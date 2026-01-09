# Apple Silicon CTF Environment

A lightweight virtual machine image pre-configured for CTF challenges designed for the Offensive and Defensive cybersecurity course at Politecnico di Milano A.Y. 2025/26.

The vm is based on [lima](https://github.com/lima-vm/lima) and its designed to run on **Apple Silicon Macs**.

## Overview

The VM runs on **Ubuntu 24.04** virtualized via [qemu](https://github.com/qemu/qemu) and contains:

- Pre configured python with `pwntools`, `angr`, `ropper` and `libdebug`
- gdb ([`pwndbg`](https://github.com/pwndbg/pwndbg))
- tmux
- [`one_gadget`](https://github.com/david942j/one_gadget)
- ... and other useful tools and packages for CTF challenges

## Requirements

To setup the vm you need a working installation of [Homebrew](https://docs.brew.sh/Installation)

## Getting started

```
git clone https://github.com/zaniluca/pwn
cd pwn
./setup.sh
```

This will create a `lima` instance named `default` and start it, you can then connect to it via:

```
lima
```

And voilà, you are in your ctf environment!
You can stop the vm via:

```sh
limactl stop default # or limactl stop since 'default' is the default instance
```

To start it again:

```sh
limactl start default # or simply limactl start
```

> If you want a different instance name, you can change `VM_NAME` in the `setup.sh` script before running it.

## VSCode integration

> Note: The setup script automatically configures SSH for you!

You can use VSCode to edit files directly inside the VM via SSH:

1. Install [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extension
2. Start the VM: `limactl start`
3. Connect via: Cmd+Shift+P -> "Remote-SSH: Connect to Host" -> lima-default

You'll be connected to the VM inside VSCode.

> TIP: If you're inside vscode (without being connected via ssh), open the terminal and run `lima` you'll be inside the vm **inside the current working directory**, this is very useful as it allows for an experience similar to WSL on Windows.

## Additional information

- I've tested this setup on a MacBook Pro M4 Pro and the performance was fine, bear in mind that on lower end machines the VM might be a bit slow.
- You can increase the VM resources (cpu, ram, disk) by editing either the template `pwn.yaml` or when starting the VM via `limactl start default --cpu 4 --memory 8 --disk 50` (for 4 cpu, 8gb ram and 50gb disk)
- Once inside the VM you can install additional packages via `sudo apt install <package>` as usual
- See [lima documentation](https://lima-vm.io/docs/) for more information about lima usage and configuration

## Contributing

Feel free to open issues or submit pull requests if you find any problems or something can be improved!
