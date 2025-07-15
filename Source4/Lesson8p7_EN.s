
; Lesson 8p7.s    Condition Codes with the CMP Instruction

SECTION    CondC,CODE

Start:
move.w    #$9000,d0
move.w    #$6000,d1
cmp.w    d0,d1
bgt.w    jump
stop:
rts

jump:
nop    ; this jump is made if the destination is greater
; than the source
rts

end

The CMP instruction allows us to compare two numbers and set the CCs accordingly.
 Usually, a CMP is followed by a Bcc instruction. Here are the three ‘types’:

CMPA.x    <ea>,Ay        Source=All    Destination=An (note: ONLY .W or .L).
-----------------------------------------------------------------------------
CMPI.x	#d,<ea>		Sorgente=#d	Destinazione=Dati alterabili
-----------------------------------------------------------------------------
CMPM.x	(Ax)+,(Ay)+	Sorgente=(An)+	Destinazione=(An)+
-----------------------------------------------------------------------------

Each of the 68000 comparison instructions subtracts the Source operand 
from the Destination and sets the condition flags according to the following table:

+----------------------+---+---+---+---+
|Condition | N | Z | V | C |
+----------------------+---+---+---+---+
|Source<Destination | 0 | 0 |0/1| 0 |
+----------------------+---+---+---+---+
|Source=Destination | 0 | 1 | 0 | 0 |
+----------------------+---+---+---+---+
|Source>Destination | 1 | 0 |0/1| 1 |
+----------------------+---+---+---+---+

The V bit is 1 if the difference between source and destination exceeds
the 2's complement field of the operand (i.e. if it is less than the
smallest representable negative number or greater than the largest
representable positive number).
N and V are only significant when comparing operands in 2's complement.

N.B.: Unlike subtraction instructions, comparison instructions
do not save the result of the subtraction!!!!!!!! (I think that's clear!)
------------------------------------------------------------------------------

The Bcc read the status of the CC and, if a particular
condition (which varies between individual Bcc) is met, they execute or do not execute a jump.
The CMP sets the CC flags in the same way as the SUB.
Let's look at a quick example. We compare a positive number
with a negative number. We see that the result of the comparison is different if we consider
the negative number as positive.
We run the programme up to the BGT instruction.

D0: 00009000 00006000 00000000 00000000 00000000 00000000 00000000 00000000
 
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA4F64
 
SSP=07CA6097 USP=07CA4F64 SR=800B T1 -- PL=0 -N-VC PC=07CA7B52
PC=07CA7B52 6E000004         BGT.W $07CA7B58
>

As you know, BGT jumps if the destination operand is greater than
the source operand.
It also considers numbers as values in 2's complement.
In our case, the destination operand is greater than the source operand
because the former is positive and the latter is negative.
 
Let's take another step and verify this:

D0: 00009000 00006000 00000000 00000000 00000000 00000000 00000000 00000000 
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA4F64
 
SSP=07CA6097 USP=07CA4F64 SR=800B T1 -- PL=0 -N-VC PC=07CA7B58
PC=07CA7B58 4E71         NOP
>

As you can see, the jump has been made; in fact, the next instruction
to be executed is NOP.
Now let's see what happens when we replace the BGT instruction with the BHI instruction.
This instruction also performs the jump if the destination operand is
greater than the source operand. The difference is that BHI considers all numbers
to be positive.
Let's run the modified programme.

D0: 00009000 00006000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA4F64
SSP=07CA6097 USP=07CA4F64 SR=800B T1 -- PL=0 -N-VC PC=07CA7B52
PC=07CA7B52 62000004         BHI.W $07CA7B58
>

This time, $9000 is considered a positive number. Therefore, it
is greater than $6000. As a result, the jump is not executed:

D0: 00009000 00006000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA4F64
SSP=07CA6097 USP=07CA4F64 SR=800B T1 -- PL=0 -N-VC PC=07CA7B56
PC=07CA7B56 4E75         RTS
>

In conclusion, when using CMP, you must pay close attention to how you
want to interpret negative numbers, and then use the correct Bcc.

