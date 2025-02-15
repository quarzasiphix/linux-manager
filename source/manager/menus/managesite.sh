config_file="/var/www/sites/$name/wp-config.php"
nginxdisabled="/etc/nginx/disabled"

# New functions for the extra features

# Edit nginx config with editor choice
EditConf() {
    echo "Select your editor for nginx config:"
    echo "1. vim"
    echo "2. nano"
    read -p "Enter your choice (1 or 2): " editorChoice
    config_path="$nginxconfdir/$name.nginx"
    case $editorChoice in
        1)
            vim "$config_path"
            ;;
        2)
            nano "$config_path"
            ;;
        *)
            echo "Invalid choice. Defaulting to nano."
            nano "$config_path"
            ;;
    esac
}

# Example WP CLI function for WordPress projects
WPCLICommands() {
    echo "Enter your WP-CLI command (e.g., plugin update --all):"
    read -r wp_cmd
    # Run WP-CLI as the appropriate user and path
    sudo -u www-data wp $wp_cmd --path="/var/www/sites/$name"
}

# Functions for HTML projects (example: starting/stopping a Python script)
StartHTMLScript() {
    script="/var/www/sites/$name/start_script.py"
    if [ -f "$script" ]; then
        nohup python3 "$script" > "/var/www/sites/$name/script.log" 2>&1 &
        echo "Script started in background."
    else
        echo "No start_script.py found in $name."
    fi
}

CheckHTMLScriptStatus() {
    pid=$(pgrep -f "/var/www/sites/$name/start_script.py")
    if [ -z "$pid" ]; then
        echo "Script is not running."
    else
        echo "Script is running with PID: $pid"
    fi
}

StopHTMLScript() {
    pid=$(pgrep -f "/var/www/sites/$name/start_script.py")
    if [ -z "$pid" ]; then
        echo "Script is not running."
    else
        kill "$pid" && echo "Script stopped." || echo "Failed to stop the script."
    fi
}

