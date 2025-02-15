#!/bin/bash
# ------------------------------------------------------------------
# Linux Server Setup Script (Cleaned & Revised)
# ------------------------------------------------------------------

# --- Function: Setup GoAccess Configuration ---
SetupGoaccess() {
    read -p "Domain for GoAccess: " godomain

    # Insert an access_log directive (if not already present)
    sudo sed -i '/http {/a\    access_log /var/log/nginx/access.log combined;' /etc/nginx/nginx.conf

    # Create GoAccess site configuration
    sudo tee /etc/nginx/sites-enabled/goaccess.nginx > /dev/null <<EOT
server {
    listen 80;
    server_name ${godomain};

    root /var/www/sites/goaccess;
    index report.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location /logs {
        autoindex on;
        try_files \$uri \$uri/ =404;
    }

    location /backups {
        autoindex on;
        try_files \$uri \$uri/ =404;
    }
}
EOT

    echo "GoAccess configuration completed."
}

# --- Function: Setup Terminal Banner ---
SetupTerminal() {
    # Read the server name from the config file (if exists)
    local s_name
    s_name=$(sudo cat /var/www/server/name.txt 2>/dev/null)
    sudo tee /var/www/scripts/banner.sh > /dev/null <<EOT
#!/bin/bash
export PATH=\$PATH:/var/www/scripts/manager
clear
PS1="\${debian_chroot:+(\$debian_chroot)}\[\033[01;32m\]\u@${s_name}\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\\\$ "
echo
echo "  ==================================="
echo -e "         Hello \e[36m\$USER\e[0m"
echo -e "   Welcome to \e[95mWeb wiz\e[0m"
echo "  ==================================="
echo
EOT
    sudo chmod +x /var/www/scripts/banner.sh

    # Append the banner to /etc/bash.bashrc if not already done
    if ! grep -q "source /var/www/scripts/banner.sh" /etc/bash.bashrc; then
        echo "source /var/www/scripts/banner.sh" | sudo tee -a /etc/bash.bashrc > /dev/null
    fi
}

# --- Function: Setup SSH for Admin ---
SetupSsh() {
    echo "Setting up SSH for admin: $admin_name"
    local udir="/home/$admin_name"

    if [ ! -d "$udir" ]; then
        echo "Home directory for $admin_name not found. Creating it..."
        sudo mkdir -p "$udir"
        sudo chown "$admin_name":"$admin_name" "$udir"
        sudo chmod 755 "$udir"
    fi

    sudo mkdir -p "$udir/.ssh"
    sudo touch "$udir/.ssh/authorized_keys"
    # Open authorized_keys for editing so you can add keys manually
    sudo nano "$udir/.ssh/authorized_keys"
    sudo chmod 700 "$udir/.ssh"
    sudo chmod 600 "$udir/.ssh/authorized_keys"
    sudo chown -R "$admin_name":"$admin_name" "$udir/.ssh"

    echo "Securing SSH..."
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    sudo sed -i -E 's/^#?(PasswordAuthentication)\s+(yes|no)/\1 no/' /etc/ssh/sshd_config
    sudo sed -i -E 's/^#?(PubkeyAuthentication)\s+(yes|no)/\1 yes/' /etc/ssh/sshd_config
    sudo sed -i -E 's/^#?(PermitRootLogin)\s+(yes|no)/\1 no/' /etc/ssh/sshd_config
    sudo systemctl restart sshd

    SetupTerminal
}

# --- Function: Download & Install Required Packages ---
Download() {
    echo "Installing required packages..."
    sudo apt install -y apt-transport-https lsb-release ca-certificates wget
    sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
    sudo sh -c "echo 'deb https://packages.sury.org/php/ \$(lsb_release -sc) main' > /etc/apt/sources.list.d/php.list"
    sudo wget -O - https://deb.goaccess.io/gnugpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/goaccess.gpg >/dev/null
    sudo tee /etc/apt/sources.list.d/goaccess.list > /dev/null <<EOT
deb [signed-by=/usr/share/keyrings/goaccess.gpg arch=\$(dpkg --print-architecture)] https://deb.goaccess.io/ \$(lsb_release -cs) main
EOT
    sudo apt update
    echo "Downloading additional packages..."
    # Download WP-CLI
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    sudo mv wp-cli.phar /usr/local/bin/wp
    sudo apt-get install -y ufw goaccess screen unzip neofetch zip trash-cli nginx curl mariadb-server mariadb-client \
        php8.2-sqlite3 php8.2-gd php8.2-mbstring php8.2-pdo-sqlite php8.2-fpm php8.2-cli php8.2-soap \
        php8.2-zip php8.2-xml php8.2-dom php8.2-curl php8.2-mysqli
}

