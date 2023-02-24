;======================================
; 準備
;======================================
#SingleInstance Force ; このスクリプトの再実行を許可する

ConfFileName := A_ScriptDir "\conf.ini"

DateFormatList := ["yyyyMMdd", "yyyyMMdd_HHmm", "yyMMdd", "yyMMdd_HHmm"]
FolderKeys   := "1,2,3,4,5"
SoftwareKeys := "A,W,E,S,D,F"

FolderIniKeyList := ["Folder1", "Folder2", "Folder3", "Folder4", "Folder5"]
SoftwareIniKeyList := ["ExeA", "ExeW", "ExeE", "ExeS", "ExeD", "ExeF"]
SoftwareLabelList := ["エディタ", "ワード", "Eメール", "スライド", "PDF", "ブラウザ"]

WebsiteIniKeyList := ["EngDictionary", "Thesaurus", "Translator", "SearchEngine"]
WebsiteOption := Map()
for Website in WebsiteIniKeyList
  WebsiteOption[Website] := Map("Name", Array(), "URL", Array())

WebsiteOption["EngDictionary"]["Name"] := ["Weblio英和和英辞典", "英辞郎 on the WEB", "Longman", "Oxford"]
WebsiteOption["EngDictionary"]["URL"] := [
  "https://ejje.weblio.jp/content/",
  "https://eow.alc.co.jp/search?q=",
  "https://www.ldoceonline.com/dictionary/",
  "https://www.oxfordlearnersdictionaries.com/definition/english/"
]
WebsiteOption["Thesaurus"]["Name"] := ["Weblio類語辞典","連想類語辞典"]
WebsiteOption["Thesaurus"]["URL"] := [
  "https://thesaurus.weblio.jp/content/",
  "https://renso-ruigo.com/word/"
]
WebsiteOption["Translator"]["Name"] := ["DeepL 翻訳","Google 翻訳"]
WebsiteOption["Translator"]["URL"] := [
  "https://www.deepl.com/translator#en/ja/",
  "https://translate.google.co.jp/?hl=ja&sl=auto&tl=ja&text="
]
WebsiteOption["SearchEngine"]["Name"] := ["Google","DuckDuckGo","Microsoft Bing","Yahoo"]
WebsiteOption["SearchEngine"]["URL"] := [
  "https://www.google.co.jp/search?q=",
  "https://duckduckgo.com/?q=",
  "https://www.bing.com/search?q=",
  "https://search.yahoo.co.jp/search?p="
]

