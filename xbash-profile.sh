#!/usr/bin/env bash

# ------------------------------------------
# Filename: xbash-profile.sh
# Version:   0.1
# Date: 2022/03/09
# 在$HOME/.bash_profile中调用，读取指定的global config文件
# 建议这里定义常用的不易改变的功能，一些临时使用或者不普适的需求，
# 可以定义到 ext/下， 将会被自动引入
# ------------------------------------------

function __xbash_init__() {
    # xbash-profile也是基于lib，core
    [[ -s $XLIB_CORE ]] && source "$XLIB_CORE" || {
        local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
        source "$script_dir/lib/core.sh"
    }

    import meta
}

function importCommonFunctions() {
    echo "load common libraries: $LIBS_IMPORTED"

    local d k
    if [[ -n $LIBS_IMPORTED ]]; then
        d=($LIBS_IMPORTED)
        for k in "${d[@]}"; do
            eval "import $k"
        done
    fi
}

# 20220307 引入 BASE_HOME 变量，用于定制个人根目录
function get-base-home() {
    #    if [[ ! $HOME ]]; then
    #         warn "Environment variable 'HOME' is not set!"
    #    fi
    #
    #    if [[ ! -d $HOME ]]; then
    #        warn "\$HOME '$HOME' is not a directory!"
    #    fi

    # if BASE_HOME is still not set, go with the default value
    BASE_HOME=${BASE_HOME:-$HOME}
}

# 设置 MY_* 的全局变量
function loadGlobalVariables() {
    # set -a：使得其后定义的变量都被自动export
    set -a
    source "$GLOBAL_INI"
    set +a

    # another way: https://stackoverflow.com/questions/19331497/set-environment-variables-from-file-of-key-value-pairs
    #    export $(grep -v '^#' .env | xargs -d '\n')
    # unset:
    #    unset $(grep -v '^#' .env | sed -E 's/(.*)=.*/\1/' | xargs)

    #bash ${-:+-$-} -c 'command'
    #https://www.cnblogs.com/0xcafebabe/p/12720768.html
    #${-:+-$-} 的含义是，将当前 shell 的选项作为子进程（bash）的选项。

    # NOTE 设置默认值，a:-"dd": a为null或空字符串时赋值
    # a-"dd": a为null时赋值
    #

    # 系统预设的全局变量：env:
    # $USERNAME=xjming
    # $HOME=/c/Users/xjming
    # $USERPROFILE=C:\Users\xjming

    # 设置默认值
    export MY_CODES=${MY_CODES:-$HOME/xcodes}
    # todo 应该将自己定义的变量与xlib需要的变量分开，并加以说明！
    # 自定义变量不允许出现在xlib中！
    export PS1_GIT_STATUS=${PS1_GIT_STATUS:-false}
    export MY_OPS=${MY_OPS:-"$HOME/xcodes/xops"}
    export MY_DATA=${MY_DATA:-"$HOME/xdata"}
    export MY_BACKUP=${MY_BACKUP:-"$MY_OPS/0_system_files/backuped-files/${USERNAME}"}
    export GLOBAL_INI=${GLOBAL_INI:-"$HOME/xcodes/xops/xshell/config/global.ini"}
    export FREE_CODES=${FREE_CODES:-"$HOME/xcodes/free"}
    export XTEMP=${XTEMP:-"$HOME/xtmp"}
    export MAVEN_REPOSITORY=${MAVEN_REPOSITORY:-"$HOME/.m2/repository"}
    export MAVEN_OPTS=${MAVEN_OPTS_STR:-"-Xms512m -Xmx2G -Dfile.encoding=UTF-8"}
    export XLIB_EDITOR=${XLIB_EDITOR:-"vi"}
    export MY_VMWARE_GROUPS=${MY_VMWARE_GROUPS:-""}

    #
    export MY_SOFT=$HOME/xsoft

    # https://curl.se/docs/sslcerts.html
    export CURL_CA_BUNDLE="$MY_SOFT/bin/cacert.pem"

    # default jdk，jd的目录名称
    export DEFAULT_JDK_VERSION=${DEFAULT_JDK_VERSION:-"jdk11"}

    #
    export MY_BASH_HOME="$MY_OPS/xshell"

    export SYSINTERNALS_ROOT="$MY_SOFT/system/sysinternals"

    # go
    export GOPROXY=https://goproxy.cn

}

