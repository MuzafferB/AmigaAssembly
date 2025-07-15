
; Lesson 5m.s    MOVING THE VIDEO WINDOW WITH DIWSTART ($dff08e)

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea    GfxName(PC),a1    ; Address of the lib name to open in a1
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase    ; save the GFX base address in GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the address of the old copperlist

;     POINT TO OUR BITPLANES

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

bsr.w    SuGiuDIW    ; scrolls up and down with DIWSTART

Wait:
cmpi.b    #$ff,$dff006    ; Are we at line 255?
beq.s    Wait        ; If yes, don't continue, wait!

btst    #6,$bfe001    ; Left mouse button pressed?
bne.s    mouse        ; If not, return to mouse:

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

GfxBase:        ; This is where the base address for the Offsets goes
dc.l    0    ; of the graphics.library

OldCop:            ; This is where the address of the old system COP goes
dc.l    0

;	This routine simply acts on the YY byte of $dff08e in
;    copperlist, the DIWSTART; this register defines the start of the
;    video window, which can be ‘centred’, as can be done
;    from the WorkBench preferences. In our case, we simply
;    make the video window ‘start’ lower down, so
;    move its contents. In this case, unlike the
;    scroll we saw with bitplanes, nothing is displayed
;    ‘above’ the image, because we move the ‘window’ itself, and
;    the bitplanes outside it are not displayed.
;    An interesting aspect of the routine may be the fact that
;    a word labelled COUNTER is used to wait 35 frames
;    before acting, to create a delay when the logo is at the top
;    before descending; I also used two ‘new’ instructions, which
;    we had not seen before, but which are very useful in this routine; they
;    BHI, which is an instruction from the BEQ/BNE family, which jumps
;    to the routine if the result of CMP, i.e. COMPARE, is that
;    the value is HIGHER, in this case BHI.s LOGOD jumps to LOGOD
;    only when COUNTER has reached the value 35, as well as the times
;    after, when it will be at 36, 37, etc., in any case HIGHER than 35.
;    The other instruction is BCHG, which means BIT CHANGE, i.e.
;    ‘swap the bit’, it is from the BTST family, and ‘swaps’ the bit
;    indicated, i.e.: a BCHG #1,label acts on bit 1 of that label
;    making it 1 if it was 0, 0 if it was 1.

SuGiuDIW:
ADDQ.W    #1,COUNTER    ; mark the execution
CMPI.W    #35,COUNTER    ; have at least 35 frames passed?
BHI.S    LOGOD        ; if the routine is executed
RTS            ; otherwise return without executing it

LOGOD:
BTST    #1,FLAGDIW    ; Do we need to go up?
BEQ.S    UP        ; If so, execute the ‘UP’ routine
SUBQ.B    #2,DIWSCX    ; Go up in steps of 2, faster
CMPI.B    #$2c,DIWSCX    ; Are we at the top? (normal value $2c81)
BEQ.S    CHANGEUPDOWN2    ; if we change the scroll direction
RTS

UP:
ADDQ.B    #1,DIWSCX    ; Go down in steps of 1, slowly
CMPI.B    #$70,DIWSCX    ; Are we at the bottom? (position $70)
BEQ.S    CHANGEUPDOWN    ; if yes, change the scroll direction
RTS

CHANGEUPDOWN
BCHG    #1,FLAGDIW    ; swap the direction bit
RTS

CHANGEUPDOWN2
BCHG    #1,FLAGDIW    ; swap the direction bit
CLR.W    COUNTER        ; and reset the COUNTER, we're done!
RTS

FLAGDIW:
dc.w    0

COUNTER:
dc.w    0


SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $120,$0000,$122,$0000,$124,$0000,$126,$0000,$128,$0000 ; SPRITE
dc.w	$12a,$0000,$12c,$0000,$12e,$0000,$130,$0000,$132,$0000
dc.w	$134,$0000,$136,$0000,$138,$0000,$13a,$0000,$13c,$0000
dc.w	$13e,$0000

dc.w    $8E
DIWSCX:
dc.w    $2c81    ; DIWSTRT = $YYXX Start of video window

dc.w    $90,$2cc1    ; DiwStop
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

dc.w    $FFFF,$FFFE    ; End of copperlist

;    figure

PIC:
incbin    ‘amiga.320*256*3’    ; here we load the figure in RAW,
; converted with KEFCON, made up of
; 3 consecutive bitplanes

end
