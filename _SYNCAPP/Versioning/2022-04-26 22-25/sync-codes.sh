script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
source "$script_dir/lib/core.sh"

import xdev
import string

function update() {
    local repo="$1"
    cd "$1" && git::au >/dev/null 2>&1
    string::formatKeyValue "$repo" "updated"
}

function main() {
    local aexe="/c/Users/xjming/xsoft/system/Allway Sync/Bin/syncappw.exe"
    local code_root="$HOME/xcodes/xopensource"
    local gitee="$code_root/gitee"
    local github="$code_root/github"
    local private_github="$code_root/private-github"

    ui::banner "sync codes to my open source repos"

    start "$aexe -s xjenkins, xshell, github -e"

    update "$gitee/xjenkins"
    update "$gitee/xshell"
    update "$github/xjenkins"
    update "$github/xshell"
    update "$private_github/xcodes"
    update "$private_github/xops"

    ui::figlet "ALL DONE"
}

main
