; アンインストール後: 設定ファイルの削除を確認
!macro NSIS_HOOK_POSTUNINSTALL
  MessageBox MB_YESNO "設定ファイルを削除しますか？$\n$\n残す場合はフォルダを開きます。$\n$INSTDIR" IDYES _delete_config
    ; 「いいえ」— フォルダを開く
    ExecShell "open" "$INSTDIR"
    Goto _done_config
  _delete_config:
    ; 「はい」— ディレクトリごと削除
    RMDir /r "$INSTDIR"
  _done_config:
!macroend
