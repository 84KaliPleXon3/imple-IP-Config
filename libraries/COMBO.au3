#include "GUIRegisterMsg20.au3"
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <ComboConstants.au3>
#include <WinAPI.au3>
#include <GuiComboBox.au3>

; An enumeration for the getters and setters
Global Enum $COMBO_DATA_GET, $COMBO_DATA_SET

; An enumeration for the different settings
Global Enum $COMBO_DATA_ISFIRSTRUN, $COMBO_DATA_INIT, $COMBO_DATA_TEXT, $COMBO_DATA_HOVER, $COMBO_DATA_BKCOLOR, $COMBO_DATA_COLOR, $COMBO_DATA_BORDER, $COMBO_DATA_LISTBKCOLOR, $COMBO_DATA_LISTCOLOR, $COMBO_DATA_LISTBORDER, $COMBO_DATA_HOVERBKCOLOR, $COMBO_DATA_HOVERCOLOR, $COMBO_DATA_MAX


;Getter & Setter Functions
Func _COMBO_SetData( $controlId, $text )
	GUICtrlSetData( $controlId, $text )
    Return _COMBO_DataWrapper($COMBO_DATA_SET, $COMBO_DATA_TEXT, $text)
EndFunc

Func _COMBO_GetHover( )
    Return _COMBO_DataWrapper($COMBO_DATA_GET, $COMBO_DATA_HOVER)
EndFunc

Func _COMBO_SetHover( $isHover )
    Return _COMBO_DataWrapper($COMBO_DATA_SET, $COMBO_DATA_HOVER, $isHover)
EndFunc

Func _COMBO_GetBkColor( )
    Return _COMBO_DataWrapper($COMBO_DATA_GET, $COMBO_DATA_BKCOLOR)
EndFunc

Func _COMBO_SetBkColor( $bkColor )
    Return _COMBO_DataWrapper($COMBO_DATA_SET, $COMBO_DATA_BKCOLOR, $bkColor)
EndFunc

Func _COMBO_GetColor( )
    Return _COMBO_DataWrapper($COMBO_DATA_GET, $COMBO_DATA_COLOR)
EndFunc

Func _COMBO_SetColor( $color )
    Return _COMBO_DataWrapper($COMBO_DATA_SET, $COMBO_DATA_COLOR, $color)
EndFunc

Func _COMBO_Init( )
    Return _COMBO_DataWrapper($COMBO_DATA_SET, $COMBO_DATA_INIT, Null)
EndFunc


;Wrapper function to get/set values
Func _COMBO_DataWrapper($iGetterOrSetter, $iType, $vValue = Null)
    ; Create a local static variable and initialise to 0
    Local Static $s_aAppSettings[$COMBO_DATA_MAX] = [True] ; First element is $COMBO_DATA_ISFIRSTRUN

    ; If the first run, then initialise the $s_aAppSettings array with default values
    If $s_aAppSettings[$COMBO_DATA_ISFIRSTRUN] Then
        $s_aAppSettings[$COMBO_DATA_ISFIRSTRUN] = False ; Set to false, as now the array has been initialised
		$s_aAppSettings[$COMBO_DATA_BKCOLOR] = 0x444444
		$s_aAppSettings[$COMBO_DATA_COLOR] = 0xFFFFFF
    EndIf

    Switch $iGetterOrSetter
        Case $COMBO_DATA_GET ; Getter
            Switch $iType
                Case $COMBO_DATA_HOVER
                    Return $s_aAppSettings[$iType]

                Case $COMBO_DATA_BKCOLOR
                    Return $s_aAppSettings[$iType]

                Case $COMBO_DATA_COLOR
                    Return $s_aAppSettings[$iType]

            EndSwitch

        Case $COMBO_DATA_SET ; Setter
            Switch $iType
                Case $COMBO_DATA_HOVER
					$s_aAppSettings[$iType] = $vValue

				Case $COMBO_DATA_BKCOLOR
					$s_aAppSettings[$iType] = $vValue

				Case $COMBO_DATA_COLOR
					$s_aAppSettings[$iType] = $vValue

				Case $COMBO_DATA_TEXT
					$s_aAppSettings[$iType] = $vValue

            EndSwitch

    EndSwitch

    ; Return null by default, especially if the type is as a setter
    Return Null
