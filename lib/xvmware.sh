# ------------------------------------------
# Filename: xvmware.sh
# Version:   0.1
# Date: 2021/05/26
# note:
#   functions for cloud, including kubecttl, terraform, ansible, etc

# 输入
#    VM_GROUPS
# ------------------------------------------

# 避免重复导入
[[ -n $__XLIB_IMPORTED__XVMWARE ]] && return 0
__XLIB_IMPORTED__XVMWARE=1

function __xvmware_init__() {
    # 引入core.sh
    [[ -s $XLIB_CORE ]] && source "$XLIB_CORE" || {
        local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
        source "$script_dir/core.sh"
    }

    export win_sudo="$MY_BASH_HOME/sudo.cmd"

    alias vmstart="${win_sudo} $MY_BASH_HOME/win/startVMWare.bat"
    alias vmstop="${win_sudo} $MY_BASH_HOME/win/stopVMWare.bat"

    PATH::append "$CLOUD_VMRUN"

    # alias vmrun="${VMRUN_EXE[@]}" 是无效的
    #function vmrun(){
    #    "${VMRUN_EXE[@]}" "$@"
    #}

}

# todo: check is vmware service is running
function _vm-check-running() {
    echo "vmware service: NOT ACTIVE"
}

# _vm-group-action "start|stop" "ini-file" "group-name"
function _vm-group-action() {
    local action="$1"
    local ini="$2"
    local target="$3"

    if [[ "$action" != "start" ]] && [[ "$action" != "stop" ]]; then
        echo "Invalid action. Action must be either start or stop."
        exit 1
    fi
    if [[ -z "$ini" || -z "$target" ]]; then
        echo "Usage: _vm-group-action start|stop ini-file group-name"
        return 1
    fi
    if [[ ! -f "$ini" ]]; then
        echo "Error: ini file '$ini' not found"
        return 1
    fi

    echo "$action $target with nogui from $ini"
    local boxes=($(string::ini::readIniItems "$ini" "$target"))
    if [[ ${#boxes[@]} -eq 0 ]]; then
        echo "Error: no VMs found in ini file for group '$target'"
        return 1
    fi
    for s in "${boxes[@]}"; do
        vmrun "$action" "$s" nogui
        echo "--- $s: ${action}ed"
    done
    echo "$target ${action}ed"
    echo ""
    echo ""
    # list all running instances
    vmrun list
}
function start-vm-group() {
    _vm-group-action start "$@"
}
function stop-vm-group() {
    _vm-group-action stop "$@"
}

__xvmware_init__
