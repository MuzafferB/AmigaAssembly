
; Lesson 8p2b.s    Sign extension in address registers

SECTION    CondC,CODE

Start:
move.l    #$ffffffff,a0    ; That is, ‘move.l #-1,a0’
move.w    #$51a7,a0
stop:
rts

end

; \|/
; (©_©)
;--------ooO-(_)-Ooo--------

In this lesson, we will deal with another peculiarity of
direct address register addressing.
Let's execute the above programme one instruction at a time.
The first MOVE loads a 32-bit value into A0.

D0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
A0: FFFFFFFF 00000000 00000000 00000000 00000000 00000000 00000000 07C9F584
SSP=07CA06B7 USP=07C9F584 SR=8000 T1 -- PL=0 ----- PC=07CA1F8E
PC=07CA1F8E 307C0100         MOVE.W #$51A7,A0
>

As usual, register A0 has taken the value $FFFFFFFF. Now let's execute
the second MOVE. We notice that it loads a 16-bit value into A0.
We would expect only the low word of A0 to be modified.
Instead, we can see that the high word has also been modified:

D0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 000051A7 00000000 00000000 00000000 00000000 00000000 00000000 07C9F584
SSP=07CA06B7 USP=07C9F584 SR=8000 T1 -- PL=0 ----- PC=07CA1F92
PC=07CA1F92 4E75         RTS
>

This happens because when you write a WORD to an address register
(remember that it is NOT possible to write a single BYTE, i.e.
the instruction MOVE.B xxxx,Ax is NOT allowed), it is transformed into a
LONG WORD through an operation called ‘sign extension’, which consists
of copying the most significant bit of the WORD (i.e. bit 15, which, as
you know, indicates the sign of a WORD value) to all the bits of the
upper WORD, so as to retain the same sign when passing from the WORD value to
the LONG WORD value. In practice, in our case we have:

starting value = $51A7 = %0101000110100111
^
|
most significant bit is 0

extended value = $000051A7 = %00000000000000000101000110100111

all bits from 16 to 31 have taken the value 0.

Let's take another example, changing the values loaded by MOVE:

move.l    #$22222222,a0
move.w    #$c1a7,a0

By executing the first MOVE, we obtain:

D0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 22222222 00000000 00000000 00000000 00000000 00000000 00000000 07C9F584
SSP=07CA06B7 USP=07C9F584 SR=8000 T1 -- PL=0 ----- PC=07CA2642
PC=07CA2642 307CC1A7         MOVE.W #$C1A7,A0
>

running the second:

D0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 
A0: FFFFC1A7 00000000 00000000 00000000 00000000 00000000 00000000 07C9F584
 
SSP=07CA06B7 USP=07C9F584 SR=8000 T1 -- PL=0 ----- PC=07CA2646
PC=07CA2646 4E75 RTS

In this case, the sign extension made the LONG WORD value negative:

Starting value = $C1A7 = %1100000110100111
^
|
The most significant bit is 1
Extended value = $FFFFC1A7 = %11111111111111111100000110100111

All bits from 16 to 31 have taken the value 1.

Note: the EXT.L instruction is used to extend the sign as in these examples.
