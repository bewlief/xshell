#!/usr/bin/env bash

# ------------------------------------------
# Filename: clean.sh
# Version:   0.1
# Date: 20221026
# 文件清理，默认读取 config/clean.list中预定义的文件和目录
# ------------------------------------------

SCRIPT_PATH=$(dirname $0)
source "$SCRIPT_PATH/../lib/core.sh"

import string
import file

OLD_IFS=$IFS
IFS=$(echo -en "\n\b")

showGreen "Clean tools"
showGreen "1. clean java target directories"

CONFIG_FILE="$SCRIPT_PATH/../config/clean.list"
file::read $CONFIG_FILE filesRemoved

for s in "${filesRemoved[@]}"; do
    # todo file::read中已经做了断行和换行处理，但此处仍需要再次处理，何故？？？
    k1=$(echo $s | sed 's/\\r//' | sed 's/\\n//')
    k2=$(echo "$k1" | awk '{gsub(/^ +| +$/,"")} {print $0}')
    k3=$(cygpath -u $k2)
    k3=$(string::trim "$k3")
#     ls -l
#     echo "clean $k3 -> $(cygpath -u $k3)"
     if [[ -d "$k3" ]]; then
#         echo ">>> $k3"
         rm -rf ${k3}/*
     else
         warn "$k2 not existing"
     fi

    string::formatKeyValue "$k2" "end"
done

IFS=$OLD_IFS

unset filesRemoved
