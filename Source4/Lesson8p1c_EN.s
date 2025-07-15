
; Lesson 8p1c.s        Condition Codes with DIVU/DIVS

SECTION    CondC,CODE

Start:
moveq    #$0010,d0
moveq    #$0003,d1
divs.w    d1,d0

move.l    #$200000,d0
moveq    #$0002,d1
divs.w    d1,d0
stop:
rts

end

;    ·[oO]·
;     C
;     \__/
;     U

Let's now look at an example of how to use division instructions.
The 68000 also provides two different instructions for division:
DIVS divides two numbers considering them as numbers in 2's complement,
while DIVU always considers the numbers to be divided as positive.
The differences are therefore similar to those between MULS and MULU, so we will not
illustrate them here; experiment for yourself.
The examples we will use concern DIVS.
Division instructions divide a 32-bit operand in a data register
by a 16-bit divisor. The 16-bit quotient will be placed in the lower word
of the destination register and the remainder in the upper word.
In the case of division by 0, the 68000 will perform an exception routine, 
and in most cases you will get a nice GURU MEDITATION.
Division can affect condition codes in the following ways:

1) Carry (C) is always set to 0
2) Overflow (V) is set if the dividend is so much greater than the divisor that
the result cannot be contained in 16 bits
e.g.:
move.l    #$ffffffff,d0
divu.w    #2,d0

3) Zero (Z) is set to 1 if the result of the operation is 0
4) Negative (N) is set to 1 if the result of the operation is negative
5) Extend (X) remains unchanged.
----------------------------------------------------------------------------

First, let's look at a normal example: we divide the number $10 (=16) contained in
register D0 by the number 3, contained in D1.

D0: 00000010 00000003 00000000 00000000 00000000 00000000 00000000 00000000 00000000
 
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07D32154
 
SSP=07D33287 USP=07D32154 SR=8000 T1 -- PL=0 ----- PC=07D34CE8
PC=07D34CE8 81C1         DIVS.W D1,D0
>

The result is shown below. Note that both the quotient
(placed in the lower word D0) and the remainder (placed in the upper word of D0) are calculated.
This is because it is a division between integers.

D0: 00010005 00000003 00000000 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07D32154
SSP=07D33287 USP=07D32154 SR=8000 T1 -- PL=0 ----- PC=07D34CEA
PC=07D34CEA 203C00200000     MOVE.L #$00200000,D0
>

Let's look at another example.
Let's divide the number $200000 (contained in D0) by $2 (in D1).

D0: 00200000 00000002 00000000 00000000 00000000 00000000 00000000 00000000
 
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07D32154
 
SSP=07D33287 USP=07D32154 SR=8000 T1 -- PL=0 ----- PC=07D34CF6
PC=07D34CF6 81C1         DIVS.W D1,D0
>

The correct result is $100000, as you can verify with the ‘?’ command in
ASMONE. However, this number is too large to be contained in a word.
Therefore, DIVS cannot perform the calculation correctly and signals
this fact by setting the V flag to 1:

D0: 00200000 00000002 00000000 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07D32154
SSP=07D33287 USP=07D32154 SR=8002 T1 -- PL=0 ---V- PC=07D34CF8
PC=07D34CF8 4E75         RTS
>

In cases like this, the division must be performed using special algorithms
.

