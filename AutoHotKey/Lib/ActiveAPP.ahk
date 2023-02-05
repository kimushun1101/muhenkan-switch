; 指定のソフトを最前面にする。
; もし指定したソフトが起動していなければ起動する。
ActiveAPP(app)
{
  if WinExist("ahk_exe " app) ; https://www.autohotkey.com/docs/v2/misc/WinTitle.htm#ahk_exe
    WinActivate
  else
    Run app
}