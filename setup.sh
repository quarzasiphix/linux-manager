SetupDirs() {
    #setup directories
    echo
    echo "setting up directories"
    echo

    sudo mkdir /var/www/
    sudo mkdir /var/www/sites/
    sudo mkdir /var/www/scripts/
    sudo mkdir /var/www/backups/
    sudo mkdir /var/www/libs/
    sudo mkdir /var/www/logs/
    sudo mkdir /var/www/disabled/
    sudo mkdir /var/www/admin/
    sudo mkdir /var/www/server/

    sudo chmod -R 777 /var/www/
}

wwwdir="/var/www"


if [ ! -d "$directory" ]; then
    SetupDirs
fi

dir="/var/www/scripts"

sudo rm -R $dir/downloader
sudo mkdir $dir/downloader
sudo chmod 777 -R $dir

dwldir="$dir/downloader"
dwlurl="https://raw.githubusercontent.com/quarzasiphix/linux-manager/master/source/downloader/download.sh"
#remove previous if exists
sudo rm $dwldir/download.sh
sudo curl -o "$dwldir/download.sh" "$dwlurl"
sudo chmod +x $dwldir/download.sh

echo
echo "running download script..."
echo

$dwldir/download.sh

