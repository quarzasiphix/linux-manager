SetupHtml() {
    read -p "Enter project name: " name
    echo

    read -p "Enter domain: " domain
    echo

    dir="/var/www/sites/$name"
    
    sudo mkdir "$dir"

    echo 
    echo "setting up template html file"
    echo

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
            background-color: #f0f0f0; /* Gray background color */
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

        location / {
            try_files \$uri \$uri/ /index.html /index.php?\$args;
        }

        location ~ ^/(\.user.ini|\.htaccess|\.git|\.svn|\.project|LICENSE|README.md) {
            deny all;
        }
    }
EOT

    # Enable the site by creating a symbolic link
    sudo ln -s "$nginx_config" "/etc/nginx/sites-enabled/$name.nginx" > /dev/null

    sudo systemctl restart nginx
}