; *******************************************************************
; *** This software is copyright 2021 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

; ************************************************
; ***** 64-bit Add.    M[R7]=M[R7]+M[R8]     *****
; ***** Numbers in memory stored LSB first   *****
; ************************************************
add64:   push     r7                ; save consumed registers
         push     r8
         ldi      8                 ; 8 bytes to process
         plo      re
         sex      r8                ; point x to second number
         adi      0                 ; clear DF
add64lp: ldn      r7                ; get lsb
         adc                        ; add byte of second number
         str      r7                ; store it
         inc      r7                ; point to 2nd byte
         inc      r8
         dec      re                ; decrement count
         glo      re                ; see if done
         lbnz     add64lp           ; loop until all bytes processed
         sex      r2                ; restore stack
         pop      r8                ; restore consumed registers
         pop      r7
         sep      sret              ; return to caller
        
    

; ************************************************
; ***** 64-bit subtract.  M[R7]=M[R7]-M[R8]  *****
; ***** Numbers in memory stored LSB first   *****
; ************************************************
sub64:   push     r7                ; save consumed registers
         push     r8
         ldi      8                 ; 8 bytes to process
         plo      re
         sex      r8                ; point x to second number
         smi      0                 ; set DF for first subtract
sub64lp: ldn      r7                ; get lsb
         smb                        ; subtract byte of second number
         str      r7                ; store it
         inc      r7                ; point to 2nd byte
         inc      r8
         dec      re                ; decrement count
         glo      re                ; see if done
         lbnz     sub64lp           ; loop back if not
         sex      r2                ; restore stack
         pop      r8                ; restore consumed registers
         pop      r7
         sep      sret              ; return to caller
        

    
; ************************************************
; ***** 64-bit Inc.  M[RF]=M[RF]+1           *****
; ***** Numbers in memory stored LSB first   *****
; ************************************************
inc64:   ldn      rf                ; get lsb
         adi      1                 ; add 1
         str      rf                ; store it
         inc      rf                ; point to next byte
         ldi      7                 ; 7 further bytes to process
         plo      re
inc64lp: ldn      rf                ; get second byte
         adci     0                 ; propagate carry
         str      rf                ; store it
         inc      rf                ; point to 3rd byte
         dec      re                ; decrement count
         glo      re                ; check if done
         lbnz     inc64lp           ; loop back if not
         sep      sret              ; and return


    
; ************************************************
; ***** 64-bit Dec.  M[RF]=M[RF]-1           *****
; ***** Numbers in memory stored LSB first   *****
; ************************************************
dec64:   ldn      rf                ; get lsb
         smi      1                 ; subtract 1
         str      rf                ; store it
         inc      rf                ; point to next byte
         ldi      7                 ; 7 more bytes to process
         plo      re
dec64lp: ldn      rf                ; get second byte
         smbi     0                 ; propagate borrow
         str      rf                ; store it
         inc      rf                ; point to 3rd byte
         dec      re                ; decrement count
         glo      re                ; see if done
         lbnz     dec64lp           ; loop back if not
         sep      sret              ; and return


; ************************************************
; ***** 64-bit cmp.  M[R7]-M[R8]             *****
; ***** Numbers in memory stored LSB first   *****
; ***** Returns: D=0 if M[R7]=M[R8]          *****
; *****          DF=1 if M[R7]<M[R8]         *****
; ************************************************
cmp64:   push     r7                ; save registers
         push     r8
         glo      r9                ; need this register too
         stxd
         ldi      0                 ; clear zero test
         plo      re
         ldi      8                 ; 8 bytes to process
         plo      r9
         smi      0                 ; set DF for first subtract
cmp64lp: lda      r8                ; get byte from second number
         str      r2                ; store for subtract
         lda      r7                ; get byte from first number
         smb                        ; subtract
         str      r2                ; store to combine with zero test
         glo      re                ; get zero test
         or                         ; combine with last subtract
         plo      re                ; keep it
         dec      r9                ; decrement count
         glo      r9                ; see if done
         lbnz     cmp64lp           ; loop back if not
         ldxa                       ; get final byte
         shl                        ; shift sign bit into DF
         ldx
         plo      r9
         pop      r8                ; recover consumed registers
         pop      r7
         glo      re                ; get zero test
         sep      sret              ; return to caller

