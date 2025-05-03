# this file holds the code for the backup script.
safe_delete_dir() {
    local dir="$1"
    if [[ -z "$dir" || "$dir" == "/" || "$dir" == "/var" || "$dir" == "/var/www" ]]; then
        log_action "Refused to delete suspicious directory: $dir"
        echo "Refusing to delete suspicious directory: $dir"
        return 1
    fi
    if [[ -d "$dir" ]]; then
        sudo rm -rf "$dir"
        log_action "Deleted directory: $dir"
    else
        log_action "Directory not found for deletion: $dir"
    fi
}

RestoreWP() {
    log_action "Starting restore for $name"
    if [[ -z "$name" ]] || ! validate_name "$name"; then
        log_action "Aborted restore: invalid or empty project name"
        echo "Invalid or empty project name. Aborting."
        return 1
    fi

    echo
    backupdir="/var/www/backups/$name"
    dir="/var/www/sites/$name"
    tmpdir=$(mktemp -d /var/www/backups/${name}-tmp-XXXXXXXX)
    
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
    sudo unzip "$backupdir/$backup" -d "$tmpdir" > /dev/null
    if [ $? -ne 0 ]; then
        echo "Error: Failed to unzip the backup file"
        return 1
    fi

    echo 
    echo "Clearing previous files"
    echo

    # Remove old WordPress files and Nginx configuration
    safe_delete_dir "$dir"
    sudo trash "/etc/nginx/sites-enabled/$name.nginx" > /dev/null 2>&1

    echo
    echo "Moving WordPress files to directory"
    echo

    # Move the backup files to their appropriate locations
    sudo mv "$tmpdir/$name" "/var/www/sites/"
    sudo mv "$tmpdir/$name.nginx" "/etc/nginx/sites-enabled/"
    sudo mkdir -p "/var/www/logs/$name"

    echo
    echo "Setting up database"
    echo    

    # Get database password
    dbpass=$(sudo awk -F"'" '/DB_PASSWORD/ {print $4}' "$dir/wp-config.php")

    if [ -z "$dbpass" ]; then
        echo
        echo "Error: Could not retrieve database password from wp-config.php"
        echo
        return 1
    fi

    echo 
    echo "DB password: $dbpass"
    echo

    # Restore the database
    sudo mysql -u root <<EOF
    DROP DATABASE IF EXISTS $name;
    CREATE DATABASE $name;
    DROP USER IF EXISTS '$name'@'localhost';
    CREATE USER '$name'@'localhost' IDENTIFIED BY '$dbpass';
    GRANT ALL PRIVILEGES ON $name.* TO '$name'@'localhost';
    FLUSH PRIVILEGES;
EOF

    sudo mysql -u $name -p"$dbpass" $name < "$tmpdir/$name.sql"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to restore the database"
        return 1
    fi

    # Clean up
    safe_delete_dir "$tmpdir"

    # Set ownership and permissions
    sudo chown -R quarza:www-data /var/www/sites/$name
    sudo find /var/www/sites/$name -type d -exec chmod 755 {} \;
    sudo find /var/www/sites/$name -type f -exec chmod 644 {} \;
    sudo chmod -R 755 "$dir"
    sudo chmod 640 "$dir/wp-config.php" > /dev/null 2>&1
    sudo chmod -R 755 "$dir/wp-content/uploads" > /dev/null 2>&1
    sudo chown -R quarza:www-data "$dir"

    # Restart Nginx to apply changes
    sudo systemctl restart nginx
    if [ $? -ne 0 ]; then
        echo "Error: Failed to restart Nginx"
        return 1
    fi

    log_action "Completed restore for $name"
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

