# ------------------------------------------
# Filename: math.sh
# Version:   0.1
# Date: 2021/05/26
# note:
#   functions for math
# ------------------------------------------

# 避免重复导入
[[ -n $__XLIB_IMPORTED__MATH ]] && return 0
__XLIB_IMPORTED_MATH=1

function is-digit() {
    # 引入core.sh
    [[ -s $XLIB_CORE ]] && source "$XLIB_CORE" || {
        local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
        source "$script_dir/core.sh"
    }

    # echo "$1" | [ -n "`sed -n '/^[0-9][0-9]*$/p'`" ] && echo 1

    #     if grep '^[[:digit:]]*$' <<< "$1";then
    #  echo "$1 is number."
    # else
    #  echo 'no.'
    # fi

    echo "$1" | awk '{print($0~/^[-]?([0-9])+[.]?([0-9])+$/)?"1":"0"}'
}

function abs() {
    #    [[ $[ $@ ] -lt 0 ]] && echo "$[ ($@) * -1 ]" || echo "$[ $@ ]"
    echo ${1#-}
}

# https://www.baeldung.com/linux/round-divided-number
#          4/2    3/2     10/3=3.333...
# Floor    2      1       3
# Ceil     2      2       4
# halfup   2      2       3
function ceil() {
    # using bc
    #    echo "($1 + $2 - 1)/$2" | bc

    # pure bash
    echo $((($1 + $2 - 1) / $2))
}
function floor() {
    echo $((($1 / $2)))
}
function halfup() {
    echo $(((($1 + $2 / 2) / $2)))
}

# calculate the arithmetic-geometric mean of two numbers
#
#   see http://en.wikipedia.org/wiki/Arithmetic-geometric_mean

#@public
function bashlets::core::math::mean::agm() {
    local a=${1:-0} b=${2:-0}
    local tol=${3:-.0001}

    awk -v a=$a -v b=$b -v tol=$tol -e '
        function abs(x) {
            return x >= -x ? x : -x
        }

        BEGIN {
            if (a > 0 && b > 0) {
                am = a
                gm = b

                while (abs(am - gm) >= tol) {
                    am_old = am
                    gm_old = gm
                    am = (am_old + gm_old) / 2
                    gm = sqrt(am_old * gm_old)
                }

                print (am + gm) / 2
            }

            exit
        }
    '
}

#@public
function bashlets::core::math::integer::abs() {
    local value="$1"
    local opposite
    $BASHLETS_NAMESPACE integer validate "$value" || return 1
    opposite="$((-1 * value))"
    [[ $value -ge $opposite ]] && echo "$value" || echo "$opposite"
}

#@public
function bashlets::core::math::integer::sign() {
    local value="$1"
    local opposite
    $BASHLETS_NAMESPACE integer validate "$value" || return 1
    [[ $value -eq 0 ]] && {
        echo 0
        return
    }
    opposite="$((-1 * value))"
    [[ $value -ge $opposite ]] && echo 1 || echo -1
}

#@public
function bashlets::core::math::integer::get_unique_factors() {
    local pass_0

    $BASHLETS_NAMESPACE integer validate "$value" || return 1

    declare -i n="$1"
    declare -i sign=1

    # is $n < 0?
    test $n -lt 0 && {
        sign=-1
        n=$((-1 * n))
    }

    # call factor(1)
    pass_0="$(factor $n 2>/dev/null)" || return 1

    # is $n == 0?
    # then the call to factor(1) above just returned the string "0:"
    test $n -eq 0 && pass_0="$pass_0 0"

    echo "$pass_0" | cut -d: -f2 | (
        test $sign -lt 0 && echo -1
        cat
    ) | xargs -n 1 echo | uniq -c
}

#
# fast modular exponentiation
#
#   see http://en.wikipedia.org/wiki/Modular_exponentiation
#

#@public
function bashlets::core::math::integer::modular_pow() {
    local base=$1 expon=$2 mod=$3

    $BASHLETS_NAMESPACE integer validate $base || return 1
    $BASHLETS_NAMESPACE integer validate $expon || return 1
    $BASHLETS_NAMESPACE unsigned validate $mod || return 1

    ((mod > 0)) || return 1

    awk -v base=$base -v expon=$expon -v mod=$mod -e '
        function modular_pow(base, expon, mod) {
            result = 1

            while (expon > 0) {
                if (and(expon, 1) == 1) {
                    result = (result * base) % mod
                }

                expon = rshift(expon, 1)
                base = (base * base) % mod
            }

            return result
        }

        BEGIN {
            print modular_pow(base, expon, mod)
            exit
        }
    '
}

#@public
function bashlets::core::math::icomplex::to_real() {
    declare w="$1"
    (
        IFS=":"
        set -- $w # no quotes!
        echo "$1"
    )
}

#@public
function bashlets::core::math::icomplex::to_img() {
    declare w="$1"
    (
        IFS=":"
        set -- $w # no quotes!
        echo "$2"
    )
}

#@public
function bashlets::core::math::icomplex::to_s() {
    declare w="$1"
    declare -i real img

    real="$(bashlets::core::math::icomplex::to_real "$w")"
    img="$(bashlets::core::math::icomplex::to_img "$w")"

    echo "$real + ${img}i"
}

#@public
function bashlets::core::math::icomplex::compare() {
    declare w="$1" z="$2"
    declare -i w_real w_img z_real z_img

    w_real="$(bashlets::core::math::icomplex::to_real "$w")"
    w_img="$(bashlets::core::math::icomplex::to_img "$w")"
    z_real="$(bashlets::core::math::icomplex::to_real "$z")"
    z_img="$(bashlets::core::math::icomplex::to_img "$z")"

    [[ $w_real -eq $z_real && $w_img -eq $z_img ]]
}

#@public
function bashlets::core::math::icomplex::is_zero() {
    declare w="$1"
    declare -i real img

    real="$(bashlets::core::math::icomplex::to_real "$w")"
    img="$(bashlets::core::math::icomplex::to_img "$w")"

    [[ "$real" -eq 0 && "$img" -eq 0 ]]
}

#@public
function icomplex::negate() {
    declare w="$1"
    declare -i real img

    real="$((-1 * $(icomplex::to_real "$w")))"
    img="$((-1 * $(icomplex::to_img "$w")))"

    icomplex::create "$real" "$img"
}

#@public
function icomplex::conjugate() {
    declare w="$1"
    declare -i real img

    real="$(icomplex::to_real "$w")"
    img="$((-1 * $(icomplex::to_img "$w")))"

    icomplex::create "$real" "$img"
}

#@public
function icomplex::norm2() {
    declare w="$1"
    declare -i real img

    real="$(icomplex::to_real "$w")"
    img="$(icomplex::to_img "$w")"

    echo "$((real ** 2 + img ** 2))"
}

#@public
function icomplex::add() {
    declare w="$1"
    declare z="$2"
    declare -i realw imgw
    declare -i realz imgz
    declare -i real img

    realw="$(icomplex::to_real "$w")"
    realz="$(icomplex::to_real "$z")"
    imgw="$(icomplex::to_img "$w")"
    imgz="$(icomplex::to_img "$z")"

    real="$((realw + realz))"
    img="$((imgw + imgz))"

    icomplex::create "$real" "$img"
}

#@public
function icomplex::subtract() {
    declare w="$1"
    declare z="$2"

    icomplex::add "$w" "$(icomplex::negate "$z")"
}

#@public
function icomplex::multiply() {
    declare w="$1"
    declare z="$2"
    declare -i realw imgw
    declare -i realz imgz
    declare -i real img

    realw="$(icomplex::to_real "$w")"
    realz="$(icomplex::to_real "$z")"
    imgw="$(icomplex::to_img "$w")"
    imgz="$(icomplex::to_img "$z")"

    real=$((realw * realz - imgw * imgz))
    img=$((imgw * realz + realw * imgz))

    icomplex::create "$real" "$img"
}

#@public
function icomplex::square() {
    declare w="$1"

    icomplex::multiply "$w" "$w"
}
