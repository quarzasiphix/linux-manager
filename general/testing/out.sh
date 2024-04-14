#!/bin/bash

# Read server name from the file
#server_name=$(sed -n '1p' server_name.txt)
server_name=$(</var/www/server_name.txt)

# Read server location from the file
server_location=$(</var/www/server_info.txt)

#server_location=$(sed -n '2p' server_info.txt)

# Print both server name and location
echo "Server Name: $server_name"
echo "Server Location: $server_location"
