
; Lesson 5n.s    MERGE OF 3 COPPER EFFECTS + 8-COLOUR FIGURE with
;        EFFECTS $dff102 and bitplane pointers

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea    GfxName(PC),a1    ; Address of the name of the lib to open in a1
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
move.w    d0,2(a1)    ; copy the HIGH word of the plane swap address
swap    d0        ; swap the 2 words of d0 (e.g.: 3412 > 1234)
ADD.L	#40*256,d0    ; + bitplane length -> next bitplane
addq.w    #8,a1        ; go to the next bplpointers in COP
dbra    d1,POINTBP    ; Repeat D1 times POINTBP (D1=number of bitplanes)

move.l    #COPPERLIST,$dff080	; Point our COP
move.w    d0,$dff088        ; Start the COP

move.w    #0,$dff1fc        ; Disable AGA
move.w    #$c00,$dff106        ; Disable AGA

bsr.w    mt_init		; Initialise music routine

mouse:
cmpi.b    #$ff,$dff006    ; Are we at line 255?
bne.s    mouse        ; If not, don't continue

bsr.w    muovicopper    ; red bar below line $ff
bsr.s    CopperDestSin    ; Right/left scrolling routine
BSR.w    scrollcolors    ; cyclic colour scrolling
bsr.w    ScorriPlanes    ; up-down scrolling of the figure
bsr.w    Ondula        ; Wavering using many $dff102
bsr.w    mt_music    ; Play music

Wait:
cmpi.b    #$ff,$dff006    ; Are we at line 255?
beq.s	Wait        ; If yes, don't continue, wait for the
; next line, otherwise MoveCopper is
; re-executed

btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse        ; if not, return to mouse:

bsr.w    mt_end        ; End the music routine

move.l    OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088        ; start the old cop

move.l    4.w,a6
jsr    -$7e(a6)    ; Enable - re-enable Multitasking
move.l    gfxbase(PC),a1    ; Base of the library to be closed
jsr    -$19e(a6)    ; Closelibrary - close the graphics library
rts            ; EXIT THE PROGRAM


;    Data

GfxName:
dc.b    ‘graphics.library’,0,0
	

GfxBase:        ; This is where the base address for the Offsets goes
dc.l    0    ; of the graphics.library

OldCop:            ; This is where the address of the old system COP goes
dc.l    0

; **************************************************************************
; *        HORIZONTAL SCROLL BAR (Lesson 3h.s)         *
; **************************************************************************

CopperDESTSIN:
CMPI.W    #85,RightFlag        ; VAIDESTRA executed 85 times?
BNE.S    VAIDESTRA        ; if not yet, re-execute
CMPI.W    #85,LeftFlag    ; VAISINISTRA executed 85 times?
BNE.S    VAISINISTRA        ; if not yet, re-execute
CLR.W    RightFlag    ; the VAISINISTRA routine has been executed
CLR.W    LeftFlag    ; 85 times, restart
RTS            ; RETURN TO THE LOOP mouse


VAIDESTRA:            ; this routine moves the bar to the RIGHT
lea    CopBar+1,A0    ; Put the address of the first XX in A0
move.w    #29-1,D2    ; we need to change 29 wait (use a DBRA)
RightLoop:
addq.b    #2,(a0)        ; add 2 to the X coordinate of the wait
ADD.W    #16,a0        ; go to the next wait to be changed
dbra    D2,RightLoop    ; cycle executed d2 times
addq.w    #1,RightFlag    ; mark that we have executed RIGHT
RTS            ; RETURN TO THE LOOP mouse


VAISINISTRA:            ; this routine moves the bar to the LEFT
lea    CopBar+1,A0
move.w    #29-1,D2    ; we need to change 29 waits
SinistraLoop:
subq.b    #2,(a0)        ; subtract 2 from the X coordinate of the wait
ADD.W    #16,a0        ; go to the next wait to be changed
dbra    D2,SinistraLoop    ; cycle executed d2 times
addq.w	#1,LeftFlag ; We note the movement
RTS            ; RETURN TO THE LOOP mouse


