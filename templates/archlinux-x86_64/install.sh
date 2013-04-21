#!/bin/bash -x

NAME=$1

# launch automated install
#format the partitioon
fdisk /dev/sda << EOF
n
p
1


w
EOF

mkfs.ext4 /dev/sda1

mount /dev/sda1 /mnt

pacstrap /mnt base grub-bios openssh

genfstab -pU /mnt >> /mnt/etc/fstab

# make directory for veewee/install.log
mkdir /mnt/root/veewee

# chroot into the new system
arch-chroot /mnt <<ENDCHROOT | tee /mnt/root/veewee/install.log
# set hostname
echo $NAME > /etc/hostname

# make sure network is up and a nameserver is available
systemctl start dhcpcd

# choose a mirror
sed -i 's/^#\(.*leaseweb.*\)/\1/' /etc/pacman.d/mirrorlist

pacman-db-upgrade
pacman --noprogressbar -Syy

#make the initramfs
mkinitcpio -p linux

#install grub
grub-install --recheck --debug /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# set up user accounts
passwd<<EOF
vagrant
vagrant
EOF
useradd -m -G wheel -r vagrant
passwd -d vagrant
passwd vagrant<<EOF
vagrant
vagrant
EOF

# make sure ssh is allowed
echo "sshd:	ALL" > /etc/hosts.allow

# and everything else isn't
echo "ALL:	ALL" > /etc/hosts.deny

# make sure to have dhcpcd at startup
#systemctl enable dhcpcd
# unfortunately systemctl doesn't work under chroot
# instead we make symlink manually here
ln -s '/usr/lib/systemd/system/dhcpcd.service' '/etc/systemd/system/multi-user.target.wants/dhcpcd.service'

# make sure sshd starts too
#systemctl enable ssh
# unfortunately systemctl doesn't work under chroot
# instead we create symlink manually here
ln -s '/usr/lib/systemd/system/sshd.service' '/etc/systemd/system/multi-user.target.wants/sshd.service'

# not yet a fan of Predictable Network Interface Names?  I am not sold yet either.
# http://www.freedesktop.org/wiki/Software/systemd/PredictableNetworkInterfaceNames
ln -s /dev/null /etc/udev/rules.d/80-net-name-slot.rules

# leave the chroot
ENDCHROOT

# unmount disk
umount /mnt

# and final reboot!
reboot
