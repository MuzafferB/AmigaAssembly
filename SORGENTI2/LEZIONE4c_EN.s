
; Lesson 4c.s    MERGE OF 3 COPPER EFFECTS + 8-COLOUR FIGURE

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea    GfxName(PC),a1    ; Address of the name of the lib to open in a1
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase    ; save the GFX base address in GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the address of the old copperlist

;*****************************************************************************
;    POINT THE BPLPOINTERS IN THE COPPELIST TO OUR BITPLANES
;*****************************************************************************


MOVE.L    #PIC,d0        ; put the PIC address in d0,
; i.e. where the first bitplane starts

LEA    BPLPOINTERS,A1    ; put the address of the
; pointers to the planes of the COPPERLIST
MOVEQ    #2,D1        ; number of bitplanes -1 (here there are 3)
; to execute the cycle with DBRA
POINTBP:
move.w    d0,6(a1)    ; copy the LOWER word of the plane address
; to the correct word in the copperlist
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
; putting the UPPER word in place of the
; LOWER one, allowing it to be copied with move.w!!
move.w    d0,2(a1)    ; copy the HIGH word of the plane address
; to the correct word in the copperlist
swap    d0        ; swap the 2 words of d0 (e.g.: 3412 > 1234)
; putting the address back in place.
ADD.L	#40*256,d0    ; Add 10240 to D0, making it point
; to the second bitplane (located after the first)
; (i.e. add the length of a plane)
; In the cycles following the first, we will point
; to the third, fourth bitplane, and so on.

addq.w    #8,a1        ; a1 now contains the address of the next
; bplpointers in the copperlist to be written.
dbra    d1,POINTBP    ; Repeat D1 times POINTBP (D1=number of bitplanes)

;

move.l    #COPPERLIST,$dff080    ; Point to our COP
move.w    d0,$dff088        ; Start the COP

move.w    #0,$dff1fc        ; FMODE - Disable AGA
move.w	#$c00,$dff106        ; BPLCON3 - Disable AGA

mouse:
cmpi.b    #$ff,$dff006    ; Are we at line 255?
bne.s    mouse        ; If not, don't continue

bsr.w    muovicopper    ; red bar under line $ff
bsr.w    CopperDestSin    ; Right/left scrolling routine
BSR.w    scrollcolors    ; cyclic colour scrolling

Wait:
cmpi.b    #$ff,$dff006    ; Are we at line 255?
beq.s    Wait        ; If yes, do not continue, wait for the
; next line, otherwise MoveCopper is
; re-executed

btst    #6,$bfe001    ; Left mouse button pressed?
bne.s    mouse        ; If not, return to mouse:


move.l    OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088		; start the old cop

move.l    4.w,a6
jsr    -$7e(a6)    ; Enable - re-enable Multitasking
move.l    gfxbase(PC),a1    ; Base of the library to close
jsr    -$19e(a6)	; Closelibrary - close the graphics library
rts            ; EXIT THE PROGRAM


;    Data

GfxName:
dc.b    ‘graphics.library’,0,0

GfxBase:        ; This is where the base address for the Offsets goes
dc.l    0	; of the graphics.library

OldCop:            ; This is where the address of the old system COP goes
dc.l    0

; **************************************************************************
; *        HORIZONTAL SCROLL BAR (Lesson 3h.s)         *
; **************************************************************************

CopperDESTSIN:
CMPI.W    #85,RightFlag        ; VAIDESTRA executed 85 times?
BNE.S    VAIDESTRA        ; if not yet, re-execute
CMPI.W    #85,LeftFlag    ; VAISINISTRA executed 85 times?
BNE.S    LEFT        ; if not yet, run again
CLR.W    RightFlag    ; the LEFT routine has been run
CLR.W    LeftFlag    ; 85 times, restart
RTS            ; RETURN TO THE LOOP mouse


VAIDESTRA:            ; this routine moves the bar to the RIGHT
lea    CopBar+1,A0    ; Put the address of the first XX in A0
move.w    #29-1,D2    ; we need to change 29 wait (we use a DBRA)
RightLoop:
addq.b    #2,(a0)        ; add 2 to the X coordinate of the wait
ADD.W	#16,a0        ; go to the next wait to be changed
dbra    D2,RightLoop    ; cycle executed d2 times
addq.w    #1,RightFlag    ; mark that we have executed VAIDESTRA
RTS            ; RETURN TO THE LOOP mouse


