#! /bin/bash
#
# Custom Arch installation, setup & config
#
# ----------------------------------------

#---Installation
pacman --noconfirm -Sy archlinux-keyring
loadkeys pl
timedatectl set-ntp true

echo ""
echo ""
lsblk
echo ""
echo "------------------"
echo ""
read -p "Enter Arch drive: " drive
cfdisk $drive

#read -p "Do you want a home partition? [y/n]" home
#if [[ $home = y ]] then
#	echo "Not supported yet"
#fi

echo ""
echo ""
echo "------------------"
echo ""
read -p "Enter main partition: " main
mkfs.ext4 $main

echo ""
echo ""
echo "------------------"
echo ""
read -p "Do you want an EFI partition? [y/n] " ans
if [[ $ans = y ]];
then
	read -p "Enter EFI partition: " efi
	mkfs.vfat -F 32 $efi
fi

mount $main /mnt
pacstrap /mnt base base-devel linux linux-firmware neovim
genfstab -U /mnt >> /mnt/etc/fstab

sed -nE '/^#---Setup/, $p' $(basename "$0") >> /mnt/$(basename "$0")
chmod +x /mnt/$(basename "$0")
arch-chroot /mnt ./$(basename "$0")
exit

#---Setup
pacman -S --noconfirm grub os-prober efibootmgr networkmanager
ln -sf /usr/share/zoneinfo/Europe/Warsaw
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo ""
echo ""
echo "------------------"
echo ""
read -p "Enter hostname: " hostname
echo $hostname > /etc/hostname
echo "127.0.0.1		localhost" > /etc/hosts
echo "::1		localhost" >> /etc/hosts
echo "127.0.1.1		$hostname.localdomain $hostname" >> /etc/hosts

echo ""
echo "Changing root password..."
passwd

read -p "Enter EFI partition: " efi
mkdir /boot/efi
mount $efi /boot/efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager.service

echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
echo ""
echo ""
echo "------------------"
echo ""
read -p "Enter your username: " username
useradd -m -G wheel $username
echo "Setting password for $username..."
passwd $username

echo ""
echo ""
echo "------------------"
echo ""
read -p "Install command line utilities? [y/n] " ans
if [[ $ans = y ]];
then
	pacman -S --noconfirm neofetch htop git openssh sxiv > /dev/null
fi

echo ""
echo ""
echo "------------------"
echo ""
read -p "Minimal installation? [y/n] " ans

echo "Installing dependencies"
pacman -S --noconfirm python3 alacritty libnotify dunst picom sxhkd\
	xorg xclip xorg-xsetroot xorg-xinit maim mpv python-pywal tee rofi\
	pulseaudio exa > /dev/null

echo "Installing fonts..."
pacman -S --noconfirm ttf-font-awesome > /dev/null

if [[ $ans = n ]];
then
	echo ""
	echo ""
	echo "------------------"
	echo ""
	read -p "Install additional applications? (e.g. web browser) [y/n] " answer
	if [[ $answer = y ]];
	then
		pacman -S --noconfirm firefox tor tor-browser mupdf keepassxc
	fi
fi

#---Config
HOME=/home/$username
cd $HOME
mkdir $HOME/.config

mkdir -p $HOME/.local/src
mkdir $HOME/.local/bin
mkdir -p $HOME/pic/scr
mkdir -p $HOME/pic/wal
mkdir $HOME/downloads
mkdir -p $HOME/dev/proj
mkdir -p $HOME/dev/arch
mkdir -p $HOME/mount/storage
mkdir -p $HOME/mount/backup
mkdir $HOME/notes
mkdir $HOME/temp
mkdir $HOME/doc
mkdir $HOME/git
mkdir $HOME/games

#---dmenu, dwm, utility scripts and dotfiles
echo "Cloning dwm and dmenu..."
git clone https://github.com/Vincchy/dmenu $HOME/.local/src/dmenu > /dev/null
git clone https://github.com/Vincchy/dwm $HOME/.local/src/dwm > /dev/null
echo "Getting useful scripts..."
git clone https://github.com/Vincchy/util $HOME/.local/bin > /dev/null
echo "Fetching config files..."
git clone https://github.com/Vincchy/dotfiles $HOME/.config > /dev/null

cat $HOME/.config/.bashrc > $HOME/.bashrc

chown $username $HOME/*

#---yay installation
# Something breaks here -----------------------------------------------------------------------
new_script=/home/$username/$(basename "$0")
sed -nE '/^#---Yay_Installation/, $p' $(basename "$0") >> $new_script
chown $username:$username $new_script
chmod +x $new_script
su -c $new_script $username
exit

#---Yay_Installation
echo "Installing yay package manager..."
git clone https://aur.archlinux.org/yay.git $HOME/git/yay > /dev/null
cd $HOME/git/yay
makepkg -si

#---yay apps installation
echo "Installing yay dependencies..."
yay -S adwaita-dark ytfzf shell-color-scripts python-pywalfox > /dev/null

# ----------------------------- Xinit config
cat >$HOME/.xinitrc <<END
# !/bin/sh
setxkbmap pl
dunst &
picom -b &
sxhkd &
# For Android Studio to render properly
export _JAVA_AWT_WM_NONREPARENTING=1
$HOME/.local/bin/changewallpaper.sh
# Update dwm bar
while true
do
	DISK=$(echo " $(df -h | grep '/dev/sda2' | awk {'print $3 "/" $2'})")
	DATE=$(echo " $(date '+%a %d %b')")
	TIME=$(echo " $(date '+%H:%M')")
	MEMO=$(echo " $(free -h --si | awk /Mem/ | awk '{ print $3}')")
	VOLU=$(echo " $(awk -F"[][]" '/dB/ { print $2 }' <(amixer sget Master))")
	xsetroot -name "[  $VOLU  ]  [  $MEMO  ]  [  $DISK  ]  [  $DATE  ]  [  $TIME  ]  "
	sleep 1s
done &
# Water drinking reminder
while true; do notify-send "Drink Water"; sleep 15m; done &
# Main dwm loop
while :
do
	$HOME/.local/src/dwm/dwm
done
END
# ----------------------------- end of Xinit config

#---End
echo "Almost there..."
echo "Just one more step"
read -p "Press ENTER to reboot" junk
reboot
