
; Lesson 8p6.s    Condition Codes with the ADD Instruction

SECTION    CondC,CODE

Start:
move.w    #$4000,d0
move.w    #$2000,d1
add.w    d0,d1
move.w    #$e000,d0
move.w    #$b000,d1
add.w    d0,d1
move.w    #$6000,d0
move.w    #$5000,d1
add.w    d0,d1
move.w    #$9000,d0
move.w    #$a000,d1
add.w    d0,d1
stop:
rts

end


The ADD instruction affects the status codes as follows:

1) Bit0, Carry (C): is set to 1 if the result cannot be contained
in the destination operand.
Example: (assuming that the numbers are unsigned.)

move.w    #$7001,d0    ; d0=$7001
add.w    #$8fff,d0    ; d0=$7001+$8fff=$10000

As can be seen, the result of the addition cannot be contained in
one word as 17 bits would be required, so the C flag is set.

2) Bit1, Overflow (V): The bit is set to 1 only if the addition of two numbers
with the same sign exceeds the 2's complement field of the operand
(e.g. in the case of WORD operands, V is 1 if the result
is greater than 32767 or less than -32768)
Example: (signed numbers)

move.w    #$7fff,d0    ; d0=$7fff
addq.w    #$1,d0        ; d0=$7fff+1=$8000=-32768 !!!!!

In this case, the Overflow bit is set.

3) Bit2, Zero (Z): The bit is set to 1 if the result of the operation is zero.
4) Bit3, Negative (N): The bit is set to 1 if the last operation produced
a negative result.
5) Bit4, Extend (X): takes the same state as bit C

V and N only make sense if signed numbers are added together.

N.B.: If the operations have an address register as their destination operand,
the condition codes remain UNCHANGED!!!!
This is a variation of the ADD instruction, and is called add address ADDA.
-------------------------------------------------------------------------------

Now let's check the theory.
Let's execute the first 2 steps of the programme: these are 2 MOVE instructions that
have the effect of loading the 2 values we want to add into 2
registers. These are 2 positive values.

D0: 00004000 00002000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA4754
SSP=07CA5887 USP=07CA4754 SR=8000 T1 -- PL=0 ----- PC=07CA7A74
PC=07CA7A74 D240         ADD.W D0,D1
>

Let's add them up. As you can verify ‘by hand’, this sum does not generate
carries, i.e. the result ($6000) is less than $7fff, and therefore
can still be contained in a word. So the C, X and V flags are
reset. In addition, Z and N are also reset, because $6000 is positive and
not equal to zero.

D0: 00004000 00006000 00000000 00000000 00000000 00000000 00000000 00000000
 
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA4754
 
SSP=07CA5887 USP=07CA4754 SR=8000 T1 -- PL=0 ----- PC=07CA7A76
PC=07CA7A76 303CE000         MOVE.W #$E000,D0
>

Now let's add $e000 and $b000. In this case, we are dealing with
negative numbers. The result (which you can check by hand)
is $9000=-28672, which is greater than -32768 and therefore does not cause any problems, so
the V flag is zero.
Note, however, that if we wanted to, we could consider our two numbers as positive
by ignoring the sign. In this case, our words would take on
values between 0 and 65535. In this case, the result we obtain,
i.e. $9000, is obviously incorrect. This happens because the exact result
of $e000+$b000 (considered as positive) would be $19000=102400, i.e. a
number greater than 65535, which would need 17 bits to be
represented correctly.
To overcome this problem, the 68000 stores the 17th bit in the Carry,
(and also in X), which then takes the value 1. Note also that since $9000
is negative (considered in 2's complement), the N flag also takes the value 1.
Here is what you get when you perform the sum:

D0: 0000E000 00009000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA4754
SSP=07CA5887 USP=07CA4754 SR=8019 T1 -- PL=0 XN--C PC=07CA7A80
PC=07CA7A80 303C6000         MOVE.W #$6000,D0
>

Let's look at a third example. This time, we add $5000 (=20480) and $6000 (=24576).
These are two positive numbers. Unlike the first example, however,
if we perform the sum by hand, we see that the result is 45056 (=$b000), which
is greater than 32767, and in fact, as you can see, it is a negative number.
Therefore, if we interpret the numbers in 2's complement (i.e., ranging from -32768
to 32767), the result is wrong, and therefore the V flag takes the value 1.
If, on the other hand, we interpret the numbers as always positive (i.e. from 0 to 65536)
the result is correct, because it is less than 65535. Therefore, the C flag
takes the value zero. The N flag still takes the value 1 because we have a
negative number (if interpreted as a two's complement). In fact:

D0: 00006000 0000B000 00000000 00000000 00000000 00000000 00000000 00000000
 
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA4754
 
SSP=07CA5887 USP=07CA4754 SR=800A T1 -- PL=0 -N-V- PC=07CA7A8A
PC=07CA7A8A 303C9000 MOVE.W #$9000,D0
>

Let's look at one last example. Let's add $9000 and $a000. These are two negative numbers.
 If we interpret them as 2's complements and add them together, we see
that the result is less than -32768. Therefore, the V flag takes the value 1.
If we interpret them as positive numbers, their sum would be
$13000, which requires 17 bits. Therefore, the C flag is also 1. 
As a result, we obtain $3000, which is the 16 least significant bits of the sum.
Since $3000 is positive, the N flag is zero.

D0: 00009000 00003000 00000000 00000000 00000000 00000000 00000000 00000000
 
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA4754
 
SSP=07CA5887 USP=07CA4754 SR=8013 T1 -- PL=0 X--VC PC=07CA7A94
PC=07CA7A94 4E75 RTS 
>
