#!/usr/bin/env bash

# Title   : Whitelist Cloudflare IPs and hide ssh port
# Author  : Remisa Yousefvand <remisa.yousefvand@gmail.com>
# date    : 2018-09-24
# Version : 1.0.0

function askYesNoQuestion()
{
  while read -ep "$1 (`tput setaf 2`y`tput sgr0`/`tput setaf 1`n`tput sgr0`)? " -n 1 -i "$2" answer; do
    case "$answer" in
      y|Y) return 0
      ;;
      n|N) return 1
      ;;
      *) askYesNoQuestion "$1" "$2"
      ;;
    esac
  done
}

echo "Whitelisting Cloudflare IPs..."
echo
sudo ufw disable
sudo ufw default deny incoming
sudo ufw default allow outgoing

IPS=`curl -s https://www.cloudflare.com/ips-v4`
IPS+=`echo -e "\n" && curl -s https://www.cloudflare.com/ips-v6`
for ip in ${IPS}; do
  sudo ufw allow from $ip
done

echo
if ! `askYesNoQuestion "Enable port knocking?" "y"`; then
  sudo ufw allow ssh
  sudo ufw enable
  exit 0
fi

sudo apt install -y knockd

n=$((2 + RANDOM % 3))
for (( i=0; i<$n; i++ )); do
  randomPorts="$((8000 + RANDOM % 65000)), $randomPorts"
done
randomPorts+=$((8000 + RANDOM % 65000))

read -ep "Enter port sequence (comma seperated i.g. 7000,8000,9000...): " -i "$randomPorts" ports
ports="${ports:-randomPorts}"

echo "Writing knockd config..."
cat << EOL | sudo tee /etc/knockd.conf
[options]
  logfile = /var/log/knockd.log

[SSH]
  sequence      = $ports
  seq_timeout   = 5
  start_command = ufw allow from %IP% to any port 22
  tcpflags      = syn
  cmd_timeout   = 30
  stop_command  = ufw delete allow from %IP% to any port 22
EOL

echo "ReadWritePaths=-/etc/ufw/" | sudo tee -a /lib/systemd/system/knockd.service

sudo service knockd restart
publicIp=`curl -s ipinfo.io/ip`

cat >./client.sh <<EOL
#!/usr/bin/env bash

if [ -z `command -v knock` ]; then
  echo "Installing knockd..."
  sudo apt install -y knockd
fi
echo "Connecting $publicIp..."
knock -v $publicIp $ports
ssh `whoami`@$publicIp
EOL

chmod +x ./client.sh
echo
echo "`tput setaf 1`IMPORTANT:`tput sgr0` Write down these numbers: `tput bold`$ports`tput sgr0`"
echo
echo "`tput setaf 3`Download `tput bold`client.sh`tput sgr0``tput setaf 3` to your client machine and run it to connect via ssh.`tput srg0`"

sudo ufw enable
