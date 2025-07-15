
; Lesson 4b.s    DISPLAYING A FIGURE IN 320*256 on 3 planes (8 colours)

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea    GfxName(PC),a1    ; Address of the lib name to open in a1
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
; pointers to the COPPERLIST planes in a1
MOVEQ    #2,D1        ; number of bitplanes -1 (here there are 3)
; to execute the cycle with DBRA
POINTBP:
move.w    d0,6(a1)    ; copy the LOWER word of the plane address
; to the correct word in the copperlist
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
; putting the HIGH word in place of the
; LOW one, allowing it to be copied with move.w!!
move.w    d0,2(a1)    ; copy the HIGH word of the plane address
; to the correct word in the copperlist
swap    d0        ; swap the 2 words of d0 (e.g.: 3412 > 1234)
; putting the address back in place.
ADD.L    #40*256,d0    ; Add 10240 to D0, making it point
; to the second bitplane (located after the first)
; (i.e. add the length of a plane)
; In the cycles following the first, we will point
; to the third, fourth bitplane, and so on.

addq.w    #8,a1        ; a1 now contains the address of the next
; bplpointers in the copperlist to be written.
dbra    d1,POINTBP    ; Repeat D1 times POINTBP (D1=num of bitplanes)

;

move.l    #COPPERLIST,$dff080	; Point to our COP
move.w    d0,$dff088        ; Start the COP

move.w    #0,$dff1fc        ; FMODE - Disable AGA
move.w    #$c00,$dff106        ; BPLCON3 - Disable AGA

mouse:
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse        ; if not, return to mouse:

move.l    OldCop(PC),$dff080    ; Point to the system COP
move.w    d0,$dff088        ; start the old COP

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

SECTION    GRAPHIC,DATA_C

COPPERLIST:

; Let's point the sprites to ZERO to eliminate them, or we'll find them
; scattered around causing trouble!!!

dc.w	$120,$0000,$122,$0000,$124,$0000,$126,$0000,$128,$0000
dc.w	$12a,$0000,$12c,$0000,$12e,$0000,$130,$0000,$132,$0000
dc.w	$134,$0000,$136,$0000,$138,$0000,$13a,$0000,$13c,$0000
dc.w	$13e,$0000

dc.w	$8e,$2c81	; DiwStrt	(registers with normal values)
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0    ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0		; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; BPLCON0 ($dff100) For a 3-bitplane screen: (8 colours)

; 5432109876543210
dc.w    $100,%0011001000000000    ; bits 13 and 12 on!! (3 = %011)

;    Let's point the bitplanes directly by putting the registers $dff0e0 and following in the copperlist
;    with the addresses
;    of the bitplanes that will be set by the POINTBP routine

BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane - BPL0PT
dc.w $e4,$0000,$e6,$0000    ;second bitplane - BPL1PT
dc.w $e8,$0000,$ea,$0000    ;third     bitplane - BPL2PT

;    The 8 colours of the figure are defined here:

dc.w    $0180,$000    ; colour0
dc.w    $0182,$475	; colour1
dc.w    $0184,$fff    ; colour2
dc.w    $0186,$ccc    ; colour3
dc.w    $0188,$999    ; colour4
dc.w    $018a,$232    ; colour5
dc.w    $018c,$777    ; colour6
dc.w    $018e,$444    ; colour7

;    Insert any effects with WAIT here

dc.w    $FFFF,$FFFE    ; End of copperlist


;    Remember to select the directory where the image is located
;    in this case, just write: ‘V df0:SOURCES2’


PIC:
incbin    ‘amiga.320*256*3’    ; here we load the image in RAW,
; converted with KEFCON, made up of
; 3 consecutive bitplanes

end

As you can see, there are no synchronised routines in this example, only
routines that point to the bitplanes and the copperlist.
First, try deleting the sprite pointers with ;:

;    dc.w    $120,$0000,$122,$0000,$124,$0000,$126,$0000,$128,$0000
;	dc.w	$12a,$0000,$12c,$0000,$12e,$0000,$130,$0000,$132,$0000
;	dc.w	$134,$0000,$136,$0000,$138,$0000,$13a,$0000,$13c,$0000
;	dc.w	$13e,$0000

You will notice that sometimes they appear as STRIPES; these are sprites
running wild. We will learn how to tame them later.

