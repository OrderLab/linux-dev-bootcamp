## Performance Profiling


### Kernel

TBA

### Perf

The default Debian kernel does not have the `perf` tool enabled. We need to compile it in order to use the `perf` tool like in a stock OS.

1. Clone the custom kernel repo into the VM:

```
git clone /path/to/custom/kernel/repo kernel
cd kernel
```

2. Install dependencies:

```bash
sudo apt install libelf-dev libdw-dev libunwind-dev
```

3. Compile

```bash
cd tools/perf && make -j16
```

After the compilation succeeds, you will see the `perf` executable in the directory. And you can use the `sudo ./perf ...` command.

#### References

[1] https://eastrivervillage.com/Custom-perf-with-custom-kernel
