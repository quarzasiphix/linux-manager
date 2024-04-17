
GetDisabledSites() {
    # Initialize an empty array to store the modified filenames
    file_names=()

    # Check if there are any .nginx files in the directory
    if ! ls "$nginxdisabled"/*.nginx &> /dev/null; then
        echo
        echo -e "   No\e[31m Disabled\e[0m websites"
        echo
        return
    fi

    # Iterate over each file in the directory
    for file in "$nginxdisabled"/*.nginx; do
        # Extract the filename without the extension
        filename=$(basename "$file" .nginx) > /dev/null 2>&1
        # Add the modified filename to the array
        file_names+=("$filename") > /dev/null 2>&1
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

    # Check if there are any .nginx files in the directory
    if ! ls "$nginxconfdir"/*.nginx &> /dev/null; then
        echo
        echo -e "   No\e[32m active\e[0m websites"
        echo
        return
    fi

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


GetMiscSites() {
    # Initialize an empty array to store the modified filenames
    file_names=()

    # Check if there are any .nginx files in the directory
    if ! ls "$nginxconfdir"/*.nginx &> /dev/null; then
        echo
        echo -e "   No\e[32m active\e[0m websites"
        echo
        return
    fi

    # Iterate over each file in the directory
    for file in "$nginxconfdir"/*; do
        # Extract the filename without the extension
        filename=$(basename "$file" .nginx)
        # Add the modified filename to the array
        file_names+=("$filename")
    done

    echo -e "   \e[32m:Misc sites websites:\e[0m"
    echo

    # Define the maximum width for the filenames
    max_width=20

    for name in "${file_names[@]}"; do
        # Get the domain

        if ! ls "$nginxconfdir"/$name.nginx &> /dev/null; then
            getdomain=$(grep -o 'server_name.*;' "$nginxconfdir/$name.nginx" | awk '{print $2}' | sed 's/;//')
        else
            echo "Config not found"
        fi
        
        # Pad the filename with spaces to ensure even alignment
        padded_name=$(printf "%-${max_width}s" "$name")

        # Print the formatted output
        echo " : $padded_name :  domain: $getdomain"
    done

    echo 
}
