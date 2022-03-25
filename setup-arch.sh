#! /bin/bash
#
# Custom Arch installation, setup & config
#
# ----------------------------------------


pacman --no-confirm -Sy archlinux-keyring
loadkeys pl
timedatectl set-ntp true

lsblk
echo "Enter Arch drive: "
read drive
cfdisk $drive

#read -p "Do you want a home partition? [y/n]" home
#if [[ $home = y ]] then
#	echo "Not supported yet"
#fi

echo "Enter main partition"
read main
mkfs.ext4 $main
