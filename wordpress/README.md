<h3> Setup script - put setupwp.sh file into /var/www/ </h3>

<h5>// run these commands first:</h5>
<p>sudo curl -O https://github.com/quarzasiphix/server-setup/blob/master/wordpress/setupwp.sh -o setupwp.sh </p>
<p>sudo apt-get install dos2unix </p>
<p>sudo dos2unix setupwp.sh </p>
<p>sudo chmod +x setupwp.sh </p>

<h4>// then u can run the script:</h4>
<p>./setupwp.sh</p>

the script installs latest wordpress, sets up nginx config for the domain and sql database and username. 

<hr>

<h3> Backup - put createwpbackup.sh /var/www </h3>
<h5> Run this command first: </h5>
<p> sudo chmod +x createwpbackup.sh </p>
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
