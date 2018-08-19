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
    dc	h'4300 9100 3400 0E00 0500 1D00 0300 2500'
	dc	h'2900 6400 1300 0F00 0200 5C00 6100 5400'
	dc	h'6000 5A00 0C00 5800 1100 1000 1F00 6900'
	dc	h'4D00 5E00 3D00 0400 3500 6800 0500 2400'
	dc	h'6C00 2700 0A00 2000 1F00 4400 5F00 5800'
	dc	h'5500 6400 0F00 5700 5000 2500 0200 1E00'
	dc	h'3D00 4F00 1C00 2600 3000 2200 4800 4A00'
	dc	h'4C00 5600 4400 4300 1000 1100 2500 2000'
	dc	h'2600 2B00 2E00 2700 7A00 7B00 7D00 7E00'
	dc	h'1700 2D00 1500 2700 0E00 1600 1F00 4700'
	dc	h'0000 0600 0500 6300 0800 0800 2800 2A00'
	dc	h'2E00 0B00 4900 4B00 3E00 4600 4800 1E00'
	dc	h'2B00 5400 0900 1900 1D00 4000 2C00 5200'
	dc	h'2200 0700 1E00 3100 2300 2100 5200 2D00'
	dc	h'1600 3600 7100 5100 5A00 1C00 2800 1A00'
	dc	h'4200 4C00 5D00 5C00 3C00 4600 3200 4500'
	dc	h'6000 2A00 5B00 3B00 1600 1800 3300 6100'
	dc	h'3E00 5300 1700 1A00 5F00 3200 4E00 0A00'
	dc	h'3600 2F00 2200 3B00 2B00 3700 4A00 4000'
	dc	h'5700 3400 3800 2000 3900 3F00 3100 5D00'
	dc	h'3000 2300 5A00 0400 0E00 4C00 2800 4300'
	dc	h'4900 2F00 2F00 7900 2800 1F00 4A00 2700'
	dc	h'3500 4900 4F00 3C00 6A00 0A00 1500 8C00'
	dc	h'7300 1600 2200 7C00 6700 3900 1500 5E00'
	dc	h'7000 4200 3A00 2100 4800 5100 3600 1900'
	dc	h'1400 1300 5E00 1000 0600 0200 5300 5000'
	dc	h'0E00 0B00 4400 2E00 5200 3A00 4700 1800'
	dc	h'8500 1900 4600 2E00 5900 3800 6200 4D00'
	dc	h'4000 3400 7200 2A00 3100 7700 2C00 3200'
	dc	h'1B00 1C00 6B00 5700 2300 1A00 6E00 6900'
	dc	h'3000 4100 1700 2100 1D00 1E00 6800 6F00'
	dc	h'3200 3700 3B00 3000 3A00 5900 3D00 6500'
	dc	h'6E00 1400 5800 3300 5B00 3900 6D00 1200'
	dc	h'0B00 1100 3800 2D00 5400 3700 0700 0300'
	dc	h'0B00 0600 6600 2C00 0900 0000 0100 1200'
	dc	h'1900 2B00 2000 2500 5500 0D00 5500 2300'
	dc	h'1C00 4B00 0800 5600 2900 5000 1B00 4700'
	dc	h'1D00 1B00 1800 1100 4E00 3F00 3C00 4D00'
	dc	h'4400 9000 8000 8300 8600 7F00 8100 8700'
	dc	h'8900 8800 8D00 8B00 8F00 8A00 0500 0300'
	dc	h'0600 0200 8200 8400 0000 0900 0800 0100'
	dc	h'0F00 1200 8E00 6B00 5D00 6300 6700 5C00'
	dc	h'6A00 5300 1A00 0D00 1200 0A00 1400 0C00'
	dc	h'0900 0700 7800 7600 2400 2100 4500 4300'
	dc	h'5100 3B00 2400 3300 3F00 4500 1700 0100'
	dc	h'1000 6F00 3500 5F00 4E00 6000 5600 4100'
	dc	h'2400 4200 4B00 5B00 1B00 1300 2600 3E00'
	dc	h'4F00 3700 0F00 2600 2900 4100 4100 3D00'
	dc	h'3500 3100 0D00 0700 6500 6D00 7100 7500'
	dc	h'1500 1300 3400 3A00 3F00 3600 2D00 2900'
	dc	h'3E00 4200 2F00 3C00 0C00 0400 6600 6C00'
	dc	h'7400 7000 1800 1400 3300 3900 4000 3800'
	dc	h'2C00 2A00 5900 6200 0D00 0C00 0100 0400'
	dc	h'0000 0300'

