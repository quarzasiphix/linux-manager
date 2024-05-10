. $dir/server/stuff.sh
. $dir/site/manage.sh
. $dir/site/setupwp.sh
. $dir/site/restore.sh
. $dir/site/backup.sh
. $dir/site/webs.sh
. $dir/site/setuphtml.sh

general() {
    ProjectBanner
    echo
    echo "0. Select project"
    echo
    echo "1. View All active websites"
    echo "2. View All disabled websites"
    echo "3. Graph All active sites"
    echo "4. Disable All sites"
    echo "5. Backup All Active"
    echo
    echo "conf. Edit configs"
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
        'conf')
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

configurator() {
    echo
    ProjectBanner
    echo
    echo "Welcome to config shortcut menu"
    echo
    echo " 0. Go back to main menu"
    echo
    echo "sizes.    check size of main directories"
    echo "serv.     update server config"
    echo "ngc.      nginx general config (/etc/nginx/nginx.conf)"
    echo "sc.       sshd config (/etc/ssh/sshd_config)"
    echo "motd.     ssh motd (/etc/motd)" 
    echo "banner.   ssh banner (/etc/ssh/banner.sh)"
    echo "passwd.   (/etc/passwd)"
    echo "bashrc.   (~/.bashrc)"
    echo "visudo."
    echo "check.    check for updates"
    echo "Update.   updates the script"
    echo
    read -p "   What confif do you want to edit?: " conf
    case $conf in
        0)
            clear
            IsSetProject=false
            EditingConfig=false
        ;;
        'check')
            clear
            check_for_update
        ;;
        'sizes')
            clear
            echo
            neofetch
            echo
            echo "www folder size: "
            du -sh "/var/www"
            echo
            echo "Sites folder size: "
            du -sh "/var/www/sites"
            echo
            echo "Backups folder size: "
            du -sh "/var/www/backups"
            echo
            echo "logs folder size: "
            du -sh "/var/www/logs"
        ;;  
        'serv')
            clear
            ConfigServer
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
        'update')
            clear
            echo
            echo " retrieving new downloader..."
            echo
            sudo rm /var/www/scripts/downloader/download.sh
            sudo curl -o "/var/www/scripts/downloader/download.sh" "https://raw.githubusercontent.com/quarzasiphix/linux-manager/master/source/downloader/download.sh"
            sudo chmod +x "/var/www/scripts/downloader/download.sh"
            echo
            echo "updating..."
            echo
            /var/www/scripts/downloader/download.sh
        ;;
        *)  
            echo
            echo "invalid choice"
            echo
        ;;
    esac
}

managesite() {
    ProjectBanner
    echo
    echo "  Project: $name"
    echo

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
        echo "4. Change domain"
        # Read user's choice
        echo "s. Check weight of source files"
        echo "b. Create backup"
        echo "r. Restore back"
        echo
        echo "pass. Show project password"
        echo "del. Delete project"
        read -p "Enter your choice (1-X): " choice

        # Perform action based on user's choice
        case $choice in
        'pass')
            clear
            password_file="/var/www/sites/$name/password.txt"
            if [ ! -f "$password_file" ]; then
                echo
                echo "No set password for $name."
                echo
                read -p "Do you want to set a new project password for $name? (y/n): " set_password
                if [ "$set_password" = "y" ]; then
                    read -s -p "Enter a new project password for $name: " new_password
                    echo "$new_password" | sudo tee "$password_file" > /dev/null
                    echo "Password file created."
                else
                    echo "No changes made to the password."
                fi
            else
                password=$(sudo cat "$password_file")
                echo 
                echo "Password for project $name: $password"
                echo
                read -p "Do you want to change the project password for $name? (y/n): " change_password
                if [ "$change_password" = "y" ]; then
                    read -s -p "Enter the new project password for $name: " new_password
                    echo "$new_password" | sudo tee "$password_file" > /dev/null
                    echo "Password changed."
                else
                    echo "No changes made to the password."
                fi
            fi
            ;;
        0)
            clear
            IsSetProject=false
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
            echo "Changing domain..."
            ChangeDomain
        ;;
        's')
            clear
            echo "storage usage for $name"
            echo
            echo "  Logs folder size: "
            du -sh "/var/www/logs/$name"
            echo
                    # Check if directory exists
            if [ -d "/var/www/backups/$name" ]; then
                # If directory exists, show size
                echo "  Backups folder size:"
                du -sh "/var/www/backups/$namey"
            else
                # If directory does not exist, show message
                echo "No backups found"
            fi
            echo
            echo "  source folder size: "
            du -sh "/var/www/sites/$name"
            echo
            echo
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
        'del')
            clear
            echo
            echo "Deleting project..."
            echo
            DeleteWp
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
        
        'disable')
            clear
            DisableConf
        ;;

        'enable')
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

    elif [ -d "/var/www/backups/$name" ]; then
        clear
        ProjectBanner
        echo
        echo
        echo "no active running site for project"
        echo 
        echo "  found available backups: "
        echo
        echo "restore. Restore a backup"
        echo "wp. Setup wordpress project"
        echo "html. Setup regular html project"
        echo
        read -p " (Type 'no' to leave): " confirm
        case $confirm in
        'restore')
            clear
            ProjectBanner
            echo
            echo "Restoring $name"...
            echo
            RestoreWP
            ;;
        'wp')
            clear
            ProjectBanner
            echo
            echo "setting up project for $name"
            echo
            echo
            SetupWP
            ;;
        'html')
            echo
            echo "setting up html project for $name"
            echo
            SetupHtml
            echo
            echo "Done configuring html project for $name"
            echo
            ;;
        'no')
            clear
            IsSetProject=false
            ;;
      esac
  
    else
        echo 
        echo "project $name doesnt exist"
        echo
        read -p "setup new project for $name? (wp, html or no): " create
        case $create in
            'wp')
                echo
                echo "setup wordpress project for $name"
                echo
                SetupWP
                clear
                echo "successfully setup project $name"
                echo
                ;;
            'html')
                echo
                echo "setting up html project for $name"
                echo
                SetupHtml
                echo
                echo "Done configuring html project for $name"
                echo
                ;;
            'no') 
                IsSetProject=false
                clear
                ;;
            *)
                echo "Invalid choice. cancelling"
            ;;
        esac
    fi
}