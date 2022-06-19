# ------------------------------------------
# Filename: string.sh
# Version:   0.1
# Date: 2021/05/26
# note:
#   functions for string
# ------------------------------------------

# 避免重复导入
[[ -n $__XLIB_IMPORTED__STRING ]] && return 0
__XLIB_IMPORTED__STRING=1

function __string_init__() {
    [[ -s $XLIB_CORE ]] && source "$XLIB_CORE" || {
        local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
        source "$script_dir/core.sh"
    }
}

# *************** string *************** #

# random 10 alnum: 生成指定长度、指定算法的随机字符串
# 可选算法：alnum, alpaha, digit, graph, lower, print, punct, upper
function string::random() {
    local length=$1
    local algorithm=$2

    local count=6
    [[ $length != "" ]] && count=$(($length + 1))

    # 注意数组元素之间的空格！
    local types=("alnum" "alpha" "digit" "graph" "lower" "print" "upper")
    # NOTE 判断元素是否在数组中
    local inarray=$(echo ${types[@]} | \grep -o "$algorithm" | wc -w)
    if [[ $inarray != 1 ]]; then
        algorithm="alnum"
    fi

    # 使用 tr 输出随机字符串
    echo $(cat /dev/urandom | tr -dc "[:$algorithm:]" | fold -w ${length:-$count} | head -n 1)
}

# 比较快速的随机数 randomq 6
function string::randomq() {
    local max=${1:-6}
    [[ $max -gt 32 ]] && max=32
    echo $RANDOM | md5sum | cut -c 1-$max
}

# lower ARG
function string::lower() {
    # echo ${1,,}
    echo -n "$1" | awk '{print tolower($0)}'
}
function string::upper() {
    # echo ${1^^}
    echo -n "$1" | awk '{print toupper($0)}'
}
function string::length() {
    echo -n "$1" | awk '{print length($0)}'
}

# 判断字符是否为空
# isBlank <string>
# s="ddd"; if string::isBalnk $s; then ...
function string::isBlank() {
    local length=$(string::length $1)
    if [[ $length -gt 0 ]]; then
        return 1
    else
        return 0
    fi
}
function string::notBlank() {
    local length=$(string::length $1)
    if [[ $length -eq 0 ]]; then
        return 1
    else
        return 0
    fi
}

