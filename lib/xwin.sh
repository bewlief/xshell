# ------------------------------------------
# Filename: xwin.sh
# Version:   0.1
# Date: 2021/12/07
# windows下相关的函数
# ------------------------------------------

# 避免重复导入
[[ -n $__XLIB_IMPORTED__XWIN ]] && return 0
__XLIB_IMPORTED__XWIN=1

#
function __xwin_init__() {
    # 引入core.sh
    [[ -s $XLIB_CORE ]] && source "$XLIB_CORE" || {
        local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
        source "$script_dir/core.sh"
    }

    _set-win-global

    import string
}

function _set-win-global() {
    alias ps='ps -W '
}

function monitor() {
    local type=$1

    if [[ -n $type ]]; then
        local MMT="$MY_BASH_HOME/win/_switch-monitor.bat"
        #    local MONITOR_CONFIG_ROOT=$MY_BASH/config/monitor

        start $MMT $type &
    else
        monitor::help
    fi
}
function monitor::help() {
    local c

    cat <<EOF

switch monitor mode between internal/extend/external/PBP/PIB using mmt.

Usage
    monitor
    monitor <config name>
    monitor::help

how to:
1. setup your monitor using windows monitor configuration.
2. run mmt, save current configuration to $XLIB_BASE_CONFIG/monitor, as a .cfg file.
3. setup your monitor to another resolution/config and export again.
EOF

    ui::hr
    for c in $XLIB_BASE_CONFIG/monitor/*.cfg; do
        local n=$(file::baseName "$c")
        echo "-- $n"
    done
    ui::hr
}

# 根据 global.ini 更新set-win-variables.bat
function update-win-vars() {
    # 需更新的变量包括：
    # GRADLE_USER_HOME, JAVA_HOME, GIT_HOME
    echo "update-win-vars"
}


function nosleep() {
    import string

    # start cscript "$MY_BASH/win/nosleep.vbs"
    start $XLIB_BASE_PARENT/win/_no-sleep.bat

    ui::figlet "NO SLEEP"
    ui::banner "close the windows of cscript then sleep again"
}

__xwin_init__
