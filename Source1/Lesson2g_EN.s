
; Lesson 2G.s

Start:
	lea    THEEND,a0   ; put the address where to start in a0
	lea    START,a1    ; put the address where to end in a1

CLELOOP:
	clr.l    -(a0)    ;add 4 to a0 (long!), then reset the long
	cmp.l    a0,a1    ; is a0 equal to a1? In other words, are we at the START address?
	bne.s    CLELOOP  ; if not, go back and execute CLELOOP...
	rts        ; EXIT the program and return to ASMONE

START:
	dcb.b    40,$fe    ; PUT 40 bytes $fe IN MEMORY HERE.

THEEND:            ; this label marks the end of the 40 bytes...

	dcb.b    10,0    ; let's put 10 bytes reset here just for fun

	end

This little program cleans up from the address set in a0 to
the address we set in a1: the difference with LESSON2f.s, where
a CLR.L (a0)+ is used, is that here we start from the end of the bytes to be cleaned and
work backwards to the beginning.
To verify this, do an AD and you will notice that every time
CLR.L -(a0) is executed, the a0 register decrements until it reaches a1, i.e. START.
Check with M START that the clean-up has taken place after execution,
and if you like, change CLR.L -(a0) to CLR.W -(a0) and you will notice
that 20 steps are required (in fact, 20*2=40) and that each time a0 is
decreased by 2, while replacing it with CLR.B -(a0) will require 40 steps
and the a0 register will be decremented by 1 each time.
