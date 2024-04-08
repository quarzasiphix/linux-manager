

GraphLog() {
    pubdir="/var/www/sites/goaccess"
    nginxdir="/etc/nginx/sites-enabled"
    logdir="/var/www/logs/$name"

    outputfile="$pubdir/logs/$name-report-$(date +%F)"
    inputfile="$logdir/access.nginx"

    sudo mkdir $pubdir > /dev/null 2>&1
    sudo mkdir $pubdir/logs > /dev/null 2>&1
    sudo mkdir $pubdir/logs/$name > /dev/null 2>&1

    sudo mkdir $logdir/archive

    sudo chown -R www-data:www-data $pubdir/logs > /dev/null 2>&1
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
    
    #echo "backing up current log"
    #echo
    #sudo mv $inputfile $inputfile-$(date +%F)
    #sudo mv $inputfile-$(date +%F) $logdir/archive
    sudo touch $inputfile
    sudo systemctl restart nginx

    echo
    echo "done backing up log"
    echo
}