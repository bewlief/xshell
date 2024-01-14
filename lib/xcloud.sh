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

  # set PATH for cloud
  PATH::append "$CLOUD_AWS"
  PATH::append "$CLOUD_AWS_SAM/bin"
  PATH::append "$CLOUD_BIN"

  # functions for k8s and cloud
  alias kc="kubectl.exe "
  alias tf="terraform.exe "
  alias hm='helm '
  alias sam="$CLOUD_AWS_SAM/bin/sam.cmd "

  # using alpine/dfimage to check history of a docker image
  # usage: dfimage -sV=1.36 docker.io/sonarqube:v1.0.0
  alias dfimage="docker run -v /var/run/docker.sock:/var/run/docker.sock --rm alpine/dfimage"
}

#---------- k8s ---------#
# xkc -n {namespace}: 设置默认的namespace
# xkc --kubeconfig {config-file}：设置cluster config文件
function xkc() {
  #
  local count=${#@}
  if [[ $count -gt 0 ]]; then
    if [[ "$1" == "-n" ]]; then
      _kc_set_namespace "$2"
      info "kubectl: set default namespace=$2"
    elif [[ "$1" == "-config" ]]; then
      if [[ -f "$2" ]]; then
        _kc_set_config "$2"
        info "kubectl: set config to $2"
      else
        error "kubectl: config file not existing: $2"
      fi
    else
      echo "xkc -n {namespace} or xkc --kubeconfig {config-file}"
    fi
  else
    echo "xkc -n {namespace} or xkc --kubeconfig {config-file}"
  fi
}

# KUBECONFIG 用于设置活动的cluster配置文件
# 也可直接指定：kubectl --kubeconfig=file1
function kc::config() {
  if [ -z "$1" ]; then
    if [ -d "$HOME/.kube" ]; then
      echo "Available kubeconfig files in $HOME/.kube:"
      for file in $HOME/.kube/*; do
        if grep -q "kind: Config" "$file"; then
          #                    clusterName=$(jq -r '.clusters[].name' "$file" | head -n 1)
          echo "  - $file"
          #                    echo "    * cluster: ${clusterName:-Unknown}"
        fi
      done
    else
      echo "Error: $HOME/.kube directory does not exist"
      return 1
    fi
  else
    if [ ! -f "$1" ]; then
      echo "Error: $1 does not exist"
      return 1
    fi

    export KUBECONFIG="$1"
    echo "Using kubeconfig file: $1"
  fi
}

# 设置默认的namespace
function _kc_set_namespace() {
  export KUBE_DEFAULT_NAMESPACE="$1"
  kubectl config set-context --current --namespace=$KUBE_DEFAULT_NAMESPACE
}

# 查询 namespace=$1 中的 name包含$2的完整的pod name
# todo
function kc::get-pod-name() {
  echo "search in namespace [ $1 ], pod for [ $2 ]"
  # 默认的namespace？
  echo $(kubectl get pods --namespace $1 -l "app.kubernetes.io/name=$2,app.kubernetes.io/instance=$2" -o jsonpath="{.items[0].metadata.name}")
}

function kc::set-default-namespace() {
  kubectl config set-context --current --namespace=${1:-default}
}

#---------- PCF ---------#
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

#---------- aws ---------#
function ssha() {
  if [[ -n "$1" ]]; then
    local cmd="$(which ssh) -i /d/Download/aws/vm1_key_pair.pem ec2-user@$1"
    echo "---> $cmd"
    eval "$cmd"
  else
    error "target hostname cannot be null!"
  fi
}

#---------- docker ---------#

# 清理 tag=none 的镜像
function dk::clean() {
  # docker images -qf "dangling=true" | xargs docker rmi --force
  docker images -qf "dangling=true" | while read line; do
    # 删除镜像
    echo "delete $line"
    docker rmi $line --force
  done
}

function dk::check(){
  # 检查包含指定字符的容器
  echo "包含 $1 的容器："
  docker ps -a --filter "name=*$1*"

  # 检查包含指定字符的活动镜像
  echo "包含 $1 的活动镜像："
  docker images --filter "reference=*$1*"
}

#---------- openshift ---------#
function oc_login(){
  # todo need define constants for openshift
  OPENSHIFT_SERVER="https://api.openshift.com:6443"
  OPENSHIFT_USERNAME="root"
  OPENSHIFT_PASSWORD="123456"

  oc login -u "$OPENSHIFT_USERNAME" -p "$OPENSHIFT_PASSWORD" --server="$OPENSHIFT_SERVER" --insecure-skip-tls-verify > /dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    TOKEN=$(oc whoami --show-token)
    if [[ -n "$TOKEN" ]]; then
      echo "Successfully logged in. Access token: $TOKEN"
      export OC_TOKEN="$OTKEN"
    else
      echo "Faield to extract the access token. Please check he user information."
    fi
  else
    echo "Login faile。 Please chec your credentials."
  fi
}

function oc_getpod(){
  current_pod=$(oc get pods|grep "$1" | awk '$3=="Running" {print $1}')
  return $current_pod
}

#---------- ALL CLOUD function end ---------#

__xcloud_init__
