#!/usr/bin/env bash
# ------------------------------------------
# Filename: template.sh
# Version:   0.1
# Date: 2021/05/26
# Author: xinj
# Email: x@xhoe.com
# Website: www.xhoe.com
# Description: from https://mp.weixin.qq.com/s/ZO5jKzQGDy1Di1WDl49d_g
# Copyright: xinj
# License: GPL
# ------------------------------------------

# ------------------------------------------
# -a 标示已修改的变量，以供输出至环境变量。
# -b 使被中止的后台程序立刻回报执行状态。
# -C 转向所产生的文件无法覆盖已存在的文件。
# -d Shell预设会用杂凑表记忆使用过的指令，以加速指令的执行。使用-d参数可取消。
# -e 若指令传回值不等于0，即所谓的出错，则立即退出shell。
# -f 取消使用通配符。
# -h 自动记录函数的所在位置。
# -H Shell 可利用"!"加<指令编号>的方式来执行history中记录的指令。
# -k 指令所给的参数都会被视为此指令的环境变量。
# -l 记录for循环的变量名称。
# -m 使用监视模式。
# -n 只读取指令，而不实际执行。
# -p 启动优先顺序模式。
# -P 启动-P参数后，执行指令时，会以实际的文件或目录来取代符号连接。
# -t 执行完随后的指令，即退出shell。
# -u 当执行时使用到未定义过的变量，则显示错误信息。
# -v 显示shell所读取的输入值。
# -x 执行指令后，会先显示该指令及所下的参数。
# -o pipefail 使用管道时，有一个命令的返回值不为空，则整个管道返回该非0值
# +<参数> 取消某个set曾启动的参数。
# -E ERR trap被shell的函数所继承
# ------------------------------------------
# set -x
set -Eeuo pipefail

# ------------------------------------------
# trap -l: 列出支持的signal
# trap -p SIGINT SIGTERM 取消对信号的捕捉
#
# SIGINT: ctrl+c
# SIGTERM: 也是中断，kill缺省创建该信号
# ERR, EXIT: 报错和退出时处理
# ------------------------------------------
trap cleanup SIGINT SIGTERM ERR EXIT

# 初始化
function __change_this_name_init__() {
    # XLIB_CORE 未定义时则手动引入
    [[ -s $XLIB_CORE ]] && source "$XLIB_CORE" || {
        local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

        local parent=${script_dir%/*}
        source "$parent/..change-it-here../lib/core.sh"
    }
}
__change_this_name_init__

usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value arg1 [arg2...]

Script description here.

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-f, --flag      Some flag description
-p, --param     Some param description
EOF
    exit
}

cleanup() {
    # 取消trap捕获
    trap - SIGINT SIGTERM ERR EXIT
    # script cleanup here
}

setup_colors() {
    if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
        NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
    else
        NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
    fi
}

msg() {
    echo >&2 -e "${1-}"
}

die() {
    local msg=$1
    local code=${2-1} # default exit status 1
    msg "$msg"
    exit "$code"
}

parse_params() {
    # default values of variables set from params
    flag=0
    param=''

    #-o或--options选项后面接可接受的短选项，如ab:c::，表示可接受的短选项为-a -b -c，其中-a选项不接参数，-b选项后必须接参数，-c选项的参数为可选的
    #-l或--long选项后面接可接受的长选项，用逗号分开，冒号的意义同短选项。
    #-n选项后接选项解析错误时提示的脚本名字
    GETOPT_ARGS=$(getopt -o aehlp: -- "$@")
    if [ $? != 0 ]; then
        echo "Terminating..."
        exit 1
    fi
    echo ">>>> args: $@"
    #将规范化后的命令行参数分配至位置参数（$1,$2,...)
    eval set -- "$GETOPT_ARGS"
    while true; do
        case "$1" in
        -h | --help)
            usage
            shift
            ;;
        -v | --verbose)
            set -x
            shift
            ;;
        --no-color)
            NO_COLOR=1
            shift
            ;;

        -e)
            showRed "*** gitee"
            U_GITEE=1
            shift
            ;;
        -l)
            showRed "*** gitlab"
            U_GITLAB=1
            shift
            ;;
        -p)
            showRed "target path: $2"
            U_ROOT_PATH=$2
            shift 2
            ;;
        -a)
            showRed "update all repos for gitee,github,gitlab"
            U_GITEE=1
            U_GITHUB=1
            U_GITLAB=1
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Internal error!"
            exit 1
            ;;
        esac
    done

    #处理剩余的参数
    for arg in $@; do
        echo "processing $arg"
    done

    # while :; do
    #     case "${1-}" in
    #     -h | --help) usage ;;
    #     -v | --verbose) set -x ;;
    #     --no-color) NO_COLOR=1 ;;
    #     -f | --flag) flag=1 ;; # example flag
    #     -p | --param)          # example named parameter
    #         param="${2-}"
    #         shift
    #         ;;
    #     -?*) die "Unknown option: $1" ;;
    #     *) break ;;
    #     esac
    #     shift
    # done

    args=("$@")

    # check required params and arguments
    # [[ -z "${param-}" ]] && die "Missing required parameter: param"
    [[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

    return 0
}

main() {
    parse_params "$@"
    setup_colors

    # script logic here

    msg "${RED}Read parameters:${NOFORMAT}"
    msg "- flag: ${flag}"
    msg "- param: ${param}"
    msg "- arguments: ${args[*]-}"
}

main
