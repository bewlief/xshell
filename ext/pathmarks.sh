#!/usr/bin/env bash

# ------------------------------------------
# Filename: pathmarks.sh
# Version:   0.1
# Date: 2022/03/09
# 命令行下的目录快捷方式管理
#    l, g, s, d
# ------------------------------------------


# 避免重复导入
[[ -n $__XLIB_IMPORTED__PATHMARKS ]] && return 0
__XLIB_IMPORTED__PATHMARKS=1

function __pathmarks_init__() {
    # 引入core.sh
    # todo 可去掉core.sh的引入，作用不大！
    [[ -s $XLIB_CORE ]] && source "$XLIB_CORE" || {
        local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
        local parent=${script_dir%/*}
        source "$parent/lib/core.sh"
    }

    # setup file to store pathmarks
    SDIRS=~/.sdirs
    touch $SDIRS

    import string

    # 使用alias，而不是命名函数
    alias s='pathmark::save'
    alias g='pathmark::goto'
    alias p='pathmark::print'
    alias d='pathmark::delete'
    alias ph='pathmark::help'
    alias l='pathmark::list'
}

# USAGE:
# s bookmarkname - saves the curr dir as bookmarkname
# g bookmarkname - jumps to the that bookmark
# p bookmarkname - prints the bookmark
# d bookmarkname - deletes the bookmark
# l - list all pathmarks

# save current directory to pathmarks
# or reg quick command using alias
function pathmark::save {
    local key="$1"
    pathmark::help $key
    shift
    local cmd="$@"

    # 注册快速命令
    if [[ -n $cmd ]]; then
        echo "cmd reg: $key -> $cmd"
        local s="alias $key=\"$cmd\""

        _purge_line "$SDIRS" "$s"

        eval "$s"
    # 注册目录
    else
        # 无需检查名称是否合适
        #    _bookmark_name_valid "$@"

        local qpath="export DIR_$key="
        _purge_line "$SDIRS" "$qpath"
        CURDIR=$(echo $PWD | sed "s#^$HOME#\$HOME#g")

        # 保存后即可刷新DIR_$1的值
        local s="$qpath\"$CURDIR\""
        echo "$s" >>$SDIRS

        eval "$s"
    fi

}

# jump to bookmark
function pathmark::goto {
    pathmark::help $1

    # 首先直接获取变量值，为空，则重新读取下 $SDIRS
    target="$(eval echo \$DIR_$1)"
    if [[ -z "$target" ]]; then
        source "$SDIRS"

        target="$(eval echo \$DIR_$1)"
    fi

    if [[ -d "$target" ]]; then
        # todo 是否改成 cdl，从而自动更新PATH？
        cd "$target" || error "$target not accessible now"
        \ls -lah --color=auto
    elif [[ -z "$target" ]]; then
        error "'${1}' bashmark does not exist"
    else
        error "'${target}' does not exist"
    fi
}

# print bookmark
function pathmark::print {
    pathmark::help $1
    #    source $SDIRS
    echo "$(eval echo \$DIR_$1)"
}

# delete bookmark
function pathmark::delete {
    pathmark::help $1
    #    _bookmark_name_valid "$@"
    #    if [ -z "$exit_message" ]; then
    _purge_line "$SDIRS" "export DIR_$1="
    _purge_line "$SDIRS" "alias $1="
    unset "DIR_$1"
    #    fi
}

# print out help for the forgetful
function pathmark::help {
    if [ "$1" = "-h" ] || [ "$1" = "-help" ] || [ "$1" = "--help" ]; then
        echo ''
        echo 's <bookmark_name> - Saves the current directory as "bookmark_name"'
        echo 'g <bookmark_name> - Goes (cd) to the directory associated with "bookmark_name"'
        echo 'p <bookmark_name> - Prints the directory associated with "bookmark_name"'
        echo 'd <bookmark_name> - Deletes the bookmark'
        echo 'l                 - Lists all available pathmarks'
        kill -SIGINT $$
    fi
}

# list pathmarks with dirnam
function pathmark::list {
    pathmark::help "$1"
    source "$SDIRS"

    # if color output is not working for you, comment out the line below '\033[1;32m' == "red"
    #    env | sort | awk '/^DIR_.+/{split(substr($0,5),parts,"="); printf("\033[0;33m%-20s\033[0m %s\n", parts[1], parts[2]);}'
    env | awk -F= '/^DIR_/ {printf("\033[0m%-20s\033[0m %s\n", substr($1, 5), $2)}' | sort

    # uncomment this line if color output is not working with the line above
    # env | grep "^DIR_" | cut -c5- | sort |grep "^.*="
}

# validate bookmark name
function _bookmark_name_valid {
    if [[ -z $1 || ! "$1" =~ ^[A-Za-z0-9_]+$ ]]; then
        echo "$1 invalid"
    fi
}

# safe delete line from sdirs
function _purge_line {
    if [[ -s "$1" ]]; then
        # safely create a temp file
        local t=$(mktemp -t bashmarks.XXXXXX) || exit 1
        trap "/bin/rm -f -- '$t'" EXIT

        # purge line
        #        sed "/$2/d" "$1" >"$t"
        #        /bin/mv "$t" "$1"
        sed -i "/$2/d" "$1"

        # cleanup temp file
        # will clean automatically when script exist(?)
        #        /bin/rm -f -- "$t"
        trap - EXIT
    fi
}

# completion command
function _comp {
    local curw
    COMPREPLY=()
    curw=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=($(compgen -W '`_l`' -- $curw))
    return 0
}
# list bookmarks without dirname
function _l {
    source "$SDIRS"
    env | \grep "^DIR_" | cut -c5- | sort | \grep "^.*=" | cut -f1 -d "="
}

shopt -s progcomp
complete -F _comp g
complete -F _comp p
complete -F _comp d

__pathmarks_init__
