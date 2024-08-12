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
            
            ;;
        5)
            clear
            backupAll
            ;;
        'g')
            clear
            echo
            echo "starting nginx website"
            echo
            sudo mv /etc/nginx/disabled/goaccess.nginx/ /etc/nginx/sites-enabled/goaccess.nginx/ 
            sudo systemctl restart nginx 
            echo
            echo
            echo "Starting go access in real time.."
            echo
            sudo goaccess /var/log/nginx/access.log --log-format=COMBINED --real-time-html -o /var/www/sites/goaccess/report.html
            echo
            echo "disabling nginx server"
            sudo mv /etc/nginx/sites-enabled/goaccess.nginx/ /etc/nginx/disabled/
            sudo systemctl restart nginx 
            echo
            ::
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
