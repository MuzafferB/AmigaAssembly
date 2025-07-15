
; Lesson 8p9.s    Condition Codes with 
;        shift instructions

SECTION    CondC,CODE

Start:
move.w    #$c003,d0
move.w    d0,d1
lsr.w    #1,d0
asr.w    #1,d1

move.w    #$6000,d0
move.w    d0,d1
lsl.w    #1,d0
asl.w    #1,d1
stop:
rts

end

In this example, we will discuss shift instructions, highlighting the
differences between arithmetic shift (ASx) and logical shift (LSx) instructions.
Let's start with right shift. Take the number $C003 and shift it
to the right by 1 place (which corresponds to dividing by 2). Let's start
with LSR:

D0: 0000C003 0000C003 03336222 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA4A64
SSP=07CA5B97 USP=07CA4A64 SR=8008 T1 -- PL=0 -N--- PC=07CA78A6
PC=07CA78A6 E248         LSR.W #1,D0
>

The LSR always interprets numbers as positive numbers.
Note that the number $C003 has become $6001, which is correct if
we assume it to be positive. Also note that the C flag has taken on the
value of the bit that came out on the right, in this case 1.

D0: 00006001 0000C003 03336222 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA4A64
SSP=07CA5B97 USP=07CA4A64 SR=8011 T1 -- PL=0 X---C PC=07CA78A8
PC=07CA78A8 E241         ASR.W #1,D1
>

The ASR, on the other hand, interprets numbers in 2's complement. In this case, therefore,
$C003 was interpreted as a negative number, and the result obtained
is $E001, which is correct in 2's complement notation, as you can
verify with the ASMONE ‘?’ command.

D0: 00006001 0000E001 03336222 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA4A64
SSP=07CA5B97 USP=07CA4A64 SR=8019 T1 -- PL=0 XN--C PC=07CA78AA
PC=07CA78AA 303C6000         MOVE.W #$6000,D0
>

Now let's look at the left shift, which ‘corresponds’ to multiplication.
Here too, there is the same difference between ASL and LSL. Let's first see how
LSL behaves:

D0: 00006000 00006000 03336222 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA4A64
SSP=07CA5B97 USP=07CA4A64 SR=8010 T1 -- PL=0 X---- PC=07CA78B0
PC=07CA78B0 E348         LSL.W #1,D0
>

As you can see, the result of shifting $6000 to the left is $C000, which is
correct if we interpret $C000 as a positive number. Let's see what
the ASL does instead

D0: 0000C000 00006000 03336222 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA4A64
SSP=07CA5B97 USP=07CA4A64 SR=8008 T1 -- PL=0 -N--- PC=07CA78B2
PC=07CA78B2 E341         ASL.W #1,D1
>

The result is still $C000. This is wrong if we interpret the numbers
in 2's complement. Why is this? If you convert $6000 to decimal and multiply it
by 2, you will see that the result is greater than 32767, and therefore cannot be
represented correctly in 2's complement notation. Note that ASL
signals this by setting the V flag to 1. This does not happen with LSL,
which always resets the V flag. This is the only (but important) difference
between the two left shift instructions.

D0: 0000C000 0000C000 03336222 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA4A64
SSP=07CA5B97 USP=07CA4A64 SR=800A T1 -- PL=0 -N-V- PC=07CA78B4
PC=07CA78B4 4E75         RTS
>

