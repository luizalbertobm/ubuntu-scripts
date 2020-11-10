#!/bin/bash

Red='\033[0;31m' 
Green='\033[0;32m' 
Cyan='\033[0;36m' 
Color_Off='\033[0m'

#Check if running as root  
if [ "$(id -u)" != "0" ]; then  
    echo -e "$Red This script must be run as root $Color_Off"
    exit 1  
fi  

function aptinstall {
    say $Cyan "Instaling $*"
    if ! dpkg -s $@ >/dev/null 2>&1; then
        sudo apt -y -f -qq install "$@"
    else
        say $Red "Já instalado"
    fi
    shift
}

function say(){
    echo -e "$1 \n $2 $Color_Off"
}

# ocs-url to use gnome-look.org
sudo dpkg -i ocs-url_3.1.0-0ubuntu1_amd64.deb

#install ubuntu themes and icons
mkdir -p $HOME/themes-temp && cd $HOME/themes-temp
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git

sudo aptinstall gtk2-engines-murrine gtk2-engines-pixbuf
sudo aptinstall sassc optipng inkscape
sudo ./WhiteSur-gtk-theme/install.sh --gdm -a standard
sudo ./WhiteSur-icon-theme/install.sh

# install grube2 themes
git clone https://github.com/vinceliuice/grub2-themes.git
sudo ./grub2-themes/install.sh -b -t

# install plymouth themes
sudo apt install plymouth-themes
git clone https://github.com/adi1090x/plymouth-themes.git
sudo cp -r plymouth-themes/pack_3/metal_ball /usr/share/plymouth/themes/
sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/metal_ball/metal_ball.plymouth 100
sudo update-alternatives --config default.plymouth
sudo update-initramfs -u

#cleaning
cd ..
sudo rm -R $HOME/themes-temp