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
stty rows 42 cols 130
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
