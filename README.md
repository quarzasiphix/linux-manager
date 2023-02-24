--- install required dependencies ---
<p>// update & upgrade is required to install mariadb and latest php </p>
<h4>sudo apt update -y && sudo apt upgrade -y </h4>
<p>// installs everything, default php on debian is 7.4 (matches with config)</p>
<h4>sudo apt-get install ufw nginx mariadb-server mariadb-client curl php-fpm php-cli php-zip php-xml php-dom phpmyadmin</h4>


<h3> Laravel installation guide in vps.setup </h3>

// general nginx config for php7.4 
``` nginx
server {
    listen 80;
    server_name quarry;
    index index.php index.html;
    root /var/www/html;
    
    error_page 404 /index.php;

    location ~ [^/].php(/|$) {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
    }

    location / {
        try_files $uri $uri/ $uri.html $uri.php$is_args$query_string;
    }

    location ~ ^/(\.user.ini|\.htaccess|\.git|\.svn|\.project|LICENSE|README.md)
    {
        return 404;
    }
}
```

