<h3> Put scripts into /var/www/scripts/ </h3>
creates website in /var/www/sites/

<h5>// run these commands first:</h5>

<p>sudo chmod +x (script)wp.sh </p>

<h4>// then u can run the script:</h4>
<p>./(script)pwp.sh</p>

the script installs latest wordpress, sets up nginx config for the domain and sql database and username. 

<hr>

<h3> Backup  </h3>
<p> dumps database, nginx config and wordpress files </p>
<hr>

// nginx config
``` nginx
server {
    listen 80;
    server_name *domain*;
    root /var/www/*name*;
    index index.php;

    error_page 404 /index;
    error_log /var/log/nginx/*name*.error;
    access_log /var/log/nginx/*name*.access;

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
```
