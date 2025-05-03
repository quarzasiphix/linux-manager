GraphAllActive() {
    file_names=()

    # Iterate over each file in the directory
    for file in "$nginxconfdir"/*.nginx; do
        # Extract the filename without the extension
        filename=$(basename "$file" .nginx)
        # Add the modified filename to the array
        file_names+=("$filename")
    done

    echo "\e[31mDisabled websites:\e[0m"
    echo

    # Define the maximum width for the filenames
    max_width=20
    pubdir="/var/www/sites/goaccess"
    nginxdir="/etc/nginx/sites-enabled"

    for names in "${file_names[@]}"; do
        logdir="/var/www/logs/$names"

        outputfile="$pubdir/logs/$names-report-$(date +%F)"
        inputfile="$logdir/access.nginx"

        sudo mkdir $pubdir > /dev/null 2>&1
        sudo mkdir $pubdir/logs > /dev/null 2>&1
        sudo mkdir $pubdir/logs/$name > /dev/null 2>&1

        sudo mkdir $logdir/archive

        sudo chown -R quarza:www-data $pubdir/logs > /dev/null 2>&1
        sudo chmod -R 755 $pubdir/logs > /dev/null 2>&1

        counter=1
        while [ -f "$inputfile.html" ]; do
            ((counter++))
        done

        if [ -f "$outputfile" ]; then
            echo
            echo "$counter graph made on $(date +%F) "
            echo
            echo "graphing...."
            echo
            sudo goaccess $inputfile -o $outputfile-$counter.html --log-format=COMBINED
        else 
            echo "first graph of today $(date +%F)"
            echo
            echo "graphing..."
            echo
            sudo goaccess $inputfile -o $outputfile.html --log-format=COMBINED
        fi

        echo
        echo "done graphing for $name"
        echo

        echo "backing up current log"
        echo

        #sudo mv $inputfile $inputfile-$(date +%F)
        #sudo mv $inputfile-$(date +%F) $logdir/archive
        sudo touch $inputfile
        sudo systemctl restart nginx

        echo
        echo "done backing up log"
        echo 
    done
}