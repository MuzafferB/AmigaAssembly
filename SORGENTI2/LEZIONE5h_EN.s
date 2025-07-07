
; Lesson 5h.s    HORIZONTAL WAVING OF A FIGURE WITH $dff102

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea	GfxName(PC),a1    ; Address of the name of the lib to open in a1
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase    ; save the GFX base address in GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the address of the old copperlist

;     POINT OUR BITPLANES

MOVE.L    #PIC,d0        ; put the PIC address in d0,
LEA    BPLPOINTERS,A1    ; pointers in the COPPERLIST
MOVEQ    #2,D1        ; number of bitplanes -1 (here there are 3)
POINTBP:
move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the HIGH word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 3412 > 1234)
ADD.L    #40*256,d0    ; + bitplane length -> next bitplane
addq.w    #8,a1		; go to the next bplpointers in COP
dbra    d1,POINTBP    ; Repeat D1 times POINTBP (D1=number of bitplanes)

;

move.l    #COPPERLIST,$dff080    ; Point to our COP
move.w    d0,$dff088        ; Start the COP

move.w    #0,$dff1fc        ; Disable AGA
move.w    #$c00,$dff106        ; Disable AGA

mouse:
cmpi.b    #$ff,$dff006    ; Are we at line 255?
bne.s    mouse        ; If not, don't continue

btst    #2,$dff016    ; if the right mouse button is pressed, jump
beq.s    Wait        ; the scroll routine, blocking it

bsr.w    Wave        ; waves the figure with many $dff102 in
; copperlist

Wait:
cmpi.b    #$ff,$dff006	; Are we at line 255?
beq.s    Wait        ; If yes, don't continue, wait!

btst    #6,$bfe001    ; Left mouse button pressed?
bne.s    mouse        ; If not, go back to mouse:

move.l    OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088        ; start the old cop

move.l    4.w,a6
jsr    -$7e(a6)    ; Enable - re-enable Multitasking
move.l    gfxbase(PC),a1    ; Base of the library to close
jsr    -$19e(a6)    ; Closelibrary - close graphics lib
rts            ; EXIT PROGRAM

;    Data

GfxName:
dc.b    ‘graphics.library’,0,0

GfxBase:        ; Here goes the base address for the Offsets
dc.l    0    ; of graphics.library

OldCop:            ; This is where the address of the old system COP goes
dc.l    0

; This routine is similar to the one in Lesson 3e.s, in fact values are ‘moved’
; as in a chain; remember the system already used:
;    
;    move.w    col2,col1    ; col2 copied to col1
;    move.w    col3,col2    ; col3 copied to col2
;    move.w    col4,col3    ; col4 copied to col3
;    move.w    col5,col4    ; col5 copied to col4
;
; In this routine, instead of copying colours, values from $dff102 are copied, but
; the routine works in the same way. To save LABEL and time
; the routine has been provided with a DBRA cycle that rotates
; as many words as we want: since the words to be changed are 8 bytes apart, just
; put the address of one in a0 and the other in a1 and the move is done
; with a MOVE.W (a0),(a1). Then we move on to the next pair by adding 8
; to a0 and a1, which will point to the next pair of words to be exchanged.
; Remember that to make the cycle INFINITE, the first value must
; always be replaced by the last:
;
;     >>>>>>>>>>>>>>>>>>>>>    
;    ^          v
; In this case, at the end of the cycle, the first value is copied to the last
; so the flow is constant; the old routine actually ended like this:
;
;    move.w    col1,col14    ; col1 copied to col14
;

Ondula:
LEA    CON1EFFETTO+8,A0 ; Source word address in a0
LEA	CON1EFFETTO,A1    ; Destination word address in a1
MOVEQ    #44,D2        ; 45 bplcon1 to be changed in COPLIST
SCAMBIA:
MOVE.W    (A0),(A1)    ; copy two consecutive words - scrolling!
ADDQ.W    #8,A0        ; next pair of words
ADDQ.W    #8,A1        ; next pair of words
DBRA    D2,SWAP    ; repeat ‘SWAP’ the right number of TIMES

MOVE.W    CON1EFFETTO,ULTIMOVALORE ; to make the cycle infinite
RTS                ; copy the first value to the last
; every time.


SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$120,$0000,$122,$0000,$124,$0000,$126,$0000,$128,$0000 ; SPRITE
dc.w	$12a,$0000,$12c,$0000,$12e,$0000,$130,$0000,$132,$0000
dc.w	$134,$0000,$136,$0000,$138,$0000,$13a,$0000,$13c,$0000
dc.w	$13e,$0000

