; *******************************************************************
; *** This software is copyright 2020 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

; **********************************
; ***** Floating point library *****
; **********************************

fpdot1:    db      0cdh, 0cch, 0cch, 03dh
fp_0:      db      00,00,00,00
fp_1:      db      00,00,080h,03fh
fp_2:      db      00,00,000h,040h
fp_10:     db      00,00,020h,041h
fp_100:    db      00,00,0c8h,042h
fp_1000:   db      00,00,07ah,044h
fp_e:      db      054h, 0f8h, 02dh, 040h
fp_pi:     db      0dbh, 00fh, 049h, 040h
fp_3:      db      00,00,040h,040h
fpdot5:    db      000h, 000h, 000h, 03fh
fp_halfpi: db      0dbh, 00fh, 0c9h, 03fh

; ******************************************
; ***** 2's compliment number in r7:r8 *****
; ******************************************
fpcomp2:   glo     r8           ; perform 2s compliment on input
           xri     0ffh
           adi     1
           plo     r8
           ghi     r8
           xri     0ffh
           adci    0
           phi     r8
           glo     r7
           xri     0ffh
           adci    0
           plo     r7
           ghi     r7
           xri     0ffh
           adci    0
           phi     r7
           sep     sret

; ****************************************************
; ***** Convert 32-bit integer to floating point *****
; ***** RF - Pointer to 32-bit integer           *****
; ***** RD - Destination floating point          *****
; ****************************************************
itof:      lda     rf           ; retrieve 32-bit integer into r7:r8
           plo     r8
           str     r2           ; store for zero check
           lda     rf
           phi     r8
           or                   ; combine with zero check
           str     r2           ; keep zero check on stack
           lda     rf
           plo     r7
           or
           str     r2
           lda     rf           ; MSB
           phi     r7
           or
           lbz     itof0        ; jump if input number is zero
           ldi     0            ; set sign flag
           str     r2
           ghi     r7           ; see if number is negative
           shl                  ; shift sign bit into DF
           lbnf    itof_p       ; jump if number is positive
           ldi     1            ; set sign flag
           stxd
           sep     scall        ; 2s compliment input number
           dw      fpcomp2
           irx                  ; point x back to sign flag
itof_p:    ldi     150          ; exponent starts at 150
           plo     re
itof_1:    ghi     r7           ; see if need right shifts
           lbz     itof_2       ; jump if not
           shr                  ; otherwise shift number right
           phi     r7
           glo     r7
           shrc
           plo     r7
           ghi     r8
           shrc
           phi     r8
           glo     r8
           shrc
           plo     r8
           inc     re           ; increment exponent
           lbr     itof_1       ; and loop to see if more shifts needed
itof_2:    glo     r7           ; see if we need left shifts
           ani     080h
           lbnz    itof_3       ; jump if no shifts needed
           glo     r8           ; shift number left
           shl
           plo     r8
           ghi     r8
           shlc
           phi     r8
           glo     r7
           shlc
           plo     r7
           ghi     r7
           shlc
           phi     r7
           dec     re           ; decrement exponent
           lbr     itof_2       ; and loop to see if more shifts needed
itof_3:    glo     r7           ; prepare to merge in exponent
           shl
           plo     r7
           glo     re           ; get exponent
           phi     r7           ; store into result
           shr                  ; shift it right 1 bit
           glo     r7
           shrc                 ; shift final exponent bit in
           plo     r7
           ldx                  ; recover sign flag
           shr                  ; shift it into DF
           ghi     r7           ; get msb of result
           shrc                 ; shift in sign bit
           phi     r7           ; and put it back
itof0:     glo     r8           ; store answer into destination
           str     rd
           inc     rd
           ghi     r8
           str     rd
           inc     rd
           glo     r7
           str     rd
           inc     rd
           ghi     r7
           str     rd
           sep     sret         ; and return

; *******************************************
; ***** Normalize and combine FP result *****
; ***** R7:R8 - Mantissa                *****
; ***** R9.0  - Exponent                *****
; ***** R9.1  - Sign                    *****
; ***** Returns: R7:R8 - FP number      *****
; *******************************************
fpnorm:    glo     r9           ; Get exponent
           lbz     fpnorm0      ; jump if zero
           glo     r8           ; zero check mantissa
           lbnz    fpnormnz     ; jump if not
           ghi     r8
           lbnz    fpnormnz
           glo     r7
           lbnz    fpnormnz
           ghi     r7
           lbnz    fpnormnz
fpnorm0:   ldi     0            ; set result to 0
           plo     r8
           phi     r8
           plo     r7
           phi     r7
           sep     sret         ; and return
fpnormi:   ldi     03fh         ; set infinity
           phi     r7
           ldi     080h
           plo     r7
           ldi     0
           phi     r8
           plo     r8
           sep     sret         ; and return
fpnormnz:  ghi     r7           ; check for need to right shift
           lbz     fpnorm_1     ; jump if no right shifts needed
           shr                  ; shift mantissa right
           phi     r7
           glo     r7
           shrc
           plo     r7
           ghi     r8
           shrc
           phi     r8
           glo     r8
           shrc
           plo     r8
           inc     r9           ; increment exponent
           glo     r9           ; get exponent
           smi     0ffh         ; check for exponent overflow
           lbz     fpnormi      ; jump if exponent overflow, returns 0
           lbr     fpnormnz     ; keep checking for bits too high in mantissa
fpnorm_1:  glo     r7           ; check for need to shift left
           shl                  ; shift high bit into DF
           lbdf    fpnorm_2     ; jump if high bit is set
           glo     r8           ; shift mantissa left
           shl
           plo     r8
           ghi     r8
           shlc
           phi     r8
           glo     r7
           shlc 
           plo     r7
           dec     r9           ; decrement exponent
           glo     r9           ; check for exponent underflow
           lbz     fpnorm0      ; jump if underflow occured
           lbr     fpnorm_1     ; loop until high bit set