; ************************************************
; ***** 64-bit cmp.  M[R8]-M[R7]             *****
; ***** Numbers in memory stored LSB first   *****
; ***** Returns: D=0 if M[R7]=M[R8]          *****
; *****          DF=1 if M[R8]<M[R7]         *****
; ************************************************
icmp64:  push     r7                ; save registers
         push     r8
         glo      r9                ; need this register too
         stxd
         ldi      0                 ; clear zero test
         plo      re
         ldi      8                 ; 8 bytes to process
         plo      r9
         smi      0                 ; set DF for first subtract
icmp64l: lda      r8                ; get byte from second number
         str      r2                ; store for subtract
         lda      r7                ; get byte from first number
         sdb                        ; subtract
         str      r2                ; store to combine with zero test
         glo      re                ; get zero test
         or                         ; combine with last subtract
         plo      re                ; keep it
         dec      r9                ; decrement count
         glo      r9                ; see if done
         lbnz     icmp64l           ; loop back if not
         ldxa                       ; get final byte
         shl                        ; shift sign bit into DF
         ldx
         plo      r9
         pop      r8                ; recover consumed registers
         pop      r7
         glo      re                ; get zero test
         sep      sret              ; return to caller


; ***************************************
; ***** is zero check               *****
; ***** returnss: DF=1 if M[RF]=0   *****
; ***************************************
iszero:  ldi      8                 ; 8 bytes to check
         plo      re
zerolp:  lda      rf                ; get next byte
         lbnz     notzero           ; jump if not zero
         dec      re                ; decrement count
         glo      re                ; see if done
         lbnz     zerolp            ; loop back if not
         smi      0                 ; signal number was zero
         sep      sret              ; and return
notzero: adi      0                 ; number was not zero
         sep      sret              ; and return

        
; ***************************************
; ***** M[RF] = 0                   *****
; ***************************************
null64:  ldi      8                 ; 8 bytes to zero
         plo      re
nulllp:  ldi      0                 ; need to zero
         str      rf                ; store into destination
         inc      rf                ; next position
         dec      re                ; decrement count
         glo      re                ; see if done
         lbnz     nulllp            ; loop back if not
         sep      sret              ; return to caller

    
; *************************************************
; ***** Check if M[RF] is negative            *****
; ***** Returns: DF=1 if number is negative   *****
; *************************************************
isneg64: inc      rf                ; point to msb
         inc      rf
         inc      rf
         inc      rf
         inc      rf
         inc      rf
         inc      rf
         ldn      rf                ; retrieve msb
         shl                        ; shift sign bit into df
         sep      sret              ; and return


; *********************************************
; ***** 2s compliment the number in M[RF] *****
; *********************************************
comp2s:  ldi      8                 ; need to work on 8 bytes
         plo      re
         smi      1                 ; first add needs to add 1
comp2lp  ldn      rf                ; get byte
         xri      0ffh              ; invert it
         adci     0                 ; propagate carry
         str      rf                ; write back
         inc      rf                ; and move to next byte
         dec      re                ; decrement count
         glo      re                ; see if done
         lbnz     comp2lp           ; loop back if not
         sep      sret              ; return


; ************************************************
; ***** 64-bit shift left.  M[RF]=M[RF]<<1   *****
; ***** Numbers in memory stored LSB first   *****
; ************************************************
shl64:   ldi      8                 ; 8 bytes to shift
         plo      re
         adi      0                 ; clear DF for first shift
shl64lp: ldn      rf                ; get byte from number
         shlc                       ; perform shift
         str      rf                ; put it back
         inc      rf                ; move to next byte
         dec      re                ; decrement count
         glo      re                ; see if done
         lbnz     shl64lp           ; loop back if not
         sep      sret              ; and return

    

