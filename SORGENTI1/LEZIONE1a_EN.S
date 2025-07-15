
; by Fabio Ciucci - Assemble with ‘A’, execute with ‘J’

Waitmouse:            ; this LABEL serves as a reference for the bne.
	move.w    $dff006,$dff180    ; put the value of $dff006 in $dff180
								 ; i.e. from VHPOSR to COLOR00
	btst    #6,$bfe001    ; left mouse button pressed?
	bne.s    Waitmouse    ; if not, return to waitmouse and repeat
	rts            ; exit

END

; NOTE: the MOVE command means MOVE, or rather COPY the number contained
; in the first operand to the second, in this case ‘READ THE NUMBER IN
; $DFF006, AND PUT IT IN $DFF180’. The .w means that it moves a word, i.e.
; 2 bytes, i.e. 16 bits (1 byte=8 bits, 1 word=16 bits, 1 longword=32 bits)
; NOTE2: the BTST followed by the BNE is used to jump in the program
; if a condition has been met: it can be translated as follows:
; BTST = CHECK IF PIERO HAS EATEN THE APPLE, AND WRITE IT ON A PIECE OF PAPER
; BNE = THE BNE GOES TO READ ON THE PIECE OF PAPER IF PIERO HAS EATEN THE APPLE,
; WHICH HE CANNOT CHECK HIMSELF, BUT WHICH HIS FRIEND BTST HAS CHECKED...
; IF THE PIECE OF PAPER SAYS THAT HE HAS NOT EATEN IT, THEN
; SKIP TO THE INDICATED LABEL (IN THIS CASE BNE.S Waitmouse, so if Piero
; has not eaten the apple, the processor will skip to Waitmouse and repeat
; everything; if, on the other hand, he has eaten it, then it does not skip to Waitmouse, but continues
; executing the instruction under BNE... in this case, it finds an RTS and
; consequently, the programme ends. The sheet on which BTST writes the sentence
; for the BNE is the STATUS REGISTER, or SR. If, for example, instead of the BNE
; there was a BEQ, then the loop would only occur when the mouse
; is pressed, and would end when it is released (THE OPPOSITE: IN FACT, BNE means:
; BRANCH IF NOT EQUAL, i.e. JUMP IF NOT EQUAL (false), while BEQ:
; BRANCH IF EQUAL, i.e. jump if EQUAL (true).
; The first line reads the value in $dff006, i.e. the line
; reached by the electronic brush that continuously rewrites the screen,
; therefore always a different number, and puts it in $dff180, which is the
; register that controls colour 0, thus obtaining a
; flashing or striped screen, where the colour is continuously changed.
; Check that $dff006 is VHPOSR by doing ‘=c 006’, and that $dff180 is
; COLOUR 0, by doing ‘=C 180’. You can ask ASMONE for help with
; each $dffxxx register.
; the colour format is as follows: $0RGB, i.e. the word in the register
; is divided into RED, GREEN and BLUE, in 16 tones per colour; by mixing them as
; in the PALETTE or TAVOLOZZA of Deluxe Paint, you can select one of the
; 4096 possible colours (16*16*16=4096), each value of RED, GREEN and BLUE
; ranges from 0 to F (hexadecimal number, i.e. it can
; be 0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f), for example try changing the
; first line with MOVE.W #$000,$dff180: you will get black
; changing it to MOVE.W #$00e,$dff180 will give you BLUE, 
; with MOVE.W #$cd0,$dff180 you will get YELLOW, i.e. red+green...
; try changing the colour to check if you have understood
; #$444 = grey, #$900 = dark red, #$e00 = bright red, #$0a0 = green....
; finally, if you change $dff180 to $dff182, the text will flash instead of
; the background, i.e. the colour with colour 1. If you put both
; instructions one after the other, both the background and the text will flash.
; The BTST command checks whether a BIT at a given address is =0...
; remember that the number of bits must be read from right to left and
; starting from 0, for example in a byte such as %01000000, the bit at 1 is 6:
; 76543210         5432109876543210
; 01000000 a word: 0001000000000000 <= here bit 12 is 1!!!
;
; P.S:    The first bit is called bit 0 and not bit 1, so don't
;    get confused about this, i.e. that, for example, the seventh bit
;    is called bit 6. To avoid mistakes, always put the numbering
;    ; 5432109876543210 above the binary number.
;
; Bit 6 of $bfe001 is in fact the left mouse button.
; The name of the register $bfe001 is CIAAPRA, but no one remembers it.
; The right button is bit 2 of $dff016. Try replacing the
; line BTST #6,$bfe001 with BTST #2,$dff016, and the right button will
; exit the loop. Make all the suggested changes to check!
; NOTE: if you want to save the program so that it can be followed from the CLI
; just type ‘WO’ after assembling with A (and before doing J!),
; and a window will appear where you can decide where to save it
; (Important! Save it on another diskette! Keep the course diskette
; write-protected and don't write on it!!!).
; If you want to save the listing, use the ‘W’ command. (on another
; disk!!!).

; PSPS: You may have noticed BNE.S, which is a suffix that is neither .B, .W
;    nor .L!!!! Well, in instructions such as BNE, BEQ, BSR, you can specify
;    only two dimensions: .B and .W, which do not affect the result,
;    in fact, a bne.w will do the same thing as a bne.b. In these instructions
;    it is allowed to call .B as .S, which stands for SHORT, and
;    it can only be used if the label it refers to is not too
;    ‘far away’, otherwise ASMONE will change it to .W in the
;    listing automatically during assembly. Since .S (which, I repeat, stands for .B)
;    can only be used with these instructions, I think it is best to use it.
;    Now that you know this, it should not cause any problems.
;    PSPSPS: If you set the size to .L (BNE.L), ASMONE will not give an error
;    and will assemble as .W, other assemblers will give an error. If you forget
;    to put the suffix (BNE Start), ASMONE will always assemble as
;    BNE.W, the same applies to other instructions! writing MOVE $10,$20,
;    does not give an error because it is assembled as MOVE.W $10,$20, BUT
;    THIS DOES NOT MEAN THAT ALL ASSEMBLERS BEHAVE THIS WAY, SO ALWAYS ADD
;    THE SUFFIX, which also looks better.
