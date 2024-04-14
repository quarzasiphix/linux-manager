server_name=$(</var/www/server/name.txt)

new_ps1="\${debian_chroot:+(\$debian_chroot)}\[\033[01;32m\]\u@$server_name\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\\$ "
sudo sed -i "s/^export PS1=.*/export PS1=\"$new_ps1\"/" "/etc/bash.bashrc"\


PS1="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@linode\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
source /etc/bash.bashrc
