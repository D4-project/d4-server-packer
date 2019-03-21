#!/usr/bin/env bash
PATH_TO_D4="/home/d4"
# Grub config (reverts network interface names to ethX)
GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"
DEFAULT_GRUB=/etc/default/grub

# Ubuntu version
UBUNTU_VERSION="$(lsb_release -r -s)"
# Timing creation
TIME_START=$(date +%s)

echo "--- Installing D4 server ---"

echo "--- Updating packages list ---"
sudo apt-get -qq update > /dev/null 2>&1

echo "--- Upgrading and autoremoving packages ---"
sudo apt-get -y upgrade > /dev/null 2>&1
sudo apt-get -y autoremove > /dev/null 2>&1

echo "--- Install base packages ---"
sudo apt-get -y install git python redis-server sudo tmux vim virtualenvwrapper virtualenv zip python3-pythonmagick htop imagemagick asciidoctor jq ntp ntpdate > /dev/null 2>&1
## Remove mailutils, it probably makes the script stuck on a user prompt....

echo "--- Installing and configuring Postfix ---"
# # Postfix Configuration: Satellite system
# # change the relay server later with:
# sudo postconf -e 'relayhost = example.com'
# sudo postfix reload
echo "postfix postfix/mailname string `hostname`.misp.local" | debconf-set-selections
echo "postfix postfix/main_mailer_type string 'Satellite system'" | debconf-set-selections
sudo apt-get install -y postfix > /dev/null 2>&1

echo "--- Retrieving D4 ---"
## Double check perms.
sudo mkdir $PATH_TO_D4
cd $PATH_TO_D4
sudo -u d4 git clone https://github.com/D4-project/d4-core.git $PATH_TO_D4 > /dev/null 2>&1

echo "--- Installing dependencies ---"
sudo -u d4 $PATH_TO_D4/install_server.sh
sudo -u d4 $PATH_TO_D4/gen_cert/gen_root.sh
sudo -u d4 $PATH_TO_D4/gen_cert/gen_cert.sh

TIME_END=$(date +%s)
TIME_DELTA=$(expr ${TIME_END} - ${TIME_START})

echo "The generation took ${TIME_DELTA} seconds"
