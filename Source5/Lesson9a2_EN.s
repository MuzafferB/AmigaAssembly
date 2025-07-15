
; Lesson 9a2.s - COPY OF $10 words using BLITTER

SECTION Blit,CODE

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea    GfxName,a1	; Address of the name of the lib to open in a1
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,a6        ; use a graphics library routine:
jsr    -$1c8(a6)    ; OwnBlitter, which gives us exclusive access to the blitter
; preventing its use by the operating system.
btst    #6,$dff002    ; wait for the blitter to finish (empty test)
; for the Agnus BUG
waitblit:
btst    #6,$dff002    ; blitter free?
bne.s    waitblit

; Here's how to make a copy

;     __&__
;     / \
;     | |
;     | (o)(o)
;     c .---_)
;     | |.___|
;     | \__/
;     /_____\
;     /_____/ \
;    / \

move.w    #$09f0,$dff040     ; BLTCON0: activate channels A and D
; MINTERMS (i.e. bits 0-7) take the
; value $f0. This defines
; the copy operation from A to D

move.w    #$0000,$dff042     ; BLTCON1: this register will be explained later
move.l    #SORG,$dff050     ; BLTAPT: Address of the source channel
move.l    #DEST,$dff054     ; BLTDPT: Address of the destination channel
move.w    #$0000,$dff064     ; BLTAMOD: we will explain this register later
move.w    #$0000,$dff066     ; BLTDMOD: this register will be explained later
move.w    #(1*64)+$10,$dff058 ; BLTSIZE: defines the dimensions of the
; rectangle. In this case, we have
; a width of $10 words and a height of 1 line.
; Since the height of the rectangle must be
; written in bits 6-15 of BLTSIZE
; we must shift it to the left by 6 bits.
; This is equivalent to multiplying its value
; by 64. The width is expressed in
; the lower 6 bits and therefore is not 
; modified.
; Furthermore, this instruction starts
; the blitter

btst    #6,$dff002    ; wait for the blitter to finish (empty test)
waitblit2:
btst    #6,$dff002    ; blitter free?
bne.s    waitblit2

jsr    -$1ce(a6)    ; DisOwnBlitter, the operating system can now
; use the blitter
move.l    a6,a1        ; Base of the graphics library to be closed
move.l    4.w,a6
jsr    -$19e(a6)    ; Closelibrary - close the graphics library
jsr    -$7e(a6)    ; Enable - riabilita il Multitasking
rts

GfxName:
dc.b	‘graphics.library’,0,0

******************************************************************************

SECTION THE_DATA,DATA_C

; note that the data we copy must be in CHIP memory
; in fact, the Blitter only operates in CHIP memory

; this is the source

SORG:
dc.w	$1111,$2222,$3333,$4444,$5555,$6666,$7777,$aaaa
dc.w	$8888,$2222,$3333,$4444,$5555,$6666,$7777,$ffff
THEEND1:
dc.b    “Here ends the source”
even

; this is the destination

DEST:
dcb.w    $10,$0000
THEEND2:
dc.b    “Here ends the destination”

even

end

This example shows a SIMPLE copy with the blitter.
Assemble without jumping, check with the ASMONE command ‘M SORG’
that starting from the SORG address there are $10 words in memory that take on
various values. This is the source of the copy, i.e. the area from which
we will read the data. 
Similarly, with the command ‘M DEST’, check that 
there are $10 words reset to zero starting from the DEST address.

At this point, run the example.
Now, again with the ASMONE command ‘M’, go and see what has happened
in memory: the data at the SORG address has remained the same as before.
This is normal because the blitter has simply read that data without
modifying it. The words starting from the DEST address, on the other hand, are no longer
zeroed, but have taken on the same values as the source data.

The copy operation requires the use of one channel for reading and one for
writing. In this case, we use A for reading and D (obviously) for writing.
To copy from channel A to channel D, you need to set the MINTERMS to the value
$f0. Therefore, the value to be loaded into the BLTCON0 register is $09f0.

Note that we could have performed the copy using another channel (B or C)
for reading. You can try this yourself as an exercise. The changes
to be made are very simple:

- Enable the channel you want to use instead of channel A (bits 8-11 of
BLTCON0)

- Change the value of MINTERMS (bits 0-7 of BLTCON0) to indicate a copy
from the channel you want to use to channel D.
To copy from channel B to D, the correct value is $CC, while to copy
from C to D, it is $AA.

- Write the starting address of the data to be copied instead of in the pointer
to channel A (BLTAPT) in the pointer to the channel you want to use. The addresses
of the BLTBPT and BLTCPT registers are shown in the lesson.

