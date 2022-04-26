#!/usr/bin/env bash

# ------------------------------------------
# Filename: meta.sh
# Version:   0.1
# Date: 20220325
# note:
#   functions of os:
#       xkill: kill a process
# 输入
#
#
# 输出
#    BASE_OS
# ------------------------------------------

# 避免重复导入
[[ -n $__XLIB_IMPORTED__META ]] && return 0
__XLIB_IMPORTED__META=1

function __meta_init__() {
    # 引入core.sh
    [[ -s $XLIB_CORE ]] && source "$XLIB_CORE" || {
        local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
        source "$script_dir/core.sh"
    }

    readonly MAC="MAC"
    readonly WIN="WIN"
    readonly LINUX="LINUX"

    # 设置BASE_OS变量
    meta::os

    alias xkill="meta::kill"
}

# 系统os类型：win, mac
function meta::os() {
    # OS tag
    local _mac="darwin"
    local _win="mingw"
    local _solaris="solaris"
    local _sun="sunos"
    local _linux="linux"
    local _cygwin="cygwin"

    local os=$(uname -s)
    # NOTE 转小写 ${os,}：仅小写首字符
    os=$(echo ${os,,})

    # 设置全局变量 BASE_OS
    case "$os" in
    $_mac*)
        export BASE_OS="$MAC"
        ;;
    $_win* | $_cygwin*)
        export BASE_OS="$WIN"
        ;;
    $_solaris* | $_linux*)
        export BASE_OS="$LINUX"
        ;;
    *)
        export BASE_OS="NOT_SUPPORTED_OS"
        ;;
    esac
}

# kill
function meta::kill() {
    import math

    # 判断是数字还是字符串
    local d=$(is-digit "$1")
    if [[ "$d" == "1" ]]; then
        if [[ "$BASE_OS" == "MAC" ]]; then
            # kill -9 $pid
            echo "mac, using kill"
        else
            cmd "/C taskkill /F /PID $1"
        fi
    else
        if [[ "$BASE_OS" == "MAC" ]]; then
            kill -9 $pid
        else
            cmd "/C taskkill /F /PID $1"
        fi
    fi

    # todo 传入多个进程id
}

# NOTE 查找一个function所来源于的shell
function meta::from() {
    local func_name=$1
    echo $(
        shopt -s extdebug
        declare -Ff "${func_name}"
        shopt -u extdebug
    )
}

# 列出所有变量
function meta::vars(){
    # {$1=$2="";print $0;}: 打印第3及之后的列
    declare -p |\grep -i -E "declare \-A|declare \-a|declare \-r" | \grep -v "\-\-" | awk -F' ' '{$1=$2="";print $0;}'
}

# 列出所有定义的function
function meta::funcs() {
    if [[ -f "$1" ]]; then
        meta::_funcs-file "$1"
    else
        meta::_funcs-mem
    fi
}
# functions
# 列出所有当前shell中的函数
# declarations="$(functions)"
function meta::_funcs-mem() {
    declare -F | cut --delimiter ' ' --fields 3
    $only_functions || declare -p | \grep '^declare' |
        cut --delimiter ' ' --fields 3 - | cut --delimiter '=' --fields 1 | sort --unique
}

# file-functions <script file name>
# 列出一个文件中定义的函数 TBC 尚有缺陷
function meta::_funcs-file() {
    local file=$1
    echo "$(\grep -E '^[[:space:]]*([[:alnum:]_]+[[:space:]]*\(\)|function[[:space:]]+[[:alnum:]_]+)' $file)"

    # 当前shell中定义的所有函数
    #    declare -F | awk '{print $NF}' | sort | egrep -v "^_"
}

# in git bash, change path from posix to windows
function path2win() {
    local path=$1
    echo "$path" | sed -e 's/^\///' -e 's/\//\\/g' -e 's/^./\0:/'

    # cygpath -w $1
}

# Check if any of $pid (could be plural) are running
function check-pid() {
    local i

    for i in $*; do
        [ -d "/proc/$i" ] && return 0
    done
    return 1
}

# mcd <new dir name>
# 创建并切换到新目录
function mcd() {
    [[ -n "$1" ]] && mkdir -p "$1" >/dev/null && cd "$1"
    info "$1 created"
}

# 以数字形式列出个文件的属性
function lsmod() {
    ls -l $1 | awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/) *2^(8-i));if(k)printf("%0o ",k);print}'
}

# 休眠，不使用外置命令sleep
function wait() {
    # Usage: sleep 1
    #        sleep 0.2
    read -rst "${1:-1}" -N 999
}

# 列出所有定义的alias
function meta::aliases() {
    alias | grep '^alias' | cut --delimiter ' ' --fields 2 - | cut --delimiter '=' --fields 1
}

sleep_until() {
    # <doc:sleep_until>
    #
    # Causes the running process to wait until the given date.
    # If the date is in the past, it immediately returns.
    #
    # </doc:sleep_until>

    local secs=$(($(date -d "$1" +%s) - $(date +%s)))
    ((secs > 0)) && sleep $secs
}