RightFlag:        ; This word keeps track of the number of times
dc.w    0    ; VAIDESTRA has been executed

LeftFlag:		; This word keeps track of the number of times
dc.w 0    ; VAISINISTRA has been executed

; **************************************************************************
; *        RED BAR UNDER THE $FF LINE (Lesson 3f.s)         *
; **************************************************************************

MoveCopper:
READ    BAR,a0
TST.B    UpDown        ; Should we go up or down?
beq.w    GOUP
cmpi.b    #$0a,(a0)    ; Have we reached line $0a+$ff? (265)
beq.s	PutDown    ; if so, we are at the top and we have to go down
subq.b    #1,(a0)
subq.b    #1,8(a0)    ; now we change the other waits: the distance
subq.b    #1,8*2(a0)    ; between one wait and another is 8 bytes
subq.b    #1,8*3(a0)
subq.b    #1,8*4(a0)
subq.b    #1,8*5(a0)
subq.b    #1,8*6(a0)
subq.b    #1,8*7(a0)    ; here we have to modify all 9 waits of the
subq.b    #1,8*8(a0)    ; red bar each time to make it go up!
subq.b    #1,8*9(a0)
rts

PutDown:
clr.b    UpDown        ; Resetting UpDown, at TST.B UpDown the BEQ
rts            ; will jump to the VAIGIU routine, and
; the bar will go down

VAIGIU:
cmpi.b	#$2c,8*9(a0)    ; have we reached line $2c?
beq.s    MettiSu        ; if so, we are at the bottom and must go back up
addq.b    #1,(a0)
addq.b    #1,8(a0)    ; now let's change the other waits: the distance
addq.b    #1,8*2(a0)	; between one wait and the next is 8 bytes
addq.b    #1,8*3(a0)
addq.b    #1,8*4(a0)
addq.b    #1,8*5(a0)
addq.b    #1,8*6(a0)
addq.b    #1,8*7(a0)    ; here we have to modify all 9 waits of the
addq.b    #1,8*8(a0)    ; red bar each time to make it go down!
addq.b    #1,8*9(a0)
rts

PutUp:
move.b    #$ff,UpDown    ; When the UpDown label is not zero,
rts            ; it means we have to go back up.


UpDown:
dc.b    0,0

; **************************************************************************
; *        CYCLICAL COLOUR SCROLLING (Lesson 3E.s)         *
; **************************************************************************

Scrollcolors:
move.w    col2,col1    ; col2 copied to col1
move.w    col3,col2    ; col3 copied to col2
move.w    col4,col3    ; col4 copied to col3
move.w    col5,col4    ; col5 copied to col4
move.w    col6,col5    ; col6 copied to col5
move.w    col7,col6    ; col7 copied to col6
move.w    col8,col7    ; col8 copied to col7
move.w    col9,col8    ; col9 copied to col8
move.w    col10,col9    ; col10 copied to col9
move.w    col11,col10    ; col11 copied to col10
move.w    col12,col11	; col12 copied to col11
move.w    col13,col12    ; col13 copied to col12
move.w    col14,col13    ; col14 copied to col13
move.w    col1,col14    ; col1 copied to col14
rts


; **************************************************************************
; *    UP AND DOWN SCROLLING OF THE FIGURE (from Lesson 5g.s)     *
; **************************************************************************

;    This routine moves the figure up and down, acting on the
;    pointers to the bitplanes in copperlist (using the label BPLPOINTERS)

ScorriPlanes:
LEA    BPLPOINTERS,A1    ; With these 4 instructions we retrieve from
move.w	2(a1),d0    ; copperlist the address where it is pointing
swap    d0        ; currently $dff0e0 and we place it
move.w    6(a1),d0    ; in d0 - the opposite of the routine that
; points to the bitplanes! Here, instead of putting
; the address, we take it!!!

TST.B    SuGiu3		; Should we go up or down? If SuGiu is
; reset (i.e. TST checks BEQ)
; then we jump to VAIGIU, if instead it is at $FF
(i.e. if this TST is not verified)
; we continue going up (doing subs)
beq.w    VAIGIU3
cmp.l    #PIC-(40*18),d0    ; are we low enough?
beq.w    MettiGiu3    ; if so, we are at the bottom and must go back up
sub.l    #40,d0        ; subtract 40, i.e. 1 line, doing
; scroll DOWN the figure
bra.s    Finito3

