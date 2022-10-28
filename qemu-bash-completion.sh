_init_comp_wordbreaks()
{
    if [[ $PROMPT_COMMAND == *";COMP_WORDBREAKS="* ]]; then
        [[ $PROMPT_COMMAND =~ ^:\ ([^;]+)\; ]]
        [[ ${BASH_REMATCH[1]} != "${COMP_WORDS[0]}" ]] && eval "${PROMPT_COMMAND%%$'\n'*}"
    fi
    if [[ $PROMPT_COMMAND != *";COMP_WORDBREAKS="* ]]; then
        PROMPT_COMMAND=": ${COMP_WORDS[0]};COMP_WORDBREAKS=${COMP_WORDBREAKS@Q};\
        "$'PROMPT_COMMAND=${PROMPT_COMMAND#*$\'\\n\'}\n'$PROMPT_COMMAND
    fi
}

_qemu_header()
{
    CUR=${COMP_WORDS[COMP_CWORD]} CUR_O=$CUR
    [[ ${COMP_LINE:COMP_POINT-1:1} = " " || $COMP_WORDBREAKS == *$CUR* ]] && CUR=""
    PREV=${COMP_WORDS[COMP_CWORD-1]} PREV_O=$PREV
    [[ $PREV == "=" ]] && PREV=${COMP_WORDS[COMP_CWORD-2]}
    COMP_LINE2=${COMP_LINE:0:$COMP_POINT}
    local i arr
    eval arr=( $COMP_LINE2 )
    for (( i = ${#arr[@]} - 1; i > 0; i-- )); do
        if [[ ${arr[i]} == -* ]]; then
            PREO=${arr[i]%%[^[:alnum:]_-]*}
            [[ ($PREO == ${COMP_LINE2##*[ ]}) && ($PREO == $CUR_O) ]] && PREO=""
            break
        fi
    done
}

_qemu_footer()
{
    if [[ -z $COMPREPLY ]]; then
        WORDS=$( <<< $WORDS sed -E 's/^[[:blank:]]+|[[:blank:]]+$//g' )
        if [[ $WORDS == *[[:graph:]][\ ][[:graph:]]* ]]; then
            IFS=$'\n' COMPREPLY=($(compgen -P \' -S \' -W "$WORDS" -- "$CUR"))
        else
            IFS=$'\n' COMPREPLY=($(compgen -W "$WORDS" -- "$CUR"))
        fi
    fi
    [[ ${COMPREPLY: -1} == "=" ]] && compopt -o nospace
}

_qemu_set_words()
{
    case $1 in
        -cpu)
            WORDS=$( $CMD -cpu help | sed -En '/^Available CPUs:/n; :X /^$/Q; s/^\s*([^ ]+ )?([^ ]+).*/\2/; p; n; bX' ) ;;
        chardev)
            WORDS=$'vc[:WxH]\npty\nnone\nnull\nchardev:id\n/dev/XXX\n/dev/parportN
            file:filename\nstdio\npipe:filename\nCOMn
            udp:[remote_host]:remote_port[@[src_ip]:src_port]\ntcp:[host]:port
            telnet:host:port\nwebsocket:host:port\nunix:path\nmon:dev_string
            braille\nmsmouse' ;;
        -object)
            if [[ -n $_qemu_object_help ]]; then
                HELP=$_qemu_object_help
                return
            fi
            HELP=$( man $CMD 2> /dev/null | gawk '/^\s*Generic object creation/,0 { 
                r = match($0, /[[:graph:]]/); 
                if (r > pv) { pv = r; c++ }; 
                if (c == 3) { 
                    while (getline) { 
                        if (match($0, "^[ ]{" r-1 "}-object")) { 
                            addres(); 
                            while (getline) { 
                                if (match($0, "^[ ]{" r-1 "}[[:graph:]]")) 
                                    addres();
                                else 
                                    break 
                }}}}} END { print gensub(/\xe2\x80\x90\n[ ]*/,"","g",res) }; 
                function addres() { res = res "\n" gensub(/^[ ]+-object[ ]+/,"-object ","g") }' )
            _qemu_object_help=$HELP
    esac
}

_qemu_set_optv()
{
    local arg1=$1 arg2=$2 help
    [[ $arg1 == *" "* ]] && arg1=${arg1/%/\\[?,} || arg1="$arg1 "

    if [[ -n $arg1 && -z $arg2 ]]; then
        WORDS=$( <<< $HELP sed -En -e '/^'"$arg1"'/{ :X H; $bZ; n; /^-\w/{ /^'"$arg1"'/bX; bZ}; /^$/bZ; bX }; b' -e ':Z g; s/((in\|out)?[[:alnum:]_.-]+=)|./\1\n/g; p; Q' )
        WORDS=${WORDS//default=/}

    elif [[ -n $arg1 && $arg2 == "@" ]]; then
        WORDS=$( <<< $HELP sed -En -e '/^'"$arg1"'/{ :X s/^[^ ]+ ([[:alnum:]-]+)\[?[, ].*/\1/p; tR; :R s/^[^ ]+ \[?([[:alnum:]-]+(\|[[:alnum:]-]+)+)]?.*/\1/; tY; bZ; :Y s/\|/\n/gp; :Z $Q; n; /^-\w/{ /^'"$arg1"'/!Q; bX }}' )

    elif [[ -n $arg1 && -n $arg2 ]]; then
        help=$( <<< $HELP sed -En -e '/^'"$arg1"'/{ :X H; $bZ; n; /^-\w/{ /^'"$arg1"'/bX; bZ}; /^$/bZ; bX }; b' -e ':Z g; p; Q' )
        [[ $help =~ $arg2=\[?(<?[[:alnum:]_.-]+>?(\|<?[[:alnum:]_.-]+>?)+)]? ]]
        WORDS=${BASH_REMATCH[1]//|/$'\n'}
    fi
}

_qemu_global()
{
    [[ $COMP_WORDBREAKS != *"."* ]] && COMP_WORDBREAKS+="."
    local driver property
    if [[ $PREV_O == -global || $PREV == driver ]]; then
        WORDS=$( $CMD -device help | sed -En 's/^name "([^"]+)".*/\1/p' )
        [[ $PREV != driver ]] && WORDS+=$'\ndriver=\nproperty=\nvalue='
        return
    fi
    [[ $COMP_LINE2 =~ .*" "-global" "+(driver=)?([[:alnum:]_.-]+)([.,]) ]]
    driver=${BASH_REMATCH[2]}
    if [[ ${BASH_REMATCH[3]} == "." ]]; then
        if [[ "." == @($CUR_O|$PREV_O) ]]; then
            WORDS=$( $CMD -device "$driver",help | sed -En 's/^\s*([[:alnum:]_.-]+=).*/\1/p' )
        elif [[ "=" == @($CUR_O|$PREV_O) ]]; then
            WORDS=$( $CMD -device "$driver",help | sed -En '/^\s*'"$PREV"'=/{s#.* ([[:alnum:]_.-]+(/[[:alnum:]_.-]+)+).*#\1#; tX; b; :X s#/#\n#g; p }' )
        fi
    else
        [[ $COMP_WORDBREAKS == *"."* ]] && COMP_WORDBREAKS=${COMP_WORDBREAKS//./}
        if [[ "," == @($CUR_O|$PREV_O) ]]; then 
            WORDS=$'\ndriver=\nproperty=\nvalue='
            return
        fi
        if [[ $PREV == property ]]; then
            WORDS=$( $CMD -device "$driver",help | sed -En 's/^\s*([[:alnum:]_.-]+=).*/\1/p' )
            WORDS=${WORDS//=/}
        elif [[ $PREV == value ]]; then
            [[ $CUR_O == "=" ]] && property=${COMP_WORDS[COMP_CWORD-3]} || property=${COMP_WORDS[COMP_CWORD-4]}
            WORDS=$( $CMD -device "$driver",help | sed -En '/^\s*'"$property"'=/{s#.* ([[:alnum:]_.-]+(/[[:alnum:]_.-]+)+).*#\1#; tX; b; :X s#/#\n#g; p }' )
        fi
    fi
}

_qemu_system() 
{
    # It is recommended that every completion function starts with _init_comp_wordbreaks,
    # whether or not they change the COMP_WORDBREAKS variable afterward.
    _init_comp_wordbreaks
    [[ $COMP_WORDBREAKS != *","* ]] && COMP_WORDBREAKS+=","
    local IFS=$' \t\n' CUR CUR_O PREV PREV_O PREO CMD=$1 CMD2 WORDS COMP_LINE2
    _qemu_header
    local HELP=$( $CMD --help )
    if [[ $CUR == -* ]]; then
        WORDS=$( <<< $HELP sed -En 's/^(-[^ ]+).*/\1/; tX; b; :X s/\//\n/; p' )
        WORDS+=$'\n-help'
    else
    case $PREO in
        -machine)
            local machine_h=$( $CMD -machine help | sed -En '1d; s/^([^ ]+).*/\1/; p' )
            if [[ $PREV_O == -machine ]]; then
                WORDS=$'type=\n'$machine_h
            elif [[ "," == @($CUR_O|$PREV_O) ]]; then
                _qemu_set_optv "-machine"
            elif [[ -n $CUR_O ]]; then
                if [[ $PREV == type ]]; then
                    WORDS=$machine_h
                elif [[ $PREV == accel || ":" == @($CUR_O|$PREV_O) ]]; then
                    WORDS=$'kvm\nxen\nhax\nhvf\nnvmm\nwhpx\ntcg'
                else
                    _qemu_set_optv "-machine" "$PREV"
                fi
            fi ;;

        -cpu) [[ $PREV_O == -cpu ]] && _qemu_set_words "-cpu" ;;

        -accel)
            local accel_h=$( $CMD -accel help | sed -En '1d; s/^([^ ]+).*/\1/; p' )
            if [[ $PREV_O == -accel ]]; then
                WORDS=$'accel=\n'$accel_h
            elif [[ "," == @($CUR_O|$PREV_O) ]]; then
                _qemu_set_optv "-accel"
            elif [[ -n $CUR_O ]]; then
                case $PREV in
                    accel) WORDS=$accel_h ;;
                    igd-passthru|split-wx) WORDS=$'on\noff' ;;
                    kernel-irqchip) WORDS=$'on\noff\nsplit' ;;
                    thread) WORDS=$'single\nmulti' ;;
                esac
            fi ;;

        -numa|-chardev|-tpmdev)
            if [[ $PREV_O == $PREO ]]; then
                case $PREO in
                    -numa|-tpmdev)
                        _qemu_set_optv "$PREO" "@" ;;
                    -chardev)
                        WORDS=$( $CMD -chardev help | tail -n +2 ) ;;
                esac
            elif [[ -n $CUR_O ]]; then
                if [[ $COMP_LINE2 =~ .*" "$PREO" "+([[:alnum:]_.-]+)"," ]]; then
                    local opt=${BASH_REMATCH[1]}
                    if [[ "=" == @($CUR_O|$PREV_O) ]]; then
                        _qemu_set_optv "$PREO $opt" "$PREV"
                    else
                        _qemu_set_optv "$PREO $opt"
                    fi
                fi
            fi ;;

        -netdev|-net|-nic)
            if [[ $PREV_O == $PREO ]]; then
                _qemu_set_optv -netdev "@"
                WORDS+=$'\nvde'
                [[ $PREO == -nic ]] && WORDS+=$'\nnetmap\nnone'
                [[ $PREO == -net ]] && WORDS+=$'\nnic'
            elif [[ -n $CUR_O ]]; then
                if [[ $COMP_LINE2 =~ .*" "$PREO" "+([[:alnum:]_.-]+)"," ]]; then
                    local opt=${BASH_REMATCH[1]}
                    if [[ "=" == @($CUR_O|$PREV_O) ]]; then
                        if [[ $PREV == model ]]; then
                            WORDS=$( $CMD -net nic,model=help | tail -n +2 )
                        else
                            _qemu_set_optv "-netdev $opt" "$PREV"
                        fi
                    else
                        if [[ $opt == vde ]]; then
                            WORDS=$'id=\nsock=\nport=\ngroup=\nmode='
                        elif [[ $PREO == -net && $opt == nic ]]; then
                            WORDS=$'netdev=\nmacaddr=\nmodel=\nname=\naddr=\nvectors='
                        else
                            _qemu_set_optv "-netdev $opt"
                            [[ $PREO == -nic ]] && WORDS+=$'\nmodel=\nmac='
                        fi
                    fi
                fi
            fi ;;

        -set) ;;

        -global) _qemu_global ;;

        -boot) 
            if [[ $PREV_O == -boot || "," == @($CUR_O|$PREV_O) ]]; then
                _qemu_set_optv "-boot"
            elif [[ -n $CUR_O || ($PREV_O == $PREO && -z $CUR_O) ]]; then
                if [[ $PREV == order ]]; then
                    WORDS=$'a\nc\nd\nn'
                else
                    _qemu_set_optv "-boot" "$PREV"
                fi
            fi ;;

        -!(-*)m|-smp|-add-fd|-acpitable) 
            if [[ "=" != @($CUR_O|$PREV_O) ]]; then
                if [[ $PREV_O == $PREO || ( -n $CUR_O && $CUR_O != ":" ) ]]; then
                    _qemu_set_optv "$PREO"
                    [[ $PREO == -acpitable ]] && WORDS+=$'\ndata=\nfile='
                fi
            fi ;;

        -!(-*)[kL]|-usbdevice|-vga|-watchdog-action)
            if [[ $PREV_O == -k ]]; then
                WORDS=$'ar\nde-ch\nes\nfo\nfr-ca\nhu\nja\nmk\nno\npt-br\nsv\nda
                en-gb\net\nfr\nfr-ch\nis\nlt\nnl\npl\nru\nth\nde\nen-us\nfi\nfr-be
                hr\nit\nlv\nnl-be\npt\nsl\ntr'
            elif [[ $PREV_O == -L ]]; then
                WORDS=$( $CMD -L help )
            elif [[ $PREV_O == -usbdevice ]]; then
                WORDS=$'braille\nkeyboard\nmouse\ntablet\nwacom-tablet\ndisk:\nhost:\nserial:\nnet'
            elif [[ $PREV_O == @(-vga|-watchdog-action) ]]; then
                _qemu_set_optv "-vga" "@"
            fi ;;

        -audiodev)
            if [[ $PREV_O == -audiodev ]]; then
                _qemu_set_optv "-audiodev" "@"
            elif [[ -n $CUR_O ]]; then
                [[ $COMP_WORDBREAKS == *"."* ]] && COMP_WORDBREAKS=${COMP_WORDBREAKS//./}
                local c_opts=$'id=\ntimer-period=\nin|out.mixing-engine=
                in|out.fixed-settings=\nin|out.frequency=\nin|out.channels=
                in|out.format=\nin|out.voices=\nin|out.buffer-length='
                if [[ $COMP_LINE2 =~ .*" "-audiodev" "+([[:alnum:]_.-]+)"," ]]; then
                    local driver=${BASH_REMATCH[1]}
                    if [[ "=" == @($CUR_O|$PREV_O) ]]; then
                        _qemu_set_optv "-audiodev $driver" "$PREV"
                    else
                        _qemu_set_optv "-audiodev $driver"
                        WORDS=$( <<< $WORDS$'\n'$c_opts sed -E 's/([^ ]+)\|([^ ]+)\.([^ ]+)/\1.\3\n\2.\3/' )
                    fi
                fi
            fi ;;

        -soundhw|-watchdog|-plugin)
            if [[ $PREV_O == -soundhw ]]; then
                WORDS=$( $CMD $PREO help | sed -En '1d; /^$/Q; s/^([^ ]+).*/\1/; p' ) 
                WORDS+=$'\nall'
            elif [[ $PREV_O == -watchdog ]]; then
                WORDS=$( $CMD -device help | sed -En '/^Watchdog devices:/,/^$/{ //d; s/[^"]*"([^"]+)".*/\1/; p}' )
            elif [[ $PREV_O == -plugin ]]; then
                WORDS=$'file=\nargname='
            fi ;;

        -device)
            local driver property
            if [[ $PREV_O == -device ]]; then
                WORDS=$( $CMD -device help | sed -En 's/^name "([^"]+)".*/\1/p' )
            else
                [[ $COMP_LINE2 =~ .*" "-device" "+([[:alnum:]_.-]+)"," ]]
                driver=${BASH_REMATCH[1]}
                if [[ "," == @($CUR_O|$PREV_O) ]]; then
                    WORDS=$( $CMD -device "$driver",help | sed -En 's/^\s*([[:alnum:]_.-]+=).*/\1/p' )
                elif [[ "=" = @($CUR_O|$PREV_O) ]]; then
                    WORDS=$( $CMD -device "$driver",help | sed -En '/^\s*'"$PREV"'=/{s#.* ([[:alnum:]_.-]+(/[[:alnum:]_.-]+)+).*#\1#; tX; b; :X s#/#\n#g; p }' )
                fi
            fi ;;

        -blockdev)
            [[ $COMP_WORDBREAKS == *"."* ]] && COMP_WORDBREAKS=${COMP_WORDBREAKS//./}
            if [[ $PREV_O == -blockdev ]]; then
                WORDS=$'file\nraw\nqcow2\ndriver='
            elif [[ "," == @($CUR_O|$PREV_O) ]]; then
                [[ $COMP_LINE2 =~ .*" "-blockdev" "+(driver=)?([[:alnum:]_.-]+)"," ]]
                local driver=${BASH_REMATCH[2]}
                _qemu_set_optv "-blockdev"
                case $driver in
                    file) 
                        WORDS+=$'\nfilename=\naio=\nlocking=' ;;
                    raw) 
                        WORDS+=$'\nfile=' ;;
                    qcow2) 
                        WORDS+=$'\nfile=\nbacking=\nlazy-refcounts=
                        cache-size=\nl2-cache-size=\nrefcount-cache-size=
                        cache-clean-interval=\npass-discard-request=
                        pass-discard-snapshot=\npass-discard-other=\noverlap-check=' ;;
                esac
            elif [[ -n $CUR_O ]]; then
                case "$PREV" in
                    driver)
                        WORDS=$'file\nraw\nqcow2' ;;
                    discard) 
                        WORDS=$'ignore\nunmap' ;;
                    detect-zeroes) 
                        WORDS=$'on\noff\nunmap' ;;
                    cache.direct|cache.no-flush|read-only|auto-read-only|\
                    force-share|pass-discard-request|pass-discard-snapshot|\
                    pass-discard-other)
                        WORDS=$'on\noff' ;;
                    aio)
                        WORDS=$'threads\nnative\nio_uring' ;;
                    locking)
                        WORDS=$'auto\non\noff' ;;
                    overlap-check)
                        WORDS=$'none\nconstant\ncached\nall' ;;
                esac
            fi ;;

        -fsdev|-virtfs|-display)
            [[ $COMP_WORDBREAKS == *"."* ]] && COMP_WORDBREAKS=${COMP_WORDBREAKS//./}
            if [[ $PREV_O == $PREO ]]; then
                if [[ $PREO == -display ]]; then
                    WORDS=$( $CMD -display help 2> /dev/null | sed -En '1d; s/^([^ ]+).*/\1/p' )
                else
                    _qemu_set_optv "$PREO" "@"
                fi
            elif [[ -n $CUR_O ]]; then
                if [[ $COMP_LINE2 =~ .*" "$PREO" "+([[:alnum:]_.-]+)"," ]]; then
                    local opt=${BASH_REMATCH[1]}
                    if [[ "=" == @($CUR_O|$PREV_O) ]]; then
                        _qemu_set_optv "$PREO $opt" "$PREV"
                    else
                        _qemu_set_optv "$PREO $opt"
                    fi
                fi
            fi ;;

        -vnc)
            if [[ $PREV_O == -vnc ]]; then
                WORDS=$'to=L\nhost:d\nunix:path\nnone'
            elif [[ -n $CUR_O ]]; then
                if [[ "=" == @($CUR_O|$PREV_O) ]]; then
                    case $PREV in
                        share) 
                            WORDS=$'allow-exclusive\nforce-shared\nignore' ;;
                        power-control|non-adaptive|lossy|acl|sasl|password|\
                        websocket|reverse)
                            WORDS=$'on\noff'
                    esac
                else
                    WORDS=$'reverse=\nwebsocket=\npassword=\npassword-secret=
                    tls-creds=\ntls-authz=\nsasl=\nsasl-authz=\nacl=\nlossy=
                    non-adaptive=\nshare=\nkey-delay-ms=\naudiodev=\npower-control='
                fi
            fi ;;

        -smbios)
            if [[ $PREV_O == -smbios ]]; then
                WORDS=$'file=\ntype=0\ntype=1\ntype=2\ntype=3\ntype=4\ntype=11
                type=17\ntype=41'
            elif [[ -n $CUR_O ]]; then
                if [[ $COMP_LINE2 =~ .*" "-smbios" "+(type=[0-9]+)"," ]]; then
                    local opt=${BASH_REMATCH[1]}
                    if [[ "=" == @($CUR_O|$PREV_O) ]]; then
                        _qemu_set_optv "-smbios $opt" "$PREV"
                    else
                        _qemu_set_optv "-smbios $opt"
                    fi
                fi
            fi ;;

        -name|-iscsi|-drive|-spice|-compat|-fw_cfg|-mon|-overcommit|-action|-rtc|\
        -icount|-incoming|-msg|-trace|-semihosting-config)
            if [[ "=" == @($CUR_O|$PREV_O) ]]; then
                if [[ $PREO == -mon && $PREV == chardev ]]; then
                    _qemu_set_words chardev
                elif [[ $PREO == -trace && $PREV == enable ]]; then
                    WORDS=$( $CMD -trace help )
                else
                    _qemu_set_optv "$PREO" "$PREV"
                    [[ $PREO == -mon && $PREV == pretty ]] && WORDS=$'on\noff'
                    [[ $PREO == -msg && $PREV == timestamp ]] && WORDS=$'on\noff'
                fi
            elif [[ $PREV_O == $PREO || -n $CUR_O ]]; then
                _qemu_set_optv "$PREO"
                case $PREO in
                    -drive) 
                        WORDS+=$'\ncyls=\nserial=\naddr=' ;;
                    -incoming) 
                        WORDS+=$'\ntcp:[host]:port\nrdma:host:port\nunix:socketpath
                        fd:fd\nexec:cmdline\ndefer' ;;
                    -mon)
                        WORDS+=$'\npretty=' ;;
                    -msg)
                        WORDS+=$'\ntimestamp=' ;;
                esac
            fi ;;

        -serial|-monitor|-parallel|-qmp|-qmp-pretty|-debugcon)
            if [[ $PREV_O == $PREO ]]; then
                _qemu_set_words chardev
                [[ $PREO == -parallel ]] && WORDS=$'/dev/parportN\nnone'
            elif [[ -n $CUR_O ]]; then
                if [[ $COMP_LINE2 =~ .*" "$PREO" "+([[:alnum:]_.-]+:) ]]; then
                    local opt=${BASH_REMATCH[1]}
                    if [[ "=" == @($CUR_O|$PREV_O) ]]; then
                        [[ $PREV == @(server|wait|nodelay) ]] && WORDS=$'on\noff'
                    else
                        case $opt in
                            tcp:) WORDS=$'server=\nwait=\nnodelay=\nreconnect=' ;;
                            telnet: | websocket:) WORDS=$'server=\nwait=\nnodelay=' ;;
                            unix:) WORDS=$'server=\nwait=\nreconnect=' ;;
                        esac
                    fi
                fi
            fi ;;

        -sandbox)
            if [[ $PREV_O == -sandbox ]]; then
                WORDS=$'on\noff'
            elif [[ "," == @($CUR_O|$PREV_O) ]]; then
                _qemu_set_optv "-sandbox"
            elif [[ -n $CUR_O ]]; then
                _qemu_set_optv "$PREO" "$PREV"
            fi ;;

        -object)
            _qemu_set_words "-object"
            if [[ $PREV_O == -object ]]; then
                _qemu_set_optv "-object" "@"
            elif [[ -n $CUR_O ]]; then
                [[ $COMP_LINE2 =~ .*" "-object" "+([[:alnum:]_.-]+)"," ]]
                local typename=${BASH_REMATCH[1]}
                if [[ "=" == @($CUR_O|$PREV_O) ]]; then
                    _qemu_set_optv "-object $typename" "$PREV"
                else
                    _qemu_set_optv "-object $typename"
                fi
            fi ;;
            
    esac
    fi
    _qemu_footer
}