fpnorm_2:  glo     r7           ; prepare mantissa for merging exponent
           shl
           plo     r7
           ghi     r9           ; get sign
           shr                  ; shift into DF
           glo     r9           ; get exponent
           shrc                 ; shift in sign
           phi     r7           ; place into answer
           glo     r7           ; get high byte of mantissa
           shrc                 ; shift in least bit from exponent
           plo     r7           ; and put back
           sep     sret         ; return to caller

; *********************************
; ***** Retrieve fp arguments *****
; ***** M[RF] -> R7:R8 R9.0   *****
; ***** M[RD] -> RA:RB R9.1   *****
; *********************************
fpargs:    lda     rf           ; retrieve first number
           plo     r8
           lda     rf
           phi     r8
           lda     rf
           plo     r7
           shl                  ; shift low bit of exponent
           lda     rf
           phi     r7
           shlc                 ; get full exponent
           plo     r9           ; save exponent 1
           lda     rd           ; retrieve second number
           plo     rb
           lda     rd
           phi     rb
           lda     rd
           plo     ra
           shl                  ; shift low bit of exponent
           lda     rd
           phi     ra
           shlc                 ; get full exponent
           phi     r9           ; save exponent 2
           sep     sret         ; return to caller

fpret_0:   pop     rf           ; recover destination address
           ldi     0            ; write 0
           str     rf
           inc     rf
           str     rf
           inc     rf
           str     rf
           inc     rf
           str     rf
           sep     sret         ; and return

fpret_a:   pop     rf           ; recover destination address
           glo     r8           ; store a as answer
           str     rf
           inc     rf
           ghi     r8
           str     rf
           inc     rf
           glo     r7
           str     rf
           inc     rf
           ghi     r7
           str     rf
           sep     sret         ; and return to caller

fpret_b:   pop     rf           ; recover destination address
           glo     rb           ; store a as answer
           str     rf
           inc     rf
           ghi     rb
           str     rf
           inc     rf
           glo     ra
           str     rf
           inc     rf
           ghi     ra
           str     rf
           sep     sret         ; and return to caller

; ********************************************
; ***** Floating point addition          *****
; ***** RF - pointer to first fp number  *****
; ***** RD - pointer to second fp number *****
; ***** Uses: R7:R8 - first number (aa)  *****
; *****       RA:RB - second number (bb) *****
; *****       R9.0  - exponent           *****
; *****       R9.1  - sign               *****
; ********************************************
fpadd:     push    rf           ; save destination address
           sep     scall        ; retrieve arguments
           dw      fpargs
fpsub_1:   lbz     fpret_a      ; return a if b==0
           smi     0ffh         ; check for infinity
           lbz     fpret_b      ; return b if b==infinity
           glo     r9           ; get exponent 1
           lbz     fpret_b      ; return b if a==0
           smi     0ffh         ; check for infinity
           lbz     fpret_a      ; return a if a==infinity
           glo     r9           ; get exponent 1
           str     r2           ; store for comparison
           ghi     r9           ; get exponent 2
           sm                   ; compare to exponent 1
           lbnf    fpadd_1      ; jump if b<a
           glo     r8           ; swap a and b
           plo     re
           glo     rb
           plo     r8
           glo     re
           plo     rb
           ghi     r8           ; swap a and b
           plo     re
           ghi     rb
           phi     r8
           glo     re
           phi     rb
           glo     r7           ; swap a and b
           plo     re
           glo     ra
           plo     r7
           glo     re
           plo     ra
           ghi     r7           ; swap a and b
           plo     re
           ghi     ra
           phi     r7
           glo     re
           phi     ra
           glo     r9           ; also swap exponents
           plo     re
           ghi     r9
           plo     r9
           glo     re
           phi     r9
fpadd_1:   ghi     r7           ; compare signs
           str     r2
           ghi     ra
           xor
           plo     rc           ; store operation, 0=+, 1=-
           ghi     r7           ; get sign of largest number
           phi     rc           ; save it for now
           ldi     0            ; clear high bytes of numbers
           phi     ra
           phi     r7
           glo     ra           ; set implied 1 bit
           ori     080h
           plo     ra
           glo     r7           ; in first number too
           ori     080h
           plo     r7
fpadd_2:   glo     r9           ; compare exponents
           str     r2
           ghi     r9
           sm
           lbz     fpadd_3;     ; jump if exponents match
           ghi     r9           ; increment exponent 2
           adi     1
           phi     r9
           ghi     ra           ; shift b right
           shr
           phi     ra
           glo     ra
           shrc
           plo     ra
           ghi     rb
           shrc
           phi     rb
           glo     rb
           shrc
           plo     rb
           lbr     fpadd_2      ; loop until exponents match
fpadd_3:   glo     rc           ; get operation
           shl                  ; shift into DF
           lbdf    fpadd_s      ; jump if subtraction
           glo     r8           ; a += b
           str     r2
           glo     rb
           add
           plo     r8
           ghi     r8
           str     r2
           ghi     rb
           adc
           phi     r8
           glo     r7
           str     r2
           glo     ra
           adc
           plo     r7
           ghi     r7
           str     r2
           ghi     ra
           adc
           phi     r7
           lbr     fpadd_4      ; jump to completion
fpadd_s:   glo     r8           ; a -= b
           str     r2
           glo     rb
           sd
           plo     r8
           ghi     r8
           str     r2
           ghi     rb
           sdb
           phi     r8
           glo     r7
           str     r2
           glo     ra
           sdb
           plo     r7
           ghi     r7
           str     r2
           ghi     ra
           sdb
           phi     r7
           shl                  ; need to check sign of answer
           lbnf    fpadd_4      ; jump if positive
           sep     scall        ; 2s compliment number
           dw      fpcomp2
           ghi     rc           ; compliment sign
           xri     080h
           phi     rc           ; put it back
