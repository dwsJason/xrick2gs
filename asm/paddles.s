*
* ORCA/M Format!!
* @JBrooksBSI fast Dual Axis Paddle Read
*
	case on
	longa on
	longi on
	
* ORCA is neat	
DummyPaddles start ASMCODE
	end

*PEEK 49249 - PADDLE 0 BUTTON (>127 IF BUTTON PRESSED)
*PEEK 49250 - PADDLE 1 BUTTON (>127 IF BUTTON PRESSED)
*PEEK 49251 - PADDLE 2 BUTTON (>127 IF BUTTON PRESSED)

*
* XRick GS C Interface to read
* the joystick, and the button
*
paddle0 start ASMCODE
	ds 2
paddle1 entry
	ds 2
paddle_button_0 entry
	ds 2
	
ReadPaddles entry
	phb
	phk
	plb
	
	jsr GetJoyXY
	
	stx	paddle0
	sty paddle1
	
	lda >$E0C061
	and #$0080
	sta paddle_button_0
			
	plb	
	rtl
	end

*
*------------------------------- 
* IIGS 1MHz single-pass GetJoyXY 
* 
* 10/21/2018 by John Brooks 
*------------------------------- 

*------------------------------- 
* Read JoyX,Y every 11cyc on avg 
* Return: X=JoyX, Y=JoyY 
GetJoyXY start ASMCODE
               php              ;Save irq & mx reg size 
               sep   #$34       ;sei & 8-bit mx 
               phd              ;Save DPage 
               pea   $C000      ;DP to I/O 
               pld              ;DP=$C000 

               bit   $70        ;Start X,Y timers. ~16c to 1st read 
*               cyc   on 
               lsr   $36        ;5: Force 1MHz 
               ldx   #1         ;2: Init dual X,Y ctr 
               xba              ;3: Wait 
               xba              ;3: Wait 
_DualXY0       anop
               lda   $64        ;3: Chk JoyX. 10c to DualXY1 
*               cyc   on 
               and   $65        ;3: Chk JoyY 
               bpl   _ToSolo    ;2/3 
               inx              ;2: Inc XY 
_DualXY1       anop
               lda   $64        ;3: Chk JoyX. 10c to DualXY2 
*               cyc   on 
               and   $65        ;3: Chk JoyY 
               bpl   _ToSolo    ;2/3 
               inx              ;2: Inc XY 
_DualXY2       anop
               lda   $64        ;3: Chk JoyX. 13c to DualXY0 
*               cyc   on 
               and   $65        ;3: Chk JoyY 
               bpl   _ToSolo    ;3 
               inx              ;2: Inc XY 
               bne   _DualXY0 
_DualXY3       anop
               lda   $64        ;3: Chk JoyX               and   $65        ;3: Chk JoyY 
               bmi   _SameXY    ;3 
               dex              ;#$FE 
_SameXY 	   anop
               dex              ;#$FF 
               txy 
               bra   _Exit 

_SoloX  	   anop
               bit   $64        ;3: Chk JoyX 
               bmi   _SoloXOk   ;2/3 
               dey              ;2 
               bra   _Exit 
_SoloXOk       anop
               inx              ;2 
               bne   _SoloX     ;2/3 
*                               ;#$FF. Fall into dex & Exit 

_SoloY  	   anop
               bit   $65        ;3: Chk JoyY 
               bmi   _SoloYOk   ;2/3 
               dex              ;2 
               bra   _Exit 
_ToSolo 	   anop
               txy              ;2 
               bit   $64        ;3 
               bmi   _SoloXOk   ;2/3 
               bit   $65        ;3 
               bpl   _SameXY    ;2/3 
_SoloYOk       anop
               iny              ;2 
               bne   _SoloY     ;2/3 
               dey              ;#$FF. Fall into Exit 

_Exit   	   anop
               rol   $36        ;Restore CPU speed 

               pld              ;Restore dpage 
               plp              ;Restore m,x size & interrupt enable 
               rts              ;Returns X=JoyX $00-$FF, Y=JoyY $00-$FF 
	end
*               lst   off 