MettiGiu3:
clr.b    SuGiu3        ; Resetting SuGiu, at TST.B SuGiu the BEQ
bra.s    Finito3        ; will jump to the VAIGIU routine

VAIGIU3:
cmpi.l	#PIC+(40*130),d0 ; are we high enough?
beq.s    MettiSu3    ; if so, we are at the bottom and must go back up
add.l    #40,d0        ; Add 40, i.e. 1 line, causing
; the figure to move UP
bra.s    finito3

MettiSu3:
move.b    #$ff,SuGiu3    ; When the SuGiu label is not zero,
rts            ; it means we have to go back up.

Finito3:            ; POINT THE BITPLANE POINTERS
LEA    BPLPOINTERS,A1    ; pointers in the COPPERLIST
MOVEQ
	#2,D1        ; number of bitplanes -1 (here there are 3) POINTBP2:
move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; 
swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the HIGH word of the plane address
swap    d0		; swap the 2 words of d0 (e.g.: 3412 > 1234)
ADD.L    #40*256,d0    ; + bitplane length -> next bitplane
addq.w    #8,a1        ; go to the next bplpointers in the COP
dbra    d1,POINTBP2	; Repeat POINTBP times D1 (D1=number of bitplanes)
rts


;    This byte, indicated by the label SuGiu, is a FLAG.

SuGiu3:
dc.b    0,0


; **************************************************************************
; *    WAVING EFFECT USING MULTIPLE $dff102 (Lesson 5h.s)     *
; **************************************************************************


Ondula:
LEA    CON1EFFETTO+8,A0 ; Source word address in a0
LEA    CON1EFFETTO,A1    ; Destination word address in a1
MOVEQ    #19,D2        ; 20 bplcon1 to be changed in COPLIST
SCAMBIA:
MOVE.W	(A0),(A1)    ; copy two consecutive words - scrolling!
ADDQ.W    #8,A0        ; next pair of words
ADDQ.W    #8,A1        ; next pair of words
DBRA    D2,SWAP    ; repeat ‘SWAP’ the right number of TIMES

MOVE.W    CON1EFFETTO,ULTIMOVALORE ; to make the cycle infinite
RTS                ; copy the first value to the last
; every time.

; **************************************************************************
; *        ROUTINE THAT PLAYS SOUNDTRACKER/PROTRACKER MUSIC     *
; **************************************************************************

include    ‘music.s’    ; routine 100% working on all Amigas

; **************************************************************************
; *                SUPER COPPERLIST             *
; **************************************************************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:

; Let's set the sprites to ZERO to eliminate them, or we'll find them
; running around like crazy and disturbing us!!!

dc.w    $120,$0000,$122,$0000,$124,$0000,$126,$0000,$128,$0000
dc.w	$12a,$0000,$12c,$0000,$12e,$0000,$130,$0000,$132,$0000
dc.w	$134,$0000,$136,$0000,$138,$0000,$13a,$0000,$13c,$0000
dc.w	$13e,$0000

dc.w	$8e,$2c81	; DiwStrt	(registers with normal values)
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0	; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; For a 3-bitplane screen: (8 colours)

; 5432109876543210
dc.w    $100,%0011001000000000    ; bits 13 and 12 on!! (3 = %011)

;    Let's point the bitplanes directly by putting the registers $dff0e0 and following in the copperlist
;    with the addresses
;    of the bitplanes that will be set by the POINTBP routine

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000	;first bitplane
dc.w $e4,$0000,$e6,$0000    ;second bitplane
dc.w $e8,$0000,$ea,$0000    ;third bitplane

;	The 8 colours in the figure here are made more ‘green’

dc.w    $0180,$000    ; colour0
dc.w    $0182,$070    ; colour1
dc.w    $0184,$0f0    ; colour2
dc.w    $0186,$0c0    ; colour3
dc.w    $0188,$090    ; colour4
dc.w    $018a,$030    ; colour5
dc.w    $018c,$070	
; color6
dc.w    $018e,$040    ; color7

