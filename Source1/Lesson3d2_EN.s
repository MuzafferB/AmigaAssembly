
; Lesson3d2.s    BAR THAT GOES UP AND DOWN MADE WITH COPPER'S MOVE&WAIT


;    Routine executed once every 3 frames


SECTION    CiriCop,CODE    ; also works in Fast

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea    GfxName(PC),a1    ; Address of the name of the lib to open in a1
jsr    -$198(a6)    ; OpenLibrary, EXEC routine that opens
; the libraries and outputs the
; base address of the library from which to calculate
; the addressing distances (Offset)
move.l    d0,GfxBase    ; save the GFX base address in GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the address of the system copperlist
;
move.l    #COPPERLIST,$dff080    ; COP1LC - Point to our COP
move.w    d0,$dff088		; COPJMP1 - Start the COP
mouse:
cmpi.b    #$ff,$dff006    ; Are we at line 255?
bne.s    mouse        ; If not, don't continue
frame:
cmpi.b    #$fe,$dff006    ; Are we at line 254? (must repeat the cycle!)
bne.s    frame        ; If not yet, do not continue
frame2:
cmpi.b    #$fd,$dff006    ; Are we at line 253? (must repeat the cycle!)
bne.s    frame2        ; If not yet, do not continue

bsr.s    MoveCopper    ; A routine that moves the bar up and down


btst    #6,$bfe001    ; Left mouse button pressed?
bne.s    mouse        ; If not, go back to mouse:

move.l    OldCop(PC),$dff080    ; COP1LC - Point to the system cop
move.w    d0,$dff088        ; COPJMP1 - start the cop

move.l    4.w,a6
jsr    -$7e(a6)    ; Enable - re-enable Multitasking
move.l    gfxbase(PC),a1    ; Base of the library to close
; (libraries must be opened and closed!!!)
jsr    -$19e(a6)    ; Closelibrary - close the graphics library
rts

;    MoveCopper routine modified in style with the ‘ZOOM’ already seen

MoveCopper:
LEA    BARRA,a0
TST.B	SuGiu        ; Do we need to go up or down? If SuGiu is
; reset (i.e. TST checks BEQ)
; then jump to VAIGIU, otherwise if it is at $FF
; (i.e. this TST is not checked)
; continue going up (doing subq)
beq.w    VAIGIU
cmpi.b    #$82,8*9(a0)    ; have we reached line $82?
beq.s    MettiGiu    ; if so, we are at the top and must go down
;    subq.b    #1,(a0)
subq.b    #1,8(a0)    ; now let's change the other waits: the distance
subq.b	#2,8*2(a0)    ; between one wait and the next is 8 bytes
subq.b    #3,8*3(a0)
subq.b    #4,8*4(a0)
subq.b    #5,8*5(a0)
subq.b    #6,8*6(a0)
subq.b    #7,8*7(a0)    ; here we have to modify all 9 waits of the
subq.b    #8,8*8(a0)    ; red bar each time to make it go up!
subq.b    #8,8*9(a0)
rts

MettiGiu:
clr.b    SuGiu        ; By resetting SuGiu, at TST.B SuGiu the BEQ
rts            ; will jump to the VAIGIU routine, and
; the bar will drop

VAIGIU:
cmpi.b    #$fa,8*9(a0)    ; have we reached line $fc?
beq.s	MettiSu        ; if so, we are at the bottom and we have to go back up
;    addq.b    #1,(a0)
addq.b    #1,8(a0)    ; now we change the other waits: the distance
addq.b    #2,8*2(a0)    ; between one wait and another is 8 bytes
addq.b    #3,8*3(a0)
addq.b    #4,8*4(a0)
addq.b    #5,8*5(a0)
addq.b    #6,8*6(a0)
addq.b    #7,8*7(a0)    ; here we have to modify all 9 waits of the
addq.b    #8,8*8(a0)	; red bar each time to make it go down!
addq.b    #8,8*9(a0)
rts

PutUp:
move.b    #$ff,UpDown    ; When the UpDown label is not zero,
rts            ; it means we have to go back up.

SuGiu:
dc.b    0,0

GfxName:
dc.b    ‘graphics.library’,0,0

GfxBase:        ; Here goes the base address for the Offsets
dc.l    0    ; of the graphics.library

OldCop:            ; Here goes the address of the old system COP
dc.l    0