_qemu_user()
{
    _init_comp_wordbreaks
    [[ $COMP_WORDBREAKS != *","* ]] && COMP_WORDBREAKS+=","
    local IFS=$' \t\n' CUR CUR_O PREV PREV_O PREO CMD=$1 CMD2 WORDS HELP COMP_LINE2
    _qemu_header

    if [[ $CUR == -* ]]; then
        WORDS=$( $CMD --help | sed -En 's/^(-[^ ]+).*/\1/p' )

    elif [[ $PREV == -cpu ]]; then
        _qemu_set_words "-cpu"

    elif [[ $PREO == -trace ]]; then
        if [[ $PREV == enable ]]; then
            WORDS=$( $CMD -trace help )
        elif [[ $PREV_O == $PREO || "," == @($CUR_O|$PREV_O) ]]; then
            WORDS=$'enable=\nevents=\nfile='
        fi 

    elif [[ $PREO == -!(-*)d ]]; then
        if [[ trace == @($PREV_O|${COMP_WORDS[COMP_CWORD-2]}) ]]; then
            WORDS=$( $CMD -d trace:help )
        else
            WORDS=$( $CMD -d help | sed -En 's/^([^ ]+)  .*/\1/p' )
        fi
    fi
    _qemu_footer
}

_qemu_io()
{
    _init_comp_wordbreaks
    local IFS=$' \t\n' CUR CUR_O PREV PREV_O PREO CMD=$1 CMD2 WORDS COMP_LINE2
    _qemu_header

    if [[ $CUR == -* ]]; then
        WORDS=$( $CMD --help | sed -En 's/^\s{,10}(-[[:alpha:]], -[^ =]+|-[^ =]+)(.).*/\1\2/; tX; b; :X s/,/\n/; p' )

    elif [[ $PREV == @(-!(-*)c|--cmd) ]]; then
        ### WORDS=$( qemu-io -c help | sed -En '/^$/Q; s/^([[:alnum:]_-]+).*/\1/p' )
        WORDS=$'abort\naio_flush\naio_read\naio_write\nalloc\nbreak\nclose\ndiscard
        flush\nhelp\ninfo\nlength\nmap\nopen\nquit\nread\nreadv\nremove_break\nreopen
        resume\nsigraise\nsleep\ntruncate\nwait_break\nwrite\nwritev'

    elif [[ $PREV == @(-!(-*)f|--format) ]]; then
        WORDS=$'file\nraw\nqcow2'

    elif [[ $PREV == @(-!(-*)i|--aio) ]]; then
        WORDS=$'threads\nnative\nio_uring'

    elif [[ $PREV == @(-!(-*)t|--cache) ]]; then
        WORDS=$'none\nwriteback\nunsafe\ndirectsync\nwritethrough'

    elif [[ $PREV == @(-!(-*)d|--discard) ]]; then
        WORDS=$'ignore\noff\nunmap\non'

    elif [[ $PREO == @(-!(-*)T|--trace) ]]; then
        if [[ $PREV == enable ]]; then
            WORDS=$( qemu-img --trace help )
        elif [[ $PREV_O == $PREO || "," == @($CUR_O|$PREV_O) ]]; then
            WORDS=$'enable=\nevents=\nfile='
        fi 
    fi
    _qemu_footer
}

