*
* ORCA/M Format !!
* Thunk from C to Blit Rectangles from Bank 01
* Up to bank E1, this is as close as we get to a page
* flip, or backbuffer present
*
 case on
 longa on
 longi on

	mcopy asm:unroll.macros
	 
Dummy5 start BLITCODE
	end

PresentPalette start BLITCODE
	phb
	phk
	plb
	
	tsc
	sta stack
	
	tdc
	sta dp
	
*---------------------
	sei
	_shadowON
	_auxON
*---------------------

	clc
	lda #$9E00
peiloop anop
	tcd
	adc #$00FF
	tcs

	_pushpage
	
	inc a
	cmp #$A000
	bcs done
	jmp peiloop

*---------------------
done anop
	
*---------------------
	_auxOFF
	_shadowOFF
	cli	
*---------------------
	
	lda dp
	tcd
	
	lda stack
	tcs	

	plb
	rtl
stack ds 2
dp ds 2
	end

PresentSCB start BLITCODE
	phb
	phk
	plb
	
	tsc
	sta stack
	
	tdc
	sta dp
*---------------------
	sei
	_shadowON
	_auxON	
*---------------------

	lda #$9D00
	tcd
	lda #$9DFF
	tcs

	lcla &ct
&ct seta 128
.loop
&ct seta &ct-1
	pei &ct*2
	aif &ct,^loop

*---------------------
	_auxOFF
	_shadowOFF
	cli	 
*---------------------
	lda dp
	tcd
	
	lda stack
	tcs	

	plb
	rtl
stack ds 2
dp ds 2
	end

PresentFrameBuffer start BLITCODE

	phb
	phk
	plb
	
	tsc
	sta stack
	tax
	
	tdc
	sta dp
	
*---------------------
	sei
	_shadowON
	_auxON
*---------------------

	ldy #5 ; re-enable interrupts every 5 pages
	
	clc
	lda #$2000
peiloop anop
	tcd
	adc #$00FF
	tcs

	_pushpage
	
	inc a
	cmp #$9d00
	bcs done
	
	dey
	bpl nextpage
	
	tay
	_auxOFF
	txs
	cli
	sei
*	_auxON
	ora #$0030
	sta >$00C068
	
	tya
	ldy #5	

nextpage anop
	jmp peiloop

*---------------------
done anop
	
*---------------------
	_auxOFF
	_shadowOFF
	cli
*---------------------
	
	lda dp
	tcd
	
	lda stack
	tcs	

	plb
	rtl
stack ds 2
dp ds 2
	end
	

*
* void BlitRect(short x, short y, short width, short height)
*

BlitRect start BLITCODE

inputX equ 5
inputY equ 7
inputW equ 9
inputH equ 11

stackFix equ 9

	phb
	phk
	plb
	
* save off stack and dp registers for later	
	
	tsc
	sta stack
	
	tdc
	sta dp
	
* snap X, and Y to multiples of 8
* snap W and H to multiples of 8
   
	clc
	lda inputX,s
	and #3
	adc inputW,s
	adc #7
	lsr a
	lsr a
	lsr a
	sta inputW,s
	sta loopW
	
	clc
	lda inputY,s
	and #3
	adc inputH,s
	adc #7
	lsr a
	lsr a
	lsr a
	sta inputH,s
	sta loopH
	
	lda inputY,s
	and #~3
	lsr a
	lsr a
	sta inputY,s
	sta loopY
	tay
	
	lda inputX,s
	and #~3
	tax
	sta inputX,s	; maybe don't need this
	sta loopX
	
*---------------------------------------
	sei
	_shadowON
	_auxON
*---------------------------------------

*
* We're messing with the stack, and the DP
* so operationally, we can't use these things
* for variables, or for call returns
*

*	
* Outter loop, once for each Y
*
YLOOP ANOP

	lda loopX
	sta tempX
	
	lda loopW
	sta tempW
		
XLOOP ANOP ; Inner Loop, for each X Block
	lda tempW ; width in tiles
	cmp #9
	blt LastBlock
	sbc #8
	sta tempW
	
	lda #8
LastBlock ANOP	
	asl a
	adc tempX
	tax	
				
* pei blitter changes A, S, D, and C
* trb blitter requires C = 0, A = 0, changes S, D, and C

	lda DPtable,y
	jmp (dispatchTable-2,x) 
	   
BRET anop	; Blit Return

	lda tempW
	bne XLOOP
	
	dec loopH
	bmi done
	
	iny 	; next direct page
	iny
	
* TODO, every 4 lines or so (or every so many clocks)
* re-enable interrupts, for audio, and the heartbeat	
	
	bra YLOOP 
	
done ANOP	

* restore stack and dp

	lda dp
	tcd
	
	lda stack
	tcs
	
*---------------------------------------
	_auxOFF
	_shadowOFF
	cli
*---------------------------------------

	
* Patchup the Stack so we can return

	lda 3,s
	sta stackFix+2,s
	lda 1,s
	sta stackFix,s	

	plb
	rtl
*-------------------------------------------------------------------------------
tempX ds 2  ; inner X
tempW ds 2  ; inner W
* Local bank copies of our stack variables
loopX ds 2
loopY ds 2
loopW ds 2
loopH ds 2	
stack ds 2 	; stack register
dp    ds 2  ; dp register
	
*-------------------------------------------------------------------------------
DPtable ANOP  ; only first 25 entries are used
	dc i'$2000,$2500,$2A00,$2F00,$3400,$3900,$3E00,$4300'
	dc i'$4800,$4D00,$5200,$5700,$5C00,$6100,$6600,$6B00'
	dc i'$7000,$7500,$7A00,$7F00,$8400,$8900,$8E00,$9300'
	dc i'$9800,$9D00,$A200,$A700,$AC00,$B100,$B600,$BB00'
*-------------------------------------------------------------------------------
dispatchTable ANOP
    dc  a'blit0_8,blit0_16,blit0_24,blit0_32,blit0_40,blit0_48,blit0_56,blit0_64'
    dc  a'blit8_8,blit8_16,blit8_24,blit8_32,blit8_40,blit8_48,blit8_56,blit8_64'
    dc  a'blit16_8,blit16_16,blit16_24,blit16_32,blit16_40,blit16_48,blit16_56,blit16_64'
    dc  a'blit24_8,blit24_16,blit24_24,blit24_32,blit24_40,blit24_48,blit24_56,blit24_64'
    dc  a'blit32_8,blit32_16,blit32_24,blit32_32,blit32_40,blit32_48,blit32_56,blit32_64'
    dc  a'blit40_8,blit40_16,blit40_24,blit40_32,blit40_40,blit40_48,blit40_56,blit40_64'
    dc  a'blit48_8,blit48_16,blit48_24,blit48_32,blit48_40,blit48_48,blit48_56,blit48_64'
    dc  a'blit56_8,blit56_16,blit56_24,blit56_32,blit56_40,blit56_48,blit56_56,blit56_64'
    dc  a'blit64_8,blit64_16,blit64_24,blit64_32,blit64_40,blit64_48,blit64_56,blit64_64'
    dc  a'blit72_8,blit72_16,blit72_24,blit72_32,blit72_40,blit72_48,blit72_56,blit72_64'
    dc  a'blit80_8,blit80_16,blit80_24,blit80_32,blit80_40,blit80_48,blit80_56,blit80_64'
    dc  a'blit88_8,blit88_16,blit88_24,blit88_32,blit88_40,blit88_48,blit88_56,blit88_64'
    dc  a'blit96_8,blit96_16,blit96_24,blit96_32,blit96_40,blit96_48,blit96_56,blit96_64'
    dc  a'blit104_8,blit104_16,blit104_24,blit104_32,blit104_40,blit104_48,blit104_56,blit104_64'
    dc  a'blit112_8,blit112_16,blit112_24,blit112_32,blit112_40,blit112_48,blit112_56,blit112_64'
    dc  a'blit120_8,blit120_16,blit120_24,blit120_32,blit120_40,blit120_48,blit120_56,blit120_64'
    dc  a'blit128_8,blit128_16,blit128_24,blit128_32,blit128_40,blit128_48,blit128_56,blit128_64'
    dc  a'blit136_8,blit136_16,blit136_24,blit136_32,blit136_40,blit136_48,blit136_56,blit136_64'
    dc  a'blit144_8,blit144_16,blit144_24,blit144_32,blit144_40,blit144_48,blit144_56,blit144_64'
    dc  a'blit152_8,blit152_16,blit152_24,blit152_32,blit152_40,blit152_48,blit152_56,blit152_64'
    dc  a'blit160_8,blit160_16,blit160_24,blit160_32,blit160_40,blit160_48,blit160_56,blit160_64'
    dc  a'blit168_8,blit168_16,blit168_24,blit168_32,blit168_40,blit168_48,blit168_56,blit168_64'
    dc  a'blit176_8,blit176_16,blit176_24,blit176_32,blit176_40,blit176_48,blit176_56,blit176_64'
    dc  a'blit184_8,blit184_16,blit184_24,blit184_32,blit184_40,blit184_48,blit184_56,blit184_64'
    dc  a'blit192_8,blit192_16,blit192_24,blit192_32,blit192_40,blit192_48,blit192_56,blit192_64'
    dc  a'blit200_8,blit200_16,blit200_24,blit200_32,blit200_40,blit200_48,blit200_56,blit200_64'
    dc  a'blit208_8,blit208_16,blit208_24,blit208_32,blit208_40,blit208_48,blit208_56,blit208_64'
    dc  a'blit216_8,blit216_16,blit216_24,blit216_32,blit216_40,blit216_48,blit216_56,blit216_64'
    dc  a'blit224_8,blit224_16,blit224_24,blit224_32,blit224_40,blit224_48,blit224_56,blit224_64'
    dc  a'blit232_8,blit232_16,blit232_24,blit232_32,blit232_40,blit232_48,blit232_56,blit232_64'
    dc  a'blit240_8,blit240_16,blit240_24,blit240_32,blit240_40,blit240_48,blit240_56,blit240_64'
    dc  a'blit248_8,blit248_16,blit248_24,blit248_32,blit248_40,blit248_48,blit248_56,blit248_64'
    dc  a'blit256_8,blit256_16,blit256_24,blit256_32,blit256_40,blit256_48,blit256_56,blit256_64'
    dc  a'blit264_8,blit264_16,blit264_24,blit264_32,blit264_40,blit264_48,blit264_56,blit_null'
    dc  a'blit272_8,blit272_16,blit272_24,blit272_32,blit272_40,blit272_48,blit_null,blit_null'
    dc  a'blit280_8,blit280_16,blit280_24,blit280_32,blit280_40,blit_null,blit_null,blit_null'
    dc  a'blit288_8,blit288_16,blit288_24,blit288_32,blit_null,blit_null,blit_null,blit_null'
    dc  a'blit296_8,blit296_16,blit296_24,blit_null,blit_null,blit_null,blit_null,blit_null'
    dc  a'blit304_8,blit304_16,blit_null,blit_null,blit_null,blit_null,blit_null,blit_null'
    dc  a'blit312_8,blit_null,blit_null,blit_null,blit_null,blit_null,blit_null,blit_null'

*-------------------------------------------------------------------------------
blit0_64 ANOP
         TCD        ; Set DP $0000
         ADC #31
         TCS        ; Set S  $001F
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #160
         TCS        ; Set S  $00BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $015F
         ADC #-95
         TCD        ; Set DP $0100
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #254
         TCS        ; Set S  $01FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $029F
         ADC #-159
         TCD        ; Set DP $0200
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #318
         TCS        ; Set S  $033F
         ADC #-63
         TCD        ; Set DP $0300
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #222
         TCS        ; Set S  $03DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $047F
         ADC #-127
         TCD        ; Set DP $0400
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         JMP BRET   ;833 cycles
blit8_64 ANOP
         TCD        ; Set DP $0000
         ADC #35
         TCS        ; Set S  $0023
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #160
         TCS        ; Set S  $00C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $0163
         ADC #-99
         TCD        ; Set DP $0100
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #258
         TCS        ; Set S  $0203
         ADC #-3
         TCD        ; Set DP $0200
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #418
         TCS        ; Set S  $02A3
         ADC #-163
         TCD        ; Set DP $0200
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #322
         TCS        ; Set S  $0343
         ADC #-67
         TCD        ; Set DP $0300
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #226
         TCS        ; Set S  $03E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $0483
         ADC #-131
         TCD        ; Set DP $0400
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         JMP BRET   ;843 cycles
blit16_64 ANOP
         TCD        ; Set DP $0000
         ADC #39
         TCS        ; Set S  $0027
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #160
         TCS        ; Set S  $00C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $0167
         ADC #-103
         TCD        ; Set DP $0100
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #262
         TCS        ; Set S  $0207
         ADC #-7
         TCD        ; Set DP $0200
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #422
         TCS        ; Set S  $02A7
         ADC #-167
         TCD        ; Set DP $0200
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #326
         TCS        ; Set S  $0347
         ADC #-71
         TCD        ; Set DP $0300
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #230
         TCS        ; Set S  $03E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $0487
         ADC #-135
         TCD        ; Set DP $0400
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         JMP BRET   ;843 cycles
blit24_64 ANOP
         TCD        ; Set DP $0000
         ADC #43
         TCS        ; Set S  $002B
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #160
         TCS        ; Set S  $00CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $016B
         ADC #-107
         TCD        ; Set DP $0100
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #266
         TCS        ; Set S  $020B
         ADC #-11
         TCD        ; Set DP $0200
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #426
         TCS        ; Set S  $02AB
         ADC #-171
         TCD        ; Set DP $0200
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #330
         TCS        ; Set S  $034B
         ADC #-75
         TCD        ; Set DP $0300
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #234
         TCS        ; Set S  $03EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $048B
         ADC #-139
         TCD        ; Set DP $0400
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         JMP BRET   ;843 cycles
blit32_64 ANOP
         TCD        ; Set DP $0000
         ADC #47
         TCS        ; Set S  $002F
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #160
         TCS        ; Set S  $00CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $016F
         ADC #-111
         TCD        ; Set DP $0100
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #270
         TCS        ; Set S  $020F
         ADC #-15
         TCD        ; Set DP $0200
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #430
         TCS        ; Set S  $02AF
         ADC #-175
         TCD        ; Set DP $0200
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #334
         TCS        ; Set S  $034F
         ADC #-79
         TCD        ; Set DP $0300
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #238
         TCS        ; Set S  $03EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $048F
         ADC #-143
         TCD        ; Set DP $0400
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         JMP BRET   ;843 cycles
blit40_64 ANOP
         TCD        ; Set DP $0000
         ADC #51
         TCS        ; Set S  $0033
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #160
         TCS        ; Set S  $00D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $0173
         ADC #-115
         TCD        ; Set DP $0100
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #274
         TCS        ; Set S  $0213
         ADC #-19
         TCD        ; Set DP $0200
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #434
         TCS        ; Set S  $02B3
         ADC #-179
         TCD        ; Set DP $0200
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         ADC #338
         TCS        ; Set S  $0353
         ADC #-83
         TCD        ; Set DP $0300
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #242
         TCS        ; Set S  $03F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $0493
         ADC #-147
         TCD        ; Set DP $0400
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         JMP BRET   ;843 cycles
blit48_64 ANOP
         TCD        ; Set DP $0000
         ADC #55
         TCS        ; Set S  $0037
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #160
         TCS        ; Set S  $00D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $0177
         ADC #-119
         TCD        ; Set DP $0100
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #278
         TCS        ; Set S  $0217
         ADC #-23
         TCD        ; Set DP $0200
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #438
         TCS        ; Set S  $02B7
         ADC #-183
         TCD        ; Set DP $0200
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         ADC #342
         TCS        ; Set S  $0357
         ADC #-87
         TCD        ; Set DP $0300
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #246
         TCS        ; Set S  $03F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $0497
         ADC #-151
         TCD        ; Set DP $0400
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         JMP BRET   ;843 cycles
blit56_64 ANOP
         TCD        ; Set DP $0000
         ADC #59
         TCS        ; Set S  $003B
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #160
         TCS        ; Set S  $00DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $017B
         ADC #-123
         TCD        ; Set DP $0100
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #282
         TCS        ; Set S  $021B
         ADC #-27
         TCD        ; Set DP $0200
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         ADC #442
         TCS        ; Set S  $02BB
         ADC #-187
         TCD        ; Set DP $0200
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         ADC #346
         TCS        ; Set S  $035B
         ADC #-91
         TCD        ; Set DP $0300
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #250
         TCS        ; Set S  $03FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $049B
         ADC #-155
         TCD        ; Set DP $0400
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         JMP BRET   ;843 cycles
blit64_64 ANOP
         TCD        ; Set DP $0000
         ADC #63
         TCS        ; Set S  $003F
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #160
         TCS        ; Set S  $00DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $017F
         ADC #-127
         TCD        ; Set DP $0100
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #286
         TCS        ; Set S  $021F
         ADC #-31
         TCD        ; Set DP $0200
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #190
         TCS        ; Set S  $02BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $035F
         ADC #-95
         TCD        ; Set DP $0300
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #254
         TCS        ; Set S  $03FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $049F
         ADC #-159
         TCD        ; Set DP $0400
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         JMP BRET   ;833 cycles
blit72_64 ANOP
         TCD        ; Set DP $0000
         ADC #67
         TCS        ; Set S  $0043
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #160
         TCS        ; Set S  $00E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $0183
         ADC #-131
         TCD        ; Set DP $0100
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #290
         TCS        ; Set S  $0223
         ADC #-35
         TCD        ; Set DP $0200
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #194
         TCS        ; Set S  $02C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $0363
         ADC #-99
         TCD        ; Set DP $0300
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #258
         TCS        ; Set S  $0403
         ADC #-3
         TCD        ; Set DP $0400
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #418
         TCS        ; Set S  $04A3
         ADC #-163
         TCD        ; Set DP $0400
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         JMP BRET   ;843 cycles
blit80_64 ANOP
         TCD        ; Set DP $0000
         ADC #71
         TCS        ; Set S  $0047
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #160
         TCS        ; Set S  $00E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $0187
         ADC #-135
         TCD        ; Set DP $0100
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #294
         TCS        ; Set S  $0227
         ADC #-39
         TCD        ; Set DP $0200
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #198
         TCS        ; Set S  $02C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $0367
         ADC #-103
         TCD        ; Set DP $0300
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #262
         TCS        ; Set S  $0407
         ADC #-7
         TCD        ; Set DP $0400
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #422
         TCS        ; Set S  $04A7
         ADC #-167
         TCD        ; Set DP $0400
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         JMP BRET   ;843 cycles
blit88_64 ANOP
         TCD        ; Set DP $0000
         ADC #75
         TCS        ; Set S  $004B
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #160
         TCS        ; Set S  $00EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $018B
         ADC #-139
         TCD        ; Set DP $0100
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #298
         TCS        ; Set S  $022B
         ADC #-43
         TCD        ; Set DP $0200
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #202
         TCS        ; Set S  $02CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $036B
         ADC #-107
         TCD        ; Set DP $0300
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #266
         TCS        ; Set S  $040B
         ADC #-11
         TCD        ; Set DP $0400
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #426
         TCS        ; Set S  $04AB
         ADC #-171
         TCD        ; Set DP $0400
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         JMP BRET   ;843 cycles
blit96_64 ANOP
         TCD        ; Set DP $0000
         ADC #79
         TCS        ; Set S  $004F
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #160
         TCS        ; Set S  $00EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $018F
         ADC #-143
         TCD        ; Set DP $0100
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #302
         TCS        ; Set S  $022F
         ADC #-47
         TCD        ; Set DP $0200
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #206
         TCS        ; Set S  $02CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $036F
         ADC #-111
         TCD        ; Set DP $0300
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #270
         TCS        ; Set S  $040F
         ADC #-15
         TCD        ; Set DP $0400
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #430
         TCS        ; Set S  $04AF
         ADC #-175
         TCD        ; Set DP $0400
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         JMP BRET   ;843 cycles
blit104_64 ANOP
         TCD        ; Set DP $0000
         ADC #83
         TCS        ; Set S  $0053
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #160
         TCS        ; Set S  $00F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $0193
         ADC #-147
         TCD        ; Set DP $0100
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         ADC #306
         TCS        ; Set S  $0233
         ADC #-51
         TCD        ; Set DP $0200
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #210
         TCS        ; Set S  $02D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $0373
         ADC #-115
         TCD        ; Set DP $0300
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #274
         TCS        ; Set S  $0413
         ADC #-19
         TCD        ; Set DP $0400
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #434
         TCS        ; Set S  $04B3
         ADC #-179
         TCD        ; Set DP $0400
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         JMP BRET   ;843 cycles
blit112_64 ANOP
         TCD        ; Set DP $0000
         ADC #87
         TCS        ; Set S  $0057
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #160
         TCS        ; Set S  $00F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $0197
         ADC #-151
         TCD        ; Set DP $0100
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         ADC #310
         TCS        ; Set S  $0237
         ADC #-55
         TCD        ; Set DP $0200
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #214
         TCS        ; Set S  $02D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $0377
         ADC #-119
         TCD        ; Set DP $0300
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #278
         TCS        ; Set S  $0417
         ADC #-23
         TCD        ; Set DP $0400
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #438
         TCS        ; Set S  $04B7
         ADC #-183
         TCD        ; Set DP $0400
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         JMP BRET   ;843 cycles
blit120_64 ANOP
         TCD        ; Set DP $0000
         ADC #91
         TCS        ; Set S  $005B
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #160
         TCS        ; Set S  $00FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $019B
         ADC #-155
         TCD        ; Set DP $0100
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         ADC #314
         TCS        ; Set S  $023B
         ADC #-59
         TCD        ; Set DP $0200
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #218
         TCS        ; Set S  $02DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $037B
         ADC #-123
         TCD        ; Set DP $0300
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #282
         TCS        ; Set S  $041B
         ADC #-27
         TCD        ; Set DP $0400
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         ADC #442
         TCS        ; Set S  $04BB
         ADC #-187
         TCD        ; Set DP $0400
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         JMP BRET   ;843 cycles
blit128_64 ANOP
         TCD        ; Set DP $0000
         ADC #95
         TCS        ; Set S  $005F
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #160
         TCS        ; Set S  $00FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $019F
         ADC #-159
         TCD        ; Set DP $0100
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #318
         TCS        ; Set S  $023F
         ADC #-63
         TCD        ; Set DP $0200
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #222
         TCS        ; Set S  $02DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $037F
         ADC #-127
         TCD        ; Set DP $0300
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #286
         TCS        ; Set S  $041F
         ADC #-31
         TCD        ; Set DP $0400
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #190
         TCS        ; Set S  $04BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         JMP BRET   ;833 cycles
blit136_64 ANOP
         TCD        ; Set DP $0000
         ADC #99
         TCS        ; Set S  $0063
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #160
         TCS        ; Set S  $0103
         ADC #-3
         TCD        ; Set DP $0100
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #418
         TCS        ; Set S  $01A3
         ADC #-163
         TCD        ; Set DP $0100
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #322
         TCS        ; Set S  $0243
         ADC #-67
         TCD        ; Set DP $0200
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #226
         TCS        ; Set S  $02E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $0383
         ADC #-131
         TCD        ; Set DP $0300
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #290
         TCS        ; Set S  $0423
         ADC #-35
         TCD        ; Set DP $0400
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #194
         TCS        ; Set S  $04C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         JMP BRET   ;843 cycles
blit144_64 ANOP
         TCD        ; Set DP $0000
         ADC #103
         TCS        ; Set S  $0067
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #160
         TCS        ; Set S  $0107
         ADC #-7
         TCD        ; Set DP $0100
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #422
         TCS        ; Set S  $01A7
         ADC #-167
         TCD        ; Set DP $0100
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #326
         TCS        ; Set S  $0247
         ADC #-71
         TCD        ; Set DP $0200
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #230
         TCS        ; Set S  $02E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $0387
         ADC #-135
         TCD        ; Set DP $0300
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #294
         TCS        ; Set S  $0427
         ADC #-39
         TCD        ; Set DP $0400
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #198
         TCS        ; Set S  $04C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         JMP BRET   ;843 cycles
blit152_64 ANOP
         TCD        ; Set DP $0000
         ADC #107
         TCS        ; Set S  $006B
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #160
         TCS        ; Set S  $010B
         ADC #-11
         TCD        ; Set DP $0100
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #426
         TCS        ; Set S  $01AB
         ADC #-171
         TCD        ; Set DP $0100
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #330
         TCS        ; Set S  $024B
         ADC #-75
         TCD        ; Set DP $0200
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #234
         TCS        ; Set S  $02EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $038B
         ADC #-139
         TCD        ; Set DP $0300
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #298
         TCS        ; Set S  $042B
         ADC #-43
         TCD        ; Set DP $0400
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #202
         TCS        ; Set S  $04CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         JMP BRET   ;843 cycles
blit160_64 ANOP
         TCD        ; Set DP $0000
         ADC #111
         TCS        ; Set S  $006F
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #160
         TCS        ; Set S  $010F
         ADC #-15
         TCD        ; Set DP $0100
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #430
         TCS        ; Set S  $01AF
         ADC #-175
         TCD        ; Set DP $0100
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #334
         TCS        ; Set S  $024F
         ADC #-79
         TCD        ; Set DP $0200
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #238
         TCS        ; Set S  $02EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $038F
         ADC #-143
         TCD        ; Set DP $0300
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #302
         TCS        ; Set S  $042F
         ADC #-47
         TCD        ; Set DP $0400
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #206
         TCS        ; Set S  $04CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         JMP BRET   ;843 cycles
blit168_64 ANOP
         TCD        ; Set DP $0000
         ADC #115
         TCS        ; Set S  $0073
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #160
         TCS        ; Set S  $0113
         ADC #-19
         TCD        ; Set DP $0100
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #434
         TCS        ; Set S  $01B3
         ADC #-179
         TCD        ; Set DP $0100
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         ADC #338
         TCS        ; Set S  $0253
         ADC #-83
         TCD        ; Set DP $0200
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #242
         TCS        ; Set S  $02F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $0393
         ADC #-147
         TCD        ; Set DP $0300
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         ADC #306
         TCS        ; Set S  $0433
         ADC #-51
         TCD        ; Set DP $0400
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #210
         TCS        ; Set S  $04D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         JMP BRET   ;843 cycles
blit176_64 ANOP
         TCD        ; Set DP $0000
         ADC #119
         TCS        ; Set S  $0077
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #160
         TCS        ; Set S  $0117
         ADC #-23
         TCD        ; Set DP $0100
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #438
         TCS        ; Set S  $01B7
         ADC #-183
         TCD        ; Set DP $0100
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         ADC #342
         TCS        ; Set S  $0257
         ADC #-87
         TCD        ; Set DP $0200
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #246
         TCS        ; Set S  $02F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $0397
         ADC #-151
         TCD        ; Set DP $0300
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         ADC #310
         TCS        ; Set S  $0437
         ADC #-55
         TCD        ; Set DP $0400
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #214
         TCS        ; Set S  $04D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         JMP BRET   ;843 cycles
blit184_64 ANOP
         TCD        ; Set DP $0000
         ADC #123
         TCS        ; Set S  $007B
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #160
         TCS        ; Set S  $011B
         ADC #-27
         TCD        ; Set DP $0100
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         ADC #442
         TCS        ; Set S  $01BB
         ADC #-187
         TCD        ; Set DP $0100
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         ADC #346
         TCS        ; Set S  $025B
         ADC #-91
         TCD        ; Set DP $0200
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #250
         TCS        ; Set S  $02FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $039B
         ADC #-155
         TCD        ; Set DP $0300
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         ADC #314
         TCS        ; Set S  $043B
         ADC #-59
         TCD        ; Set DP $0400
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #218
         TCS        ; Set S  $04DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         JMP BRET   ;843 cycles
