
#    echo "  setup sudo account"
#    read -p "admin account: " admin_name
#
#    #echo
#    #echo "setting up admin: $admin_name"
#    #echo
# #   #sudo adduser $admin_name
# #   #sudo usermod -aG sudo $admin_name#
#
#    bashrc="/home/$admin_name/.bashrc"###
#
#    # Backup the original .bashrc file
#    cp "$bashrc" "$bashrc.bak"##
#
#    # Remove every instance of PS1 in the .bashrc file
#    sed -i '/PS1=/d' "$bashrc"#
#
#    echo
#    new_ps1="\${debian_chroot:+(\$debian_chroot)}\[\033[01;32m\]\u@$server_name\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\\$ "
#    sudo sed -i "s/^export PS1=.*/export PS1=\"$new_ps1\"/" "/etc/bash.bashrc"
#    echo
#    echo "PS1 line replaced with: $new_ps1"
#    echo


SetupGoaccess() {
    echo
    read -p "domain for goaccess: " godomain
    echo
    sudo tee "/etc/nginx/sites-enabled/goaccess.nginx" > /dev/null <<EOT
        server {
            listen 80;
            server_name $godomain;

            root /var/www/sites/goaccess;  # Replace this with the actual path to your directory containing report.html
            index report.html;

            location / {
                try_files \$uri \$uri/ =404;
            }

            location /logs {
                autoindex on;
                try_files \$uri \$uri/ =404;
            }

            location /backups {
                autoindex on;
                try_files \$uri \$uri/ =404;
            }
        }
EOT

}

#!/bin/bash

# Declare admin_name as a global variable
admin_name=""

SetupTerminal() {
    s_name=$(</var/www/server/name.txt)
    sudo tee "/var/www/scripts/banner.sh" > /dev/null <<EOT
    export PATH=\$PATH:/var/www/scripts/manager
    clear
    PS1="\${debian_chroot:+(\$debian_chroot)}\[\033[01;32m\]\u@$s_name\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\\$ "
    echo
    echo
    echo
    echo    "  =================================== "
    echo
    echo -e "             Hello\e[36m $USER \e[0m"
    echo
    echo -e "         Welcome to\e[95m Web wiz \e[0m"
    echo
    echo    "  =================================== "
    echo
    echo
    echo
EOT
    sudo chmod +x /var/www/scripts/banner.sh
    #add post auth banner script
    echo "source /var/www/scripts/banner.sh" | sudo tee -a /etc/bash.bashrc > /dev/null
}


SetupSsh() {
    echo
    echo "setting up ssh for admin: $admin_name"
    echo

    #setup ssh
    udir="/home/$admin_name"
    sudo mkdir $udir/.ssh
    sudo chmod 700 $udir/.ssh
    sudo touch $udir/.ssh/authorized_keys
    sudo chown $admin_name:$admin_name $udir/.ssh
    sudo chown $admin_name:$admin_name $udir/.ssh/authorized_keys
    sudo nano $udir/.ssh/authorized_keys


    #ssh security
    echo
    echo "securing ssh"
    echo

    #backup current config
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    #disable password auth and only allow key auth
    sudo sed -i -E 's/^#?(PasswordAuthentication)\s+(yes|no)/\1 no/' /etc/ssh/sshd_config
    sudo sed -i -E 's/^#?(PubkeyAuthentication)\s+(yes|no)/\1 yes/' /etc/ssh/sshd_config 
    #disables root login
    sudo sed -i -E 's/^#?(PermitRootLogin)\s+(yes|no)/\1 no/' /etc/ssh/sshd_config
    sudo systemctl restart sshd
    SetupTerminal
}

SetupAdmin() {
    echo
    echo
    echo "  setup sudo account"
    read -p "admin account name: " admin_name

    echo
    echo "setting up admin: $admin_name"
    echo
    sudo adduser $admin_name
    sudo usermod -aG sudo $admin_name

    SetupSsh
}

Download() {
    echo
    echo "installing every required program"
    echo

    #install everything
    sudo apt install apt-transport-https lsb-release ca-certificates wget -y > /dev/null
    sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg > /dev/null
    sudo sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' > /dev/null
    sudo wget -O - https://deb.goaccess.io/gnugpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/goaccess.gpg >/dev/null
    sudo echo "deb [signed-by=/usr/share/keyrings/goaccess.gpg arch=$(dpkg --print-architecture)] https://deb.goaccess.io/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/goaccess.list > /dev/null
    echo
    echo "running apt update and upgrade..."
    echo
    sudo apt update > /dev/null
    echo
    echo "Downloading..."
    echo
    #download wp cli
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    sudo mv wp-cli.phar /usr/local/bin/wp
    sudo apt-get install --assume-yes ufw screen unzip neofetch zip trash-cli nginx curl mariadb-server mariadb-client curl php8.2-sqlite3 php8.2-gd php8.2-mbstring php8.2-pdo-sqlite php8.2-fpm php8.2-cli php8.2-soap php8.2-zip php8.2-xml php8.2-dom php8.2-curl php8.2-mysqli > /dev/null
}


