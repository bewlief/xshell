# ------------------------------------------
# Filename: xdev.sh
# Version:   0.1
# Date: 2021/05/26
# functions for development, including git, maven, gradle, etc
# ------------------------------------------

# 避免重复导入
[[ -n $__XLIB_IMPORTED__XDEV ]] && return 0
__XLIB_IMPORTED__XDEV=1

function __xdev_init__() {
    local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
    source "$script_dir/core.sh"

    import string
    import file
    import log
    import color

    # 设置常用的git/maven
    _git-common
    _maven-common
    _alias
}

function _alias() {
    alias pkg='mvn clean package -Dmaven.test.skip=true'
    alias pmd='mvn -q -f pom.xml -Dmaven.test.skip clean install'
    alias gwt='git worktree '
}

function _git-common() {
    alias gl='git log --color --graph --decorate -M --pretty=oneline --abbrev-commit -M'
    alias gls='git log --color --graph --decorate --pretty=oneline --abbrev-commit --all --simplify-by-decoration'
    alias gl1='git log --graph --color --pretty=format:"%C(yellow)%H%C(green)%d%C(reset)%n%x20%cd%n%x20%cn%C(blue)%x20(%ce)%x20%C(cyan)[gpg:%GK%x20%G?]%C(reset)%n%x20%s%n"'
    alias gc="git clone "
}

function _maven-common() {
    # alias
    alias mtree='mvn::tree -v -t'
    alias mpkg='mvn clean package -Dmaven.test.skip=true'
}

# 覆盖xbash-profile中的cdl，因xdev后导入，因此会覆盖之前的定义
function cdl() {
    # 将目录加入到PATH中
    # 与CPATH作比较，不同，则更新CPATH为当前目录并设置PATH
    local target="$1"
    if [[ $target != "-" ]]; then
        target=$(cygpath -u -a "$1")
        if [[ -n $target && ! $CPATH == "$target" ]]; then
            # 如果目录不存在于CPATH中，则加入到PATH中
            PATH::remove "${CPATH}"
            PATH::append "$target"
            export CPATH=$target
        fi
    fi

    cd "$@" && info "cd && ll $(pwd)"
    setPS1
    ls -lah --color=auto

    # 设置maven目录跳转的快捷方式
    [[ -s "pom.xml" ]] && {
        # 更新全局变量，标识当前maven项目的根目录
        export MAVEN_PROJECT_ROOT="$PWD"
        alias mh="info maven shortcuts: mh, mm, mj, mr, mt, mg"
        alias mm="cdl $MAVEN_PROJECT_ROOT"
        alias mj="cdl $MAVEN_PROJECT_ROOT/src/main/java"
        alias mr="cdl $MAVEN_PROJECT_ROOT/src/main/resources"
        alias mt="cdl $MAVEN_PROJECT_ROOT/src/test"
        alias mg="cdl $MAVEN_PROJECT_ROOT/target"
        alias ml="cdl last maven directory"

        info "mh->show help for maven shortcuts"
        info "mm->$MAVEN_PROJECT_ROOT, mj->/src/main/java, mr->/src/main/resource, mt->/src/test, mg->/target"
    }
}

# 设置dev下的命令行提示符PS1，检查PS1_GIT_STATUS
# 会覆盖xbash-profile中的已有定义
function setPS1() {
    local _normal_ps="$XLIB_DEFAULT_NORMAL_PS1"
    # gitRepo=$(git-repo)
    if [[ x"$PS1_GIT_STATUS" == x"true" ]]; then
        local _git_ps="$_normal_ps"
        # not using gir-repo, so that needn't import xos.sh by default
        # git@github.com:eugenp/tutorials.git
        # bitbucket: ssh://git@aaa.com:888/aaa/www.git
        # NOTE 此处不能使用 local gitRepo！
        # local gitRepo
        gitRepo=$(git remote -v 2>/dev/null | head -1 | awk -F" " '{print $2}')
        if [[ $gitRepo != "" ]]; then
            gitRepo=$(getGitRepoShort $gitRepo)
            #            echo "4. == $gitRepo =="
            # gitRepo=$(echo $gitRepo | awk -F'/' '{print $4"/"$5}')
            _git_ps="[\[\033[1;32m\]\w\[\033[0m\]] \[\033[0m\]\[\033[1;36m\]\$gitRepo (\$(git::target)) \[\033[0;31m\]\$(git::status)\[\033[0m\]$ "
        fi
        export PS1="$_git_ps"
        return 0
    fi
    export PS1="$_normal_ps"
}

