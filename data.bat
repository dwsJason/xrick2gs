@echo off
setlocal
rem
rem Make the data lib, for xrick2gs
rem

echo Y |del data.lib

rem
rem Compress the title page
rem
lz4 -c2 data\pics\splash.c1 data\splash.lz4
lz4 -c2 data\pics\img_splash.c1 data\img_splash16.lz4
rem
rem Hall of Fame
rem
lz4 -c2 data\pics\haf.gs data\pic_haf.lz4
rem
rem Convert the title page into an object file
rem
iix mkobj splash_lz4 data:splash.lz4 data:splash.a
iix mkobj img_splash_lz4 data:img_splash16.lz4 data:img_splash.a
iix mkobj pic_haf_lz4 data:pic_haf.lz4 data:pic_haf.a
iix mkobj tiles_lz4 data:tiles.lz4 data:tiles.a
rem
rem Packed Mr.Sprites into object files
rem
iix mkobj xrickspr_00 data:sprites:xrick00.lz4 data:xrick0.a
iix mkobj xrickspr_01 data:sprites:xrick01.lz4 data:xrick1.a
iix mkobj xrickspr_02 data:sprites:xrick02.lz4 data:xrick2.a
iix mkobj xrickspr_03 data:sprites:xrick03.lz4 data:xrick3.a
rem
rem Create Static Linked Binary data library
rem
iix makelib -P data.lib +data\splash.a
iix makelib -P data.lib +data\img_splash.a
iix makelib -P data.lib +data\pic_haf.a
iix makelib -P data.lib +data\tiles.a
iix makelib -P data.lib +data\xrick0.a
iix makelib -P data.lib +data\xrick1.a
iix makelib -P data.lib +data\xrick2.a
iix makelib -P data.lib +data\xrick3.a