blit192_64 ANOP
         TCD        ; Set DP $0000
         ADC #127
         TCS        ; Set S  $007F
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #160
         TCS        ; Set S  $011F
         ADC #-31
         TCD        ; Set DP $0100
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #190
         TCS        ; Set S  $01BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $025F
         ADC #-95
         TCD        ; Set DP $0200
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #254
         TCS        ; Set S  $02FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $039F
         ADC #-159
         TCD        ; Set DP $0300
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #318
         TCS        ; Set S  $043F
         ADC #-63
         TCD        ; Set DP $0400
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #222
         TCS        ; Set S  $04DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         JMP BRET   ;833 cycles
blit200_64 ANOP
         TCD        ; Set DP $0000
         ADC #131
         TCS        ; Set S  $0083
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #160
         TCS        ; Set S  $0123
         ADC #-35
         TCD        ; Set DP $0100
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #194
         TCS        ; Set S  $01C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $0263
         ADC #-99
         TCD        ; Set DP $0200
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #258
         TCS        ; Set S  $0303
         ADC #-3
         TCD        ; Set DP $0300
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #418
         TCS        ; Set S  $03A3
         ADC #-163
         TCD        ; Set DP $0300
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #322
         TCS        ; Set S  $0443
         ADC #-67
         TCD        ; Set DP $0400
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #226
         TCS        ; Set S  $04E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         JMP BRET   ;843 cycles
blit208_64 ANOP
         TCD        ; Set DP $0000
         ADC #135
         TCS        ; Set S  $0087
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #160
         TCS        ; Set S  $0127
         ADC #-39
         TCD        ; Set DP $0100
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #198
         TCS        ; Set S  $01C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $0267
         ADC #-103
         TCD        ; Set DP $0200
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #262
         TCS        ; Set S  $0307
         ADC #-7
         TCD        ; Set DP $0300
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #422
         TCS        ; Set S  $03A7
         ADC #-167
         TCD        ; Set DP $0300
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #326
         TCS        ; Set S  $0447
         ADC #-71
         TCD        ; Set DP $0400
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #230
         TCS        ; Set S  $04E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         JMP BRET   ;843 cycles
blit216_64 ANOP
         TCD        ; Set DP $0000
         ADC #139
         TCS        ; Set S  $008B
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #160
         TCS        ; Set S  $012B
         ADC #-43
         TCD        ; Set DP $0100
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #202
         TCS        ; Set S  $01CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $026B
         ADC #-107
         TCD        ; Set DP $0200
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #266
         TCS        ; Set S  $030B
         ADC #-11
         TCD        ; Set DP $0300
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #426
         TCS        ; Set S  $03AB
         ADC #-171
         TCD        ; Set DP $0300
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #330
         TCS        ; Set S  $044B
         ADC #-75
         TCD        ; Set DP $0400
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #234
         TCS        ; Set S  $04EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         JMP BRET   ;843 cycles
blit224_64 ANOP
         TCD        ; Set DP $0000
         ADC #143
         TCS        ; Set S  $008F
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #160
         TCS        ; Set S  $012F
         ADC #-47
         TCD        ; Set DP $0100
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #206
         TCS        ; Set S  $01CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $026F
         ADC #-111
         TCD        ; Set DP $0200
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #270
         TCS        ; Set S  $030F
         ADC #-15
         TCD        ; Set DP $0300
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #430
         TCS        ; Set S  $03AF
         ADC #-175
         TCD        ; Set DP $0300
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #334
         TCS        ; Set S  $044F
         ADC #-79
         TCD        ; Set DP $0400
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #238
         TCS        ; Set S  $04EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         JMP BRET   ;843 cycles
blit232_64 ANOP
         TCD        ; Set DP $0000
         ADC #147
         TCS        ; Set S  $0093
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         ADC #160
         TCS        ; Set S  $0133
         ADC #-51
         TCD        ; Set DP $0100
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #210
         TCS        ; Set S  $01D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $0273
         ADC #-115
         TCD        ; Set DP $0200
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #274
         TCS        ; Set S  $0313
         ADC #-19
         TCD        ; Set DP $0300
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #434
         TCS        ; Set S  $03B3
         ADC #-179
         TCD        ; Set DP $0300
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         ADC #338
         TCS        ; Set S  $0453
         ADC #-83
         TCD        ; Set DP $0400
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #242
         TCS        ; Set S  $04F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         JMP BRET   ;843 cycles
blit240_64 ANOP
         TCD        ; Set DP $0000
         ADC #151
         TCS        ; Set S  $0097
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         ADC #160
         TCS        ; Set S  $0137
         ADC #-55
         TCD        ; Set DP $0100
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #214
         TCS        ; Set S  $01D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $0277
         ADC #-119
         TCD        ; Set DP $0200
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #278
         TCS        ; Set S  $0317
         ADC #-23
         TCD        ; Set DP $0300
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #438
         TCS        ; Set S  $03B7
         ADC #-183
         TCD        ; Set DP $0300
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         ADC #342
         TCS        ; Set S  $0457
         ADC #-87
         TCD        ; Set DP $0400
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #246
         TCS        ; Set S  $04F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         JMP BRET   ;843 cycles
blit248_64 ANOP
         TCD        ; Set DP $0000
         ADC #155
         TCS        ; Set S  $009B
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         ADC #160
         TCS        ; Set S  $013B
         ADC #-59
         TCD        ; Set DP $0100
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #218
         TCS        ; Set S  $01DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $027B
         ADC #-123
         TCD        ; Set DP $0200
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #282
         TCS        ; Set S  $031B
         ADC #-27
         TCD        ; Set DP $0300
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         ADC #442
         TCS        ; Set S  $03BB
         ADC #-187
         TCD        ; Set DP $0300
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         ADC #346
         TCS        ; Set S  $045B
         ADC #-91
         TCD        ; Set DP $0400
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #250
         TCS        ; Set S  $04FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         JMP BRET   ;843 cycles
blit256_64 ANOP
         TCD        ; Set DP $0000
         ADC #159
         TCS        ; Set S  $009F
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #160
         TCS        ; Set S  $013F
         ADC #-63
         TCD        ; Set DP $0100
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #222
         TCS        ; Set S  $01DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $027F
         ADC #-127
         TCD        ; Set DP $0200
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #286
         TCS        ; Set S  $031F
         ADC #-31
         TCD        ; Set DP $0300
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #190
         TCS        ; Set S  $03BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $045F
         ADC #-95
         TCD        ; Set DP $0400
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #254
         TCS        ; Set S  $04FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         JMP BRET   ;833 cycles
blit0_56 ANOP
         TCD        ; Set DP $0000
         ADC #27
         TCS        ; Set S  $001B
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #160
         TCS        ; Set S  $00BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $015B
         ADC #-91
         TCD        ; Set DP $0100
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #250
         TCS        ; Set S  $01FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $029B
         ADC #-155
         TCD        ; Set DP $0200
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #314
         TCS        ; Set S  $033B
         ADC #-59
         TCD        ; Set DP $0300
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #218
         TCS        ; Set S  $03DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $047B
         ADC #-123
         TCD        ; Set DP $0400
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         JMP BRET   ;737 cycles
blit8_56 ANOP
         TCD        ; Set DP $0000
         ADC #31
         TCS        ; Set S  $001F
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #160
         TCS        ; Set S  $00BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $015F
         ADC #-95
         TCD        ; Set DP $0100
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #254
         TCS        ; Set S  $01FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $029F
         ADC #-159
         TCD        ; Set DP $0200
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #318
         TCS        ; Set S  $033F
         ADC #-63
         TCD        ; Set DP $0300
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #222
         TCS        ; Set S  $03DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $047F
         ADC #-127
         TCD        ; Set DP $0400
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         JMP BRET   ;737 cycles
blit16_56 ANOP
         TCD        ; Set DP $0000
         ADC #35
         TCS        ; Set S  $0023
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #160
         TCS        ; Set S  $00C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $0163
         ADC #-99
         TCD        ; Set DP $0100
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #258
         TCS        ; Set S  $0203
         ADC #-3
         TCD        ; Set DP $0200
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #418
         TCS        ; Set S  $02A3
         ADC #-163
         TCD        ; Set DP $0200
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #322
         TCS        ; Set S  $0343
         ADC #-67
         TCD        ; Set DP $0300
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #226
         TCS        ; Set S  $03E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $0483
         ADC #-131
         TCD        ; Set DP $0400
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         JMP BRET   ;747 cycles
blit24_56 ANOP
         TCD        ; Set DP $0000
         ADC #39
         TCS        ; Set S  $0027
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #160
         TCS        ; Set S  $00C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $0167
         ADC #-103
         TCD        ; Set DP $0100
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #262
         TCS        ; Set S  $0207
         ADC #-7
         TCD        ; Set DP $0200
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #422
         TCS        ; Set S  $02A7
         ADC #-167
         TCD        ; Set DP $0200
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #326
         TCS        ; Set S  $0347
         ADC #-71
         TCD        ; Set DP $0300
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #230
         TCS        ; Set S  $03E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $0487
         ADC #-135
         TCD        ; Set DP $0400
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         JMP BRET   ;747 cycles
blit32_56 ANOP
         TCD        ; Set DP $0000
         ADC #43
         TCS        ; Set S  $002B
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #160
         TCS        ; Set S  $00CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $016B
         ADC #-107
         TCD        ; Set DP $0100
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #266
         TCS        ; Set S  $020B
         ADC #-11
         TCD        ; Set DP $0200
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #426
         TCS        ; Set S  $02AB
         ADC #-171
         TCD        ; Set DP $0200
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #330
         TCS        ; Set S  $034B
         ADC #-75
         TCD        ; Set DP $0300
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #234
         TCS        ; Set S  $03EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $048B
         ADC #-139
         TCD        ; Set DP $0400
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         JMP BRET   ;747 cycles
blit40_56 ANOP
         TCD        ; Set DP $0000
         ADC #47
         TCS        ; Set S  $002F
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #160
         TCS        ; Set S  $00CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $016F
         ADC #-111
         TCD        ; Set DP $0100
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #270
         TCS        ; Set S  $020F
         ADC #-15
         TCD        ; Set DP $0200
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #430
         TCS        ; Set S  $02AF
         ADC #-175
         TCD        ; Set DP $0200
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         ADC #334
         TCS        ; Set S  $034F
         ADC #-79
         TCD        ; Set DP $0300
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #238
         TCS        ; Set S  $03EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $048F
         ADC #-143
         TCD        ; Set DP $0400
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         JMP BRET   ;747 cycles
blit48_56 ANOP
         TCD        ; Set DP $0000
         ADC #51
         TCS        ; Set S  $0033
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #160
         TCS        ; Set S  $00D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $0173
         ADC #-115
         TCD        ; Set DP $0100
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #274
         TCS        ; Set S  $0213
         ADC #-19
         TCD        ; Set DP $0200
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #434
         TCS        ; Set S  $02B3
         ADC #-179
         TCD        ; Set DP $0200
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         ADC #338
         TCS        ; Set S  $0353
         ADC #-83
         TCD        ; Set DP $0300
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #242
         TCS        ; Set S  $03F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $0493
         ADC #-147
         TCD        ; Set DP $0400
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         JMP BRET   ;747 cycles
blit56_56 ANOP
         TCD        ; Set DP $0000
         ADC #55
         TCS        ; Set S  $0037
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #160
         TCS        ; Set S  $00D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $0177
         ADC #-119
         TCD        ; Set DP $0100
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #278
         TCS        ; Set S  $0217
         ADC #-23
         TCD        ; Set DP $0200
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         ADC #438
         TCS        ; Set S  $02B7
         ADC #-183
         TCD        ; Set DP $0200
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         ADC #342
         TCS        ; Set S  $0357
         ADC #-87
         TCD        ; Set DP $0300
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #246
         TCS        ; Set S  $03F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $0497
         ADC #-151
         TCD        ; Set DP $0400
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         JMP BRET   ;747 cycles
blit64_56 ANOP
         TCD        ; Set DP $0000
         ADC #59
         TCS        ; Set S  $003B
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #160
         TCS        ; Set S  $00DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $017B
         ADC #-123
         TCD        ; Set DP $0100
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #282
         TCS        ; Set S  $021B
         ADC #-27
         TCD        ; Set DP $0200
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #186
         TCS        ; Set S  $02BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $035B
         ADC #-91
         TCD        ; Set DP $0300
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #250
         TCS        ; Set S  $03FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $049B
         ADC #-155
         TCD        ; Set DP $0400
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         JMP BRET   ;737 cycles
blit72_56 ANOP
         TCD        ; Set DP $0000
         ADC #63
         TCS        ; Set S  $003F
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #160
         TCS        ; Set S  $00DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $017F
         ADC #-127
         TCD        ; Set DP $0100
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #286
         TCS        ; Set S  $021F
         ADC #-31
         TCD        ; Set DP $0200
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #190
         TCS        ; Set S  $02BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $035F
         ADC #-95
         TCD        ; Set DP $0300
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #254
         TCS        ; Set S  $03FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $049F
         ADC #-159
         TCD        ; Set DP $0400
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         JMP BRET   ;737 cycles
blit80_56 ANOP
         TCD        ; Set DP $0000
         ADC #67
         TCS        ; Set S  $0043
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #160
         TCS        ; Set S  $00E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $0183
         ADC #-131
         TCD        ; Set DP $0100
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #290
         TCS        ; Set S  $0223
         ADC #-35
         TCD        ; Set DP $0200
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #194
         TCS        ; Set S  $02C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $0363
         ADC #-99
         TCD        ; Set DP $0300
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #258
         TCS        ; Set S  $0403
         ADC #-3
         TCD        ; Set DP $0400
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #418
         TCS        ; Set S  $04A3
         ADC #-163
         TCD        ; Set DP $0400
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         JMP BRET   ;747 cycles
blit88_56 ANOP
         TCD        ; Set DP $0000
         ADC #71
         TCS        ; Set S  $0047
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #160
         TCS        ; Set S  $00E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $0187
         ADC #-135
         TCD        ; Set DP $0100
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #294
         TCS        ; Set S  $0227
         ADC #-39
         TCD        ; Set DP $0200
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #198
         TCS        ; Set S  $02C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $0367
         ADC #-103
         TCD        ; Set DP $0300
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #262
         TCS        ; Set S  $0407
         ADC #-7
         TCD        ; Set DP $0400
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #422
         TCS        ; Set S  $04A7
         ADC #-167
         TCD        ; Set DP $0400
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         JMP BRET   ;747 cycles
blit96_56 ANOP
         TCD        ; Set DP $0000
         ADC #75
         TCS        ; Set S  $004B
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #160
         TCS        ; Set S  $00EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $018B
         ADC #-139
         TCD        ; Set DP $0100
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #298
         TCS        ; Set S  $022B
         ADC #-43
         TCD        ; Set DP $0200
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #202
         TCS        ; Set S  $02CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $036B
         ADC #-107
         TCD        ; Set DP $0300
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #266
         TCS        ; Set S  $040B
         ADC #-11
         TCD        ; Set DP $0400
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #426
         TCS        ; Set S  $04AB
         ADC #-171
         TCD        ; Set DP $0400
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         JMP BRET   ;747 cycles
blit104_56 ANOP
         TCD        ; Set DP $0000
         ADC #79
         TCS        ; Set S  $004F
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #160
         TCS        ; Set S  $00EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $018F
         ADC #-143
         TCD        ; Set DP $0100
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         ADC #302
         TCS        ; Set S  $022F
         ADC #-47
         TCD        ; Set DP $0200
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #206
         TCS        ; Set S  $02CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $036F
         ADC #-111
         TCD        ; Set DP $0300
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #270
         TCS        ; Set S  $040F
         ADC #-15
         TCD        ; Set DP $0400
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #430
         TCS        ; Set S  $04AF
         ADC #-175
         TCD        ; Set DP $0400
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         JMP BRET   ;747 cycles
blit112_56 ANOP
         TCD        ; Set DP $0000
         ADC #83
         TCS        ; Set S  $0053
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #160
         TCS        ; Set S  $00F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $0193
         ADC #-147
         TCD        ; Set DP $0100
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         ADC #306
         TCS        ; Set S  $0233
         ADC #-51
         TCD        ; Set DP $0200
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #210
         TCS        ; Set S  $02D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $0373
         ADC #-115
         TCD        ; Set DP $0300
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #274
         TCS        ; Set S  $0413
         ADC #-19
         TCD        ; Set DP $0400
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #434
         TCS        ; Set S  $04B3
         ADC #-179
         TCD        ; Set DP $0400
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         JMP BRET   ;747 cycles
blit120_56 ANOP
         TCD        ; Set DP $0000
         ADC #87
         TCS        ; Set S  $0057
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #160
         TCS        ; Set S  $00F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $0197
         ADC #-151
         TCD        ; Set DP $0100
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         ADC #310
         TCS        ; Set S  $0237
         ADC #-55
         TCD        ; Set DP $0200
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #214
         TCS        ; Set S  $02D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $0377
         ADC #-119
         TCD        ; Set DP $0300
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #278
         TCS        ; Set S  $0417
         ADC #-23
         TCD        ; Set DP $0400
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         ADC #438
         TCS        ; Set S  $04B7
         ADC #-183
         TCD        ; Set DP $0400
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         JMP BRET   ;747 cycles
blit128_56 ANOP
         TCD        ; Set DP $0000
         ADC #91
         TCS        ; Set S  $005B
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #160
         TCS        ; Set S  $00FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $019B
         ADC #-155
         TCD        ; Set DP $0100
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #314
         TCS        ; Set S  $023B
         ADC #-59
         TCD        ; Set DP $0200
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #218
         TCS        ; Set S  $02DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $037B
         ADC #-123
         TCD        ; Set DP $0300
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #282
         TCS        ; Set S  $041B
         ADC #-27
         TCD        ; Set DP $0400
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #186
         TCS        ; Set S  $04BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         JMP BRET   ;737 cycles
blit136_56 ANOP
         TCD        ; Set DP $0000
         ADC #95
         TCS        ; Set S  $005F
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #160
         TCS        ; Set S  $00FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $019F
         ADC #-159
         TCD        ; Set DP $0100
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #318
         TCS        ; Set S  $023F
         ADC #-63
         TCD        ; Set DP $0200
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #222
         TCS        ; Set S  $02DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $037F
         ADC #-127
         TCD        ; Set DP $0300
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #286
         TCS        ; Set S  $041F
         ADC #-31
         TCD        ; Set DP $0400
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #190
         TCS        ; Set S  $04BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         JMP BRET   ;737 cycles
blit144_56 ANOP
         TCD        ; Set DP $0000
         ADC #99
         TCS        ; Set S  $0063
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #160
         TCS        ; Set S  $0103
         ADC #-3
         TCD        ; Set DP $0100
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #418
         TCS        ; Set S  $01A3
         ADC #-163
         TCD        ; Set DP $0100
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #322
         TCS        ; Set S  $0243
         ADC #-67
         TCD        ; Set DP $0200
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #226
         TCS        ; Set S  $02E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $0383
         ADC #-131
         TCD        ; Set DP $0300
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #290
         TCS        ; Set S  $0423
         ADC #-35
         TCD        ; Set DP $0400
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #194
         TCS        ; Set S  $04C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         JMP BRET   ;747 cycles
blit152_56 ANOP
         TCD        ; Set DP $0000
         ADC #103
         TCS        ; Set S  $0067
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #160
         TCS        ; Set S  $0107
         ADC #-7
         TCD        ; Set DP $0100
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #422
         TCS        ; Set S  $01A7
         ADC #-167
         TCD        ; Set DP $0100
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #326
         TCS        ; Set S  $0247
         ADC #-71
         TCD        ; Set DP $0200
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #230
         TCS        ; Set S  $02E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $0387
         ADC #-135
         TCD        ; Set DP $0300
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #294
         TCS        ; Set S  $0427
         ADC #-39
         TCD        ; Set DP $0400
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #198
         TCS        ; Set S  $04C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         JMP BRET   ;747 cycles
blit160_56 ANOP
         TCD        ; Set DP $0000
         ADC #107
         TCS        ; Set S  $006B
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #160
         TCS        ; Set S  $010B
         ADC #-11
         TCD        ; Set DP $0100
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #426
         TCS        ; Set S  $01AB
         ADC #-171
         TCD        ; Set DP $0100
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #330
         TCS        ; Set S  $024B
         ADC #-75
         TCD        ; Set DP $0200
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #234
         TCS        ; Set S  $02EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $038B
         ADC #-139
         TCD        ; Set DP $0300
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #298
         TCS        ; Set S  $042B
         ADC #-43
         TCD        ; Set DP $0400
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #202
         TCS        ; Set S  $04CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         JMP BRET   ;747 cycles
blit168_56 ANOP
         TCD        ; Set DP $0000
         ADC #111
         TCS        ; Set S  $006F
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #160
         TCS        ; Set S  $010F
         ADC #-15
         TCD        ; Set DP $0100
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #430
         TCS        ; Set S  $01AF
         ADC #-175
         TCD        ; Set DP $0100
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         ADC #334
         TCS        ; Set S  $024F
         ADC #-79
         TCD        ; Set DP $0200
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #238
         TCS        ; Set S  $02EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $038F
         ADC #-143
         TCD        ; Set DP $0300
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         ADC #302
         TCS        ; Set S  $042F
         ADC #-47
         TCD        ; Set DP $0400
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #206
         TCS        ; Set S  $04CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         JMP BRET   ;747 cycles
blit176_56 ANOP
         TCD        ; Set DP $0000
         ADC #115
         TCS        ; Set S  $0073
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #160
         TCS        ; Set S  $0113
         ADC #-19
         TCD        ; Set DP $0100
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #434
         TCS        ; Set S  $01B3
         ADC #-179
         TCD        ; Set DP $0100
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         ADC #338
         TCS        ; Set S  $0253
         ADC #-83
         TCD        ; Set DP $0200
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #242
         TCS        ; Set S  $02F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $0393
         ADC #-147
         TCD        ; Set DP $0300
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         ADC #306
         TCS        ; Set S  $0433
         ADC #-51
         TCD        ; Set DP $0400
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #210
         TCS        ; Set S  $04D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         JMP BRET   ;747 cycles
blit184_56 ANOP
         TCD        ; Set DP $0000
         ADC #119
         TCS        ; Set S  $0077
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #160
         TCS        ; Set S  $0117
         ADC #-23
         TCD        ; Set DP $0100
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         ADC #438
         TCS        ; Set S  $01B7
         ADC #-183
         TCD        ; Set DP $0100
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         ADC #342
         TCS        ; Set S  $0257
         ADC #-87
         TCD        ; Set DP $0200
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #246
         TCS        ; Set S  $02F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $0397
         ADC #-151
         TCD        ; Set DP $0300
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         ADC #310
         TCS        ; Set S  $0437
         ADC #-55
         TCD        ; Set DP $0400
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #214
         TCS        ; Set S  $04D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         JMP BRET   ;747 cycles
blit192_56 ANOP
         TCD        ; Set DP $0000
         ADC #123
         TCS        ; Set S  $007B
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #160
         TCS        ; Set S  $011B
         ADC #-27
         TCD        ; Set DP $0100
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #186
         TCS        ; Set S  $01BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $025B
         ADC #-91
         TCD        ; Set DP $0200
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #250
         TCS        ; Set S  $02FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $039B
         ADC #-155
         TCD        ; Set DP $0300
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #314
         TCS        ; Set S  $043B
         ADC #-59
         TCD        ; Set DP $0400
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #218
         TCS        ; Set S  $04DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         JMP BRET   ;737 cycles
blit200_56 ANOP
         TCD        ; Set DP $0000
         ADC #127
         TCS        ; Set S  $007F
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #160
         TCS        ; Set S  $011F
         ADC #-31
         TCD        ; Set DP $0100
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #190
         TCS        ; Set S  $01BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $025F
         ADC #-95
         TCD        ; Set DP $0200
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #254
         TCS        ; Set S  $02FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $039F
         ADC #-159
         TCD        ; Set DP $0300
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #318
         TCS        ; Set S  $043F
         ADC #-63
         TCD        ; Set DP $0400
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #222
         TCS        ; Set S  $04DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         JMP BRET   ;737 cycles
blit208_56 ANOP
         TCD        ; Set DP $0000
         ADC #131
         TCS        ; Set S  $0083
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #160
         TCS        ; Set S  $0123
         ADC #-35
         TCD        ; Set DP $0100
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #194
         TCS        ; Set S  $01C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $0263
         ADC #-99
         TCD        ; Set DP $0200
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #258
         TCS        ; Set S  $0303
         ADC #-3
         TCD        ; Set DP $0300
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #418
         TCS        ; Set S  $03A3
         ADC #-163
         TCD        ; Set DP $0300
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #322
         TCS        ; Set S  $0443
         ADC #-67
         TCD        ; Set DP $0400
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #226
         TCS        ; Set S  $04E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         JMP BRET   ;747 cycles
blit216_56 ANOP
         TCD        ; Set DP $0000
         ADC #135
         TCS        ; Set S  $0087
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #160
         TCS        ; Set S  $0127
         ADC #-39
         TCD        ; Set DP $0100
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #198
         TCS        ; Set S  $01C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $0267
         ADC #-103
         TCD        ; Set DP $0200
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #262
         TCS        ; Set S  $0307
         ADC #-7
         TCD        ; Set DP $0300
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #422
         TCS        ; Set S  $03A7
         ADC #-167
         TCD        ; Set DP $0300
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #326
         TCS        ; Set S  $0447
         ADC #-71
         TCD        ; Set DP $0400
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #230
         TCS        ; Set S  $04E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         JMP BRET   ;747 cycles
blit224_56 ANOP
         TCD        ; Set DP $0000
         ADC #139
         TCS        ; Set S  $008B
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #160
         TCS        ; Set S  $012B
         ADC #-43
         TCD        ; Set DP $0100
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #202
         TCS        ; Set S  $01CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $026B
         ADC #-107
         TCD        ; Set DP $0200
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #266
         TCS        ; Set S  $030B
         ADC #-11
         TCD        ; Set DP $0300
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #426
         TCS        ; Set S  $03AB
         ADC #-171
         TCD        ; Set DP $0300
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #330
         TCS        ; Set S  $044B
         ADC #-75
         TCD        ; Set DP $0400
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #234
         TCS        ; Set S  $04EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         JMP BRET   ;747 cycles
blit232_56 ANOP
         TCD        ; Set DP $0000
         ADC #143
         TCS        ; Set S  $008F
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         ADC #160
         TCS        ; Set S  $012F
         ADC #-47
         TCD        ; Set DP $0100
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #206
         TCS        ; Set S  $01CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $026F
         ADC #-111
         TCD        ; Set DP $0200
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #270
         TCS        ; Set S  $030F
         ADC #-15
         TCD        ; Set DP $0300
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #430
         TCS        ; Set S  $03AF
         ADC #-175
         TCD        ; Set DP $0300
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         ADC #334
         TCS        ; Set S  $044F
         ADC #-79
         TCD        ; Set DP $0400
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #238
         TCS        ; Set S  $04EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         JMP BRET   ;747 cycles
blit240_56 ANOP
         TCD        ; Set DP $0000
         ADC #147
         TCS        ; Set S  $0093
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         ADC #160
         TCS        ; Set S  $0133
         ADC #-51
         TCD        ; Set DP $0100
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #210
         TCS        ; Set S  $01D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $0273
         ADC #-115
         TCD        ; Set DP $0200
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #274
         TCS        ; Set S  $0313
         ADC #-19
         TCD        ; Set DP $0300
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #434
         TCS        ; Set S  $03B3
         ADC #-179
         TCD        ; Set DP $0300
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         ADC #338
         TCS        ; Set S  $0453
         ADC #-83
         TCD        ; Set DP $0400
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #242
         TCS        ; Set S  $04F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         JMP BRET   ;747 cycles
