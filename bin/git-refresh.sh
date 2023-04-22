#!/usr/bin/env bash

#------------------------------------------------
# git-refresh.sh
# 读取 config/repo.config，对指定的site
# 刷新指定类别下的repo
# git-refresh.sh 无参数时读取默认的配置
#   -c config/repo.config 指定配置文件
#   -s gitee,github 指定要刷新的site
#   -t shell,jenkins 指定要刷新的列别，多类别时,分割
#   -r /d/daaa 保存的目标目录
# git-refresh.sh -c $XTEMP/aa.config -s gitee,github -t shell,jenkins,java -r $XTEMP/aaa/bbb
# 需要把 aa.config, gitee.repo, github.repo等放在同一目录下
#------------------------------------------------

#set -Eeuo pipefail
trap cleanup SIGINT SIGTERM EXIT

function __git_refresh_init__() {
    [[ -s $XLIB_CORE ]] && source "$XLIB_CORE" || {
        local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
        source "$script_dir/../lib/core.sh"
    }

    import meta
    import string
    import xdev
    import ansi
    import file
    import log

    # 处理命令行的入参
    # c: repo config file
    # t: 要刷新的代码类别，如jenkins,shell
    # s: site，如github, gitee，需要在repo config中预先配置好其对应的host
    # r: 代码的存放路径
    # f: 是否强制刷新默认分支
    eval "$(meta::getopts 'c:t:s:r:f')"
    log::debug "getotps: config=$c, tags=$t, sites=$s, target=$r, refresh default branch=$f"

    # 代码要存放的根目录
    CODE_ROOT=${r:-$FREE_CODES}

    # repo.config文件路径
    REPO_CONFIG=${c:-"$GIT_REFRESH_CONFIG"}
    #    [[ -f $REPO_CONFIG ]] || error "no configuration file existing" && return 1

    # 要刷新的代码类别，默认为ALL
    TAGS=${t:-"all"}

    # 要刷新的site，需要和repo.config中的[host]匹配
    SITES=${s:-"all"}

    FORCE_REFRESH_BRANCH=${f:-"FALSE"}

    # repo.config所在路径，需要和*.repo在同一目录下
    repoConfigPath=$(file::parent $REPO_CONFIG)

    # ssh/http等命令的输出文件
    HTTP_FILE="$CODE_ROOT/http-clone.txt"
    SSH_FILE="$CODE_ROOT/ssh-clone.txt"
    REMOVED_REPO_FILE="$CODE_ROOT/removed-repos.txt"

    log::debug "arguments: CODE_ROOT=$CODE_ROOT, REPO_CONFIG=$REPO_CONFIG, TAGS=$TAGS, SITES=$SITES"
}

function cleanup() {
    trap - SIGINT SIGTERM ERR EXIT

    # script cleanup here
    unset CODE_ROOT REPO_CONFIG TAGS SITES repoConfigPath cates cateCount HTTP_FILE SSH_FILE REMOVED_REPO_FILE FORCE_REFRESH_BRANCH

    echo "."
}

# 显示相关的参数
function showConfig() {
    ui::figlet "g i t repo"
    local k
    local c

    string::repeat "="
    string::formatKeyValue "code root" "$CODE_ROOT"
    string::formatKeyValue "config" "$REPO_CONFIG"
    string::formatKeyValue "sites" "$SITES"
    string::formatKeyValue "tags" "$TAGS"

    string::repeat "."

    string::formatKeyValue "http commands" "$HTTP_FILE"
    string::formatKeyValue "ssh commands" "$SSH_FILE"
    string::formatKeyValue "remove repo file" "$REMOVED_REPO_FILE"

    string::repeat "="

}

# 初始化相关的输出文件
function initOutput() {
    file::new $HTTP_FILE
    file::new $SSH_FILE
    file::new $REMOVED_REPO_FILE

    echo "# GIT CLONE HTTP urls" >$HTTP_FILE
    echo "# GIT CLONE SSH urls" >$SSH_FILE
    echo "#### REMOVED GIT REPOS" >$REMOVED_REPO_FILE

    echo "export CODE_ROOT=$CODE_ROOT" >>$HTTP_FILE
    echo "export CODE_ROOT=$CODE_ROOT" >>$SSH_FILE
}

