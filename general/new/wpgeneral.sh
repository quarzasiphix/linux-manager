#!/bin/bash

nginxconfdir="/etc/nginx/sites-enabled"
nginxdisabled="/etc/nginx/disabled"

# project info
currentdomain=


DeleteWp() {
    # Confirm deletion
    echo -e " \e[31m Permanent Erase,\e[0m there is no turnning back! "
    echo
    echo "make a backup before deleting"
    echo
    echo -e "Are you sure you want to delete project '$name'?"
    echo
    echo "Deleting the project will delete the database"
    echo ", nginx config, source files and logs"
    echo 
    read -p " (Type 'yes' to confirm): " confirm

    if [[ $confirm == "yes" ]]; then
        echo
        echo "Removing files, config, and logs for project '$name'..."
        echo

        sudo rm -R "/var/www/sites/$name"
        sudo rm -R "/var/www/logs/$name"
        sudo rm "/etc/nginx/sites-enabled/$name.nginx"

        # Restarting nginx to update delete
        sudo systemctl restart nginx

        echo
        echo "Clearing database for project '$name'..."
        echo

        sudo mysql -u root <<EOF
        DROP DATABASE IF EXISTS $name;
        DROP USER IF EXISTS '$name'@'localhost';
        \q
EOF
        echo "Successfully removed project '$name'"
    else
        echo "Deletion canceled. No changes made."
    fi
}

GraphLog() {
    pubdir="/var/www/sites/goaccess"
    nginxdir="/etc/nginx/sites-enabled"
    logdir="/var/www/logs/$name"

    outputfile="$pubdir/logs/$name-report-$(date +%F)"
    inputfile="$logdir/access.nginx"

    sudo mkdir $pubdir > /dev/null 2>&1
    sudo mkdir $pubdir/logs > /dev/null 2>&1
    sudo mkdir $pubdir/logs/$name > /dev/null 2>&1

    sudo mkdir $logdir/archive

    sudo chown -R quarza:www-data $pubdir/logs > /dev/null 2>&1
    sudo chmod -R 755 $pubdir/logs > /dev/null 2>&1

    counter=1
    while [ -f "$inputfile.html" ]; do
        ((counter++))
    done

    if [ -f "$outputfile" ]; then
        echo
        echo "$counter graph made on $(date +%F) "
        echo
        echo "graphing...."
        echo
        sudo goaccess $inputfile -o $outputfile-$counter.html --log-format=COMBINED
    else 
        echo "first graph of today $(date +%F)"
        echo
        echo "graphing..."
        echo
        sudo goaccess $inputfile -o $outputfile.html --log-format=COMBINED
    fi

    echo
    echo "done graphing for $name"
    echo
    
    #echo "backing up current log"
    #echo
    #sudo mv $inputfile $inputfile-$(date +%F)
    #sudo mv $inputfile-$(date +%F) $logdir/archive
    sudo touch $inputfile
    sudo systemctl restart nginx

    echo
    echo "done backing up log"
    echo
}

