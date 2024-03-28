#!/bin/bash
echo
echo "  :server setup:"
read -p "name of the server: " server_name
read -p "Enter the location of the server: " server_location
echo

sudo rm -r /var/www/server/
sudo mkdir /var/www/server/
sudo chmod -R 777 /var/www/server

sudo echo "$server_name" > /var/www/server/name.txt
sudo echo "$server_location" >> /var/www/server/info.txt

new_ps1='${debian_chroot:+($debian_chroot)}\\[\\033[01;32m\\]\\u@'"$server_name"'\\[\\033[00m\\]:\\[\\033[01;34m\\]\\w\\[\\033[00m\\]\\$ '

# Use sed to replace the PS1 line in /etc/bash.bashrc
sudo sed -i "s|^\\( *PS1=.*\\)$|PS1=\"$new_ps1\"|" "/etc/bash.bashrc"

source /etc/bash.bashrc
