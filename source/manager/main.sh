#!/bin/bash

dir="/var/www/scripts/manager"

. $dir/menus.sh

. $dir/server/stuff.sh
. $dir/site/manage.sh

nginxconfdir="/etc/nginx/sites-enabled"
nginxdisabled="/etc/nginx/disabled"

# project info
currentdomain=
IsSetProject=false

#!/bin/bash
latest_version=$(curl -s "https://raw.githubusercontent.com/quarzasiphix/linux-manager/master/source/version.txt")
current_version=$(cat version.txt)

ProjectBanner() {
    server_name=$(</var/www/server/name.txt)
    server_location=$(</var/www/server/info.txt)

    if [[ "$current_version" != "$latest_version" ]]; then
        echo -e "   \e[38;5;208mUpdate availabile!\e[0m"
        echo -e "   Current version: \e[38;5;208m$current_version \e[0m => \e[32m$latest_version\e[0m"
    else
        echo -e "   Up to date"
        echo -e "   Current version: \e[32m$current_version\e[0m"
    fi
    echo
    echo    "   Server: $server_name!"
    echo    "   at: $server_location!"
    echo
    echo -e "    :Welcome \e[36m$USER\e[0m!!!"
    echo -e "to the\e[38m project management tool! \e[0m"
    echo
}

main () {
    clear
    while true; do
        while [ "$IsSetProject" == "false" ]; do 
        general
        done

        while [ "$IsSetProject" == "true" ]; do
        managesite
        done

        while [ "$IsSetProject" == "conf" ]; do 
        configurator
        done
    done
}

main 