## QEMU Bash Completion

This is bash completion functions for `qemu-system` , `qemu-user` ,
`qemu-utils` commands.

```sh
bash$ hostnamectl
Operating System: Ubuntu 22.10                    
          Kernel: Linux 5.19.0-23-generic
    Architecture: x86-64

bash$ qemu-system-x86_64 -version 
QEMU emulator version 7.0.0 (Debian 1:7.0+dfsg-7ubuntu2)
```

> please leave an issue above if you have any problems using this script.

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