LEFT:			; this routine moves the bar to the LEFT
lea    CopBar+1,A0
move.w    #29-1,D2    ; we need to change 29 wait
SinistraLoop:
subq.b    #2,(a0)        ; subtract 2 from the X coordinate of the wait
ADD.W    #16,a0        ; go to the next wait to be changed
dbra	D2,SinistraLoop    ; cycle executed d2 times
addq.w    #1,SinistraFlag ; We note the movement
RTS            ; RETURN TO THE LOOP mouse


DestraFlag:        ; This word keeps track of the number of times
dc.w    0    ; VAIDESTRA has been executed

LeftFlag:        ; This word keeps track of the number of times
dc.w 0    ; VAISINISTRA has been executed

; **************************************************************************
; *        RED BAR UNDER THE $FF LINE (Lesson 3f.s)         *
; **************************************************************************

MoveCopper:
LEA    BAR,a0
TST.B    UpDown        ; Should we go up or down?
beq.w    GOUP
cmpi.b    #$0a,(a0)    ; have we reached line $0a+$ff? (265)
beq.s    MettiGiu    ; if so, we are at the top and must go down
subq.b    #1,(a0)
subq.b    #1,8(a0)    ; now let's change the other waits: the distance
subq.b    #1,8*2(a0)    ; between one wait and the next is 8 bytes
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
cmpi.b    #$2c,8*9(a0)	; have we reached line $2c?
beq.s    MettiSu        ; if so, we are at the bottom and must go back up
addq.b    #1,(a0)
addq.b    #1,8(a0)    ; now let's change the other waits: the distance
addq.b    #1,8*2(a0)    ; between one wait and the next is 8 bytes
addq.b    #1,8*3(a0)
addq.b    #1,8*4(a0)
addq.b	#1,8*5(a0)
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
move.w    col5,col4	; col5 copied to col4
move.w    col6,col5    ; col6 copied to col5
move.w    col7,col6    ; col7 copied to col6
move.w    col8,col7    ; col8 copied to col7
move.w    col9,col8    ; col9 copied to col8
move.w    col10,col9    ; col10 copied to col9
move.w    col11,col10    ; col11 copied to col10
move.w    col12,col11    ; col12 copied to col11
move.w    col13,col12	; col13 copied to col12
move.w    col14,col13    ; col14 copied to col13
move.w    col1,col14    ; col1 copied to col14
rts

; **************************************************************************
; *                SUPER COPPERLIST             *
; **************************************************************************

SECTION    GRAPHIC,DATA_C

COPPERLIST:

; Let's point the sprites to ZERO to eliminate them, or we'll find them
; running around like crazy and disturbing everything!

dc.w    $120,$0000,$122,$0000,$124,$0000,$126,$0000,$128,$0000
dc.w	$12a,$0000,$12c,$0000,$12e,$0000,$130,$0000,$132,$0000
dc.w	$134,$0000,$136,$0000,$138,$0000,$13a,$0000,$13c,$0000
dc.w	$13e,$0000

dc.w	$8e,$2c81	; DiwStrt    (registers with normal values)
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0    ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; BPLCON0 for a 3-bitplane screen: (8 colours)

; 5432109876543210
dc.w    $100,%0011001000000000    ; bits 13 and 12 on!! (3 = %011)

;    Let's point the bitplanes directly by putting the registers $dff0e0 and following in the copperlist
;    with the addresses
;    of the bitplanes that will be set by the POINTBP routine

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000	;first bitplane - BPL0PT
dc.w $e4,$0000,$e6,$0000    ;second bitplane - BPL1PT
dc.w $e8,$0000,$ea,$0000    ;third bitplane - BPL2PT

;    The effect of Lesson3e.s moved UP

