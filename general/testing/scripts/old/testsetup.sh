#!/bin/bash

read -p "name of the server: " server_name

read -p "admin account: " admin_name
#read -p "admin password: " admin_password

sudo adduser $admin_name
sudo usermod -aG sudo $admin_name

sudo passwd $admin_name