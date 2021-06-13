# Build Custom Kernel 

Reference:

* https://kernelnewbies.org/KernelBuild 

## Install Toolchain
 
```bash
sudo apt-get install libncurses5-dev gcc make git exuberant-ctags bc libssl-dev flex bison
```
 
Try to build the kernel on a host with similar kernel versions
 
## Download Linux Source
 
 
```bash
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.4.86.tar.xz 
tar xvf linux-5.4.86.tar.xz
```
 
## Kernel Config  
 
If the host kernel version is similar to the built kernel, then copy the host build config:
 
```bash
cp /boot/config-`uname -r`* linux-5.4.86/.config 
```
 
Otherwise, generate a basic config:
 
```bash
cd linux-5.4.86
make x86_64_defconfig
make kvm_guest.config 
```

## Compile

```bash
make -j16 
```
