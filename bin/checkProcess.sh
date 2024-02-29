#!/Users/xinj/xsoft/m/bin/bash
#filename: checkProcess.sh
#示例：每分钟检测httpd是否在运行，不在运行则重启
#crontab -e
# 加入：*/1 * * * * checkProcess.sh "httpd" "/etc/init.d/httpd start"
#-------------------------------
# 函数: checkProcess
# 功能: 检查一个进程是否存在
# 参数: $1 --- 要检查的进程名称（可以加入路径，增强唯一性）
# 返回: 如果存在返回1, 否则返回0.
#-------------------------------
checkProcess() {
    # 检查输入的参数是否有效
    if [ "$1" = "" ]; then
        return 0
    fi

    #$PROCESS_NUM获取指定进程名的数目（过滤文件名 checkProcess.sh）
    #【此处做了修订，加入grep -v "checkProcess.sh"，对应修改IS_RUNNING_NUM=3 为 IS_RUNNING_NUM=1】
    PROCESS_NUM=$(ps -ef | grep "$1" | grep -v "grep" | grep -v "checkProcess.sh" | wc -l)

    #判断进程正在运行的数量
    IS_RUNNING_NUM=1

    echo "Current Process num:$PROCESS_NUM"

    #实际进程数PROCESS_NUM小于判断为运行中的数IS_RUNNING_NUM，表示有错误，需要重新启动
    if [ $PROCESS_NUM -lt $IS_RUNNING_NUM ]; then
        return 0
    else
        return 1
    fi
}

#如果参数1或者参数2为空，提示用法
if [ -z "$1" -o -z "$2" ]; then
    echo "Usage: checkProcess.sh process execCommand"
    echo 'Example: checkProcess.sh "httpd" "/etc/init.d/httpd start"'
    exit
fi

# 检查test实例是否已经存在
# checkProcess.sh "httpd" "/etc/init.d/httpd start"
checkProcess $1
checkResult=$?
if [ $checkResult -eq 0 ]; then
    # 杀死所有test进程，可换任意你需要执行的操作
    killall -9 $1
    echo "Now execute: $2"
    # 在后台执行程序
    exec $2 &
else
    echo "Process is running"
fi
