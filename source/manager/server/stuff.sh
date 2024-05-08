EditSshconf() {
    sudo vim /etc/ssh/sshd_config
    echo
    echo "restarting ssh to confirm changes..."
    sudo systemctl restart sshd 
    echo
    echo "done"
    echo
}

EditMotd() {
    sudo vim /etc/motd
    echo
    echo "restarting ssh to confirm changes..."
    sudo systemctl restart sshd 
    echo
    echo "done"
    echo
}

EditBanner() {
    sudo vim /etc/ssh/banner.sh
    echo
    echo "restarting ssh to confirm changes..."
    sudo systemctl restart sshd 
    echo
    echo "done"
    echo
}

EditNginxconf() {
    sudo vim /etc/nginx/nginx.conf
    echo
    echo "restarting nginx to confirm changes..."
    sudo systemctl restart nginx 
    echo
    echo "done"
    echo
}

EditPasswd() {
    sudo vim /etc/passwd
    echo
    echo "done"
    echo
}

EditBash() {
    sudo vim ~/.bashrc
    echo
    echo "done"
    echo
}

EditVisudo() {
    sudo visudo
    echo
    echo "done"
    echo
}
