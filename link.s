  
  
         dsk e1.obj                ; program name
         typ $b1                   ; OBJ
         ;xpl                       ; Add Expressload


; Segment 1

         asm e1.s                  ; Really want to attempt a putbin
         ds $8000
         knd   #$1100              ; Kind
         ali   None                ; alignment
;         lna   e1demo.s16          ; Load Name
         sna   framebuffer         ; Segment Name
                                    
; Segment 2
                                    
         asm   waitkey.s
         ds 0
         knd #$1100
         ali none
;         lna e1demo.s16
         sna keything
                                       
                                      
