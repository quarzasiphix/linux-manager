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


managesite() {
    clear
    ProjectBanner
    echo
    echo "  Project: $name"
    echo
    echo
     
    # Determine project type for menu display
    local project_type="unknown"
    if [[ -d "/var/www/sources/$name" ]]; then
        project_type="lovable"
    elif [[ -f "/var/www/sites/$name/wp-config.php" ]]; then
        project_type="wordpress"
    elif [[ -d "/var/www/sites/$name" ]]; then # Check this after WP/Lovable
        project_type="html"
    fi

    # Check if the Nginx config exists in either enabled or disabled
    local nginx_conf_exists=false
    if [[ -f "$nginxconfdir/$name.nginx" || -f "$nginxdisabled/$name.nginx" ]]; then
        nginx_conf_exists=true
    fi

    # Only show management menu if project files/source exist OR nginx config exists
    if [[ "$project_type" != "unknown" || "$nginx_conf_exists" == true ]]; then
        echo
        if [ -f "$nginxconfdir/$name.nginx" ]; then
            # Print "Site Enabled" in green
            echo -e " :Site \e[32m Enabled\e[0m:"
        elif [ -f "$nginxdisabled/$name.nginx" ]; then
            # Print "Site Disabled" in red
            echo -e " :Site \e[31m Disabled\e[0m:"
        fi
        echo
        
        #if is_debug_enabled; then
        #    echo "  \033[38;5;214mDEBUG ENABLED\033[0m"
        #else
        #    echo "Debug Disabled1"
        #fi
        
        echo
        echo "Current domain: $currentdomain" 
        echo
        echo "What would you like to do to $name?"
        echo
        echo "0 - Change project"
        # Enable/Disable toggle logic
        if [ -f "$nginxconfdir/$name.nginx" ]; then
            echo -e "5) \e[31mDisable\e[0m site"
        elif [ -f "$nginxdisabled/$name.nginx" ]; then
            echo -e "5) \e[32mEnable\e[0m site"
        else
            echo "  (Site Nginx config missing - cannot Enable/Disable)"
        fi


        echo
        echo "2 - Backup create"
        echo "3 - Restore"
        echo
        # Show type-specific menu options
        echo "E/e - Edit General Configs (Domain, Nginx)"
        case $project_type in
            lovable)
                echo "L/l - Lovable Project Management (Update, etc.)"
                ;;
            wordpress)
                echo "W/w - WordPress Management (WP-CLI, etc.)"
                ;;
            html)
                echo "S/s - Script Management (HTML)"
                ;;
            *)
                # Maybe show generic options if type is unknown but config exists?
                echo "  (Project type unknown)"
                ;;
        esac
        echo "A/a - Analytics"
        echo

        echo "del - Delete project"
        echo "res - Reset project"
        echo "r - Return to main menu"  # Return option
        echo
        echo
        read -p "Enter your choice (0-X, r): " choice

        case $choice in
            0)
                clear
                echo "Changing project..."
                IsSetProject=false
                SetProject
                ;;
            2)
                clear
                echo "Creating backup..."
                CreateBackup
                ;;
            3)
                clear
                echo "Restoring backup..."
                RestoreBackup
                ;;
            E|e)
                clear
                echo "Editing site configurations..."
                EditSiteConfig
                ;;
            L|l)
                 if [[ "$project_type" == "lovable" ]]; then
                    clear
                    echo "Lovable project management..."
                    LovableOptions
                else
                    echo "Not a Lovable project."; sleep 1
                fi
                ;;
            S|s)
                 if [[ "$project_type" == "html" ]]; then
                    clear
                    echo "Script management..."
                    ScriptManagement
                else
                    echo "Not an HTML project (or type detection failed). Maybe try Edit Configs (E)?"; sleep 2
                fi
                ;;
            A|a)
                clear
                echo "Analytics options..."
                AnalyticsOptions
                ;;
            W|w)
                if [[ "$project_type" == "wordpress" ]]; then
                    clear
                    echo "WordPress management..."
                    WordPressOptions
                else
                    echo "Not a WordPress project."; sleep 1
                fi
                ;;
            'del')
                clear
                echo "Deleting project..."
                DeleteProject
                ;;
            'res')
                clear
                echo "Resetting project..."
                ResetProject
                ;;
            r|R)  # Return option
                clear
                echo "Returning to main menu..."
                IsSetProject=false
                ;;
            5) # Enable/Disable Toggle
                clear
                if [ -f "$nginxconfdir/$name.nginx" ]; then
                    echo "Disabling site..."
                    DisableConf
                elif [ -f "$nginxdisabled/$name.nginx" ]; then
                    echo "Enabling site..."
                    EnableConf
                else
                    echo "Cannot determine state (config missing from both enabled and disabled)."
                    sleep 2
                fi
                ;;
            *)
                echo "Invalid choice, please try again."
                ;;
        esac

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
        echo "lov. Setup lovable (node build) project"
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
            clear
            ProjectBanner
            echo
            echo "setting up html project for $name"
            echo
            SetupHtml
            echo
            echo "Done configuring html project for $name"
            echo
            ;;
        'lov')
            clear
            ProjectBanner
            echo
            echo "setting up lovable project for $name"
            echo
            echo
            SetupLov
            ;;
        'no')
            clear
            IsSetProject=false
            ;;
    esac
  
    else
        echo 
        echo "project $name doesnt exist, and no backups found."
        echo
        echo
        echo "wp. Wordpress project"
        echo "html. Blank html project"
        echo "lov. Setup a lovable project from git" 
        echo "no or 0 to exit"
        echo
        read -p "setup new project for $name? "
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
            'lov')
                echo "setting up lovable project.."
                SetupLov
                ;;
            'no' | 0) 
                IsSetProject=false
                clear
                ;;
            *)
                echo "Invalid choice. cancelling"
            ;;
        esac
    fi
}