blit248_56 ANOP
         TCD        ; Set DP $0000
         ADC #151
         TCS        ; Set S  $0097
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         ADC #160
         TCS        ; Set S  $0137
         ADC #-55
         TCD        ; Set DP $0100
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #214
         TCS        ; Set S  $01D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $0277
         ADC #-119
         TCD        ; Set DP $0200
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #278
         TCS        ; Set S  $0317
         ADC #-23
         TCD        ; Set DP $0300
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         ADC #438
         TCS        ; Set S  $03B7
         ADC #-183
         TCD        ; Set DP $0300
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         ADC #342
         TCS        ; Set S  $0457
         ADC #-87
         TCD        ; Set DP $0400
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #246
         TCS        ; Set S  $04F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         JMP BRET   ;747 cycles
blit256_56 ANOP
         TCD        ; Set DP $0000
         ADC #155
         TCS        ; Set S  $009B
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #160
         TCS        ; Set S  $013B
         ADC #-59
         TCD        ; Set DP $0100
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #218
         TCS        ; Set S  $01DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $027B
         ADC #-123
         TCD        ; Set DP $0200
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #282
         TCS        ; Set S  $031B
         ADC #-27
         TCD        ; Set DP $0300
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #186
         TCS        ; Set S  $03BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $045B
         ADC #-91
         TCD        ; Set DP $0400
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #250
         TCS        ; Set S  $04FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         JMP BRET   ;737 cycles
blit264_56 ANOP
         TCD        ; Set DP $0000
         ADC #159
         TCS        ; Set S  $009F
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #160
         TCS        ; Set S  $013F
         ADC #-63
         TCD        ; Set DP $0100
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #222
         TCS        ; Set S  $01DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $027F
         ADC #-127
         TCD        ; Set DP $0200
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #286
         TCS        ; Set S  $031F
         ADC #-31
         TCD        ; Set DP $0300
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #190
         TCS        ; Set S  $03BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $045F
         ADC #-95
         TCD        ; Set DP $0400
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #254
         TCS        ; Set S  $04FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         JMP BRET   ;737 cycles
blit0_48 ANOP
         TCD        ; Set DP $0000
         ADC #23
         TCS        ; Set S  $0017
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #160
         TCS        ; Set S  $00B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $0157
         ADC #-87
         TCD        ; Set DP $0100
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #246
         TCS        ; Set S  $01F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $0297
         ADC #-151
         TCD        ; Set DP $0200
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #310
         TCS        ; Set S  $0337
         ADC #-55
         TCD        ; Set DP $0300
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #214
         TCS        ; Set S  $03D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $0477
         ADC #-119
         TCD        ; Set DP $0400
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         JMP BRET   ;641 cycles
blit8_48 ANOP
         TCD        ; Set DP $0000
         ADC #27
         TCS        ; Set S  $001B
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #160
         TCS        ; Set S  $00BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $015B
         ADC #-91
         TCD        ; Set DP $0100
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #250
         TCS        ; Set S  $01FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $029B
         ADC #-155
         TCD        ; Set DP $0200
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #314
         TCS        ; Set S  $033B
         ADC #-59
         TCD        ; Set DP $0300
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #218
         TCS        ; Set S  $03DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $047B
         ADC #-123
         TCD        ; Set DP $0400
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         JMP BRET   ;641 cycles
blit16_48 ANOP
         TCD        ; Set DP $0000
         ADC #31
         TCS        ; Set S  $001F
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #160
         TCS        ; Set S  $00BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $015F
         ADC #-95
         TCD        ; Set DP $0100
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #254
         TCS        ; Set S  $01FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $029F
         ADC #-159
         TCD        ; Set DP $0200
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #318
         TCS        ; Set S  $033F
         ADC #-63
         TCD        ; Set DP $0300
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #222
         TCS        ; Set S  $03DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $047F
         ADC #-127
         TCD        ; Set DP $0400
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         JMP BRET   ;641 cycles
blit24_48 ANOP
         TCD        ; Set DP $0000
         ADC #35
         TCS        ; Set S  $0023
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #160
         TCS        ; Set S  $00C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $0163
         ADC #-99
         TCD        ; Set DP $0100
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #258
         TCS        ; Set S  $0203
         ADC #-3
         TCD        ; Set DP $0200
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #418
         TCS        ; Set S  $02A3
         ADC #-163
         TCD        ; Set DP $0200
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #322
         TCS        ; Set S  $0343
         ADC #-67
         TCD        ; Set DP $0300
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #226
         TCS        ; Set S  $03E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $0483
         ADC #-131
         TCD        ; Set DP $0400
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         JMP BRET   ;651 cycles
blit32_48 ANOP
         TCD        ; Set DP $0000
         ADC #39
         TCS        ; Set S  $0027
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #160
         TCS        ; Set S  $00C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $0167
         ADC #-103
         TCD        ; Set DP $0100
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #262
         TCS        ; Set S  $0207
         ADC #-7
         TCD        ; Set DP $0200
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #422
         TCS        ; Set S  $02A7
         ADC #-167
         TCD        ; Set DP $0200
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #326
         TCS        ; Set S  $0347
         ADC #-71
         TCD        ; Set DP $0300
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #230
         TCS        ; Set S  $03E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $0487
         ADC #-135
         TCD        ; Set DP $0400
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         JMP BRET   ;651 cycles
blit40_48 ANOP
         TCD        ; Set DP $0000
         ADC #43
         TCS        ; Set S  $002B
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #160
         TCS        ; Set S  $00CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $016B
         ADC #-107
         TCD        ; Set DP $0100
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #266
         TCS        ; Set S  $020B
         ADC #-11
         TCD        ; Set DP $0200
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #426
         TCS        ; Set S  $02AB
         ADC #-171
         TCD        ; Set DP $0200
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         ADC #330
         TCS        ; Set S  $034B
         ADC #-75
         TCD        ; Set DP $0300
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #234
         TCS        ; Set S  $03EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $048B
         ADC #-139
         TCD        ; Set DP $0400
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         JMP BRET   ;651 cycles
blit48_48 ANOP
         TCD        ; Set DP $0000
         ADC #47
         TCS        ; Set S  $002F
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #160
         TCS        ; Set S  $00CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $016F
         ADC #-111
         TCD        ; Set DP $0100
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #270
         TCS        ; Set S  $020F
         ADC #-15
         TCD        ; Set DP $0200
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #430
         TCS        ; Set S  $02AF
         ADC #-175
         TCD        ; Set DP $0200
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         ADC #334
         TCS        ; Set S  $034F
         ADC #-79
         TCD        ; Set DP $0300
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #238
         TCS        ; Set S  $03EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $048F
         ADC #-143
         TCD        ; Set DP $0400
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         JMP BRET   ;651 cycles
blit56_48 ANOP
         TCD        ; Set DP $0000
         ADC #51
         TCS        ; Set S  $0033
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #160
         TCS        ; Set S  $00D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $0173
         ADC #-115
         TCD        ; Set DP $0100
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #274
         TCS        ; Set S  $0213
         ADC #-19
         TCD        ; Set DP $0200
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         ADC #434
         TCS        ; Set S  $02B3
         ADC #-179
         TCD        ; Set DP $0200
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         ADC #338
         TCS        ; Set S  $0353
         ADC #-83
         TCD        ; Set DP $0300
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #242
         TCS        ; Set S  $03F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $0493
         ADC #-147
         TCD        ; Set DP $0400
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         JMP BRET   ;651 cycles
blit64_48 ANOP
         TCD        ; Set DP $0000
         ADC #55
         TCS        ; Set S  $0037
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #160
         TCS        ; Set S  $00D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $0177
         ADC #-119
         TCD        ; Set DP $0100
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #278
         TCS        ; Set S  $0217
         ADC #-23
         TCD        ; Set DP $0200
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #182
         TCS        ; Set S  $02B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $0357
         ADC #-87
         TCD        ; Set DP $0300
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #246
         TCS        ; Set S  $03F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $0497
         ADC #-151
         TCD        ; Set DP $0400
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         JMP BRET   ;641 cycles
blit72_48 ANOP
         TCD        ; Set DP $0000
         ADC #59
         TCS        ; Set S  $003B
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #160
         TCS        ; Set S  $00DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $017B
         ADC #-123
         TCD        ; Set DP $0100
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #282
         TCS        ; Set S  $021B
         ADC #-27
         TCD        ; Set DP $0200
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #186
         TCS        ; Set S  $02BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $035B
         ADC #-91
         TCD        ; Set DP $0300
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #250
         TCS        ; Set S  $03FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $049B
         ADC #-155
         TCD        ; Set DP $0400
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         JMP BRET   ;641 cycles
blit80_48 ANOP
         TCD        ; Set DP $0000
         ADC #63
         TCS        ; Set S  $003F
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #160
         TCS        ; Set S  $00DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $017F
         ADC #-127
         TCD        ; Set DP $0100
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #286
         TCS        ; Set S  $021F
         ADC #-31
         TCD        ; Set DP $0200
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #190
         TCS        ; Set S  $02BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $035F
         ADC #-95
         TCD        ; Set DP $0300
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #254
         TCS        ; Set S  $03FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $049F
         ADC #-159
         TCD        ; Set DP $0400
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         JMP BRET   ;641 cycles
blit88_48 ANOP
         TCD        ; Set DP $0000
         ADC #67
         TCS        ; Set S  $0043
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #160
         TCS        ; Set S  $00E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $0183
         ADC #-131
         TCD        ; Set DP $0100
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #290
         TCS        ; Set S  $0223
         ADC #-35
         TCD        ; Set DP $0200
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #194
         TCS        ; Set S  $02C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $0363
         ADC #-99
         TCD        ; Set DP $0300
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #258
         TCS        ; Set S  $0403
         ADC #-3
         TCD        ; Set DP $0400
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #418
         TCS        ; Set S  $04A3
         ADC #-163
         TCD        ; Set DP $0400
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         JMP BRET   ;651 cycles
blit96_48 ANOP
         TCD        ; Set DP $0000
         ADC #71
         TCS        ; Set S  $0047
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #160
         TCS        ; Set S  $00E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $0187
         ADC #-135
         TCD        ; Set DP $0100
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #294
         TCS        ; Set S  $0227
         ADC #-39
         TCD        ; Set DP $0200
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #198
         TCS        ; Set S  $02C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $0367
         ADC #-103
         TCD        ; Set DP $0300
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #262
         TCS        ; Set S  $0407
         ADC #-7
         TCD        ; Set DP $0400
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #422
         TCS        ; Set S  $04A7
         ADC #-167
         TCD        ; Set DP $0400
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         JMP BRET   ;651 cycles
blit104_48 ANOP
         TCD        ; Set DP $0000
         ADC #75
         TCS        ; Set S  $004B
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #160
         TCS        ; Set S  $00EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $018B
         ADC #-139
         TCD        ; Set DP $0100
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         ADC #298
         TCS        ; Set S  $022B
         ADC #-43
         TCD        ; Set DP $0200
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #202
         TCS        ; Set S  $02CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $036B
         ADC #-107
         TCD        ; Set DP $0300
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #266
         TCS        ; Set S  $040B
         ADC #-11
         TCD        ; Set DP $0400
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #426
         TCS        ; Set S  $04AB
         ADC #-171
         TCD        ; Set DP $0400
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         JMP BRET   ;651 cycles
blit112_48 ANOP
         TCD        ; Set DP $0000
         ADC #79
         TCS        ; Set S  $004F
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #160
         TCS        ; Set S  $00EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $018F
         ADC #-143
         TCD        ; Set DP $0100
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         ADC #302
         TCS        ; Set S  $022F
         ADC #-47
         TCD        ; Set DP $0200
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #206
         TCS        ; Set S  $02CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $036F
         ADC #-111
         TCD        ; Set DP $0300
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #270
         TCS        ; Set S  $040F
         ADC #-15
         TCD        ; Set DP $0400
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #430
         TCS        ; Set S  $04AF
         ADC #-175
         TCD        ; Set DP $0400
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         JMP BRET   ;651 cycles
blit120_48 ANOP
         TCD        ; Set DP $0000
         ADC #83
         TCS        ; Set S  $0053
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #160
         TCS        ; Set S  $00F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $0193
         ADC #-147
         TCD        ; Set DP $0100
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         ADC #306
         TCS        ; Set S  $0233
         ADC #-51
         TCD        ; Set DP $0200
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #210
         TCS        ; Set S  $02D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $0373
         ADC #-115
         TCD        ; Set DP $0300
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #274
         TCS        ; Set S  $0413
         ADC #-19
         TCD        ; Set DP $0400
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         ADC #434
         TCS        ; Set S  $04B3
         ADC #-179
         TCD        ; Set DP $0400
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         JMP BRET   ;651 cycles
blit128_48 ANOP
         TCD        ; Set DP $0000
         ADC #87
         TCS        ; Set S  $0057
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #160
         TCS        ; Set S  $00F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $0197
         ADC #-151
         TCD        ; Set DP $0100
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #310
         TCS        ; Set S  $0237
         ADC #-55
         TCD        ; Set DP $0200
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #214
         TCS        ; Set S  $02D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $0377
         ADC #-119
         TCD        ; Set DP $0300
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #278
         TCS        ; Set S  $0417
         ADC #-23
         TCD        ; Set DP $0400
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #182
         TCS        ; Set S  $04B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         JMP BRET   ;641 cycles
blit136_48 ANOP
         TCD        ; Set DP $0000
         ADC #91
         TCS        ; Set S  $005B
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #160
         TCS        ; Set S  $00FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $019B
         ADC #-155
         TCD        ; Set DP $0100
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #314
         TCS        ; Set S  $023B
         ADC #-59
         TCD        ; Set DP $0200
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #218
         TCS        ; Set S  $02DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $037B
         ADC #-123
         TCD        ; Set DP $0300
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #282
         TCS        ; Set S  $041B
         ADC #-27
         TCD        ; Set DP $0400
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #186
         TCS        ; Set S  $04BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         JMP BRET   ;641 cycles
blit144_48 ANOP
         TCD        ; Set DP $0000
         ADC #95
         TCS        ; Set S  $005F
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #160
         TCS        ; Set S  $00FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $019F
         ADC #-159
         TCD        ; Set DP $0100
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #318
         TCS        ; Set S  $023F
         ADC #-63
         TCD        ; Set DP $0200
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #222
         TCS        ; Set S  $02DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $037F
         ADC #-127
         TCD        ; Set DP $0300
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #286
         TCS        ; Set S  $041F
         ADC #-31
         TCD        ; Set DP $0400
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #190
         TCS        ; Set S  $04BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         JMP BRET   ;641 cycles
blit152_48 ANOP
         TCD        ; Set DP $0000
         ADC #99
         TCS        ; Set S  $0063
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #160
         TCS        ; Set S  $0103
         ADC #-3
         TCD        ; Set DP $0100
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #418
         TCS        ; Set S  $01A3
         ADC #-163
         TCD        ; Set DP $0100
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #322
         TCS        ; Set S  $0243
         ADC #-67
         TCD        ; Set DP $0200
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #226
         TCS        ; Set S  $02E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $0383
         ADC #-131
         TCD        ; Set DP $0300
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #290
         TCS        ; Set S  $0423
         ADC #-35
         TCD        ; Set DP $0400
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #194
         TCS        ; Set S  $04C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         JMP BRET   ;651 cycles
blit160_48 ANOP
         TCD        ; Set DP $0000
         ADC #103
         TCS        ; Set S  $0067
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #160
         TCS        ; Set S  $0107
         ADC #-7
         TCD        ; Set DP $0100
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #422
         TCS        ; Set S  $01A7
         ADC #-167
         TCD        ; Set DP $0100
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #326
         TCS        ; Set S  $0247
         ADC #-71
         TCD        ; Set DP $0200
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #230
         TCS        ; Set S  $02E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $0387
         ADC #-135
         TCD        ; Set DP $0300
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #294
         TCS        ; Set S  $0427
         ADC #-39
         TCD        ; Set DP $0400
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #198
         TCS        ; Set S  $04C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         JMP BRET   ;651 cycles
blit168_48 ANOP
         TCD        ; Set DP $0000
         ADC #107
         TCS        ; Set S  $006B
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #160
         TCS        ; Set S  $010B
         ADC #-11
         TCD        ; Set DP $0100
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #426
         TCS        ; Set S  $01AB
         ADC #-171
         TCD        ; Set DP $0100
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         ADC #330
         TCS        ; Set S  $024B
         ADC #-75
         TCD        ; Set DP $0200
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #234
         TCS        ; Set S  $02EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $038B
         ADC #-139
         TCD        ; Set DP $0300
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         ADC #298
         TCS        ; Set S  $042B
         ADC #-43
         TCD        ; Set DP $0400
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #202
         TCS        ; Set S  $04CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         JMP BRET   ;651 cycles
blit176_48 ANOP
         TCD        ; Set DP $0000
         ADC #111
         TCS        ; Set S  $006F
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #160
         TCS        ; Set S  $010F
         ADC #-15
         TCD        ; Set DP $0100
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #430
         TCS        ; Set S  $01AF
         ADC #-175
         TCD        ; Set DP $0100
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         ADC #334
         TCS        ; Set S  $024F
         ADC #-79
         TCD        ; Set DP $0200
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #238
         TCS        ; Set S  $02EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $038F
         ADC #-143
         TCD        ; Set DP $0300
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         ADC #302
         TCS        ; Set S  $042F
         ADC #-47
         TCD        ; Set DP $0400
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #206
         TCS        ; Set S  $04CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         JMP BRET   ;651 cycles
blit184_48 ANOP
         TCD        ; Set DP $0000
         ADC #115
         TCS        ; Set S  $0073
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #160
         TCS        ; Set S  $0113
         ADC #-19
         TCD        ; Set DP $0100
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         ADC #434
         TCS        ; Set S  $01B3
         ADC #-179
         TCD        ; Set DP $0100
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         ADC #338
         TCS        ; Set S  $0253
         ADC #-83
         TCD        ; Set DP $0200
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #242
         TCS        ; Set S  $02F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $0393
         ADC #-147
         TCD        ; Set DP $0300
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         ADC #306
         TCS        ; Set S  $0433
         ADC #-51
         TCD        ; Set DP $0400
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #210
         TCS        ; Set S  $04D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         JMP BRET   ;651 cycles
blit192_48 ANOP
         TCD        ; Set DP $0000
         ADC #119
         TCS        ; Set S  $0077
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #160
         TCS        ; Set S  $0117
         ADC #-23
         TCD        ; Set DP $0100
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #182
         TCS        ; Set S  $01B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $0257
         ADC #-87
         TCD        ; Set DP $0200
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #246
         TCS        ; Set S  $02F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $0397
         ADC #-151
         TCD        ; Set DP $0300
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #310
         TCS        ; Set S  $0437
         ADC #-55
         TCD        ; Set DP $0400
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #214
         TCS        ; Set S  $04D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         JMP BRET   ;641 cycles
blit200_48 ANOP
         TCD        ; Set DP $0000
         ADC #123
         TCS        ; Set S  $007B
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #160
         TCS        ; Set S  $011B
         ADC #-27
         TCD        ; Set DP $0100
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #186
         TCS        ; Set S  $01BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $025B
         ADC #-91
         TCD        ; Set DP $0200
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #250
         TCS        ; Set S  $02FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $039B
         ADC #-155
         TCD        ; Set DP $0300
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #314
         TCS        ; Set S  $043B
         ADC #-59
         TCD        ; Set DP $0400
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #218
         TCS        ; Set S  $04DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         JMP BRET   ;641 cycles
blit208_48 ANOP
         TCD        ; Set DP $0000
         ADC #127
         TCS        ; Set S  $007F
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #160
         TCS        ; Set S  $011F
         ADC #-31
         TCD        ; Set DP $0100
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #190
         TCS        ; Set S  $01BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $025F
         ADC #-95
         TCD        ; Set DP $0200
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #254
         TCS        ; Set S  $02FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $039F
         ADC #-159
         TCD        ; Set DP $0300
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #318
         TCS        ; Set S  $043F
         ADC #-63
         TCD        ; Set DP $0400
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #222
         TCS        ; Set S  $04DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         JMP BRET   ;641 cycles
blit216_48 ANOP
         TCD        ; Set DP $0000
         ADC #131
         TCS        ; Set S  $0083
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #160
         TCS        ; Set S  $0123
         ADC #-35
         TCD        ; Set DP $0100
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #194
         TCS        ; Set S  $01C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $0263
         ADC #-99
         TCD        ; Set DP $0200
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #258
         TCS        ; Set S  $0303
         ADC #-3
         TCD        ; Set DP $0300
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #418
         TCS        ; Set S  $03A3
         ADC #-163
         TCD        ; Set DP $0300
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #322
         TCS        ; Set S  $0443
         ADC #-67
         TCD        ; Set DP $0400
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #226
         TCS        ; Set S  $04E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         JMP BRET   ;651 cycles
blit224_48 ANOP
         TCD        ; Set DP $0000
         ADC #135
         TCS        ; Set S  $0087
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #160
         TCS        ; Set S  $0127
         ADC #-39
         TCD        ; Set DP $0100
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #198
         TCS        ; Set S  $01C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $0267
         ADC #-103
         TCD        ; Set DP $0200
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #262
         TCS        ; Set S  $0307
         ADC #-7
         TCD        ; Set DP $0300
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #422
         TCS        ; Set S  $03A7
         ADC #-167
         TCD        ; Set DP $0300
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #326
         TCS        ; Set S  $0447
         ADC #-71
         TCD        ; Set DP $0400
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #230
         TCS        ; Set S  $04E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         JMP BRET   ;651 cycles
blit232_48 ANOP
         TCD        ; Set DP $0000
         ADC #139
         TCS        ; Set S  $008B
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         ADC #160
         TCS        ; Set S  $012B
         ADC #-43
         TCD        ; Set DP $0100
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #202
         TCS        ; Set S  $01CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $026B
         ADC #-107
         TCD        ; Set DP $0200
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #266
         TCS        ; Set S  $030B
         ADC #-11
         TCD        ; Set DP $0300
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #426
         TCS        ; Set S  $03AB
         ADC #-171
         TCD        ; Set DP $0300
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         ADC #330
         TCS        ; Set S  $044B
         ADC #-75
         TCD        ; Set DP $0400
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #234
         TCS        ; Set S  $04EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         JMP BRET   ;651 cycles
blit240_48 ANOP
         TCD        ; Set DP $0000
         ADC #143
         TCS        ; Set S  $008F
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         ADC #160
         TCS        ; Set S  $012F
         ADC #-47
         TCD        ; Set DP $0100
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #206
         TCS        ; Set S  $01CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $026F
         ADC #-111
         TCD        ; Set DP $0200
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #270
         TCS        ; Set S  $030F
         ADC #-15
         TCD        ; Set DP $0300
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #430
         TCS        ; Set S  $03AF
         ADC #-175
         TCD        ; Set DP $0300
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         ADC #334
         TCS        ; Set S  $044F
         ADC #-79
         TCD        ; Set DP $0400
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #238
         TCS        ; Set S  $04EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         JMP BRET   ;651 cycles
blit248_48 ANOP
         TCD        ; Set DP $0000
         ADC #147
         TCS        ; Set S  $0093
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         ADC #160
         TCS        ; Set S  $0133
         ADC #-51
         TCD        ; Set DP $0100
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #210
         TCS        ; Set S  $01D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $0273
         ADC #-115
         TCD        ; Set DP $0200
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #274
         TCS        ; Set S  $0313
         ADC #-19
         TCD        ; Set DP $0300
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         ADC #434
         TCS        ; Set S  $03B3
         ADC #-179
         TCD        ; Set DP $0300
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         ADC #338
         TCS        ; Set S  $0453
         ADC #-83
         TCD        ; Set DP $0400
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #242
         TCS        ; Set S  $04F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         JMP BRET   ;651 cycles
blit256_48 ANOP
         TCD        ; Set DP $0000
         ADC #151
         TCS        ; Set S  $0097
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #160
         TCS        ; Set S  $0137
         ADC #-55
         TCD        ; Set DP $0100
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #214
         TCS        ; Set S  $01D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $0277
         ADC #-119
         TCD        ; Set DP $0200
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #278
         TCS        ; Set S  $0317
         ADC #-23
         TCD        ; Set DP $0300
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #182
         TCS        ; Set S  $03B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $0457
         ADC #-87
         TCD        ; Set DP $0400
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #246
         TCS        ; Set S  $04F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         JMP BRET   ;641 cycles
blit264_48 ANOP
         TCD        ; Set DP $0000
         ADC #155
         TCS        ; Set S  $009B
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #160
         TCS        ; Set S  $013B
         ADC #-59
         TCD        ; Set DP $0100
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #218
         TCS        ; Set S  $01DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $027B
         ADC #-123
         TCD        ; Set DP $0200
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #282
         TCS        ; Set S  $031B
         ADC #-27
         TCD        ; Set DP $0300
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #186
         TCS        ; Set S  $03BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $045B
         ADC #-91
         TCD        ; Set DP $0400
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #250
         TCS        ; Set S  $04FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         JMP BRET   ;641 cycles
blit272_48 ANOP
         TCD        ; Set DP $0000
         ADC #159
         TCS        ; Set S  $009F
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #160
         TCS        ; Set S  $013F
         ADC #-63
         TCD        ; Set DP $0100
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #222
         TCS        ; Set S  $01DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $027F
         ADC #-127
         TCD        ; Set DP $0200
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #286
         TCS        ; Set S  $031F
         ADC #-31
         TCD        ; Set DP $0300
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #190
         TCS        ; Set S  $03BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $045F
         ADC #-95
         TCD        ; Set DP $0400
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #254
         TCS        ; Set S  $04FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         JMP BRET   ;641 cycles
