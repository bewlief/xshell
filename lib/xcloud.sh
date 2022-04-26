# ------------------------------------------
# Filename: xcloud.sh
# Version:   0.1
# Date: 2021/05/26
# note:
#   functions for cloud, including kubecttl, terraform, ansible, etc
# ------------------------------------------

# 避免重复导入
[[ -n $__XLIB_IMPORTED__XCLOUD ]] && return 0
__XLIB_IMPORTED__XCLOUD=1

function __xcloud_init__() {
    # 引入core.sh
    [[ -s $XLIB_CORE ]] && source "$XLIB_CORE" || {
        local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
        source "$script_dir/core.sh"
    }
}


# functions for k8s and cloud
alias kc='kubectl -n kube-system '

# 先使用 kubectl -n nnnn
# 然后就可以使用 k 去操作，不用再输入namespace
# 要切换到其他namespace，则使用 kubectl -n mmmm 操作下
function k() {
    local cmdline=$(HISTTIMEFORMAT="" history | awk '$2 == "kubectl" && (/-n/ || /--namespace/) {for(i=2;i<=NF;i++)printf("%s ",$i);print ""}' | tail -n 1)
    local regs=('\-n [\w\-\d]+' '\-n=[\w\-\d]+' '\-\-namespace [\w\-\d]+' '\-\-namespace=[\w\-\d]+')
    for i in "${!regs[@]}"; do
        local reg=${regs[i]}
        local nsarg=$(echo $cmdline | \grep -o -P "$reg")
        if [[ "$nsarg" == "" ]]; then
            continue
        fi
        local cmd="kubectl $nsarg $@"
        echo "$cmd"
        $cmd
        return
    done
    cmd="kubectl $@"
    echo "$cmd"
    $cmd
}

# 刷新PCF设置，从PCF_API_ORGS读取
# PCF_API_ORGS格式： env, api url, orgs list, default space
function cf-config() {
    # dev|https://dev.com:8080|aaa,bbb|space1;uat|https://uat.com:9000|org1,org2|none
    echo "pcf: $PCF_API_ORGS"
    echo ""
    local d1=($(string::split $PCF_API_ORGS ";"))
    for k in "${d1[@]}"; do
        d2=($(string::split $k "|"))
        if [[ ${#d2[@]} -eq 4 ]]; then
            env="${d2[0]}"
            url="${d2[1]}"
            orgs="${d2[2]}"
            default_space="${d2[3]}"

            echo "env=$env"
            echo "url=$url"
            echo "orgs=$orgs"
            echo "default space=$default_space"
            echo ""

            # 导出为全局变量，每个env包含2个变量：
            # pcf_dev_url, pcf_dev_orgs
            m1="export pcf_${env}_url=\"$url\""
            m2="export pcf_${env}_orgs=\"$orgs\""
            m3="export pcf_${env}_default=\"$default_space\""
            # echo "++++ $m1, $m2"
            eval $m1 || error "$m1 FAILED"
            eval $m2 || error "$m2 FAILED"
            eval $m3 || error "$m3 FAILED"
        else
            error "wrong configuration of PCF_API_ORGS"
        fi
    done
}

# 登录cloud foundry
# 调用：cf-login env org space
function cf-login() {
    cf-config

    local env=$1
    local org=$2
    local space=$3

    # 保存所有的错误
    declare -a msg
    # 必须输入 env 和 org
    if [[ -z $env || -z $org ]]; then
        msg+=("env and org be empty")
    fi

    # 必须预定义好 PCF_USER, PCF_PASS 这两个变量
    if [[ -z $PCF_USER || -z $PCF_PASS ]]; then
        msg+=("\$PCF_USER, \$PCF_PASS not defined")
    fi

    # 检查env，org是否在预定义的列表中
    local m1="pcf_${env}_url"
    local m2="pcf_${env}_orgs"
    local m3="pcf_${env}_default"
    # NOTE 注意如何读取m1，m2的值
    local v_url=${!m1}
    local v_orgs=${!m2}
    local v_space=${!m3}
    if [[ -z $env ]]; then
        msg+=("env $env not defined")
    fi
    if [[ ! $v_orgs =~ $org ]]; then
        msg+=("org $org not defined")
    fi
    if [[ -n $space ]]; then
        v_space=$space
    fi

    local cf_path=$(file::exist cf)
    if [[ -z $cf_path ]]; then
        msg+=("cf not found")
    fi

    # refactme: 新函数去打印某些提示信息
    local error_count=${#msg[@]}
    if [[ $error_count -gt 0 ]]; then
        error $(string::repeat "-" 80)
        printf "%s\n" "${msg[@]}"
        error $(string::repeat "-" 80)
        return 1
    fi

    # t_user=$(echo $PCF_USER | base64 -d)
    # t_pass=$(echo $PCF_PASS | base64 -d)
    local cf_login_cmd="cf login -a $v_url -o $org -s $v_space -u $PCF_USER -p \"$PCF_PASS\""
    alias cflogin="$cf_login_cmd"
    local reult=$(eval $cf_login_cmd)
    echo "==$result=="

    # 解析返回结果
    # FAILED, Unable to authenticate
    # Targeted org mdsg
    if [[ $result =~ "FAILED" ]]; then
        error "failed to cf login $url, $org"
    else
        # 登录成功，设置全局变量
        info "cf login $v_url, $org successfully"
        # cf apps

        # 保存当前的env，org，space
        set-active-env "$env"
        set-active-org "$org"
        set-active-space "$v_space"
    fi
}

function set-active-env() {
    local m="export pcf_active_env=\"$1\""
    eval $m || error "$m FAIELD"
}

function set-active-org() {
    local m="export pcf_active_org=\"$1\""
    eval $m || error "$m FAIELD"
}

function set-active-space() {
    local m="export pcf_active_space=\"$1\""
    eval $m || error "$m FAIELD"
}

# list current orgs, spaces
function cf-list() {
    local NOT_LOGGED_IN="Not logged in"
    local FAILED="FAILED"
    local WARN_NOT_LoGGED="you are not logged on any PCF instance"

    # cf orgs
    local orgs=($(cf orgs))
    if [[ $orgs =~ "$FAILED" ]]; then
        warn "$WARN_NOT_LoGGED"
        return
    else
        orgs=$(echo "$orgs" | sed -n '4,$p')
    fi
    echo "orgs: $orgs"

    local status=$(cf target 2>/dev/null)
    # 不能使用 cf target 的结果作为判断依据，因不调用cf logout时，长时间session
    # 过期后，cf target仍有正常返回！
    if [[ $status =~ "$FAILED" ]]; then
        warn "$WARN_NOT_LoGGED"
        return
    fi

    # spaces，删除前3行数据
    local spaces=($(cf spaces | sed -n '2,$p'))
    warn "current spaces"
    for s in "${spaces[@]}"; do
        info "---$s---"
    done
}

function cf-space() {
    local env=$pcf_active_env
    local org=$pcf_active_org
    local space=$pcf_active_space

    cf target -o $org -s $1
}
function cf-org() {
    local env=$pcf_active_env
    local org=$pcf_active_org
    local space=$pcf_active_space

    cf target -o $1 -s $space
}

# 检查是否登录在某个 pcf instance 中
# cf-ok dev
function cf-in() {
    local target_pcf=$1

    local status=$(cf target 2>/dev/null)
    echo "===$status==="

    if [[ $status =~ "Not logged in" || $status =~ "FAILED" ]]; then
        echo "false"
    else
        # 登录pcf，检查当前 env
        echo "true"
    fi
}
