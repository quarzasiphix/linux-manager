function n8n_panel() {
    # — if pm2, jq or n8n binary or .env is missing, offer to install+configure —
    missing=()
    for cmd in pm2 jq n8n; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    if [ ${#missing[@]} -gt 0 ] || [ ! -f "$HOME/.n8n/.env" ]; then
        echo
        echo "n8n dependencies/config missing: ${missing[*]}"
        read -p "Install and configure n8n now? (y/n): " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            setup_n8n_env
        fi
        return
    fi

    ProjectBanner
    echo
    echo "====== n8n MANAGEMENT PANEL ======"
    echo

    # ensure logs dir for nginx exists
    sudo mkdir -p /var/www/logs/n8n
    sudo touch /var/www/logs/n8n/{error.nginx,access.nginx}
    sudo chown -R quarza:www-data /var/www/logs/n8n
    sudo chmod -R 755 /var/www/logs/n8n

    # show pm2 status
    n8n_status=$(pm2 jlist | jq -r '.[] | select(.name=="n8n") | .pm2_env.status')
    case "$n8n_status" in
        online)  echo -e "n8n status: \e[32mONLINE\e[0m" ;;
        stopped) echo -e "n8n status: \e[33mSTOPPED\e[0m" ;;
        errored) echo -e "n8n status: \e[31mERRORED\e[0m" ;;
        "")       echo -e "n8n status: \e[31mNOT RUNNING\e[0m" ;;
        *)        echo -e "n8n status: \e[31mUNKNOWN ($n8n_status)\e[0m" ;;
    esac
    echo
    echo "1) Start n8n"
    echo "2) Stop n8n"
    echo "3) Restart n8n"
    echo "4) Show n8n log"
    echo "5) Show n8n status"
    echo "0) Return to main menu"
    echo
    read -p "Choose an option: " n8n_opt
    case "$n8n_opt" in
        1)
            clear
            echo "Starting n8n…"
            [ ! -f "$HOME/.n8n/ecosystem.config.js" ] && generate_n8n_ecosystem
            pm2 start "$HOME/.n8n/ecosystem.config.js"
            ;;
        2)
            clear
            echo "Stopping n8n…"
            pm2 stop n8n
            ;;
        3)
            clear
            echo "Restarting n8n…"
            pm2 restart n8n
            ;;
        4)
            clear
            echo "Press Enter to exit logs…"
            (pm2 logs n8n &); read; pkill -f "pm2 logs n8n"
            ;;
        5)
            clear
            pm2 status n8n
            read -p "Enter to continue…"
            ;;
        0)
            clear
            IsSetProject="false"
            ;;
        *)
            clear
            echo "Invalid option"
            ;;
    esac
}

generate_n8n_ecosystem() {
    local envfile="$HOME/.n8n/.env"
    local ecofile="$HOME/.n8n/ecosystem.config.js"

    # Ensure .env exists
    if [ ! -f "$envfile" ]; then
        echo "No $envfile found. Please create your n8n .env file first."
        return 1
    fi

    # Start writing the ecosystem file
    cat > "$ecofile" <<EOF
module.exports = {
  apps : [{
    name: "n8n",
    script: "n8n",
    env: {
EOF

    # Add all non-comment, non-empty lines from .env as JS env vars
    grep -v '^#' "$envfile" | grep -v '^\s*$' | while IFS='=' read -r key value; do
        # Escape double quotes in value
        value_escaped=$(echo "$value" | sed 's/"/\\"/g')
        echo "      $key: \"$value_escaped\"," >> "$ecofile"
    done

    # Close the JS object
    cat >> "$ecofile" <<EOF
    }
  }]
}
EOF

    echo "n8n PM2 ecosystem file created at $ecofile"
}

# -----------------------------------------------------------------------------
# Run on first‐time or when pm2/jq/.env is missing
setup_n8n_env() {
    echo
    echo "----- n8n Initial Setup -----"
    read -p "Enter your public domain for n8n (e.g. n8n.example.com): " N8N_DOMAIN
    mkdir -p "$HOME/.n8n"

    # 1) Write .env with full webhook + editor URLs
    cat > "$HOME/.n8n/.env" <<EOF
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=https
WEBHOOK_URL=https://$N8N_DOMAIN/
WEBHOOK_TUNNEL_URL=https://$N8N_DOMAIN/
N8N_EDITOR_BASE_URL=https://$N8N_DOMAIN/
VUE_APP_URL_BASE_API=https://$N8N_DOMAIN/
EOF

    # 2) Install prerequisites
    echo "Installing Node.js, npm, jq, pm2 and n8n…"
    sudo apt update
    sudo apt install -y nodejs npm jq
    npm install -g n8n pm2

    # 3) Generate PM2 ecosystem
    generate_n8n_ecosystem

    # 4) Create nginx vhost for n8n
    sudo mkdir -p /var/www/logs/n8n
    sudo touch /var/www/logs/n8n/{error.nginx,access.nginx}
    sudo chown -R quarza:www-data /var/www/logs/n8n
    sudo chmod -R 755 /var/www/logs/n8n
    nginx_conf="/etc/nginx/sites-available/n8n.nginx"
    sudo tee "$nginx_conf" > /dev/null <<EOT
server {
    listen 80;
    server_name $N8N_DOMAIN;

    error_log  /var/www/logs/n8n/error.nginx;
    access_log /var/www/logs/n8n/access.nginx;

    location / {
        proxy_pass http://localhost:5678;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOT
    sudo ln -sf "$nginx_conf" /etc/nginx/sites-enabled/n8n.nginx
    sudo systemctl reload nginx

    echo
    echo "✅  n8n setup complete. You can now select 'Start n8n' in the panel."
    echo
} 



