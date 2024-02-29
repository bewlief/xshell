#!/usr/bin/env bash

# ------------------------------------------
# Filename: color.sh
# Version:   0.1
# Date: 2022/04/02
#   ansi的简化版，仅定义了基本的前景色、背景色
#   如需下划线等格式，应使用ansi
#   而core中仅有前景色的使用
#   功能比较： ansi >color >core
# ------------------------------------------

# 避免重复导入
[[ -n $__XLIB_IMPORTED__COLOR ]] && return 0
__XLIB_IMPORTED__COLOR=1

function __color_init__() {
    # 引入core.sh
    [[ -s $XLIB_CORE ]] && source "$XLIB_CORE" || {
        local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
        source "$script_dir/core.sh"
    }

    # 定义了常用的颜色、背景色、下划线、粗体
    # 使用时需要导入！

    # tput setaf: 设置前景色， setab：设置背景色

    # \e, \033一般情况下无区别，但有时\e可能不被支持
    DEFAULT_FG_COLOR="\033[39m"
    DEFAULT_BG_COLOR="\033[49m"
    ANSI_RESET="\e[0m"

    # Regular
    txtblk="$(tput setaf 0 2>/dev/null || echo '\e[0;30m')" # Black
    txtred="$(tput setaf 1 2>/dev/null || echo '\e[0;31m')" # Red
    txtgrn="$(tput setaf 2 2>/dev/null || echo '\e[0;32m')" # Green
    txtylw="$(tput setaf 3 2>/dev/null || echo '\e[0;33m')" # Yellow
    txtblu="$(tput setaf 4 2>/dev/null || echo '\e[0;34m')" # Blue
    txtpur="$(tput setaf 5 2>/dev/null || echo '\e[0;35m')" # Purple
    txtcyn="$(tput setaf 6 2>/dev/null || echo '\e[0;36m')" # Cyan
    txtwht="$(tput setaf 7 2>/dev/null || echo '\e[0;37m')" # White

    # Bold

    # Underline

    # Background
    bakblk="$(tput setab 0 2>/dev/null || echo '\e[40m')" # Black
    bakred="$(tput setab 1 2>/dev/null || echo '\e[41m')" # Red
    bakgrn="$(tput setab 2 2>/dev/null || echo '\e[42m')" # Green
    bakylw="$(tput setab 3 2>/dev/null || echo '\e[43m')" # Yellow
    bakblu="$(tput setab 4 2>/dev/null || echo '\e[44m')" # Blue
    bakpur="$(tput setab 5 2>/dev/null || echo '\e[45m')" # Purple
    bakcyn="$(tput setab 6 2>/dev/null || echo '\e[46m')" # Cyan
    bakwht="$(tput setab 7 2>/dev/null || echo '\e[47m')" # White

    # text Reset
    txtrst="$(tput sgr 0 2>/dev/null || echo $ANSI_RESET)"

    # 使用举例：
    # echo "${bakwht}[ notice ] : ${undgrn}underline green${undblu}hello you ${txtrst}"

    #
    alias fg="color::fg"
    alias bg="color::bg"

}
# $ hex_to_rgb "#FFFFFF"
# 255 255 255
function hex_to_rgb() {
    # Usage: hex_to_rgb "#FFFFFF"
    #        hex_to_rgb "000000"
    : "${1/\#/}"
    ((r = 16#${_:0:2}, g = 16#${_:2:2}, b = 16#${_:4:2}))

    printf '%s\n' "$r $g $b"
}

# $ rgb_to_hex "255" "255" "255"
# #FFFFFF
function rgb_to_hex() {
    # Usage: rgb_to_hex "r" "g" "b"
    printf '#%02x%02x%02x\n' "$1" "$2" "$3"
}

# Foreground (Text)
function color::fg() {
    # 默认前景色
    local __end=$DEFAULT_FG_COLOR
    local __color=$__end # end by default

    case "$1" in
    end | off | reset)
        __color=$__end
        ;;
    black)
        __color="$txtblk"
        ;;
    red)
        __color="$txtred"
        ;;
    green)
        __color="$txtgrn"
        ;;
    yellow)
        __color="$txtylw"
        ;;
    blue)
        __color="$txtblu"
        ;;
    magenta)
        __color="$txtpur"
        ;;
    cyan)
        __color="$txtcyn"
        ;;
        #    gray) __color='\033[90m' ;;
        #    darkgray) __color='\033[91m' ;;
        #    lightgreen | 00fe0) __color='\033[92m' ;;
        #    lightyellow | f8fe0) __color='\033[93m' ;;
        #    lightblue) __color='\033[94m' ;;
        #    lightmagenta) __color='\033[95m' ;;
        #    lightcyan | 00fef) __color='\033[96m' ;;
        #    white) __color='\033[97m' ;;
    esac
    if [[ -n "$2" ]]; then
        echo -en "$__color$2$__end"
    else
        echo -en "$__color"
    fi
}

# Background
function color::bg() {
    # 默认背景色
    local __end=$DEFAULT_BG_COLOR
    local __color=$__end # end by default

    case "$1" in
    end | off | reset)
        __color=$__end
        ;;
    black)
        __color="$bakblk"
        ;;
    red)
        __color="$bakred"
        ;;
    green)
        __color="$bakgrn"
        ;;
    yellow)
        __color="$bakylw"
        ;;
    blue)
        __color="$bakblu"
        ;;
    magenta)
        __color="$bakpur"
        ;;
    cyan)
        __color="$bakcyn"
        ;;
    gray)
        __color="$bakwht"
        ;;
        #    darkgray) __color='\033[100m' ;;
        #    lightred) __color='\033[101m' ;;
        #    lightgreen) __color='\033[102m' ;;
        #    lightyellow) __color='\033[103m' ;;
        #    lightblue) __color='\033[104m' ;;
        #    lightmagenta) __color='\033[105m' ;;
        #    lightcyan) __color='\033[106m' ;;
        #    white) __color='\033[107m' ;;
    esac

    if [[ -n "$2" ]]; then
        echo -en "$__color$2$__end"
    else
        echo -en "$__color"
    fi
}

__color_init__
