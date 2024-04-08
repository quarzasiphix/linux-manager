DIR="/var/www/scripts/new/general"

for gen in "$DIR"/*.sh; do
    if [ -f "$gen" ]; then
        echo "   including: $gen"
        . "$gen"
    else
        echo "   $gen is not a regular file"
    fi
done
# Include scripts from subdirectories recursively
for gen in "$DIR"/*/*.sh; do
    if [ -f "$gen" ]; then
        echo "   including: $gen"
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
