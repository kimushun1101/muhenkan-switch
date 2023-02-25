OutputDir := A_ScriptDir "\muhenkan-switch"
try DirDelete OutputDir, 1
DirCreate OutputDir

for filename in ["muhenkan", "uninstall"]
{
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

for filename in ["muhenkan", "uninstall"]
{
  exe := OutputDir "\" filename ".exe"
  while not FileExist(exe)
    Sleep 1000
}
RunWait "powershell -Command `"Compress-Archive -Path `'" OutputDir "\*`' -Destination `'"  OutputDir ".zip`'`""
DirDelete OutputDir, 1