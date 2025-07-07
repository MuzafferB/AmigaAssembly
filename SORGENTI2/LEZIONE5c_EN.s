
; Lesson 5c.s    MOVING A FIGURE UP AND DOWN BY MODIFYING THE
;        POINTERS TO THE PITPLANES IN THE COPPERLIST

SECTION	CiriCop,CODE

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
MOVEQ    #2,D1		; number of bitplanes -1 (here there are 3)
POINTBP:
move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)	; copy the HIGH word of the plane swap address
d0        ; swap the 2 words of d0 (e.g.: 3412 > 1234)
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

btst    #2,$dff016    ; if the right key is pressed, jump
beq.s    Wait        ; the scroll routine, blocking it


bsr.w    MoveCopper    ; scrolls the figure up and down
; one line at a time, changing the
; pointers to the bitplanes in copperlist

Wait:
cmpi.b    #$ff,$dff006    ; Are we at line 255?
beq.s    Wait        ; If yes, don't continue, wait!

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


;    This routine moves the figure up and down, acting on
;    the pointers to the bitplanes in copperlist (via the BPLPOINTERS label)
;    The structure is similar to that of Lesson3d.s
;    First, we put the address that the BPLPOINTERS are pointing to
;    in d0, then we add or subtract 40 from d0, and finally, to modify
;    the BPLPOINTERS in copperlist, we must ‘repoint’ the changed value
;    in d0 with the same POINTBP routine.

MoveCopper:
LEA    BPLPOINTERS,A1	; With these 4 instructions we retrieve from
move.w    2(a1),d0    ; copperlist the address where
swap    d0        ; currently $dff0e0 is pointing and we place it
move.w    6(a1),d0    ; in d0 - the opposite of the routine that
; points the bitplanes! Here, instead of putting
; the address, we take it!!!

TST.B    SuGiu        ; Do we need to go up or down? If SuGiu is
; reset (i.e. TST checks BEQ)
; then we jump to VAIGIU, if instead it is at $FF
; (i.e. this TST is not verified)
; we continue going up (doing subs)
beq.w	VAIGIU
cmp.l    #PIC-(40*30),d0    ; are we high enough?
beq.s    MettiGiu    ; if so, we are at the top and must go down
sub.l    #40,d0        ; subtract 40, i.e. 1 line, causing
; the figure to scroll DOWN
bra.s    Finito

MettiGiu:
clr.b    SuGiu        ; Resetting SuGiu, at TST.B SuGiu the BEQ
bra.s    Finito        ; will jump to the VAIGIU routine

VAIGIU:
cmpi.l    #PIC+(40*30),d0    ; are we low enough?
beq.s    MettiSu        ; if so, we are at the bottom and must go back up
add.l    #40,d0		; Add 40, i.e. 1 line, causing
; the figure to scroll UP
bra.s    finished

MettiSu:
move.b    #$ff,SuGiu    ; When the SuGiu label is not zero,
rts            ; it means we have to go back up.

Finito:                ; POINT THE BITPLANE POINTERS
LEA    BPLPOINTERS,A1    ; pointers in the COPPERLIST
MOVEQ    #2,D1        ; number of bitplanes -1 (here there are 3)
POINTBP2:
move.w    d0,6(a1)    ; copy the LOW word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the HIGH word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 3412 > 1234)
ADD.L    #40*256,d0    ; + bitplane length -> next bitplane
addq.w	#8,a1        ; go to the next bplpointers in COP
dbra    d1,POINTBP2    ; Repeat D1 times POINTBP (D1=number of bitplanes)
rts


;    This byte, indicated by the label SuGiu, is a FLAG.

SuGiu:
dc.b	0,0


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
dc.w    $102,0        ; BplCon1
dc.w    $104,0		; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210    ; BPLCON0:
dc.w    $100,%0011001000000000	; bits 13 and 12 on!! (3 = %011)
; 3 lowres bitplanes, no lace
BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane - BPL0PT
dc.w $e4,$0000,$e6,$0000	;second bitplane - BPL1PT
dc.w $e8,$0000,$ea,$0000    ;third     bitplane - BPL2PT

dc.w    $0180,$000    ; colour0
dc.w    $0182,$475    ; colour1
dc.w    $0184,$fff    ; colour2
dc.w    $0186,$ccc    ; colour3
dc.w    $0188,$999    ; colour4
dc.w    $018a,$232    ; colour5
dc.w    $018c,$777    ; colour6
dc.w    $018e,$444    ; colour7

