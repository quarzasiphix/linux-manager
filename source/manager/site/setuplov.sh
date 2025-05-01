SetupLov() {
    # Args & derived paths
    # local REPO_URL # REPO_URL is now expected to be set by the caller (general.sh)
    local NAME=$name # Use the project name set by the caller (derived from URL)
    local DOMAIN
    local SRC_ROOT="/var/www/sources" # Changed from /var/www/sites/sources
    local PROJ_DIR="$SRC_ROOT/$NAME"
    local DIST_DIR="$PROJ_DIR/dist" # Standard build output dir

    local LOG_DIR="/var/www/logs/$NAME"
    local NGX_AVAIL="/etc/nginx/sites-available"
    local NGX_CONF="$NGX_AVAIL/$NAME.nginx"
    local NGX_ENABLED="/etc/nginx/sites-enabled/$NAME.nginx"
    local first_time=false

    # Check if REPO_URL is actually set by the caller (basic guard)
    if [[ -z "$REPO_URL" ]]; then
        echo "❌ Error: REPO_URL variable not set before calling SetupLov. Exiting."
        return 1
    fi

    # 1. Nginx vhost check / create
    if [[ -f "$NGX_CONF" ]]; then
        current_domain=$(awk '/^\\s*server_name/ {print $2}' "$NGX_CONF" | sed 's/[; ]//g')
        echo "ℹ️  Existing vhost found → $NGX_CONF"
        echo "    server_name: $current_domain (skipping vhost creation)"
    else
        read -rp "Domain for this site (e.g. example.com): " DOMAIN
        [[ -z $DOMAIN ]] && { echo "❌ Domain cannot be empty"; exit 1; }

        sudo mkdir -p "$LOG_DIR"
        sudo tee "$NGX_CONF" >/dev/null <<EOT
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    root $DIST_DIR; # Point Nginx root to the build output directory
    index index.html;

    error_page 404 /index.html;
    error_log  $LOG_DIR/error.nginx;
    access_log $LOG_DIR/access.nginx;

    location / {
        try_files \\\$uri \\\$uri/ =404; # Ensure backslash before $uri is escaped for tee
    }
}
EOT
        # Avoid error if link already exists but file didn't (unlikely scenario, but safe)
        if [ ! -e "$NGX_ENABLED" ]; then
             sudo ln -s "$NGX_CONF" "$NGX_ENABLED"
        fi
        first_time=true
        echo "✅ Nginx config created: $NGX_CONF"
    fi

    # 2. Clone (or update) the repo
    sudo mkdir -p "$SRC_ROOT"
    # Ensure current user can write to SRC_ROOT if needed, but PROJ_DIR will be owned by user running clone
    # sudo chown -R "$USER":"$USER" "$SRC_ROOT"

    if [[ -d "$PROJ_DIR/.git" ]]; then
        echo "⬆️  Updating repo…"
        # Ensure the user running the script can operate git commands - relies on safe.directory for root/other users
        git -C "$PROJ_DIR" fetch --all --prune || { echo "❌ git fetch failed"; return 1; }
        git -C "$PROJ_DIR" pull --ff-only || { echo "❌ git pull failed"; return 1; }
    else
        echo "⬇️  Cloning $REPO_URL → $PROJ_DIR"
        # Clone will be done as the user running the script (likely root if manager started with sudo)
        git clone "$REPO_URL" "$PROJ_DIR" || { echo "❌ git clone failed"; return 1; }
    fi
    # REMOVED: sudo chown -R www-data:www-data "$PROJ_DIR" # Don't change ownership yet

    # 3. Build
    echo "📦  Installing dependencies…"
    # Run npm commands in a subshell to avoid changing the script's directory
    ( cd "$PROJ_DIR" && { 
        if [[ -f package-lock.json ]]; then 
            sudo npm ci --prefix "$PROJ_DIR" || { echo "❌ npm ci failed"; exit 1; } 
        else 
            sudo npm install --prefix "$PROJ_DIR" || { echo "❌ npm install failed"; exit 1; }
        fi; 
      } ) || return 1 # Propagate failure from subshell

    echo "🔨  Running build…"
    ( cd "$PROJ_DIR" && sudo npm run build --prefix "$PROJ_DIR" ) || { echo "❌ npm run build failed"; return 1; }
    # Chown the DIST dir AFTER build is successful
    echo "🔒 Setting permissions for $DIST_DIR..."
    sudo chown -R www-data:www-data "$DIST_DIR" # Ensure web server owns build output
    sudo chmod -R 755 "$DIST_DIR"

    # 4. Nginx reload/restart
    echo "🔄 Reloading Nginx configuration..."
    sudo systemctl restart nginx || { echo "❌ Nginx restart failed"; return 1; }

    echo -e "\n✅ Lovable site '$NAME' setup complete!"
    echo "   Source: $PROJ_DIR"
    echo "   Built : $DIST_DIR"
    [[ -f "$NGX_CONF" ]] && echo "   Vhost : $NGX_CONF"
    echo "   Domain: ${current_domain:-$DOMAIN}" # Show the domain used

    # Set ownership for web server access if needed (adjust if build dir is different) - MOVED earlier, after build.
    # sudo chown -R www-data:www-data "$DIST_DIR"
    # sudo chmod -R 755 "$DIST_DIR"

    echo "Press Enter to continue..."
    read -r
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
