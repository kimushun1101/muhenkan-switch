FileObj := FileOpen(A_ScriptDir "\muhenkan.ahk", "r")
FileObj.Seek(0)
FirstLine := StrSplit(FileObj.ReadLine(), "`"")
CurrentVersion := FirstLine[2]
FileObj.Close()

IB := InputBox("書き出すバージョンを指定してください。", "バージョン入力", "w250 h100", CurrentVersion)
if IB.Result = "Cancel"
  return
else
  CurrentVersion := IB.Value

; ここを書き換えて実行する

OutputDir := A_ScriptDir "\muhenkan-switch"
try DirDelete OutputDir, 1
DirCreate OutputDir

Files := ["muhenkan", "uninstall", "update"]

for filename in Files
{
  FileObj := FileOpen(A_ScriptDir "\" filename ".ahk", "rw")
  FileObj.Seek(0)
  FileObj.Write("CurrentVersion := `"" CurrentVersion "`"")
  FileObj.Close()

  ahk2exe := "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
  ahk := A_ScriptDir "\" filename ".ahk"
  exe := OutputDir "\" filename ".exe"
  ico := A_ScriptDir "\img\" filename ".ico"
  base := "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
  Run "`"" ahk2exe "`" /in `"" ahk "`" /out `"" exe "`" /icon `"" ico "`" /base `"" base "`" /compress 1"
}

DirCreate OutputDir "\img"
FileNames := Array()
FileNames.Push("img\activeapp.gif")
FileNames.Push("img\config.png")
FileNames.Push("img\keyboard.png")
FileNames.Push("img\text2web.gif")
FileNames.Push("LICENSE")
FileNames.Push("README.html")
for path in FileNames
  FileCopy A_ScriptDir "\" path, OutputDir "\" path

for filename in Files
{
  exe := OutputDir "\" filename ".exe"
  while not FileExist(exe)
    Sleep 1000
}

Ver := StrReplace(CurrentVersion, ".", "_")
FileMove OutputDir "\update.exe", OutputDir "\update_" Ver ".exe"

RunWait "powershell -Command `"Compress-Archive -Path `'" OutputDir "\*`' -Destination `'"  OutputDir ".zip`'`""
DirDelete OutputDir, 1