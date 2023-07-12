<h1> install required dependencies </h1> 
<hr/>
<p>// update & upgrade is required to install mariadb and latest php </p>
<h4>sudo apt update -y && sudo apt upgrade -y </h4>
<p>// installs everything</p>

<h4> sudo apt install apt-transport-https lsb-release ca-certificates wget -y </h4>
<h4> sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg </h4>
<h4> sudo sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' </h4>
<h4> sudo apt update </h4>
<h4> sudo apt-get install ufw nginx mariadb-server mariadb-client curl php8.2-sqlite3 php8.2-pdo-sqlite php8.2-fpm php8.2-cli php8.2-zip php8.2-xml php8.2-dom php8.2-curl php8.2-mysqli</h4>

<p>// create shortcut for phpmyadmin in nginx default dir </p>
<h4>sudo ln -s /usr/share/phpmyadmin /var/www/phpmyadmin </h4>
<hr/>

<h2> Laravel installation guide in vps.setup </h2>

// general nginx config for php8.2, hides .html/php extensions
``` nginx
server {
    listen 80;
    server_name **;
    index index.php index.html;
    root /var/www/**;
    
    error_page 404 /index;
    error_log /var/log/nginx/**.error;
    access_log /var/log/nginx/**.access;

    location ~ [^/].php(/|$) {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        #change to your php version  ^^^ 
    }

    location / {
        try_files $uri $uri/ $uri.html $uri.php$is_args$query_string;
    }

    location ~ ^/(\.user.ini|\.htaccess|\.git|\.svn|\.project|LICENSE|README.md) {
        return 404;
    }
}
```