;    The effect of Lesson3e.s moved UP

dc.w    $2c07,$fffe    ; wait for line 154 ($9a in hexadecimal)
dc.w    $180        ; COLOUR REGISTER 0
col1:
dc.w    $0f0        ; COLOUR 0 VALUE (to be modified)
dc.w    $2d07,$fffe ; wait for line 155 (will not be modified)
dc.w    $180        ; COLOUR0 REGISTER (will not be modified)
col2:
dc.w    $0d0        ; COLOUR 0 VALUE (will be modified)
dc.w    $2e07,$fffe    ; wait for line 156 (not modified, etc.)
dc.w    $180        ; COLOUR0 REGISTER
col3:
dc.w    $0b0        ; COLOUR 0 VALUE
dc.w     $2f07,$fffe    ; wait for line 157
dc.w    $180        ; COLOUR REGISTER 0
col4:
dc.w    $090        ; COLOUR VALUE 0
dc.w    $3007,$fffe    ; wait for line 158
dc.w    $180        ; COLOUR REGISTER 0
col5:
dc.w	$070        ; COLOUR VALUE 0
dc.w    $3107,$fffe    ; wait for line 159
dc.w    $180        ; COLOUR REGISTER 0
col6:
dc.w    $050        ; COLOUR VALUE 0
dc.w    $3207,$fffe	; wait for line 160
dc.w    $180        ; COLOUR REGISTER0
col7:
dc.w    $030        ; COLOUR VALUE 0
dc.w    $3307,$fffe    ; wait for line 161
dc.w    $180        ; colour0... (now you understand the comments,
col8:                ; I can stop putting them here!)
dc.w    $030
dc.w    $3407,$fffe    ; line 162
dc.w    $180
col9:
dc.w    $050
dc.w    $3507,$fffe    ; line 163
dc.w    $180
col10:
dc.w    $070
dc.w	$3607,$fffe    ; line 164
dc.w    $180
col11:
dc.w    $090
dc.w    $3707,$fffe    ; line 165
dc.w    $180
col12:
dc.w    $0b0
dc.w    $3807,$fffe	; line 166
dc.w    $180
col13:
dc.w    $0d0
dc.w    $3907,$fffe    ; line 167
dc.w    $180
col14:
dc.w    $0f0
dc.w     $3a07,$fffe    ; line 168

dc.w    $0180,$000    ; colour0    ; actual colours of the figure
dc.w    $0182,$475    ; colour1
dc.w    $0184,$fff    ; colour2
dc.w    $0186,$ccc    ; colour3
dc.w    $0188,$999	; colour4
dc.w    $018a,$232    ; colour5
dc.w    $018c,$777    ; colour6
dc.w    $018e,$444    ; colour7

;    Copper effect of the ripple with $dff102 from Lesson 5h.s ‘restricted’

DC.W    $102
CON1EFFETTO:
dc.w	$000
DC.W	$4007,$FFFE,$102,$00
DC.W	$4407,$FFFE,$102,$11
DC.W	$4807,$FFFE,$102,$11
DC.W	$4C07,$FFFE,$102,$22
DC.W	$5007,$FFFE,$102,$33
DC.W	$5407,$FFFE,$102,$44
DC.W	$5807,$FFFE,$102,$66
DC.W	$5C07,$FFFE,$102,$66
DC.W	$6007,$FFFE,$102,$77
DC.W	$6407,$FFFE,$102,$77
DC.W	$6807,$FFFE,$102,$77
DC.W	$6C07,$FFFE,$102,$66
DC.W	$7007,$FFFE,$102,$66
DC.W	$7407,$FFFE,$102,$55
DC.W	$7807,$FFFE,$102,$33
DC.W	$7C07,$FFFE,$102,$22
DC.W	$8007,$FFFE,$102,$11
DC.W	$8407,$FFFE,$102,$11
DC.W	$8807,$FFFE,$102,$00
DC.W	$8C07,$FFFE,$102
ULTIMOVALORE:
DC.W	$00