#----------------- git -----------------#

# 被setPS1调用
function git::status() {
    local git_status=$(git status 2>/dev/null)
    local git_now="UNKNOWN -"

    case $git_status in
    *'not a git repository'*) git_now="NOT GIT -" ;;
    *'no changes added'*) git_now="CHANGED +" ;;
    *'have diverged'*) git_now="UNPUSHED +" ;;
    *'working tree clean'*) git_now="CLEAN -" ;;
    *'Changes to be committed'*) git_now="UNOMMITED +" ;;
    *'Changes not staged for commit'*) git_now="UNOMMITED +" ;;
    *'Untracked files'*) git_now="UNTRACKED +" ;;
    *'Your branch is behind'*) git_now="NEED REBASE" ;;
    *'Your branch is ahead of'*) git_now="AHEAD" ;;
    *'000'*) git_now="0000" ;;
    *'000'*) git_now="0000" ;;
    *'000'*) git_now="0000" ;;
    *'000'*) git_now="0000" ;;
    *) git_now="UNKNOWN -" ;;
    esac
    echo "${git_now} "
}

# default
# 获取repo的默认分支
function git::default() {
    local s=$(git remote show origin 2>&1 | \grep 'HEAD branch' | \cut -d ' ' -f5)
    if [[ ! "$s" =~ "fatal" ]]; then
        echo "$s"
    fi
}

# 添加、提交、push当前目录重得所有更新
function git::acp() {
    import date

    local now=$(date::now)
    local msg=${1:-"commit ./* @ $now"}

    # save commit msg to last_commit
    local last=$(file::absolute ".")
    last="$last/last_commit"
    echo "$msg" >"$last"

#    ui::banner "$(pwd)" "git add ." "git commit -m \"$msg\"" "git push"

    git add .
    git commit -m "$msg"
    git push
}

# git update in target directory
function git::au() {
    local old=$(pwd)

    if [[ $1 != "" ]]; then
        t1=$(dirname $1)
        cd $t1
        cur_dir="$(pwd)/$1"
    else
        cur_dir=$(pwd)
    fi
    info "git push $cur_dir"
    cd $cur_dir
    git status
    local d=$(date)
    local u=$(whoami)
    git add . && git commit -m "auto update: $u @ $d" && git push

    cd $old || die "faild to return origional directory"
}

# clone <git repo url:git@gitee.com:aaa> <target directory>
# git clone会自动创建相关目录
function git::clone() {
    local url="$1"
    local target="$2"

    #
    local cmd="git clone $url $target"

    local dummy=$($cmd 2>&1)
    echo $dummy
}

# 刷新当前目录或指定目录下的所有git 子目录
# refresh [target path]
function git::refresh() {
    local curr, d, k
    if [[ "$1" != "" ]]; then
        curr=$(pwd)
        info "refresh $curr/$1"
        cd "$curr/$1"
        # git checkout master
        git pull
        info "git pull $curr completed"
        cdl $curr
    else
        curr=$(pwd)
        info "refresh git repos in $curr"
        cd $curr
        echo ""
        for d in $(ls -d */); do
            k="$curr/$d"
            echo ">>>> $k"
            cd $k
            # git checkout develop
            git pull
            echo ""
        done
        info "git pull completed"
        cdl $curr
    fi
}

# todo rollback target branch, not completed
function git::rollback() {
    git stash clear && git reset --hard && git clean -xdf && git pull --rebase
}

# repo
# 获取当前git repo的url
function git::repo() {
    local repo=$(git remote -v 2>/dev/null | head -1 | awk -F" " '{print $2}')
    echo $repo
}

# branches
# 显示local和remote的分支列表
function git::branches() {
    git remote update origin -p >/dev/null 2>&1

    ui::banner "git::branches -> show local and remote branches"

    ui::figlet "local" "all branches on local and active branch"
    git branch

    ui::figlet "remote" "all branches on remote side"
    git branch -r
}