dc.w	$8e,$2c81	; DiwStrt    (registers with normal values)
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0    ; DdfStop


dc.w    $102        ; BplCon1 - THE REGISTER
dc.b    $00        ; BplCon1 - THE UNUSED BYTE!!!
MIOCON1:
dc.b    $00        ; BplCon1 - THE USED BYTE!!!


dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210
dc.w    $100,%0011001000000000    ; bits 13 and 12 on!! (3 = %011)
; 3 lowres bitplanes, non lace
BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first bitplane
dc.w $e4,$0000,$e6,$0000    ;second bitplane
dc.w $e8,$0000,$ea,$0000	;third bitplane

dc.w    $0180,$000    ; colour0
dc.w    $0182,$475    ; colour1
dc.w    $0184,$fff    ; colour2
dc.w    $0186,$ccc    ; colour3
dc.w $0188,$999; colour4
dc.w $018a,$232; colour5
dc.w $018c,$777; colour6
dc.w $018e,$444; colour7

;    The effect in the copperlist: it consists of a wait and a BPLCON1, the
;    waits wait once every 4 lines: $34,$38,$3c....
;    In $dff102 there are already the values of the ‘WAVE’: 1,2,3,4...3,2,1.

DC.W	$3007,$FFFE,$102
CON1EFFETTO:
DC.W	$00
DC.W	$3407,$FFFE,$102,$00
DC.W	$3807,$FFFE,$102,$00
DC.W	$3C07,$FFFE,$102,$11
DC.W    $4007,$FFFE,$102,$11
DC.W    $4407,$FFFE,$102,$11
DC.W    $4807,$FFFE,$102,$11
DC.W    $4C07,$FFFE,$102,$22
DC.W	$5007,$FFFE,$102,$22
DC.W	$5407,$FFFE,$102,$22
DC.W	$5807,$FFFE,$102,$33
DC.W	$5C07,$FFFE,$102,$33
DC.W	$6007,$FFFE,$102,$44
DC.W	$6407,$FFFE,$102,$44
DC.W	$6807,$FFFE,$102,$55
DC.W	$6C07,$FFFE,$102,$66
DC.W    $7007,$FFFE,$102,$77
DC.W    $7407,$FFFE,$102,$88
DC.W    $7807,$FFFE,$102,$88
DC.W    $7C07,$FFFE,$102,$99
DC.W	$8007,$FFFE,$102,$99
DC.W	$8407,$FFFE,$102,$aa
DC.W	$8807,$FFFE,$102,$aa
DC.W	$8C07,$FFFE,$102,$aa
DC.W	$9007,$FFFE,$102,$99
DC.W	$9407,$FFFE,$102,$99
DC.W	$9807,$FFFE,$102,$88
DC.W	$9C07,$FFFE,$102,$88
DC.W    $A007,$FFFE,$102,$77
DC.W    $A407,$FFFE,$102,$66
DC.W    $A807,$FFFE,$102,$55
DC.W    $AC07,$FFFE,$102,$44
DC.W    $B007,$FFFE,$102,$44
DC.W    $B407,$FFFE,$102,$33
DC.W    $B807,$FFFE,$102,$33
DC.W    $BC07,$FFFE,$102,$22
DC.W    $C007,$FFFE,$102,$22
DC.W    $C407,$FFFE,$102,$22
DC.W	$C807,$FFFE,$102,$11
DC.W	$CC07,$FFFE,$102,$11
DC.W	$D007,$FFFE,$102,$11
DC.W	$D407,$FFFE,$102,$11
DC.W	$D807,$FFFE,$102,$00
DC.W    $DC07,$FFFE,$102,$00
DC.W    $E007,$FFFE,$102,$00
DC.W    $E407,$FFFE,$102
ULTIMOVALORE:
DC.W    $00

dc.w    $FFFF,$FFFE    ; End of copperlist

;    figure

PIC:
incbin    ‘amiga.320*256*3’    ; here we load the figure in RAW,
; converted with KEFCON, made up of
; 3 consecutive bitplanes

end

This wave effect is a classic in Amiga. To save space
, it does not ripple each line separately but every four lines, but at least it has a
routine with a fast loop to scroll through the values of $102 present in the
copperlist.

The routine in this lesson can be used to ‘rotate’ any
group of words, so it can also be used for colour scrolling effects
or any other effect.
