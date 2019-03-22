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
sudo apt-get -y install git python sudo tmux vim virtualenvwrapper virtualenv zip python3-pythonmagick htop imagemagick asciidoctor jq ntp ntpdate > /dev/null 2>&1
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
sudo -u d4 git clone https://github.com/D4-project/d4-core.git $PATH_TO_D4/d4-core
echo "--- Installing dependencies ---"
cd $PATH_TO_D4/d4-core/server
sudo -u d4 ./install_server.sh
echo "--- Creating Certificates  ---"
cd gen_cert
sudo -u d4 ./gen_root.sh
sudo -u d4 ./gen_cert.sh

echo "--- Writing rc.local  ---"
# With initd:
if [ ! -e /etc/rc.local ]
then
    echo '#!/bin/sh -e' | sudo tee -a /etc/rc.local
    echo 'exit 0' | sudo tee -a /etc/rc.local
    chmod u+x /etc/rc.local
fi

# redis-server requires the following /sys/kernel tweak
sed -i -e '$i \echo never > /sys/kernel/mm/transparent_hugepage/enabled\n' /etc/rc.local
sed -i -e '$i \echo 1024 > /proc/sys/net/core/somaxconn\n' /etc/rc.local
sed -i -e '$i \sysctl vm.overcommit_memory=1\n' /etc/rc.local
sed -i -e '$i \sudo -u d4 bash -c "(cd /home/d4/d4-core/server; ./LAUNCH.sh -l > /tmp/d4.log)"\n' /etc/rc.local

TIME_END=$(date +%s)
TIME_DELTA=$(expr ${TIME_END} - ${TIME_START})

echo "The generation took ${TIME_DELTA} seconds"