# getGitRepoShort <git-repo-url>
# 将repo url转换为短字符串
# git@github.com:bewlief/xops.git -> github
function getGitRepoShort() {
    #
    local remote="$1"
    local m2=($(string::split "$remote" ":"))

    local short=""
    if [[ "$remote" =~ "github" ]]; then
        short="github"
    elif [[ "$remote" =~ "gitee" ]]; then
        short="gitee"
    elif [[ "$remote" =~ "gitlab" ]]; then
        short="gitlab"
    elif [[ "$remote" =~ "bitbucket" ]]; then
        short="bitbucket"
    else
        short=$remote
    fi

    local total=${#m2[@]}
    ((total1 = $total - 1))

    local last=${m2[$total1]}
    last=${last%*".git"}

    local ma=($(string::split $last "/"))
    local tt=${#ma[@]}
    local repo=""
    if [[ $tt -eq 3 ]]; then
        repo="${ma[1]}/${ma[2]}"
    else
        repo=$last
    fi

    echo "$short: ${repo}"
}

# 当前的branch name
# git::target [target path]
function git::target() {
    local old="$PWD"
    if [[ -n $1 ]]; then
        cd "$1" || error "$1 invalud"
    fi
    local ref=$(git symbolic-ref HEAD 2>/dev/null) || return
    echo "${ref#refs/heads/}"
    cd $old
    setPS1
}

# 使用worktree初始化一个repo
# git::wt::init <repo url> <branch>
function git::wt::init() {
    local repo=$1
    local branch=$2

    git::worktree::init $repo $branch
}

# 在当前目录下初始化 worktree
# git::wt::init <repo url> <branch:dev,test,b1,b2>
function git::wt::init() {
    local repo=$1
    local branches=$2

    info "git worktree init" "$repo" "worktree: $branches"

    local dir="${repo##*/}"
    dir="${dir%.*}"
    echo "---> $dir"

    path::new $dir
    cd $dir || error "$dir: invalid"

    #
    git clone --bare $repo .bare
    echo "gitdir: ./.bare" >.git
    echo -e "\tfetch = +refs/heads/*:refs/remotes/origin/*" >>./.bare/config

    # 添加各branch
    local dd=($(string::split "$branches" ","))
    local d
    for d in "${dd[@]}"; do
        echo "worktree add $d"
        git worktree add $d
    done
}

function git::wt::add() {
    git worktree add $1
}
function git::wt::list() {
    echo "git worktree list"
}

#----------------- maven -----------------#

# clean *lastUpdate* in $HOME/.m2/
function mvn::clean() {
    local target=$1
    if [[ -z $target && -n $MAVEN_REPOSITORY ]]; then
        target=$MAVEN_REPOSITORY
    else
        target="$HOME/.m2/repository"
    fi
    info "clean non-updated dependencies in: $target"

    local file_types=(
        "_remote.repositories"
        "*.lastUpdated"
    )
    # find $target -name "_remote.repositories" -exec rm -rf {} \;
    # find $target -name "*.lastUpdated" -exec rm -rf {} \;

    local t

    for t in "${file_types[@]}"; do
        #        find $target -name "$t" -type f -print0 | xargs -0 rm -rf 2>/dev/null 1>/dev/null
        find $target -name "$t" -type f -print0 | xargs -0 rm -rf 2>/dev/null #1>/dev/null

        string::formatKeyValue $t "done"
    done

    # NOTE https://github.com/koalaman/shellcheck/wiki/SC2038
    # 使用xargs时，-print0, -0 可以正确处理非ascii名称的文件，及含空格的文件
    # 而-exec无需 -print0, -0 即可正确处理

    info "clean non-updated dependencies in $target/***: FINISHED"
}

# 修改settings.xml中的local repo path
function mvn::set-repo() {
    # set repo to $1
    mkdir -p "$1"
    local mvn_settings="$HOME/.m2/settings.xml"

    # todo 尚未完成！
}

# 对指定目录做 mvn clean
# mvn::package /d/www
function mvn::package() {
    _mvn-execute "$1" "package -Dmaven.test.skip=true"
}

function mvn::test() {
    _mvn-execute "$1" "test"
}

function mvn::check() {
    _mvn-execute "$1" "-Dmaven.test.skip=true install"
}

#
function mvn::install() {
    _mvn-execute "$1" "install -Dmaven.test.skip=true"
}

# 使用pmd扫描
function mvn::pmd() {
    _mvn-execute "$1" "-q -f pom.xml -Dmaven.test.skip=true clean install"
}

# _mvn-check-pom [mvn project path]
function _mvn-check-pom() {
    # 入参即为绝对路径
    local source=${1:-$(pwd)}
    source=$(file::absolute $source)
    if [[ -s "$source/pom.xml" ]]; then
        echo TRUE
    else
        echo FALSE
    fi
}

# 在source下运行mvn命令
# 会自动添加 clean
# _mvn-execute <mvn project path> <mvn command>
function _mvn-execute() {
    local cmd="$2"
    local source="${1:-$(pwd)}"
    source="$(file::absolute $source)"

    [[ $(_mvn-check-pom $source) == FALSE ]] && error "invalid maven project: $source" && return

    local pom="$source/pom.xml"

    #    declare -A commands
    #    commands=(
    #        ["test"]="clean test"
    #        ["package"]="clean package -Dmaven.test.skip=true"
    #        ["package-test"]="clean package"
    #        ["install"]="clean install -Dmaven.test.skip=true"
    #        ["install-test"]="clean install"
    #    )

    # todo check if cmd in commands
    #    local s=${commands[$cmd]}
    ui::figlet "M V N"
    ui::banner "Source: $source" "command: mvn clean $cmd"

    local OLD_PATH=$(pwd)

    cd "$source" || error "$source not existing"
    eval "mvn -f $pom clean $cmd"

    cd $OLD_PATH || error "$OLD_PATH"
    ui::banner "mvn clean $cmd completed"
}

# 从pom中获取artifactId等，存入数组中
# artifact <mvn project path> <bash array name>
function mvn::artifact() {
    local source=${1:-$PWD}
    source=$(file::absolute $source)

    local -n ref=$2

    #ref=(111 222 333)
    [[ $(_mvn-check-pom $source) == FALSE ]] && error "Invalid maven project: $source" && return

    local pom="$source/pom.xml"
    local s=$(mvn -f $pom -q -Dexec.executable=echo -Dexec.args='${project.groupId} ${project.artifactId} ${project.version}' --non-recursive exec:exec 2>/dev/null)
    string::split2 "$s" " " ref
}

# install-jar <mvn project path>
# 安装jar到mvn repository下
function mvn::install-jar() {
    import file

    local SOURCE=${1:-$(pwd)}
    SOURCE=$(file::absolute $SOURCE)
    [[ ! -d $SOURCE ]] && error "$SOURCE not existing" && return

    local OLD_PATH=$(pwd)
    echo "source: $SOURCE, now in: $OLD_PATH"

    local pom="pom.xml"

    cd "$SOURCE" || error "$SOURCE not existing now"
    if [[ -s "pom.xml" ]]; then
        # 获取pom中的group等
        local s=$(mvn -f $pom -q -Dexec.executable=echo -Dexec.args='${project.groupId} ${project.artifactId} ${project.version}' --non-recursive exec:exec 2>/dev/null)
        local dd=($(string::split "$s" " "))
        local groupId=${dd[0]}
        local artifactId=${dd[1]}
        local version=${dd[2]}

        echo "--- $artifactId, $groupId, $version"
        local jar="./target/${artifactId}-${version}.jar"
        if [[ -s "$jar" ]]; then
            echo "install to local repo"
            #  mvn install:install-file -DgroupId=$groupId -DartifactId=$artifactId -Dversion=$version -Dpackaging=jar -Dfile=./target/jj.jar
        else
            error "$jar not existing, please package firstly"
        fi

    fi

    cd $OLD_PATH
}

# 输出 dependency tree/effective-pom 到文件
# mvn::tree [-v] [-t] [-p]
# -v: -Dverbose, -t: tree, -p: pom
function mvn::tree() {
    import meta
    import file
    import string

    local SOURCE show_verbose do_tree do_pom
    local v
    show_verbose=""

    SOURCE=$(pwd)

    local s1=""

    # 解析入参
    eval "$(meta::getopts 'vtpf:')"
    if ((v)); then
        show_verbose="-Dverbose"
        s1+="$show_verbose"
    fi
    if ((t)); then
        do_tree=TRUE
        s1+=" dependency tree, "
    else
        do_tree=FALSE
    fi
    if ((p)); then
        do_pom=TRUE
        s1+=" effective POM"
    else
        do_pom=FALSE
    fi

    if [[ $do_tree == FALSE && $do_pom == FALSE ]]; then
        do_tree=TRUE
        do_pom=TRUE
        s1+=" dependency tree, effective POM"
    fi

    # todo assert xmllint existing
    [[ $(_mvn-check-pom $SOURCE) == FALSE ]] && error "invalid maven project: $SOURCE" && return

    local pom="pom.xml"

    # todo 直接读取pom文件，无法正确处理parent时的groupId
    local GROUP_ID=$(echo -e 'setns x=http://maven.apache.org/POM/4.0.0\ncat /x:project/x:groupId/text()' | xmllint --shell $pom | \grep -v /)
    local ARTIFACT_ID=$(echo -e 'setns x=http://maven.apache.org/POM/4.0.0\ncat /x:project/x:artifactId/text()' | xmllint --shell $pom | \grep -v /)
    local VERSION=$(echo -e 'setns x=http://maven.apache.org/POM/4.0.0\ncat /x:project/x:version/text()' | xmllint --shell $pom | \grep -v /)

    # 全局变量 TREE_ID 一个顺序号，文件标识，自动增长
    TREE_ID=${TREE_ID:-$(mvn::treeid "$ARTIFACT_ID")}

    ui::figlet "mvn tree" "mvn::tree: $s1"
    string::formatKeyValue "Source" $SOURCE
    string::formatKeyValue "GroupId" $GROUP_ID
    string::formatKeyValue "ArtifactId" $ARTIFACT_ID
    string::formatKeyValue "Version" $VERSION
    string::formatKeyValue "Sequence" $TREE_ID
    [[ -n $show_verbose ]] && string::formatKeyValue "Verbose" $show_verbose

    # XTEMP未设置时，在当前目录下创建文件
    local tmp=${XTEMP:-"$SOURCE"}

    local s1=${ARTIFACT_ID,,} # 小写
    local s2="$s1-$VERSION-$TREE_ID"

    # 更新 TREE_ID
    TREE_ID=$((TREE_ID + 1))
    echo "$TREE_ID" >"$TEMP/$ARTIFACT_ID"

    # 没有必要手动去创建相关目录，-Doutput会自动创建目录
    # 而 echo "dd" > a/b/c/1.log 则不会自动创建目录
    #    mkdir -p $tmp/$fname || error "failed to create $tmp/$fname"

    local tree_file="$tmp/mvn-tree/$s1/$s2.tree"
    local pom_file="$tmp/mvn-tree/$s1/$s2.pom.xml"

    s1=""
    if [[ $do_tree == TRUE ]]; then
        _mvn-execute "$SOURCE" "dependency:tree ${show_verbose} -DoutputFile=$tree_file"
        [[ -s $tree_file ]] && file::open $tree_file "$XLIB_EDITOR"
    fi
    if [[ $do_pom == TRUE ]]; then
        _mvn-execute "$SOURCE" "help:effective-pom ${show_verbose} -Doutput=$pom_file"
        [[ -s $pom_file ]] && file::open $pom_file "$XLIB_EDITOR"
    fi

    #    [[ $do_tree == TRUE ]] && _mvn-execute "$SOURCE" "dependency:tree ${show_verbose} -DoutputFile=$tree_file"
    #    [[ $do_pom == TRUE ]] && _mvn-execute "$SOURCE" "help:effective-pom ${show_verbose} -Doutput=$pom_file"

    ui::banner "mvn dependency/effective-pom end" "-> $tree_file" "-> $pom_file"
    ui::figlet "mvn tree DONE"

    cdl "$SOURCE"
}

#
function mvn::treeid() {
    local artifact=$1
    local tmp="$TEMP/$artifact"
    if [[ -e "$tmp" ]]; then
        local d=$(cat $tmp)
        echo $d
    else
        echo "1" >$tmp
        echo "1"
    fi
}

# 常用的mvn命令范例
function mvn::help() {
    ui::figlet "MVN  help"

    local help="$XLIB_BASE_CONFIG/mvn.help"

    # 直接原格式输出
    [[ -e $help ]] && cat "$help"
}
#----------------- gradle -----------------#

#----------------- java -----------------#

# _switchJdk /c/jdk/jdk11 true
function _switchJdk() {
    local type=$1
    if [[ "$type" == "" ]]; then
        type=$DEFAULT_JDK_VERSION
        warn "use default JDK version: $DEFAULT_JDK_VERSION"
    fi

    # inarray=$(echo ${!mapJdkPaths[@]} | \grep -o "$type" | wc -w)
    # if [[ $inarray != 1 ]]; then
    #     warn "no such version of jdk: $type, set to default $DEFAULT_JDK_VERSION"
    #     type=$DEFAULT_JDK_VERSION
    # fi

    local path=$type
    local msg=$path
    if [[ $path == "" ]]; then
        msg="path of $type not defined"
    fi

    # TODO 检查是否存在 /bin/java
    local JAVA_EXE
    if [[ $XOS == "WIN" ]]; then
        JAVA_EXE="$path/bin/java.exe"
    else
        JAVA_EXE="$path/bin/java"
    fi

    if [[ -f $JAVA_EXE ]]; then
        # remove old JAVA_HOME
        PATH::remove "$JAVA_HOME"

        # set JAVA_HOME to new path
        export JAVA_HOME=$path
        PATH::add "$JAVA_HOME/bin"
        PATH::dedup
        #        export PATH=$JAVA_HOME/bin:$MY_PATH:$ORIGIN_PATH
        # export PATH=$JAVA_HOME/bin:$MY_PATH:$ORIGIN_PATH:$SYSINTERNALS_ROOT

        # TODO: should check if existing
        local jshell="$JAVA_HOME/bin/jshell"
        [[ -x "$jshell" ]] && alias jshell="$jshell --startup $MY_BASH_HOME/start.jsh"
    else
        error "$JAVA_EXE not found"
    fi

    [[ "$2" == "true" ]] && {
        info "switch JDK to ${txtred}$type${txtrst}"
        string::repeat "-"
        java -version
        string::repeat "-"
    }
}

# 无参数：显示当前版本
# list： 列出当前可用的版本
# zulu11： 切换jdk
function jdk() {
    case "$1" in
    "list")
        _jdk-list true
        ;;
    "help")
        _jdk-help
        ;;
    "info")
        _jdk-info
        ;;
    *)
        _jdk-help
        ;;
    esac
}

