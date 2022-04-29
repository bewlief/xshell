# ------------------------------------------
# Filename: file.sh
# Version:   0.1
# Date: 2022/01/07
# note:
#   functions for file opration
# ------------------------------------------

# 避免重复导入
[[ -n $__XLIB_IMPORTED__FILE ]] && return 0
__XLIB_IMPORTED__FILE=1

function __file_init__() {
    # 引入core.sh
    [[ -s $XLIB_CORE ]] && source "$XLIB_CORE" || {
        local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
        source "$script_dir/core.sh"
    }

    # 文件系统错误代码
    readonly FILE_NOT_FOUND=100
    readonly FILE_NOT_EXECUTEABLE=101
    readonly FILE_CREATE_FAILURE=102
}

# 文件数量
# count ~/*; count $HOME/test/; count $HOME/test/*.sh
function file::count() {
    printf '%s\n' "$#"
}

# trap 'printf \\e[2J\\e[H\\e[m' EXIT

# NOTE 使用nameref读取文件到数组
# read-file file1 mm
# for v in "${mm[@]}" ...
#
# 注意，在消费完 $mm 后，最好unset掉！
function file::read() {
    local source=$1
    local -n arr=$2
    local k1 k2

    # todo mapfile如何自动去掉换行和断行？
    mapfile -t arr <$source
    for kk in "${t[@]}"; do
        # while read 无法正确处理windows的路径，去掉了"\": c:\ww\nn -> c:wwnn
        # 而 mapfile 是可以正确处理的！
        #    while read kk; do
        # 去掉断行和换行 todo 貌似不大好用？
        k1=$(echo $kk | sed 's/\\r//' | sed 's/\\n//')
        k2=$(echo "$k1" | awk '{gsub(/^ +| +$/,"")} {print $0}')
        arr+=("$k2")
        #    done <$source  # while read ... done < $source
    done
}

# check if a command existing in $PATH
function file::exist() {
    local cmd="$1"
    [[ -z "$cmd" ]] && {
        error "Usage: exist cmd"
        return $INVALID_ARGUMENTS
    }

    # command -v "$@" >/dev/null 2>&1
    local f=$(command -v $1)
    [[ $f != "" ]] && echo "$1: $f" || return $FILE_NOT_FOUND

    #    if [[ $f != "" ]]; then
    #        echo "$1: $f"
    #    else
    #        return $NOT_FOUND
    #    fi

    # if type -p command &>/dev/null then
    #       echo "in path"
    # fi

    # hash command &>/dev/null
}

# 创建指定的文件
function file::new() {
    [[ -z $1 ]] && error "INVALID_ARGUMENTS" && return 1

    local file=$(cygpath -u "$1")
    local basename=$(basename $file)

    local p=$(file::parent $file)

    path::new $p && touch "$p/$basename"
}

# 创建新目录
function path::new() {
    local path=$(cygpath -u "$1")
    mkdir -p "$path" || return $FILE_CREATE_FAILURE
}

# 获取指定文件的parent目录的绝对路径，即使文件不存在
function file::parent() {
    local file=$(cygpath -a "$1")
    echo $(dirname "$file")
}

# 调用 $1 $@
function file::execute() {
    local cmd=$1
    shift
    # NOTE 注意此处的true/false判断
    if command -v -- "$cmd" &>/dev/null; then
        "$cmd" "$@"
    else
        error "Function '$cmd' not implemented"
    fi
}

# 使用指定的editor打开文件
# open <file> <editor>
# todo 设置一个全局变量 EDITOR
function file::open() {
    local file=$1
    local editor=$2
    local s="$editor $file"
    [[ -s $file ]] && eval "$s"
}

# fullName <file>
# 文件的带绝对路径的name
function file::fullName() {
    echo $(file::absolute "$1")
}

# name <file or path>
# 文件的全名称: 名称+扩展名 aa/cc.log -> cc.log，不含路径
# https://www.cnblogs.com/yanwei-wang/p/8135489.html
function file::name() {
    local file=$1
    # using echo to return values
    #  echo ${file%.*}
    echo "$(basename $file)"
}

# baseName <file>
# 获取去掉最后一个ext后的文件名，不含路径
# aa/bb/cc.pom.xml -> cc.pom
function file::baseName() {
    local file="$1"
    local s=$(\basename $file)
    echo "${s%.*}"
}

# lastExt <file>
# 获取文件扩展名的最后一段
# a.b.c -> c
function file::lastExt() {
    local file=$1
    echo "${file##*.}"
    return 1
}

# fullExt <file>
# 除文件名之外的所有ext的字段，不含路径
# a.b.c -> b.c
function file::ext() {
    local file=$1
    echo "${file#*.}"
}

