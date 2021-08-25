# Virtual Machine Setup


It is recommended to use either `libvirt` management suite or raw QEMU for the Linux kernel development. The following instructions are based on Ubuntu 18.04.


## Choice 1: libvirt Managed KVM

The [libvirt](https://wiki.debian.org/libvirt) (`virsh`) suite provides management of different vitalization solutions
including KVM and Xen. It's more handy to control the VM, networking, etc., 
than typing raw QEMU commands each time.

Install the `libvirt` toolchain:

```bash
sudo apt-get install qemu-system qemu-kvm libvirt-daemon-system libvirt-clients virtinst ebtables dnsmasq
```

Your username must be in the `libvirt` group. If not, add the user to the group: `sudo usermod -aG libvirt ryan`.

### 1.a Customize Preseed File
Use the pressed file [debian-buster-preseed.cfg](debian-buster-preseed.cfg) in this repo to 
automate the guest OS installation. Copy and customize it:

```bash
mkdir workspace && cd workspace
git clone git@github.com:OrderLab/linux-dev-bootcamp.git bootcamp
mkdir vm && cd vm
cp ../bootcamp/debian-buster-preseed.cfg preseed.cfg
```

Use an editor to change `preseed.cfg` such as the new user, initial password, hostname. 
For example, you can change the hostname configuration as follows:

```diff
- d-i netcfg/get_hostname string order
+ d-i netcfg/get_hostname string obiwan-dev
```

### 1.b Download and Mount Guest OS Installation ISO

```bash
wget -O debian-10.9.0-amd64-netinst.iso https://cdimage.debian.org/cdimage/archive/10.9.0/amd64/iso-cd/debian-10.9.0-amd64-netinst.iso
mkdir debian10-amd64
sudo mount -t iso9660 -r -o loop debian-10.9.0-amd64-netinst.iso debian10-amd64
loop_path=$(/sbin/losetup --list -O NAME,BACK-FILE | grep debian-10.9.0-amd64-netinst.iso | tail -n 1 | cut -d' ' -f 1)
echo $loop_path
```
**Double check that `loop_path` is not empty and correspond to the iso image** (`/sbin/losetup --list -O NAME,BACK-FILE | grep debian-10.9.0-amd64-netinst.iso`)

### 1.c Create Guest VM Image and Install Guest OS

We will perform the installation without GUI and in a non-interactive way:

```bash
proj=obiwan-dev
qemu-img create -f qcow2 $proj.qcow2 32G

virt-install --virt-type kvm --name $proj --os-variant debian10 --location debian10-amd64 \
--disk path=$loop_path,device=cdrom,readonly=on --disk path=$proj.qcow2,size=32 \
--initrd-inject=preseed.cfg --memory 16384 --vcpus=8 --graphics none \
--console pty,target_type=serial --extra-args "console=ttyS0" 
```

The installation beginning will show a couple of error messages like 
`mount: mounting /dev/vda on /media failed: Invalid argument`. Those 
are benign errors due to the empty disk image.

If the installation succeeds, the VM will boot into GRUB and you will be able
to select Debian.

<details>
  <summary>Resolve <b>"No common CD-ROM drive was detected"</b> error</summary>
  
If you encounter an error message of "No common CD-ROM drive was detected"

[[/images/no-cdrom-error.png\|width=50|no-cdrom-error]]

This is likely because of the wrong loop device (`/dev/loop0`) used in the `virt-install` command. Find the correct device path:

```bash
$ /sbin/losetup --list -O NAME,BACK-FILE | grep debian-10.9.0-amd64-netinst.iso
/dev/loop9  /home/ryan/project/obi-wan/vm/debian-10.9.0-amd64-netinst.iso
```

Then replace `/dev/loop0` in the command with the correct path. And retry `virt-install`:

```bash
virsh destroy $proj
virsh undefine $proj
rm -f $proj.qcow2
qemu-img create -f qcow2 $proj.qcow2 32G
loop=/dev/loop9

virt-install --virt-type kvm --name $proj --os-variant debian10 --location debian10-amd64 \
--disk path=$loop,device=cdrom,readonly=on --disk path=$proj.qcow2,size=32 \
--initrd-inject=preseed.cfg --memory 16384 --vcpus=8 --graphics none \
--console pty,target_type=serial --extra-args "console=ttyS0" 
```

If somehow this fix still does not work, the fallback solution that should work is directly execute `virt-install` with `sudo` and passing the `.iso` image instead of the mounted path:

```bash
sudo virt-install --virt-type kvm --name $proj --os-variant debian10 --location debian-10.9.0-amd64-netinst.iso --disk path=$proj.qcow2,size=32 \
--initrd-inject=preseed.cfg --memory 16384 --vcpus=8 --graphics none \
--console pty,target_type=serial --extra-args "console=ttyS0" 
```

</details>

### 1.d Manage and Login to Guest VM

Use `virsh` to list, start, shutdown, login to the create guest VM.

```bash
$ virsh list --all
 Id    Name                           State
----------------------------------------------------
 -     obiwan-dev                     shut off
$ virsh start obiwan-dev
$ virsh console obiwan-dev
```

The last two steps can be combined into one step of `virsh start obiwan-dev --console`.

To gracefully shutdown the VM, run `virsh shutdown obiwan-dev`. If the graceful 
shutdown is not successful, run `virsh destroy obiwan-dev`. Destroy does *not* 
delete the virtual disk file. It only powers off the VM. To delete the VM, 
run `virsh undefine obiwan-dev` and manually delete the disk image file.

Install SSH server, update the VM hostname so that we can SSH into the VM later 
using the hostname.

```bash
$ virsh console obiwan-dev
Connected to domain psbox-dev
Escape character is ^]

order login: root
Password:
Last login: Wed Jun  9 03:53:39 EDT 2021 on ttyS0
...
root@order:~# apt-get install openssh-server
root@order:~# hostnamectl set-hostname obiwan-dev
```

### 1.e Configure Networking

The default bridge networking created by libvirt should work directly for most cases. If 
not, refer to the manual networking [configuration document](https://wiki.debian.org/KVM#Setting_up_bridge_networking).
The default NATed, briedged network that libvirt provides is called `default`:

```bash
$ virsh net-list
 Name                 State      Autostart     Persistent
----------------------------------------------------------
 default              active     yes           yes
$ virsh net-info default
Name:           default
UUID:           02cc5180-60e3-429a-af96-d1e08cb0a8a4
Active:         yes
Persistent:     yes
Autostart:      yes
Bridge:         virbr0
$ virsh net-dhcp-leases default
 Expiry Time          MAC address        Protocol  IP address                Hostname        Client ID or DUID
-------------------------------------------------------------------------------------------------------------------
```

A DHCP service is provided to the guest VMs via `dnsmasq`.  The VMs using this network 
will end up in `192.168.122.1/24` (or `192.168.123.1/24`). This network is not 
automatically started. To start it use: `virsh net-start default`.

Because the VMs get IPs from the DHCP service, their IPs can change upon reboots 
or when the DHCP lease expires. As a result, we will need to double check the guest 
VM ip address each time to ssh into the VM. We can configure the network manager 
to assign static IP to a VM. 

```bash
$ virsh dumpxml obiwan-dev | grep -i '<mac'
$ virsh net-edit default
```

Add a `<host>` entry to the `<dhcp>` element. Use the VM MAC address from the `virsh dumpxml` 
command in the `mac` field and any static IP in the range to assign to the VM.

```xml
    ...
    <dhcp>
      <range start='192.168.123.2' end='192.168.123.254'/>
      <host mac='52:54:00:f0:8b:6c' ip='192.168.123.2'/>
    </dhcp>
    ...
```

Then restart the virtual network:

```bash
$ virsh net-destroy default
$ virsh net-start default
$ virsh net-dhcp-leases default
 Expiry Time          MAC address        Protocol  IP address                Hostname        Client ID or DUID
-------------------------------------------------------------------------------------------------------------------
 2021-06-09 06:10:05  52:54:00:f0:8b:6c  ipv4      192.168.123.2/24          obiwan-dev      ff:00:f0:8b:6c:00:01:00:01:28:52:95:00:52:54:00:f0:8b:6c
```

Now, you can SSH into the guest VM (assuming SSH server is running the credentials
have been set up correctly) with the static IP: `ssh 192.168.123.2`.

To make it even more conveniently SSH into the guest VM, we would like to 
directly use the guest VM's hostname. For a single VM, we can modify the 
`/etc/hosts` file. But more generally, it is recommended to use the 
libvirt NSS module, which will allow `ssh` to consult `libvirt` with
guest VM hostname. 

```bash
sudo apt-get install libnss-libvirt
```

The usage of this module is simple: follow the [NSS module documentation](https://libvirt.org/nss.html). 
In particular, just add `libvirt` to the `hosts` line into the `/etc/nsswitch.conf` file:

```
hosts:          files libvirt dns
```

Now, we can do directly SSH with the VM's hostname:

```bash
ssh obiwan-dev
```


## Choice 2: Raw QEMU 
 
You can also directly use QEMU. Compared to libvirt, it is more cumbersome to type the full QEMU command each time. The raw QEMU commands do give you direct control. However, there is no fundamental difference between the two in terms of their underlying capabilities. The VM images libvirt creates and manages can also be used directly by raw QEMU commands. libvirt provides handy interfaces such as persisting the VM profiles and network management. Thus, it is our recommended choice.



### 2.a Install Dependencies

```bash
$ sudo apt-get install  debootstrap libguestfs-tools qemu-system-x86
```
 
### 2.b Create Rootfs
 
QEMU can boot a kernel image directly, e.g., 
 
```bash
sudo qemu-system-x86_64 -kernel /boot/vmlinuz-`uname -r`
```
 
The missing part is a root file system, which we need to create.
 
Basically, we will create an empty QEMU image first, then format it to an ext2 file system, mount the image file to a temporary directory, and then install a Debian 10 (buster) distribution into the temporary directory using a tool called debootstrap (https://manpages.debian.org/unstable/debootstrap/debootstrap.8.en.html). We use Debian as the base system because it is stable and only contains the essential files, compared to a feature-rich Ubuntu system (debootstrap can also install an Ubuntu image if needed). 

#### Rootfs Setup Script

A root fs bootstrap script is provided, which will automatically create a 
debian buster based root file system with the setup for user accounts, 
network, common packages, etc.

The usage is simply: `./bootstrap.sh [image_file] [mount_dir]`

```bash
./bootstrap.sh my-linux.img qemu-mount.dir
```

#### Manual Rootfs Setup
 
 
```bash
image_file=my-linux.img
mount_dir=qemu-mount.dir
new_user=$USER
new_host=debian-buster

qemu-img create $image_file 8g
mkfs.ext2 $image_file
mkdir -p $mount_dir
sudo mount -o loop  $image_file $mount_dir
sudo debootstrap --arch amd64 buster $mount_dir
```
 
Before we unmount the directory, we should first set the root user password and create a new user using chroot. Otherwise, the root user is locked by default from Debian 10 and we will not be able to login because the root user is locked and its password is not set.
 
```bash
echo 'root:root' | sudo chroot $mount_dir chpasswd
sudo chroot $mount_dir /bin/bash -c "useradd $new_user -m -s /bin/bash"
echo "$new_user:$new_user" | sudo chroot $mount_dir chpasswd
```

**Update hostname, hostsfile and network interfaces**

```bash
cat << EOF | sudo chroot $mount_dir
echo $new_host > /etc/hostname
sed -i "2i127.0.1.1 $new_host" /etc/hosts
echo "auto lo" >> /etc/network/interfaces
echo "iface lo inet loopback" >> /etc/network/interfaces
EOF
```
 
**Remount root filesystem as writable**
 
```bash
cat << EOF | sudo tee "$mount_dir/etc/fstab"
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
sudo cp /etc/resolv.conf $mount_dir/etc/resolv.conf
sudo mount -o bind,ro /dev $mount_dir/dev
sudo mount -o bind,ro /dev/pts $mount_dir/dev/pts
sudo mount -t proc none $mount_dir/proc
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
cat << EOF | sudo LANG=C.UTF-8 chroot $mount_dir 
apt-get update
apt-get install -y sudo ssh
apt-get install -y ifupdown net-tools network-manager
apt-get install -y curl wget
EOF
```

**Unmount the device files and proc**

```bash
sudo umount $mount_dir/dev/pts
sudo umount $mount_dir/dev
sudo umount $mount_dir/proc
```
 
**Unmount the image directory**
 
```bash
sudo umount $mount_dir
```

### 2.c References

* https://www.collabora.com/news-and-blog/blog/2017/01/16/setting-up-qemu-kvm-for-kernel-development/
* https://medium.com/@daeseok.youn/prepare-the-environment-for-developing-linux-kernel-with-qemu-c55e37ba8ade 
 


## Choice 3: VirtualBox
 
Reference: 

* https://cs4118.github.io/dev-guides/debian-vm-setup.html 
* https://linuxize.com/post/how-to-install-virtualbox-guest-additions-on-debian-10/ 