fpadd_4:   ghi     rc           ; move sign to R9.1
           shl
           ldi     0
           shlc
           phi     r9
           ghi     r7           ; check for zero
           lbnz    fpadd_5
           glo     r7
           lbnz    fpadd_5
           ghi     r8
           lbnz    fpadd_5
           glo     r8
           lbnz    fpadd_5
           lbr     fpret_0      ; otherwise answer is 0
fpadd_5:   sep     scall        ; normalize the answer
           dw      fpnorm
           lbr     fpret_a      ; write answer and return


; ********************************************
; ***** Floating point subtraction       *****
; ***** RF - pointer to first fp number  *****
; ***** RD - pointer to second fp number *****
; ***** Uses: R7:R8 - first number (aa)  *****
; *****       RA:RB - second number (bb) *****
; *****       R9.0  - exponent           *****
; *****       R9.1  - sign               *****
; ********************************************
fpsub:     push    rf           ; save destination address
           sep     scall        ; retrieve arguments
           dw      fpargs
           ghi     ra           ; invert number
           xri     080h
           phi     ra           ; save inverted sign
           ghi     r9
           lbr     fpsub_1      ; now process with add


; ********************************************
; ***** Floating point multiplication    *****
; ***** RF - pointer to first fp number  *****
; ***** RD - pointer to second fp number *****
; ***** Uses: R7:R8 - answer       (cc)  *****
; *****       RA:RB - second number (bb) *****
; *****       R9.0  - exponent           *****
; *****       R9.1  - sign               *****
; *****       RC:RD - first number (aa)  *****
; ********************************************
fpmul:    push     rf           ; save destination addres
          lda      rd           ; retrieve second number
          plo      rb           ; place into bb
          lda      rd
          phi      rb
          lda      rd
          plo      ra
          shl                   ; shift high bit into DF
          lda      rd
          phi      ra
          shlc                  ; now have full 8 bits of exponent
          phi      r9           ; store into r9
          lbz      fpret_0      ; jump if number is zero
          lda      rf           ; retrieve first number
          plo      rd           ; place into aa
          lda      rf
          phi      rd
          lda      rf
          plo      rc
          shl                   ; shift high bit into DF
          lda      rf
          phi      rc
          shlc                  ; now have exponent of first number
          plo      r9           ; save it
          lbz      fpret_0      ; jump if number was zero
          glo      r9           ; get exponent of first number
          smi      0ffh         ; check for infinity
          lbz      fpmul_a      ; jump if so
          ghi      r9           ; get exponent of second number
          smi      0ffh         ; check for infinity
          lbz      fpmul_b      ; jump if so
          glo      r9           ; get exponent 1
          smi      127          ; remove bias
          str      r2           ; store for add
          ghi      r9           ; get exponent 2
          smi      127          ; remove bias
          add                   ; add in exponent 1
          adi      127          ; add bias back in
          plo      r9           ; r9 now has exponent of result
          ghi      ra           ; get msb of bb
          str      r2           ; store it
          ghi      rc           ; get msb of aa
          xor                   ; now have sign comparison
          shl                   ; shift sign into DF
          ldi      0            ; clear byte
          shlc                  ; shift in sign
          phi      r9           ; save sign for later
          ldi      0            ; need to clear high bytes
          phi      ra           ; of bb
          phi      rc           ; and aa
          plo      r8           ; also clear answer
          phi      r8
          plo      r7
          phi      r7
          glo      ra           ; get msb of bb mantissa
          ori      080h         ; add in implied 1
          plo      ra           ; and put it back
          glo      rc           ; get msb of aa mantissa
          ori      080h         ; add in implied 1
          plo      rc           ; and put it back
fpmul_lp: glo      ra           ; need to zero check bb
          str      r2
          ghi      ra
          or
          str      r2
          glo      rb
          or
          str      r2
          ghi      rb
          or
          lbz      fpmul_dn     ; jump of bb==0
          ghi      r7           ; cc >>= 1
          shr
          phi      r7
          glo      r7
          shrc
          plo      r7
          ghi      r8
          shrc
          phi      r8
          glo      r8
          shrc
          plo      r8
          ghi      ra           ; bb >>= 1
          shr
          phi      ra
          glo      ra
          shrc
          plo      ra
          ghi      rb
          shrc
          phi      rb
          glo      rb
          shrc
          plo      rb
          lbnf     fpmul_lp     ; back to loop if no addition needed
          glo      r8           ; cc += aa
          str      r2
          glo      rd
          add
          plo      r8
          ghi      r8
          str      r2
          ghi      rd
          adc
          phi      r8
          glo      r7
          str      r2
          glo      rc
          adc
          plo      r7
          ghi      r7
          str      r2
          ghi      rc
          adc
          phi      r7
          lbr      fpmul_lp     ; back to beginning of loop
fpmul_dn: sep      scall        ; assemble answer
          dw       fpnorm
          pop      rf           ; recover destination address
          glo      r8           ; store answer
          str      rf
          inc      rf
          ghi      r8
          str      rf
          inc      rf
          glo      r7
          str      rf
          inc      rf
          ghi      r7
          str      rf
          sep      sret         ; return to caller
fpmul_a:  pop      rf           ; recover destination address
          glo      rd           ; write a to answer
          str      rf
          inc      rf
          ghi      rd 
          str      rf
          inc      rf
          glo      rc
          str      rf
          inc      rf
          ghi      rc
          str      rf
          sep      sret         ; and return to caller
fpmul_b:  pop      rf           ; recover destination address
          glo      rb           ; write b to answer
          str      rf
          inc      rf
          ghi      rb 
          str      rf
          inc      rf
          glo      ra
          str      rf
          inc      rf
          ghi      ra
          str      rf
          sep      sret         ; and return to caller

          

