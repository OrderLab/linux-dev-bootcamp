# Boot and Install Custom Kernel in VM

## 1. Boot Custom Kernel
 
### QEMU

If using raw QEMU to boot the VM image with the custom kernel, you can specify the `-kernel` command argument to point to the custom kernel image:

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

### Direct kernel boot under `libvirt`

When using `libvirt` to manage the VM, the VM by default boots with the virtual disk's kernel. Testing an updated kernel involves `scp` or sharing the kernel image to the VM and installing the kernel in the guest. For frequently testing kernel changes, a more efficient way is to 
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

### Enable KVM (with QEMU command)
 
KVM can significantly accelerate the boot time. `libvirt` probes the presence of KVM and enables it in the VM profile if it's available. Thus,  no additional configuration needs to be done. For raw QEMU, you need to add the `--enable-kvm` option:
 
```bash
sudo qemu-system-x86_64 -kernel arch/x86/boot/bzImage  -hda ../my-linux.img \
-append "root=/dev/sda console=ttyS0" --enable-kvm -m 4G --nographic
```

If you do not want to risk using `sudo` every time running QEMU, here is a way to run as normal user.

KVM only requires access to `/dev/kvm`, which has owner `root:kvm` and file mode `660`. Add a normal user to the `kvm` group:

```bash
sudo usermod -a -G kvm `whoami`
```

User group modification takes effect after logging out and logging in again.

## 2. Install Custom Kernel

It is recommended to install the custom kernel into the VM at least once as well. To do that, you need to build the kernel into [distribution packages](https://github.com/OrderLab/linux-dev-bootcamp/wiki/Build-Custom-Kernel#package). Then copy the package files into the VM either through shared folder or scp. 

Once in the VM, install the package files:

```bash
sudo dpkg -i linux-headers-5.4.0_5.4.0-1_amd64.deb
sudo dpkg -i linux-image-5.4.0_5.4.0-1_amd64.deb
sudo dpkg -i linux-libc-dev_5.4.0-1_amd64.deb
```

Note: there might be a .deb package for a debug image, e.g., `linux-image-5.4.0-dbg_5.4.0-1_amd64.deb`, which is quite big. Do *NOT* install that package.

Reboot the VM. Now without specifying the custom kernel in the boot option, you should still see the new kernel version:

```bash
uname -a
```

Note after you install the custom kernel, you will likely encounter a loss of VM network after you reboot the VM. Refer to the [troubleshooting page](https://github.com/OrderLab/linux-dev-bootcamp/wiki/Troubleshooting#loss-of-vm-network-after-installing-new-kernel) for how to resolve the issue.

## 3. Change grub entry

To automatically select the custom kernel during booting: 

1. Find the custom kernel menu entry: 

```
grep -e "menuentry " -e submenu -e linux /boot/grub/grub.cfg
```

For example, if the output is

```bash
...
submenu 'Advanced options for Ubuntu' $menuentry_id_option 'gnulinux-advanced-8b9e1980-828f-418f-ae44-80689ca8bd2f' {
	menuentry 'Ubuntu, with Linux 5.4.0-100-generic' --class ubuntu --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-5.4.0-100-generic-advanced-8b9e1980-828f-418f-ae44-80689ca8bd2f' {
		gfxmode $linux_gfx_mode
		linux	/boot/vmlinuz-5.4.0-100-generic root=UUID=8b9e1980-828f-418f-ae44-80689ca8bd2f ro console=ttyS1,115200
	menuentry 'Ubuntu, with Linux 5.4.0-100-generic (recovery mode)' --class ubuntu --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-5.4.0-100-generic-recovery-8b9e1980-828f-418f-ae44-80689ca8bd2f' {
		linux	/boot/vmlinuz-5.4.0-100-generic root=UUID=8b9e1980-828f-418f-ae44-80689ca8bd2f ro recovery nomodeset dis_ucode_ldr console=ttyS1,115200
	menuentry 'Ubuntu, with Linux 5.4.0' --class ubuntu --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-5.4.0-advanced-8b9e1980-828f-418f-ae44-80689ca8bd2f' {
		gfxmode $linux_gfx_mode
		linux	/boot/vmlinuz-5.4.0 root=UUID=8b9e1980-828f-418f-ae44-80689ca8bd2f ro console=ttyS1,115200
	menuentry 'Ubuntu, with Linux 5.4.0 (recovery mode)' --class ubuntu --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-5.4.0-recovery-8b9e1980-828f-418f-ae44-80689ca8bd2f' {
		linux	/boot/vmlinuz-5.4.0 root=UUID=8b9e1980-828f-418f-ae44-80689ca8bd2f ro recovery nomodeset dis_ucode_ldr 
...
```

Assume our custom kernel is 'Ubuntu, with Linux 5.4.0', which is the 3rd `menuentry` under the `submenu`.


2. Change the `GRUB_DEFAULT=0` line in the `/etc/default/grub` file. If the custom kernel is the `Nth` `menuentry` under `submenu`, change it to `GRUB_DEFAULT="1>$N-1$"`. For example, for a 3rd `menuentry`, change it to `GRUB_DEFAULT="1>2"`.

3. Update grub script and reboot:

```
sudo update-grub

sudo reboot
```


