#! /usr/bin/env bash

echo "--- Configuring sudo "
echo %d4 ALL=NOPASSWD:ALL > /etc/sudoers.d/d4
chmod 0440 /etc/sudoers.d/d4

