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
	dc	h'5C00 5B00 5A00 5900 5800 5700 5500 5400'
	dc	h'5300 5200 5100 5000 4F00 4D00 4C00 4B00'
	dc	h'4A00 4900 4800 4700 4600 4500 4400 4300'
	dc	h'9100 9000 3500 0E00 0400 1C00 0300 2400'
	dc	h'6200 2B00 1200 0F00 0200 5900 5400 6000'
	dc	h'5A00 6100 5800 0C00 1100 1000 1F00 6900'
	dc	h'5E00 4E00 0700 3E00 6800 3400 2500 0400'
	dc	h'6A00 2700 0B00 2000 4400 1E00 5F00 5800'
	dc	h'6400 5500 5700 0E00 2600 5000 1E00 0000'
	dc	h'3D00 4F00 1C00 2600 3000 2200 4800 4900'
	dc	h'4C00 5600 4300 4400 1100 1200 2100 2400'
	dc	h'2B00 2700 2600 2E00 7A00 7B00 7E00 7C00'
	dc	h'2E00 1700 2700 1600 1500 0E00 1E00 4600'
	dc	h'0100 0600 0500 6400 0800 0900 2800 2A00'
	dc	h'0B00 2D00 4A00 4900 3F00 4600 1F00 4700'
	dc	h'5400 2C00 1A00 0900 1C00 4000 5500 2B00'
	dc	h'0700 2200 1D00 3100 2300 2100 2D00 5200'
	dc	h'3700 1600 7100 5100 1D00 5D00 2800 1A00'
	dc	h'4200 4C00 5C00 5D00 4700 3C00 4500 3200'
	dc	h'2A00 6000 3B00 5A00 1700 1600 6000 3000'
	dc	h'5200 3D00 1800 1900 5F00 3200 5000 0B00'
	dc	h'3600 3000 3B00 2200 3600 2900 4000 4900'
	dc	h'3500 5C00 3900 2000 3E00 3700 5700 3100'
	dc	h'2400 3100 0500 5B00 4C00 1000 4300 2C00'
	dc	h'4B00 2F00 2F00 7900 2800 1F00 4B00 2700'
	dc	h'3400 4A00 4F00 3C00 6A00 0A00 1500 8B00'
	dc	h'7300 1600 7D00 2200 3800 6700 5E00 1500'
	dc	h'4200 6F00 2100 3900 4800 5100 3600 1900'
	dc	h'1400 1300 5D00 1000 0200 0600 5300 4F00'
	dc	h'0F00 0B00 4400 2D00 5200 3A00 4700 1800'
	dc	h'8500 1900 4600 2E00 5900 3A00 6300 4D00'
	dc	h'3500 4100 2A00 7100 7700 3300 2C00 3200'
	dc	h'1B00 1C00 5700 6B00 2300 1A00 6900 6E00'
	dc	h'4200 2F00 1700 2100 1D00 1E00 6F00 6800'
	dc	h'3200 3600 2F00 3A00 3900 5A00 3D00 6500'
	dc	h'1400 6C00 5B00 3400 3A00 5800 6E00 1300'
	dc	h'0F00 0A00 2E00 3800 3800 5400 0600 0300'
	dc	h'0500 0A00 2800 6600 0100 0800 0200 1200'
	dc	h'2B00 1900 2400 2000 0D00 5600 2300 5300'
	dc	h'1D00 4A00 5500 0800 2900 5100 1B00 4800'
	dc	h'1B00 1F00 1800 1100 3F00 4E00 4D00 3C00'
	dc	h'5600 4E00 8100 8000 8600 7F00 8700 8200'
	dc	h'8900 8800 8D00 8A00 8C00 8F00 0300 0400'
	dc	h'0100 0600 8400 8300 0800 0000 0900 0200'
	dc	h'0E00 1000 6B00 8E00 5E00 6300 5C00 6700'
	dc	h'5300 6D00 0D00 1A00 1200 0A00 1400 0C00'
	dc	h'0700 0900 7800 7600 2000 2500 4300 4500'
	dc	h'4E00 3B00 3300 2300 3F00 4500 1700 0000'
	dc	h'1100 7000 3300 5F00 6100 4D00 4000 5600'
	dc	h'2500 4100 4B00 5B00 1B00 1300 2600 3E00'
	dc	h'5000 3700 0F00 2500 2900 4100 4200 3C00'
	dc	h'3000 3500 0C00 0700 6C00 6600 7200 7500'
	dc	h'1500 1300 3900 3300 4000 3700 2C00 2900'
	dc	h'3D00 4100 3100 3E00 0D00 0500 6D00 6500'
	dc	h'7000 7400 1400 1800 3B00 3400 3F00 3800'
	dc	h'2D00 2A00 6200 5900 0C00 0D00 0100 0400'
	dc	h'0000 0300'