EndFunc   ;==>__AppSettings_Wrapper

;create the ownerdraw combobox
Func _COMBO_Create( $text, $left, $top, $width, $height )
	Local $tInfo, $hComboList

	; Create combo
	$idCombo = GUICtrlCreateCombo( $text, $left, $top, $width, $height, BITOR($WS_CHILD, $CBS_DROPDOWNLIST, $WS_VSCROLL, $CBS_OWNERDRAWVARIABLE, $CBS_HASSTRINGS ) )
	$hCombo = GUICtrlGetHandle($idCombo)
	_COMBO_Init() ;initialize data

	;get handle to combo listbox
	$hComboList = -1
    If _GUICtrlComboBox_GetComboBoxInfo($idCombo, $tInfo) Then
        $hComboList = DllStructGetData($tInfo, "hList")
    EndIf

	;GUI messages:  these 2 handlers would need to be modified if used for other purposes
	GUIRegisterMsg( $WM_MEASUREITEM, "WM_MEASUREITEM"  )
	GUIRegisterMsg( $WM_DRAWITEM , "WM_DRAWITEM"  )

	;subclass the combobox to paint the main (edit/button) control
	GUIRegisterMsg20( $hCombo, $WM_PAINT , _COMBO_WM_PAINT  )
	GUIRegisterMsg20( $hCombo, $WM_MOUSEFIRST , _COMBO_WM_MOUSEFIRST  )
	GUIRegisterMsg20( $hCombo, $WM_MOUSELEAVE , _COMBO_WM_MOUSELEAVE  )

	; subclass the combo listbox for custom border color
	If $hComboList <> -1 Then
		GUIRegisterMsg20( $hComboList, $WM_NCPAINT , _COMBO_WM_NCPAINT  )
		GUIRegisterMsg20( $hComboList, $WM_PRINT , _COMBO_WM_PRINT  )
	EndIf

	Return $idCombo
EndFunc

;handle mouse hover
Func _COMBO_WM_MOUSEFIRST( $hWnd, $iMsg, $wParam, $lParam )
	_COMBO_SetHover(True)
	Return $GUI_RUNDEFMSG
EndFunc

;handle mouse leave
Func _COMBO_WM_MOUSELEAVE( $hWnd, $iMsg, $wParam, $lParam )
	_COMBO_SetHover(False)
	Return $GUI_RUNDEFMSG
EndFunc

;handler for drawing the main edit/button control
Func _COMBO_WM_PAINT( $hWnd, $iMsg, $wParam, $lParam )
	    Local $tPAINTSTRUCT, $hDC

        ;within the scope of this function, 'background' refers to the space between the selected item and the border
        $buttonWidth = _WinAPI_GetSystemMetrics($SM_CXVSCROLL)
        $hDC = _WinAPI_BeginPaint($hWnd, $tPAINTSTRUCT)

        ;Get client rect
        $cRect = _WinAPI_GetClientRect($hWnd)

        ;shrink rect by 3 (space for border and background)
        _WinAPI_InflateRect ( $cRect, -3, -3 )
        ;shrink right side (space for button)
        DllStructSetData($cRect, "Right", DllStructGetData($cRect, "Right")-$buttonWidth-1)

        ;remove border, button, and background from clipping region
        _WinAPI_IntersectClipRect ( $hDC, $cRect )

        ;draw the default combobox using the $hDC
        DllCall( "comctl32.dll", "lresult", "DefSubclassProc", "hwnd", $hWnd, "uint", $iMsg, "wparam", $hDC, "lparam", $lParam )

        ;remove the clipping region
        _WinAPI_SelectClipRgn ( $hDC, Null )

