# Troubleshooting

## Serial size is fixed at 80x24

In `-nographic` mode, QEMU serial uses `vt220` and cannot automatically fit to the host's terminal size. Thus commands such as `vim` and `tmux` may become inconvenient to use. We can manually set terminal size in the VM.

First get the host terminal size. The first value below is rows and the second is columns.

```bash
stty size
# 42 130
```

Then set the terminal size in VM. Put this in VM's `~/.bash_login`

```bash
if [ ! -f /tmp/ALREADYRESET ]; then
    touch /tmp/ALREADYRESET
    stty rows 42 cols 130
    tput init
fi
```

Alternatively, setup `ssh` or `telnet` to connect to the VM.

## Force-quit QEMU

Sometimes our modified kernel may panic, and we need to force halt the VM. We can use `pkill` in the host to kill QEMU. Alternatively, press `Ctrl-a x` in the QEMU serial console. This is useful in text mode (`-nographic` mode).

QEMU will terminate and print:

```
QEMU: Terminated
```

Side note: There are other functionalities in `Ctrl-a`. Press `Ctrl-a h` for help. For example, `Ctrl-a c` switches between console and [QEMU Monitor](https://qemu-project.gitlab.io/qemu/system/monitor.html). You may see something like below if you accidentally pressed `Ctrl-a c`. Press `Ctrl-a c` to switch back to VM.

```
QEMU 2.11.1 monitor - type 'help' for more information
(qemu)
```

To send a real `Ctrl-a` (go to start of line) to the VM, press `Ctrl-a` twice. To send `Ctrl-a` into `screen` in the VM, press `Ctrl-a Ctrl-a a`.

## Fixing corrupted file system

Sometimes if you happen to run the VM and mount the disk image at the same time, the file system may be messed up.

First unmount the disk image and shutdown the VM. Then use fsck tools (`e2fsck` for ext4) to fix the file system.

```bash
e2fsck -f qemu-image.img
```

In most cases if the VM, only file system stats needs to be recalculated and no data will loss. 

There may have some data corruption or data loss In some cases.

## Extending disk size

First extend the disk image size with `qemu-img`, and then use file system utility (`resize2fs` for ext4) to resize the file system.

```bash
qemu-img resize qemu-image.img +1G
e2fsck -f qemu-image.img
resize2fs qemu-image.img
```

**Caution for shrinking**: We need to change the above command order for shrinking. File system resizing must be done before resizing disk image.

## Reduce VM image size

The VM image size can grow into an explosive size after a while (e.g., 30+ GB), even though the total data you add to the VM is definitely not that big. This is because of the free space in the VM image is not reclaimed. You can use the `virt-sparsify` tool to reduce the image size, which is easy to use and safe. Please read the man page of `virt-sparsify` first: https://libguestfs.org/virt-sparsify.1.html

**Shut down the VM**, then run the command `virt-sparsify indisk.img outdisk.img`. You should see significantly reduced image size for the `outdisk.img`. Test the new image with QEMU and verify it does not loose data. After you double check it works, you can delete `indisk.img` and rename `outdisk.img` to `indisk.img`.

If the VM image format is `qcow2`, you can further add `--compress` option to compress the large image. 







## Loss of VM network after installing new kernel

When you install the custom-built kernel for the first time, you will likely encounter a loss of VM network after the VM reboots. The root cause is because the network interface changed with the custom kernel, so you need to update the network configuration to restore the network functionality.

#### Symptom

The VM's network interface no longer has an IP address: 

```bash
$ sudo ifconfig -a
enp0s2: flags=4098<BROADCAST,MULTICAST>  mtu 1500
        ether 52:54:00:f0:8b:6c  txqueuelen 1000  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
...
```

On the host, the DHCP lease is also gone:

```bash
$ virsh net-dhcp-leases default
 Expiry Time          MAC address        Protocol  IP address                Hostname        Client ID or DUID
-------------------------------------------------------------------------------------------------------------------
```

#### Diagnosis

Check the network interface configuration file `/etc/network/interfaces` inside the VM:

```
...
allow-hotplug ens2
iface ens2 inet dhcp
```

There is an `ens2` in the configuration file, but there is no such interface in the output of `ifconfig -a`. In addition, the `ifconfig -a` shows an interface `enp0s2`, which does not appear in the configuration file. This discrepancy leads to our diagnosis hypothesis that the network interface `ens2` from the VM creation time no longer exists and a new interface `enp0s2` is added with the custom kernel. To validate this hypothesis, simply update the `ens2` in the configuration:

```diff
- allow-hotplug ens2
- iface ens2 inet dhcp
+ allow-hotplug enp0s2
+ iface enp0s2 inet dhcp
```

Reboot the VM, then check the `ifconfig` output:

```bash
$ sudo ifconfig -a
enp0s2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.123.2  netmask 255.255.255.0  broadcast 192.168.123.255
        inet6 fe80::5054:ff:fef0:8b6c  prefixlen 64  scopeid 0x20<link>
...
```

It gets assigned with the IP address now.

