SetupWP() {
    # Check if name is empty
    dir="/var/www/sites/$name"
    if [ -z "$name" ]; then
        echo
        echo "Error: Project name is empty. Exiting..."
        echo
        return 1
    fi
    # Get domain
    read -p "Enter domain: " domain
    if [[ ! "$domain" =~ ^[a-zA-Z0-9.-]+$ ]]; then
        echo "Invalid domain name."
        return 1
    fi
    echo

    # Get database password
    read -sp "Enter Project password: " password
    echo
    
    echo "setting up wordpress"


    # Download WordPress
    sudo rm latest.tar.gz
    echo "downloading wordpress files... "
    echo
    sudo wget https://wordpress.org/latest.tar.gz
    
    sudo mkdir "/var/www/backups/temp-old"
    sudo mv "$dir" "/var/www/backups/temp-old"
    sudo mkdir "$dir"
    echo
    echo "extracting wordpress files... "
    echo
    sudo tar -xvzf latest.tar.gz --strip-components=1 -C "$dir" > /dev/null
    echo "finished extracting wp files.. setting up perms"

    echo
    echo "setting up database"
    echo

    # Setup database
    sudo mysql -u root <<EOF
    DROP DATABASE IF EXISTS $name;
    CREATE DATABASE $name;
    DROP USER IF EXISTS '$name'@'localhost';
    CREATE USER '$name'@'localhost' IDENTIFIED BY '$password';
    GRANT ALL PRIVILEGES ON $name.* TO '$name'@'localhost';
    FLUSH PRIVILEGES;
    \q
EOF
    # Use WP-CLI to configure WordPress
    # Force https and allow 512mb file size
    dbprefix="${name:0:1}${name: -1}_"
    sudo wp core config --allow-root --path="$dir" --dbname="$name" --dbuser="$name" --dbpass="$password" --dbprefix="$dbprefix" --dbhost="localhost" --extra-php <<PHP
    define( 'WP_MEMORY_LIMIT', '512M' );
    \$_SERVER['HTTPS'] = 'on';
PHP
    sudo chmod 600 "$dir/wp-config.php" > /dev/null

    echo
    sudo chown -R quarza:www-data "$dir"
    sudo find "$dir" -type d -exec chmod 755 {} \;
    sudo find "$dir" -type f -exec chmod 644 {} \;
    sudo chmod 640 "$dir/wp-config.php"

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
        access_log /var/log/nginx/access.log;

        location / {
            try_files \$uri \$uri/ /index.php?\$args;
        }

        location ~* /uploads/.*\.php$ {
            deny all;
        }
        
        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        }

        location ~ ^/(\.user.ini|\.htaccess|\.git|\.svn|\.project|LICENSE|README.md) {
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

    echo 
    echo "Clearing plugins folder"
    sudo rm -rf "$dir/wp-content/plugins/*"
    echo

    echo
    echo "Dowloading Pluginer"
    echo

    #downloading my own pluginer
    #REPO_URL="https://github.com/quarzasiphix/WPpluginer"
    #sudo rm "/var/www/libs/pluginer.zip"  > /dev/null
    #sudo curl -L "$REPO_URL/archive/refs/heads/main.zip" -o "/var/www/libs/pluginer.zip"
    #sudo unzip -o "/var/www/libs/pluginer.zip" "/var/www/libs/" 
    
    
    echo
    sudo cp -R "/var/www/libs/WPpluginer-main/ecom-site" "$dir/wp-content/plugins/"
    sudo cp -R "/var/www/libs/WPpluginer-main/standard-site" "$dir/wp-content/plugins/"
    
    sudo cp -R /var/www/libs/elementor-pro "$dir/wp-content/plugins/"
    sudo cp -R /var/www/libs/kera $dir/wp-content/themes/    

    echo
    echo "Setting permissions"
    echo 

    sudo chown -R quarza:www-data "$dir"
    sudo find "$dir" -type d -exec chmod 755 {} \;
    sudo find "$dir" -type f -exec chmod 644 {} \;

    echo
    echo "initialising project with wp cli.."
    echo

    echo 
    echo "Project config initialised.."
    echo

    echo
    echo "Project $name setup succesfully"
    echo
}
