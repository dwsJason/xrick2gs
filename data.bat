@echo off
setlocal
rem
rem Make the data lib, for xrick2gs
rem

echo Y |del data.lib

if exist "bmp" (
	echo Y |del bmp\*
	rmdir bmp
)

rem
rem bmp directory if it doesn't exist
rem 
if not exist "bmp" (
	mkdir bmp
)

rem
rem convert all the pngs to bmp
rem
png2bmp -D bmp data\pics\*.png
rem
rem for now just convert the splash screen, to GS format
rem
b2s bmp\splash.bmp
b2s bmp\img_splash16.bmp
rem
rem Compress the title page
rem
lz4 -c2 bmp\splash.SHR#C10000 data\splash.lz4
lz4 -c2 bmp\img_splash16.SHR#C10000 data\img_splash16.lz4
rem
rem Convert the title page into an object file
rem
iix mkobj splash_lz4 data:splash.lz4 data:splash.a
iix mkobj img_splash_lz4 data:img_splash16.lz4 data:img_splash.a
rem
rem Create Static Linked Binary data library
rem
iix makelib -P data.lib +data\splash.a
iix makelib -P data.lib +data\img_splash.a