;~ 		ConsoleWrite(_COMBO_GetHover() & @CRLF)
        If _COMBO_GetHover() Then
			$bkColor = 0x999999
            $buttonColor = 0x999999
            $borderColor = 0x999999
			$arrowColor = 0xFFFFFF
        Else
			$bkColor = _COMBO_GetBkColor()
            $buttonColor = 0x444444
            $borderColor = 0x666666
			$arrowColor = 0xCCCCCC
        EndIf

        ;get area between middle and border (our background)
        $cRect = _WinAPI_GetClientRect($hWnd)
        _WinAPI_InflateRect ( $cRect, -1, -1 )
        _WinAPI_IntersectClipRect ( $hDC, $cRect )
        _WinAPI_InflateRect ( $cRect, -2, -2 )
        DllStructSetData($cRect, "Right", DllStructGetData($cRect, "Right")+1)
        _WinAPI_ExcludeClipRect($hDC, $cRect)
        _WinAPI_InflateRect ( $cRect, 2, 2 )
        DllStructSetData($cRect, "Right", DllStructGetData($cRect, "Right")-1-$buttonWidth-3)
        ;draw the background
		$hBrushNorm = _WinAPI_CreateSolidBrush(0x444444)
        _WinAPI_FillRect($hDC, DllStructGetPtr($cRect), $hBrushNorm)

        ;reset the clipping region again
        _WinAPI_SelectClipRgn ( $hDC, Null )

        ;get the rect for the button and set clipping region
        $bRect = _WinAPI_GetClientRect($hWnd)
        DllStructSetData($bRect, "Left", DllStructGetData($bRect, "Right")-1-$buttonWidth-3)
        DllStructSetData($bRect, "Right", DllStructGetData($bRect, "Right")-1)
        DllStructSetData($bRect, "Top", DllStructGetData($bRect, "Top")+1)
        DllStructSetData($bRect, "Bottom", DllStructGetData($bRect, "Bottom")-1)
        _WinAPI_IntersectClipRect ( $hDC, $bRect )
        ;draw the button
        $hBrushButton = _WinAPI_CreateSolidBrush($buttonColor)
        _WinAPI_FillRect($hDC, DllStructGetPtr($bRect), $hBrushButton)

        ;Create the arrow path
        $leftpos = DllStructGetData($bRect, "Left")
        $toppos = DllStructGetData($bRect, "Top")
        $buttonMiddle = ($buttonWidth+3)/2
        $buttonVMiddle = (DllStructGetData($cRect, "Bottom")-$toppos)/2
        $arrowWidth = 12
        $arrowHeight = 6

        _WinAPI_BeginPath($hDC)
        _WinAPI_MoveTo($hDC, $leftpos+$buttonMiddle, $toppos+$buttonVMiddle+$arrowHeight/2)
        _WinAPI_LineTo($hDC, $leftpos+$buttonMiddle+$arrowWidth/2, $toppos++$buttonVMiddle-$arrowHeight/2)
		_WinAPI_MoveTo($hDC, $leftpos+$buttonMiddle, $toppos+$buttonVMiddle+$arrowHeight/2)
        _WinAPI_LineTo($hDC, $leftpos+$buttonMiddle-$arrowWidth/2, $toppos++$buttonVMiddle-$arrowHeight/2)
        _WinAPI_CloseFigure($hDC)
        _WinAPI_EndPath($hDC)

		$hPenArrow = _WinAPI_CreatePen($PS_SOLID, 2, $arrowColor)
        $hOldPen = _WinAPI_SelectObject($hDC, $hPenArrow)
		_WinAPI_StrokePath($hDC)

        _WinAPI_SelectObject($hDC, $hOldPen)

        ;remove the clipping region
        _WinAPI_SelectClipRgn ( $hDC, Null )

        ;remove inside from clipping region (keep only the border)
        DllStructSetData($cRect, "Right", DllStructGetData($cRect, "Right")+_WinAPI_GetSystemMetrics($SM_CXVSCROLL)+3)
        _WinAPI_ExcludeClipRect($hDC, $cRect)
        $cRect = _WinAPI_GetClientRect($hWnd)

        ;create border brush
        $hBrushBorder = _WinAPI_CreateSolidBrush($borderColor)

        ;get full rect size again and fill border
        $cRect = _WinAPI_GetClientRect($hWnd)
        _WinAPI_FillRect($hDC, DllStructGetPtr($cRect), $hBrushBorder)

        ;clean up
        _WinAPI_DeleteObject($hBrushBorder)
        _WinAPI_DeleteObject($hBrushButton)
		_WinAPI_DeleteObject($hBrushNorm)
		_WinAPI_DeleteObject($hPenArrow)

        _WinAPI_EndPaint($hWnd, $tPAINTSTRUCT)
        Return 0
EndFunc

