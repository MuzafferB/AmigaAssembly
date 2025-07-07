
; Lesson 2m.s

; Demonstration that working with address registers a0...a7 always operates
; on the entire longword, both with the usual .L and with .W.


beginning:
move.l    #FFFFFF,d0
ADDQ.W    #4,d0        ; Add .w 4 to d0, but only work on the word
; because we are on a DATA register (the same
; would be done on a label)
lea    $FFFFFF,a0
ADDQ.W	#4,a0        ; Add .w 4 to a0, but working on an
; ADDRESS register, the add involves the entire
; address, i.e. the longword.
rts

end

Try debugging this listing (AD) and step by step you will notice the
main difference between an address register and a data register or any
label. This difference is that address registers always work on the entire
address, i.e. on the entire longword. In fact, it is not possible to operate with
.B instructions on such registers, and when working with .W (only possible
if we add/subtract/move numbers smaller than a word), the
result is the same as a .L. Therefore, you can always use .L, but
in cases where it is possible, it is better to ‘OPTIMISE’ the instruction by changing
it to .W, as it is faster than .L.
By DEBUGging this listing, you will notice that ADDQ.W #4,d0 only operates
on the word D0, changing it to $00FF0003, since after $FFFF
the numbering starts again from $0000, then reaches $0003, but
the upper part of the number is not involved.
If, on the other hand, you did an ADDQ.L #4,d0 (try it!), that ADD would involve the entire
LONG, transforming it into $01000003, because after $00FFFFFF comes $01000000.
Instead, when operating on address registers, ADD.W behaves like ADD.L, except that it
cannot always be used. For example, it cannot be used for a number such as
$123456. Although this is not an error, always remember to use
.W instead of .L in these instructions with address registers to make
the code slightly faster.

ADD.L    #$123,a0    ; optimisable to ADD.W #$123,a0
ADD.L    #$12345,a0    ; not optimisable

