nginxdisabled="/etc/nginx/disabled"
config_file="$dir/wp-config.php"
name=""

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
    echo
    source="/var/www/sites/$name"
    GrabDomain
    IsSetProject=true
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
        echo "Removing files, config, and logs for project '$name'..."
        echo

        sudo trash "/var/www/sites/$name"
        sudo trash "/var/www/logs/$name"
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
    sudo vim $nginxconfdir/$name.nginx
    clear
    echo
    echo "edited config for $name"
    echo
    echo "restarting nginx to confirm changes"
    echo
    sudo systemctl restart nginx
}

EnableConf() {
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
    echo
}

DisableConf() {
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

ChangeDomain() {
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
}