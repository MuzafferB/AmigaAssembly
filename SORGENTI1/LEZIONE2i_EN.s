
; Lesson 2i.s

Start:
	lea    $dff000,a0    ; put $dff000 in a0
Waitmouse:
	move.w    6(a0),$180(a0)    ; put the .w value of $dff006 in colour 0
								; 6(a0)=$dff000+6, $180(a0)=$dff000+$180
	btst    #6,$bfe001    ; left mouse button pressed?
	bne.s    Waitmouse    ; if not, return to waitmouse and repeat everything
	rts            ; exit

	END

In this variation of the first listing, there are addressing distances: 
the address $dff000 is placed in a0 (in this case, it is chosen because it is 
even and when addressing distances are made
it is possible to recognise which addresses are being referred to:
for example, colour 0, i.e. $dff180, can be reached with $180(a0), and 
it is clear that this is $dff180. If, for example, you had put
the address $dff013 in a0 to indicate colour0, the correct addressing distance
would have been $16d(a0), because $dff013+$16d=$dff180).
Note that the a0 register is never changed, it always remains
$dff000, and each time the processor calculates which address we are referring to
by adding the addressing distance to the address in a0.
In almost all programs that use graphics, the address $dff000 is
placed in some register to make the addressing distance (or OFFSET),
in fact, in this way, all CUSTOM registers can be reached
(which end at $dff1fe).
You can specify an offset from -32768 to +32767, i.e. from -$8000
to $7FFF.

NOTE:
be careful of the difference between LEA and MOVE when
using an addressing distance:

MOVE.L    $100(a0),a1

Copies the longword CONTAINED in the address that is $100 bytes ahead of the one
in a0, into register a1. THEREFORE: "ADD THE ADDRESS
IN A0 AND THE NUMBER BEFORE THE BRACKETS; THE RESULT IS THE ADDRESS FROM WHICH
THE LONGWORD IN A1 WILL BE COPIED".

while:

LEA    $100(a0),a1

Puts in a1 the address resulting from the sum of a0+$100, not its content
in fact, the LEA command is only used to load ADDRESSES, not CONTENTS.

Let's take an example to clarify: consider memory addresses as
the addresses of a long sunny street with many houses in a row, each
with a house number. If we put the address 0, i.e. the address of the
first house, in a0 with the instruction MOVE.L $100(a0),a1, all we are doing is putting
the carpet and furniture from the entrance of house no. 100 in a1, i.e. we are copying
its CONTENTS for the length of a longword in a1.
Instead, with LEA $100(a0),a1, we put the address of house $100 in a1 without
entering it. The difference is that with MOVE in a1 we put the furniture,
while with lea we put the address.
 By CONTENTS I mean what is in the addresses, in fact in every address 
 (every house) there is always something: it can
be a number (when there is furniture) or it can be empty (when the
house is abandoned, but from which you can still take ZERO ($00)).

For example, the instruction

LEA    $100(a1),a1

is equivalent to the instruction:

ADD.W    #$100,a1

Because the address in a1+$100 is placed in a1.

NOTE: you can write the addressing distances in decimal or
hexadecimal (with the $ symbol) as you wish, and you can also add
multiplications or divisions, etc.:

lea    $10*3(a1),a2    ; i.e. LEA $30(a1),a2 will be assembled
; in fact, * means MULTIPLY

