#!/usr/bin/env bash

# cache.sh 以文件系统为存储的简单的cache
# cache::set cache-name key-name value-of-key
# cache::get cache-name key-name

# 避免重复导入
[[ -n $__XLIB_IMPORTED__CACHE ]] && return 0
__XLIB_IMPORTED__CACHE=1

function __fscache_init__() {
    [[ -s $XLIB_CORE ]] && source "$XLIB_CORE" || {
        local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
        source "$script_dir/core.sh"
    }

    # root of cache files
    if [[ -w $TEMP ]]; then
        FS_CACHE_ROOT="$TEMP/.xfscache"
    else
        mkdir -p "$HOME/.xfscache"
        FS_CACHE_ROOT="$HOME/.xfscache"
    fi
}

# 获取cache，即一级目录
function _cache_to_path() {
    local cache="$1"
    echo "$FS_CACHE_ROOT/$$/$cache"
}

# 获取key，即二级目录
function _get_key_path() {
    local path="$1"
    local key="$2"

    echo "$path/$key"
}

# cache中的key的数量
function cache::count() {
    local cache="$1"
    local path="$(_cache_to_path "$cache")"
    local count

    [[ -d "$path" ]] || return 1

    count="$(find "$path" -type f | wc -l)" || return 1
    [[ -z $count ]] && count=0

    echo "$count"
}

#@public
function cache::create() {
    local __path="$($BASHLETS_NAMESPACE tempdir create)" || return 1
    local path="$(_cache_to_path "$__path")"

    echo "$path"
}

#
function cache::destroy() {
    local cache="$1"
    local path="$(_cache_to_path "$cache")"

    [[ -d "$path" ]] || return 1

    rm -fr "$path"
}

# 检查cache/key是否存在
function cache::exists() {
    local cache="$1"
    local key="$2"
    local path="$(_cache_to_path "$cache")"
    local key_path="$(_get_key_path "$path" "$key")"

    [[ -d "$path" ]] || return 1

    [[ -e "$key_path" ]]
}

# 列出cache中所有的key
function cache::keys() {
    local cache="$1"
    local path="$(_cache_to_path "$cache")"

    [[ -d "$path" ]] || return 1

    find "$path" -type f -printf "%f\n"
}

# 获取key，仅适用于scalar
function cache::get() {
    local cache="$1"
    local key="$2"
    local path="$(_cache_to_path "$cache")"
    local key_path="$(_get_key_path "$path" "$key")"

    [[ -d "$path" ]] || return 1
    [[ -e "$key_path" ]] || return 2

    # 数组的cache
    [[ -f "$key_path" ]] && echo "$(cat "$key_path")"
}

# 查询type
function cache::type() {
    local cache="$1"
    local key="$2"
    local path="$(_cache_to_path "$cache")"
    local key_path="$(_get_key_path "$path" "$key")"

    [[ -d "$path" ]] || return 1
    [[ -e "$key_path" ]] || return 2

    [[ -d "$key_path" ]] && echo array || echo scalar
}

# 设置缓存 set cache-name key-name value-of-key
function cache::set() {
    local cache="$1"
    local key="$2"
    shift 2
    local value="$@"
    local path="$(_cache_to_path "$cache")"
    local key_path="$(_get_key_path "$path" "$key")"

    #    [[ -d "$path" ]] || return 1
    mkdir -p "$path" || (
        echo "failed to create $path"
        return 1
    )

    echo "$value" >"$key_path"
}

# 缓存数组
# set_array cache1 aa 其中aa是一个数组
# 会创建$FS_CACHE_ROOT/cache1/aa/下的名称为index序列号的文件，数据为其对应的值
function cache::set_array() {
    # TODO: associative arrays

    local cache="$1"
    local key="$2"
    local -n arr=$3

    local path="$(_cache_to_path "$cache")"
    local key_path="$(_get_key_path "$path" "$key")"

    # 非数组则退出
    [[ $(_is_array $key) -eq 0 ]] || return 1

    # create container...
    rm -fr "$key_path" && mkdir "$key_path"

    local count=0

    #    key=$key[@]                     # no quotes here...
    #    for item in "${!key}"       # ... but here the quotes are pivotal!
    #    do
    #        echo $item > "$key_path/$count"
    #        ((count++))
    #    done
    for item in "${arr[@]}"; do
        echo "$item" >"$key_path/$count"
        ((count++))
    done

    eval unset $array_name
}

function _is_array() {
    local obj="$1"
    local s=$(declare -p "$obj" 2>/dev/null | \grep '^declare \-a' | wc -l)
    echo $s
}

# 读取数组的缓存
# get_array cache1 names a1: a1即获取到的数据
function cache::get_array() {
    local cache="$1"
    local key="$2"

    local path="$(_cache_to_path "$cache")"
    local key_path="$(_get_key_path "$path" "$key")"

    # 读取文件内容到数组中
    # todo 如何保证其顺序？和文件名称匹配？
    declare -n arr=$3
    for f in $key_path/*; do
        local s1=$(cat $f)
        arr+=("$s1")
    done
}

# 删除key
function cache::unset() {
    local cache="$1"
    local key="$2"
    local path="$(_cache_to_path "$cache")"
    local key_path="$(_get_key_path "$path" "$key")"

    [[ -d "$path" ]] || return 1
    [[ -e "$key_path" ]] || return

    rm -f "$key_path"
}

__fscache_init__
