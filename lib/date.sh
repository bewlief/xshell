#!/usr/bin/env bash

# ------------------------------------------
# Filename: date.sh
# Version:   0.1
# Date: 2022/03/03
# 日期相关的函数实现
# ------------------------------------------

# 避免重复导入
[[ -n $__XLIB_IMPORTED__DATE ]] && return 0
__XLIB_IMPORTED__DATE=1

function __date_init__() {
    # 引入core.sh
    [[ -s $XLIB_CORE ]] && source "$XLIB_CORE" || {
        local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
        source "$script_dir/core.sh"
    }
}

# format <source date> <format>
function date::format() {
    local tdate=$1
    local format=$2

    # todo 检查 format 是否合法
    echo "$(date +"$format" --date "$tdate")"
}

# mac:
function date::now() {
    [[ -n $DEFAULT_DATE_TIME_FORMAT ]] && echo "$(date +"$DEFAULT_DATE_TIME_FORMAT")" && return 0
    date
}

function date::today() {
    echo "$(date +"$DEFAULT_DATE_FORMAT")"
}

function date::timestamp() {
    echo $(date +%s)
}

# Timestamp In Milliseconds
function date::timestamp1() {
    echo '('$(date +"%s.%N") ' * 1000000)/1' | bc
}

function date::toDate() {
    echo "$(date -d @$1)"
}
# todo
function date::toTimestamp() {
    date -d '02/12/2019 00:00:00' +"%s"
}

# 日期的加减
# getDays <type> <number>
# 根据 <type> 对今日日期增加 <number>，可为负值
function getDays() {
    local type=${1^^}
    local number=$2

    local type_str
    case "$type" in
    D | DAY | DAYS)
        type_str="days"
        ;;
    M | MONTH | MONTHS)
        type_str="months"
        ;;
    W | WEEK | WEEKS)
        type_str="weeks"
        ;;
    Y | YEAR | YEARS)
        type_str="years"
        ;;
    esac

    # date --date="2 days ago" 和 --date="-2 days" 是相同的，
    # 因此此处不判断运算类型
    echo "$(date --date="$number $type_str")"
}

# date2stamp "2006-10-01 15:00"
function date2stamp() {
    date --utc --date "$1" +%s
}

function stamp2date() {
    date --utc --date "1970-01-01 $1 sec" "+%Y-%m-%d %T"
}

# -s: sec. | -m: min. | -h: hours  | -d: days (default)
function dateDiff() {
    case $1 in
    -s)
        sec=1
        shift
        ;;
    -m)
        sec=60
        shift
        ;;
    -h)
        sec=3600
        shift
        ;;
    -d)
        sec=86400
        shift
        ;;
    *) sec=86400 ;;
    esac
    dte1=$(date2stamp $1)
    dte2=$(date2stamp $2)
    diffSec=$((dte2 - dte1))
    if ((diffSec < 0)); then abs=-1; else abs=1; fi
    echo $((diffSec / sec * abs))
}

function parseFromDateExample() {
    # 下面演示了如何解析一个日期，而不是多次调用 date +%m, date +%d 去获取！
    declare -A myDate=$(date +'([month]=%m [day]=%d [year]=%Y)')
    echo "Month=${myDate[month]}, Day=${myDate[day]}, Year=${myDate[year]}"

    # 操作一个时间戳
    local today=$(date +"%s")
    local month=$(date -d @$today +"%m")
    local day=$(date -d @$today +"%d")
    echo "timestamp: $today -> month=$month, day=$day"
}

# leap <year>
# 判断是否是闰年
function date::is-leap() {
    # based on http://cfajohnson.com/shell/date-functions/?is_leap_year

    local year="$1"
    local gregorian=1752

    [[ -z $year ]] && printf -v year '%(%Y)T'

    if ((year > gregorian)); then
        case $year in
        *0[48] | \
            *[2468][048] | \
            *[13579][26] | \
            *[02468][048]00 | \
            *[13579][26]00)
            return 0
            ;;
        *)
            return 1
            ;;
        esac
    else
        ((year % 4 == 0))
    fi
}

function date::to_path() {
    local timestamp="${1:-$(date +%s)}" depth="${2:-day}"
    local fmt

    case "$depth" in
    year)
        fmt="%Y"
        ;;
    month)
        fmt="%Y/%m"
        ;;
    day)
        fmt="%Y/%m/%d"
        ;;
    hour)
        fmt="%Y/%m/%d/%H"
        ;;
    minute)
        fmt="%Y/%m/%d/%H/%M"
        ;;
    second)
        fmt="%Y/%m/%d/%H/%M/%S"
        ;;
    *)
        echo "Invalid depth specified!"
        return 1
        ;;
    esac

    date -d@"$timestamp" +"$fmt"
}

# days <month> <year>
# 返回该月所包含的天数
function date::days() {
    # based on http://cfajohnson.com/shell/date-functions/?days_in_month

    declare -i month="${1#0}"
    declare -i year="${2:-$(date +%Y)}"
    declare -i days_in_month

    case $month in

    9 | 4 | 6 | 11)
        days_in_month=30
        ;;
    1 | 3 | 5 | 7 | 8 | 10 | 12)
        days_in_month=31
        ;;
    2)
        #               February alone
        # Which has but twenty-eight
        # Or twenty-nine each leap year
        year date::is-leap "$year" &&
            days_in_month=29 ||
            days_in_month=28
        ;;
    *)
        return 5
        ;;
    esac

    echo $days_in_month
}

