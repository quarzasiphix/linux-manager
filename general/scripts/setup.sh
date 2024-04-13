dir="/var/www/scripts"

sudo mkdir $dir/downloader
sudo chmod 777 -R $dir

dwldir="$dir/new/downloader"
dwlurl="https://raw.githubusercontent.com/quarzasiphix/server-setup/master/general/scripts/downloader/download.sh"
#remove previous if exists
sudo rm $dwldir/download.sh
sudo curl -o "$dwldir" "$dwlurl"
sudo chmod +x $dwldir/download.sh

echo
echo "running download script..."
echo

$dwldir/download.sh