# --- Function: Setup Disabled Site for Nginx ---
SetupDisabled() {
    sudo mkdir -p /etc/nginx/disabled
    sudo chmod -R 777 /etc/nginx/disabled

    sudo tee /etc/nginx/sites-enabled/default > /dev/null <<EOT
server {
    listen 80 default_server;
    server_name _;

    location / {
        root /var/www/sites/disabled;
        index index.html;
    }
}
EOT

    sudo mkdir -p /var/www/sites/disabled
    sudo tee /var/www/sites/disabled/index.html > /dev/null <<EOT
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Site Disabled</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: 'Poppins', sans-serif;
            background-color: #0d0d0d;
            text-align: center;
            color: #fff;
        }
        .header {
            padding: 20px 0;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>This site is disabled</h1>
    </div>
</body>
</html>
EOT
}

# --- Function: Configure Server Settings & Create Admin User ---
ConfigServer() {
    echo "Server setup:"
    read -p "Name of the server: " server_name
    read -p "Enter the location of the server: " server_location
    local server_dir="/var/www/server"
    sudo mkdir -p "$server_dir"
    sudo chmod 777 -R "$server_dir"

    echo "$server_name" | sudo tee /var/www/server/name.txt > /dev/null
    echo "$server_location" | sudo tee /var/www/server/info.txt > /dev/null

    sudo mkdir -p /var/www/scripts
    sudo chmod 777 -R /var/www/scripts

    # Create banner script with the server name embedded in the PS1 prompt
    sudo tee /var/www/scripts/banner.sh > /dev/null <<EOT
#!/bin/bash
export PATH=\$PATH:/var/www/scripts/manager
clear
PS1="\${debian_chroot:+(\$debian_chroot)}\[\033[01;32m\]\u@${server_name}\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\\\$ "
echo
echo "  ==================================="
echo -e "         Hello \e[36m\$USER\e[0m"
echo -e "   Welcome to \e[95mWeb wiz\e[0m"
echo "  ==================================="
echo
EOT
    sudo chmod +x /var/www/scripts/banner.sh

    # Create or check for the admin user
    read -p "Admin account name: " admin_name
    if id "$admin_name" &>/dev/null; then
        echo "User $admin_name already exists."
    else
        sudo adduser "$admin_name"
        sudo usermod -aG sudo "$admin_name"
    fi

    SetupSsh
}

# --- Function: Setup Directory Structure ---
SetupDirs() {
    echo "Setting up directories..."
    sudo mkdir -p /var/www/sites
    sudo mkdir -p /var/www/scripts
    sudo mkdir -p /var/www/backups
    sudo mkdir -p /var/www/libs
    sudo mkdir -p /var/www/logs
    sudo mkdir -p /var/www/disabled
    sudo mkdir -p /var/www/admin
    sudo mkdir -p /var/www/server
    sudo mkdir -p /var/www/sites/disabled
    sudo chmod -R 777 /var/www/
}

# --- Main Script Execution ---

wwwdir="/var/www"

read -p "Is this a new server setup? (yes/no): " newserv
if [[ "$newserv" == "yes" ]]; then
    echo "Setting up new server..."
    Download
    SetupDirs
    ConfigServer
    SetupDisabled
else
    echo "Existing server setup. Configuring server..."
    SetupDirs
    ConfigServer
fi

echo "Checking directories..."
if [ ! -d "$wwwdir" ]; then
    echo "Main directory /var/www/ not found. Setting up."
else 
    echo "Directories found."
fi

if [ ! -d "$wwwdir/server" ]; then
    echo "Server config not found."
else
    echo "Server config located."
fi

if [ ! -d "$wwwdir/sites/goaccess" ]; then
    echo "GoAccess directory not found."
    read -p "Setup GoAccess? (yes/no): " goa
    if [[ "$goa" == "yes" ]]; then
        echo "Starting GoAccess configuration..."
        SetupGoaccess
    else
        echo "Skipping GoAccess setup."
    fi
fi

echo "Downloading script manager..."
dir="/var/www/scripts"
sudo rm -rf "$dir/downloader"
sudo mkdir -p "$dir/downloader"
sudo chmod -R 777 "$dir"

dwldir="$dir/downloader"
dwlurl="https://raw.githubusercontent.com/quarzasiphix/linux-manager/master/source/downloader/download.sh"
sudo rm -f "$dwldir/download.sh"
sudo curl -o "$dwldir/download.sh" "$dwlurl"
sudo chmod +x "$dwldir/download.sh"

echo "Running download script..."
"$dwldir/download.sh"
