general() {
    ProjectBanner
    echo
    echo "0. Select project"
    echo
    echo "1. View All Projects"
    echo "2. View All active websites"
    echo "3. View All disabled websites"
    #echo "3. Graph All active sites"
    echo "4. Disable All sites"
    echo "5. Backup All Active"
    echo "6. Create New Lovable Project (Git + npm build)"
    echo
    echo "conf. Edit configs"
    echo "r. Restart nginx"
    echo
    echo "g. Start goaccess"
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
            echo
            echo "  Available projects.."
            echo
            GetDisabledSites
            echo
            GetActiveSites
            echo
            ;;
    
        2)
            clear
            GetActiveSites
            ;;
        3)
            clear
            GetDisabledSites
            ;;
        'gl')
            clear
            GraphAllActive
            ;;
        4)
            clear
            DisableAllSites
            ;;
        5)
            clear
            backupAll
            ;;
        6) # New Lovable Project
            clear
            ProjectBanner
            echo
            read -p "Enter name for the new project: " name
            # Basic validation: check if name is provided
            if [[ -z "$name" ]]; then
                echo "❌ Project name cannot be empty."
                sleep 2
            # Basic check: prevent overwriting existing source or config by simplistic check
            elif [[ -d "/var/www/sources/$name" || -f "/etc/nginx/sites-available/$name.nginx" ]]; then
                echo "❌ Project '$name' already exists (source dir or nginx config found)."
                sleep 3
            else
                echo "🚀 Starting setup for new lovable project: $name..."
                # Call the setup function - it will ask for Git URL and domain
                SetupLov
                # SetupLov already has a 'Press Enter to continue', so no extra pause needed
            fi
            # Return to general menu after setup attempt
            ;;
        'g')
            clear
            echo "Starting Nginx website..."
            sudo mv /etc/nginx/disabled/goaccess.nginx /etc/nginx/sites-enabled/goaccess.nginx
            echo
            sudo systemctl restart nginx
            echo "Starting GoAccess in real-time..."
            echo
            sudo goaccess /var/log/nginx/access.log --log-format=COMBINED --real-time-html -o /var/www/sites/goaccess/report.html
            echo
            echo "Disabling Nginx server..."
            echo
            sudo mv /etc/nginx/sites-enabled/goaccess.nginx /etc/nginx/disabled/
            sudo systemctl restart nginx
            ;;
        'conf')
            clear
            IsSetProject="conf"
            ;;
        'r')
            clear
            echo "Restarting Nginx..."
            sudo systemctl restart nginx
            echo "Finished restarting Nginx"
            ;;
        'reboot')
            clear
            echo "Any UNSAVED changes will be LOST"
            echo "Are you sure you want to fully reboot the server?"
            read -p " (Type 'yes' to confirm reboot): " confirm
            if [[ $confirm == "yes" ]]; then
                echo "Initiating full reboot of Linux..."
                sudo reboot
                # This line will not be reached if `reboot` is successful
                echo "Rebooting..."
                while true; do
                    echo "Bye"
                    sleep 1
                done
            else
                echo "Cancelling reboot"
            fi
            ;;
        *)
            clear
            echo "Invalid option"
            ;;
    esac
}


