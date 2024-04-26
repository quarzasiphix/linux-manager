comments() {


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

}

ConfigServer() {
    echo
    echo "  :server setup:"
    read -p "name of the server: " server_name
    read -p "Enter the location of the server: " server_location
    echo

    echo "$server_name" > /var/www/server/name.txt
    echo "$server_location" >> /var/www/server/info.txt



    sudo tee "/var/www/scripts/banner.sh" > /dev/null <<EOT
    clear
    export PATH=$PATH:/var/www/scripts/manager
    echo
    echo
    echo
    echo    "  =================================== "
    echo
    echo -e "             Hello\e[36m $USER \e[0m"
    echo
    echo -e "         Welcome\e[95m to Web wiz \e[0m"
    echo
    echo    "  =================================== "
    echo
    echo
    echo
EOT

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

    sudo chmod -R 777 /var/www/
}

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



wwwdir="/var/www"


if [ ! -d "$directory" ]; then
    echo
    echo "main directory /var/www/ not found.. setting up."
    echo
    SetupDirs
    echo
else 
    echo
    echo "directories found.."
    echo
fi

if [ ! -d "$directory/server" ]; then
    echo
    echo "server config not found.."
    echo
    ConfigServer
fi

if [ ! -d "$directory/sites/goaccess" ]; then
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

