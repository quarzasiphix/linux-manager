SetupLov() {
    # Prompt for the Git repository URL
    read -p "Enter Git repository URL: " git_url
    if [ -z "$git_url" ]; then
        echo "No Git URL provided. Exiting."
        return 1
    fi

    # Define directories: clone into /var/www/sites/sources/<project_name>
    # and deploy the build into /var/www/sites/<project_name>
    source_dir="/var/www/sites/sources/$name"
    project_dir="/var/www/sites/$name"

    # Create the necessary directories
    sudo mkdir -p "$source_dir" "$project_dir"

    # Clone the repository into the source directory
    echo "Cloning repository from $git_url..."
    git clone "$git_url" "$source_dir" || { echo "Git clone failed."; return 1; }

    # Change into the source directory
    cd "$source_dir" || { echo "Cannot change directory to $source_dir."; return 1; }

    # Install npm dependencies
    echo "Installing npm dependencies..."
    npm install || { echo "npm install failed."; return 1; }

    # Build the React project (assumes 'build' script is defined in package.json)
    echo "Building the React project..."
    npm run build || { echo "Build failed."; return 1; }

    # Copy the compiled build files (typically in the "build" folder) to the project directory
    echo "Deploying build files to project directory..."
    sudo cp -R "$source_dir/build/"* "$project_dir/" || { echo "Failed to deploy build files."; return 1; }

    echo "Project $name set up successfully using the lov method."
}
