CurrentVersion := "v.1.1.1"
; release.ahk によって書き換えられる
Ver := StrReplace(CurrentVersion, ".", "_")

; バージョン違いのupdate.exe を削除
Loop Files, A_ScriptDir "\update*.exe"
{
  if A_LoopFileFullPath != A_ScriptDir "\update_" Ver ".exe"
    FileDelete A_LoopFileFullPath
}

; スタートアップにリンクを作成
LinkFile := A_Startup "\muhenkan_ahk_or_exe.lnk"
if FileExist(LinkFile)
{
  FileGetShortcut LinkFile, &OutTarget
  if OutTarget != A_ScriptFullPath
  {
    FileDelete LinkFile
    FileCreateShortcut A_ScriptFullPath, LinkFile
  }
}
else
  FileCreateShortcut A_ScriptFullPath, LinkFile

; このスクリプトの再実行を許可する
#SingleInstance Force

; 変数の準備
ConfFileName := A_ScriptDir "\conf.ini"

DateFormatList := ["yyyyMMdd", "yyyyMMdd_HHmm", "yyMMdd", "yyMMdd_HHmm"]
FolderKeys   := "1,2,3,4,5"
SoftwareKeys := "A,W,E,S,D,F"

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

; 初期設定
OpenSetting := 1
DateFormat := "yyyyMMdd"
TimestampPosition := "before file name"

WebsiteArray := Array()
for Website in WebsiteIniKeyList
  WebsiteArray.Push(WebsiteOption[Website]["URL"][1])

FolderLabelArray := ["ドキュメント", "ダウンロード", "デスクトップ", "OneDrive", "ごみ箱"]
FolderPathArray := Array()
FolderPathArray.Push("C:\Users\A_UserName\Documents")
FolderPathArray.Push("C:\Users\A_UserName\Downloads")
FolderPathArray.Push("C:\Users\A_UserName\Desktop")
FolderPathArray.Push("C:\Users\A_UserName\OneDrive")
FolderPathArray.Push("shell:RecycleBinFolder")

