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
	dc	i,'$013B'	; Frequency
	dc	b,'$2B'	; Address
	dc	b,'$00'	; Size
SND_BONUS anop
	dc	i,'$003D'	; Frequency
	dc	b,'$A0'	; Address
	dc	b,'$24'	; Size
SND_BOX anop
	dc	i,'$0039'	; Frequency
	dc	b,'$D0'	; Address
	dc	b,'$1B'	; Size
SND_BULLET anop
	dc	i,'$0033'	; Frequency
	dc	b,'$70'	; Address
	dc	b,'$24'	; Size
SND_CRAWL anop
	dc	i,'$005D'	; Frequency
	dc	b,'$9E'	; Address
	dc	b,'$09'	; Size
SND_DIE anop
	dc	i,'$0042'	; Frequency
	dc	b,'$90'	; Address
	dc	b,'$24'	; Size
SND_ENT0 anop
	dc	i,'$0065'	; Frequency
	dc	b,'$D8'	; Address
	dc	b,'$1B'	; Size
SND_ENT1 anop
	dc	i,'$0030'	; Frequency
	dc	b,'$30'	; Address
	dc	b,'$24'	; Size
SND_ENT2 anop
	dc	i,'$0032'	; Frequency
	dc	b,'$40'	; Address
	dc	b,'$24'	; Size
SND_ENT3 anop
	dc	i,'$0033'	; Frequency
	dc	b,'$80'	; Address
	dc	b,'$24'	; Size
SND_ENT4 anop
	dc	i,'$0036'	; Frequency
	dc	b,'$50'	; Address
	dc	b,'$24'	; Size
SND_ENT6 anop
	dc	i,'$006D'	; Frequency
	dc	b,'$E8'	; Address
	dc	b,'$1B'	; Size
SND_ENT8 anop
	dc	i,'$005D'	; Frequency
	dc	b,'$AC'	; Address
	dc	b,'$12'	; Size
SND_EXPLODE anop
	dc	i,'$0036'	; Frequency
	dc	b,'$B0'	; Address
	dc	b,'$24'	; Size
SND_JUMP anop
	dc	i,'$0072'	; Frequency
	dc	b,'$F0'	; Address
	dc	b,'$1B'	; Size
SND_PAD anop
	dc	i,'$003A'	; Frequency
	dc	b,'$E0'	; Address
	dc	b,'$1B'	; Size
SND_SBONUS1 anop
	dc	i,'$003D'	; Frequency
	dc	b,'$C0'	; Address
	dc	b,'$24'	; Size
SND_SBONUS2 anop
	dc	i,'$0041'	; Frequency
	dc	b,'$60'	; Address
	dc	b,'$24'	; Size
SND_STICK anop
	dc	i,'$0067'	; Frequency
	dc	b,'$2C'	; Address
	dc	b,'$12'	; Size
SND_WALK anop
	dc	i,'$007B'	; Frequency
	dc	b,'$AB'	; Address
	dc	b,'$00'	; Size

*-------------------------------------------------------------------------------
	end