xrickBank ANOP
	dc	a'xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank03'
	dc	a'xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank03'
	dc	a'xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank03'
	dc	a'xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank01,xrickBank01'
	dc	a'xrickBank01,xrickBank02,xrickBank01,xrickBank02,xrickBank01,xrickBank01,xrickBank02,xrickBank02'
	dc	a'xrickBank02,xrickBank02,xrickBank00,xrickBank01,xrickBank02,xrickBank02,xrickBank02,xrickBank01'
	dc	a'xrickBank01,xrickBank01,xrickBank02,xrickBank02,xrickBank01,xrickBank02,xrickBank01,xrickBank01'
	dc	a'xrickBank01,xrickBank02,xrickBank02,xrickBank01,xrickBank01,xrickBank01,xrickBank02,xrickBank02'
	dc	a'xrickBank02,xrickBank02,xrickBank00,xrickBank01,xrickBank02,xrickBank01,xrickBank02,xrickBank02'
	dc	a'xrickBank01,xrickBank01,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00'
	dc	a'xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank03,xrickBank03,xrickBank03,xrickBank03'
	dc	a'xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank02,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00'
	dc	a'xrickBank01,xrickBank01,xrickBank00,xrickBank01,xrickBank00,xrickBank02,xrickBank00,xrickBank00'
	dc	a'xrickBank00,xrickBank00,xrickBank02,xrickBank02,xrickBank01,xrickBank01,xrickBank01,xrickBank01'
	dc	a'xrickBank00,xrickBank01,xrickBank01,xrickBank01,xrickBank01,xrickBank01,xrickBank00,xrickBank01'
	dc	a'xrickBank01,xrickBank01,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank02,xrickBank01'
	dc	a'xrickBank01,xrickBank02,xrickBank01,xrickBank01,xrickBank02,xrickBank01,xrickBank01,xrickBank02'
	dc	a'xrickBank02,xrickBank01,xrickBank00,xrickBank00,xrickBank00,xrickBank01,xrickBank02,xrickBank01'
	dc	a'xrickBank01,xrickBank00,xrickBank02,xrickBank00,xrickBank01,xrickBank01,xrickBank01,xrickBank02'
	dc	a'xrickBank00,xrickBank02,xrickBank01,xrickBank01,xrickBank01,xrickBank02,xrickBank00,xrickBank01'
	dc	a'xrickBank00,xrickBank01,xrickBank01,xrickBank02,xrickBank01,xrickBank02,xrickBank02,xrickBank01'
	dc	a'xrickBank01,xrickBank01,xrickBank02,xrickBank02,xrickBank01,xrickBank02,xrickBank01,xrickBank01'
	dc	a'xrickBank02,xrickBank02,xrickBank01,xrickBank00,xrickBank00,xrickBank01,xrickBank01,xrickBank02'
	dc	a'xrickBank01,xrickBank02,xrickBank00,xrickBank02,xrickBank03,xrickBank03,xrickBank02,xrickBank01'
	dc	a'xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank02,xrickBank03,xrickBank01,xrickBank02'
	dc	a'xrickBank02,xrickBank03,xrickBank02,xrickBank03,xrickBank01,xrickBank01,xrickBank00,xrickBank02'
	dc	a'xrickBank00,xrickBank01,xrickBank01,xrickBank00,xrickBank02,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank02,xrickBank02,xrickBank02,xrickBank00,xrickBank00,xrickBank00,xrickBank02,xrickBank02'
	dc	a'xrickBank03,xrickBank03,xrickBank00,xrickBank01,xrickBank02,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank02,xrickBank03,xrickBank02,xrickBank02,xrickBank00,xrickBank01,xrickBank01,xrickBank00'
	dc	a'xrickBank00,xrickBank00,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank00,xrickBank00'
	dc	a'xrickBank03,xrickBank03,xrickBank02,xrickBank01,xrickBank03,xrickBank03,xrickBank02,xrickBank02'
	dc	a'xrickBank01,xrickBank01,xrickBank03,xrickBank02,xrickBank03,xrickBank03,xrickBank02,xrickBank02'
	dc	a'xrickBank03,xrickBank03,xrickBank03,xrickBank03,xrickBank01,xrickBank01,xrickBank00,xrickBank01'
	dc	a'xrickBank01,xrickBank01,xrickBank01,xrickBank01,xrickBank00,xrickBank01,xrickBank01,xrickBank01'
	dc	a'xrickBank01,xrickBank01,xrickBank01,xrickBank00,xrickBank02,xrickBank01,xrickBank02,xrickBank02'
	dc	a'xrickBank02,xrickBank02,xrickBank02,xrickBank01,xrickBank02,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank01,xrickBank01,xrickBank01,xrickBank00'
	dc	a'xrickBank01,xrickBank01,xrickBank01,xrickBank01,xrickBank01,xrickBank00,xrickBank01,xrickBank01'
	dc	a'xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank02,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank03,xrickBank03,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank03,xrickBank03'
	dc	a'xrickBank03,xrickBank03,xrickBank02,xrickBank02,xrickBank03,xrickBank03,xrickBank03,xrickBank03'
	dc	a'xrickBank03,xrickBank03,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02,xrickBank02'
	dc	a'xrickBank01,xrickBank01,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00,xrickBank00'
	dc	a'xrickBank00,xrickBank00,xrickBank02,xrickBank02,xrickBank03,xrickBank03,xrickBank00,xrickBank00'
	dc	a'xrickBank00,xrickBank00,xrickBank00,xrickBank02,xrickBank00,xrickBank01,xrickBank02,xrickBank01'
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

