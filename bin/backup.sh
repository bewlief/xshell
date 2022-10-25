#/usr/local/bin/bash

#
# update all git repo codes
# 备份一天内更新的文件： find . -mtime -1 -type f -exec tar rvf "$archive.tar" '{}' \;
#
#pwd=$(cd `dirname $0` || exit; pwd)
SCRIPT_PATH=$(unset CDPATH && cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "${SCRIPT_PATH}/../lib/core.sh"

import string
import color

# target=$HOME/xcodes/axin-repos/docs/a11k
target="$MY_BACKUP"
info "clean: rm -rf ${target}/*"
rm -rf $target/*

info "start to backup all important files"
ui::hr "+"

# home of current user
export soft="$HOME/xsoft/w/"

#sourceFile=$1
#[[ ! -f $sourceFile ]] && die "cannot read from $sourceFile"
#mapfile -t files < $sourceFile

# file and dir to be backuped up
files=(
    "$HOME/.config"
    "$HOME/.docker/config.json"
    "$HOME/.docker/daemon.json"
    "$HOME/.gitconfig"
    "$HOME/.pip/pip.conf"
    "C:\Users\xjming\AppData\Roaming\pip\pip.ini"
    "$HOME/.bash_profile"
    "$HOME/.profile"
    "$HOME/.minttyrc"
    "$HOME/.tmux.conf"
    "$HOME/.sdirs"
    "$HOME/.ideavimrc"
    "$HOME/.minttyrc"
    "$HOME/.tmux.conf"
    "$HOME/.bashrc"
    "$HOME/.gitconfig"
    "$HOME/.ssh"
    "$HOME/.gradle/init.gradle"
    "$HOME/.m2/settings.xml"
    "$HOME/.m2/settings-security.xml"
    "$HOME/.m2/gradle.properties"
    "$HOME/.m2/settings.xml.proxyon"
    "$HOME/.m2/settings.xml.proxyoff"
    "$soft/sdk/jdk/jdk11/lib/security/cacerts"
    "$soft/sdk/jdk/jdk17/lib/security/cacerts"
    "$soft/sdk/jdk/jdk8/jre/lib/security/cacerts"
    "C:\Users\xjming\xsoft\dev\vscode\data\user-data\User\settings.json"
    "C:\Windows\System32\drivers\etc\hosts"
    "$HOME/xsoft/system/ConEmu/ConEmu.xml"
    "C:\Users\xjming\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    "$HOME/.ideavimrc"
    "$HOME/.vimrc"
    "$HOME/.viminfo"
    "C:\Users\xjming\xsoft\dev\JetBrains\go\bin\idea.properties"
    "C:\Users\xjming\xsoft\dev\JetBrains\go\bin\goland64.exe.vmoptions"
    "C:\Users\xjming\xsoft\dev\JetBrains\ideaIU64\bin\idea.properties"
    "C:\Users\xjming\xsoft\dev\JetBrains\ideaIU64\bin\idea64.exe.vmoptions"
    "C:\Users\xjming\xsoft\dev\JetBrains\idec\bin\idea.properties"
    "C:\Users\xjming\xsoft\dev\JetBrains\idec\bin\idea64C-review.exe.vmoptions"
    "/c/Users/xjming/AppData/Roaming/Sync App Settings/_SYNCAPP/default profile.xml"
    "/c/Users/xjming/AppData/Roaming/Sync App Settings/_SYNCAPP/default settings.xml"
    "C:\Users\xjming\xsoft\documents\Typora\resources\app.asar"
    "C:\Users\xjming\AppData\Roaming\Typora\conf\conf.user.json"
    "C:\Users\xjming\AppData\Roaming\Typora\themes\night.css"
    "C:\Users\xjming\xcodes\mycodes\.git\config"
    "C:\Users\xjming\xcodes\myhistory\.git\config"
    "C:\Users\xjming\xcodes\mypims\.git\config"
    "C:\Users\xjming\xcodes\myrepo\.git\config"
    "C:\Users\xjming\xcodes\xops\.git\config"
    "C:\Users\xjming\xopensource\xshell\.git\config"
    "C:\Users\xjming\xopensource\xjenkins\.git\config"
    "C:\Users\xjming\xsoft\documents\nppx64\config.xml"
    "C:\Users\xjming\xsoft\documents\nppx64\session.xml"
)

OLD_IFS="$IFS"
IFS=","

for f in "${files[@]}"; do
    if [[ ! -e $f ]]; then
        #        error "$f not existing"
        string::formatKeyValue $f "${txtylw}NOT EXISTING${txtrst}"
        continue
    fi

    # is a file
    if [[ -f $f ]]; then
        thisDir=$(dirname $f)
        thisDir=$(cygpath -u $thisDir)
        thisDir="$target/$thisDir"
        thisDir=$(cygpath -u $thisDir)
        thisDir=${thisDir//\/\//\/}

        thisFile=$(basename $f)
        targetFile="$thisDir/$thisFile"

        mkdir -p "$thisDir"
        cp -a $f $targetFile
        if [[ "$?" != "0" ]]; then
            error "$f: FAIELD"
        else
            string::formatKeyValue "$f" "${txtgrn}FINISHED${txtrst}"
        fi

    # is a directory
    elif [[ -d $f ]]; then
        # /d/test/1014/
        # handle last "/"
        d=$(dirname $f)
        d=$(cygpath -u $d)

        # echo "/$d" | sed 's/\\/\//g' | sed 's/://'

        # /d/test/1014
        targetDir="$target/$d"
        targetDir=$(cygpath -u $targetDir)
        targetDir=${targetDir//\/\//\/}
        # /d/download/1020/d/test
        # targetDir=$(dirname $targetDir)
        mkdir -p "$targetDir"
        $(cp -r "$f" $targetDir)
        if [[ "$?" != "0" ]]; then
            error "$f: ${txtred}FAIELD${txtrst}"
        else
            string::formatKeyValue "$f" "${txtgrn}FINISHED${txtrst}"
        fi
    fi

done

IFS="$OLD_IFS"

ui::hr "+"
showBlue "All files are backed up to ${undred}$target${txtrst}\n"
