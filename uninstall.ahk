CurrentVersion := "v1.3.2"
; release.ahk によって書き換えられる

#Requires AutoHotkey v2.0

if not FileExist(A_ScriptDir "\muhenkan.exe")
{
  MsgBox "muhenkan.exe がありません。`nフォルダごと削除してください。"
  return
}

if MsgBox("アンイストールしますか？", , "OKCancel Default2") = "Cancel"
  return

DetectHiddenWindows True
try WinKill A_ScriptDir "\muhenkan.exe"

try FileDelete A_ScriptDir "\..\muhenkan-switch.zip"
try DirDelete  A_ScriptDir "\img", 1
try FileDelete A_ScriptDir "\*"
try FileDelete A_Startup "\muhenkan_ahk_or_exe.lnk"

MsgBox "uninstall.exe は手動で削除してください。"