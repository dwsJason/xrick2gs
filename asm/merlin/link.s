  
         dsk ntpplayer.a                ; program name
         typ $b1                   ; OBJ
         ;xpl                       ; Add Expressload


; Segment 1

         asm ninjatrackerplus.s
         ds 0
;         knd   #$1100              ; Kind
         knd   #$0000              ; Kind
         ali   None                ; alignment
         lna   "ntpplayer  "           ; Load Name
         sna   "ntpplayer  "         ; Segment Name
                                    
                                      
