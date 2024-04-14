#!/bin/bash
read -p "Enter the name of the server: " server_name
read -p "Enter the location of the server: " server_location


echo "$server_name" > /var/www/server_name.txt
echo "$server_location" >> /var/www/server_info.txt