blit0_40 ANOP
         TCD        ; Set DP $0000
         ADC #19
         TCS        ; Set S  $0013
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #160
         TCS        ; Set S  $00B3
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $0153
         ADC #-83
         TCD        ; Set DP $0100
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #242
         TCS        ; Set S  $01F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $0293
         ADC #-147
         TCD        ; Set DP $0200
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #306
         TCS        ; Set S  $0333
         ADC #-51
         TCD        ; Set DP $0300
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #210
         TCS        ; Set S  $03D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $0473
         ADC #-115
         TCD        ; Set DP $0400
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         JMP BRET   ;545 cycles
blit8_40 ANOP
         TCD        ; Set DP $0000
         ADC #23
         TCS        ; Set S  $0017
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #160
         TCS        ; Set S  $00B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $0157
         ADC #-87
         TCD        ; Set DP $0100
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #246
         TCS        ; Set S  $01F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $0297
         ADC #-151
         TCD        ; Set DP $0200
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #310
         TCS        ; Set S  $0337
         ADC #-55
         TCD        ; Set DP $0300
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #214
         TCS        ; Set S  $03D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $0477
         ADC #-119
         TCD        ; Set DP $0400
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         JMP BRET   ;545 cycles
blit16_40 ANOP
         TCD        ; Set DP $0000
         ADC #27
         TCS        ; Set S  $001B
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #160
         TCS        ; Set S  $00BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $015B
         ADC #-91
         TCD        ; Set DP $0100
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #250
         TCS        ; Set S  $01FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $029B
         ADC #-155
         TCD        ; Set DP $0200
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #314
         TCS        ; Set S  $033B
         ADC #-59
         TCD        ; Set DP $0300
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #218
         TCS        ; Set S  $03DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $047B
         ADC #-123
         TCD        ; Set DP $0400
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         JMP BRET   ;545 cycles
blit24_40 ANOP
         TCD        ; Set DP $0000
         ADC #31
         TCS        ; Set S  $001F
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #160
         TCS        ; Set S  $00BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $015F
         ADC #-95
         TCD        ; Set DP $0100
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #254
         TCS        ; Set S  $01FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #160
         TCS        ; Set S  $029F
         ADC #-159
         TCD        ; Set DP $0200
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #318
         TCS        ; Set S  $033F
         ADC #-63
         TCD        ; Set DP $0300
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #222
         TCS        ; Set S  $03DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $047F
         ADC #-127
         TCD        ; Set DP $0400
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         JMP BRET   ;545 cycles
blit32_40 ANOP
         TCD        ; Set DP $0000
         ADC #35
         TCS        ; Set S  $0023
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #160
         TCS        ; Set S  $00C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $0163
         ADC #-99
         TCD        ; Set DP $0100
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #258
         TCS        ; Set S  $0203
         ADC #-3
         TCD        ; Set DP $0200
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #418
         TCS        ; Set S  $02A3
         ADC #-163
         TCD        ; Set DP $0200
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #322
         TCS        ; Set S  $0343
         ADC #-67
         TCD        ; Set DP $0300
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #226
         TCS        ; Set S  $03E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $0483
         ADC #-131
         TCD        ; Set DP $0400
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         JMP BRET   ;555 cycles
blit40_40 ANOP
         TCD        ; Set DP $0000
         ADC #39
         TCS        ; Set S  $0027
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #160
         TCS        ; Set S  $00C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $0167
         ADC #-103
         TCD        ; Set DP $0100
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #262
         TCS        ; Set S  $0207
         ADC #-7
         TCD        ; Set DP $0200
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #422
         TCS        ; Set S  $02A7
         ADC #-167
         TCD        ; Set DP $0200
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         ADC #326
         TCS        ; Set S  $0347
         ADC #-71
         TCD        ; Set DP $0300
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #230
         TCS        ; Set S  $03E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $0487
         ADC #-135
         TCD        ; Set DP $0400
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         JMP BRET   ;555 cycles
blit48_40 ANOP
         TCD        ; Set DP $0000
         ADC #43
         TCS        ; Set S  $002B
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #160
         TCS        ; Set S  $00CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $016B
         ADC #-107
         TCD        ; Set DP $0100
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #266
         TCS        ; Set S  $020B
         ADC #-11
         TCD        ; Set DP $0200
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #426
         TCS        ; Set S  $02AB
         ADC #-171
         TCD        ; Set DP $0200
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         ADC #330
         TCS        ; Set S  $034B
         ADC #-75
         TCD        ; Set DP $0300
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #234
         TCS        ; Set S  $03EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $048B
         ADC #-139
         TCD        ; Set DP $0400
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         JMP BRET   ;555 cycles
blit56_40 ANOP
         TCD        ; Set DP $0000
         ADC #47
         TCS        ; Set S  $002F
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #160
         TCS        ; Set S  $00CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $016F
         ADC #-111
         TCD        ; Set DP $0100
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #270
         TCS        ; Set S  $020F
         ADC #-15
         TCD        ; Set DP $0200
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         ADC #430
         TCS        ; Set S  $02AF
         ADC #-175
         TCD        ; Set DP $0200
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         ADC #334
         TCS        ; Set S  $034F
         ADC #-79
         TCD        ; Set DP $0300
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #238
         TCS        ; Set S  $03EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $048F
         ADC #-143
         TCD        ; Set DP $0400
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         JMP BRET   ;555 cycles
blit64_40 ANOP
         TCD        ; Set DP $0000
         ADC #51
         TCS        ; Set S  $0033
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #160
         TCS        ; Set S  $00D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $0173
         ADC #-115
         TCD        ; Set DP $0100
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #274
         TCS        ; Set S  $0213
         ADC #-19
         TCD        ; Set DP $0200
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #178
         TCS        ; Set S  $02B3
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $0353
         ADC #-83
         TCD        ; Set DP $0300
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #242
         TCS        ; Set S  $03F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $0493
         ADC #-147
         TCD        ; Set DP $0400
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         JMP BRET   ;545 cycles
blit72_40 ANOP
         TCD        ; Set DP $0000
         ADC #55
         TCS        ; Set S  $0037
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #160
         TCS        ; Set S  $00D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $0177
         ADC #-119
         TCD        ; Set DP $0100
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #278
         TCS        ; Set S  $0217
         ADC #-23
         TCD        ; Set DP $0200
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #182
         TCS        ; Set S  $02B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $0357
         ADC #-87
         TCD        ; Set DP $0300
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #246
         TCS        ; Set S  $03F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $0497
         ADC #-151
         TCD        ; Set DP $0400
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         JMP BRET   ;545 cycles
blit80_40 ANOP
         TCD        ; Set DP $0000
         ADC #59
         TCS        ; Set S  $003B
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #160
         TCS        ; Set S  $00DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $017B
         ADC #-123
         TCD        ; Set DP $0100
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #282
         TCS        ; Set S  $021B
         ADC #-27
         TCD        ; Set DP $0200
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #186
         TCS        ; Set S  $02BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $035B
         ADC #-91
         TCD        ; Set DP $0300
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #250
         TCS        ; Set S  $03FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $049B
         ADC #-155
         TCD        ; Set DP $0400
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         JMP BRET   ;545 cycles
blit88_40 ANOP
         TCD        ; Set DP $0000
         ADC #63
         TCS        ; Set S  $003F
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #160
         TCS        ; Set S  $00DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $017F
         ADC #-127
         TCD        ; Set DP $0100
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #286
         TCS        ; Set S  $021F
         ADC #-31
         TCD        ; Set DP $0200
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #190
         TCS        ; Set S  $02BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $035F
         ADC #-95
         TCD        ; Set DP $0300
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #254
         TCS        ; Set S  $03FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #160
         TCS        ; Set S  $049F
         ADC #-159
         TCD        ; Set DP $0400
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         JMP BRET   ;545 cycles
blit96_40 ANOP
         TCD        ; Set DP $0000
         ADC #67
         TCS        ; Set S  $0043
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #160
         TCS        ; Set S  $00E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $0183
         ADC #-131
         TCD        ; Set DP $0100
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #290
         TCS        ; Set S  $0223
         ADC #-35
         TCD        ; Set DP $0200
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #194
         TCS        ; Set S  $02C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $0363
         ADC #-99
         TCD        ; Set DP $0300
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #258
         TCS        ; Set S  $0403
         ADC #-3
         TCD        ; Set DP $0400
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #418
         TCS        ; Set S  $04A3
         ADC #-163
         TCD        ; Set DP $0400
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         JMP BRET   ;555 cycles
blit104_40 ANOP
         TCD        ; Set DP $0000
         ADC #71
         TCS        ; Set S  $0047
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #160
         TCS        ; Set S  $00E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $0187
         ADC #-135
         TCD        ; Set DP $0100
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         ADC #294
         TCS        ; Set S  $0227
         ADC #-39
         TCD        ; Set DP $0200
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #198
         TCS        ; Set S  $02C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $0367
         ADC #-103
         TCD        ; Set DP $0300
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #262
         TCS        ; Set S  $0407
         ADC #-7
         TCD        ; Set DP $0400
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #422
         TCS        ; Set S  $04A7
         ADC #-167
         TCD        ; Set DP $0400
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         JMP BRET   ;555 cycles
blit112_40 ANOP
         TCD        ; Set DP $0000
         ADC #75
         TCS        ; Set S  $004B
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #160
         TCS        ; Set S  $00EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $018B
         ADC #-139
         TCD        ; Set DP $0100
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         ADC #298
         TCS        ; Set S  $022B
         ADC #-43
         TCD        ; Set DP $0200
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #202
         TCS        ; Set S  $02CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $036B
         ADC #-107
         TCD        ; Set DP $0300
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #266
         TCS        ; Set S  $040B
         ADC #-11
         TCD        ; Set DP $0400
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #426
         TCS        ; Set S  $04AB
         ADC #-171
         TCD        ; Set DP $0400
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         JMP BRET   ;555 cycles
blit120_40 ANOP
         TCD        ; Set DP $0000
         ADC #79
         TCS        ; Set S  $004F
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #160
         TCS        ; Set S  $00EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $018F
         ADC #-143
         TCD        ; Set DP $0100
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         ADC #302
         TCS        ; Set S  $022F
         ADC #-47
         TCD        ; Set DP $0200
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #206
         TCS        ; Set S  $02CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $036F
         ADC #-111
         TCD        ; Set DP $0300
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #270
         TCS        ; Set S  $040F
         ADC #-15
         TCD        ; Set DP $0400
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         ADC #430
         TCS        ; Set S  $04AF
         ADC #-175
         TCD        ; Set DP $0400
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         JMP BRET   ;555 cycles
blit128_40 ANOP
         TCD        ; Set DP $0000
         ADC #83
         TCS        ; Set S  $0053
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #160
         TCS        ; Set S  $00F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $0193
         ADC #-147
         TCD        ; Set DP $0100
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #306
         TCS        ; Set S  $0233
         ADC #-51
         TCD        ; Set DP $0200
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #210
         TCS        ; Set S  $02D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $0373
         ADC #-115
         TCD        ; Set DP $0300
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #274
         TCS        ; Set S  $0413
         ADC #-19
         TCD        ; Set DP $0400
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #178
         TCS        ; Set S  $04B3
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         JMP BRET   ;545 cycles
blit136_40 ANOP
         TCD        ; Set DP $0000
         ADC #87
         TCS        ; Set S  $0057
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #160
         TCS        ; Set S  $00F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $0197
         ADC #-151
         TCD        ; Set DP $0100
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #310
         TCS        ; Set S  $0237
         ADC #-55
         TCD        ; Set DP $0200
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #214
         TCS        ; Set S  $02D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $0377
         ADC #-119
         TCD        ; Set DP $0300
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #278
         TCS        ; Set S  $0417
         ADC #-23
         TCD        ; Set DP $0400
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #182
         TCS        ; Set S  $04B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         JMP BRET   ;545 cycles
blit144_40 ANOP
         TCD        ; Set DP $0000
         ADC #91
         TCS        ; Set S  $005B
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #160
         TCS        ; Set S  $00FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $019B
         ADC #-155
         TCD        ; Set DP $0100
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #314
         TCS        ; Set S  $023B
         ADC #-59
         TCD        ; Set DP $0200
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #218
         TCS        ; Set S  $02DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $037B
         ADC #-123
         TCD        ; Set DP $0300
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #282
         TCS        ; Set S  $041B
         ADC #-27
         TCD        ; Set DP $0400
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #186
         TCS        ; Set S  $04BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         JMP BRET   ;545 cycles
blit152_40 ANOP
         TCD        ; Set DP $0000
         ADC #95
         TCS        ; Set S  $005F
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #160
         TCS        ; Set S  $00FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #160
         TCS        ; Set S  $019F
         ADC #-159
         TCD        ; Set DP $0100
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #318
         TCS        ; Set S  $023F
         ADC #-63
         TCD        ; Set DP $0200
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #222
         TCS        ; Set S  $02DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $037F
         ADC #-127
         TCD        ; Set DP $0300
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #286
         TCS        ; Set S  $041F
         ADC #-31
         TCD        ; Set DP $0400
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #190
         TCS        ; Set S  $04BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         JMP BRET   ;545 cycles
blit160_40 ANOP
         TCD        ; Set DP $0000
         ADC #99
         TCS        ; Set S  $0063
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #160
         TCS        ; Set S  $0103
         ADC #-3
         TCD        ; Set DP $0100
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #418
         TCS        ; Set S  $01A3
         ADC #-163
         TCD        ; Set DP $0100
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #322
         TCS        ; Set S  $0243
         ADC #-67
         TCD        ; Set DP $0200
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #226
         TCS        ; Set S  $02E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $0383
         ADC #-131
         TCD        ; Set DP $0300
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #290
         TCS        ; Set S  $0423
         ADC #-35
         TCD        ; Set DP $0400
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #194
         TCS        ; Set S  $04C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         JMP BRET   ;555 cycles
blit168_40 ANOP
         TCD        ; Set DP $0000
         ADC #103
         TCS        ; Set S  $0067
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #160
         TCS        ; Set S  $0107
         ADC #-7
         TCD        ; Set DP $0100
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #422
         TCS        ; Set S  $01A7
         ADC #-167
         TCD        ; Set DP $0100
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         ADC #326
         TCS        ; Set S  $0247
         ADC #-71
         TCD        ; Set DP $0200
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #230
         TCS        ; Set S  $02E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $0387
         ADC #-135
         TCD        ; Set DP $0300
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         ADC #294
         TCS        ; Set S  $0427
         ADC #-39
         TCD        ; Set DP $0400
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #198
         TCS        ; Set S  $04C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         JMP BRET   ;555 cycles
blit176_40 ANOP
         TCD        ; Set DP $0000
         ADC #107
         TCS        ; Set S  $006B
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #160
         TCS        ; Set S  $010B
         ADC #-11
         TCD        ; Set DP $0100
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #426
         TCS        ; Set S  $01AB
         ADC #-171
         TCD        ; Set DP $0100
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         ADC #330
         TCS        ; Set S  $024B
         ADC #-75
         TCD        ; Set DP $0200
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #234
         TCS        ; Set S  $02EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $038B
         ADC #-139
         TCD        ; Set DP $0300
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         ADC #298
         TCS        ; Set S  $042B
         ADC #-43
         TCD        ; Set DP $0400
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #202
         TCS        ; Set S  $04CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         JMP BRET   ;555 cycles
blit184_40 ANOP
         TCD        ; Set DP $0000
         ADC #111
         TCS        ; Set S  $006F
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #160
         TCS        ; Set S  $010F
         ADC #-15
         TCD        ; Set DP $0100
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         ADC #430
         TCS        ; Set S  $01AF
         ADC #-175
         TCD        ; Set DP $0100
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         ADC #334
         TCS        ; Set S  $024F
         ADC #-79
         TCD        ; Set DP $0200
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #238
         TCS        ; Set S  $02EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $038F
         ADC #-143
         TCD        ; Set DP $0300
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         ADC #302
         TCS        ; Set S  $042F
         ADC #-47
         TCD        ; Set DP $0400
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #206
         TCS        ; Set S  $04CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         JMP BRET   ;555 cycles
blit192_40 ANOP
         TCD        ; Set DP $0000
         ADC #115
         TCS        ; Set S  $0073
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #160
         TCS        ; Set S  $0113
         ADC #-19
         TCD        ; Set DP $0100
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #178
         TCS        ; Set S  $01B3
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $0253
         ADC #-83
         TCD        ; Set DP $0200
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #242
         TCS        ; Set S  $02F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $0393
         ADC #-147
         TCD        ; Set DP $0300
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #306
         TCS        ; Set S  $0433
         ADC #-51
         TCD        ; Set DP $0400
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #210
         TCS        ; Set S  $04D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         JMP BRET   ;545 cycles
blit200_40 ANOP
         TCD        ; Set DP $0000
         ADC #119
         TCS        ; Set S  $0077
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #160
         TCS        ; Set S  $0117
         ADC #-23
         TCD        ; Set DP $0100
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #182
         TCS        ; Set S  $01B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $0257
         ADC #-87
         TCD        ; Set DP $0200
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #246
         TCS        ; Set S  $02F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $0397
         ADC #-151
         TCD        ; Set DP $0300
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #310
         TCS        ; Set S  $0437
         ADC #-55
         TCD        ; Set DP $0400
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #214
         TCS        ; Set S  $04D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         JMP BRET   ;545 cycles
blit208_40 ANOP
         TCD        ; Set DP $0000
         ADC #123
         TCS        ; Set S  $007B
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #160
         TCS        ; Set S  $011B
         ADC #-27
         TCD        ; Set DP $0100
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #186
         TCS        ; Set S  $01BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $025B
         ADC #-91
         TCD        ; Set DP $0200
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #250
         TCS        ; Set S  $02FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $039B
         ADC #-155
         TCD        ; Set DP $0300
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #314
         TCS        ; Set S  $043B
         ADC #-59
         TCD        ; Set DP $0400
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #218
         TCS        ; Set S  $04DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         JMP BRET   ;545 cycles
blit216_40 ANOP
         TCD        ; Set DP $0000
         ADC #127
         TCS        ; Set S  $007F
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #160
         TCS        ; Set S  $011F
         ADC #-31
         TCD        ; Set DP $0100
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #190
         TCS        ; Set S  $01BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $025F
         ADC #-95
         TCD        ; Set DP $0200
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #254
         TCS        ; Set S  $02FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #160
         TCS        ; Set S  $039F
         ADC #-159
         TCD        ; Set DP $0300
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #318
         TCS        ; Set S  $043F
         ADC #-63
         TCD        ; Set DP $0400
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #222
         TCS        ; Set S  $04DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         JMP BRET   ;545 cycles
blit224_40 ANOP
         TCD        ; Set DP $0000
         ADC #131
         TCS        ; Set S  $0083
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #160
         TCS        ; Set S  $0123
         ADC #-35
         TCD        ; Set DP $0100
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #194
         TCS        ; Set S  $01C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $0263
         ADC #-99
         TCD        ; Set DP $0200
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #258
         TCS        ; Set S  $0303
         ADC #-3
         TCD        ; Set DP $0300
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #418
         TCS        ; Set S  $03A3
         ADC #-163
         TCD        ; Set DP $0300
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #322
         TCS        ; Set S  $0443
         ADC #-67
         TCD        ; Set DP $0400
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #226
         TCS        ; Set S  $04E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         JMP BRET   ;555 cycles
blit232_40 ANOP
         TCD        ; Set DP $0000
         ADC #135
         TCS        ; Set S  $0087
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         ADC #160
         TCS        ; Set S  $0127
         ADC #-39
         TCD        ; Set DP $0100
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #198
         TCS        ; Set S  $01C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $0267
         ADC #-103
         TCD        ; Set DP $0200
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #262
         TCS        ; Set S  $0307
         ADC #-7
         TCD        ; Set DP $0300
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #422
         TCS        ; Set S  $03A7
         ADC #-167
         TCD        ; Set DP $0300
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         ADC #326
         TCS        ; Set S  $0447
         ADC #-71
         TCD        ; Set DP $0400
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #230
         TCS        ; Set S  $04E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         JMP BRET   ;555 cycles
blit240_40 ANOP
         TCD        ; Set DP $0000
         ADC #139
         TCS        ; Set S  $008B
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         ADC #160
         TCS        ; Set S  $012B
         ADC #-43
         TCD        ; Set DP $0100
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #202
         TCS        ; Set S  $01CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $026B
         ADC #-107
         TCD        ; Set DP $0200
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #266
         TCS        ; Set S  $030B
         ADC #-11
         TCD        ; Set DP $0300
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #426
         TCS        ; Set S  $03AB
         ADC #-171
         TCD        ; Set DP $0300
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         ADC #330
         TCS        ; Set S  $044B
         ADC #-75
         TCD        ; Set DP $0400
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #234
         TCS        ; Set S  $04EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         JMP BRET   ;555 cycles
blit248_40 ANOP
         TCD        ; Set DP $0000
         ADC #143
         TCS        ; Set S  $008F
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         ADC #160
         TCS        ; Set S  $012F
         ADC #-47
         TCD        ; Set DP $0100
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #206
         TCS        ; Set S  $01CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $026F
         ADC #-111
         TCD        ; Set DP $0200
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #270
         TCS        ; Set S  $030F
         ADC #-15
         TCD        ; Set DP $0300
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         ADC #430
         TCS        ; Set S  $03AF
         ADC #-175
         TCD        ; Set DP $0300
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         ADC #334
         TCS        ; Set S  $044F
         ADC #-79
         TCD        ; Set DP $0400
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #238
         TCS        ; Set S  $04EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         JMP BRET   ;555 cycles
blit256_40 ANOP
         TCD        ; Set DP $0000
         ADC #147
         TCS        ; Set S  $0093
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #160
         TCS        ; Set S  $0133
         ADC #-51
         TCD        ; Set DP $0100
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #210
         TCS        ; Set S  $01D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $0273
         ADC #-115
         TCD        ; Set DP $0200
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #274
         TCS        ; Set S  $0313
         ADC #-19
         TCD        ; Set DP $0300
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #178
         TCS        ; Set S  $03B3
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $0453
         ADC #-83
         TCD        ; Set DP $0400
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #242
         TCS        ; Set S  $04F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         JMP BRET   ;545 cycles
blit264_40 ANOP
         TCD        ; Set DP $0000
         ADC #151
         TCS        ; Set S  $0097
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #160
         TCS        ; Set S  $0137
         ADC #-55
         TCD        ; Set DP $0100
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #214
         TCS        ; Set S  $01D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $0277
         ADC #-119
         TCD        ; Set DP $0200
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #278
         TCS        ; Set S  $0317
         ADC #-23
         TCD        ; Set DP $0300
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #182
         TCS        ; Set S  $03B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $0457
         ADC #-87
         TCD        ; Set DP $0400
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #246
         TCS        ; Set S  $04F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         JMP BRET   ;545 cycles
blit272_40 ANOP
         TCD        ; Set DP $0000
         ADC #155
         TCS        ; Set S  $009B
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #160
         TCS        ; Set S  $013B
         ADC #-59
         TCD        ; Set DP $0100
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #218
         TCS        ; Set S  $01DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $027B
         ADC #-123
         TCD        ; Set DP $0200
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #282
         TCS        ; Set S  $031B
         ADC #-27
         TCD        ; Set DP $0300
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #186
         TCS        ; Set S  $03BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $045B
         ADC #-91
         TCD        ; Set DP $0400
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #250
         TCS        ; Set S  $04FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         JMP BRET   ;545 cycles
blit280_40 ANOP
         TCD        ; Set DP $0000
         ADC #159
         TCS        ; Set S  $009F
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #160
         TCS        ; Set S  $013F
         ADC #-63
         TCD        ; Set DP $0100
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #222
         TCS        ; Set S  $01DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $027F
         ADC #-127
         TCD        ; Set DP $0200
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #286
         TCS        ; Set S  $031F
         ADC #-31
         TCD        ; Set DP $0300
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #190
         TCS        ; Set S  $03BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $045F
         ADC #-95
         TCD        ; Set DP $0400
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #254
         TCS        ; Set S  $04FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         JMP BRET   ;545 cycles
