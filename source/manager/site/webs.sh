GetDisabledSites() {
    local wp_sites=()
    local lov_sites=()
    local html_sites=()
    local other_sites=()
    local site_domains=()
    local site_types=()

    # Check if there are any .nginx files in the directory
    if ! ls "$nginxdisabled"/*.nginx &> /dev/null; then
        echo
        echo -e "   No \e[31mDisabled\e[0m websites"
        echo
        return
    fi

    echo -e "  \e[31m:Disabled websites:\e[0m"
    echo

    # Iterate over each file, determine type, and store info
    for file in "$nginxdisabled"/*.nginx; do
        local name=$(basename "$file" .nginx)
        local domain=$(grep -o 'server_name.*;' "$file" | awk '{print $2}' | sed 's/;//')
        local site_type="other" # Default type

        if [[ -d "/var/www/sources/$name" ]]; then
            site_type="lovable"
        elif [[ -f "/var/www/sites/$name/wp-config.php" ]]; then
            site_type="wordpress"
        elif [[ -d "/var/www/sites/$name" ]]; then
            site_type="html"
        fi

        case $site_type in
            lovable)
                lov_sites+=("$name:$domain")
                ;;
            wordpress)
                wp_sites+=("$name:$domain")
                ;;
            html)
                html_sites+=("$name:$domain")
                ;;
            *)
                other_sites+=("$name:$domain")
                ;;
        esac
    done

    # --- Printing Section ---
    local max_width=20
    local reset_color='\e[0m'

    # Print WordPress sites (Blue)
    if [ ${#wp_sites[@]} -gt 0 ]; then
        echo -e "    \e[34mWordPress sites:$reset_color"
        for site_info in "${wp_sites[@]}"; do
            local name=${site_info%%:*}
            local domain=${site_info#*:}
            local padded_name=$(printf "%-${max_width}s" "$name")
            echo "     : $padded_name :  domain: $domain"
        done
        echo # Add a blank line after the section
    fi

    # Print Lovable sites (Magenta)
    if [ ${#lov_sites[@]} -gt 0 ]; then
        echo -e "    \e[35mLovable sites (Git):$reset_color"
        for site_info in "${lov_sites[@]}"; do
            local name=${site_info%%:*}
            local domain=${site_info#*:}
            local padded_name=$(printf "%-${max_width}s" "$name")
            echo "     : $padded_name :  domain: $domain"
        done
        echo
    fi

    # Print HTML sites (Cyan)
    if [ ${#html_sites[@]} -gt 0 ]; then
        echo -e "    \e[36mHTML sites:$reset_color"
        for site_info in "${html_sites[@]}"; do
            local name=${site_info%%:*}
            local domain=${site_info#*:}
            local padded_name=$(printf "%-${max_width}s" "$name")
            echo "     : $padded_name :  domain: $domain"
        done
        echo
    fi

    # Print any other sites (unclassified)
    if [ ${#other_sites[@]} -gt 0 ]; then
        echo -e "    Other sites:$reset_color"
        for site_info in "${other_sites[@]}"; do
            local name=${site_info%%:*}
            local domain=${site_info#*:}
            local padded_name=$(printf "%-${max_width}s" "$name")
            echo "     : $padded_name :  domain: $domain"
        done
        echo
    fi

    # Remove final echo if no sites were printed in categories
    if [ ${#wp_sites[@]} -eq 0 ] && [ ${#lov_sites[@]} -eq 0 ] && [ ${#html_sites[@]} -eq 0 ] && [ ${#other_sites[@]} -eq 0 ]; then
      # If all arrays are empty, maybe add a message? For now, just ensures no extra blank line.
      :
    fi
}


GetActiveSites() {
    local wp_sites=()
    local lov_sites=()
    local html_sites=()
    local other_sites=()

    # Check if there are any .nginx files in the directory
    if ! ls "$nginxconfdir"/*.nginx &> /dev/null; then
        echo
        echo -e "   No \e[32mActive\e[0m websites"
        echo
        return
    fi

    echo -e "   \e[32m:Active websites:\e[0m"
    echo

    # Iterate over each file, determine type, and store info
    for file in "$nginxconfdir"/*.nginx; do
        local name=$(basename "$file" .nginx)
        local domain=$(grep -o 'server_name.*;' "$file" | awk '{print $2}' | sed 's/;//')
        local site_type="other" # Default type

        if [[ -d "/var/www/sources/$name" ]]; then
            site_type="lovable"
        elif [[ -f "/var/www/sites/$name/wp-config.php" ]]; then
            site_type="wordpress"
        elif [[ -d "/var/www/sites/$name" ]]; then
            site_type="html"
        fi

        case $site_type in
            lovable)
                lov_sites+=("$name:$domain")
                ;;
            wordpress)
                wp_sites+=("$name:$domain")
                ;;
            html)
                html_sites+=("$name:$domain")
                ;;
            *)
                other_sites+=("$name:$domain")
                ;;
        esac
    done

    # --- Printing Section ---
    local max_width=20
    local reset_color='\e[0m'

    # Print WordPress sites (Blue)
    if [ ${#wp_sites[@]} -gt 0 ]; then
        echo -e "    \e[34mWordPress sites:$reset_color"
        for site_info in "${wp_sites[@]}"; do
            local name=${site_info%%:*}
            local domain=${site_info#*:}
            local padded_name=$(printf "%-${max_width}s" "$name")
            echo "     : $padded_name :  domain: $domain"
        done
        echo
    fi

    # Print Lovable sites (Magenta)
    if [ ${#lov_sites[@]} -gt 0 ]; then
        echo -e "    \e[35mLovable sites (Git):$reset_color"
        for site_info in "${lov_sites[@]}"; do
            local name=${site_info%%:*}
            local domain=${site_info#*:}
            local padded_name=$(printf "%-${max_width}s" "$name")
            echo "     : $padded_name :  domain: $domain"
        done
        echo
    fi

    # Print HTML sites (Cyan)
    if [ ${#html_sites[@]} -gt 0 ]; then
        echo -e "    \e[36mHTML sites:$reset_color"
        for site_info in "${html_sites[@]}"; do
            local name=${site_info%%:*}
            local domain=${site_info#*:}
            local padded_name=$(printf "%-${max_width}s" "$name")
            echo "     : $padded_name :  domain: $domain"
        done
        echo
    fi

    # Print any other sites (unclassified)
    if [ ${#other_sites[@]} -gt 0 ]; then
        echo -e "    Other sites:$reset_color"
        for site_info in "${other_sites[@]}"; do
            local name=${site_info%%:*}
            local domain=${site_info#*:}
            local padded_name=$(printf "%-${max_width}s" "$name")
            echo "     : $padded_name :  domain: $domain"
        done
        echo
    fi

    if [ ${#wp_sites[@]} -eq 0 ] && [ ${#lov_sites[@]} -eq 0 ] && [ ${#html_sites[@]} -eq 0 ] && [ ${#other_sites[@]} -eq 0 ]; then
        :
    fi
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

GrabDomain() {
    if [[ -d "/var/www/sources/$name" ]]; then
        echo "Project '$name' doesn't exist, and no backups found."
        echo
        # loop until a valid choice is made
        while true; do
          echo "Choose project type to create:"
          echo "  wp    – WordPress project"
          echo "  html  – Blank HTML project"
          echo "  lov   – Lovable project (Git + build)"
          echo "  no/0  – Cancel"
          read -rp "Setup new project for '$name'? " opt
          case "${opt,,}" in
            wp)
              SetupWP
              break
              ;;
            html)
              SetupHtml
              break
              ;;
            lov)
              SetupLov
              break
              ;;
            no|0)
              echo "Project creation canceled."
              return 1
              ;;
            *)
              echo "Invalid option: '$opt'. Please enter wp, html, lov or no/0."
              ;;
          esac
        done
    fi
}
