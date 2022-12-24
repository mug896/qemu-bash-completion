## QEMU Bash Completion

This is a bash completion function for `qemu-system*` , `qemu-user*` ,
`qemu-utils*` commands.
It's based on the help message output of the command.

```sh
bash$ hostnamectl
Operating System: Ubuntu 22.10                    
          Kernel: Linux 5.19.0-23-generic
    Architecture: x86-64

bash$ qemu-system-x86_64 -version 
QEMU emulator version 7.0.0 (Debian 1:7.0+dfsg-7ubuntu2)
```


## Installation

Copy contents of qemu-bash-completion.sh to ~/.bash_completion  
open new terminal and try auto completion !

## Usage


```sh
$ qemu-system-x86_64 -[tab]
Display all 121 possibilities? (y or n)
--preconfig           -echr                 -mtdblock             -sandbox
-D                    -enable-fips          -name                 -sd
-L                    -enable-kvm           -net                  -sdl
-S                    -enable-sync-profile  -netdev               -seed
-accel                -fda                  -nic                  -serial
-acpitable            -fdb                  -no-acpi              -set
-action               -fsdev                -no-fd-bootchk        -singlestep
-add-fd               -full-screen          -no-hpet              -smbios
-alt-grab             -fw_cfg               -no-quit              -smp
. . .
```

The `-global` option can be used in two ways.
if a value contain `.` char like `zoned.zasl` then you have to use the second method.

```sh
1) -global ide-hd.physical_block_size=4096

2) -global driver=ide-hd,property=physical_block_size,value=4096
```

> please leave an issue above if you have problems using this script.

