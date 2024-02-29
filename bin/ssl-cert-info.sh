usage() {
    echo "help"
    # cat <&2
    #             echo "see --help for usage"
    #             exit 1
    #                   ;;
    #   esac
    #   shift
    # done
}

CheckLocalCert() {
    openssl x509 -in $crt -noout $opt
}

CheckRemoteCert() {
    echo |
        openssl s_client $servername -connect $host:$port 2>/dev/null |
        openssl x509 -noout $opt
}

if [ -z "$(type -t FormatOutput)" ]; then
    FormatOutput() { cat; }
fi

if [ -z "$opt" ]; then
    opt="-text -certopt no_header,no_version,no_serial,no_signame,no_pubkey,no_sigdump,no_aux"
fi

if [ -z "$source" ]; then
    echo "ERROR: missing certificate source."
    echo "Provide one via '--file' or '--host' arguments."
    echo "See '--help' for examples."
    exit 1
fi

if [ "$source" == "local" ]; then
    [ -n "$DEBUG" ] && echo "DEBUG: certificate source is local file"
    if [ -z "$crt" ]; then
        echo "ERROR: missing certificate file"
        exit 1
    fi
    [ -n "$DEBUG" ] && echo
    CheckLocalCert | FormatOutput
fi

if [ "$source" == "remote" ]; then
    [ -n "$DEBUG" ] && echo "DEBUG: certificate source is remote host"
    if [ -z "$host" ]; then
        echo "ERROR: missing remote host value."
        echo "Provide one via '--host' argument"
        exit 1
    fi
    if [ -z "$port" ]; then
        [ -n "$DEBUG" ] && echo "DEBUG: defaulting to 443 for port."
        port="443"
    fi
    [ -n "$DEBUG" ] && echo
    CheckRemoteCert | FormatOutput
fi
