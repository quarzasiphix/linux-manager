SetProject() {
    clear

    echo
    echo "  Available projects.."
    echo
    GetDisabledSites
    echo
    GetActiveSites
    echo
    ProjectBanner
    # Ask user to type in a name
    read -p "Project name: " name
    if ! validate_name "$name"; then
        echo "Invalid project name. Only letters, numbers, - and _ allowed."
        return 1
    fi
    echo
    source="/var/www/sites/$name"
    GrabDomain
    IsSetProject="true"
}


ConfigServer() {
    echo
    echo "  :server setup:"
    read -p "name of the server: " server_name
    read -p "Enter the location of the server: " server_location
    echo
    server_dir="/var/www/server"
    sudo mkdir -p "$server_dir"
    sudo chmod 777 -R $server_dir

    echo "$server_name" > /var/www/server/name.txt
    echo "$server_location" > /var/www/server/info.txt
    sudo chmod 777 -R $server_dir
    
}

DeleteWp() {
    # Confirm deletion
    echo -e " \e[31m Permanent Erase,\e[0m there is no turnning back! "
    echo
    echo "make a backup before deleting"
    echo
    echo -e "Are you sure you want to delete project '$name'?"
    echo
    echo "Deleting the project will delete the database"
    echo ", nginx config, source files and logs"
    echo 
    read -p " (Type 'yes' to confirm): " confirm

    if [[ $confirm == "yes" ]]; then
        echo
        echo "Removing files and configs for project '$name'..."
        echo

        sudo trash "/var/www/sites/$name"
        #sudo trash "/var/www/logs/$name"
        sudo rm "/etc/nginx/sites-enabled/$name.nginx"

        # Restarting nginx to update delete
        sudo systemctl restart nginx

        echo
        echo "Clearing database for project '$name'..."
        echo

        sudo mysql -u root <<EOF
        DROP DATABASE IF EXISTS $name;
        DROP USER IF EXISTS '$name'@'localhost';
        \q
EOF
        echo "Successfully removed project '$name'"
    else
        echo "Deletion canceled. No changes made."
    fi
}


# Function to check if debug is enabled
is_debug_enabled() {
    grep -q "define('WP_DEBUG', true);" "$config_file" && \
    grep -q "define('WP_DEBUG_LOG', true);" "$config_file" && \
    grep -q "define('WP_DEBUG_DISPLAY', false);" "$config_file" && \
    grep -q "@ini_set('display_errors', 0);" "$config_file" && \
    grep -q "define('SCRIPT_DEBUG', true);" "$config_file"
}

DisableDebug() {
    # Path to wp-config.php
    # Check if wp-config.php exists
    echo
    echo "Disabling Debug mode for $name"
    echo

    sed -i "s/define('WP_DEBUG', true);/define('WP_DEBUG', false);/" "$config_file"
    sed -i "s/define('WP_DEBUG_LOG', true);/define('WP_DEBUG_LOG', false);/" "$config_file"
    sed -i "s/define('WP_DEBUG_DISPLAY', false);/define('WP_DEBUG_DISPLAY', true);/" "$config_file"
    sed -i "s/@ini_set('display_errors', 0);/@ini_set('display_errors', 1);/" "$config_file"
    sed -i "s/define('SCRIPT_DEBUG', true);/define('SCRIPT_DEBUG', false);/" "$config_file" 
}

EnanbleDebug() {
    # Check if directory argument is provided
    # Path to wp-config.php
    echo
    echo "Enabling Debug mode for $name"
    echo

    # Debug settings to add
    debug_settings="
    /* Enable WP_DEBUG mode */
    define('WP_DEBUG', true);

    /* Enable Debug logging to the /wp-content/debug.log file */
    define('WP_DEBUG_LOG', true);

    /* Disable display of errors and warnings */
    define('WP_DEBUG_DISPLAY', false);
    @ini_set('display_errors', 0);

    /* Use dev versions of core JS and CSS files (only needed if you are modifying these core files) */
    define('SCRIPT_DEBUG', true);
    "

    # Check if WP_DEBUG is already defined
    if grep -q "define('WP_DEBUG'" "$config_file"; then
    echo "Debug settings already defined in $config_file"
    else
    # Add debug settings before the line that says "That's all, stop editing! Happy blogging."
    sed -i "/^\/\* That's all, stop editing! Happy blogging. \*\//i $debug_settings" "$config_file"
    echo "Debug settings added to $config_file"
    fi
}

