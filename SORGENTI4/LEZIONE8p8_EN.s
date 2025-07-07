
; Lesson 8p8.s    Condition Codes with the ADDX Instruction

SECTION    CondC,CODE

Start:
move.l    #$b1114000,d0
move.l    #$22222222,d1
move.l    #$82345678,d2
move.l	#$abababab,d3
add.l	d0,d2
addx.l	d1,d3
move.l	#$01114000,d0
move.l	#$00000000,d1
move.l	#$02222222,d2
move.l	#00000000,d3
add.l    d0,d2
addx.l    d1,d3
stop:
rts

end

Let's now look at an example of how to use the ADDX instruction.
Suppose we need to add two 64-bit integers, one contained in D0 and D1
and the other in D2 and D3. First, we add the least significant 32 bits
of the two numbers with a normal ADD:

D0: B1114000 22222222 82345678 ABABABAB 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA4A64
SSP=07CA5B97 USP=07CA4A64 SR=8008 T1 -- PL=0 -N--- PC=07CA74C4
PC=07CA74C4 D480         ADD.L D0,D2
>

We note that a carry is generated because the sum is too large to
be contained in 32 bits. Therefore, the C and X flags take the value 1.
To add the most significant 32 bits, we use ADDX, which
adds the contents of the X flag to the two registers, thus taking into account
the carry.

D0: B1114000 22222222 33459678 ABABABAB 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA4A64
SSP=07CA5B97 USP=07CA4A64 SR=8013 T1 -- PL=0 X--VC PC=07CA74C6
PC=07CA74C6 D781         ADDX.L D1,D3
>

We now have our 64-bit result in registers D2 and D3

D0: B1114000 22222222 33459678 CDCDCDCE 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA4A64
SSP=07CA5B97 USP=07CA4A64 SR=8008 T1 -- PL=0 -N--- PC=07CA74C8
PC=07CA7B3E 223C02222222     MOVE.L #$02222222,D1
>

ADDX modifies the flags like ADD, except for the Z flag.
In fact, the Z flag is cleared if the result of ADDX is not zero,
but is left unchanged if the result is zero. This allows the Z flag
to take into account the status of the entire operation.
The rest of the example shows this:
We are adding two 64-bit numbers, but both have the most significant 32
bits set to zero

D0: 01114000 00000000 02222222 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA4A64
SSP=07CA5B97 USP=07CA4A64 SR=8004 T1 -- PL=0 --Z-- PC=07CA8058
PC=07CA8058 D480         ADD.L D0,D2
>

The ADD of the least significant digits sets Z to 1 because the result
is not zero

D0: 01114000 00000000 03336222 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA4A64
SSP=07CA5B97 USP=07CA4A64 SR=8000 T1 -- PL=0 ----- PC=07CA805A
PC=07CA805A D781         ADDX.L D1,D3
>

The result of ADDX, on the other hand, is zero. If it behaved like
ADD, it would reset the Z flag. But even if the sum of the 32 most significant bits
is zero, the result of the entire operation is not.
ADDX therefore leaves the Z flag unchanged so that we can
see that the result of the entire operation is not zero.

D0: 01114000 00000000 03336222 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA4A64
SSP=07CA5B97 USP=07CA4A64 SR=8000 T1 -- PL=0 ----- PC=07CA805C
PC=07CA805C 4E75         RTS
>

This way of handling the Z flag is also used by the
SUBX and NEGX instructions.

