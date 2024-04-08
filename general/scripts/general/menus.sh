. server/serverstuff.sh
. site/manage.sh

general() {
    ProjectBanner
    echo "0. Select project"
    echo
    echo "1. View All active websites"
    echo "2. View All disabled websites"
    echo "3. Graph All active sites"
    echo "4. Disable All sites"
    echo "5. Backup All Active"
    echo "6. Edit configs"
    echo
    echo "r. Restart nginx"
    echo
    echo "reboot - Fully reboot the server"
    echo
    read -p "What you wanna do?: " adminchoice
    case $adminchoice in 
        0)
            clear
            SetProject
            ;;
        1)
            clear
            GetActiveSites
            ;;
        2)
            clear
            GetDisabledSites
            ;;
        3)
            clear
            GraphAllActive
            ;;
        4)
            
            ;;
        5)
            clear
            backupAll
            ;;
        6)
            clear
            IsSetProject="conf"
            ;;
        'r')
            clear
            echo 
            echo "restarting nginx..."
            sudo systemctl restart nginx
            echo
            echo "finished restarting nginx"
            echo
            ;;
        'reboot')
            clear
            echo
            echo "Any UNSAVED changes Will be LOST"
            echo
            echo "are you sure you want to fully reboot the server"
            echo
            read -p " (Type 'yes' to confirm reboot): " confirm

            if [[ $confirm == "yes" ]]; then
                echo
                echo "initiating full reboot of linux...."
                echo
                sudo reboot

                echo "rebooting...."
                echo

                while true; do
                    echo "bye"
                done
            else
                echo "cancelling reboot"
                echo
            fi
            ;;
        *)
            clear
            echo "invalid"
            ;;
    esac
}

sites() {
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
}

configurator() {
    ProjectBanner
    echo
    echo "Welcome to config shortcut menu"
    echo
    echo " 0. Go back to main menu"
    echo
    echo "ngc.      nginx general config (/etc/nginx/nginx.conf)"
    echo "sc.       sshd config (/etc/ssh/sshd_config)"
    echo "motd.     ssh motd (/etc/motd)" 
    echo "banner.   ssh banner (/etc/ssh/banner.sh)"
    echo "passwd.   (/etc/passwd)"
    echo "bashrc.   (~/.bashrc)"
    echo "visudo"
    echo
    read -p "   What confif do you want to edit?: " conf
    case $conf in
        0)
            EditingConfig=false
            ;;
        'ngc')
            clear
            EditNginxconf
            ;;
        'sc')
            clear
            EditSshconf
            ;;
        'motd')
            clear
            EditMotd
            ;;
        'banner')
            clear
            EditBanner
            ;;
        'passwd')
            clear
            EditPasswd
            ;;
        'bashrc')
            clear
            EditBash
            ;;
        'visudo')
            clear
            EditVisudo
            ;;
        *)  
            echo
            echo "invalid choice"
            echo
            ;;
    esac
}