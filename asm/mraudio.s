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

pAudioBank equ 4
	lda 2,s
	sta pAudioBank+2,s
	lda 1,s
	sta pAudioBank+1,s

	pla
	pla
	rtl
*-------------------------------------------------------------------------------
	end
	
*
* void mraPlay(U8 sfxNo);
*
mraPlay start ASM_CODE
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

