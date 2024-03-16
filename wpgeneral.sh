#!/bin/bash

nginxconfdir="/etc/nginx/sites-enabled"
nginxdisabled="/etc/nginx/disabled"

DeleteWp() {
    # Confirm deletion
    echo "Are you sure you want to delete project '$name'?"
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

    sudo chown -R www-data:www-data $pubdir/logs > /dev/null 2>&1
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
    sudo tar -xvzf latest.tar.gz --strip-components=1 -C "$dir" 2>&1
    sudo chown -R www-data:www-data "$dir"
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

    grabbeddomain=$(grep -o 'server_name.*;' $nginxconfdir/$name.nginx | awk '{print $2}' | sed 's/;//')
    echo
    echo "setting up config for $name on $grabbeddomain to disabled page"
    echo
    echo ...
    sudo mv $nginxconfdir/$name.nginx $nginxdisabled 
    sudo tee "$nginxconfdir/$name.disabled" > /dev/null << EOT
server {
    listen 80;
    server_name $grabbeddomain www.$grabbeddomain;
    root /var/www/sites/disabled;
    index index.html;
}
EOT
    echo
    echo "Made config for $name to disabled route"
    echo
    echo "restarting nginx..."
    sudo systemctl restart nginx
    echo
    echo "Disabled! $name"
}

clear

echo "Welcome to the project management tool!"

# Ask user to type in a name
read -p "Project name: " name

source="/var/www/sites/$name"

# Present options to the user
while true; do
if [ -d "$source" ]; then
    echo
    echo "What would you like to do to $name?"
    echo
    echo "1. Graph log"
    echo "2. Edit nginx config"
    echo "3. Reset project"
    echo "4. Delete project"
    if [ -f "$nginxconfdir/$name.nginx" ]; then
        echo "5. Disble site"
    elif [ -f "$nginxdisabled/$name.nginx" ]; then
        echo "5. Enable site"
    else
        echo
        echo "  :site status unknown:  "
        echo
    fi
    # Read user's choice
    read -p "Enter your choice (1-5): " choice

    # Perform action based on user's choice
    case $choice in
        1)
            clear
            echo "Graphing log..."
            GraphLog
            ;;
        2)    
            echo "Editing config..."
            EditConf
            ;;
            
        3)  
            clear
            echo "Resetting project..."
            test
            ;;
            
        4)
            clear
            echo "Deleting project..."
            DeleteWp
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
                echo "Enabling site.."
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
