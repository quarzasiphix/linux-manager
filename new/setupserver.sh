#!/bin/bash

read -p "name of the server: " server_name

read -p "admin account: " admin_name

#read -p "admin password: " admin_password

echo
echo "setting up admin: $admin_name"
echo
sudo adduser $admin_name
sudo usermod -aG sudo $admin_name

#sudo passwd $admin_name
echo
echo "setting up ssh for admin"
echo

#setup ssh
dir="/home/$admin_name"
sudo mkdir $dir/.ssh
sudo chmod 700 $dir/.ssh
sudo touch $dir/.ssh/authorized_keys
sudo chown $admin_name:$admin_name $dir/.ssh
sudo chown $admin_name:$admin_name $dir/.ssh/authorized_keys
sudo nano $dir/.ssh/authorized_keys


#ssh security
echo
echo "securing ssh"
echo

#backup current config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
#disable password auth and only allow key auth
sudo sed -i -E 's/^#?(PasswordAuthentication)\s+(yes|no)/\1 no/' /etc/ssh/sshd_config
sudo sed -i -E 's/^#?(PubkeyAuthentication)\s+(yes|no)/\1 yes/' /etc/ssh/sshd_config 
#disables root login
sudo sed -i -E 's/^#?(PermitRootLogin)\s+(yes|no)/\1 no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

echo
echo "installing every required program"
echo

#install everything
sudo apt install apt-transport-https lsb-release ca-certificates wget -y 
sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg 
sudo sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' 
sudo wget -O - https://deb.goaccess.io/gnugpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/goaccess.gpg >/dev/null
sudo echo "deb [signed-by=/usr/share/keyrings/goaccess.gpg arch=$(dpkg --print-architecture)] https://deb.goaccess.io/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/goaccess.list
sudo apt update 
sudo apt-get install ufw screen unzip zip nginx curl mariadb-server mariadb-client curl php8.2-sqlite3 php8.2-gd php8.2-mbstring php8.2-pdo-sqlite php8.2-fpm php8.2-cli php8.2-zip php8.2-xml php8.2-dom php8.2-curl php8.2-mysqli

#setup directories
echo
echo "setting up directories"
echo

sudo rm -R /var/www/
sudo mkdir /var/www/
sudo mkdir /var/www/sites/
sudo mkdir /var/www/scripts/
sudo mkdir /var/www/backups/
sudo mkdir /var/www/libs/
sudo mkdir /var/www/logs/
sudo mkdir /var/www/disabled/
sudo mkdir /var/www/admin/

sudo chmod -R 777 /var/www/



#setting up web admin account

echo
echo "setting up web admin account"
echo 

sudo useradd webwiz
sudo usermod -ag sudo webwiz

sudo mkdir /var/www/admin
export PATH=$PATH:/var/www/admin
sudo mkdir /var/www/admin/.ssh
sudo chmod 700 /var/www/admin/.ssh
sudo touch /var/www/admin/.ssh/authorized_keys
sudo chown webwiz:webwiz /var/www/admin/.ssh
sudo chown webwiz:webwiz /var/www/admin/.ssh/authorized_keys
sudo nano /var/www/admin/.ssh/authorized_keys

sudo tee "/var/www/admin/login.sh" > /dev/null <<EOT
#!/bin/bash

# Function to handle cleanup
cleanup() {
    # If the script exits for some reason, switch to rbash
    exec rbash
}

# Trap signals for cleanup
trap cleanup SIGINT EXIT

# Execute your script
/var/www/admin/wpgeneral.sh

echo "sup"
EOT

echo
echo "downloading wpgeneral script from github"
echo

curl -o /var/www/admin/wpgeneral.sh https://raw.githubusercontent.com/quarzasiphix/server-setup/master/wpgeneral.sh

