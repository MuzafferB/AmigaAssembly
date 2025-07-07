
; Lesson11l1.s - change the colour0 and bplcon1 ($dff102) on each line

SECTION    coplanes,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include    ‘startup2.s’ ; Save Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001110000000    ; only copper and bitplane DMA

WaitDisk    EQU    30    ; 50-150 on save (depending on the case)

scr_bytes    = 40    ; Number of bytes per horizontal line.
; From this, the screen width is calculated
; by multiplying the bytes by 8: normal screen 320/8=40
; E.g. for a screen 336 pixels wide, 336/8=42
; example widths:
; 264 pixels = 33 / 272 pixels = 34 / 280 pixels = 35
; 360 pixels = 45 / 368 pixels = 46 / 376 pixels = 47
; ... 640 pixels = 80 / 648 pixels = 81 ...

scr_h        = 256    ; Screen height in lines
scr_x        = $81    ; Start of screen, position XX (normal $xx81) (129)
scr_y        = $2c    ; Start of screen, position YY (normal $2cxx) (44)
scr_res        = 1    ; 2 = HighRes (640*xxx) / 1 = LowRes (320*xxx)
scr_lace    = 0    ; 0 = no interlace (xxx*256) / 1 = interlace (xxx*512)
ham        = 0    ; 0 = no ham / 1 = ham
scr_bpl        = 1    ; Number of bitplanes

; parameters calculated automatically

scr_w        = scr_bytes*8        ; screen width
scr_size    = scr_bytes*scr_h    ; screen size in bytes
BPLC0    = ((scr_res&2)<<14)+(scr_bpl<<12)+$200+(scr_lace<<2)+(ham<<11)
DIWS	= (scr_y<<8)+scr_x
DIWSt	= ((scr_y+scr_h/(scr_lace+1))&255)<<8+(scr_x+scr_w/scr_res)&255
DDFS    = (scr_x-(16/scr_res+1))/2
DDFSt    = DDFS+(8/scr_res)*(scr_bytes/2-scr_res)

START:
;     POINT OUR BITPLANE

MOVE.L    #BITPLANE,d0
LEA    BPLPOINTER,A1
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

lea    $dff000,a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.

move.l    #COPPERLIST,$80(a5)    ; Point our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

move.w    #11,LoopCount1
move.w    #2,Counter1
clr.w    Counter2

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$12c00,d2    ; line to wait for = $12c
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $12c
BNE.S    Waity1
Wait:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $12c
BEQ.S    Wait

btst.b    #2,$dff016
beq.s    NoEff
bsr.s    Mainroutine    ; scroll colours and roll bplcon1
NoEff:
bsr.w    PrintCarattere    ; Print one character at a time

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse
rts