# DESC: Run the requested command as root (via sudo if requested)
# ARGS: $1 (optional): Set to zero to not attempt execution via sudo
#       $@ (required): Passed through for execution as root user
# OUTS: None
function run_as_root() {
    if [[ $# -eq 0 ]]; then
        script_exit 'Missing required argument to run_as_root()!' 2
    fi

    if [[ ${1-} =~ ^0$ ]]; then
        local skip_sudo=true
        shift
    fi

    if [[ $EUID -eq 0 ]]; then
        "$@"
    elif [[ -z ${skip_sudo-} ]]; then
        sudo -H -- "$@"
    else
        script_exit "Unable to run requested command as root: $*" 1
    fi
}

# Buffers all output of the passed command, and only prints on error
# Uses eval to support pipes and multiple commands, but defining a
# wrapper function is generally recommended.
# http://unix.stackexchange.com/a/41388/19157
# TODO try http://joeyh.name/code/moreutils/ on Cygwin and just wrap chronic
# if it's on the PATH.
quiet_success() {
    local output
    output=$(eval "$*" 2>&1)
    local ret=$?
    if ((ret != 0)); then
        echo "$output"
        return $ret
    fi
}

# git@github.com:qzb/is.sh.git
# 条件判断
# is <condition> [value a] [value b]
function is() {
    local condition="$1"
    local value_a="$2"
    local value_b="$3"

    if [ "$condition" == "not" ]; then
        shift 1
        ! is "${@}"
        return $?
    fi

    if [ "$condition" == "a" ] || [ "$condition" == "an" ] || [ "$condition" == "the" ]; then
        shift 1
        is "${@}"
        return $?
    fi

    case "$condition" in
    file)
        [ -f "$value_a" ]
        return $?
        ;;
    dir | directory)
        [ -d "$value_a" ]
        return $?
        ;;
    link | symlink)
        [ -L "$value_a" ]
        return $?
        ;;
    existing | exist | exists)
        [ -e "$value_a" ]
        return $?
        ;;
    readable)
        [ -r "$value_a" ]
        return $?
        ;;
    writeable)
        [ -w "$value_a" ]
        return $?
        ;;
    executable)
        [ -x "$value_a" ]
        return $?
        ;;
    available | installed)
        which "$value_a"
        return $?
        ;;
    empty)
        [ -z "$value_a" ]
        return $?
        ;;
    number)
        echo "$value_a" | grep -E '^[0-9]+(\.[0-9]+)?$'
        return $?
        ;;
    older)
        [ "$value_a" -ot "$value_b" ]
        return $?
        ;;
    newer)
        [ "$value_a" -nt "$value_b" ]
        return $?
        ;;
    gt)
        is not a number "$value_a" && return 1
        is not a number "$value_b" && return 1
        awk "BEGIN {exit $value_a > $value_b ? 0 : 1}"
        return $?
        ;;
    lt)
        is not a number "$value_a" && return 1
        is not a number "$value_b" && return 1
        awk "BEGIN {exit $value_a < $value_b ? 0 : 1}"
        return $?
        ;;
    ge)
        is not a number "$value_a" && return 1
        is not a number "$value_b" && return 1
        awk "BEGIN {exit $value_a >= $value_b ? 0 : 1}"
        return $?
        ;;
    le)
        is not a number "$value_a" && return 1
        is not a number "$value_b" && return 1
        awk "BEGIN {exit $value_a <= $value_b ? 0 : 1}"
        return $?
        ;;
    eq | equal)
        [ "$value_a" = "$value_b" ] && return 0
        is not a number "$value_a" && return 1
        is not a number "$value_b" && return 1
        awk "BEGIN {exit $value_a == $value_b ? 0 : 1}"
        return $?
        ;;
    match | matching)
        echo "$value_b" | grep -xE "$value_a"
        return $?
        ;;
    substr | substring)
        echo "$value_b" | grep -F "$value_a"
        return $?
        ;;
    true)
        [ "$value_a" == true ] || [ "$value_a" == 0 ]
        return $?
        ;;
    false)
        [ "$value_a" != true ] && [ "$value_a" != 0 ]
        return $?
        ;;
    # todo 无法处理 string::length 这样的函数！
    function)
#        meta::is-function "$value_a"
#        return $?
        [[ "$value_a" == $(meta::is-function "$value_a") ]]
        return $?
        ;;
    esac >/dev/null

    return 1
}

# 判断变量是否被定义
function core::is-defined() {
    set +o nounset
    if ((BASH_VERSINFO[0] >= 4)) && ((BASH_VERSINFO[1] >= 3)); then
        [[ -v "${1:-}" ]] || echo FALSE
    else # for bash < 4.3
        # Note: ${varname:-foo} expands to foo if varname is unset or set to the
        # empty string; ${varname-foo} only expands to foo if varname is unset.
        # shellcheck disable=SC2016
        eval '! [[ "${'"${1}"'-this_variable_is_undefined_!!!}"' \
            ' == "this_variable_is_undefined_!!!" ]]'
        #        exit $?
        echo TRUE
#        return $?
    fi
}

