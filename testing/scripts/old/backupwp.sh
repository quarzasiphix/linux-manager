#!/bin/bash

# Prompt for the name of the backup.
read -p "Enter name: " name
echo

# Define variables.
nginx_config="/etc/nginx/sites-enabled/$name.nginx"
backupdir="/var/www/backups/$name"
tempdir="$backupdir/$name-temp"

# Create a temporary directory and set appropriate permissions.
sudo mkdir "$backupdir" > /dev/null
sudo mkdir "$tempdir" > /dev/null
sudo chmod -R 777 "$tempdir" > /dev/null

# Perform MySQL database backup.
sudo mysqldump -u root --single-transaction "$name" > "$tempdir/$name.sql"

# Backup Nginx configuration.
sudo cp "$nginx_config" "$tempdir/"

sudo cp -R "/var/www/logs/$name" > /dev/null

echo "Backing up source files"

# Backup WordPress files.
sudo cp -R "/var/www/sites/$name" "$tempdir/logs/" > /dev/null

echo "Zipping backup files"

# Create a ZIP archive with the backup files.
sudo zip -r "$name-$(date +%F).zip" "$tempdir"  > /dev/null

# Create the backup directory if it doesn't exist.
sudo mkdir -p "$backupdir" > /dev/null

# Move the backup file to the backup directory.
sudo mv "$name-$(date +%F).zip" "$backupdir/"

# Remove the temporary directory.
#sudo rm -r "$tempdir"

echo "Backup completed. Files are stored in $backupdir." 
