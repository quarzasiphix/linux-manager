#!/bin/bash

# Get name
read -p "Enter name: " name
echo

backupdir="/var/www/backups/$name"
sudo rm -R "$backupdir/$name-temp" > /dev/null

# List files inside backup directory
echo
echo "Backups"
sudo ls -l "$backupdir" | awk '{print $9}'
read -p "backup to restore: " backup


# Get database password
read -sp "Enter database password: " dbpasss
echo


echo "unzipping"
echo
sudo unzip "$backupdir/$backup" -d "$backupdir/" > /dev/null

echo "moving files to directory"
echo
sudo mv $backupdir/var/www/backups/$name/$name-temp/ $backupdir/
sudo rm -R $backupdir/var > /dev/null
sudo mv $backupdir/$name-temp/$name /var/www/sites/
sudo mv $backupdir/$name-temp/$name.nginx /etc/nginx/sites-enabled/

echo "setting up database"
echo

sudo mysql -u root <<EOF
DROP DATABASE IF EXISTS $name;
CREATE DATABASE $name;
DROP USER IF EXISTS '$name'@'localhost';
CREATE USER '$name'@'localhost' IDENTIFIED BY '$dbpasss';
GRANT ALL PRIVILEGES ON $name.* TO '$name'@'localhost';
FLUSH PRIVILEGES;
\q
EOF

sudo mysql -u $name -p$dbpass $name < $backupdir/$name-temp/$name-backup.sql

sudo rm -R "$backupdir/$name-temp" > /dev/null

dir="/var/www/sites/$name"

sudo chown -R quarza:www-data "$dir"

sudo chmod -R 755 $dir

sudo chmod 600 "$dir/wp-config.php" > /dev/null
sudo chmod -R 755 "$dir/wp-content/uploads" > /dev/null

sudo systemctl restart nginx

echo
echo "restore complete"
echo
