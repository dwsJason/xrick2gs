*
* ORCA/M Fomat!!
* NinjaTrackerPlus C interfaces for ORCA
*
	case on
	longa on
	longi on
	
* Wow this is dummy section is silly
DummyNTP start ASM_CODE
	end
	
; prepare
; Prepares music, copies all instruments into sound ram and inits the sound interrupt.
; input:  call with X=address low, Y=address high of pointer to the ntp file in memory
; output: X=address low, Y=address high of pointer to instruments (main program can reuse memory from here)
;         when carry bit is set, an error occurred. Either the player did not find a NTP module at the given location
;         or the version of the NTP module is not supported.

*
* bool NTPprepare(void* pNTPData)
*
NTPprepare start ASM_CODE

aNTPprepare EQU ntpplayer
			
	lda 4,s
	tax
	lda 6,s
	tay
	
	lda 1,s
	sta 5,s
	lda 2,s
	sta 6,s
	
	pla
	lda #0
	sta 1,s
	
	jsl aNTPprepare
	
	bcc okgo
	
	lda #1
	sta 1,s
	
okgo pla
	rtl
*-------------------------------------------------------------------------------
	end

; play
; Starts previously prepared music.
; input:  call with A=0 loop song, else play song only once
; output: -
*
* void NTPplay(bool bPlayOnce)
*
NTPplay start ASM_CODE

aNTPplay EQU ntpplayer+3

	lda 4,s
	tax
	lda 2,s
	sta 4,s
	lda 1,s
	sta 3,s
	pla
	txa
	jmp >aNTPplay
*-------------------------------------------------------------------------------
	end
					  
; stop
; Stops a currently playing music, turns off all oscillators used by the player and restores the sound interrupt.
; input:  -
; outout: -
*
* void NTPstop(void)
*
NTPstop start ASM_CODE

aNTPstop EQU ntpplayer+6

	jmp >aNTPstop
*-------------------------------------------------------------------------------
	end
	

; getvuptr
; Returns a pointer to vu data (1 word number of tracks, then one word for every track with its volume).
; input:  -
; output: X=address low, Y=address high of pointer
;aNTPgetvuptr      GEQU   ntpplayer+9
*
* u8* NTPgetvuptr(void)
*
NTPgetvuptr start ASM_CODE
	rtl
*-------------------------------------------------------------------------------
	end


; gete8ptr
; Returns a pointer to where the player stores information about the last 8xx command found. Can be used for timing purposes.
; input:  -
; output: X=address low, Y=address high of pointer
;aNTPgete8ptr      GEQU   ntpplayer+12
*
* u8* NTPgete8ptr(void)
*
NTPgete8ptr start ASM_CODE
	rtl
*-------------------------------------------------------------------------------
	end

; forcesongpos
; Forces the player to jump to a certain pattern (like command B).
; input:  A=songpos
; output: carry bit is set when the song position does not exist (error)
;aNTPforcesongpos  GEQU   ntpplayer+15
*
* bool NTPforcesongpos(int songpos)
*
NTPforcesongpos start ASM_CODE
	lda #0
	rtl
*-------------------------------------------------------------------------------
	end



