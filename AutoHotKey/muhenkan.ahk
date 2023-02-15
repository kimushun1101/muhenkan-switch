;======================================
; 準備
;======================================
#SingleInstance Force ; このスクリプトの再実行を許可する

; conf ファイルの指定
ConfFileName := A_ScriptDir "\conf.ini"

WebsiteIniKeyList := ["EngDictionary", "Thesaurus", "Translator", "SearchEngine"]
WebsiteOption := Map()
for Website in WebsiteIniKeyList
  WebsiteOption[Website] := Map("Name", Array(), "URL", Array())

WebsiteOption["EngDictionary"]["Name"] := ["Weblio英和和英辞典", "英辞郎 on the WEB", "Longman", "Oxford Learner's Dictionaries"]
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

try
{
  ; タイムスタンプの設定
  DateFormat := StrReplace(IniRead(ConfFileName, "Timestamp", "DateFormat"), "A_UserName", A_UserName)
  TimestampPosition := StrReplace(IniRead(ConfFileName, "Timestamp", "Position"), "A_UserName", A_UserName)

  ; Web サイトの設定
  WebsiteArray := Array()
  for Website in WebsiteIniKeyList
    WebsiteArray.Push(StrReplace(IniRead(ConfFileName, "Website", Website), "A_UserName", A_UserName))

  ; フォルダの設定
  FolderArray := Array()
  FolderIniKeyList := ["Folder1", "Folder2", "Folder3", "Folder4", "Folder5"]
  for Folder in FolderIniKeyList
    FolderArray.Push(StrReplace(IniRead(ConfFileName, "Folder", Folder), "A_UserName", A_UserName))

  ; ソフトウェアの設定
  SoftwareArray := Array()
  SoftwareIniKeyList := ["Editor", "Word", "EMail", "Slide", "PDF", "Browser"]
  for Software in SoftwareIniKeyList
    SoftwareArray.Push(StrReplace(IniRead(ConfFileName, "Software", Software), "A_UserName", A_UserName))
}
catch as Err
{
  StackLines := StrSplit(Err.Stack, "`n")
  ObjectLine := StrSplit(StackLines[2], "=")
  ConfParam := StrSplit(ObjectLine[2], ")")
  Run "powershell -Command `"Invoke-Item '" ConfFileName "'`""
  MsgBox ConfFileName "`nの設定が間違っています。以下の設定を見直してください。`n --- `n" SubStr(ConfParam[1], 34)
  ExitApp
}

OnExit ExitFunc
ExitFunc(ExitReason, ExitCode)
{
  if ExitReason != "Reload" and ExitReason != "Logoff" and ExitReason != "Shutdown"
  {
    MsgBox A_ScriptFullPath "`nを終了します。`n" A_ScriptDir "`nを開きます。", "終了"
    Run A_ScriptDir ; 再起動したい場合のためにこのスクリプトの場所を開いておく
  }
}

