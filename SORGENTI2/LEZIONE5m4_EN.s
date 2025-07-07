
; Lesson 5m4.s    ‘CLOSING’ THE VIDEO WINDOW WITH DIWSTART/STOP ($8e/$90)

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea    GfxName(PC),a1    ; Address of the lib name to open in a1
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
addq.w    #8,a1        ; go to the next bplpointers in the COP
dbra    d1,POINTBP    ; Repeat D1 times POINTBP (D1=number of bitplanes)
;
move.l    #COPPERLIST,$dff080    ; Point to our COP
move.w    d0,$dff088        ; Start the COP
move.w    #0,$dff1fc        ; Disable AGA
move.w    #$c00,$dff106        ; Disable AGA

mouse:
cmpi.b    #$ff,$dff006    ; Are we at line 255?
bne.s    mouse        ; If not, don't continue

btst    #2,$dff016    ; if the right button is pressed, jump
beq.s    Wait        ; the scroll routine, blocking it

bsr.w    DIWORIZZONTALE    ; show the function of DIWSTART and DIWSTOP
bsr.w    DIWVERTICALE    ; 

Wait:
cmpi.b    #$ff,$dff006    ; Are we at line 255?
beq.s    Wait        ; If yes, don't go on, wait!

btst    #6,$bfe001    ; Left mouse button pressed?
bne.s    mouse        ; If not, go back to mouse:

move.l    OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088        ; Start the old cop

move.l    4.w,a6
jsr    -$7e(a6)    ; Enable - re-enable Multitasking
move.l    gfxbase(PC),a1    ; Base of the library to close
jsr    -$19e(a6)    ; Closelibrary - close the graphics library
rts            ; EXIT THE PROGRAM

;    Data

GfxName:
dc.b    ‘graphics.library’,0,0

GfxBase:        ; Here goes the base address for the Offsets
dc.l    0    ; of the graphics.library

OldCop:            ; Here goes the address of the old system COP
dc.l    0


DIWORIZZONTALE:
CMPI.B    #$FF,DIWXSTART    ; Have we reached the maximum DIWSTART?
BEQ.S    FINITO        ; if yes, we cannot proceed further
ADDQ.B    #2,DIWXSTART    ; if no, then add 1
FINITO:
TST.B    DIWXSTOP    ; Have we reached the minimum DIWSTOP? ($00)
BEQ.S    FINITO2        ; if yes, we cannot go any lower
SUBQ.B    #2,DIWXSTOP    ; if not, then subtract 1
FINITO2:
RTS            ; Exit routine


DIWVERTICALE:
CMPI.B    #$95,DIWYSTOP    ; Have we reached the correct DIWSTOP?
BEQ.S    FINITO3        ; if yes, we must not proceed further
ADDQ.B    #1,DIWYSTART    ; add 1 to the start
SUBQ.B    #1,DIWYSTOP    ; subtract 1 from the stop
FINITO3:
RTS            ; Exit routine

SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $120,$0000,$122,$0000,$124,$0000,$126,$0000,$128,$0000 ; SPRITE
dc.w	$12a,$0000,$12c,$0000,$12e,$0000,$130,$0000,$132,$0000
dc.w    $134,$0000,$136,$0000,$138,$0000,$13a,$0000,$13c,$0000
dc.w    $13e,$0000

dc.w    $8E        ; DIWSTART - Start of video window
DIWYSTART:
dc.b    $2c        ; DIWSTRT $YY
DIWXSTART:
dc.b    $81        ; DIWSTRT $XX (increment until $ff)

dc.w    $90        ; DIWSTOP - End of video window
DIWYSTOP:
dc.b    $fe        ; DiwStop YY
DIWXSTOP:
dc.b    $c1        ; DiwStop XX (we lower it to $00)
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0    ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210
dc.w    $100,%0011001000000000    ; bits 13 and 12 on!! (3 = %011)
; 3 lowres bitplanes, no lace
BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first bitplane
dc.w $e4,$0000,$e6,$0000    ;second bitplane
dc.w $e8,$0000,$ea,$0000    ;third bitplane

dc.w    $0180,$000    ; colour0
dc.w    $0182,$475    ; colour1
dc.w    $0184,$fff    ; colour2
dc.w    $0186,$ccc    ; colour3
dc.w    $0188,$999    ; colour4
dc.w    $018a,$232    ; colour5
dc.w    $018c,$777    ; colour6
dc.w    $018e,$444    ; colour7

dc.w    $ca07,$fffe
dc.w    $180,$456    ; note: the background colour is not affected
; by diwstart-diwstop

dc.w    $FFFF,$FFFE    ; End of copperlist

;    figure

PIC:
incbin    ‘amiga.320*256*3’    ; here we load the figure in RAW,
; converted with KEFCON, made up of
; 3 consecutive bitplanes

end

In this listing, both the XX and YY of the DIWSTART and DIWSTOP
are modified to constrict the figure.

