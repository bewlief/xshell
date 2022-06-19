#!/usr/bin/env bash

# ------------------------------------------
# Filename: core.sh
# core.sh是lib的核心，包含基本的几个常用函数
# 设置了 XLIB_BASE， XLIB_BASE_EXT, CORE_LIB等
# 其他lib必须首先source $CORE_LIB
#
# 输入
#
#
# 输出
#    XLIB_BASE
#    XLIB_BASE_EXT
#    XLIB_BASE_CONFIG
#    XLIB_CORE
#    XLIB_DEFAULT_NORMAL_PS1
#    DEFAULT_DATE_FORMAT
#    DEFAULT_DATE_TIME_FORMAT
#    LIB_IMPORTED_TIMESTAMP
#    XLIB_ORIGIN
# ------------------------------------------

# 避免重复导入
[[ -n $__XLIB_IMPORTED__CORE ]] && return 0
__XLIB_IMPORTED__CORE=1

function __core_init__() {
    # $COLUMNS仅在交互模式下有效
    COLUMNS="$(tput cols)"
    IFS_MINE="XxlyY"

    # 初始化3个基础路径变量
    # core.sh所在目录, /c/Users/xjming/xcodes/xops/xshell/lib
    export XLIB_BASE=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
    # parent of XLIB_BASE_PATH
    local d="${XLIB_BASE%/*}"
    export XLIB_BASE_PARENT="$d"

    # $HOME/xcodes/xops/xshell/ext
    export XLIB_BASE_EXT="${XLIB_BASE_PARENT}/ext"

    # $HOME/xcodes/xops/xshell/config
    export XLIB_BASE_CONFIG="${XLIB_BASE_PARENT}/config"

    export XLIB_BASE_BIN="${XLIB_BASE_PARENT}/bin"

    # 设置XLIB_CORE，即本文件
    export XLIB_CORE="${BASH_SOURCE[0]}"

    export XLIB_DEFAULT_NORMAL_PS1="[\[\033[1;32m\]\w\[\033[0m\]] \[\033[0m\]\[\033[1;36m\]\[\033[0;31m\]\[\033[0m\]$ "

    # 启用颜色显示
    export CLICOLOR=1

    export DEFAULT_DATE_FORMAT="%Y-%m-%d %a"
    export DEFAULT_DATE_TIME_FORMAT="%Y-%m-%d %H:%M:%S"

    export LIB_IMPORTED_TIMESTAMP="%F+%T"

    # 添加基础路径到PATH
    PATH::add $XLIB_BASE
    PATH::add $XLIB_BASE_EXT
    PATH::add $XLIB_BASE_BIN
    PATH::add "$XLIB_BASE_PARENT/tool"
    PATH::add "$XLIB_BASE_PARENT/tool"
    PATH::add "$XLIB_BASE_PARENT/test"
    PATH::add "$XLIB_BASE_PARENT/win"

    # 缩短路径时保留的层数
    PROMPT_DIRTRIM=5

    # NOTE 设置各种类型文件的颜色，共11种，2个一组，依次为：
    # 目录，链接，socket文件，管道文件，可执行文件，块设备文件
    # 设定了suid的可执行文件，设定了guid的可执行文件，有sticky位的目录，无sticky位的目录
    # 大写：粗体，小写：普通类型。x：使用系统默认颜色
    export LSCOLORS=bxfxhxhxgxhxhxgxgxbxbx
    if ls --color >/dev/null 2>&1; then # GNU `ls`
        colorflag="--color"
        export LS_COLORS='no=00:fi=00:di=01;31:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:'
    else # macOS `ls`
        colorflag="-G"
        export LSCOLORS='BxBxhxDxfxhxhxhxhxcxcx'
    fi

    # 获取最初始的$PATH
    readonly XLIB_ORIGIN_PATH=$PATH >/dev/null 2>&1

    readonly TRUE="TRUE"
    readonly FALSE="FALSE"

    readonly INFO="INFO"
    readonly ERROR="ERROR"
    readonly WARN="WARN"

    _define-error-codes
    _core-alias
}

