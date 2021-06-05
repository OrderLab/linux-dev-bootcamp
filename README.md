# Linux Development Guide
 
## Virtual Machine Dev Environment 


### 1. QEMU (recommended): 
 
Reference:

* https://www.collabora.com/news-and-blog/blog/2017/01/16/setting-up-qemu-kvm-for-kernel-development/
* https://medium.com/@daeseok.youn/prepare-the-environment-for-developing-linux-kernel-with-qemu-c55e37ba8ade 
 
The advantages of a QEMU-based dev environment are the quick cycle of kernel rebuilding and booting. It is also friendly to headless servers. Thus, this is the recommended development environment.

#### 1.a Install Dependencies

```bash
$ sudo apt-get install  debootstrap libguestfs-tools qemu-system-x86
```
 
#### 1.b Create Rootfs
 
QEMU can boot a kernel image directly, e.g., 
 
```bash
$ sudo qemu-system-x86_64 -kernel /boot/vmlinuz-`uname -r`
```
 
The missing part is a root file system, which we need to create.
 
Basically, we will create an empty QEMU image first, then format it to an ext2 file system, mount the image file to a temporary directory, and then install a Debian 10 (buster) distribution into the temporary directory using a tool called debootstrap (https://manpages.debian.org/unstable/debootstrap/debootstrap.8.en.html). We use Debian as the base system because it is stable and only contains the essential files, compared to a feature-rich Ubuntu system (debootstrap can also install an Ubuntu image if needed). 

##### Rootfs Setup Script

A root fs bootstrap script is provided, which will automatically create a 
debian buster based root file system with the setup for user accounts, 
network, common packages, etc.

The usage is simply: `./bootstrap.sh [image_file] [mount_dir]`

```bash
$ ./bootstrap.sh my-linux.img qemu-mount.dir
```

##### Manual Rootfs Setup
 
 
```bash
$ qemu-img create my-linux.img 4g 
$ mkfs.ext2 my-linux.img 
$ mkdir qemu-mount.dir 
$ sudo mount -o loop  my-linux.img qemu-mount.dir/ 
$ sudo debootstrap --arch amd64 buster qemu-mount.dir 
```
 
Before we unmount the directory, we should first set the root user password and create a new user using chroot. Otherwise, the root user is locked by default from Debian 10 and we will not be able to login because the root user is locked and its password is not set.
 
```bash
$ echo 'root:root' | sudo chroot qemu-mount.dir chpasswd
$ sudo chroot qemu-mount.dir /bin/bash -c "useradd $USER -m -s /bin/bash
$ echo "$USER:$USER" | sudo chroot qemu-mount.dir chpasswd
```

**Update hostname, hostsfile and network interfaces**

```bash
cat << EOF | sudo chroot qemu-mount.dir
echo debian-buster > /etc/hostname
sed -i "2i127.0.1.1 debian-buster" /etc/hosts
echo "auto lo" >> /etc/network/interfaces
echo "iface lo inet loopback" >> /etc/network/interfaces
EOF
```
 
**Remount root filesystem as writable**
 
```bash
$ cat << EOF | sudo tee "qemu-mount.dir/etc/fstab"
/dev/sda / ext4 errors=remount-ro,acl 0 1
EOF
```

**Install Common Packages**

Common packages like `ssh` and `sudo` are not installed in the default Debian 
image. We will need to use `apt-get` to install them. The packages can be 
installed in the jailed (chroot) environment through the host without booting
the VM image. 

To do so, however, we cannot simply execute `chroot` and then `apt-get` at 
this point. We need to mount device files and proc from the host OS **temporarily**.

```bash
sudo mount -o bind,ro /dev qemu-mount.dir/dev
sudo mount -o bind,ro /dev/pts qemu-mount.dir/dev/pts
sudo mount -t proc none qemu-mount.dir/proc
```

Note that we mount the /dev as read-only to prevent the jailed commands 
from modifying the device files in some scenarios.

Now we can install the packages through two ways: 

1. Interactive shell:

```bash
sudo LANG=C.UTF-8 chroot /bin/bash --login
```

2. Command line (script):

```bash
cat << EOF | sudo LANG=C.UTF-8 chroot qemu-mount.dir
apt-get update
apt-get install -y sudo ssh
apt-get install -y ifupdown net-tools network-manager
apt-get install -y curl wget
EOF
```

**Unmount the device files and proc**

```bash
sudo umount qemu-mount.dir/dev/pts
sudo umount qemu-mount.dir/dev
sudo umount qemu-mount.dir/proc
```
 
**Unmount the image directory**
 
```bash
$ sudo umount qemu-mount.dir
```
 
### 2. VirtualBox:
 
Reference: 

* https://cs4118.github.io/dev-guides/debian-vm-setup.html 
* https://linuxize.com/post/how-to-install-virtualbox-guest-additions-on-debian-10/ 
 
 
## Boot Virtual Machine with Stock Kernel

### 1. QEMU: 
 
#### With graphic window (if running locally):
 
```bash
$ sudo qemu-system-x86_64 -kernel /boot/vmlinuz-`uname -r` -hda my-linux.img -append "root=/dev/sda single" 
```
 
#### Text-mode (if running in remote server):
 
```bash
$ sudo qemu-system-x86_64 -kernel /boot/vmlinuz-`uname -r` -hda my-linux.img -append "root=/dev/sda single console=ttyS0" --nographic
```
 
After the system boots up, use the root user login (password is “root”) or press Ctrl-D to login with the new user created in the previous step.

### 2. VirtualBox:
TBA


## Build Custom Kernel 

Reference:

* https://kernelnewbies.org/KernelBuild 

### Install Toolchain
 
```bash
$ sudo apt-get install libncurses5-dev gcc make git exuberant-ctags bc libssl-dev
```
 
Try to build the kernel on a host with similar kernel versions
 
### Download Linux Source
 
 
```bash
$ wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.4.86.tar.xz 
$ tar xvf linux-5.4.86.tar.xz
```
 
### Kernel Config  
 
If the host kernel version is similar to the built kernel, then copy the host build config:
 
```bash
$ cp /boot/config-`uname -r`* linux-5.4.86/.config 
```
 
Otherwise, generate a basic config:
 
```bash
$ cd linux-5.4.86
$ make x86_64_defconfig
$ make kvm_guest.config 
```

### Compile

```bash
$ make -j16 
```
 
## Boot VM with Custom Kernel
 
```bash
$ cd linux-5.4.86
$ sudo qemu-system-x86_64 -kernel arch/x86/boot/bzImage  -hda ../my-linux.img -append "root=/dev/sda console=ttyS0" -m 2G --nographic
```
 
```bash
Debian GNU/Linux 10 razor5 ttyS0
 
razor5 login: root
Password: 
Linux razor5 5.4.86 #1 SMP Mon Jan 4 12:34:19 EST 2021 x86_64
 
The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.
 
Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
root@razor5:~# 
```
 
## Enable KVM
 
KVM can significantly accelerate the boot time.
 
```bash
$ sudo qemu-system-x86_64 -kernel arch/x86/boot/bzImage  -hda ../my-linux.img -append "root=/dev/sda console=ttyS0" --enable-kvm -m 2G --nographic
```
 
## Enable Network

### 1. QEMU: 
 
Boot into the system image with root user using the previous command
 
```bash
root@razor5:~# ip link show
```
 
If the output shows something besides “lo” (loopback), then we can use that to create a DHCP configuration. If it only outputs the “lo”, then we need more complicated QEMU network configuration: https://wiki.qemu.org/Documentation/Networking.
 
#### Shut down the system

```bash
root@razor5:~# shutdown now 
```

#### Remount the system image
 
```bash
$ sudo mount -o loop  my-linux.img qemu-mount.dir/
 
$ cat << EOF | sudo tee "qemu-mount.dir/etc/network/interfaces.d/00mylinux"
auto lo
iface lo inet loopback
auto enp0s3
iface enp0s3 inet dhcp
EOF
```

## Modify Kernel

### Add a custom syscall

Reference: 

* https://brennan.io/2016/11/14/kernel-dev-ep3/

TBA


## Debugging 
 
Reference:

* https://www.collabora.com/news-and-blog/blog/2017/03/13/kernel-debugging-with-qemu-overview-tools-available/ 
* https://wiki.osdev.org/How_Do_I_Use_A_Debugger_With_My_OS 

TBA

## References

* https://brennan.io/2017/03/08/sane-kernel-dev/ 
* https://kernelnewbies.org/KernelHacking
