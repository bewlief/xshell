#!/usr/bin/env bash

SCRIPT_PATH=$(dirname $0)
source "./lib/core.sh"

import string
import file

OLD_IFS=$IFS
IFS=$(echo -en "\n\b")

showGreen "Clean tools"
showGreen "1. clean java target directories"

CONFIG_FILE="$SCRIPT_PATH/config/clean.list"
file::read $CONFIG_FILE filesRemoved

for s in "${filesRemoved[@]}"; do
    echo ">>> $s--"

    # todo file::read中已经做了断行和换行处理，但此处仍需要再次处理，何故？？？
    k1=$(echo $s | sed 's/\\r//' | sed 's/\\n//')
    k2=$(echo "$k1" | awk '{gsub(/^ +| +$/,"")} {print $0}')
    cd "$k2"
    ls -l
    # echo "clean $s -> $(cygpath -u $s)"
    # if [ -d "$s" ]; then
    #     echo ">>> $s"
    #     rm -rf ${s}/*
    # else
    #     warn "file: $s"
    #     rm -f $s
    # fi

    string::formatKeyValue "$k2" "end"
    echo ""
done

IFS=$OLD_IFS

unset filesRemoved