managesite() {
    ProjectBanner
    echo
    echo "  Project: $name"
    echo
    echo

    # Determine project type based on the existence of the WordPress config file
    if [ -f "$config_file" ]; then
        projectType="wordpress"
    else
        projectType="html"
    fi

    if [ -d "$source" ]; then
        echo
        if [ -f "$nginxconfdir/$name.nginx" ]; then
            echo -e " :Site \e[32mEnabled\e[0m:"
        elif [ -f "$nginxdisabled/$name.nginx" ]; then
            echo -e " :Site \e[31mDisabled\e[0m:"
        fi
        echo
        
        echo "Current domain: $currentdomain" 
        echo
        echo "What would you like to do to $name?"
        echo
        echo "0. Change project"
        if [ -f "$nginxconfdir/$name.nginx" ]; then
            echo -e "5) \e[31mDisable\e[0m site"
        elif [ -f "$nginxdisabled/$name.nginx" ]; then
            echo -e "5) \e[32mEnable\e[0m site"
        else
            echo "  :site status unknown:"
        fi
        echo "1. Graph log"
        echo "2. Edit nginx config"
        echo "3. Reset project"
        echo "4. Change domain"
        
        # Display additional options based on project type
        if [ "$projectType" = "wordpress" ]; then
            echo "w. WP-CLI commands"
            echo "pass. Show project password"
        elif [ "$projectType" = "html" ]; then
            echo "p. Start script"
            echo "q. Check script status"
            echo "r. Stop script"
        fi
        
        echo "e. Update elementor pro from lib."
        echo "s. Check weight of source files"
        echo "b. Create backup"
        echo "r. Restore backup"
        echo "d. Toggle debug"
        echo "g. Start Goaccess for site"
        echo
        echo "del. Delete project"
        read -p "Enter your choice (1-X): " choice

        # Main case statement for actions
        case $choice in
            'pass')
                clear
                password_file="/var/www/sites/$name/password.txt"
                if [ ! -f "$password_file" ]; then
                    echo "No set password for $name."
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
                    echo "Password for project $name: $password"
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
                echo "Graphing log..."
                GraphLog
                ;;
            2)
                clear
                echo "Editing nginx config..."
                EditConf
                ;;
            3)
                clear
                echo "Resetting project..."
                test
                ;;
            4)
                clear
                echo "Changing domain..."
                ChangeDomain
                ;;
            'w')
                # WordPress specific option
                clear
                echo "WP-CLI Commands:"
                WPCLICommands
                ;;
            'p')
                # HTML specific: start script
                clear
                echo "Starting HTML project script..."
                StartHTMLScript
                ;;
            'q')
                clear
                echo "Checking HTML project script status..."
                CheckHTMLScriptStatus
                ;;
            'r')
                # For HTML: stop script; note: if you have both 'r' for restore and stop script,
                # you might want to choose a different letter or number for one of these actions.
                clear
                if [ "$projectType" = "html" ]; then
                    echo "Stopping HTML project script..."
                    StopHTMLScript
                else
                    echo "Restoring backup..."
                    RestoreWP
                fi
                ;;
            'e')
                clear
                echo "Starting elementor updater..."
                UpdateElementor
                ;;
            's')
                clear
                echo "Storage usage for $name:"
                echo "Logs folder size:"
                du -sh "/var/www/logs/$name"
                if [ -d "/var/www/backups/$name" ]; then
                    echo "Backups folder size:"
                    du -sh "/var/www/backups/$name"
                else
                    echo "No backups found."
                fi
                echo "Source folder size:"
                du -sh "/var/www/sites/$name"
                ;;
            'b')
                clear
                echo "Creating backup for $name..."
                BackupWP
                ;;
            'del')
                clear
                echo "Deleting project..."
                DeleteWp
                ;;
            'g')
                clear
                echo "Starting Nginx website for GoAccess..."
                sudo mv /etc/nginx/disabled/goaccess.nginx /etc/nginx/sites-enabled/goaccess.nginx
                sudo systemctl restart nginx
                echo "Starting GoAccess in real-time for \e[32m$name\e[0m..."
                sudo goaccess /var/www/logs/$name/access.nginx --log-format=COMBINED --real-time-html -o /var/www/sites/goaccess/report.html
                sudo mv /etc/nginx/sites-enabled/goaccess.nginx /etc/nginx/disabled/
                sudo systemctl restart nginx
                ;;
            *)
                echo "Invalid choice. Please try again."
                ;;
        esac

        # Site enable/disable logic remains unchanged
        if [ -f "$nginxconfdir/$name.nginx" ]; then
            case $choice in
                5|'disable')
                    clear
                    DisableConf
                    ;;
            esac
        elif [ -f "$nginxdisabled/$name.nginx" ] || [ -f "$nginxconfdir/$name.disabled" ]; then
            case $choice in
                5|'enable')
                    clear
                    EnableConf
                    ;;
            esac
        fi

    elif [ -d "/var/www/backups/$name" ]; then
        echo "No active running site for project. Available backups:"
        echo "restore. Restore a backup"
        echo "wp. Setup WordPress project"
        echo "html. Setup regular HTML project"
        read -p " (Type 'no' to leave): " confirm
        case $confirm in
            'restore')
                clear
                ProjectBanner
                echo "Restoring $name..."
                RestoreWP
                ;;
            'wp')
                clear
                ProjectBanner
                echo "Setting up WordPress project for $name..."
                SetupWP
                ;;
            'html')
                clear
                ProjectBanner
                echo "Setting up HTML project for $name..."
                SetupHtml
                ;;
            'no')
                clear
                IsSetProject=false
                ;;
        esac
  
    else
        echo "Project $name doesn't exist."
        read -p "Setup new project for $name? (wp, html, or no): " create
        case $create in
            'wp')
                echo "Setting up WordPress project for $name..."
                SetupWP
                ;;
            'html')
                echo "Setting up HTML project for $name..."
                SetupHtml
                ;;
            'no') 
                IsSetProject=false
                clear
                ;;
            *)
                echo "Invalid choice. Cancelling."
                ;;
        esac
    fi
}
