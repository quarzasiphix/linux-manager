# this file holds the code for the backup script.
RestoreWP() {
    echo
    backupdir="/var/www/backups/$name"
    dir="/var/www/sites/$name"
    
    # Clean up temporary directory
    sudo rm -rf "$backupdir/$name-temp" > /dev/null 2>&1

    # List backups and their sizes
    echo
    echo "Backups folder size for $name:"
    du -sh "$backupdir"
    echo
    echo "Backups:"
    sudo ls -l "$backupdir" | awk '{print $9}'
    echo
    echo "  (type 'quit' to exit restore)"
    
    # Prompt for backup to restore
    read -p "Backup to restore: " backup
    if [ "$backup" = "quit" ]; then
        return  # Exit the function
    fi

    echo
    echo "Continuing..."
    echo
    echo "Unzipping backup file"
    echo

    # Unzip the backup file
    sudo unzip "$backupdir/$backup" -d "$backupdir/" > /dev/null
    if [ $? -ne 0 ]; then
        echo "Error: Failed to unzip the backup file"
        return 1
    fi

    echo 
    echo "Clearing previous files"
    echo

    # Remove old WordPress files and Nginx configuration
    sudo rm -rf "$dir"
    sudo rm "/etc/nginx/sites-enabled/$name.nginx" > /dev/null 2>&1

    echo
    echo "Moving WordPress files to directory"
    echo

    # Move the backup files to their appropriate locations
    sudo mv "$backupdir/var/www/backups/$name/$name-temp" "$backupdir/" > /dev/null 2>&1
    sudo rm -rf "$backupdir/var" > /dev/null 2>&1
    sudo mv "$backupdir/$name-temp/$name" "/var/www/sites/"
    sudo mv "$backupdir/$name-temp/$name.nginx" "/etc/nginx/sites-enabled/"
    sudo mkdir -p "/var/www/logs/$name"

    echo
    echo "Setting up database"
    echo    

    # Get database password
    dbpass=$(awk -F"'" '/DB_PASSWORD/ {print $4}' "$dir/wp-config.php")

    if [ -z "$dbpass" ]; then
        echo "Error: Could not retrieve database password from wp-config.php"
        return 1
    fi

    # Restore the database
    sudo mysql -u root <<EOF
    DROP DATABASE IF EXISTS $name;
    CREATE DATABASE $name;
    DROP USER IF EXISTS '$name'@'localhost';
    CREATE USER '$name'@'localhost' IDENTIFIED BY '$dbpass';
    GRANT ALL PRIVILEGES ON $name.* TO '$name'@'localhost';
    FLUSH PRIVILEGES;
EOF

    sudo mysql -u $name -p"$dbpass" $name < "$backupdir/$name-temp/$name.sql"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to restore the database"
        return 1
    fi

    # Clean up temporary backup directory
    sudo rm -rf "$backupdir/$name-temp" > /dev/null 2>&1

    # Set ownership and permissions
    sudo chown -R www-data:www-data "$dir"
    sudo chmod -R 755 "$dir"
    sudo chmod 600 "$dir/wp-config.php" > /dev/null 2>&1
    sudo chmod -R 755 "$dir/wp-content/uploads" > /dev/null 2>&1

    # Restart Nginx to apply changes
    sudo systemctl restart nginx
    if [ $? -ne 0 ]; then
        echo "Error: Failed to restart Nginx"
        return 1
    fi

    echo
    echo "Restore complete"
    echo
}


#echo 
#    echo "checkin if password file exists on server..."
#    echo#
#
#    #password_file="/var/www/sites/$name/password.txt"
#    #password=
#    #if [ ! -f "$password_file" ]; then
#    #    echo
#    #    echo "Password for $name not found on server."
#    #    echo
#    #    #read -s -p "Enter a new project password for $name: " new_password
#    #    #echo "$new_password" | sudo tee "$password_file" > /dev/null
#    #    #echo "Password file created."#
#
#        read -sp "Enter project password: " new_password
#        echo "$new_password" | sudo tee "$password_file" > /dev/null
#    fi##
#
#    password=$(sudo cat "$password_file")#
#
#   echo#  dir="/var/www/sites/$name"
#
#
#    password=$(sudo cat "$password_file")
#    while true; do
#        echo
#        echo "Checking password..."
#        echo
#        # Test the integrity of the encrypted zip file without extracting its contents
#        sudo unzip -t -P "$password" "$backupdir/$backup" -d "$backupdir/" > /dev/null 2>&1
#        # Check the exit code
#        if [ $? -eq 0 ]; then
#            # Password is correct, proceed with restoring backup
#            echo "password is correct"
#            echo
#            echo " unzipping.."
#            echo
#            sudo unzip "$backupdir/$backup" -d "$backupdir/" > /dev/null
#            echo
#            echo "Zip file extracted successfully, continuin with restoration..."
#            break
#        else
#            # Password is incorrect
#            echo "Incorrect password."
#            read -p "Type 'x' to exit or press Enter to retry: " choice
#            if [ "$choice" == "x" ]; then
#                echo "Exiting."
#                exit 1
#            fi
#        fi
#    done#

