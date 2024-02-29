# ------------------------------------------
# Filename: log.sh
# Version:   0.1
# Date: 2022/01/05
# note:
#   functions for log
# 注意：
# 1 有返回值的function中不要使用log::debug等否则会因echo而返回过多错误的数据
# 2
# info和log_info的区别在于是否显示色彩#
# ------------------------------------------

# 避免重复导入
[[ -n $__XLIB_IMPORTED__LOG ]] && return 0
__XLIB_IMPORTED__LOG=1

function __log_init__() {
    # 引入core.sh
    [[ -s $XLIB_CORE ]] && source "$XLIB_CORE" || {
        local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
        source "$script_dir/core.sh"
    }

    export LOG_DEBUG=9
    export LOG_INFO=7
    export LOG_WARN=5
    export LOG_ERROR=3

    # 设定log file，全局变量
    export LOG_FILE=${LOG_FILE}

    # ex: LOG_LEVEL=info, LOG_LEVEL_n=7
    export LOG_LEVEL_n=$(_parse-level "${LOG_LEVEL:-"info"}")

    # 是否打印 stack trace
    export LOG_STACKTRACE=${LOG_STACKTRACE:-$FALSE}
}

# 把 "info" -> $LOG_INFO
function _parse-level() {
    local level="$1"

    local result
    case "${level^^}" in
    "INFO")
        result=$LOG_INFO
        ;;
    "DEBUG")
        result=$LOG_DEBUG
        ;;
    "WARN")
        result=$LOG_WARN
        ;;
    "ERROR")
        result=$LOG_ERROR
        ;;
    *) ## 默认为 info，仅显示 info,warn,error
        result=$LOG_INFO
        ;;
    esac
    echo "$result"
}

# 动态修改 LOG_LEVEL
function log::level() {
    import string

    if [[ -n "$1" ]]; then
        export LOG_LEVEL="${1:-info}"
        export LOG_LEVEL_n=$(_parse-level $LOG_LEVEL)
    fi

    local s="$LOG_LEVEL"
    [[ -n "$LOG_FILE" ]] && s="$LOG_LEVEL >>$LOG_FILE"

    info "log level is [ $s ], print stacktrace: [ $LOG_STACKTRACE ]"
}

function log::d() {
    log::level "debug"
}
function log::i() {
    log::level "info"
}
function log::w() {
    log::level "warn"
}
function log::e() {
    log::level "error"
}

function log::stack() {
    export LOG_STACKTRACE=${1:-$FALSE}
}

# 要写入log，必须使用 start 1.log 初始化log文件
function log::start() {
    import file

    # 设置一个默认log文件
    LOG_FILE=${1:-"$TEMP/$$.log"}
    LOG_FILE=$(file::absolute $LOG_FILE)

    file::new ${LOG_FILE} && chmod 775 $LOG_FILE
    log::info "Process $$, start at: $(date +"$DEFAULT_DATE_TIME_FORMAT")"
    log::info "LOG_LEVEL: $LOG_LEVEL"
    log::info "LOG_FILE: $LOG_FILE"
    log::blank

    log::level
}
function log::stop() {
    unset LOG_FILE
    log::level
}

#readonly LOG_DEBUG=9 LOG_INFO=7 LOG_WARN=5 LOG_ERROR=3

function log::debug() {
    [[ $LOG_LEVEL_n -ge $LOG_DEBUG ]] && _log_message "DEBUG" "$@"
}

function log::info() {
    [[ $LOG_LEVEL_n -ge $LOG_INFO ]] && _log_message "INFO" "$@"
}

function log::warn() {
    [[ $LOG_LEVEL_n -ge $LOG_WARN ]] && _log_message "WARN" "$@"
}

function log::error() {
    [[ $LOG_LEVEL_n -ge $LOG_ERROR ]] && _log_message "ERROR" "$@"
}

function log::blank() {
    _write_text_to_log ""
    _write_text_to_log ""
}

# $1: type, error/info/warn...
# $2: msg
function _log_message() {
    local level="${1^^}"
    shift

    # level的颜色控制
    local s=""
    case "$level^^" in
    "INFO")
        s="${GREEN_COLOR}$level${RES}"
        ;;
    "DEBUG")
        s="${PINK_COLOR}$level${RES}"
        ;;
    "WARN")
        s="${YELLOW_COLOR}$level${RES}"
        ;;
    "ERROR")
        s="${RED_COLOR}$level${RES}"
        ;;
    *) ## 默认为 info，仅显示 info,warn,error
        s="${GREEN_COLOR}$level${RES}"
        ;;
    esac

    local msg="[$s] $(date +'%H:%M:%S') [$(hostname)] $@"
    local rawMsg="[$level] $(date +'%H:%M:%S') [$(hostname)] $@"

    local st=""
    if [[ $level == "DEBUG" && ${LOG_STACKTRACE^^} == $TRUE ]]; then
        # 3个数组的数据是一一对应的
        #        t1=${#BASH_LINENO[@]}
        #        t2=${#BASH_SOURCE[@]}
        #        t3=${#FUNCNAME[@]}
        #        total=$((t1 - 1))
        #        local st=""
        #        for ((v1 = $total; v1 > 0; v1--)); do
        #            st+="${BASH_SOURCE[v1]}[${BASH_LINENO[v1]}]${FUNCNAME[v1]} ->"
        #        done
        local BEGIN=0
        local I
        for ((I = BEGIN; I < ${#FUNCNAME[@]}; I++)); do
            st+="\t at ${FUNCNAME[$I]}(${BASH_SOURCE[$I]}:${BASH_LINENO[$I - 1]})\n"
        done
        import string
        st=$(string::rstrip "$st" "\n")
        msg="$msg\n$st"
    fi
    # todo 会导致function返回多余的数据。如何避免这个呢？？？
    echo -e "$msg"

    # 仅当 $LOG_FILE 定义时才写入文件
    [[ -f "$LOG_FILE" ]] && _write_text_to_log "$rawMsg"
}

function _write_text_to_log() {
    # 无需检查文件是否存在，直接写入
    echo "$1" >>$LOG_FILE
}

#>> * `stacktrace [INDEX]` - display functions and source line numbers starting
#>> from given index in stack trace, when debugging or back tracking is enabled.
function log::stacktrace() {
    [ "${__log__DEBUG:-}" != "yes" -a "${__log__STACKTRACE:-}" != "yes" ] || {
        local BEGIN="${1:-1}" # Display line numbers starting from given index, e.g. to skip "log::stacktrace" and "error" functions.
        local I
        for ((I = BEGIN; I < ${#FUNCNAME[@]}; I++)); do
            echo $'\t\t'"at ${FUNCNAME[$I]}(${BASH_SOURCE[$I]}:${BASH_LINENO[$I - 1]})" >&2
        done
        echo
    }
}

__log_init__
