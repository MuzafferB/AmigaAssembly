
; Lesson 14-3a.s    ** PRECISION TONES AND SEMITONES **


SECTION    Tones,CODE

Start:
move.l    4.w,a6
jsr    -$78(A6)        ; _LVODisable
bset    #1,$bfe001        ; Turns off the low-pass filter
lea    $dff000,a6
move.w    $2(a6),d7        ; dmaconr - Save OS DMA

move.l    #harmonica,$a0(a6)    ; AUD0LCH.w+AUD0LCL.w=AUD0LC.l
move.w    #16/2,$a4(a6)        ; 16 bytes/2=8 words of data (AUD0LEN)

move.l    #12*2+2,d0        ; RE3
moveq    #16,d1
bsr.s    halftone2per
move.w    d0,$a6(a6)        ; AUD0PER

move.w    #64,$a8(a6)        ; AUD0VOL at maximum (0 dB)
move.w    #$8001,$96(a6)        ; turns on AUD0 DMA in DMACONW

WLMB:
btst    #6,$bfe001        ;wait for left mouse button
bne.s    WLMB

or.w    #$8000,d7        ; turn on bit 15 (SET/CLR)
move.w    #$0001,$96(a6)		; turns off DMA
move.w    d7,$96(a6)        ; dmacon - resets OS DMA
move.l    4.w,a6
jsr    -$7e(a6)        ; _LVOEnable
rts

******************************************************************************
;            ‘HalfTone To Period’
;
; Calculates the period to be inserted in AUDxPER given the semitone starting from DO1
;
; d0.w = semitone (starting from DO1=0)
; d1.w = harmonic length (in bytes)
******************************************************************************

Clock    equ    3546895
DO1    equ    131            ; Frequency [Hz] of DO 1st octave

HalfTone2Per:
divu.w    #12,d0
move.w    #do1,d2
lsl.w    d0,d2
swap    d0
add.w    d0,d0
add.w    d0,d0
mulu.w    halftones(pc,d0.w),d2
divu.w    halftones+2(pc,d0.w),d2
move.l    #clock,d0
mulu.w    d2,d1
divu.w    d1,d0
rts            ; [d0.w=sampling period]

HalfTones:
dc.w    10000,10000    ;DO=1.0
dc.w    10595,10000    ;DO#=1.0595
dc.w    11225,10000    ;RE=1.1225
dc.w    11892,10000	;RE#=1.1892
dc.w	12599,10000	;MI=1.2599
dc.w	13348,10000	;FA=1.3348
dc.w	14142,10000	;FA#=1.4142
dc.w	14983,10000	;SOL=1.4983
dc.w	15874,10000	;SOL#=1.5874
dc.w	16818,10000	;LA=1.6818
dc.w	17818,10000	;LA#=1.7818
dc.w	18877,10000	;SI=1.8877

******************************************************************************

SECTION    Sample,DATA_C    ;when read by the DMA, it must be in CHIP

; 16-value harmonic created with the IS of trash'm-one

Harmonic:
DC.B	$19,$46,$69,$7C,$7D,$6A,$47,$1A,$E8,$BB,$97,$84,$83,$95,$B8,$E5

END

******************************************************************************

This source code is not very different from the previous one, as it
includes a small routine that calculates the sampling period based
on a given note; the only difference is that now you can generate not only the 7
notes of a scale of several octaves, but also the notes of the ‘black keys’ of the
piano, i.e. SHARPS(#)/FLATS(b): in short, you are not limited
to whole tones, but you can also play SEMITONES.
First of all, one difference is obvious: the values in the
‘HalfTones’ table are much larger than those in the ‘Notes’ table in the previous example,
 and this is to ensure greater precision: in fact, the two
words indicate respectively the NUMERATOR and DENOMINATOR of the fraction that
indicates the ratio between a note and the C in a scale, and the ratio, in fact,
does NOT change. Let's take G as an example: in ‘Notes’ the ratio is 3/2 = 1.5,
in ‘HalfTones’ it is 14983/10000 = 1.4983; as you can see, the ratio
is almost the same (the difference is NEGLIGIBLE).
In ‘Notes’ I have used the ‘classic’ fractions found in many
acoustic physics books, which have the advantage of having small numerators and
denominators that are easy to memorise; the values of ‘HalfTones’,
on the other hand, in addition to showing the ratios of all the notes of the semitone scale
in semitones, have an accuracy of 4 decimal places beyond the ‘comma’ (which
is simulated by multiplying by very large numbers and then dividing by
10^number of decimal places), i.e. up to thousandths.
The ‘HalfTone2Per’ subroutine works roughly like the ‘Note2Per’ subroutine;
the only difference is in the expression of the input parameter: this
time it is necessary to indicate the desired semitone starting from C1.
Therefore, if we want to play an F1, we must set d0.w=5, since
there are 5 semitones between C1 and F1.

In music, 1 tone = 2 semitones, and each scale has 6 tones = 12 semitones;
between one note and another there is 1 tone, excluding the frequency intervals
between E and F, and between B and C of the octave after, which are equal to only 1 semitone.

Since the frequency must be doubled at each octave, the increase
in frequency of the notes - within a scale and beyond - is NOT constant,
but EXPONENTIAL based on 2.
Therefore, calculating the ratios of notes within a scale is not
as simple as it might seem: knowing that the interval of the
ratios in a 12-semitone scale is equal to 1 (from 1 of the first C to 2 of the
C of the next octave), each semitone is 1/12 away from the other on the axis
of the abscissa of a Cartesian graph (x, y) that has the exponential function
: Y = 2^X; considering the interval 0<=X<=1, we have
a branch of the curve 2^0<=Y<=2^1 = 1<=Y<=2 on the ordinate; now, at every 12th
from X=0, we calculate the relative value in Y, 12 times: Y = 2^(1/12),
Y = 2^(2/12), Y = 2^(3/12), and so on until Y=2^(12/12) = 2, which
corresponds to the ratio of the 12th semitone, or the C of the
next octave; Each of the decimal values obtained corresponds to the value
to be multiplied by the frequency of the C of the desired octave to obtain
the frequency of the note required in the same octave, and can be reduced
to a fraction (or rather, MUST be reduced to a fraction with non-decimal numbers
so that the 68000 can calculate with whole numbers by “simulating”
the decimal point).
For example, to find the ratio between the frequency of an A# and a C (=1/1):
Y = 2^(10/12) = 2^0.8333 (...periodic...) = 1.7818 (rounded); this decimal number
can easily be converted to the fraction 17818/10000 (it is
actually 17818 thousandths)
Now, if, for example, we want an A3#: C3 = 131 * 2^(3-1) = 131 * 2 * 2 =
= 131 * 4 = 524 Hz; A3# = (524 * 17818)/10000 = 933 Hz.
