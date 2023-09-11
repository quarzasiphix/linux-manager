#!/bin/bash

# Prompt for MySQL root password securely.
read -sp "Enter MySQL root password: " mysql_password
echo

# Prompt for the name of the backup.
read -p "Enter name: " name
echo

# Define variables.
nginx_config="/etc/nginx/sites-enabled/$name.nginx"
backupdir="/var/www/backups/$name/"
tempdir="$name-temp"

# Create a temporary directory and set appropriate permissions.
sudo mkdir "$tempdir" > /dev/null
sudo chmod -R 777 "$tempdir"

echo "Backing up Nginx, SQL, and WordPress files."
# Perform MySQL database backup.
echo ...
sudo mysqldump -u root -p"$mysql_password" --single-transaction "$name" > "$tempdir/$name-backup.sql"
# Backup Nginx configuration.
sudo cp "$nginx_config" "$tempdir/" > /dev/null

echo ...
# Backup WordPress files.
sudo cp -R "$name" "$tempdir/" > /dev/null

echo
echo "Compressing...."
echo

# Create a ZIP archive with the backup files.
zip -r "$name-$(date +%F).zip" "$tempdir" > /dev/null


# Create the backup directory if it doesn't exist.
sudo mkdir -p "$backupdir" > /dev/null

echo ...
# Move the backup file to the backup directory.
sudo mv "$name-$(date +%F).zip" "$backupdir/"
echo ...

# Remove the temporary directory.
#sudo rm -r "$tempdir"

echo 
echo "Backup completed. Files are stored in $backupdir."
