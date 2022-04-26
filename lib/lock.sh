#!/usr/bin/env bash

# ------------------------------------------
# Filename: xlock.sh
# Version:   0.1
# Date: 20220330
# note:
#
# attempt to lock the shared resource
# lock::lock "your_task_name"
#
# if the lock was successful, execute the task
# sleep 30
#
# release the lock when the task is done
# lock::release "your_task_name"
#
# lock::spinlock "ssss"
# echo "spin lock got"
# sleep 30
# lock::release "ssss"
# ------------------------------------------

# 避免重复导入
[[ -n $__XLIB_IMPORTED__LOCK ]] && return 0
__XLIB_IMPORTED__LOCK=1

function __lock_init__() {
    # 引入core.sh
    [[ -s $XLIB_CORE ]] && source "$XLIB_CORE" || {
        local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
        source "$script_dir/core.sh"
    }

    # Practice safe bash scripting.
    set -o errexit
    set -o nounset

    # Customize the location of your lock files for this resource.
    LOCK_DIR="${TEMP:-"$HOME'.xlock"}"
    # Set to true to supress log messages.
    SILENT=false

    # Check for locks and provide a warning during an abnormal exit.
    trap "check_for_locks" SIGTERM SIGINT ERR
}

# 获取loc，不成功则直接退出
lock::lock() {
    if create_lock $1; then
        check_execution "acquire lock"
        lock_log "Created $1 lock."
    else
        lock_log "Cannot run $1 -- application locked."
        exit 1
    fi
}

# 获取loc，不成功则一直等待
# spinlock "dd" 20
# dd: lock name, 20: second, timeout
lock::spinlock() {
    local max=${2:-3}
    echo "max waittime: $max"

    lock_log "Waiting on lock for $1."
    local wait_period=0
    while :; do
        if create_lock $1; then
            lock_log "Created $1 lock."
            break
        else
            sleep 1
            wait_period=$((wait_period + 1))
            if [[ wait_period -gt $max ]]; then
                lock_log "timeout: max=$max, now: $wait_period"
                exit 1
            fi
        fi
    done
}

create_lock() {
    check_lock_dir
    (
        set -o noclobber
        echo "locked" >"$LOCK_DIR/$1".lock
    ) 2>/dev/null
}

function lock::release() {
    lock_log "Releasing $1 lock."
    rm "$LOCK_DIR/$1".lock
    check_execution "release lock"
}

check_for_locks() {
    shopt -s nullglob
#    if [[ ($LOCK_DIR/*.lock) ]]; then
    local f
    for f in $LOCK_DIR/*.log; do
        lock_log "Dirty exit -- lock files found in $LOCK_DIR."
        shopt -u nullglob && exit 3
    done
    shopt -u nullglob
}

check_lock_dir() {
    if [ ! -d $LOCK_DIR ]; then
        lock_log "Creating lock directory: $LOCK_DIR"
        mkdir -p $LOCK_DIR
        check_execution "create lock directory"
    fi
}

check_execution() {
    if [ $? -ne 0 ]; then
        lock_log "Could not $1, exiting."
        exit 2
    fi
}

lock_log() {
    if [ ! "$SILENT" == true ]; then
        local datetime=$(date +"%Y-%m-%d %H:%M:%S")
        printf "$datetime - Keyway: $1\n"
    fi
}

__lock_init__
