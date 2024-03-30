nginxconfdir="/etc/nginx/sites-enabled"
nginxdisabled="/etc/nginx/disabled"

# project info
currentdomain=

ProjectBanner() {
    server_name=$(</var/www/server/name.txt)
    server_location=$(</var/www/server/info.txt)

    echo
    echo    "   Server: $server_name!"
    echo    "   at: $server_location!"
    echo
    echo -e "    :Welcome \e[36m$USER\e[0m!!!"
    echo -e "to the\e[38m project management tool! \e[0m"
    echo
}

main () {
    
#SetProject
clear
while true; do
    while [ "$IsSetProject" == "false" ]; do 
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
    done


    while [ "$IsSetProject" == "conf" ]; do 
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
    done
done
}

main 