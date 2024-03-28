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
sudo mkdir ~/.ssh
sudo chmod 700 ~/.ssh
sudo touch ~/.ssh/authorized_keys
sudo chown $admin_name:$admin_name ~/.ssh
sudo chown $admin_name:$admin_name ~/.ssh/authorized_keys
sudo nano ~/.ssh/authorized_keys