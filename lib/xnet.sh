# ------------------------------------------
# Filename: xnet.sh
# Version:   0.1
# Date: 2021/12/07
# note:
#   functions for network
# ------------------------------------------

# 避免重复导入
[[ -n $__XLIB_IMPORTED__XNET ]] && return 0
__XLIB_IMPORTED__XNET=1

function __xnet_init__() {
    # 引入core.sh
    [[ -s $XLIB_CORE ]] && source "$XLIB_CORE" || {
        local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
        source "$script_dir/core.sh"
    }

    # IP addresses
    alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
    alias localip="ipconfig getifaddr en0"
    alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

    # Show active network interfaces
    alias ifactive="ifconfig | pcregrep -M -o '^[^\t:]+:([^\n]|\n\t)*status: active'"

    net::setup-proxy
}

# 配置命令行的proxy
# todo 依赖于xbash-profile中导入的global.ini，需解耦！
# setup-proxy <proxy user> <proxy pass> <proxy url> <no proxy list>
function net::setup-proxy() {
    # proxy的密码中需要转义的特殊字符
    # ~: 0x7e
    # !: 0x21：无需转义
    # @: 0x40
    # #: 0x23
    # $: 0x24
    # %: 0x25
    # ^: 0x5e
    # &: 0x26
    # *: 0x2a
    # ?: 0x3F
    # todo 试一下全部都encode后是否可用！
    # export PROXY_PASS="pass0x7e23K0x25"

    #     export PROXY_URL="aa.com:8088"
    if [[ "${PROXY_ENABLED^^}" == "TRUE" && -n $PROXY_USER && -n $PROXY_PASS ]]; then
        local s="$PROXY_USER:$PROXY_PASS"
        # http://，而不是 https://
        export HTTP_PROXY="http://$s@$PROXY_URL"
        export HTTPS_PROXY="http://$s@$PROXY_URL"

        # 多个地址用","分隔，aa.com，则匹配*.aa.com
        export NO_PROXY=$NO_PROXY_HOST
    else
        echo "proxy disabled"
        unset HTTP_PROXY
        unset HTTPS_PROXY
        unset NO_PROXY
        unset PROXY_URL
        unset PROXY_USER
        unset PROXY_PASS
        unset NO_PROXY_HOST
    fi
}

# todo need implment for win
function net::getNetworkStatus() {
    echo ""
    if [[ $centosVersion -lt 7 ]]; then
        /sbin/ifconfig -a | \grep -v packets | \grep -v collisions | \grep -v inet6
    else
        #ip a
        for i in $(ip link | \grep BROADCAST | awk -F: '{print $2}'); do
            ip add show $i | \grep -E "BROADCAST|global" | awk '{print $2}' | tr '\n' ' '
            echo ""
        done
    fi
    GATEWAY=$(ip route | \grep default | awk '{print $3}')
    DNS=$(\grep nameserver /etc/resolv.conf | \grep -v "#" | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')
    echo ""
    echo "网关：$GATEWAY "
    echo "DNS：$DNS"
    #报表信息
    IP=$(ip -f inet addr | grep -v 127.0.0.1 | \grep inet | awk '{print $NF,$2}' | tr '\n' ',' | sed 's/,$//')
    MAC=$(ip link | \grep -v "LOOPBACK\|loopback" | awk '{print $2}' | sed 'N;s/\n//' | tr '\n' ',' | sed 's/,$//')
    report_IP="$IP"
    report_MAC=$MAC
    report_Gateway="$GATEWAY"
    report_DNS="$DNS"
    echo ""
    ping -c 4 www.baidu.com >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "网络连接：正常"
    else
        echo "网络连接：异常"
    fi
}

# 验证IPv4地址的有效性
# 参数：IPv4地址
# 返回值：0 表示有效，1 表示无效
function net::validate-ip4() {
    local arr element
    # 以"."为分隔符分隔到数组中
    IFS=. read -r -a arr <<<"$1"
    [[ ${#arr[@]} != 4 ]] && return 1
    for element in "${arr[@]}"; do
        [[ (! $element =~ ^[0-9]+$) ||
            $element =~ ^0[1-9]+$ ]] &&
            return 1
        ((element < 0 || element > 255)) && return 1
    done
    return 0
}

#
# check if URL is valid.  Credit: https://stackoverflow.com/a/12199125/6862601
# 需检查 $? 确定是否可访问
function net::validate-url() {
    #    assert_arg_count $# 1 "is_valid_url: expected 1 argument, got $#"
    curl --output /dev/null --silent --head --fail "$1"
}

function net::is_valid_url_no_head() {
    #    assert_arg_count $# 1 "is_valid_url_no_head: expected 1 argument, got $#"
    curl --output /dev/null --silent --fail -r 0-0 "$1"
}

function net::set-ip() {
    local ip=$1

    # Check if IP address is valid
    if [[ ! $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid IP address: $ip"
        return 1
    fi

    # Check if hostname is valid
    if [[ ! $hostname =~ ^[a-zA-Z0-9\-]+$ ]]; then
        echo "Invalid hostname: $hostname"
        return 1
    fi

    echo "set ip to $1, hostname to $2, and add DNS"

    # Get the name of the current network interface
    iface=$(ip link | awk '/state UP/{print $2}' | sed 's/://')

    # Get the current configuration file for the network interface
    # Red Hat / CentOS / Fedora: /etc/sysconfig/network-scripts/ifcfg-<interface>
    # Debian / Ubuntu: /etc/network/interfaces
    # Arch Linux: /etc/netctl/<profile>
    # openSUSE: /etc/sysconfig/network/ifcfg-<interface>

    cfg_file=$(ls /etc/sysconfig/network-scripts/ifcfg-$iface 2>/dev/null)

    # If the configuration file exists, modify it
    if [[ -n "$cfg_file" ]]; then
        echo "Modifying $cfg_file"

        # Replace the current IP address with a new one (e.g., 192.168.1.100)
        sed -i "s/^IPADDR=.*/IPADDR=$1/" "$cfg_file"

        # Add a new DNS server (e.g., 8.8.8.8)
        #echo "DNS1=8.8.8.8" >> "$cfg_file"

        # Update BOOTPROTO to static
        sed -i 's/^BOOTPROTO=.*/BOOTPROTO=static/' "$cfg_file"
        sed -i 's/^ONBOOT=no/ONBOOT=yes/g' "${cfg_file}"

        # Change the hostname to a specific value (e.g., myhost)
        hostnamectl set-hostname "$2"

        # Restart the network service to apply the changes
        systemctl restart NetworkManager
    else
        echo "Configuration file for $iface not found"
    fi

}
__xnet_init__
