# Boot Virtual Machine with Stock Kernel

## 1. QEMU: 
 
### With graphic window (if running locally):
 
```bash
qemu-system-x86_64 -kernel /boot/vmlinuz-`uname -r` -hda my-linux.img \
-append "root=/dev/sda single" 
```
 
### Text-mode (if running in remote server):
 
```bash
qemu-system-x86_64 -kernel /boot/vmlinuz-`uname -r` -hda my-linux.img \
-append "root=/dev/sda single console=ttyS0" --nographic
```
 
After the system boots up, use the root user login (password is “root”) or press Ctrl-D to login with the new user created in the previous step. To skip typing user name and password every time, see [[Auto-login|Automation#auto-login]].

## 2. Libvirt

```bash
virsh list --all
virsh start obiwan-dev
ssh obiwan-dev
```

## 3. VirtualBox:
TBA