; ************************************************
; ***** 64-bit shift right. M[RF]=M[RF]>>1   *****
; ***** Numbers in memory stored LSB first   *****
; ************************************************
shr64:   inc      rf                ; point to msb
         inc      rf
         inc      rf
         inc      rf
         inc      rf
         inc      rf
         inc      rf
         ldi      8                 ; 8 bytes to shift
         plo      re
         adi      0                 ; clear DF for first shift
shr64lp: ldn      rf                ; get byte from number
         shrc                       ; shift it
         str      rf                ; put it back
         dec      rf                ; move to prior byte
         dec      re                ; decrement count
         glo      re                ; see if done
         lbnz     shr64lp           ; loop back if not
         sep      sret              ; return to caller

; ***********************************************************
; ***** normalize M[R7] and M[R8] for multiply/division *****
; ***** Returns: D=0 - signs are the same               *****
; *****          D=1 - signs are different              *****
; *****          negative numbers converted to positive *****
; ***********************************************************
norm64:  ldi      0                 ; signal signs are the same
         stxd                       ; save on stack
         push     r7                ; save r7
         inc      r7                ; move to msb
         inc      r7
         inc      r7
         inc      r7
         inc      r7
         inc      r7
         inc      r7
         ldn      r7                ; get byte from first number
         plo      re
         pop      r7                ; recover R7
         glo      re
         shl                        ; is it negative
         lbnf     nrm64n1           ; jump if not
         irx                        ; set sign
         ldi      1
         stxd
         mov      rf,r7             ; point to first number
         sep      scall             ; and 2s compliment it
         dw       comp2s
nrm64n1: push     r8                ; save R8
         inc      r8                ; move to msb
         inc      r8
         inc      r8
         inc      r8
         inc      r8
         inc      r8
         inc      r8
         ldn      r8                ; get msb of second number
         plo      re
         pop      r8                ; recover R8
         glo      re
         shl                        ; is it negative
         lbnf     nrm64n2           ; jump if not
         irx                        ; point to sign flag
         ldi      1                 ; combine 2nd number sign
         xor
         stxd                       ; and save it
         mov      rf,r8             ; point rf to second number
         sep      scall             ; and 2s compliment it
         dw       comp2s
nrm64n2: irx                        ; recover signs flag
         ldx
         sep      sret              ; and return to caller


; ************************************************
; ***** 64-bit multiply. M[R7]=M[R7]*M[R8]   *****
; ***** Numbers in memory stored LSB first   *****
; ***** In routine:                          *****
; *****    R7 - points to answer             *****
; *****    R9 - points to first number       *****
; *****    R8 - points to second number      *****
; ************************************************
mul64:   sep      scall             ; normalize numbers
         dw       norm64
         stxd                       ; store signs flag
         push     r8                ; save pointers
         push     r7
         ldi      0                 ; need to zero answer
         stxd
         stxd
         stxd
         stxd
         stxd
         stxd
         stxd
         stxd
         mov      r9,r7             ; rf will point to first number
         mov      r7,r2             ; r7 will point to where the answer is
         inc      r7                ; point to LSB of answer
scmul2:  mov      rf,r8             ; need second number
         sep      scall             ; check for zero
         dw       iszero
         lbnf     scmul4            ; jump if number was not zero
         inc      r2                ; now pointing at lsb of answer
         ldi      8                 ; 8 bytes to transfer
         plo      re
scmul2a: lda      r2                ; get byte from result
         str      r9                ; store into answer
         inc      r9                ; point to next byte
         dec      re                ; decrement count
         glo      re                ; see if done
         lbnz     scmul2a           ; jump if not
         dec      r2                ; undo last increment
         pop      r7                ; recover pointers
         pop      r8
         irx                        ; get sign
         ldx
         lbz      scmulp            ; jump if positive answer
         mov      rf,r7             ; point to answer
         sep      scall             ; and 2s compliment it
         dw       comp2s
scmulp:  sep      sret              ; return to caller
scmul4:  ldn      r8                ; get lsb of second number
         shr                        ; shift low bit into df
         lbnf     scmulno           ; no add needed
         push     r7                ; save position of first number
         push     r8                ; save position of second number
         mov      r8,r9             ; r8 needs to be first number
         sep      scall             ; call add routine
         dw       add64
         pop      r8                ; recover positions
         pop      r7
