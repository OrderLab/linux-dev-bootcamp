# Configure VM Networking

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
sudo mount -o loop  my-linux.img qemu-mount.dir/
 
cat << EOF | sudo tee "qemu-mount.dir/etc/network/interfaces.d/00mylinux"
auto lo
iface lo inet loopback
auto enp0s3
iface enp0s3 inet dhcp
EOF
```