# 获取文件/目录的绝对路径
function file::absolute() {
    # cygpath 最简单
    [[ -n $1 ]] && cygpath -a "$1"

    #    local path=$(cygpath -u "$1")
    #
    #    local fileName=$(basename $1)
    #    local parentPath=$(dirname $1)
    #
    #    # 已存在的路径
    #    if [[ -d "$path" ]]; then
    #        local abs_path_dir
    #        abs_path_dir="$(cd "$path" && pwd)"
    #        echo "${abs_path_dir}"
    #    else # 文件或尚不存在的路径
    #        local parent="$path"
    #        # =0时，最左非 "/"，设置当前目录为"/"
    ##        if [[ $(string::startWith "$path" "/") -eq 0 ]]; then
    #        if string::startWith "$path" "/"; then
    #            parent="$PWD/$path"
    #        fi
    #        echo "$parent"
    #    fi
}

# replaceLine <file> <old> <new>
# 替换文件中的字符串
function file::replaceAll() {
    if [ $# -ne 3 ]; then
        msg "ERROR" "Usage:replaceLine searchStr replaceStr filename"
    fi

    local searchStr="$2"
    local replaceStr="$3"
    local filename="$1"

    if [ ! -f ${filename} ]; then
        error "ERROR" "The file of ${filename} is not existing, please check."
    fi

    # 为何把 . 替换为 \. ？？？
    #    searchStr=$(echo "${searchStr}" | sed -e 's/\[/\\[/g' -e 's/\]/\\]/g' -e 's/\./\\./g')
    searchStr=$(echo "${searchStr}" | sed -e 's/\[/\\[/g' -e 's/\]/\\]/g')

    # 是否包含
    local strline=$(sed -n "/${searchStr}/=" ${filename})

    # 包含则全部替换
    if [[ -n "${strline}" ]]; then
        # -i: 不使用临时文件，直接操作源文件
        sed -i -e "s/${searchStr}/${replaceStr}/g" ${filename}
        return 0
    else
        error "ERROR" "Replace parameter of ${searchStr} at ${filename} file failed."
        return 1
    fi
}

# repladeLine2 <file> <start string> <end string> <old> <new>
function string::replace-between() {
    if [ $# -ne 5 ]; then
        prompt_msg "ERROR" "Usage:replaceLine2 startStr endStr searchStr replaceStr filename."
    fi

    local startStr=$2
    local endStr=$3
    local searchStr=$4
    local replaceStr=$5
    local filename=$1

    if [ ! -f ${filename} ]; then
        prompt_msg "ERROR" "The file of ${filename} is not exist,please check."
    fi

    ##transfer input startstr,endstr and searchstr
    startStr=$(echo ${startStr} | sed -e 's/\[/\\[/g' -e 's/\]/\\]/g' -e 's/\./\\./g')
    endStr=$(echo ${endStr} | sed -e 's/\[/\\[/g' -e 's/\]/\\]/g' -e 's/\./\\./g')
    searchStr=$(echo ${searchStr} | sed -e 's/\[/\\[/g' -e 's/\]/\\]/g' -e 's/\./\\./g')

    local startline=$(sed -n "/${startStr}/=" ${filename})
    local endline=$(sed -n "/${endStr}/=" ${filename})

    if [ "X${startline}" != "X" -a "X${endline}" != "X" ]; then
        strline=$(sed -n "/${startline}/,/${endline}/{/${searchStr}/=}" ${filename})
        if [ "X${strline}" != "X" ]; then
            sed -i "$startline,${endline}s/${searchStr}/${replaceStr}/g" ${filename}
            info "INFO" "Replace parameter of ${searchStr} at ${filename} file success."
            return 0
        fi
    fi

    error "ERROR" "Replace parameter of ${searchStr} at ${filename} file failed."
    return 1
}

# 解析相对路径
function path::relative() {
    # shellcheck disable=SC2016
    local __doc__='
    Computes relative path from $1 to $2.
    Taken from http://stackoverflow.com/a/12498485/2972353

    >>> core_rel_path "/A/B/C" "/A"
    ../..
    >>> core_rel_path "/A/B/C" "/A/B"
    ..
    >>> core_rel_path "/A/B/C" "/A/B/C/D"
    D
    >>> core_rel_path "/A/B/C" "/A/B/C/D/E"
    D/E
    >>> core_rel_path "/A/B/C" "/A/B/D"
    ../D
    >>> core_rel_path "/A/B/C" "/A/B/D/E"
    ../D/E
    >>> core_rel_path "/A/B/C" "/A/D"
    ../../D
    >>> core_rel_path "/A/B/C" "/A/D/E"
    ../../D/E
    >>> core_rel_path "/A/B/C" "/D/E/F"
    ../../../D/E/F
    >>> core_rel_path "/" "/"
    .
    >>> core_rel_path "/A/B/C" "/A/B/C"
    .
    >>> core_rel_path "/A/B/C" "/"
    ../../../
    '
    # both $1 and $2 are absolute paths beginning with /
    # returns relative path to $2/$target from $1/$source
    local source="$1"
    local target="$2"
    if [[ "$source" == "$target" ]]; then
        echo "."
        return
    fi

    local common_part="$source" # for now
    local result=""             # for now

    while [[ "${target#$common_part}" == "${target}" ]]; do
        # no match, means that candidate common part is not correct
        # go up one level (reduce common part)
        common_part="$(dirname "$common_part")"
        # and record that we went back, with correct / handling
        if [[ -z $result ]]; then
            result=".."
        else
            result="../$result"
        fi
    done

    if [[ $common_part == "/" ]]; then
        # special case for root (no common path)
        result="$result/"
    fi

    # since we now have identified the common part,
    # compute the non-common part
    local forward_part="${target#$common_part}"

    # and now stick all parts together
    if [[ -n $result ]] && [[ -n $forward_part ]]; then
        result="$result$forward_part"
    elif [[ -n $forward_part ]]; then
        # extra slash removal
        result="${forward_part:1}"
    fi
    echo "$result"
}

# 获取已有文件或目录的父级目录的绝对路径，最后带上 "/"
#function file::parent() {
#    local base_path="$1"
#    local a=$(file::absolute $base_path)
#    echo $(dirname $a)
#
# 以下为原来的实现方式
# use the containing directory when --base-path is a file
#    if [[ ! -d "$base_path" ]]; then
#        base_path="$(dirname "$base_path")"
#    fi
# get the absolute path
#    base_path="$(cd "$base_path" && pwd)"
# ensure the path ends with / to strip that later on
#    if [[ "${base_path}" != *"/" ]]; then
#        base_path="$base_path/"
#    fi
#    echo "$base_path"
#}

# 一次创建多个目录
function path::mk() {
    local dir fails=0 failed_dirs=()
    for dir; do
        mkdir -p -- "$dir"
        if (($? != 0)); then
            ((fails++))
            failed_dirs+=("$dir")
        fi
    done
    if ((fails == 1)); then
        error "Couldn't create directory '${failed_dirs[0]}'"
    elif ((fails > 1)); then
        error "Couldn't create these directories: ${failed_dirs[@]}"
    fi
    return 0
}

# read yaml file
# eval $(parse_yaml zconfig.yml "config_")

# access yaml content
# echo $config_development_database
# echo $config_development_address_add1
function file::parse_yaml() {
    local prefix=$2
    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @ | tr @ '\034')
    sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" $1 |
        awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

# Given a directory name (like .hg or .git) look through the pwd for such a repo
function file::find-repo() {
    local dir="$PWD" repoMarker="${1:?Must specify the marker that indicates a repo}"
    until [[ -z "$dir" ]]; do
        if [[ -e "$dir/$repoMarker" ]]; then
            echo "$dir"
            return
        fi
        dir="${dir%/*}"
    done
    return 1
}

#@public
function file::unix2dos() {
    local input="$1"
    local output="$2"

    type unix2dos >/dev/null 2>&1 && {
        function unix2dos() { command unix2dos; }
    } || {
        function unix2dos() { sed "s/$/\r/"; }
    }

    (test -n "$input" && cat "$input" || cat) |
        unix2dos | (test -n "$output" && cat >"$output" || cat)

    unset unix2dos
}

#@public
function file::dos2unix() {
    local input="$1"
    local output="$2"

    type dos2unix >/dev/null 2>&1 && {
        function dos2unix() { command dos2unix; }
    } || {
        function dos2unix() { tr -d "\r"; }
    }

    (test -n "$input" && cat "$input" || cat) |
        dos2unix | (test -n "$output" && cat >"$output" || cat)

    unset dos2unix
}

function file::removeBom() {
    local bomFile=$(grep -I -l $'^xEFxBBxBF' $1)
    if [[ x$1 == x$bomFile ]]; then
        # has BOM
        sed -i 's/xEFxBBxBF//' $1
        echo BOM removed by file: $1
    fi
}

# 同步文件夹
# sync <source path> <target path> [-x "*.sh,*.md"] [-i "gl.ini"] [-p]
# sync <source path> <target path> [-x "ex.file"] [-i "in.file"] [-p]
# -x: 要排除的目录名称列表
# -i: 要包含的文件类型
# -p: 是否purge，即删除source中不存在的文件
# 单独的列表和excludeFrom/includeFrom不能混用！
function file::sync() {
    import meta

    local source="$1"
    local target="$2"
    echo "source=$source, target=$target"
    shift 2

    eval "$(meta::getopts 'X:I:x:i:p')"

    # exclude的文件类型
    local excludeFiles="${x:-}"
    local excludeFrom="${X:-}"

    # exclude的目录
    local includeFiles="${i:-}"
    local includeFrom="${I:-}"

    # todo 检查 xX,iI是否同时存在

    local s
    s="rsync -a $source/ $target "

    # 是否 purge，默认是
    local purge="${p:-1}"
    if [[ $purge -eq 1 ]]; then
        s+="--delete "
    fi

# rsync -a --delete --exclude="*.txt" --exclude=".*" source/ destination : 把source/下的内容被分到dest
# rsync -a source dest：则是备份到 dest/source下了
# --exclude={'file1.txt','dir1/*'}
# --exclude-from='exclude-file.txt'
#  --include="*.txt"

    if [[ -n $includeFiles ]]; then
        local dd=($(string::split $includeFiles ","))
        local d
        for d in "${dd[@]}"; do
            s+="--include=\"$d\" "
        done
    fi
    if [[ -n $excludeFiles ]]; then
        local dd=($(string::split $excludeFiles ","))
        local d
        for d in "${dd[@]}"; do
            s+="--exclude=\"$d\" "
        done
    fi

    if [[ -n $excludeFrom ]]; then
        s+="--excludeFrom=\"$excludeFrom\" "
    fi
    if [[ -n $includeFrom ]]; then
        s+="--includeFrom=\"$includeFrom\" "
    fi

    echo "==== $s"
    eval "$s --progress"
}

# extract <compressed-file> [target directory]
# todo 需要完善指定目录的功能
function file::extract() {
    if [ -f $1 ]; then
        case $1 in
        *.tar.bz2) tar xjf $1 ;;
        *.tar.gz) tar xzf $1 ;;
        *.bz2) bunzip2 $1 ;;
        *.rar) unrar e $1 ;;
        *.gz) gunzip $1 ;;
        *.tar) tar xf $1 ;;
        *.tbz2) tar xjf $1 ;;
        *.tgz) tar xzf $1 ;;
        *.zip) unzip $1 ;;
        *.Z) uncompress $1 ;;
        *.7z) 7z x $1 ;;
        *) echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# targz <target file name> <file list>
