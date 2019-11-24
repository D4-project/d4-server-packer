#! /usr/bin/env bash

# package
echo "--- autoremove for apt ---"
apt-get -y autoremove > /dev/null 2>&1

echo "--- Cleaning packages"
apt-get -y clean > /dev/null 2>&1

# End Cleaning
echo "VM cleaned and rebooting for automagic reas0ns."
halt -p
