#!/usr/bin/env bash

#  functions
CONTAINING_DIR=$(unset CDPATH && cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
info "functions for nnnn $CONTAINING_DIR/mac-function.sh"


# 这里定义需要手动设置的变量
export alpaca_name="alpaca.xjm.0410"
export MAVEN_DIR="$HOME/xdata/m2"

# 定义网络热点的名称和密码，key必须要一一匹配
declare -A mapNetworkNames
declare -A mapNetworkPasses
declare -A mapNetworkSec

# network device name for Wi-Fi
export WIFIETH="en0"
export WIFINAME="Wi-Fi"



# Trim new lines and copy to clipboard
alias c="tr -d '\n' | pbcopy"

# Recursively delete `.DS_Store` files
alias cleanup="find . -type f -name '*.DS_Store' -ls -delete"

# Empty the Trash on all mounted volumes and the main HDD.
# Also, clear Apple’s System Logs to improve shell startup speed.
# Finally, clear download history from quarantine. https://mths.be/bum
alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl; sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV* 'delete from LSQuarantineEvent'"

# Show/hide hidden files in Finder
alias show="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hide="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

# Hide/show all desktop icons (useful when presenting)
alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"

# security type
mapNetworkSec=(
    # key如果以数字开头，可能会导致无法创建map，奇怪？！
    # fixme 貌似cd不该是wpa
    ["cd"]="WPA2"
    # 必须使用正确的类型！可先手动加入后再获取其ecurity类型
    # OPEN: none, WPA: WPA Personal, WPAE: WPA Enterprise, 
    # WPA2: WPA2 Personal, WPA2E: WPA2 Enterprise, WEP: plain WEP, 8021XWEP: 802.1X WEP
    ["bb"]="WPA2"
    ["xhoe"]="OPEN"
) 

# 热点名称
mapNetworkNames=(
    ["cd"]="SC_WIFI_5G"
    ["bb"]="BlackBerry BBB100-4 a8b5"
)

warn "Please keep these passwords secret!"
# 各热点的密码
mapNetworkPasses=(
    # xhoewlan的密码是域用户密码
    ["cd"]="---"
    ["bb"]="---"
)

mountxjm() {
    smbpath="---/xinj$"
    networkId=$(nws -getairportnetwork $WIFIETH | awk -F':' '{print $2}')
    if [ $networkId == "XWLAN" ]; then
        info "mount $smbpath now"
        osascript \
            -e 'tell application "System Events"' \
            -e 'if "---" is not in the name of every disk then mount volume "smb://---/xinj$"' \
            -e 'end tell'
        cdl "/Volumes/xinj$"
    else
        error "not XWLAN, will not mount $smbpath"
        return 1
    fi

}

# 下面的网络切换，需要预先创建各location，并设置好该location对应的proxy等：
# ---->>>>> 并不需要预先创建！

# 设置cmd下的proxy
# 需要alpaca进程预先启动！
function set_cmd_proxy() {
    # run alpaca
    # checkProcess.sh "alpaca.xjm.0410" "$HOME/xcodes/mycodes/xops/mybash/bin/start-alpaca.sh"

    # cntlm_proxy="http://---:80"
    cntlm_proxy=$1
    if [[ "$cntlm_proxy" != "" ]]; then 
        export http_proxy=$cntlm_proxy
        export https_proxy=$cntlm_proxy
        export HTTP_PROXY=$cntlm_proxy
        export HTTPS_PROXY=$cntlm_proxy

        # 使用 pac 后会自动设置no_proxy的内容
        export no_proxy="---"
        export NO_PROXY=$no_proxy

        # set up aopdemo.proxy for homebrew and curl
        export ALL_PROXY=$cntlm_proxy

        # set up pip for python
        export REQUESTS_CA_BUNDLE=/Users/xinj/.rrr/cacerts.txt
        export SSL_CERT_FILE=$REQUESTS_CA_BUNDLE

        # 指定curl使用的证书，相当于 curl --cacert 
        export CURL_CA_BUNDLE=$REQUESTS_CA_BUNDLE

        info "proxy set to: $cntlm_proxy"
        info "no_proxy = $no_proxy"

        info "switch MAVEN settings.xml: proxy on"
        cp "$MAVEN_DIR/settings.xml.proxyon" "$MAVEN_DIR/settings.xml"
    else 
        # kill alpaca
        # pkill -9 "$alpaca_name"

        unset http_proxy
        unset https_proxy
        unset HTTP_PROXY
        unset HTTPS_PROXY
        unset no_proxy
        unset NO_PROXY

        # unset aopdemo.proxy for homebrew and curl
        unset ALL_PROXY
        unset CURL_CA_BUNDLE

        # unset aopdemo.proxy for pip
        unset REQUESTS_CA_BUNDLE
        unset SSL_CERT_FILE

        warn "proxy UNSET"

        info "switch MAVEN settings.xml: proxy off"
        cp "$MAVEN_DIR/settings.xml.proxyoff" "$MAVEN_DIR/settings.xml"
    fi
}

# show proxy status
function proxy() {
    d=$(ps -ef | grep alpaca.xjm.0410 | grep -v grep | awk -F' ' '{print $3}')
    if [ $d -gt 0 ]; then
        info "Alpaca.xjm.0410: $d"
    else
        warn "Alpaca NOT RUNNING"
    fi

    if [[ -z "$http_proxy" ]]; then
        info "Terminal proxy : DISABLED"
        # set_cmd_proxy
    else
        info "Terminal proxy : ENABLED"
        info "http_proxy = $http_proxy"
        info "no_proxy = $no_proxy"
        # set_cmd_proxy ""
        if [ "$d"x == ""x ]; then
            error "set to use proxy but ALPACA NOT RUNNING now"
        fi
    fi
}

# todo 设置proxy url。需要细化！
# 使用auto discover时会自动启用 automatic aopdemo.proxy configuration
# 使用 http/https proxy时，需要把auto discover禁止
function set_pac_proxy_url(){
    url=$1
    # 禁止 web aopdemo.proxy/secure web aopdemo.proxy
    nws -setwebproxystate "$WIFINAME" off
    nws -setsecurewebproxystate "$WIFINAME" off

    if [[ "$url" != "" ]]; then 
        # 设置 auto aopdemo.proxy configuration的url
        nws -setautoproxyurl "$WIFINAME" $url

        # 设置 bypass 列表
        nws -setproxybypassdomains "$WIFINAME" ""
    else 
        nws -setproxyautodiscovery "$WIFINAME" off
        nws -setautoproxystate "$WIFINAME" off
        warn "disable http/https proxy"
    fi
}

# 切换网络
# todo 不知如何去设置热点优先级，所以暂时切换时先清空，
# 只保留当前network，以实现不会自己切换到其他网络
function switchNetwork(){
    info "available network for now: "
    for key in ${!mapNetworkNames[@]}; do 
        echo "--- $key"
    done
    echo ""

    network=$1

    if [[ "$network" == "" ]]; then 
        error "network name cannot be empty"
    fi

    # 移除所有的 preferred network
    nws -removeallpreferredwirelessnetworks $WIFIETH
    
    network_name=${mapNetworkNames[$network]}
    network_pass=${mapNetworkPasses[$network]}
    network_sec=${mapNetworkSec[$network]}
    info "$network >>> $network_name,  $network_sec"

    # 使用密码时，会把密码保存到keychain中
    # fixme 有时还会提示，有点烦
    if [[ $network_sec == "OPEN" ]]; then
        #下面这个就不会弹出keychain窗口
        nws -addpreferredwirelessnetworkatindex $WIFIETH "$network_name" 0 "$network_sec" "$network_pass"
    else
        # OPEN时会有弹出框，要求keychain密码，但WPA下则不会，奇怪！
        nws -addpreferredwirelessnetworkatindex $WIFIETH "$network_name" 0 "$network_sec" "$network_pass"
    fi

    re=$(nws -setairportnetwork $WIFIETH "$network_name")
    if [[ "$re" != "" ]]; then 
        error $re
        warn "switch network FAILED, will keep current configuration"
    fi

    # 强制重启Wi-Fi：可能不是必要的
    nws -setairportpower $WIFIETH off && nws -setairportpower $WIFIETH on
}

# todo 考虑和net的统一
function netxhoe() {
    proxy_type=$1

    if [[ "$proxy_type" == "" ]]; then 
        proxy_type="pac"
    fi

    if [[ "$proxy_type" =~ "local" ]]; then
        url="http://localhost:3128/alpaca.pac"
    elif [[ "$proxy_type" =~ "pac" ]]; then
        url="http://---/gblproxy.pac"
    elif [[ "$proxy_type" =~ "ip" ]]; then
        url="---"

        # 设置 Proxies 中的 Web Proxy(http), Secure Web Proxy(https)
        nws -setwebproxystate "$WIFINAME" on
        nws -setsecurewebproxystate "$WIFINAME" on

        domain="---"
        port=80
        username="global\xinj"
        password="---"

        # 使用账户和密码
        nws -setwebproxy "$WIFINAME" $domain $port on $username $password
        nws -setsecurewebproxy "$WIFINAME" $domain $port on $username $password

        # set to blank = diable "auto aopdemo.proxy conf"
        # nws -setautoproxyurl "$WIFINAME" ""

        # 设置  Wi-Fi>Proxies>Automatic aopdemo.proxy configuration为off，即没有勾选
        nws -setautoproxystate "$WIFINAME" off
    else 
        error "unkonwn type of proxy: $proxy_type"
        return 1
    fi
    showRed "switch network to $proxy_type: proxy=$url"

    # 无需切换location
    # scselect $location

    switchNetwork "xhoe"

    set_cmd_proxy "http://localhost:3128/"
    set_pac_proxy_url $url


    # using AppleScript to switch to XWLAN
    # /usr/bin/osascript \
    #     -e 'tell application "System Events"' \
    #     -e 'tell process "SystemUIServer"' \
    #     -e 'click (menu bar item 1 of menu bar 1 whose description contains "Wi-Fi")' \
    #     -e 'tell (menu item "XWLAN" of menu 1 of menu bar item 9 of menu bar 1 of application process "SystemUIServer" of application "System Events")' \
    #     -e ' click' \
    #     -e 'end tell' \
    #     -e 'end tell' \
    #     -e 'end tell'

    # entire contents ：显示所有item以获取其访问路径！
    
    network
}

# 切换5g/bb
function net(){
    network=$1
    showBlue "switch to network: $network"
    switchNetwork $network

    # 无需切换location
    # scselect noproxy

    # 设置命令行的proxy为空
    set_cmd_proxy ""
    set_pac_proxy_url ""

    network
}


network() {
    echo ""
    nwService="$WIFINAME"
    nwEth="$WIFIETH"
    nw=$(nws -getairportnetwork $nwEth)
    info "$nw\n"

    proxy=$(nws -getwebproxy $nwService)
    info "Proxy $proxy"
    proxy=$(nws -getsecurewebproxy $nwService)
    info "Https Proxy $proxy\n"

    auto_proxy=$(nws -getautoproxyurl "$WIFINAME")
    info $auto_proxy

    # aopdemo.proxy

    repeat "*" 80
    info "Switch to other network : netxhoe [pac, local, ip], netcd, netbb"
    repeat "*" 80
    echo ""

}


alias netcd='net cd'
alias netbb='net bb'
alias nws="networksetup "
alias myshare="cdl /Volumes/General/Public/xinj"
alias my="cdl /Volumes/xinj$"
alias alpaca="start-alpaca.sh"



alias f='open -a Finder ./'                 # f:            Opens current directory in MacOS Finder
ql () { qlmanage -p "$*" >& /dev/null; }    # ql:           Opens any file in MacOS Quicklook Preview
alias DT='tee ~/Desktop/terminalOut.txt'    # DT:           Pipe content to file on MacOS Desktop

#   cdf:  'Cd's to frontmost window of MacOS Finder
#   ------------------------------------------------------
cdf () {
    currFolderPath=$( /usr/bin/osascript <<EOT
        tell application "Finder"
            try
        set currFolder to (folder of the front window as alias)
            on error
        set currFolder to (path to desktop folder as alias)
            end try
            POSIX path of currFolder
        end tell
EOT
    )
    echo "cd to \"$currFolderPath\""
    cd "$currFolderPath"
}

#   spotlight: Search for a file using MacOS Spotlight's metadata
#   -----------------------------------------------------------
spotlight () { mdfind "kMDItemDisplayName == '$@'wc"; }



#   cleanupDS:  Recursively delete .DS_Store files
#   -------------------------------------------------------------------
alias cleanupDS="find . -type f -name '*.DS_Store' -ls -delete"



#   finderShowHidden:   Show hidden files in Finder
#   finderHideHidden:   Hide hidden files in Finder
#   -------------------------------------------------------------------
alias finderShowHidden='defaults write com.apple.finder ShowAllFiles TRUE'
alias finderHideHidden='defaults write com.apple.finder ShowAllFiles FALSE'

#   cleanupLS:  Clean up LaunchServices to remove duplicates in the "Open With" menu
#   -----------------------------------------------------------------------------------
alias cleanupLS="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder"

#    screensaverDesktop: Run a screensaver on the Desktop
#   -----------------------------------------------------------------------------------
alias screensaverDesktop='/System/Library/Frameworks/ScreenSaver.framework/Resources/ScreenSaverEngine.app/Contents/MacOS/ScreenSaverEngine -background'


start-alpaca(){
    script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
    source $HOME/.bash_profile
    expect $script_dir/alpaca.exp $MY_PASS
}



function proxyon() {
    # run alpaca
    # checkProcess.sh "$alpaca_name" "nohup $alpaca_name -C http://---/gblproxy.pac 2>&1" >/dev/null
    # checkProcess.sh "$alpaca_name" "alpaca"

    cntlm_proxy="http://localhost:3128/"
    export http_proxy=$cntlm_proxy
    export https_proxy=$cntlm_proxy
    export HTTP_PROXY=$cntlm_proxy
    export HTTPS_PROXY=$cntlm_proxy

    # 使用 pac 后会自动设置no_proxy的内容
    # export no_proxy="---"
    # export NO_PROXY=$no_proxy

    # set up aopdemo.proxy for homebrew and curl
    export ALL_PROXY=$cntlm_proxy
    export CURL_CA_BUNDLE=$REQUESTS_CA_BUNDLE

    # set up pip for python
    export REQUESTS_CA_BUNDLE=/Users/xinj/.rrr/cacerts.txt
    export SSL_CERT_FILE=$REQUESTS_CA_BUNDLE

    info "proxy set to: $cntlm_proxy"
    info "no_proxy = $no_proxy"

    info "switch MAVEN settings.xml: proxy on"
    cp "$MAVEN_DIR/settings.xml.proxyon" "$MAVEN_DIR/settings.xml"
}

function proxyoff() {
    # kill alpaca
    # pkill -9 "$alpaca_name"

    unset http_proxy
    unset https_proxy
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset no_proxy
    unset NO_PROXY

    # unset aopdemo.proxy for homebrew and curl
    unset ALL_PROXY
    unset CURL_CA_BUNDLE

    # unset aopdemo.proxy for pip
    unset REQUESTS_CA_BUNDLE
    unset SSL_CERT_FILE

    warn "proxy UNSET"

    info "switch MAVEN settings.xml: proxy off"
    cp "$MAVEN_DIR/settings.xml.proxyoff" "$MAVEN_DIR/settings.xml"
}

# show aopdemo.proxy status
function proxy() {
    d=$(ps -ef | grep alpaca.xjm.0410 | grep -v grep | awk -F' ' '{print $3}')
    if [ $d -gt 0 ]; then
        info "Alpaca.xjm.0410: $d"
    else
        warn "Alpaca NOT RUNNING"
    fi

    if [[ -z "$http_proxy" ]]; then
        info "Terminal proxy : DISABLED"
        # proxyon
    else
        info "Terminal proxy : ENABLED"
        info "http_proxy = $http_proxy"
        info "no_proxy = $no_proxy"
        # proxyoff
        if [ "$d"x == ""x ]; then
            error "set to use proxy but ALPACA NOT RUNNING now"
        fi
    fi
}

#source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc"
#source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc"

function netxhoe() {
    proxyon

    nws -setwebproxystate "Wi-Fi" off
    nws -setsecurewebproxystate "Wi-Fi" off
    #setup mac aopdemo.proxy securitydemo.config
    networksetup -setautoproxyurl Wi-Fi http://localhost:3128/alpaca.pac
    networksetup -setproxybypassdomains Wi-Fi ""

    # using AppleScript to switch to XWLAN
    /usr/bin/osascript \
        -e 'tell application "System Events"' \
        -e 'tell process "SystemUIServer"' \
        -e 'click (menu bar item 1 of menu bar 1 whose description contains "Wi-Fi")' \
        -e 'tell (menu item "XWLAN" of menu 1 of menu bar item 9 of menu bar 1 of application process "SystemUIServer" of application "System Events")' \
        -e ' click' \
        -e 'end tell' \
        -e 'end tell' \
        -e 'end tell'

    # entire contents ：显示所有item以获取其访问路径！

}

function netbb() {
    proxyoff

    # nws -setwebproxystate "Wi-Fi" off
    # nws -setsecurewebproxystate "Wi-Fi" off
    nws -setwebproxystate "Wi-Fi" off
    nws -setsecurewebproxystate "Wi-Fi" off
    nws -setairportnetwork en0 "BlackBerry BBB100-4 a8b5" "20050410"

    wifi
}

function net5g() {
    proxyoff

    nws -setwebproxystate "Wi-Fi" off
    nws -setsecurewebproxystate "Wi-Fi" off
    nws -setgopherproxystate "Wi-Fi" off
    nws -setproxyautodiscovery "Wi-Fi" off
    nws -setairportnetwork en0 "X_WIFI_5G" "---"

    wifi
}

wifi() {
    nwService="Wi-Fi"
    nwEth="en0"
    nw=$(nws -getairportnetwork $nwEth)
    proxy=$(nws -getwebproxy $nwService)
    info "current wifi configuration:"
    info "$nw"
    info "Proxy $proxy"
    proxy

    repeat "*" 80
    info "Switch to other network : netxhoe, net5g, netbb"
    repeat "*" 80

}