dc.w    $3a07,$fffe	; wait for line 154 ($9a in hexadecimal)
dc.w    $180        ; COLOUR REGISTER 0
col1:
dc.w    $0f0        ; VALUE OF COLOUR 0 (which will be modified)
dc.w    $3b07,$fffe ; wait for line 155 (will not be modified)
dc.w    $180        ; COLOUR REGISTER 0 (will not be modified)
col2:
dc.w    $0d0        ; COLOUR VALUE 0 (will be modified)
dc.w    $3c07,$fffe    ; wait for line 156 (not modified, etc.)
dc.w    $180        ; COLOUR REGISTER 0
col3:
dc.w    $0b0        ; COLOUR VALUE 0
dc.w     $3d07,$fffe    ; wait for line 157
dc.w    $180        ; COLOUR REGISTER 0
col4:
dc.w    $090        ; COLOUR VALUE 0
dc.w    $3e07,$fffe    ; wait for line 158
dc.w    $180        ; COLOUR REGISTER 0
col5:
dc.w    $070		; COLOUR 0 VALUE
dc.w    $3f07,$fffe    ; wait for line 159
dc.w    $180        ; COLOUR REGISTER 0
col6:
dc.w    $050        ; COLOUR VALUE 0
dc.w    $4007,$fffe    ; wait for line 160
dc.w    $180		; COLOUR REGISTER0
col7:
dc.w    $030        ; COLOUR VALUE 0
dc.w    $4107,$fffe    ; wait for line 161
dc.w    $180        ; colour0... (now you understand the comments,
col8:				; I can stop putting them here!)
dc.w    $030
dc.w    $4207,$fffe    ; line 162
dc.w    $180
col9:
dc.w    $050
dc.w    $4307,$fffe    ; line 163
dc.w    $180
col10:
dc.w    $070
dc.w    $4407,$fffe    ; line 164
dc.w    $180
col11:
dc.w    $090
dc.w    $4507,$fffe    ; line 165
dc.w    $180
col12:
dc.w    $0b0
dc.w    $4607,$fffe    ; line 166
dc.w    $180
col13:
dc.w    $0d0
dc.w	$4707,$fffe    ; line 167
dc.w    $180
col14:
dc.w    $0f0
dc.w     $4807,$fffe    ; line 168

dc.w     $180,$0000    ; Let's decide on BLACK as the colour for the
; part of the screen below the effect


dc.w    $0180,$000    ; colour0
dc.w    $0182,$550    ; colour1    ; we redefine the colour of the
dc.w    $0184,$ff0    ; colour2    ; COMMODORE! YELLOW!
dc.w    $0186,$cc0    ; color3
dc.w    $0188,$990    ; color4
dc.w    $018a,$220    ; color5
dc.w    $018c,$770    ; color6
dc.w    $018e,$440    ; color7

dc.w    $7007,$fffe    ; Wait for the end of the COMMODORE text

;    The 8 colours of the figure are defined here:

dc.w    $0180,$000    ; colour0
dc.w    $0182,$475    ; colour1
dc.w    $0184,$fff    ; colour2
dc.w    $0186,$ccc    ; colour3
dc.w    $0188,$999    ; colour4
dc.w    $018a,$232    ; colour5
dc.w    $018c,$777    ; colour6
dc.w    $018e,$444    ; colour7

; EFFECT OF LESSON 3h.s