blit0_32 ANOP
         TCD        ; Set DP $0000
         ADC #15
         TCS        ; Set S  $000F
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #160
         TCS        ; Set S  $00AF
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $014F
         ADC #-79
         TCD        ; Set DP $0100
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #238
         TCS        ; Set S  $01EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $028F
         ADC #-143
         TCD        ; Set DP $0200
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #302
         TCS        ; Set S  $032F
         ADC #-47
         TCD        ; Set DP $0300
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #206
         TCS        ; Set S  $03CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $046F
         ADC #-111
         TCD        ; Set DP $0400
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         JMP BRET   ;449 cycles
blit8_32 ANOP
         TCD        ; Set DP $0000
         ADC #19
         TCS        ; Set S  $0013
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #160
         TCS        ; Set S  $00B3
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $0153
         ADC #-83
         TCD        ; Set DP $0100
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #242
         TCS        ; Set S  $01F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $0293
         ADC #-147
         TCD        ; Set DP $0200
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #306
         TCS        ; Set S  $0333
         ADC #-51
         TCD        ; Set DP $0300
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #210
         TCS        ; Set S  $03D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $0473
         ADC #-115
         TCD        ; Set DP $0400
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         JMP BRET   ;449 cycles
blit16_32 ANOP
         TCD        ; Set DP $0000
         ADC #23
         TCS        ; Set S  $0017
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #160
         TCS        ; Set S  $00B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $0157
         ADC #-87
         TCD        ; Set DP $0100
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #246
         TCS        ; Set S  $01F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $0297
         ADC #-151
         TCD        ; Set DP $0200
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #310
         TCS        ; Set S  $0337
         ADC #-55
         TCD        ; Set DP $0300
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #214
         TCS        ; Set S  $03D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $0477
         ADC #-119
         TCD        ; Set DP $0400
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         JMP BRET   ;449 cycles
blit24_32 ANOP
         TCD        ; Set DP $0000
         ADC #27
         TCS        ; Set S  $001B
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #160
         TCS        ; Set S  $00BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $015B
         ADC #-91
         TCD        ; Set DP $0100
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #250
         TCS        ; Set S  $01FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #160
         TCS        ; Set S  $029B
         ADC #-155
         TCD        ; Set DP $0200
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #314
         TCS        ; Set S  $033B
         ADC #-59
         TCD        ; Set DP $0300
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #218
         TCS        ; Set S  $03DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $047B
         ADC #-123
         TCD        ; Set DP $0400
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         JMP BRET   ;449 cycles
blit32_32 ANOP
         TCD        ; Set DP $0000
         ADC #31
         TCS        ; Set S  $001F
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #160
         TCS        ; Set S  $00BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $015F
         ADC #-95
         TCD        ; Set DP $0100
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #254
         TCS        ; Set S  $01FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #160
         TCS        ; Set S  $029F
         ADC #-159
         TCD        ; Set DP $0200
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #318
         TCS        ; Set S  $033F
         ADC #-63
         TCD        ; Set DP $0300
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #222
         TCS        ; Set S  $03DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $047F
         ADC #-127
         TCD        ; Set DP $0400
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         JMP BRET   ;449 cycles
blit40_32 ANOP
         TCD        ; Set DP $0000
         ADC #35
         TCS        ; Set S  $0023
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #160
         TCS        ; Set S  $00C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $0163
         ADC #-99
         TCD        ; Set DP $0100
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #258
         TCS        ; Set S  $0203
         ADC #-3
         TCD        ; Set DP $0200
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #418
         TCS        ; Set S  $02A3
         ADC #-163
         TCD        ; Set DP $0200
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         ADC #322
         TCS        ; Set S  $0343
         ADC #-67
         TCD        ; Set DP $0300
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #226
         TCS        ; Set S  $03E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $0483
         ADC #-131
         TCD        ; Set DP $0400
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         JMP BRET   ;459 cycles
blit48_32 ANOP
         TCD        ; Set DP $0000
         ADC #39
         TCS        ; Set S  $0027
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #160
         TCS        ; Set S  $00C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $0167
         ADC #-103
         TCD        ; Set DP $0100
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #262
         TCS        ; Set S  $0207
         ADC #-7
         TCD        ; Set DP $0200
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #422
         TCS        ; Set S  $02A7
         ADC #-167
         TCD        ; Set DP $0200
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         ADC #326
         TCS        ; Set S  $0347
         ADC #-71
         TCD        ; Set DP $0300
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #230
         TCS        ; Set S  $03E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $0487
         ADC #-135
         TCD        ; Set DP $0400
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         JMP BRET   ;459 cycles
blit56_32 ANOP
         TCD        ; Set DP $0000
         ADC #43
         TCS        ; Set S  $002B
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #160
         TCS        ; Set S  $00CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $016B
         ADC #-107
         TCD        ; Set DP $0100
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #266
         TCS        ; Set S  $020B
         ADC #-11
         TCD        ; Set DP $0200
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         ADC #426
         TCS        ; Set S  $02AB
         ADC #-171
         TCD        ; Set DP $0200
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         ADC #330
         TCS        ; Set S  $034B
         ADC #-75
         TCD        ; Set DP $0300
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #234
         TCS        ; Set S  $03EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $048B
         ADC #-139
         TCD        ; Set DP $0400
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         JMP BRET   ;459 cycles
blit64_32 ANOP
         TCD        ; Set DP $0000
         ADC #47
         TCS        ; Set S  $002F
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #160
         TCS        ; Set S  $00CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $016F
         ADC #-111
         TCD        ; Set DP $0100
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #270
         TCS        ; Set S  $020F
         ADC #-15
         TCD        ; Set DP $0200
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #174
         TCS        ; Set S  $02AF
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $034F
         ADC #-79
         TCD        ; Set DP $0300
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #238
         TCS        ; Set S  $03EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $048F
         ADC #-143
         TCD        ; Set DP $0400
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         JMP BRET   ;449 cycles
blit72_32 ANOP
         TCD        ; Set DP $0000
         ADC #51
         TCS        ; Set S  $0033
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #160
         TCS        ; Set S  $00D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $0173
         ADC #-115
         TCD        ; Set DP $0100
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #274
         TCS        ; Set S  $0213
         ADC #-19
         TCD        ; Set DP $0200
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #178
         TCS        ; Set S  $02B3
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $0353
         ADC #-83
         TCD        ; Set DP $0300
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #242
         TCS        ; Set S  $03F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $0493
         ADC #-147
         TCD        ; Set DP $0400
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         JMP BRET   ;449 cycles
blit80_32 ANOP
         TCD        ; Set DP $0000
         ADC #55
         TCS        ; Set S  $0037
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #160
         TCS        ; Set S  $00D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $0177
         ADC #-119
         TCD        ; Set DP $0100
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #278
         TCS        ; Set S  $0217
         ADC #-23
         TCD        ; Set DP $0200
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #182
         TCS        ; Set S  $02B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $0357
         ADC #-87
         TCD        ; Set DP $0300
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #246
         TCS        ; Set S  $03F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $0497
         ADC #-151
         TCD        ; Set DP $0400
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         JMP BRET   ;449 cycles
blit88_32 ANOP
         TCD        ; Set DP $0000
         ADC #59
         TCS        ; Set S  $003B
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #160
         TCS        ; Set S  $00DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $017B
         ADC #-123
         TCD        ; Set DP $0100
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #282
         TCS        ; Set S  $021B
         ADC #-27
         TCD        ; Set DP $0200
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #186
         TCS        ; Set S  $02BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $035B
         ADC #-91
         TCD        ; Set DP $0300
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #250
         TCS        ; Set S  $03FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #160
         TCS        ; Set S  $049B
         ADC #-155
         TCD        ; Set DP $0400
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         JMP BRET   ;449 cycles
blit96_32 ANOP
         TCD        ; Set DP $0000
         ADC #63
         TCS        ; Set S  $003F
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #160
         TCS        ; Set S  $00DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $017F
         ADC #-127
         TCD        ; Set DP $0100
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #286
         TCS        ; Set S  $021F
         ADC #-31
         TCD        ; Set DP $0200
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #190
         TCS        ; Set S  $02BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $035F
         ADC #-95
         TCD        ; Set DP $0300
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #254
         TCS        ; Set S  $03FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #160
         TCS        ; Set S  $049F
         ADC #-159
         TCD        ; Set DP $0400
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         JMP BRET   ;449 cycles
blit104_32 ANOP
         TCD        ; Set DP $0000
         ADC #67
         TCS        ; Set S  $0043
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #160
         TCS        ; Set S  $00E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $0183
         ADC #-131
         TCD        ; Set DP $0100
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         ADC #290
         TCS        ; Set S  $0223
         ADC #-35
         TCD        ; Set DP $0200
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #194
         TCS        ; Set S  $02C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $0363
         ADC #-99
         TCD        ; Set DP $0300
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #258
         TCS        ; Set S  $0403
         ADC #-3
         TCD        ; Set DP $0400
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #418
         TCS        ; Set S  $04A3
         ADC #-163
         TCD        ; Set DP $0400
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         JMP BRET   ;459 cycles
blit112_32 ANOP
         TCD        ; Set DP $0000
         ADC #71
         TCS        ; Set S  $0047
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #160
         TCS        ; Set S  $00E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $0187
         ADC #-135
         TCD        ; Set DP $0100
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         ADC #294
         TCS        ; Set S  $0227
         ADC #-39
         TCD        ; Set DP $0200
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #198
         TCS        ; Set S  $02C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $0367
         ADC #-103
         TCD        ; Set DP $0300
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #262
         TCS        ; Set S  $0407
         ADC #-7
         TCD        ; Set DP $0400
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #422
         TCS        ; Set S  $04A7
         ADC #-167
         TCD        ; Set DP $0400
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         JMP BRET   ;459 cycles
blit120_32 ANOP
         TCD        ; Set DP $0000
         ADC #75
         TCS        ; Set S  $004B
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #160
         TCS        ; Set S  $00EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $018B
         ADC #-139
         TCD        ; Set DP $0100
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         ADC #298
         TCS        ; Set S  $022B
         ADC #-43
         TCD        ; Set DP $0200
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #202
         TCS        ; Set S  $02CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $036B
         ADC #-107
         TCD        ; Set DP $0300
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #266
         TCS        ; Set S  $040B
         ADC #-11
         TCD        ; Set DP $0400
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         ADC #426
         TCS        ; Set S  $04AB
         ADC #-171
         TCD        ; Set DP $0400
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         JMP BRET   ;459 cycles
blit128_32 ANOP
         TCD        ; Set DP $0000
         ADC #79
         TCS        ; Set S  $004F
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #160
         TCS        ; Set S  $00EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $018F
         ADC #-143
         TCD        ; Set DP $0100
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #302
         TCS        ; Set S  $022F
         ADC #-47
         TCD        ; Set DP $0200
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #206
         TCS        ; Set S  $02CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $036F
         ADC #-111
         TCD        ; Set DP $0300
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #270
         TCS        ; Set S  $040F
         ADC #-15
         TCD        ; Set DP $0400
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #174
         TCS        ; Set S  $04AF
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         JMP BRET   ;449 cycles
blit136_32 ANOP
         TCD        ; Set DP $0000
         ADC #83
         TCS        ; Set S  $0053
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #160
         TCS        ; Set S  $00F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $0193
         ADC #-147
         TCD        ; Set DP $0100
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #306
         TCS        ; Set S  $0233
         ADC #-51
         TCD        ; Set DP $0200
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #210
         TCS        ; Set S  $02D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $0373
         ADC #-115
         TCD        ; Set DP $0300
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #274
         TCS        ; Set S  $0413
         ADC #-19
         TCD        ; Set DP $0400
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #178
         TCS        ; Set S  $04B3
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         JMP BRET   ;449 cycles
blit144_32 ANOP
         TCD        ; Set DP $0000
         ADC #87
         TCS        ; Set S  $0057
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #160
         TCS        ; Set S  $00F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $0197
         ADC #-151
         TCD        ; Set DP $0100
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #310
         TCS        ; Set S  $0237
         ADC #-55
         TCD        ; Set DP $0200
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #214
         TCS        ; Set S  $02D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $0377
         ADC #-119
         TCD        ; Set DP $0300
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #278
         TCS        ; Set S  $0417
         ADC #-23
         TCD        ; Set DP $0400
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #182
         TCS        ; Set S  $04B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         JMP BRET   ;449 cycles
blit152_32 ANOP
         TCD        ; Set DP $0000
         ADC #91
         TCS        ; Set S  $005B
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #160
         TCS        ; Set S  $00FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #160
         TCS        ; Set S  $019B
         ADC #-155
         TCD        ; Set DP $0100
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #314
         TCS        ; Set S  $023B
         ADC #-59
         TCD        ; Set DP $0200
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #218
         TCS        ; Set S  $02DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $037B
         ADC #-123
         TCD        ; Set DP $0300
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #282
         TCS        ; Set S  $041B
         ADC #-27
         TCD        ; Set DP $0400
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #186
         TCS        ; Set S  $04BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         JMP BRET   ;449 cycles
blit160_32 ANOP
         TCD        ; Set DP $0000
         ADC #95
         TCS        ; Set S  $005F
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #160
         TCS        ; Set S  $00FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #160
         TCS        ; Set S  $019F
         ADC #-159
         TCD        ; Set DP $0100
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #318
         TCS        ; Set S  $023F
         ADC #-63
         TCD        ; Set DP $0200
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #222
         TCS        ; Set S  $02DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $037F
         ADC #-127
         TCD        ; Set DP $0300
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #286
         TCS        ; Set S  $041F
         ADC #-31
         TCD        ; Set DP $0400
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #190
         TCS        ; Set S  $04BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         JMP BRET   ;449 cycles
blit168_32 ANOP
         TCD        ; Set DP $0000
         ADC #99
         TCS        ; Set S  $0063
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #160
         TCS        ; Set S  $0103
         ADC #-3
         TCD        ; Set DP $0100
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #418
         TCS        ; Set S  $01A3
         ADC #-163
         TCD        ; Set DP $0100
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         ADC #322
         TCS        ; Set S  $0243
         ADC #-67
         TCD        ; Set DP $0200
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #226
         TCS        ; Set S  $02E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $0383
         ADC #-131
         TCD        ; Set DP $0300
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         ADC #290
         TCS        ; Set S  $0423
         ADC #-35
         TCD        ; Set DP $0400
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #194
         TCS        ; Set S  $04C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         JMP BRET   ;459 cycles
blit176_32 ANOP
         TCD        ; Set DP $0000
         ADC #103
         TCS        ; Set S  $0067
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #160
         TCS        ; Set S  $0107
         ADC #-7
         TCD        ; Set DP $0100
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #422
         TCS        ; Set S  $01A7
         ADC #-167
         TCD        ; Set DP $0100
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         ADC #326
         TCS        ; Set S  $0247
         ADC #-71
         TCD        ; Set DP $0200
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #230
         TCS        ; Set S  $02E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $0387
         ADC #-135
         TCD        ; Set DP $0300
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         ADC #294
         TCS        ; Set S  $0427
         ADC #-39
         TCD        ; Set DP $0400
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #198
         TCS        ; Set S  $04C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         JMP BRET   ;459 cycles
blit184_32 ANOP
         TCD        ; Set DP $0000
         ADC #107
         TCS        ; Set S  $006B
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #160
         TCS        ; Set S  $010B
         ADC #-11
         TCD        ; Set DP $0100
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         ADC #426
         TCS        ; Set S  $01AB
         ADC #-171
         TCD        ; Set DP $0100
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         ADC #330
         TCS        ; Set S  $024B
         ADC #-75
         TCD        ; Set DP $0200
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #234
         TCS        ; Set S  $02EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $038B
         ADC #-139
         TCD        ; Set DP $0300
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         ADC #298
         TCS        ; Set S  $042B
         ADC #-43
         TCD        ; Set DP $0400
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #202
         TCS        ; Set S  $04CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         JMP BRET   ;459 cycles
blit192_32 ANOP
         TCD        ; Set DP $0000
         ADC #111
         TCS        ; Set S  $006F
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #160
         TCS        ; Set S  $010F
         ADC #-15
         TCD        ; Set DP $0100
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #174
         TCS        ; Set S  $01AF
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $024F
         ADC #-79
         TCD        ; Set DP $0200
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #238
         TCS        ; Set S  $02EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $038F
         ADC #-143
         TCD        ; Set DP $0300
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #302
         TCS        ; Set S  $042F
         ADC #-47
         TCD        ; Set DP $0400
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #206
         TCS        ; Set S  $04CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         JMP BRET   ;449 cycles
blit200_32 ANOP
         TCD        ; Set DP $0000
         ADC #115
         TCS        ; Set S  $0073
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #160
         TCS        ; Set S  $0113
         ADC #-19
         TCD        ; Set DP $0100
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #178
         TCS        ; Set S  $01B3
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $0253
         ADC #-83
         TCD        ; Set DP $0200
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #242
         TCS        ; Set S  $02F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $0393
         ADC #-147
         TCD        ; Set DP $0300
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #306
         TCS        ; Set S  $0433
         ADC #-51
         TCD        ; Set DP $0400
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #210
         TCS        ; Set S  $04D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         JMP BRET   ;449 cycles
blit208_32 ANOP
         TCD        ; Set DP $0000
         ADC #119
         TCS        ; Set S  $0077
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #160
         TCS        ; Set S  $0117
         ADC #-23
         TCD        ; Set DP $0100
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #182
         TCS        ; Set S  $01B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $0257
         ADC #-87
         TCD        ; Set DP $0200
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #246
         TCS        ; Set S  $02F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $0397
         ADC #-151
         TCD        ; Set DP $0300
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #310
         TCS        ; Set S  $0437
         ADC #-55
         TCD        ; Set DP $0400
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #214
         TCS        ; Set S  $04D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         JMP BRET   ;449 cycles
blit216_32 ANOP
         TCD        ; Set DP $0000
         ADC #123
         TCS        ; Set S  $007B
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #160
         TCS        ; Set S  $011B
         ADC #-27
         TCD        ; Set DP $0100
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #186
         TCS        ; Set S  $01BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $025B
         ADC #-91
         TCD        ; Set DP $0200
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #250
         TCS        ; Set S  $02FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #160
         TCS        ; Set S  $039B
         ADC #-155
         TCD        ; Set DP $0300
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #314
         TCS        ; Set S  $043B
         ADC #-59
         TCD        ; Set DP $0400
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #218
         TCS        ; Set S  $04DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         JMP BRET   ;449 cycles
blit224_32 ANOP
         TCD        ; Set DP $0000
         ADC #127
         TCS        ; Set S  $007F
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #160
         TCS        ; Set S  $011F
         ADC #-31
         TCD        ; Set DP $0100
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #190
         TCS        ; Set S  $01BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $025F
         ADC #-95
         TCD        ; Set DP $0200
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #254
         TCS        ; Set S  $02FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #160
         TCS        ; Set S  $039F
         ADC #-159
         TCD        ; Set DP $0300
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #318
         TCS        ; Set S  $043F
         ADC #-63
         TCD        ; Set DP $0400
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #222
         TCS        ; Set S  $04DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         JMP BRET   ;449 cycles
blit232_32 ANOP
         TCD        ; Set DP $0000
         ADC #131
         TCS        ; Set S  $0083
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         ADC #160
         TCS        ; Set S  $0123
         ADC #-35
         TCD        ; Set DP $0100
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #194
         TCS        ; Set S  $01C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $0263
         ADC #-99
         TCD        ; Set DP $0200
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #258
         TCS        ; Set S  $0303
         ADC #-3
         TCD        ; Set DP $0300
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #418
         TCS        ; Set S  $03A3
         ADC #-163
         TCD        ; Set DP $0300
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         ADC #322
         TCS        ; Set S  $0443
         ADC #-67
         TCD        ; Set DP $0400
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #226
         TCS        ; Set S  $04E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         JMP BRET   ;459 cycles
blit240_32 ANOP
         TCD        ; Set DP $0000
         ADC #135
         TCS        ; Set S  $0087
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         ADC #160
         TCS        ; Set S  $0127
         ADC #-39
         TCD        ; Set DP $0100
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #198
         TCS        ; Set S  $01C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $0267
         ADC #-103
         TCD        ; Set DP $0200
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #262
         TCS        ; Set S  $0307
         ADC #-7
         TCD        ; Set DP $0300
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #422
         TCS        ; Set S  $03A7
         ADC #-167
         TCD        ; Set DP $0300
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         ADC #326
         TCS        ; Set S  $0447
         ADC #-71
         TCD        ; Set DP $0400
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #230
         TCS        ; Set S  $04E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         JMP BRET   ;459 cycles
blit248_32 ANOP
         TCD        ; Set DP $0000
         ADC #139
         TCS        ; Set S  $008B
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         ADC #160
         TCS        ; Set S  $012B
         ADC #-43
         TCD        ; Set DP $0100
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #202
         TCS        ; Set S  $01CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $026B
         ADC #-107
         TCD        ; Set DP $0200
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #266
         TCS        ; Set S  $030B
         ADC #-11
         TCD        ; Set DP $0300
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         ADC #426
         TCS        ; Set S  $03AB
         ADC #-171
         TCD        ; Set DP $0300
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         ADC #330
         TCS        ; Set S  $044B
         ADC #-75
         TCD        ; Set DP $0400
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #234
         TCS        ; Set S  $04EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         JMP BRET   ;459 cycles
blit256_32 ANOP
         TCD        ; Set DP $0000
         ADC #143
         TCS        ; Set S  $008F
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #160
         TCS        ; Set S  $012F
         ADC #-47
         TCD        ; Set DP $0100
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #206
         TCS        ; Set S  $01CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $026F
         ADC #-111
         TCD        ; Set DP $0200
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #270
         TCS        ; Set S  $030F
         ADC #-15
         TCD        ; Set DP $0300
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #174
         TCS        ; Set S  $03AF
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $044F
         ADC #-79
         TCD        ; Set DP $0400
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #238
         TCS        ; Set S  $04EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         JMP BRET   ;449 cycles
blit264_32 ANOP
         TCD        ; Set DP $0000
         ADC #147
         TCS        ; Set S  $0093
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #160
         TCS        ; Set S  $0133
         ADC #-51
         TCD        ; Set DP $0100
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #210
         TCS        ; Set S  $01D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $0273
         ADC #-115
         TCD        ; Set DP $0200
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #274
         TCS        ; Set S  $0313
         ADC #-19
         TCD        ; Set DP $0300
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #178
         TCS        ; Set S  $03B3
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $0453
         ADC #-83
         TCD        ; Set DP $0400
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #242
         TCS        ; Set S  $04F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         JMP BRET   ;449 cycles
blit272_32 ANOP
         TCD        ; Set DP $0000
         ADC #151
         TCS        ; Set S  $0097
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #160
         TCS        ; Set S  $0137
         ADC #-55
         TCD        ; Set DP $0100
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #214
         TCS        ; Set S  $01D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $0277
         ADC #-119
         TCD        ; Set DP $0200
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #278
         TCS        ; Set S  $0317
         ADC #-23
         TCD        ; Set DP $0300
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #182
         TCS        ; Set S  $03B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $0457
         ADC #-87
         TCD        ; Set DP $0400
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #246
         TCS        ; Set S  $04F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         JMP BRET   ;449 cycles
blit280_32 ANOP
         TCD        ; Set DP $0000
         ADC #155
         TCS        ; Set S  $009B
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #160
         TCS        ; Set S  $013B
         ADC #-59
         TCD        ; Set DP $0100
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #218
         TCS        ; Set S  $01DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $027B
         ADC #-123
         TCD        ; Set DP $0200
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #282
         TCS        ; Set S  $031B
         ADC #-27
         TCD        ; Set DP $0300
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #186
         TCS        ; Set S  $03BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $045B
         ADC #-91
         TCD        ; Set DP $0400
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #250
         TCS        ; Set S  $04FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         JMP BRET   ;449 cycles
blit288_32 ANOP
         TCD        ; Set DP $0000
         ADC #159
         TCS        ; Set S  $009F
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #160
         TCS        ; Set S  $013F
         ADC #-63
         TCD        ; Set DP $0100
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #222
         TCS        ; Set S  $01DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $027F
         ADC #-127
         TCD        ; Set DP $0200
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #286
         TCS        ; Set S  $031F
         ADC #-31
         TCD        ; Set DP $0300
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #190
         TCS        ; Set S  $03BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $045F
         ADC #-95
         TCD        ; Set DP $0400
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #254
         TCS        ; Set S  $04FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         JMP BRET   ;449 cycles
blit0_24 ANOP
         TCD        ; Set DP $0000
         ADC #11
         TCS        ; Set S  $000B
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #160
         TCS        ; Set S  $00AB
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $014B
         ADC #-75
         TCD        ; Set DP $0100
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #234
         TCS        ; Set S  $01EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $028B
         ADC #-139
         TCD        ; Set DP $0200
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #298
         TCS        ; Set S  $032B
         ADC #-43
         TCD        ; Set DP $0300
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #202
         TCS        ; Set S  $03CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $046B
         ADC #-107
         TCD        ; Set DP $0400
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         JMP BRET   ;353 cycles
blit8_24 ANOP
         TCD        ; Set DP $0000
         ADC #15
         TCS        ; Set S  $000F
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #160
         TCS        ; Set S  $00AF
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $014F
         ADC #-79
         TCD        ; Set DP $0100
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #238
         TCS        ; Set S  $01EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $028F
         ADC #-143
         TCD        ; Set DP $0200
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #302
         TCS        ; Set S  $032F
         ADC #-47
         TCD        ; Set DP $0300
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #206
         TCS        ; Set S  $03CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $046F
         ADC #-111
         TCD        ; Set DP $0400
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         JMP BRET   ;353 cycles
blit16_24 ANOP
         TCD        ; Set DP $0000
         ADC #19
         TCS        ; Set S  $0013
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #160
         TCS        ; Set S  $00B3
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $0153
         ADC #-83
         TCD        ; Set DP $0100
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #242
         TCS        ; Set S  $01F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $0293
         ADC #-147
         TCD        ; Set DP $0200
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #306
         TCS        ; Set S  $0333
         ADC #-51
         TCD        ; Set DP $0300
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #210
         TCS        ; Set S  $03D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $0473
         ADC #-115
         TCD        ; Set DP $0400
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         JMP BRET   ;353 cycles
blit24_24 ANOP
         TCD        ; Set DP $0000
         ADC #23
         TCS        ; Set S  $0017
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #160
         TCS        ; Set S  $00B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $0157
         ADC #-87
         TCD        ; Set DP $0100
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #246
         TCS        ; Set S  $01F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #160
         TCS        ; Set S  $0297
         ADC #-151
         TCD        ; Set DP $0200
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #310
         TCS        ; Set S  $0337
         ADC #-55
         TCD        ; Set DP $0300
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #214
         TCS        ; Set S  $03D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $0477
         ADC #-119
         TCD        ; Set DP $0400
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         JMP BRET   ;353 cycles
blit32_24 ANOP
         TCD        ; Set DP $0000
         ADC #27
         TCS        ; Set S  $001B
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #160
         TCS        ; Set S  $00BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $015B
         ADC #-91
         TCD        ; Set DP $0100
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #250
         TCS        ; Set S  $01FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #160
         TCS        ; Set S  $029B
         ADC #-155
         TCD        ; Set DP $0200
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #314
         TCS        ; Set S  $033B
         ADC #-59
         TCD        ; Set DP $0300
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #218
         TCS        ; Set S  $03DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $047B
         ADC #-123
         TCD        ; Set DP $0400
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         JMP BRET   ;353 cycles
blit40_24 ANOP
         TCD        ; Set DP $0000
         ADC #31
         TCS        ; Set S  $001F
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #160
         TCS        ; Set S  $00BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $015F
         ADC #-95
         TCD        ; Set DP $0100
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #254
         TCS        ; Set S  $01FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #160
         TCS        ; Set S  $029F
         ADC #-159
         TCD        ; Set DP $0200
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         ADC #318
         TCS        ; Set S  $033F
         ADC #-63
         TCD        ; Set DP $0300
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #222
         TCS        ; Set S  $03DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $047F
         ADC #-127
         TCD        ; Set DP $0400
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         JMP BRET   ;353 cycles
blit48_24 ANOP
         TCD        ; Set DP $0000
         ADC #35
         TCS        ; Set S  $0023
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #160
         TCS        ; Set S  $00C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $0163
         ADC #-99
         TCD        ; Set DP $0100
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #258
         TCS        ; Set S  $0203
         ADC #-3
         TCD        ; Set DP $0200
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #418
         TCS        ; Set S  $02A3
         ADC #-163
         TCD        ; Set DP $0200
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         ADC #322
         TCS        ; Set S  $0343
         ADC #-67
         TCD        ; Set DP $0300
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #226
         TCS        ; Set S  $03E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $0483
         ADC #-131
         TCD        ; Set DP $0400
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         JMP BRET   ;363 cycles
blit56_24 ANOP
         TCD        ; Set DP $0000
         ADC #39
         TCS        ; Set S  $0027
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #160
         TCS        ; Set S  $00C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $0167
         ADC #-103
         TCD        ; Set DP $0100
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #262
         TCS        ; Set S  $0207
         ADC #-7
         TCD        ; Set DP $0200
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         ADC #422
         TCS        ; Set S  $02A7
         ADC #-167
         TCD        ; Set DP $0200
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         ADC #326
         TCS        ; Set S  $0347
         ADC #-71
         TCD        ; Set DP $0300
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #230
         TCS        ; Set S  $03E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $0487
         ADC #-135
         TCD        ; Set DP $0400
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         JMP BRET   ;363 cycles
blit64_24 ANOP
         TCD        ; Set DP $0000
         ADC #43
         TCS        ; Set S  $002B
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #160
         TCS        ; Set S  $00CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $016B
         ADC #-107
         TCD        ; Set DP $0100
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #266
         TCS        ; Set S  $020B
         ADC #-11
         TCD        ; Set DP $0200
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #170
         TCS        ; Set S  $02AB
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $034B
         ADC #-75
         TCD        ; Set DP $0300
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #234
         TCS        ; Set S  $03EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $048B
         ADC #-139
         TCD        ; Set DP $0400
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         JMP BRET   ;353 cycles
blit72_24 ANOP
         TCD        ; Set DP $0000
         ADC #47
         TCS        ; Set S  $002F
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #160
         TCS        ; Set S  $00CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $016F
         ADC #-111
         TCD        ; Set DP $0100
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #270
         TCS        ; Set S  $020F
         ADC #-15
         TCD        ; Set DP $0200
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #174
         TCS        ; Set S  $02AF
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $034F
         ADC #-79
         TCD        ; Set DP $0300
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #238
         TCS        ; Set S  $03EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $048F
         ADC #-143
         TCD        ; Set DP $0400
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         JMP BRET   ;353 cycles
blit80_24 ANOP
         TCD        ; Set DP $0000
         ADC #51
         TCS        ; Set S  $0033
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #160
         TCS        ; Set S  $00D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $0173
         ADC #-115
         TCD        ; Set DP $0100
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #274
         TCS        ; Set S  $0213
         ADC #-19
         TCD        ; Set DP $0200
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #178
         TCS        ; Set S  $02B3
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $0353
         ADC #-83
         TCD        ; Set DP $0300
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #242
         TCS        ; Set S  $03F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $0493
         ADC #-147
         TCD        ; Set DP $0400
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         JMP BRET   ;353 cycles
blit88_24 ANOP
         TCD        ; Set DP $0000
         ADC #55
         TCS        ; Set S  $0037
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #160
         TCS        ; Set S  $00D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $0177
         ADC #-119
         TCD        ; Set DP $0100
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #278
         TCS        ; Set S  $0217
         ADC #-23
         TCD        ; Set DP $0200
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #182
         TCS        ; Set S  $02B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $0357
         ADC #-87
         TCD        ; Set DP $0300
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #246
         TCS        ; Set S  $03F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #160
         TCS        ; Set S  $0497
         ADC #-151
         TCD        ; Set DP $0400
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         JMP BRET   ;353 cycles
blit96_24 ANOP
         TCD        ; Set DP $0000
         ADC #59
         TCS        ; Set S  $003B
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #160
         TCS        ; Set S  $00DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $017B
         ADC #-123
         TCD        ; Set DP $0100
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #282
         TCS        ; Set S  $021B
         ADC #-27
         TCD        ; Set DP $0200
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #186
         TCS        ; Set S  $02BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $035B
         ADC #-91
         TCD        ; Set DP $0300
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #250
         TCS        ; Set S  $03FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #160
         TCS        ; Set S  $049B
         ADC #-155
         TCD        ; Set DP $0400
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         JMP BRET   ;353 cycles
blit104_24 ANOP
         TCD        ; Set DP $0000
         ADC #63
         TCS        ; Set S  $003F
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #160
         TCS        ; Set S  $00DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $017F
         ADC #-127
         TCD        ; Set DP $0100
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         ADC #286
         TCS        ; Set S  $021F
         ADC #-31
         TCD        ; Set DP $0200
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #190
         TCS        ; Set S  $02BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $035F
         ADC #-95
         TCD        ; Set DP $0300
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #254
         TCS        ; Set S  $03FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #160
         TCS        ; Set S  $049F
         ADC #-159
         TCD        ; Set DP $0400
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         JMP BRET   ;353 cycles
blit112_24 ANOP
         TCD        ; Set DP $0000
         ADC #67
         TCS        ; Set S  $0043
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #160
         TCS        ; Set S  $00E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $0183
         ADC #-131
         TCD        ; Set DP $0100
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         ADC #290
         TCS        ; Set S  $0223
         ADC #-35
         TCD        ; Set DP $0200
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #194
         TCS        ; Set S  $02C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $0363
         ADC #-99
         TCD        ; Set DP $0300
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #258
         TCS        ; Set S  $0403
         ADC #-3
         TCD        ; Set DP $0400
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #418
         TCS        ; Set S  $04A3
         ADC #-163
         TCD        ; Set DP $0400
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         JMP BRET   ;363 cycles
blit120_24 ANOP
         TCD        ; Set DP $0000
         ADC #71
         TCS        ; Set S  $0047
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #160
         TCS        ; Set S  $00E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $0187
         ADC #-135
         TCD        ; Set DP $0100
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         ADC #294
         TCS        ; Set S  $0227
         ADC #-39
         TCD        ; Set DP $0200
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #198
         TCS        ; Set S  $02C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $0367
         ADC #-103
         TCD        ; Set DP $0300
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #262
         TCS        ; Set S  $0407
         ADC #-7
         TCD        ; Set DP $0400
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         ADC #422
         TCS        ; Set S  $04A7
         ADC #-167
         TCD        ; Set DP $0400
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         JMP BRET   ;363 cycles
blit128_24 ANOP
         TCD        ; Set DP $0000
         ADC #75
         TCS        ; Set S  $004B
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #160
         TCS        ; Set S  $00EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $018B
         ADC #-139
         TCD        ; Set DP $0100
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #298
         TCS        ; Set S  $022B
         ADC #-43
         TCD        ; Set DP $0200
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #202
         TCS        ; Set S  $02CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $036B
         ADC #-107
         TCD        ; Set DP $0300
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #266
         TCS        ; Set S  $040B
         ADC #-11
         TCD        ; Set DP $0400
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #170
         TCS        ; Set S  $04AB
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         JMP BRET   ;353 cycles
blit136_24 ANOP
         TCD        ; Set DP $0000
         ADC #79
         TCS        ; Set S  $004F
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #160
         TCS        ; Set S  $00EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $018F
         ADC #-143
         TCD        ; Set DP $0100
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #302
         TCS        ; Set S  $022F
         ADC #-47
         TCD        ; Set DP $0200
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #206
         TCS        ; Set S  $02CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $036F
         ADC #-111
         TCD        ; Set DP $0300
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #270
         TCS        ; Set S  $040F
         ADC #-15
         TCD        ; Set DP $0400
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #174
         TCS        ; Set S  $04AF
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         JMP BRET   ;353 cycles
blit144_24 ANOP
         TCD        ; Set DP $0000
         ADC #83
         TCS        ; Set S  $0053
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #160
         TCS        ; Set S  $00F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $0193
         ADC #-147
         TCD        ; Set DP $0100
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #306
         TCS        ; Set S  $0233
         ADC #-51
         TCD        ; Set DP $0200
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #210
         TCS        ; Set S  $02D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $0373
         ADC #-115
         TCD        ; Set DP $0300
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #274
         TCS        ; Set S  $0413
         ADC #-19
         TCD        ; Set DP $0400
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #178
         TCS        ; Set S  $04B3
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         JMP BRET   ;353 cycles
blit152_24 ANOP
         TCD        ; Set DP $0000
         ADC #87
         TCS        ; Set S  $0057
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #160
         TCS        ; Set S  $00F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #160
         TCS        ; Set S  $0197
         ADC #-151
         TCD        ; Set DP $0100
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #310
         TCS        ; Set S  $0237
         ADC #-55
         TCD        ; Set DP $0200
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #214
         TCS        ; Set S  $02D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $0377
         ADC #-119
         TCD        ; Set DP $0300
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #278
         TCS        ; Set S  $0417
         ADC #-23
         TCD        ; Set DP $0400
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #182
         TCS        ; Set S  $04B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         JMP BRET   ;353 cycles