SECTION    GRAPHIC,DATA_C    ; This command loads this segment of data from the operating system
; into CHIP RAM, which is mandatory
; The copperlists MUST be in CHIP RAM!
;
COPPERLIST:
dc.w    $100,$200    ; BPLCON0
dc.w    $180,$000    ;
COLOR0 - Start the cop with the colour BLACK 
COLOR0 - Start the copy with the colour BLACK
dc.w    $4907,$FFFE    ; WAIT - Wait for line $49 (73)
dc.w    $180,$001    ; COLOR0 - very dark blue
dc.w    $4a07,$FFFE	; WAIT - line 74 ($4a)
dc.w    $180,$002    ; slightly more intense blue
dc.w    $4b07,$FFFE    ; line 75 ($4b)
dc.w    $180,$003	; lighter blue
dc.w    $4c07,$FFFE    ; next line
dc.w    $180,$004    ; lighter blue
dc.w    $4d07,$FFFE    ; next line
dc.w    $180,$005    ; lighter blue
dc.w    $4e07,$FFFE	; next line
dc.w    $180,$006    ; blue at 6
dc.w    $5007,$FFFE    ; jump 2 lines: from $4e to $50, i.e. from 78 to 80
dc.w    $180,$007    ; blue at 7
dc.w    $5207,$FFFE	; 2 lines
dc.w    $180,$008    ; blue at 8
dc.w    $5507,$FFFE    ; jump 3 lines
dc.w    $180,$009    ; blue at 9
dc.w    $5807,$FFFE    ; jump 3 lines
dc.w    $180,$00a    ; blue at 10
dc.w    $5b07,$FFFE    ; jump 3 lines
dc.w    $180,$00b    ; blue at 11
dc.w    $5e07,$FFFE    ; jump 3 lines
dc.w    $180,$00c    ; blue at 12
dc.w    $6207,$FFFE    ; jump 4 lines
dc.w    $180,$00d    ; blue at 13
dc.w    $6707,$FFFE    ; jump 5 lines
dc.w    $180,$00e    ; blue at 14
dc.w    $6d07,$FFFE    ; jump 6 lines
dc.w    $180,$00f    ; blue at 15
dc.w    $780f,$FFFE    ; line $78
dc.w    $180,$000    ; colour BLACK

BAR:
dc.w    $7907,$FFFE    ; wait for line $79
dc.w    $180,$300    ; start red bar: red at 3
dc.w    $7a07,$FFFE    ; next line
dc.w    $180,$600    ; red at 6
dc.w    $7b07,$FFFE
dc.w    $180,$900    ; red at 9
dc.w    $7c07,$FFFE
dc.w    $180,$c00    ; red at 12
dc.w    $7d07,$FFFE
dc.w    $180,$f00    ; red at 15 (maximum)
dc.w    $7e07,$FFFE
dc.w    $180,$c00    ; red at 12
dc.w    $7f07,$FFFE
dc.w    $180,$900    ; red at 9
dc.w    $8007,$FFFE
dc.w    $180,$600	; red at 6
dc.w    $8107,$FFFE
dc.w    $180,$300    ; red at 3
dc.w    $8207,$FFFE
dc.w    $180,$000    ; colour BLACK

dc.w    $fd07,$FFFE    ; wait for line $FD
dc.w    $180,$00a    ; blue intensity 10
dc.w    $fe07,$FFFE	; following line
dc.w    $180,$00f    ; blue maximum intensity (15)
dc.w    $FFFF,$FFFE    ; END OF COPPERLIST


end

In this example, the Muovicopper routine is executed once every 3 FRAMES,
i.e. once every 3 fiftieths of a second, to slow down the excessive
speed, using the trick of various cmp with $dff006.
On the other hand, the fact that it is executed every 3 frames also makes it less
smooth, as can be seen from the jerks it makes in the lower part.

Now is the time to teach you a few tricks of the trade.
If you need to make changes to long COPPERLISTs, for example
you need to change all 07s to 87s, to make half of each
line wait instead of the beginning, you can use the REPLACE command in the editor,
which allows you to change a given string of characters with another.
To make the change I mentioned, you need to position the cursor at the beginning
of the COPPERLIST, then press the ‘AMIGA+SHIFT+R’ keys together, and
the words ‘Search For:’ will appear. Here you must write the original text
to search for, in this case write ‘07,$fffe’ and press return.
Now the message ‘Replace with:’ will appear. Here you must enter the change you
want to make: i.e. ‘87,$fffe’. At this point, the cursor will move to the
first 07,$fffe and the message ‘Replace: (Y/N/L/G)’ will appear. At this point
you must decide whether or not to swap the 07 with the 87. If you want to change it,
press Y, if you don't want to change it, press N. Once you have made your choice, the
cursor will move to the next 07,$fffe and repeat the question. Change
them all until you reach the end of the copperlist, then press ESC to
avoid changing those in the comment below. If you press G when prompted
, all 07,$fffe will be swapped until the end of the text. Think carefully
before using G (GLOBAL), as you may change something that should not
be changed. It is better to proceed by pressing Y or N until the end of the area to be
changed, then press ESC to finish, or press L at the last
change to be made (indicates LOCAL, i.e. LAST CHANGE TO BE MADE).

Once you have made this change, run the listing: you will notice that the bar
and the other ‘shades’ are staggered towards the centre. This is
precisely because we change colour in the middle ($87) instead of at the beginning of the video.

Now try to change everything back: do REPLACE, giving as the original string
‘87,$ff’ and as the new string ‘$67,$ff’. You will notice that the scaling is more
to the right. To finish, do another effect: now you have all the waits changed
to $xx67,$fffe, so try changing them to $xx69,$fffe, but one yes and one
no, i.e., enter ‘67,$ff’ as the first string in the replace question and
‘69,$ff’ as the second, then press Y once, then N, then
Y again, and so on, one Y and one N.
This way, one colour will change at line $67 and the other at $69,
creating an effect similar to interlocking bricks. Try it out.

The interlocking will look something like this:

ooooooo+++++
oooo++++++++
oooooo++++++
oooo++++++++
oooooo++++++