; ********************************************
; ***** Floating point division          *****
; ***** RF - pointer to first fp number  *****
; ***** RD - pointer to second fp number *****
; ***** Uses: R7:R8 - answer       (a)   *****
; *****       RA:RB - second number (b)  *****
; *****       RA    - pointer to (aa)    *****
; *****       RB    - pointer to (bb)    *****
; *****       R9.0  - exponent           *****
; *****       R9.1  - sign               *****
; *****       RC:RD - mask               *****
; ********************************************
fpdiv:    push     rf           ; save destination address
          sep      scall        ; get arguments
          dw       fpargs
          glo      r9           ; check for a==0
          lbz      fpret_0      ; return 0 if so
          ghi      r9           ; check for b==0
          lbz      fpret_0      ; return 0 if so
          glo      r9           ; check for a==infinity
          smi      0ffh
          lbz      fpret_a      ; return a if so
          ghi      r9           ; check for b==infinity
          smi      0ffh
          lbz      fpret_b      ; return b if so
          ghi      r9           ; get exp2
          smi      127          ; remove bias
          str      r2           ; store for subtraction
          glo      r9           ; get exp1
          smi      127          ; remove bias
          sm                    ; subtract exp2
          adi      127          ; add bias back in
          plo      r9           ; now have final exp
          ghi      r7           ; get sign of a
          str      r2           ; store for xor
          ghi      ra           ; get sign of b
          xor                   ; now have sign comparison
          shl                   ; shift it into DF
          ldi      0            ; clear D
          shlc                  ; and shift in sign
          phi      r9           ; store sign
          glo      ra           ; put bb on stack
          ori      080h         ; set implied 1 bit
          stxd
          ghi      rb
          stxd
          glo      rb
          stxd
          ldi      0
          stxd
          stxd
          stxd
          mov      rb,r2        ; point RB to bb
          inc      rb
          glo      r7           ; put aa on stack
          ori      080h         ; set implied 1 bit
          stxd
          ghi      r8
          stxd
          glo      r8
          stxd
          ldi      0
          stxd
          stxd
          stxd
          mov      ra,r2        ; set RA to point to aa
          inc      ra
          ldi      0            ; clear a
          plo      r8
          phi      r8
          plo      r7
          phi      r7
          plo      rd           ; setup mask
          phi      rd
          phi      rc
          ldi      080h
          plo      rc
fpdiv_lp: glo      rd           ; need to check for mask==0
          lbnz     fpdiv_1      ; jump if not 0
          ghi      rd
          lbnz     fpdiv_1
          glo      rc
          lbnz     fpdiv_1
          sep      scall        ; division is done, so call normalize
          dw       fpnorm
          glo      r2           ; clear work space from stack
          adi      12
          plo      r2
          ghi      r2
          adci     0
          phi      r2
          lbr      fpret_a      ; and return the answer
fpdiv_1:  smi      0            ; set DF for first byte
          ldi      6            ; 6 bytes to subtract
          plo      re
          sex      rb           ; point x to bb
fpdiv_1a: lda      ra           ; get byte from aa
          smb                   ; subtract byte from bb from aa
          inc      rb           ; point to next byte
          dec      re           ; decrement count
          glo      re           ; see if done
          lbnz     fpdiv_1a     ; loop back if not
          ldi      6            ; need to move pointers back
          plo      re
fpdiv_1b: dec      ra
          dec      rb
          dec      re
          glo      re
          lbnz     fpdiv_1b
          lbnf     fpdiv_2      ; jump if b>a
          ldi      6            ; 6 bytes to subtract bb from aa
          plo      re
          smi      0            ; set DF for first subtract
fpdiv_1c: ldn      ra           ; get byte from a
          smb                   ; subtract bb
          str      ra           ; put it back
          inc      ra           ; increment pointers
          inc      rb
          dec      re           ; decrement byte count
          glo      re           ; see if done
          lbnz     fpdiv_1c     ; loop back if not
          ldi      6            ; need to move pointers back
          plo      re
fpdiv_1d: dec      ra
          dec      rb
          dec      re
          glo      re
          lbnz     fpdiv_1d
          sex      r2           ; point x back to stack
          glo      rc           ; add mask to answer
          str      r2
          glo      r7
          or
          plo      r7
          ghi      rd
          str      r2
          ghi      r8
          or
          phi      r8
          glo      rd
          str      r2
          glo      r8
          or
          plo      r8
fpdiv_2:  sex      r2           ; point x back to stack
          glo      rc           ; right shift mask
          shr
          plo      rc
          ghi      rd
          shrc
          phi      rd
          glo      rd
          shrc
          plo      rd
          inc      rb           ; need to start at msb of bb
          inc      rb
          inc      rb
          inc      rb
          inc      rb
          inc      rb
          ldi      6            ; 6 bytes in bb to shift right
          plo      re
          adi      0            ; clear DF for first shift
fpdiv_2a: dec      rb
          ldn      rb           ; get byte from bb
          shrc                  ; shift it right
          str      rb           ; and put it back
          dec      re           ; decrement count
          glo      re           ; see if done
          lbnz     fpdiv_2a     ; loop back if not
          lbr      fpdiv_lp     ; loop for rest of division

; ********************************************
; ***** Convert ASCII to floating point  *****
; ***** RF - Pointer to ASCII string     *****
; ***** RD - Desintation FP              *****
; ***** Uses:                            *****
; *****       R7:R8 - mantissa           *****
; *****       R9.0  - exponent           *****
; *****       R9.1  - sign               *****
; *****       RA:RB - mask               *****
; *****       RC    - fractional pointer *****
; ********************************************
; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; +++++ First convert integer portion to floating point +++++
; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
atof:     ldi      0            ; set sign to positive
          phi      r9
          ldn      rf           ; get first byte from buffer
          smi      '-'          ; is it minus
          lbnz     atof_1       ; jump if not
          ldi      1            ; indicate negative number
          phi      r9
          inc      rf           ; and move past minus
