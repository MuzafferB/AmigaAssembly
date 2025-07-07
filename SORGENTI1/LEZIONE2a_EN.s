
; Lesson 2a.s - This little program records in the byte named
; ‘counter’ the number of times the right key is pressed, or rather
; how long it has been pressed, because when it is held down, it is continuously
; incremented; to exit, press the left key.

Start:
btst    #2,$dff016	; POTINP - right mouse button pressed?
beq.s    add    ; if yes, go to ‘add’
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    start        ; if no, go back to Start and repeat everything
rts            ; if yes, EXIT!

add:
move.b    counter,$dff180 ; put the value of COUNTER in COLOR0
addq.b    #1,counter    ; Add 1 to the value of counter
bra.s    start        ; go back to start and repeat

counter:
dc.b    0        ; this is the byte that will keep count...

END    ; END determines the end of the listing; the words
; below END are not considered, as if they were all
; preceded by ; (semicolon)

;NOTE: POTINP is the name of the register $dff016. The name in capital letters after
; the semicolon always refers to the name of the register $dffxxx
;In this listing, you can see the use of labels both to represent
;instructions (bne.s start, bra.s start) and to represent a byte
;of data (addq.b #1, counter). There is no difference between the label Start:
;and the label counter:, they are both labels, i.e. NAMES THAT IDENTIFY A
;POINT IN THE PROGRAM, WHETHER IT IS A BYTE, A MOVE OR ANYTHING ELSE,
;WHICH IS USED TO EXECUTE THE INSTRUCTIONS BELOW IT, WHEN IT PRECEDES
;INSTRUCTIONS (A BNE LABEL WILL BE USED, FOR EXAMPLE), OR TO READ/WRITE THE
;BYTE, WORD OR LONGWORD THAT PRECEDES IT. I have noticed that many people find
;it difficult to understand this logic. Let's look at some examples to clarify
;the role of LABELS: imagine you have a small rectangular vegetable garden
with a path running through the middle. After digging it over,
 you decide to sow strawberries, lettuce, basil and
parsley, so you divide it into four rectangles of different sizes and
sow the seeds. To know where the different vegetables will start to grow, you
;you often use those plastic labels with a tip that you insert into the
;soil, you know the ones? So let's plant them: the vegetable garden now has four labels
;sticking out of the ground, each with the name of the vegetable written on it: on
;one we will find STRAWBERRIES:, on another SALAD:, then BASIL: and PARSLEY:.
;Note that we have placed the labels where one type of vegetable begins
;and, consequently, where the previous one ends:
;
;
;STRAWBERRIES:    LETTUCE:    BASIL:    PARSLEY:
; \/         \/         \/         \/
; ................oooooooooooooooooo^^^^^^^^^^^^^^^^^^_-_-_-_-_-_-_-_-_-_-_-_
;
;
;If you consider strawberries as ‘......’, salad as “ooooo”,
;basil as ‘^^^^^^^’ and parsley as ‘-_-_-_-_’, you will notice
;that when I write ‘GO TO SALAD’, I mean GO TO THE SALAD LABEL, not
‘throw yourself into the salad’ or ‘go towards the salad’, but
‘GO TO THE LABEL STUCK IN THE GROUND THAT SAYS SALAD,
AND FOLLOW THE INSTRUCTIONS AFTER IT’, in which case you would execute the ‘oooo’.
;If you use the label in this way:
;
;    addq.b    #1,BASIL
;
;All I do is add 1 seed in the first byte after THE LABEL, which
;has not changed function! It does not indicate content or other oddities!!! It always indicates
;a point in the memory, i.e. in the listing, which is the beginning of the basil.
;Let's try a MOVE.B STRAWBERRIES,BASIL
;
;STRAWBERRIES:    SALAD:    BASIL:    PARSLEY:
\/         \/         \/         \/
................oooooooooooooooooo.^^^^^^^^^^^^^^^^^_-_-_-_-_-_-_-_-_-_-_-_

|                 |
\--> ----> ----> ----> ----> --->

As you will notice, a ‘.’, i.e. the byte after strawberries, has been copied to the byte
after BASIL: Let's now try a MOVE.W SALAD, STRAWBERRIES

STRAWBERRIES:    SALAD:    BASIL:    PARSLEY:
\/         \/         \/         \/
oo..............oooooooooooooooooo.^^^^^^^^^^^^^^^^^_-_-_-_-_-_-_-_-_-_-_-_

|| ||
\<--- <--- <---/

We have moved the first 2 ‘oo’ that were after INSATATA: to the first 2 bytes
after FRAGOLE:

If you want to read or write from a point between the LABELS, simply
add another one where you want it: to put 4 bytes of INSALATA
in the centre of basilico, we need to create a new LABEL called BAS2: in the
pre-established point, after which we will do a MOVE.L INSALATA,BAS2


Before:

STRAWBERRIES:    SALAD:    BASIL: BAS2:    PARSLEY:
\/         \/         \/     \/     \/
oo..............oooooooooooooooooo.^^^^^^^^^^^^^^^^^_-_-_-_-_-_-_-_-_-_-_


After:

STRAWBERRIES:    SALAD:    BASIL: BAS2:    PARSLEY:
\/         \/         \/     \/     \/
oo..............oooooooooooooooooo.^^^^^^^oooo^^^^^^_-_-_-_-_-_-_-_-_-_-_

||||             ||||
\ ----> ----> ----> -----> /

We have moved the first 4 bytes that were after SALAD: to the first 4
bytes after BAS2:

The operation is the same as the move that occurs using real addresses,
 as already explained in LESSON 1 (DOG CAT>NEW DOG), except that
instead of operating with addresses, where each seed has an address,
labels are only placed on the addresses that are of interest:

Using addresses:

STRAWBERRIES:    SALAD:    BASIL:    PARSLEY:
\/         \/         \/         \/
................oooooooooooooooooo^^^^^^^^^^^^^^^^^^_-_-_-_-_-_-_-_-_-_-_-_
123456789012345678901234567890123456789012345678901234567890123456789012345
1111111111222222222233333333334444444444555555555666666

By moving the addresses, you can copy 4 bytes of salad from each
position, for example from no. 15, and put it in no. 55: MOVE.L 15,55


STRAWBERRIES:    SALAD:    BASIL:    PARSLEY:
\/         \/         \/         \/
................oooooooooooooooooo^^^^^^^^^^^^^^^^^^_-_-_-_-_-_-oooo_-_-_-_
123456789012345678901234567890123456789012345678901234567890123456789012345
1111111111222222222233333333334444444444555555555666666
\--> ---> ---> ---> ---> ---> ---> --->/

The same operation can be performed by placing a label at position 15
and another at position 55, then doing ‘move.l LABEL1, LABEL2’

LABEL1:                    LABEL2:
\/                     \/
................oooooooooooooooooo^^^^^^^^^^^^^^^^^^_-_-_-_-_-_-oooo_-_-_-_
\---> ---> ---> ---> ---> ---> ---> --->/

Why was it preferable to use LABELS rather than addresses?
SIMPLE! Because if we had used addresses and inserted something
between the lettuce and the basil, the destination would no longer have been 55,
but another number, for example 80, and we would have had to change all the
numbers, moving them forward to fit in the new piece we had inserted.
Instead, with labels, if we insert something between them, there are no
changes, because ASMONE calculates the address of the
label each time.

Try running this program, the first time without pressing the right key,
but only the left key to exit: the CONTATORE byte in this case is
remained 0, as can be verified with the M command, which displays the actual values
contained in the memory addresses in hexadecimal byte format
(indicated by the location number, for example M $50000, or
the name of a label): doing M counter will give a ZERO, followed
by other numbers that will correspond to the following bytes in memory that are not
of interest to us. (to advance in memory, press return several times; to exit,
 press the ESC key - the bytes are obviously in HEX format)
Reassemble with A and run it a second time, this
time pressing the right mouse button before exiting (with the left button): repeating
‘M counter’ will give a number other than zero, which will correspond
to the number of cycles in which the right mouse button was pressed, in fact
the cycle is executed very quickly by the processor and even pressing the
right button for an instant will result in numbers greater than 1.
It should be noted that the counter in question is one byte long, so it can
reach a maximum value of 255, i.e. $FF, i.e. %11111111 in binary,
i.e. all eight bits that make up the ON byte (1), after which the number
will start again from zero (if you continue to add). ($ff+1 = 0, $ff+2 = 1...)
The advantage of this little program over the first one is that the structure
of the conditional jumps is more complex (and please don't go on
until you understand it!), and a byte is used as a variable.
This byte, called CONTATORE, is not only written, but also read
to write its value in $dff180, i.e. COLOR0: From this, you can see how
many VARIABLES can be managed, i.e. bytes, words or longwords in
which numbers useful to the program are written and read, for example the number
of PLAYER 1's lives, his energy, his points, etc.
The use of LABELS is useful to the programmer, but once the program is
assembled, it becomes a series of bytes, which, when read by the 68000,
 are interpreted as instructions that refer to direct addresses:
to verify this, assemble the program and press D Start...
The assembled program will be displayed in memory in its true
form, where the ACTUAL addresses appear instead of the labels: as
you can see, the first column of numbers on the left are the memory addresses
where we are reading, the second column of numbers are the commands
in their REAL form in memory, i.e. sequences of bytes (for example, the
first line BTST #2,$dff016 in memory becomes 0839000200dff016, where
$0839 means BTST, 0002 is #2, 00dff016 is the address concerned)...
The third column, on the right, shows the DISASSEMBLED code, i.e. it does the
opposite of what it does when assembling: it transforms BYTES into INSTRUCTIONS (when you
press A (assemble), instructions are transformed from the format MOVE, ADD,
BNE, BTST... into BYTES). As you read, you will immediately notice that the labels are replaced
by the actual addresses where routines or variables are located.
As a further check that the instructions become precise numbers,
 replace the line:

btst    #2,$dff016    ; POTINP - right mouse button pressed?

With the equivalent line:

dc.l    $08390002,$00dff016

or

dc.w    $0839,$0002,$00df,$f016

or

dc.b    $08,$39,$00,$02,$00,$df,$f0,$16

In all cases, the result is 0839000200dff016 in memory, which the 68000
interprets as ‘btst #2,$dff016’, i.e. ‘is bit 2 of $dff016 zero?’.

If the variable had been a WORD instead of a BYTE, the listing would have to be modified as follows:
Start: btst    #2,$dff016    ; POTINP - right mouse button pressed?

Start:
btst    #2,$dff016    ; POTINP - right mouse button pressed?
beq.s    add    ; if yes, go to ‘add’
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    start        ; if not, go back to Start and repeat everything
rts            ; if yes, EXIT!

add:
move.w    counter,$dff180 ; COLOR0 - Use .w instead of .b
addq.W    #1,counter    ; use ADDQ.W instead of ADDQ.B!!!
bra.s    start

counter:
dc.W    0        ; dc.w instead of dc.b (the same as dc.b 0,0)

In this case, the maximum number that can be contained by a word before it starts
over again is $FFFF, i.e. 65535, i.e. %1111111111111111.

If you wanted to use a LONGWORD for COUNTER:, the maximum number before
resetting would be $FFFFFFFF, i.e. a few billion, but you have to
consider that the high bit (i.e. the thirty-first in the case of the longword)
is used for the sign of the number: try ?$0FFFFFFF and you will get
268 million and change, and in binary you can see that the four highest bits
of the number (i.e. the first four after the %) are zero. The maximum positive number
that can be obtained is $7FFFFFFF, i.e. in binary:
;10987654321098765432109876543210    ; number of bits from 0 to 31
%01111111111111111111111111111111
In fact, bit 31 (which would be the thirty-second, but is the thirty-first because
zero also counts) is ZERO, while the others are all 1.
If you do ?$7FFFFFFF+1, you get -2 billion and change, and as you
increase the number, it approaches zero (-1 billion, -100 million, -10, etc.).
In fact, if you do -1, you get $FFFFFFFF, while -2 gives you $FFFFFFFE.

This system of using the high bit as a sign can also be used for
bytes and words: for bytes, a move.b #-1,$50000 can also be written as
move.b $FF,$50000 so the maximum positive number would become:
%01111111 , i.e. $7f, 127. For words, the maximum positive number becomes
%0111111111111111, i.e. $7FFF, i.e. 32767. However, depending on how
the programme is written, the numbers can be used as positive and negative numbers
or as absolute numbers.

Try changing the listing so that CONTATORE: is a word, as
described above: You can use the ASMONE editor functions, the
so-called CUT and PASTE: to ‘cut’ a piece of text and
copy it to another place, press the right Amiga key + b
at the beginning of the text you want to copy; in this case, select
the modified source in WORD under the line “be modified as follows:”
by positioning yourself above the label Start: and pressing Amiga+b. Now
you can select the block (which will appear in negative), moving
down with the cursor. Once you are under Dc.W 0, press Amiga+c, and the piece of
text including the listing will go into memory. Now go to the top of the
listing by pressing CURSOR UP+SHIFT, and press Amiga+i ...
Magically, a copy of the text you selected earlier will appear.
At this point, just put an END (spaced from the beginning of the line with
spaces, or better with a TAB) under DC.W 0 to exclude the first
source with COUNTER: one byte long. Assemble and jump.

P.S: Don't worry about the string of numbers, sometimes highlighted,
that appear after each ‘J’; their meaning will be explained later.

You will immediately notice the difference in the screen flashing when you press
the right key; try doing an M COUNTER now:
it is now a WORD, so the first 2 pairs of numbers will be valid,
i.e. the first 2 bytes.If, for example, 00 30 appears, it means that
the ADDQ.W #1,COUNTER has been executed $30 times, i.e. 48 times; a value
of 02 5e would mean $25e times, i.e. 606 times.

If you are not familiar with text editors, try CUT AND PASTE
by copying and pasting parts of this text here and there, and bear in mind that
once you have selected a block with Amiga+b, instead of copying it to memory
with Amiga+c, press Amiga+x and the selected block will also be deleted, but
by pressing Amiga+i you can reinsert it elsewhere. I assure you that
programming is all about CUT and PASTE, as this trick allows you
to save time rewriting similar parts of the program, which
can instead be copied and modified quickly.

You need to be well versed in binary numbering to be able to work, as
many hardware registers are also BITMAPPED, i.e. each bit corresponds to
a function. Here is a table to clarify the difference:

HEXadecimal BINARY DECIMAL
0 %00000 0
1
2
3
4
5
6
7
8
9
$A
$B
$C
$D
$E %01110 14
$F %01111 15
$10 %10000 16
$11 %10001 17
$12 %10010 18
...

As you can see, the binary follows a simple logic of filling with 1s until
you reach 11, 111, 1111, 11111, 111111, etc., i.e. until
the following digit appears: after %011 there is %0100, after %0111 there is %01000,
after %01111 there is %010000, after %011111 there is %0100000 and so on.
It should be remembered that numbers in hexadecimal format are preceded by the
dollar sign $, while binary numbers are preceded by the percent sign %
.
Numbers in normal decimal format, on the other hand, must not be preceded by
any sign. For example, if we write 9 or $9, we always mean 9, but if
we write 10 or $10, we mean 10 in decimal or 16 in hexadecimal!
So remember that after 9, one more or one less $ changes everything.
It is not important to know how to convert numbers by heart, as this is not necessary because
you can use the “?” command to perform any operation or conversion.
In fact, the result is given in all formats: decimal, hexadecimal, binary
and ASCII, i.e. in the form of CHARACTERS. In fact, characters such as ‘abcd’ are
nothing more than bytes, which, according to the ASCII standard, which is similar in various computers,
 correspond to certain characters, for example “a” = $61, while ‘A’ = $41.
You can check this by typing ?‘a’ or ?$61 from the command line.

NOTE: .s in BNE means SHORT (equivalent to .b)
instead of .s, or .w when the label it refers to is further away.
Always try to put .s in BNE, and you will see that if the label indicated
after beq.s or bne.s is too far away (more than 127 bytes), it is corrected
by the assembler to .w. To check this, make the following change:

Start:
btst    #2,$dff016    ; POTINP - right mouse button pressed?
beq.s    add    ; if yes, go to ‘add’
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    start        ; if not, go back to Start and repeat everything
rts            ; if yes, EXIT!

dcb.b    200,0        ; this directive will be explained
; later, in this case it puts 200
; bytes $00 in memory, increasing the distance
; between the labels Start: and add:

add:
move.b    counter,$dff180 ; put the value of COUNTER in COLOR0
addq.b    #1,counter    ; Add 1 to the value of counter
bra.s    start        ; go back to start and repeat

When assembling, you will see that the assembler reports FORCED TO WORD SIZE,
in fact it has FORCED TO WORD the bne.s, right in the listing, because the distance
between Start: and add: was greater than 128. I recommend always putting
.s after bra, bsr, beq, bne and similar, the assembler will correct it when
necessary. You can also always put .w, but .s instructions are faster
and take up fewer bytes. To return to the concept of LABEL discussed earlier,
this dcb.b 200,0 inserted is a clear example of the usefulness of
LABEL, which saved us from rewriting the new position taken by
add:, i.e. 200 bytes further on.

