
; Lesson 8p1a.s    Condition Codes with the MOVE Instruction

; Here is the programme for this lesson: 2 instructions.
; Do you think I'm kidding? After everything you've seen
; so far, do you think you already know everything about this simple programme?
; Well, you're wrong. Follow the instructions in the comments.

SECTION    CondC,CODE

Start:
move.w    #$0000,d0
stop:
rts

end

;     oO
;    \__/
;     U

In this lesson and the following ones, we will see how the
Condition Codes (CC) of the status register work.
CCs were described in detail in lesson 68000-2.TXT.
If you don't remember what they are and how they work, I recommend that you reread
68000-2.TXT.
Let's briefly recall that CCs are bits in the status register that
are modified by assembler instructions to provide information on the
result of the operation performed.
There are instructions that modify all CCs, others that modify only
some, and others that do not modify any.
Furthermore, each instruction that modifies the CCs does so in its own way.
In lesson 68000-2.TXT, the effect that each assembler instruction has on the CCs is described
briefly. In these listings, we will present
some small practical examples of how the most commonly used instructions modify the CCs.
These listings are more tedious than those you have seen so far, but
you need to study them well if you want to become REAL coders.
In this lesson, we will examine the MOVE instruction.
As you should know, this is an instruction that copies the contents
of a register or memory location and modifies the CCs accordingly.
To see how this instruction works, we will use ASMONE to
execute the program STEP BY STEP, i.e. one instruction at a time.
To do this, assemble the program as usual, but DO NOT execute it.
Instead, give ASMONE the X command, which is used to print the contents of
all the 68000 registers and the next instruction to be executed.
This information is summarised by ASMONE in the four
lines below:

D0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
 
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CAAE9C
 
SSP=07CABFD3 USP=07CAAE9C SR=0000 -- -- PL=0 ----- PC=07CAE030
PC=07CAE030 303C0000 MOVE.W #$0000,D0
>

Let's briefly explain the meaning of these 4 lines.
The first line represents the contents of the 8 data registers of the 68000.
You can see that there are 8 numbers separated by a space
representing the contents of the registers, starting with D0 (the leftmost)
and continuing in order up to D7.
Note that before the program is executed, the registers are all cleared.

The second line represents the contents of the address registers, in exactly
the same way as the first line represents the contents of the data registers.
Note that the registers are all reset except for A7, which contains the address
of the system stack.

The third row shows other processor registers.
For now, we will only deal with the PC (Program Counter) and the SR (Status
Register)
The PC contains the address of the next instruction to be executed. As you know
the instructions that make up an assembler program are stored in memory!
The PC contains the memory address from which the next instruction will be fetched.
 In this case, the address is 07CAE030, which is part
of the 32-bit FAST memory mounted on the a1200/a4000 and similar computers. It is obvious that if you
assemble on different computers with memory in different locations, this value
will change, and even on the same computer it may be different each time,
since programs are relocatable and not SCHIFOSAMENTE non-relocatable.

We have already discussed SR, the status register, in 68000-2.TXT. For now, we will only deal with
the low byte containing the CCs. Note that the contents of SR
are represented in hexadecimal form. Therefore, reading the contents of
individual CCs may be inconvenient. For this reason, CCs are
represented separately. You will notice that immediately before the contents
of the PC there are 5 dashes. Each dash represents a different CC and indicates
that it is reset. When one of the CCs takes the value 1 instead of the
dash, the letter that names the dash is printed: for example, if
the Carry becomes 1, the letter C is printed in place of the corresponding dash.
Finally, in the fourth line, we can read the next instruction that will be

executed. In this case, it is the first instruction of the program.
NOTE: if you want to print the output of ASMONE to a file, you can do so using the command > or, equivalently, by selecting the Output item from the Command menu. ASMONE will ask you for the name of the file.

NOTE: if you want to print the ASMONE output to a file, you can do so
by using the > command or, equivalently, by selecting Output from the
command menu. ASMONE will ask you for the name of the file where you want to print the output
and that's it. This is exactly how I printed
the output of the X command

At this point, we can execute the first instruction of the program, i.e.

MOVE.W #$0000,D0

We give ASMONE the command K. The instruction will be executed and the contents of the registers will be printed
automatically:

D0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
 
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CAAE9C
 
SSP=07CABFCF USP=07CAAE9C SR=8004 T1 -- PL=0 --Z-- PC=07CAE034
PC=07CAE034 4E75         RTS
>

Our instruction placed the value $0000 in register D0. It also
changed the CC. Note that the content of SR is now $8004, i.e.
the low byte is $04, which is written as %00000100 in binary. This means that
bit 2, corresponding to the CC ‘Zero’, has taken the value 1. As I mentioned
earlier, one of the five dashes that appeared previously has been
replaced by the character “Z”, which indicates that the ‘Zero’ flag has taken
the value 1.
The MOVE instruction modifies the CCs as follows:
The V and C flags are reset
The X flag is not modified
The Z flag takes the value 1 if the data being copied is 0
The N flag takes the value 1 if the data being copied is negative.

In our case, since the data we copy to D0 is $0000, the Z flag takes
the value 1 and the N flag takes the value 0 (because $0000 is NOT a negative number
).

Let's now look at some other examples of how to use the MOVE instruction. Modify the
source code by writing: 

move.w    #$1000,d0

Now repeat the procedure to execute the program STEP BY STEP.
After executing MOVE, we will have the following situation:

D0: 00001000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07C9EDFC
 
SSP=07C9FF2F USP=07C9EDFC SR=8000 T1 -- PL=0 ----- PC=07CA2E40
PC=07CA2E40 4E75         RTS
 

We can see that D0 now contains the value $00001000, which is exactly
what we copied with MOVE. Furthermore, this time the CC
are all reset to zero. This is because the value $1000 that we
moved is not zero and is also a positive number.

Let's make another change.
Instead of the value $1000, we put $8020, obtaining:

move.w    #$8020,d0    ; i.e. "move.w #-32736,d0

This time, after executing the MOVE, we obtain:

D0: 00008020 00000000 00000000 00000000 00000000 00000000 00000000 00000000 
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07C9EDFC
 
SSP=07C9FF2F USP=07C9EDFC SR=8008 T1 -- PL=0 -N--- PC=07CA2E40
PC=07CA2E40 4E75         RTS

As you can see, D0 has taken on the desired value and the N flag has taken on
the value 1. This is because the number $8020 is a negative number
because its most significant bit is 1.

Let's now transform the MOVE as follows:

move.l    #$8020,d0

We have simply changed the size of the data being moved. This
means that we must now consider the value $8020 as a 32-bit number,
 i.e. as $00008020. Now the most significant bit is bit 31, not
bit 15 as before! So in this case we are dealing with a
POSITIVE number. By executing the MOVE, we obtain:

D0: 00008020 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
 
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07C9EDC4
 
SSP=07C9FEF7 USP=07C9EDC4 SR=8000 T1 -- PL=0 ----- PC=07CA33CA
PC=07CA33CA 4E75         RTS
>

where you can see that the ‘N’ flag is reset.
