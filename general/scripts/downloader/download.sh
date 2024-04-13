#!/bin/bash

# Define the file path
scriptsdir="/var/www/scripts/new/downloader"
scriptsurl="https://raw.githubusercontent.com/quarzasiphix/server-setup/master/general/scripts/downloader/scripts"
file="$scriptsdir/scripts"

# Initialize empty arrays
general=()
server=()
site=()

# Flag to indicate which array to add lines to
url="https://raw.githubusercontent.com/quarzasiphix/server-setup/master/general/scripts/general"
dir="/var/www/scripts/new/general"

echo "setting up dir env.."
sudo rm -R "$dir"

sudo mkdir "$dir"
sudo mkdir "$dir/site"
sudo mkdir "$dir/server"

sudo chmod 777 -R "$dir"


current_array="general"
echo "getting latest list of scripts..."
sudo rm "$file"
#sudo mkdir "$scriptsdir"


echo
echo "  file: $file"
echo
sudo curl -o "$file" "$scriptsurl"
echo "done"
echo

echo
echo "  Downloading scripts from list..."
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
            sudo curl -o "$dir/$line.sh" "$url/$line.sh" > /dev/null 2>&1
            sudo chmod +x "$dir/$line.sh"
            echo "done downloading $line"
            echo
            general+=("$line")
        else 
            echo
            echo "downloading $current_array script $line..."
            sudo curl -o "$dir/$current_array/$line.sh" "$url/$current_array/$line.sh" > /dev/null 2>&1
            sudo chmod +x "$dir/$current_array/$line.sh"
            echo "done downloading $line"
            echo
            server+=("$line")
        fi
    fi
done < "$file"

clear
echo
echo "opening script post download..."
echo

$dir/general.sh