; Insert the copperlist piece here

dc.w    $FFFF,$FFFE    ; End of copperlist

;    figure

dcb.b    40*30,0    ; this zeroed space is needed because when we move
; to view lower and higher, we exit
; the PIC area and view what is
; before and after the PIC itself, which would cause
; scattered bytes of noise to be displayed.
; By putting zero bytes at that point,
; $0000 is displayed, which is the background colour.

PIC:
incbin    ‘amiga.320*256*3’    ; Here we load the image in RAW,
; converted with KEFCON, made up of
; 3 consecutive bitplanes

dcb.b    40*30,0    ; see above

; NOTE: The dcb.b is used to put many bytes that are the same in memory,
; writing dcb.b 10,0 is like writing dc.b 0 10 times.
;

end

This routine basically adds or subtracts 40 from the address pointed to by the
BPLPOINTERS in copperlist, first reading the ‘current’ address with
the routine opposite to the one that points to the bitplanes.
With this method, you can also display images larger than the
screen, displaying one part at a time with the possibility of scrolling
up or down.
 For example, in FLIPPER games, such as PINBALL DREAMS, the game screen is longer than what is visible and scrolls up or down to display the part where the ball bounces, changing the pointers of the
bitplanes.
In this example, as we move, we also see lines outside our
figure, as it is only 256 lines long and we scroll 30 lines above and 30 below, i.e. 316 lines in total. This is why there are dcb.b before and after the figure, to ‘clean up’ the area that appears when scrolling.
30 lines above and 30 below, i.e. 316 lines in total. This is why there are dcb.b before and after the figure, to ‘clean up’ the area that appears when scrolling.
30 lines above and 30 below, i.e. 316 lines in total. This is why there are
dcb.b before and after the figure, to “clean up” the area that appears
scrolling outside the RAW bitplanes. Try changing them like this:

dcb.b    40*30,%11001100

When you run the listing, you will notice that the parts outside the PIC are ‘STRIPES’ instead of
zeroed. In fact, we have filled them with %110011001100110011001100110011
110011001100110011001100110011
110011001100110011001100110011
Ossia di strisce di bit.

You can also scroll the 3 bitplanes separately: to do this, simply
enable only 1 bitplane in $dff100:

; 5432109876543210
dc.w    $100,%0001001000000000	; 1 bitplane

And change the maximum position that can be reached by scrolling:

VAIGIU:
cmpi.l    #PIC+(40*530),d0; are we low enough?
beq.s    MettiSu        ; if so, we are at the bottom and we have to go back up
...

This way you will see the 3 bitplanes scrolling separately, as they are
placed one after the other.

* Here is a change to make to the copperlist: what happens if we change all
8 colours of the figure every 2 lines? Copy (with Amiga+b+c+i) this piece
of the copperlist and insert it before the end of the copperlist:

; Insert the piece of copperlist here

By changing the 8-colour palette 52 times, you will get 8*52= 416 colours changed,
but considering that colour 0, being the background, must always remain BLACK,
it is not changed, only the other 7, and not in ‘numerical’ order, but in
“random” order. In fact, the order in which the colours are updated does not matter
for the result. You can change colour 2 first, then colour 3, etc., while in
this example, we ‘start’ from colour 5 ($dff18a), then change colour 7, etc.
By changing 7 colours 52 times and inserting this copperlist, we obtain 364
effective colours on the screen at the same time, which is not bad, considering
that the screen “officially” only displays 8 colours. (7*52=364)


