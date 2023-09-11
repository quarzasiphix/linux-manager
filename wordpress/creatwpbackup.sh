#!/bin/bash

# Prompt for MySQL root password securely.
read -s -p "Enter MySQL root password: " mysql_password
echo

# Prompt for the name of the backup.
read -p "Enter name: " name
echo

# Define variables.
dir="/var/www/sites/$name"
nginx_config="/etc/nginx/sites-enabled/$name.nginx"
backupdir="/var/www/backups/$name"
tempdir="$backupdir/temp"

# Create the backup directory if it doesn't exist.
sudo mkdir -p "$backupdir" > /dev/null

# Create a temporary directory and set appropriate permissions.
sudo mkdir -p "$tempdir" > /dev/null
sudo chmod -R 777 "$tempdir"

# Perform MySQL database backup.
echo "Backing up MySQL database..."
sudo mysqldump -u root -p"$mysql_password" --single-transaction "$name" > "$tempdir/$name-backup.sql"

# Backup Nginx configuration.
echo "Backing up Nginx configuration..."
sudo cp "$nginx_config" "$tempdir/" > /dev/null

# Backup WordPress files.
echo "Backing up WordPress files..."
sudo cp -R "$dir/" "$tempdir/" > /dev/null


# Create a ZIP archive with the backup files.
echo
echo "Creating ZIP archive..."
echo
echo "Compressing...."
sudo zip -r "$backupdir/$name-$(date +%F).zip" "$tempdir"/* > /dev/null

echo
echo "Cleaning up..."
# Remove the temporary directory.
sudo rm -r "$tempdir"

echo
echo "Backup completed. Files are stored in $backupdir."
