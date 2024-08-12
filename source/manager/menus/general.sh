#!/bin/bash

# Define your general function
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
            clear
            DisableAllSites
            ;;
        5)
            clear
            backupAll
            ;;
        'g')
            clear
            echo "Starting Nginx website..."
            sudo mv /etc/nginx/disabled/goaccess.nginx /etc/nginx/sites-enabled/goaccess.nginx
            sudo systemctl restart nginx
            echo "Starting GoAccess in real-time..."
            sudo goaccess /var/log/nginx/access.log --log-format=COMBINED --real-time-html -o /var/www/sites/goaccess/report.html &
            echo "Disabling Nginx server..."
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

# Ensure to call your function here if needed
general