;	EFFECT OF LESSON 3h.s

dc.w    $9007,$fffe    ; wait for the start of the line
dc.w    $180,$000    ; grey at minimum, i.e. BLACK!!!
CopBar:
dc.w	$9031,$fffe    ; wait for change ($9033,$9035,$9037...)
dc.w    $180,$100    ; red colour
dc.w    $9107,$fffe    ; wait for no change (Start of line)
dc.w    $180,$111    ; GREY colour (from the start of the line to
dc.w    $9131,$fffe    ; WAIT here, which we will change...
dc.w    $180,$200    ; after which RED begins

;     FIXED WAIT (then grey) - WAIT TO BE CHANGED (followed by red)

dc.w    $9207,$fffe,$180,$120,$9231,$fffe,$180,$301 ; line 3
dc.w    $9307,$fffe,$180,$230,$9331,$fffe,$180,$401 ; line 4
dc.w    $9407,$fffe,$180,$240,$9431,$fffe,$180,$502 ; line 5
dc.w    $9507,$fffe,$180,$350,$9531,$fffe,$180,$603 ; ....
dc.w	$9607,$fffe,$180,$360,$9631,$fffe,$180,$703
dc.w	$9707,$fffe,$180,$470,$9731,$fffe,$180,$803
dc.w	$9807,$fffe,$180,$580,$9831,$fffe,$180,$904
dc.w	$9907,$fffe,$180,$690,$9931,$fffe,$180,$a04
dc.w	$9a07,$fffe,$180,$7a0,$9a31,$fffe,$180,$b04
dc.w	$9b07,$fffe,$180,$8b0,$9b31,$fffe,$180,$c05
dc.w	$9c07,$fffe,$180,$9c0,$9c31,$fffe,$180,$d05
dc.w	$9d07,$fffe,$180,$ad0,$9d31,$fffe,$180,$e05
dc.w	$9e07,$fffe,$180,$be0,$9e31,$fffe,$180,$f05
dc.w	$9f07,$fffe,$180,$cf0,$9f31,$fffe,$180,$e05
dc.w	$a007,$fffe,$180,$be0,$a031,$fffe,$180,$d05
dc.w	$a107,$fffe,$180,$ad0,$a131,$fffe,$180,$c05
dc.w	$a207,$fffe,$180,$9c0,$a231,$fffe,$180,$b04
dc.w	$a307,$fffe,$180,$8b0,$a331,$fffe,$180,$a04
dc.w	$a407,$fffe,$180,$7a0,$a431,$fffe,$180,$904
dc.w	$a507,$fffe,$180,$690,$a531,$fffe,$180,$803
dc.w	$a607,$fffe,$180,$580,$a631,$fffe,$180,$703
dc.w	$a707,$fffe,$180,$470,$a731,$fffe,$180,$603
dc.w	$a807,$fffe,$180,$360,$a831,$fffe,$180,$502
dc.w	$a907,$fffe,$180,$250,$a931,$fffe,$180,$402
dc.w	$aa07,$fffe,$180,$140,$aa31,$fffe,$180,$301
dc.w	$ab07,$fffe,$180,$130,$ab31,$fffe,$180,$202
dc.w	$ac07,$fffe,$180,$120,$ac31,$fffe,$180,$103
dc.w    $ad07,$fffe,$180,$111,$ad31,$fffe,$180,$004

dc.w    $ae07,$fffe
dc.w    $180,$002
dc.w    $af07,$fffe
dc.w    $180,$003

;    ‘Cylindrical’ mirror effect from Lesson 3g.s (+colour redefinition)

dc.w    $0182,$235    ; colour1
dc.w    $0184,$99e    ; colour2
dc.w    $0186,$88c    ; colour3
dc.w    $0188,$659    ; colour4
dc.w    $018a,$122    ; colour5
dc.w    $018c,$337    ; colour6
dc.w    $018e,$224    ; colour7

dc.w    $b007,$fffe
dc.w    $180,$004    ; Colour0
dc.w    $102,$011    ; bplcon1
dc.w    $108,-40*7    ; Bpl1Mod - mirror halved 5 times
dc.w    $10a,-40*7    ; Bpl2Mod
dc.w    $b307,$fffe

dc.w    $180,$006	; Colour0
dc.w    $102,$022    ; bplcon1
dc.w    $108,-40*6    ; Bpl1Mod - mirror halved 4 times
dc.w    $10a,-40*6	; Bpl2Mod

dc.w    $b607,$fffe

dc.w    $0182,$245    ; colour1
dc.w    $0184,$9cf    ; colour2
dc.w    $0186,$89c    ; colour3
dc.w    $0188,$669    ; colour4
dc.w    $018a,$132    ; colour5
dc.w    $018c,$347    ; colour6
dc.w    $018e,$234    ; colour7

dc.w    $180,$008    ; Color0
dc.w    $102,$033    ; bplcon1
dc.w    $108,-40*5    ; Bpl1Mod - mirror halved 3 times
dc.w    $10a,-40*5    ; Bpl2Mod

dc.w    $bb07,$fffe

dc.w    $180,$00a    ; Colour0
dc.w	$102,$044    ; bplcon1
dc.w    $108,-40*4    ; Bpl1Mod - mirror halved 2 times
dc.w    $10a,-40*4    ; Bpl2Mod

dc.w	$c307,$fffe

dc.w    $0182,$355    ; colour1
dc.w    $0184,$abf    ; colour2
dc.w    $0186,$9ac    ; colour3
dc.w	$0188,$779    ; colour4
dc.w    $018a,$232    ; colour5
dc.w    $018c,$457    ; colour6
dc.w    $018e,$344    ; colour7
dc.w    $180,$00c    ; Colour0
dc.w    $102,$055    ; bplcon1
dc.w    $108,-40*3    ; Bpl1Mod - mirror halved
dc.w    $10a,-40*3    ; Bpl2Mod

dc.w    $d007,$fffe

dc.w    $180,$00e    ; Colour0
dc.w    $102,$066    ; bplcon1
dc.w    $108,-40*2    ; Bpl1Mod - normal mirror
dc.w    $10a,-40*2    ; Bpl2Mod

dc.w    $d607,$fffe
dc.w    $0182,$465    ; colour1
dc.w    $0184,$cdf    ; colour2
dc.w    $0186,$bbc    ; colour3
dc.w    $0188,$889    ; colour4
dc.w    $018a,$232    ; colour5
dc.w    $018c,$557    ; colour6
dc.w    $018e,$444    ; colour7

dc.w    $180,$00f    ; Color0
dc.w    $102,$077    ; bplcon1
dc.w    $108,-40    ; Bpl1Mod - FLOOD, repeated lines for
dc.w    $10a,-40    ; Bpl2Mod - central enlargement effect

dc.w    $da07,$fffe

dc.w    $0182,$355    ; colour1
dc.w    $0184,$abf    ; colour2
dc.w    $0186,$9ac    ; colour3
dc.w    $0188,$779    ; colour4
dc.w    $018a,$232	; colour5
dc.w    $018c,$457    ; colour6
dc.w    $018e,$344    ; colour7
dc.w    $180,$00e    ; Colour0
dc.w    $102,$066    ; bplcon1
dc.w    $108,-40*2    ; Bpl1Mod - normal mirror
dc.w    $10a,-40*2    ; Bpl2Mod

dc.w    $e007,$fffe

dc.w    $0182,$245    ; colour1
dc.w    $0184,$9cf    ; colour2
dc.w	$0186,$89c    ; colour3
dc.w    $0188,$669    ; colour4
dc.w    $018a,$132    ; colour5
dc.w    $018c,$347    ; colour6
dc.w    $018e,$234	; colour7
dc.w    $180,$00c    ; Colour0
dc.w    $102,$055    ; bplcon1
dc.w    $108,-40*3    ; Bpl1Mod - mirror halved
dc.w    $10a,-40*3    ; Bpl2Mod

dc.w    $ed07,$fffe

dc.w    $180,$00a    ; Colour0
dc.w    $102,$044    ; bplcon1
dc.w    $108,-40*4    ; Bpl1Mod - mirror halved twice
dc.w    $10a,-40*4    ; Bpl2Mod

dc.w    $f507,$fffe

dc.w    $0182,$235    ; colour1
dc.w    $0184,$99e    ; colour2
dc.w    $0186,$88c    ; colour3
dc.w    $0188,$659    ; colour4
dc.w    $018a,$122    ; colour5
dc.w    $018c,$337    ; colour6
dc.w    $018e,$224    ; colour7
dc.w    $180,$008    ; Colour0
dc.w    $102,$033    ; bplcon1
dc.w    $108,-40*5    ; Bpl1Mod - mirror halved 3 times
dc.w    $10a,-40*5    ; Bpl2Mod

dc.w    $fa07,$fffe

dc.w    $180,$006    ; Colour0
dc.w    $102,$022    ; bplcon1
dc.w    $108,-40*6    ; Bpl1Mod - mirrored 4 times
dc.w    $10a,-40*6    ; Bpl2Mod

dc.w    $fd07,$fffe

dc.w    $180,$004    ; Color0
dc.w    $102,$011	; bplcon1
dc.w    $108,-40*7    ; Bpl1Mod - mirror halved 5 times
dc.w    $10a,-40*7    ; Bpl2Mod

dc.w    $ff07,$fffe

dc.w    $180,$002	; Colour0
dc.w    $102,$000    ; bplcon1
dc.w    $108,-40    ; freeze the image to avoid displaying
dc.w    $10a,-40    ; the bytes before the RAW

;    Effect of lesson 3f.s

dc.w    $ffdf,$fffe    ; ATTENTION! WAIT AT THE END OF THE LINE $FF!
; the waits after this are below the line
; $FF and start again from $00!!

dc.w    $0107,$FFFE    ; a fixed green bar BELOW the line $FF!
dc.w    $180,$010
dc.w    $0207,$FFFE
dc.w    $180,$020
dc.w    $0307,$FFFE
dc.w    $180,$030
dc.w    $0407,$FFFE
dc.w    $180,$040
dc.w    $0507,$FFFE
dc.w    $180,$030
dc.w    $0607,$FFFE
dc.w    $180,$020
dc.w    $0707,$FFFE
dc.w    $180,$010
dc.w    $0807,$FFFE
dc.w    $180,$000

BAR:
dc.w    $0907,$FFFE    ; wait for line $79
dc.w    $180,$300    ; start red bar: red at 3
dc.w    $0a07,$FFFE	; next line
dc.w    $180,$600    ; red at 6
dc.w    $0b07,$FFFE
dc.w    $180,$900    ; red at 9
dc.w    $0c07,$FFFE
dc.w    $180,$c00    ; red at 12
dc.w    $0d07,$FFFE
dc.w    $180,$f00    ; red at 15 (maximum)
dc.w    $0e07,$FFFE
dc.w    $180,$c00    ; red at 12
dc.w    $0f07,$FFFE
dc.w    $180,$900	; red at 9
dc.w    $1007,$FFFE
dc.w    $180,$600    ; red at 6
dc.w    $1107,$FFFE
dc.w    $180,$300    ; red at 3
dc.w    $1207,$FFFE
dc.w    $180,$000    ; colour BLACK

dc.w    $FFFF,$FFFE    ; END OF COPPERLIST


; **************************************************************************
; *            8-COLOUR IMAGE 320x256             *
; **************************************************************************

dcb.b    40*98,0        ; space cleared

PIC:
incbin    ‘amiga.320*256*3’    ; here we load the figure in RAW,
; converted with KEFCON, made up of
; 3 consecutive bitplanes
dcb.b    40*8,0        ; space cleared

; **************************************************************************
; *                PROTRACKER MUSIC             *
; **************************************************************************

mt_data:
incbin    ‘mod.purple-shades’

end

; **************************************************************************

This listing is nothing more than Lesson4c.s to which I added Lesson4g.s
and Lesson4h.s. the only changes are two:
1) I had to decrease the ‘wavy’ effect as a WAIT number to make it
fit between one effect and another, going from 45 to 20.
2) I changed the palette of the figure at the top, making it green
as if the figure were “sliding” into the ‘scrollColors’ effect, and I
changed the colours here and there to improve (and lengthen) the SUPERCOPPERLIST!

