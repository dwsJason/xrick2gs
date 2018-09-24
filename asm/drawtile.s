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
* u8 draw_tilesSubList
*
draw_tilesSubList start ASM_CODE
	phb
	
	lda |draw_tilesBank
	pha
	
	ldy	|fb
	
	lda |draw_tllst
	sta |LOAD+1
	lda |draw_tllst+1
	sta |LOAD+2
		

	pea $0101
	plb
	plb
	
	ldx	#0
 
LOAD lda >$880000,x
	and #$00FF
	cmp #$00FE
	bge done
	ora 1,s
	asl A
	phx
	tax
TILEBANK7 entry
	lda >$880005,x
	sta >TILEBANK8+1
TILEBANK8 entry
	jsl $880000
	tya
	adc #4
	tay
	plx
	inx
	bra LOAD
done ANOP
	sta 1,s
	txa
	adc >draw_tllst	; c=1, depending on adding the +1
	sta >draw_tllst
	
	pla	   
	plb
	sty |fb
	rtl
*-------------------------------------------------------------------------------
	end
*
* void draw_map(void)
*
draw_map start ASM_CODE
	phb
	
	lda |map_tilesBank
	sta |draw_tilesBank
	
	pha	

	pea $0101
	plb
	plb
	
	ldy #$2010+(160*8)
	ldx #8*32
loop ANOP	
	lda	>map_map,x
	and #$00FF
	ora 1,s
	asl A
	phx
	tax
TILEBANK5 entry
	lda >$880005,x
	sta >TILEBANK6+1
TILEBANK6 entry
	jsl >$880000
	tya
	adc #4
	tay
	plx
	inx
	txa
	
	and	#$1f
	bne continue
	
	tya
	adc #160*8-(32*4)
	tay
	
continue ANOP	

	cpx #(8*32)+(32*24)
	blt loop
	
	pla
	
	plb
	rtl
*-------------------------------------------------------------------------------
    end


*
* void draw_tile(U8 tileNumber)
*
draw_tile start ASM_CODE
iTileNo equ 5

	phb
	lda iTileNo,s
	ora |draw_tilesBank
	asl A
	tax
	
	lda |fb
	tay
	adc #4
	sta |fb
	
	lda 3,s
	sta iTileNo,s
	lda 1,s
	sta iTileNo-2,s
	
	lda #$0101
	sta 1,s
	plb
	plb
TILEBANK3 entry
	lda >$880005,x
	sta >TILEBANK4+1
TILEBANK4 entry
	jsl >$880000

	plb
	rtl
*-------------------------------------------------------------------------------
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
	
	cpy #$9D00-(7*160)
	bge skip

TILEBANK entry	
	jsl >$880000
skip anop   
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
	sta >TILEBANK3+3
	sta >TILEBANK4+3
	sta >TILEBANK5+3
	sta >TILEBANK6+3
	sta >TILEBANK7+3
	sta >TILEBANK8+3
	rep #$30
	lda 2,s
	sta iBank,s
	lda 1,s
	sta iBank-1,s
	pla
	rtl	

*-------------------------------------------------------------------------------
	end
	

*-------------------------------------------------------------------------------
wait_vsync start BLITCODE
	
	php
	sep #$30
  
*	while VBLANK, wait here  
invbl anop
	lda >$00c019
	bpl invbl
	
*	while !VBLANK, loop here
vbl anop
	lda >$00c019
	bmi vbl
	
	plp
	rtl
*-------------------------------------------------------------------------------
	end
*-------------------------------------------------------------------------------