# 字符串向右缩进
# echo "hello " | indent <indent level>
function string::indent() {
    local LINE
    local LINES
    local I
    local INDENT_LEVEL
    local INDENT

    # Get the second argument with default value 1.
    INDENT_LEVEL=${1:-1}
    INDENT=$(string::repeat '  ' "$INDENT_LEVEL")

    IFS=$'\n' read -rd '' -a LINES || true
    if [[ ${#LINES[@]} -eq 0 ]]; then
        echo -n "$INDENT"
        return 0
    fi

    # Make sure not to add a trailing line terminator back.
    for ((I = 0; I < ${#LINES[@]} - 1; I++)); do
        echo "${INDENT}${LINES[$I]}"
    done
    echo -n "${INDENT}${LINES[$I]}"
}

# 判断字符串 s1 是否包含 s2
# contains <s1> <s2>
function string::contains() {
    # [ "${1#*$2*}" = "$1" ] && return 1
    # return 0
    if [[ "$2" =~ $1 ]]; then
        return 1
    else
        return 0
    fi
}

function string::removeBrCr() {
    echo $1 | sed 's/\\r//' | sed 's/\\n//'
}

# 将 k=v 格式化为 k ------------ v
# formatKeyValue <key> <value> [length] [splitter char]
# char, length 为空时，则设置为默认的 "-", 屏幕的一半宽度
function string::formatKeyValue() {
    local k="$1"
    local v="$2"
    local char=${3:-"-"}
    local d=$(($COLUMNS / 2))
    local length=${4:-$d}

    # NOTE 另一个生成重复字符串的方法，但不知如何使用变量
    # R=$(printf '%0.1s' ${char}{1..${length}})

    local R=$(string::repeat "$char" $length)

    # echo $line
    #printf "${color} %s %s $v\E[0m\n" "$k" "${R:${#k}}"
    printf " %s %s $v\n" "$k" "${R:${#k}}"
}

# 居中，两侧填充 "hello world" "-"
# 对中文不准
function string::center() {
    [[ $# == 0 ]] && return 1
    [[ $# -ge 2 ]] && ch="${2:0:1}" || ch=" "

    declare -i TERM_COLS="$(tput cols)"
    declare -i str_len="${#1}"
    [[ $str_len -ge $TERM_COLS ]] && {
        echo "$1"
        return 0
    }

    declare -i filler_len="$(((TERM_COLS - str_len - 2) / 2))"
    local filler=""
    for ((i = 0; i < filler_len; i++)); do
        filler="${filler}${ch}"
    done

    printf "%s%s%s" "$filler" " $1 " "$filler"
    [[ $(((TERM_COLS - str_len) % 2)) -ne 0 ]] && printf "%s" "${ch}"
    printf "\n"

    return 0
}

# 左侧填充: leftPad "hello" "-" 80
function string::leftPad() {
    local k=$1
    local char
    local length

    char=${2:-" "}
    length=${3:-$(($COLUMNS / 2))}

    #    if [[ "$2" != "" ]]; then
    #        char=$2
    #    fi
    #
    #    if [[ "$3" != "" ]]; then
    #        length=$3
    #    fi

    local R=$(string::repeat "$char" $length)

    echo "${R:${#k}} $k"
}
# 右侧填充: rightPad "hello" "-" 80
function string::rightPad() {
    local k=$1
    local char
    local length

    char=${2:-" "}
    length=${3:-$(($COLUMNS / 2))}

    local R=$(string::repeat "$char" $length)

    echo "$k ${R:${#k}}"
}

# 分割字符串
# substr <string> <start index> [end index]
# substr "hello world" 1 -> ello wolrd: from 1 to end
# substr "hello world" 1 3 -> ell: from 1 to 3
function string::substr() {
    local s="$1"
    local start=${2-0}
    local end=${3-${#s}}
#    if [ $# -eq 2 ]; then
#        s=$1
#        start=$2
#        end=${#s}
#    elif [ $# -eq 3 ]; then
#        s=$1
#        start=$2
#        end=$3
#    fi

    echo "${s:start:end}"
    return $?
}

# 向字符串中的指定位置插入字符串
# todo 注意nameref的使用！
# 使用： v="abba"; insert v 2 "cc"; v->"abccba"
function string::insert() {
  local -n source="$1"
  local position="$2"
  local val="${3:-}"

  val="${source::$position}${val}${source:$position}"

  source="$val"
}

# strip "The Quick Brown Fox" "[aeiou]" -> Th Qck Brwn Fx
# strip "The Quick Brown Fox" "[[:space:]]" -> TheQuickBrownFox
# strip "The Quick Brown Fox" "Quick " -> The Brown Fox
function string::strip() {
    # Usage: strip_all "string" "pattern"
    printf '%s' "${1//$2/}"
}

# 删除第一次出现的pattern
function string::lstrip() {
    # Usage: lstrip "string" "pattern"
    printf '%s' "${1##$2}"
}

# 删除最后出现的pattern
function string::rstrip() {
    # Usage: rstrip "string" "pattern"
    printf '%s' "${1%%$2}"
}

# 字符串替换
# replace <string> <source str> <target string>
function string::replace() {
    echo "${1//${2}/${3}}"
}

# 大小写反转
function string::reverse(){
    printf '%s' "${1~~}"
}

# 连接数组中的元素
# join <splitter char> "${dd[@]}"
# 只能是单字符！
function string::join() {
    local IFS="$1"
    shift
    echo "$*"
}
# 连接数组中的各元素
# 可使用多char的分隔符
function string::joins(){
    local s
    local split="$1"
    shift
    for m in "$@"; do
        s+="$split$m"
    done
    # 去掉最前面的split
    s=$(printf '%s' "${s##$split}")
    echo $s
}


# 对输出中的特定字符着色处理
# noisy_command | highlight ERROR INFO
# Inspired by https://stackoverflow.com/a/25357856
function string::highlight() {
    # color cycles from 0-5, (shifted 31-36), i.e. r,g,y,b,m,c
    local color=0 patterns=()
    for term in "$@"; do
        patterns+=("$(printf 's|%s|\e[%sm\\0\e[0m|g' "${term//|/\\|}" "$((color + 31))")")
        color=$(((color + 1) % 6))
    done
    sed -f <(printf '%s\n' "${patterns[@]}")
}

# 仅能使用单一字符作为splittor！
# 分解字符串，注意调用时变量都要用 ""！
# todo 无法处理带有空格的元素！
# dd=($(split "hello,you,world" ","))
function string::split() {
    local str=$1
    local splittor=$2

    local OLD_IFS="$IFS"
    IFS="$splittor"
    local array=($str)

    # just print for testing.
    # SHOULD NOT USE ECHO here OR it will be treated as return value
    # for s in ${array[@]}; do
    #     echo "---$s"
    # done
    IFS="$OLD_IFS"

    # count=${#array[@]}
    # echo "这里是正确的，in split, total: $count"
    # for ((i = 0; i < count; i++)); do
    #     t=${array[i]}
    #    new[i]=$t
    #     echo "--$t"
    # done

    # return one array
    # todo 有问题，无法正确处理空格！
    echo ${array[@]}
}

# NOTE 分解字符串到一个数组，使用nameref
# https://stackoverflow.com/questions/10582763/how-to-return-an-array-in-bash-without-using-globals
# split "11,22,33,44" "," m1 : 分解字符串到数组变量 m1
# 调用前先unset m1，避免其被使用过！
# split "Helloyou Hellome Hello我" "Hello" m1
function string::split2() {
    local source=$1
    local splittor=$2

    # local -n, declare -n相同，声明一个nameref，相当于指针
    local -n arr=$3

    local t

    local str=$source$splittor
    while [[ $str ]]; do
        t=("${str%%"$splittor"*}")
        t=$(string::trim $t)
        [[ -n $t ]] && arr+=("$t")
        str=${str#*"$splittor"}
    done
}

# 重复输出字符串
# repeat <string> [length]
# repeat $1 $2: $1=字符串，$2=重复次数
function string::repeat() {
    # char=$1
    # num=$2
    # printf "%-${num}s\n" | sed "s/\s/$char/g"

    local OLD_IFS="$IFS"
    IFS=$IFS_MINE

    local N
    local R
    local R=" "
    local N=$(($COLUMNS-3))

    R=${1:-" "}
    N=${2:-$N}

    while true; do
        ((N -= 1))
        [[ $N -ge 0 ]] || break
        R+=$1
    done
    echo "$R"

    IFS="$OLD_IFS"
}

# 水平分割线，默认为*，全屏长度
function ui::hr() {
    string::repeat "${1:-"-"}"
}


# zconfig.yml:
# development:
#   adapter: mysql2
#   encoding: utf8
#   database: my_database
#   username: root
#   password: dsdsd
#   address: ddddd
#     add1: addddddd

# 去除字符串两头的空格
#  trim "$d" 注意双引号括起来！
function string::trim() {
    local var=$1
    echo "${var}" | awk '{gsub(/^ +| +$/,"")} {print $0}'
}

# 移除所有空格
# var="'Hello', \"World\""
# trim_quotes "$var" -> Hello,World
function string::trimAll() {
    # Usage: trim_all "   example   string    "
    set -f
    set -- $*
    printf '%s\n' "$*"
    set +f
}

#$ var="'Hello', \"World\""
#$ trim_quotes "$var"
#Hello, World
trim_quotes() {
    # Usage: trim_quotes "string"
    : "${1//\'/}"
    printf '%s\n' "${_//\"/}"
}

# Removes all leading/trailing blank lines.
function string::trim_lines() {
    #
    # Explanation of sed command:
    #     :a      # Set label a
    #     $!{     # For every line except the last...
    #         N   # Add to pattern space with a newline
    #         ba  # Go back to label a
    #     }
    #
    # The pattern space now consists of a single string containing newlines.
    #
    #     s/^[[:space:]]*\n//  # Remove all leading whitespace (blank lines).
    #     s/\n[[:space:]]*$//  # Remove all trailing whitespace (blank lines).
    #
    # </doc:trim_lines>

    sed ':a;$!{N;ba;};s/^[[:space:]]*\n//;s/\n[[:space:]]*$//'
}

# 对string使用正则
# Trim leading white-space.
# regex '    hello' '^\s*(.*)'
#hello
#
## Validate a hex color.
#regex "#FFFFFF" '^(#?([a-fA-F0-9]{6}|[a-fA-F0-9]{3}))$'
##FFFFFF
#
## Validate a hex color (invalid).
#regex "red" '^(#?([a-fA-F0-9]{6}|[a-fA-F0-9]{3}))$'
## no output (invalid)
function string::regx() {
    [[ $1 =~ $2 ]] && printf '%s' "${BASH_REMATCH[1]}"
}

join_lines() {
    # <doc:join_lines>
    #
    # Joins lines from stdin into a string::
    #
    # DELIMITER defaults to ", ".
    #
    # Usage: join_lines [DELIMITER]
    #
    # Usage examples:
    #     echo -e "foo\nbar\nbaz" | join_lines      #==> foo, bar, baz
    #     echo -e "foo\nbar\nbaz" | join_lines "|"  #==> foo|bar|baz
    #
    # </doc:join_lines>

    local delim=${1:-, }

    while read -r; do
        echo -ne "${REPLY}${delim}"
    done | sed "s/$delim$//"
    echo
}

flatten() {
    # <doc:flatten>
    #
    # Substitute variable names with variables.
    #
    # The default is to try to substitute all environment variables, but if
    # any names are given, it will be limited to just those.
    #
    # The placeholder syntax can be changed by setting the following variables:
    #
    #     FLATTEN_L  # Default: {{
    #     FLATTEN_R  # Default: }}
    #
    # Usage: flatten TEXT [VAR...]
    #
    # </doc:flatten>

    local t=$1
    shift
    local n

    local fl=${FLATTEN_L:-\{\{}
    local fr=${FLATTEN_R:-\}\}}

    if (($# == 0)); then
        IFS=$'\n' set -- $(set | variables)
    fi

    for n in "$@"; do
        t=${t//${fl}${n}${fr}/${!n}}
    done

    echo "$t"
}

# 是否以 $2 开头
# 另一种方式： if [[ $var == sub_string* ]]; then ”start with $2"; fi
function string::startWith() {
    local _str="$1"
    local _sub="$2"
    local t=$(echo "$_str" | \grep "^$_sub")
    if [[ -n $t ]]; then
        return 1
    else
        return 0
    fi
}

# 另一种方式：if [[ $var == *sub_string ]]; then ...
function string::endWith() {
    local _str="$1"
    local _sub="$2"
    local t=$(echo "$_str" | \grep -- "$_sub\$")
    if [[ -n $t ]]; then
        return 1
    else
        return 0
    fi
}

# ********** ini ********** #
# _readINI 1.repo jenkins host ： 从文件1.repo中读取小节=jenkins，字段名 host 的值
# 范例文件 1.repo 的内容：
# [jenkins]
# a=user1/repo1
# a=user2/repo2

# [maven]
# c=user3/repo1
# d=user4/repo2

# readSectionField 1.repo jenkins a
# 读取1.repo中的[jenkins]部分的key=a的值
function readSectionField() {
    local INIFILE=$1
    local SECTION=$2
    local ITEM=$3

    local _readIni=$(awk -F '=' '/\['$SECTION'\]/{a=1}a==1&&$1~/'$ITEM'/{print $2;exit}' $INIFILE)
    echo ${_readIni}
}

# load section from ini format
# todo 怎么用的？？？
function readIniKeyValue() {
    if [ "$#" -eq "2" ] && [ -f "$1" ] && [ -n "$2" ]; then
        local INIFILE=$1
        local SECTION=$2
        local ITEM=$3
        local _readIni=$(awk -F '=' '/\['$SECTION'\]/{a=1}a==1&&$1~/'$ITEM'/{print $2;exit}' $INIFILE)
        echo ${_readIni}
    else
        echo ""
    fi
}

# readRepos 1.repo jenkins
# 读取 1.repo 中，[jenins]部分的所有item
function readIniItems() {
    local CONFIG=$1
    local SECTION=$2
    if [[ -e $CONFIG ]]; then
        # 读取 [SECTION] 到下一个 [或# 之间的部分
        local vv=($(sed -n '1,/'"\[$SECTION\]"'/d;/[\[#]/,$d;/^$/d;p' "$CONFIG"))

        # 去掉 ;和#开头的元素
        declare -a newvv=(${vv[@]/[;#]*/})
        # echo "${vv[@]}"
        echo "${newvv[@]}"
    else
        echo ""
    fi
}

# Get INI section
function readIniSections() {
    local filename="$1"
    gawk '{ if ($1 ~ /^\[/) section=tolower(gensub(/\[(.+)\]/,"\\1",1,$1)); configuration[section]=1 } END {for (key in configuration) { print key} }' ${filename}
}

function string::uuid() {
    #string::GenerateUUID() {
    ## https://gist.github.com/markusfisch/6110640
    local N B C='89ab'

    for ((N = 0; N < 16; ++N)); do
        B=$(($RANDOM % 256))
        case $N in
        6)
            printf '4%x' $((B % 16))
            ;;
        8)
            printf '%c%x' ${C:$RANDOM%${#C}:1} $((B % 16))
            ;;
        3 | 5 | 7 | 9)
            printf '%02x-' $B
            ;;
        *)
            printf '%02x' $B
            ;;
        esac
    done
}


# 比较版本号，返回：0=，1>，2<
# ver-cmp 2.3 2.5.9 版本号要用 . 分隔
function ver-cmp() {
    local r=0
    if [[ $1 == $2 ]]; then
        r=0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i = ${#ver1[@]}; i < ${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i = 0; i < ${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            r=1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            r=2
        fi
    done
    echo $r
}

# 获取字符串中指定索引的字段的值
# field-by-index "aa,bb,cc" 2 ","
function string::field() {
    local _str="$1"
    local _findex="$2"
    local _sep="$3"

    if [ -z "$_findex" ]; then
        return 1
    fi

    # 默认 , 分割
    if [ -z "$_sep" ]; then
        _sep=","
    fi

    local _ffi="$_findex"
    while [ "$_ffi" -gt "0" ]; do
        _fv="$(echo "$_str" | cut -d "$_sep" -f "$_ffi")"
        if [ "$_fv" ]; then
            printf -- "%s" "$_fv"
            return 0
        fi
        _ffi="$(_math "$_ffi" - 1)"
    done

    printf -- "%s" "$_str"

}

# below are from: D:\Download\aaaa\free\shell\acmesh-official\acme.sh\acme.sh

function string::char2dec() {
    local _ch=$1
    case "${_ch}" in
    a | A)
        printf "10"
        ;;
    b | B)
        printf "11"
        ;;
    c | C)
        printf "12"
        ;;
    d | D)
        printf "13"
        ;;
    e | E)
        printf "14"
        ;;
    f | F)
        printf "15"
        ;;
    *)
        printf "%s" "$_ch"
        ;;
    esac
}

# todo how to use?
function string::ord() {
    local __string__VAR="$1"
    local __string__CHAR="$2"

    printf -v "$__string__VAR" '%d' "'$__string__CHAR"
}

function string::ascii2hex() {
    _str="$1"
    _str_len=${#_str}
    _h_i=1
    while [ "$_h_i" -le "$_str_len" ]; do
        _str_c="$(printf "%s" "$_str" | cut -c "$_h_i")"
        printf " %02x" "'$_str_c"
        _h_i=$(($_h_i + 1))
    done
}
#a + b
_math() {
    _m_opts="$@"
    printf "%s" "$(($_m_opts))"
}


# 对空格分割的字符串中的元素进行排序
# echo "c b a"     | sort_list       #==> a b c
# echo "c, b, a"   | sort_list ", "  #==> a, b, c
# echo "c b b b a" | sort_list -u    #==> a b c
# echo "c b a"     | sort_list -r    #==> c b a
function string::sort() {
    local r u

    unset OPTIND
    while getopts ":ur" option; do
        case $option in
        u) u=-u ;;
        r) r=-r ;;
        esac
    done && shift $(($OPTIND - 1))

    local delim=${1:- }
    local item list

    OIFS=$IFS
    IFS=$'\n'
    for item in $(sed "s%${delim//%/\%}%\n%g" | sort $r $u); do
        IFS=$OIFS
        list+="$(trim <<<"$item")$delim"
    done

    echo "${list%%$delim}"
}

# *************** array *************** #

# ----------------------------
# 检查数组中是否包含某元素
# in "$aaa" "${array[@]}"
# 返回 $aaa 在数组中的数量，全词匹配
# ----------------------------
function array::in() {
    local ele=$1
    shift
    local array=("${@}")

    # 使用grep，无法处理 #$^*等，@是可以处理的
    #    d=$(echo "${array[@]}" | grep -ow "$ele" | wc -w)

    # 循环处理，慢但可以处理任何字符
    local count=0
    for k in "${array[@]}"; do
        if [[ x"$k" == x"$ele" ]]; then
            ((count++))
        fi
    done
    echo $count
}

function array::in2() {
    local e
    for e in "${@:2}"; do
        [[ "$e" == "$1" ]] && return 0
    done
    return 1
}

# 判断一个变量是否是array
function array::is() {
    local obj="$1"
    local s=$(declare -p "$obj" 2>/dev/null | \grep '^declare \-a' | wc -l)
    echo $s
}

# *************** ui *************** #
# 打印ascii图标
function ui::icon() {
    local i=''
    case "$1" in
        check | checkmark) i='\xE2\x9C\x93' ;;
        X | x | xmark) i='\xE2\x9C\x98' ;;
        '<3' | heart) i='\xE2\x9D\xA4' ;;
        sun) i='\xE2\x98\x80' ;;
        '*' | star) i='\xE2\x98\x85' ;;
        darkstar) i='\xE2\x98\x86' ;;
        umbrella) i='\xE2\x98\x82' ;;
        flag) i='\xE2\x9A\x91' ;;
        snow | snowflake) i='\xE2\x9D\x84' ;;
        music) i='\xE2\x99\xAB' ;;
        scissors) i='\xE2\x9C\x82' ;;
        tm | trademark) i='\xE2\x84\xA2' ;;
        copyright) i='\xC2\xA9' ;;
        apple) i='\xEF\xA3\xBF' ;;
        skull | bones) i='\xE2\x98\xA0' ;;
        ':-)' | ':)' | smile | face) i='\xE2\x98\xBA' ;;
    esac
    echo -ne "$i"
}