EditSiteConfig() {
    clear
    ProjectBanner
    echo "Project: $name"
    echo
    echo "Edititing project $name"
    echo
    echo "1 - Change domain"
    echo "2 - Edit nginx config"
    echo "3 - Edit index.html"
    echo "4 - Edit wp-config.php (WordPress only)"
    echo "5 - Update lov project"
    echo "0 - Return to previous menu"  # Return option
    echo
    echo
    echo "r - Return to previous menu"  # Return option
    echo
    read -p "Select your choice (1-2, r): " editChoice
    case $editChoice in
        1)
            echo "Changing domain..."
            ChangeDomain
            ;;
        2)
            echo "Editing nginx config..."
            EditNginxConfig
            ;;
        3)
            echo "Editing index.html..."
            EditIndexHtml
            ;;
        4)
            echo "Editing wp-config.php..."
            EditWpConfig
            ;;
        5)
            echo "Updating lov project"
            UpdateLov
            ;;
        r|R)  # Return option
            clear
            echo "Returning to the manage site menu..."
            managesite  # Calls the main menu again
            ;;
        *)
            echo "Invalid choice."
            ;;
    esac
}


AnalyticsOptions() {
    clear
    ProjectBanner
    echo "Project: $name"
    echo
    echo "1 - Start Go access for project $name"
    echo "2 - Show weight of source files"
    echo
    echo
    echo "r - Return to previous menu"  # Return option
    echo
    read -p "Select your choice (1-2, r): " editChoice
    case $editChoice in
        1)
            echo "Starting script"
            StartHTMLScript
            ;;
        2)
            echo "Editing nginx config..."
            EditNginxConfig
            ;;
        3)
            echo "Editing index.html..."
            EditIndexHtml
            ;;
        4)
            echo "Editing wp-config.php..."
            EditWpConfig
            ;;
        0)  # Return option
            clear
            echo "Returning to the manage site menu..."
            managesite  # Calls the main menu again
            ;;
        *)
            echo "Invalid choice."
            ;;
    esac
}



WordPressOptions() {
    clear
    ProjectBanner
    echo "Project: $name"
    echo
    echo "0 - Return to previous menu"  # Return option
    echo "1 - debug mode (not finished)"
    echo "2 - update elementor"
    echo "3 - wp-cli (not finished)"
    echo
    echo
    echo "r - Return to previous menu"  # Return option
    echo
    read -p "Select your choice (1-3, r): " editChoice
    case $editChoice in
        1)
            echo "toggling debug"
            ;;
        2)
            echo "Updating elementor..."
            UpdateElementor
            ;;
        3)
            echo "Editing index.html..."
            EditIndexHtml
            ;;
        4)
            echo "Editing wp-config.php..."
            EditWpConfig
            ;;
        0)  # Return option
            clear
            echo "Returning to the manage site menu..."
            managesite  # Calls the main menu again
            ;;
        *)
            echo "Invalid choice."
            ;;
    esac
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

ScriptManagement() {
    clear
    ProjectBanner
    echo "Project: $name"
    echo
    echo "0 - Return to previous menu"  # Return option
    echo "1 - Start Script"
    echo "2 - Status of script"
    echo "3 - Stop script"
    echo "4 - Edit script"
    echo
    echo
    echo "r - Return to previous menu"  # Return option
    echo
    read -p "Select your choice (1-4, r): " editChoice
    case $editChoice in
        1)
            echo "Starting script"
            StartHTMLScript
            ;;
        2)
            echo "Editing nginx config..."
            EditNginxConfig
            ;;
        3)
            echo "Editing index.html..."
            EditIndexHtml
            ;;
        4)
            echo "Editing wp-config.php..."
            EditWpConfig
            ;;
        0)  # Return option
            clear
            echo "Returning to the manage site menu..."
            managesite  # Calls the main menu again
            ;;
        *)
            echo "Invalid choice."
            ;;
    esac
}

LovableOptions() {
    clear
    ProjectBanner
    echo "Project: $name (Lovable)"
    echo
    echo "Lovable Project Options:"
    echo
    echo "1 - Update Project (Git Pull + Build)"
    echo "2 - Change domain (calls existing function)"
    echo "3 - Edit Nginx Config (calls existing function)"
    echo "4 - Delete Project (calls existing function)"
    echo "0 / r - Return to Manage Site Menu"
    echo
    read -p "Select your choice: " lovChoice

    local SRC_DIR="/var/www/sources/$name"
    local DIST_DIR="$SRC_DIR/dist"

    case $lovChoice in
        1)
            clear
            echo "Updating project $name..."
            UpdateLov
            read -p "Press Enter to continue..." ;;
        2)
            echo "Changing domain..."
            ChangeDomain # Assuming ChangeDomain function exists and works
            ;;
        3)
            echo "Editing Nginx config..."
            EditNginxConfig # Assuming EditNginxConfig function exists and works
            ;;
        4)
            echo "Deleting project..."
            DeleteProject # Assuming DeleteProject function exists and works
            ;;
        0|r|R)
            clear
            echo "Returning to Manage Site menu..."
            # No need to call managesite here, the loop will continue
            ;;
        *)
            echo "Invalid choice."
            sleep 1
            ;;
    esac
    # Call recursively to show menu again unless returning
    if [[ "$lovChoice" != "0" && "$lovChoice" != "r" && "$lovChoice" != "R" ]]; then
        LovableOptions
    fi
}