atof_1:   push     rd           ; save destination
          sep      scall        ; convert integer portion of number
          dw       atoi
          pop      rd           ; recover destination
          push     rd           ; save destination for later
          lda      rd           ; retrieve integer number
          plo      r8 
          str      r2           ; store for zero check
          lda      rd
          phi      r8
          or                    ; combine with zero check
          str      r2
          lda      rd
          plo      r7
          or                    ; combine with zero check
          str      r2
          lda      rd
          phi      r7
          or                    ; combine with zero check
          lbz      atof_z       ; jump if integer is zero
          ldi      150          ; initial exponent starts at 150
          plo      r9
          ldi      1            ; initial mask is 1
          plo      rb
          ldi      0
          phi      rb
          plo      ra
          phi      ra
          ghi      r7           ; check if high byte has anything
          lbz      atof_b       ; jump if not
atof_a1:  ghi      r7           ; get high byte
          lbz      atof_a2      ; jump if done shifting
          shr                   ; shift mantissa right
          phi      r7
          glo      r7
          shrc
          plo      r7
          ghi      r8
          shrc
          phi      r8
          glo      r8
          shrc
          plo      r8
          glo      r9           ; get exponent
          adi      1            ; increment it
          plo      r9           ; put it back
          lbr      atof_a1      ; loop until high byte cleared
atof_a2:  ldi      0            ; clear mask
          phi      ra
          plo      ra
          phi      rb
          plo      rb
          lbr      atof_2       ; and then jump to next section
atof_b:   glo      r7           ; get first byte of mantissa
          shl                   ; shift high bit into DF
          lbdf     atof_2       ; if set, no more shifts needed
          glo      r8           ; shift mantissa left
          shl
          plo      r8
          ghi      r8
          shlc
          phi      r8
          glo      r7
          shlc
          plo      r7
          glo      rb           ; shift mask left
          shl
          plo      rb
          ghi      rb
          shlc
          phi      rb
          glo      ra
          shlc
          plo      ra
          glo      r9           ; get exponent
          smi      1            ; decrement it
          plo      r9           ; and put it back
          lbr      atof_b       ; loop until high bit of mantissa set
atof_z:   ldi      080h         ; set initial mask
          plo      ra
          ldi      0
          phi      ra
          phi      rb
          plo      rb
          ldi      127          ; initial exponent
          plo      r9
; ++++++++++++++++++++++++++++++++++++++++++++++++++
; +++++ Now convert number after decimal point +++++
; ++++++++++++++++++++++++++++++++++++++++++++++++++
atof_2:   ldn      rf           ; get next byte from input
          smi      '.'          ; is it a decimal
          lbnz     atof_e       ; jump if not
          inc      rf           ; move past decimal
          ldi      99           ; need marker on stack
          stxd
atof_2a:  lda      rf           ; get next byte from input
          plo      re           ; keep a copy
          smi      '0'          ; see if below digits
          lbnf     atof_2b      ; jump if not valid digit
          smi      10           ; check for high of range
          lbdf     atof_2b      ; jump if not valid digit
          glo      re           ; recover number
          smi      '0'          ; convert to binary
          stxd                  ; and store on stack
          lbr      atof_2a      ; loop until all numerals copied
atof_2b:  dec      rf           ; move pointer back to non-numeral character
; ------------------------------------
; ----- Main loop for fractional -----
; ------------------------------------
atof_2c:  glo      rb           ; check mask for zero
          lbnz     atof_2d
          ghi      rb
          lbnz     atof_2d
          glo      ra
          lbnz     atof_2d
          lbr      atof_2z      ; done with fractional
atof_2d:  glo      r7           ; check mantissa for zero
          lbnz     atof_2e
          ghi      r8 
          lbnz     atof_2e
          glo      r8 
          lbnz     atof_2e
          glo      r9           ; zero result
          smi      1            ; so subtract 1 from exponent
          plo      r9           ; put it back
          lbr      atof_2f
atof_2e:  glo      ra           ; if result nonzero, shift mask right
          shr
          plo      ra
          ghi      rb
          shrc
          phi      rb
          glo      rb
          shrc
          plo      rb
atof_2f:  ldi      0            ; set carry to 0
          plo      re
          mov      rc,r2        ; point to fractional data
          inc      rc
atof_2g:  ldn      rc           ; get next byte from fractional
          smi      99           ; check for end
          lbz      atof_2j      ; jump if end found
          glo      re           ; get carry
          shr                   ; shift into DF
          ldn      rc           ; get next fractional digit
          shlc                  ; add to itself plus carry
          str      rc           ; put it back
          smi      10           ; see if exceeded 10
          lbnf     atof_2h      ; jump if not
          str      rc           ; store corrected number
          ldi      1            ; set carry
atof_2i:  plo      re
          inc      rc           ; point to next character
          lbr      atof_2g      ; and loop back for more
atof_2h:  ldi      0            ; clear carry
          lbr      atof_2i
atof_2j:  glo      re           ; get carry
          shr                   ; shift into DF
          lbnf     atof_2c      ; loop until mask==0
          glo      rb           ; check mask for zero
          lbnz     atof_2k      ; jump if not zero
          ghi      rb
          lbnz     atof_2k      ; jump if not zero
          glo      ra
          lbnz     atof_2k      ; jump if not zero
          glo      r8           ; mask==0, add 1
          adi      1
          plo      r8
          ghi      r8
          adci     0
          phi      r8
          glo      r7
          adci     0
          plo      r7
          lbr      atof_2z      ; done with fractional
atof_2k   glo      rb           ; combine mask with result
          str      r2
          glo      r8
          or
          plo      r8
          ghi      rb
          str      r2
          ghi      r8
          or
          phi      r8
          glo      ra
          str      r2
          glo      r7
          or
          plo      r7
          lbr      atof_2c      ; loop until mask == 0
atof_2z:  irx                   ; clean temp data from stack
atof_2z2: ldxa                  ; get next byte
          smi      99           ; look for end marker
          lbnz     atof_2z2     ; loop until marker found
          dec      r2           ; move stack pointer back