# todo
function ui::head(){
    ui::hr "-"
    echo -e "$1"
    ui::hr "-"
}
function ui::foot(){
    ui::hr "-"
    echo -e "$1"
    ui::hr "-"
}

# figlet的封装
# figlet "msg" "a-text" "flf file name"
function ui::figlet() {
    local msg="$1"
    local text="$2"
    local font="${3:-standard}"

    local font_file="$HOME/xsoft/bin/flf/$font.flf"

    # todo check length
    local length=${#msg}
    [[ $length -ge 30 ]] && warn "String is too long"

    # 最大宽度为999，但调用时msg不要过长，否则换行后很难看
    echo ""
    figlet0 -f "$font_file" -w 999 "$msg"
    echo -e "$text" # so that it can parse \t,\n...
}

# todo 汉字的长度计算不准确，最右的|会错位
# banner  $contents
function ui::banner() {
    local t=$(expr $COLUMNS - 3)
    local t1=$(expr $t - 1)
    local m=$(string::repeat "-" $t)

    echo -n "+$m+"
    printf "| %-${t1}s |" "$(date +"$DEFAULT_DATE_TIME_FORMAT")"
    echo -n "|$m|"
    printf "|$(tput bold) %-${t1}s $(tput sgr0)|" "$@"
    echo -n "+$m+"
    echo ""
}

# urlencode "https://github.com/dylanaraps/pure-bash-bible"
# -> https%3A%2F%2Fgithub.com%2Fdylanaraps%2Fpure-bash-bible
function url-encode() {
    local LC_ALL=C
    local r i
    for ((i = 0; i < ${#1}; i++)); do
        # 截取字符串放到 $_ 终故能
        : "${1:i:1}"
        case "$_" in
        [a-zA-Z0-9.~_-])
            r+=$(printf '%s' "$_")
            ;;
        *)
            r+=$(printf '%%%02X' "'$_")
            ;;
        esac
    done
    echo "$r"
}
function url-decode() {
    echo "$(printf '%b\n' "${_//%/\\x}")"
}

# 翻转数组 "${aa[@]}"
function array::reverse() {
    shopt -s extdebug
    f() (printf '%s\n' "${BASH_ARGV[@]}")
    f "$@"
    shopt -u extdebug
}

# 移除数组中的重复元素 "${aa[@]}"
function array::remove-dups() {
    # Usage: remove_array_dups "array"
    declare -A tmp_array

    for i in "$@"; do
        [[ $i ]] && IFS=" " tmp_array["${i:- }"]=1
    done

    printf '%s\n' "${!tmp_array[@]}"
}

# 随机元素
function array::random() {
    # Usage: random_array_element "array"
    local arr=("$@")
    printf '%s\n' "${arr[RANDOM % $#]}"
}

function array::dump() {
    printf "%s\n" "$@"
}

# 查询某元素在数组中的位置
# index "aaa" "${a[@]}"
# 返回该元素的index，不存在时则返回-1
# todo 使用nameref的版本？
function array::index() {
    local value="$1"
    shift
    local array=("$@")
    local -i index=-1
    local i
    for i in "${!array[@]}"; do
        if [[ "${array[$i]}" == "${value}" ]]; then
            local index="${i}"
        fi
    done
    echo "$index"
    if ((index == -1)); then
        return 1
    fi
}

# 过滤数组
function array::filter() {
    # shellcheck disable=SC2016,SC2034
    local __doc__='
    Filters values from given array by given regular expression.

    >>> local a=(one two three wolf)
    >>> local b=( $(array::filter ".*wo.*" "${a[@]}") )
    >>> echo ${b[*]}
    two wolf
    '
    local pattern="$1"
    shift
    local array=($@)
    local element
    for element in "${array[@]}"; do
        echo "$element"
    done | \grep --extended-regexp "$pattern"
}

# 数组切片
function array::slice() {
    local __doc__='
    Returns a slice of an array (similar to Python).

    From the Python documentation:
    One way to remember how slices work is to think of the indices as pointing
    between elements, with the left edge of the first character numbered 0.
    Then the right edge of the last element of an array of length n has
    index n, for example:
    ```
    +---+---+---+---+---+---+
    | 0 | 1 | 2 | 3 | 4 | 5 |
    +---+---+---+---+---+---+
    0   1   2   3   4   5   6
    -6  -5  -4  -3  -2  -1
    ```

    >>> local a=(0 1 2 3 4 5)
    >>> echo $(array_slice 1:-2 "${a[@]}")
    1 2 3
    >>> local a=(0 1 2 3 4 5)
    >>> echo $(array::slice 0:1 "${a[@]}")
    0
    >>> local a=(0 1 2 3 4 5)
    >>> [ -z "$(Array::slice 1:1 "${a[@]}")" ] && echo empty
    empty
    >>> local a=(0 1 2 3 4 5)
    >>> [ -z "$(Array::slice 2:1 "${a[@]}")" ] && echo empty
    empty
    >>> local a=(0 1 2 3 4 5)
    >>> [ -z "$(Array::slice -2:-3 "${a[@]}")" ] && echo empty
    empty
    >>> local a=(0 1 2 3 4 5)
    >>> [ -z "$(Array::slice -2:-2 "${a[@]}")" ] && echo empty
    empty

    Slice indices have useful defaults; an omitted first index defaults to
    zero, an omitted second index defaults to the size of the string being
    sliced.
    >>> local a=(0 1 2 3 4 5)
    >>> # from the beginning to position 2 (excluded)
    >>> echo $(Array::slice 0:2 "${a[@]}")
    >>> echo $(Array::slice :2 "${a[@]}")
    0 1
    0 1

    >>> local a=(0 1 2 3 4 5)
    >>> # from position 3 (included) to the end
    >>> echo $(Array::slice 3:"${#a[@]}" "${a[@]}")
    >>> echo $(Array::slice 3: "${a[@]}")
    3 4 5
    3 4 5

    >>> local a=(0 1 2 3 4 5)
    >>> # from the second-last (included) to the end
    >>> echo $(Array::slice -2:"${#a[@]}" "${a[@]}")
    >>> echo $(Array::slice -2: "${a[@]}")
    4 5
    4 5

    >>> local a=(0 1 2 3 4 5)
    >>> echo $(Array::slice -4:-2 "${a[@]}")
    2 3

    If no range is given, it works like normal array indices.
    >>> local a=(0 1 2 3 4 5)
    >>> echo $(Array::slice -1 "${a[@]}")
    5
    >>> local a=(0 1 2 3 4 5)
    >>> echo $(Array::slice -2 "${a[@]}")
    4
    >>> local a=(0 1 2 3 4 5)
    >>> echo $(Array::slice 0 "${a[@]}")
    0
    >>> local a=(0 1 2 3 4 5)
    >>> echo $(Array::slice 1 "${a[@]}")
    1
    >>> local a=(0 1 2 3 4 5)
    >>> Array::slice 6 "${a[@]}"; echo $?
    1
    >>> local a=(0 1 2 3 4 5)
    >>> Array::slice -7 "${a[@]}"; echo $?
    1
    '
    local start end array_length length
    if [[ "$1" == *:* ]]; then
        IFS=":"
        read -r start end <<<"$1"
        shift
        array_length="$#"
        # defaults
        [ -z "$end" ] && end=$array_length
        [ -z "$start" ] && start=0
        ((start < 0)) && let "start=(( array_length + start ))"
        ((end < 0)) && let "end=(( array_length + end ))"
    else
        start="$1"
        shift
        array_length="$#"
        ((start < 0)) && let "start=(( array_length + start ))"
        let "end=(( start + 1 ))"
    fi
    let "length=(( end - start ))"
    ((start < 0)) && return 1
    # check bounds
    ((length < 0)) && return 1
    ((start < 0)) && return 1
    ((start >= array_length)) && return 1
    # parameters start with $1, so add 1 to $start
    let "start=(( start + 1 ))"
    echo "${@:$start:$length}"
}


__string_init__
