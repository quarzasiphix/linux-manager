name=$1
IsSetProject=true

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
    echo "setting up config for $name on $grabbeddomain to disabled page"
    echo
    echo ...
    sudo mv $nginxconfdir/$name.nginx $nginxdisabled 
    sudo tee "$nginxconfdir/$name.disabled" > /dev/null << EOT
server {
    listen 80;
    server_name $grabbeddomain www.$grabbeddomain;
    root /var/www/sites/disabled;
    index index.html;
}
EOT
    echo
    echo "Made config for $name to disabled route"
    echo
    echo "restarting nginx..."
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

SetProject() {
    clear
    ProjectBanner
    # Ask user to type in a name
    read -p "Project name: " name
    echo
    source="/var/www/sites/$name"
    GrabDomain
    IsSetProject=true
}


# Present options to the user
while [ "$IsSetProject" == "true" ]; do
    if [ -d "$source" ]; then
        echo
        if [ -f "$nginxconfdir/$name.nginx" ]; then
            # Print "Site Enabled" in green
            echo -e " :Site \e[32m Enabled\e[0m:"
        elif [ -f "$nginxdisabled/$name.nginx" ]; then
            # Print "Site Disabled" in red
            echo -e " :Site \e[31m Disabled\e[0m:"
        fi
        echo
        echo "Current domain: $currentdomain" 
        echo
        echo "What would you like to do to $name?"
        echo
        echo "0. Change project"
        echo
        if [ -f "$nginxconfdir/$name.nginx" ]; then
            echo -e "\e[31m Disble\e[0m site"
        elif [ -f "$nginxdisabled/$name.nginx" ]; then
            echo -e "\e[32m Enable\e[0m site "
        else
            echo
            echo "  :site status unknown:  "
            echo
        fi
        echo "1. Graph log"
        echo "2. Edit nginx config"
        echo "3. Reset project"
        echo "4. Delete project"
        # Read user's choice
        echo "6. Change domain"
        echo "b. Create backup"
        echo "r. Restore back"
        echo
        read -p "Enter your choice (1-X): " choice

        # Perform action based on user's choice
        case $choice in
            0)
                clear
                IsSetProject=false
                break
                ;;
            1)
                clear
                echo
                echo "Graphing log..."
                GraphLog
                ;;
            2)    
                echo
                echo "Editing config..."
                EditConf
                ;;
                
            3)  
                clear
                echo
                echo "Resetting project..."
                test
                ;;
                
            4)
                clear
                echo
                echo "Deleting project..."
                echo
                DeleteWp
                ;;
            6)
                clear
                #grabbeddomain=$(grep -o 'server_name.*;' $nginxconfdir/$name.nginx | awk '{print $2}' | sed 's/;//')
                echo "Changing domain for project $name"
                echo
                read -p "Enter new domain: " new_domain
                echo
                GrabDomain 
                if [ -f "$nginxconfdir/$name.nginx" ]; then
                    sudo sed -i "s/server_name .*/server_name $new_domain www.$new_domain;/g" "$nginxconfdir/$name.nginx"
                elif [ -f "$nginxdisabled/$name.nginx" ]; then
                    sudo sed -i "s/server_name .*/server_name $new_domain www.$new_domain;/g" "$nginxdisabled/$name.nginx"
                else
                    $new_domain="unkown"
                fi
                echo "Changing domain.."

                echo
                echo "succesfully changed the domain for project $name from $grabbeddomain to $new_domain"
                echo
                GrabDomain
                ;;
            'b')
                clear
                echo
                echo "Creating backup for $name"
                echo
                BackupWP
                ;;
            'r')
                clear
                echo
                echo "Restoring a backup for $name"
                echo
                RestoreWP
                ;;

            11)
                clear
                echo "Going to $names's plugins..."
                echo
                cd /var/www/sites/$name/wp-content/plugins 
                exit
                ;;
            22)
                clear
                echo "Going to $name's source..."
                echo
                cd /var/www/sites/$name 
                exit
                ;;
            33)
                clear
                echo "Going to $name's logs..."
                echo
                cd /var/www/logs/$name 
                exit
                ;;
       
            *)
                echo "Invalid choice. Please enter a number between 1 and 4."
                ;;
            esac
        if [ -f "$nginxconfdir/$name.nginx" ]; then
            case $choice in
                5)
                    clear
                    DisableConf
                    ;;
            esac
        elif [ -f "$nginxdisabled/$name.nginx" ] || [ -f "$nginxconfdir/$name.disabled" ]; then
            case $choice in
                5)
                    clear
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
                    ;;
            esac
        fi

    elif [ -d "/var/www/backups/$name" ]; then
        clear
        echo
        echo "no active running site for project"
        echo 
        echo "found available backups: "
        echo
        echo
        RestoreWP

    else
        echo 
        echo "project $name doesnt exist"
        echo
        read -p "setup new project for $name? (yes or no): " create
        case $create in
            yes)
                echo "setup wordpress project for $name"
                echo
                SetupWP
                clear
                echo "successfully setup project $name"
                echo
                ;;
            no) 
                exit
                ;;
            *)
                echo "Invalid choice. cancelling"
                exit
            ;;
        esac
    fi
    done