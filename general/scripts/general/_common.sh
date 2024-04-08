DIR="/var/www/scripts/new/general"

for gen in "$DIR"/*.sh; do
    echo "   including: $gen"
    if [ -f "$gen" ]; then
        . "$gen"
    else
        echo "   $gen is not a regular file"
    fi
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

git add .
git commit -m "fixing manager"
git push