blit160_24 ANOP
         TCD        ; Set DP $0000
         ADC #91
         TCS        ; Set S  $005B
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #160
         TCS        ; Set S  $00FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #160
         TCS        ; Set S  $019B
         ADC #-155
         TCD        ; Set DP $0100
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #314
         TCS        ; Set S  $023B
         ADC #-59
         TCD        ; Set DP $0200
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #218
         TCS        ; Set S  $02DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $037B
         ADC #-123
         TCD        ; Set DP $0300
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #282
         TCS        ; Set S  $041B
         ADC #-27
         TCD        ; Set DP $0400
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #186
         TCS        ; Set S  $04BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         JMP BRET   ;353 cycles
blit168_24 ANOP
         TCD        ; Set DP $0000
         ADC #95
         TCS        ; Set S  $005F
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #160
         TCS        ; Set S  $00FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #160
         TCS        ; Set S  $019F
         ADC #-159
         TCD        ; Set DP $0100
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         ADC #318
         TCS        ; Set S  $023F
         ADC #-63
         TCD        ; Set DP $0200
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #222
         TCS        ; Set S  $02DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $037F
         ADC #-127
         TCD        ; Set DP $0300
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         ADC #286
         TCS        ; Set S  $041F
         ADC #-31
         TCD        ; Set DP $0400
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #190
         TCS        ; Set S  $04BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         JMP BRET   ;353 cycles
blit176_24 ANOP
         TCD        ; Set DP $0000
         ADC #99
         TCS        ; Set S  $0063
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #160
         TCS        ; Set S  $0103
         ADC #-3
         TCD        ; Set DP $0100
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #418
         TCS        ; Set S  $01A3
         ADC #-163
         TCD        ; Set DP $0100
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         ADC #322
         TCS        ; Set S  $0243
         ADC #-67
         TCD        ; Set DP $0200
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #226
         TCS        ; Set S  $02E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $0383
         ADC #-131
         TCD        ; Set DP $0300
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         ADC #290
         TCS        ; Set S  $0423
         ADC #-35
         TCD        ; Set DP $0400
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #194
         TCS        ; Set S  $04C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         JMP BRET   ;363 cycles
blit184_24 ANOP
         TCD        ; Set DP $0000
         ADC #103
         TCS        ; Set S  $0067
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #160
         TCS        ; Set S  $0107
         ADC #-7
         TCD        ; Set DP $0100
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         ADC #422
         TCS        ; Set S  $01A7
         ADC #-167
         TCD        ; Set DP $0100
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         ADC #326
         TCS        ; Set S  $0247
         ADC #-71
         TCD        ; Set DP $0200
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #230
         TCS        ; Set S  $02E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $0387
         ADC #-135
         TCD        ; Set DP $0300
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         ADC #294
         TCS        ; Set S  $0427
         ADC #-39
         TCD        ; Set DP $0400
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #198
         TCS        ; Set S  $04C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         JMP BRET   ;363 cycles
blit192_24 ANOP
         TCD        ; Set DP $0000
         ADC #107
         TCS        ; Set S  $006B
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #160
         TCS        ; Set S  $010B
         ADC #-11
         TCD        ; Set DP $0100
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #170
         TCS        ; Set S  $01AB
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $024B
         ADC #-75
         TCD        ; Set DP $0200
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #234
         TCS        ; Set S  $02EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $038B
         ADC #-139
         TCD        ; Set DP $0300
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #298
         TCS        ; Set S  $042B
         ADC #-43
         TCD        ; Set DP $0400
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #202
         TCS        ; Set S  $04CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         JMP BRET   ;353 cycles
blit200_24 ANOP
         TCD        ; Set DP $0000
         ADC #111
         TCS        ; Set S  $006F
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #160
         TCS        ; Set S  $010F
         ADC #-15
         TCD        ; Set DP $0100
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #174
         TCS        ; Set S  $01AF
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $024F
         ADC #-79
         TCD        ; Set DP $0200
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #238
         TCS        ; Set S  $02EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $038F
         ADC #-143
         TCD        ; Set DP $0300
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #302
         TCS        ; Set S  $042F
         ADC #-47
         TCD        ; Set DP $0400
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #206
         TCS        ; Set S  $04CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         JMP BRET   ;353 cycles
blit208_24 ANOP
         TCD        ; Set DP $0000
         ADC #115
         TCS        ; Set S  $0073
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #160
         TCS        ; Set S  $0113
         ADC #-19
         TCD        ; Set DP $0100
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #178
         TCS        ; Set S  $01B3
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $0253
         ADC #-83
         TCD        ; Set DP $0200
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #242
         TCS        ; Set S  $02F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $0393
         ADC #-147
         TCD        ; Set DP $0300
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #306
         TCS        ; Set S  $0433
         ADC #-51
         TCD        ; Set DP $0400
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #210
         TCS        ; Set S  $04D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         JMP BRET   ;353 cycles
blit216_24 ANOP
         TCD        ; Set DP $0000
         ADC #119
         TCS        ; Set S  $0077
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #160
         TCS        ; Set S  $0117
         ADC #-23
         TCD        ; Set DP $0100
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #182
         TCS        ; Set S  $01B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $0257
         ADC #-87
         TCD        ; Set DP $0200
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #246
         TCS        ; Set S  $02F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #160
         TCS        ; Set S  $0397
         ADC #-151
         TCD        ; Set DP $0300
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #310
         TCS        ; Set S  $0437
         ADC #-55
         TCD        ; Set DP $0400
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #214
         TCS        ; Set S  $04D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         JMP BRET   ;353 cycles
blit224_24 ANOP
         TCD        ; Set DP $0000
         ADC #123
         TCS        ; Set S  $007B
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #160
         TCS        ; Set S  $011B
         ADC #-27
         TCD        ; Set DP $0100
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #186
         TCS        ; Set S  $01BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $025B
         ADC #-91
         TCD        ; Set DP $0200
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #250
         TCS        ; Set S  $02FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #160
         TCS        ; Set S  $039B
         ADC #-155
         TCD        ; Set DP $0300
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #314
         TCS        ; Set S  $043B
         ADC #-59
         TCD        ; Set DP $0400
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #218
         TCS        ; Set S  $04DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         JMP BRET   ;353 cycles
blit232_24 ANOP
         TCD        ; Set DP $0000
         ADC #127
         TCS        ; Set S  $007F
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         ADC #160
         TCS        ; Set S  $011F
         ADC #-31
         TCD        ; Set DP $0100
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #190
         TCS        ; Set S  $01BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $025F
         ADC #-95
         TCD        ; Set DP $0200
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #254
         TCS        ; Set S  $02FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #160
         TCS        ; Set S  $039F
         ADC #-159
         TCD        ; Set DP $0300
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         ADC #318
         TCS        ; Set S  $043F
         ADC #-63
         TCD        ; Set DP $0400
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #222
         TCS        ; Set S  $04DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         JMP BRET   ;353 cycles
blit240_24 ANOP
         TCD        ; Set DP $0000
         ADC #131
         TCS        ; Set S  $0083
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         ADC #160
         TCS        ; Set S  $0123
         ADC #-35
         TCD        ; Set DP $0100
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #194
         TCS        ; Set S  $01C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $0263
         ADC #-99
         TCD        ; Set DP $0200
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #258
         TCS        ; Set S  $0303
         ADC #-3
         TCD        ; Set DP $0300
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #418
         TCS        ; Set S  $03A3
         ADC #-163
         TCD        ; Set DP $0300
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         ADC #322
         TCS        ; Set S  $0443
         ADC #-67
         TCD        ; Set DP $0400
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #226
         TCS        ; Set S  $04E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         JMP BRET   ;363 cycles
blit248_24 ANOP
         TCD        ; Set DP $0000
         ADC #135
         TCS        ; Set S  $0087
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         ADC #160
         TCS        ; Set S  $0127
         ADC #-39
         TCD        ; Set DP $0100
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #198
         TCS        ; Set S  $01C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $0267
         ADC #-103
         TCD        ; Set DP $0200
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #262
         TCS        ; Set S  $0307
         ADC #-7
         TCD        ; Set DP $0300
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         ADC #422
         TCS        ; Set S  $03A7
         ADC #-167
         TCD        ; Set DP $0300
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         ADC #326
         TCS        ; Set S  $0447
         ADC #-71
         TCD        ; Set DP $0400
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #230
         TCS        ; Set S  $04E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         JMP BRET   ;363 cycles
blit256_24 ANOP
         TCD        ; Set DP $0000
         ADC #139
         TCS        ; Set S  $008B
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #160
         TCS        ; Set S  $012B
         ADC #-43
         TCD        ; Set DP $0100
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #202
         TCS        ; Set S  $01CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $026B
         ADC #-107
         TCD        ; Set DP $0200
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #266
         TCS        ; Set S  $030B
         ADC #-11
         TCD        ; Set DP $0300
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #170
         TCS        ; Set S  $03AB
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $044B
         ADC #-75
         TCD        ; Set DP $0400
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #234
         TCS        ; Set S  $04EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         JMP BRET   ;353 cycles
blit264_24 ANOP
         TCD        ; Set DP $0000
         ADC #143
         TCS        ; Set S  $008F
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #160
         TCS        ; Set S  $012F
         ADC #-47
         TCD        ; Set DP $0100
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #206
         TCS        ; Set S  $01CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $026F
         ADC #-111
         TCD        ; Set DP $0200
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #270
         TCS        ; Set S  $030F
         ADC #-15
         TCD        ; Set DP $0300
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #174
         TCS        ; Set S  $03AF
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $044F
         ADC #-79
         TCD        ; Set DP $0400
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #238
         TCS        ; Set S  $04EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         JMP BRET   ;353 cycles
blit272_24 ANOP
         TCD        ; Set DP $0000
         ADC #147
         TCS        ; Set S  $0093
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #160
         TCS        ; Set S  $0133
         ADC #-51
         TCD        ; Set DP $0100
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #210
         TCS        ; Set S  $01D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $0273
         ADC #-115
         TCD        ; Set DP $0200
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #274
         TCS        ; Set S  $0313
         ADC #-19
         TCD        ; Set DP $0300
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #178
         TCS        ; Set S  $03B3
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $0453
         ADC #-83
         TCD        ; Set DP $0400
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #242
         TCS        ; Set S  $04F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         JMP BRET   ;353 cycles
blit280_24 ANOP
         TCD        ; Set DP $0000
         ADC #151
         TCS        ; Set S  $0097
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #160
         TCS        ; Set S  $0137
         ADC #-55
         TCD        ; Set DP $0100
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #214
         TCS        ; Set S  $01D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $0277
         ADC #-119
         TCD        ; Set DP $0200
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #278
         TCS        ; Set S  $0317
         ADC #-23
         TCD        ; Set DP $0300
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #182
         TCS        ; Set S  $03B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $0457
         ADC #-87
         TCD        ; Set DP $0400
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #246
         TCS        ; Set S  $04F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         JMP BRET   ;353 cycles
blit288_24 ANOP
         TCD        ; Set DP $0000
         ADC #155
         TCS        ; Set S  $009B
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #160
         TCS        ; Set S  $013B
         ADC #-59
         TCD        ; Set DP $0100
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #218
         TCS        ; Set S  $01DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $027B
         ADC #-123
         TCD        ; Set DP $0200
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #282
         TCS        ; Set S  $031B
         ADC #-27
         TCD        ; Set DP $0300
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #186
         TCS        ; Set S  $03BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $045B
         ADC #-91
         TCD        ; Set DP $0400
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #250
         TCS        ; Set S  $04FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         JMP BRET   ;353 cycles
blit296_24 ANOP
         TCD        ; Set DP $0000
         ADC #159
         TCS        ; Set S  $009F
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         ADC #160
         TCS        ; Set S  $013F
         ADC #-63
         TCD        ; Set DP $0100
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #222
         TCS        ; Set S  $01DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $027F
         ADC #-127
         TCD        ; Set DP $0200
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         ADC #286
         TCS        ; Set S  $031F
         ADC #-31
         TCD        ; Set DP $0300
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #190
         TCS        ; Set S  $03BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $045F
         ADC #-95
         TCD        ; Set DP $0400
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #254
         TCS        ; Set S  $04FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         JMP BRET   ;353 cycles
blit0_16 ANOP
         TCD        ; Set DP $0000
         ADC #7
         TCS        ; Set S  $0007
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #160
         TCS        ; Set S  $00A7
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $0147
         ADC #-71
         TCD        ; Set DP $0100
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #230
         TCS        ; Set S  $01E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $0287
         ADC #-135
         TCD        ; Set DP $0200
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #294
         TCS        ; Set S  $0327
         ADC #-39
         TCD        ; Set DP $0300
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #198
         TCS        ; Set S  $03C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $0467
         ADC #-103
         TCD        ; Set DP $0400
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         JMP BRET   ;257 cycles
blit8_16 ANOP
         TCD        ; Set DP $0000
         ADC #11
         TCS        ; Set S  $000B
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #160
         TCS        ; Set S  $00AB
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $014B
         ADC #-75
         TCD        ; Set DP $0100
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #234
         TCS        ; Set S  $01EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $028B
         ADC #-139
         TCD        ; Set DP $0200
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #298
         TCS        ; Set S  $032B
         ADC #-43
         TCD        ; Set DP $0300
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #202
         TCS        ; Set S  $03CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $046B
         ADC #-107
         TCD        ; Set DP $0400
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         JMP BRET   ;257 cycles
blit16_16 ANOP
         TCD        ; Set DP $0000
         ADC #15
         TCS        ; Set S  $000F
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #160
         TCS        ; Set S  $00AF
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $014F
         ADC #-79
         TCD        ; Set DP $0100
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #238
         TCS        ; Set S  $01EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $028F
         ADC #-143
         TCD        ; Set DP $0200
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #302
         TCS        ; Set S  $032F
         ADC #-47
         TCD        ; Set DP $0300
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #206
         TCS        ; Set S  $03CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $046F
         ADC #-111
         TCD        ; Set DP $0400
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         JMP BRET   ;257 cycles
blit24_16 ANOP
         TCD        ; Set DP $0000
         ADC #19
         TCS        ; Set S  $0013
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #160
         TCS        ; Set S  $00B3
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $0153
         ADC #-83
         TCD        ; Set DP $0100
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #242
         TCS        ; Set S  $01F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #160
         TCS        ; Set S  $0293
         ADC #-147
         TCD        ; Set DP $0200
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #306
         TCS        ; Set S  $0333
         ADC #-51
         TCD        ; Set DP $0300
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #210
         TCS        ; Set S  $03D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $0473
         ADC #-115
         TCD        ; Set DP $0400
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         JMP BRET   ;257 cycles
blit32_16 ANOP
         TCD        ; Set DP $0000
         ADC #23
         TCS        ; Set S  $0017
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #160
         TCS        ; Set S  $00B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $0157
         ADC #-87
         TCD        ; Set DP $0100
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #246
         TCS        ; Set S  $01F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #160
         TCS        ; Set S  $0297
         ADC #-151
         TCD        ; Set DP $0200
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #310
         TCS        ; Set S  $0337
         ADC #-55
         TCD        ; Set DP $0300
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #214
         TCS        ; Set S  $03D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $0477
         ADC #-119
         TCD        ; Set DP $0400
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         JMP BRET   ;257 cycles
blit40_16 ANOP
         TCD        ; Set DP $0000
         ADC #27
         TCS        ; Set S  $001B
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #160
         TCS        ; Set S  $00BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $015B
         ADC #-91
         TCD        ; Set DP $0100
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #250
         TCS        ; Set S  $01FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #160
         TCS        ; Set S  $029B
         ADC #-155
         TCD        ; Set DP $0200
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         ADC #314
         TCS        ; Set S  $033B
         ADC #-59
         TCD        ; Set DP $0300
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #218
         TCS        ; Set S  $03DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $047B
         ADC #-123
         TCD        ; Set DP $0400
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         JMP BRET   ;257 cycles
blit48_16 ANOP
         TCD        ; Set DP $0000
         ADC #31
         TCS        ; Set S  $001F
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #160
         TCS        ; Set S  $00BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $015F
         ADC #-95
         TCD        ; Set DP $0100
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #254
         TCS        ; Set S  $01FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #160
         TCS        ; Set S  $029F
         ADC #-159
         TCD        ; Set DP $0200
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         ADC #318
         TCS        ; Set S  $033F
         ADC #-63
         TCD        ; Set DP $0300
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #222
         TCS        ; Set S  $03DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $047F
         ADC #-127
         TCD        ; Set DP $0400
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         JMP BRET   ;257 cycles
blit56_16 ANOP
         TCD        ; Set DP $0000
         ADC #35
         TCS        ; Set S  $0023
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #160
         TCS        ; Set S  $00C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $0163
         ADC #-99
         TCD        ; Set DP $0100
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #258
         TCS        ; Set S  $0203
         ADC #-3
         TCD        ; Set DP $0200
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0100
         PEI $FE
         PEI $FC
         ADC #418
         TCS        ; Set S  $02A3
         ADC #-163
         TCD        ; Set DP $0200
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         ADC #322
         TCS        ; Set S  $0343
         ADC #-67
         TCD        ; Set DP $0300
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #226
         TCS        ; Set S  $03E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $0483
         ADC #-131
         TCD        ; Set DP $0400
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         JMP BRET   ;267 cycles
blit64_16 ANOP
         TCD        ; Set DP $0000
         ADC #39
         TCS        ; Set S  $0027
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #160
         TCS        ; Set S  $00C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $0167
         ADC #-103
         TCD        ; Set DP $0100
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #262
         TCS        ; Set S  $0207
         ADC #-7
         TCD        ; Set DP $0200
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #166
         TCS        ; Set S  $02A7
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $0347
         ADC #-71
         TCD        ; Set DP $0300
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #230
         TCS        ; Set S  $03E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $0487
         ADC #-135
         TCD        ; Set DP $0400
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         JMP BRET   ;257 cycles
blit72_16 ANOP
         TCD        ; Set DP $0000
         ADC #43
         TCS        ; Set S  $002B
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #160
         TCS        ; Set S  $00CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $016B
         ADC #-107
         TCD        ; Set DP $0100
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #266
         TCS        ; Set S  $020B
         ADC #-11
         TCD        ; Set DP $0200
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #170
         TCS        ; Set S  $02AB
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $034B
         ADC #-75
         TCD        ; Set DP $0300
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #234
         TCS        ; Set S  $03EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $048B
         ADC #-139
         TCD        ; Set DP $0400
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         JMP BRET   ;257 cycles
blit80_16 ANOP
         TCD        ; Set DP $0000
         ADC #47
         TCS        ; Set S  $002F
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #160
         TCS        ; Set S  $00CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $016F
         ADC #-111
         TCD        ; Set DP $0100
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #270
         TCS        ; Set S  $020F
         ADC #-15
         TCD        ; Set DP $0200
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #174
         TCS        ; Set S  $02AF
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $034F
         ADC #-79
         TCD        ; Set DP $0300
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #238
         TCS        ; Set S  $03EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $048F
         ADC #-143
         TCD        ; Set DP $0400
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         JMP BRET   ;257 cycles
blit88_16 ANOP
         TCD        ; Set DP $0000
         ADC #51
         TCS        ; Set S  $0033
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #160
         TCS        ; Set S  $00D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $0173
         ADC #-115
         TCD        ; Set DP $0100
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #274
         TCS        ; Set S  $0213
         ADC #-19
         TCD        ; Set DP $0200
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #178
         TCS        ; Set S  $02B3
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $0353
         ADC #-83
         TCD        ; Set DP $0300
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #242
         TCS        ; Set S  $03F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #160
         TCS        ; Set S  $0493
         ADC #-147
         TCD        ; Set DP $0400
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         JMP BRET   ;257 cycles
blit96_16 ANOP
         TCD        ; Set DP $0000
         ADC #55
         TCS        ; Set S  $0037
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #160
         TCS        ; Set S  $00D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $0177
         ADC #-119
         TCD        ; Set DP $0100
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #278
         TCS        ; Set S  $0217
         ADC #-23
         TCD        ; Set DP $0200
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #182
         TCS        ; Set S  $02B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $0357
         ADC #-87
         TCD        ; Set DP $0300
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #246
         TCS        ; Set S  $03F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #160
         TCS        ; Set S  $0497
         ADC #-151
         TCD        ; Set DP $0400
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         JMP BRET   ;257 cycles
blit104_16 ANOP
         TCD        ; Set DP $0000
         ADC #59
         TCS        ; Set S  $003B
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #160
         TCS        ; Set S  $00DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $017B
         ADC #-123
         TCD        ; Set DP $0100
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         ADC #282
         TCS        ; Set S  $021B
         ADC #-27
         TCD        ; Set DP $0200
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #186
         TCS        ; Set S  $02BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $035B
         ADC #-91
         TCD        ; Set DP $0300
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #250
         TCS        ; Set S  $03FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #160
         TCS        ; Set S  $049B
         ADC #-155
         TCD        ; Set DP $0400
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         JMP BRET   ;257 cycles
blit112_16 ANOP
         TCD        ; Set DP $0000
         ADC #63
         TCS        ; Set S  $003F
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #160
         TCS        ; Set S  $00DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $017F
         ADC #-127
         TCD        ; Set DP $0100
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         ADC #286
         TCS        ; Set S  $021F
         ADC #-31
         TCD        ; Set DP $0200
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #190
         TCS        ; Set S  $02BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $035F
         ADC #-95
         TCD        ; Set DP $0300
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #254
         TCS        ; Set S  $03FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #160
         TCS        ; Set S  $049F
         ADC #-159
         TCD        ; Set DP $0400
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         JMP BRET   ;257 cycles
blit120_16 ANOP
         TCD        ; Set DP $0000
         ADC #67
         TCS        ; Set S  $0043
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #160
         TCS        ; Set S  $00E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $0183
         ADC #-131
         TCD        ; Set DP $0100
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         ADC #290
         TCS        ; Set S  $0223
         ADC #-35
         TCD        ; Set DP $0200
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #194
         TCS        ; Set S  $02C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $0363
         ADC #-99
         TCD        ; Set DP $0300
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #258
         TCS        ; Set S  $0403
         ADC #-3
         TCD        ; Set DP $0400
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0300
         PEI $FE
         PEI $FC
         ADC #418
         TCS        ; Set S  $04A3
         ADC #-163
         TCD        ; Set DP $0400
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         JMP BRET   ;267 cycles
blit128_16 ANOP
         TCD        ; Set DP $0000
         ADC #71
         TCS        ; Set S  $0047
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #160
         TCS        ; Set S  $00E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $0187
         ADC #-135
         TCD        ; Set DP $0100
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #294
         TCS        ; Set S  $0227
         ADC #-39
         TCD        ; Set DP $0200
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #198
         TCS        ; Set S  $02C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $0367
         ADC #-103
         TCD        ; Set DP $0300
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #262
         TCS        ; Set S  $0407
         ADC #-7
         TCD        ; Set DP $0400
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #166
         TCS        ; Set S  $04A7
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         JMP BRET   ;257 cycles
blit136_16 ANOP
         TCD        ; Set DP $0000
         ADC #75
         TCS        ; Set S  $004B
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #160
         TCS        ; Set S  $00EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $018B
         ADC #-139
         TCD        ; Set DP $0100
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #298
         TCS        ; Set S  $022B
         ADC #-43
         TCD        ; Set DP $0200
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #202
         TCS        ; Set S  $02CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $036B
         ADC #-107
         TCD        ; Set DP $0300
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #266
         TCS        ; Set S  $040B
         ADC #-11
         TCD        ; Set DP $0400
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #170
         TCS        ; Set S  $04AB
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         JMP BRET   ;257 cycles
blit144_16 ANOP
         TCD        ; Set DP $0000
         ADC #79
         TCS        ; Set S  $004F
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #160
         TCS        ; Set S  $00EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $018F
         ADC #-143
         TCD        ; Set DP $0100
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #302
         TCS        ; Set S  $022F
         ADC #-47
         TCD        ; Set DP $0200
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #206
         TCS        ; Set S  $02CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $036F
         ADC #-111
         TCD        ; Set DP $0300
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #270
         TCS        ; Set S  $040F
         ADC #-15
         TCD        ; Set DP $0400
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #174
         TCS        ; Set S  $04AF
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         JMP BRET   ;257 cycles
blit152_16 ANOP
         TCD        ; Set DP $0000
         ADC #83
         TCS        ; Set S  $0053
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #160
         TCS        ; Set S  $00F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #160
         TCS        ; Set S  $0193
         ADC #-147
         TCD        ; Set DP $0100
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #306
         TCS        ; Set S  $0233
         ADC #-51
         TCD        ; Set DP $0200
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #210
         TCS        ; Set S  $02D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $0373
         ADC #-115
         TCD        ; Set DP $0300
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #274
         TCS        ; Set S  $0413
         ADC #-19
         TCD        ; Set DP $0400
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #178
         TCS        ; Set S  $04B3
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         JMP BRET   ;257 cycles
blit160_16 ANOP
         TCD        ; Set DP $0000
         ADC #87
         TCS        ; Set S  $0057
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #160
         TCS        ; Set S  $00F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #160
         TCS        ; Set S  $0197
         ADC #-151
         TCD        ; Set DP $0100
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #310
         TCS        ; Set S  $0237
         ADC #-55
         TCD        ; Set DP $0200
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #214
         TCS        ; Set S  $02D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $0377
         ADC #-119
         TCD        ; Set DP $0300
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #278
         TCS        ; Set S  $0417
         ADC #-23
         TCD        ; Set DP $0400
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #182
         TCS        ; Set S  $04B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         JMP BRET   ;257 cycles
