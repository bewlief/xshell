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

    # alias vmrun="${VMRUN_EXE[@]}" 是无效的
    #function vmrun(){
    #    "${VMRUN_EXE[@]}" "$@"
    #}

}

__xvmware_init__
