# Automation

## Command line alias

To facilitate faster development, we can set a group of alias commands in the host for common operations. Add the following to host shell startup file. Some commands require writing custom scripts.

```bash
export image_file=/path/to/my-linux.img
export mount_dir=/path/to/qemu-mount.dir
function mount_qemu_image() {
    sudo mount -o loop $image_file $mount_dir && \
    sudo mount -o bind,ro /dev $mount_dir/dev && \
    sudo mount -o bind,ro /dev/pts $mount_dir/dev/pts && \
    sudo mount -t proc none $mount_dir/proc
}
function unmount_qemu_image() {
    sudo umount $mount_dir/dev/pts
    sudo umount $mount_dir/dev
    sudo umount $mount_dir/proc
    sudo umount $mount_dir
}
# Mount/unmount disk image (do not mount if qemu is running)
alias m='pgrep qemu && echo "QEMU is running" || mount_qemu_image'
alias um=unmount_qemu_image
# Update image file (need to write custom cp/rsync scripts)
# You can also use (un)mount_qemu_image in the script.
alias ui='./updateimg.sh'
# Chroot into mounted disk image
# (`sudo' is used for setting $HOME and other variables correctly)
alias ch='sudo -i chroot $mount_dir'
# Run the VM (fail if still mounted) (need to write custom run.sh)
alias r='um; (mount | grep $mount_dir) || ./run.sh'
# Build the kernel
alias b='make -j`nproc`'
# Start gdb, attach to QEMU debug port, and boot the system
# (remove "-ex c" to stay in the gdb console)
alias g="gdb vmlinux -ex 'target remote 127.0.0.1:1234' -ex c"
# Force kill QEMU
alias k='killall qemu-system-x86_64'
```

## Auto-login

To skip typing user name and password in the serial console every time we start QEMU, we can change to auto-login.

By default, Debian uses `agetty` with `systemd`. Edit the file `/lib/systemd/system/serial-getty@.service`. Find something like

```ini
[Service]
ExecStart=-/sbin/agetty -o '-p -- \\u' --keep-baud 115200,38400,9600 %I $TERM
```

Add `-a root` after `agetty` command (`-a` stands for `--autologin`):

```ini
[Service]
ExecStart=-/sbin/agetty -a root -o '-p -- \\u' --keep-baud 115200,38400,9600 %I $TERM
```

## Auto-shutdown

To automatically shutdown the VM after `Ctrl-D` (or `exit`) in the login shell, add the following to `~/.bash_logout` in the VM.

```bash
# Shutdown automatically (but do not shutdown when closing tmux pane)
if [[ $TMUX = "" ]]; then
    shutdown -h now
fi
```

## Automatically run experiments

To automatically run experiments after login, we can add experiment commands to `~/.bash_login`.

Note that `~/.bashrc` has a different purpose and experiment commands should not be in this file. `~/.bashrc` is sourced for non-login shells, and `~/.bash_login` is for login shells. `chroot` from host uses non-login shell, while QEMU serial console uses a login shell. Running experiment code when `chroot` from the host is not a desired behavior, thus automated commands should only be in `~/.bash_login`.

Conversely, we can put environment variable exports like `export HISTSIZE=100000` in `~/.bashrc`. If `~/.bashrc` only contains common variables, we can even `source ~/.bashrc` in `~/.bash_login`.

## Tmux window

We can also automatically create Tmux layouts and run commands. See [clustermanager](https://github.com/OrderLab/clustermanager).

This can also be added into `~/.bash_login`.