EditConf() {
    log_action "Editing Nginx config"
    sudo vim $nginxconfdir/$name.nginx
    log_action "Edited Nginx config"
    clear
    echo
    echo "edited config for $name"
    echo
    echo "restarting nginx to confirm changes"
    echo
    sudo systemctl restart nginx
}

EnableConf() {
    log_action "Enabling site"
    echo 
    echo -e "\e[32m Enabling site... \e[0m"
    echo
    sudo rm $nginxconfdir/$name.disabled
    sudo mv $nginxdisabled/$name.nginx $nginxconfdir
    echo
    echo "restarting nginx..."
    echo
    sudo systemctl restart nginx
    echo
    echo "Enabled! $name"
    log_action "Site enabled"
}

DisableConf() {
    log_action "Disabling site"
    echo
    echo
    echo

    echo -e " \e[31m Disbling site... \e[0m"
    sudo mkdir "$nginxdisabled" > /dev/null 2>&1
    grabbeddomain=$(grep -o 'server_name.*;' $nginxconfdir/$name.nginx | awk '{print $2}' | sed 's/;//')
    echo
    echo "Disabling config for $name on $grabbeddomain..."
    echo
    sudo mv $nginxconfdir/$name.nginx $nginxdisabled 
    echo
    echo "restarting nginx..."
    echo "..."
    sudo systemctl restart nginx
    echo
    echo "Disabled! $name"
    log_action "Site disabled"
}

GrabDomain() {
    if [ -f "$nginxconfdir/$name.nginx" ]; then
        # Print "Site Enabled" in green
        currentdomain=$(grep -o 'server_name.*;' $nginxconfdir/$name.nginx | awk '{print $2}' | sed 's/;//')
    elif [ -f "$nginxdisabled/$name.nginx" ]; then
        currentdomain=$(grep -o 'server_name.*;' $nginxdisabled/$name.nginx | awk '{print $2}' | sed 's/;//')
    else
        echo
        echo "config not found.."
        echo
    fi
    #echo "$grabbeddomain"
    #currentdomain=$grabbeddomain
}

# Function to extract database password from wp-config.php
extract_db_password() {
    wp_config_file="/var/www/sites/$name/wp-config.php"
    db_password=$(sed -nE "s/.*DB_PASSWORD\s*=\s*['\"](.*)['\"].*/\1/p" "$wp_config_file")
    echo "$db_password"
}

UpdateElementor() {
    nginx_config="/etc/nginx/sites-enabled/$name.nginx"
    backupdir="/var/www/backups/$name"
    tempdir="$backupdir/$name-temp"
    plugindir="/var/www/sites/$name"

    echo
    echo "Making backup..."
    echo

    if ! BackupWP; then
        echo "Backup failed! Exiting..."
        exit 1
    fi

    echo "Backup finished."
    echo "Removing old Elementor Pro..."
    
    # Get current date
    current_date=$(date +%F)

    # Define backup directories
    elementor_backup="$backupdir/elementor"
    dated_backup="$elementor_backup/3-$current_date"
    elementor_version_backup="$dated_backup/e-$current_date"

    # Create necessary backup directories
    sudo mkdir -p "$elementor_version_backup"

    # Move old Elementor Pro into the dated backup folder
    if [[ -d "$plugindir/elementor-pro" ]]; then
        sudo mv "$plugindir/elementor-pro" "$elementor_version_backup"
        echo "Old Elementor Pro moved to $elementor_version_backup"
    else
        echo "Warning: No existing Elementor Pro found at $plugindir"
    fi

    echo
    echo "Updating Elementor Pro..."
    echo

    # Copy new Elementor Pro from /var/www/libs/
    if [[ -d "/var/www/libs/elementor-pro" ]]; then
        sudo cp -r "/var/www/libs/elementor-pro" "$plugindir"
        echo "New Elementor Pro installed successfully."
    else
        echo "Error: New Elementor Pro not found at $elementor_lib. Exiting..."
        exit 1
    fi
}

