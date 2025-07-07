
; Lesson 3b.s    ; THE FIRST COPPERLIST


SECTION    PRIMOCOP,CODE    ; This command loads this part of the code from the operating system
; into FAST RAM, if it is free, or if there is only CHIP, it loads it into CHIP.
; Execbase in a6 jsr
-$78(a6)    ; Disable - stops multitasking

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
lea    GfxName,a1    ; Address of the name of the lib to open in a1
jsr    -$198(a6)    ; OpenLibrary, EXEC routine that opens
; the libraries, and outputs the
; base address of the library from which to calculate
; the addressing distances (Offset)
move.l    d0,GfxBase    ; save the GFX base address in GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the address of the system copperlist
(always at $26 of GfxBase)
move.l    #COPPERLIST,$dff080    ; COP1LC - Point to our COP
move.w    d0,$dff088        ; COPJMP1 - Start the COP
mouse:
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse        ; if not, return to mouse:

move.l    OldCop(PC),$dff080    ; COP1LC - Point to the system COP
move.w    d0,$dff088		; COPJMP1 - start the cop

move.l    4.w,a6
jsr    -$7e(a6)    ; Enable - re-enable Multitasking
move.l    gfxbase(PC),a1    ; Base of the library to close
; (libraries must be opened and closed!!!)
jsr    -$19e(a6)    ; Closelibrary - close the graphics library
rts

GfxName:
dc.b    ‘graphics.library’,0,0    ; NOTE: to store
; characters in memory, always use dc.b
; and place them between ‘’, or “”
; ending with ,0


GfxBase:        ; This is where the base address for the Offsets goes
dc.l    0    ; of the graphics.library



OldCop:            ; This is where the address of the old system COP goes
dc.l    0

SECTION    GRAPHIC,DATA_C    ; This command loads this segment of data
; from the operating system
; into CHIP RAM, which is mandatory
; The copperlists MUST be in CHIP RAM!

COPPERLIST:
dc.w    $100,$200	; BPLCON0 - No image, only the background
dc.w    $180,$000    ; Colour 0 BLACK
dc.w    $7f07,$FFFE    ; WAIT - Wait for line $7f (127)
dc.w    $180,$00F	; Colour 0 BLUE
dc.w    $FFFF,$FFFE    ; END OF COPPERLIST

end

This program ‘points’ to one of our COPPERLISTS, and can be used
to point to any COPPERLIST, so it is useful for experimenting
with COPPER. DO NOT BE DISCOURAGED FROM USING THE OPERATING SYSTEM
WITH THE OPENING OF LIBRARIES AND THE LIKE, AS THROUGHOUT THE COURSE YOU WILL ONLY
NEED TO OPEN THE GRAPHICS.LIBRARY TO PUT THE OLD
COPPERLIST AND A FEW OTHER THINGS IN PLACE, SO YOU ONLY NEED TO LEARN THESE FEW THINGS.
NOTE 1: As you have already noticed, this listing contains the SECTION command,
which has the function of deciding the HUNKs of the executable file that you will save
with the WO command: every file executable from the shell, such as
ASMONE itself, is placed in RAM by the operating system by copying it from
the diskette or hard disk, 
and this copying action is performed
according to the HUNKS of the file in question, which are nothing more than parts of
that file; in fact, a file is made up of one or more hunks. Each hunk has
its own characteristics, in particular WHERE IT MUST BE LOADED, whether only
in CHIP RAM or whether it can also be placed in FAST RAM; it is necessary to
use the SECTION command if you want to generate an executable file with
copperlists or sounds, because this type of data must always be loaded
into CHIP RAM, otherwise, if you do not specify _C, the file generated with
WO will have a generic hunk that can be loaded anywhere in
free memory, whether CHIP or FAST. Many old demos or even 
demos for Amiga 1200 do not work on Amiga with Fast RAM precisely because the
file has hunks that can be loaded into any type of free memory, and does not
work on computers with FAST memory, as the operating system tends
to fill the FAST RAM before the precious CHIP RAM: evidently, those
who made those old demos or games had the basic Amiga 500 with
512k of chip RAM, without FAST, and the programs worked for them because they were
still loaded into CHIP. The same applies to those who have an A500+ or an A600,
which only have 1MB of CHIP, but when these programs are
loaded onto a computer with FAST RAM, the FIGURES, SOUNDS and COPPERLISTS
are loaded into FAST RAM and, since the CUSTOM CHIPS can only access
the CHIP memory, they make random sounds and the video goes haywire,
sometimes causing the system to freeze.
The syntax of the SECTION command is as follows: after the word SECTION, you must
write the name of that section, give it any name you like, then
write the type of section you are defining: CODE or DATA, i.e. whether it is made up of
INSTRUCTIONS or DATA. However, this difference is not very important. In fact,
the first section in this list is defined as a CODE section, which also has LABELS
with texts (dc.b “graphics library”);
 then you decide the most important thing: whether it should be loaded into CHIP or whether it is also OK in FAST memory: to
decide that it must be loaded into CHIP, simply add a _C
to the DATA or CODE; if nothing is added, it means that the data or
instructions in the section can be loaded into any type of memory.
Some examples:

