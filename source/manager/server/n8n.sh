n8n_panel() {
    ProjectBanner
    echo
    echo "====== n8n MANAGEMENT PANEL ======"
    echo

    # Get n8n status from pm2
    n8n_status=$(pm2 info n8n 2>/dev/null | awk -F': ' '/status/ {print $2}' | head -n1)
    if [[ "$n8n_status" == "online" ]]; then
        echo -e "n8n status: \e[32mONLINE\e[0m"
    elif [[ "$n8n_status" == "stopped" ]]; then
        echo -e "n8n status: \e[33mSTOPPED\e[0m"
    elif [[ "$n8n_status" == "errored" ]]; then
        echo -e "n8n status: \e[31mERRORED\e[0m"
    else
        echo -e "n8n status: \e[31mNOT RUNNING\e[0m"
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
            export $(grep -v '^#' ~/.n8n/.env | xargs)
            pm2 start n8n --name n8n --time
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
            echo "Showing n8n log (press Ctrl+C to exit)..."
            pm2 logs n8n
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