;handler for drawing the list items
Func WM_DRAWITEM( $hWnd, $iMsg, $wParam, $lParam )
    Local Const $ODT_COMBOBOX = 3
    Local Const $ODT_STATIC = 5
    Local Const $ODS_SELECTED = 1
    Local Const $ODS_COMBOBOXEDIT = 4096

	Local Const $tagDRAWITEMSTRUCT = _
			'uint CtlType;' & _
			'uint CtlID;' & _
			'uint itemID;' & _
			'uint itemAction;' & _
			'uint itemState;' & _
			'hwnd hwndItem;' & _
			'hwnd hDC;' & _
			$tagRECT & _
			';ulong_ptr itemData;'

	Local $tDIS
	Local $iCtlType, $iCtlID, $iItemID, $iItemAction, $iItemState
	Local $clrForeground, $clrBackground
	Local $hWndItem, $hDC, $hOldPen, $hOldBrush
	Local $tRect, $aRect[4]
	Local $sText, $iCode, $iIDFrom

	$tDIS = DllStructCreate($tagDRAWITEMSTRUCT, $lParam)
	$iCtlType = DllStructGetData($tDIS, 'CtlType')
	$iCtlID = DllStructGetData($tDIS, 'CtlID')
	$iItemID = DllStructGetData($tDIS, 'itemID')
	$iItemAction = DllStructGetData($tDIS, 'itemAction')
	$iItemState = DllStructGetData($tDIS, 'itemState')
	$hWndItem = DllStructGetData($tDIS, 'hwndItem')
	$hDC = DllStructGetData($tDIS, 'hDC')
	$tRect = DllStructCreate($tagRECT)

	If $iCtlType = $ODT_COMBOBOX Then
		For $i = 1 To 4
			DllStructSetData($tRect, $i, DllStructGetData($tDIS, $i + 7))
			$aRect[$i - 1] = DllStructGetData($tRect, $i)
		Next

		_GUICtrlComboBox_GetLBText($hWndItem, $iItemID, $sText)

		If BitAND($iItemState, $ODS_SELECTED) And Not BitAND($iItemState, $ODS_COMBOBOXEDIT) Then
			$hBrushSel = _WinAPI_CreateSolidBrush(0x777777)
			$hPen = _WinAPI_CreatePen($PS_SOLID, 2, 0x777777)
			$hOldBrush = _WinAPI_SelectObject($hDC, $hBrushSel)
			$hOldPen = _WinAPI_SelectObject($hDC, $hPen)
			_WinAPI_Rectangle($hDC, _WinAPI_CreateRect( $aRect[0] + 1, $aRect[1] + 1, $aRect[2], $aRect[3]))
			_WinAPI_SelectObject($hDC, $hOldPen)
			_WinAPI_SelectObject($hDC, $hOldBrush)
			_WinAPI_DeleteObject($hPen)
			_WinAPI_DeleteObject($hBrushSel)

			$clrForeground = _WinAPI_SetTextColor($hDC, 0xFFFFFF)
			$clrBackground = _WinAPI_SetBkColor($hDC, 0x777777)
		Else
			$clrForeground = _WinAPI_SetTextColor($hDC, _COMBO_GetColor())
			$clrBackground = _WinAPI_SetBkColor($hDC, _COMBO_GetBkColor())
			$hBrushNorm = _WinAPI_CreateSolidBrush(_COMBO_GetBkColor())
			_WinAPI_FillRect($hDC, DllStructGetPtr($tRect), $hBrushNorm)
			_WinAPI_DeleteObject($hBrushNorm)
		EndIf
		DllStructSetData($tRect, "Left", $aRect[0] + 4)
		DllStructSetData($tRect, "Top", $aRect[1] + 2)
		DllStructSetData($tRect, "Bottom", $aRect[3] - 2)

		_WinAPI_DrawText($hDC, $sText, $tRect, BitOR($DT_LEFT, $DT_VCENTER, $DT_WORD_ELLIPSIS ))
		_WinAPI_SetTextColor($hDC, $clrForeground)
		_WinAPI_SetBkColor($hDC, $clrBackground)

		Return True
	EndIf

EndFunc

