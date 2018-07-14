         rel
         dsk Main.l
		 
;	ext fbuffer
          
waitkey  ent          
         clc
         xce
         sep #$30
          
         ; Enable SHR

		ldal	$e0c029
		ora		#$c0
		stal	$e0c029

         ; Wait Key
:lp          
         ldal $e0c000
         bpl :lp
         stal $e0c010
          
         ; Exit the App

         ; TODO call Prodos 16 Exit
         ; as rtl probably just crashes

         rtl
           
;	da fbuffer		  
          