blit168_16 ANOP
         TCD        ; Set DP $0000
         ADC #91
         TCS        ; Set S  $005B
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #160
         TCS        ; Set S  $00FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #160
         TCS        ; Set S  $019B
         ADC #-155
         TCD        ; Set DP $0100
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         ADC #314
         TCS        ; Set S  $023B
         ADC #-59
         TCD        ; Set DP $0200
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #218
         TCS        ; Set S  $02DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $037B
         ADC #-123
         TCD        ; Set DP $0300
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         ADC #282
         TCS        ; Set S  $041B
         ADC #-27
         TCD        ; Set DP $0400
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #186
         TCS        ; Set S  $04BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         JMP BRET   ;257 cycles
blit176_16 ANOP
         TCD        ; Set DP $0000
         ADC #95
         TCS        ; Set S  $005F
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #160
         TCS        ; Set S  $00FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #160
         TCS        ; Set S  $019F
         ADC #-159
         TCD        ; Set DP $0100
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         ADC #318
         TCS        ; Set S  $023F
         ADC #-63
         TCD        ; Set DP $0200
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #222
         TCS        ; Set S  $02DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $037F
         ADC #-127
         TCD        ; Set DP $0300
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         ADC #286
         TCS        ; Set S  $041F
         ADC #-31
         TCD        ; Set DP $0400
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #190
         TCS        ; Set S  $04BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         JMP BRET   ;257 cycles
blit184_16 ANOP
         TCD        ; Set DP $0000
         ADC #99
         TCS        ; Set S  $0063
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #160
         TCS        ; Set S  $0103
         ADC #-3
         TCD        ; Set DP $0100
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0000
         PEI $FE
         PEI $FC
         ADC #418
         TCS        ; Set S  $01A3
         ADC #-163
         TCD        ; Set DP $0100
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         ADC #322
         TCS        ; Set S  $0243
         ADC #-67
         TCD        ; Set DP $0200
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #226
         TCS        ; Set S  $02E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $0383
         ADC #-131
         TCD        ; Set DP $0300
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         ADC #290
         TCS        ; Set S  $0423
         ADC #-35
         TCD        ; Set DP $0400
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #194
         TCS        ; Set S  $04C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         JMP BRET   ;267 cycles
blit192_16 ANOP
         TCD        ; Set DP $0000
         ADC #103
         TCS        ; Set S  $0067
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #160
         TCS        ; Set S  $0107
         ADC #-7
         TCD        ; Set DP $0100
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #166
         TCS        ; Set S  $01A7
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $0247
         ADC #-71
         TCD        ; Set DP $0200
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #230
         TCS        ; Set S  $02E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $0387
         ADC #-135
         TCD        ; Set DP $0300
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #294
         TCS        ; Set S  $0427
         ADC #-39
         TCD        ; Set DP $0400
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #198
         TCS        ; Set S  $04C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         JMP BRET   ;257 cycles
blit200_16 ANOP
         TCD        ; Set DP $0000
         ADC #107
         TCS        ; Set S  $006B
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #160
         TCS        ; Set S  $010B
         ADC #-11
         TCD        ; Set DP $0100
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #170
         TCS        ; Set S  $01AB
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $024B
         ADC #-75
         TCD        ; Set DP $0200
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #234
         TCS        ; Set S  $02EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $038B
         ADC #-139
         TCD        ; Set DP $0300
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #298
         TCS        ; Set S  $042B
         ADC #-43
         TCD        ; Set DP $0400
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #202
         TCS        ; Set S  $04CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         JMP BRET   ;257 cycles
blit208_16 ANOP
         TCD        ; Set DP $0000
         ADC #111
         TCS        ; Set S  $006F
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #160
         TCS        ; Set S  $010F
         ADC #-15
         TCD        ; Set DP $0100
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #174
         TCS        ; Set S  $01AF
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $024F
         ADC #-79
         TCD        ; Set DP $0200
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #238
         TCS        ; Set S  $02EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $038F
         ADC #-143
         TCD        ; Set DP $0300
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #302
         TCS        ; Set S  $042F
         ADC #-47
         TCD        ; Set DP $0400
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #206
         TCS        ; Set S  $04CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         JMP BRET   ;257 cycles
blit216_16 ANOP
         TCD        ; Set DP $0000
         ADC #115
         TCS        ; Set S  $0073
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #160
         TCS        ; Set S  $0113
         ADC #-19
         TCD        ; Set DP $0100
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #178
         TCS        ; Set S  $01B3
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $0253
         ADC #-83
         TCD        ; Set DP $0200
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #242
         TCS        ; Set S  $02F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         ADC #160
         TCS        ; Set S  $0393
         ADC #-147
         TCD        ; Set DP $0300
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #306
         TCS        ; Set S  $0433
         ADC #-51
         TCD        ; Set DP $0400
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #210
         TCS        ; Set S  $04D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         JMP BRET   ;257 cycles
blit224_16 ANOP
         TCD        ; Set DP $0000
         ADC #119
         TCS        ; Set S  $0077
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #160
         TCS        ; Set S  $0117
         ADC #-23
         TCD        ; Set DP $0100
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #182
         TCS        ; Set S  $01B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $0257
         ADC #-87
         TCD        ; Set DP $0200
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #246
         TCS        ; Set S  $02F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         ADC #160
         TCS        ; Set S  $0397
         ADC #-151
         TCD        ; Set DP $0300
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #310
         TCS        ; Set S  $0437
         ADC #-55
         TCD        ; Set DP $0400
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #214
         TCS        ; Set S  $04D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         JMP BRET   ;257 cycles
blit232_16 ANOP
         TCD        ; Set DP $0000
         ADC #123
         TCS        ; Set S  $007B
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         ADC #160
         TCS        ; Set S  $011B
         ADC #-27
         TCD        ; Set DP $0100
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #186
         TCS        ; Set S  $01BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $025B
         ADC #-91
         TCD        ; Set DP $0200
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #250
         TCS        ; Set S  $02FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         ADC #160
         TCS        ; Set S  $039B
         ADC #-155
         TCD        ; Set DP $0300
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         ADC #314
         TCS        ; Set S  $043B
         ADC #-59
         TCD        ; Set DP $0400
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #218
         TCS        ; Set S  $04DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         JMP BRET   ;257 cycles
blit240_16 ANOP
         TCD        ; Set DP $0000
         ADC #127
         TCS        ; Set S  $007F
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         ADC #160
         TCS        ; Set S  $011F
         ADC #-31
         TCD        ; Set DP $0100
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #190
         TCS        ; Set S  $01BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $025F
         ADC #-95
         TCD        ; Set DP $0200
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #254
         TCS        ; Set S  $02FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         ADC #160
         TCS        ; Set S  $039F
         ADC #-159
         TCD        ; Set DP $0300
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         ADC #318
         TCS        ; Set S  $043F
         ADC #-63
         TCD        ; Set DP $0400
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #222
         TCS        ; Set S  $04DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         JMP BRET   ;257 cycles
blit248_16 ANOP
         TCD        ; Set DP $0000
         ADC #131
         TCS        ; Set S  $0083
         PEI $82
         PEI $80
         PEI $7E
         PEI $7C
         ADC #160
         TCS        ; Set S  $0123
         ADC #-35
         TCD        ; Set DP $0100
         PEI $22
         PEI $20
         PEI $1E
         PEI $1C
         ADC #194
         TCS        ; Set S  $01C3
         PEI $C2
         PEI $C0
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $0263
         ADC #-99
         TCD        ; Set DP $0200
         PEI $62
         PEI $60
         PEI $5E
         PEI $5C
         ADC #258
         TCS        ; Set S  $0303
         ADC #-3
         TCD        ; Set DP $0300
         PEI $02
         PEI $00
         ADC #-257
         TCD        ; Set DP $0200
         PEI $FE
         PEI $FC
         ADC #418
         TCS        ; Set S  $03A3
         ADC #-163
         TCD        ; Set DP $0300
         PEI $A2
         PEI $A0
         PEI $9E
         PEI $9C
         ADC #322
         TCS        ; Set S  $0443
         ADC #-67
         TCD        ; Set DP $0400
         PEI $42
         PEI $40
         PEI $3E
         PEI $3C
         ADC #226
         TCS        ; Set S  $04E3
         PEI $E2
         PEI $E0
         PEI $DE
         PEI $DC
         JMP BRET   ;267 cycles
blit256_16 ANOP
         TCD        ; Set DP $0000
         ADC #135
         TCS        ; Set S  $0087
         PEI $86
         PEI $84
         PEI $82
         PEI $80
         ADC #160
         TCS        ; Set S  $0127
         ADC #-39
         TCD        ; Set DP $0100
         PEI $26
         PEI $24
         PEI $22
         PEI $20
         ADC #198
         TCS        ; Set S  $01C7
         PEI $C6
         PEI $C4
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $0267
         ADC #-103
         TCD        ; Set DP $0200
         PEI $66
         PEI $64
         PEI $62
         PEI $60
         ADC #262
         TCS        ; Set S  $0307
         ADC #-7
         TCD        ; Set DP $0300
         PEI $06
         PEI $04
         PEI $02
         PEI $00
         ADC #166
         TCS        ; Set S  $03A7
         PEI $A6
         PEI $A4
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $0447
         ADC #-71
         TCD        ; Set DP $0400
         PEI $46
         PEI $44
         PEI $42
         PEI $40
         ADC #230
         TCS        ; Set S  $04E7
         PEI $E6
         PEI $E4
         PEI $E2
         PEI $E0
         JMP BRET   ;257 cycles
blit264_16 ANOP
         TCD        ; Set DP $0000
         ADC #139
         TCS        ; Set S  $008B
         PEI $8A
         PEI $88
         PEI $86
         PEI $84
         ADC #160
         TCS        ; Set S  $012B
         ADC #-43
         TCD        ; Set DP $0100
         PEI $2A
         PEI $28
         PEI $26
         PEI $24
         ADC #202
         TCS        ; Set S  $01CB
         PEI $CA
         PEI $C8
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $026B
         ADC #-107
         TCD        ; Set DP $0200
         PEI $6A
         PEI $68
         PEI $66
         PEI $64
         ADC #266
         TCS        ; Set S  $030B
         ADC #-11
         TCD        ; Set DP $0300
         PEI $0A
         PEI $08
         PEI $06
         PEI $04
         ADC #170
         TCS        ; Set S  $03AB
         PEI $AA
         PEI $A8
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $044B
         ADC #-75
         TCD        ; Set DP $0400
         PEI $4A
         PEI $48
         PEI $46
         PEI $44
         ADC #234
         TCS        ; Set S  $04EB
         PEI $EA
         PEI $E8
         PEI $E6
         PEI $E4
         JMP BRET   ;257 cycles
blit272_16 ANOP
         TCD        ; Set DP $0000
         ADC #143
         TCS        ; Set S  $008F
         PEI $8E
         PEI $8C
         PEI $8A
         PEI $88
         ADC #160
         TCS        ; Set S  $012F
         ADC #-47
         TCD        ; Set DP $0100
         PEI $2E
         PEI $2C
         PEI $2A
         PEI $28
         ADC #206
         TCS        ; Set S  $01CF
         PEI $CE
         PEI $CC
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $026F
         ADC #-111
         TCD        ; Set DP $0200
         PEI $6E
         PEI $6C
         PEI $6A
         PEI $68
         ADC #270
         TCS        ; Set S  $030F
         ADC #-15
         TCD        ; Set DP $0300
         PEI $0E
         PEI $0C
         PEI $0A
         PEI $08
         ADC #174
         TCS        ; Set S  $03AF
         PEI $AE
         PEI $AC
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $044F
         ADC #-79
         TCD        ; Set DP $0400
         PEI $4E
         PEI $4C
         PEI $4A
         PEI $48
         ADC #238
         TCS        ; Set S  $04EF
         PEI $EE
         PEI $EC
         PEI $EA
         PEI $E8
         JMP BRET   ;257 cycles
blit280_16 ANOP
         TCD        ; Set DP $0000
         ADC #147
         TCS        ; Set S  $0093
         PEI $92
         PEI $90
         PEI $8E
         PEI $8C
         ADC #160
         TCS        ; Set S  $0133
         ADC #-51
         TCD        ; Set DP $0100
         PEI $32
         PEI $30
         PEI $2E
         PEI $2C
         ADC #210
         TCS        ; Set S  $01D3
         PEI $D2
         PEI $D0
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $0273
         ADC #-115
         TCD        ; Set DP $0200
         PEI $72
         PEI $70
         PEI $6E
         PEI $6C
         ADC #274
         TCS        ; Set S  $0313
         ADC #-19
         TCD        ; Set DP $0300
         PEI $12
         PEI $10
         PEI $0E
         PEI $0C
         ADC #178
         TCS        ; Set S  $03B3
         PEI $B2
         PEI $B0
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $0453
         ADC #-83
         TCD        ; Set DP $0400
         PEI $52
         PEI $50
         PEI $4E
         PEI $4C
         ADC #242
         TCS        ; Set S  $04F3
         PEI $F2
         PEI $F0
         PEI $EE
         PEI $EC
         JMP BRET   ;257 cycles
blit288_16 ANOP
         TCD        ; Set DP $0000
         ADC #151
         TCS        ; Set S  $0097
         PEI $96
         PEI $94
         PEI $92
         PEI $90
         ADC #160
         TCS        ; Set S  $0137
         ADC #-55
         TCD        ; Set DP $0100
         PEI $36
         PEI $34
         PEI $32
         PEI $30
         ADC #214
         TCS        ; Set S  $01D7
         PEI $D6
         PEI $D4
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $0277
         ADC #-119
         TCD        ; Set DP $0200
         PEI $76
         PEI $74
         PEI $72
         PEI $70
         ADC #278
         TCS        ; Set S  $0317
         ADC #-23
         TCD        ; Set DP $0300
         PEI $16
         PEI $14
         PEI $12
         PEI $10
         ADC #182
         TCS        ; Set S  $03B7
         PEI $B6
         PEI $B4
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $0457
         ADC #-87
         TCD        ; Set DP $0400
         PEI $56
         PEI $54
         PEI $52
         PEI $50
         ADC #246
         TCS        ; Set S  $04F7
         PEI $F6
         PEI $F4
         PEI $F2
         PEI $F0
         JMP BRET   ;257 cycles
blit296_16 ANOP
         TCD        ; Set DP $0000
         ADC #155
         TCS        ; Set S  $009B
         PEI $9A
         PEI $98
         PEI $96
         PEI $94
         ADC #160
         TCS        ; Set S  $013B
         ADC #-59
         TCD        ; Set DP $0100
         PEI $3A
         PEI $38
         PEI $36
         PEI $34
         ADC #218
         TCS        ; Set S  $01DB
         PEI $DA
         PEI $D8
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $027B
         ADC #-123
         TCD        ; Set DP $0200
         PEI $7A
         PEI $78
         PEI $76
         PEI $74
         ADC #282
         TCS        ; Set S  $031B
         ADC #-27
         TCD        ; Set DP $0300
         PEI $1A
         PEI $18
         PEI $16
         PEI $14
         ADC #186
         TCS        ; Set S  $03BB
         PEI $BA
         PEI $B8
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $045B
         ADC #-91
         TCD        ; Set DP $0400
         PEI $5A
         PEI $58
         PEI $56
         PEI $54
         ADC #250
         TCS        ; Set S  $04FB
         PEI $FA
         PEI $F8
         PEI $F6
         PEI $F4
         JMP BRET   ;257 cycles
blit304_16 ANOP
         TCD        ; Set DP $0000
         ADC #159
         TCS        ; Set S  $009F
         PEI $9E
         PEI $9C
         PEI $9A
         PEI $98
         ADC #160
         TCS        ; Set S  $013F
         ADC #-63
         TCD        ; Set DP $0100
         PEI $3E
         PEI $3C
         PEI $3A
         PEI $38
         ADC #222
         TCS        ; Set S  $01DF
         PEI $DE
         PEI $DC
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $027F
         ADC #-127
         TCD        ; Set DP $0200
         PEI $7E
         PEI $7C
         PEI $7A
         PEI $78
         ADC #286
         TCS        ; Set S  $031F
         ADC #-31
         TCD        ; Set DP $0300
         PEI $1E
         PEI $1C
         PEI $1A
         PEI $18
         ADC #190
         TCS        ; Set S  $03BF
         PEI $BE
         PEI $BC
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $045F
         ADC #-95
         TCD        ; Set DP $0400
         PEI $5E
         PEI $5C
         PEI $5A
         PEI $58
         ADC #254
         TCS        ; Set S  $04FF
         PEI $FE
         PEI $FC
         PEI $FA
         PEI $F8
         JMP BRET   ;257 cycles
blit0_8 ANOP
         TCD        ; Set DP $0000
         ADC #3
         TCS        ; Set S  $0003
         PEI $02
         PEI $00
         ADC #160
         TCS        ; Set S  $00A3
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $0143
         ADC #-67
         TCD        ; Set DP $0100
         PEI $42
         PEI $40
         ADC #226
         TCS        ; Set S  $01E3
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $0283
         ADC #-131
         TCD        ; Set DP $0200
         PEI $82
         PEI $80
         ADC #290
         TCS        ; Set S  $0323
         ADC #-35
         TCD        ; Set DP $0300
         PEI $22
         PEI $20
         ADC #194
         TCS        ; Set S  $03C3
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $0463
         ADC #-99
         TCD        ; Set DP $0400
         PEI $62
         PEI $60
         JMP BRET   ;161 cycles
blit8_8 ANOP
         TCD        ; Set DP $0000
         ADC #7
         TCS        ; Set S  $0007
         PEI $06
         PEI $04
         ADC #160
         TCS        ; Set S  $00A7
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $0147
         ADC #-71
         TCD        ; Set DP $0100
         PEI $46
         PEI $44
         ADC #230
         TCS        ; Set S  $01E7
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $0287
         ADC #-135
         TCD        ; Set DP $0200
         PEI $86
         PEI $84
         ADC #294
         TCS        ; Set S  $0327
         ADC #-39
         TCD        ; Set DP $0300
         PEI $26
         PEI $24
         ADC #198
         TCS        ; Set S  $03C7
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $0467
         ADC #-103
         TCD        ; Set DP $0400
         PEI $66
         PEI $64
         JMP BRET   ;161 cycles
blit16_8 ANOP
         TCD        ; Set DP $0000
         ADC #11
         TCS        ; Set S  $000B
         PEI $0A
         PEI $08
         ADC #160
         TCS        ; Set S  $00AB
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $014B
         ADC #-75
         TCD        ; Set DP $0100
         PEI $4A
         PEI $48
         ADC #234
         TCS        ; Set S  $01EB
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $028B
         ADC #-139
         TCD        ; Set DP $0200
         PEI $8A
         PEI $88
         ADC #298
         TCS        ; Set S  $032B
         ADC #-43
         TCD        ; Set DP $0300
         PEI $2A
         PEI $28
         ADC #202
         TCS        ; Set S  $03CB
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $046B
         ADC #-107
         TCD        ; Set DP $0400
         PEI $6A
         PEI $68
         JMP BRET   ;161 cycles
blit24_8 ANOP
         TCD        ; Set DP $0000
         ADC #15
         TCS        ; Set S  $000F
         PEI $0E
         PEI $0C
         ADC #160
         TCS        ; Set S  $00AF
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $014F
         ADC #-79
         TCD        ; Set DP $0100
         PEI $4E
         PEI $4C
         ADC #238
         TCS        ; Set S  $01EF
         PEI $EE
         PEI $EC
         ADC #160
         TCS        ; Set S  $028F
         ADC #-143
         TCD        ; Set DP $0200
         PEI $8E
         PEI $8C
         ADC #302
         TCS        ; Set S  $032F
         ADC #-47
         TCD        ; Set DP $0300
         PEI $2E
         PEI $2C
         ADC #206
         TCS        ; Set S  $03CF
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $046F
         ADC #-111
         TCD        ; Set DP $0400
         PEI $6E
         PEI $6C
         JMP BRET   ;161 cycles
blit32_8 ANOP
         TCD        ; Set DP $0000
         ADC #19
         TCS        ; Set S  $0013
         PEI $12
         PEI $10
         ADC #160
         TCS        ; Set S  $00B3
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $0153
         ADC #-83
         TCD        ; Set DP $0100
         PEI $52
         PEI $50
         ADC #242
         TCS        ; Set S  $01F3
         PEI $F2
         PEI $F0
         ADC #160
         TCS        ; Set S  $0293
         ADC #-147
         TCD        ; Set DP $0200
         PEI $92
         PEI $90
         ADC #306
         TCS        ; Set S  $0333
         ADC #-51
         TCD        ; Set DP $0300
         PEI $32
         PEI $30
         ADC #210
         TCS        ; Set S  $03D3
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $0473
         ADC #-115
         TCD        ; Set DP $0400
         PEI $72
         PEI $70
         JMP BRET   ;161 cycles
blit40_8 ANOP
         TCD        ; Set DP $0000
         ADC #23
         TCS        ; Set S  $0017
         PEI $16
         PEI $14
         ADC #160
         TCS        ; Set S  $00B7
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $0157
         ADC #-87
         TCD        ; Set DP $0100
         PEI $56
         PEI $54
         ADC #246
         TCS        ; Set S  $01F7
         PEI $F6
         PEI $F4
         ADC #160
         TCS        ; Set S  $0297
         ADC #-151
         TCD        ; Set DP $0200
         PEI $96
         PEI $94
         ADC #310
         TCS        ; Set S  $0337
         ADC #-55
         TCD        ; Set DP $0300
         PEI $36
         PEI $34
         ADC #214
         TCS        ; Set S  $03D7
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $0477
         ADC #-119
         TCD        ; Set DP $0400
         PEI $76
         PEI $74
         JMP BRET   ;161 cycles
blit48_8 ANOP
         TCD        ; Set DP $0000
         ADC #27
         TCS        ; Set S  $001B
         PEI $1A
         PEI $18
         ADC #160
         TCS        ; Set S  $00BB
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $015B
         ADC #-91
         TCD        ; Set DP $0100
         PEI $5A
         PEI $58
         ADC #250
         TCS        ; Set S  $01FB
         PEI $FA
         PEI $F8
         ADC #160
         TCS        ; Set S  $029B
         ADC #-155
         TCD        ; Set DP $0200
         PEI $9A
         PEI $98
         ADC #314
         TCS        ; Set S  $033B
         ADC #-59
         TCD        ; Set DP $0300
         PEI $3A
         PEI $38
         ADC #218
         TCS        ; Set S  $03DB
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $047B
         ADC #-123
         TCD        ; Set DP $0400
         PEI $7A
         PEI $78
         JMP BRET   ;161 cycles
blit56_8 ANOP
         TCD        ; Set DP $0000
         ADC #31
         TCS        ; Set S  $001F
         PEI $1E
         PEI $1C
         ADC #160
         TCS        ; Set S  $00BF
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $015F
         ADC #-95
         TCD        ; Set DP $0100
         PEI $5E
         PEI $5C
         ADC #254
         TCS        ; Set S  $01FF
         PEI $FE
         PEI $FC
         ADC #160
         TCS        ; Set S  $029F
         ADC #-159
         TCD        ; Set DP $0200
         PEI $9E
         PEI $9C
         ADC #318
         TCS        ; Set S  $033F
         ADC #-63
         TCD        ; Set DP $0300
         PEI $3E
         PEI $3C
         ADC #222
         TCS        ; Set S  $03DF
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $047F
         ADC #-127
         TCD        ; Set DP $0400
         PEI $7E
         PEI $7C
         JMP BRET   ;161 cycles
blit64_8 ANOP
         TCD        ; Set DP $0000
         ADC #35
         TCS        ; Set S  $0023
         PEI $22
         PEI $20
         ADC #160
         TCS        ; Set S  $00C3
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $0163
         ADC #-99
         TCD        ; Set DP $0100
         PEI $62
         PEI $60
         ADC #258
         TCS        ; Set S  $0203
         ADC #-3
         TCD        ; Set DP $0200
         PEI $02
         PEI $00
         ADC #162
         TCS        ; Set S  $02A3
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $0343
         ADC #-67
         TCD        ; Set DP $0300
         PEI $42
         PEI $40
         ADC #226
         TCS        ; Set S  $03E3
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $0483
         ADC #-131
         TCD        ; Set DP $0400
         PEI $82
         PEI $80
         JMP BRET   ;161 cycles
blit72_8 ANOP
         TCD        ; Set DP $0000
         ADC #39
         TCS        ; Set S  $0027
         PEI $26
         PEI $24
         ADC #160
         TCS        ; Set S  $00C7
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $0167
         ADC #-103
         TCD        ; Set DP $0100
         PEI $66
         PEI $64
         ADC #262
         TCS        ; Set S  $0207
         ADC #-7
         TCD        ; Set DP $0200
         PEI $06
         PEI $04
         ADC #166
         TCS        ; Set S  $02A7
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $0347
         ADC #-71
         TCD        ; Set DP $0300
         PEI $46
         PEI $44
         ADC #230
         TCS        ; Set S  $03E7
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $0487
         ADC #-135
         TCD        ; Set DP $0400
         PEI $86
         PEI $84
         JMP BRET   ;161 cycles
blit80_8 ANOP
         TCD        ; Set DP $0000
         ADC #43
         TCS        ; Set S  $002B
         PEI $2A
         PEI $28
         ADC #160
         TCS        ; Set S  $00CB
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $016B
         ADC #-107
         TCD        ; Set DP $0100
         PEI $6A
         PEI $68
         ADC #266
         TCS        ; Set S  $020B
         ADC #-11
         TCD        ; Set DP $0200
         PEI $0A
         PEI $08
         ADC #170
         TCS        ; Set S  $02AB
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $034B
         ADC #-75
         TCD        ; Set DP $0300
         PEI $4A
         PEI $48
         ADC #234
         TCS        ; Set S  $03EB
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $048B
         ADC #-139
         TCD        ; Set DP $0400
         PEI $8A
         PEI $88
         JMP BRET   ;161 cycles
blit88_8 ANOP
         TCD        ; Set DP $0000
         ADC #47
         TCS        ; Set S  $002F
         PEI $2E
         PEI $2C
         ADC #160
         TCS        ; Set S  $00CF
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $016F
         ADC #-111
         TCD        ; Set DP $0100
         PEI $6E
         PEI $6C
         ADC #270
         TCS        ; Set S  $020F
         ADC #-15
         TCD        ; Set DP $0200
         PEI $0E
         PEI $0C
         ADC #174
         TCS        ; Set S  $02AF
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $034F
         ADC #-79
         TCD        ; Set DP $0300
         PEI $4E
         PEI $4C
         ADC #238
         TCS        ; Set S  $03EF
         PEI $EE
         PEI $EC
         ADC #160
         TCS        ; Set S  $048F
         ADC #-143
         TCD        ; Set DP $0400
         PEI $8E
         PEI $8C
         JMP BRET   ;161 cycles
