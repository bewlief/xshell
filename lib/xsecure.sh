# 避免重复导入
[[ -n $__XLIB_IMPORTED__XSECURE ]] && return 0
__XLIB_IMPORTED__XSECURE=1

function __xsecure_init__() {
    # 引入core.sh
    [[ -s $XLIB_CORE ]] && source "$XLIB_CORE" || {
        local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
        source "$script_dir/core.sh"
    }

    # todo 需要检查openssl是否存在？

}

# 非对称加密字符串
# encrypt <plain-string> <password>
# echo 'rusty!herring.pitshaft' | openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 -salt -pass pass:'pick.your.password'
function openssl::encrypt() {
    if [ -z "$1" ]; then return 1; fi
    if [ -z "$2" ]; then return 2; fi
    local status=1
    echo -n "$1" | openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 -salt -pass pass:"$2" && status=0 || status=1
    return $status
}

# 返回解密后的字符串
# decrypt <enc-string> <password>
function openssl::decrypt() {
    if [ -z "$1" ]; then return 1; fi
    if [ -z "$2" ]; then return 2; fi
    local status=1
    echo "$1" | openssl enc -aes-256-cbc -md sha512 -a -d -pbkdf2 -iter 100000 -salt -pass pass:"$2" && status=0 || status=1
    return $status
}


