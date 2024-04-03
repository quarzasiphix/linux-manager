#!/bin/bash

# Define the file path
file="scripts"

# Initialize empty arrays
general=()
server=()
site=()

# Flag to indicate which array to add lines to
current_array="general"

url="https://raw.githubusercontent.com/quarzasiphix/server-setup/master/general/scripts/general"

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
            curl -O $url/$line.sh
            general+=("$line")
        elif [ "$current_array" == "server" ]; then
            server+=("$line")
        elif [ "$current_array" == "site" ]; then
            site+=("$line")
        fi
    fi
done < "$file"


##run_curl_requests() {
#    local array_name="$1"
#    echo "Running curl requests for $array_name..."
#    for name in "${!array_name[@]}"; do
#        curl -O "https://github.com/$name"
#    done
#}#

# Run curl requests through each array
#run_curl_requests general
#run_curl_requests server
#run_curl_requests site

