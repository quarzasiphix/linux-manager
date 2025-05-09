#!/bin/bash

#script files
dir=
sdir="/var/www/scripts/manager"

. $sdir/menus/managesite.sh
. $sdir/menus/general.sh
. $sdir/menus/safety.sh
. $sdir/menus/configurator.sh

. $sdir/server/stuff.sh
. $sdir/server/banner.sh
. $sdir/server/stuff.sh
. $sdir/server/n8n.sh

. $sdir/site/manage.sh
. $sdir/site/setupwp.sh
. $sdir/site/setuplov.sh
. $sdir/site/restore.sh
. $sdir/site/backup.sh
. $sdir/site/webs.sh
. $sdir/site/setuphtml.sh

latest_version=""
current_version=$(cat $sdir/version.txt)

check_for_update() {
    latest_version=$(curl -s "https://raw.githubusercontent.com/quarzasiphix/linux-manager/master/source/version.txt")
}


# website management variables
name=
nginx_config="/etc/nginx/sites-enabled/$name.nginx"
backupdir="/var/www/backups/$name"
tempdir="$backupdir/$name-temp"
plugindir="/var/www/sites/$name"

#for backups


nginxconfdir="/etc/nginx/sites-enabled"
nginxdisabled="/etc/nginx/disabled"

# project info
currentdomain=
IsSetProject="false"

ProjectBanner() {
    server_name=$(</var/www/server/name.txt)
    server_location=$(</var/www/server/info.txt)

    if [[ "$current_version" != "$latest_version" ]]; then
        echo -e "   \e[38;5;208mUpdate availabile!\e[0m"
        echo -e "   Current version: \e[38;5;208m$current_version\e[0m => \e[32m$latest_version\e[0m"
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

        while [ "$IsSetProject" == "safe" ]; do
        SafetyPanel
        done

        while [ "$IsSetProject" == "n8n" ]; do
        n8n_panel
        done
    done
}

check_for_update
main 