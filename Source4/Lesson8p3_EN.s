
; Lesson 8p3.s    Condition Codes with the TST Instruction

SECTION    CondC,CODE

Start:
tst.w    data
stop:
rts


data:
dc.w    $ff02

end

;     \ /
;     oO
;     \__/

The tst instruction basically compares the operand with zero.
We have seen that the MOVE instruction modifies the CCs, giving us information about
the data being copied. If we want to obtain that information WITHOUT copying
the data, we can use the TST instruction.
This is a single-operand instruction that reads a value and modifies
all the CCs based on it.
The CCs are modified in the same way as the MOVE instruction:

The V and C flags are reset
The X flag is not modified
The Z flag takes the value 1 if the tested data is 0
The N flag takes the value 1 if the tested data is negative.

Assemble the programme and execute the TST instruction:

D0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CBD594
SSP=07CBE6C7 USP=07CBD594 SR=8008 T1 -- PL=0 -N--- PC=07CC0F52
PC=07CC0F52 4E75         RTS
>

The N flag has taken the value 1 because the WORD at the
memory address ‘data’ is $ff03, which is a negative number because its most significant bit
is 1.

You can change the value contained at the ‘data’ address and observe how 
the TST behaves.
Note that it is not possible to use the TST with address registers, i.e.
if you try to assemble

TST.W    A0

ASMONE will give you an error message.