scmulno: mov      rf,r9             ; point to first number
         sep      scall             ; shift left
         dw       shl64
         mov      rf,r8             ; now need pointer to second number
         sep      scall             ; shift right
         dw       shr64
         lbr      scmul2            ; loop until done


; ************************************************
; ***** 64-bit division. M[R7]=M[R7]/M[R8]   *****
; ***** D = number of bytes in integer       *****
; ***** Numbers in memory stored LSB first   *****
; ***** In routine:                          *****
; *****    R7=a                              *****
; *****    R8=b                              *****
; *****    RA=result                         *****
; *****    RB=shift                          *****
; ************************************************
div64:   sep      scall             ; normalize numbers
         dw       norm64
         stxd                       ; save sign flag
         dec      r2                ; reserve bytes on stack for result
         dec      r2
         dec      r2
         dec      r2
         dec      r2
         dec      r2
         dec      r2
         mov      ra,r2             ; set RA here
         dec      r2
         mov      rf,ra             ; point to result
         sep      scall             ; set answer to 0
         dw       null64            ; set to zero
         ldi      1                 ; set shift to 1
         plo      rb
scdiv1:  sep      scall             ; compare a to b
         dw       icmp64
         lbnf     scdiv4            ; jump if b>=a
         mov      rf,r8             ; need to shift b
         sep      scall 
         dw       shl64
         inc      rb                ; increment shift
         lbr      scdiv1            ; loop until b>=a
scdiv4:  mov      rf,r7             ; point to a
         sep      scall             ; is a zero
         dw       iszero
         lbdf     scdivd1           ; jump if it was zero
         mov      rf,r8             ; point to b
         sep      scall             ; is b zero
         dw       iszero
         lbdf     scdivd1           ; jump if so
         mov      rf,ra             ; point to result
         sep      scall             ; need to shift result left
         dw       shl64
         sep      scall             ; compare a to b
         dw       cmp64
         lbdf     scdiv6            ; jump if a < b
         ldn      ra                ; get LSB of result
         ori      1                 ; set low bit
         str      ra                ; and but it back
         sep      scall             ; subtract a from b
         dw       sub64
scdiv6:  ldn      r8                ; get lsb of b
         shr                        ; see if low bit is set
         lbnf     scdiv5            ; jump if not
         dec      rb                ; mark final shift
         lbr      scdivd1           ; and then done
scdiv5:  mov      rf,r8             ; point to b
         sep      scall             ; need to shift b right
         dw       shr64
         dec      rb                ; decrement shift
         lbr      scdiv4            ; loop back until done
scdivd1: glo      rb                ; get shift
         shl                        ; shift sign into df
         lbdf     scdivd2           ; jump if so
scdivd3: glo      rb                ; get shift
         lbz      scdivdn           ; jump if zero
         mov      rf,ra             ; point to result
         sep      scall             ; shift it left
         dw       shl64
         dec      rb                ; decrement shift
         lbr      scdivd3           ; loop back
scdivd2: glo      rb                ; get shift
         lbz      scdivdn           ; jump if zero
         mov      rf,ra             ; point to result
         sep      scall             ; shift it right
         dw       shr64
         inc      rb                ; increment shift
         lbr      scdivd2
scdivdn: push     r7                ; save answer position
         ldi      8                 ; 8 bytes to transfer
         plo      r9
scdivd5: lda      ra                ; get result byte
         str      r7                ; store into answer
         inc      r7
         dec      r9                ; decrement count
         glo      r9                ; see if done
         lbnz     scdivd5           ; jump if not
         pop      r7                ; recover answer
         glo      ra                ; need to clean up the stack
         plo      r2
         ghi      ra
         phi      r2
         ldn      r2                ; were signs different
         lbz      div64p            ; jump if not
         mov      rf,r7
         sep      scall             ; 2s compliment result
         dw       comp2s
div64p:  sep      sret              ; return to caller


; *****************************************
; ***** Convert R7:R8 to bcd in M[RF] *****
; *****************************************
tobcd:     push    rf           ; save address
           ldi     20           ; 20 bytes to clear
           plo     re