function file::targz() {
    local target="$1"
    shift

    #    local tmpFile="${@%/}.tar"
    local tmpFile="$(string::randomq).tar"

    # todo 需要一个默认排除文件的设置
    local _exclude=".DS_Store"
    tar -cvf "${tmpFile}" --exclude="$_exclude" "${@}" || return 1

    size=$(
        stat -f"%z" "${tmpFile}" 2>/dev/null # macOS `stat`
        stat -c"%s" "${tmpFile}" 2>/dev/null # GNU `stat`
    )

    local cmd=""
    if ((size < 52428800)) && hash zopfli 2>/dev/null; then
        # the .tar file is smaller than 50 MB and Zopfli is available; use it
        cmd="zopfli"
    else
        if hash pigz 2>/dev/null; then
            cmd="pigz"
        else
            cmd="gzip"
        fi
    fi

    echo "Compressing .tar ($((size / 1000)) kB) using \`${cmd}\`…"
    "${cmd}" -v "${tmpFile}" || return 1
    [[ -f "${tmpFile}" ]] && rm "${tmpFile}"

    zippedSize=$(
        stat -f"%z" "${tmpFile}.gz" 2>/dev/null # macOS `stat`
        stat -c"%s" "${tmpFile}.gz" 2>/dev/null # GNU `stat`
    )

    # todo 计算耗时

    ui::banner "${tmpFile}.gz ($((zippedSize / 1000)) kB) created successfully." "${@}"
}

# 获取文件或目录的大小
function file::size() {
    if du -b /dev/null >/dev/null 2>&1; then
        local arg=-sbh
    else
        local arg=-sh
    fi

    if [[ -n "$@" ]]; then
        du $arg -- "$@"
    else
        du $arg ./*
    fi
}

# 使用gzip压缩到base64
# encode <source> <target>
function file::encode() {
    if [[ -f $1 ]]; then
        local tmp="$TEMP/$(string::random)-$$"
        gzip -c -n "$1" | base64 >$tmp
        cp $tmp $2
        info "$1 encode to $2"
    fi
}

# 从base64文件还原
# decode <compress file> <target file>
function file::decode() {
    local tmpFile="$TEMP/$(string::random)-$$"
    cat "$1" | base64 -d >$tmpFile
    gzip -c -d -n "$tmpFile" >$2
    info "$1 decode to $2"
}

__file_init__
