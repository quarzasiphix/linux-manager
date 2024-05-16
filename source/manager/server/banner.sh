banner() {
    clear
    server_name=$(</var/www/server/name.txt)

    # Read server location from the file
    server_location=$(</var/www/server/info.txt)

    echo
    echo    "  =================================== "
    echo
    echo -e "             Hello\e[36m \$USER \e[0m"
    echo
    echo -e "         Welcome\e[95m to Web wiz \e[0m"
    echo
    echo    "   Server: $server_name!"
    echo    "   at: $server_location!"
    echo
    echo    "  =================================== "
    echo
    echo
    echo

}