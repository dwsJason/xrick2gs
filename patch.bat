rem 
rem $ printf '\x31\xc0\xc3' | dd of=test_blob bs=1 seek=100 count=3 conv=notrunc 
rem dd arguments:
rem 
rem of | file to patch
rem bs | 1 byte at a time please
rem seek | go to position 100 (decimal)
rem conv=notrunc | don't truncate the output after the edit (which dd does by default)