blit96_8 ANOP
         TCD        ; Set DP $0000
         ADC #51
         TCS        ; Set S  $0033
         PEI $32
         PEI $30
         ADC #160
         TCS        ; Set S  $00D3
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $0173
         ADC #-115
         TCD        ; Set DP $0100
         PEI $72
         PEI $70
         ADC #274
         TCS        ; Set S  $0213
         ADC #-19
         TCD        ; Set DP $0200
         PEI $12
         PEI $10
         ADC #178
         TCS        ; Set S  $02B3
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $0353
         ADC #-83
         TCD        ; Set DP $0300
         PEI $52
         PEI $50
         ADC #242
         TCS        ; Set S  $03F3
         PEI $F2
         PEI $F0
         ADC #160
         TCS        ; Set S  $0493
         ADC #-147
         TCD        ; Set DP $0400
         PEI $92
         PEI $90
         JMP BRET   ;161 cycles
blit104_8 ANOP
         TCD        ; Set DP $0000
         ADC #55
         TCS        ; Set S  $0037
         PEI $36
         PEI $34
         ADC #160
         TCS        ; Set S  $00D7
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $0177
         ADC #-119
         TCD        ; Set DP $0100
         PEI $76
         PEI $74
         ADC #278
         TCS        ; Set S  $0217
         ADC #-23
         TCD        ; Set DP $0200
         PEI $16
         PEI $14
         ADC #182
         TCS        ; Set S  $02B7
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $0357
         ADC #-87
         TCD        ; Set DP $0300
         PEI $56
         PEI $54
         ADC #246
         TCS        ; Set S  $03F7
         PEI $F6
         PEI $F4
         ADC #160
         TCS        ; Set S  $0497
         ADC #-151
         TCD        ; Set DP $0400
         PEI $96
         PEI $94
         JMP BRET   ;161 cycles
blit112_8 ANOP
         TCD        ; Set DP $0000
         ADC #59
         TCS        ; Set S  $003B
         PEI $3A
         PEI $38
         ADC #160
         TCS        ; Set S  $00DB
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $017B
         ADC #-123
         TCD        ; Set DP $0100
         PEI $7A
         PEI $78
         ADC #282
         TCS        ; Set S  $021B
         ADC #-27
         TCD        ; Set DP $0200
         PEI $1A
         PEI $18
         ADC #186
         TCS        ; Set S  $02BB
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $035B
         ADC #-91
         TCD        ; Set DP $0300
         PEI $5A
         PEI $58
         ADC #250
         TCS        ; Set S  $03FB
         PEI $FA
         PEI $F8
         ADC #160
         TCS        ; Set S  $049B
         ADC #-155
         TCD        ; Set DP $0400
         PEI $9A
         PEI $98
         JMP BRET   ;161 cycles
blit120_8 ANOP
         TCD        ; Set DP $0000
         ADC #63
         TCS        ; Set S  $003F
         PEI $3E
         PEI $3C
         ADC #160
         TCS        ; Set S  $00DF
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $017F
         ADC #-127
         TCD        ; Set DP $0100
         PEI $7E
         PEI $7C
         ADC #286
         TCS        ; Set S  $021F
         ADC #-31
         TCD        ; Set DP $0200
         PEI $1E
         PEI $1C
         ADC #190
         TCS        ; Set S  $02BF
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $035F
         ADC #-95
         TCD        ; Set DP $0300
         PEI $5E
         PEI $5C
         ADC #254
         TCS        ; Set S  $03FF
         PEI $FE
         PEI $FC
         ADC #160
         TCS        ; Set S  $049F
         ADC #-159
         TCD        ; Set DP $0400
         PEI $9E
         PEI $9C
         JMP BRET   ;161 cycles
blit128_8 ANOP
         TCD        ; Set DP $0000
         ADC #67
         TCS        ; Set S  $0043
         PEI $42
         PEI $40
         ADC #160
         TCS        ; Set S  $00E3
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $0183
         ADC #-131
         TCD        ; Set DP $0100
         PEI $82
         PEI $80
         ADC #290
         TCS        ; Set S  $0223
         ADC #-35
         TCD        ; Set DP $0200
         PEI $22
         PEI $20
         ADC #194
         TCS        ; Set S  $02C3
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $0363
         ADC #-99
         TCD        ; Set DP $0300
         PEI $62
         PEI $60
         ADC #258
         TCS        ; Set S  $0403
         ADC #-3
         TCD        ; Set DP $0400
         PEI $02
         PEI $00
         ADC #162
         TCS        ; Set S  $04A3
         PEI $A2
         PEI $A0
         JMP BRET   ;161 cycles
blit136_8 ANOP
         TCD        ; Set DP $0000
         ADC #71
         TCS        ; Set S  $0047
         PEI $46
         PEI $44
         ADC #160
         TCS        ; Set S  $00E7
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $0187
         ADC #-135
         TCD        ; Set DP $0100
         PEI $86
         PEI $84
         ADC #294
         TCS        ; Set S  $0227
         ADC #-39
         TCD        ; Set DP $0200
         PEI $26
         PEI $24
         ADC #198
         TCS        ; Set S  $02C7
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $0367
         ADC #-103
         TCD        ; Set DP $0300
         PEI $66
         PEI $64
         ADC #262
         TCS        ; Set S  $0407
         ADC #-7
         TCD        ; Set DP $0400
         PEI $06
         PEI $04
         ADC #166
         TCS        ; Set S  $04A7
         PEI $A6
         PEI $A4
         JMP BRET   ;161 cycles
blit144_8 ANOP
         TCD        ; Set DP $0000
         ADC #75
         TCS        ; Set S  $004B
         PEI $4A
         PEI $48
         ADC #160
         TCS        ; Set S  $00EB
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $018B
         ADC #-139
         TCD        ; Set DP $0100
         PEI $8A
         PEI $88
         ADC #298
         TCS        ; Set S  $022B
         ADC #-43
         TCD        ; Set DP $0200
         PEI $2A
         PEI $28
         ADC #202
         TCS        ; Set S  $02CB
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $036B
         ADC #-107
         TCD        ; Set DP $0300
         PEI $6A
         PEI $68
         ADC #266
         TCS        ; Set S  $040B
         ADC #-11
         TCD        ; Set DP $0400
         PEI $0A
         PEI $08
         ADC #170
         TCS        ; Set S  $04AB
         PEI $AA
         PEI $A8
         JMP BRET   ;161 cycles
blit152_8 ANOP
         TCD        ; Set DP $0000
         ADC #79
         TCS        ; Set S  $004F
         PEI $4E
         PEI $4C
         ADC #160
         TCS        ; Set S  $00EF
         PEI $EE
         PEI $EC
         ADC #160
         TCS        ; Set S  $018F
         ADC #-143
         TCD        ; Set DP $0100
         PEI $8E
         PEI $8C
         ADC #302
         TCS        ; Set S  $022F
         ADC #-47
         TCD        ; Set DP $0200
         PEI $2E
         PEI $2C
         ADC #206
         TCS        ; Set S  $02CF
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $036F
         ADC #-111
         TCD        ; Set DP $0300
         PEI $6E
         PEI $6C
         ADC #270
         TCS        ; Set S  $040F
         ADC #-15
         TCD        ; Set DP $0400
         PEI $0E
         PEI $0C
         ADC #174
         TCS        ; Set S  $04AF
         PEI $AE
         PEI $AC
         JMP BRET   ;161 cycles
blit160_8 ANOP
         TCD        ; Set DP $0000
         ADC #83
         TCS        ; Set S  $0053
         PEI $52
         PEI $50
         ADC #160
         TCS        ; Set S  $00F3
         PEI $F2
         PEI $F0
         ADC #160
         TCS        ; Set S  $0193
         ADC #-147
         TCD        ; Set DP $0100
         PEI $92
         PEI $90
         ADC #306
         TCS        ; Set S  $0233
         ADC #-51
         TCD        ; Set DP $0200
         PEI $32
         PEI $30
         ADC #210
         TCS        ; Set S  $02D3
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $0373
         ADC #-115
         TCD        ; Set DP $0300
         PEI $72
         PEI $70
         ADC #274
         TCS        ; Set S  $0413
         ADC #-19
         TCD        ; Set DP $0400
         PEI $12
         PEI $10
         ADC #178
         TCS        ; Set S  $04B3
         PEI $B2
         PEI $B0
         JMP BRET   ;161 cycles
blit168_8 ANOP
         TCD        ; Set DP $0000
         ADC #87
         TCS        ; Set S  $0057
         PEI $56
         PEI $54
         ADC #160
         TCS        ; Set S  $00F7
         PEI $F6
         PEI $F4
         ADC #160
         TCS        ; Set S  $0197
         ADC #-151
         TCD        ; Set DP $0100
         PEI $96
         PEI $94
         ADC #310
         TCS        ; Set S  $0237
         ADC #-55
         TCD        ; Set DP $0200
         PEI $36
         PEI $34
         ADC #214
         TCS        ; Set S  $02D7
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $0377
         ADC #-119
         TCD        ; Set DP $0300
         PEI $76
         PEI $74
         ADC #278
         TCS        ; Set S  $0417
         ADC #-23
         TCD        ; Set DP $0400
         PEI $16
         PEI $14
         ADC #182
         TCS        ; Set S  $04B7
         PEI $B6
         PEI $B4
         JMP BRET   ;161 cycles
blit176_8 ANOP
         TCD        ; Set DP $0000
         ADC #91
         TCS        ; Set S  $005B
         PEI $5A
         PEI $58
         ADC #160
         TCS        ; Set S  $00FB
         PEI $FA
         PEI $F8
         ADC #160
         TCS        ; Set S  $019B
         ADC #-155
         TCD        ; Set DP $0100
         PEI $9A
         PEI $98
         ADC #314
         TCS        ; Set S  $023B
         ADC #-59
         TCD        ; Set DP $0200
         PEI $3A
         PEI $38
         ADC #218
         TCS        ; Set S  $02DB
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $037B
         ADC #-123
         TCD        ; Set DP $0300
         PEI $7A
         PEI $78
         ADC #282
         TCS        ; Set S  $041B
         ADC #-27
         TCD        ; Set DP $0400
         PEI $1A
         PEI $18
         ADC #186
         TCS        ; Set S  $04BB
         PEI $BA
         PEI $B8
         JMP BRET   ;161 cycles
blit184_8 ANOP
         TCD        ; Set DP $0000
         ADC #95
         TCS        ; Set S  $005F
         PEI $5E
         PEI $5C
         ADC #160
         TCS        ; Set S  $00FF
         PEI $FE
         PEI $FC
         ADC #160
         TCS        ; Set S  $019F
         ADC #-159
         TCD        ; Set DP $0100
         PEI $9E
         PEI $9C
         ADC #318
         TCS        ; Set S  $023F
         ADC #-63
         TCD        ; Set DP $0200
         PEI $3E
         PEI $3C
         ADC #222
         TCS        ; Set S  $02DF
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $037F
         ADC #-127
         TCD        ; Set DP $0300
         PEI $7E
         PEI $7C
         ADC #286
         TCS        ; Set S  $041F
         ADC #-31
         TCD        ; Set DP $0400
         PEI $1E
         PEI $1C
         ADC #190
         TCS        ; Set S  $04BF
         PEI $BE
         PEI $BC
         JMP BRET   ;161 cycles
blit192_8 ANOP
         TCD        ; Set DP $0000
         ADC #99
         TCS        ; Set S  $0063
         PEI $62
         PEI $60
         ADC #160
         TCS        ; Set S  $0103
         ADC #-3
         TCD        ; Set DP $0100
         PEI $02
         PEI $00
         ADC #162
         TCS        ; Set S  $01A3
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $0243
         ADC #-67
         TCD        ; Set DP $0200
         PEI $42
         PEI $40
         ADC #226
         TCS        ; Set S  $02E3
         PEI $E2
         PEI $E0
         ADC #160
         TCS        ; Set S  $0383
         ADC #-131
         TCD        ; Set DP $0300
         PEI $82
         PEI $80
         ADC #290
         TCS        ; Set S  $0423
         ADC #-35
         TCD        ; Set DP $0400
         PEI $22
         PEI $20
         ADC #194
         TCS        ; Set S  $04C3
         PEI $C2
         PEI $C0
         JMP BRET   ;161 cycles
blit200_8 ANOP
         TCD        ; Set DP $0000
         ADC #103
         TCS        ; Set S  $0067
         PEI $66
         PEI $64
         ADC #160
         TCS        ; Set S  $0107
         ADC #-7
         TCD        ; Set DP $0100
         PEI $06
         PEI $04
         ADC #166
         TCS        ; Set S  $01A7
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $0247
         ADC #-71
         TCD        ; Set DP $0200
         PEI $46
         PEI $44
         ADC #230
         TCS        ; Set S  $02E7
         PEI $E6
         PEI $E4
         ADC #160
         TCS        ; Set S  $0387
         ADC #-135
         TCD        ; Set DP $0300
         PEI $86
         PEI $84
         ADC #294
         TCS        ; Set S  $0427
         ADC #-39
         TCD        ; Set DP $0400
         PEI $26
         PEI $24
         ADC #198
         TCS        ; Set S  $04C7
         PEI $C6
         PEI $C4
         JMP BRET   ;161 cycles
blit208_8 ANOP
         TCD        ; Set DP $0000
         ADC #107
         TCS        ; Set S  $006B
         PEI $6A
         PEI $68
         ADC #160
         TCS        ; Set S  $010B
         ADC #-11
         TCD        ; Set DP $0100
         PEI $0A
         PEI $08
         ADC #170
         TCS        ; Set S  $01AB
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $024B
         ADC #-75
         TCD        ; Set DP $0200
         PEI $4A
         PEI $48
         ADC #234
         TCS        ; Set S  $02EB
         PEI $EA
         PEI $E8
         ADC #160
         TCS        ; Set S  $038B
         ADC #-139
         TCD        ; Set DP $0300
         PEI $8A
         PEI $88
         ADC #298
         TCS        ; Set S  $042B
         ADC #-43
         TCD        ; Set DP $0400
         PEI $2A
         PEI $28
         ADC #202
         TCS        ; Set S  $04CB
         PEI $CA
         PEI $C8
         JMP BRET   ;161 cycles
blit216_8 ANOP
         TCD        ; Set DP $0000
         ADC #111
         TCS        ; Set S  $006F
         PEI $6E
         PEI $6C
         ADC #160
         TCS        ; Set S  $010F
         ADC #-15
         TCD        ; Set DP $0100
         PEI $0E
         PEI $0C
         ADC #174
         TCS        ; Set S  $01AF
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $024F
         ADC #-79
         TCD        ; Set DP $0200
         PEI $4E
         PEI $4C
         ADC #238
         TCS        ; Set S  $02EF
         PEI $EE
         PEI $EC
         ADC #160
         TCS        ; Set S  $038F
         ADC #-143
         TCD        ; Set DP $0300
         PEI $8E
         PEI $8C
         ADC #302
         TCS        ; Set S  $042F
         ADC #-47
         TCD        ; Set DP $0400
         PEI $2E
         PEI $2C
         ADC #206
         TCS        ; Set S  $04CF
         PEI $CE
         PEI $CC
         JMP BRET   ;161 cycles
blit224_8 ANOP
         TCD        ; Set DP $0000
         ADC #115
         TCS        ; Set S  $0073
         PEI $72
         PEI $70
         ADC #160
         TCS        ; Set S  $0113
         ADC #-19
         TCD        ; Set DP $0100
         PEI $12
         PEI $10
         ADC #178
         TCS        ; Set S  $01B3
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $0253
         ADC #-83
         TCD        ; Set DP $0200
         PEI $52
         PEI $50
         ADC #242
         TCS        ; Set S  $02F3
         PEI $F2
         PEI $F0
         ADC #160
         TCS        ; Set S  $0393
         ADC #-147
         TCD        ; Set DP $0300
         PEI $92
         PEI $90
         ADC #306
         TCS        ; Set S  $0433
         ADC #-51
         TCD        ; Set DP $0400
         PEI $32
         PEI $30
         ADC #210
         TCS        ; Set S  $04D3
         PEI $D2
         PEI $D0
         JMP BRET   ;161 cycles
blit232_8 ANOP
         TCD        ; Set DP $0000
         ADC #119
         TCS        ; Set S  $0077
         PEI $76
         PEI $74
         ADC #160
         TCS        ; Set S  $0117
         ADC #-23
         TCD        ; Set DP $0100
         PEI $16
         PEI $14
         ADC #182
         TCS        ; Set S  $01B7
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $0257
         ADC #-87
         TCD        ; Set DP $0200
         PEI $56
         PEI $54
         ADC #246
         TCS        ; Set S  $02F7
         PEI $F6
         PEI $F4
         ADC #160
         TCS        ; Set S  $0397
         ADC #-151
         TCD        ; Set DP $0300
         PEI $96
         PEI $94
         ADC #310
         TCS        ; Set S  $0437
         ADC #-55
         TCD        ; Set DP $0400
         PEI $36
         PEI $34
         ADC #214
         TCS        ; Set S  $04D7
         PEI $D6
         PEI $D4
         JMP BRET   ;161 cycles
blit240_8 ANOP
         TCD        ; Set DP $0000
         ADC #123
         TCS        ; Set S  $007B
         PEI $7A
         PEI $78
         ADC #160
         TCS        ; Set S  $011B
         ADC #-27
         TCD        ; Set DP $0100
         PEI $1A
         PEI $18
         ADC #186
         TCS        ; Set S  $01BB
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $025B
         ADC #-91
         TCD        ; Set DP $0200
         PEI $5A
         PEI $58
         ADC #250
         TCS        ; Set S  $02FB
         PEI $FA
         PEI $F8
         ADC #160
         TCS        ; Set S  $039B
         ADC #-155
         TCD        ; Set DP $0300
         PEI $9A
         PEI $98
         ADC #314
         TCS        ; Set S  $043B
         ADC #-59
         TCD        ; Set DP $0400
         PEI $3A
         PEI $38
         ADC #218
         TCS        ; Set S  $04DB
         PEI $DA
         PEI $D8
         JMP BRET   ;161 cycles
blit248_8 ANOP
         TCD        ; Set DP $0000
         ADC #127
         TCS        ; Set S  $007F
         PEI $7E
         PEI $7C
         ADC #160
         TCS        ; Set S  $011F
         ADC #-31
         TCD        ; Set DP $0100
         PEI $1E
         PEI $1C
         ADC #190
         TCS        ; Set S  $01BF
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $025F
         ADC #-95
         TCD        ; Set DP $0200
         PEI $5E
         PEI $5C
         ADC #254
         TCS        ; Set S  $02FF
         PEI $FE
         PEI $FC
         ADC #160
         TCS        ; Set S  $039F
         ADC #-159
         TCD        ; Set DP $0300
         PEI $9E
         PEI $9C
         ADC #318
         TCS        ; Set S  $043F
         ADC #-63
         TCD        ; Set DP $0400
         PEI $3E
         PEI $3C
         ADC #222
         TCS        ; Set S  $04DF
         PEI $DE
         PEI $DC
         JMP BRET   ;161 cycles
blit256_8 ANOP
         TCD        ; Set DP $0000
         ADC #131
         TCS        ; Set S  $0083
         PEI $82
         PEI $80
         ADC #160
         TCS        ; Set S  $0123
         ADC #-35
         TCD        ; Set DP $0100
         PEI $22
         PEI $20
         ADC #194
         TCS        ; Set S  $01C3
         PEI $C2
         PEI $C0
         ADC #160
         TCS        ; Set S  $0263
         ADC #-99
         TCD        ; Set DP $0200
         PEI $62
         PEI $60
         ADC #258
         TCS        ; Set S  $0303
         ADC #-3
         TCD        ; Set DP $0300
         PEI $02
         PEI $00
         ADC #162
         TCS        ; Set S  $03A3
         PEI $A2
         PEI $A0
         ADC #160
         TCS        ; Set S  $0443
         ADC #-67
         TCD        ; Set DP $0400
         PEI $42
         PEI $40
         ADC #226
         TCS        ; Set S  $04E3
         PEI $E2
         PEI $E0
         JMP BRET   ;161 cycles
blit264_8 ANOP
         TCD        ; Set DP $0000
         ADC #135
         TCS        ; Set S  $0087
         PEI $86
         PEI $84
         ADC #160
         TCS        ; Set S  $0127
         ADC #-39
         TCD        ; Set DP $0100
         PEI $26
         PEI $24
         ADC #198
         TCS        ; Set S  $01C7
         PEI $C6
         PEI $C4
         ADC #160
         TCS        ; Set S  $0267
         ADC #-103
         TCD        ; Set DP $0200
         PEI $66
         PEI $64
         ADC #262
         TCS        ; Set S  $0307
         ADC #-7
         TCD        ; Set DP $0300
         PEI $06
         PEI $04
         ADC #166
         TCS        ; Set S  $03A7
         PEI $A6
         PEI $A4
         ADC #160
         TCS        ; Set S  $0447
         ADC #-71
         TCD        ; Set DP $0400
         PEI $46
         PEI $44
         ADC #230
         TCS        ; Set S  $04E7
         PEI $E6
         PEI $E4
         JMP BRET   ;161 cycles
blit272_8 ANOP
         TCD        ; Set DP $0000
         ADC #139
         TCS        ; Set S  $008B
         PEI $8A
         PEI $88
         ADC #160
         TCS        ; Set S  $012B
         ADC #-43
         TCD        ; Set DP $0100
         PEI $2A
         PEI $28
         ADC #202
         TCS        ; Set S  $01CB
         PEI $CA
         PEI $C8
         ADC #160
         TCS        ; Set S  $026B
         ADC #-107
         TCD        ; Set DP $0200
         PEI $6A
         PEI $68
         ADC #266
         TCS        ; Set S  $030B
         ADC #-11
         TCD        ; Set DP $0300
         PEI $0A
         PEI $08
         ADC #170
         TCS        ; Set S  $03AB
         PEI $AA
         PEI $A8
         ADC #160
         TCS        ; Set S  $044B
         ADC #-75
         TCD        ; Set DP $0400
         PEI $4A
         PEI $48
         ADC #234
         TCS        ; Set S  $04EB
         PEI $EA
         PEI $E8
         JMP BRET   ;161 cycles
blit280_8 ANOP
         TCD        ; Set DP $0000
         ADC #143
         TCS        ; Set S  $008F
         PEI $8E
         PEI $8C
         ADC #160
         TCS        ; Set S  $012F
         ADC #-47
         TCD        ; Set DP $0100
         PEI $2E
         PEI $2C
         ADC #206
         TCS        ; Set S  $01CF
         PEI $CE
         PEI $CC
         ADC #160
         TCS        ; Set S  $026F
         ADC #-111
         TCD        ; Set DP $0200
         PEI $6E
         PEI $6C
         ADC #270
         TCS        ; Set S  $030F
         ADC #-15
         TCD        ; Set DP $0300
         PEI $0E
         PEI $0C
         ADC #174
         TCS        ; Set S  $03AF
         PEI $AE
         PEI $AC
         ADC #160
         TCS        ; Set S  $044F
         ADC #-79
         TCD        ; Set DP $0400
         PEI $4E
         PEI $4C
         ADC #238
         TCS        ; Set S  $04EF
         PEI $EE
         PEI $EC
         JMP BRET   ;161 cycles
blit288_8 ANOP
         TCD        ; Set DP $0000
         ADC #147
         TCS        ; Set S  $0093
         PEI $92
         PEI $90
         ADC #160
         TCS        ; Set S  $0133
         ADC #-51
         TCD        ; Set DP $0100
         PEI $32
         PEI $30
         ADC #210
         TCS        ; Set S  $01D3
         PEI $D2
         PEI $D0
         ADC #160
         TCS        ; Set S  $0273
         ADC #-115
         TCD        ; Set DP $0200
         PEI $72
         PEI $70
         ADC #274
         TCS        ; Set S  $0313
         ADC #-19
         TCD        ; Set DP $0300
         PEI $12
         PEI $10
         ADC #178
         TCS        ; Set S  $03B3
         PEI $B2
         PEI $B0
         ADC #160
         TCS        ; Set S  $0453
         ADC #-83
         TCD        ; Set DP $0400
         PEI $52
         PEI $50
         ADC #242
         TCS        ; Set S  $04F3
         PEI $F2
         PEI $F0
         JMP BRET   ;161 cycles
blit296_8 ANOP
         TCD        ; Set DP $0000
         ADC #151
         TCS        ; Set S  $0097
         PEI $96
         PEI $94
         ADC #160
         TCS        ; Set S  $0137
         ADC #-55
         TCD        ; Set DP $0100
         PEI $36
         PEI $34
         ADC #214
         TCS        ; Set S  $01D7
         PEI $D6
         PEI $D4
         ADC #160
         TCS        ; Set S  $0277
         ADC #-119
         TCD        ; Set DP $0200
         PEI $76
         PEI $74
         ADC #278
         TCS        ; Set S  $0317
         ADC #-23
         TCD        ; Set DP $0300
         PEI $16
         PEI $14
         ADC #182
         TCS        ; Set S  $03B7
         PEI $B6
         PEI $B4
         ADC #160
         TCS        ; Set S  $0457
         ADC #-87
         TCD        ; Set DP $0400
         PEI $56
         PEI $54
         ADC #246
         TCS        ; Set S  $04F7
         PEI $F6
         PEI $F4
         JMP BRET   ;161 cycles
blit304_8 ANOP
         TCD        ; Set DP $0000
         ADC #155
         TCS        ; Set S  $009B
         PEI $9A
         PEI $98
         ADC #160
         TCS        ; Set S  $013B
         ADC #-59
         TCD        ; Set DP $0100
         PEI $3A
         PEI $38
         ADC #218
         TCS        ; Set S  $01DB
         PEI $DA
         PEI $D8
         ADC #160
         TCS        ; Set S  $027B
         ADC #-123
         TCD        ; Set DP $0200
         PEI $7A
         PEI $78
         ADC #282
         TCS        ; Set S  $031B
         ADC #-27
         TCD        ; Set DP $0300
         PEI $1A
         PEI $18
         ADC #186
         TCS        ; Set S  $03BB
         PEI $BA
         PEI $B8
         ADC #160
         TCS        ; Set S  $045B
         ADC #-91
         TCD        ; Set DP $0400
         PEI $5A
         PEI $58
         ADC #250
         TCS        ; Set S  $04FB
         PEI $FA
         PEI $F8
         JMP BRET   ;161 cycles
blit312_8 ANOP
         TCD        ; Set DP $0000
         ADC #159
         TCS        ; Set S  $009F
         PEI $9E
         PEI $9C
         ADC #160
         TCS        ; Set S  $013F
         ADC #-63
         TCD        ; Set DP $0100
         PEI $3E
         PEI $3C
         ADC #222
         TCS        ; Set S  $01DF
         PEI $DE
         PEI $DC
         ADC #160
         TCS        ; Set S  $027F
         ADC #-127
         TCD        ; Set DP $0200
         PEI $7E
         PEI $7C
         ADC #286
         TCS        ; Set S  $031F
         ADC #-31
         TCD        ; Set DP $0300
         PEI $1E
         PEI $1C
         ADC #190
         TCS        ; Set S  $03BF
         PEI $BE
         PEI $BC
         ADC #160
         TCS        ; Set S  $045F
         ADC #-95
         TCD        ; Set DP $0400
         PEI $5E
         PEI $5C
         ADC #254
         TCS        ; Set S  $04FF
         PEI $FE
         PEI $FC
         JMP BRET   ;161 cycles
	  
*-------------------------------------------------------------------------------
    end  	;; END BLITCODE
	
