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
#sudo apt-get -y upgrade > /dev/null 2>&1
#sudo apt-get -y upgrade > /dev/null 2>&1

echo "--- Install base packages ---"
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install binutils-dev ldnsutils libldns-dev libpcap-dev libdate-simple-perl golang-go autoconf git python sudo tmux vim virtualenvwrapper virtualenv zip python3-pythonmagick htop imagemagick asciidoctor jq ntp ntpdate net-tools python-pcapy postgresql-plpython3-11 postgresql postgresql-contrib

echo "--- Installing and configuring Postfix ---"
# # Postfix Configuration: Satellite system
# # change the relay server later with:
# sudo postconf -e 'relayhost = example.com'
# sudo postfix reload
echo "postfix postfix/mailname string `hostname`.misp.local" | sudo debconf-set-selections
echo "postfix postfix/main_mailer_type string 'Satellite system'" | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postfix > /dev/null 2>&1

echo "--- Retrieving D4 ---"
git clone https://github.com/D4-project/d4-core.git $PATH_TO_D4/d4-core
echo "--- Installing dependencies ---"
pushd $PATH_TO_D4/d4-core/server
./install_server.sh
echo "--- Creating Certificates  ---"
pushd gen_cert
./gen_root.sh
./gen_cert.sh
popd 
popd 

echo "--- Installing d4-goclient ---"
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> $PATH_TO_D4/.bashrc 
go get github.com/D4-project/d4-goclient
mkdir conf.pssl
pushd conf.pssl
echo "127.0.0.1:4443" > destination
echo "stdin" > source
echo "private key to change" > key
echo "1" > version
echo "2" > type
echo "4096" > snaplen
echo "{\"type\":\"ja3-jl\"}" > metaheader.json
touch uuid
popd

echo "--- Installing sensor-d4-tlsfingerprinting ---"
go get github.com/D4-project/sensor-d4-tls-fingerprinting

echo "--- Installing analyzer-d4-passivessl ---"
go get github.com/gomodule/redigo/redis
go get github.com/lib/pq
go get github.com/D4-project/analyzer-d4-passivessl

echo "--- Installing Snake-oil-crypto ---"
git clone https://github.com/D4-project/snake-oil-crypto.git
pushd snake-oil-crypto
./install-19.04.sh
popd

echo "--- Moving pssl DB  ---"
sudo -u postgres psql -c 'create database passive_ssl;'
sudo -u postgres psql -c 'grant all privileges on database passive_ssl to postgres;'
sudo -u postgres psql -f /tmp/postgresql passive_ssl

echo "--- Cloning slides / hands-on ---"
git clone https://github.com/D4-project/architecture.git
ln -sr /home/d4/architecture/docs/workshop/5-snake-oil-crypto/hands-on-support /home/d4/hands-on
virtualenv -p python3 venv
. ./venv/bin/activate
pip install cryptography 
deactivate

echo "--- Writing rc.local  ---"
# With initd:
if [ ! -e /etc/rc.local ]
then
    echo '#!/bin/sh -e' | sudo tee -a /etc/rc.local
    echo 'exit 0' | sudo tee -a /etc/rc.local
    sudo chmod u+x /etc/rc.local
fi

# redis-server requires the following /sys/kernel tweak
sudo sed -i -e '$i \echo never > /sys/kernel/mm/transparent_hugepage/enabled\n' /etc/rc.local
sudo sed -i -e '$i \echo 1024 > /proc/sys/net/core/somaxconn\n' /etc/rc.local
sudo sed -i -e '$i \sysctl vm.overcommit_memory=1\n' /etc/rc.local
sudo sed -i -e '$i \su d4 bash -c "(cd /home/d4/d4-core/server; ./LAUNCH.sh -l > /tmp/d4.log)"\n' /etc/rc.local
#sudo sed -i -e '$i \su d4 bash -c "(cd /home/d4/analyzer-d4-passivedns; ./launch_server.sh > /tmp/pdns.log)"\n' /etc/rc.local

TIME_END=$(date +%s)
TIME_DELTA=$(expr ${TIME_END} - ${TIME_START})

echo "The generation took ${TIME_DELTA} seconds"
