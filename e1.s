  
         rel
         dsk framebuffer.l
		 
		ext waitkey
         ; We could have a putbin here, to display a raw image 
fbuffer ent
	clc
	xce
	rep #$30
	jsl waitkey
	rtl
		 db 1
          
          
