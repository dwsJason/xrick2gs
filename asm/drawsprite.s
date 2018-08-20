*
* ORCA/M Format!!
* Thunk from C to compiled draw things
*
 case on
 longa on
 longi on

Dummy4 start ASMCODE
	end
*-------------------------------------------------------------------------------
*
*void DrrawSprite(int offset, into SpriteNo);
*	
DrawSprite start ASMCODE

iOffset equ 5
iSpriteNo equ 7

	PHB
	PHK
	PLB
	
	lda iOffset,s	; Screen Address
	tay				; Y=Target Screen Address ($2000-$9D00)
	
	lda iSpriteNo,s
	ASL	A	; A=Sprite Number ($0000-$01C1)
	tax
* Repair Stack
    lda 3,s
    sta iSpriteNo,s
    lda 1,s
    sta iSpriteNo-2,s
	pla
	pla
* Dispatch bank specific
	LDA	xrickNum,X	; Relative Sprite Number Table
	JMP	(xrickBank,X)	; Bank Number Table

xrickNum ANOP
	dc	h'4400 4300 0E00 3400 0500 1C00 0300 2500'
	dc	h'6400 2B00 1300 0F00 0200 5D00 6100 5400'
	dc	h'5A00 6000 0A00 5800 1100 1000 6800 2000'
	dc	h'5E00 4F00 3D00 0400 6900 3500 2600 0500'
	dc	h'2800 6C00 2200 0A00 4400 1D00 5F00 5800'
	dc	h'6400 5500 0E00 5700 5200 2700 1E00 0000'
	dc	h'3F00 5100 2600 1C00 3000 2200 4900 4700'
	dc	h'5600 4C00 4400 4500 1000 1100 2000 2500'
	dc	h'2600 2B00 2700 2E00 7A00 7D00 7C00 7E00'
	dc	h'2D00 1700 2700 1500 0E00 1600 4800 1F00'
	dc	h'0600 5F00 6300 0500 0800 0800 2800 2A00'
	dc	h'0B00 2E00 4900 4B00 3D00 4700 1B00 4900'
	dc	h'2C00 5200 0900 1800 1F00 4000 2B00 5400'
	dc	h'0700 2000 3200 1E00 2300 2100 1F00 4300'
	dc	h'1600 3200 5000 4200 5900 1D00 2900 1A00'
	dc	h'4300 4C00 5A00 0100 3800 4400 4600 3300'
	dc	h'6000 2A00 3B00 5C00 1900 1600 6100 3200'
	dc	h'5300 3E00 1A00 1700 6000 3300 0B00 5100'
	dc	h'3600 3000 3C00 2300 3700 2900 4D00 4000'
	dc	h'3500 5700 2100 3800 3E00 3900 3100 5B00'
	dc	h'3000 2400 5B00 0400 1100 4C00 4500 2A00'
	dc	h'4800 2F00 7900 2F00 1F00 2800 2800 4A00'
	dc	h'3500 4A00 5000 3C00 0A00 6A00 8B00 1500'
	dc	h'1600 7300 2200 7B00 6600 3A00 5E00 1500'
	dc	h'6B00 4200 3900 2100 4800 5100 3600 1900'
	dc	h'1400 1300 1100 5E00 0200 0600 5300 5000'
	dc	h'0B00 0E00 2E00 4500 5200 3A00 4700 1800'
	dc	h'1900 8500 7100 2E00 3900 5900 4D00 6200'
	dc	h'4000 3400 2C00 7100 7700 3100 2C00 3100'
	dc	h'1C00 1B00 6D00 5700 1A00 2300 6900 6E00'
	dc	h'2F00 4100 2200 1700 1E00 1D00 6F00 6800'
	dc	h'3700 3200 3B00 3000 5800 3B00 3D00 6500'
	dc	h'1400 6F00 3400 5C00 3A00 5A00 6E00 1200'
	dc	h'1000 0C00 3800 2D00 5400 3700 0300 0700'
	dc	h'0B00 0600 6700 2D00 0900 0100 1200 0200'
	dc	h'2B00 1900 2000 2500 0D00 5500 2300 5500'
	dc	h'1C00 4A00 0800 5600 2700 4E00 4B00 1E00'
	dc	h'1D00 1B00 1000 1800 4E00 3F00 3C00 4D00'
	dc	h'9000 4500 8000 8100 7F00 8700 8200 8900'
	dc	h'8800 8600 8C00 8D00 8F00 8A00 0500 0100'
	dc	h'0200 0700 8400 8300 0000 0900 0800 0300'
	dc	h'0F00 1200 8E00 6B00 5D00 6300 6700 5C00'
	dc	h'6A00 5300 1A00 0D00 1200 0A00 1400 0C00'
	dc	h'0900 0700 7800 7600 2400 2100 4600 4300'
	dc	h'4F00 3B00 2500 3300 3E00 4600 1700 0000'
	dc	h'0F00 7000 3600 5D00 4E00 5F00 5600 4100'
	dc	h'2400 4200 4B00 5B00 1B00 1300 3F00 2400'
	dc	h'4F00 3700 0F00 2600 4100 2900 3D00 4100'
	dc	h'3500 3100 0D00 0600 6C00 6600 7200 7500'
	dc	h'1500 1300 3400 3A00 3600 3F00 2900 2D00'
	dc	h'4200 3E00 2F00 3C00 0400 0C00 6500 6D00'
	dc	h'7000 7400 1400 1800 3900 3300 3800 4000'
	dc	h'2A00 2C00 6200 5900 0D00 0C00 0100 0400'
	dc	h'0000 0300'

