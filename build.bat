@echo off
setlocal
rem
rem Build and link xRick for the Apple IIgs
rem

rem
rem object directory if it doesn't exist
rem 
if not exist "obj" (
	mkdir obj
)

rem
rem #define IIGS 1
rem Add "include" into the directory search path for #include
rem 
set CC=cc=-DIIGS=1 cc=-Iinclude cc=-Isrc

rem
rem Build a list of .c files
rem 
for /f 	"tokens=*" %%a in ('dir /b src\*.c') do call :appendsrc %%a
goto :compile

rem
rem Silly append function, that has the conditional
rem to work around starting the list with a space character
rem
:appendsrc
if defined SOURCEFILES (
	set SOURCEFILES=%SOURCEFILES% %1
) else (
	if "%1" NEQ "\\" (
		set SOURCEFILES=%1
	)
)
EXIT /B 0

:appendobj
if defined OBJFILES (
	set OBJFILES=%OBJFILES% obj\%1
) else (
	set OBJFILES=obj\%1
)
EXIT /B 0

rem
rem Loop through the list of .c files, compiling them with ORCA
rem
:compile

FOR %%I IN (%SOURCEFILES%) DO (
	echo Compile: %%I
	set CFILE=%%I
    iix compile -P -I +O src\%%I keep=obj:%%I %CC% || goto :error
)

:link

del xrick.lib

echo makelib xrick.lib

FOR %%I IN (%SOURCEFILES%) DO (
	call :appendobj %%I
	rem	echo iix makelib -P xrick.lib +obj:%%I.a
	set CFILE=%%I
	iix makelib -P xrick.lib +obj:%%I.a || goto :error3
)

iix makelib -P xrick.lib +e1.obj

echo Linking xrick.s16
rem echo %OBJFILES%
set CFILE=xrick.s16
iix link +L obj\xrick.c xrick.lib keep=xrick || goto :error2
rem iix -DKeepType=S16 link +L +S %OBJFILES% keep=xrick || goto :error2 

goto :eof

:error3
	echo !!ERROR adding object: %CFILE%
	exit /B 1

:error2
	echo !!ERROR Linking: %CFILE%
	exit /B 1

:error
	echo !!ERROR Compiling: %CFILE%
	exit /B 1

:eof


