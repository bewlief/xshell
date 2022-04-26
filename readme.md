## xshell

### vmrun

+ 用于命令行操作vmware得虚拟机，复制自 C:\Program Files (x86)\VMware\VMware Workstation/
+ 需要文件包括：

```shell
libcrypto-1_1.dll  
libssl-1_1.dll  
libxml2.dll  
vix.dll  
vmrun.exe  
vnetlib.dll  
zlib1.dll
```

+ 直接调用原目录下的vmrun

```shell
global.ini: 
    VMRUN_EXE="C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe"

# alias vmrun="${VMRUN_EXE[@]}" 是无效的
function vmrun(){
    "${VMRUN_EXE[@]}" "$@"
}
```

### windows下的sudo脚本

+ sudo.cmd调用sudu.vbs实现提权，根据UAC的设置，可能会弹出确认的对话框。
+ 使用：

```shell
alias sudo="$MY_BASH_HOME/sudo.cmd"
sudo /?
```
