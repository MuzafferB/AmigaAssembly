
; Lesson 14-2b.s    ** PLAYING A MULTIPLE-NOTE HARMONICA 2 **


SECTION    Harmonica2b,CODE

Start:
move.l    4.w,a6
jsr    -$78(A6)        ; _LVODisable
bset    #1,$bfe001		; Turns off the low-pass filter
lea    $dff000,a6
move.w    $2(a6),d7        ; dmaconr - Save OS DMA

move.l    #armonica,$a0(a6)    ; AUD0LCH.w+AUD0LCL.w=AUD0LC.l
move.w	#16/2,$a4(a6)        ; 16 bytes/2=8 words of data (AUD0LEN)

move.l    #1<<16!2,d0        ; plays a RE3
moveq    #16,d1            ; length=16 bytes
bsr.s    note2per
move.w    d0,$a6(a6)        ; AUD0PER with the result

move.w    #64,$a8(a6)        ; AUD0VOL to maximum (0 dB)
move.w    #$8201,$96(a6)        ; turns on AUD0 DMA in DMACONW

WLMB:    btst	#6,$bfe001        ; wait for left mouse button
bne.s    WLMB

or.w    #$8000,d7        ; turn on bit 15 (SET/CLR)
move.w    #$0001,$96(a6)        ; dmacon - turn off aud0
move.w    d7,$96(a6)        ; dmacon - reset OS DMA
move.l    4.w,a6
jsr    -$7e(a6)        ; _LVOEnable
rts

******************************************************************************
;            ‘Note To Period’
;
; Calculates the period to be inserted in AUDxPER given the note and octave
;
; d0hi.w = note (0[DO]..6[SI])
; d0lo.w = octave (0[1]..3[4])
; d1.w     = harmonic length (in bytes)
******************************************************************************

Clock    equ    3546895
DO1    equ    131            ; frequency [Hz] of DO 1st octave

Note2Per:
move.w    #do1,d2            ; d2.w=DO1
lsl.w    d0,d2			; d2.w=DOx (according to the octave in d0lo.w)
swap    d0            ; d0lo.w=d0hi.w
add.w    d0,d0            ; d0.w=d0.w*4
add.w    d0,d0            ; for longword offset from NOTES
mulu.w    notes(pc,d0.w),d2    ; d2.l=DOx*num
divu.w    notes+2(pc,d0.w),d2    ; d2.l=DOx*num/den=note frequency
mulu.w    d1,d2            ; d2.l=note freq. * length=sampling freq.
move.l    #clock,d0        ; d0.l=clock constant
divu.w    d2,d0            ; d0.w=clock/sampling frequency
rts                ; [d0.w=sampling period]

Notes:
DO:    dc.w    1,1
RE:    dc.w    9,8
MI:    dc.w    5,4
FA:    dc.w    4,3
SOL:    dc.w    3,2
LA:    dc.w    5,3
SI:    dc.w    15,8


******************************************************************************

SECTION    Sample,DATA_C    ;when read by the DMA, it must be in CHIP

; 16-value harmonic created with the IS of the trash'm-one

Armonica:
DC.B	$19,$46,$69,$7C,$7D,$6A,$47,$1A,$E8,$BB,$97,$84,$83,$95,$B8,$E5

END

******************************************************************************

As explained in the lesson text, at each octave there is a DOUBLING
of frequency, so if the C of the first octave has 131 Hz, C2 has 262 Hz,
C3 has 524 Hz, etc.; within the scale there are very precise ratios
between the frequencies of the 7 notes: C=1, D=9/8, E=5/4, F=4/3, G=3/2, A=5/3,
B=15/8 (and the next C = 2); with this table, it is very easy to
calculate the frequency of any note in any octave starting
from a given note in a given octave.

The subroutine ‘Note2Per’ requires the following input parameters: d0 with the note (from 0
for C to 6 for B) on the high word, and the octave (from 0 for the first to 3
for the fourth) on the low word, and d1, with the length of the sample in bytes.
It calculates the sampling period to be inserted in the AUDxPER registers
only by knowing the frequency of a DO1 and the desired note.
How does it work? Simple: first of all, note that the ratios between the notes
relative to the DO of each scale have been inserted as word data, with
the first indicating the numerator of the fraction and the second indicating the
denominator; the routine first doubles the frequency of the starting DO1
as many times as there are octaves expressed in the lower word of the
d0 parameter, simply by shifting to the left (multiplying by *2 with each
single shift) the value 132 (frequency of DO1) by as many bits as the
value in d0lo.w; then, based on the note specified in d0hi.w, it takes from
Notes+d0hi.w*4 a longword with the numerator in the high word and
the denominator of the fraction indicating the ratio of the desired note
within the scale from the relative DO (DO=1/1) in the low word; then,
calculates the frequency of the desired octave note by multiplying the fraction
by the frequency of the DO of the octave itself, and then multiplying this
by the numerator of the fraction (upper word) and then dividing the whole by
the denominator (lower word); Finally, once the exact frequency has been obtained,
the sampling period is calculated so that the sample of length d1.w
is read ENTIRELY at the note frequency (as mentioned in the previous examples,
 we do not calculate the sampling period in reading derived
from the number of bytes per second that must be read, but the sampling period
derived from the number of times that the ENTIRE harmonic must be
read in 1 second, equal to the product of the frequency and the length in bytes
of the wave: a MUCH higher value!), dividing the clock constant by
the product of the sample length and the note frequency.

If, for example, we want to play a G2, we must provide the value 4 (5th
note) in the high word of d0 and 1 (2nd octave) in the low word.
The frequency of the note will be:
((132 * 2^octave) * 3)/2
|         / \
DO1 num den
\____________/
|
DOx

** Basically, the routine first calculates the DO of the right octave, then
calculates 3/2 (‘three halves’) **.

N.B.:    as it stands, the ‘Note2Per’ routine has a limitation: as you should know,
 the 68000 performs 16bit*16bit=32bit multiplications and
32bit/16bit=16bit (the remainder on the high word of the result), so
it is not possible to play samples that are too long at too high a frequency,
 simply because the product of length and frequency must
be divided by the clock constant, and therefore, the divisor of the
DIVU must be in a word (without sign, fortunately).
** In practice, however, this limitation does not harm anyone, because
the reading speed = note frequency * sample length cannot
exceed 28836 Hz, a value that fits comfortably within a word:
THEREFORE, DO NOT USE TOO HIGH FREQUENCIES FOR TOO LONG SAMPLES **