CharList := ["%", "`r`n", "`"", "#", "$", "&", "`'", "(", ")", "*", "+", ",", "/", "`:", "`;", "<", "=", ">", "?", "@", "`[", "`]", "^", "``", "`{", "|", "`}", "~"]
URLChar := Map()
URLChar["%"] :=	"%25"
URLChar["`r`n"] := "%20"
URLChar["`""] := "%22"
URLChar["#"] :=	"%23"
URLChar["$"] :=	"%24"
URLChar["&"] :=	"%26"
URLChar["`'"] := "%27"
URLChar["("] :=	"%28"
URLChar[")"] :=	"%29"
URLChar["*"] :=	"%2A"
URLChar["+"] :=	"%2B"
URLChar[","] :=	"%2C"
URLChar["/"] :=	"%5C%2F"
URLChar["`:"] := "%3A"
URLChar["`;"] := "%3B"
URLChar["<"] :=	"%3C"
URLChar["="] :=	"%3D"
URLChar[">"] :=	"%3E"
URLChar["?"] :=	"%3F"
URLChar["@"] :=	"%40"
URLChar["`["] := "%5B"
URLChar["`]"] := "%5D"
URLChar["^"] :=	"%5E"
URLChar["``"] := "%60"
URLChar["`{"] := "%7B"
URLChar["|"] :=	"%5C%7C"
URLChar["`}"] := "%7D"
URLChar["~"] :=	"%7E"

SoftwarePath(ext)
{
  try
  {
    SoftwareProgid := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\." ext "\UserChoice", "Progid")
    OpenCommand := RegRead("HKEY_CLASSES_ROOT\" SoftwareProgid "\shell\open\command")
    TestArray := StrSplit(OpenCommand, "`"")
    return TestArray[2]
  }
  catch
    return "未設定"
}


; Default Setting
OpenSetting := 1
DateFormat := "yyyyMMdd"
TimestampPosition := "before file name"
WebsiteArray := Array()
for Website in WebsiteIniKeyList
  WebsiteArray.Push(WebsiteOption[Website]["URL"][1])
FolderArray := Array()
FolderArray.Push("C:\Users\A_UserName\Documents")
FolderArray.Push("C:\Users\A_UserName\Downloads")
FolderArray.Push("C:\Users\A_UserName\Desktop")
FolderArray.Push("C:\Users\A_UserName\OneDrive")
FolderArray.Push("shell:RecycleBinFolder")
SoftwareArray := Array()
SoftwareArray.Push(SoftwarePath("txt"))
SoftwareArray.Push(SoftwarePath("docx"))
SoftwareArray.Push(SoftwarePath("eml"))
SoftwareArray.Push(SoftwarePath("pptx"))
SoftwareArray.Push(SoftwarePath("pdf"))
SoftwareArray.Push(SoftwarePath("html"))

; 設定の読み込み、無ければ作成
if FileExist(ConfFileName)
  LoadFile(ConfFileName)
else
  SaveFile(ConfFileName)

LoadFile(FileName)
{
  global ; 変数書き込みを行うためglobal を指定
  try
  {
    ; 設定画面を開くか？
    OpenSetting := IniRead(FileName, "Open", "Setting")
    ; タイムスタンプの設定
    DateFormat := IniRead(FileName, "Timestamp", "DateFormat")
    TimestampPosition := IniRead(FileName, "Timestamp", "Position")

    ; Web サイトの設定
    WebsiteArray := Array()
    for Website in WebsiteIniKeyList
      WebsiteArray.Push(IniRead(FileName, "Website", Website))

    ; フォルダの設定
    FolderArray := Array()
    for Folder in FolderIniKeyList
      FolderArray.Push(StrReplace(IniRead(FileName, "Folder", Folder), "A_UserName", A_UserName))

    ; ソフトウェアの設定
    SoftwareArray := Array()
    for Software in SoftwareIniKeyList
      SoftwareArray.Push(StrReplace(IniRead(FileName, "Software", Software), "A_UserName", A_UserName))
  }
  catch
  {
    MsgBox FileName "`nこのファイルは読み込めません。"
    return 0
  }
  return 1
}

SaveFile(FileName)
{
  ; global ; 変数読み込みだけのためglobal 指定は不要
  try
  {
    IniWrite 1, FileName, "Open", "Setting"
    IniWrite DateFormat, FileName, "Timestamp", "DateFormat"
    IniWrite TimestampPosition, FileName, "Timestamp", "Position"
    for Key in WebsiteIniKeyList
      IniWrite WebsiteArray[A_Index], FileName, "Website", Key
    for Key in FolderIniKeyList
      IniWrite StrReplace(FolderArray[A_Index], A_UserName, "A_UserName"), FileName, "Folder", Key
    for Key in SoftwareIniKeyList
      IniWrite StrReplace(SoftwareArray[A_Index],  A_UserName, "A_UserName"), FileName, "Software", Key
  }
  catch
  {
    MsgBox FileName "`nこのファイルは書き込めません。"
    return 0
  }
  return 1
}

; https://www.autohotkey.com/docs/v2/KeyList.htm#SpecialKeys
; 無変換キーに同時押しを許可する
SC07B::Send "{Blind}{SC07B}"
; 変換キーに同時押しを許可する
; SC079::Send "{Blind}{SC079}" ; このスクリプトでは使っていません

;======================================
; 設定GUI
; 無変換キー＋F1 で開く
;======================================
MyGui := Gui(,"設定")

FileMenu := Menu()
FileMenu.Add("開く", MenuHandler)
FileMenu.Add("保存", MenuHandler)
FileMenu.Add("名前をつけて保存", MenuHandler)
FileMenu.Add("初期設定に戻す", MenuHandler)
FileMenu.Add
FileMenu.Add("終了", MenuHandler)
MyMenuBar := MenuBar()
MyMenuBar.Add("&ファイル", FileMenu)

HelpMenu := Menu()
HelpMenu.Add("使い方", MenuHandler)
FileMenu.Add
HelpMenu.Add("アップデート確認", MenuHandler)
MyMenuBar.Add("&ヘルプ", HelpMenu)
MyGui.MenuBar := MyMenuBar

; 起動時の動作
MyGui.Add("GroupBox", "xm ym w250 h65 section", "起動時の動作")
AutoStartCheckBox := MyGui.Add("CheckBox", "xs+10 ys+20 w235 h15", "Windows 起動時にこのソフトを自動実行する")
OpenSettingCheckBox := MyGui.Add("CheckBox", "xs+10 ys+40 w235 h15", "ソフト起動時にこの設定ウィンドウを開く")
; タイムスタンプ
MyGui.Add("GroupBox", "xs ys+70 w250 h130 section", "タイムスタンプ")
MyGui.Add("Link", "xs+10  ys+15", 'フォーマット　（仕様は<a href="https://www.autohotkey.com/docs/v2/lib/FormatTime.htm#Date_Formats">こちら</a>）')
DateFormatListHas := 0
for DateFormatCandidate in DateFormatList
  if DateFormat = DateFormatCandidate
    DateFormatListHas := 1
if DateFormatListHas = 0
  DateFormatList.Push(DateFormat)
DateFormatComboBox := MyGui.Add("ComboBox", "xs+10 ys+30 w150", DateFormatList)
DateFormatComboBox.OnEvent("Change", ChangeTimestampExample)
BeforeRadio := MyGui.Add("Radio", "xs+10  ys+60", "ファイル名の前")
AfterRadio  := MyGui.Add("Radio", "xs+10  ys+80", "ファイル名の後")
ExampleText := MyGui.Add("Text",  "xs+10  ys+100", "例:")
TimestampText := MyGui.Add("Text",  "xs+30  ys+100 w200 BackgroundWhite", "_ファイル名.txt")
BeforeRadio.OnEvent("Click", ChangeTimestampExample)
AfterRadio.OnEvent("Click", ChangeTimestampExample)
; ウェブサイト
MyGui.Add("GroupBox", "xs ys+130 w250 h105 section", "ウェブサイト")
for Site in ["Q 英語辞典", "R 類語辞典", "T 翻訳", "G 検索エンジン"]
  MyGui.Add("Text", "xs+10  ys+" A_Index*20,  Site)
WebsiteDDL := Array()
for KeyIndex, Key in WebsiteIniKeyList
{
  for URL in WebsiteOption[Key]["URL"]
    if WebsiteArray[KeyIndex] = URL
      WebsiteDDL.Push(MyGui.Add("DDL", "w150 xs+90  ys+" KeyIndex*20  " Choose" A_Index, WebsiteOption[Key]["Name"]))
}
; フォルダ
MyGui.Add("GroupBox", "xs+260 ys-200 w510 h120 section", "フォルダ")
FolderTextBox := Array()
for Index in ["1", "2", "3", "4", "5"]
{
  MyGui.Add("Text", "xs+10  ys+" A_Index*20, Index)
  FolderTextBox.Push(MyGui.Add("Text", "w480 BackgroundWhite xs+20 ys+" A_Index*20, FolderArray[A_Index]))
  FolderTextBox[A_Index].OnEvent("Click", SelectFolderCallback.Bind(A_Index))
}
; ソフトウェア
MyGui.Add("GroupBox", "xs ys+125 w510 h140 section", "ソフトウェア")
SoftwareTextBox := Array()
for Software in ["A エディタ", "W ワード", "E Eメール", "S スライド", "D PDF", "F ブラウザ"]
{
  MyGui.Add("Text", "xs+10  ys+" A_Index*20,  Software)
  SoftwareTextBox.Push(MyGui.Add("Text", "w440 BackgroundWhite xs+60 ys+" A_Index*20, SoftwareArray[A_Index]))
  SoftwareTextBox[A_Index].OnEvent("Click", NavigateF3)
}

; 操作ボタン
SaveButton := MyGui.Add("Button", "xs+425 ys+150 w50 w80", "適用")
SaveButton.OnEvent("Click", SaveFileFromGUI.Bind(ConfFileName))

UpdateContents()
if OpenSetting
  MyGui.Show()

;======================================
; 設定GUI の関数
; 無変換キー＋F1 で開く
;======================================
; Esc を押したら閉じる
MyGui.OnEvent("Escape", GUIEsc)
GUIEsc(*)
{
  MyGui.Hide()
}
; メニューバーの機能
MenuHandler(Item, *) {
  if Item = "開く"
  {
    FileName := FileSelect(, ConfFileName, "Open a file", "設定ファイル (*.ini)")
    if LoadFile(FileName)
    {
      UpdateContents()
      if FileName != ConfFileName
        MsgBox(FileName "`nを読み込みました。`n現在の変更を反映させるには「適用」を押してください。")
    }
  }
  else if Item = "保存"
    SaveFileFromGUI(ConfFileName)
  else if Item = "名前をつけて保存"
  {
    FileName := FileSelect(, ConfFileName, "Open a file", "設定ファイル (*.ini)")
    SplitPath(FileName, , &dir, &ext, &name_no_ext)
    if ext = "ini"
      SaveFileFromGUI(dir "\" name_no_ext ".ini")
    else if ext = ""
      SaveFileFromGUI(dir "\" name_no_ext ".ini")
    else
      MsgBox FileName "`nこのファイルには保存できません"
  }
  else if Item = "初期設定に戻す"
  {
    if (MsgBox("初期設定に戻しますか？`n(現在の設定は失われます。)", , "OKCancel") = "OK")
    {
      FileDelete ConfFileName
      reload
    }
  }
  else if Item = "終了"
  {
    Result := MsgBox("ソフトを終了します。`nソフトがあるフォルダを開きますか？", , "YesNoCancel")
    if Result = "Yes"
    {
      Run A_ScriptDir
      ExitApp
    }
    else if Result = "No"
      ExitApp
  }
  else if Item = "使い方"
  {
    if FileExist(A_ScriptDir "/README.html")
      Run A_ScriptDir "/README.html"
    else
      Run "https://github.com/kimushun1101/muhenkan-switch"
    MyGui.Hide()
  }
}

UpdateContents()
{
  if FileExist(A_Startup "\muhenkan_ahk_or_exe.lnk")
    AutostartCheckBox.Value := 1
  else
    AutostartCheckBox.Value := 0
  OpenSettingCheckBox.Value := OpenSetting
  for DateFormatCandidate in DateFormatList
    if DateFormat = DateFormatCandidate
      DateFormatComboBox.Choose(A_Index)
  if (TimestampPosition = "before file name")
  {
    BeforeRadio.Value := 1
    Timestamp := FormatTime(, DateFormatComboBox.Text)
    TimestampText.Text := Timestamp "_ファイル名.txt"
  }
  else if (TimestampPosition = "after file name")
  {
    AfterRadio.Value := 1
    Timestamp := FormatTime(, DateFormatComboBox.Text)
    TimestampText.Text := "ファイル名_" Timestamp ".txt"
  }
  ; Web サイトの設定
  for KeyIndex, Key in WebsiteIniKeyList
  {
    for URLIndex, URL in WebsiteOption[Key]["URL"]
    {
      if (WebsiteArray[KeyIndex] = URL)
        WebsiteDDL[KeyIndex].Value := URLIndex
    }
  }
  ; フォルダの設定
  for Directory in FolderArray
    FolderTextBox[A_Index].Text := Directory
  ; ソフトウェアの設定
  for Software in SoftwareArray
    SoftwareTextBox[A_Index].Text := Software
}

ChangeTimestampExample(*)
{
  Timestamp := FormatTime(, DateFormatComboBox.Text)
  if (BeforeRadio.Value = 1)
    TimestampText.Value := Timestamp "_ファイル名.txt"
  else
    TimestampText.Value := "ファイル名_" Timestamp ".txt"
}
SelectFolderCallback(Num, *)
{
    SelectedFolder := FileSelect("D", FolderTextBox[Num].Text, "Select a folder")
    if SelectedFolder
      FolderTextBox[Num].Text := SelectedFolder
}
NavigateF3(*)
{
  if MsgBox("設定画面を閉じた後、`n割り当てたいソフトを最前面に出して``無変換``+``F3キー``を押してください。`n設定画面を閉じますか？",, "YesNo") ="YES"
    MyGui.Hide()
}
SaveFileFromGUI(FileName, *)
{
  if FileName = ConfFileName
  {
    if MsgBox("現在の設定を変更しますか？",, "YesNo") = "No"
      return
  }
  if AutoStartCheckBox.Value and not FileExist(A_Startup "\muhenkan_ahk_or_exe.lnk")
    FileCreateShortcut(A_ScriptFullPath, A_Startup "\muhenkan_ahk_or_exe.lnk")
  else if not AutoStartCheckBox.Value and FileExist(A_Startup "\muhenkan_ahk_or_exe.lnk")
    FileDelete(A_Startup "\muhenkan_ahk_or_exe.lnk")
  try
  {
    IniWrite OpenSettingCheckBox.Value, FileName, "Open", "Setting"
    IniWrite DateFormatComboBox.Text, FileName, "Timestamp", "DateFormat"
    if (BeforeRadio.Value = 1)
      IniWrite "before file name", FileName, "Timestamp", "Position"
    else
      IniWrite "after file name", FileName, "Timestamp", "Position"
    for KeyIndex, Key in WebsiteIniKeyList
    {
      for URLIndex, URL in WebsiteOption[Key]["URL"]
      {
        if (URLIndex = WebsiteDDL[KeyIndex].Value)
          IniWrite URL, FileName, "Website", Key
      }
    }
    for Key in FolderIniKeyList
      IniWrite StrReplace(FolderTextBox[A_Index].Text, A_UserName, "A_UserName"), FileName, "Folder", Key
    for Key in SoftwareIniKeyList
      IniWrite StrReplace(SoftwareTextBox[A_Index].Text,  A_UserName, "A_UserName"), FileName, "Software", Key
    if FileName = ConfFileName
    {
      MsgBox("設定を変更しました。")
      Reload
    }
    else
      MsgBox(FileName "`nにバックアップを作成しました。`n現在の変更を反映させるには「適用」を押してください。")
  }
  ; catch
  ;   MsgBox FileName "`nこのファイルは書き込めません。"
  catch as Err
    MsgBox FileName "`nこのファイルは書き込めません。" Err.Message
}


;======================================
; カーソル操作
; ホームポジションで使われることを想定
; 右手で操作するキーに割り当てる
;======================================
; 両手がホームポジションにあるはずとして
; 右手のアルファベットキーに割り当てる

; 無変換キー+hjkl でカーソルキー移動
SC07B & h::Send "{Blind}{Left}"
SC07B & j::Send "{Blind}{Down}"
SC07B & k::Send "{Blind}{Up}"
SC07B & l::Send "{Blind}{Right}"

; 無変換キー+u またはi で左右へ単語移動
SC07B & u::Send "{Blind}^{Left}"
SC07B & i::Send "{Blind}^{Right}"
; 無変換キー+y またはo でHome とEnd
SC07B & y::Send "{Blind}{Home}"
SC07B & o::Send "{Blind}{End}"

; BackSpace, Delete, Esc
SC07B & n::Send "{BS}"
SC07B & m::Send "{Del}"
SC07B & .::Send "{Esc}"

;======================================
; エクスプローラーの表示
; 左手上段の数字キーに割り当てる
;======================================
; 指定のフォルダを最前面にする。
; もし指定したフォルダが開かれていなかったら新規エクスプローラーで開く
ActiveFolder(folder)
{
  SplitPath(folder, &name)
  if (name = "Documents")
    name := "ドキュメント"
  else if (name = "Downloads")
    name := "ダウンロード"
  else if (name = "Desktop")
    name := "デスクトップ"
  else if (name = "RecycleBinFolder")
    name := "ごみ箱"
  else if (name = "Music")
    name := "ミュージック"
  else if (name = "Videos")
    name := "ビデオ"
  else if (name = "3D Objects")
    name := "3D オブジェクト"

  if WinExist(name)
    WinActivate
  else
    Run "explorer `"" folder "`"" 
}

SC07B & 1::ActiveFolder FolderArray[1]
SC07B & 2::ActiveFolder FolderArray[2]
SC07B & 3::ActiveFolder FolderArray[3]
SC07B & 4::ActiveFolder FolderArray[4]
SC07B & 5::ActiveFolder FolderArray[5]

;======================================
; 選択文字列を検索
; 左手上段 Q W E R T (G) に割り当てる
;======================================
; 指定したurl の後ろに選択した文字列を追加してWebページを開く
SearchClipbard(url)
{
  old_clip := ClipboardAll()
  A_Clipboard := "" ; https://www.autohotkey.com/docs/v2/lib/A_Clipboard.htm
  Send "^c"
  ClipWait
  SearchText := A_Clipboard
  for Key in CharList
    SearchText := StrReplace(SearchText, Key, URLChar[Key])
  Run url SearchText
  A_Clipboard := old_clip
}
; 文字列選択状態で、無変換キー+
; q : 英単語検索
SC07B & q::SearchClipbard WebsiteArray[1]
; r : 類語辞典
SC07B & r::SearchClipbard WebsiteArray[2]
; t : Translator
SC07B & t::SearchClipbard WebsiteArray[3]
; g : Google 検索
SC07B & g::SearchClipbard WebsiteArray[4]

;======================================
; ソフトウェアのアクティブ化
; 左手中段 A W E S D F に割り当てる
;======================================
; 指定のソフトを最前面にする
; もし指定したソフトが起動していなければ起動する
ActiveSoftware(Software, Name)
{
  if Software = "未設定"
    MsgBox Name " ソフトウェアが未設定です。`n割り当てたいソフトを最前面に出して``無変換``+``F3キー``を押してください。"
  else
  {
    if WinExist("ahk_exe " Software) ; https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_exe
      WinActivate
    else
      Run Software
  }
}
; a : エディタ(Atom のA で覚えた)
SC07B & a::ActiveSoftware(SoftwareArray[1], SoftwareIniKeyList[1])
; w : ワード
SC07B & w::ActiveSoftware(SoftwareArray[2], SoftwareIniKeyList[2])
; e : E-mail
SC07B & e::ActiveSoftware(SoftwareArray[3], SoftwareIniKeyList[3])
; s : スライド作成
SC07B & s::ActiveSoftware(SoftwareArray[4], SoftwareIniKeyList[4])
; d : PDF Viewer
SC07B & d::ActiveSoftware(SoftwareArray[5], SoftwareIniKeyList[5])
; f : ブラウザ（FireFox のF で覚えた）
SC07B & f::ActiveSoftware(SoftwareArray[6], SoftwareIniKeyList[6])

;======================================
; 選択しているファイル名やフォルダ名の操作
; 左手下段Z X C V キーに割り当てる
;======================================
;---------------------------------------
; 無変換キー+xcv で名前の先頭にタイムスタンプ
;---------------------------------------
; ファイルに最終編集日のタイムスタンプを貼り付け Ctrl + v 的なノリで
SC07B & v::
{
  old_clip := ClipboardAll()
  A_Clipboard := ""
  Send "^c"
  ClipWait(1)
  TergetFile := A_Clipboard
  A_Clipboard := old_clip
  SplitPath(TergetFile, &name, &dir, &ext, &name_no_ext)
  if (dir = "") ; 選択されているのがフォルダやファイルではない場合
    return
  Timestamp := FormatTime(FileGetTime(TergetFile, "M"), DateFormat)
  if (ext = "") ; フォルダの場合
  {
    Loop Files, TergetFile "\*", "R"  ; Recurse into subfolders.
    {
      TimestampCandidate := FormatTime(FileGetTime(A_LoopFilePath, "M"), DateFormat)
      if TimestampCandidate > Timestamp
        Timestamp := TimestampCandidate
    }
  }
  DllCall("user32.dll\SendMessageA", "UInt", DllCall("imm32.dll\ImmGetDefaultIMEWnd", "Uint", WinExist("A")), "UInt", 0x0283, "Int", 0x006, "Int", 0)
  if (TimestampPosition = "before file name")
    Send "{F2}{Left}" Timestamp "_{Enter}"
  else if (TimestampPosition = "after file name")
    Send "{F2}{Right}_" Timestamp "{Enter}"
  else
    MsgBox "TimestampPosition が間違っています。"
}
; ファイルやフォルダをコピーしてファイル最終編集日のタイムスタンプをつける
SC07B & c::
{
  old_clip := ClipboardAll()
  A_Clipboard := ""
  Send "^c"
  ClipWait(1)
  TergetFile := A_Clipboard
  A_Clipboard := old_clip
  SplitPath(TergetFile, &name, &dir, &ext, &name_no_ext)
  if (dir = "")       ; 選択されているのがフォルダやファイルではない場合
    return
  Timestamp := FormatTime(FileGetTime(TergetFile, "M"), DateFormat)
  if (ext = "") ; フォルダの場合
  {
    Loop Files, TergetFile "\*", "R"  ; Recurse into subfolders.
    {
      TimestampCandidate := FormatTime(FileGetTime(A_LoopFilePath, "M"), DateFormat)
      if TimestampCandidate > Timestamp
        Timestamp := TimestampCandidate
    }
  }
  if (TimestampPosition = "before file name")
    NewFile := dir "\" Timestamp "_" name
  else if (TimestampPosition = "after file name")
    NewFile := dir "\" name_no_ext "_" Timestamp "." ext
  else
    MsgBox "TimestampPosition が間違っています。"
  
  While FileExist(NewFile)
  {
    IB := InputBox(NewFile "`nはすでに存在します。`nファイル名を指定してください", "ファイル名の修正", , NewFile)
    if (IB.Result = "OK" and IB.Value != NewFile)
      NewFile := IB.Value
    else if IB.Result = "Cancel"
      return
  }
  if (ext = "") ; 拡張子がない=フォルダ
    DirCopy TergetFile, NewFile
  else          ; 拡張子がある=ファイル
    FileCopy TergetFile, NewFile
}
; タイムスタンプ切り取り
SC07B & x::
{
  CharCount := StrLen(DateFormat)+1
  if (TimestampPosition = "before file name")
    Send "{F2}{Left}{DEL " CharCount "}{Enter}"
  else if (TimestampPosition = "after file name")
    Send "{F2}{Right}{BS " CharCount "}{Enter}"
  else
    MsgBox "TimestampPosition が間違っています。"
}

;---------------------------------------
; タイムスタンプの位置を変更
;---------------------------------------
; ; 無変換キー+ z
; SC07B & z::
; {
;   IniWrite "before file name", ConfFileName, "Timestamp", "Position"
;   Timestamp := FormatTime(, DateFormat)
;   MsgBox "タイムスタンプの位置を前にします。`n例：" Timestamp "_ファイル名"
;   Reload
; }
; ; 変換キー+ b
; SC07B & b::
; {
;   IniWrite "after file name", ConfFileName, "Timestamp", "Position"
;   Timestamp := FormatTime(, DateFormat)
;   MsgBox "タイムスタンプの位置を後ろにします。`n例：ファイル名_" Timestamp
;   Reload
; }

;======================================
; その他
; 上記の法則から外れるがよく使うもの
;======================================
; PrintScreen を近場に置く
SC07B & p::PrintScreen

; Ctrl＋Shift＋v : 書式なし貼り付け
; エディタ（VS Code）ではCtrl＋Shift＋v を他の機能で使うので無効化しておく
HotIfWinNotActive "ahk_exe " SoftwareArray[1]
Hotkey "^+v", PastePlaneText  ; Creates a hotkey that works only in Notepad.
PastePlaneText(ThisHotkey)
{
  A_Clipboard := A_Clipboard
  Send "^v"
}

; 日付や時刻を入力
::;date::{
  SendInput FormatTime(, "yyyyMMdd")
}
::;_date::{
  SendInput FormatTime(, "yyyy_MMdd")
}
::;datetime::{
  SendInput FormatTime(, "yyyyMMdd_HHmm")
}
::;/date::{
  SendInput FormatTime(, "yyyy/MM/dd")
}
::;.date::{
  SendInput FormatTime(, "yyyy.MM.dd")
}
::;time::{
  SendInput FormatTime(, "HHmm")
}
::`:time::{
  SendInput FormatTime(, "HH:mm")
}

;======================================
; 設定関連
; ファンクションキーに割り当てる
;======================================
; F1 で設定の変更
SC07B & F1::
{
  MyGui.Show()
}
; F3 でキー割当の変更
SC07B & F3::
{
  Path := StrReplace(WinGetProcessPath(WinExist("A")), A_UserName, "A_UserName")
  if (Path = A_WinDir "\explorer.exe")
  {
    old_clip := ClipboardAll()
    A_Clipboard := ""
    Send "{Down}{Left}{Right}{Up}^c"  ; フォルダ内のファイルを何か選択してコピー
    if not ClipWait(1)
    {
      MsgBox "1. ソフトまたはフォルダを最前面にしてください。`n2. フォルダの場合、フォルダ内のファイルを選択してください。`n3. このフォルダは設定ができません。", "割り当て失敗"
      return
    }
    SelectedPath := StrReplace(A_Clipboard, A_UserName, "A_UserName")
    A_Clipboard := old_clip
    SplitPath(SelectedPath, , &dir)
    Path := dir
  }
  SplitPath(Path, &name, &dir, &ext)
  if (ext = "exe")       ; exe ファイルの場合
  {
    CurrentKeys := "a (Editor) :`t" SoftwareArray[1] "`nw (Word) :`t" SoftwareArray[2] "`ne (Email) :`t" SoftwareArray[3]  "`ns (Slide) :`t`t" SoftwareArray[4] "`nd (PDF) :`t`t" SoftwareArray[5] "`nf (Browser) :`t" SoftwareArray[6]
    EnableKeys := SoftwareKeys
  }
  else
  {
    CurrentKeys := "1 : " FolderArray[1] "`n2 : " FolderArray[2] "`n3 : " FolderArray[3] "`n4 : " FolderArray[4] "`n5 : " FolderArray[5]
    EnableKeys := FolderKeys
  }
  IB := InputBox(Path "`nに上書きしたいキー（" EnableKeys "）を入力してください`n`n設定可能なキー: 現在の設定`n" CurrentKeys, "キーの入力", "w600 h300")
  if (IB.Result = "OK" and IB.Value)
  {
    if EnableKeys = SoftwareKeys
      ConfirmIfMatchKey(SoftwareKeys, IB.Value, "Software", "Exe", Path)
    else if EnableKeys = FolderKeys
      ConfirmIfMatchKey(FolderKeys, IB.Value, "Folder", "Folder", Path)
    MsgBox IB.Value " には設定できません。`n" StrReplace(EnableKeys, ",", ", ") " から選択してください．"
  }
}
ConfirmIfMatchKey(KeysName, InputValue, Sec, Key, Path)
{
  Loop parse, KeysName, ", "
  {
    if (InputValue = A_LoopField)
    {
      if (MsgBox(SoftwareLabelList[A_Index] "を以下に設定します。`n" Path, , "OKCancel") = "OK")
      {
        IniWrite Path, ConfFileName, Sec, Key A_LoopField
        Reload
      }
    }
  }
}

; F5 でAutoHotKey のスクリプトをセーブ&リロード（デバッグ用）
SC07B & F5::
{
  Send "^s"
  ; MsgBox A_ScriptFullPath "`nをセーブ&リロード"
  Reload
}
;---------------------------------------
; CapsLock キーをCtrl キーへ変更
; 日本語キーボードではうまく動作しないのでCtrl2Cap に任せている
;---------------------------------------
; https://www.autohotkey.com/docs/v2/KeyList.htm#IME
; ここも試してみたが、2回目以降からCapsLock UP が効かない状況、までは確認済み

; MsgBox A_ScriptFullPath "`nを起動しました。"