
; Lesson 2h.s

Start:
	lea    $dff006,a0    ; VHPOSR - put $dff006 in a0
	lea    $dff180,a1    ; COLOR00 - put $dff180 in a1
	lea    $bfe001,a2	 ; CIAAPRA - put $bfe001 in a2

Waitmouse:
	move.w    (a0),(a1)+    ; put the value of $dff006 in colour 0,
							; i.e. $dff180 (contained in a1)
							; and increment a1 by 2, bringing it to $dff182,
							; i.e. colour 1
	move.w    (a0),-(a1)    ; decrement a1 by 2, bringing it back to $dff180,
							; then put $dff006 in colour 0
	btst    #6,(a2)         ; left mouse button pressed?
	bne.s    Waitmouse      ; if not, return to waitmouse and repeat
	rts            			; exit

	END

With this cycle, you can clearly see the differences between (a1)+ and -(a1), which
are placed in such a way as to cancel each other out: while the first (a1)+
increases a1 by one word, bringing it to $dff182, the following -(a1) returns
a1 to $dff180 and always writes in colour 0.
In fact, the two instructions can be rewritten simply as:

move.w    (a0),(a1)
move.w    (a0),(a1)

Check that the addresses $dff180 and $dff182 are swapped in reg. a1 by doing
an AD. REMEMBER that when you see a + AFTER a bracket, the register
is INCREASED (+!!!) AFTER the operation, while if you see a - BEFORE
a bracket, the register is DECREASED (-!!!) BEFORE!!!
NOTE: you can terminate the cycle during the AD by holding down the left
key when executing btst; once you reach RTS, press ESC to return.

