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

UpdateLov() {
    source_dir="/var/www/sites/sources/$name"
    project_dir="/var/www/sites/$name"

    # Ensure the source directory exists
    if [ ! -d "$source_dir" ]; then
        echo "Source directory $source_dir does not exist. Cannot update."
        return 1
    fi

    # Change into the source directory
    cd "$source_dir" || { echo "Failed to change directory to $source_dir."; return 1; }

    # Optional: Pull the latest changes from the Git repository
    echo "Pulling latest changes from repository..."
    git pull || { echo "Git pull failed."; return 1; }

    # Install/update npm dependencies
    echo "Installing npm dependencies..."
    npm install || { echo "npm install failed."; return 1; }

    # Build the React project (assumes a 'build' script is defined in package.json)
    echo "Building the React project..."
    npm run build || { echo "Build failed."; return 1; }

    # Deploy the compiled build files to the project directory
    echo "Deploying updated build to $project_dir..."
    sudo rm -rf "$project_dir"/*
    sudo cp -R "$source_dir/build/"* "$project_dir/" || { echo "Failed to deploy build files."; return 1; }

    # Set proper permissions for the deployed files
    sudo chown -R www-data:www-data "$project_dir"
    sudo chmod -R 755 "$project_dir"

    echo "Project $name updated successfully."
}

managesite() {
    clear
    ProjectBanner
    echo
    echo "  Project: $name"
    echo
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
        if [ -f "$nginxconfdir/$name.nginx" ]; then
            echo -e "5) \e[31mDisable\e[0m site"
        elif [ -f "$nginxdisabled/$name.nginx" ]; then
            echo -e "5) \e[32mEnable\e[0m site"
        else
            echo "  :site status unknown:"
        fi


        echo
        echo "2 - Backup create"
        echo "3 - Restore"
        echo

        echo "E/e - Edit files and configs"
        echo "S/s - Script management"
        echo "A/a - Analytics"
        echo "W/w - WordPress management"
        echo
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
            S|s)
                clear
                echo "Managing scripts..."
                ScriptManagement
                ;;
            A|a)
                clear
                echo "Analytics options..."
                AnalyticsOptions
                ;;
            W|w)
                clear
                echo "WordPress management..."
                WordPressOptions
                ;;
            del)
                clear
                echo "Deleting project..."
                DeleteProject
                ;;
            res)
                clear
                echo "Resetting project..."
                ResetProject
                ;;
            r|R)  # Return option
                clear
                echo "Returning to main menu..."
                IsSetProject=false
                ;;
            *)
                echo "Invalid choice, please try again."
                ;;
        esac

        # Site enable/disable logic remains unchanged
        if [ -f "$nginxconfdir/$name.nginx" ]; then
            case $choice in
                1|'disable')
                    clear
                    DisableConf
                    ;;
            esac
        elif [ -f "$nginxdisabled/$name.nginx" ] || [ -f "$nginxconfdir/$name.disabled" ]; then
            case $choice in
                1|'enable')
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
        'no')
            clear
            IsSetProject=false
            ;;
    esac
  
    else
        echo 
        echo "project $name doesnt exist"
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
            'lov' )

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
