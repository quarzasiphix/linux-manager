dir="/var/www/sites/$name"

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
            echo -e "5)\e[31m Disble\e[0m site"
        elif [ -f "$nginxdisabled/$name.nginx" ]; then
            echo -e "5)\e[32m Enable\e[0m site "
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
        esac
    if [ -f "$nginxconfdir/$name.nginx" ]; then
        case $choice in
        5)
            clear
            DisableConf
        ;;
        'disable')
            clear
            DisableConf
        ;;
        
        esac
    elif [ -f "$nginxdisabled/$name.nginx" ] || [ -f "$nginxconfdir/$name.disabled" ]; then
        case $choice in
            5)
                clear
                EnableConf
            ;;
            'enable')
                clear
                EnableConf
            ;;
        esac
    fi

    elif [ -d "/var/www/backups/$name" ]; then
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