ChangeDomain() {
    echo
    echo "Changing domain for project $name"
    echo
    read -p "   Add or replace domain? (R, A):  " radomain
    echo
    read -p "   Enter new domain: " new_domain
    echo

    config_file=""
    if [ -f "$nginxconfdir/$name.nginx" ]; then
        config_file="$nginxconfdir/$name.nginx"
    elif [ -f "$nginxdisabled/$name.nginx" ]; then
        config_file="$nginxdisabled/$name.nginx"
    else
        echo "Could not find Nginx config."
        return
    fi

    current_domains=$(grep -o 'server_name.*;' "$config_file" | awk '{for(i=2; i<=NF; i++) print $i}' | sed 's/;//')
    echo
    echo "Current domains in the configuration:"
    printf "%s\n" "$current_domains"
    echo

    if [ "$radomain" = "A" ] || [ "$radomain" = "a" ]; then
        echo "Adding domain $new_domain to the configuration..."
        sed -i "/server_name/ s/;/ $new_domain;/" "$config_file"
        echo "Domain added successfully."
    elif [ "$radomain" = "R" ] || [ "$radomain" = "r" ]; then
        echo "Replacing domain in the configuration with $new_domain..."
        current_domain=$(echo "$current_domains" | head -n 1) # Assume first domain is the one to replace
        sed -i "s/\b$current_domain\b/$new_domain/" "$config_file"
        echo "Domain replaced successfully."
    else
        echo "Invalid option. Please choose 'A' to add or 'R' to replace."
        return
    fi

    # Restart Nginx to apply changes
    sudo systemctl restart nginx

    echo
    echo "Successfully updated the Nginx configuration for project $name."
    echo
}



OldChangeDomain() {
    #grabbeddomain=$(grep -o 'server_name.*;' $nginxconfdir/$name.nginx | awk '{print $2}' | sed 's/;//')
    echo
    echo "Changing domain for project $name"
    echo
    read -p "Add or replace domain? (R, A):  " radomain
    read -p "Enter new domain: " new_domain
    echo
    GrabDomain 
    currentdomain=$(grep -o 'server_name.*;' $nginxconfdir/$name.nginx | awk '{print $2}' | sed 's/;//')
    if [ -f "$nginxconfdir/$name.nginx" ]; then
        echo
        echo "  domains"
        echo
        domains=$(grep -o 'server_name.*;' "$nginxconfdir/$name.nginx" | awk '{for(i=2; i<=NF; i++) print $i}' | sed 's/;//')
        printf "%s\n" "$domains"
    elif [ -f "$nginxdisabled/$name.nginx" ]; then
        echo
        echo "  domains"
        echo
        domains=$(grep -o 'server_name.*;' "$nginxdisabled/$name.nginx" | awk '{for(i=2; i<=NF; i++) print $i}' | sed 's/;//')
        printf "%s\n" "$domains"
    else
        new_domain="unkown"
        echo "couldnt find nginx config"
    fi
    echo
    read -p "attempt to change wordpress domain?: " wpdomain
    if [ "$wpdomain" = "yes" ]; then
        db_password=$(extract_db_password)
        # Check if the password was found
        if [ -z "$db_password" ]; then
            echo "Error: Database password not found in wp-config.php"
            echo "password: $db_password"
        else
            echo
            echo -e "Database password found"
            echo
            return
        fi

    # Update WordPress options table
    mysql -u$name -p$db_password $name << EOF
    UPDATE wp_options SET option_value = replace(option_value, '$currentdomain', '$new_domain') WHERE option_name = 'home' OR option_name = 'siteurl';
EOF
    # Update WordPress posts content
    mysql -u$name -p$db_password $name << EOF
    UPDATE wp_posts SET post_content = replace(post_content, '$currentdomain', '$new_domain');
EOF
    # Update WordPress post meta
    mysql -u$name -p$db_password $name << EOF
    UPDATE wp_postmeta SET meta_value = replace(meta_value, '$currentdomain','$new_domain');
EOF
    fi
    sudo systemctl restart nginx
    echo
    echo "succesfully changed the domain for project $name from $currentdomain to $new_domain"
    echo
    GrabDomain

    rm /var/$name
}

