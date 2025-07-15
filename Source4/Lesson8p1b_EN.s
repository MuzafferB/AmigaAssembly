
; Lesson 8p1b.s        Condition Codes with MULU/MULS

SECTION    CondC,CODE

;     oO 
;     C _
;    \__/
;     U

Start:
move.l    #$0003,d0    ; A ‘moveq #3,d0’ would be faster...
move.l    #$c000,d1
muls.w    d0,d1

moveq    #3,d0        ; Here we used it... oh well!
move.l    #$c000,d1
mulu.w    d0,d1
stop:
rts

end

Let's now look at an example of how to use multiplication instructions.
The 68000 provides us with two different multiplication instructions:
MULS multiplies two numbers considering them as numbers in two's complement,
while MULU always considers the numbers to be multiplied as positive.
Muls/Divs work with numbers in two's complement, while Mulu/Divu use
unsigned numbers.

MULU <ea>,Dn Source=Data Destination=Dn
MULS <ea>,Dn Source=Data Destination=Dn

Only 16-bit numbers (in word format) can be multiplied, and
the 32-bit product (longword format) is provided in a data register.
Obviously, the results obtained with MULU or MULS are very different.
Let's take an example by multiplying $c000 by $0003.

D0: 00000003 0000C000 00000000 00000000 00000000 00000000 00000000 00000000
 
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07D32154
 
SSP=07D33287 USP=07D32154 SR=8000 T1 -- PL=0 ----- PC=07D34CEC
PC=07D34CEC C3C0         MULS.W D0,D1
>

MULS considers $c000 as a negative number.
The result obtained is as follows:

D0: 00000003 FFFF4000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07D32154
SSP=07D33287 USP=07D32154 SR=8008 T1 -- PL=0 -N--- PC=07D34CEE
PC=07D34CEE 203C00000003     MOVE.L #$00000003,D0
>

The result is negative (because we multiplied a positive number by
a negative number) and therefore the N flag is 1.
For those who don't know, if you multiply two positive numbers, the
result is positive, and similarly, if you multiply two negative numbers
, the result is positive. However, if you multiply a negative number
by a positive number, or a positive number by a negative number, the result is negative.
In summary:     + * + = + - * - = + + * - = - - * + = -
Let's now see how the MULU behaves, which considers $c000 as a positive number
.

D0: 00000003 0000C000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07D32154
SSP=07D33287 USP=07D32154 SR=8000 T1 -- PL=0 ----- PC=07D34CFA
PC=07D34CFA C2C0         MULU.W D0,D1
>

The result obtained is as follows:

D0: 00000003 00024000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07D32154
SSP=07D33287 USP=07D32154 SR=8000 T1 -- PL=0 ----- PC=07D34CFC
PC=07D34CFC 4E75         RTS
>

As you can see, it is very different. Among other things, it is positive, and in fact
the N flag is 0. Therefore, even for multiplications, you must
carefully choose the instruction to use.

