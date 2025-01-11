
####sudo mysql -u root <<EOF
#    DROP DATABASE IF EXISTS $name;
#    CREATE DATABASE $name;
#    DROP USER IF EXISTS '$name'@'localhost';
#   CREATE USER '$name'@'localhost' IDENTIFIED BY '$new_password';
#   GRANT ALL PRIVILEGES ON $name.* TO '$name'@'localhost';
#    FLUSH PRIVILEGES;
#    \q
#           EOF
#        echo
#        echo "changing wp-config.php database password to new project password"
###        echp
#sudo sed -i "s/'DB_PASSWORD',.*/'DB_PASSWORD', '$new_password');/" "$wp_config"

##    password_file="/var/www/sites/$name/password.txt"
#    if [ ! -f "$password_file" ]; then
#        echo
#        echo "No set password for $name."
#        echo
#        read -s -p "Enter a new project password for $name: " new_password
#        echo "$new_password" | sudo tee "$password_file" > /dev/null
#        echo "Password file created."#
#
#        #echo
#        #echo "setting up database to new project password"
#        #echo
#    else
#        echo 
#        echo "Using Password for project $name found on server..."
#    fi##
#
#        #get project password:
#    password=$(sudo cat "/var/www/sites/$name/password.txt")#


   # if [ -d "$tempdir" ]; then
   #     echo "temp dir size: "
   #     du -sh "$tempdir"
   #     echo
    #    echo "moving existing temp directory to archive"
    #    echo
   #     if [ -f "$backupdir/archive/$(date +%F)" ]; then
   #         sudo mv "$tempdir" "$tempdir-$(date +%F)"
   #         sudo mv "$tempdir-$(date +%F)" "$backupdir/archive/$(date +%F)"
   #     else
   #     fi
   #     sudo mkdir "$tempdir"
   # fi

BackupWP() {
    nginx_config="/etc/nginx/sites-enabled/$name.nginx"
    backupdir="/var/www/backups/$name"
    tempdir="$backupdir/$name-temp"
    
    # Define variables.
    # Create directories if they don't exist.
    sudo mkdir -p "$backupdir/archive/$(date +%F)" > /dev/null 2>&1

    if [ -d "$tempdir" ]; then
        echo "Temp dir size: "
        du -sh "$tempdir"
        echo
        echo "Moving existing temp directory to archive $(date +%F)"
        sudo mv "$tempdir" "$backupdir/archive/$(date +%F)/"
    fi

    echo
    sudo mkdir -p "$tempdir"
    sudo chmod -R 777 "$tempdir" > /dev/null 2>&1

    # Perform MySQL database backup.
    sudo mysqldump -u root --single-transaction "$name" > "$tempdir/$name.sql"

    # Backup Nginx configuration.
    sudo cp "$nginx_config" "$tempdir/"

    # Backup logs.
    sudo cp -R "/var/www/logs/$name" "$tempdir/logs/" > /dev/null 2>&1
    echo "Logs folder size: "
    du -sh "/var/www/logs/$name"

    echo
    echo "Backing up source files"
    echo
    echo "Source folder size: "
    du -sh "/var/www/sites/$name"

    # Backup WordPress files.
    sudo cp -R "/var/www/sites/$name" "$tempdir/$name" > /dev/null 2>&1

    counter=1
    backupfile="$backupdir/$name-$(date +%F)"
    while [ -f "${backupfile}-$counter.zip" ]; do
        ((counter++))
    done

    if [ -f "$backupfile.zip" ]; then
        echo
        echo "$counter backups made on $(date +%F)"
        echo
        echo "Zipping backup files"
        sudo zip -r "${backupfile}-$counter.zip" "$tempdir" > /dev/null
        sudo mv "${backupfile}-$counter.zip" "$backupdir/"
        final_backupfile="${backupfile}-$counter.zip"
    else
        echo
        echo "First backup of today $(date +%F)"
        echo
        echo "Zipping backup files"
        sudo zip -r "${backupfile}.zip" "$tempdir" > /dev/null
        sudo mv "${backupfile}.zip" "$backupdir/"
        final_backupfile="${backupfile}.zip"
    fi

    echo
    echo "Backup archive size:"
    du -sh "$final_backupfile"
    echo
    echo -e "\e[32mBackup completed. \e[0m Files are stored in $backupdir."

    du -sh "$tempdir"
    read -p "Remove temp directory? (yes/no): " _temps
    if [ "$_temps" = "yes" ]; then
        sudo trash "$tempdir"
    fi

    read -p "Setup for goaccess download? (yes/no): " _public
    if [ "$_public" = "yes" ]; then
        sudo cp -R "$final_backupfile" "/var/www/sites/goaccess/backups/"
        if [ -f "$nginxdisabled/$name.nginx" ] || [ -f "$nginxconfdir/$name.disabled" ]; then
            tempname=$name
            name="goaccess"
            EnableConf
            name=$tempname

            echo "Enabled goaccess site"
        fi
    fi  
}