The real news is the inclusion of the routine that plays the music!
To begin with, instead of inserting it into the listing, I preferred to
use the ASMONE ‘INCLUDE’ directive, which allows me to 
INCLUDE a piece of listing in my listing.
So let's see how to provide music for our productions: first of all,
 it must be clarified that the music is in a particular format, in this
case PROTRACKER, it is not a piece ‘SAMPLED’ with a digitiser and
replayed. There are various programs for composing music, the most widely used is
Protracker (compatible with Soundtracker and Noisetracker), which saves music
in MOD format. In fact, music in this format often begins with
MOD. However, it is not necessary to always use Protracker music. Certain
Amiga games or demos, especially older ones, have music composed
with programs such as MED, OCTAMED, FUTURE COMPOSER, SOUNDMONITOR, OKTALYZER, but
in this case you need to 'playthe music with the routine designed to play
such music formats. In fact, together with the music programme, there is usually
a REPLAY routine, which can be included in the list to play it again.
Nowadays, 99% of Amiga productions use Protracker music, or at least
subspecies of Protracker, i.e. routines that compress or optimise a
module in protracker format and turn it into ‘prorunner’ or ‘propacker’.
Therefore, in this course I have included the routine that plays PROTRACKER music,
compatible with various NOISETRACKER and SOUNDTRACKER modules, which I have modified to make it 100% compatible with 68020+ microprocessors even with CACHE active. In fact, originally this replay routine had problems with processors that were too slow, but I have also modified it to make it compatible with CACHE.more, I have
modified it to make it 100% compatible with 68020+ microprocessors, even
with CACHE enabled. In fact, this replay routine originally had
problems with processors that were too fast, causing some notes to be “cut” or “lost”
during playback. So the “music.s” routine sounds good
even on the Amiga 4000.
To use it, just insert it in the listing, or with the ‘I’ command, or you can
load it into another text buffer and copy it into your listing.
Personally, I prefer to save space in the listings and include it with the
‘INCLUDE’ directive, which basically assembles the routine as if it had
has been inserted manually, but you save the 21k of its length:
imagine you have 5 sources, and you want to put the music in each one:

