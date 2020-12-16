sudo systemctl stop mysql
sudo apt purge -y mysql-server mysql-client mysql-common;
sudo rm -rf /etc/mysql /var/lib/mysql
sudo apt update -y;
sudo apt install mysql-server -y;
sudo service mysql start;
sudo systemctl enable mysql;
sudo mysql -Bse "DROP USER 'root'@'localhost'; CREATE USER 'root'@'%' IDENTIFIED BY 'root'; GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"
sudo apt install ubuntu-desktop-minimal -y