# for my local


# ext/*.sh，构建与lib/基础之上，只是因为通过 xbash_profile.sh 导入，
# 因此无需再次source core
function __local_xjm_init__() {
    [[ -s $XLIB_CORE ]] && source "$XLIB_CORE" || {
        local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
        local parent=${script_dir%/*}
        source "$parent/lib/core.sh"
    }

    import meta

    import xdev
    import string

    # golang
    export GO_HOME="$MY_SOFT/dev/sdk/go"
    export GOROOT="$GO_HOME"
    export GOPATH="$MY_CODES/mygo"
    export ANT_HOME="$MY_SOFT/dev/build/ant"
    export NODE_HOME=$MY_SOFT/dev/build/node

    export GROOVY_HOME=$MY_SOFT/dev/sdk/groovy
    local MYSQL_HOME=$MY_SOFT/database/mysql
    local POSTGRESQL_HOME=/usr/local/Cellar/postgresql@12/12.6_1
    local VIM="$MY_SOFT/dev/vim"
    local VIM_BIN="$VIM/vim82"

    PATH::after "$MYSQL_HOME/bin:$POSTGRESQL_HOME/bin:$GROOVY_HOME/bin"
    PATH::after "$NODE_HOME/:$ANT_HOME/bin:$MY_SOFT/database/redis/redis-win64/bin/windows:$GO_HOME/bin:$VIM_BIN"
    PATH::before "$HOME/xcodes/xops/xshell/test"
}

function _setVmwareEnv() {
    import xvmware
    VM_GROUPS=("k8s/vm2/vm2" "harbor/harbor" "rancher/master2/r3")
    k8s=("" "" "" "" "")
    ranche=("" "" "" "")


    declare -A dddd=(
        ["aaa"]="a1/b1/c1, a1/b2/c2"
        ["bbb"]="d1/ss, ww/dd"
    )

}

function _mkAlias() {
    # cluster on Rancher
    alias k1='kubectl --kubeconfig $HOME/.kube/k1.config '

    # cluster on old k8s
    alias k0='kubectl --kubeconfig $HOME/.kube/k0.config '

    # single node k8s by rancher
    alias ks='kubectl --kubeconfig $HOME/.kube/s.yaml '

    alias dl='cdl /d/Download'

    alias mycodes="cdl $MY_CODES/mycodes"
    alias mygo="cdl $MY_CODES/mygo"
    alias mypy="cdl $MY_CODES/mypy"
    alias xops="cdl $MY_CODES/xops"

    alias mysql='mysql -uroot -p123456 -Ddevops -h 127.0.0.1'

    local HOSTS="/etc/hosts"
    alias hosts="clear && showRed \"alias <hosts> only shows the contents added by xjm in $HOSTS\" && repeat '*' 90 && tail -n +$(\grep -n "CHANGED BY XJM" $HOSTS | awk -F':' '{print $1}') $HOSTS && repeat '*' 90 "
}

# 打印空行而已
function b() {
    local count=$1
    local count=${count:-10}
    for ((I = 0; I < $count; I++)); do
        echo ""
    done
}

########## spring actuator curl .../info
[[ -z $SPRING_ACTUATOR_PORT ]] && SPRING_ACTUATOR_PORT=8080
[[ -z $SPRING_ACTUATOR_HOST ]] && SPRING_ACTUATOR_HOST="localhost"

# act info
# act info localhost 8001
function act() {
    local count=${#@}

    if [[ $count == 3 ]]; then
        set-spring-act $2 $3
    fi

    if [[ $count -ne 3 && $count -ne 1 ]]; then
        error "wrong"
        return
    fi

    local s="curl http://${SPRING_ACTUATOR_HOST}:${SPRING_ACTUATOR_PORT}"
    s="$s/$@ | jq"
    echo ">>>> $s"
    eval "$s"
}
# set-spring-act localhost 9001
function set-spring-act() {
    local host=$1
    local port=$2
    export SPRING_ACTUATOR_HOST=$host
    export SPRING_ACTUATOR_PORT=$port
}

__local_xjm_init__

# 自定义函数及环境设置
_mkAlias
_setVmwareEnv
