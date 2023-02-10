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
  ArticlesSearch := StrReplace(IniRead(ConfFileName, "WebSite", "ArticlesSearch"), "A_UserName", A_UserName)
  WordDictionary := StrReplace(IniRead(ConfFileName, "WebSite", "WordDictionary"), "A_UserName", A_UserName)
  Thesaurus := StrReplace(IniRead(ConfFileName, "WebSite", "Thesaurus"), "A_UserName", A_UserName)
  ECommerce := StrReplace(IniRead(ConfFileName, "WebSite", "ECommerce"), "A_UserName", A_UserName)
  Translator := StrReplace(IniRead(ConfFileName, "WebSite", "Translator"), "A_UserName", A_UserName)
  SearchEngine := StrReplace(IniRead(ConfFileName, "WebSite", "SearchEngine"), "A_UserName", A_UserName)

  ; ソフトウェアの設定
  Editor := StrReplace(IniRead(ConfFileName, "App", "Editor"), "A_UserName", A_UserName)
  Slide := StrReplace(IniRead(ConfFileName, "App", "Slide"), "A_UserName", A_UserName)
  PDF := StrReplace(IniRead(ConfFileName, "App", "PDF"), "A_UserName", A_UserName)
  Browser := StrReplace(IniRead(ConfFileName, "App", "Browser"), "A_UserName", A_UserName)  
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
; q : 論文検索
SC07B & q::SearchClipbard ArticlesSearch
; w : word 検索
SC07B & w::SearchClipbard WordDictionary
; r : 類語辞典
SC07B & r::SearchClipbard Thesaurus
; e : Eコマース
SC07B & e::SearchClipbard ECommerce
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
ActiveAPP(app)
{
  if WinExist("ahk_exe " app) ; https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_exe
    WinActivate
  else
    Run app
}
; a : エディタ(Atom のA で覚えた)
SC07B & a::ActiveAPP(Editor)
; s : スライド作成
SC07B & s::ActiveAPP(Slide)
; d : PDF Viewer
SC07B & d::ActiveAPP(PDF)
; f : ブラウザ（FireFox のF で覚えた）
SC07B & f::ActiveAPP(Browser)

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
  IniWrite " before file name", ConfFileName, "Timestamp", "Position"
  Timestamp := FormatTime(, DateFormat)
  MsgBox "タイムスタンプの位置を前にします。`n例：" Timestamp "_ファイル名"
  Reload
}
; 変換キー+ b
SC07B & b::
{
  IniWrite " after file name", ConfFileName, "Timestamp", "Position"
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
  SettingInstruction := "タイムスタンプ位置の変更は、``無変換``+``z`` または``b`` を押す`n---`n"
  TimestampList := "TimeStamp`nDateFormat : " DateFormat "`nTimestamp Position : " TimestampPosition "`n---`n"
  FolderList := "Folder`n1 : " Folder1 "`n2 : " Folder2 "`n3 : " Folder3 "`n4 : " Folder4 "`n---`n"
  WebSiteList := "WebSite`nQ 論文検索 : " ArticlesSearch "`nW 英単語検索 : " WordDictionary "`nR 類語検索 : " Thesaurus "`nE Eコマース : " ECommerce "`nT 翻訳 : " Translator "`nG 検索エンジン : " SearchEngine "`n---`n"
  AppList := "App`nA エディタ : " Editor "`nS スライド : " Slide "`nD PDFビュワー : " PDF "`nF ブラウザ : " Browser
  MsgBox SettingInstruction A_ScriptFullPath "`nを起動中`n---`n" TimestampList FolderList WebSiteList AppList, "Settings"
  try WinClose "keyboard.png"
}
; F2 でこのスクリプトの自動起動のオンオフを切り替え
SC07B & F2::
{
  If not FileExist(A_Startup "\muhenkan_ahk_or_exe.lnk")
  {
    FileCreateShortcut(A_ScriptFullPath, A_Startup "\muhenkan_ahk_or_exe.lnk")
    MsgBox "自動起動に設定しました。"
  }
  Else
  {
    FileDelete(A_Startup "\muhenkan_ahk_or_exe.lnk")
    MsgBox "自動起動を解除しました。"
  }
}
; F3 で設定変更
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
      MsgBox "中身のあるフォルダを選択してください。または、このフォルダは設定ができません。"
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
    CurrentKeys := "a (Editor) : `t" Editor "`ns (Slide) : `t" Slide "`nd (PDF) : `t`t" PDF "`nf (Browser) : `t" Browser
    EnableKeys := "a, s, d, f"
  }
  else
  {
    CurrentKeys := "1 : " Folder1 "`n2 : " Folder2 "`n3 : " Folder3 "`n4 : " Folder4
    EnableKeys := "1, 2, 3, 4"
  }
  IB := InputBox(Path "`nに上書きキーを入力してください`n`n設定可能なキー: 現在の設定`n" CurrentKeys, "キーの入力", "w600 h300")
  if (IB.Result = "OK")
  {
    if (EnableKeys = "1, 2, 3, 4" and IB.Value = "1")
      ConfirmSetIni("Folder", "Folder1", Path)
    else if (EnableKeys = "1, 2, 3, 4" and IB.Value = "2")
      ConfirmSetIni("Folder", "Folder2", Path)
    else if (EnableKeys = "1, 2, 3, 4" and IB.Value = "3")
      ConfirmSetIni("Folder", "Folder3", Path)
    else if (EnableKeys = "1, 2, 3, 4" and IB.Value = "4")
      ConfirmSetIni("Folder", "Folder4", Path)
    else if (EnableKeys = "a, s, d, f" and IB.Value = "a")
      ConfirmSetIni("App", "Editor", Path)
    else if (EnableKeys = "a, s, d, f" and IB.Value = "s")
      ConfirmSetIni("App", "Slide", Path)
    else if (EnableKeys = "a, s, d, f" and IB.Value = "d")
      ConfirmSetIni("App", "PDF", Path)
    else if (EnableKeys = "a, s, d, f" and IB.Value = "f")
      ConfirmSetIni("App", "Browser", Path)
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
    IniWrite " " Path, ConfFileName, Sec, Key
    Reload
  }
}
; F4 でスクリプトを終了 Alt + F4 的なノリで
SC07B & F4::
{
  Run A_ScriptDir ; 再起動したい場合のためにこのスクリプトの場所を開いておく
  MsgBox A_ScriptFullPath "`nを終了しました。"
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