;2
dc.w $18a,$102,$18e,$212,$182,$223    ; colour 5, colour 7, colour 2
dc.w $18c,$323,$188,$323,$186,$334,$184,$434 ; colour 6, colour 4, colour 3, colour 2
dc.w $5007,$fffe
;3
dc.w $18a,$104,$18e,$214,$182,$225
dc.w $18c,$324,$188,$324,$186,$335,$184,$435
dc.w $5207,$fffe
;4
dc.w $18a,$203,$18e,$313,$182,$324
dc.w $18c,$423,$188,$423,$186,$434,$184,$534
dc.w $5407,$fffe
;5
dc.w $18a,$213,$18e,$313,$182,$324
dc.w $18c,$433,$188,$433,$186,$434,$184,$534
dc.w $5607,$fffe
;6
dc.w $18a,$114,$18e,$214,$182,$224
dc.w $18c,$323,$188,$323,$186,$334,$184,$434
dc.w $5807,$fffe
;7
dc.w $18a,$101,$18e,$211,$182,$222
dc.w $18c,$312,$188,$322,$186,$333,$184,$433
dc.w $5a07,$fffe
;8
dc.w $18a,$101,$18e,$211,$182,$222
dc.w $18c,$312,$188,$312,$186,$323,$184,$423
dc.w $5c07,$fffe
;9
dc.w $18a,$101,$18e,$211,$182,$222
dc.w $18c,$312,$188,$312,$186,$323,$184,$423
dc.w $5e07,$fffe
;10
dc.w $18a,$101,$18e,$211,$182,$222
dc.w $18c,$322,$188,$312,$186,$323,$184,$433
dc.w $6007,$fffe
;11
dc.w $18a,$110,$18e,$210,$182,$221
dc.w $18c,$321,$188,$311,$186,$322,$184,$432
dc.w $6207,$fffe
;12
dc.w $18a,$210,$18e,$310,$182,$321
dc.w $18c,$421,$188,$411,$186,$422,$184,$532
dc.w $6407,$fffe
;13
dc.w $18a,$210,$18e,$320,$182,$331
dc.w $18c,$431,$188,$421,$186,$432,$184,$542
dc.w $6607,$fffe
;14
dc.w $18a,$220,$18e,$330,$182,$431
dc.w $18c,$441,$188,$431,$186,$442,$184,$552
dc.w $6807,$fffe
;15
dc.w $18a,$220,$18e,$330,$182,$431
dc.w $18c,$440,$188,$430,$186,$441,$184,$551
dc.w $6a07,$fffe
;16
dc.w $18a,$220,$18e,$330,$182,$431
dc.w $18c,$441,$188,$431,$186,$442,$184,$552
dc.w $6c07,$fffe
;17
dc.w $18a,$120,$18e,$230,$182,$331
dc.w $18c,$341,$188,$331,$186,$342,$184,$452
dc.w $6e07,$fffe
;18
dc.w $18a,$120,$18e,$230,$182,$341
dc.w $18c,$351,$188,$341,$186,$352,$184,$462
dc.w $7007,$fffe
;19
dc.w $18a,$121,$18e,$231,$182,$332
dc.w $18c,$342,$188,$332,$186,$343,$184,$453
dc.w $7207,$fffe
;20
dc.w $18a,$021,$18e,$131,$182,$232
dc.w $18c,$242,$188,$232,$186,$243,$184,$353
dc.w $7407,$fffe
;21
dc.w $18a,$022,$18e,$132,$182,$233
dc.w $18c,$243,$188,$233,$186,$244,$184,$354
dc.w $7607,$fffe
;22
dc.w $18a,$012,$18e,$122,$182,$223
dc.w $18c,$233,$188,$223,$186,$234,$184,$344
dc.w $7807,$fffe
;23
dc.w $18a,$013,$18e,$123,$182,$224
dc.w $18c,$234,$188,$224,$186,$235,$184,$345
dc.w $7a07,$fffe
;24
dc.w $18a,$013,$18e,$023,$182,$124
dc.w $18c,$134,$188,$124,$186,$135,$184,$245
dc.w $7c07,$fffe
;25
dc.w $18a,$013,$18e,$123,$182,$224
dc.w $18c,$234,$188,$224,$186,$235,$184,$345
dc.w $7e07,$fffe
;26
dc.w $18a,$012,$18e,$122,$182,$223
dc.w $18c,$233,$188,$223,$186,$234,$184,$344
dc.w $8007,$fffe
;27
dc.w $18a,$022,$18e,$132,$182,$233
dc.w $18c,$243,$188,$233,$186,$244,$184,$354
dc.w $8207,$fffe
;28
dc.w $18a,$112,$18e,$132,$182,$233
dc.w $18c,$233,$188,$233,$186,$244,$184,$344
dc.w $8407,$fffe
;29
dc.w $18a,$102,$18e,$222,$182,$223
dc.w $18c,$323,$188,$323,$186,$334,$184,$443
dc.w $8607,$fffe
;30
dc.w $18a,$101,$18e,$211,$182,$222
dc.w $18c,$322,$188,$322,$186,$333,$184,$433
dc.w $8807,$fffe
;31
dc.w $18a,$104,$18e,$214,$182,$225
dc.w $18c,$324,$188,$324,$186,$335,$184,$435
dc.w $8a07,$fffe
;32
dc.w $18a,$203,$18e,$313,$182,$324
dc.w $18c,$423,$188,$423,$186,$434,$184,$534
dc.w $8c07,$fffe
;33
dc.w $18a,$213,$18e,$313,$182,$324
dc.w $18c,$433,$188,$433,$186,$434,$184,$534
dc.w $8e07,$fffe
;34
dc.w $18a,$114,$18e,$214,$182,$224
dc.w $18c,$323,$188,$323,$186,$334,$184,$434
dc.w $9007,$fffe
;35
dc.w $18a,$101,$18e,$211,$182,$222
dc.w $18c,$312,$188,$322,$186,$333,$184,$433
dc.w $9207,$fffe
;36
dc.w $18a,$101,$18e,$211,$182,$222
dc.w $18c,$312,$188,$312,$186,$323,$184,$423
dc.w $9407,$fffe
;37
dc.w $18a,$101,$18e,$211,$182,$222
dc.w $18c,$312,$188,$312,$186,$323,$184,$423
dc.w $9607,$fffe
;38
dc.w $18a,$101,$18e,$211,$182,$222
dc.w $18c,$322,$188,$312,$186,$323,$184,$433
dc.w $9807,$fffe
;39
dc.w $18a,$110,$18e,$210,$182,$221
dc.w $18c,$321,$188,$311,$186,$322,$184,$432
dc.w $9a07,$fffe
;40
dc.w $18a,$210,$18e,$310,$182,$321
dc.w $18c,$421,$188,$411,$186,$422,$184,$532
dc.w $9c07,$fffe
;41
dc.w $18a,$210,$18e,$320,$182,$331
dc.w $18c,$431,$188,$421,$186,$432,$184,$542
dc.w $9e07,$fffe
;42
dc.w $18a,$220,$18e,$330,$182,$431
dc.w $18c,$441,$188,$431,$186,$442,$184,$552
dc.w $a007,$fffe
;43
dc.w $18a,$220,$18e,$330,$182,$431
dc.w $18c,$440,$188,$430,$186,$441,$184,$551
dc.w $a207,$fffe
;44
dc.w $18a,$220,$18e,$330,$182,$431
dc.w $18c,$441,$188,$431,$186,$442,$184,$552
dc.w $a407,$fffe
;45
dc.w $18a,$120,$18e,$230,$182,$331
dc.w $18c,$341,$188,$331,$186,$342,$184,$452
dc.w $a607,$fffe
;46
dc.w $18a,$120,$18e,$230,$182,$341
dc.w $18c,$351,$188,$341,$186,$352,$184,$462
dc.w $a807,$fffe
;47
dc.w $18a,$121,$18e,$231,$182,$332
dc.w $18c,$342,$188,$332,$186,$343,$184,$453
dc.w $aa07,$fffe
;48
dc.w $18a,$021,$18e,$131,$182,$232
dc.w $18c,$242,$188,$232,$186,$243,$184,$353
dc.w $ac07,$fffe
;49
dc.w $18a,$022,$18e,$132,$182,$233
dc.w $18c,$243,$188,$233,$186,$244,$184,$354
dc.w $ae07,$fffe
;50
dc.w $18a,$012,$18e,$122,$182,$223
dc.w $18c,$233,$188,$223,$186,$234,$184,$344
dc.w $b007,$fffe
;51
dc.w $18a,$013,$18e,$123,$182,$224
dc.w $18c,$234,$188,$224,$186,$235,$184,$345
dc.w $b207,$fffe
;52
dc.w $18a,$013,$18e,$023,$182,$124
dc.w $18c,$134,$188,$124,$186,$135,$184,$245
dc.w $b407,$fffe
;53
dc.w $18a,$013,$18e,$123,$182,$224
dc.w $18c,$234,$188,$224,$186,$235,$184,$345
dc.w $b607,$fffe
;54
dc.w $18a,$012,$18e,$122,$182,$223
dc.w $18c,$233,$188,$223,$186,$234,$184,$344
