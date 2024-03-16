#!/bin/bash

DeleteWp() {
    #!/bin/bash
    read -p "Enter project to delete: " name

    # Confirm deletion
    echo "Are you sure you want to delete project '$name'?"
    echo "Deleting the project will delete the database"
    echo ", nginx config, source files and logs"
    echo 
    read -p " (Type 'yes' to confirm): " confirm

    if [[ $confirm == "yes" ]]; then
        echo
        echo "Removing files, config, and logs for project '$name'..."
        echo

        sudo rm -R "/var/www/sites/$name"
        sudo rm -R "/var/www/logs/$name"
        sudo rm "/etc/nginx/sites-enabled/$name.nginx"

        # Restarting nginx to update delete
        sudo systemctl restart nginx

        echo
        echo "Clearing database for project '$name'..."
        echo

        sudo mysql -u root <<EOF
        DROP DATABASE IF EXISTS $name;
        DROP USER IF EXISTS '$name'@'localhost';
        \q
EOF
        echo "Successfully removed project '$name'"
    else
        echo "Deletion canceled. No changes made."
    fi
}

GraphLog() {
    pubdir="/var/www/sites/goaccess"
    nginxdir="/etc/nginx/sites-enabled"
    logdir="/var/www/logs/$name"

    outputfile="$pubdir/logs/$name/report-$(date +%F)"
    inputfile="$logdir/access.nginx"

    sudo mkdir $pubdir > /dev/null 2>&1
    sudo mkdir $pubdir/logs > /dev/null 2>&1
    sudo mkdir $pubdir/logs/$name > /dev/null 2>&1

    sudo mkdir $logdir/archive

    sudo chown -R www-data:www-data $pubdir/logs > /dev/null 2>&1
    sudo chmod -R 755 $pubdir/logs > /dev/null 2>&1

    counter=1
    while [ -f "$pubdir/$name-$(date +%F)-$counter.zip" ]; do
        ((counter++))
    done

    if [ -f "$outputfile" ]; 
    then
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

    sudo mv $inputfile $inputfile-$(date +%F)
    sudo mv $inputfile-$(date +%F) $logdir/archive
    sudo touch $inputfile
    sudo systemctl restart nginx

    echo
    echo "done backing up log"
    echo
}

EditConf() {
    configdir="/etc/nginx/sites-enabled/"

    sudo vim $configdir/$name.nginx

    echo
    echo "edited config for $name"
    echo
    echo "restarting nginx to confirm changes"
    echo
    sudo systemctl restart nginx
}

clear

echo "Welcome to the project management tool!"

# Ask user to type in a name
read -p "Project name: " name

source="/var/www/sites/$name"

# Present options to the user
while true; do
if [ -d "$source" ]; then
    echo
    echo "What would you like to do to $name?"
    echo
    echo "1. Graph log"
    echo "2. Edit nginx config"
    echo "3. Reset/Create project"
    echo "4. Delete project"
    echo
    # Read user's choice
    read -p "Enter your choice (1-4): " choice

    # Perform action based on user's choice
    case $choice in
        1)
            clear
            echo "Graphing log..."
            GraphLog
            ;;
        2)    
            echo "Editing config..."
            EditConf
            ;;
            
        3)  
            clear
            echo "Resetting project..."
            test
            ;;
            
        4)
            clear
            echo "Deleting project..."
            # Add commands for deleting project
            ;;
        *)
            echo "Invalid choice. Please enter a number between 1 and 4."
            ;;
    esac
else
    echo 
    echo "project doesnt exist"
    echo
    read -p "create new project? (yes or no)" create
    
    case $choice in
        yes)
            SetupWP
            ;;
        no) 
            exit
            ;;
        *)
            echo "Invalid choice. cancelling"
            exit
        ;;
done
