
; Lesson9i5.s    Bob's clipping on the right. (By Erra Ugo)
;        Left key to exit.

section    CLippaD,code

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘Startup1.s’ ; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper,bitplane,blitter DMA


; Let's define the constants related to our bob in these equ...

XBob    equ    16*8    ; X dimension of the bob
YBob    equ    29    ; Y dimension of the bob
XWord    equ    8    ; Number of words in the bob

; Let's define the screen limits

XMax    =    320-64        ; Right horizontal limit of the screen
XMin    =    0        ; Left horizontal limit of the screen
YMax    =    200-YBob    ; Lower vertical limit of the screen
YMin    =    0        ; Upper vertical limit of the screen


Start:
Lea    Screen,a0        ; prepare the pointer
Move.l    a0,d0            ; to the bitplane.
Move.w    d0,BPLPointer1+6
Swap    d0
Move.w    d0,BPLPointer1+2

Lea    $dff000,a6        ; CUSTOM REGISTER in a5
Move.w    #DMASET,$96(a6)        ; DMACON - enable bitplane, copper
Move.l    #CopperList,$80(a6)    ; Point to our COP
Move.w    d0,$88(a6)        ; Start the COP
Move.w    #0,$1fc(a6)        ; Disable AGA
Move.w    #$c00,$106(a6)        ; Disable AGA
Move.w    #$11,$10c(a6)        ; Disable AGA

Moveq    #100,d0        ; d0 is the x coordinate
Move.w    #100,d1		; d1 is the y coordinate
Moveq    #0,d2        ; reset the rest of the data registers
Moveq    #0,d3        ; blah blah blah
Moveq    #0,d4        ; blah blah
Moveq    #0,d5        ; blah
Moveq    #0,d6
Moveq    #0,d7

Loop
Cmpi.b    #$ff,$6(a6)
Bne.s    Loop

Bsr.w    ReadJoystick    ; The routine reads the joystick status
; and updates x and y directly in registers
; d0 and d1.
Bsr.w    CheckLimit    ; Checks if the routine is within limits
Bsr.w    ClearScreen    ; clears the screen
Bsr.s    ClipBobRight    ; clips the bob and places it on the screen
Btst    #6,$bfe001    ; Waits for the left button to be pressed
Bne.s    Loop        ; ...
Rts

; ****************************************************************************
; The decryption technique is implemented as follows:
; 1) If the top right coordinate is outside the maximum limit, then
; do not blit anything.
; 2) Calculate how many pixels the bob has gone outside, as follows
; Xout=(x+xdim)-XMax
; 3) Then calculate exactly how many words the bob has gone outside and 
; how many pixels, as follows XOut/16 and XOut mod 16.
; 4) At this point, from the maskright table, we take the value
; of the BLTLWM register using the value XOut mod 16
; 5) Prepare module A of the blitter using the operation (XBob-XOut)/16
; ****************************************************************************

;     . . . .
;     :¦:¦:¦:¦:¦ 
;     ¦ ____l___
;     |__ '______/
 