# 解析git操作后的结果
function parseResult() {
    local status=""
    local DUMMY=$(string::join " " "$@")
    local SKIPPED="SKIPPED"
    if [[ "$DUMMY" =~ "not a git repository" ]]; then
        status="$(ansi::red)NOT A GIT REPO"
    elif [[ "$DUMMY" =~ "Already up to date" ]]; then
        status="$(ansi::green)SKIPPED"
    elif [[ "$DUMMY" =~ "ERROR: Repository not found" ]]; then
        status="$(ansi::red)NOT FOUND"
    elif [[ "$DUMMY" =~ "Filename too long" ]]; then
        status="$(ansi::red)File name too long"
    elif [[ "$DUMMY" =~ "fatal" ]]; then
        status="$(ansi::red)FATAL"
    elif [[ "$DUMMY" =~ "not found" ]]; then
        status="$(ansi::red)REPO NOT FOUND"
    elif [[ "$DUMMY" =~ "Cloning into" ]]; then
        status="$(ansi::green)CLONED"
    elif [[ "$DUMMY" =~ "No update" ]]; then
        status="$(ansi::magenta)$SKIPPED"
    elif [[ "$DUMMY" =~ $SKIPPED ]]; then
        status="$(ansi::magenta)$SKIPPED"
    else
        status="$(ansi::green)UPDATED"
    fi

    echo "$status$(ansi::normal)"
}

# readRepos 1.repo jenkins a
function readRepos() {
    local CONFIG=$1
    local SECTION=$2
    local vv=($(sed -n '1,/'"\[$SECTION\]"'/d;/\[/,$d;/^$/d;p' "$CONFIG"))
    echo "${vv[@]}"
}

# 处理一个site
# handleGitSite <site:github>
function handleGitSite() {
    # ex: git
    local site=$1

    ui::figlet "$site"

    # 仅刷新输入的类目: -t shell,jenkins,java
    if [[ ${TAGS^^} == "ALL" ]]; then
        # 读取要刷新的repo一级目录，即 TAGS
        cates=($(string::ini::readIniItems $REPO_CONFIG "cates"))
    else
        cates=($(string::split "$TAGS" ","))
    fi

    log::debug "refresh: ${cates[*]}"

    local cate
    for cate in "${cates[@]}"; do
        handleGitCate "$site" "$cate"
    done
}

