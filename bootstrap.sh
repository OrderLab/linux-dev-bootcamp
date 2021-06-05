#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage: $0 IMAGE_FILE MOUNT_DIR"
  exit 1
fi

image_file=$1
mount_dir=$2

# create a new user (current user by default)
new_user=$USER
new_host=debian-buster

if [[ $image_file != *.img ]]; then
  echo "Image file $image_file does not end with .img"
  exit 1
fi

qemu-img create $image_file 8g
mkfs.ext2 $image_file
mkdir -p $mount_dir
sudo mount -o loop  $image_file $mount_dir
sudo debootstrap --arch amd64 buster $mount_dir

# update root password
echo 'root:root' | sudo chroot $mount_dir chpasswd

# create new user with home
sudo chroot $mount_dir /bin/bash -c "useradd $new_user -m -s /bin/bash"
# default password username
echo "$new_user:$new_user" | sudo chroot $mount_dir chpasswd

# update hostname, hosts file, and network interfaces
cat << EOF | sudo chroot $mount_dir
echo $new_host > /etc/hostname
sed -i "2i127.0.1.1 $new_host" /etc/hosts
echo "auto lo" >> /etc/network/interfaces
echo "iface lo inet loopback" >> /etc/network/interfaces
EOF

# make drive writable
cat << EOF | sudo tee "$mount_dir/etc/fstab"
/dev/sda / ext4 errors=remount-ro,acl 0 1
EOF

# copy host resolve.conf to guest to get networking working in chroot command
sudo cp /etc/resolv.conf $mount_dir/etc/resolv.conf

# need to mount device files and /proc for the jailed commands like apt-get
# installation to work in the chroot environment
sudo mount -o bind,ro /dev $mount_dir/dev
sudo mount -o bind,ro /dev/pts $mount_dir/dev/pts
sudo mount -t proc none $mount_dir/proc

cat << EOF | sudo LANG=C.UTF-8 chroot $mount_dir 
apt-get update
apt-get install -y sudo ssh
apt-get install -y ifupdown net-tools network-manager
apt-get install -y curl wget
EOF

# unmount the device files and /proc
sudo umount $mount_dir/dev/pts
sudo umount $mount_dir/dev
sudo umount $mount_dir/proc

# unmount image mount point
sudo umount $mount_dir