; https://www.autohotkey.com/docs/v2/KeyList.htm#SpecialKeys
; 無変換キーに同時押しを許可する
SC07B::Send "{Blind}{SC07B}"
; 変換キーに同時押しを許可する
; SC079::Send "{Blind}{SC079}" ; このスクリプトでは使っていません

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
;======================================
; エクスプローラーの表示
; 左手上段の数字キーに割り当てる
;======================================
; 指定のフォルダを最前面にする。
; もし指定したソフトが起動していなければ起動する。
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
  Run url StrReplace(StrReplace(A_Clipboard, "/", "%5C%2F"), "`r`n", " ")
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
; 左手中段 A S D F に割り当てる
;======================================
; 指定のソフトを最前面にする。
; もし指定したソフトが起動していなければ起動する。
ActiveSoftware(Software)
{
  if WinExist("ahk_exe " Software) ; https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_exe
    WinActivate
  else
    Run Software
}
; a : エディタ(Atom のA で覚えた)
SC07B & a::ActiveSoftware(SoftwareArray[1])
; w : ワード
SC07B & w::ActiveSoftware(SoftwareArray[2])
; e : E-mail
SC07B & e::ActiveSoftware(SoftwareArray[3])
; s : スライド作成
SC07B & s::ActiveSoftware(SoftwareArray[4])
; d : PDF Viewer
SC07B & d::ActiveSoftware(SoftwareArray[5])
; f : ブラウザ（FireFox のF で覚えた）
SC07B & f::ActiveSoftware(SoftwareArray[6])

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
  if (TimestampPosition = "before file name")
    Send "{F2}{Left}{SC07B}" Timestamp "_{Enter}"
  else if (TimestampPosition = "after file name")
    Send "{F2}{Right}{SC07B}_" Timestamp "{Enter}"
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
  if (TimestampPosition = "before file name")
    NewFile := dir "\" Timestamp "_" name
  else if (TimestampPosition = "after file name")
    NewFile := dir "\" name_no_ext "_" Timestamp "." ext
  else
    MsgBox "TimestampPosition が間違っています。"
  
  if FileExist(NewFile)
  {
    MsgBox NewFile "`nはすでに存在します。"
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
; 無変換キー+ z
SC07B & z::
{
  IniWrite "before file name", ConfFileName, "Timestamp", "Position"
  Timestamp := FormatTime(, DateFormat)
  MsgBox "タイムスタンプの位置を前にします。`n例：" Timestamp "_ファイル名"
  Reload
}
; 変換キー+ b
SC07B & b::
{
  IniWrite "after file name", ConfFileName, "Timestamp", "Position"
  Timestamp := FormatTime(, DateFormat)
  MsgBox "タイムスタンプの位置を後ろにします。`n例：ファイル名_" Timestamp
  Reload
}

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

;======================================
; 設定関連
; ファンクションキーに割り当てる
;======================================

; F1 でキーボード画像を出す（ヘルプ）
SC07B & F1::
{
  Run "powershell -Command `"Invoke-Item '" A_ScriptDir "\Img\keyboard.png'`""
  WinWait "keyboard.png"
  WinActivate "keyboard.png"
  WinMove 0, 0, , , "keyboard.png"
  MsgBox "設定変更は``無変換``+``F2```nフォルダやソフトの割当変更は`n割り当てたいフォルダやソフトを最前面に出した状態で``無変換``+``F3``", "Help"
  try WinClose "keyboard.png"
}
; F2 で設定の変更
SC07B & F2::
{
  MyGui := Gui("AlwaysOnTop", "設定")
  MyGui.Add("Text", "ym+10 w205 section", "現在起動しているファイル : ")
  MyGui.Add("Text", "xs+130 ys w550 BackgroundWhite", A_ScriptFullPath)
  if FileExist(A_Startup "\muhenkan_ahk_or_exe.lnk")
    TextStartup := MyGui.Add("Text",  "xs+695 ys h15 w80 Background69B076", " 自動起動ON")
  else
    TextStartup := MyGui.Add("Text",  "xs+695 ys h15 w80 BackgroundFADBDA", " 自動起動OFF")
  BtnStartUP := MyGui.Add("Button", "xs+770 ys-5", "切替").OnEvent("Click", ToggleStartUp)

  ; タイムスタンプ
  MyGui.Add("GroupBox", "xs ys+20 w290 h120 section", "タイムスタンプ")
  DateFormatList := ["yyyyMMdd", "yyMMdd", "yyyyMMdd_HHmmss"]
  if DateFormat = "yyyyMMdd"
    ChooseDateFormat := "Choose1"
  else if DateFormat = "yyMMdd"
    ChooseDateFormat := "Choose2"
  else if DateFormat = "yyyyMMdd_HHmmss"
    ChooseDateFormat := "Choose3"
  else
  {
    DateFormatList := ["yyyyMMdd", "yyMMdd", "yyyyMMdd_HHmmss" , DateFormat]
    ChooseDateFormat := "Choose4"
  }

  DateFormatComboBox := MyGui.Add("ComboBox", "xs+10 ys+20 w150 " ChooseDateFormat, DateFormatList)
  DateFormatComboBox.OnEvent("Change", ChangeTimestampExample)
  MyGui.Add("Link", "xs+170  ys+25", 'フォーマットは <a href="https://www.autohotkey.com/docs/v2/lib/FormatTime.htm">こちら</a>')
  Timestamp := FormatTime(, DateFormat)
  if (TimestampPosition = "before file name")
  {
    BeforeRadio := MyGui.Add("Radio", "xs+10  ys+55 checked", "ファイル名の前")
    AfterRadio  := MyGui.Add("Radio", "xs+10  ys+75", "ファイル名の後")
    TextTimestamp := MyGui.Add("Text",  "xs+10  ys+100 w270", "例:  " Timestamp "_ファイル名.txt")
  }
  else if (TimestampPosition = "after file name")
  {
    BeforeRadio := MyGui.Add("Radio", "xs+10  ys+55", "ファイル名の前")
    AfterRadio  := MyGui.Add("Radio", "xs+10  ys+75 checked", "ファイル名の後")
    TextTimestamp := MyGui.Add("Text",  "xs+20  ys+100 w270", "例:  ファイル名_" Timestamp ".txt")
  }
  BeforeRadio.OnEvent("Click", ChangeTimestampExample)
  AfterRadio.OnEvent("Click", ChangeTimestampExample)

  ; ウェブサイト
  MyGui.Add("GroupBox", "xs ys+125 w290 h140 section", "ウェブサイト")
  for Index, Site in ["Q 英語辞典", "R 類語辞典", "T 翻訳", "G 検索エンジン"]
    MyGui.Add("Text", "xs+10  ys+" Index*25,  Site)
  WebsiteDDL := Array()
  for KeyIndex, Key in WebsiteIniKeyList
  {
    for URLIndex, URL in WebsiteOption[Key]["URL"]
    {
      if (WebsiteArray[KeyIndex] = URL)
      {
        WebsiteDDL.Push(MyGui.Add("DDL", "w180 xs+90  ys+" KeyIndex*25  " Choose" URLIndex, WebsiteOption[Key]["Name"]))
      }
    }
  }

  ; フォルダ
  MyGui.Add("GroupBox", "xs+300 ys-125 w510 h120 section", "フォルダ")
  FolderTextBox := Array()
  for Index in ["1", "2", "3", "4", "5"]
  {
    MyGui.Add("Text", "xs+10  ys+" Index*20, Index)
    FolderTextBox.Push(MyGui.Add("Text", "w480 BackgroundWhite xs+20 ys+" Index*20, FolderArray[Index]))
    FolderTextBox[Index].OnEvent("Click", SelectFolderCallback.Bind(Index))
  }
  ; ソフトウェア
  MyGui.Add("GroupBox", "xs ys+125 w510 h140 section", "ソフトウェア")
  SoftwareTextBox := Array()
  for Index, Software in ["A エディタ", "W ワード", "E Eメール", "S スライド", "D PDF", "F ブラウザ"]
  {
    MyGui.Add("Text", "xs+10  ys+" Index*20,  Software)
    SoftwareTextBox.Push(MyGui.Add("Text", "w440 BackgroundWhite xs+60 ys+" Index*20, SoftwareArray[Index]))
    SoftwareTextBox[Index].OnEvent("Click", NavigateF3)
  }

  ; 設定ファイル
  MyGui.Add("GroupBox", "xs-300 ys+150 w810 h50 section", "設定ファイル")
  BackupFileName := A_ScriptDir "\backup.ini"
  DefaultFileName := A_ScriptDir "\default.ini"
  ConfFileDDL := MyGui.Add("DDL", "xs+10 ys+20 w650 Choose1", [ConfFileName, BackupFileName, DefaultFileName, "Another File"])
  ConfFileDDL.OnEvent("Change", ChangeSaveFileButton)
  MyGui.Add("Button", "xs+670 ys+18 w50", "読込").OnEvent("Click", LoadFile)
  SaveButton := MyGui.Add("Button", "xs+725 ys+18 w50 w80", "設定を適用")
  SaveButton.OnEvent("Click", SaveFile)

  MyGui.Show()

  ToggleStartUp(*)
  {
    if not FileExist(A_Startup "\muhenkan_ahk_or_exe.lnk")
    {
      FileCreateShortcut(A_ScriptFullPath, A_Startup "\muhenkan_ahk_or_exe.lnk")
      TextStartup.Value := " 自動起動ON"
      TextStartup.Opt("Background69B076")
      TextStartup.Redraw()
    }
    else
    {
      FileDelete(A_Startup "\muhenkan_ahk_or_exe.lnk")
      TextStartup.Value := " 自動起動OFF"
      TextStartup.Opt("BackgroundFADBDA")
      TextStartup.Redraw()
    }
  }
  ChangeTimestampExample(*)
  {
    Timestamp := FormatTime(, DateFormatComboBox.Text)
    if (BeforeRadio.Value = 1)
      TextTimestamp.Value := "例:  " Timestamp "_ファイル名.txt"
    else
      TextTimestamp.Value := "例:  ファイル名_" Timestamp ".txt"
  }
  ChangeSaveFileButton(*)
  {
    if ConfFileDDL.Text = ConfFileName
    {
      SaveButton.Text := "設定を適用"
      SaveButton.Enabled := true
    }
    else if ConfFileDDL.Text = "Another File"
    {
      MyGui.Opt("-AlwaysOnTop")
      SelectedFile := FileSelect(, ConfFileName, "Open a file", "設定ファイル (*.ini)")
      try ConfFileDDL.Delete(5)
      if SelectedFile
      {
        SplitPath(SelectedFile, , &dir, &ext, &name_no_ext)
        if ext != "ini"
          SelectedFile := dir "\" name_no_ext ".ini"
        ConfFileDDL.Add([SelectedFile])
        ConfFileDDL.Value := 5
      }
      else
        ConfFileDDL.Value := 1
      ChangeSaveFileButton()
      MyGui.Opt("AlwaysOnTop")
    }
    else if ConfFileDDL.Text = DefaultFileName
    {
      SaveButton.Text := "書換不可"
      SaveButton.Enabled := false
    }
    else
    {
      SaveButton.Text := "バックアップ"
      SaveButton.Enabled := true
    }
  }

  SelectFolderCallback(Num, *)
  {
      MyGui.Opt("-AlwaysOnTop")
      SelectedFolder := FileSelect("D", FolderTextBox[Num].Text, "Select a folder")
      if SelectedFolder
        FolderTextBox[Num].Text := SelectedFolder
      MyGui.Opt("AlwaysOnTop")    
  }
  NavigateF3(*)
  {
    MyGui.Opt("-AlwaysOnTop")
    if MsgBox("設定画面を閉じて、割り当てたいソフトを最前面に出して無変換＋F3キーを押してください。`n設定画面を閉じますか？",, 4) ="YES"
      MyGui.Destroy()
    else
      MyGui.Opt("AlwaysOnTop")    
  }
  LoadFile(*)
  {
    if not FileExist(ConfFileDDL.Text)
    {
      MyGui.Opt("-AlwaysOnTop")
      MsgBox ConfFileDDL.Text "`nは存在しません。"
      MyGui.Opt("AlwaysOnTop")
      return
    }

    MyGui.Opt("-AlwaysOnTop")
    Result := MsgBox(ConfFileDDL.Text "`nを読み込みますか？",, 4) ="No"
    MyGui.Opt("AlwaysOnTop")
    if Result
      return

    ; タイムスタンプの設定
    DateFormatComboBox.Text := StrReplace(IniRead(ConfFileDDL.Text, "Timestamp", "DateFormat"), "A_UserName", A_UserName)
    TimestampPosition := StrReplace(IniRead(ConfFileDDL.Text, "Timestamp", "Position"), "A_UserName", A_UserName)
    if (TimestampPosition = "before file name")
    {
      BeforeRadio.Value := 1
      Timestamp := FormatTime(, DateFormatComboBox.Text)
      TextTimestamp.Text := "例:  " Timestamp "_ファイル名.txt"
    }
    else if (TimestampPosition = "after file name")
    {
      AfterRadio.Value := 1
      Timestamp := FormatTime(, DateFormatComboBox.Text)
      TextTimestamp.Text := "例:  ファイル名_" Timestamp ".txt"
    }
    ; Web サイトの設定
    for KeyIndex, Key in WebsiteIniKeyList
    {
      WebsiteArray[KeyIndex] := StrReplace(IniRead(ConfFileDDL.Text, "Website", Key), "A_UserName", A_UserName)
      for URLIndex, URL in WebsiteOption[Key]["URL"]
      {
        if (WebsiteArray[KeyIndex] = URL)
          WebsiteDDL[KeyIndex].Value := URLIndex
      }
    }
    ; フォルダの設定
    for Index, Key in FolderIniKeyList
      FolderTextBox[Index].Text := StrReplace(IniRead(ConfFileDDL.Text, "Folder", Key), "A_UserName", A_UserName)
    ; ソフトウェアの設定
    for Index, Key in SoftwareIniKeyList
      SoftwareTextBox[Index].Text := StrReplace(IniRead(ConfFileDDL.Text, "Software", Key), "A_UserName", A_UserName)

    MyGui.Opt("-AlwaysOnTop")
    if ConfFileDDL.Text = ConfFileName
      MsgBox "現在の設定に戻しました。"
    else
    {
      ConfFileDDL.Value := 1
      SaveButton.Text := "設定を適用"
      SaveButton.Enabled := true
      MsgBox "設定を読み込みました。反映させるには「設定の適用」を押してください。"
    }
    MyGui.Opt("AlwaysOnTop")
  }
  SaveFile(*)
  {
    MyGui.Opt("-AlwaysOnTop")
    if ConfFileDDL.Text = ConfFileName
    {
      if MsgBox("現在の設定を変更しますか？",, 4) = "No"
        return
    }
    else
    {
      if MsgBox(ConfFileDDL.Text "`nにバックアップを取りますか？`n（現在の設定は変更されません。）",, 4) = "No"
        return
    }
    IniWrite DateFormatComboBox.Text, ConfFileDDL.Text, "Timestamp", "DateFormat"
    if (BeforeRadio.Value = 1)
      IniWrite "before file name", ConfFileDDL.Text, "Timestamp", "Position"
    else
      IniWrite "after file name", ConfFileDDL.Text, "Timestamp", "Position"

    for KeyIndex, Key in WebsiteIniKeyList
    {
      for URLIndex, URL in WebsiteOption[Key]["URL"]
      {
        if (URLIndex = WebsiteDDL[KeyIndex].Value)
          IniWrite URL, ConfFileDDL.Text, "Website", Key
      }
    }

    for Index, Key in FolderIniKeyList
      IniWrite StrReplace(FolderTextBox[Index].Text, A_UserName, "A_UserName"), ConfFileDDL.Text, "Folder", Key
    for Index, Key in SoftwareIniKeyList
      IniWrite StrReplace(SoftwareTextBox[Index].Text,  A_UserName, "A_UserName"), ConfFileDDL.Text, "Software", Key

    if ConfFileDDL.Text = ConfFileName
    {
      MsgBox("設定を変更しました。`n設定画面を閉じます。")
      Reload
    }
    else
    {
      MsgBox(ConfFileDDL.Text "`nにバックアップを作成しました。`n現在の変更を反映させるには「設定の適用」を押してください。")
      ConfFileDDL.Value := 1
      SaveButton.Text := "設定を適用"
    }
  }
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
    EnableKeys := "a, w, e, s, d, f"
  }
  else
  {
    CurrentKeys := "1 : " FolderArray[1] "`n2 : " FolderArray[2] "`n3 : " FolderArray[3] "`n4 : " FolderArray[4] "`n5 : " FolderArray[5]
    EnableKeys := "1, 2, 3, 4, 5"
  }
  IB := InputBox(Path "`nに上書きしたいキーを入力してください`n`n設定可能なキー: 現在の設定`n" CurrentKeys, "キーの入力", "w600 h300")
  if (IB.Result = "OK" and IB.Value)
  {
    if (EnableKeys = "1, 2, 3, 4, 5" and IB.Value = "1")
      ConfirmSetIni("Folder", "Folder1", Path)
    else if (EnableKeys = "1, 2, 3, 4, 5" and IB.Value = "2")
      ConfirmSetIni("Folder", "Folder2", Path)
    else if (EnableKeys = "1, 2, 3, 4, 5" and IB.Value = "3")
      ConfirmSetIni("Folder", "Folder3", Path)
    else if (EnableKeys = "1, 2, 3, 4, 5" and IB.Value = "4")
      ConfirmSetIni("Folder", "Folder4", Path)
    else if (EnableKeys = "1, 2, 3, 4, 5" and IB.Value = "5")
      ConfirmSetIni("Folder", "Folder5", Path)
    else if (EnableKeys = "a, w, e, s, d, f" and IB.Value = "a")
      ConfirmSetIni("Software", "Editor", Path)
    else if (EnableKeys = "a, w, e, s, d, f" and IB.Value = "w")
      ConfirmSetIni("Software", "Word", Path)
    else if (EnableKeys = "a, w, e, s, d, f" and IB.Value = "e")
      ConfirmSetIni("Software", "EMail", Path)
    else if (EnableKeys = "a, w, e, s, d, f" and IB.Value = "s")
      ConfirmSetIni("Software", "Slide", Path)
    else if (EnableKeys = "a, w, e, s, d, f" and IB.Value = "d")
      ConfirmSetIni("Software", "PDF", Path)
    else if (EnableKeys = "a, w, e, s, d, f" and IB.Value = "f")
      ConfirmSetIni("Software", "Browser", Path)
    else
    {
      MsgBox IB.Value " には設定できません。"
    }
  }
}
ConfirmSetIni(Sec, Key, Path)
{
  if (MsgBox(Key "を以下に設定します。`n" Path, , 1) = "OK")
  {
    IniWrite Path, ConfFileName, Sec, Key
    Reload
  }
}

; F4 でスクリプトを終了 Alt + F4 から連想
SC07B & F4::
{
  if (MsgBox("スクリプトを終了しますか？`n", , 1) = "OK")
    ExitApp
}
; F5 でAutoHotKey のスクリプトをセーブ&リロード（デバッグ用）
SC07B & F5::
{
  Send "^s"
  MsgBox A_ScriptFullPath "`nをセーブ&リロード"
  Reload
}
;---------------------------------------
; CapsLock キーをCtrl キーへ変更
; 日本語キーボードではうまく動作しないのでCtrl2Cap に任せている
;---------------------------------------
; https://www.autohotkey.com/docs/v2/KeyList.htm#IME
; ここも試してみたが、2回目以降からCapsLock UP が効かない状況、までは確認済み