*****************************************************************************
; This routine is not optimised at all. You could create a
; routine that creates the copperlist, to be called at the beginning, then another
; that only changes the values of colour1 and bplcon1.
; Since it was already slow, to make it worse, a system was used that
; can still be useful in certain cases: to ‘scroll’ through the tables,
; a buffer as long as the table is used, into which the table
; itself is copied rotated, then from this table the values are copied back into
; the original table. But couldn't it be done without the buffer? Yes!
But think of a routine with many tables, which can hold the values
in the various stages of rotation. In this case, we could “pre-calculate”
the rotated values in each stage in many tables... but perhaps this would result in
so little optimisation that it would not be worth it... in short, take a
look at the routine, it is “strange” and gets tangled up for no reason, just
; to show “alternative” techniques... (exaggerated... it's just awful!).
*****************************************************************************

;     ______
;     .//_____\,
;     \\ ¦.¦ /
;     _\\_-_/_. dA!
;     ( / : \ \
;     / / : \ \
;     \,_,_,:,_,_\/`).
;     | | | (//\\
;    .-./,,_|__,,\.-. \\
;    `------`-------' `

MainRoutine:
move.l    a5,-(sp)    ; save a5
subq.w    #1,Counter1    ; Mark this execution
tst.w    Counter1    ; 2 frames passed?
bne.w	SaltaRull    ; If not yet, do not roll
move.w    #2,Counter1    ; Restart, wait for 2 frames
cmp.w    #15,Counter2    ; 15 frames passed?
beq.s    Roll2
addq.w    #1,CountLoop1
cmp.w    #30,CountLoop1 ; are we at 30 loops to go?
bne.s    GoRoll     ; if not OK yet
move.w    #15,Counter2     ; Otherwise Counter2=15
bra.s    GoRoll
Roll2:
subq.w    #1,CountLoop1    ; subtract
cmp.w    #3,CountLoop1    ; are we at 3?
bne.s    GoRoll        ; If not, roll again
clr.w    Counter2        ; Otherwise, reset counter2
GoToRoll:
lea    coltab(PC),a0    ; Table with colours
lea    TabBuf(PC),a1
move.w    (a0)+,d0    ; First colour in d0
CopyColtabLoop:
move.w    (a0)+,d1    ; Next colour in d1
cmp.w    #-2,d1	; end of table?
beq.s    FiniTabCol    ; If yes, the loop is finished
move.w    d1,(a1)+    ; if not, put this colour in TabBuf
bra.s    CopiaColtabLoop

FiniTabCol:
move.w    d0,(a1)+    ; Put the first colour as the last
move.w	#-2,(a1)+    ; And set the end of table mark
lea    coltab(PC),a0    ; Colour table
lea    TabBuf(PC),a1    ; Tab buffer
RecopyInColTabLoop:
move.w    (a1)+,d0    ; Copy colour from TabBuf
move.w    d0,(a0)+	; Put it in coltab
cmp.w    #-2,d0        ; End?
bne.s    CopyToColTabLoop
SaltaRull:
lea    BplCon1Tab(PC),a0 ; Tab with values for bplcon1
lea    TabBuf(PC),a1
move.w    (a0)+,d0	; No value from tab saved in d0
RullaLoop:
move.w    (a0)+,d1    ; Next tab value Bplcon1
cmp.w    #-2,d1        ; End of table?
beq.s    rullFinito    ; If skip forward
move.w    d1,(a1)+	; Copy from BplCon1Tab to TabBuf
bra.s    RullaLoop
rullFinito:
move.w    d0,(a1)+    ; Put the first value as the last
move.w    #-2,(a1)+     ; Set end of table flag
lea    BplCon1Tab(PC),a0 ; Bplcon1 value table
lea    TabBuf(PC),a1     ; buffer
RecopyCon1:
move.w    (a1)+,d0    ; copy from tabbuf
move.w    d0,(a0)+    ; to bplcon1tab
cmp.w    #-2,d0        ; are we at the end?
bne.s    RecopyCon1    ; if not, recopy!
delayed:
lea    CopperEffect,a0

; first loop, which does the ntsc part (first $ff lines)

move.w    #$2007,d0    ; wait start position YY=$22
move.w	#$4007,d2    ; wait step position YY=$22
moveq    #7-1,d4        ; Number of loops at $20 each.
; $20*7=$e0, + initial $20 = $100, i.e.
; the entire NTSC area
lea    EndTabCol(PC),a1
lea    BplCon1Tab(PC),a2 ; values table for bplcon1
loop:
move.w    ContaNumLoop1(PC),d3
main:
move.w    (a2)+,d5    ; First value of bplcon1
cmp.w    #-2,d5		; End of table?
bne.s    initd        ; If not, continue
lea    BplCon1Tab(PC),a2 ; Otherwise, start again
move.w    (a2)+,d5    ; value of bplcon1
initd:
move.w    -(a1),d1	; read the colour and go back
cmp.w    #-2,d1        ; End of table?
bne.s    initc        ; If not yet, set the colour & bplcon1
lea    EndTabCol(PC),a1 ; Otherwise, start again from the end of tabcol
move.w    -(a1),d1    ; read the colour and go back
initc:
move.w    d0,(a0)+    ; YYXX of the wait
move.w    #$fffe,(a0)+    ; wait
move.w    #$0180,(a0)+    ; colour register 0
move.w    d1,(a0)+    ; value of colour 0
move.w    #$0102,(a0)+    ; bplcon1
move.w    d5,(a0)+    ; value of bplcon1
add.w    #$0100,d0    ; wait one line below
dbra    d3,main
second:
move.w    (a2)+,d5    ; Next Bplcon1val
cmp.w    #-2,d5		; End of table?
bne.s    doned
lea    BplCon1Tab(PC),a2 ; restart from the beginning
move.w    (a2)+,d5    ; Next Bplcon1 value
doned:
move.w    (a1)+,d1    ; Next colour
cmp.w    #-2,d1        ; End of table?
bne.s    done
lea    coltab(PC),a1    ; restart from the beginning
move.w    (a1)+,d1    ; Next colour in tab
done:
move.w    d0,(a0)+    ; YYXX of wait
move.w    #$fffe,(a0)+	; wait
move.w    #$0180,(a0)+    ; colour register0
move.w    d1,(a0)+    ; value of colour0
move.w    #$0102,(a0)+    ; bplcon1 register
move.w    d5,(a0)+    ; value of bplcon1 register
add.w    #0100,d0    ; wait one line below
cmp.w    d2,d0        ; are we at the end of the block from $20 lines?
bne.s    second
add.w    #2000,d2    ; move the new maximum $20 lower.
dbra    d4,loop
move.l	#$ffdffffe,(a0)+    ; End of ntsc zone

; Second loop, which does the PAL zone, below line $FF

move.w    #$0007,d0    ; Start wait, at line $00 (i.e. 256)
move.w    #$2007,d2    ; End at line $20 (+$ff)
moveq    #2-1,d4        ; Number of loops
loop2:
move.w    ContaNumLoop1(PC),d3
main2:
move.w    -(a1),d1    ; Previous colour
cmp.w    #-2,d1        ; End of tab?
bne.s    initc2
lea	EndTabCol(PC),a1 ; restart from the end of tabCol
move.w    -(a1),d1    ; Previous colour
initc2:
move.w    d0,(a0)+	; YYXX of the wait
move.w    #$fffe,(a0)+    ; Wait
move.w    #$0180,(a0)+    ; colour register0
move.w    d1,(a0)+    ; value of colour0
add.w    #$0100,d0    ; wait one line below
dbra    d3,main2
second2:
move.w    (a1)+,d1    ; Next colour
cmp.w    #-2,d1        ; end of tab?
bne.s    done2
lea    coltab(PC),a1    ; Colour table - start again from the beginning
move.w    (a1)+,d1    ; Next colour in d1
done2:
move.w    d0,(a0)+    ; YYXX coordinates of the wait
move.w    #$fffe,(a0)+    ; second word of the wait
move.w    #$0180,(a0)+    ; colour0 register
move.w    d1,(a0)+    ; Value of colour0
add.w    #$0100,d0    ; Wait one line below
cmp.w    d2,d0        ; Are we at the bottom? ($20-$40-$60)
bne.s    second2        ; If not, continue
add.w    #$2000,d2	; Set the maximum 20 lower
dbra    d4,loop2
move.l    (sp)+,a5    ; Restore a5
rts

ContaNumLoop1:    dc.w    0
Counter1:    dc.w    0
Counter2:    dc.w	0


dc.w	-2	; inizio tab
coltab:
dc.w	$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
dc.w	$000,$001,$002,$003,$004,$005,$006,$007,$008,$009,$009
dc.w	$00a,$00a,$00b,$00b,$00b,$01c,$02c,$03c,$04c,$05d,$05d
dc.w	$06d,$06d,$07d,$07d,$07d,$08d,$08d,$08d,$09d,$09D,$09C
dc.w	$0aA,$0aA,$0a9,$0a8,$0a7,$0a6,$0a5,$0a4,$0a3,$0b2,$0b1
dc.w	$0b0,$1b0,$2b0,$3b0,$4b0,$5b0,$6b0,$7b0,$8b0,$9b0,$Ab0
dc.w	$Bb0,$Cb0,$Db0,$db0,$db0,$db0,$db0,$da0,$da0,$d90,$d90
dc.w	$d80,$d70,$d60,$d50,$d40,$d30,$d20,$d10,$d00,$d00,$D00
dc.w	$C00,$B00,$A00,$900,$800,$700,$600,$500,$400,$300,$200
dc.w	$100,$000,$000
FineTabCol:
dc.w	-2	; fine tab

; Table of values for bplcon1. As you can see, this causes a ripple.

dc.w	-2	; inizio tab
BplCon1Tab:
dc.w	$11,$11,$11,$22,$22,$33,$44,$55,$55,$66,$66,$66,$077,$077
dc.w	$77,$77,$77,$77,$66,$66,$66,$55,$55,$44,$33,$33,$022,$022
dc.w	$22,$11,$11,$11,$11,$00,$00,$00,$00,$00,$00,$11,$011,$011
dc.w	$11,$11,$22,$22,$22,$22,$33,$33,$44,$44,$55,$55,$055,$055
dc.w	$66,$66,$66,$66,$66,$66,$77,$77,$77,$77,$77,$77,$077,$077
dc.w	$77,$77,$66,$66,$66,$66,$66,$66,$55,$55,$55,$55,$044,$044
dc.w	$33,$33,$33,$33,$22,$22,$22,$22,$22,$22,$11,$11,$011,$011
dc.w    -2    ; end tab

; The rotated tables are copied into this buffer, which are then
; copied back into the tables themselves... a strange way to scroll, isn't it?

TabBuf:
ds.w    128

*****************************************************************************
;            Print routine
*****************************************************************************

PRINTcharacter:
movem.l    d2/a0/a2-a3,-(SP)
MOVE.L    PuntaTESTO(PC),A0 ; Address of the text to be printed in a0
MOVEQ    #0,D2        ; Clear d2
MOVE.B    (A0)+,D2    ; Next character in d2
CMP.B    #$ff,d2        ; End of text signal? ($FF)
beq.s    EndText    ; If yes, exit without printing
TST.B    d2        ; End of line signal? ($00)
bne.s	NonFineRiga    ; If not, do not go to the next line

ADD.L    #40*7,PuntaBITPLANE    ; GO TO THE NEXT LINE
ADDQ.L    #1,PuntaTesto        ; first character of the next line
; (skip ZERO)
move.b    (a0)+,d2        ; first character of the next line
; (skip ZERO)

NonFineRiga:
SUB.B    #$20,D2        ; SUBTRACT 32 FROM THE ASCII VALUE OF THE CHARACTER,
; SO AS TO TRANSFORM, FOR EXAMPLE, THAT
; OF THE SPACE (which is $20), into $00, that
; OF THE ASTERISK ($21), in $01...
LSL.W    #3,D2        ; MULTIPLY THE PREVIOUS NUMBER BY 8,
; since the characters are 8 pixels high
MOVE.L	D2,A2
ADD.L    #FONT,A2    ; FIND THE DESIRED CHARACTER IN THE FONT...

MOVE.L    PuntaBITPLANE(PC),A3 ; Address of the destination bitplane in a3

; PRINT THE CHARACTER LINE BY LINE
MOVE.B	(A2)+,(A3)    ; print LINE 1 of the character
MOVE.B    (A2)+,40(A3)    ; print LINE 2 ‘ ’
MOVE.B    (A2)+,40*2(A3)    ; print LINE 3 ‘ ’
MOVE.B	(A2)+,40*3(A3)    ; print LINE 4 ‘ ’
MOVE.B    (A2)+,40*4(A3)    ; print LINE 5 ‘ ’
MOVE.B    (A2)+,40*5(A3)    ; print LINE 6 ‘ ’
MOVE.B    (A2)+,40*6(A3)    ; print LINE 7 ‘ ’
MOVE.B    (A2)+,40*7(A3)    ; print LINE 8 ‘ ’

ADDQ.L    #1,PuntaBitplane ; advance 8 bits (NEXT CHARACTER)
ADDQ.L    #1,PuntaTesto    ; next character to print

EndText:
movem.l    (SP)+,d2/a0/a2-a3
RTS


TextPointer:
dc.l    TEXT

BitplanePointer:
dc.l    BITPLANE

;    $00 for ‘end of line’ - $FF for ‘end of text’

; number of characters per line: 40
TEXT:     ;         1111111111222222222233333333334
; 1234567890123456789012345678901234567890
dc.b    “ ”,0 ; 1
dc.b    “ This listing changes every ”,0 ; 2
dc.b    “ ”,0 ; 3
dc.b    “ line is either colour1 ($dff184), ”,0 ; 4
dc.b    “ ”,0 ; 5
dc.b    “ than bplcon1 ($dff102). Note ”,0 ; 6
dc.b    “ ”,0 ; 7
dc.b    “ how listings ”,0 ; 8
dc.b    “ ”,0 ; 9
dc.b    “ previously seen into a single ”,0 ; 10
dc.b    “ ”,0 ; 11
dc.b    “ effect. You could also change ”,0 ; 12
dc.b    “ ”,0 ; 13
dc.b    “ other colours and modules for ”,0 ; 14
dc.b    “ ”,0 ; 15
dc.b    “ each line, if you feel like ”,0 ; 16
dc.b    “ ”,0 ; 17
dc.b    “ trying! ”,$FF ; 18

EVEN

;    The 8x8 character FONT (copied to CHIP by the CPU and not by the blitter,
;    so it can also be in fast RAM. In fact, that would be better!

FONT:
incbin    ‘assembler2:sorgenti4/nice.fnt’

*****************************************************************************

section	graficozza,data_C

COPPERLIST:
dc.w	$8e,DIWS	; DiwStrt
dc.w	$90,DIWSt	; DiwStop
dc.w	$92,DDFS	; DdfStart
dc.w    $94,DDFSt    ; DdfStop
dc.w    $100,BPLC0    ; BplCon0
dc.w    $180,$000    ; colour0 black
dc.w    $182,$eee    ; colour1 white
BPLPOINTER:
dc.w    $E0,$0000    ; Bpl0h
dc.w    $E2,$0000    ; Bpl0l
dc.w    $102,$0        ; Bplcon1
dc.w    $104,$0        ; Bplcon2
dc.w    $108,$0		; Bpl1mod
dc.w    $10a,$0        ; Bpl2mod

CopperEffect:
dcb.l    801,0        ; space for the effect (caution! if
; you change the effect, it may become larger
; or smaller)
dc.w    $ffff,$fffe    ; End copperlist

*****************************************************************************

SECTION	MIOPLANE,BSS_C

BITPLANE:
ds.b	40*256	; un bitplane lowres 320x256

end

You may have noticed that the routine is quite tangled and has many strange loops, regulated by counters.
This is necessary to create the colour effect, which is not
a simple scrolling up or down, but the “crossing” of several
scrolls, created by various passes.