_qemu_nbd()
{
    _init_comp_wordbreaks
    [[ $COMP_WORDBREAKS != *","* ]] && COMP_WORDBREAKS+=","
    local IFS=$' \t\n' CUR CUR_O PREV PREV_O PREO CMD=$1 CMD2 WORDS HELP COMP_LINE2
    _qemu_header

    if [[ $CUR == -* ]]; then
        WORDS=$( $CMD --help | sed -En 's/^\s{,10}(-[[:alpha:]], -[^ =]+|-[^ =]+)(.).*/\1\2/; tX; b; :X s/,/\n/; p' )

    elif [[ $PREV == @(-!(-*)f|--format) ]]; then
        WORDS=$'file\nraw\nqcow2'

    elif [[ $PREV == --aio ]]; then
        WORDS=$'threads\nnative\nio_uring'

    elif [[ $PREV == --cache ]]; then
        WORDS=$'none\nwriteback\nunsafe\ndirectsync\nwritethrough'

    elif [[ $PREV == --discard ]]; then
        WORDS=$'ignore\noff\nunmap\non'

    elif [[ $PREO == @(-!(-*)T|--trace) ]]; then
        if [[ $PREV == enable ]]; then
            WORDS=$( qemu-img --trace help )
        elif [[ $PREV_O == $PREO || "," == @($CUR_O|$PREV_O) ]]; then
            WORDS=$'enable=\nevents=\nfile='
        fi 
    fi
    _qemu_footer
}