atof_e:   sep      scall        ; normalize number
          dw       fpnorm
          ldn      rf           ; get next character
          smi      'E'          ; check for exponent
          lbz      atof_ex      ; jump if so
          smi      32           ; check lowercase e as well
          lbz      atof_ex      ; jump if exponent
atof_dn:  pop      rd           ; recover destination
          glo      r8           ; store answer in destination
          str      rd
          inc      rd
          ghi      r8
          str      rd
          inc      rd
          glo      r7
          str      rd
          inc      rd
          ghi      r7
          str      rd
          dec      rd           ; restore destination pointer
          dec      rd
          dec      rd
          sep      sret         ; return to caller
; ++++++++++++++++++++++++++++
; +++++ Process exponent +++++
; ++++++++++++++++++++++++++++
atof_ex:  ldi      0            ; signal positive exponent
          phi      r9           ; put it here
          inc      rf           ; move past E
          ldn      rf           ; need to check for sign
          smi      '+'          ; check for positive
          lbz      atof_exp     ; jump if so
          smi      2            ; check for negative
          lbnz     atof_ex1     ; jump if not
          ldi      1            ; signal negative number
          phi      r9
atof_exp: inc      rf           ; move past sign
atof_ex1: ldi      0            ; set exponent count to zero
          plo      rc
atof_ex2: ldn      rf           ; get byte from input
          smi      '0'          ; see if below digits
          lbnf     atof_ex3     ; jump if not valid digit
          smi      10           ; check for high of range
          lbdf     atof_ex3     ; jump if not valid digit
          glo      rc           ; get count
          shl                   ; multiply by 2
          str      r2           ; save for add
          shl                   ; multiply by 4
          shl                   ; by 8
          add                   ; by 10
          str      r2           ; store for add
          lda      rf           ; get input byte
          smi      '0'          ; convert to binary
          add                   ; add in prior total
          plo      rc           ; put it back
          lbr      atof_ex2     ; loop until no more digits
atof_ex3: ghi      r7           ; put result on stack
          stxd
          glo      r7
          stxd
          ghi      r8
          stxd
          glo      r8
          stxd
          ghi      r9           ; check sign of exponent
          shr
          lbdf     atof_exn     ; jump if negative
atof_ex4: glo      rc           ; see if done
          lbz      atof_exd     ; jump if done
          mov      rf,r2        ; point to result
          inc      rf
          mov      rd,fp_10     ; point to 10.0
          glo      rc           ; save count
          stxd
          sep      scall        ; multiply result by 10.0
          dw       fpmul
          irx                   ; recover count
          ldx        
          plo      rc           ; put back into count
          dec      rc           ; decrement count
          lbr      atof_ex4     ; loop until done
atof_exn: glo      rc           ; see if done
          lbz      atof_exd     ; jump if done
          mov      rf,r2        ; point to result
          inc      rf
          mov      rd,fp_10     ; point to 10.0
          glo      rc           ; save count
          stxd
          sep      scall        ; divide result by 10.0
          dw       fpdiv
          irx                   ; recover count
          ldx        
          plo      rc           ; put back into count
          dec      rc           ; decrement count
          lbr      atof_exn     ; loop until done
atof_exd: irx                   ; recover answer
          ldxa
          plo      r8
          ldxa
          phi      r8
          ldxa
          plo      r7
          ldx
          phi      r7
          lbr      atof_dn      ; and return result

; *************************************************
; ***** Convert floating point to ASCII       *****
; ***** RF - pointer to floating point number *****
; ***** RD - destination buffer               *****
; ***** Uses:                                 *****
; *****       R9.0  - exponent                *****
; *****       R9.1  - E                       *****
; *****       R7:R8 - number                  *****
; *****       RA:RB - fractional              *****
; *****       RC.0  - digit count             *****
; *************************************************
ftoa:     lda      rf           ; retrieve number into R7:R8
          plo      r8
          lda      rf
          phi      r8
          lda      rf
          plo      r7
          lda      rf
          phi      r7
          shl                   ; shift sign into DF
          lbnf     ftoa_1       ; jump if number is positive
          ldi      '-'          ; place minus sign into output
          str      rd
          inc      rd
ftoa_1:   glo      r7           ; get low bit of exponent
          shl                   ; shift into DF
          ghi      r7           ; get high 7 bits of exponent
          shlc                  ; shift in the low bit
          plo      r9           ; store it
          lbnz     ftoa_2       ; jump if exponent is not zero
          ldi      '0'          ; write 0 digit to output
          str      rd
          inc      rd
ftoa_t:   ldi      0            ; terminate output
          str      rf
          sep      sret         ; and return to caller
ftoa_2:   smi      0ffh         ; check for infinity
          lbnz     ftoa_3       ; jump if not
          ldi      'i'          ; write inf to output
          str      rd
          inc      rd
          ldi      'n'
          str      rd
          inc      rd
          ldi      'f'
          str      rd
          inc      rd
          lbr      ftoa_t       ; terminate string and return
ftoa_3:   push     rd           ; save destination pointer
          ldi      0            ; clear E
          phi      r9
          glo      r9           ; check exponent for greater than 150
          smi      151
          lbnf     ftoa_4       ; jump if <= 150
          ghi      r7           ; put number on the stack
          stxd
          glo      r7
          stxd
          ghi      r8
          stxd
          glo      r8
          stxd
ftoa_3a:  glo      r9           ; get exponent
          smi      131          ; looking for below 131
          lbnf     ftoa_3z      ; jump if done scaling
          mov      rf,r2        ; point to number
          inc      rf
          ghi      r9           ; get E
          stxd                  ; and save on stack
          mov      rd,fp_10     ; need to divide by 10
          sep      scall        ; perform the division
          dw       fpdiv
          irx                   ; recover E
          ldx
          adi      1            ; increment E
          phi      r9           ; and put it back
          glo      r2           ; point to new exponent
          adi      3
          plo      rf
          ghi      r2
          adci     0
          phi      rf
          lda      rf           ; get low bit
          shl                   ; shift into DF
          ldn      rf           ; get high 7 bites
          shlc                  ; shift in the low bit
          plo      r9           ; and store it
          lbr      ftoa_3a      ; loop until exponent in correct range
