
; Lesson 3a.s    - HOW TO EXECUTE AN OPERATING SYSTEM ROUTINE

Start:
move.l    $4.w,a6        ; Execbase in a6
jsr    -$78(a6)    ; Disable - stops multitasking
mouse:
move.w    $dff006,$dff180    ; set VHPOSR to COLOR00 (flashing!!)
btst    #6,$bfe001    ; left mouse button pressed?
bne.s    mouse        ; if not, return to mouse:

move.l    4.w,a6        ; Execbase in a6
jsr    -$7e(a6)    ; Enable - re-enable multitasking
rts

END

This is the first listing in which we use an operating system routine!
And, coincidentally, it is the one that disables the operating system itself!
In fact, you will notice that during execution, the arrow controlled by the mouse freezes,
 pressing the right mouse button does not bring up the drop-down menus, and the disk drives
stop clicking. And be careful that even the AD command, i.e. the
debugger, which uses the operating system, is disabled and remains stuck!
So remember that when we disable the operating system, or even
point to our own copperlist, the debugger is needed until the operating system
is alive!
Try pressing “AD” anyway, using the cursor key with the arrow pointing to the right
(this key allows you to “enter” the BSR and JSR, while the
cursor key with the arrow pointing downwards skips the BSR and JSR debug).
After the first instruction, MOVE.L 4.w,a6, will appear in register A6
the address that was contained in the long composed of the 4 bytes $4,$5,$6,$7.
Press ESC and check by typing ‘M 4’ and pressing return four times: you will find
the same address. This address is placed there by the kick
every time the Amiga is reset or turned on.
Resume debugging, pass the MOVE.L 4.w,a6, and ‘enter’ JSR -$78(a6)
with the cursors: to follow the subroutine, you need to look at the disassembly line
at the bottom of the screen, where you will see a JMP $fcxxxx or $f8xxxx instruction,
depending on whether you have a 1.3 or 2.0/3.0 kick. You are at the address that was in $4
minus $78, and you are still in the RAM of your Amiga, where, however,
you will find a JMP that will jump you into the ROM. In fact, every time
the Amiga loses that second or two during RESET or power-up, it creates a
JMP TABLE in memory, whose final address is placed in $4.
Each JMP jumps to the address of that particular kickstart where the
routine corresponding to the position of that JMP relative to its end is located.
In fact, by doing JSR -$78(a6) you disable multitasking on both a kick 1.2
and a kick 1.3, or 2.0 or 3.0, as well as on future ones.
If, for example, in kick 1.3 the routine in the ROM is located at $fc12345, the
JMP located at $78 bytes below the base address will be JMP $fc12345, while
if on a kick 2.0 the routine in question is at $f812345, the JMP in question
will be at $f812345. This system also allows you to load a kickstart into
RAM: all you need to do is create a JMP TABLE pointing to its routines.
Stop debugging with ESC after noting down the address of the JMP,
and try doing a ‘D that address’ (the address of the instruction is the
first number on the left at the bottom of the screen! or you can also find it in
at the bottom of the register list on the right, it is the PC register, i.e. Program
Counter, which records the address being executed, just add a
$ in front of it). You will see that there is a row of JMPs; here is an example:

JMP    $00F817EA    ; -$78(a6), i.e. DISABLE
JMP    $00F833DC    ; -$72(a6) another routine
JMP    $00F83064    ; -$6c(a6) another routine...
JMP    $00F80F74    ; ....
JMP    $00F80F0C
JMP    $00F81B74
JMP    $00F81AEC
JMP    $00F8103A
JMP    $00F80F3C
JMP    $00F81444
JMP    $00F813A0
JMP    $00F814F8
JMP    $00F82842
JMP    $00F812F8
JMP    $00F812D6
JMP    $00F80B38
JMP    $00F82C24
JMP    $00F82C24
JMP    $00F82C20
JMP    $00F82C18

To insert disassembled pieces into the source, I used the ‘ID’ command,
in which you must specify the start and end of the area to be inserted:

BEG> here you put the address or label, try with the JMP address
END> put the final address, or $xxxxx+$80, where $xxxxx
is the starting address: in this case you will get the disassembled code
starting from address $xxxxx up to $80 bytes after.

REMOVE UNUSED LABELS? (Y/N)    ; ENTER ‘Y’ HERE. If you do not enter this,
; a label containing the address will be placed
; on each line of code, instead of only where
; the label is needed. Try doing an ‘ID’
; of this listing to check the
; difference.

Example: if the address was $32123

ID

BEG> $32123
END> $32123+$80        ; NOTE: to get the old addresses back, press
; the up arrow key several times.
; (In fact, pressing the up arrow returns
; the things you wrote before as in SHELL)

and the requested disassembly will appear, starting from where you were last with the cursor in the
text.

Now you can imagine how many JSR and JMP the processor has to execute when
a program asks it to execute routines. All this jumping
wastes time, which is why we will only use the operating system when absolutely
necessary.

If you continue with DEBUG after JMP, you will find yourself in the ROM, i.e.
at the JMP address: DISABLE is usually like this:

MOVE.W    #$4000,$dff09a    ; INTENA - Stop interrupts
ADDQ.B    #1,$126(a6)    ; Stop the operating system
RTS

If you enter by pressing the right arrow, the instructions will be seen,
but not executed (for safety, when debugging subroutines outside
the listing, i.e. usually in the ROM, it just scrolls through them), in fact you can
continue and go into the mouse loop and you will notice that the mouse arrow
can move and the drives click, i.e. those two operations have not been executed
those two operations. You can also go to JSR -$7e(a6) and exit.

Instead, try going down using the cursor key with the arrow pointing down
: this time, when you go through JSR -$78(a6), the program will escape
because it is executed (but not shown).
You can still exit with the left key, after which you will need to press
ESC to exit DEBUG.

Now try making these changes:

1) Assemble, do a “D start” and you will see this:

MOVE.L    $0004.W,A6

Now try removing the .w at 4 in the listing, assemble and repeat the ‘D’:

MOVE.L    $00000004,A6

As you can see, in this case all 4 bytes of the address have been used,
whereas before, with the .w option, we saved 2 bytes. The .w
option can be used on all addresses that are one word long or less.

2) Try replacing the line

JSR    -$78(a6)

with the lines

MOVE.W    #$4000,$dff09a    ; INTENA - Stops interrupts
ADDQ.B    #1,$126(a6)    ; Stop the operating system

Or whatever you find in the ROM after the JMP (without the final RTS!).

You will notice that it works the same.

You can do the same thing with JSR -$7e(a6).

