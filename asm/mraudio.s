*
* ORCA/M Format!!
* Mr. Audio Interfaces
*
	case on
	longa on
	longi on

* How Dumb
mraDummy start ASM_CODE
	end


*
* void mraLoadBank(char* pAudioBank);
*
mraLoadBank start ASM_CODE

pAudioBank equ 5
	
	phb
	phk
	plb
	
* Get the pointer, and poke it into
* the fetch code

	lda pAudioBank,s
	sta |ReadByte+1
	lda pAudioBank+1,s
	sta |ReadByte+2
	
*
* Fix up Return Address
* 	
	lda 1,s
	sta pAudioBank,s
	lda 3,s
	sta pAudioBank+2,s
	pla
	pla
	 
	php
	sei
	phd
	
	lda #$c000
	tcd
	
	longi on
	longa off
	
	sep #$20
	lda >$E100CA	; RAM Volume
	and #%00001111  ; Leave Volume alone
	ora #%01100000  ; RAM with auto increment
	sta <$3C
	
*
* Clear our the entire DOC RAM, because
* Mr. Audio doesn't add play stop bytes
*
	stz <$3E	; Address Zero
	stz <$3F
	
	ldx #0
zeroloop ANOP
	stz <$3D
	dex
	bne zeroloop

* 1 byte, version # (should be zero)
* 1 byte, number of waves
* For each wave
*   1 byte address in DOC
*   2 byte, length of wave
*     wave data

	jsr ReadByte
	cmp #0
	bne BadVersion 	; If the version bad, don't try to upload wave
	
	lda #0
	xba
	jsr ReadByte
	tay		  ; Y is the countdown for the total number of Waves
	
* Now for each wave, load the address
   
WaveLoop ANOP   
	jsr ReadByte
	stz <$3E  		; DOC Addr Low
	sta <$3F    	; DOC Addr High

* Get the Length, of the Wave, and put it in X
	jsr ReadByte
	pha
	jsr ReadByte
	xba
	pla
	tax
	
* Copy the Wave Data	
	
CopyLoop ANOP
	jsr ReadByte
	sta <$3D
	dex
	bne CopyLoop
	
* Dec Wave Count, and move to next Wave	
	
	dey
	bne WaveLoop 

*
* Restore Registers, and return
*
BadVersion ANOP
	pld
	plp
	plb
	rtl

	longa off
	longi on
ReadByte lda >$0
	inc |ReadByte+1
	bne ReadReturn
	inc |ReadByte+2
ReadReturn rts

*-------------------------------------------------------------------------------
	end
	
	longa on
	longi on
	
*
* void mraPlay(U8 sfxNo);
*
mraPlay start ASM_CODE

* Stack offsets
iSfxNo equ 5

* Sound Play Register Value offsets
iFreq equ 0
iAddress equ 2
iSize equ 3

	phb
	phk
	plb
	
	lda iSfxNo,s
	asl a
	tax
	
	lda |AudioTable,x
	tax
	
	php
	sei
	phd
	lda #$C000
	tcd
	
	rep #$20
	longa off
	longi on
	
* Incrememnt the channel we're going to play on

* Setup Doc for Register Stores on the Appropriate channel

* copy Register Values from the play table

* play the audio
	
	pld
	plp
	longa on
	longi on
	
	lda 3,s
	sta iSfxNo,s
	lda 1,s
	sta iSfxNo-2,s
	
	pla
	plb

	rtl
*-------------------------------------------------------------------------------
	end


*
* Data Copy / Paste from Mr. Audio
*
*
* Mr. Audio DOC Register Data
* ORCA Syntax
*

AudioTable start ASM_CODE
	dc	a'SND_BOMBSHHT'
	dc	a'SND_BONUS'
	dc	a'SND_BOX'
	dc	a'SND_BULLET'
	dc	a'SND_CRAWL'
	dc	a'SND_DIE'
	dc	a'SND_ENT0'
	dc	a'SND_ENT1'
	dc	a'SND_ENT2'
	dc	a'SND_ENT3'
	dc	a'SND_ENT4'
	dc	a'SND_ENT6'
	dc	a'SND_ENT8'
	dc	a'SND_EXPLODE'
	dc	a'SND_JUMP'
	dc	a'SND_PAD'
	dc	a'SND_SBONUS1'
	dc	a'SND_SBONUS2'
	dc	a'SND_STICK'
	dc	a'SND_WALK'

SND_BOMBSHHT anop
	dc	i'$013B'	; Frequency
	dc	h'2B'	; Address
	dc	h'00'	; Size
SND_BONUS anop
	dc	i'$003D'	; Frequency
	dc	h'A0'	; Address
	dc	h'24'	; Size
SND_BOX anop
	dc	i'$0039'	; Frequency
	dc	h'D0'	; Address
	dc	h'1B'	; Size
SND_BULLET anop
	dc	i'$0033'	; Frequency
	dc	h'70'	; Address
	dc	h'24'	; Size
SND_CRAWL anop
	dc	i'$005D'	; Frequency
	dc	h'9E'	; Address
	dc	h'09'	; Size
SND_DIE anop
	dc	i'$0042'	; Frequency
	dc	h'90'	; Address
	dc	h'24'	; Size
SND_ENT0 anop
	dc	i'$0065'	; Frequency
	dc	h'D8'	; Address
	dc	h'1B'	; Size
SND_ENT1 anop
	dc	i'$0030'	; Frequency
	dc	h'30'	; Address
	dc	h'24'	; Size
SND_ENT2 anop
	dc	i'$0032'	; Frequency
	dc	h'40'	; Address
	dc	h'24'	; Size
SND_ENT3 anop
	dc	i'$0033'	; Frequency
	dc	h'80'	; Address
	dc	h'24'	; Size
SND_ENT4 anop
	dc	i'$0036'	; Frequency
	dc	h'50'	; Address
	dc	h'24'	; Size
SND_ENT6 anop
	dc	i'$006D'	; Frequency
	dc	h'E8'	; Address
	dc	h'1B'	; Size
SND_ENT8 anop
	dc	i'$005D'	; Frequency
	dc	h'AC'	; Address
	dc	h'12'	; Size
SND_EXPLODE anop
	dc	i'$0036'	; Frequency
	dc	h'B0'	; Address
	dc	h'24'	; Size
SND_JUMP anop
	dc	i'$0072'	; Frequency
	dc	h'F0'	; Address
	dc	h'1B'	; Size
SND_PAD anop
	dc	i'$003A'	; Frequency
	dc	h'E0'	; Address
	dc	h'1B'	; Size
SND_SBONUS1 anop
	dc	i'$003D'	; Frequency
	dc	h'C0'	; Address
	dc	h'24'	; Size
SND_SBONUS2 anop
	dc	i'$0041'	; Frequency
	dc	h'60'	; Address
	dc	h'24'	; Size
SND_STICK anop
	dc	i'$0067'	; Frequency
	dc	h'2C'	; Address
	dc	h'12'	; Size
SND_WALK anop
	dc	i'$007B'	; Frequency
	dc	h'AB'	; Address
	dc	h'00'	; Size

*-------------------------------------------------------------------------------
	end