ftoa_3z:  irx                   ; retrieve the number from the stack
          ldxa
          plo      r8
          ldxa
          phi      r8
          ldxa
          plo      r7
          ldx
          phi      r7
ftoa_4:   glo      r9           ; check exponent for less than 114
          smi      114
          lbdf     ftoa_5       ; jump if > 114
          ghi      r7           ; put number on the stack
          stxd
          glo      r7
          stxd
          ghi      r8
          stxd
          glo      r8
          stxd
ftoa_4a:  glo      r9           ; get exponent
          smi      127          ; looking for below 127
          lbdf     ftoa_4z      ; jump if done scaling
          mov      rf,r2        ; point to number
          inc      rf
          ghi      r9           ; get E
          stxd                  ; and save on stack
          mov      rd,fp_10     ; need to divide by 10
          sep      scall        ; perform the division
          dw       fpmul
          irx                   ; recover E
          ldx
          smi      1            ; decrement E
          phi      r9           ; and put it back
          glo      r2           ; point to new exponent
          adi      3
          plo      rf
          ghi      r2
          adci     0
          phi      rf
          lda      rf           ; get low bit
          shl                   ; shift into DF
          ldn      rf           ; get high 7 bites
          shlc                  ; shift in the low bit
          plo      r9           ; and store it
          lbr      ftoa_4a      ; loop until exponent in correct range
ftoa_4z:  irx                   ; retrieve the number from the stack
          ldxa
          plo      r8
          ldxa
          phi      r8
          ldxa
          plo      r7
          ldx
          phi      r7
ftoa_5:   ldi      0            ; clear high byte of number
          phi      r7
          glo      r7           ; set implied 1
          ori      080h
          plo      r7           ; and put it back
          ldi      0            ; clear fractional
          phi      ra
          plo      ra
          phi      rb
          plo      rb
ftoa_6:   glo      r9           ; get exponent
          smi      150          ; check for less than 150
          lbdf     ftoa_7       ; jump if not
          glo      ra           ; shift fractional right
          shr
          plo      ra
          ghi      rb
          shrc
          phi      rb
          glo      rb
          shrc
          plo      rb
          glo      r8           ; get low bit of number
          shr                   ; shift it into DF
          lbnf     ftoa_6a      ; jump if bit was clear
          glo      ra           ; otherwise set high bit in fractional
          ori      080h
          plo      ra           ; put it back
ftoa_6a:  glo      r7           ; shift number right
          shr
          plo      r7
          ghi      r8
          shrc
          phi      r8
          glo      r8
          shrc
          plo      r8
          glo      r9           ; get exponent
          adi      1            ; increase it
          plo      r9           ; put it back
          lbr      ftoa_6       ; loop back until exponent >= 150
ftoa_7:   glo      r9           ; get exponent
          smi      151          ; check for greater than 150
          lbnf     ftoa_8       ; jump if not
          glo      r8           ; shift number left
          shl
          plo      r8
          ghi      r8
          shlc
          phi      r8
          glo      r7
          shlc
          plo      r7
          ghi      r7
          shlc
          phi      r7
          glo      r9           ; get exponent
          adi      1            ; increment it
          plo      r9           ; and put it back
          lbr      ftoa_7       ; loop until exponent in range
ftoa_8:   pop      rd           ; recover destination
          ghi      r7           ; place integer portion on stack
          stxd
          glo      r7
          stxd
          ghi      r8
          stxd
          glo      r8
          stxd
          mov      rf,r2        ; point source to integer number
          inc      rf
          push     ra           ; save registers consumed by itoa
          push     rb
          push     r9
          sep      scall        ; call ito a to convert integer portion of result
          dw       itoa
          pop      r9           ; recover consumed registers
          pop      rb
          pop      ra
          irx                   ; remove number from stack
          irx
          irx
          irx
          glo      ra           ; check for nonzero fractional
          lbnz     ftoa_9       ; jump if not zero
          ghi      rb
          lbnz     ftoa_9
          glo      rb
          lbnz     ftoa_9
          lbr      ftoa_e       ; no fractional digits, jump to E processing
ftoa_9:   dec      rd           ; get 2 characters back
          dec      rd
          lda      rd           ; get it
          smi      '1'          ; see if it was 1
          lbnz     ftoa_9c      ; jump if not
          ldn      rd           ; get 2nd number
          plo      re           ; save it
          ldi      '.'          ; replace it with a dot
          str      rd
          inc      rd
          glo      re           ; recover number
          str      rd           ; and store into destination
          inc      rd
          ghi      r9           ; get E
          adi      1            ; increment it
          phi      r9           ; and put it back
          lbr      ftoa_9d      ; then continue
ftoa_9c:  inc      rd           ; put RD back to original position
          ldi      '.'          ; need decimal point
          str      rd           ; store into destination
          inc      rd
ftoa_9d:  ldi      6            ; set digit count
          plo      rc
ftoa_9a:  glo      ra           ; check if fractional is still non-zero
          lbnz     ftoa_9b      ; jump if not
          ghi      rb
          lbnz     ftoa_9b
          glo      rb
          lbz      ftoa_e       ; on to E processing if no more fractional bits
