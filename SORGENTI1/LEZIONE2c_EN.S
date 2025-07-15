
; Lesson 2c.s

Start:
	LEA    	  DOG,a0
	MOVE.L    #DOG,a1
	MOVE.L    DOG,a2
	move.l    a0,CAT1
	move.l    a1,CAT2
	move.l    a2,CAT3
	rts

DOG:
	dc.l    $12345678

CAT1:
	dc.l    0

CAT2:
	dc.l    0

CAT3:
	dc.l    0

	END

Assemble, press D Start to check which addresses the labels are allocated to, 
then execute with J. You will already see that after the J, the
register list shows negative numbers, specifically:

D0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
A0: NUMBER NUMBER 12345678 00000000 00000000 00000000 00000000 NUMBER (SP)
SSP= ..... USP= SR.....

Each time a listing is performed, all registers are displayed
: the first row is D0, D1, D2, D3, D4, D5, D6, D7, the second
row is a0, a1, a2, a3, a4, a5, a6, a7.
Below are other registers that we will discuss later. The number in A7
is the current SP, which is not important at this point. Instead, check the
numbers in A0, A1 and A2: the first two are the same numbers, in this case
the address of DOG:, in fact the two instructions:

LEA    DOG,a0        ; faster than MOVE.L #DOG,A1! do it like this!
MOVE.L    #DOG,a1

They do the same thing, i.e. copy the address of the label into a register.
In A2, on the other hand, we read 12345678, which is the content of the longword DOG:
in fact, the instruction MOVE.L DOG,a2 puts the content of the long DOG in a2.
As a further check, check after the J with an M DOG, and you will see
that DOG is in the same location as it appears in a0 and a1; after that, you can
also check with M CAT1 and M CAT2 that these two longwords contain
the address of cat, in fact it is copied with these two instructions:

move.l    a0,CAT1
move.l    a1,CAT2

Finally, with M CAT3, you will verify that it contains the content of the long
CAT, i.e. $12345678.
To perform these three checks in one go, you can type m cat1 and
press the return key (or enter or ‘A CAPO!’) several times: you will obtain
the address of DOG in the first four bytes, the same address in the next four bytes,
and the content .L of dog, i.e. $12345678, in the next four bytes. Continuing, you
will see numbers that have nothing to do with anything; in fact, you are seeing a part
of memory that is empty or occupied by who knows what.
If you want to make some changes, you can add, for example, before the RTS
these lines:

MOVE.L    A0,D0
MOVE.L    A1,D1
MOVE.L    A2,D2

You will then see a change in the first three DATA registers in the register list after the J.
NOTE 1: As you have seen, using LEA is better than MOVE.L #lab,a0, but
be careful! The lea command can only be used to put a
value in the address registers! You cannot do LEA LABEL,d0, for example!!!!
To put the address of a label in a data register or in another long
memory location, you must use MOVE.L #LABEL,destination!!!!
NOTE2: Usually, addresses are placed in registers a0, a1, a2... and
various data is placed in registers d0, d1, d2, d3..., but often addresses are placed
in data registers (d0, d1...) or data in address registers (a0, a1, a2...),
depending on the situation. 
In short, to give you an idea of how they are used,
they are used like a notepad where you keep a certain number
of phone numbers or where you write down how much you spent on ice cream, 
so they are useful and QUICK longwords that can
be used at will, just remember what you put there!!!!!
