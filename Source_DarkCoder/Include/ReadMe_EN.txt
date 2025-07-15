____ ___ _____ ___ ___ ___ ___
(_, V ), . \|, ~] |(___)| |
..-----|o |o | )o 7o | \o /o| |------. ^ ^ ^ ^ ^
| ___|___Y___|_____/|___!_____/___L____|____ | +----------------------+
| ( , ! )___)/,___)(___), . \|, \ \/,___) | |Feel the DEATH inside!|
`--\o /|o (___ \|o |o | )o )__ \-' `----------------------'
.p.\___/ |___(______)___!_____/|___!___|_____) v v v v v

WHQ: Extrema +39-861-413362
IHQ: DoWn ToWn +39-2-48000352


All material in this directory is ***COPYDEATH*** Morbid
Visions. Morbid Visions (or any of the authors) assume no
responsibility for any damage, direct or indirect, caused by the use
of the above material, including the burning of your monitor!

NOTES ON THE SOURCE CODE
The sources were written for ASM-One 1.29 by T.F.A. All sources
begin with an INCDIR ‘Infamia:MV_Code/’. To assemble, it is therefore
necessary to execute ‘ASSIGN INFAMIA:’ in the directory containing the
MV_Code directory, or you must modify the INCDIRs in the sources. All
sources use the same startup code, contained in the
MVStartup.S file. This is a VERY simple startup code for testing purposes only.
 Do not use it for your demos!

In the sources, we use the Dark Rules established by the Dark Texts
of Deadly Coding, the books that express the coding philosophy
of Morbid Visions. To make it easier to read for those who are used to the source code from Randy's
course, we list some of the Dark Rules that differ from the
conventions followed in the course:

- The size of operands is only indicated when it is different
from the default. (Remember that by default, if the size is not specified
, ASMOne assumes that the size is WORD, except for
those fixed-size instructions, such as Scc (which has size BYTE),
BTST (which has size BYTE if the destination is in memory and LONG if
the destination is a register), etc.
For example:
move    d0,d1        indicates        move.w    d0,d1
btst    #6,$bfe001    indicates        btst.b    #6,$bfe001.
btst    #14,d0        indicates        btst.l    #14,d0
lea    label,a0    indicates        lea.l    label,a0).

- The double blitter wait test is NOT performed: to wait for
the blitter, we perform a simple:

.wait
btst    #6,dmaconr(a5)        ;wait for the blitter
bne.s    .wait

The famous Agnus BUG is present only in very few units assembled
on the first A1000s, and it also occurs in special circumstances.
This BUG has become commonplace, but in reality no one has
ever seen it. The tests we performed on The Hobbit / MV's A1000
did not find the BUG. ALL of our OCS routines work on
ALL Amiga OCS computers WITHOUT the double test. Now that even the AGA era
is coming to an end, there is no point in carrying around these useless additional BTSTs
that spoil the aesthetics of the source code.

- Local MACROs and labels are often used, which make the code more
orderly and readable.

Morbid Visions
