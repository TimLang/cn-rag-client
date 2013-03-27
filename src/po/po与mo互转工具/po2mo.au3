#include <GUIConstants.au3>

#Region ### START Koda GUI section ### Form=f:\my documents\autoit文件\form1.kxf
$Form1_1 = GUICreate("Form1", 343, 126, 333, 234)
$Input1 = GUICtrlCreateInput("", 64, 16, 209, 21)
$Label1 = GUICtrlCreateLabel("源文件", 8, 16, 40, 17)
$Label2 = GUICtrlCreateLabel("目标文件", 8, 56, 52, 17)
$Input2 = GUICtrlCreateInput("", 64, 48, 209, 21)
$Checkbox1 = GUICtrlCreateCheckbox("po转mo", 88, 80, 73, 17)
GUICtrlSetState($Checkbox1, $GUI_CHECKED)
$Input3 = GUICtrlCreateInput("  彩虹神话出品:论坛：huohai12.5d6d.com", 0, 104, 249, 21)
GUICtrlSetState(-1, $GUI_DISABLE)
$Button1 = GUICtrlCreateButton("浏览", 288, 15, 49, 25, 0)
$Button2 = GUICtrlCreateButton("浏览", 288, 48, 49, 25, 0)
$tijiao = GUICtrlCreateButton("提交", 248, 80, 89, 33, 0)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Exit
        Case $Button1
			$filey = FileOpenDialog("请选择源文件(po文件)","","所有文件(*.*)")
		    Else
			$filey = FileOpenDialog("请选择源文件(mo文件)","","mo所有文件(*.*)")
			GUICtrlSetData($Input1,$filey)
		    If @error = -1 Then ExitLoop
			EndIf
		Case $Button2
           $filem = FileSaveDialog("请选择目标文件(mo文件)","","所有文件(*.*)")
		   $filem=$filem&".mo"
            GUICtrlSetData($Input2,$filem)
		    If @error = -1 Then ExitLoop
		Case $tijiao
             				
	EndSwitch
WEnd