SoftwareLabelArray := ["エディタ", "ワード", "Eメール", "スライド", "PDFビューア", "ブラウザ"]
SoftwarePath(ext, mailto:=false)
{
  try
  {
    if mailto
      OpenCommand := RegRead("HKEY_CURRENT_USER\Software\Classes\mailto\shell\open\command")
    else
    {
      SoftwareProgid := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\." ext "\UserChoice", "Progid")
      OpenCommand := RegRead("HKEY_CLASSES_ROOT\" SoftwareProgid "\shell\open\command")
    }
    TestArray := StrSplit(OpenCommand, "`"")
    return TestArray[2]
  }
  catch
    return "未設定"
}
SoftwareExeArray := Array()
SoftwareExeArray.Push(SoftwarePath("txt"))
SoftwareExeArray.Push(SoftwarePath("docx"))
SoftwareExeArray.Push(SoftwarePath("eml", true))
SoftwareExeArray.Push(SoftwarePath("pptx"))
SoftwareExeArray.Push(SoftwarePath("pdf"))
SoftwareExeArray.Push(SoftwarePath("html"))

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
    FolderPathArray := Array()
    FolderLabelArray := Array()
    Loop parse, FolderKeys, ","
    {
      FolderPathArray.Push(StrReplace(IniRead(FileName, "Folder", "Path" A_LoopField), "A_UserName", A_UserName))
      FolderLabelArray.Push(IniRead(FileName, "Folder", "Label" A_LoopField))
    }

    ; ソフトウェアの設定
    SoftwareExeArray := Array()
    SoftwareLabelArray := Array()
    Loop parse, SoftwareKeys, ","
    {
      SoftwareExeArray.Push(StrReplace(IniRead(FileName, "Software", "Exe" A_LoopField), "A_UserName", A_UserName))
      SoftwareLabelArray.Push(IniRead(FileName, "Software", "Label" A_LoopField))
    }
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
    IniWrite OpenSetting, FileName, "Open", "Setting"
    IniWrite DateFormat, FileName, "Timestamp", "DateFormat"
    IniWrite TimestampPosition, FileName, "Timestamp", "Position"
    for Key in WebsiteIniKeyList
      IniWrite WebsiteArray[A_Index], FileName, "Website", Key
    Loop parse, FolderKeys, ","
    {
      IniWrite StrReplace(FolderPathArray[A_Index], A_UserName, "A_UserName"), FileName, "Folder", "Path" A_LoopField
      IniWrite FolderLabelArray[A_Index], FileName, "Folder", "Label" A_LoopField
    }
    Loop parse, SoftwareKeys, ","
    {
      IniWrite StrReplace(SoftwareExeArray[A_Index], A_UserName, "A_UserName"), FileName, "Software", "Exe" A_LoopField
      IniWrite SoftwareLabelArray[A_Index], FileName, "Software", "Label" A_LoopField
    }
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
MyGui := Gui(,"設定 - 無変換スイッチ")

FileMenu := Menu()
FileMenu.Add("バックアップを作成", MenuHandler)
FileMenu.Add("バックアップを読込", MenuHandler)
FileMenu.Add("初期設定に戻す", MenuHandler)
FileMenu.Add
FileMenu.Add("終了", MenuHandler)
MyMenuBar := MenuBar()
MyMenuBar.Add("&ファイル", FileMenu)

HelpMenu := Menu()
HelpMenu.Add("使い方", MenuHandler)
HelpMenu.Add
HelpMenu.Add("アップデート確認", MenuHandler)
MyMenuBar.Add("&ヘルプ", HelpMenu)
MyGui.MenuBar := MyMenuBar

; 起動時の動作
MyGui.Add("GroupBox", "xm ym w250 h70 section", "起動時の動作")
OpenSettingCheckBox := MyGui.Add("CheckBox", "xs+10 ys+23 w235 h30", "ソフト起動時にこの設定ウィンドウを開く`n（ソフト起動中に無変換+F1キーで開けます）")
OpenSettingCheckBox.OnEvent("Click", EnableButtons)
; タイムスタンプ
MyGui.Add("GroupBox", "xs ys+75 w250 h125 section", "タイムスタンプ")
MyGui.Add("Link", "xs+10  ys+20", 'フォーマット　（仕様は<a href="https://www.autohotkey.com/docs/v2/lib/FormatTime.htm#Date_Formats">こちら</a>）')
DateFormatListHas := 0
for DateFormatCandidate in DateFormatList
  if DateFormat = DateFormatCandidate
    DateFormatListHas := 1
if DateFormatListHas = 0
  DateFormatList.Push(DateFormat)
DateFormatComboBox := MyGui.Add("ComboBox", "xs+10 ys+35 w150", DateFormatList)
DateFormatComboBox.OnEvent("Change", ChangeTimestampExample)
BeforeRadio := MyGui.Add("Radio", "xs+10  ys+65", "ファイル名の前")
AfterRadio  := MyGui.Add("Radio", "xs+10  ys+80", "ファイル名の後")
ExampleText := MyGui.Add("Text",  "xs+10  ys+100", "例:")
TimestampText := MyGui.Add("Text",  "xs+30  ys+100 w200 BackgroundWhite", "_ファイル名")
BeforeRadio.OnEvent("Click", ChangeTimestampExample)
AfterRadio.OnEvent("Click", ChangeTimestampExample)
; ウェブサイト
MyGui.Add("GroupBox", "xs ys+135 w250 h125 section", "ウェブサイト")
for Site in ["Q 英語辞典", "R 類語辞典", "T 翻訳", "G 検索エンジン"]
{
  MyGui.Add("Text", "xs+10  ys+" A_Index*25,  Site)
}
WebsiteDDL := Array()
for KeyIndex, Key in WebsiteIniKeyList
{
  for URL in WebsiteOption[Key]["URL"]
    if WebsiteArray[KeyIndex] = URL
    {
      WebsiteDDL.Push(MyGui.Add("DDL", "w150 xs+90  ys+" KeyIndex*25-3  " Choose" A_Index, WebsiteOption[Key]["Name"]))
      WebsiteDDL[KeyIndex].OnEvent("Change", EnableButtons)
    }
}
; フォルダ
MyGui.Add("GroupBox", "xs+260 ys-210 w710 h150 section", "フォルダ")
FolderButton := Array()
FolderLabelEdit := Array()
Loop parse, FolderKeys, ","
{
  MyGui.Add("Text", "xs+10 ys+" A_Index*25,  A_LoopField)
  FolderLabelEdit.Push(MyGui.Add("Edit", "w70 xs+25  ys+" A_Index*25-5,  FolderLabelArray[A_Index]))
  FolderButton.Push(MyGui.Add("Button", "0x100 w600 xs+100 ys+" A_Index*25-6, FolderPathArray[A_Index]))
  FolderButton[A_Index].OnEvent("Click", SelectFolderCallback.Bind(A_Index))
}
; ソフトウェア
MyGui.Add("GroupBox", "xs ys+160 w710 h175 section", "ソフトウェア")
SoftwareButton := Array()
SoftwareLabelEdit := Array()
Loop parse, SoftwareKeys, ","
{
  MyGui.Add("Text", "xs+10 ys+" A_Index*25,  A_LoopField)
  SoftwareLabelEdit.Push(MyGui.Add("Edit", "w70 xs+25  ys+" A_Index*25-5,  SoftwareLabelArray[A_Index]))
  SoftwareButton.Push(MyGui.Add("Button", "0x100 w600 xs+100 ys+" A_Index*25-6, SoftwareExeArray[A_Index]))
  SoftwareButton[A_Index].Name := StrSplit(SoftwareKeys, ",")[A_Index]
  SoftwareButton[A_Index].OnEvent("Click", SetSoftwareKey)
}

; 操作ボタン
ApplyButton := MyGui.Add("Button", "xs+610 ys+180 w100", "適用")
ApplyButton.OnEvent("Click", SaveFileFromGUI.Bind(ConfFileName))
ResetButton := MyGui.Add("Button", "xs-260 ys+180 w100", "現在の設定に戻す")
ResetButton.OnEvent("Click", UpdateContents)

UpdateContents()
if OpenSetting
  MyGui.Show()
myGui.OnEvent("Close", myGui_Close)

;======================================
; 設定GUI の関数
; 無変換キー＋F1 で開く
;======================================
; Esc を押したら閉じる
MyGui.OnEvent("Escape", GUIEsc)
GUIEsc(Item, *)
{
  Item.Hide()
}
EnableButtons(*)
{
  ApplyButton.Enabled := 1
  ResetButton.Enabled := 1
}
DisableButtons(*)
{
  ApplyButton.Enabled := 0
  ResetButton.Enabled := 0
}
myGui_Close(thisGui) {  ; Declaring this parameter is optional.
  if ApplyButton.Enabled
  {
    if MsgBox("設定が適用されていません。画面を閉じますか？",, "YesNo") = "No"
      return true
  }
  return false
}

; メニューバーの機能
MenuHandler(Item, *) {
  if Item = "バックアップを作成"
  {
    FileName := FileSelect(, A_ScriptDir "\backup.ini", "Open a file", "設定ファイル (*.ini)")
    if FileName = ""
      return
    if FileName = ConfFileName
    {
      MsgBox ConfFileName "`nにはバックアップを作れません。"
      return
    }
    SplitPath(FileName, , &dir, &ext, &name_no_ext)
    if ext = "ini"
      SaveFileFromGUI(dir "\" name_no_ext ".ini")
    else if ext = ""
      SaveFileFromGUI(dir "\" name_no_ext ".ini")
    else
      MsgBox FileName "`nこのファイルには保存できません"
  }
  else if Item = "バックアップを読込"
  {
    FileName := FileSelect(, A_ScriptDir "\backup.ini", "Open a file", "設定ファイル (*.ini)")
    if FileName = ""
      return
    if LoadFile(FileName)
    {
      UpdateContents()
      if FileName != ConfFileName
      {
        SaveFile(ConfFileName)
        MsgBox(FileName "`nを読み込みました。")
      }
    }
  }
  else if Item = "初期設定に戻す"
  {
    if (MsgBox("初期設定に戻しますか？`n(現在の設定は失われるためバックアップを推奨します。)", , "OKCancel Default2") = "OK")
    {
      try FileDelete ConfFileName
      reload
    }
  }
  else if Item = "終了"
  {
    if ApplyButton.Enabled
    {
      if MsgBox("設定が適用されていません。ソフトを終了しますか？",, "YesNo") = "No"
        return
    }
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
  }
  else if Item = "アップデート確認"
  {
    Run A_ScriptDir "\update_" Ver ".exe"
  }
}

UpdateContents(*)
{
  OpenSettingCheckBox.Value := OpenSetting
  for DateFormatCandidate in DateFormatList
    if DateFormat = DateFormatCandidate
      DateFormatComboBox.Choose(A_Index)
  if (TimestampPosition = "before file name")
  {
    BeforeRadio.Value := 1
    Timestamp := FormatTime(, DateFormatComboBox.Text)
    TimestampText.Text := Timestamp "_ファイル名"
  }
  else if (TimestampPosition = "after file name")
  {
    AfterRadio.Value := 1
    Timestamp := FormatTime(, DateFormatComboBox.Text)
    TimestampText.Text := "ファイル名_" Timestamp
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
  Loop parse, FolderKeys, ","
  {
    FolderLabelEdit[A_Index].Text := FolderLabelArray[A_Index]
    FolderButton[A_Index].Text := FolderPathArray[A_Index]
  }
  ; ソフトウェアの設定
  Loop parse, SoftwareKeys, ","
  {
    SoftwareLabelEdit[A_Index].Text := SoftwareLabelArray[A_Index]
    SoftwareButton[A_Index].Text := SoftwareExeArray[A_Index]
  }
  DisableButtons()
}
ChangeTimestampExample(*)
{
  EnableButtons()
  Timestamp := FormatTime(, DateFormatComboBox.Text)
  if (BeforeRadio.Value = 1)
    TimestampText.Value := Timestamp "_ファイル名"
  else
    TimestampText.Value := "ファイル名_" Timestamp
}
SelectFolderCallback(Num, *)
{
  SelectedFolder := FileSelect("D", FolderButton[Num].Text, "Select a folder")
  if SelectedFolder
  {
    FolderButton[Num].Text := SelectedFolder
    EnableButtons()
  }
}
SetSoftwareKey(Item, *)
{
  SetSoftwareKeyGui := Gui(, Item.Name " キーに割り当て")
  SetSoftwareKeyGui.Add("Text", "section", Item.Name " キーに割り当てたいソフトウェアを選択してください。`n現在起動しているソフトは以下のとおりです。更新する場合には一度閉じてから開き直してください。")
  SetSoftwareKeyGui.OnEvent("Escape", GUIEsc)
  SoftwarePaths := Map()

  for this_id in WinGetList(,, "Program Manager")
  {
    Title := WinGetTitle(this_id)
    Path := StrReplace(WinGetProcessPath(this_id), A_UserName, "A_UserName")
    if (Title != "設定 - 無変換スイッチ" and Path != A_WinDir "\explorer.exe")
    {
      word_array := StrSplit(Title, "-", A_Space)
      if word_array.Length != 0
        SoftName := word_array[word_array.Length]
      else
        SoftName := Title
      SetSoftwareKeyGui.Add("Button", "xs vid" this_id, SoftName).OnEvent("Click", ProcessUserInput)
      SetSoftwareKeyGui.Add("Text", "xs+20", Path)
      SoftwarePaths["id" this_id] := Path
    }
  }
  ProcessUserInput(SetSoftwareKeyItem, *)
  {
    if (MsgBox("無変換 + " Item.Name " キーに" SetSoftwareKeyItem.Text "を割り当てますか？", , "OKCancel") = "OK")
    {
      Item.Text := SoftwarePaths[SetSoftwareKeyItem.Name]
      EnableButtons()
      SetSoftwareKeyGui.Destroy()
    }
  }
  SetSoftwareKeyGui.Show()
}
SaveFileFromGUI(FileName, *)
{
  if FileName = ConfFileName
  {
    if MsgBox("現在の設定を変更しますか？",, "OKCancel") = "Cancel"
      return
  }
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
    Loop parse, FolderKeys, ","
    {
      IniWrite StrReplace(FolderButton[A_Index].Text, A_UserName, "A_UserName"), FileName, "Folder", "Path" A_LoopField
      IniWrite FolderLabelEdit[A_Index].Text, FileName, "Folder", "Label" A_LoopField
    }
    Loop parse, SoftwareKeys, ","
    {
      IniWrite StrReplace(SoftwareButton[A_Index].Text, A_UserName, "A_UserName"), FileName, "Software", "Exe" A_LoopField
      IniWrite SoftwareLabelEdit[A_Index].Text, FileName, "Software", "Label" A_LoopField
    }
    if FileName = ConfFileName
    {
      MsgBox("設定を変更しました。")
      Reload
    }
    else
      MsgBox(FileName "`nにバックアップを作成しました。`n現在の変更を反映させるには「適用」を押してください。")
  }
  catch
    MsgBox FileName "`nこのファイルは書き込めません。"
}

; F1 で設定の変更
SC07B & F1::
{
  MyGui.Show()
}

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

SC07B & 1::ActiveFolder FolderPathArray[1]
SC07B & 2::ActiveFolder FolderPathArray[2]
SC07B & 3::ActiveFolder FolderPathArray[3]
SC07B & 4::ActiveFolder FolderPathArray[4]
SC07B & 5::ActiveFolder FolderPathArray[5]

;======================================
; 選択文字列を検索
; 左手上段 Q R T G に割り当てる
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
    MsgBox "「" Name "」ソフトが未設定です。`n``無変換``+``F1キー``で設定を確認してください。"
  else
  {
    if WinExist("ahk_exe " Software) ; https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_exe
      WinActivate
    else
      Run Software
  }
}
; a : エディタ(Atom のA で覚えた)
SC07B & a::ActiveSoftware(SoftwareExeArray[1], SoftwareLabelArray[1])
; w : ワード
SC07B & w::ActiveSoftware(SoftwareExeArray[2], SoftwareLabelArray[2])
; e : E-mail
SC07B & e::ActiveSoftware(SoftwareExeArray[3], SoftwareLabelArray[3])
; s : スライド作成
SC07B & s::ActiveSoftware(SoftwareExeArray[4], SoftwareLabelArray[4])
; d : PDF Viewer
SC07B & d::ActiveSoftware(SoftwareExeArray[5], SoftwareLabelArray[5])
; f : ブラウザ（FireFox のF で覚えた）
SC07B & f::ActiveSoftware(SoftwareExeArray[6], SoftwareLabelArray[6])

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
SC07B & `;::Send "{Esc}"
SC07B & ,::Send "、"
SC07B & .::Send "。"

;======================================
; その他
; 上記の法則から外れるがよく使うもの
;======================================
; Ctrl＋Shift＋v : 書式なし貼り付け
; エディタ（VS Code）ではCtrl＋Shift＋v を他の機能で使うので無効化しておく
HotIfWinNotActive "ahk_exe " SoftwareExeArray[1]
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
::;dateu::{
  SendInput FormatTime(, "yyyy_MMdd")
}
::;dates::{
  SendInput FormatTime(, "yyyy/MM/dd")
}
::;dated::{
  SendInput FormatTime(, "yyyy.MM.dd")
}
::;time::{
  SendInput FormatTime(, "HHmm")
}
::;timec::{
  SendInput FormatTime(, "HH:mm")
}
::;datetime::{
  SendInput FormatTime(, "yyyyMMdd_HHmm")
}
;---------------------------------------
; CapsLock キーをCtrl キーへ変更
; 日本語キーボードではうまく動作しないのでCtrl2Cap に任せている
;---------------------------------------
; https://www.autohotkey.com/docs/v2/KeyList.htm#IME
; ここも試してみたが、2回目以降からCapsLock UP が効かない状況、までは確認済み

; MsgBox A_ScriptFullPath "`nを起動しました。"
