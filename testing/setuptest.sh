#!/bin/bash

read -p "name of the server: " server_name

read -p "admin account: " admin_name

#read -p "admin password: " admin_password

echo
echo "setting up admin: $admin_name"
echo

sudo adduser $admin_name
sudo usermod -aG sudo $admin_name

#sudo passwd $admin_name
echo
echo "setting up ssh for admin"
echo

#setup ssh
dir="/home/$admin_name"
sudo mkdir $dir/.ssh
sudo chmod 700 $dir/.ssh
sudo touch $dir/.ssh/authorized_keys
sudo chown $admin_name:$admin_name $dir/.ssh
sudo chown $admin_name:$admin_name $dir/.ssh/authorized_keys
sudo nano $dir/.ssh/authorized_keys