function _jdk-help() {
    string::repeat "-"
    echo "Usage: ${txtgrn}jdk [list | info | help | {jdk-version}${txtrst}"
    echo "jdk: show usage"
    echo "jdk list: list available jdk vesions"
    echo "jdk info: show target jdk version"
    echo "jdk help: show usage"
    echo "jdk {jdk-version}: switch to target version"
    string::repeat "-"
}

function _jdk-info() {
    local ver=$(java -version 2>&1)

    string::repeat "-"
    echo "JAVA_HOME = $JAVA_HOME"
    echo "$ver"
    string::repeat "-"
}

# 获取可用的jdk版本类型，填充 jdkMap
function _jdk-list() {
    [[ -z "$JDK_ROOT" ]] && error "\$JDK_ROOT not set" && return 1

    local show="${1,,}"
    [[ "$show" == "true" ]] && info "Available jdk versions:"

    local dd kk s
    for dd in $JDK_ROOT/*; do
        if [[ -d $dd ]]; then
            kk=$(file::name "$dd")
            [[ "$show" == "true" ]] && printf "%-20s %-3s %s\n" "+ ${txtred}$kk${txtrst}" "->" "${txtcyn}$JDK_ROOT/$kk${txtrst}"

            local v="alias $kk=\"_switchJdk ${dd} true\""
            eval $v

            s+="$dd "

            # todo 设置默认的jdk为最新创建的jdk目录
            #            jdk_version=$dd
        fi
    done

    # Q 这样读取出来的数组元素，最后可能带有dos的换行符之类的(removeBrCr依然不行)，
    # 导致下面的 eval "alias jdk ..." 时报错
    # 突然出现的，奇怪得很！
    #    mapfile -t jdks < <(ls -F -t $JDK_ROOT | \grep '/$')
    #    local d s kk
    #    for kk in "${jdks[@]}"; do
    #        # ex:  /c/Users/xjming/xsoft/dev/sdk/jdk/jdk8/
    #        local kk_path="$JDK_ROOT/$kk"
    #        #        if [[ -d "$kk_path" ]]; then
    #        # ex: jdk11
    #        kk=${kk%*/}
    ##        [[ "$show" == "true" ]] && echo "+ ${txtred}$kk${txtrst} -> ${txtcyn}$JDK_ROOT/$kk${txtrst}"
    #
    #        # 创建对应的 alias，去掉了路径最后的 "/"
    #        local v="alias $kk='_switchJdk ${kk_path%/*} true'"
    #        eval "$v"
    #
    #        s+="$kk_path "
    #
    #        # 设置默认的jdk为最新创建的jdk目录
    #        jdk_version=$kk_path
    #    done

    # todo 导出所有的jdk目录列表： 有何用途？
    export JDK_LIST="$s"
}

__xdev_init__
