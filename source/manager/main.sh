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

#!/bin/bash

# Function to retrieve the current version from the file
get_current_version() {
    # Use cat to read the version from the file
    version=$(cat ../../version.txt)
    echo "$version"
}

# Function to retrieve the latest version from the website
get_latest_version() {
    # Use curl to fetch the plain text content of the website
    latest_version=$(curl -s https://raw.githubusercontent.com/quarzasiphix/linux-manager/master/source/version.txt)

    echo "$latest_version"
}

# Function to check for updates
check_for_update() {
    current_version=$(get_current_version)
    latest_version=$(get_latest_version)

    if [[ "$current_version" != "$latest_version" ]]; then
        echo "There is an update available! Current version: $current_version, Latest version: $latest_version"
    else
        echo "You are already using the latest version: $current_version"
    fi
}

# Call the function to check for updates
check_for_update


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