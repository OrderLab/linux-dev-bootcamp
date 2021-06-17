# Boot VM with Custom Kernel
 
```bash
cd linux-5.4.86
qemu-system-x86_64 -kernel arch/x86/boot/bzImage  -hda ../my-linux.img \
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
 
### Use QEMU with KVM without `sudo`

If you do not want to risk using `sudo` every time running QEMU, here is a way to run as normal user.

KVM only requires access to `/dev/kvm`, which has owner `root:kvm` and file mode `660`. Add a normal user to the `kvm` group:

```bash
sudo usermod -a -G kvm `whoami`
```

User group modification takes effect after logging out and logging in again.

## Direct kernel boot under `libvirt`

When using `libvirt` to manage the VM, the VM by default boots with the virtual disk's kernel. Testing an updated kernel involves `scp` or share the kernel image to the VM and installing the kernel in the guest. For frequently testing kernel changes, a more efficient way is to 
use the direct kernel boot option with the kernel image file on the host.

```bash
virsh edit obiwan-dev
```

Change the `<os>` tag to be like the following:

```bash
  <os>
    <type arch='x86_64' machine='pc-i440fx-bionic'>hvm</type>
    <kernel>/path/to/kernel/arch/x86/boot/bzImage</kernel>
    <cmdline>console=ttyS0 root=/dev/vda1 rw</cmdline>
    <boot dev='hd'/>
  </os>
```

Then later with `virsh start obiwan-dev`, the VM will always boot with the latest `bzImage` compiled in the host.




