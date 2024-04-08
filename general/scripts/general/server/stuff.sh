source graphlogs.sh

GetDisabledSites() {
    # Initialize an empty array to store the modified filenames
    file_names=()

    # Iterate over each file in the directory
    for file in "$nginxdisabled"/*.nginx; do
        # Extract the filename without the extension
        filename=$(basename "$file" .nginx)
        # Add the modified filename to the array
        file_names+=("$filename")
    done

    echo -e "  \e[31m:Disabled websites:\e[0m"
    echo

    # Define the maximum width for the filenames
    max_width=20

    for name in "${file_names[@]}"; do
        # Get the domain
        getdomain=$(grep -o 'server_name.*;' "$nginxdisabled/$name.nginx" | awk '{print $2}' | sed 's/;//')
        
        # Pad the filename with spaces to ensure even alignment
        padded_name=$(printf "%-${max_width}s" "$name")

        # Print the formatted output
        echo " : $padded_name :  domain: $getdomain"
    done

    echo 
}


GetActiveSites() {
    # Initialize an empty array to store the modified filenames
    file_names=()

    # Iterate over each file in the directory
    for file in "$nginxconfdir"/*.nginx; do
        # Extract the filename without the extension
        filename=$(basename "$file" .nginx)
        # Add the modified filename to the array
        file_names+=("$filename")
    done

    echo -e "   \e[32m:Active websites:\e[0m"
    echo

    # Define the maximum width for the filenames
    max_width=20

    for name in "${file_names[@]}"; do
        # Get the domain
        getdomain=$(grep -o 'server_name.*;' "$nginxconfdir/$name.nginx" | awk '{print $2}' | sed 's/;//')
        
        # Pad the filename with spaces to ensure even alignment
        padded_name=$(printf "%-${max_width}s" "$name")

        # Print the formatted output
        echo " : $padded_name :  domain: $getdomain"
    done

    echo 
}

EditSshconf() {
    sudo vim /etc/ssh/sshd_config
    echo
    echo "restarting ssh to confirm changes..."
    sudo systemctl restart sshd 
    echo
    echo "done"
    echo
}

EditMotd() {
    sudo vim /etc/motd
    echo
    echo "restarting ssh to confirm changes..."
    sudo systemctl restart sshd 
    echo
    echo "done"
    echo
}

EditBanner() {
    sudo vim /etc/ssh/banner.sh
    echo
    echo "restarting ssh to confirm changes..."
    sudo systemctl restart sshd 
    echo
    echo "done"
    echo
}

EditNginxconf() {
    sudo vim /etc/nginx/nginx.conf
    echo
    echo "restarting nginx to confirm changes..."
    sudo systemctl restart nginx 
    echo
    echo "done"
    echo
}

EditPasswd() {
    sudo vim /etc/passwd
    echo
    echo "done"
    echo
}

EditBash() {
    sudo vim ~/.bashrc
    echo
    echo "done"
    echo
}

EditVisudo() {
    sudo visudo
    echo
    echo "done"
    echo
}
