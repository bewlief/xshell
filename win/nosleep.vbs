
' disable screen auto lock in windows
' wcript.exe nosleep.vbs

Dim objResult
Dim intervalSec
Dim durationSec
Dim cnt
Dim duration

intervalSec=60

'Set objArgs=WScript.Arguments
'duration=objArgs(0)
'WScript.echo duration

' 运行的总时长
durationSec=720000
cnt=0

Set objShell=WScript.CreateObject("WScript.Shell")

Do While True
    objResult=objShell.sendkeys("{NUMLOCK}{NUMLOCK}")
    Wscript.Sleep(intervalSec * 1000)
    cnt=cnt+1

    if durationSec <= (intervalSec*cnt) Then
        Exit Do
    End If 
Loop
