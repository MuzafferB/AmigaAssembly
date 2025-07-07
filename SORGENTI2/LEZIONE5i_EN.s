
; Lesson 5i.s    MOVING A FIGURE UP AND DOWN THE ENTIRE CHIP
;        MEMORY USING POINTERS TO PITPLANES IN THE COPPERLIST
;        LEFT KEY TO MOVE FORWARD, RIGHT KEY TO MOVE
;        BACK, BOTH TO EXIT.

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea    GfxName(PC),a1	; Address of the name of the lib to open in a1
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase    ; save the GFX base address in GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the address of the old copperlist

;    Note: here we leave the bitplanes pointing to $000000, i.e.
;    at the beginning of the CHIP MEMORY

move.l    #COPPERLIST,$dff080    ; Point to our COP
move.w    d0,$dff088        ; Start the COP

move.w    #0,$dff1fc        ; Disable AGA
move.w    #$c00,$dff106        ; Disable AGA

mouse:
cmpi.b    #$ff,$dff006    ; Are we at line 255?
bne.s    mouse        ; If not, don't continue
Wait:
cmpi.b    #$ff,$dff006    ; Are we at line 255?
beq.s    Wait        ; If yes, don't continue, wait!

btst    #2,$dff016    ; if the right button is pressed
bne.s    NonGiu        ; scroll down!, or go to NonGiu

bsr.s    GoDown        ; right button pressed, scroll down!

Nongiu:
btst    #6,$bfe001    ; left mouse button pressed?
beq.s    ScrollUp    ; if yes, scroll up
bra.s    mouse        ; no? then repeat the cycle in the next FRAME

ScrollUp:
bsr.w    GoUp        ; scroll the figure up

btst    #2,$dff016    ; if the right button is also pressed, then
bne.s    mouse        ; both are pressed, exit, or ‘MOUSE’

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

GfxBase:        ; This is where the base address for the Offsets goes
dc.l    0    ; of the graphics.library

OldCop:            ; This is where the address of the old system COP goes
dc.l    0


;    This routine moves the figure up and down, acting on the
;    pointers to the bitplanes in copperlist (via the label BPLPOINTERS)

VAIGIU:
LEA    BPLPOINTERS,A1    ; With these 4 instructions, we retrieve from
move.w    2(a1),d0    ; copperlist the address where
swap    d0        ; $dff0e0 is currently pointing and place it
move.w    6(a1),d0	; in d0 - the opposite of the routine that
sub.l    #80*3,d0    ; we subtract 80*3, i.e. 3 lines, causing
; the figure to scroll DOWN
bra.s    Finished


VAISU:
LEA    BPLPOINTERS,A1    ; With these 4 instructions we retrieve from
move.w    2(a1),d0    ; copperlist the address where swap is pointing
swap    d0        ; currently $dff0e0 and we place it
move.w    6(a1),d0	; in d0 - the opposite of the routine that
add.l    #80*3,d0    ; We add 80*3, i.e. 3 lines, by
; scrolling UP the figure
bra.w    finished


Finished:                ; POINT THE BITPLANE POINTERS
move.w    d0,6(a1)    ; copy the LOWER word of the plane address
swap    d0        ; swap the 2 words of d0 (e.g.: 1234 > 3412)
move.w    d0,2(a1)    ; copy the UPPER word of the plane address
rts


SECTION	GRAPHIC,DATA_C

COPPERLIST:
dc.w	$120,$0000,$122,$0000,$124,$0000,$126,$0000,$128,$0000 ; SPRITE
dc.w	$12a,$0000,$12c,$0000,$12e,$0000,$130,$0000,$132,$0000
dc.w	$134,$0000,$136,$0000,$138,$0000,$13a,$0000,$13c,$0000
dc.w	$13e,$0000

dc.w    $8e,$2c81    ; DiwStrt    (registers with normal values)
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$003c    ; DdfStart normal HIRES
dc.w    $94,$00d4    ; DdfStop normal HIRES
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210
dc.w    $100,%1001001000000000    ; bits 12/15 on!! 1 bitplane
; hires 640x256, non lace
BPLPOINTERS:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane

dc.w    $0180,$000    ; colour0
dc.w    $0182,$2ae    ; colour1

dc.w    $FFFF,$FFFE    ; End of copperlist

end

With this little program you can see the contents of your CHIP RAM.
In fact, 1 bitplane is displayed in high resolution, pointing to address $00000
, i.e. the beginning of the Amiga's CHIP RAM. By pressing the left button of the
mouse, you can increase the address displayed, scrolling through the entire memory,
where you will notice the Wordbench screen, the ASMONE screen, as well as any
images remaining in memory. For example, if you played a game before
running this listing, you will probably find the backgrounds and characters of the
game still in memory, as the memory is not cleared when the computer is reset, but
only when it is turned off. With the right mouse button, you can move backwards to
centre an image that interests you; to exit, press both
buttons. Try experimenting by loading various video games, resetting
and running this little program to find what is left in memory
.
If you want to speed up the scrolling, you need to increase the value added to the
bitplanes, as long as it is a multiple of 80 (in fact, to scroll one line
in HIRES, being 640 bits wide per line instead of 320, you need double
40, which we have used so far for LOWRES screens).
In the listing, the screen scrolls 3 lines at a time:

sub.l    #80*3,d0    ; subtract 80*3, i.e. 3 lines

To make it scroll with TURBO, try 80*10 or higher.
If, out of curiosity, you want to know the address of a bitplane you see
on the screen, exit at that point and type ‘M BPLPOINTERS’:

XXXXXX 00 E0 00 02 00 E2 10 C0 ... (00 e0 = bplpointerH, 00 e2 the other BPLP)

i.e. $00E0,$0002,$00E2,$10C0 ......

In this example, the address is $0002 10c0, i.e. $210c0
