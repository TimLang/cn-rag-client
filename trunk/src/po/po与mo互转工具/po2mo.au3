#include <GUIConstants.au3>

#Region ### START Koda GUI section ### Form=f:\my documents\autoit�ļ�\form1.kxf
$Form1_1 = GUICreate("Form1", 343, 126, 333, 234)
$Input1 = GUICtrlCreateInput("", 64, 16, 209, 21)
$Label1 = GUICtrlCreateLabel("Դ�ļ�", 8, 16, 40, 17)
$Label2 = GUICtrlCreateLabel("Ŀ���ļ�", 8, 56, 52, 17)
$Input2 = GUICtrlCreateInput("", 64, 48, 209, 21)
$Checkbox1 = GUICtrlCreateCheckbox("poתmo", 88, 80, 73, 17)
GUICtrlSetState($Checkbox1, $GUI_CHECKED)
$Input3 = GUICtrlCreateInput("  �ʺ��񻰳�Ʒ:��̳��huohai12.5d6d.com", 0, 104, 249, 21)
GUICtrlSetState(-1, $GUI_DISABLE)
$Button1 = GUICtrlCreateButton("���", 288, 15, 49, 25, 0)
$Button2 = GUICtrlCreateButton("���", 288, 48, 49, 25, 0)
$tijiao = GUICtrlCreateButton("�ύ", 248, 80, 89, 33, 0)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Exit
        Case $Button1
			$filey = FileOpenDialog("��ѡ��Դ�ļ�(po�ļ�)","","�����ļ�(*.*)")
		    Else
			$filey = FileOpenDialog("��ѡ��Դ�ļ�(mo�ļ�)","","mo�����ļ�(*.*)")
			GUICtrlSetData($Input1,$filey)
		    If @error = -1 Then ExitLoop
			EndIf
		Case $Button2
           $filem = FileSaveDialog("��ѡ��Ŀ���ļ�(mo�ļ�)","","�����ļ�(*.*)")
		   $filem=$filem&".mo"
            GUICtrlSetData($Input2,$filem)
		    If @error = -1 Then ExitLoop
		Case $tijiao
             				
	EndSwitch
WEnd