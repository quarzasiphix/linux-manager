#!/bin/bash
read -p "name: " name

while true; do
    # Confirm the project name before proceeding
    read -p "Type the name of the project you're deleting to confirm: " confirmation
    if [ "$confirmation" = "$name" ]; then
        break
    else
        read -p "Confirmation failed. Retry? (y/n) " retry_response
        if [ "$retry_response" != "y" ]; then
            echo "Exiting script."
            exit 1
        fi
    fi
done

backupdir="/var/www/backups/$name"
recent_backup="$backupdir/$name-$(date +%F).zip"

if [ -f "$recent_backup" ]; then
    echo "Recent backup found: $recent_backup"
else
    read -p "Delete without backing up? (y/n) " response
    if [ "$response" != "y" ]; then
        echo "Exiting script."
        exit 1
    else
        # Run the backup script
        /bin/bash /var/www/scripts/backupwp.sh
    fi
fi

echo "deleting nginx config"
sudo rm -R "/etc/nginx/sites-enabled/$name.nginx" 

echo "deleting source"
sudo rm -R "/var/www/sites/$name"

echo "dropping database"
sudo mysql -u root <<EOF 
DROP DATABASE IF EXISTS $name;
DROP USER IF EXISTS '$name'@'localhost';
FLUSH PRIVILEGES;
/q
EOF

echo "clearing logs"
nginx_log_dir="/var/www/logs/$name"
sudo rm -R $nginx_log_dir > /dev/null

echo
echo "fully removed project $name"
echo

