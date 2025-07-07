
; Lesson 2d.s

Start:
lea    CANGURO,a0    ; put the address of CANGURO in A0
move.l    (a0),d0        ; put the value .L found
; at the address in a0, i.e.
; the first longword contained in CANGURO
move.l	CANGURO,d1    ; in d1 we put the contents of the first
; longword (4 bytes=4 addresses) of canguro
move.l    a0,d2        ; in d2 we put the number contained in a0,
; i.e. the address of CANGURO loaded
; earlier with LEA CANGURO,a0
move.l    #CANGURO,d3    ; put the address of CANGURO in d3
rts

CANGURO:
dc.l    $123

END

This example shows the difference between direct, indirect and absolute addressing: once assembled, press D Start to
check and, after executing with J, you will see the result in the
registers: in d0 and d1 you will see $123, i.e. the content .L of CANGURO:

lea    CANGURO,a0    ; in A0 we put the address of CANGURO
move.l    (a0),d0        ; in d0 we put the value contained
; in the address that is in a0, i.e.
; the .L value contained in CANGURO
; (With MOVE.L, the byte contained
; in the address in a0 is copied, as well as the following 3,
; being a 4-byte long)
This is equivalent to:

move.l    CANGURO,d1    ; in d1 we put the .L content of canguro

In fact, in both cases, the .L content of canguro goes into the data register.

Instead, in d2, d3 and a0, you will notice the address of CANGURO, in fact:

lea    CANGURO,a0    ; in A0 we put the address of CANGURO
move.l    a0,d2        ; in d2 we put the number contained in a0,
; i.e. the address of CANGURO loaded with LEA

This is equivalent to:

move.l    #CANGURO,d3    ; in d3 we put the address of CANGURO

These differences in addressing must be clear, because once
you know them, you just need to remember the commands, which all use the same
addressing system.

Examples of addressing analysed so far:

DIRECT:
move.l    a0,a1

INDIRECT:
clr.l    (a0)
move.l    (a3),(a4)

ABSOLUTE:
move.l    #LABEL,d0
MOVE.L    #10,d4

