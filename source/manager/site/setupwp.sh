SetupWP() {
    # Get domain
    read -p "Enter domain: " domain
    echo

    # Get database password
    read -sp "Enter Project password: " password
    echo

    dir="/var/www/sites/$name"
    
    echo "setting up wordpress"

    # Download WordPress
    sudo rm latest.tar.gz
    echo "downloading wordpress files... "
    echo
    sudo wget https://wordpress.org/latest.tar.gz
    sudo rm -R "$dir"
    sudo mkdir "$dir"
    echo "$password" | sudo tee "$dir/password.txt" > /dev/null
    echo
    echo "extracting wordpress files... "
    echo
    sudo tar -xvzf latest.tar.gz --strip-components=1 -C "$dir" > /dev/null
    echo "finished extracting wp files.. setting up perms"
    echo
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
    CREATE USER '$name'@'localhost' IDENTIFIED BY '$password';
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

        location ~ /\.(ht|txt)$ {
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
    echo "waiting on user to initialise project on $domain"
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
