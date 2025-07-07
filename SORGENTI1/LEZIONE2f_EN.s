
; Lesson 2f.s

Start:
lea    START,a0    ; put the address where to start in a0
; i.e. the address of START goes in a0, i.e.
; WHERE START is located, not what it contains!
lea    THEEND,a1    ; put the address where to end in a1
; i.e. put the address of the end of the
; 40 bytes, because it is BELOW 40 bytes.
; Now, EVERYTHING BETWEEN the label
; START: and the LABEL THEEND: will be cleared
; by LOOP CLELOOP:, whether it is 40 bytes
; or more, even if you put
; instructions there.

CLELOOP:
clr.l    (a0)+    ; Reset the long in (a0), then add 4 to a0 (long!)
; WARNING! This is indirect addressing,
; in which the a0 register is not cleared, but the
; contents of the address, i.e. 4 $FE at a time,
; ($fe is a random number that I have put in just
; as an example to distinguish it from the zeros! to show
; that I am clearing an area filled with $FE;
; since there is a + after the parentheses, each time
; it is executed, the value of a0 increases by 4, i.e.
; it moves to the next address to be cleared)
; (In the first step, the first 4
; $FE under start are cleared, in the second step the next 4
; and so on). Note that only a0 increases,
; while a1 remains at the address THEEND.
cmp.l    a0,a1    ; Is a0 equal to a1? In other words, are we at the THEEND address?
; (In fact, a0 increases by 4 each cycle, and we stop the
; cycle when a0 reaches the THEEND address)
bne.s    CLELOOP    ; If not, return to execute CLELOOP...
rts        ; EXIT the program and return to ASMONE

START:
dcb.b    40,$fe    ; The DCB command is used to store a
; defined number of bytes, words or longs that are equal to
; each other: similar to the DC.B command, in which
; in this case we would have had to do dc.b $fe,$fe,$fe...
; putting 40 $fe. Instead, with the dcb command, we can
; simply do dcb.b 40,$fe, i.e.
; PUT 40 bytes $fe INTO MEMORY.
THEEND:        ; this label marks the end of the 40 bytes...

dcb.b    10,0    ; let's put 10 bytes here just for fun

end

Warning! With LEA START,a0, a0 contains the address of the first of the 40 bytes
$fe, and does not contain the 40 bytes!!! LABEL is a convention used in
programming to navigate the listing. It is used to give a name
to the various parts of the program, whether they are instructions or something else. Then, by referring
to that LABEL, we refer to THE EXACT POINT WHERE THE LABEL IS PLACED, i.e.
the address where the label is located.
 To avoid confusion, imagine why LABELS were invented: if they did not exist, we would have to
number each byte, i.e. think in terms of addresses. For example, instead of
writing BNE.S CLELOOP, we would have to write BNE.S $20398, for
example, i.e. write the starting address of the loop, i.e. where
clr.l (a0)+ was located. Similarly, instead of writing LEA START,a0, we would have
had to write lea $123456,a0, i.e. the address from which to start cleaning.
Imagine if we had inserted an extra instruction in the cycle! In
this case, START would have moved forward, and we would have had to rewrite
the exact number in LEA $123456,a0, i.e. in LEA START,a0. Instead, by giving a
name to each POINT IN THE PROGRAM, just as you name a river, you indicate
with that name the starting address of that thing (AND NOT ITS CONTENTS!
IF I DO LEA START,A0, the contents of start do not go to A0! But where do they go?).
During assembly, the assembler takes care of arranging all the
labels and replacing them with the addresses they represent.
This little program cleans up from the address put in a0 to
the address we put in a1: to check this, assemble with A and
do M START (before doing j) to check that they have been put in that
point of the consecutive $fe; as a further check, do D Start, and you will notice
that the same number that appears next to the first LINE_F is placed in a0,
i.e. the address of the first $FE that is interpreted as LINE_F by
ASMONE, while the address of THEEND is placed in a1, i.e. as you can
see the end of the $FEFE and the beginning of the 00000000. Now run J:
if you press D START, you can check that the bytes have been reset (and are now
interpreted as ORI.B #$0,d0). You can check this in the same way with M START.
You can also check that A0 and A1 have the same value.
NOW I WILL TEACH YOU A VERY NICE ASMONE UTILITY TO CHECK THE
FUNCTIONING OF YOUR PROGRAMS:
instead of doing A, try doing AD!!!!!
This way, after assembling, you will enter the DEBUGGER!!!!
STAY CALM AND KEEP A COOL HEAD: the source code will appear as you wrote it,
and on the right-hand side you will see all the registers appearing in
a column one below the other: d0, d1, d2..a0, a1, a2.. etc.
You will notice that the first line of the listing, in this case START,a0, is
written in negative: this indicates that we are on that line. Now you can
check the execution of the program instruction by instruction, verifying
what happens in the registers! In the last line at the bottom, you can see the instructions
disassembled as with the D command, one at a time, with the address on the far
left, followed by the instruction in BYTES format, followed by the instruction
in COMMAND format (e.g. CLR.L (a0)+, which you will see is $4298 in bytes).
To execute one instruction at a time and move on to the next, just press
the key that moves the cursor forward, the one with the arrow pointing
to the right: you will notice that after executing the first instruction,
the START address will be placed in a0, while after the second one,
the THEEND address will be loaded; going down the loop, you will notice that a0
will be increased by 4 each time and that it will return to CLELOOP
after the BNE until a0 reaches the value of a1.
Once you reach the RTS at the end, or even before if you wish, you can
exit the debugger with the ESC key.
If you count the number of times CLR.L (a0)+ is executed, you will see that
it is executed 10 times. In fact, to clear 40 bytes one long at a time,
i.e. 4 bytes at a time, 10 passes are required (10*4=40).
Try changing CLR.L (a0)+ to CLR.W (a0)+ and you will notice that 20 steps are
required (in fact, 20*2=40) and that each time a0 is increased
by 2, while replacing it with CLR.B (a0)+ will require 40 steps and the
a0 register will be incremented by 1 each time.
To check, reload the listings seen so far and follow them
step by step with the AD command.
NOTE: the debugger cannot be used for all programs, because
those that disable the operating system also disable the debugger!

To make sure that everything between the START:
and THEEND: labels is cleared, whether it is 40 bytes, 200 bytes or more, try
making this change:

START:
dcb.b    80,$fe    ; PUT 80 bytes $fe IN MEMORY HERE.

THEEND:        ; this label marks the end of the 80 bytes...

If you do the same steps with AD, you will notice that twice as many
cycles are performed, because the distance between START and THEEND has doubled.
In fact, imagine that the program is a street, where START corresponds
to house number 10... in the first case there are 40 bytes between them, so
THEEND would be the equivalent of house number 50 (10+40), and if the inhabitant
at START wants to visit his friend at THEEND, he has to take 40 steps
1 byte long. If, on the other hand, START still represents the number 10, but his friend
THEEND has moved 80 bytes away instead of 40, he will be
at address 90, and the friend START will have to take
80 steps of one byte to reach him.
