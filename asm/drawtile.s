*
* ORCA/M Format!!
* Thunk from C to compiled draw things
*
 case on
 longa on
 longi on

Dummy3 start ASMCODE
	end

*
* void DrawTile(short offset, short tileNo)
*

DrawTile start ASMCODE
	
iOffset equ 5
iTileNo equ 7

	phb
		
	lda iOffset,s
	tay
	lda iTileNo,s
	asl A
	tax 		; jmp table offset in x
	
	anop ; adjust the stack
    anop ; Copy the Return address
    lda 3,s
    sta iTileNo,s
    lda 1,s
    sta iTileNo-2,s

	pla
	
	lda #$0101
	sta 1,s
	plb
	plb
TILEBANK2 entry	
	lda >$880005,x	
	sta >TILEBANK+1
	
TILEBANK entry	
	jsl >$880000
	
	plb
	
	rtl

*-------------------------------------------------------------------------------
    end

SetTileBank start ASMCODE
	
iBank equ 4
	sep #$30
	lda iBank,s
	sta >TILEBANK+3
	sta >TILEBANK2+3
	rep #$30
	lda 2,s
	sta iBank,s
	lda 1,s
	sta iBank-1,s
	pla
	rtl	

*-------------------------------------------------------------------------------
	end