GraphAllActive() {
    file_names=()

    # Iterate over each file in the directory
    for file in "$nginxconfdir"/*.nginx; do
        # Extract the filename without the extension
        filename=$(basename "$file" .nginx)
        # Add the modified filename to the array
        file_names+=("$filename")
    done

    echo "\e[31mDisabled websites:\e[0m"
    echo

    # Define the maximum width for the filenames
    max_width=20
    pubdir="/var/www/sites/goaccess"
    nginxdir="/etc/nginx/sites-enabled"

    for names in "${file_names[@]}"; do
        logdir="/var/www/logs/$names"

        outputfile="$pubdir/logs/$names-report-$(date +%F)"
        inputfile="$logdir/access.nginx"

        sudo mkdir $pubdir > /dev/null 2>&1
        sudo mkdir $pubdir/logs > /dev/null 2>&1
        sudo mkdir $pubdir/logs/$name > /dev/null 2>&1

        sudo mkdir $logdir/archive

        sudo chown -R quarza:www-data $pubdir/logs > /dev/null 2>&1
        sudo chmod -R 755 $pubdir/logs > /dev/null 2>&1

        counter=1
        while [ -f "$inputfile.html" ]; do
            ((counter++))
        done

        if [ -f "$outputfile" ]; then
            echo
            echo "$counter graph made on $(date +%F) "
            echo
            echo "graphing...."
            echo
            sudo goaccess $inputfile -o $outputfile-$counter.html --log-format=COMBINED
        else 
            echo "first graph of today $(date +%F)"
            echo
            echo "graphing..."
            echo
            sudo goaccess $inputfile -o $outputfile.html --log-format=COMBINED
        fi

        echo
        echo "done graphing for $name"
        echo

        echo "backing up current log"
        echo

        #sudo mv $inputfile $inputfile-$(date +%F)
        #sudo mv $inputfile-$(date +%F) $logdir/archive
        sudo touch $inputfile
        sudo systemctl restart nginx

        echo
        echo "done backing up log"
        echo 
    done
}

EditConf() {
    sudo vim $nginxconfdir/$name.nginx
    clear
    echo
    echo "edited config for $name"
    echo
    echo "restarting nginx to confirm changes"
    echo
    sudo systemctl restart nginx
}


SetupWP() {
    # Get domain
    read -p "Enter domain: " domain
    echo

    # Get database password
    read -sp "Enter database password: " dbpasss
    echo

    echo "setting up wordpress"
    # Download WordPress
    sudo rm latest.tar.gz
    echo "downloading wordpress files... "
    echo
    sudo wget https://wordpress.org/latest.tar.gz
    dir="/var/www/sites/$name"
    sudo rm -R "$dir"
    sudo mkdir "$dir"
    echo
    echo "extracting wordpress files... "
    echo
    sudo tar -xvzf latest.tar.gz --strip-components=1 -C "$dir" > /dev/null
    echo "finished extracting wp files.. setting up perms"
    echo
    sudo chown -R quarza:www-data "$dir"
    sudo chmod -R 755 "$dir"

    echo
    echo "setting up database"
    echo

    # Setup database
    sudo mysql -u root <<EOF
    DROP DATABASE IF EXISTS $name;
    CREATE DATABASE $name;
    DROP USER IF EXISTS '$name'@'localhost';
    CREATE USER '$name'@'localhost' IDENTIFIED BY '$dbpasss';
    GRANT ALL PRIVILEGES ON $name.* TO '$name'@'localhost';
    FLUSH PRIVILEGES;
    \q
EOF
    echo
    echo "Setting up Nginx"
    echo

    # Create Nginx configuration file
    nginx_log_dir="/var/www/logs/$name"
    sudo mkdir $nginx_log_dir > /dev/null

    nginx_config="/etc/nginx/sites-available/$name.nginx"
    sudo rm "$nginx_config" > /dev/null
    sudo tee "$nginx_config" > /dev/null <<EOT
    server {
        listen 80;
        server_name $domain www.$domain;
        root $dir;
        index index.php;

        error_page 404 /index;
        error_log $nginx_log_dir/error.nginx;
        access_log $nginx_log_dir/access.nginx;

        location / {
            try_files \$uri \$uri/ /index.php?\$args;
        }

        location ~* /uploads/.*\.php$ {
            return 503;
        }

        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        }

        location ~ /\.ht {
            deny all;
        }
    }
EOT

    # Enable the site by creating a symbolic link
    sudo ln -s "$nginx_config" "/etc/nginx/sites-enabled/$name.nginx" > /dev/null

    # Restart Nginx
    sudo systemctl restart nginx

    echo
    echo "Created WordPress project $name"
    echo

    # Wait until wp-config.php has <?php tag on the first line
    echo "waiting on user to initialise project on $domain/admin"
    echo
    while ! head -n 1 "$dir/wp-config.php" 2>/dev/null | grep -q "^<?php"; do
        sleep 1
    done

    sudo cp -R /var/www/libs/elementor-pro $dir/wp-content/plugins/
    sudo cp -R /var/www/libs/kera $dir/wp-content/themes/


    # Force https and allow 512mb file size
    sudo sed -i '2i$_SERVER["HTTPS"] = "on";' "$dir/wp-config.php"
    sudo sed -i '4i define('"'"'WP_MEMORY_LIMIT'"'"', '"'"'512M'"'"');' "$dir/wp-config.php"
    echo
    echo "setting permissions"
    echo 

    sudo chmod 644 	"$dir/wp-admin/index.php" > /dev/null
    sudo chmod 600 "$dir/wp-config.php" > /dev/null
    sudo chmod -R 755 "$dir/wp-content/uploads" > /dev/null

    echo
    echo "initialised https, project $name setup succesfully"
    echo
}

DisableConf() {
    echo
    echo
    echo

    echo -e " \e[31m Disbling site... \e[0m"

    grabbeddomain=$(grep -o 'server_name.*;' $nginxconfdir/$name.nginx | awk '{print $2}' | sed 's/;//')
    echo
    echo "setting up config for $name on $grabbeddomain to disabled page"
    echo
    echo ...
    sudo mv $nginxconfdir/$name.nginx $nginxdisabled 
    echo
    echo "restarting nginx..."
    sudo systemctl restart nginx
    echo
    echo "Disabled! $name"
}

BackupWP() {
    # Define variables.

    nginx_config="/etc/nginx/sites-enabled/$name.nginx"
    backupdir="/var/www/backups/$name"
    tempdir="$backupdir/$name-temp"

    # Create a temporary directory and set appropriate permissions.
    sudo mkdir "$backupdir" > /dev/null 2>&1
    sudo mkdir "$backupdir/archive/$(date +%F)" > /dev/null 2>&1

    echo "moving existing temp directory to archive"
    echo
    sudo mv "$tempdir" "$backupdir/archive/$(date +%F)" > /dev/null 2>&1
    sudo mkdir "$tempdir" > /dev/null 2>&1

    sudo chmod -R 777 "$tempdir" > /dev/null

    # Perform MySQL database backup.
    sudo mysqldump -u root --single-transaction "$name" > "$tempdir/$name.sql"

    # Backup Nginx configuration.
    sudo cp "$nginx_config" "$tempdir/"

    # Backup Logs
    sudo cp -R "/var/www/logs/$name" "$tempdir/logs/" > /dev/null
    echo "Logs folder size: "
    du -sh "/var/www/logs/$name"

    echo
    echo "Backing up source files"
    echo

    echo "source folder size: "
    du -sh "/var/www/sites/$name"

    # Backup WordPress files.
    sudo cp -R "/var/www/sites/$name" "$tempdir/$name" > /dev/null

    # Copy existing backup
    # Check if the file exists
    counter=1
    while [ -f "$backupdir/$name-$(date +%F)-$counter.zip" ]; do
        ((counter++))
    done

    if [ -f "$backupdir/$name-$(date +%F).zip" ]; then
        # If the file exists, copy it to the archive folder
        #cp "$name-$(date +%F).zip" "$backupdir/archive"
            #sudo mv "$backupdir/$name-$(date +%F).zip" "$backupdir/$name-$(date +%F)-$counter.zip

            echo
        echo "$counter backups made on $(date +%F) "
            echo
            echo "Zipping backup files"
            echo
            sudo zip -r "$name-$(date +%F)-$counter.zip" "$tempdir"  > /dev/null
            sudo mv "$name-$(date +%F)-$counter.zip" "$backupdir/"
            echo 
            echo "Backup archive size: "
            du -sh "$backupdir/$name-$(date +%F)-$counter.zip"
    else
            echo
        echo "First backup of today $(date +%F)"
            echo
            echo "Zipping backup files"
            echo
            sudo zip -r "$name-$(date +%F).zip" "$tempdir"  > /dev/null
            sudo mv "$name-$(date +%F).zip" "$backupdir/"
            echo 
            echo "Backup archive size: "
            du -sh "$backupdir/$name-$(date +%F).zip"
    fi
    echo
    echo -e "\e[32m Backup completed. \e[0m  Files are stored in $backupdir."


    # Create the backup directory if it doesn't exist.
    sudo mkdir -p "$backupdir" > /dev/null

    # Move the backup file to the backup directory.
    #sudo mv "$name-$(date +%F).zip" "$backupdir/"

    # Remove the temporary directory.
    #sudo rm -r "$tempdir"
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

        #echo "source folder size for $names: "
        #du -sh "/var/www/sites/$names"

        # Backup WordPress files.
        echo "..."
        sudo cp -R "/var/www/sites/$names" "$tempdir/$names" > /dev/null

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

RestoreWP() {
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

    dir="/var/www/sites/$name"

    echo "unzipping"
    echo
    sudo unzip "$backupdir/$backup" -d "$backupdir/" > /dev/null

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
    CREATE USER '$name'@'localhost' IDENTIFIED BY '$dbpasss';
    GRANT ALL PRIVILEGES ON $name.* TO '$name'@'localhost';
    FLUSH PRIVILEGES;
    \q
EOF

    sudo mysql -u $name -p$dbpass $name < $backupdir/$name-temp/$name.sql

    sudo rm -R "$backupdir/$name-temp" > /dev/null

    sudo chown -R quarza:www-data "$dir"

    sudo chmod -R 755 $dir

    sudo chmod 600 "$dir/wp-config.php" > /dev/null
    sudo chmod -R 755 "$dir/wp-content/uploads" > /dev/null

    sudo systemctl restart nginx

    echo
    echo "restore complete"
    echo
}

GrabDomain() {
    if [ -f "$nginxconfdir/$name.nginx" ]; then
        # Print "Site Enabled" in green
        currentdomain=$(grep -o 'server_name.*;' $nginxconfdir/$name.nginx | awk '{print $2}' | sed 's/;//')
    elif [ -f "$nginxdisabled/$name.nginx" ]; then
        currentdomain=$(grep -o 'server_name.*;' $nginxdisabled/$name.nginx | awk '{print $2}' | sed 's/;//')
    fi
    #echo "$grabbeddomain"
    #currentdomain=$grabbeddomain
}

GetDisabledSites() {
    # Initialize an empty array to store the modified filenames
    file_names=()

    # Iterate over each file in the directory
    for file in "$nginxdisabled"/*.nginx; do
        # Extract the filename without the extension
        filename=$(basename "$file" .nginx)
        # Add the modified filename to the array
        file_names+=("$filename")
    done

    echo -e "  \e[31m:Disabled websites:\e[0m"
    echo

    # Define the maximum width for the filenames
    max_width=20

    for name in "${file_names[@]}"; do
        # Get the domain
        getdomain=$(grep -o 'server_name.*;' "$nginxdisabled/$name.nginx" | awk '{print $2}' | sed 's/;//')
        
        # Pad the filename with spaces to ensure even alignment
        padded_name=$(printf "%-${max_width}s" "$name")

        # Print the formatted output
        echo " : $padded_name :  domain: $getdomain"
    done

    echo 
}


GetActiveSites() {
    # Initialize an empty array to store the modified filenames
    file_names=()

    # Iterate over each file in the directory
    for file in "$nginxconfdir"/*.nginx; do
        # Extract the filename without the extension
        filename=$(basename "$file" .nginx)
        # Add the modified filename to the array
        file_names+=("$filename")
    done

    echo -e "   \e[32m:Active websites:\e[0m"
    echo

    # Define the maximum width for the filenames
    max_width=20

    for name in "${file_names[@]}"; do
        # Get the domain
        getdomain=$(grep -o 'server_name.*;' "$nginxconfdir/$name.nginx" | awk '{print $2}' | sed 's/;//')
        
        # Pad the filename with spaces to ensure even alignment
        padded_name=$(printf "%-${max_width}s" "$name")

        # Print the formatted output
        echo " : $padded_name :  domain: $getdomain"
    done

    echo 
}

EditNginxconf() {
    sudo vim /etc/nginx/nginx.conf
    echo
    echo "restarting nginx to confirm changes..."
    sudo systemctl restart nginx 
    echo
    echo "done"
    echo
}

EditSshconf() {
    sudo vim /etc/ssh/sshd_config
    echo
    echo "restarting ssh to confirm changes..."
    sudo systemctl restart sshd 
    echo
    echo "done"
    echo
}

EditMotd() {
    sudo vim /etc/motd
    echo
    echo "restarting ssh to confirm changes..."
    sudo systemctl restart sshd 
    echo
    echo "done"
    echo
}

EditBanner() {
    sudo vim /etc/ssh/banner.sh
    echo
    echo "restarting ssh to confirm changes..."
    sudo systemctl restart sshd 
    echo
    echo "done"
    echo
}

EditPasswd() {
    sudo vim /etc/passwd
    echo
    echo "done"
    echo
}

EditBash() {
    sudo vim ~/.bashrc
    echo
    echo "done"
    echo
}

EditVisudo() {
    sudo visudo
    echo
    echo "done"
    echo
}

IsSetProject=false
export IsSetProject

ProjectBanner() {
    server_name=$(</var/www/server/name.txt)
    server_location=$(</var/www/server/info.txt)

    echo
    echo    "   Server: $server_name!"
    echo    "   at: $server_location!"
    echo
    echo -e "    :Welcome \e[36m$USER\e[0m!!!"
    echo -e "to the\e[97m project management tool! \e[0m"
    echo
}



  
SetProject() {
    clear
    ProjectBanner
    # Ask user to type in a name
    read -p "Project name: " name
    echo
    source="/var/www/sites/$name"
    GrabDomain
    IsSetProject=true
}


#SetProject
clear
while true; do
    while [ "$IsSetProject" == "false" ]; do 
        ProjectBanner
        echo "0. Select project"
        echo
        echo "1. View All active websites"
        echo "2. View All disabled websites"
        echo "3. Graph All active sites"
        echo "4. Disable All sites"
        echo "5. Backup All Active"
        echo "6. Edit configs"
        echo
        echo "r. Restart nginx"
        echo
        echo "reboot - Fully reboot the server"
        echo
        read -p "What you wanna do?: " adminchoice
        case $adminchoice in 
            0)
                clear
                SetProject
                ;;
            1)
                clear
                GetActiveSites
                ;;
            2)
                clear
                GetDisabledSites
                ;;
            3)
                clear
                GraphAllActive
                ;;
            4)
                
                ;;
            5)
                clear
                backupAll
                ;;
            6)
                clear
                IsSetProject="conf"
                ;;
            'r')
                clear
                echo 
                echo "restarting nginx..."
                sudo systemctl restart nginx
                echo
                echo "finished restarting nginx"
                echo
                ;;
            'reboot')
                clear
                echo
                echo "Any UNSAVED changes Will be LOST"
                echo
                echo "are you sure you want to fully reboot the server"
                echo
                read -p " (Type 'yes' to confirm reboot): " confirm

                if [[ $confirm == "yes" ]]; then
                    echo
                    echo "initiating full reboot of linux...."
                    echo
                    sudo reboot

                    echo "rebooting...."
                    echo

                    while true; do
                        echo "bye"
                    done
                else
                    echo "cancelling reboot"
                    echo
                fi
                ;;
            *)
                clear
                echo "invalid"
                ;;
        esac
    done

    # Present options to the user
    while [ "$IsSetProject" == "true" ]; do
    if [ -d "$source" ]; then
        echo
        if [ -f "$nginxconfdir/$name.nginx" ]; then
            # Print "Site Enabled" in green
            echo -e " :Site \e[32m Enabled\e[0m:"
        elif [ -f "$nginxdisabled/$name.nginx" ]; then
            # Print "Site Disabled" in red
            echo -e " :Site \e[31m Disabled\e[0m:"
        fi
        echo
        echo "Current domain: $currentdomain" 
        echo
        echo "What would you like to do to $name?"
        echo
        echo "0. Change project"
        echo
        if [ -f "$nginxconfdir/$name.nginx" ]; then
            echo -e "\e[31m Disble\e[0m site"
        elif [ -f "$nginxdisabled/$name.nginx" ]; then
            echo -e "\e[32m Enable\e[0m site "
        else
            echo
            echo "  :site status unknown:  "
            echo
        fi
        echo "1. Graph log"
        echo "2. Edit nginx config"
        echo "3. Reset project"
        echo "4. Delete project"
        # Read user's choice
        echo "6. Change domain"
        echo "b. Create backup"
        echo "r. Restore back"
        echo
        read -p "Enter your choice (1-X): " choice

        # Perform action based on user's choice
        case $choice in
            0)
                clear
                IsSetProject=false
                break
                ;;
            1)
                clear
                echo
                echo "Graphing log..."
                GraphLog
                ;;
            2)    
                echo
                echo "Editing config..."
                EditConf
                ;;
                
            3)  
                clear
                echo
                echo "Resetting project..."
                test
                ;;
                
            4)
                clear
                echo
                echo "Deleting project..."
                echo
                DeleteWp
                ;;
            6)
                clear
                #grabbeddomain=$(grep -o 'server_name.*;' $nginxconfdir/$name.nginx | awk '{print $2}' | sed 's/;//')
                echo "Changing domain for project $name"
                echo
                read -p "Enter new domain: " new_domain
                echo
                GrabDomain 
                if [ -f "$nginxconfdir/$name.nginx" ]; then
                    sudo sed -i "s/server_name .*/server_name $new_domain www.$new_domain;/g" "$nginxconfdir/$name.nginx"
                    sudo sed -i "s/server_name \(.*\);/server_name \1 $new_domain;/g" "$conf_file"
                elif [ -f "$nginxdisabled/$name.nginx" ]; then
                    sudo sed -i "s/server_name .*/server_name $new_domain www.$new_domain;/g" "$nginxdisabled/$name.nginx"
                else
                    $new_domain="unkown"
                fi
                echo "Changing domain.."

                echo
                echo "succesfully changed the domain for project $name from $grabbeddomain to $new_domain"
                echo
                GrabDomain
                ;;
            'b')
                clear
                echo
                echo "Creating backup for $name"
                echo
                BackupWP
                ;;
            'r')
                clear
                echo
                echo "Restoring a backup for $name"
                echo
                RestoreWP
                ;;

            11)
                clear
                echo "Going to $names's plugins..."
                echo
                cd /var/www/sites/$name/wp-content/plugins 
                exit
                ;;
            22)
                clear
                echo "Going to $name's source..."
                echo
                cd /var/www/sites/$name 
                exit
                ;;
            33)
                clear
                echo "Going to $name's logs..."
                echo
                cd /var/www/logs/$name 
                exit
                ;;
       
            *)
                echo "Invalid choice. Please enter a number between 1 and 4."
                ;;
            esac
        if [ -f "$nginxconfdir/$name.nginx" ]; then
            case $choice in
                5)
                    clear
                    DisableConf
                    ;;
            esac
        elif [ -f "$nginxdisabled/$name.nginx" ] || [ -f "$nginxconfdir/$name.disabled" ]; then
            case $choice in
                5)
                    clear
                    echo 
                    echo -e "\e[32m Enabling site... \e[0m"
                    echo
                    sudo rm $nginxconfdir/$name.disabled
                    sudo mv $nginxdisabled/$name.nginx $nginxconfdir
                    echo
                    echo "restarting nginx..."
                    echo
                    sudo systemctl restart nginx
                    echo
                    echo "Enabled! $name"
                    echo
                    ;;
            esac
        fi

    elif [ -d "/var/www/backups/$name" ]; then
        clear
        echo
        echo "no active running site for project"
        echo 
        echo "found available backups: "
        echo
        echo
        RestoreWP

    else
        echo 
        echo "project $name doesnt exist"
        echo
        read -p "setup new project for $name? (yes or no): " create
        case $create in
            yes)
                echo "setup wordpress project for $name"
                echo
                SetupWP
                clear
                echo "successfully setup project $name"
                echo
                ;;
            no) 
                exit
                ;;
            *)
                echo "Invalid choice. cancelling"
                exit
            ;;
        esac
    fi
    done

    while [ "$IsSetProject" == "conf" ]; do 
        ProjectBanner
        echo
        echo "Welcome to config shortcut menu"
        echo
        echo " 0. Go back to main menu"
        echo
        echo "ngc.      nginx general config (/etc/nginx/nginx.conf)"
        echo "sc.       sshd config (/etc/ssh/sshd_config)"
        echo "motd.     ssh motd (/etc/motd)" 
        echo "banner.   ssh banner (/etc/ssh/banner.sh)"
        echo "passwd.   (/etc/passwd)"
        echo "bashrc.   (~/.bashrc)"
        echo "visudo"
        echo
        read -p "   What confif do you want to edit?: " conf
        case $conf in
            0)
                EditingConfig=false
                ;;
            'ngc')
                clear
                EditNginxconf
                ;;
            'sc')
                clear
                EditSshconf
                ;;
            'motd')
                clear
                EditMotd
                ;;
            'banner')
                clear
                EditBanner
                ;;
            'passwd')
                clear
                EditPasswd
                ;;
            'bashrc')
                clear
                EditBash
                ;;
            'visudo')
                clear
                EditVisudo
                ;;
            *)  
                echo
                echo "invalid choice"
                echo
                ;;
        esac
    done
done