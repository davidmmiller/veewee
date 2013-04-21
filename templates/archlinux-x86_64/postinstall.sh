#!/bin/bash

date > /etc/vagrant_box_build_time

# install packages
pacman -Sy --noprogressbar --noconfirm base-devel git wget

# install mitchellh's ssh key
mkdir /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O /home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

# sudo setup
echo "vagrant ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# make aur compile directory
mkdir /root/aur

# install ruby 2.0
pacman -Sy --noprogressbar --noconfirm ruby

# or install ruby 1.9
#cd /root/aur
#wget https://aur.archlinux.org/packages/ru/ruby1.9/PKGBUILD
#makepkg -sfci --noconfirm --asroot
#rm * -r
#
#cd

# create puppet group
groupadd puppet

# install gems for chef facter puppet
##  The default location of gem installs is $HOME/.gem/ruby
##
##  Add the following line to your PATH if you plan to install using gem
##  $(ruby -rubygems -e "puts Gem.user_dir")/bin
##  If you want to install to the system wide location, you must either:
##    edit /etc/gemrc or run gem with the --no-user-install flag.
gem install --no-ri --no-rdoc --no-user-install chef facter puppet

# or install puppet from source - and chef and facter from gems
#gem install --no-ri --no-rdoc chef facter
#cd /tmp
#git clone https://github.com/puppetlabs/puppet.git
#cd puppet
#ruby install.rb --bindir=/usr/bin --sbindir=/sbin

# install package-query
cd /root/aur
wget https://aur.archlinux.org/packages/pa/package-query/PKGBUILD
makepkg -sfci --noconfirm --asroot
rm * -r

# install yaourt
cd /root/aur
wget https://aur.archlinux.org/packages/ya/yaourt/PKGBUILD
makepkg -sfci --noconfirm --asroot
rm * -r

# install virtualbox guest additions
VBOX_VERSION=$(cat /root/.vbox_version)
pacman -Sy --noprogressbar --noconfirm virtualbox-guest-utils

cat > /etc/modules-load.d/virtualbox.conf << EOF
vboxguest
vboxsf
vboxvideo
EOF

modprobe -a vboxguest vboxsf vboxvideo

groupadd -r vboxsf
mkdir /media && chgrp vboxsf /media
gpasswd -a vagrant vboxsf

systemctl start vboxservice.service
systemctl enable vboxservice.service

# host-only networking
cat >> /etc/rc.local <<EOF
# enable DHCP at boot on eth0
# See https://wiki.archlinux.org/index.php/Network#DHCP_fails_at_boot
systemctl restart dhcpcd@eth0
EOF

# clean out pacman cache
pacman -Scc<<EOF
y
y
EOF

# zero out the fs
dd if=/dev/zero of=/tmp/clean || rm /tmp/clean

# and the final reboot!
# no reboot is necessary
#reboot

