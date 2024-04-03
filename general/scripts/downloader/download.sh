#!/bin/bash

# Define the file path
scriptsdir="/var/www/scripts/new/downloader/scripts"
scriptsurl="https://raw.githubusercontent.com/quarzasiphix/server-setup/master/general/scripts/downloader/scripts"
file="$scriptsdir"

# Initialize empty arrays
general=()
server=()
site=()

# Flag to indicate which array to add lines to
url="https://raw.githubusercontent.com/quarzasiphix/server-setup/master/general/scripts/general"
dir="/var/www/scripts/new/general"

current_array="general"

echo "getting latest list of scripts..."
sudo rm "$scriptsdir"
curl -o "$scriptsdir" "$scriptsurl"
echo "done"
echo

echo
echo "grabbing list of scripts..."
echo

# Read each line from the file
while IFS= read -r line; do
    # Check if the line contains "server"
    if [[ "$line" == *"server"* ]]; then
        # Change the current array to server
        current_array="server"
    elif [[ "$line" == *"site"* ]]; then
        # Change the current array to site
        current_array="site"
    else
        # Add the line to the current array
        if [ "$current_array" == "general" ]; then
            echo
            echo "downloading general script $line..."
            curl -o "$dir/$line.sh" "$url/$line.sh" > /dev/null 2>&1
            echo "done downloading $line"
            echo
            general+=("$line")
        else 
            echo
            echo "downloading $current_array script $line..."
            curl -o "$dir/$current_array/$line.sh" "$url/$current_array/$line.sh" > /dev/null 2>&1
            echo "done downloading $line"
            echo
            server+=("$line")
        fi
    fi
done < "$file"
