#!/bin/bash
sourceurl="https://raw.githubusercontent.com/quarzasiphix/linux-manager/master/source"

# Define the file path
scriptsdir="/var/www/scripts/downloader"
scriptsurl="$sourceurl/downloader/scripts"
versionurl="$sourceurl/version.txt"
file="$scriptsdir/scripts"

# Initialize empty arrays
general=()
server=()
site=()

# Flag to indicate which array to add lines to
url="https://raw.githubusercontent.com/quarzasiphix/linux-manager/master/source/manager"
dir="/var/www/scripts/manager"

echo "setting up dir env.."
sudo rm -R "$dir"

sudo mkdir "$dir"
sudo mkdir "$dir/site"
sudo mkdir "$dir/server"
sudo mkdir "$dir/menus"

sudo chmod 777 -R "$dir"


current_array="general"
echo "getting latest list of scripts..."
sudo rm "$file"
#sudo mkdir "$scriptsdir"

#sudo ln -s /var/www/scripts/general.sh

echo
echo "  file: $file"
echo
sudo curl -o "$file" "$scriptsurl"
echo "done"
echo

echo
echo "  Downloading scripts from list..."
echo

#sudo curl -o "/var/www/scripts/start_manager.sh" "https://raw.githubusercontent.com/quarzasiphix/server-setup/master/general/scripts/start_manager.sh" > /dev/null 2>&1
#udo chmod +x /var/www/scripts/start_manager.sh

#get version:
echo
echo "getting version.."
echo
sudo curl -o "$dir/version.txt" "https://raw.githubusercontent.com/quarzasiphix/linux-manager/master/source/version.txt" > /dev/null 2>&1
sudo chmod 777 "$dir/version.txt"
current_version=$(cat $dir/version.txt)
echo -e "version: \e[32m$current_version\e[0m"
# Read each line from the file

while IFS= read -r line; do
    # Check if the line contains "server"
    if [[ "$line" == "server" ]]; then
        current_array="server"
    elif [[ "$line" == "site" ]]; then
        current_array="site"
    elif [[ "$line" == "menus" ]]; then
        current_array="menus"
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
            sudo curl -o "$dir/$current_array/$line.sh" "$url/$current_array/$line.sh" > /dev/null
            sudo chmod +x "$dir/$current_array/$line.sh"
            echo "done downloading $line"
            echo
            server+=("$line")
        fi
    fi
done < "$file"

echo
echo "opening script post download..."
echo

sudo ln -s $dir/main.sh /var/www/scripts/start_manager > /dev/null 2>&1

/var/www/scripts/start_manager
