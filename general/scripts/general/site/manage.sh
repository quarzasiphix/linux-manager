SetProject() {
    clear
    ProjectBanner

    echo
    echo "  Available projects.."
    echo
    GetDisabledSites
    echo
    GetActiveSites
    
    # Ask user to type in a name
    read -p "Project name: " name
    echo
    source="/var/www/sites/$name"
    GrabDomain
    IsSetProject=true

    clear
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
    fi
    #echo "$grabbeddomain"
    #currentdomain=$grabbeddomain
}