dc.w    $9007,$fffe    ; wait for the start of the line
dc.w    $180,$000    ; grey at minimum, i.e. BLACK!!!
CopBar:
dc.w    $9031,$fffe    ; wait for change ($9033,$9035,$9037...)
dc.w    $180,$100    ; red colour
dc.w    $9107,$fffe    ; wait for no change (Start of line)
dc.w    $180,$111    ; GREY colour (from the start of the line to
dc.w    $9131,$fffe    ; at this WAIT, which we will change...
dc.w    $180,$200    ; after which RED begins

;     FIXED WAITS (then grey) - WAIT TO BE CHANGED (followed by red)

dc.w    $9207,$fffe,$180,$222,$9231,$fffe,$180,$300 ; line 3
dc.w    $9307,$fffe,$180,$333,$9331,$fffe,$180,$400 ; line 4
dc.w    $9407,$fffe,$180,$444,$9431,$fffe,$180,$500 ; line 5
dc.w    $9507,$fffe,$180,$555,$9531,$fffe,$180,$600 ; ....
dc.w	$9607,$fffe,$180,$666,$9631,$fffe,$180,$700
dc.w	$9707,$fffe,$180,$777,$9731,$fffe,$180,$800
dc.w	$9807,$fffe,$180,$888,$9831,$fffe,$180,$900
dc.w	$9907,$fffe,$180,$999,$9931,$fffe,$180,$a00
dc.w	$9a07,$fffe,$180,$aaa,$9a31,$fffe,$180,$b00
dc.w	$9b07,$fffe,$180,$bbb,$9b31,$fffe,$180,$c00
dc.w	$9c07,$fffe,$180,$ccc,$9c31,$fffe,$180,$d00
dc.w	$9d07,$fffe,$180,$ddd,$9d31,$fffe,$180,$e00
dc.w	$9e07,$fffe,$180,$eee,$9e31,$fffe,$180,$f00
dc.w	$9f07,$fffe,$180,$fff,$9f31,$fffe,$180,$e00
dc.w	$a007,$fffe,$180,$eee,$a031,$fffe,$180,$d00
dc.w	$a107,$fffe,$180,$ddd,$a131,$fffe,$180,$c00
dc.w	$a207,$fffe,$180,$ccc,$a231,$fffe,$180,$b00
dc.w	$a307,$fffe,$180,$bbb,$a331,$fffe,$180,$a00
dc.w	$a407,$fffe,$180,$aaa,$a431,$fffe,$180,$900
dc.w	$a507,$fffe,$180,$999,$a531,$fffe,$180,$800
dc.w	$a607,$fffe,$180,$888,$a631,$fffe,$180,$700
dc.w	$a707,$fffe,$180,$777,$a731,$fffe,$180,$600
dc.w	$a807,$fffe,$180,$666,$a831,$fffe,$180,$500
dc.w	$a907,$fffe,$180,$555,$a931,$fffe,$180,$400
dc.w	$aa07,$fffe,$180,$444,$aa31,$fffe,$180,$301
dc.w	$ab07,$fffe,$180,$333,$ab31,$fffe,$180,$202
dc.w	$ac07,$fffe,$180,$222,$ac31,$fffe,$180,$103
dc.w	$ad07,$fffe,$180,$113,$ad31,$fffe,$180,$004

dc.w    $ae07,$FFFE    ; next line
dc.w    $180,$006    ; blue at 6
dc.w    $b007,$FFFE    ; jump 2 lines
dc.w	$180,$007    ; blue at 7
dc.w    $b207,$FFFE    ; jump 2 lines
dc.w    $180,$008    ; blue at 8
dc.w    $b507,$FFFE	; jump 3 lines
dc.w    $180,$009    ; blue at 9
dc.w    $b807,$FFFE    ; jump 3 lines
dc.w    $180,$00a	; blue at 10
dc.w    $bb07,$FFFE    ; jump 3 lines
dc.w    $180,$00b    ; blue at 11
dc.w    $be07,$FFFE    ; jump 3 lines
dc.w    $180,$00c    ; blue at 12
dc.w	$c207,$FFFE    ; jump 4 lines
dc.w    $180,$00d    ; blue to 13
dc.w    $c707,$FFFE    ; jump 7 lines
dc.w    $180,$00e    ; blue to 14
dc.w	$ce07,$FFFE    ; jump 6 lines
dc.w    $180,$00f    ; blue at 15
dc.w    $d807,$FFFE    ; jump 10 lines
dc.w    $180,$11F    ; lighten...
dc.w    $e807,$FFFE	; jump 16 lines
dc.w    $180,$22F    ; lighten...

;    Effect of lesson 3f.s

dc.w    $ffdf,$fffe    ; ATTENTION! WAIT AT THE END OF THE $FF LINE!
; the waits after this are below the
; $FF line and start again from $00!!

dc.w    $0107,$FFFE    ; a fixed green bar BELOW the $FF line!
dc.w    $180,$010
dc.w    $0207,$FFFE
dc.w    $180,$020
dc.w    $0307,$FFFE
dc.w	$180,$030
dc.w	$0407,$FFFE
dc.w	$180,$040
dc.w	$0507,$FFFE
dc.w	$180,$030
dc.w	$0607,$FFFE
dc.w	$180,$020
dc.w $0707,$FFFE
dc.w $180,$010
dc.w $0807,$FFFE
dc.w $180,$000

BAR:
dc.w    $0907,$FFFE    ; wait for line $79
dc.w    $180,$300    ; start red bar: red at 3
dc.w    $0a07,$FFFE    ; next line
dc.w    $180,$600    ; red at 6
dc.w	$0b07,$FFFE
dc.w    $180,$900    ; red at 9
dc.w    $0c07,$FFFE
dc.w    $180,$c00    ; red at 12
dc.w    $0d07,$FFFE
dc.w    $180,$f00    ; red at 15 (maximum)
dc.w    $0e07,$FFFE
dc.w    $180,$c00    ; red to 12
dc.w    $0f07,$FFFE
dc.w	$180,$900    ; red at 9
dc.w    $1007,$FFFE
dc.w    $180,$600    ; red at 6
dc.w    $1107,$FFFE
dc.w    $180,$300    ; red at 3
dc.w    $1207,$FFFE
dc.w    $180,$000    ; BLACK colour

dc.w    $FFFF,$FFFE    ; END OF COPPERLIST


; **************************************************************************
; *            8-COLOUR IMAGE 320x256             *
; **************************************************************************

;    Remember to select the directory where the image is located
;    in this case, just write: ‘V df0:SORGENTI2’


PIC:
incbin    ‘amiga.320*256*3’    ; here we load the image in RAW,
; converted with KEFCON, made up of
; 3 consecutive bitplanes

end

In this example there is nothing new, but we have put together many
of the copper effects studied so far: Lesson3h.s, Lesson3f.s, Lesson3e.s,
simply by loading those sources into other text buffers, copying the
routine and the copperlist part of the effect: as you can see, the routines
are one below the other in the order in which I loaded the examples, while the
wait of the copperlists are ‘ADDED’ in a specific order so that
they do not overlap: in fact, I had to move the waits
of the Lesson3f.s effect further up, while I was able to leave the other two the same.
Then, all you need to do is call the routines in the synchronised loop:

bsr.w    muovicopper    ; red bar under line $ff
bsr.w    CopperDestSin    ; Right/left scrolling routine
BSR.w    scrollcolors    ; cyclic colour scrolling

Individual routines are often programmed separately and then put together
as in this example; it is a good idea to practise assembling and disassembling
graphic demos as in this example, because, after all, a large part of
programming consists of assembling routines. Each routine can then
be reused in many listings with simple modifications: for
example, the TEAM 17 programmer certainly used the same joystick management and disk loading routines on all his games, and
the routines that move the characters on the screen are
probably derived from each other with few modifications.
 Every routine you program
or find around can be useful many times, both as an example and to
put it in your own programs. If you had all the routines necessary
for programming a game separated, let's say a joystick.s, a
diskloader.s, a playmusic.s, a scrollscreen.s, etc., making the 
game would be limited to an operation similar to setting the table:
that is, putting the napkins, plates, and cutlery in the right place, so
you would have to put the game together like a puzzle, which would
still require at least a knowledge of how the routines work.
The problem with many demos and games is that the
routines are well combined, the graphics and sound are good, but
one suspects that the routines come from other programmers, stolen
or licensed. On the other hand, if the game works, who cares? It will always be
a nice game but similar to some other, a cross between two. When you program the routines
yourself, you can always tell because you either did them worse
than others or you did them better. So ugly games and beautiful games
are the most “HONESTLY” programmed. But I advise you to leave 
pride aside for now that you are learning, I don't think you can innovate
Amiga programming now! So break down and reassemble the routines you
find in the course as in this listing, the aim is to learn, and there is no
better way to learn than to add and dismantle routines.
 Just don't go around with MY routines saying that you programmed
them all by yourselves. When you have finished this course, you will be able to
do it yourselves, and maybe even come up with innovative ideas. The assembler has no limits.

