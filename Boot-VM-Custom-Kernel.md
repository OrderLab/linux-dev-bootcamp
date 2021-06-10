# Boot VM with Custom Kernel
 
```bash
cd linux-5.4.86
sudo qemu-system-x86_64 -kernel arch/x86/boot/bzImage  -hda ../my-linux.img \
-append "root=/dev/sda console=ttyS0" -m 4G --nographic
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
sudo qemu-system-x86_64 -kernel arch/x86/boot/bzImage  -hda ../my-linux.img \
-append "root=/dev/sda console=ttyS0" --enable-kvm -m 4G --nographic
```
 