ftoa_9b:  glo      rb           ; multiply fractional by 2
          shl
          plo      rb
          plo      r8           ; put copy in R7:R8 as well
          ghi      rb
          shlc
          phi      rb
          phi      r8
          glo      ra
          shlc
          plo      ra
          plo      r7
          ghi      ra
          shlc
          phi      ra
          phi      r7
          glo      r8           ; now multiply R7:R8 by 2
          shl
          plo      r8
          ghi      r8
          shlc
          phi      r8
          glo      r7
          shlc
          plo      r7
          ghi      r7
          shlc
          phi      r7
          glo      r8           ; now multiply R7:R8 by 4
          shl
          plo      r8
          ghi      r8
          shlc
          phi      r8
          glo      r7
          shlc
          plo      r7
          ghi      r7
          shlc
          phi      r7
          glo      rb           ; now add R7:R8 to RA:RB
          str      r2
          glo      r8
          add
          plo      rb
          ghi      rb
          str      r2
          ghi      r8
          adc
          phi      rb
          glo      ra
          str      r2
          glo      r7
          adc
          plo      ra
          ghi      ra
          str      r2
          ghi      r7
          adc
          phi      ra           ; D now has decimal byte
          adi      '0'          ; convert to ASCII
          str      rd           ; and write to destination
          inc      rd
          ldi      0            ; clear high byte of fractional
          phi      ra
          dec      rc           ; increment counter
          glo      rc           ; need to see if done
          lbnz     ftoa_9a      ; loop until done
ftoa_e:   ghi      r9           ; need to check for E
          lbz      ftoa_dn      ; jump if no E needed
          ldi      'E'          ; write E to output
          str      rd
          inc      rd
          ghi      r9           ; see if E was negative
          shl
          lbnf     ftoa_ep      ; jump if not
          ldi      '-'          ; write minus sign to output
          str      rd
          inc      rd
          ghi      r9           ; then 2s compliment E
          xri      0ffh
          adi      1
          phi      r9           ; and put it back
          lbr      ftoa_e1      ; then continue
ftoa_ep:  ldi      '+'          ; write plus to output
          str      rd
          inc      rd
ftoa_e1:  ldi      0            ; place E as 32-bits onto stack
          stxd
          stxd
          stxd
          ghi      r9
          stxd
          mov      rf,r2        ; point rf to number
          inc      rf
          sep      scall        ; call itoa to display E
          dw       itoa
          irx                   ; remove number from stack
          irx
          irx
          irx
ftoa_dn:  ldi      0            ; terminate string
          str      rd
          sep      sret         ; and return to caller

; *************************************************
; ***** Convert floating point to integer     *****
; ***** RF - pointer to floating point number *****
; ***** RD - destination integer              *****
; ***** Returns: DF=1 - overflow              *****
; ***** Uses:                                 *****
; *****       R9.0  - exponent                *****
; *****       R9.1  - sign                    *****
; *****       R7:R8 - number                  *****
; *****       RA:RB - fractional              *****
; *****       RC.0  - digit count             *****
; *************************************************
ftoi:     lda      rf           ; retrieve number into R7:R8
          plo      r8
          lda      rf
          phi      r8
          lda      rf
          plo      r7
          lda      rf
          phi      r7
          shl                   ; shift sign into DF
          ldi      0            ; clear D
          shlc                  ; shift sign into D
          phi      r9           ; and store it
ftoi_1:   glo      r7           ; get low bit of exponent
          shl                   ; shift into DF
          ghi      r7           ; get high 7 bits of exponent
          shlc                  ; shift in the low bit
          plo      r9           ; store it
          lbnz     ftoi_2       ; jump if exponent is not zero
          ldi      0            ; result is zero
          str      rd
          inc      rd
          str      rd
          inc      rd
          str      rd
          inc      rd
          str      rd
          adi      0            ; clear DF
          shr
          sep      sret         ; return to caller
ftoi_2:   smi      0ffh         ; check for infinity
          lbnz     ftoi_5       ; jump if not
ftoi_ov:  ldi      0ffh         ; write highest integer
          str      rd
          inc      rd
          str      rd
          inc      rd
          str      rd
          inc      rd
          ldi      07fh         ; positive number
          str      rd
          smi      0            ; set DF to signal overflow
          shr
          sep      sret         ; and return

ftoi_5:   ldi      0            ; clear high byte of number
          phi      r7
          glo      r7           ; set implied 1
          ori      080h
          plo      r7           ; and put it back
          ldi      0            ; clear fractional
          phi      ra
          plo      ra
          phi      rb
          plo      rb
ftoi_6:   glo      r9           ; get exponent
          smi      150          ; check for less than 150
          lbdf     ftoi_7       ; jump if not
          glo      ra           ; shift fractional right
          shr
          plo      ra
          ghi      rb
          shrc
          phi      rb
          glo      rb
          shrc
          plo      rb
          glo      r8           ; get low bit of number
          shr                   ; shift it into DF
          lbnf     ftoi_6a      ; jump if bit was clear
          glo      ra           ; otherwise set high bit in fractional
          ori      080h
          plo      ra           ; put it back
ftoi_6a:  glo      r7           ; shift number right
          shr
          plo      r7
          ghi      r8
          shrc
          phi      r8
          glo      r8
          shrc
          plo      r8
          glo      r9           ; get exponent
          adi      1            ; increase it
          plo      r9           ; put it back
          lbr      ftoi_6       ; loop back until exponent >= 150
ftoi_7:   glo      r9           ; get exponent
          smi      151          ; check for greater than 150
          lbnf     ftoi_8       ; jump if not
          ghi      r7           ; check for overflow
          ani      080h
          lbnz     ftoi_ov      ; jump if overflow
          glo      r8           ; shift number left
          shl
          plo      r8
          ghi      r8
          shlc
          phi      r8
          glo      r7
          shlc
          plo      r7
          ghi      r7
          shlc
          phi      r7
          glo      r9           ; get exponent
          adi      1            ; increment it
          plo      r9           ; and put it back
          lbr      ftoi_7       ; loop until exponent in range
ftoi_8:   glo      r8           ; store number into destination
          str      rd
          inc      rd
          ghi      r8
          str      rd
          inc      rd
          glo      r7
          str      rd
          inc      rd
          ghi      r7
          str      rd
          dec      rd           ; move destination pointer back
          dec      rd
          dec      rd
          adi      0            ; signal no overflow
          shr
          sep      sret         ; and return to caller
