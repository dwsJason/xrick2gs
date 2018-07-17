
                 MX   %00

*-------------------------------------------------------------------------------
LZ4_Unpack       STA  LZ4_Literal_3+1   ; Uncompress a LZ4 Packed Data buffer (64 KB max)
                 SEP  #$20              ; A = Bank Src,Bank Dst
                 STA  LZ4_Match_5+1     ; X = Header Size = 1st Packed Byte offset
                 STA  LZ4_Match_5+2     ; Y = Pack Data Size
                 XBA                    ;  => Return in A the length of unpacked Data
                 STA  LZ4_ReadToken+3   
                 STA  LZ4_Match_1+3     
                 STA  LZ4_GetLength_1+3 
                 REP  #$30 
                 STY  LZ4_Limit+1
*--
                 LDY  #$0000            ; Init Target unpacked Data offset
LZ4_ReadToken    LDAL $AA0000,X         ; Read Token Byte
                 INX
                 STA  LZ4_Match_2+1
*----------------
LZ4_Literal      AND  #$00F0            ; >>> Process Literal Bytes <<<
                 BEQ  LZ4_Limit         ; No Literal
                 CMP  #$00F0
                 BNE  LZ4_Literal_1
                 JSR  LZ4_GetLengthLit  ; Compute Literal Length with next bytes
                 BRA  LZ4_Literal_2
LZ4_Literal_1    LSR                    ; Literal Length use the 4 bit
                 LSR
                 LSR
                 LSR
*--
LZ4_Literal_2    DEC                    ; Copy A+1 Bytes
LZ4_Literal_3    MVN  $AA,$BB           ; Copy Literal Bytes from packed data buffer
                 PHK                    ; X and Y are auto incremented
                 PLB
*----------------
LZ4_Limit        CPX  #$AAAA            ; End Of Packed Data buffer ?
                 BEQ  LZ4_End
*----------------
LZ4_Match        TYA                    ; >>> Process Match Bytes <<<
                 SEC
LZ4_Match_1      SBCL $AA0000,X         ; Match Offset
                 INX
                 INX
                 STA  LZ4_Match_4+1
*--
LZ4_Match_2      LDA  #$0000            ; Current Token Value
                 AND  #$000F
                 CMP  #$000F
                 BNE  LZ4_Match_3
                 JSR  LZ4_GetLengthMat  ; Compute Match Length with next bytes
LZ4_Match_3      CLC
                 ADC  #$0003            ; Minimum Match Length is 4 (-1 for the MVN)
*--
                 PHX
LZ4_Match_4      LDX  #$AAAA            ; Match Byte Offset
LZ4_Match_5      MVN  $BB,$BB           ; Copy Match Bytes from unpacked data buffer
                 PHK                    ; X and Y are auto incremented
                 PLB
                 PLX
*----------------
                 BRA  LZ4_ReadToken
*----------------
LZ4_GetLengthLit LDA  #$000F            ; Compute Variable Length (Literal or Match)
LZ4_GetLengthMat STA  LZ4_GetLength_2+1
LZ4_GetLength_1  LDAL $AA0000,X         ; Read Length Byte
                 INX
                 AND  #$00FF
                 CMP  #$00FF
                 BNE  LZ4_GetLength_3
                 CLC
LZ4_GetLength_2  ADC  #$000F
                 STA  LZ4_GetLength_2+1
                 BRA  LZ4_GetLength_1
LZ4_GetLength_3  ADC  LZ4_GetLength_2+1
                 RTS
*----------------
LZ4_End          TYA                    ; A = Length of Unpack Data
                 RTS
*-------------------------------------------------------------------------------