Now try adding some WAIT commands before the end of the copperlist,
and you will see how useful WAIT+COLOR commands are for ADDING HORIZONTAL GRADIENTS
or CHANGE COLOURS completely FREE, i.e., with an 8-colour figure like
this, we can work with MOVE+WAIT, creating a background with a hundred
colours and blending them, or even changing the ‘overlay’ colours,
i.e. $182, $184, $186, $188, $18a, $18c, $18e.

As a first “embellishment”, copy and insert this prefabricated piece of
shading between the colours and the end of the copperlist: (dc.w $FFFF,$FFFE)
REMEMBER TO SELECT THE BLOCK WITH Amiga+b, Amiga+c, then
place the cursor where you want to copy the text, and insert it with Amiga+i.


dc.w    $a907,$FFFE    ; Wait for line $a9
dc.w    $180,$001    ; very dark blue
dc.w    $aa07,$FFFE    ; line $aa
dc.w    $180,$002    ; slightly more intense blue
dc.w    $ab07,$FFFE	; line $ab
dc.w    $180,$003    ; lighter blue
dc.w    $ac07,$FFFE    ; next line
dc.w    $180,$004    ; lighter blue
dc.w    $ad07,$FFFE    ; next line
dc.w    $180,$005	; lighter blue
dc.w    $ae07,$FFFE    ; next line
dc.w    $180,$006    ; blue at 6
dc.w    $b007,$FFFE    ; skip 2 lines
dc.w    $180,$007    ; blue at 7
dc.w    $b207,$FFFE    ; skip 2 lines
dc.w    $180,$008    ; blue at 8
dc.w    $b507,$FFFE    ; skip 3 lines
dc.w    $180,$009    ; blue at 9
dc.w    $b807,$FFFE    ; jump 3 lines
dc.w    $180,$00a    ; blue at 10
dc.w    $bb07,$FFFE    ; jump 3 lines
dc.w    $180,$00b    ; blue at 11
dc.w    $be07,$FFFE    ; jump 3 lines
dc.w    $180,$00c    ; blue at 12
dc.w    $c207,$FFFE    ; jump 4 lines
dc.w    $180,$00d    ; blue at 13
dc.w    $c707,$FFFE    ; jump 7 lines
dc.w    $180,$00e    ; blue at 14
dc.w    $ce07,$FFFE	; jump 6 lines
dc.w    $180,$00f    ; blue at 15
dc.w    $d807,$FFFE    ; jump 10 lines
dc.w    $180,$11F    ; lighten...
dc.w    $e807,$FFFE    ; jump 16 lines
dc.w    $180,$22F    ; lighten...
dc.w    $ffdf,$FFFE    ; END OF NTSC AREA (line $FF)
dc.w    $180,$33F    ; lighten...
dc.w    $2007,$FFFE    ; line $20+$FF = line $1ff (287)
dc.w    $180,$44F    ; lighten...

We have created a shade from scratch, without any counterproductive effects,
 bringing the actual colours on the screen from 8 to 27!!!!
Let's add another 7 colours, this time changing not the background colour,
the $dff180, but the other 7 colours: insert this piece of copperlist between
the bitplane pointers and the colours: (leave the other change as it is)

dc.w    $0180,$000    ; colour0
dc.w    $0182,$550    ; colour1    ; let's redefine the colour of the
dc.w    $0184,$ff0    ; colour2    ; COMMODORE! YELLOW!
dc.w    $0186,$cc0    ; colour3
dc.w    $0188,$990    ; colour4
dc.w    $018a,$220    ; colour5
dc.w    $018c,$770    ; colour6
dc.w    $018e,$440    ; colour7

dc.w    $7007,$fffe    ; Wait for the end of the COMMODORE writing

With 45 ‘dc.w’ added to the copperlist, we have transformed an innocuous PIC with
only 8 colours into a 34-colour PIC, even exceeding the 32-colour limit
of 5-bitplane PICs!!!

Only by programming the copperlists in assembler can you get the most out of
Amiga graphics: now you could even make 320-colour images
simply by changing the entire palette of a 32-colour image
10 times, putting a wait+palette every 25 lines...
Now perhaps you will understand why certain games have 64, 128 or more colours
on the screen! They have very long copperlists where they change colour
at different heights on the screen!

Make a few changes, which are always good, and if you like, try
putting the examples with the bars from Lesson 3 in the “background”. Just
load them into other buffers and insert the right pieces of routine and copperlist.
 It's good practice. Try to make the bar walk “under”
the drawing. If you can do it, you're tough.