SetupDisabled() {
    sudo mkdir /etc/nginx/disabled
    sudo chmod -R 777 /etc/nginx/disabled

    sudo tee "/etc/nginx/sites-enabled/default" > /dev/null <<EOT
server {
    listen 80 default_server;
    server_name _;

    location / {
        root /var/www/sites/disabled;
        index index.html;
    }
}
EOT

    sudo tee "/var/www/sites/disabled/index.html" > /dev/null <<EOT
<!DOCTYPE html>
<html lang="en">
<head>
    <link href="https://fonts.googleapis.com/css2?family=Poppins&display=swap" rel="stylesheet">
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: 'Poppins', sans-serif;
            background-color: #0d0d0d; /* Light gray background */
            text-align: center;
        }

        .header {
            color: #ffffff; /* White font color */
            text-alrgb(0, 0, 0) center;
            padding: 20px 0; /* Top and bottom padding of 20 pixels, no left and right padding */
        }
    </style>
</head>
<body>

<div class="header">
    <h1>This site is disabled</h1>
</div>

</body>
</html>
EOT

}


ConfigServer() {
    echo
    echo "  :server setup:"
    read -p "name of the server: " server_name
    read -p "Enter the location of the server: " server_location
    echo
    server_dir="/var/www/server"
    sudo mkdir -p "$server_dir"
    sudo chmod 777 -R $server_dir

    echo "$server_name" > /var/www/server/name.txt
    echo "$server_location" > /var/www/server/info.txt
    sudo chmod 777 -R $server_dir
    
    sudo mkdir -p "/var/www/scripts/"
    sudo chmod 777 -R "/var/www/scripts/"

    sudo tee "/var/www/scripts/banner.sh" > /dev/null <<EOT
    export PATH=\$PATH:/var/www/scripts/manager
    clear
    echo
    echo
    echo
    echo    "  =================================== "
    echo
    echo -e "             Hello\e[36m \$USER \e[+0m"
    echo
    echo -e "         Welcome to\e[95m Web wiz \e[0m"
    echo
    echo    "  =================================== "
    echo
    echo
    echo
EOT
    read -p "admin account name: " admin_name
    SetupSsh
    #read -p "setup admin account?: " setadmin
    #case $setadmin in
    #'yes')
    #;;
    #esac

}

SetupDirs() {
    #setup directories
    echo
    echo "setting up directories"
    echo

    sudo mkdir /var/www/
    sudo mkdir /var/www/sites/
    sudo mkdir /var/www/scripts/
    sudo mkdir /var/www/backups/
    sudo mkdir /var/www/libs/
    sudo mkdir /var/www/logs/
    sudo mkdir /var/www/disabled/
    sudo mkdir /var/www/admin/
    sudo mkdir /var/www/server/
    sudo mkdir /var/www/sites/disabled

    sudo chmod -R 777 /var/www/
}

wwwdir="/var/www"

read -p "is this a new server setup?: " newserv
case $newserv in
'yes')
    echo
    echo "new server ight"
    echo
    Download
    ConfigServer
    SetupDisabled
;;
*)
    echo
    echo "ight, we'll see about that"
    ConfigServer
    SetupDirs
    echo
;;
esac

echo
echo "checking directories.."
echo

if [ ! -d "$wwwdir" ]; then
    echo
    echo "main directory /var/www/ not found.. setting up."
    echo
    echo
else 
    echo
    echo "directories found.."
    echo
fi

if [ ! -d "$wwwdir/server" ]; then
    echo
    echo "server config not found.."
    echo
else
    echo
    echo "server config located.."
    echo
fi

if [ ! -d "$wwwdir/sites/goaccess" ]; then
    echo
    echo "go access not found.."
    echo
    read -p "setup goaccess: " goa
    case $goa in
    'yes')
        echo
        echo "starting go access config..."
        echo
        SetupGoaccess
    ;;
    *)
        echo
        echo "ight, moving on"
        echo
    ;;
    esac
fi

echo
echo "downloading script manager.."
echo

dir="/var/www/scripts"

sudo rm -R $dir/downloader
sudo mkdir $dir/downloader
sudo chmod 777 -R $dir

dwldir="$dir/downloader"
dwlurl="https://raw.githubusercontent.com/quarzasiphix/linux-manager/master/source/downloader/download.sh"
#remove previous if exists
sudo rm $dwldir/download.sh
sudo curl -o "$dwldir/download.sh" "$dwlurl"
sudo chmod +x $dwldir/download.sh

echo
echo "running download script..."
echo

$dwldir/download.sh