SECTION FIGURE,DATA_C    ; data section to be loaded into CHIP
SECTION    LISTANOMI,DATA    ; data section that can be loaded into CHIP or FAST
SECTION Program,CODE_C    ; code section to be loaded into CHIP
SECTION Program2,CODE	; code section loadable in CHIP or FAST

Always put the first SECTION as CODE or CODE_C, obviously starting with
instructions, after which you can create DATA or DATA_C sections where there are no
instructions. Let's take an example:

SECTION    Myprogram,CODE    ; Loadable in both CHIP and FAST

move...
move...

SECTION    COPPER,DATA_C    ; Can only be assembled in CHIP

dc.w    $100,$200....    ; $0100,$0200, but you can remove
; the leading zeros, if, for example,
; we need to write dc.l $00000001
; it will be more convenient to write dc.l 1
; in the same way dc.b $0a can be
; written dc.b $a, in memory it will be
; assembled $0a.

SECTION    MUSICA,DATA_C    ; Assembled only in CHIP

dc.b    Pavarotti.....

SECTION    FIGURE,DATA_C    ; only in CHIP!

dc.l    Egyptian pyramids

END

You can also create a single CODE_C section, but fragmenting
the graphics or sound data into 50k pieces makes the program easier to
allocate in the memory holes of a single 300k or larger piece.
Also consider that loading instructions into CHIP RAM is a waste
because if they are loaded into FAST RAM, especially on an Amiga with a 68020+,
they are executed faster, even up to 4 times faster than in CHIP memory.
There are also BSS or BSS_C sections, which we will discuss when we use them.
NOTE2: You may also have noticed the use of (PC) in the instruction:

move.l    OldCop(PC),$dff080	; COP1LC - Point to the system cop

This (PC) added after the label name does not change the FUNCTION of the
command; in fact, if you remove the (PC), the same thing happens. Rather, it serves
to change the FORM of the command. Try assembling and doing a
D Mouse:...

            BTST    #$06,$00BFE001
...            BNE.B    $xxxxxxxx
23FA003400DFF080    MOVE.L    $xxxxxx(PC),$00DFF080...
            MOVE.W    D0,$00DFF088

You will notice that move.l Oldcop(PC),$dff080 is assembled as $23fa....

Now try removing (PC), assemble and redo D MOUSE:

23F900xxxxxx00DFF080    MOVE.L    $xxxxxx,$00DFF080

This time the instruction is assembled in 10 bytes instead of 8, and
can be clearly read after $23f9, which means MOVE.L, the address of Oldcop,
while in the case of move.l with PC, the command starts with $23fa and can be seen in $34
instead of the address of OldCop!The difference is that when there is no
PC, the instruction refers to a DEFINED ADDRESS, in fact it is assembled,
while an instruction with (PC) instead of writing the address writes the distance
from itself to the label in question, in this case $34 bytes.
Instructions with (PC) are called RELATIVE TO THE PC, i.e. to the Program Counter, which
is the register where the address of the instruction being executed is written:
when the 68000 executes MOVE.L OLDCOP(PC), it calculates the address
in PC+$34 and obtains the address of Oldcop, located $34 bytes further
on. This method is faster and, as we have already seen, the instructions are shorter,
 but they can only be used for labels no further away than 32768 (as with
BSR), and cannot be used between sections, precisely because
the sections are loaded at who knows what point and who knows what distance in memory
and would therefore be too far away. In fact, try adding the line
LEA COPPERLIST(PC),a0 at the beginning of the listing and you will see that when you try to
assemble ASMONE, you get a RELATIVE MODE ERROR, while removing the (PC)
the instruction is assembled. I recommend always putting (PC) at the
labels whenever possible:

LEA    LABEL(PC),a0
MOVE.L    LABEL(PC),d0
MOVE.L    LABEL1(PC),LABEL2    ; only the first label can be
; followed by PC, the second NEVER.
MOVE.L    #LABEL1,LABEL2        ; in this case, in fact, you cannot
; put the (PC) in either the
; first or second operand.

CHANGES: Now you can make any copperlist! Start by changing the 2
colours, bearing in mind that the format is as follows: $0RGB, where only 3
numbers, $RGB, where R=RED, G=GREEN, B=BLUE
Each of these 3 numbers can range from 0 to 15, in hexadecimal notation,
i.e. from 0 to F (0123456789ABCDEF), and depending on how these
3 basic colours are mixed, all 4096 colours of the Amiga (16*16*16) can be formed.
To obtain black, you need $000, for white, $FFF, and $999 is grey.
Please note! They are not mixed like tempera or oil colours! For example
to make yellow you need RED+GREEN, $dd0 for example, to make purple
you need to mix RED+BLUE, for example $d0e.
This colour mixing system is the same as the one found in the PREFERENCES
of the WorkBench or in the DPAINT palette, with the 3 RGB controls.
Once you have experimented with changing the first copperlist, you can create
shades by adding WAIT and COLOR 0 ($180,xxx), similar to the
sunsets you have seen in the backgrounds of SHADOW OF THE BEAST or other
games, or the bar shades in many demos: now you know how they work!
Replace this copperlist with Amiga+B+C+I in the listing, observe
what is displayed and why, and modify it to make sure you understand
everything, or to create background gradients for your first game!!!