# 判断函数是否被定义
# is-function <function-name>
# 返回函数名表示已定义，为空则未定义
meta::is-function() {
    echo "$(declare -F "$1")"
#    declare -F "$1"
}

# 复制函数到新的函数，名称前面加上前缀
# meta::copy_function FUNCTION_NAME NEW_FUNCTION_PREFIX
#> 原函数可重新导入或直接unset -f
function meta::copy_function() {
    local FUNCTION_NAME="$1"
    local PREFIX="$2"

    eval "$PREFIX$(declare -fp $FUNCTION_NAME)"
}

# 前置、后置运行function
# meta::wrap BEFORE AFTER FUNCTION_NAME[...]
# 原有function被复制为 meta::orig_FUNCTION_NAME
# 插入前置、后置代码，生成新的FUNCTION_NAME函数，并执行
# 例子：
# function before(){...}
# function after(){...}
# meta::wrap before after target-function
function meta::wrap() {
    local BEFORE="$1"
    local AFTER="$2"
    shift 2

    local FUNCTION_NAME
    # 创建新的function：
    for FUNCTION_NAME in "$@"; do
        # Rename original function
        meta::copy_function "$FUNCTION_NAME" "meta::orig_" || return 1

        # Redefine function
        eval "
            function $FUNCTION_NAME() {
                $BEFORE

                local __meta__EXIT_CODE=0
                meta::orig_$FUNCTION_NAME \"\$@\" || __meta__EXIT_CODE=\$?

                $AFTER

                return \$__meta__EXIT_CODE
            }
        "

        declare -f "meta::orgi_$FUNCTION_NAME"

        # 执行 FUNCTION_NAME
        eval "$FUNCTION_NAME"
    done
}


# 脚本命令行参数处理
# Example usage:
# foo() {
#   local _usage=...                # optional usage string
#   eval "$(meta::getopts 'ab:f:v')"  # provide a standard getopts optstring
#   echo "f is $f"                  # opts are now local variables
#   if (( a )); then                # check boolean flags with (( ... ))
#     echo "Saw -a"
#   fi
#   echo "$@"                       # opts are removed from $@, positional args remain
# }
# foo "$@"

# a 短参数，无值
# b: 长参数，需要传值过来
function meta::getopts() {
    local i char last_char var vars=() optstring=${1:-} min_args=${2:-0} max_args=${3:-}
    optstring="${optstring#:}" # ensure string is not prefixed with :
    if ! [[ "$optstring" =~ ^[a-zA-Z0-9:]*$ ]] || [[ "$optstring" == *::* ]]; then
        error "Invalid optstring: $optstring"
        echo 'return 2' # for eval-ing
        return 2
    fi
    for ((i = ${#optstring} - 1; i >= 0; i--)); do
        char=${optstring:i:1}
        if [[ "$char" != ":" ]]; then
            var="$char"
            if [[ "$var" =~ [0-9] ]]; then
                # prefix with 'o' so numeric flags aren't confused for positional args
                var="o${var}"
            fi
            if [[ "$last_char" == ":" ]]; then
                vars+=("$var")
            else
                vars+=("${var}=0")
            fi
        fi
        last_char=$char
    done
    # Do as little work as possible here, as it will be eval-ed by the caller.
    echo "local OPTIND=1 ${vars[*]}"
    printf '_getopts_helper %q %q %q "$@" || return\n' "$optstring" "$min_args" "$max_args"
    # shellcheck disable=SC2016
    echo 'shift $((OPTIND - 1)); OPTIND=1'
}

# Actual parser implementation; assumes all variables it sets are local,
# which pg::getopts sets up. Do not call directly.
function _getopts_helper() {
    local OPTARG opt failed=0
    # $1 and $3 can be empty strings, so ? instead of :?
    local optstring=${1?optstring} min_args=${2:?min_args} max_args=${3?max_args}
    shift 3
    # ensure optstring _is_ prefixed with :
    while getopts ":${optstring#:}" opt; do
        case "${opt}" in
        [?:])
            case "${opt}" in
            :) error "Option '-${OPTARG}' requires an argument" ;;
            [?]) error "Unknown option '-${OPTARG}'" ;;
            esac
            failed=1
            break
            ;;
        *)
            if [[ "$optstring" != *"${opt}:"* ]]; then
                OPTARG=1
            fi
            if [[ "$opt" =~ [0-9] ]]; then
                opt="o${opt}"
            fi
            printf -v "$opt" '%s' "$OPTARG"
            ;;
        esac
    done
    local pos_args=$(($# - OPTIND + 1))
    if ((pos_args < min_args)); then
        error "Insufficient arguments; minimum ${min_args}"
        failed=1
    elif [[ -n "$max_args" ]] && ((pos_args > max_args)); then
        error "Too many arguments; maximum ${max_args}"
        failed=1
    fi
    if ((failed)); then
        if [[ -n "${_usage:-}" ]]; then
            error "Usage: $_usage"
        fi
        return 2
    fi
}


__meta_init__
