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
rem Compress the NinjaTrackerPlus songs, and audio
rem
lz4 -c2 data\sound\egypt.ntp data\egypt.lz4
lz4 -c2 data\sound\mbase.ntp data\mbase.lz4
lz4 -c2 data\sound\rick1.ntp data\rick1.lz4
lz4 -c2 data\sound\rick1victory.ntp data\rick1victory.lz4
lz4 -c2 data\sound\samerica.ntp data\samerica.lz4
lz4 -c2 data\sound\schwarz.ntp data\schwarz.lz4
lz4 -c2 data\sound\sfx.bin data\sfx.lz4
rem
rem Convert the title page into an object file
rem
iix mkobj splash_lz4 data:splash.lz4 data:splash.a screendata
iix mkobj img_splash_lz4 data:img_splash16.lz4 data:img_splash.a screendata
iix mkobj pic_haf_lz4 data:pic_haf.lz4 data:pic_haf.a screendata
iix mkobj tiles_lz4 data:tiles.lz4 data:tiles.a tilesdata
rem
rem NinjaTrackerPlus Songs to object files
rem
iix mkobj egypt_lz4 data:egypt.lz4 data:egypt.a ntpdata
iix mkobj mbase_lz4 data:mbase.lz4 data:mbase.a ntpdata
iix mkobj rick1_lz4 data:rick1.lz4 data:rick1.a ntpdata
iix mkobj rick1victory_lz4 data:rick1victory.lz4 data:rick1victory.a ntpdata
iix mkobj samerica_lz4 data:samerica.lz4 data:samerica.a ntpdata
iix mkobj schwarz_lz4 data:schwarz.lz4 data:schwarz.a ntpdata
iix mkobj sfx_lz4 data:sfx.lz4 data:lz4.a sfxdata
rem
rem Packed Mr.Sprites into object files
rem
iix mkobj xrickspr_00 data:sprites:xrick00.lz4 data:xrick0.a sprdata0
iix mkobj xrickspr_01 data:sprites:xrick01.lz4 data:xrick1.a sprdata1
iix mkobj xrickspr_02 data:sprites:xrick02.lz4 data:xrick2.a sprdata2
iix mkobj xrickspr_03 data:sprites:xrick03.lz4 data:xrick3.a sprdata3
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
iix makelib -P data.lib +data:egypt.a
iix makelib -P data.lib +data:mbase.a
iix makelib -P data.lib +data:rick1.a
iix makelib -P data.lib +data:rick1victory.a
iix makelib -P data.lib +data:samerica.a
iix makelib -P data.lib +data:schwarz.a
iix makelib -P data.lib +data:sfx.a
rem
rem NinjaTrackerPlus Library
rem
cd asm\merlin
call make.bat
cd ..\..
lz4 -c2 asm\merlin\ntpplayer.bin data\ntpplayer.lz4
iix mkobj ntpplayer_lz4 data:ntpplayer.lz4 data:ntpplayer.a ntpdata
iix makelib -P data.lib +data\ntpplayer.a


