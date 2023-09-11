#!/bin/bash

# Get MySQL root password
read -sp "Enter MySQL root password: " mysql_password
echo

# Get name
read -p "Enter name: " name
echo

# Get domain
read -p "Enter domain: " domain
echo

# Get database password
read -sp "Enter password: " dbpasss
echo

# Download WordPress
echo "Deleting previous WordPress tar"
sudo rm latest.tar.gz
sudo wget https://wordpress.org/latest.tar.gz

sudo rm -R "../sites/$name"
# Create directory
sudo mkdir "../sites/$name"

# Extract files
sudo tar -xvzf latest.tar.gz --strip-components=1 -C "./$name"

# Set ownership
sudo chown -R www-data:www-data "../sites/$name"

# Set permissions
sudo chmod -R 755 "../sites/$name"

# Setup database
sudo mysql -u root -p$mysql_password <<EOF
DROP DATABASE IF EXISTS $name;
CREATE DATABASE $name;
DROP USER IF EXISTS '$name'@'localhost';
CREATE USER '$name'@'localhost' IDENTIFIED BY '$dbpasss';
GRANT ALL PRIVILEGES ON $name.* TO '$name'@'localhost';
FLUSH PRIVILEGES;
\q
EOF

echo
echo "Setting up Nginx config"
echo

# Create Nginx configuration file
nginx_config="/etc/nginx/sites-available/$name.nginx"
sudo rm "$nginx_config"
sudo tee "$nginx_config" > /dev/null <<EOT
server {
    listen 80;
    server_name $domain www.$domain;
    root /var/www/$name;
    index index.php;

    error_page 404 /index;
    error_log /var/log/nginx/$name.error;
    access_log /var/log/nginx/$name.access;

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
sudo ln -s "$nginx_config" "/etc/nginx/sites-enabled/$name.nginx"

# Restart Nginx
sudo systemctl restart nginx

echo
echo "Created WordPress project $name"
echo

# Wait until wp-config.php has <?php tag on the first line
echo "waiting on user to initialise project on $domain/admin"
echo
while ! head -n 1 "$name/wp-config.php" 2>/dev/null | grep -q "^<?php"; do
    sleep 1
done


# Add $_SERVER["HTTPS"] = "on"; on the second line
sudo sed -i '2i$_SERVER["HTTPS"] = "on";' "$name/wp-config.php"

echo
echo initialised https, project $name setup succesfully
echo
