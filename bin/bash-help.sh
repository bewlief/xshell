##############################################################################
# BASH CHEATSHEET (中文速查表)  -  by skywind (created on 2018/02/14)
# Version: 47, Last Modified: 2019/09/24 17:58
# https://github.com/skywind3000/awesome-cheatsheets
##############################################################################


# 内部变量
BASH
BASH_VERSION
EDITOR

# Current function.
"${FUNCNAME[0]}"

# Parent function.
"${FUNCNAME[1]}"

# So on and so forth.
"${FUNCNAME[2]}"
"${FUNCNAME[3]}"

# All functions including parents.
"${FUNCNAME[@]}"

$HOSTNAME
$HOSTTYPE
$OSTYPE
$PWD
$SECONDS 脚本运行的秒数
$SECONDS

##############################################################################
# 变量操作
##############################################################################

varname=value             # 定义变量
varname=value command     # 定义子进程变量并执行子进程
echo $varname             # 查看变量内容
echo $$                   # 查看当前 shell 的进程号
echo $!                   # 查看最近调用的后台任务进程号
echo $?                   # 查看最近一条命令的返回码
export VARNAME=value      # 设置环境变量（将会影响到子进程）

array[0]=valA             # 定义数组
array[1]=valB
array[2]=valC
array=([0]=valA [1]=valB [2]=valC)   # 另一种方式
array=(valA valB valC)               # 另一种方式

