#
# xrick2gs/Makefile
#

# This makefile was created by Jason Andersen
#
# I build on Windows-10 64-bit, this makefile is designed to run under
# a Windows-10 Command Prompt, and makes use of DOS shell commands
#
# In order to build this you need GoldenGate, and ORCA/C
#
# http://golden-gate.ksherlock.com/
#
# I have the contents  of the OPUS-II collection installed
#
# As far a free stuff, I setup a c:\bin directory, in my path
# the following packages and executables are in there
#
# Fine Tools from Brutal Deluxe
# http://www.brutaldeluxe.fr/products/crossdevtools/
# Cadius.exe
# Merlin32.exe
# OMFAnalyzer.exe
# LZ4.exe
#
# gnumake-4.2.1-x64.exe (with a symbolic link that aliases this to "make")
#
# https://apple2.gs/plus/
# gsplus32.exe (KEGS based GS Emulator fork by Dagen Brock)
# I configure this to boot the xrick.po image directly
# once that's done "make run" will build, update the disk image
# and boot into xrick2gs.
#

# Make and Build Variables

VPATH = src:obj
SOURCEFILES = $(wildcard src/*.c)
ASMFILES = $(wildcard asm/*.s)
OBJFILES = $(patsubst src/%.c,obj/%.a,$(SOURCEFILES))
OBJFILES += $(patsubst asm/%.s,obj/%.a,$(ASMFILES))
CC = iix compile
CFLAGS = cc=-DIIGS=1 cc=-Iinclude cc=-Isrc
# List of directories to create
DIRS=obj

help:
	@echo. 
	@echo xrickgs Makefile
	@echo -------------------------------------------------
	@echo build commands:
	@echo    make gs     - Apple IIgs
	@echo    make image  - Build Bootable .PO File
	@echo    make run    - Build / Run IIgs on emulator
	@echo    make clean  - Clean intermediate/target files
	@echo    make depend - Build dependencies
	@echo -------------------------------------------------
	@echo.

xrick.lib: $(OBJFILES)
	@echo Y | del xrick.lib
	iix makelib -P xrick.lib $(patsubst %,+%,$(OBJFILES))
#	iix makelib -P xrick.lib test.obj

xrick.sys16: xrick.lib
#	iix link +L obj\xrick xrick.lib keep=xrick.sys16
	iix link obj\xrick xrick.lib data.lib keep=xrick.sys16

gs: xrick.sys16

disk image: gs
	@echo Updating xrick.po
	@echo Remove xrick.sys16
	cadius deletefile xrick.po /xrick/xrick.sys16
	@echo Add xrick.sys16
	cadius addfile xrick.po /xrick ./xrick.sys16

run: image
	gsplus32

clean:
	@echo Remove xrick.sys16
	$(shell if exist xrick.sys16 echo Y | del xrick.sys16)
	@echo Remove Intermediate Files
	@del /q obj\*
	$(shell if exist xrick.lib echo Y | del xrick.lib)

depend:
	@echo TODO - make dependencies

# Generic Rules
#objdir: obj

# Goofy Object File Rule for ORCA
obj/%.a : src/%.c
	@echo Compiling $(<F)
	@$(CC) -P -I +O $< keep=$(basename $@) $(CFLAGS)

obj/%.a : asm/%.s
	@echo Assembling $(<F)
	@$(CC) -P -I +O $< keep=$(basename $@) $(CFLAGS)

# Create all the directories
$(shell if not exist $(DIRS) mkdir $(DIRS))
