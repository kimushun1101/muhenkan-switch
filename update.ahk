CurrentVersion := "v.1.1.0"
; release.ahk によって書き換えられる
if not FileExist(A_ScriptDir "\muhenkan.exe")
{
  MsgBox "muhenkan.exe がありません。`nアップデートを中止します。"
  return
}

req := ComObject("Msxml2.XMLHTTP")
req.open("GET", "https://api.github.com/repos/kimushun1101/muhenkan-switch/releases/latest", false)
req.send()

; https://www.autohotkey.com/boards/viewtopic.php?t=107697
htmlfile := ComObject('htmlfile')
htmlfile.write('<meta http-equiv="X-UA-Compatible" content="IE=edge">')
LatestVersion := htmlfile.parentWindow.JSON.parse(req.responseText).tag_name

if CurrentVersion = LatestVersion
{
  MsgBox "現在のバージョン：" CurrentVersion "`n現在のバージョンは最新です。"
  return
}
else
{
  if MsgBox("現在のバージョン：" CurrentVersion "`n最新のバージョン：" LatestVersion "`nアップデートしますか？", , "YesNo") = "No"
    return
}

DetectHiddenWindows True
try WinKill A_ScriptDir "\muhenkan.exe"

URL := "https://github.com/kimushun1101/muhenkan-switch/releases/latest/download/muhenkan-switch.zip"
LatestZip := A_ScriptDir "\latest.zip"
Download URL, LatestZip

LatestDir := A_ScriptDir "\latest"
try DirDelete LatestDir, 1
DirCreate LatestDir

while not FileExist(LatestZip)
  Sleep 1000

RunWait("powershell -Command `"Expand-Archive -Path " LatestZip " -Destination "  LatestDir "`"")

; ini ファイルを退避
FileMove A_ScriptDir "\*.ini", LatestDir "\*.ini"

; 現在のフォルダとimg フォルダの中身を削除
try FileDelete A_ScriptDir "\*"
try FileDelete A_ScriptDir "\img\*"

; latest フォルダのファイルを移動して、latest フォルダを削除
FileMove LatestDir "\img\*", A_ScriptDir "\img\*"
FileMove LatestDir "\*", A_ScriptDir "\*"
DirDelete LatestDir, 1

MsgBox "アップデートが完了しました。"
Run A_ScriptDir "\muhenkan.exe"