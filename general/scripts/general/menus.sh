. server/stuff.sh
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

managesite() {
    echo
    echo "sup"
    read -p "What you wanna do?: " test
    echo
}