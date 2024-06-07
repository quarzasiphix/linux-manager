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