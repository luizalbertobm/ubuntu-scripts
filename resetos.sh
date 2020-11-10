#Try configuring unconfigured packages:
sudo dpkg --configure -a
#Update the contents of the repositories
sudo apt-get update
#Try to fix missing dependencies:
sudo apt-get -f install
#Update all packages with new versions available:
sudo apt-get full-upgrade
#Reinstall Ubuntu desktop:
sudo apt-get install --reinstall ubuntu-desktop
#Remove unnecessary packages:
sudo apt-get autoremove
#Delete downloaded packages already installed:
sudo apt-get clean
#Reboot the system to see if the issue was resolved:
sudo reboot