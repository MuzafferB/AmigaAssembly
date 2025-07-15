
; Lesson 8p9b.s        Questions and advice on CC applications

SECTION    CondC,CODE

WaitMouse:
move.b    $BFE001,d2
and.b    #$40,D2        ; $40 = %01000000, i.e. bit 6
bne.s    WaitMouse
RTS

end

Why does this routine wait correctly for the mouse to be pressed, without
any BTST? I hope that the comment on the side and your knowledge of CCs will
help you guess the answer.
Let's look at some applications of ‘cc’. Go back to Lesson 7n.s
which made a sprite bounce. Here is that routine without the ‘btst’ that
tested (unnecessarily) the high bit to see if the number had become
negative:

; This routine changes the coordinates of the sprite by adding a constant speed
; both vertically and horizontally. Furthermore, when the sprite touches
; one of the edges, the routine reverses the direction.
; To understand this routine, you need to know that the ‘NEG’ instruction is used
; to convert a positive number to a negative number and vice versa. You will also notice
; a BPL after an ADD, and not after a TST or a CMP. Now you know why:


MoveSprite:
move.w    sprite_y(PC),d0	; read the old position
add.w    speed_y(PC),d0    ; add the speed
bpl.s    no_touch_top    ; if >0, it's OK
neg.w    speed_y        ; if <0, we have touched the top edge
; then reverse the direction
bra.s    MoveSprite    ; recalculate the new position

no_touch_top:
cmp.w    #243,d0    ; when the position is 256-13=243, the sprite
; touches the bottom edge
blo.s    no_touch_bottom
neg.w    speed_y        ; if the sprite touches the bottom edge,
; reverse the speed
bra.s	MoveSprite    ; recalculate the new position

no_touch_below:
move    d0,sprite_y    ; update the position
posiz_x:
move.w    sprite_x(PC),d1    ; read the old position
add.w    speed_x(PC),d1	; add speed
bpl.s    no_touch_left
neg.w    speed_x        ; if <0 touches left: reverse direction
bra.s    posiz_x        ; recalculate new horizontal position

no_touch_left:
cmp.w    #304,d1	; when the position is 320-16=304, the sprite
; touches the right edge
blo.s    no_touch_right
neg.w    speed_x        ; if it touches the right, reverse the direction
bra.s    posiz_x        ; recalculate new horizontal position

no_touch_right:
move.w    d1,sprite_x    ; update position

lea    miosprite,a1    ; sprite address
moveq    #13,d2        ; sprite height
bsr.s    UniMuoviSprite ; executes the universal routine that positions
; the sprite
rts

-    -    -    -    -    -    -    -    -

Now let's look at another possible use of CCs. Suppose we want to do a
vertical scroll on a bitplane, using a routine other than the one that
‘takes’ the address from the bplpointers, adds 40 and repoints it.
Let's assume that this routine only needs to add 40 to bpl0ptl, i.e. to the
low word of the address. The problem arises when we are, for example,
at address $2ffE2, where adding 40 would take us to $3000a, and the high word would also change:
Copperlist:
...
dc.w    $e0    ; bpl0pth
PlaneH:
dc.w    $0002
dc.w    $e2    ; bpl0ptl
PlaneL:
dc.w    $ffe2

As you can see, if we add 40 to PlaneL, we get $000A, but PlaneH remains $0002!
This is why every time we retrieve the address, we add it and put it back in the
2 words! Otherwise, when the high word ‘triggers’, what would we do?
However, with CC, something can be done. We said that $ffe2+40 gives us
the exact solution, $000a, but it also sets the Carry, for the carry, given
that we have exceeded $ffff. We could write:

Scroll:
add.w    #40,PlaneL    ; Go down one line by adding 40 to the
; low word of the address pointed to by
; bpl1pt
bcc.s    NotTriggered    ; We have exceeded the value that can be contained
; by the word and we also have to modify
; the high word? If not, skip...
addq.w    #1,PlaneH    ; Otherwise, add 1 to the high word, i.e.
; ‘execute’ the carry on PlaneL!
NotTriggered:
rts

These are some examples of how you can ‘revise’ already known routines.

