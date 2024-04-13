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

#include common..
DIR="/var/www/scripts/new/general"


# Print the script name being sourced
echo "Sourcing main script: $0"

for gen in "$DIR"/*.sh; do
    echo "   including: $gen"
    . "$gen"
done

# Include scripts from subdirectories recursively using find command
find "$DIR" -type f -name '*.sh' -print0 | while IFS= read -r -d '' gen; do
    if [ -f "$gen" ]; then
        echo "   including: $gen"
        . "$gen"
    else
        echo "   $gen is not a regular file"
    fi
done

git add .
git commit -m "fixing manager"
git push