${array[i]}               # 取得数组中的元素
${#array[@]}              # 取得数组的长度
${#array[i]}              # 取得数组中某个变量的长度

declare -a                # 查看所有数组
declare -f                # 查看所有函数
declare -F                # 查看所有函数，仅显示函数名
declare -i                # 查看所有整数
declare -r                # 查看所有只读变量
declare -x                # 查看所有被导出成环境变量的东西
declare -p varname        # 输出变量是怎么定义的（类型+值）

${varname:-word}          # 如果变量不为空则返回变量，否则返回 word
${varname:=word}          # 如果变量不为空则返回变量，否则赋值成 word 并返回
${varname:?message}       # 如果变量不为空则返回变量，否则打印错误信息并退出
${varname:+word}          # 如果变量不为空则返回 word，否则返回 null
${varname:offset:len}     # 取得字符串的子字符串

${variable#pattern}       # 如果变量头部匹配 pattern，则删除最小匹配部分返回剩下的
${variable##pattern}      # 如果变量头部匹配 pattern，则删除最大匹配部分返回剩下的
${variable%pattern}       # 如果变量尾部匹配 pattern，则删除最小匹配部分返回剩下的
${variable%%pattern}      # 如果变量尾部匹配 pattern，则删除最大匹配部分返回剩下的
${variable/pattern/str}   # 将变量中第一个匹配 pattern 的替换成 str，并返回
${variable//pattern/str}  # 将变量中所有匹配 pattern 的地方替换成 str 并返回

${#varname}               # 返回字符串长度

*(patternlist)            # 零次或者多次匹配
+(patternlist)            # 一次或者多次匹配
?(patternlist)            # 零次或者一次匹配
@(patternlist)            # 单词匹配
!(patternlist)            # 不匹配

array=($text)             # 按空格分隔 text 成数组，并赋值给变量
IFS="/" array=($text)     # 按斜杆分隔字符串 text 成数组，并赋值给变量
text="${array[*]}"        # 用空格链接数组并赋值给变量
text=$(IFS=/; echo "${array[*]}")  # 用斜杠链接数组并赋值给变量

A=( foo bar "a  b c" 42 ) # 数组定义
B=("${A[@]:1:2}")         # 数组切片：B=( bar "a  b c" )
C=("${A[@]:1}")           # 数组切片：C=( bar "a  b c" 42 )
echo "${B[@]}"            # bar a  b c
echo "${B[1]}"            # a  b c
echo "${C[@]}"            # bar a  b c 42
echo "${C[@]: -2:2}"      # a  b c 42  减号前的空格是必须的

$(UNIX command)           # 运行命令，并将标准输出内容捕获并返回
varname=$(id -u user)     # 将用户名为 user 的 uid 赋值给 varname 变量

num=$(expr 1 + 2)         # 兼容 posix sh 的计算，使用 expr 命令计算结果
num=$(expr $num + 1)      # 数字自增
expr 2 \* \( 2 + 3 \)     # 兼容 posix sh 的复杂计算，输出 10

num=$((1 + 2))            # 计算 1+2 赋值给 num，使用 bash 独有的 $((..)) 计算
num=$(($num + 1))         # 变量递增
num=$((num + 1))          # 变量递增，双括号内的 $ 可以省略
num=$((1 + (2 + 3) * 2))  # 复杂计算


##############################################################################
# 事件指示符
##############################################################################

!!                  # 上一条命令
!^                  # 上一条命令的第一个单词
!:n                 # 上一条命令的第n个单词
!:n-$               # 上一条命令的第n个单词到最后一个单词
!$                  # 上一条命令的最后一个单词
!-n:$               # 上n条命令的最后一个单词
!string             # 最近一条包含string的命令
!^string1^string2   # 最近一条包含string1的命令, 快速替换string1为string2
!#                  # 本条命令之前所有的输入内容
!#:n                # 本条命令之前的第n个单词, 快速备份cp /etc/passwd !#:1.bak


##############################################################################
# 函数
##############################################################################

# 定义一个新函数
function myfunc() {
    # $1 代表第一个参数，$N 代表第 N 个参数
    # $# 代表参数个数
    # $0 代表被调用者自身的名字
    # $@ 代表所有参数，类型是个数组，想传递所有参数给其他命令用 cmd "$@" 
    # $* 空格链接起来的所有参数，类型是字符串
    {shell commands ...}
}

myfunc                    # 调用函数 myfunc 
myfunc arg1 arg2 arg3     # 带参数的函数调用
myfunc "$@"               # 将所有参数传递给函数
myfunc "${array[@]}"      # 将一个数组当作多个参数传递给函数
shift                     # 参数左移

unset -f myfunc           # 删除函数
declare -f                # 列出函数定义


##############################################################################
# 条件判断（兼容 posix sh 的条件判断）：man test
##############################################################################

statement1 && statement2  # and 操作符
statement1 || statement2  # or 操作符

exp1 -a exp2              # exp1 和 exp2 同时为真时返回真（POSIX XSI扩展）
exp1 -o exp2              # exp1 和 exp2 有一个为真就返回真（POSIX XSI扩展）
( expression )            # 如果 expression 为真时返回真，输入注意括号前反斜杆
! expression              # 如果 expression 为假那返回真

str1 = str2               # 判断字符串相等，如 [ "$x" = "$y" ] && echo yes
str1 != str2              # 判断字符串不等，如 [ "$x" != "$y" ] && echo yes
str1 < str2               # 字符串小于，如 [ "$x" \< "$y" ] && echo yes
str2 > str2               # 字符串大于，注意 < 或 > 是字面量，输入时要加反斜杆
-n str1                   # 判断字符串不为空（长度大于零）
-z str1                   # 判断字符串为空（长度等于零）

-a file                   # 判断文件存在，如 [ -a /tmp/abc ] && echo "exists"
-d file                   # 判断文件存在，且该文件是一个目录
-e file                   # 判断文件存在，和 -a 等价
-f file                   # 判断文件存在，且该文件是一个普通文件（非目录等）
-r file                   # 判断文件存在，且可读
-s file                   # 判断文件存在，且尺寸大于0
-w file                   # 判断文件存在，且可写
-x file                   # 判断文件存在，且执行
-N file                   # 文件上次修改过后还没有读取过
-O file                   # 文件存在且属于当前用户
-G file                   # 文件存在且匹配你的用户组
file1 -nt file2           # 文件1 比 文件2 新
file1 -ot file2           # 文件1 比 文件2 旧

num1 -eq num2             # 数字判断：num1 == num2
num1 -ne num2             # 数字判断：num1 != num2
num1 -lt num2             # 数字判断：num1 < num2
num1 -le num2             # 数字判断：num1 <= num2
num1 -gt num2             # 数字判断：num1 > num2
num1 -ge num2             # 数字判断：num1 >= num2


##############################################################################
# 分支控制：if 和经典 test，兼容 posix sh 的条件判断语句
##############################################################################

test {expression}         # 判断条件为真的话 test 程序返回0 否则非零
[ expression ]            # 判断条件为真的话返回0 否则非零

test "abc" = "def"        # 查看返回值 echo $? 显示 1，因为条件为假
test "abc" != "def"       # 查看返回值 echo $? 显示 0，因为条件为真

test -a /tmp; echo $?     # 调用 test 判断 /tmp 是否存在，并打印 test 的返回值
[ -a /tmp ]; echo $?      # 和上面完全等价，/tmp 肯定是存在的，所以输出是 0

test cond && cmd1         # 判断条件为真时执行 cmd1
[ cond ] && cmd1          # 和上面完全等价
[ cond ] && cmd1 || cmd2  # 条件为真执行 cmd1 否则执行 cmd2

# 判断 /etc/passwd 文件是否存在
# 经典的 if 语句就是判断后面的命令返回值为0的话，认为条件为真，否则为假
if test -e /etc/passwd; then
    echo "alright it exists ... "
else
    echo "it doesn't exist ... "
fi

# 和上面完全等价，[ 是个和 test 一样的可执行程序，但最后一个参数必须为 ]
# 这个名字为 "[" 的可执行程序一般就在 /bin 或 /usr/bin 下面，比 test 优雅些
if [ -e /etc/passwd ]; then   
    echo "alright it exists ... "
else
    echo "it doesn't exist ... "
fi

# 和上面两个完全等价，其实到 bash 时代 [ 已经是内部命令了，用 enable 可以看到
[ -e /etc/passwd ] && echo "alright it exists" || echo "it doesn't exist"

# 判断变量的值
if [ "$varname" = "foo" ]; then
    echo "this is foo"
elif [ "$varname" = "bar" ]; then
    echo "this is bar"
else
    echo "neither"
fi

# 复杂条件判断，注意 || 和 && 是完全兼容 POSIX 的推荐写法
if [ $x -gt 10 ] && [ $x -lt 20 ]; then
    echo "yes, between 10 and 20"
fi

# 可以用 && 命令连接符来做和上面完全等价的事情
[ $x -gt 10 ] && [ $x -lt 20 ] && echo "yes, between 10 and 20"

# 小括号和 -a -o 是 POSIX XSI 扩展写法，小括号是字面量，输入时前面要加反斜杆
if [ \( $x -gt 10 \) -a \( $x -lt 20 \) ]; then
    echo "yes, between 10 and 20"
fi

# 同样可以用 && 命令连接符来做和上面完全等价的事情
[ \( $x -gt 10 \) -a \( $x -lt 20 \) ] && echo "yes, between 10 and 20"


# 判断程序存在的话就执行
[ -x /bin/ls ] && /bin/ls -l

# 如果不考虑兼容 posix sh 和 dash 这些的话，可用 bash 独有的 ((..)) 和 [[..]]:
https://www.ibm.com/developerworks/library/l-bash-test/index.html


##############################################################################
# 流程控制：while / for / case / until 
##############################################################################

# while 循环
while condition; do
    statements
done

i=1
while [ $i -le 10 ]; do
    echo $i; 
    i=$(expr $i + 1)
done

# for 循环：上面的 while 语句等价
for i in {1..10}; do
    echo $i
done

for name [in list]; do
    statements
done

# for 列举某目录下面的所有文件
for f in /home/*; do 
    echo $f
done

# bash 独有的 (( .. )) 语句，更接近 C 语言，但是不兼容 posix sh
for (( initialisation ; ending condition ; update )); do
    statements
done

# 和上面的写法等价
for ((i = 0; i < 10; i++)); do echo $i; done

# case 判断
case expression in 
    pattern1 )
        statements ;;
    pattern2 )
        statements ;;
    * )
        otherwise ;;
esac

# until 语句
until condition; do
    statements
done

# select 语句
select name [in list]; do
  statements that can use $name
done


##############################################################################
# 命令处理
##############################################################################

command ls                         # 忽略 alias 直接执行程序或者内建命令 ls
builtin cd                         # 忽略 alias 直接运行内建的 cd 命令
enable                             # 列出所有 bash 内置命令，或禁止某命令
help {builtin_command}             # 查看内置命令的帮助（仅限 bash 内置命令）

eval $script                       # 对 script 变量中的字符串求值（执行）


##############################################################################
# 输出/输入 重定向
##############################################################################

cmd1 | cmd2                        # 管道，cmd1 的标准输出接到 cmd2 的标准输入
< file                             # 将文件内容重定向为命令的标准输入
> file                             # 将命令的标准输出重定向到文件，会覆盖文件
>> file                            # 将命令的标准输出重定向到文件，追加不覆盖
>| file                            # 强制输出到文件，即便设置过：set -o noclobber
n>| file                           # 强制将文件描述符 n的输出重定向到文件
<> file                            # 同时使用该文件作为标准输入和标准输出
n<> file                           # 同时使用文件作为文件描述符 n 的输出和输入
n> file                            # 重定向文件描述符 n 的输出到文件
n< file                            # 重定向文件描述符 n 的输入为文件内容
n>&                                # 将标准输出 dup/合并 到文件描述符 n
n<&                                # 将标准输入 dump/合并 定向为描述符 n
n>&m                               # 文件描述符 n 被作为描述符 m 的副本，输出用
n<&m                               # 文件描述符 n 被作为描述符 m 的副本，输入用
&>file                             # 将标准输出和标准错误重定向到文件
<&-                                # 关闭标准输入
>&-                                # 关闭标准输出
n>&-                               # 关闭作为输出的文件描述符 n
n<&-                               # 关闭作为输入的文件描述符 n
diff <(cmd1) <(cmd2)               # 比较两个命令的输出


##############################################################################
# 文本处理 - cut
##############################################################################

cut -c 1-16                        # 截取每行头16个字符
cut -c 1-16 file                   # 截取指定文件中每行头 16个字符
cut -c3-                           # 截取每行从第三个字符开始到行末的内容
cut -d':' -f5                      # 截取用冒号分隔的第五列内容
cut -d';' -f2,10                   # 截取用分号分隔的第二和第十列内容
cut -d' ' -f3-7                    # 截取空格分隔的三到七列
echo "hello" | cut -c1-3           # 显示 hel
echo "hello sir" | cut -d' ' -f2   # 显示 sir
ps | tr -s " " | cut -d " " -f 2,3,4  # cut 搭配 tr 压缩字符


##############################################################################
# 文本处理 - awk / sed 
##############################################################################

awk '{print $5}' file              # 打印文件中以空格分隔的第五列
awk -F ',' '{print $5}' file       # 打印文件中以逗号分隔的第五列
awk '/str/ {print $2}' file        # 打印文件中包含 str 的所有行的第二列
awk -F ',' '{print $NF}' file      # 打印逗号分隔的文件中的每行最后一列 
awk '{s+=$1} END {print s}' file   # 计算所有第一列的合
awk 'NR%3==1' file                 # 从第一行开始，每隔三行打印一行

sed 's/find/replace/' file         # 替换文件中首次出现的字符串并输出结果 
sed '10s/find/replace/' file       # 替换文件第 10 行内容
sed '10,20s/find/replace/' file    # 替换文件中 10-20 行内容
sed -r 's/regex/replace/g' file    # 替换文件中所有出现的字符串
sed -i 's/find/replace/g' file     # 替换文件中所有出现的字符并且覆盖文件
sed -i '/find/i\newline' file      # 在文件的匹配文本前插入行
sed -i '/find/a\newline' file      # 在文件的匹配文本后插入行
sed '/line/s/find/replace/' file   # 先搜索行特征再执行替换
sed -e 's/f/r/' -e 's/f/r' file    # 执行多次替换
sed 's#find#replace#' file         # 使用 # 替换 / 来避免 pattern 中有斜杆
sed -i -r 's/^\s+//g' file         # 删除文件每行头部空格
sed '/^$/d' file                   # 删除文件空行并打印
sed -i 's/\s\+$//' file            # 删除文件每行末尾多余空格
sed -n '2p' file                   # 打印文件第二行
sed -n '2,5p' file                 # 打印文件第二到第五行


##############################################################################
# 排序 - sort
##############################################################################

sort file                          # 排序文件
sort -r file                       # 反向排序（降序）
sort -n file                       # 使用数字而不是字符串进行比较
sort -t: -k 3n /etc/passwd         # 按 passwd 文件的第三列进行排序
sort -u file                       # 去重排序


##############################################################################
# 快速跳转 - https://github.com/rupa/z
##############################################################################

source /path/to/z.sh               # .bashrc 中初始化 z.sh
z                                  # 列出所有历史路径以及他们的权重
z foo                              # 跳到历史路径中匹配 foo 的权重最大的目录
z foo bar                          # 跳到历史路径中匹配 foo 和 bar 权重最大的目录
z -l foo                           # 列出所有历史路径中匹配 foo 的目录及权重
z -r foo                           # 按照最高访问次数优先进行匹配跳转
z -t foo                           # 按照最近访问优先进行匹配跳转


##############################################################################
# 网络管理：ip / ifconfig / nmap ...
##############################################################################

ip a                               # 显示所有网络地址，同 ip address
ip a show eth1                     # 显示网卡 IP 地址
ip a add 172.16.1.23/24 dev eth1   # 添加网卡 IP 地址
ip a del 172.16.1.23/24 dev eth1   # 删除网卡 IP 地址
ip link show dev eth0              # 显示网卡设备属性
ip link set eth1 up                # 激活网卡
ip link set eth1 down              # 关闭网卡
ip link set eth1 address {mac}     # 修改 MAC 地址
ip neighbour                       # 查看 ARP 缓存
ip route                           # 查看路由表
ip route add 10.1.0.0/24 via 10.0.0.253 dev eth0    # 添加静态路由
ip route del 10.1.0.0/24           # 删除静态路由

ifconfig                           # 显示所有网卡和接口信息
ifconfig -a                        # 显示所有网卡（包括开机没启动的）信息
ifconfig eth0                      # 指定设备显示信息
ifconfig eth0 up                   # 激活网卡
ifconfig eth0 down                 # 关闭网卡
ifconfig eth0 192.168.120.56       # 给网卡配置 IP 地址
ifconfig eth0 10.0.0.8 netmask 255.255.255.0 up     # 配置 IP 并启动
ifconfig eth0 hw ether 00:aa:bb:cc:dd:ee            # 修改 MAC 地址

nmap 10.0.0.12                     # 扫描主机 1-1000 端口
nmap -p 1024-65535 10.0.0.12       # 扫描给定端口
nmap 10.0.0.0/24                   # 给定网段扫描局域网内所有主机
nmap -O -sV 10.0.0.12              # 探测主机服务和操作系统版本


##############################################################################
# 有趣的命令
##############################################################################

man hier                           # 查看文件系统的结构和含义
man test                           # 查看 posix sh 的条件判断帮助
man ascii                          # 显示 ascii 表
getconf LONG_BIT                   # 查看系统是 32 位还是 64 位
bind -P                            # 列出所有 bash 的快捷键
mount | column -t                  # 漂亮的列出当前加载的文件系统
curl ip.cn                         # 取得外网 ip 地址和服务商信息
disown -a && exit                  # 关闭所有后台任务并退出
cat /etc/issue                     # 查看 Linux 发行版信息
lsof -i port:80                    # 哪个程序在使用 80 端口？
showkey -a                         # 取得按键的 ASCII 码
svn diff | view -                  # 使用 Vim 来显示带色彩的 diff 输出
mv filename.{old,new}              # 快速文件改名
time read                          # 使用 CTRL-D 停止，最简单的计时功能
cp file.txt{,.bak}                 # 快速备份文件
sudo touch /forcefsck              # 强制在下次重启时扫描磁盘
find ~ -mmin 60 -type f            # 查找 $HOME 目录中，60 分钟内修改过的文件
curl wttr.in/~beijing              # 查看北京的天气预报
echo ${SSH_CLIENT%% *}             # 取得你是从什么 IP 链接到当前主机上的
echo $[RANDOM%X+1]                 # 取得 1 到 X 之间的随机数
bind -x '"\C-l":ls -l'             # 设置 CTRL+l 为执行 ls -l 命令
find / -type f -size +5M           # 查找大于 5M 的文件
chmod --reference f1 f2            # 将 f2 的权限设置成 f1 一模一样的
curl -L cheat.sh                   # 速查表大全


##############################################################################
# 常用技巧
##############################################################################

# 列出最常使用的命令
history | awk '{a[$2]++}END{for(i in a){print a[i] " " i}}' | sort -rn | head

# 列出所有网络状态：ESTABLISHED / TIME_WAIT / FIN_WAIT1 / FIN_WAIT2 
netstat -n | awk '/^tcp/ {++tt[$NF]} END {for (a in tt) print a, tt[a]}'

# 通过 SSH 来 mount 文件系统
sshfs name@server:/path/to/folder /path/to/mount/point

# 显示前十个运行的进程并按内存使用量排序
ps aux | sort -nk +4 | tail

# 在右上角显示时钟
while sleep 1;do tput sc;tput cup 0 $(($(tput cols)-29));date;tput rc;done&

# 从网络上的压缩文件中解出一个文件来，并避免保存中间文件
wget -qO - "http://www.tarball.com/tarball.gz" | tar zxvf -

# 性能测试：测试处理器性能
python -c "import test.pystone;print(test.pystone.pystones())"

# 性能测试：测试内存带宽
dd if=/dev/zero of=/dev/null bs=1M count=32768

# Linux 下挂载一个 iso 文件
mount /path/to/file.iso /mnt/cdrom -oloop

# 通过主机 A 直接 ssh 到主机 B
ssh -t hostA ssh hostB

# 下载一个网站的所有图片
wget -r -l1 --no-parent -nH -nd -P/tmp -A".gif,.jpg" http://example.com/images

# 快速创建项目目录
mkdir -p work/{project1,project2}/{src,bin,bak}

# 按日期范围查找文件
find . -type f -newermt "2010-01-01" ! -newermt "2010-06-01"

# 显示当前正在使用网络的进程
lsof -P -i -n | cut -f 1 -d " "| uniq | tail -n +2

# Vim 中保存一个没有权限的文件
:w !sudo tee > /dev/null %

# 在 .bashrc / .bash_profile 中加载另外一个文件（比如你保存在 github 上的配置）
source ~/github/profiles/my_bash_init.sh

# 反向代理：将外网主机（202.115.8.1）端口（8443）转发到内网主机 192.168.1.2:443
ssh -CqTnN -R 0.0.0.0:8443:192.168.1.2:443  user@202.115.8.1

# 正向代理：将本地主机的 8443 端口，通过 192.168.1.3 转发到 192.168.1.2:443 
ssh -CqTnN -L 0.0.0.0:8443:192.168.1.2:443  user@192.168.1.3

# socks5 代理：把本地 1080 端口的 socks5 的代理请求通过远程主机转发出去
ssh -CqTnN -D localhost:1080  user@202.115.8.1

# 终端下正确设置 ALT 键和 BackSpace 键
http://www.skywind.me/blog/archives/2021


##############################################################################
# 有用的函数
##############################################################################

# 自动解压：判断文件后缀名并调用相应解压命令
function q-extract() {
    if [ -f $1 ] ; then
        case $1 in
        *.tar.bz2)   tar -xvjf $1    ;;
        *.tar.gz)    tar -xvzf $1    ;;
        *.tar.xz)    tar -xvJf $1    ;;
        *.bz2)       bunzip2 $1     ;;
        *.rar)       rar x $1       ;;
        *.gz)        gunzip $1      ;;
        *.tar)       tar -xvf $1     ;;
        *.tbz2)      tar -xvjf $1    ;;
        *.tgz)       tar -xvzf $1    ;;
        *.zip)       unzip $1       ;;
        *.Z)         uncompress $1  ;;
        *.7z)        7z x $1        ;;
        *)           echo "don't know how to extract '$1'..." ;;
        esac
    else
        echo "'$1' is not a valid file!"
    fi
}

# 自动压缩：判断后缀名并调用相应压缩程序
function q-compress() {
    if [ -n "$1" ] ; then
        FILE=$1
        case $FILE in
        *.tar) shift && tar -cf $FILE $* ;;
        *.tar.bz2) shift && tar -cjf $FILE $* ;;
        *.tar.xz) shift && tar -cJf $FILE $* ;;
        *.tar.gz) shift && tar -czf $FILE $* ;;
        *.tgz) shift && tar -czf $FILE $* ;;
        *.zip) shift && zip $FILE $* ;;
        *.rar) shift && rar $FILE $* ;;
        esac
    else
        echo "usage: q-compress <foo.tar.gz> ./foo ./bar"
    fi
}

# 漂亮的带语法高亮的 color cat ，需要先 pip install pygments
function ccat() {
    local style="monokai"
    if [ $# -eq 0 ]; then
        pygmentize -P style=$style -P tabsize=4 -f terminal256 -g
    else
        for NAME in $@; do
            pygmentize -P style=$style -P tabsize=4 -f terminal256 -g "$NAME"
        done
    fi
}


##############################################################################
# 好玩的配置
##############################################################################

# 放到你的 ~/.bashrc 配置文件中，给 man 增加漂亮的色彩高亮
export LESS_TERMCAP_mb=$'\E[1m\E[32m'
export LESS_TERMCAP_mh=$'\E[2m'
export LESS_TERMCAP_mr=$'\E[7m'
export LESS_TERMCAP_md=$'\E[1m\E[36m'
export LESS_TERMCAP_ZW=""
export LESS_TERMCAP_us=$'\E[4m\E[1m\E[37m'
export LESS_TERMCAP_me=$'\E(B\E[m'
export LESS_TERMCAP_ue=$'\E[24m\E(B\E[m'
export LESS_TERMCAP_ZO=""
export LESS_TERMCAP_ZN=""
export LESS_TERMCAP_se=$'\E[27m\E(B\E[m'
export LESS_TERMCAP_ZV=""
export LESS_TERMCAP_so=$'\E[1m\E[33m\E[44m'

# ALT+hjkl/HJKL 快速移动光标，将下面内容添加到 ~/.inputrc 中可作用所有工具，
# 包括 bash/zsh/python/lua 等使用 readline 的工具，帮助见：info rluserman
"\eh": backward-char
"\el": forward-char
"\ej": next-history
"\ek": previous-history
"\eH": backward-word
"\eL": forward-word
"\eJ": beginning-of-line
"\eK": end-of-line


##############################################################################
# References
##############################################################################

https://github.com/Idnan/bash-guide
http://www.linuxstall.com/linux-command-line-tips-that-every-linux-user-should-know/
https://ss64.com/bash/syntax-keyboard.html
http://wiki.bash-hackers.org/commands/classictest
https://www.ibm.com/developerworks/library/l-bash-test/index.html
https://www.cyberciti.biz/faq/bash-loop-over-file/
https://linuxconfig.org/bash-scripting-tutorial
https://github.com/LeCoupa/awesome-cheatsheets/blob/master/languages/bash.sh
https://devhints.io/bash
https://github.com/jlevy/the-art-of-command-line
https://yq.aliyun.com/articles/68541

# vim: set ts=4 sw=4 tw=0 et :