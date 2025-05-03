SetupLov() {
    # Args & derived paths
    # local REPO_URL # REPO_URL is now expected to be set by the caller (general.sh)
    local NAME=$name # Use the project name set by the caller (derived from URL)
    local DOMAIN
    local SRC_ROOT="/var/www/sources" # Changed from /var/www/sites/sources
    local PROJ_DIR="$SRC_ROOT/$NAME"
    local DIST_DIR="$PROJ_DIR/dist" # Standard build output dir
    local BUILD_DIR="$PROJ_DIR/build"
    local SITE_LINK="/var/www/sites/$NAME"

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
    # REMOVED: sudo chown -R quarza:www-data "$PROJ_DIR" # Don't change ownership yet

    # 3. Build
    echo "📦  Installing dependencies…"
    # Run npm commands in a subshell to avoid changing the script's directory
    ( cd "$PROJ_DIR" && { 
        if [[ -f package-lock.json ]]; then 
            echo "(Using npm ci --verbose)"
            sudo npm ci --prefix "$PROJ_DIR" --verbose || { echo "❌ npm ci failed"; exit 1; } 
        else 
            echo "(Using npm install --verbose)"
            sudo npm install --prefix "$PROJ_DIR" --verbose || { echo "❌ npm install failed"; exit 1; }
        fi; 
      } ) || return 1 # Propagate failure from subshell

    echo "🔨  Running build…"
    ( cd "$PROJ_DIR" && sudo npm run build --prefix "$PROJ_DIR" ) || { echo "❌ npm run build failed"; return 1; }
    # Chown the DIST dir AFTER build is successful
    echo "🔒 Setting permissions for $DIST_DIR..."
    sudo chown -R quarza:www-data "$DIST_DIR" # Ensure web server owns build output
    sudo chmod -R 755 "$DIST_DIR"
    sudo find "$DIST_DIR" -type f -exec chmod 644 {} \;

    # 4. Nginx reload/restart
    echo "🔄 Reloading Nginx configuration..."
    sudo systemctl restart nginx || { echo "❌ Nginx restart failed"; return 1; }

    echo -e "\n✅ Lovable site '$NAME' setup complete!"
    echo "   Source: $PROJ_DIR"
    echo "   Built : $DIST_DIR"
    [[ -f "$NGX_CONF" ]] && echo "   Vhost : $NGX_CONF"
    echo "   Domain: ${current_domain:-$DOMAIN}" # Show the domain used

    # Set ownership for web server access if needed (adjust if build dir is different) - MOVED earlier, after build.
    # sudo chown -R quarza:www-data "$DIST_DIR"
    # sudo chmod -R 755 "$DIST_DIR"

    # Remove old site and symlink new build
    sudo rm -rf "$SITE_LINK"
    sudo ln -s "$BUILD_DIR" "$SITE_LINK"
    sudo chown -h quarza:www-data "$SITE_LINK"

    # Set permissions for build output
    sudo chown -R quarza:www-data "$BUILD_DIR"
    sudo find "$BUILD_DIR" -type d -exec chmod 755 {} \;
    sudo find "$BUILD_DIR" -type f -exec chmod 644 {} \;

    # After setup, set project as selected and open manager
    IsSetProject=true
    export name="$NAME"
    SetProject
}

UpdateLov() {
    local SRC_ROOT="/var/www/sources"
    local source_dir="$SRC_ROOT/$name"
    local build_dir="$source_dir/build"
    local site_link="/var/www/sites/$name"

    if [ ! -d "$source_dir/.git" ]; then
        echo "Error: $source_dir is not a git repository."
        return 1
    fi

    cd "$source_dir" || { echo "Failed to cd to $source_dir"; return 1; }

    echo "Pulling latest changes from git..."
    if ! git pull; then
        echo "Git pull failed. Please check the remote repository."
        return 1
    fi

    echo "Installing npm dependencies..."
    if [[ -f package-lock.json ]]; then
        sudo npm ci --prefix "$source_dir" --verbose || { echo "npm ci failed."; return 1; }
    else
        sudo npm install --prefix "$source_dir" --verbose || { echo "npm install failed."; return 1; }
    fi

    echo "Building the project..."
    sudo npm run build --prefix "$source_dir" || { echo "Build failed."; return 1; }

    # Update symlink
    echo "Updating symlink in $site_link to point to $build_dir..."
    sudo rm -rf "$site_link"
    sudo ln -s "$build_dir" "$site_link"
    sudo chown -h quarza:www-data "$site_link"

    # Set permissions for build output
    sudo chown -R quarza:www-data "$build_dir"
    sudo find "$build_dir" -type d -exec chmod 755 {} \;
    sudo find "$build_dir" -type f -exec chmod 644 {} \;

    echo "Reloading Nginx configuration..."
    sudo systemctl reload nginx

    echo "Project $name updated and deployed successfully."
}