COPPERLIST:
dc.w    $100,$200    ; BPLCON0 - background only
dc.w    $180,$000    ; COLOR0 - Start the cop with the colour BLACK
dc.w    $4907,$FFFE    ; WAIT - Wait for line $49 (73)
dc.w    $180,$001    ; COLOR0 - very dark blue
dc.w    $4a07,$FFFE    ; WAIT - line 74 ($4a)
dc.w    $180,$002    ; COLOR0 - slightly darker blue
dc.w    $4b07,$FFFE    ; WAIT - line 75 ($4b)
dc.w    $180,$003    ; COLOR0 - lighter blue
dc.w    $4c07,$FFFE    ; WAIT - next line
dc.w    $180,$004    ; COLOR0 - lighter blue
dc.w    $4d07,$FFFE	; WAIT - next line
dc.w    $180,$005    ; COLOR0 - lighter blue
dc.w    $4e07,$FFFE    ; WAIT - next line
dc.w    $180,$006    ; COLOR0 - blue at 6
dc.w    $5007,$FFFE	; WAIT - jump 2 lines: from $4e to $50, i.e. from 78 to 80
dc.w    $180,$007    ; COLOR0 - blue at 7
dc.w    $5207,$FFFE    ; WAIT - jump 2 lines
dc.w    $180,$008    ; COLOR0 - blue at 8
dc.w    $5507,$FFFE    ; WAIT - jump 3 lines
dc.w    $180,$009    ; COLOR0 - blue at 9
dc.w    $5807,$FFFE	; WAIT - jump 3 lines
dc.w    $180,$00a    ; COLOR0 - blue at 10
dc.w    $5b07,$FFFE    ; WAIT - jump 3 lines
dc.w    $180,$00b    ; COLOR0 - blue at 11
dc.w    $5e07,$FFFE	; WAIT - jump 3 lines
dc.w    $180,$00c    ; COLOR0 - blue at 12
dc.w    $6207,$FFFE    ; WAIT - jump 4 lines
dc.w    $180,$00d    ; COLOR0 - blue at 13
dc.w    $6707,$FFFE    ; WAIT - jump 5 lines
dc.w    $180,$00e    ; COLOR0 - blue at 14
dc.w    $6d07,$FFFE    ; WAIT - jump 6 lines
dc.w    $180,$00f    ; COLOR0 - blue at 15
dc.w    $7907,$FFFE    ; WAIT - wait for line $79
dc.w    $180,$300    ; COLOR0 - start red bar: red at 3
dc.w    $7a07,$FFFE    ; WAIT - next line
dc.w    $180,$600    ; COLOR0 - red at 6
dc.w    $7b07,$FFFE	; WAIT - 
dc.w    $180,$900    ; COLOR0 - red at 9
dc.w    $7c07,$FFFE    ; WAIT - 
dc.w    $180,$c00	; COLOR0 - red at 12
dc.w    $7d07,$FFFE
dc.w    $180,$f00    ; red at 15 (maximum)
dc.w    $7e07,$FFFE
dc.w    $180,$c00	; red at 12
dc.w    $7f07,$FFFE
dc.w    $180,$900    ; red at 9
dc.w    $8007,$FFFE
dc.w    $180,$600    ; red at 6
dc.w    $8107,$FFFE
dc.w    $180,$300    ; red at 3
dc.w    $8207,$FFFE
dc.w    $180,$000    ; colour BLACK
dc.w    $fd07,$FFFE	; wait for line $FD
dc.w    $180,$00a    ; blue intensity 10
dc.w    $fe07,$FFFE    ; next line
dc.w    $180,$00f    ; blue maximum intensity (15)
dc.w    $FFFF,$FFFE    ; END OF COPPERLIST

In summary, if, for example, you set colour 0 as green at line $50, lines
$50 and following will be green until the colour is changed again
after a wait, for example a wait $6007.
A tip: to make this copperlist, I OBVIOUSLY did not write all the
times dc.w $180,$... dc.w $xx07,$FFFE!!!! Just take the two instructions:

dc.w    $xx07,$FFFE    ; WAIT
dc.w    $180,$000    ; COLOR0

Select them with Amiga+B and Amiga+C, then make a long line by pressing
Amiga+i several times:

dc.w    $xx07,$FFFE    ; WAIT
dc.w    $180,$000    ; COLOR0
dc.w    $xx07,$FFFE    ; WAIT
dc.w    $180,$000    ; COLOR0
dc.w    $xx07,$FFFE    ; WAIT
dc.w    $180,$000    ; COLOR0
.....

At this point, just change the XX in the wait and the value of $180 each time,
and delete the extra instructions with Amiga+B and Amiga+X.
NOTE: This can also be done between different ASMONE text buffers.
For example, if I have a listing in buffer F2 with a copperlist that I want to modify,
just select it normally with Amiga+B and Amiga+C, then
return to my listing, for example in F5, and insert the piece taken
from the other listing with Amiga+i.

