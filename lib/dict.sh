#!/usr/bin/env bash

# ------------------------------------------
# Filename: dict.sh
# Version:   0.1
# Date: 2022/03/09
# 内存中的dictionary
#
# ------------------------------------------

# 避免重复导入
[[ -n $__XLIB_IMPORTED__DICT ]] && return 0
__XLIB_IMPORTED__DICT=1

function __dict_init__() {
    # 引入core.sh
    [[ -s $XLIB_CORE ]] && source "$XLIB_CORE" || {
        local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
        source "$script_dir/core.sh"
    }
}

# 列出所有的数据
function dict::all() {
    declare -p | grep "dictionary__store" | awk -F' ' '{$1=$2="";print $0;}'
#    dictionary__store_namex=([meng]="888" [zhang]="40" [xjm]="20" [li]="2873")
}

# set names xjm 20
# set names xjm 20 zhang 80 li 88
function dict::set() {
    local name="$1"
    while true; do
        local key="$2"
        local value="\"$3\""
        shift 2
        (($# % 2)) || return 1
        # shellcheck disable=SC2154
        if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
            eval "dictionary__store_${name}_${key}=""$value"
        else
            # A关联数组，g全局变量
            declare -Ag "dictionary__store_${name}"
            eval "dictionary__store_${name}[${key}]=""$value"
        fi
        (($# == 1)) && return
    done
}

# 获取某dict中的元素的值
# get names xjm
function dict::get() {
    local name="$1"
    local key="$2"
    if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
        local store="dictionary__store_${name}_${key}"
    else
        local store="dictionary__store_${name}[${key}]"
    fi
    echo "1.--- $store"
    # todo 检查store是否已有定义
    #    core_is_defined "${store}" || return 1
    local value="${!store}"
    echo "$value"
}

# 获取dict的key列表
# keys names
function dict::keys() {
    local name="$1"
    local keys key
    local store="dictionary__store_${name}"
    if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
        for key in $(declare -p | cut -d' ' -f3 |
            grep -E "^${store}" | cut -d '=' -f1); do
            echo "${key#${store}_}"
        done
    else
        # shellcheck disable=SC2016
        eval 'keys="${!'"$store"'[@]}"'
    fi
    # shellcheck disable=SC2154
    for key in ${keys:-}; do
        echo "$key"
    done
}

# 获取某dict的所有的values
function dict::values() {
    local name="$1"
    local keys key
    local store="dictionary__store_${name}"
    eval 'keys="${'"$store"'[@]}"'
    echo "$keys"
}

# 删除dict中的元素
function dict::remove() {
    local name="$1"
    local key="$2"
    if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
        unset "dictionary__store_${name}_${key}"
    else
        # NOTE 从map中删除元素
        unset "dictionary__store_${name}[${key}]"
    fi
}

# dump一个dict
function dict::dump() {
    local name="$1"
    local keys key
    local store="dictionary__store_${name}"
    if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
        for key in $(declare -p | cut -d' ' -f3 |
            grep -E "^${store}" | cut -d '=' -f1); do
            echo "${key#${store}_}"
        done
    else
        eval 'keys="${!'"$store"'[@]}"'
    fi

    echo "dictionary__store_$name :"
    for key in ${keys:-}; do
        local v="dictionary__store_${name}[${key}]"
        echo -e "\t$key = ${!v}"
    done
}

__dict_init__