# 替换密码中的特殊字符，用于proxy
# TODO 测试下字母也替换后是否可用！
# printf \\x$(printf "%x" 97) -> a
# printf "%d" \'a -> 97，注意单引号 ' 的使用，只有一半！
function hex() {
    local password=$1
    local i,m,d
    #    declare -A chars
    #     declare -a arr=("~" "@" "$" "^" "*" "!" "%" "&" "?")

    # 目前仅需要处理 @%
    declare -a arr=("@" "%")
    #    chars=(
    #        ["~"]="0x7e"
    #        ["@"]="0x40"
    #        ["$"]="0x24"
    #        ["^"]="0x5e"
    #        ["*"]="0x2a"
    #        ["!"]="0x21"
    #        ["#"]="0x23"
    #        ["%"]="0x25"
    #        ["&"]="0x26"
    #        ["?"]="0x3F"
    #    )
    echo "src=$password"
    for i in $(seq ${#password}); do
        d=${password:$i-1:1}
        local in_chars=$(in-array "$d" "${arr[@]}")
        if [[ $in_chars -gt 0 ]]; then
            m=$(printf "0x%d" \'$d)
            echo -n "$m"
        else
            echo -n "$d"
        fi
    done
}

# 返回随机字符串
# rand <bae64|hex> <length>
# ex:
#   rand -base64 10
#   rand -hex 10
function openssl::random() {
    local status=0
    local outpuType=${1:-"hex"}
    local outputNum=${2-10}

    openssl rand -${outpuType} ${outputNum} && status=0 || status=1
    unset outpuType outputNum
    return ${status}
}

# 返回字符串摘要值
# digest <string> <algorithm(md5|sha1|...)>
function openssl::digest() {
    if [ -z "$1" ]; then return 1; fi

    # 确定摘要算法，缺省md5
    digest_algorithm=${2-"md5"}

    local status=0
    echo -n "$1" | openssl dgst -${digest_algorithm} | awk '{printf("%s",$2)}' && status=0 || status=1
    unset digest_algorithm
    return $status
}

function openssl::md5() {
    openssl::digest "$1" "md5"
    return $?
}

function openssl::sha1() {
    openssl::digest "$1" "sha1"
    return $?
}

#Usage: keyfile hashalg
#Output: Base64-encoded signature value
_sign() {
    keyfile="$1"
    alg="$2"
    if [ -z "$alg" ]; then
        _usage "Usage: _sign keyfile hashalg"
        return 1
    fi

    _sign_openssl="${ACME_OPENSSL_BIN:-openssl} dgst -sign $keyfile "

    if _isRSA "$keyfile" >/dev/null 2>&1; then
        $_sign_openssl -$alg | _base64
    elif _isEcc "$keyfile" >/dev/null 2>&1; then
        if ! _signedECText="$($_sign_openssl -sha$__ECC_KEY_LEN | ${ACME_OPENSSL_BIN:-openssl} asn1parse -inform DER)"; then
            _err "Sign failed: $_sign_openssl"
            _err "Key file: $keyfile"
            _err "Key content:$(wc -l <"$keyfile") lines"
            return 1
        fi
        _debug3 "_signedECText" "$_signedECText"
        _ec_r="$(echo "$_signedECText" | _head_n 2 | _tail_n 1 | cut -d : -f 4 | tr -d "\r\n")"
        _ec_s="$(echo "$_signedECText" | _head_n 3 | _tail_n 1 | cut -d : -f 4 | tr -d "\r\n")"
        if [ "$__ECC_KEY_LEN" -eq "256" ]; then
            while [ "${#_ec_r}" -lt "64" ]; do
                _ec_r="0${_ec_r}"
            done
            while [ "${#_ec_s}" -lt "64" ]; do
                _ec_s="0${_ec_s}"
            done
        fi
        if [ "$__ECC_KEY_LEN" -eq "384" ]; then
            while [ "${#_ec_r}" -lt "96" ]; do
                _ec_r="0${_ec_r}"
            done
            while [ "${#_ec_s}" -lt "96" ]; do
                _ec_s="0${_ec_s}"
            done
        fi
        if [ "$__ECC_KEY_LEN" -eq "512" ]; then
            while [ "${#_ec_r}" -lt "132" ]; do
                _ec_r="0${_ec_r}"
            done
            while [ "${#_ec_s}" -lt "132" ]; do
                _ec_s="0${_ec_s}"
            done
        fi
        _debug3 "_ec_r" "$_ec_r"
        _debug3 "_ec_s" "$_ec_s"
        printf "%s" "$_ec_r$_ec_s" | _h2b | _base64
    else
        _err "Unknown key file format."
        return 1
    fi

}

#keylength or isEcc flag (empty str => not ecc)
_isEccKey() {
    _length="$1"

    if [ -z "$_length" ]; then
        return 1
    fi

    [ "$_length" != "1024" ] &&
        [ "$_length" != "2048" ] &&
        [ "$_length" != "3072" ] &&
        [ "$_length" != "4096" ] &&
        [ "$_length" != "8192" ]
}

# _createkey  2048|ec-256   file
_createkey() {
    length="$1"
    f="$2"
    _debug2 "_createkey for file:$f"
    eccname="$length"
    if _startswith "$length" "ec-"; then
        length=$(printf "%s" "$length" | cut -d '-' -f 2-100)

        if [ "$length" = "256" ]; then
            eccname="prime256v1"
        fi
        if [ "$length" = "384" ]; then
            eccname="secp384r1"
        fi
        if [ "$length" = "521" ]; then
            eccname="secp521r1"
        fi

    fi

    if [ -z "$length" ]; then
        length=2048
    fi

    _debug "Use length $length"

    if ! touch "$f" >/dev/null 2>&1; then
        _f_path="$(dirname "$f")"
        _debug _f_path "$_f_path"
        if ! mkdir -p "$_f_path"; then
            _err "Can not create path: $_f_path"
            return 1
        fi
    fi

    if _isEccKey "$length"; then
        _debug "Using ec name: $eccname"
        if _opkey="$(${ACME_OPENSSL_BIN:-openssl} ecparam -name "$eccname" -noout -genkey 2>/dev/null)"; then
            echo "$_opkey" >"$f"
        else
            _err "error ecc key name: $eccname"
            return 1
        fi
    else
        _debug "Using RSA: $length"
        __traditional=""
        if _contains "$(${ACME_OPENSSL_BIN:-openssl} help genrsa 2>&1)" "-traditional"; then
            __traditional="-traditional"
        fi
        if _opkey="$(${ACME_OPENSSL_BIN:-openssl} genrsa $__traditional "$length" 2>/dev/null)"; then
            echo "$_opkey" >"$f"
        else
            _err "error rsa key: $length"
            return 1
        fi
    fi

    if [ "$?" != "0" ]; then
        _err "Create key error."
        return 1
    fi
}

# from: D:\Download\aaaa\free\shell\acmesh-official\acme.sh\acme.sh
#file
# _checkcert <cert file>
_checkcert() {
    local OPENSSL_BIN="openssl"
    _cf="$1"
    if [ "$DEBUG" ]; then
        ${OPENSSL_BIN} x509 -noout -text -in "$_cf"
    else
        ${OPENSSL_BIN} x509 -noout -text -in "$_cf" >/dev/null 2>&1
    fi
}

# Show all the names (CNs and SANs) listed in the SSL certificate
# for a given domain
# cmd www.baidu.com
function getcertnames() {
	if [ -z "${1}" ]; then
		echo "ERROR: No domain specified.";
		return 1;
	fi;

	local domain="${1}";
	echo "Testing ${domain}…";
	echo ""; # newline

	local tmp=$(echo -e "GET / HTTP/1.0\nEOT" \
		| openssl s_client -connect "${domain}:443" -servername "${domain}" 2>&1);

	if [[ "${tmp}" = *"-----BEGIN CERTIFICATE-----"* ]]; then
		local certText=$(echo "${tmp}" \
			| openssl x509 -text -certopt "no_aux, no_header, no_issuer, no_pubkey, \
			no_serial, no_sigdump, no_signame, no_validity, no_version");
		echo "Common Name:";
		echo ""; # newline
		echo "${certText}" | grep "Subject:" | sed -e "s/^.*CN=//" | sed -e "s/\/emailAddress=.*//";
		echo ""; # newline
		echo "Subject Alternative Name(s):";
		echo ""; # newline
		echo "${certText}" | grep -A 1 "Subject Alternative Name:" \
			| sed -e "2s/DNS://g" -e "s/ //g" | tr "," "\n" | tail -n +2;
		return 0;
	else
		echo "ERROR: Certificate not found.";
		return 1;
	fi;
}

__xsecure_init__
