
; Lesson 9a1.s - RESETTING $10 words using the BLITTER
; Before looking at this example, take a look at LESSON 2f.s where
; memory is cleared with the 68000

SECTION Blit,CODE

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea    GfxName,a1    ; Address of the lib name to open in a1
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,a6        ; uses a graphics library routine:

jsr    -$1c8(a6)    ; OwnBlitter, which gives us exclusive access to the blitter
; preventing its use by the operating system.

; Before using the blitter, we must wait
; for it to finish any blitting in progress.
; The following instructions take care of this

btst    #6,$dff002    ; wait for the blitter to finish (empty test)
; for the Agnus BUG
waitblit:
btst    #6,$dff002    ; blitter free?
bne.s    waitblit

; Here's how to do a blit!!! Only 5 instructions to reset!!!

;     __
;    __ /_/\ __
;    \/ \_\/ /\_\
;     __ __ \/_/ __
;    /\_\ /\_\ __ /\_\
;    \/_/ \/_/ /_/\ \/_/
;     __ \_\/
;     /\_\ __
;     \/_/ \/

move.w    #$0100,$dff040     ; BLTCON0: only DESTINATION activated
; the MINTERMS (i.e. bits 0-7) are all
; reset. This defines
; the delete operation

move.w    #$0000,$dff042     ; BLTCON1: this register will be explained later
move.l	#START,$dff054     ; BLTDPT: Address of the destination channel
move.w    #$0000,$dff066     ; BLTDMOD: we will explain this register later
move.w    #(1*64)+$10,$dff058 ; BLTSIZE: defines the dimensions of the
; rectangle. In this case, we have
; a width of $10 words and a height of 1 line.
; Since the height of the rectangle must be
; written in bits 6-15 of BLTSIZE
; we must shift it to the left by 6 bits.
; This is equivalent to multiplying its value
; by 64. The width is expressed in
; 6 low bits and therefore is not 
; modified.
; Furthermore, this instruction starts
; the blitter

btst    #6,$dff002    ; wait for the blitter to finish (empty test)
waitblit2:
btst    #6,$dff002    ; blitter free?
bne.s    waitblit2

jsr    -$1ce(a6)    ; DisOwnBlitter, the operating system can now
; use the blitter again
move.l    a6,a1        ; Base of the graphics library to be closed
move.l    4.w,a6
jsr    -$19e(a6)    ; Closelibrary - close the graphics library
jsr    -$7e(a6)	; Enable - riabilita il Multitasking
rts

******************************************************************************

SECTION THE_DATA,DATA_C

; note that the data we delete must be in CHIP memory
; in fact, the Blitter only operates in CHIP memory

START:
dcb.b    $20,$fe
THEEND:
dc.b    “We do not delete here”

even

GfxName:
dc.b    ‘graphics.library’,0,0

end

This example is the blitter version of the Lesson2f.s listing, in which
bytes were cleared using a loop of ‘clr.l (a0)+’.

As in that case, assemble without jumping and check with ‘M START’
to check that $20 bytes ‘$fe’ are assembled under that label. At this point, run
the listing, activating the blitter for the first time in the course, then
repeat ‘M START’ and check that those bytes have been cleared up to the
THEEND label. In fact, with a ‘N THEEND’ you will find the text still in its
place.

The deletion operation requires the use of channel D only.
It is also necessary to reset all MINTERMS. Therefore, the value to be loaded
into the BLTCON0 register is $0100.
Please note the value written in the BLTSIZE register. We need to
delete a rectangle $10 words wide and one line high. We need to write
the width in bits 0-5 of BLTSIZE and the height in bits 6-15, also of BLTSIZE.
To write the height in bits 6-15, we can shift it to the left by
6 bits, which is equivalent to multiplying it by 64. Therefore, to write the
dimensions of the rectangle to be blitted in the BLTSIZE register, we use the following
formula:

Value to be written in BLTSIZE = (HEIGHT*64)+WIDTH

Remember that WIDTH is expressed in words.

NOTE: We have used an operating system function that we have not
discussed before, which prevents the operating system from using the blitter
to avoid using the blitter when Workbench is also using it.
To disable and re-enable the use of the blitter by the operating system, simply
run the appropriate routines already available in the kickstart, more specifically
in the graphics.library: with GFXBASE in A6, simply run a

jsr    -$1c8(a6)    ; OwnBlitter, which gives us exclusive access to the blitter

To ensure that we are the only ones looking for the blitter, while a

jsr    -$1ce(a6)    ; DisOwnBlitter, the operating system can now
; use the blitter again

will be necessary before exiting the programme to reactivate the workbench.

So just remember that when we use the blitter in our masterpieces,
we need to add OwnBlitter at the beginning and DisownBlitter at the end,
in addition to the well-known Disable and Enable.

