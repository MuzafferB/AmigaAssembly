
; Lesson 5l.s    ‘EXTENSION’ effect achieved by alternating normal modules and -40

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea    GfxName(PC),a1    ; Address of the lib name to open in a1
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase    ; save the GFX base address in GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the address of the old copperlist

;    Point the bitplanes in copperlist

MOVE.L    #PIC,d0        ; put the PIC address in d0,
LEA    BPLPOINTERS,A1    ; pointers in COPPERLIST
MOVEQ    #2,D1        ; number of bitplanes -1 (here there are 3)
POINTBP:
move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the HIGH word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 3412 > 1234)
ADD.L    #40*256,d0    ; + bitplane length -> next bitplane
addq.w    #8,a1        ; go to the next bplpointers in the COP
dbra    d1,POINTBP    ; Repeat D1 times POINTBP (D1=number of bitplanes)

move.l    #COPPERLIST,$dff080    ; Point to our COP
move.w    d0,$dff088        ; Start the COP

move.w    #0,$dff1fc        ; Disable AGA
move.w    #$c00,$dff106        ; Disable AGA

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

GfxBase:        ; This is where the base address for the Offsets goes
dc.l    0    ; of the graphics.library

OldCop:            ; This is where the address of the old system COP goes
dc.l    0

SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$120,$0000,$122,$0000,$124,$0000,$126,$0000,$128,$0000 ; SPRITE
dc.w	$12a,$0000,$12c,$0000,$12e,$0000,$130,$0000,$132,$0000
dc.w	$134,$0000,$136,$0000,$138,$0000,$13a,$0000,$13c,$0000
dc.w	$13e,$0000

dc.w	$8e,$2c81	; DiwStrt	(registers with normal values)
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0    ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210
dc.w    $100,%0011001000000000    ; bits 13 and 12 on!! (3 = %011)

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

; COPPERLIST THAT ‘EXTEND’

dc.l    $8907fffe        ; wait line $89
dc.w    $108,-40,$10a,-40    ; module -40, repeat last line
dc.l    $9007fffe		; wait 7 lines - they will all be the same
dc.w    $108,0,$10a,0        ; then advance one line
dc.l    $9107fffe        ; and the following line...
dc.w    $108,-40,$10a,-40    ; I put the module back to FLOOD
dc.l    $9807fffe        ; wait for 7 lines - they will all be the same
dc.w    $108,0,$10a,0        ; I move forward to the next line
dc.l    $9907fffe		; then...
dc.w    $108,-40,$10a,-40    ; repeat the line 7 times with
dc.l    $a007fffe        ; module at -40
dc.w    $108,0,$10a,0        ; advance one line... ETC.
dc.l    $a107fffe
dc.w    $108,-40,$10a,-40
dc.l    $a807fffe
dc.w    $108,0,$10a,0
dc.l    $a907fffe
dc.w    $108,-40,$10a,-40
dc.l    $b007fffe
dc.w    $108,0,$10a,0
dc.l    $b107fffe
dc.w    $108,-40,$10a,-40
dc.l    $b807fffe
dc.w    $108,0,$10a,0
dc.l    $b907fffe
dc.w    $108,-40,$10a,-40
dc.l    $c007fffe
dc.w    $108,0,$10a,0
dc.l    $c107fffe
dc.w    $108,-40,$10a,-40
dc.l    $c807fffe
dc.w    $108,0,$10a,0
dc.l    $c907fffe
dc.w    $108,-40,$10a,-40
dc.l    $007fffe
dc.w    $108,0,$10a,0
dc.l    $107fffe
dc.w    $108,-40,$10a,-40
dc.l    $807fffe
dc.w    $108,0,$10a,0
dc.l    $907fffe
dc.w    $108,-40,$10a,-40
dc.l    $e007fffe
dc.w    $108,0,$10a,0
dc.l    $e107fffe
dc.w    $108,-40,$10a,-40
dc.l    $e807fffe
dc.w    $108,0,$10a,0
dc.l    $e907fffe
dc.w    $108,-40,$10a,-40
dc.l    $f007fffe
dc.w    $108,0,$10a,0    ; return to normal

dc.w    $FFFF,$FFFE    ; End of copperlist

PIC:
incbin    ‘amiga.320*256*3’    ; here we load the image in RAW,
; converted with KEFCON, made up of
; 3 consecutive bitplanes

end

This is one of the other uses of the ‘FLOOD’ effect made with modules.
In fact, it is quite easy to ‘stretch’ a figure or simulate longer pixels
longer than normal by alternating -40 modules, which lengthen, with modules
normally set to zero, which trigger the next line, which will then be
lengthened by following it with another -40 module maintained for a few lines.
In this example, the lengthening is by a factor of 8, as the line is only advanced once every 8 pixels.
The -40 modules are spaced
with a wait of 7 lines, and between these lengthenings there are lines with
normal modules, which therefore trigger the next line once the
display is finished, but the following line immediately has another negative module
which repeats the new line for 7 lines, plus the one with the normal module which
triggers the new line again when it goes “to the next line”.
By changing the distance between the waits, you can create interesting
“zoom” style wave effects.