tobcdlp1:  ldi     0
           str     rf           ; store into answer
           inc     rf
           dec     re           ; decrement count
           glo     re           ; get count
           lbnz    tobcdlp1     ; loop until done
           pop     rf           ; recover address
           ldi     64           ; 64 bits to process
           plo     r9
tobcdlp2:  ldi     20           ; need to process 20 cells
           plo     re           ; put into count
           push    rf           ; save address
tobcdlp3:  ldn     rf           ; get byte
           smi     5            ; need to see if 5 or greater
           lbnf    tobcdlp3a    ; jump if not
           adi     8            ; add 3 to original number
           str     rf           ; and put it back
tobcdlp3a: inc     rf           ; point to next cell
           dec     re           ; decrement cell count
           glo     re           ; retrieve count
           lbnz    tobcdlp3     ; loop back if not done
           push    rf           ; save RF
           mov     rf,r7        ; need to shift input number
           sep     scall
           dw      shl64
           pop     rf           ; recover RF
           shlc                 ; now shift result to bit 3
           shl
           shl
           shl
           str     rf
           pop     rf           ; recover address
           push    rf           ; save address again
           ldi     20           ; 20 cells to process
           plo     re
tobcdlp4:  lda     rf           ; get current cell
           str     r2           ; save it
           ldn     rf           ; get next cell
           shr                  ; shift bit 3 into df
           shr
           shr
           shr
           ldn     r2           ; recover value for current cell
           shlc                 ; shift with new bit
           ani     0fh          ; keep only bottom 4 bits
           dec     rf           ; point back
           str     rf           ; store value
           inc     rf           ; and move to next cell
           dec     re           ; decrement count
           glo     re           ; see if done
           lbnz    tobcdlp4     ; jump if not
           pop     rf           ; recover address
           dec     r9           ; decrement bit count
           glo     r9           ; see if done
           lbnz    tobcdlp2     ; loop until done
           sep     sret         ; return to caller

; ***************************************************
; ***** Print number in M[R7] as signed integer *****
; ***************************************************
itoa64:    push    rf           ; save consumed registers
           push    r8
           push    rf           ; save RF
           mov     rf,r7        ; is number negative
           sep     scall
           dw      isneg64
           pop     rf           ; recover RF
           lbnf    itoa2s       ; jump if not
           ldi     '-'          ; output negative sign
           sep     scall
           dw      f_type
           push    rf           ; save RF
           mov     rf,r7        ; point to number
           sep     scall        ; 2s complement number
           dw      comp2s
           pop     rf           ; recover RF
itoa2s:    glo     r2           ; make room on stack for buffer
           smi     21
           plo     r2
           ghi     r2
           smbi    0
           phi     r2
           mov     rf,r2        ; RF is output buffer
           inc     rf
itoa1:     sep     scall        ; convert to bcd
           dw      tobcd
           mov     rf,r2
           inc     rf
           ldi     20
           plo     r8
           ldi     19           ; max 19 leading zeros
           phi     r8
loop1:     lda     rf
           lbz     itoaz        ; check leading zeros
           str     r2           ; save for a moment
           ldi     0            ; signal no more leading zeros
           phi     r8
           ldn     r2           ; recover character
itoa2:     adi     030h
           sep     scall
           dw      f_type
itoa3:     dec     r8
           glo     r8
           lbnz    loop1
           glo     r2           ; pop work buffer off stack
           adi     21
           plo     r2
           ghi     r2
           adci    0
           phi     r2
           pop     r8           ; recover consumed registers
           pop     rf
           sep     sret         ; return to caller
itoaz:     ghi     r8           ; see if leading have been used up
           lbz     itoa2        ; jump if so
           smi     1            ; decrement count
           phi     r8
           lbr     itoa3        ; and loop for next character

