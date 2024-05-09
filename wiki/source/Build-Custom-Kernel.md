# Build Custom Kernel 

Reference:

* [https://kernelnewbies.org/KernelBuild](https://kernelnewbies.org/KernelBuild)

## Install Toolchain
 
```bash
sudo apt-get install libncurses5-dev gcc make git exuberant-ctags bc libssl-dev flex bison libelf-dev rsync
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

If you are building the kernel to run on a bare-metal machine, you may also need to disable some key signing-related configs:

```bash
scripts/config --disable SYSTEM_TRUSTED_KEYS
scripts/config --disable SYSTEM_REVOCATION_KEYS
scripts/config --disable SECURITY_LOCKDOWN_LSM
scripts/config --disable MODULE_SIG
scripts/config --disable MODULE_SIG_ALL
```

If the build script asks to customize other configs during the initial compilation stage, just press Enter to choose default for all other configs.

## Compile

```bash
make -j16 
```

#### Troubleshooting Errors

<details>
  <summary>Resolve <code class="docutils literal notranslate"><span class="pre">BTF: .tmp_vmlinux.btf: pahole (pahole) is not available Failed to generate BTF for vmlinux</span></code></summary>

<p></p>
Attempts to compile a more recent version of Linux may run into an error stating pahole is not available. To avoid this compilation error, use <code>sudo apt-get install dwarves</code> to install the missing package. 

<p></p>
Alternatively, the error can also be avoided by disabling BPF Type Format so pahole won't be needed. In the kernel config, run <code>scripts/config --disable CONFIG_DEBUG_INFO_BTF</code> to disable BPF Type Format.
</details>

## Package

```bash
make -j16 bindeb-pkg
```