# Function to delete a project (generic)
DeleteProject() {
    log_action "User requested deletion for project $name"
    if [[ -z "$name" ]] || ! validate_name "$name"; then
        log_action "Aborted deletion: invalid or empty project name"
        echo "Invalid or empty project name. Aborting."
        return 1
    fi

    echo -e " \e[31mWARNING: Permanent Deletion!\e[0m "
    echo
    echo "This will attempt to remove the following for project '$name':"
    echo "  - Nginx configuration (enabled/available/disabled)"
    echo "  - Log directory (/var/www/logs/$name)"
    
    # Determine paths based on likely type
    local project_type="unknown"
    local site_dir="/var/www/sites/$name"
    local source_dir="/var/www/sources/$name"
    local nginx_conf_avail="/etc/nginx/sites-available/$name.nginx"
    local nginx_conf_enabled="/etc/nginx/sites-enabled/$name.nginx"
    local nginx_conf_disabled="/etc/nginx/disabled/$name.nginx"
    local log_dir="/var/www/logs/$name"
    
    if [[ -d "$source_dir" ]]; then
        project_type="lovable"
        echo "  - Source directory ($source_dir)"
    elif [[ -f "$site_dir/wp-config.php" || -d "$site_dir" ]]; then # Assume WP or HTML if site dir exists
        project_type="site_based" # Generic type for WP/HTML
        echo "  - Site directory ($site_dir)"
    else
         echo "  (Could not detect specific site/source directory, will only remove Nginx/logs)"
    fi
    echo
    echo "This action cannot be undone. Consider creating a backup first."
    echo "Backups in /var/www/backups/$name will NOT be deleted by this action."
    echo "WordPress databases will NOT be deleted by this action."
    echo
    read -p "Type 'delete $name' to confirm: " confirm_input

    if [[ "$confirm_input" == "delete $name" ]]; then
        log_action "Confirmed deletion for $name"
        # Backup before deletion (rollback point)
        local backup_dir="/var/www/backups/$name-predelete-$(date +%s)"
        sudo mkdir -p "$backup_dir"
        if [[ -d "/var/www/sites/$name" ]]; then
            sudo cp -a "/var/www/sites/$name" "$backup_dir/"
        fi
        if [[ -d "/var/www/sources/$name" ]]; then
            sudo cp -a "/var/www/sources/$name" "$backup_dir/"
        fi

        # Remove Nginx configs
        for conf in "/etc/nginx/sites-enabled/$name.nginx" "/etc/nginx/sites-available/$name.nginx" "/etc/nginx/disabled/$name.nginx"; do
            if [[ -f "$conf" ]]; then
                sudo rm -f "$conf"
                log_action "Removed Nginx config: $conf"
            fi
        done

        # Remove directories safely
        safe_delete_dir "/var/www/sites/$name"
        if [[ "$project_type" == "lovable" ]]; then
            safe_delete_dir "/var/www/sources/$name"
        fi
        safe_delete_dir "/var/www/logs/$name"

        sudo systemctl restart nginx && log_action "Restarted Nginx after deletion"

        log_action "Completed deletion for $name. Backup at $backup_dir"
        echo "Project '$name' deleted. Backup at $backup_dir"
    else
        log_action "Deletion cancelled for $name"
        echo "Deletion cancelled."
    fi
}

validate_name() {
    [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]]
}

safe_delete_dir() {
    local dir="$1"
    if [[ -z "$dir" || "$dir" == "/" || "$dir" == "/var" || "$dir" == "/var/www" ]]; then
        log_action "Refused to delete suspicious directory: $dir"
        echo "Refusing to delete suspicious directory: $dir"
        return 1
    fi
    if [[ -d "$dir" ]]; then
        sudo rm -rf "$dir"
        log_action "Deleted directory: $dir"
    else
        log_action "Directory not found for deletion: $dir"
    fi
}

log_action() {
    local action="$1"
    local project="${name:-N/A}"
    local logfile="/var/www/logs/manager.log"
    local user="${SUDO_USER:-$USER}"
    local timestamp
    timestamp="$(date '+%F %T')"
    sudo mkdir -p /var/www/logs
    sudo touch "$logfile"
    sudo chown quarza:www-data "$logfile"
    sudo chmod 640 "$logfile"
    echo "$timestamp | user:$user | project:$project | $action" | sudo tee -a "$logfile" > /dev/null
}