;set the list item height
Func WM_MEASUREITEM( $hWnd, $iMsg, $wParam, $lParam )
	Local Const $ODT_COMBOBOX = 3
	Local Const $tagMEASUREITEMSTRUCT = _
			'uint CtlType;' & _
			'uint CtlID;' & _
			'uint itemID;' & _
			'uint itemWidth;' & _
			'uint itemHeight;' & _
			'ulong_ptr itemData;'

	Local $tMIS = DllStructCreate($tagMEASUREITEMSTRUCT, $lparam)
	Local $iCtlType, $iCtlID, $iItemID, $iItemWidth, $iItemHeight
	Local $hComboBox
	Local $tSize
	Local $sText

	$iCtlType = DllStructGetData($tMIS, 'CtlType')
	$iCtlID = DllStructGetData($tMIS, 'CtlID')
	$iItemID = DllStructGetData($tMIS, 'itemID')
	$iItemWidth = DllStructGetData($tMIS, 'itemWidth')
	$iItemHeight = DllStructGetData($tMIS, 'itemHeight')
	$hComboBox = GUICtrlGetHandle($iCtlID)

	If $iCtlType = $ODT_COMBOBOX Then
		DllStructSetData($tMIS, 'itemHeight', 20)
	EndIf
EndFunc

;paint the custom border color (after dropped down)
Func _COMBO_WM_NCPAINT ( $hWnd, $iMsg, $wParam, $lParam )
	Local $hDC
	$hDC = _WinAPI_GetWindowDC($hWnd)	;get window DC

	;create new Pen for the border
	$hPen = _WinAPI_CreatePen( $PS_SOLID, 1, 0x999999)
	$OldPen = _WinAPI_SelectObject($hDC, $hPen)

	;draw 4 lines for the border
	$aHwndPos = WinGetPos($hWnd)
	_WinAPI_BeginPath($hDC)
	_WinAPI_MoveTo($hDC, 0, 0)							;move to 0,0
	_WinAPI_LineTo($hDC, $aHwndPos[2]-1, 0)				;top
	_WinAPI_LineTo($hDC, $aHwndPos[2]-1, $aHwndPos[3]-1)	;right side
	_WinAPI_LineTo($hDC, 0, $aHwndPos[3]-1)				;bottom
	_WinAPI_LineTo($hDC, 0, 0)							;left side
	_WinAPI_CloseFigure($hDC)
	_WinAPI_EndPath($hDC)
	_WinAPI_StrokePath($hDC)

	;restore the old pen
    _WinAPI_SelectObject($hDC, $OldPen)
    _WinAPI_DeleteObject($hPen)

	;release the DC
	_WinAPI_ReleaseDC($hWnd, $hDC)
EndFunc

;paint the custom border color (while animating)
Func _COMBO_WM_PRINT ( $hWnd, $iMsg, $wParam, $lParam )
	Local $hDC
	$hDC = $wParam	;use DC from WM_PRINT

	;run the default WM_PRINT, then we will paint the border on top of it
	DllCall( "comctl32.dll", "lresult", "DefSubclassProc", "hwnd", $hWnd, "uint", $iMsg, "wparam", $hDC, "lparam", $lParam )

	;create new Pen for the border
	$hPen = _WinAPI_CreatePen( $PS_SOLID, 1, 0x999999)
	$OldPen = _WinAPI_SelectObject($hDC, $hPen)

	;draw 4 lines for the border
	$aHwndPos = WinGetPos($hWnd)
	_WinAPI_BeginPath($hDC)
	_WinAPI_MoveTo($hDC, 0, 0)							;move to 0,0
	_WinAPI_LineTo($hDC, $aHwndPos[2]-1, 0)				;top
	_WinAPI_LineTo($hDC, $aHwndPos[2]-1, $aHwndPos[3]-1)	;right side
	_WinAPI_LineTo($hDC, 0, $aHwndPos[3]-1)				;bottom
	_WinAPI_LineTo($hDC, 0, 0)							;left side
	_WinAPI_CloseFigure($hDC)
	_WinAPI_EndPath($hDC)
	_WinAPI_StrokePath($hDC)

	;restore the old pen
    _WinAPI_SelectObject($hDC, $OldPen)
    _WinAPI_DeleteObject($hPen)

	;release the DC (not necessary?)
	_WinAPI_ReleaseDC($hWnd, $hDC)
EndFunc
