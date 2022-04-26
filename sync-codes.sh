script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
source "$script_dir/lib/core.sh"

import xdev
import string

function update() {
    local repo="$1"
    cd "$1" && git::au
    string::formatKeyValue "repo" "updated"
}

function main() {
    local code_root="$HOME/xcodes/xopensource"
    local gitee="$code_root/gitee"
    local github="$code_root/github"

    ui::banner "sync codes to my open source repos"

    update "$gitee/xjenkins"
    update "$gitee/xshell"
    update "$github/xjenkins"
    update "$github/xshell"
    update "$github/xcodes"
    update "$github/xops"

    ui::figlet "ALL DONE"
}

main
