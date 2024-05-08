nginxdisabled="/etc/nginx/disabled"

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

    clear
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

        sudo rm -R "/var/www/sites/$name"
        sudo rm -R "/var/www/logs/$name"
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


DisableConf() {
    echo
    echo
    echo

    sudo mkdir "$nginxdisabled" > /dev/null 2>&1
    echo -e " \e[31m Disbling site... \e[0m"
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
    db_password=$(sed -nE "s/.*DB_PASSWORD\s*=\s*['\"](\w*)['\"].*/\1/p" "$wp_config_file")
    echo "$db_password"
}

ChangeDomain() {
    #grabbeddomain=$(grep -o 'server_name.*;' $nginxconfdir/$name.nginx | awk '{print $2}' | sed 's/;//')
    echo
    echo "Changing domain for project $name"
    echo
    read -p "Enter new domain: " new_domain
    echo
    GrabDomain 
    currentdomain=$(grep -o 'server_name.*;' $nginxconfdir/$name.nginx | awk '{print $2}' | sed 's/;//')
    if [ -f "$nginxconfdir/$name.nginx" ]; then
        sudo sed -i "s/server_name .*/server_name $new_domain www.$new_domain;/g" "$nginxconfdir/$name.nginx"
    elif [ -f "$nginxdisabled/$name.nginx" ]; then
        sudo sed -i "s/server_name .*/server_name $new_domain www.$new_domain;/g" "$nginxdisabled/$name.nginx"
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
        else
            echo
            echo -e "Database password found"
            echo
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