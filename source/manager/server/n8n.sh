n8n_panel() {
    ProjectBanner
    echo
    echo "====== n8n MANAGEMENT PANEL ======"
    echo

    # Get n8n status from pm2 using jq for robust parsing
    n8n_status=$(pm2 jlist | jq -r '.[] | select(.name=="n8n") | .pm2_env.status')
    if [[ "$n8n_status" == "online" ]]; then
        echo -e "n8n status: \e[32mONLINE\e[0m"
    elif [[ "$n8n_status" == "stopped" ]]; then
        echo -e "n8n status: \e[33mSTOPPED\e[0m"
    elif [[ "$n8n_status" == "errored" ]]; then
        echo -e "n8n status: \e[31mERRORED\e[0m"
    elif [[ -z "$n8n_status" ]]; then
        echo -e "n8n status: \e[31mNOT RUNNING\e[0m"
    else
        echo -e "n8n status: \e[31mUNKNOWN ($n8n_status)\e[0m"
    fi
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
            echo "Starting n8n with pm2..."
            if [ ! -f "$HOME/.n8n/ecosystem.config.js" ]; then
                echo "ecosystem.config.js not found, generating..."
                generate_n8n_ecosystem
            fi
            pm2 start "$HOME/.n8n/ecosystem.config.js"
            ;;
        2)
            clear
            echo "Stopping n8n..."
            pm2 stop n8n
            ;;
        3)
            clear
            echo "Restarting n8n..."
            pm2 restart n8n
            ;;
        4)
            clear
            echo "Showing live n8n log. Press Enter to return to the menu..."
            (pm2 logs n8n &)
            read -p ""
            pkill -f "pm2 logs n8n"
            ;;
        5)
            clear
            echo
            pm2 status n8n
            echo
            read -p "Press Enter to continue..." dummy
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

# After installing n8n and pm2
generate_n8n_ecosystem 