backupAll() {
    # Define variables.

    file_names=()

    # Iterate over each file in the directory
    for file in "$nginxconfdir"/*.nginx; do
        # Extract the filename without the extension
        filename=$(basename "$file" .nginx)
        # Add the modified filename to the array
        file_names+=("$filename")
    done

    echo "  :Backup All Active websites: "
    echo

    for names in "${file_names[@]}"; do
        nginx_config="/etc/nginx/sites-enabled/$names.nginx"
        backupdir="/var/www/backups/$names"
        tempdir="$backupdir/$names-temp"

        # Create a temporary directory and set appropriate permissions.
        sudo mkdir "$backupdir" > /dev/null 2>&1
        sudo mkdir "$backupdir/archive/$(date +%F)" > /dev/null 2>&1

        sudo mv "$tempdir" "$backupdir/archive/$(date +%F)" > /dev/null 2>&1
        sudo mkdir "$tempdir" > /dev/null 2>&1

        sudo chmod -R 777 "$tempdir" > /dev/null

        # Perform MySQL database backup.
        sudo mysqldump -u root --single-transaction "$names" > "$tempdir/$names.sql"

        # Backup Nginx configuration.
        sudo cp "$nginx_config" "$tempdir/"

        # Backup Logs
        echo "..."
        sudo cp -R "/var/www/logs/$names" "$tempdir/logs/" > /dev/null
        echo "Logs folder size: "
        du -sh "/var/www/logs/$name"

        #echo "source folder size for $names: "
        #du -sh "/var/www/sites/$names"

        # Backup WordPress files.
        echo "..."
        sudo cp -R "/var/www/sites/$names" "$tempdir/$names" > /dev/null
        echo "source folder size: "
        du -sh "/var/www/sites/$name"


        # Copy existing backup
        # Check if the file exists
        counter=1
        while [ -f "$backupdir/$names-$(date +%F)-$counter.zip" ]; do
            ((counter++))
        done

        if [ -f "$backupdir/$names-$(date +%F).zip" ]; then
            # If the file exists, copy it to the archive folder
            #cp "$name-$(date +%F).zip" "$backupdir/archive"
            #sudo mv "$backupdir/$name-$(date +%F).zip" "$backupdir/$name-$(date +%F)-$counter.zip
            echo
            echo "$counter backups made on $(date +%F) "
            echo
            echo "Zipping backup files"
            echo
            sudo zip -r "$names-$(date +%F)-$counter.zip" "$tempdir"  > /dev/null
            sudo mv "$names-$(date +%F)-$counter.zip" "$backupdir/"
            echo 
            echo "Backup archive size for $names: "
            du -sh "$backupdir/$names-$(date +%F)-$counter.zip"
        else
            echo
            echo "First backup of today $(date +%F)"
            echo
            echo "Zipping backup files"
            echo
            sudo zip -r "$names-$(date +%F).zip" "$tempdir"  > /dev/null
            sudo mv "$names-$(date +%F).zip" "$backupdir/"
            echo 
            echo "Backup archive size for $names: "
            du -sh "$backupdir/$names-$(date +%F).zip"
        fi
        echo
        echo -e "\e[32m Backup for $names is completed. \e[0m"
        echo


        # Create the backup directory if it doesn't exist.
        sudo mkdir -p "$backupdir" > /dev/null

        
        # Move the backup file to the backup directory.
        #sudo mv "$name-$(date +%F).zip" "$backupdir/"

        # Remove the temporary directory.
        #sudo rm -r "$tempdir"
    done
    echo
    echo "Finished backing up all active sites"
    echo
}