xrickBank ANOP
	dc	a'xrickBank03,xrickBank03,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank01,xrickBank01'
	dc	a'xrickBank01,xrickBank02,xrickBank01,xrickBank02,xrickBank01,xrickBank01,xrickBank02,xrickBank02'
	dc	a'xrickBank02,xrickBank02,xrickBank01,xrickBank00,xrickBank02,xrickBank02,xrickBank01,xrickBank02'
	dc	a'xrickBank01,xrickBank01,xrickBank02,xrickBank02,xrickBank01,xrickBank02,xrickBank01,xrickBank01'
	dc	a'xrickBank02,xrickBank01,xrickBank01,xrickBank02,xrickBank01,xrickBank01,xrickBank02,xrickBank02'
	dc	a'xrickBank02,xrickBank02,xrickBank01,xrickBank00,xrickBank01,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank01,xrickBank01,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00'
	dc	a'xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank03,xrickBank03,xrickBank03,xrickBank03'
	dc	a'xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank02,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00'
	dc	a'xrickBank01,xrickBank00,xrickBank01,xrickBank00,xrickBank02,xrickBank00,xrickBank00,xrickBank00'
	dc	a'xrickBank00,xrickBank00,xrickBank02,xrickBank02,xrickBank01,xrickBank01,xrickBank01,xrickBank01'
	dc	a'xrickBank01,xrickBank00,xrickBank01,xrickBank01,xrickBank01,xrickBank01,xrickBank01,xrickBank00'
	dc	a'xrickBank01,xrickBank01,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank02,xrickBank01'
	dc	a'xrickBank02,xrickBank01,xrickBank01,xrickBank02,xrickBank01,xrickBank02,xrickBank01,xrickBank02'
	dc	a'xrickBank02,xrickBank01,xrickBank00,xrickBank01,xrickBank01,xrickBank00,xrickBank02,xrickBank01'
	dc	a'xrickBank00,xrickBank01,xrickBank02,xrickBank00,xrickBank01,xrickBank01,xrickBank01,xrickBank02'
	dc	a'xrickBank00,xrickBank02,xrickBank01,xrickBank01,xrickBank01,xrickBank02,xrickBank01,xrickBank00'
	dc	a'xrickBank00,xrickBank01,xrickBank01,xrickBank02,xrickBank01,xrickBank02,xrickBank01,xrickBank02'
	dc	a'xrickBank01,xrickBank01,xrickBank02,xrickBank02,xrickBank01,xrickBank02,xrickBank01,xrickBank01'
	dc	a'xrickBank02,xrickBank02,xrickBank00,xrickBank01,xrickBank01,xrickBank00,xrickBank01,xrickBank02'
	dc	a'xrickBank01,xrickBank02,xrickBank02,xrickBank00,xrickBank03,xrickBank03,xrickBank01,xrickBank02'
	dc	a'xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank03,xrickBank02,xrickBank02,xrickBank01'
	dc	a'xrickBank03,xrickBank02,xrickBank03,xrickBank02,xrickBank01,xrickBank01,xrickBank00,xrickBank02'
	dc	a'xrickBank01,xrickBank00,xrickBank00,xrickBank01,xrickBank02,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank02,xrickBank02,xrickBank00,xrickBank02,xrickBank00,xrickBank00,xrickBank02,xrickBank02'
	dc	a'xrickBank03,xrickBank03,xrickBank01,xrickBank00,xrickBank02,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank03,xrickBank02,xrickBank01,xrickBank02,xrickBank01,xrickBank00,xrickBank00,xrickBank01'
	dc	a'xrickBank00,xrickBank00,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank00,xrickBank00'
	dc	a'xrickBank03,xrickBank03,xrickBank01,xrickBank02,xrickBank03,xrickBank03,xrickBank02,xrickBank02'
	dc	a'xrickBank01,xrickBank01,xrickBank02,xrickBank03,xrickBank03,xrickBank03,xrickBank02,xrickBank02'
	dc	a'xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank01,xrickBank01,xrickBank00,xrickBank01'
	dc	a'xrickBank01,xrickBank01,xrickBank01,xrickBank01,xrickBank00,xrickBank01,xrickBank01,xrickBank01'
	dc	a'xrickBank01,xrickBank01,xrickBank00,xrickBank01,xrickBank01,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank02,xrickBank02,xrickBank01,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank01,xrickBank01,xrickBank01,xrickBank00'
	dc	a'xrickBank01,xrickBank01,xrickBank01,xrickBank01,xrickBank01,xrickBank00,xrickBank01,xrickBank01'
	dc	a'xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank02,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank02,xrickBank03,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank03,xrickBank03'
	dc	a'xrickBank03,xrickBank03,xrickBank02,xrickBank02,xrickBank03,xrickBank03,xrickBank03,xrickBank03'
	dc	a'xrickBank03,xrickBank03,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank01,xrickBank01,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00'
	dc	a'xrickBank00,xrickBank00,xrickBank02,xrickBank02,xrickBank03,xrickBank03,xrickBank00,xrickBank00'
	dc	a'xrickBank00,xrickBank00,xrickBank02,xrickBank00,xrickBank00,xrickBank01,xrickBank02,xrickBank01'
	dc	a'xrickBank01,xrickBank01,xrickBank01,xrickBank00,xrickBank01,xrickBank01,xrickBank00,xrickBank00'
	dc	a'xrickBank00,xrickBank01,xrickBank00,xrickBank02,xrickBank02,xrickBank00,xrickBank00,xrickBank01'
	dc	a'xrickBank02,xrickBank00,xrickBank00,xrickBank02,xrickBank02,xrickBank00,xrickBank03,xrickBank03'
	dc	a'xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank02,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank03'
	dc	a'xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank02,xrickBank02'
	dc	a'xrickBank02,xrickBank02,xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank03'
	dc	a'xrickBank03,xrickBank03,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank00,xrickBank00'
	dc	a'xrickBank00,xrickBank00'

xrickBank00 entry
	JSL	$AA0000
	PLB
	RTL

xrickBank01 entry
	JSL	$AA0000
	PLB
	RTL

xrickBank02 entry
	JSL	$AA0000
	PLB
	RTL

xrickBank03 entry
	JSL	$AA0000
	PLB
	RTL
*------------------------------------------------
	

*-------------------------------------------------------------------------------
*
*void SetSpriteBanks(short b0, short b1, short b2, short b3);
*
SetSpriteBanks entry
	
iBank0 equ 4
iBank1 equ 6
iBank2 equ 8
iBank3 equ 10

	sep #$30

	lda iBank0,s
	sta >xrickBank00+3
	
	lda iBank1,s
	sta >xrickBank01+3

	lda iBank2,s
	sta >xrickBank02+3

	lda iBank3,s
	sta >xrickBank03+3

	rep #$30
	
	lda 2,s
	sta iBank3,s
	lda 1,s
	sta iBank3-1,s
	
    tsc
	sec
    sbc #-8
    tcs

	rtl	

*-------------------------------------------------------------------------------
	end

