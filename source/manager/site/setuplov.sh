SetupLov() {
    # Prompt for the Git repository URL
    read -p "Enter Git repository URL: " git_url
    if [ -z "$git_url" ]; then
        echo "No Git URL provided. Exiting."
        return 1
    fi

    # Define directories: clone into /var/www/sites/sources/<project name>
    # and deploy the build into /var/www/sites/<project name>
    source_dir="/var/www/sites/sources/$name"
    project_dir="/var/www/sites/$name"
    git_url_file="$source_dir/.giturl"

    # Create the necessary directories
    sudo mkdir -p "$source_dir" "$project_dir"

    # Clone the repository into the source directory
    echo "Cloning repository from $git_url..."
    git clone "$git_url" "$source_dir" || { echo "Git clone failed."; return 1; }
    
    # Save the Git URL for future updates
    echo "$git_url" | sudo tee "$git_url_file" > /dev/null

    # Change into the source directory
    cd "$source_dir" || { echo "Cannot change directory to $source_dir."; return 1; }

    # Install npm dependencies
    echo "Installing npm dependencies..."
    npm install || { echo "npm install failed."; return 1; }

    # Build the React project (assumes a 'build' script is defined in package.json)
    echo "Building the React project..."
    npm run build || { echo "Build failed."; return 1; }

    # Deploy the compiled build files (typically in the "build" folder) to the project directory
    echo "Deploying build files to project directory..."
    sudo cp -R "$source_dir/build/"* "$project_dir/" || { echo "Failed to deploy build files."; return 1; }

    # Set up the domain and Nginx configuration
    read -p "Enter domain for the project (e.g., example.com): " domain
    log_dir="/var/www/logs/$name"
    sudo mkdir -p "$log_dir"

    nginx_config="/etc/nginx/sites-available/$name.nginx"
    sudo tee "$nginx_config" > /dev/null <<EOT
server {
    listen 80;
    server_name $domain www.$domain;
    root $project_dir;
    index index.html;

    error_page 404 /index.html;
    error_log $log_dir/error.nginx;
    access_log $log_dir/access.nginx;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOT

    # Enable the Nginx site and set permissions
    sudo ln -s "$nginx_config" "/etc/nginx/sites-enabled/$name.nginx"
    sudo chown -R www-data:www-data "$project_dir"
    sudo chmod -R 755 "$project_dir"
    sudo systemctl restart nginx

    echo "Project $name set up successfully using the lov method."
}

UpdateLov() {
    source_dir="/var/www/sites/sources/$name"
    project_dir="/var/www/sites/$name"
    git_url_file="$source_dir/.giturl"

    if [ ! -d "$source_dir" ]; then
        echo "Source directory $source_dir does not exist. Cannot update."
        return 1
    fi

    if [ ! -f "$git_url_file" ]; then
        echo "Git URL file not found. Please reinitialize the Lov project."
        return 1
    fi

    git_url=$(cat "$git_url_file")

    cd "$source_dir" || { echo "Failed to change directory to $source_dir."; return 1; }

    echo "Pulling latest changes from repository ($git_url)..."
    if ! git pull; then
        echo "Git pull failed. The stored Git URL ($git_url) might be invalid."
        read -p "Enter new Git repository URL: " new_url
        if [ -z "$new_url" ]; then
            echo "No new URL provided. Aborting update."
            return 1
        fi
        git remote set-url origin "$new_url"
        echo "$new_url" | sudo tee "$git_url_file" > /dev/null
        git pull || { echo "Git pull failed even after updating remote URL."; return 1; }
    fi

    echo "Installing npm dependencies..."
    npm install || { echo "npm install failed."; return 1; }

    echo "Building the React project..."
    npm run build || { echo "Build failed."; return 1; }

    echo "Deploying updated build to $project_dir..."
    sudo rm -rf "$project_dir"/*
    sudo cp -R "$source_dir/build/"* "$project_dir/" || { echo "Failed to deploy build files."; return 1; }

    sudo chown -R www-data:www-data "$project_dir"
    sudo chmod -R 755 "$project_dir"

    echo "Project $name updated successfully."
}