source1.s    12234 bytes
source2.s    23523 bytes
source3.s    29382 bytes
source4.s	78343 bytes
source5.s    10482 bytes
source6.s    14925 bytes
source7.s    29482 bytes

Together they are about 200k long, while after adding all 21k of the
REPLAY-ROUTINE they would take up a total of about 300k! Whereas adding
only the line

include    ‘music.s’

The increase would be a few bytes, and the result would be the same.
The only difference is that, as in INCBIN, you need to be in the directory
where the file to be included is located, or you need to write the entire path:

include    ‘df0:sorgenti2/music.s’

Once inside the listing, using INCLUDE or insertion, the routine
must be run. EASY! Just run ‘mt_init’ before the
MOUSE loop to initialise it, run “mt_music” every FRAME to play,
and run ‘mt_end’ at the end before exiting to terminate and close the audio channels
:

bsr.w    mt_init        ; Initialise music routine

mouse:
cmpi.b    #$ff,$dff006    ; Are we at line 255?
bne.s    mouse        ; If not, don't continue

bsr.w    MyGraphicsRoutine
bsr.w    mt_music

btst    #6,$bfe001	; Left mouse button pressed?
bne.s    mouse        ; If not, return to mouse:

bsr.w    mt_end        ; End music routine

The music must obviously be loaded. Just load it with INCBIN at the
label ‘mt_data’:

mt_data:
incbin    ‘mod.purple-shades’

The music on the course disc is by HI-LITE from VISION FACTORY, a
song from a few years ago, which I chose because it is only 13k long!
If you want to play your own music, just load it with INCBIN:


mt_data:
incbin    ‘df1:modules/mod.MYMUSIC’    ; for example!
