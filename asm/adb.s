*
* ORCA/M Format!!!
* ADB/Keyboard Event Handling
* Based on Secrets of Wolf-3d code
* from Eric Shepherd
* Thanks Burger Becky
* Thanks Jesse Blue
*
	case on
	longa on
	longi on
	
	mcopy 2:AInclude:M16.MiscTool
	mcopy 2:AInclude:M16.ADB

setModes GEQU $0004
clearModes GEQU $0005
resetSys GEQU $0010
keyCode GEQU $0011

Dummy2 start ASMCODE
	end
	
KeyArray start ASMCODE
	ds 128

RemoveKeyboardDriver entry

	phb
	phk
	plb
	
	pea toBRamSetupVector ;Restore the previous vector
	lda VecBRamSetup+3
	and #$ff
	pha
	lda VecBRamSetup+1
	pha
	_SetVector

	ldx #1				;Restart internal keyboard scanning
	ldy #clearModes
	lda #1				;Clear mode flag
	jsr CallSendInfo
	pea $2				;Remove my handler for keyboard
	_SRQRemove
	
	plb
	rtl	
	   
AddKeyboardDriver entry

	phb
	phk
	plb
*
* Clear the KeyArray
*
	ldx #128-2
clear stz KeyArray,x
	dex
	dex
	bpl clear
	
*
* Install SRQ Completion Handler
*	
* Disable ADB Auto Polling
	ldx #1
	ldy #setModes
	lda #1			; Disable autopoll (see firmware manual)
	jsr CallSendInfo
*
* Install SRQ Completion Routine
*
	pea SRQCompRoutine|-16
	pea SRQCompRoutine
	pea $2				; Keyboard ADB Device ID
	_SRQPoll
*	ldx #$1409
*	jsl $e10000

*
* Intercept BRamSetup vector, incase we need to reinstall
* the handler
*
	pha
	pha
	pea toBRamSetupVector
	_GetVector 				; preserve original vector address
	pla
	sta VecBRamSetup+1
	pla
	sep #$20
	sta VecBRamSetup+3
	rep #$31
	
* Hook in our vector handler
	
	pea toBRamSetupVector
	pea VecBRamSetup|-16
	pea VecBRamSetup
	_SetVector	

	plb
	rtl	; Back to C

* end for the AddKeyboardDriver

CallSendInfo entry
	sta >ADBTemp
	phx
	pea ADBTemp|-16
	pea ADBTemp
	phy
	_SendInfo
*	ldx #$0909
*	jsl $e10000
	
	rts
ADBTemp ds 6

*
* SRQ Completion Routine
*
SRQCompRoutine entry

	longa off
	longi off
DataPtr equ 9

	phd		 		; save direct page
	tsc				; move dp on to stack
	tcd				; so we can get data length
	
	lda [DataPtr]	;# bytes?
	beq SRExit		;No data
	
	phb
	phk
	plb
	
	longa on
	longi on
	
	rep #$30
	ldy #1
	lda [DataPtr],y
	tay				; save a copy
	and #$7f7f
	cmp #$7f7f		; reset key?
	beq SRSpecial	; yes, handle
	
	tya				; Get it back
	and #$ff00		; First byte
	xba				; Swap to LOB
	tax				; Save in X
	tya
	and	#$00ff		; Second Byte
	bra SRMerge1

SRExit clc
	pld
	rtl
*
* Handle Reset Key if need be
*	
SRSpecial tya
	ldx #$00ff 		; invalid
SRMerge1 phx		; Save 2nd
	jsr ProcessReset

* Update the key states
*	sta >$400
	jsr PostIt
	plx				; Get 2nd
	pha				; save new #1
	txa
*	sta >$480
	jsr PostIt
	plx
	pha

* Forward Keys to ADB

	txa		; First Byte
	jsr PassADBKeyIfOk
	pla		; Second Byte
	jsr PassADBKeyIfOk
	
	sep #$30
	clc
	plb
	pld
	rtl
	
*
* Update Keystate Array
*
	longa on
	longi on
	
PostIt pha	; Save Key
	sep #$20
	longa off
	cmp #$80 ; set/clear c
	and #$7f ; keycode idx
	tax
	lda #$00
	rol	a	 ; key state
	eor #$01 ; 0 for key up
	sta KeyArray,x
	rep #$30
	longa on
	pla
	rts

KeyModTbl anop
	dc i'$0002' ;Control key
	dc i'$0080' ;Apple key
	dc i'$0001' ;Shift key
	dc i'$0004' ;Caps Lock
	dc i'$0040' ;Option key

*
* Pass Keys to ADB when appropriate
*
PassADBKeyIfOk cmp #$00E0	; Pfx Code?
	bge PAExit
	cmp #$0036				; Spec Case?
	blt PASendADB
	cmp #$003B
	bge PASendADB
	tax						; Code to X
	sec
	sbc #$0036				; Table Index
	asl a
	tay						; Idx to Y
	jsr GetModKeyReg		; Get KeyMods
	and KeyModTbl,y			; Down?
	bne PAExit				; yes
	txa
PASendADB ldx #$0001
	ldy #keyCode
	jsr CallSendInfo
PAExit rts

ProcessReset anop
* The ProcessReset routine should look to see
* if it’s a key up event on key code $7F7F.
* If it is, and the Control and Command keys
* are also down, the resetSys command should
* be sent to the ADB, to cause the system to
* reboot.
	tay
	and #$7f7f
	cmp #$7f7f
	bne PR
	
	tya
	and #$80 ; key up?
	bne PRNoReset
	jsr GetModKeyReg
	tax
	and #$02	; control key ?
	bne PRResetSystem	; Do a reset
PRNoReset ldy #$00ff	; Zap Reset Key
	tya
	rts
PRResetSystem anop
; 	Reset Hit
	ldx #0
	txa
	ldy #resetSys
	jsr CallSendInfo

PR  tya
	rts
	
*
* Return the keyboard modifer register
*
GetModKeyReg entry
	sep #$20		;8 bit
	lda >$00C025	;Get the register
	rep	#$20		;16 bit
	and	#$ff		;Fix Acc
	rts				;Exit
   
*
* This code is a tail patch to BRam setup since the BRam setup
* code will reset the ADB system to auto-poll the keyboard.
* This is bad.
*

VecBRamSetup entry
	
	jsl >$000000		;Call the real code
	php 				;Save mxc
	rep #$30			;16 bit mode
	ldx #$0001			;1 data byte
	ldy #setModes		;Set ADB device mode
	lda #$0001 			;Disable keyboard autopoll (Page 189 Firmware ref)
	jsr CallSendInfo	;Call ADB
	plp					;Restore MX
	rtl 				;Exit

toBRamSetupVector entry
	ds 4
	end
   
