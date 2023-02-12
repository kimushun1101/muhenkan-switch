;======================================
; 準備
;======================================
#SingleInstance Force ; このスクリプトの再実行を許可する

; conf ファイルの指定
ConfFileName := A_ScriptDir "\conf.ini"

try
{
  ; タイムスタンプの設定
  DateFormat := StrReplace(IniRead(ConfFileName, "Timestamp", "DateFormat"), "A_UserName", A_UserName)
  TimestampPosition := StrReplace(IniRead(ConfFileName, "Timestamp", "Position"), "A_UserName", A_UserName)

  ; フォルダの設定
  Folder1 := StrReplace(IniRead(ConfFileName, "Folder", "Folder1"), "A_UserName", A_UserName)
  Folder2 := StrReplace(IniRead(ConfFileName, "Folder", "Folder2"), "A_UserName", A_UserName)
  Folder3 := StrReplace(IniRead(ConfFileName, "Folder", "Folder3"), "A_UserName", A_UserName)
  Folder4 := StrReplace(IniRead(ConfFileName, "Folder", "Folder4"), "A_UserName", A_UserName)
  Folder5 := StrReplace(IniRead(ConfFileName, "Folder", "Folder5"), "A_UserName", A_UserName)

  ; Web サイトの設定
  EngDictionary := StrReplace(IniRead(ConfFileName, "WebSite", "EngDictionary"), "A_UserName", A_UserName)
  Thesaurus := StrReplace(IniRead(ConfFileName, "WebSite", "Thesaurus"), "A_UserName", A_UserName)
  Translator := StrReplace(IniRead(ConfFileName, "WebSite", "Translator"), "A_UserName", A_UserName)
  SearchEngine := StrReplace(IniRead(ConfFileName, "WebSite", "SearchEngine"), "A_UserName", A_UserName)

  ; ソフトウェアの設定
  Editor := StrReplace(IniRead(ConfFileName, "Software", "Editor"), "A_UserName", A_UserName)
  Word := StrReplace(IniRead(ConfFileName, "Software", "Word"), "A_UserName", A_UserName)
  EMail := StrReplace(IniRead(ConfFileName, "Software", "EMail"), "A_UserName", A_UserName)
  Slide := StrReplace(IniRead(ConfFileName, "Software", "Slide"), "A_UserName", A_UserName)
  PDF := StrReplace(IniRead(ConfFileName, "Software", "PDF"), "A_UserName", A_UserName)
  Browser := StrReplace(IniRead(ConfFileName, "Software", "Browser"), "A_UserName", A_UserName)
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

SC07B & 1::ActiveFolder Folder1
SC07B & 2::ActiveFolder Folder2
SC07B & 3::ActiveFolder Folder3
SC07B & 4::ActiveFolder Folder4
SC07B & 5::ActiveFolder Folder5

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
  Run url . A_Clipboard
  A_Clipboard := old_clip
}
; 文字列選択状態で、無変換キー+
; q : 英単語検索
SC07B & q::SearchClipbard EngDictionary
; r : 類語辞典
SC07B & r::SearchClipbard Thesaurus
; t : Translator
SC07B & t::SearchClipbard Translator
; g : Google 検索
SC07B & g::SearchClipbard SearchEngine

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
SC07B & a::ActiveSoftware(Editor)
; w : ワード
SC07B & w::ActiveSoftware(Word)
; e : E-mail
SC07B & e::ActiveSoftware(EMail)
; s : スライド作成
SC07B & s::ActiveSoftware(Slide)
; d : PDF Viewer
SC07B & d::ActiveSoftware(PDF)
; f : ブラウザ（FireFox のF で覚えた）
SC07B & f::ActiveSoftware(Browser)

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
HotIfWinNotActive "ahk_exe " Editor
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
  MyGui.Add("Text", "ym+10 w200 section", "現在起動しているファイル : ")
  MyGui.Add("Text", "xs+130 ys w550 BackgroundWhite", A_ScriptFullPath)
  if FileExist(A_Startup "\muhenkan_ahk_or_exe.lnk")
    TextStartup := MyGui.Add("Text",  "xs+700 ys h15 Background69B076", "自動起動ON　")
  else
    TextStartup := MyGui.Add("Text",  "xs+700 ys h15 BackgroundFADBDA", "自動起動OFF")
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
    TextTimestamp := MyGui.Add("Text",  "xs+10  ys+100 w280", "例:  " Timestamp "_ファイル名.txt")
  }
  else if (TimestampPosition = "after file name")
  {
    BeforeRadio := MyGui.Add("Radio", "xs+10  ys+55", "ファイル名の前")
    AfterRadio  := MyGui.Add("Radio", "xs+10  ys+75 checked", "ファイル名の後")
    TextTimestamp := MyGui.Add("Text",  "xs+20  ys+100 w280", "例:  ファイル名_" Timestamp ".txt")
  }
  BeforeRadio.OnEvent("Click", ChangeTimestampExample)
  AfterRadio.OnEvent("Click", ChangeTimestampExample)

  ; ウェブサイト
  MyGui.Add("GroupBox", "xs ys+125 w290 h140 section", "ウェブサイト")
  MyGui.Add("Text", "xs+10  ys+25",  "Q 英語辞典")
  MyGui.Add("Text", "xs+10  ys+50",  "R 類語辞典")
  MyGui.Add("Text", "xs+10  ys+75",  "T 翻訳")
  MyGui.Add("Text", "xs+10  ys+100", "G 検索エンジン")
  if (EngDictionary = "https://ejje.weblio.jp/content/")
    ChooseEngDictionary := "Choose1"
  else if (EngDictionary = "https://eow.alc.co.jp/search?q=")
    ChooseEngDictionary := "Choose2"
  else if (EngDictionary = "https://www.ldoceonline.com/dictionary/")
    ChooseEngDictionary := "Choose3"
  else if (EngDictionary = "https://www.oxfordlearnersdictionaries.com/definition/english/")
    ChooseEngDictionary := "Choose4"
  if (Thesaurus = "https://thesaurus.weblio.jp/content/")
    ChooseThesaurus := "Choose1"
  else if (Thesaurus = "https://renso-ruigo.com/word/")
    ChooseThesaurus := "Choose2"
  if (Translator = "https://www.deepl.com/translator#en/ja/")
    ChooseTranslator := "Choose1"
  else if (Translator = "https://translate.google.co.jp/?hl=ja&sl=auto&tl=ja&text=")
    ChooseTranslator := "Choose2"
  if (SearchEngine = "https://www.google.co.jp/search?q=")
    ChooseSearchEngine := "Choose1"
  else if (SearchEngine = "https://duckduckgo.com/?q=")
    ChooseSearchEngine := "Choose2"
  else if (SearchEngine = "https://search.yahoo.co.jp/search?p=")
    ChooseSearchEngine := "Choose3"
  EngDictionaryDDL := MyGui.Add("DDL", "xs+130  ys+25 w100 " ChooseEngDictionary, ["Weblio","ALC","Longman","Oxford"])
  ThesaurusDDL := MyGui.Add("DDL", "xs+130  ys+50 w100 " ChooseThesaurus, ["Weblio","連想類語辞典"])
  TranslatorDDL := MyGui.Add("DDL", "xs+130  ys+75 w100 " ChooseTranslator, ["DeepL","Google 翻訳"])
  SearchEngineDDL := MyGui.Add("DDL", "xs+130  ys+100 w100 " ChooseSearchEngine, ["Google","DuckDuckGo","Yahoo"])

  ; フォルダ
  MyGui.Add("GroupBox", "xs+300 ys-125 w500 h120 section", "フォルダ")
  MyGui.Add("Text", "xs+10 ys+20",  "1")
  MyGui.Add("Text", "xs+10 ys+40",  "2")
  MyGui.Add("Text", "xs+10 ys+60",  "3")
  MyGui.Add("Text", "xs+10 ys+80",  "4")
  MyGui.Add("Text", "xs+10 ys+100", "5")
  Folder1Text := MyGui.Add("Text", "xs+20 ys+20  w470 BackgroundWhite", Folder1)
  Folder2Text := MyGui.Add("Text", "xs+20 ys+40  w470 BackgroundWhite", Folder2)
  Folder3Text := MyGui.Add("Text", "xs+20 ys+60  w470 BackgroundWhite", Folder3)
  Folder4Text := MyGui.Add("Text", "xs+20 ys+80  w470 BackgroundWhite", Folder4)
  Folder5Text := MyGui.Add("Text", "xs+20 ys+100 w470 BackgroundWhite", Folder5)
  Folder1Text.OnEvent("Click", SelectFolder1)
  Folder2Text.OnEvent("Click", SelectFolder2)
  Folder3Text.OnEvent("Click", SelectFolder3)
  Folder4Text.OnEvent("Click", SelectFolder4)
  Folder5Text.OnEvent("Click", SelectFolder5)

  ; ソフトウェア
  MyGui.Add("GroupBox", "xs ys+125 w500 h140 section", "ソフトウェア")
  MyGui.Add("Text", "xs+10 ys+20",  "A エディタ")
  MyGui.Add("Text", "xs+10 ys+40",  "W ワード")
  MyGui.Add("Text", "xs+10 ys+60",  "E Eメール")
  MyGui.Add("Text", "xs+10 ys+80",  "S スライド")
  MyGui.Add("Text", "xs+10 ys+100", "D PDF")
  MyGui.Add("Text", "xs+10 ys+120", "F ブラウザ")
  EditorText  := MyGui.Add("Text", "xs+60 ys+20 w430 BackgroundWhite", Editor)
  WordText    := MyGui.Add("Text", "xs+60 ys+40 w430 BackgroundWhite", Word)
  EMailText   := MyGui.Add("Text", "xs+60 ys+60 w430 BackgroundWhite", EMail)
  SlideText   := MyGui.Add("Text", "xs+60 ys+80 w430 BackgroundWhite", Slide)
  PDFText     := MyGui.Add("Text", "xs+60 ys+100 w430 BackgroundWhite", PDF)
  BrowserText := MyGui.Add("Text", "xs+60 ys+120 w430 BackgroundWhite", Browser)
  EditorText.OnEvent("Click", NavigateF3)
  WordText.OnEvent("Click", NavigateF3)
  EMailText.OnEvent("Click", NavigateF3)
  SlideText.OnEvent("Click", NavigateF3)
  PDFText.OnEvent("Click", NavigateF3)
  BrowserText.OnEvent("Click", NavigateF3)

  ; 設定ファイル
  MyGui.Add("GroupBox", "xs-300 ys+150 w800 h50 section", "設定ファイル")
  BackupFileName := A_ScriptDir "\backup.ini"
  DefaultFileName := A_ScriptDir "\default.ini"
  ConfFileDDL := MyGui.Add("DDL", "xs+10 ys+20 w650 Choose1", [ConfFileName, BackupFileName, DefaultFileName, "Another File"])
  ConfFileDDL.OnEvent("Change", ChangeSaveFileButton)
  MyGui.Add("Button", "xs+670 ys+18 w50", "読込").OnEvent("Click", LoadFile)
  SaveButton := MyGui.Add("Button", "xs+725 ys+18 w50 w70", "設定を適用")
  SaveButton.OnEvent("Click", SaveFile)

  MyGui.Show()

  ToggleStartUp(*)
  {
    if not FileExist(A_Startup "\muhenkan_ahk_or_exe.lnk")
    {
      FileCreateShortcut(A_ScriptFullPath, A_Startup "\muhenkan_ahk_or_exe.lnk")
      TextStartup.Value := "自動起動ON　"
      TextStartup.Opt("Background69B076")
      TextStartup.Redraw()
    }
    else
    {
      FileDelete(A_Startup "\muhenkan_ahk_or_exe.lnk")
      TextStartup.Value := "自動起動OFF"
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
  SelectFolder1(*)
  {
      MyGui.Opt("-AlwaysOnTop")
      SelectedFolder := FileSelect("D", Folder1Text.Text, "Select a folder")
      if SelectedFolder
        Folder1Text.Text := SelectedFolder
      MyGui.Opt("AlwaysOnTop")    
  }
  SelectFolder2(*)
  {
      MyGui.Opt("-AlwaysOnTop")
      SelectedFolder := FileSelect("D", Folder2Text.Text, "Select a folder")
      if SelectedFolder
        Folder2Text.Text := SelectedFolder
      MyGui.Opt("AlwaysOnTop")    
  }
  SelectFolder3(*)
  {
      MyGui.Opt("-AlwaysOnTop")
      SelectedFolder := FileSelect("D", Folder3Text.Text, "Select a folder")
      if SelectedFolder
        Folder3Text.Text := SelectedFolder
      MyGui.Opt("AlwaysOnTop")    
  }
  SelectFolder4(*)
  {
      MyGui.Opt("-AlwaysOnTop")
      SelectedFolder := FileSelect("D", Folder4Text.Text, "Select a folder")
      if SelectedFolder
        Folder4Text.Text := SelectedFolder
      MyGui.Opt("AlwaysOnTop")    
  }
  SelectFolder5(*)
  {
      MyGui.Opt("-AlwaysOnTop")
      SelectedFolder := FileSelect("D", Folder5Text.Text, "Select a folder")
      if SelectedFolder
        Folder5Text.Text := SelectedFolder
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
    EngDictionary := StrReplace(IniRead(ConfFileDDL.Text, "WebSite", "EngDictionary"), "A_UserName", A_UserName)
    Thesaurus := StrReplace(IniRead(ConfFileDDL.Text, "WebSite", "Thesaurus"), "A_UserName", A_UserName)
    Translator := StrReplace(IniRead(ConfFileDDL.Text, "WebSite", "Translator"), "A_UserName", A_UserName)
    SearchEngine := StrReplace(IniRead(ConfFileDDL.Text, "WebSite", "SearchEngine"), "A_UserName", A_UserName)
    if (EngDictionary = "https://ejje.weblio.jp/content/")
      ChooseEngDictionary := 1
    else if (EngDictionary = "https://eow.alc.co.jp/search?q=")
      ChooseEngDictionary := 2
    else if (EngDictionary = "https://www.ldoceonline.com/dictionary/")
      ChooseEngDictionary := 3
    else if (EngDictionary = "https://www.oxfordlearnersdictionaries.com/definition/english/")
      ChooseEngDictionary := "Choose4"
    if (Thesaurus = "https://thesaurus.weblio.jp/content/")
      ChooseThesaurus := 1
    else if (Thesaurus = "https://renso-ruigo.com/word/")
      ChooseThesaurus := 2
    if (Translator = "https://www.deepl.com/translator#en/ja/")
      ChooseTranslator := 1
    else if (Translator = "https://translate.google.co.jp/?hl=ja&sl=auto&tl=ja&text=")
      ChooseTranslator := 2
    if (SearchEngine = "https://www.google.co.jp/search?q=")
      ChooseSearchEngine := 1
    else if (SearchEngine = "https://duckduckgo.com/?q=")
      ChooseSearchEngine := 2
    else if (SearchEngine = "https://search.yahoo.co.jp/search?p=")
      ChooseSearchEngine := 3

    EngDictionaryDDL.Value := ChooseEngDictionary
    ThesaurusDDL.Value := ChooseThesaurus
    TranslatorDDL.Value := ChooseTranslator
    SearchEngineDDL.Value := ChooseSearchEngine

    ; フォルダの設定
    Folder1Text.Text := StrReplace(IniRead(ConfFileDDL.Text, "Folder", "Folder1"), "A_UserName", A_UserName)
    Folder2Text.Text := StrReplace(IniRead(ConfFileDDL.Text, "Folder", "Folder2"), "A_UserName", A_UserName)
    Folder3Text.Text := StrReplace(IniRead(ConfFileDDL.Text, "Folder", "Folder3"), "A_UserName", A_UserName)
    Folder4Text.Text := StrReplace(IniRead(ConfFileDDL.Text, "Folder", "Folder4"), "A_UserName", A_UserName)
    Folder5Text.Text := StrReplace(IniRead(ConfFileDDL.Text, "Folder", "Folder5"), "A_UserName", A_UserName)

    ; ソフトウェアの設定
    EditorText.Text := StrReplace(IniRead(ConfFileDDL.Text, "Software", "Editor"), "A_UserName", A_UserName)
    WordText.Text := StrReplace(IniRead(ConfFileDDL.Text, "Software", "Word"), "A_UserName", A_UserName)
    EMailText.Text := StrReplace(IniRead(ConfFileDDL.Text, "Software", "EMail"), "A_UserName", A_UserName)
    SlideText.Text := StrReplace(IniRead(ConfFileDDL.Text, "Software", "Slide"), "A_UserName", A_UserName)
    PDFText.Text := StrReplace(IniRead(ConfFileDDL.Text, "Software", "PDF"), "A_UserName", A_UserName)
    BrowserText.Text := StrReplace(IniRead(ConfFileDDL.Text, "Software", "Browser"), "A_UserName", A_UserName)


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

    if (EngDictionaryDDL.Value = 1)
      IniWrite "https://ejje.weblio.jp/content/", ConfFileDDL.Text, "WebSite", "EngDictionary"
    else if (EngDictionaryDDL.Value = 2)
      IniWrite "https://eow.alc.co.jp/search?q=", ConfFileDDL.Text, "WebSite", "EngDictionary"
    else if (EngDictionaryDDL.Value = 3)
      IniWrite "https://www.ldoceonline.com/dictionary/", ConfFileDDL.Text, "WebSite", "EngDictionary"
    else if (EngDictionaryDDL.Value = 4)
      IniWrite "https://www.oxfordlearnersdictionaries.com/definition/english/", ConfFileDDL.Text, "WebSite", "EngDictionary"

    if (ThesaurusDDL.Value = "1")
      IniWrite "https://thesaurus.weblio.jp/content/", ConfFileDDL.Text, "WebSite", "Thesaurus"
    else if (ThesaurusDDL.Value = "2")
      IniWrite "https://renso-ruigo.com/word/", ConfFileDDL.Text, "WebSite", "Thesaurus"

    if (TranslatorDDL.Value = "1")
      IniWrite "https://www.deepl.com/translator#en/ja/", ConfFileDDL.Text, "WebSite", "Translator"
    else if (TranslatorDDL.Value = "2")
      IniWrite "https://translate.google.co.jp/?hl=ja&sl=auto&tl=ja&text=", ConfFileDDL.Text, "WebSite", "Translator"

    if (SearchEngineDDL.Value = "1")
      IniWrite "https://www.google.co.jp/search?q=", ConfFileDDL.Text, "WebSite", "SearchEngine"
    else if (SearchEngineDDL.Value = "2")
      IniWrite "https://duckduckgo.com/?q=", ConfFileDDL.Text, "WebSite", "SearchEngine"
    else if (SearchEngineDDL.Value = "3")
      IniWrite "https://search.yahoo.co.jp/search?p=", ConfFileDDL.Text, "WebSite", "SearchEngine"

    IniWrite StrReplace(Folder1Text.Text, A_UserName, "A_UserName"), ConfFileDDL.Text, "Folder", "Folder1"
    IniWrite StrReplace(Folder2Text.Text, A_UserName, "A_UserName"), ConfFileDDL.Text, "Folder", "Folder2"
    IniWrite StrReplace(Folder3Text.Text, A_UserName, "A_UserName"), ConfFileDDL.Text, "Folder", "Folder3"
    IniWrite StrReplace(Folder4Text.Text, A_UserName, "A_UserName"), ConfFileDDL.Text, "Folder", "Folder4"
    IniWrite StrReplace(Folder5Text.Text, A_UserName, "A_UserName"), ConfFileDDL.Text, "Folder", "Folder5"
    
    IniWrite StrReplace(EditorText.Text,  A_UserName, "A_UserName"), ConfFileDDL.Text, "Software", "Editor"
    IniWrite StrReplace(WordText.Text,    A_UserName, "A_UserName"), ConfFileDDL.Text, "Software", "Word"
    IniWrite StrReplace(EMailText.Text,   A_UserName, "A_UserName"), ConfFileDDL.Text, "Software", "EMail"
    IniWrite StrReplace(SlideText.Text,   A_UserName, "A_UserName"), ConfFileDDL.Text, "Software", "Slide"
    IniWrite StrReplace(PDFText.Text,     A_UserName, "A_UserName"), ConfFileDDL.Text, "Software", "PDF"
    IniWrite StrReplace(BrowserText.Text, A_UserName, "A_UserName"), ConfFileDDL.Text, "Software", "Browser"

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
    CurrentKeys := "a (Editor) :`t" Editor "`nw (Word) :`t" Word "`ne (Email) :`t" EMail  "`ns (Slide) :`t`t" Slide "`nd (PDF) :`t`t" PDF "`nf (Browser) :`t" Browser
    EnableKeys := "a, w, e, s, d, f"
  }
  else
  {
    CurrentKeys := "1 : " Folder1 "`n2 : " Folder2 "`n3 : " Folder3 "`n4 : " Folder4 "`n5 : " Folder5
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