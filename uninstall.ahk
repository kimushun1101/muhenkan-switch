if A_ScriptName = "uninstall.ahk"
{
  MsgBox "このファイルではアンイストールをしません。"
  return
}

if MsgBox("アンイストールしますか？", , "OKCancel Default2") = "Cancel"
  return

DetectHiddenWindows True
try WinKill A_ScriptDir "\muhenkan.exe"

try FileDelete A_ScriptDir "\..\muhenkan-switch.zip"
try DirDelete A_ScriptDir "\img", 1
try DirDelete A_ScriptDir, 1
try FileDelete A_ScriptFullPath

MsgBox "uninstall.exe は手動で削除してください。"