function _core-alias() {
    # NOTE path: Echo all executable Paths
    alias path='echo -e ${PATH//:/\\n}'

    alias ..='cdl ..'
    alias ...='cdl ../../'
    alias .3='cdl ../../../'          # Go back 3 directory levels
    alias .4='cdl ../../../../'       # Go back 4 directory levels
    alias .5='cdl ../../../../../'    # Go back 5 directory levels
    alias .6='cdl ../../../../../../' # Go back 6 directory levels

    [[ -e /dev/clipboard ]] && alias clipboard="cat /dev/clipboard"

    alias source0='source $HOME/.bash_profile'

    alias ll="ls -lah --color=auto"
    # List all files colorized in long format, excluding . and ..
    alias la="ls -lAF ${colorflag}"

    # List only directories
    alias lsd="ls -lF ${colorflag} | grep --color=never '^d'"
    # Always use color output for `ls`
    alias ls="command ls ${colorflag}"

    # Preferred 'mkdir' implementation
    alias mkdir='mkdir -pv'

    #   lrd: list only dir recursive
    alias lrd='find . -type d| sort | sed -e "s/[^--][^\/]*\//  |/g" -e "s/|\([^ ]\)/|--\1/" '
}
# 定义常用错误代码 0~255
function _define-error-codes() {
    # 0/1
    # i:数字,r:readonly
    declare -ir GENERIC_NORMAL=0
    declare -ir GENERIC_ERROR=1

    # function调用
    declare -ir INVALID_ARGUMENTS=130
    declare -ir INVALID_BASH_VERSION=132

    declare -ir IMPORT_LIB_FAILURE=131

    declare -ir STRING_REGX_NOT_MATCH=150
    declare -ir STRING_NOT_EQUAL=151
}

# 下面的color等变量和函数用于显示加粗的INFO WARN ERROR等
_color() {
    # \e[1;... :加粗设置
    local RED_COLOR='\E[1;31m'
    local YELLOW_COLOR='\E[1;33m'
    local GREEN_COLOR='\E[1;32m'
    local BLUE_COLOR='\E[1;34m'
    local PINK_COLOR='\E[1;35m'
    local CYAN_COLOR='\E[1;36m'
    local WHITE_COLOR='\E[1;37m'

    local RES='\E[0m'

    #这里判断传入的参数是否不等于2个，如果不等于2个就提示并退出
    if [ $# -ne 2 ]; then
        echo "Usage $0 content {red|yellow|blue|green|pink}"
        return $INVALID_ARGUMENTS
    fi
    case "${2^^}" in
    RED)
        echo -e "${RED_COLOR}$1${RES}"
        ;;
    YELLOW)
        echo -e "${YELLOW_COLOR}$1${RES}"
        ;;
    GREEN)
        echo -e "${GREEN_COLOR}$1${RES}"
        ;;
    BLUE)
        echo -e "${BLUE_COLOR}$1${RES}"
        ;;
    PINK)
        echo -e "${PINK_COLOR}$1${RES}"
        ;;
    WHITE)
        echo -e "${WHITE_COLOR}$1${RES}"
        ;;
    CYAN)
        echo -e "${CYAN_COLOR}$1${RES}"
        ;;
    *)
        echo -e "请输入指定的颜色代码：{red|yellow|green}"
        ;;
    esac
}

#显示绿色
#showGreen CONTENT
showGreen() {
    _color "$1" green
}
showRed() {
    _color "$1" red
}
showYellow() {
    _color "$1" yellow
}
showBlue() {
    _color "$1" blue
}
showCyan() {
    _color "$1" cyan
}

# Pring prompt message to screen
# msg "INFO" "Hello World"
function _msg() {
    [ $# -ne 2 ] && showRed "Usage: msg message_level message_info"

    local msg_level=$1
    local msg_info=$2

    [[ "${msg_level}" == "$INFO" ]] && showGreen "${msg_level}: ${msg_info}"
    [[ "${msg_level}" == "$WARN" ]] && showYellow "${msg_level}: ${msg_info}"
    [[ "${msg_level}" == "$ERROR" ]] && showRed "${msg_level}: ${msg_info}"
}

function info() {
    _msg $INFO "$*"
}
function warn() {
    _msg $WARN "$*"
}
function error() {
    _msg $ERROR "$*"
}

# Evaluate shvar-style booleans
function bool::true() {
    # NOTE case的用法
    case "$1" in
    [tT] | [yY] | [yY][eE][sS] | [oO][nN] | [tT][rR][uU][eE] | 1)
        echo TRUE
        ;;
    *)
        echo FALSE
        ;;
    esac
}
# Evaluate shvar-style booleans
function bool::false() {
    case "$1" in
    [fF] | [nN] | [nN][oO] | [oO][fF][fF] | [fF][aA][lL][sS][eE] | 0)
        echo FALSE
        ;;
    *)
        echo TRUE
        ;;
    esac
}

