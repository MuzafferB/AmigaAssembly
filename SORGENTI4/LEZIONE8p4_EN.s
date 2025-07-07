
; Lesson 8p4.s    Condition Codes with AND, NOT, OR, and EOR logical instructions
;        logical instructions AND, NOT, OR, EOR

SECTION    CiriCop,CODE

Start:
not.w    data1
not.w    data2
move.w    #$ff00,d0
and.w    data1,d0
move.w    #$0003,d0
and.w    data2,d0
move.w    #$8000,d0
or.w    data1,d0
move.w    #$8000,d0
eor.w    d0,data3
stop:
rts

data1:
dc.w    $ff00
data2:
dc.w    $0f00
data3:
dc.w    $c000

end

;    .----------.
;    ¦ \||/ ¦
;    ¦ (oo) ¦
;    `-oO-\/-Oo-'

Logic instructions modify the CCs in the same way as the MOVE
and TST instructions, i.e.:

The V and C flags are reset
The X flag is not modified
The Z flag takes the value 1 if the result of the operation is 0
The N flag takes the value 1 if the result of the operation is negative.

We can verify this by executing our program STEP BY STEP, in which
we present several examples.

D0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
 
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA1F14
 
SSP=07CA304B USP=07CA1F14 SR=0000 -- -- PL=0 ----- PC=07CA4AF4
PC=07CA4AF4 467907CA4B2A     NOT.W $07CA4B2A
>

The first instruction to be executed is NOT. The number $7CA4B2A is the address
‘data1’ (of course, you will see a different location!).

D0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
 
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA1F14
 
SSP=07CA3047 USP=07CA1F14 SR=8000 T1 -- PL=0 ----- PC=07CA4AFA
PC=07CA4AFA 467907CA4B2C    NOT.W $07CA4B2C
>

We can see the result of the operation with the command ‘M.W DATO1’ ,
and it is $00ff. (note: the command “m” can also be ‘m.w’ or ‘m.l’ to show
one word or one longword at a time).
This is a positive number other than zero, therefore the Z and N flags are
set to zero. Now let's perform the second NOT:

D0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA1F14
SSP=07CA3047 USP=07CA1F14 SR=8008 T1 -- PL=0 -N--- PC=07CA4B00
PC=07CA4B00 303CFF00         MOVE.W #$FF00,D0
>

This time, the result is negative (check the address DATA2)
and, in fact, the N flag is set. Now let's load a value into D0.

D0: 0000FF00 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA1F14
SSP=07CA3047 USP=07CA1F14 SR=8000 T1 -- PL=0 ----- PC=07CA4B04
PC=07CA4B04 C07907CA4B2A     AND.W $07CA4B2A,D0
>

And let's do the AND with the value ‘DATO1’

D0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA1F14
SSP=07CA3047 USP=07CA1F14 SR=8004 T1 -- PL=0 --Z-- PC=07CA4B0A
PC=07CA4B0A 303C0003         MOVE.W #$0003,D0
>

The result is zero, and therefore the Z flag takes the value 1.
Now we load a new value into D0 and do the AND with DATA2.

D0: 00000003 00000000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA1F14
SSP=07CA3047 USP=07CA1F14 SR=8000 T1 -- PL=0 ----- PC=07CA4B0E
PC=07CA4B0E C07907CA4B2C     AND.W $07CA4B2C,D0
>

This time we get a positive result, different from zero.
Now let's move on to OR. First, we load a negative value into D0.

D0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA1F14
SSP=07CA3047 USP=07CA1F14 SR=8000 T1 -- PL=0 ----- PC=07CA4B14
PC=07CA4B14 303C8000 MOVE.W #$8000,D0
>

Then we perform the OR with ‘DATO1’

D0: 00008000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA1F14
SSP=07CA3047 USP=07CA1F14 SR=8008 T1 -- PL=0 -N--- PC=07CA4B18
PC=07CA4B18 807907CA4B2A     OR.W $07CA4B2A,D0
>

As you can see, we obtain a value that is still negative, because the
most significant bit still has the value 1.

D0: 000080FF 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA1F14
SSP=07CA3047 USP=07CA1F14 SR=8008 T1 -- PL=0 -N--- PC=07CA4B1E
PC=07CA4B1E 303C8000         MOVE.W #$8000,D0
>

Now one last test. Let's load $8000 into D0 again:

D0: 00008000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA1F14
SSP=07CA3047 USP=07CA1F14 SR=8008 T1 -- PL=0 -N--- PC=07CA4B22
PC=07CA4B22 B17907CA4B2E     EOR.W D0,$07CA4B2E

And let's do the EOR with ‘DATO3’:

D0: 00008000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CA1F14
SSP=07CA3047 USP=07CA1F14 SR=8000 T1 -- PL=0 ----- PC=07CA4B28
PC=07CA4B28 4E75         RTS
>

This time we get a positive result that is not zero, as you can
see for yourself.