_qemu_img()
{
    _init_comp_wordbreaks
    local IFS=$' \t\n' CUR CUR_O PREV PREV_O PREO CMD=$1 CMD2 WORDS HELP COMP_LINE2
    _qemu_header
    [[ $COMP_WORDBREAKS != *","* ]] && COMP_WORDBREAKS+=","
    eval local ARR=( $COMP_LINE2 )
    case ${COMP_WORDS[1]} in
        -T|--trace) 
            [[ ${#ARR[@]} -gt 3 && $CUR != ${ARR[3]} ]] && CMD2=${ARR[3]} ;;
        *) 
            (( COMP_CWORD > 1 )) && CMD2=${COMP_WORDS[1]} ;;
    esac
    if [[ -n $CMD2 ]]; then
        HELP=$( $CMD --help | sed -En '/^Command syntax:/,/^$/{ //d; /^\s*'"$CMD2"' /p }' )
    fi

    if [[ $CUR == -* ]]; then
        if (( COMP_CWORD == 1 )); then
            WORDS=$'-h\n--help\n-V\n--version\n-T\n--trace'
        elif [[ -n $HELP ]]; then
            WORDS=$( <<< $HELP sed -En 's/[][()|]/\n/g; s/^\s*(-[^ =]+)(.).*$/\1\2/Mg; s/^\s*[^-].*$//Mg; p' )
        fi

    elif [[ $PREV_O == -!(-*)[fF] ]]; then
        WORDS=$'file\nraw\nqcow2'

    elif [[ $PREO == @(-!(-*)T|--trace) && 
        ( $PREO == $PREV_O || ( ${#ARR[@]} == 3 && -n $CUR_O )) ]]; then
        if [[ $PREV == enable ]]; then
            WORDS=$( qemu-img --trace help )
        elif [[ $PREV_O == @(-!(-*)T|--trace) || "," == @($CUR_O|$PREV_O) ]]; then
            WORDS=$'enable=\nevents=\nfile='
        fi 

    elif [[ -z $CMD2 && $CUR_O != [,=] && $PREV_O != [,=] ]]; then
        WORDS=$( $CMD --help | sed -En '/^Command syntax:/,/^$/{ //d; s/^\s*([^ ]+).*/\1/; p }' )

    elif [[ $CMD2 == "dd" && $CUR_O != [,=] && $PREV_O != [,=] ]]; then
        WORDS=$'bs=\ncount=\nif=\nof=\nskip=' 
    fi
    _qemu_footer
}

extglob_reset=$(shopt -p extglob)
shopt -s extglob
if path=$( type -P qemu-x86_64 ); then 
    WORDS=$( cd ${path%/*} && echo qemu-!(system-*) )
    complete -o default -o bashdefault -F _qemu_user $WORDS
fi
if path=$( type -P qemu-system-x86_64 ); then 
    WORDS=$( cd ${path%/*} && echo qemu-system-* )
    complete -o default -o bashdefault -F _qemu_system $WORDS
fi
if path=$( type -P qemu-img ); then 
    complete -o default -o bashdefault -F _qemu_img qemu-img
    complete -o default -o bashdefault -F _qemu_io qemu-io
    complete -o default -o bashdefault -F _qemu_nbd qemu-nbd
fi
$extglob_reset
unset -v extglob_reset WORDS path