# die $? [message]
# 检查$?，有错则打印错误信息并exit code
function die() {
    local msg=${2}
    local code=${1-1} # default exit status 1

    [[ $code -gt 0 ]] && {
        [[ -n $msg ]] && error "$msg"
        exit $code
    }

    return $GENERIC_NORMAL
}

# load library like ./lib/xok.sh
function import() {
    local lib="$XLIB_BASE/$1.sh"

    # -e:文件存在， -s:文件存在且不为空
    if [[ -s $lib ]]; then
        source $lib
        return $GENERIC_NORMAL
    else
        error "failed to import $1: $lib"
        return $IMPORT_LIB_FAILURE
    fi

}

# reload log, will ignore the __XLIB_IMPORTED_xxx
# xxx: 文件名称，需要在该sh中设置 __LIB_IMORTED_XXX
function reload() {
    # NOTE 转为全部大写
    local var_name="__XLIB_IMPORTED__${1^^}"

    unset ${var_name}
    import "$1"
}

# 从当前shell中移除引入的函数和变量
function unload() {
    local lib=$1
    [[ -s $lib ]] && {
        warn "unload $lib"
    }
    # todo TBC
}

# load functions for one specific target
# all such scripts should be placed in ./ext/: *.sh, size>0
function loadExt() {
    local d

    # NOTE 使用globs
    # for d in */; do 仅匹配目录
    #    When looping over a set of files, it's always better to use globs when possible. Using command expansion causes word splitting and glob expansion, which will cause problems for certain filenames (typically first seen when trying to process a file with spaces in the name).
    #    for d in $(ls $ext_dir); do
    for d in $XLIB_BASE_EXT/*.sh; do
        if [[ -s $d ]]; then
            source "$d"
            string::formatKeyValue "ext $d" "LOADED"
        else
            string::formatKeyValue "ext $d" "IGNORED"
        fi
    done
}

# list all scripts in ./ext, ./lib
function libs() {
    echo "list scripts in ./ext/, ./lib/"
}

# 类似于tree：http://gnuwin32.sourceforge.net/packages/tree.htm
# 和上面的alias lr 功能类似
# 不如tree
function lra() {
    echo ". [ $PWD ]"

    # depth: 目录层次最大10层
    # offset：每一层次增加 2 个空格作为分隔
    find . | sort | awk -F'/' '{ 
        depth=10;
        offset=2;
        str="|  ";
        path="";
        if(NF >= 2 && NF < depth + offset) {
            while(offset < NF) {
                path = path "|  ";
                offset ++;
            }
            print path "|-- "$NF;
        }}'
}

#@override
# 常用的 cdl 函数=cd+ll
function cdl() {
    cd "$@" && info "cd && ll $(pwd)"
    setPS1
    ls -lah --color=auto
}

# $PATH变量的添加、删除、去重
function PATH::append() {
    PATH::remove $1
    export PATH="$PATH:$1"
}
function PATH::add() {
    PATH::remove $1
    export PATH="$1:$PATH"
}
function PATH::remove() {
    export PATH=$(echo -n $PATH | awk -v RS=: -v ORS=: '$0 != "'$1'"' | sed 's/:$//')
    PATH::dedup
}
function PATH::dedup() {
    export PATH=$(echo -n $PATH | awk -v RS=: '!($0 in a) {a[$0]; printf("%s%s", length(a) > 1 ? ":" : "", $0)}')
}

#@override :表示会被覆盖
# 设置命令行提示符PS1，检查PS1_GIT_STATUS
function setPS1() {
    export PS1="$XLIB_DEFAULT_NORMAL_PS1"
}

# 目录的快速跳转
# bd <some parent path name>
function bd() {
    local pattern="$1"
    if [[ -n $pattern ]]; then
        local oldpwd=$(pwd)
        # echo $oldpwd | sed 's|\(.*/'$pattern'[^/]*/\).*|\1|'
        local newpwd=$(echo $oldpwd | sed 's|\(.*/'$pattern'/\).*|\1|')
        echo "1.-- $oldpwd -> $newpwd"

        if [ "$newpwd" != "$oldpwd" ]; then
            echo $newpwd
            cdl "$newpwd"
        fi
        complete -F _bd bd
    fi
}

function _bd() {
    # Handle spaces in filenames by setting the delimeter to be a newline.
    local IFS=$'\n'
    # Current argument on the command line.
    local cur=${COMP_WORDS[COMP_CWORD]}
    # Available directories to autcomplete to.
    local completions=$(dirname $(pwd) | sed 's|/|\'$'\n|g')

    COMPREPLY=($(compgen -W "$completions" -- $cur))
}

__core_init__
