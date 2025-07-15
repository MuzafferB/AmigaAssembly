
; Lesson 2l.s

Start:
	lea    $dff000,a0      ; put $dff000 in a0

Waitmouse:
	move.w   #$20,$1dc(a0) ; BEAMCON0 (ECS+) PAL video resolution
	bsr.s    Flashing      ; Flashes the screen
	bsr.s    ColorArrow    ; Flashes the arrow
	btst     #2,$16(a0)    ; POTINP - Right mouse button pressed?
						   ; (bit 2 of $dff016
	bne.s    Notpressed    ; If not pressed, skip MakeConfusion
	bsr.s    MakeConfusion  

Notpressed:
	btst    #6,$bfe001    ; left mouse button pressed?
	bne.s    Waitmouse    ; if not, return to waitmouse and repeat everything
	rts            		  ; exit

ColorArrow:
	moveq    #-1,d1      ; THAT IS moveq #$FFFFFFFF,d1
	moveq    #20-1,d0    ; number of arrow colour cycles
flash:
	subq.w    #8,d1        ; change the colour to be put in $dff1a4
	move.w    d1,$1a4(a0)  ; COLOR18 - put the value of d1 in $dff1a4
						   ; (the colour of the mouse arrow!)
	dbra    d0,flash
	rts

Flashing:
	move.w    6(a0),$180(a0)    ; put the .w value of $dff006 in colour 0
	move.b    6(a0),$182(a0)    ; put the .b value of $dff006 in colour 1
	rts

MakeConfusion:
	move.w    #0,$1dc(a0)    ; BEAMCON0 (ECS+) NTSC video resolution
	rts

	END

This little program is interesting only for its structure. In fact,
it has a main program, the one from Start to RTS, which calls
subroutines (i.e., subprograms, which are nothing more than parts of the
program named by a label (i.e., a name) and ending in an RTS.
With the ‘AD’ debugger, try to follow the course of the program: to follow
all the subroutines, proceed with the right arrow key,
and you will notice, among other things, in the ColorArrow routine how the d0 register
is decremented by 1 at a time.

The fundamental problem with BSR/BEQ/BNE/RTS structures lies in the fact that
everything is regulated by jumps that can cause a return via RTS to the
point where the jump was executed (BSR LABEL), and by jumps that are
like the branches of a tree: once you have chosen whether to take the right
right or left, you continue along that branch and cannot go back

branch 1
_______ _ _ etc. _ _ _ RTS, exit from this side
beq/bne fork /
_____________/
\ branch 2
\______ _ _ etc. _ _ _ RTS, exit from this other side


A BEQ/BNE jump is like deciding to go to Milan or Palermo, you take
different roads, and once you arrive at your destination, you spend the night in one
of those two cities (where we find the RTS), having travelled along different motorways.

Instead, if we find a BSR.w Milan, we jump to Milan, follow the instructions
we find in Milan, then when we find an RTS we “teleport” to
the point where we took the road to Milan, miraculously, it's like
reading a magic book, where on every page there is a picture of a
landscape, so with an AbraCadaBSR we enter the drawing on the first page,
we spend some time there, then when we come across an AmuletRTS we return to sitting
in front of the book, ready for an AbraCadaBSR on the second page.


NOTE1: Pressing the right mouse button executes a routine that would otherwise
be skipped:

btst    #2,$16(a0)    ; Right mouse button pressed?
; (bit 2 of $dff016 - POTINP)
bne.s    not pressed    ; If not pressed, skip MakeConfusion
bsr.s    MakeConfusion  ;
not pressed:

Remember this method for executing a subroutine only if
a certain condition is met, in this case that the
right mouse button is pressed; you often do things like this when programming.
The register used to cause ‘Confusion’ is $dff1dc, whose bit 5 is used
to switch the video mode between European PAL and American NTSC; this
register only exists in computers manufactured after 1989, so it may not work for anyone
who has an old Amiga. If it works, you will notice that
when you press the right mouse button, the screen will flash and appear to
explode, because switching modes very quickly produces this
result. If you want to make two small programs that can be called from AmigaDos to switch
the video mode, just do the following:

move.w    #0,$dff1dc    ; BEAMCON0
rts

Assemble it and save it to a disk with WO (i.e. as a file that you can
execute) with the name NTSC, then assemble this other one:

move.w    #$20,$dff1dc    ; BEAMCON0
rts

And save it as PAL. From SHELL you can then change the video mode
by calling the two small programs PAL and NTSC.

If you are not familiar with this program, bear in mind that the REAL ones are
a thousand times more complicated, such as various BSRs, so make sure you understand it 100%
before starting LESSON 3, entitled: ‘WE COULD HAVE IMPRESSED YOU WITH SPECIAL EFFECTS
AND ULTRA-VIVID COLOURS, BUT WE DON'T KNOW HOW TO DO THAT YET’.
