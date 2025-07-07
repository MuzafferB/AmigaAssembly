
; Lesson 4a.s    UNIVERSAL BITPLANE POINTING ROUTINE

SECTION    CiriBiri,CODE

Start:
MOVE.L    #PIC,d0        ; put the PIC address in d0,
; i.e. where the first bitplane starts

LEA    BPLPOINTERS,A1    ; put the address of the
; pointers to the COPPERLIST planes in a1
MOVEQ    #2,D1        ; number of bitplanes -1 (here there are 3)
; to execute the cycle with DBRA
POINTBP:
move.w    d0,6(a1)    ; copy the LOW word of the plane address
; to the correct word in the copperlist
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
; putting the HIGH word in place of the
; allowing it to be copied with move.w!!
move.w    d0,2(a1)    ; copy the HIGH word of the plane address
; to the correct word in the copperlist
swap    d0        ; swap the 2 words of d0 (e.g.: 3412 > 1234)
; putting the address back in place.
ADD.L    #40*256,d0    ; Add 10240 to D0, making it point
; to the second bitplane (located after the first)
; (i.e. add the length of a plane)
; In the cycles following the first, we will point
; to the third, fourth bitplane, and so on.

addq.w    #8,a1		; a1 now contains the address of the next
; bplpointers in the copperlist to be written.
dbra    d1,POINTBP    ; Repeat D1 times POINTBP (D1=num of bitplanes)

rts    ; EXIT!!



COPPERLIST:
;    ....    ; here we will put the necessary registers...

;    Let's point the bitplanes directly by putting
;    the registers $dff0e0 and following in the copperlist with the addresses
;    of the bitplanes that will be put by the POINTBP routine

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane - BPL0PT
dc.w $e4,$0000,$e6,$0000    ;second bitplane - BPL1PT
dc.w $e8,$0000,$ea,$0000    ;third     bitplane - BPL2PT
;    ....
dc.w    $FFFF,$FFFE    ; end of the copperlist

;    Remember to select the directory where the image is located
;    in this case, just write: ‘V df0:SORGENTI2’

PIC:
incbin    ‘amiga.320*256*3’    ; here we load the image in RAW,
; converted with KEFCON, made up of
; 3 consecutive bitplanes

end

Try doing an ‘AD’, i.e. a DEBUG of this routine. When debugging, pay
particular attention to the value of D0, visible at the top right, at the moment
of the 2 swaps. To check that it works, at the end of the execution
try checking with ‘M BPLPOINTERS’ if the words have been changed
with the PIC address: SWAPPED in the words. (With an ‘M PIC’ you can see
at which address the PIC was loaded via INCBIN, which, as expected
,
 is 30720 bytes long: 40*256*3).

