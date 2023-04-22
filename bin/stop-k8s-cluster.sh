#/usr/local/bin/bash

SCRIPT_PATH=$(unset CDPATH && cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "${SCRIPT_PATH}/../lib/core.sh"

import string
import color
import xvmware


# ini="/c/Users/xjming/xcodes/xops/xshell/bin/vmx.ini"
stop-vm-group "$MY_VMWARE_GROUPS" "cluster"