# 计算两个时间点之间的差值
time_timer_start_time=""
time_timer_start() {
    time_timer_start_time=$(date +%s%N)
}
time_timer_get_elapsed() {
    local end_time="$(date +%s%N)"
    local elapsed_time_in_ns=$(($end_time - $time_timer_start_time))
    local elapsed_time_in_ms=$(($elapsed_time_in_ns / 1000000))
    echo "$elapsed_time_in_ms"
}



function date::help() {
    cat <<EOD
            Format/result           |       Command              |          Output
    --------------------------------+----------------------------+------------------------------
    YYYY-MM-DD_hh:mm:ss             | date +%F_%T                | $(date +%F_%T)
    YYYYMMDD_hhmmss                 | date +%Y%m%d_%H%M%S        | $(date +%Y%m%d_%H%M%S)
    YYYYMMDD_hhmmss (UTC version)   | date --utc +%Y%m%d_%H%M%SZ | $(date --utc +%Y%m%d_%H%M%SZ)
    YYYYMMDD_hhmmss (with local TZ) | date +%Y%m%d_%H%M%S%Z      | $(date +%Y%m%d_%H%M%S%Z)
    YYYYMMSShhmmss                  | date +%Y%m%d%H%M%S         | $(date +%Y%m%d%H%M%S)
    YYYYMMSShhmmssnnnnnnnnn         | date +%Y%m%d%H%M%S%N       | $(date +%Y%m%d%H%M%S%N)
    YYMMDD_hhmmss                   | date +%y%m%d_%H%M%S        | $(date +%y%m%d_%H%M%S)
    Seconds since UNIX epoch:       | date +%s                   | $(date +%s)
    Nanoseconds only:               | date +%N                   | $(date +%N)
    Nanoseconds since UNIX epoch:   | date +%s%N                 | $(date +%s%N)
    Z-notation UTC timestamp        | date --utc +%FT%TZ         | $(date --utc +%FT%TZ)
    Z-notation UTC timestamp + ms   | date --utc +%FT%T.%3NZ     | $(date --utc +%FT%T.%3NZ)
    ISO8601 UTC timestamp           | date --utc +%FT%T%Z        | $(date --utc +%FT%T%Z)
    ISO8601 UTC timestamp + ms      | date --utc +%FT%T.%3N%Z    | $(date --utc +%FT%T.%3N%Z)
    ISO8601 Local TZ timestamp      | date +%FT%T%Z              | $(date +%FT%T%Z)
    YYYY-MM-DD (Short day)          | date +%F\(%a\)             | $(date +%F\(%a\))
    YYYY-MM-DD (Long day)           | date +%F\(%A\)             | $(date +%F\(%A\))
    --------------------------------+----------------------------+------------------------------
    # %a 简称，例如 Sun,Mon
    # %A 星期的全称，例如 Sunday,Monday 等

    #%b 月份的简称，例如 Jan,Feb 等
    #%B 月份的全称，例如 January,February 等

    #%c 日期和时间，例如 Sat 29 Oct 2020 05:02:25 PM CST
    #%C 世纪
    #%d 当月的第几天
    #%D 日期，相当于 %m/%d/%y
    #%e 当月的第几天，用空格代替首位的0，相当于 %_d
    #%F 日期，相当于 %Y-%m-%d
    #%g 年份的后两位
    #%G 四位年份
    #%h 相当于 %b
    #%H 小时，从00到23
    #%I 小时，从01到12
    #%j 当年的第几天，001到366之间
    #%k 小时，用空格代替首位的0，相当于 %_H
    #%l 小时，用空格代替首位的0，相当于 %_I
    #%m 月份，从01到12
    #%M 分钟，从00到59
    #%n 换行
    #%N 纳秒，从000000000到999999999
    #%p 上午(AM)或下午(PM)
    #%P 类似月%p，但是为小写
    #%q 一年的四分之几，1到4
    #%r 12小时制时间，例如 11:11:04 PM
    #%R 24小时制时间，相当于%H:%M
    #%s 从 1970-01-01 00:00:00 UTC 到当前的秒数
    #%S second (00..60)
    #%t tab符
    #%T 时间，相当于 %H:%M:%S
    #%u 星期几，从1到7，1表示星期一
    #%U 一年的第几个星期，以星期六作为星期的开始，00到53
    #%V ISO星期数, 以星期一作为星期的开始，01到53
    #%w 星期几(0..6); 0 表示星期六
    #%W ISO星期数, 以星期一作为星期的开始，00到53
    #%x 日期，例如 12/31/99
    #%X 时间，例如 23:13:48
    #%y 年份的后两位(00..99)
    #%Y 四位年份
    #%z 时区，例如 -0400
    #%:z 时区，例如 -04:00
    #%::z 时区，例如 -04:00:00
    #%:::z 时区，例如 -04, +05:30
    #%Z 时区, 例如 EDT

    # 日期/时间加减的几个例子：
    #date --date "$dte  2 days 1 hour 5 sec"
    #date --date "$dte 3 days 5 hours 10 sec ago"
    #date --date "$dte -3 days -5 hours -10 sec"
    #date --date "$dte 3 days 5 hours 10 sec ago"
    #date --date "$dte -3 days -5 hours -10 sec"

EOD
}

__date_init__
