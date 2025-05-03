n8n_panel() {
    clear
    ProjectBanner
    echo
    echo "====== n8n MANAGEMENT PANEL ======"
    echo

    # Check n8n status via pm2
    if pm2 list | grep -q -w n8n; then
        echo -e "n8n status: \e[32mRUNNING\e[0m"
    else
        echo -e "n8n status: \e[31mSTOPPED\e[0m"
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
            echo "Starting n8n with pm2..."
            export $(grep -v '^#' ~/.n8n/.env | xargs)
            pm2 start n8n --name n8n --time
            ;;
        2)
            echo "Stopping n8n..."
            pm2 stop n8n
            ;;
        3)
            echo "Restarting n8n..."
            pm2 restart n8n
            ;;
        4)
            echo "Showing n8n log (press Ctrl+C to exit)..."
            pm2 logs n8n
            ;;
        5)
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
            echo "Invalid option"
            ;;
    esac
} 