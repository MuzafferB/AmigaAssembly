
; Lesson 2e.s

Start:
	lea    $dff006,a0    ; put $dff006 (VHPOSR) in a0
	lea    $dff180,a1    ; put $dff180 (COLOR0) in a1
	lea    $bfe001,a2    ; put $bfe001 (CIAAPRA) in a2
Waitmouse:
	move.w  (a0),(a1)    ; put the value of $dff006 in colour 0
	btst    #6,(a2)      ; left mouse button pressed?
	bne.s   Waitmouse    ; if not, return to waitmouse and repeat
	rts            ; exit

	END

As you can see, the Waitmouse cycle is composed of indirect addresses
rather than direct ones, i.e. instead of operating directly with the
addresses, the latter are placed in data registers and read or written
using the registers in brackets (indirectly).
This increases the speed of the loop, as registers are faster
than direct addressing (you should notice a slight change
in the flashing of the screen compared to LESSON1a.s due to the increased
speed of execution).
After execution, you can verify that registers a0, a1 and a2 contain
$dff006 (VHPOSR), $dff180 (COLOR00) and $bfe001 (CIAAPRA) respectively.
If you want to remove all the numbers from the loop, you can modify
the BTST #6,$bfe001 with a BTST d0,$bfe001, where d0 contains 6:

Start:
	lea    $dff006,a0    ; VHPOSR - put $dff006 in a0
	lea    $dff180,a1    ; COLOR00 - put $dff180 in a1
	lea    $bfe001,a2    ; CIAAPRA - put $bfe001 in a2
	moveq  #6,d0         ; put the value 6 in d0
Waitmouse:
	move.w  (a0),(a1)    ; put the value of $dff006 in colour 0
	btst    d0,(a2)      ; left mouse button pressed?
						 ; (bit 6 of $bfe001 reset?)
	bne.s   Waitmouse    ; if not, return to waitmouse and repeat
	rts            ; exit

(use Amiga+b,c and i to replace this source with the one above)

NOTE: To put a 6 in d0 instead of MOVE.L #6,d0 I used MOVEQ #6,d0,
because numbers below $7f (i.e. 127), whether negative or positive,
can be entered into the data registers with the special command MOVEQ, which
is always .L, so you don't put .b,.w or .l as already seen for LEA.
Examples:
MOVEQ    #100,d0    ; less than 127
MOVE.L   #130,d0    ; more than 127, the normal move.l must be used.
MOVEQ    #-3,d0     ; up to -128, MOVEQ can be used.

NOTE2: It is very common to use all registers by putting the addresses and
data necessary for routines (subprograms) in them, because they are faster
and more flexible. But they are obviously less readable. In fact, imagine
that the addresses and data have been put in the registers at the beginning
of the program and that we are in the middle of it with this routine:

Routine:
	move.w  (a0),(a1)
	btst    d0,(a2)
	bne.s   Routine

In which we only see (a0),(a1), d0,(a2) etc. IF WE DON'T KNOW
WHAT IS IN THE REGISTERS, ALL THIS WILL APPEAR MEANINGLESS, so I assure you
that it is important to learn the addressing and remember where
you put the addresses and data in the registers in order to understand what
is written even just a week earlier; 
The strength of 68000 processors lies
precisely in their ability to work INDIRECTLY with memory using
the registers in their different addresses, but this is also where
the difficulty lies.

To practise, try writing some useless, tangled listings
and try to understand what the result is at the bottom of the listing, which you can then
verify by executing it. Here's a suggestion to get you started, then continue
the tangling as if you were solving a puzzle:

	lea    SMURF,a0
	move.l    (a0),a1
	move.l    a1,a2
	move.l    (a2),d0
	moveq    #0,d1
	move.l    d1,a0
	.....
	rts

SMURF:
	dc.l    $66551