xrickBank ANOP
    dc	a'xrickBank03,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank01,xrickBank01'
	dc	a'xrickBank02,xrickBank01,xrickBank01,xrickBank02,xrickBank01,xrickBank01,xrickBank02,xrickBank02'
	dc	a'xrickBank02,xrickBank02,xrickBank01,xrickBank00,xrickBank02,xrickBank02,xrickBank02,xrickBank01'
	dc	a'xrickBank01,xrickBank01,xrickBank02,xrickBank02,xrickBank02,xrickBank01,xrickBank01,xrickBank01'
	dc	a'xrickBank01,xrickBank02,xrickBank02,xrickBank01,xrickBank01,xrickBank01,xrickBank02,xrickBank02'
	dc	a'xrickBank02,xrickBank02,xrickBank01,xrickBank00,xrickBank01,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank01,xrickBank01,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00'
	dc	a'xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank03,xrickBank03,xrickBank03,xrickBank03'
	dc	a'xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank02,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00'
	dc	a'xrickBank01,xrickBank01,xrickBank00,xrickBank01,xrickBank00,xrickBank02,xrickBank00,xrickBank00'
	dc	a'xrickBank00,xrickBank00,xrickBank02,xrickBank02,xrickBank01,xrickBank01,xrickBank01,xrickBank01'
	dc	a'xrickBank01,xrickBank00,xrickBank01,xrickBank01,xrickBank01,xrickBank01,xrickBank01,xrickBank00'
	dc	a'xrickBank01,xrickBank01,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank01,xrickBank02'
	dc	a'xrickBank02,xrickBank01,xrickBank01,xrickBank01,xrickBank01,xrickBank02,xrickBank01,xrickBank02'
	dc	a'xrickBank02,xrickBank01,xrickBank00,xrickBank00,xrickBank01,xrickBank00,xrickBank01,xrickBank02'
	dc	a'xrickBank00,xrickBank01,xrickBank00,xrickBank02,xrickBank01,xrickBank01,xrickBank02,xrickBank01'
	dc	a'xrickBank02,xrickBank00,xrickBank01,xrickBank01,xrickBank01,xrickBank02,xrickBank00,xrickBank01'
	dc	a'xrickBank00,xrickBank01,xrickBank02,xrickBank01,xrickBank02,xrickBank01,xrickBank01,xrickBank02'
	dc	a'xrickBank01,xrickBank01,xrickBank02,xrickBank02,xrickBank02,xrickBank01,xrickBank01,xrickBank01'
	dc	a'xrickBank02,xrickBank02,xrickBank00,xrickBank01,xrickBank01,xrickBank00,xrickBank02,xrickBank01'
	dc	a'xrickBank01,xrickBank02,xrickBank00,xrickBank02,xrickBank03,xrickBank03,xrickBank02,xrickBank01'
	dc	a'xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank02,xrickBank03,xrickBank01,xrickBank02'
	dc	a'xrickBank02,xrickBank03,xrickBank03,xrickBank02,xrickBank01,xrickBank01,xrickBank02,xrickBank00'
	dc	a'xrickBank01,xrickBank00,xrickBank00,xrickBank01,xrickBank02,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank02,xrickBank02,xrickBank02,xrickBank00,xrickBank00,xrickBank00,xrickBank02,xrickBank02'
	dc	a'xrickBank03,xrickBank03,xrickBank00,xrickBank01,xrickBank02,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank02,xrickBank03,xrickBank02,xrickBank02,xrickBank00,xrickBank01,xrickBank01,xrickBank00'
	dc	a'xrickBank00,xrickBank00,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank00,xrickBank00'
	dc	a'xrickBank03,xrickBank03,xrickBank01,xrickBank02,xrickBank03,xrickBank03,xrickBank02,xrickBank02'
	dc	a'xrickBank01,xrickBank01,xrickBank03,xrickBank02,xrickBank03,xrickBank03,xrickBank02,xrickBank02'
	dc	a'xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank01,xrickBank01,xrickBank00,xrickBank01'
	dc	a'xrickBank01,xrickBank01,xrickBank01,xrickBank01,xrickBank01,xrickBank00,xrickBank01,xrickBank01'
	dc	a'xrickBank01,xrickBank01,xrickBank00,xrickBank01,xrickBank01,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank02,xrickBank02,xrickBank01,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank01,xrickBank01,xrickBank00,xrickBank01'
	dc	a'xrickBank01,xrickBank01,xrickBank01,xrickBank01,xrickBank01,xrickBank00,xrickBank01,xrickBank01'
	dc	a'xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank02,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank03,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank03,xrickBank03'
	dc	a'xrickBank03,xrickBank03,xrickBank02,xrickBank02,xrickBank03,xrickBank03,xrickBank03,xrickBank03'
	dc	a'xrickBank03,xrickBank03,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank01,xrickBank01,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00'
	dc	a'xrickBank00,xrickBank00,xrickBank02,xrickBank02,xrickBank03,xrickBank03,xrickBank00,xrickBank00'
	dc	a'xrickBank00,xrickBank00,xrickBank02,xrickBank00,xrickBank00,xrickBank01,xrickBank02,xrickBank01'
	dc	a'xrickBank01,xrickBank01,xrickBank01,xrickBank00,xrickBank01,xrickBank01,xrickBank00,xrickBank00'
	dc	a'xrickBank00,xrickBank01,xrickBank00,xrickBank02,xrickBank02,xrickBank00,xrickBank01,xrickBank00'
	dc	a'xrickBank02,xrickBank00,xrickBank00,xrickBank02,xrickBank00,xrickBank02,xrickBank03,xrickBank03'
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

