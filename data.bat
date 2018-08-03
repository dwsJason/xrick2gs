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

png2bmp -D bmp data\pics\*.png
b2s bmp\splash.bmp
lz4 -c2 bmp\splash.SHR#C10000 data\splash.lz4
cd data
iix mkobj splash_lz4 splash.lz4 splash.a
cd ..
iix makelib -P data.lib +data\splash.a

