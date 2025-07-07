
; Lesson 8p5.s    Condition Codes with the NEG Instruction

SECTION    CondC,CODE

Start:
neg.w    data1
neg.w    data2
neg.w    data3
neg.w    data4
stop:
rts

data1:
dc.w    $ff02
data2:
dc.w    $4f02
data3:
dc.w    $0000
data4:
dc.w    $8000

end

Let's now look at an example of the NEG instruction.
There are two negation instructions that allow you to complement an operand
B .W or .L to 2 by subtracting it from 0.
--------------------------------------------------------------------------
NEG <ea> Sorgente=All
NEGX <ea> Sorgente=All
--------------------------------------------------------------------------
The negation instruction can thus affect the condition codes:

1.Bit0, Carry (C): is set to 0 if the operand is zero, otherwise it is set to 1.

2.Bit1, Overflow (V): The bit is set to 1 only if the operand has the value of
$80 byte, $8000 word, $80000000 long.

3.Bit2, Zero (Z): The bit is set to 1 if the result of the operation is zero.
4.Bit3, Negative (N): is set to 1 if the operand is a positive number other than
zero.
5.Bit4, Extend (X): assumes the same state as bit C
------------------------------------------------------------------------------

The first instruction in the listing operates on the data at address ‘DATA1’, which is
a negative number. Executing it, we obtain:

D0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA7934
SSP=07CA8A67 USP=07CA7934 SR=8011 T1 -- PL=0 X---C PC=07CFEBDA
PC=07CFEBDA 447907CFEBF0     NEG.W $07CFEBF0
>

As you can see with the ASMONE command ‘M.w dato1’, the result is
positive and different from zero. Therefore, the only CCs set to 1
are C and X.
The second NEG operates on positive data. The result is therefore
negative, and consequently this time the N bit is also 1:

D0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA7934
SSP=07CA8A67 USP=07CA7934 SR=8019 T1 -- PL=0 XN--C PC=07CFEBE0
PC=07CFEBE0 447907CFEBF2     NEG.W $07CFEBF2
>

We are now at the third NEG, which operates on the value contained at address
‘data3’, which is zero. As you can see, the result is still zero,
because, correctly, the negative (and therefore the 2's complement) of zero is
still zero. As for the CCs, they are all reset except for Z:

D0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA7934
SSP=07CA8A67 USP=07CA7934 SR=8000 T1 -- PL=0 --Z-- PC=07CFEBE6
PC=07CFEBE6 447907CFEBF4     NEG.W $07CFEBF4
>

Now let's look at the last case. The value on which NEG operates this time is
$8000 = -32678. As you know, with 16 bits we CANNOT represent the value
+32678. Since in this case NEG operates on words, it cannot calculate
the result we are looking for correctly. When we execute it, we see that it
leaves the value contained at address ‘dato4’ UNCHANGED (i.e. at $8000)
and assigns the value 1 to the V (oVerflov) flag to signal the error:

D0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA7934
SSP=07CA8A67 USP=07CA7934 SR=801B T1 -- PL=0 XN-VC PC=07CFEBEC
PC=07CFEBEC 4E75         RTS
>

