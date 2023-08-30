read -sp "Enter MySQL root password: " mysql_password
echo

read -p "Enter name: " name
echo

nginx_config="/etc/nginx/sites-available/$name.nginx"

backupdir="/var/www/backups/$name/"

sudo mkdir $name-temp/ > /dev/null
sudo chmod -R 777 $name-temp/

sudo mysqldump -u $name -p --single-transaction $name > $name-temp/$name.sql > /dev/null
sudo cp $nginx_config $name-temp/ >/dev/null
sudo cp -R $name $name-temp/

echo backed up nginx, sql and wordpress files.

zip $name-$(date +%F).zip $name-temp/*

# sudo rm -R $name-temp/
sudo mkdir $backupdir > /dev/null
sudo mv $name-$(date +%F).zip $backupdir

echo made back in $backupdir



