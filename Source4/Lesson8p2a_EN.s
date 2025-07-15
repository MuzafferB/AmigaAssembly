
; Lesson 8p2a.s        Flags and address registers

SECTION    CondC,CODE

Start:
move.w    #$8000,d0
move.l    #$80000000,a0
stop:
rts

end


;     . · · .
;     . .
;     . .
;     . .
;     · ·

In this lesson, we will look at a special feature of addressing
directly to the address register. We will see this feature using a
MOVE instruction in which address
directing to the address register is used for the destination, but it occurs with all instructions that
allow direct addressing to the address register for the destination.

First, assemble the program and execute the first instruction.
You will get the following output:

D0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
A0: 80000000 00000000 00000000 00000000 00000000 00000000 00000000 07C9EDC4
SSP=07C9FEF7 USP=07C9EDC4 SR=8004 T1 -- PL=0 --Z-- PC=07CA18DC
PC=07CA18DC 207C80000000     MOVE.L #$80000000,A0
>

As expected, the ‘Z’ flag has taken the value 1.
Let's also execute the second instruction:

D0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 
A0: 80000000 00000000 00000000 00000000 00000000 00000000 00000000 07C9EDC4
 
SSP=07C9FEF7 USP=07C9EDC4 SR=8004 T1 -- PL=0 --Z-- PC=07CA18E2
PC=07CA18E2 4E75         RTS
>

We note that the instruction has been executed, but that the ‘Z’ flag is still 1
and the ‘N’ flag is 0. Yet the value $80000000 that we loaded
into register A0 is negative! So has our trusty 680x0 made a mistake?
Of course not! (It's not a Pentium 60! :). The point is that, as we
already explained in lesson 8, the instruction that actually 
copies data to an address register is MOVEA, a variant
of the normal MOVE; for convenience, ASMONE allows us to write
MOVE to copy to address registers, and it takes care of replacing
MOVE with MOVEA. Usually, we don't even notice this 
replacement. In this case, however, we need to be very careful because
MOVEA behaves differently from MOVE with regard to
modifying the CCs. MOVEA, as you can read in 68000-2.TXT, 
leaves ALL CCs UNCHANGED. In our case, the ‘Z’ flag was 1 before
the execution of MOVE #$80000000,A0 and for this reason it remained
at value 1. Let's check this by modifying the first MOVE in

move.w    #$8000,d0

By executing STEP BY STEP, we notice that the first MOVE takes the value 1
:

D0: 00008000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 
A0: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 07CC685C
 
SSP=07CC798F USP=07CC685C SR=8008 T1 -- PL=0 -N--- PC=07CC9A60
PC=07CC9A60 207C80000000     MOVE.L #$80000000,A0
>

And MOVE.L #$80000000,A0, as we said, leaves the CC unchanged:

D0: 00008000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
 
A0: 80000000 00000000 00000000 00000000 00000000 00000000 00000000 07CC685C
 
SSP=07CC798F USP=07CC685C SR=8008 T1 -- PL=0 -N--- PC=07CC9A66
PC=07CC9A66 4E75         RTS
>

Particular attention must be paid to the fact that the CCs are not
affected when addressing registers, because this
can cause bugs. Suppose, for example, that you have stored a piece of data
and want to modify it in two different ways depending on whether it is positive or
negative. If we move the data to a data register, for example D0, we can
write the following code fragment:

move.w    data(pc),d0    ; modifies the CCs based on the data
bmi.s    negative_data
positive_data:
; operations to be performed if the data is positive
bra.s    end

negative_data:
; operations to be performed if the data is negative
end:
; rest of the programme

In this case, as we already know, MOVE sets the CCs according to
the sign of the data.
If, on the other hand, we were to put our data in an address register
(e.g. A0), writing a similar procedure would not work because
MOVEA does not update the CCs correctly.

move.w    data(pc),a0    ; DOES NOT modify the CCs based on the data !!
bmi.s    negative_data    ; The jump is made based on the
; status of the CCs prior to MOVE
positive_data:
; operations to be performed if the data is positive
bra.s    end

negative_data:
; operations to be performed if the data is negative

end:
; rest of the program

A possible solution to the problem could be to move the data first
to a data register and then to A0, or use the TST instruction.

