script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
source "$script_dir/lib/core.sh"

import xdev
import string

dbs_root="$HOME/xcodes/github"
x1="$dbs_root/mycodes"
x2="$dbs_root/xops"

ui::banner "update codes for dbs" "-> $x1" "-> $x2"

cd $x1 && git::au
cd $x2 && git::au

ui::figlet "ALL DONE"
