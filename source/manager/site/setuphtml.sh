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

SetupHtml() {
    read -p "Enter domain: " domain
    echo

    dir="/var/www/sites/$name"
    
    safe_delete_dir "$dir"

    sudo mkdir "$dir"

    echo 
    echo "setting up template html file"
    echo
    sudo trash "$dir/index.html"
    sudo tee "$dir/index.html" > /dev/null <<EOT
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;700&display=swap">
    <style>
        body {
            margin: 0;
            padding: 0;
            background-color: #1c1a1a; /* Gray background color */
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh; /* Full viewport height */
            font-family: 'Poppins', sans-serif; /* Use Poppins font */
        }

        .welcome-text {
            font-size: 36px;
            font-weight: bold;
            text-align: center;
            color: white;
        }
    </style>
    </head>
    <body>
        <div class="welcome-text">
            <h1>Welcome to $name</h1>
        </div>
    </body>
    </html>
EOT

    echo
    echo "setting up nginx config"
    echo
    sudo chown -R quarza:www-data "$dir"
    sudo find "$dir" -type d -exec chmod 755 {} \;
    sudo find "$dir" -type f -exec chmod 644 {} \;
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
        index index.html;

        error_page 404 /index;
        error_log $nginx_log_dir/error.nginx;
        access_log $nginx_log_dir/access.nginx;
        access_log /var/log/nginx/access.log;

        location / {
            try_files \$uri \$uri/ /index.html /index.php?\$args;
        }

        location ~* /uploads/.*\.php$ {
           deny all;
        }

        location ~ ^/(\.user.ini|\.htaccess|\.git|\.svn|\.project|LICENSE|README.md) {
            deny all;
        }
    }
EOT

    # Enable the site by creating a symbolic link
    sudo ln -s "$nginx_config" "/etc/nginx/sites-enabled/$name.nginx" > /dev/null

    sudo systemctl restart nginx

    # → Obtain SSL cert
    if [ ! -d "/etc/letsencrypt/live/$domain" ]; then
        echo "🔒 Obtaining SSL for $domain"
        email=$(get_certbot_email)
        sudo certbot --nginx --non-interactive --agree-tos \
            --email "$email" --redirect -d "$domain"
    fi
}