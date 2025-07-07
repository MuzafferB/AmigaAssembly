
; Lesson 2b.s

Start:
MOVE.L    DOG,CAT
rts

DOG:
dc.l    $123456

CAT:
dc.l    0

END

;With this example, you can verify that once the source code has been assembled
;the actual addresses of DOG and CAT are assembled in place of the labels:
;Assemble with A, then press ‘D Start’ and you will notice the replacement with
;the addresses. After the rts, you will notice a couple of ORI.B and other instructions: in
;actually, these are an attempt to interpret the two longwords DOG and
;GATTO. In fact, after the $4e75 of the rts, you will notice the $00123456, which is the first
;longword named CANE by us, and $00000000, which is GATTO.
;Now run it with J, then do an M GATTO, and you will see 00 12 34 56
;in fact, the longword contained in DOG has been copied to CAT:
;Now modify the first line in MOVE.L #DOG,CAT, assemble and do
;‘D start’ ... you will see that this time too, the labels have been replaced
;with their real addresses. In fact, the only difference with the first
;test is the addition of the hash symbol (#). But this changes everything
;in an instant!!!!!!! In fact, this time if you run with J and do M CAT
;you will see that there is the address of DOG! That is, if the instruction had been
;assembled as MOVE.
L #$34200,$34204 , after execution, the FIXED number after the hash symbol (#) would have been inserted into $34204 (i.e. CAT),
i.e. the address of DOG, i.e. $34200.
Final summary:
;
;    MOVE.b	$10,$200    ; copies the value .b contained in the address
;                ; $10 to the address $200
;
;    MOVE.b    #$10,$200    ; puts the number $10 in location $200
;    MOVE.B    #16,$200    ; as above, in fact $10 = 16!!!
;    MOVE.B    #%10000,$200    ; as above, in fact %10000 = 16!!!
;
;NOTE: ASMONE allocates, i.e. positions the program each time at a different address
;the operating system does the same when you load a program,
;depending on where you have free memory.
 This system is one of the strengths of the AMIGA multitasking system. When you save the executable file with WO,
 you save the file in AMIGADOS format, which the operating system will then put
in memory where it thinks best. This is why I write ‘if it were at $34200....’:
because it can be assembled at any address.
Try loading programs in multitasking before the asmone and you will notice less
memory allocated to the initial selection (ALLOCATE Chip, fast...) and that
by doing D Start, the location is higher, because the underlying memory
 is already occupied.
 Programming at FIXED addresses, i.e. always specifying the address instead of the label, should not be done for games or demos where you can exit by returning to the workbench, because if, for example, you define the game screen at $70000 and a program has already been loaded at that location, when you exit you will get a nice GURU MEDITATION, known as
COMA... so if you don't want the Amiga to go into a continuous coma, program as this course teaches. Fixed addresses are possible, or sometimes MUST be used if you are making games or demos, but they are not recommended for general use.
;
;
COMA... If you don't want your Amiga to go into a coma continuously,
program as this course teaches. Fixed addresses can, or sometimes MUST, be used if you are making games or demos in AUTOBOOT, i.e.
those that do not start from the WB but automatically and whose directory cannot be
seen (many games are like this).
 Before making a game or demo in
;autoboot, I think it's best to at least learn how to display something on the
;screen, but I'll talk about that later.
