#!/bin/bash

echo "  :server setup:"
read -p "name of the server: " server_name
read -p "Enter the location of the server: " server_location
echo

echo "$server_name" > /var/www/server_name.txt
echo "$server_location" >> /var/www/server_info.txt

new_ps1="\${debian_chroot:+(\$debian_chroot)}\[\033[01;32m\]\u@$server_name\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\\$ "
sed -i "s/^export PS1=.*/export PS1=\"$new_ps1\"/" "/etc/bash.bashrc"