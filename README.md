## QEMU Bash Completion

This is bash completion functions for `qemu-system` , `qemu-user` ,
`qemu-utils` commands.

```sh
bash$ hostnamectl
Operating System: Ubuntu 22.04.1 LTS
          Kernel: Linux 5.15.0-43-generic
    Architecture: x86-64

bash$ qemu-system-x86_64 --version
QEMU emulator version 6.2.0 (Debian 1:6.2+dfsg-2ubuntu6.4)
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


