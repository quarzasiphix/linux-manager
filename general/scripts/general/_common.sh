#!/bin/bash
DIR="/var/www/scripts/new/general"

for gen in "$DIR"/*.sh; do
    . "$gen"
done

# Source all server scripts
#for server in "$DIR/server"/*.sh; do
#    . "$server"
#done

# Source all server scripts
#for site in "$DIR/site"/*.sh; do
#    . "$site"
#done




# Common functions or variables
#source menus.sh

#server
#source server/_common.sh