# 从gitee.repo中，读取 jenkins类别下的repo列表
# handleGitCate <site:github> <cate:shell>
function handleGitCate() {
    local site=$1
    local cate=$2
    log::debug "handlGitCate: $site, $cate"

    # *.repo 的路径，强制和 $REPO_CONFIG 在同一目录下
    local config="$repoConfigPath/$site.repo"

    echo "#$cate" >>$HTTP_FILE
    echo "#$cate" >>$SSH_FILE

    # 获取该目录下的所有repo，循环刷新
    local repos=($(string::ini::readIniItems $config "$cate"))
    repos=($(array::remove-dups "${repos[@]}"))
    log::debug "$cate --- ${repos[@]}"

    local count=${#repos[@]}
    log::debug "total $count in $cate: ${repos[@]}"
    if [[ $count -gt 0 ]]; then
        showCyan "$site - $cate"
        for repo in "${repos[@]}"; do
            log::debug "refresh $site, $cate, $repo"

            # 刷新远程的git repository
            handleGitRepo "$site" "$cate" "$repo"
        done
        string::repeat " "
    fi
}

# 获取site的git url前缀
# getHostPrefix <site> <author>
# 返回： git@github.com:author
function getHostPrefix() {
    local site="$1"
    local author="$2"

    local prefix=""

    # ex: git.com
    local host=${gitHosts[$site]}

    # todo 根据site获取其host地址，应直接从$REPO_CONFIG中读取过来
    # bitbucket: ssh://git@bitbucket.com/xjming/prj.git
    # github: git@github.com:xjming/prj.git
    if [[ $site == "" ]]; then # 针对bitbucket
        prefix="ssh://git@$host/$author"
    else
        prefix="git@$host:$author"
    fi

    echo $prefix
}

# 刷新一个git repo
# handleGitRepo <site:gitee> <cate:shell> <repo: aaa/bb | aaa/bb/default-branch>
function handleGitRepo() {
    log::debug ""
    local site=$1
    local cate=$2
    local repo=$3
    log::debug "handleGitRepo: $site, $cate, $repo"

    local GIT_REFRESH_FAILURE=120

    # split repo into author, project, default branch
    local t=($(string::split "$repo" "/"))
    local c=${#t[@]}
    if [[ $c -ge 2 || $c -eq 3 ]]; then
        local author=$(string::trim "${t[0]}")
        local project=$(string::trim "${t[1]}")
        local default_branch=$(string::trim "${t[2]}")
    else
        error "cannot refresh $site, $cate, $repo"
        return $GIT_REFRESH_FAILURE
    fi
    log::debug "refresh $repo ->[$author], [$project]: default branch=[$default_branch]"

    local hint="$author/$project"

    # 目标目录
    local target_path="$CODE_ROOT/$cate/$author/$project"
    log::debug "target: $target_path"

    # 生成ssh cmd等

    # github -> git@github.com:author
    local prefix=$(getHostPrefix "$site" "$author")
    log::debug "git url prefix: $prefix"

    # ex: git.com
    local host=${gitHosts[$site]}

    # 保存ssh/https命令到文件，便于直接shall去执行
    local ssh_cmd="git clone $prefix/$project.git $target_path"
    local http_cmd="git clone https://$host/$author/$project $target_path"
    local ssh_url="$prefix/$project.git"
    local http_url="https://$host/$author/$project"

    # 全部小写
    ssh_cmd=$(string::lower "$ssh_cmd")
    http_cmd=$(string::lower "$http_cmd")
    ssh_url=$(string::lower "$ssh_url")
    http_url=$(string::lower "$http_url")

    log::debug "ssh : $ssh_cmd"
    log::debug "http: $http_cmd"
    log::debug "ssh : $ssh_url"
    log::debug "http: $http_url"

    # git clone的结果
    local DUMMY=""

    local target_status=$(checkTargetStatus "$target_path")
    log::debug "target path status: $target_status"

    if [[ $target_status == "CLONE" ]]; then
        log::debug "no $target_path, git clone"
        # 输出clone命令到文件，以便它用
        echo "git clone $http_url $target_path" >>$HTTP_FILE
        echo "git clone $ssh_url $target_path" >>$SSH_FILE

        DUMMY=$(git::clone "$ssh_url" "$target_path")
        log::debug "git clone result: $DUMMY"

        # clone成功后保存当前分支，即默认分支
        # 无需检查 FORCE_REFRESH_BRANCH
        if [[ ! $DUMMY =~ "fatal" ]]; then
            saveBranchPath "$repoConfigPath/${site}.repo" "$author" "$project" "$target_path"
            show-status "$DUMMY"
            #            return 0
        fi
    fi

    if [[ $target_status == "PULL" ]]; then
        log::debug "$target_path existing, pull"

        cd $target_path || exit

        #
        local CURRENT_BRANCH=$(git::current)
        log::debug "$target_path -> [$CURRENT_BRANCH]"

        # stash当前分支的修改后，切换到默认分支
        # source_branch: 要刷新的分支，default/current之一
        local source_branch="$CURRENT_BRANCH"

        # 强制刷新默认分支
        local remote_default_branch
        if [[ $FORCE_REFRESH_BRANCH != "FALSE" ]]; then
            remote_default_branch=$(git::default)
            log::debug "current: $CURRENT_BRANCH, default: $default_branch, remote default: $remote_default_branch"

            if [[ $remote_default_branch != $default_branch ]]; then
                default_branch=$remote_default_branch
                saveBranchName "$repoConfigPath/${site}.repo" "$author" "$project" "$remote_default_branch"
            fi
        fi

        # todo 选择当前分支或默认分支，暂时不需要此功能，需要和saveBranch配合
        if [[ $default_branch != $CURRENT_BRANCH && $default_branch != "" ]]; then
            source_branch="$default_branch"
            log::debug "current: $CURRENT_BRANCH, default: $default_branch"
            # 做stash后切换
            DUMMY=$(
                git add . && git stash && git checkout $default_branch >/dev/null 2>&1
            )
        fi

        log::debug "default branch: [$default_branch], current: [$CURRENT_BRANCH], source: [$source_branch]"

        # NOTE 使用颜色会导致 formatKeyValue 不正常显示：右侧无法对齐
        # 因为颜色的长度也会被计入字符串总长度中！
        # 因此，hint中不显示branch，更新状态等
        # hint="$hint: ${txtgrn}$CURRENT_BRANCH${txtrst}"

        # 刷新下，否则无法获取远程的log hash
        git remote update origin -p >/dev/null 2>&1

        local LOCAL_LOG=$(git log $source_branch -n 1 --pretty=format:"%H")
        local REMOTE_LOG=$(git log remotes/origin/$source_branch -n 1 --pretty=format:"%H")

        log::debug "local : $LOCAL_LOG"
        log::debug "remote: $REMOTE_LOG"

        # 比较本地和远程的log hash
        if [[ "$LOCAL_LOG" == "$REMOTE_LOG" ]]; then
            DUMMY="No update, skip"
        else
            DUMMY=$(
                git stash clear && git reset --hard && git clean -xdf && git pull --rebase 2>&1
            )
        fi

        #
        hint="$hint:$source_branch"

        # pull完毕，切换回原先所在的分支
        if [[ $source_branch != "$CURRENT_BRANCH" ]]; then
            log::debug "switch back to $CURRENT_BRANCH"
            git checkout $CURRENT_BRANCH >/dev/null 2>&1
            git stash pop >/dev/null 2>&1
        fi

        show-status "$DUMMY"
        return 0
    fi
}

# todo remove this one after saveBranch1 ok
# saveBranch <repo file> <author> <project> <branch-name>
# ex: saveBranch "$repoConfigPath/${site}.repo" "$author" "$project" "$b"
# 更新默认分支到repo文件
function saveBranchName() {
    local repo="$1"
    local author="$2"
    local project="$3"
    local default="$4"

    # replace-all中的sed使用"/"作为分隔符，因此这里要转义
    local s1="$author\/$project\/$default"

    file::replaceAll "$repo" "^$author\/$project.*" "$s1"

    log::debug "save default branch: $repo, $author, $project, $default"
}

# saveBranch1 <repo file> <author> <project> <git path>
function saveBranchPath() {
    local repo="$1"
    local author="$2"
    local project="$3"
    local target="$4"

    local default=$(git::current $target)
    saveBranchName $repo $author $project $default

    #    # replace-all中的sed使用"/"作为分隔符，因此这里要转义
    #    local s1="$author\/$project\/$default"
    #
    #    file::replaceAll "$repo" "^$author\/$project.*" "$s1"
    #
    #    log::debug "save default branch: $repo, $author, $project, $default"
}

# gitClone <git url> <target path>
function gitClone() {
    local url="$1"
    local target="$2"

}

# 检查目标目录的状态
# 不存在 或 无git branch： CLONE
# 存在其有git branch： PULL
function checkTargetStatus() {
    local target="$1"
    local CLONE="CLONE"
    local PULL="PULL"

    local result="$PULL"

    if [[ ! -e $target ]]; then
        result=$CLONE
    fi

    if [[ -e $target ]]; then
        cd "$target" || error "invalid $target"
        local CURRENT_BRANCH=$(git::current)
        if [[ -z $CURRENT_BRANCH ]]; then
            rm -rf $target
#            rm -rf $target/* 2>&1
#            rm -rf $target/.git 2>&1
#            rm -rf $target/.github 2>&1
            result="$CLONE"
        fi
    fi

    echo "$result"
}

# 显示最后的结果
function show-status() {
    local DUMMY="$1"
    # 根据结果不同显示不同的信息
    # todo 需要优化！注意顺序，某些关键字有重复，
    #    DUMMY=$(string::join " " "${1[@]}")
    log::debug "result: $DUMMY"

    local status
    status=$(parseResult $DUMMY)

    string::formatKeyValue "$hint" "$status" "."
}

# 读取site的配置数据到map中: "github" -> "github.com"
declare -A -g gitHosts
function loadSitesConfig() {
    # 从 REPO_CONFIG 中读取 [hosts] 下配置的site=host
    local hosts=($(string::ini::readIniItems $REPO_CONFIG "hosts"))

    log::debug "load hosts config from $REPO_CONFIG -> ${hosts[@]}"

    local k v h
    for h in "${hosts[@]}"; do
        k="${h%%=*}"
        v="${h##*=}"
        gitHosts[$k]="$v"
        log::debug "gitHosts: $h -> $k=$v"
    done
}

function main() {
    # 打印参数：host，site，cates等
    showConfig

    #
    loadSitesConfig

    initOutput

    # 命令行传入了 -s：SITES
    local key host
    if [[ ${SITES^^} == "ALL" ]]; then
        for key in "${!gitHosts[@]}"; do
            host=${gitHosts[$key]}
            log::debug "-- handle site: $key -> $host"
            handleGitSite "$key"
        done
    else
        # 从配置文件读取的默认要处理的sites
        sites=($(string::split "$SITES" ","))

        local m
        for m in "${sites[@]}"; do
            handleGitSite "$m"
        done
    fi

}

# 解析参数
__git_refresh_init__ "$@"

#
main

ui::figlet "git cool"