;     _!\____,---.|
;    .---/___ (¯°) °_||----.
;    | \ \/\ ¯¯¯¯T l_ |
;    | _ \ \/\___,_)__ \ |
;    | | \ \/ /| | l/ / |
;	| | \ \/¯T¯T¯/ /T |
;    | | \_¯¯¯¯¯¯_/ | |
;    | | `------' | |
;    | l_______/¯¯)¯¯\_| |
;    l_______l__ _(_ (___|
;    .. . . \___)___/ xCz

ClipBobRight:
Movem.l    d0-d7/a0,-(a7)
Cmpi.w    #XMax,d0    ; Compare the top left coordinate
; with XMax
Bge.w    ExitClipRight    ; if it is greater then the bob is completely
; out, and therefore we do nothing

Move.w	#XBob,d7    ; d7=Size of the bob
Add.w    d0,d7        ; Add the x coordinate to d7, so d7 is
; equal to the top right coordinate. 
Subi.w    #XMax,d7    ; Calculate how many pixels the bob has gone out
Ble.w    IsInLeft    ; If the result is less than zero, then
; the bob has completely moved out.

Move.w    d7,d6        ; d7=d6=number of pixels out
Lsr.w    #4,d6        ; d6=d6/16 number of words out
Move.w    #XWord,d2    ; d2=number of words of the bob originally
Andi.w    #15,d7        ; d7=number of pixels out

; Now calculate the new value of bltsize
Move.w    d2,d5		; d5=number of words in the original bob
Sub.w    d6,d2        ; d2 number of words in
Move.w    #YBob,d3    ; Vertical size in d3
Lsl.w    #6,d3        ; Multiply d3 by 64
Add.w    d2,d3        ; d3=reduced bltsize

; Calculate the new destination module
Moveq    #40,d4        ; To calculate the new destination module
; we simply subtract
; the remaining size of the bob from 40.
Add.w    d5,d5        ; d5=d5*2 number of bytes of the original bob.
Add.w    d6,d6		; d6=d6*2 module of A in bytes
Sub.w    d6,d5        ; d5=number of bytes out
Sub.w    d5,d4        ; d4=module of D

Moveq    #-1,d5
Add.w    d7,d7        ; with d7 we retrieve the value of the mask
Lea	MaskRight,a0    ; in a0 the table index
Move.w    (a0,d7.w),d5    ; d5=maskera

Mulu    #40,d1        ; From here normal blitting...
Move.w    d0,d2
Lsr.w    #3,d0
Add.w    d0,d1
	
Lea    Screen,a0
Adda.l    d1,a0
Andi.w    #000f,d2
Ror.w    #4,d2        ; more efficient than doing LSL #4,d2 and
; then LSL #8,D2
Ori.w    #09f0,d2

Btst    #6,2(a6)
WaitBlit1b:
Btst    #6,2(a6)    ; dmaconr - wait for the blitter to be free
bne.s    WaitBlit1b

Move.w    d2,$40(a6)    ; bltcon0
Move.l    d5,$44(a6)    ; bltafwm
Move.l    #Bob,$50(a6)    ; bltapt
Move.l    a0,$54(a6)    ; bltdpt
Move.w    d6,$64(a6)	; bltamod
Move.w    d4,$66(a6)    ; bltdmod
Move.w    d3,$58(a6)    ; bltsize
Movem.l    (a7)+,d0-d7/a0
Rts

IsInLeft:
Mulu.w    #40,d1        ; In this case we use the blitter
Move.w    d0,d2        ; normally, since the bob is within
Lsr.w    #3,d0        ; the set limits.
Add.w    d0,d1    
Lea    Screen,a0
Add.l    d1,a0
Andi.w	#000f,d2
Ror.w    #4,d2
Ori.w    #09f0,d2

Moveq    #-1,d7
Clr.w    d7

Btst    #6,2(a6)
WaitBlit1a:
Btst    #6,2(a6)    ; dmaconr - wait for the blitter to be free
bne.s    WaitBlit1a

Move.w    d2,$40(a6)    ; bltcon0
Move.w    #0,$42(a6)    ; bltcon1
Move.l    d7,$44(a6)    ; bltafwm
Move.l    #Bob,$50(a6)    ; bltapt
Move.l    a0,$54(a6)    ; bltdpt
Move.w    #-2,$64(a6)    ; bltamod
Move.w    #40-18,$66(a6)	; bltdmod
Move.w	#(29*64)+(144/16),$58(a6)	; bltsize
ExitClipRight:
Movem.l	(a7)+,d0-d7/a0
Rts

; ****************************************************************************
; This routine checks that the bob does not go outside the physical limits of the
; screen. In fact, we have created a routine that cuts off the parts that
; go outside our right, but we have not done anything for
; the other limits of the screen. So this routine checks if the 
; coordinates are always in the right range.
; ****************************************************************************

CheckLimit:
Cmpi.w    #XMin,d0    ; Did it go off the left?
Bge.s    Limit2        ; no, then check above and below
Move.w    #XMin,d0    ; yes, then put it back within our limits
Limit2:
Cmpi.w    #YMin,d1	;Has it gone above?
Bge.s    Limit3        ;no, then see below
Move.w    #YMin,d1    ;yes, then put it back within the limits
Bra.s    End_Limit    ;and then exit because our bob cannot
;be above and below at the same time.
Limit3:
Cmpi.w    #YMax,d1    ; As above, but check the
Blt.s    End_Limit    ; vertical limit at the bottom.
Move.w    #YMax,d1
End_Limit
Rts



; ****************************************************************************
; This routine reads the joystick and updates the values contained in
; the sprite_x and sprite_y variables
; ****************************************************************************

LeggiJoyst:
Move.w    $dff00c,D3    ; JOY1DAT
Btst.l    #1,D3        ; bit 1 tells us if we are going right
Beq.s    NODESTRA    ; if it is zero, we do not go right
Addq.w    #1,d0        ; if it is 1, move the sprite one pixel
Bra.s    CHECK_Y        ; go to Y control
NODESTRA:
Btst    #9,D3        ; bit 9 tells us if we go left
Beq.s    CHECK_Y        ; if it is zero, we do not go left
Subq.w    #1,d0        ; if it is 1, move the sprite
CHECK_Y:
Move.w    D3,D2        ; copy the value of the register
Lsr.w    #1,D2        ; shift the bits one place to the right
Eor.w    D2,D3        ; perform the exclusive OR. Now we can test
Btst    #8,D3		; test if it goes up
Beq.s    NOALTO        ; if not, check if it goes down
Subq.w    #1,d1        ; if the sprite moves
Bra.s    ENDJOYST
NOALTO:
Btst    #0,D3        ; test if it goes down
Beq.s    ENDJOYST    ; if not, finish
Addq.w    #1,d1        ; if the sprite moves
ENDJOYST:
Rts

;****************************************************************************
; This routine clears the screen using the blitter.
;****************************************************************************

ClearScreen:
btst    #6,2(a6)
WBlit3:
btst    #6,2(a6)		 ; wait for the blitter to finish
bne.s    wblit3

move.l    #$01000000,$40(a6)    ; BLTCON0 and BLTCON1: Clear
move.w    #$0000,$66(a6)		; BLTDMOD=0
move.l    #Screen,$54(a6)        ; BLTDPT - screen address
move.w    #(64*256)+20,$58(a6)    ; BLTSIZE (start blitter!)
; clear the entire screen

rts

; ****************************************************************************

section	cop,data_C

copperlist
dc.w	$8E,$2c81	; DiwStrt
dc.w	$90,$2cc1	; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

dc.w $100,$1200        ; BPLCON0 - 2 bitplanes lowres

dc.w $180,$000    ; Colour0
dc.w $182,$aaa    ; Colour1

BPLPOINTER1:
dc.w $e0,0,$e2,0    ;first     bitplane

dc.l    $ffff,$fffe    ; end of copperlist

******************************************************************************

; the bob is at 1 bitplane, 128 pixels wide and 29 lines high

Bob:
Incbin    ‘Amiga.bmp’

; ****************************************************************************

; This is the table we need to ‘cut off’ the unwanted pixels.

MaskRight:
dc.w    %1111111111111111
dc.w    %1111111111111110
dc.w	%1111111111111100
dc.w	%1111111111111000
dc.w	%1111111111110000
dc.w	%1111111111100000
dc.w	%1111111111000000
dc.w	%1111111110000000
dc.w	%1111111100000000
dc.w	%1111111000000000
dc.w	%1111110000000000
dc.w	%1111100000000000
dc.w	%1111000000000000
dc.w	%1110000000000000
dc.w	%1100000000000000
dc.w	%1000000000000000

; ****************************************************************************

Section Miobuffero,BSS_C

Screen:
ds.b    (320*256)/8

end

This short program shows how it is possible to use the blitter 
to perform bob clipping, which is useful in many video games. First of all,
let's see what clipping is in general. Clipping routines are famous
in 2D and 3D graphics, as it is often necessary to
draw lines that extend beyond the available video memory.
For example, consider a line with coordinates (300,450) and 
needs to be drawn in a 320x256 video area. It is immediately apparent that
if the line is drawn using any algorithm, the latter could
write to an area of memory reserved for code, for example, and 
thus crash the machine. The same applies to bobs.
In fact, suppose we have a video area measuring 320x256 and a bob
measuring 64x20 pixels. Our bob will be placed on the screen based on the
coordinates in the top left corner (these can also be other coordinates)
x and y. Using the blitter, we can place this bob anywhere
point in the available area, but what happens if we place our bob
at the coordinate point (300,120), for example. Let's look at the drawing


(0x0) _______________________
|            |
|            |
|     (300x120) ___|___
|         |    | |
|         | A    | B |
|         |___|___|
|            |
|            |
|            |
|            |
|_______________________|(320x256)



As you can see, part of bob ‘B’ does not fit into the video area and goes
outside it. The question is ‘But where exactly does it go?’, and the answer is 
‘it depends’. In fact, let's assume that we always have a video area
of 320x256 with 1 bitplane. As long as we stay within a range of
 
coordinates, there is no risk that the blitter will ruin particular areas of memory.
 In fact, the portion of bob that comes out will re-enter on the
left, but one pixel lower, i.e. something like this will happen.



(0x0) _______________________
|            |
|            |
|     (300x120) ___|
|___         |    |
| |         | A    |
| B |         |___|
|___|			|
|            |
|            |
|            |
|_______________________|(320x256)


Just think about the fact that memory is sequential, so when you get to
the last word of a line, the next word will be the first word of the next line
. So in this case, you can see that there is a risk for
our data or our code, but let's suppose that the coordinate is
extremely close to (320,256). In this case, we really risk
big time! In any case, the fact remains that that portion of the bob is unsightly.
Have you ever seen a game where the bobs coming out from the right enter from the
left, like Silvan? There are various solutions to eliminate that portion
of the bob that has become useless and dangerous. One could be to make
a larger video area, i.e. add safety zones to
the right and left of the video memory. Something like this:




_______________________________________
|\\\\\\\|            |\\\\\\\|    
|\\\\\\\|            |\\\\\\\|
|\\\\\\\|             |\\\\\\\|
|\\\\\\\|             |\\\\\\\|
|\\\\\\\|             |\\\\\\\|
|\\\\\\\|		 	|\\\\\\\| 
|\\\\\\\|            |\\\\\\\|
|\\\\\\\|            |\\\\\\\|
|\\\\\\\|            |\\\\\\\|
|\\\\\\\|            |\\\\\\\|
|\\\\\\\|_______________________|\\\\\\\|


|\\\|
|\\\| <- Security memory area
|\\\|


As can be seen from the drawing, this solution guarantees two things: the first
is that the superfluous portions of bob will not affect our data, and the 
second is that those portions will not fall back from the left. But let's do a
little math.The dimensions of those areas must be at most equal
to the maximum horizontal dimension of the bobs, so if we have a bob with a
maximum horizontal dimension of 128 pixels and we also use it in a
5-bitplane context, we will need 2 areas of ((256x128)/8)*5=20480
i.e. a total of 40960. We must also consider the safety areas
that should be placed at the top and bottom of our video area,
 so the memory usage would be too high.
The solution must therefore be sought in an algorithm that is able to retrieve
the portions of bob that we are interested in at that moment and write them
in the correct memory areas. All this can be done with the blitter.
The programme shows how this can be achieved, starting from
a few considerations. First of all, if our bob must be placed at
a coordinate such that the entire bob fits into the video memory, then
this can be done with a classic routine for moving a bob with the
blitter. Variations occur when the xb coordinate at the bottom right 
coincides with the maximum limit of the video memory and exceeds it completely.
Let's prepare ourselves for a rather intricate line of reasoning.
Let XM be the limit coordinate of our video area, henceforth referred to as the window,
and let us also assume that XM is a multiple of 16 pixels (for convenience).
Let us now make some observations. When our bob coincides with XM,
the xa coordinate at the top left will also be a multiple of 16 pixels,
because the bob has a horizontal dimension that is a multiple of 16 pixels. In fact
if we have a bob of 64 pixels and XM=320, then when xb coincides with XM
we will have xa=320-64=256, which is still a multiple of 16. This means
that if our bob moves only one more pixel, xb will be equal to
 
to XM+1, but the important thing is that we will write in the first bit of the 
word following (XM/16). In our example, since XM=320, the word we will 
invade will be the 41st. If you have understood this, then you have overcome
the worst part, and if any of you have experimented a lot with the blitter, you may
already see the solution to the problem. In fact, what we need to do now is
prevent the blitter from writing in the invaded word. We can do this 
very simply with the blitter register BLTLWM by setting it to 
"1111111111111110‘. In this way, the last bits of the last word of our
bob will not be copied. If our bob moves another pixel
, then the word will be set to ’1111111111111100". But what happens if our
bob moves 16 pixels further out of the video window? It is clear that we can no
longer use the BLTLWM register, but we must also use the
module. If we have a bob that is not in RAW format, the information is
 
stored one after the other, so we set the source module to 
zero. If our bob is now 16 pixels outside the window, then 
we have to tell our blitter something like this: my bob
now has a width of x-16 and a height of y, so read x-16 bits and immediately after
skip 16 (those outside the video window), but when writing, write
x-16 and then skip 320-(x-16) pixels. Obviously, we don't talk to the 
blitter in this way, or in terms of pixels, but I hope I've made myself clear
understand. So, by combining the two techniques of masking unwanted bits
and skipping unnecessary information using the module, we can
clip the bob quickly. Logically, it takes less time not to
do it, but we also have to consider the fact that this way more of the bob
is left out, the sooner the blitter finishes the copying job.

Using the joystick, you can move a 128x29 pixel bob. Try changing
the XMax coordinate(it must be a multiple of 16).

In this example, we will limit ourselves to illustrating the technique of ‘cutting’ the bob
without worrying about the background. In fact, we draw our bob by means of a
simple copy. Furthermore, in order not to complicate the listing, we delete the entire screen each time
instead of just the rectangle that
encloses the bob.
You can try extending this technique to the complete bob example
(i.e. with background restoration). In this case, keep in mind
that when the bob is ‘cut’ to the right, you must change the module and
size of the blit not only in the bob drawing routine (as
in this example) but also in the background saving and restoration routines
.
