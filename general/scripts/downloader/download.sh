#!/bin/bash

# Define the file path
file="scripts"

# Initialize empty arrays
general=()
server=()
site=()

# Read each line from the file
while IFS= read -r scripts; do
    # Check if the line contains "server"
    general+=("$scripts")

    if [[ "$scripts" == *"server"* ]]; then
    while scripts != "site"; then do
    server+=($scripts)
    done
    while scripts != sites
    site+=("$scripts")

    else
        # Add the line to the lines array
    fi
done < "$file"

# Read each line from the file
while IFS= read -r server; do
    # Check if the line contains "server"
    if [[ "$server" == *"site"* ]]; then
        # Break the loop if "server" is found
        break
    else
        # Add the line to the lines array
        servers+=("$server")
    fi
done < "$file"


# Read each line from the file
while IFS= read -r site; do
    sites+=("$site")
done < "$file"


# Print the lines array
echo "general scripts:"
printf '%s\n' "${generals[@]}"

# Print the files array
echo "server scripts:"
printf '%s\n' "${servers[@]}"
echo
# Print the files array
echo "site scripts:"
printf '%s\n' "${sites[@]}"

