# Build Automated Machine Images for D4

Build a vbox virtual machine for D4-server based on Ubuntu 18.04 server.

## Requirements

* [VirtualBox](https://www.virtualbox.org)
* [Packer](https://www.packer.io) from the Packer website
* *tree* -> sudo apt install tree (on deployment side)

## Usage

Launch the generation with the VirtualBox builder:

    $./build_vbox.sh 

A VirtualBox image will be generated and stored in the folder
*output-virtualbox-iso*.
