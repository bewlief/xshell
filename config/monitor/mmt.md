

## 使用 MultiMonitorTool 实现命令行切换屏幕，更改分辨率及刷新频率

主屏幕：笔记本的屏幕

扩展屏：外置显示器

1. 运行 mmt.exe，将各种状态下的屏幕参数导出为不同的配置文件
    + extend.cfg: 主屏幕+扩展屏，扩展屏不使用PBP，分辨率设置为最大
    + pbp-extend.cfg：主屏幕+扩展屏，为PBP
    + pbp-external.cfg：主屏幕关闭，仅使用扩展屏，且为PBP
    + external.cfg：主屏幕关闭，仅使用扩展屏，未开启PBP，分辨率最大
2. 命令行切换配置文件
    ```shell
   mmt /LoadConfig extend.cfg
   ```
4. --


## MultiMonitorTool的常用命令
 <Monitor>的取值：
- Primary 主屏幕
- Monitor Name: \\.\DISPLAY1  , \\.\DISPLAY2, \\.\DISPLAY3，从导出的配置文件中可以看到
- Monitor Num1ber：使用序列号来代替name 
- Monitor ID:  MONITOR\GSM59A4\{4d36e96e-e325-11ce-bfc1-08002be10318}\0008

| /disable <Monitors>                                          | 禁止屏幕，如：<br/>MultiMonitorTool.exe /disable 1   <br/>MultiMonitorTool.exe /disable \\.\DISPLAY3  <br/>MultiMonitorTool.exe /disable  1 2 3 |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| /enable <Monitors>                                           | 启用屏幕，如：<br/>MultiMonitorTool.exe  /enable 3  <br/>MultiMonitorTool.exe /enable \\.\DISPLAY1  <br/>MultiMonitorTool.exe  /enable 3 2 |
| /switch <Monitors>                                           | 切换屏幕状态，<br/>MultiMonitorTool.exe /switch 3  <br/>MultiMonitorTool.exe  /switch \\.\DISPLAY1  <br/>MultiMonitorTool.exe /switch \\.\DISPLAY2 \\.\DISPLAY3 |
| /setmax <Monitors>                                           | 将屏幕分辨率设置为最大，但不会自动设置刷新率<br/> MultiMonitorTool.exe /setmax 3  <br/>MultiMonitorTool.exe /setmax \\.\DISPLAY2  \\.\DISPLAY3 |
| /SetOrientation <Monitor> <Orientation [0, 90, 180, 270]  >  | 设置屏幕的显示方向<br/>MultiMonitorTool.exe /SetOrientation 2 270  <br/>MultiMonitorTool.exe  /SetOrientation \\.\DISPLAY2 180 \\.\DISPLAY3 90 <br/>MultiMonitorTool.exe  /SetOrientation 1 0 2 0<br/>0：默认的水平显示，90：向左垂直 ...... |
| /SetPrimary <Monitor>                                        | 设置为主屏幕<br/>MultiMonitorTool.exe /SetPrimary  2  <br/>MultiMonitorTool.exe /SetPrimary \\.\DISPLAY2 |
| /SetNextPrimary                                              | 例如，3个显示器时，该命令会将第二个显示器设置为primary，再运行该命令，将第三个设置为primary，再运行，则重新将第一个设置为primary |
| /PreviewOnly <Monitor> {x} {y} {width} {height}              | 打开一个小窗口，显示指定屏幕上的内容<br/> MultiMonitorTool.exe /PreviewOnly \\.\DISPLAY2  <br/>MultiMonitorTool.exe  /PreviewOnly \\.\DISPLAY1 10 10 300 200 |
| /SaveConfig <Filename>                                       | 保存当前屏幕的设置<br/> MultiMonitorTool.exe  /SaveConfig "c:\temp\monitors1.cfg" |
| /LoadConfig <Filename>                                       | 读入屏幕设置<br/> MultiMonitorTool.exe /LoadConfig "c:\temp\monitors1.cfg" |
| /MoveWindow <To Monitor> Process <Process Name>   /MoveWindow <To Monitor> Title <Title Text>  /MoveWindow  <To Monitor> Class <Window Class>  /MoveWindow <To Monitor>  All <From Monitor> | This command-line allows you to move windows from one monitor to the other,  according to the specified conditions. You can also use this command-line option  with /WindowLeft, /WindowTop, /WindowWidth, and /WindowHeight, in order to set  the width/size of the moved window. (See examples below)  Here's some  example:  Move all windows located on all monitors to the primary monitor: (The  <From Monitor> parameter is omitted, so windows are moved from all  monitors)  <br/>MultiMonitorTool.exe /MoveWindow Primary All  <br/><br/>Move all windows of Internet Explorer to the primary monitor:   MultiMonitorTool.exe /MoveWindow Primary Process "iexplore.exe"  <br/><br/>Move all windows of Firefox to the next monitor: <br/> MultiMonitorTool.exe  /MoveWindow Next Process "firefox.exe"  <br/><br/>Move all windows that their title contains the 'Hello World' string to  '\\.\DISPLAY2' monitor: <br/> MultiMonitorTool.exe /MoveWindow 2 Title "Hello  World"  <br/><br/>Move all windows of Windows Explorer (with 'CabinetWClass' window class) to  '\\.\DISPLAY3' monitor: <br/> MultiMonitorTool.exe /MoveWindow 3 Class  "CabinetWClass"  <br/><br/>Move all windows from '\\.\DISPLAY3' monitor to '\\.\DISPLAY2' monitor:   MultiMonitorTool.exe /MoveWindow 2 All 3 <br/><br/> Move all windows of Firefox to the next monitor, and set their position to  (10, 10), relatively to the target monitor.  MultiMonitorTool.exe /MoveWindow  Next Process "firefox.exe" /WindowLeft 10 /WindowTop 10  <br/><br/>Move all windows of Firefox to the next monitor, and set their width to  (600, 400). <br/> MultiMonitorTool.exe /MoveWindow Next Process "firefox.exe"  /WindowWidth 600 /WindowHeight 400 |
| /MonitorPreviewWindow <0 \| 1>                               | Specifies whether to display the monitor preview window. 0 = No, 1 = Yes. |
| /PreviewMode <1 \| 2>                                        | Specifies the preview mode. 1 = Fast and Low Quality, 2 = Slow and High  Quality. |
| /DrawCursorPreview <0 \| 1>                                  | Specifies whether to draw the cursor inside the preview window. 0 = No, 1 =  Yes. |
| /HideInactiveMonitors <0 \| 1>                               | Specifies whether to hide inactive monitors. 0 = No, 1 = Yes. |
| /TrayIcon <0 \| 1>                                           | Specifies whether to put an icon on the system tray. 0 = No, 1 = Yes. |
| /StartAsHidden <0 \| 1>                                      | Specifies whether to start the main window as hidden. 0 = No, 1 = Yes.   Ths command-line option works only when TrayIcon option is turned on. |
| /AutoRefresh <0 \| 1>                                        | Specifies whether to automatically refresh the monitors/windows information.  0 = No, 1 = Yes. |
| /stext <Filename>                                            | Save the monitors list into a regular text file.             |
| /stab <Filename>                                             | Save the monitors list into a tab-delimited text file.       |
| /scomma <Filename>                                           | Save the monitors list into a comma-delimited text file (csv). |
| /stabular <Filename>                                         | Save the monitors list into a tabular text file.             |
| /shtml <Filename>                                            | Save the monitors list into HTML file (Horizontal).          |
| /sverhtml <Filename>                                         | Save the monitors list into HTML file (Vertical).            |
| /sxml <Filename>                                             | Save the monitors list to XML file.                          |
