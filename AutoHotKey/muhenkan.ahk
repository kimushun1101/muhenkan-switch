;======================================
; 準備
;======================================
#SingleInstance Force ; このスクリプトの再実行を許可する

; タイムスタンプの設定
DateFormat := IniRead(A_ScriptDir "\conf.ini", "Timestamp", "DateFormat")
TimestampPosition := IniRead(A_ScriptDir "\conf.ini", "Timestamp", "TimestampPosition")

; Web サイトの設定
ArticlesSearch := IniRead(A_ScriptDir "\conf.ini", "WebSite", "ArticlesSearch")
WordDictionary := IniRead(A_ScriptDir "\conf.ini", "WebSite", "WordDictionary")
Thesaurus := IniRead(A_ScriptDir "\conf.ini", "WebSite", "Thesaurus")
ECommerce := IniRead(A_ScriptDir "\conf.ini", "WebSite", "ECommerce")
Translator := IniRead(A_ScriptDir "\conf.ini", "WebSite", "Translator")
SearchEngine := IniRead(A_ScriptDir "\conf.ini", "WebSite", "SearchEngine")

; ソフトウェアの設定
Editor := StrReplace(IniRead(A_ScriptDir "\conf.ini", "App", "Editor"), "A_UserName", A_UserName)
Slide := StrReplace(IniRead(A_ScriptDir "\conf.ini", "App", "Slide"), "A_UserName", A_UserName)
DocumentViewer := StrReplace(IniRead(A_ScriptDir "\conf.ini", "App", "DocumentViewer"), "A_UserName", A_UserName)
Browser := StrReplace(IniRead(A_ScriptDir "\conf.ini", "App", "Browser"), "A_UserName", A_UserName)

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
SC07B & 1::Run A_MyDocuments
SC07B & 2::Run "C:\Users\" A_UserName "\Downloads"
SC07B & 3::Run A_Desktop
SC07B & 4::Run "C:\Users\" A_UserName "\OneDrive"
SC07B & 5::Run "explorer shell:RecycleBinFolder"

;======================================
; 選択文字列を検索
; 左手上段 Q W E R T (G) に割り当てる
;======================================
#Include <SearchClipbard>
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
#Include <ActiveAPP>
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
  Send "{^+c}"
  if (ClipWait(1) = 0) ; ファイル選択がされてない場合
    return
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
  Send "{^+c}"
  if (ClipWait(1) = 0) ; ファイル選択がされてない場合
    return
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
; zip ファイルの解凍と圧縮
;---------------------------------------
; 無変換キー+ z で選択したZipファイルをその場に解凍
SC07B & z::
{
  old_clip := ClipboardAll()
  A_Clipboard := ""
  Send "{^+c}"
  if (ClipWait(1) = 0) ; 文字選択がない場合
    return
  SplitPath(A_Clipboard, , &dir, &ext)
  if (ext != "zip`"") ; 選択されているのがzipでない場合
  {
    MsgBox ext
    return
  }
    ; return
  RunWait("powershell -Command `"Expand-Archive -Path " A_Clipboard " -Destination "  dir "`"")
  A_Clipboard := old_clip
}
; 変換キー+ b で選択したZipファイルをその場に解凍
SC07B & b::
{
  old_clip := ClipboardAll()
  A_Clipboard := ""
  Send "{^+c}"
  if (ClipWait(1) = 0) ; 文字選択がない場合
    return
  SplitPath(A_Clipboard, , &dir, &ext)
  if (dir = "" and ext != "") ; 選択されているのがフォルダでない場合
    return
  RunWait("powershell -Command `"Compress-Archive -Path " A_Clipboard " -Destination "  A_Clipboard ".zip`"")
  A_Clipboard := old_clip
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
  If not FileExist(A_Startup "\" A_ScriptName ".lnk")
  {
    FileCreateShortcut(A_ScriptFullPath, A_Startup "\" A_ScriptName ".lnk")
    MsgBox "自動起動に設定しました。"
  }
  Else
  {
    FileDelete(A_Startup "\" A_ScriptName ".lnk")
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