source _common.sh

nginxconfdir="/etc/nginx/sites-enabled"
nginxdisabled="/etc/nginx/disabled"

# project info
currentdomain=

ProjectBanner() {
    server_name=$(</var/www/server/name.txt)
    server_location=$(</var/www/server/info.txt)

    echo
    echo    "   Server: $server_name!"
    echo    "   at: $server_location!"
    echo
    echo -e "    :Welcome \e[36m$USER\e[0m!!!"
    echo -e "to the\e[38m project management tool! \e[0m"
    echo
}

main () {
    
#SetProject
clear
while true; do

    while [ "$IsSetProject" == "false" ]; do 
    general
    done

    while [ "$IsSetProject" == "true" ]; do
    site
    done

    while [ "$IsSetProject" == "conf" ]; do 
    configurator
    done

done
}

main 