# 设置各种应用的路径及相关变量
function setAppVariables() {
    # 根据系统类型更新 MY_SOFT
    if [[ "$BASE_OS" == "$MAC" ]]; then
        # todo 重新设置MY_SOFT，或可以设置为 $MY_SOFT/win | mac
        export MY_SOFT=$MY_SOFT

        # if using vscode
        vscode() { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args "$@"; }
    elif [[ "$BASE_OS" == "$WIN" ]]; then
        export MY_SOFT=$MY_SOFT
    fi

    # path of all sdk
    export JDK_ROOT=$MY_SOFT/dev/sdk/jdk

    # export DEFAULT_JDK_VERSION=11
    export JAVA_HOME="$JDK_ROOT/${DEFAULT_JDK_VERSION}"

    local VSCODE_HOME="$MY_SOFT/dev/vscode"

    export PYTHON_HOME="$MY_SOFT/dev/python"

    # maven, gradle
    export MAVEN_HOME="$MY_SOFT/dev/build/maven"

    export GRADLE_HOME="$MY_SOFT/dev/build/gradle"
    export GIT_HOME="$MY_SOFT/dev/build/git"

    # gradle.properties should be placed here
    export GRADLE_USER_HOME="$MAVEN_REPOSITORY"

    # TODO set default JDK version here !
    #     export DEFAULT_JDK_VERSION="jdk11"
    #     #switchJdk $DEFAULT_JDKVERSION
    #     jdk $DEFAULT_JDK_VERSION

    # todo 判断 PATH::add等函数是否有效
    local MY_PATH="$PYTHON_HOME:$MY_SOFT/bin:$MY_BASH_HOME:$MAVEN_HOME/bin:$GIT_HOME/bin:$GRADLE_HOME/bin:$VSCODE_HOME/bin"

    PATH::add "$MY_PATH"
    PATH::add "$JAVA_HOME/bin"
    PATH::append "$SYSINTERNALS_ROOT"
    PATH::append "$XLIB_ORIGIN_PATH"
    PATH::append "$MY_SOFT/documents/npp"

    export CARGO_HOME="/c/Users/xjming/xsoft/dev/rust/cargo"
    export RUSTUP_HOME="/c/Users/xjming/xsoft/dev/rust/rustup"
    PATH::append "$CARGO_HOME/bin"
    PATH::append "$RUSTUP_HOME/toolchains/stable-x86_64-pc-windows-gnu/bin"
}

# 创建alias
function createAlias() {

    # todo codes,xsoft等应放到 ext/local.sh 中
    alias grep='grep -i -nE --color'
    alias codes='cdl $HOME/xcodes'
    alias xsoft='cdl $MY_SOFT'
    alias mybash="cdl $MY_BASH_HOME"
    alias mine='cdl $MY_CODES'
    alias free='cdl $FREE_CODES'
    alias gy="$GROOVY_HOME/bin/groovy "
    alias gyc="$GROOVY_HOME/bin/groovyc "
    alias mynote="cdl $MY_HOME/mynote"

    # mkdir -p "$HOME/xtmp"
    #mkdir -p "$XTEMP"
    alias tmp="cdl $XTEMP"
    alias dl="cdl $XDOWNLOAD"

    alias sudo="$MY_BASH_HOME/sudo.cmd"

    # figlet
    alias fl='figlet0 -f $HOME/xsoft/bin/flf/standard.flf '

    alias mvp='mvn clean package -Dmaven.test.skip=true'

}

function main() {
    loadGlobalVariables
    setAppVariables
    importCommonFunctions
    loadExt
    createAlias
    setPS1
}

__xbash_init__

main

ui::figlet "XLIB - cool"
