# --- Safety Panel Functions ---

# Fix permissions for all sites
FixAllPrivileges() {
    echo
    echo "Fixing permissions for all /var/www directories..."

    # Set correct perms for top-level dirs
    sudo chown -R quarza:quarza /var/www/backups
    sudo chmod -R 700 /var/www/backups

    sudo chown -R quarza:quarza /var/www/libs
    sudo chmod -R 700 /var/www/libs

    sudo chown -R quarza:quarza /var/www/scripts
    sudo chmod -R 700 /var/www/scripts

    sudo chown -R quarza:quarza /var/www/server
    sudo chmod -R 700 /var/www/server

    sudo chown -R quarza:quarza /var/www/admin
    sudo chmod -R 700 /var/www/admin

    sudo chown -R quarza:quarza /var/www/disabled
    sudo chmod -R 700 /var/www/disabled

    sudo chown -R quarza:quarza /var/www/logs
    sudo chmod -R 750 /var/www/logs
    sudo chown quarza:www-data /var/www/logs/manager.log
    sudo chmod 640 /var/www/logs/manager.log

    # Sites and sources should be quarza:www-data
    sudo chown -R quarza:www-data /var/www/sites
    sudo chmod 755 /var/www/sites

    sudo chown -R quarza:www-data /var/www/sources 2>/dev/null || true
    sudo chmod 755 /var/www/sources 2>/dev/null || true

    # Now recursively fix each site
    for site in /var/www/sites/*; do
        [ -d "$site" ] || [ -L "$site" ] || continue

        # If it's a symlink (lovable project)
        if [ -L "$site" ]; then
            target=$(readlink -f "$site")
            # Set permissions on all parent dirs up to dist (Vite) or build (CRA)
            parent_dir=$(dirname "$target")
            sudo chown -R quarza:www-data "$parent_dir"
            sudo chmod 755 "$parent_dir"
            sudo chown -R quarza:www-data "$target"
            sudo find "$target" -type d -exec chmod 755 {} \;
            sudo find "$target" -type f -exec chmod 644 {} \;
            sudo chown -h quarza:www-data "$site"
            echo "  -> $site (Lovable/Node/React project symlink)"
        # Detect WordPress by presence of wp-config.php, wp-includes, or wp-admin
        elif [[ -f "$site/wp-config.php" || -d "$site/wp-includes" || -d "$site/wp-admin" ]]; then
            echo "  -> $site (WordPress)"
            FixWordPressPrivileges "$site"
        else
            echo "  -> $site (HTML/Other)"
            sudo chown -R quarza:www-data "$site"
            sudo find "$site" -type d -exec chmod 755 {} \;
            sudo find "$site" -type f -exec chmod 644 {} \;
        fi
    done

    echo "All /var/www permissions fixed."
}

# Fix permissions for a WordPress site
FixWordPressPrivileges() {
    local dir="$1"
    sudo chown -R quarza:www-data "$dir"
    sudo find "$dir" -type d -exec chmod 755 {} \;
    sudo find "$dir" -type f -exec chmod 644 {} \;
    # Secure config
    [ -f "$dir/wp-config.php" ] && sudo chmod 640 "$dir/wp-config.php"
    # wp-content and uploads
    [ -d "$dir/wp-content" ] && sudo chmod 755 "$dir/wp-content"
    [ -d "$dir/wp-content/uploads" ] && sudo chmod 755 "$dir/wp-content/uploads"
    [ -d "$dir/wp-content/uploads" ] && sudo find "$dir/wp-content/uploads" -type d -exec chmod 755 {} \;
    [ -d "$dir/wp-content/uploads" ] && sudo find "$dir/wp-content/uploads" -type f -exec chmod 644 {} \;
    echo "    Fixed WordPress permissions for $dir"
}

# Basic malware scan (look for suspicious PHP files, world-writable, etc.)
MalwareScan() {
    echo
    echo "Scanning for suspicious PHP files in /var/www/sites/ ..."
    sudo find /var/www/sites/ -type f -name "*.php" -exec grep -l -E "(eval\(|base64_decode\(|gzinflate\()" {} \; | tee /tmp/suspicious_php.txt
    echo
    echo "Scanning for world-writable files ..."
    sudo find /var/www/sites/ -type f -perm -o+w | tee /tmp/world_writable.txt
    echo
    echo "Scanning for hidden files ..."
    sudo find /var/www/sites/ -type f -name ".*" | tee /tmp/hidden_files.txt
    echo
    echo "Scan complete. See /tmp/suspicious_php.txt, /tmp/world_writable.txt, /tmp/hidden_files.txt"
}

# Show new files since last scan or a given date
ShowNewFiles() {
    echo
    read -p "Show files created since (YYYY-MM-DD): " since
    echo "New files since $since:"
    sudo find /var/www/sites/ -type f -newermt "$since" | tee /tmp/new_files.txt
    echo "See /tmp/new_files.txt"
}

# Disable all websites
DisableAllWebsites() {
    echo
    echo "Disabling all websites..."
    local enabled_dir="/etc/nginx/sites-enabled"
    local disabled_dir="/etc/nginx/disabled"
    sudo mkdir -p "$disabled_dir"
    local count=0
    for conf in "$enabled_dir"/*.nginx; do
        if [[ -f "$conf" ]]; then
            sudo mv "$conf" "$disabled_dir/"
            echo "  -> Disabled $(basename "$conf")"
            ((count++))
        fi
    done
    sudo systemctl restart nginx
    echo "Disabled $count sites and restarted Nginx."
}

# ClamAV malware scan
ClamAVScan() {
    echo
    echo "Running ClamAV scan on /var/www/sites/ ..."
    sudo clamscan -r --infected /var/www/sites/ | tee /var/www/logs/clamav_scan.log
    echo
    echo "ClamAV scan complete. See /var/www/logs/clamav_scan.log"
}

# Show Fail2ban log
ShowFail2banLog() {
    echo
    echo "==== Fail2ban Log (last 50 lines) ===="
    sudo tail -n 50 /var/log/fail2ban.log
    echo "======================================"
}

# Show ClamAV scan log
ShowClamAVLog() {
    echo
    echo "==== ClamAV Scan Log (last 50 lines) ===="
    sudo tail -n 50 /var/www/logs/clamav_scan.log
    echo "========================================="
}

# --- Ensure every active site has a cert, or generate one ---
CheckSSL() {
  echo
  echo "🔍 Checking SSL for active sites..."
  for conf in /etc/nginx/sites-enabled/*.nginx; do
    domain=$(grep -oP 'server_name\s+\K[^;]+' "$conf")
    if [ -z "$domain" ]; then continue; fi
    if [ -d "/etc/letsencrypt/live/$domain" ]; then
      echo "✅ $domain"
    else
      echo "❌ No cert for $domain → obtaining..."
      email=$(get_certbot_email)
      sudo certbot --nginx --non-interactive --agree-tos \
        --email "$email" --redirect -d "$domain"
    fi
  done
  echo "Done."
  read -p "Press Enter to continue…"
}

# Main Safety Panel Menu
SafetyPanel() {
    clear
    ProjectBanner
    echo
    echo
    echo "====== SAFETY PANEL ======"
    echo
    echo "1) Malware scan"
    echo "2) Show new files since date"
    echo "3) Fix all privileges"
    echo "4) Show world-writable files"
    echo "5) Disable ALL websites"
    echo "6) ClamAV malware scan"
    echo "7) Show Fail2ban log"
    echo "8) Show ClamAV scan log"
    echo "9) Check SSL certificates"
    echo "10) Back"
    echo "=========================="
    read -p "Choose an option: " opt
    case "$opt" in
        1) MalwareScan; read -p "Press Enter to continue..." ;;
        2) ShowNewFiles; read -p "Press Enter to continue..." ;;
        3) FixAllPrivileges; read -p "Press Enter to continue..." ;;
        4) sudo find /var/www/sites/ -type f -perm -o+w | tee /tmp/world_writable.txt; read -p "Press Enter to continue..." ;;
        5) DisableAllWebsites; read -p "Press Enter to continue..." ;;
        6) ClamAVScan; read -p "Press Enter to continue..." ;;
        7) ShowFail2banLog; read -p "Press Enter to continue..." ;;
        8) ShowClamAVLog; read -p "Press Enter to continue..." ;;
        9) CheckSSL; read -p "Press Enter to continue..." ;;
        10)             
            clear
            IsSetProject="false"
            ;; 
        *) echo "Invalid option"; sleep 1 ;;
    esac
} 