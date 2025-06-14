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

safe_delete() {
  local target="$1"
  if [[ -z "$target" ]]; then
    echo "safe_delete: no target specified"
    return 1
  fi

  # refuse dangerous paths
  case "$target" in
    "/"|"/var"|"/var/www") 
      echo "Refusing to delete suspicious directory: $target"
      return 1
      ;;
  esac

  if [ ! -e "$target" ]; then
    echo "safe_delete: target not found: $target"
    return 1
  fi

  # Prepare bin location
  local bin_dir="/var/www/bin"
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  local dest="$bin_dir/$ts"
  sudo mkdir -p "$dest"

  # Move the target
  sudo mv "$target" "$dest/"
  echo "Moved $target → $dest/"
}

# Retrieve or prompt/store the certbot email
get_certbot_email() {
  local f="/var/www/server/certbot_email.txt"
  if [ -f "$f" ]; then
    sudo cat "$f"
  else
    read -p "Email for Let's Encrypt notifications: " e
    echo "$e" | sudo tee "$f" > /dev/null
    echo "$e"
  fi
}