; ************************************
; ***** Convert ascii to int64   *****
; ***** RF - buffer to ascii     *****
; ***** R7 - Where to put number *****
; ***** Uses: RA - digits msb    *****
; *****       R9 - counters      *****
; ************************************
atoi64:    push    rf           ; save buffer
           mov     rf,r7        ; set answer to zero
           sep     scall
           dw      null64
           pop     rf           ; recover buffer
           ldi     0            ; signal positive number
           str     r2
           ldn     rf           ; get byte from ascii
           smi     '-'          ; check for negative sign
           lbnz    atoip        ; jump if not
           inc     rf           ; move past minus sign
           ldi     1            ; signal negative number
           str     r2           ; save flag
atoip:     dec     r2
           mov     ra,r2        ; keep the last position for moment
           ldi     20           ; need 20 work bytes on the stack
           plo     re
atoi1:     ldi     0            ; put a zero on the stack
           stxd
           dec     re           ; decrement count
           glo     re           ; see if done
           lbnz    atoi1        ; loop until done
           ldi     0            ; need to get count of characters
           plo     re
atoi2:     ldn     rf           ; get character from RF
           smi     '0'          ; see if below digits
           lbnf    atoi3        ; jump if not valid digit
           ldn     rf           ; recover byte
           smi     '9'+1        ; check if above digits
           lbdf    atoi3        ; jump if not valid digit
           inc     rf           ; point to next character
           inc     re           ; increment count
           lbr     atoi2        ; loop until non character found
atoi3:     glo     re           ; were any valid digits found
           lbnz    atoi4        ; jump if so
atoidn:    glo     r2           ; clear work bytes off stack
           adi     21
           plo     r2
           ghi     r2
           adci    0
           phi     r2
           ldn     r2           ; get sign flag
           lbz     atoidn2      ; jump if positive
           push    rf           ; save RF
           mov     rf,r7
           sep     scall        ; 2s compliment the number
           dw      comp2s
           pop     rf           ; recover RF
atoidn2:   sep     sret         ; and return to caller
atoi4:     dec     rf           ; move back to last valid character
           ldn     rf           ; get digit
           smi     030h         ; convert to binary
           str     ra           ; store into work space
           dec     ra
           dec     re           ; decrement count
           glo     re           ; see if done
           lbnz    atoi4        ; loop until all digits copied
           ldi     64           ; 64 bits to process
           plo     r9
atoi5:     ldi     20           ; need to shift 20 cells
           plo     re
           mov     ra,r2        ; point to msb
           inc     ra
           ldi     0            ; clear carry bit
           shr
atoi6:     ldn     ra           ; get next cell
           lbnf    atoi6a       ; Jump if no need to set a bit
           ori     16           ; set the incoming bit
atoi6a:    shr                  ; shift cell right
           str     ra           ; store new cell value
           inc     ra           ; move to next cell
           dec     re           ; decrement cell count
           glo     re           ; see if done
           lbnz    atoi6        ; loop until all cells shifted
           ldi     0            ; want DF as high bit of D
           shrc
           stxd                 ; save this for now
           push    rf           ; save rf
           mov     rf,r7        ; need to shift answer right
           sep     scall        ; shift it
           dw      shr64
           pop     rf           ; recover rf
           inc     r7           ; move to msb
           inc     r7
           inc     r7
           inc     r7
           inc     r7
           inc     r7
           inc     r7
           ldn     r7           ; retrieve msb
           irx                  ; move x to last bit
           or                   ; and combine with msb
           str     r7           ; and put it back
           dec     r7           ; restore R7
           dec     r7
           dec     r7
           dec     r7
           dec     r7
           dec     r7
           dec     r7
           ldi     20           ; need to check 20 cells
           plo     re
           mov     ra,r2        ; point ra to msb
           inc     ra
atoi7:     ldn     ra           ; get cell value
           ani     8            ; see if bit 3 is set
           lbz     atoi7a       ; jump if not
           ldn     ra           ; recover value
           smi     3            ; minus 3
           str     ra           ; put it back
atoi7a:    inc     ra           ; point to next cell
           dec     re           ; decrement cell count
           glo     re           ; see if done
           lbnz    atoi7        ; loop back if not
           dec     r9           ; decrement bit count
           glo     r9           ; see if done
           lbnz    atoi5        ; loop back if more bits
           lbr     atoidn       ; otherwise done
 
