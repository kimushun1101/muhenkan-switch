;======================================
; 準備
;======================================
#SingleInstance Force ; このスクリプトの再実行を許可する

; conf ファイルの指定
ConfFileName := A_ScriptDir "\conf.ini"
; 起動するのはどちらか
ScriptOrExe := A_ScriptFullPath

try
{
  ; タイムスタンプの設定
  DateFormat := IniRead(ConfFileName, "Timestamp", "DateFormat")
  TimestampPosition := IniRead(ConfFileName, "Timestamp", "Position")

  ; フォルダの設定
  Folder1 := StrReplace(IniRead(ConfFileName, "Folder", "Folder1"), "A_UserName", A_UserName)
  Folder2 := StrReplace(IniRead(ConfFileName, "Folder", "Folder2"), "A_UserName", A_UserName)
  Folder3 := StrReplace(IniRead(ConfFileName, "Folder", "Folder3"), "A_UserName", A_UserName)
  Folder4 := StrReplace(IniRead(ConfFileName, "Folder", "Folder4"), "A_UserName", A_UserName)
  Folder5 := StrReplace(IniRead(ConfFileName, "Folder", "Folder5"), "A_UserName", A_UserName)

  ; Web サイトの設定
  ArticlesSearch := IniRead(ConfFileName, "WebSite", "ArticlesSearch")
  WordDictionary := IniRead(ConfFileName, "WebSite", "WordDictionary")
  Thesaurus := IniRead(ConfFileName, "WebSite", "Thesaurus")
  ECommerce := IniRead(ConfFileName, "WebSite", "ECommerce")
  Translator := IniRead(ConfFileName, "WebSite", "Translator")
  SearchEngine := IniRead(ConfFileName, "WebSite", "SearchEngine")

  ; ソフトウェアの設定
  Editor := StrReplace(IniRead(ConfFileName, "App", "Editor"), "A_UserName", A_UserName)
  Slide := StrReplace(IniRead(ConfFileName, "App", "Slide"), "A_UserName", A_UserName)
  DocumentViewer := StrReplace(IniRead(ConfFileName, "App", "DocumentViewer"), "A_UserName", A_UserName)
  Browser := StrReplace(IniRead(ConfFileName, "App", "Browser"), "A_UserName", A_UserName)  
}
catch
{
  MsgBox ConfFileName "`nの設定が間違っています。見直してください。"
  Run "notepad.exe " ConfFileName
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
; 指定のフォルダを最前面にする。(Documents→ドキュメントとかに変わってしまうフォルダには効かない)
; もし指定したソフトが起動していなければ起動する。
ActiveFolder(folder)
{
  SplitPath(folder, &name)
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
SC07B & d::ActiveAPP(DocumentViewer)
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
  Send "^+c"
  if (ClipWait(1) = 0) ; ファイル選択がされてない場合
  {
    Send "exit{SC07B}{Enter}{Enter}"
    return
  }
  TergetFile := StrReplace(A_Clipboard, "`"")
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
  A_Clipboard := old_clip
}
; ファイルやフォルダをコピーしてファイル最終編集日のタイムスタンプをつける
SC07B & c::
{
  old_clip := ClipboardAll()
  A_Clipboard := ""
  Send "^+c"
  if (ClipWait(1) = 0) ; ファイル選択がされてない場合
  {
    Send "exit{SC07B}{Enter}{Enter}"
    return
  }
  TergetFile := StrReplace(A_Clipboard, "`"")
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
    MsgBox "すでにファイルが存在します。"
    return
  }
  if (ext = "") ; 拡張子がない=フォルダ
    DirCopy TergetFile, NewFile
  else          ; 拡張子がある=ファイル
    FileCopy TergetFile, NewFile
  A_Clipboard := old_clip
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
SC07B & F1::Run("powershell -Command `"Invoke-Item " A_ScriptDir "\Img\keyboard.png`"") 

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