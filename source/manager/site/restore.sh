RestoreWP() {
    echo
    backupdir="/var/www/backups/$name"
    sudo rm -R "$backupdir/$name-temp" > /dev/null
    # List files inside backup directory
    echo
    echo "Backups"
    sudo ls -l "$backupdir" | awk '{print $9}'
    read -p "backup to restore: " backup

    echo 
    echo "checkin if password file exists on server..."
    echo

    password_file="/var/www/sites/$name/password.txt"
    password=
    if [ ! -f "$password_file" ]; then
        echo
        echo "Password for $name not found on server."
        echo
        #read -s -p "Enter a new project password for $name: " new_password
        #echo "$new_password" | sudo tee "$password_file" > /dev/null
        #echo "Password file created."

        read -sp "Enter project password: " new_password
        echo "$new_password" | sudo tee "$password_file" > /dev/null
    fi

    password=$(sudo cat "$password_file")

    echo
    dir="/var/www/sites/$name"


    password=$(sudo cat "$password_file")
    while true; do
        echo
        echo "Checking password..."
        echo
        # Test the integrity of the encrypted zip file without extracting its contents
        sudo unzip -t -P "$password" "$backupdir/$backup" -d "$backupdir/" > /dev/null 2>&1
        # Check the exit code
        if [ $? -eq 0 ]; then
            # Password is correct, proceed with restoring backup
            sudo unzip "$backupdir/$backup" -d "$backupdir/" > /dev/null
            echo
            echo "Zip file extracted successfully, continuin with restoration..."
            break
        else
            # Password is incorrect
            echo "Incorrect password."
            read -p "Type 'x' to exit or press Enter to retry: " choice
            if [ "$choice" == "x" ]; then
                echo "Exiting."
                exit 1
            fi
        fi
    done


    echo 
    echo "clearing previous files"
    echo

    sudo rm -R "$dir"
    sudo rm /etc/nginx/sites-enabled/$name.nginx

    echo
    echo "moving wordpress files to directory"
    echo

    sudo mv $backupdir/var/www/backups/$name/$name-temp/ $backupdir/
    sudo rm -R $backupdir/var > /dev/null
    sudo mv $backupdir/$name-temp/$name /var/www/sites/
    sudo mv $backupdir/$name-temp/$name.nginx /etc/nginx/sites-enabled/
    sudo mkdir /var/www/logs/$name

    echo
    echo "setting up database"
    echo

    sudo mysql -u root <<EOF
    DROP DATABASE IF EXISTS $name;
    CREATE DATABASE $name;
    DROP USER IF EXISTS '$name'@'localhost';
    CREATE USER '$name'@'localhost' IDENTIFIED BY '$password';
    GRANT ALL PRIVILEGES ON $name.* TO '$name'@'localhost';
    FLUSH PRIVILEGES;
    \q
EOF

    sudo mysql -u $name -p$password $name < $backupdir/$name-temp/$name.sql

    sudo rm -R "$backupdir/$name-temp" > /dev/null

    sudo chown -R www-data:www-data "$dir"

    sudo chmod -R 755 $dir

    sudo chmod 600 "$dir/wp-config.php" > /dev/null
    sudo chmod -R 755 "$dir/wp-content/uploads" > /dev/null

    sudo systemctl restart nginx

    echo
    echo "restore complete"
    echo
}
