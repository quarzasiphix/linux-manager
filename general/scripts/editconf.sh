read -p "Enter name: " name

configdir="/etc/nginx/sites-enabled/"

sudo vim $configdir/$name.nginx

echo
echo "edited config for $name"
echo
echo "restarting nginx to confirm changes"
echo
sudo systemctl restart ngin 