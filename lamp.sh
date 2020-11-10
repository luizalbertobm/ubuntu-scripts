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

say $Green "==> Uninstalling old versions"
sudo apt purge -y php libapache2-mod-php

sudo systemctl stop apache2
sudo apt purge -y apache2 apache2-utils

sudo systemctl stop mysql
sudo apt purge -y mysql-server mysql-client mysql-common

say $Green "==> Removing old directories"
sudo rm -R /var/www/html
sudo rm -R /etc/apache2/sites-available
sudo rm -R /etc/apache2/mods-enabled
sudo rm -rf /etc/mysql /var/lib/mysql

say $Green "==> Updating repositories"
sudo apt update -y

# APACHE
say $Green "==> Instaling Apache"
aptinstall apache2 apache2-utils 
sudo ufw allow in "Apache"
apache2 -v

say $Green "==> Changing apache permissions"
sudo chown www-data:www-data /var/www/html/ -R
sudo chmod 755 /var/www/ -R

# MYSQL
say $Green "==> Instaling Mysql"
aptinstall mysql-server
mysql --version

# PHP
say $Green "==> Instaling PHP"
aptinstall php php-cli libapache2-mod-php 

say $Green "==> Instaling PHP extensions"
aptinstall php-common php-mysql php-json php-gd php-opcache php-readline php-curl php-mbstring php-xdebug
php --version
say $Green "==> see https://stackoverflow.com/questions/53133005/how-to-install-xdebug-on-ubuntu to know hot to ativate x-debug"

# CURL and GIT
say $Green "==> Instaling Curl and Git"
aptinstall composer curl git
say $Green 'seu ip externo é:'
curl http://icanhazip.com

sudo apt autoremove -y

# Adding some tools
say $Green "==> Adding some tools"
cd /var/www/html/
git clone https://github.com/luizalbertobm/php-dashboard
echo '<?php require_once "php-dashboard/index.php";' >  /var/www/html/index.php

# changing some settings
echo 'Changing index.php file order'
sudo sed -i 's/index.php //g' /etc/apache2/mods-enabled/dir.conf
sudo sed -i 's/index.html/index.php index.html/g' /etc/apache2/mods-enabled/dir.conf

sudo systemctl enable apache2
sudo systemctl enable mysql

sudo systemctl restart apache2
sudo systemctl restart mysql

# MYSQL user and pass
say $Green "==> Configuring mysql user=root and password=qweqwe"
#SET GLOBAL validate_password.policy = 0; SET GLOBAL validate_password.length = 6; SET GLOBAL validate_password.number_count = 0;
sudo mysql -Bse " DROP USER 'root'@'localhost'; CREATE USER 'root'@'%' IDENTIFIED BY 'qweqwe'; GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"