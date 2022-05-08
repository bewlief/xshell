script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
source "$script_dir/lib/core.sh"

import xdev
import string
import file

function gitUpdate() {
    local repo="$1"
    cd "$1" && git::au # >/dev/null 2>&1
    ui::banner "$repo updated"
}

function syncFiles() {
    # ecp xtmp temp/r1 //E //XD xshell java
    # ecp xtmp temp/r1 //E //XD xshell java //XF *.sh *.java *.md
    local source="$1"
    local target="$2"
    local exclude="$3"

    # 强制排除的文件或目录
    local s=".git,.idea,.vscode,*xjming*,*/target/*"
    exclude="$s,$exclude"

    ui::banner "$source -> $target" "exclude: $s"

    path::sync $source $target -x "$exclude" -p
}

function main() {
    local code_root="$HOME/xcodes/xopensource"
    local gitee="$code_root/gitee"
    local github="$code_root/github"
    local private_github="$code_root/private-github"

    ui::banner "sync codes to my open source repos"

    local xshellExclude="test,common-used"
    local xjenkinsExclude="casc-zna,jenkins-client-java,jenkinsrunner,jkmgmt,sbd"

    # sync files
    syncFiles "$HOME/xcodes/xops/xshell" "$gitee/xshell" "$xshellExclude"
    syncFiles "$HOME/xcodes/xops/jenkins" "$gitee/xjenkins" "$xjenkinsExclude"
    syncFiles "$HOME/xcodes/xops/xshell" "$github/xshell" "$xshellExclude"
    syncFiles "$HOME/xcodes/xops/jenkins" "$github/xjenkins" "$xjenkinsExclude"

    syncFiles "$HOME/xcodes/xops" "$private_github/myops"
    syncFiles "$HOME/xcodes/mycodes" "$private_github/xcodes"

    # git commit & push
    gitUpdate "$gitee/xjenkins"
    gitUpdate "$gitee/xshell"
    gitUpdate "$github/xjenkins"
    gitUpdate "$github/xshell"
    gitUpdate "$private_github/mycodes"
    gitUpdate "$private_github/xops"

    gitUpdate "$HOME/xcodes/xops"
    gitUpdate "$HOME/xcodes/mycodes"

    ui::figlet "ALL DONE"
}

main
