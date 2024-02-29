# ------------------------------------------
# Filename: assertions
# Version:   0.1
# Date: 2022/04/02
# note:
#   一些常用判断条件的assert
# ------------------------------------------

# 避免重复导入
[[ -n $__XLIB_IMPORTED__ASSERTIONS ]] && return 0
__XLIB_IMPORTED__ASSERTIONS=1

function __assertions_init__() {
    [[ -s $XLIB_CORE ]] && source "$XLIB_CORE" || {
        # shellcheck disable=SC2155
        local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
        source "$script_dir/core.sh"
    }
}
# bash-version <x.y> [message]
# 校验bash版本至少为 x.y
# BASH_VERSINFO: 4 4 23 2 release x86_64-pc-msys
function assert::bash-version() {
    local version=$1 message=$2
    local version_array curr_version
    local version_re='^[0-9]+\.[0-9]+$'
    assert::arg-count $# 1 "Usage: assert::bash-version 4.3"
    assert::regex-match "$version" "$version_re" "Version should be in the format x.y where x and y are integers"
    version_array=(${version//\./ })
    ((BASH_VERSINFO[0] < version_array[0] || ((\
    BASH_VERSINFO[0] == version_array[0] && BASH_VERSINFO[1] < version_array[1])))) && {
        local curr_version="${BASH_VERSINFO[@]:0:4}"
        [[ $message ]] || message="Running with Bash version ${curr_version// /.}; need $version or above"
        error "$message"
        exit $INVALID_BASH_VERSION
    }
    return $GENERIC_NORMAL
}

# arg-count <actual> <expected> [message]
# 校验入参个数
function assert::arg-count() {
    local actual=$1
    local expected=$2
    local message=${3:-"Expected $expected arguments, got $actual arguments"}
    ((actual == expected)) || {
        error "$message"
        exit $INVALID_ARGUMENTS
    }
    #    return 0
}

# regex <string> <regex> [message]
# 校验字符串是否符合指定的正则表达式
function assert::regex-match() {
    local string=$1
    local regex=$2
    local message=${3:-"String '$string' does not match regex '$regex'"}
    [[ $string =~ $regex ]] || {
        error "$message"
        exit $STRING_REGX_NOT_MATCH
    }
}

# 断言变量是否存在
# defined <var-name-not-$var-name>
# defined -f <var-nar-not-$var-name>
# defined "s": s:变量名称，非 $s
# defined -f: 不存在时强制exit
function assert::defined() {
    local fatal
    local var
    local num_null=0
    [[ "$1" = "-f" ]] && {
        fatal=1
        shift
    }
    for var in "$@"; do
        [[ -z "${!var}" ]] && printf '%s\n' "Variable '$var' not set" >&2 && ((num_null++))
    done

    if ((num_null > 0)); then
        [[ "$fatal" ]] && exit 1
        return $GENERIC_ERROR
    fi
    return 0
}

function assert::notNull() {
    [[ -z "$1" ]] && {
        error "$val null"
        exit $GENERIC_ERROR
    }

    return 0
}

#
# assert if $1 is a valid URL
#
function assert::valid-url() {
    (($#)) || return 0
    local url=$1
    curl --fail --head -o /dev/null --silent "$url" || {
        error "Invalid URL - '$url'"
        exit $GENERIC_ERROR
    }
}

# 检查cmd是否在PATH中
# check-cmd <command>
function assert::check-cmd() {
    cmd="$1"
    if [[ -z "$cmd" ]]; then
        _usage "Usage: _exists cmd"
        return 1
    fi

    if eval type type >/dev/null 2>&1; then
        eval type "$cmd" >/dev/null 2>&1
    elif command >/dev/null 2>&1; then
        command -v "$cmd" >/dev/null 2>&1
    else
        which "$cmd" >/dev/null 2>&1
    fi

    die $? "check-cmd: $cmd failure"

    # 注意中间不能有其他操作，否则$?不准确！
    #    [[ $? -gt 0 ]] && exit 1
    #    return $?
}

# chec-files <file or file list>
# 检查文件是否存在，有一个不存在则exit
function assert::check-files() {
    local file
    local rc=0
    for file; do
        if [[ ! -f "$file" && ! -d "$file" ]]; then
            error "File '$file' does not exist"
            ((rc++))
        fi
    done

    [[ $rc -gt 0 ]] && exit 1
    return 0
}

# assert that we are running on the right OS
# assert::os <expected os> [current os]
function assert::os() {
    local _os=${BASE_OS:-""}
    if [[ $_os != "$1" ]]; then
        error "Required OS: $1, current OS: $_OS"
        exit 1
    fi

    return 0
}

# 命令输出结果判断
# assert::cmd-equail <cmd> <expected> [stdin]
function assert::cmd-equal() {
    local _indent=$'\n\t'
    local expected=$(echo -ne "${2:-}")
    local result="$(eval 2>/dev/null $1 <<<${3:-})" || true

    if [[ "$result" == "$expected" ]]; then
        #        [[ -n "$DEBUG" ]] && echo -n $result
        return $GENERIC_NORMAL
    fi

    result="$(sed -e :a -e '$!N;s/\n/\\n/;ta' <<<"$result")"
    [[ -z "$result" ]] && result="nothing" || result="\"$result\""
    [[ -z "$2" ]] && expected="nothing" || expected="\"$2\""
    error "expected $expected${_indent}got $result" "$1" "${3:-}"
    exit $STRING_NOT_EQUAL
}

# unit::assert_not_empty VALUE [MESSAGE]
# Show error message, when `VALUE` is empty.
assert::notEmpty() {
    local VALUE="${1:-}"
    local MESSAGE="${2:-Value is empty.}"

    [[ -n "${VALUE:-}" ]] || {
        error "ASSERT FAILED" "$MESSAGE"
        exit 1
    }
}

# equal <string1> <string2> [message]
# 校验两个字符串是否相等
function assert::equal() {
    local ACTUAL="${1:-}"
    local EXPECTED="${2:-}"
    local MESSAGE="${3:-Values are not equal.}"

    [[ "${ACTUAL:-}" == "${EXPECTED:-}" ]] || {
        error "ASSERT FAILED" "$MESSAGE Actual value: \"${ACTUAL:-}\", expected value: \"${EXPECTED:-}\"."
        exit $STRING_NOT_EQUAL
    }

    return 0
}

# notEqual <string1> <string2> [message]
assert::notEqual() {
    local ACTUAL_VALUE="${1:-}"
    local UNEXPECTED_VALUE="${2:-}"
    local MESSAGE="${3:-values are equal but must not.}"

    [ "${ACTUAL_VALUE:-}" != "${UNEXPECTED_VALUE:-}" ] || {
        error "ASSERT FAILED" "$MESSAGE Actual value: \"${ACTUAL_VALUE:-}\", unexpected value: \"$UNEXPECTED_VALUE\"."
        exit 1
    }
    return 0
}

# assert <message> <command string>
# 校验command是否正常执行
assert::assert() {
    local MESSAGE="${1:-}"
    shift

    eval "$@" >/dev/null 2>&1 || {
        error "ASSERT FAILED" "${MESSAGE:-}: $@"
        exit 1
    }

    return 0
}

# array-equals <message> <a1> <a2>
# ex: a1=(111 222); a2=(aaa bbb); array-equals "mmm" a1 a2
assert::array-equals() {
    (($# == 2 || $# == 3)) || error "assertArrayEquals must 2 or 3 arguments!"

    local failMsg=""
    (($# == 3)) && {
        failMsg=$1
        shift
    }

    local a1PlaceHolder="$1[@]"
    local a2PlaceHolder="$2[@]"
    local a1=("${!a1PlaceHolder}")
    local a2=("${!a2PlaceHolder}")

    [[ ${#a1[@]} -eq ${#a2[@]} ]] || error "array length [${#a1[@]}] != [${#a2[@]}]${failMsg:+: $failMsg}"

    local i
    for ((i = 0; i < ${#a1[@]}; i++)); do
        [ "${a1[$i]}" = "${a2[$i]}" ] || error "fail element $i: [${a1[$i]}] != [${a2[$i]}]${failMsg:+: $failMsg}"
    done
}

__assertions_init__
