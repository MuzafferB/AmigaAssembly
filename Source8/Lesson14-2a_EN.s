
; Lesson 14-2a.s    ** PLAYING A MULTIPLE-NOTE HARMONICA **


SECTION    Harmonica2,CODE

Start:
move.l    4.w,a6
jsr    -$78(A6)        ; _LVODisable

bset    #1,$bfe001        ; Turns off the low-pass filter

lea    $dff000,a6
move.w    $2(a6),d7        ; dmaconr - Save OS DMA

Clock    equ    3546895

move.l    #harmonica,$a0(a6)    ; AUD0LCH.w+AUD0LCL.w=AUD0LC.l
move.w    #16/2,$a4(a6)        ; 16 bytes/2=8 words of data (AUD0LEN)
move.l    #clock/16,d1		; 1/16 = one sixteenth of the clock
divu.w    do3(pc),d1        ; <<< CHANGE THE FIRST OPERAND OF
; THIS MOVE TO GENERATE MORE
; NOTES >>>
move.w    d1,$a6(a6)        ; AUD0PER with the calculated period
move.w    #64,$a8(a6)        ; AUD0VOL at maximum (0 dB)
move.w    #$8001,$96(a6)        ; Turns on AUD0 DMA in DMACONW

WLMB:    btst    #6,$bfe001        ; Wait for the left mouse button
bne.s    WLMB

or.w    #$8000,d7        ; turns on bit 15 (SET/CLR)
move.w    #$0001,$96(a6)        ; dmacon - turns off aud0
move.w    d7,$96(a6)        ; dmacon - resets OS DMA
move.l	4.w,a6
jsr    -$7e(a6)        ; _LVOEnable
rts


DO3:    dc.w    528        ;note frequencies
RE3:    dc.w    528*9/8
MI3:    dc.w    528*5/4
FA3:    dc.w    528*4/3
G3:    dc.w    528*3/2
A3:    dc.w    528*5/3
B3:    dc.w    528*15/8
C4:    dc.w    528*2


******************************************************************************

SECTION    Sample,DATA_C    ;when read by the DMA, it must be in CHIP

; 16-value harmonic created with the IS of the trash'm-one

Armonica:
DC.B	$19,$46,$69,$7C,$7D,$6A,$47,$1A,$E8,$BB,$97,$84,$83,$95,$B8,$E5

END

******************************************************************************

At 1/16 of the clock period (= 35468095/16), the harmonic would be read at 1 Hz,
since it is 16 bytes long, and - as we said in the first source - by reading
16 per second, the entire harmonic is read once per second (= 1 Hz, in fact);
by dividing the period 1/16 by the frequency of the note to be played contained
in RAM at the relative label, the reading frequency of 1 Hz
is multiplied by the frequency of the note, causing the hardware to read the entire
harmonic several times per second.

It would have been possible to achieve the same result by inserting the following code into 
AUD0PER:

[...]
move.l    #clock,d1        ; clock constant
move.w    do3(pc),d2        ; ...or any other frequency...
mulu.w    #16,d2            ; d2.l = 16*note frequency
divu.w    d2,d1            ; d1.w = clock/(16*freq)
move.w    d1,$a6(a6)        ; set AUD0PER
[...]

