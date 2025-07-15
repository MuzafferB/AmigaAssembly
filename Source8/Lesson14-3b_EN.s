
; Lesson 14-3b.s    ** 4-VOICE HARMONIC CHORDS **


section    arm4,code	

Start:
move.l    4.w,a6
jsr    -$78(A6)        ; _LVODisable
bset    #1,$bfe001        ; Turns off the low-pass filter
lea    $dff000,a6
move.w    $2(a6),d7        ; dmaconr - Save OS DMA

move.l    #harmonica,$a0(a6)    ; AUD0LCH.w+AUD0LCL.w=AUD0LC.l
move.l    #harmonica,$b0(a6)    ; AUD1LCH.w+AUD1LCL.w=AUD1LC.l
move.l    #harmonica,$c0(a6)    ; AUD2LCH.w+AUD2LCL.w=AUD2LC.l
move.l    #harmonica,$d0(a6)    ; AUD3LCH.w+AUD2LCL.w=AUD3LC.l
move.w    #16/2,$a4(a6)        ; 16 bytes/2=8 words of data (AUD0LEN)
move.w    #16/2,$b4(a6)        ; 16 bytes/2=8 words of data (AUD1LEN)
move.w    #16/2,$c4(a6)        ; 16 bytes/2=8 words of data (AUD2LEN)
move.w    #16/2,$d4(a6)        ; 16 bytes/2=8 words of data (AUD3LEN)

moveq    #16,d1
moveq    #12*1+0,d2        ;DO2 (C chord)

move.l    d2,d0
bsr.s    halftone2per
move.w    d0,$a6(a6)        ; AUD0PER
addq.w	#2*2,d2            ; + 2 tones = MI
move.l    d2,d0
bsr.s    halftone2per
move.w    d0,$b6(a6)        ; AUD1PER
addq.w    #2+1,d2            ; + 1 tone + 1 semitone = SOL
move.l    d2,d0
bsr.s    halftone2per
move.w    d0,$c6(a6)        ; AUD2PER
addq.w    #2+1,d2            ; + 1 tone + 1 semitone = A#
move.l    d2,d0
bsr.s    halftone2per
move.w    d0,$d6(a6)        ; AUD3PER

move.w    #64,$a8(a6)        ; AUD0VOL at maximum (0 dB)
move.w    #64,$b8(a6)        ; AUD1VOL at maximum (0 dB)
move.w    #64,$c8(a6)        ; AUD2VOL at maximum (0 dB)
move.w    #64,$d8(a6)        ; AUD3VOL at maximum (0 dB)
move.w    #$800f,$96(a6)        ; Turns on AUD0-AUD3 DMA in DMACONW

WLMB:
btst    #6,$bfe001        ;wait for left mouse button
bne.s    WLMB
or.w    #$8000,d7        ; turn on bit 15 (SET/CLR)
move.w    #$000f,$96(a6)		; turns off DMA
move.w    d7,$96(a6)        ; resets OS DMA
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
move.l    d2,-(SP)
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
divu.w    d1,d0        ; DIVISION BY ZERO!!!
move.l    (SP)+,d2
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

This source code is identical to the previous one.
The only new feature is the use of all the hardware voices of the Amiga sound chip...
 nothing complicated, really: to play the same
sample at different frequencies, simply set all the
AUDxLC, AUDxLEN and AUDxVOL registers to the same value for all channels, and
only vary the periods for the AUDxPER registers.

In music, to create a MAJOR CHORD with 3 or more notes (we have
done it with 4, just so as not to leave the last voice idle...), you need to play
SIMULTANEOUSLY all the correct notes that form the chord.
Here is the general pattern:

************ MAJOR CHORDS ***********
+------+--------------------------------+
| NOTE | KEY |
+------+--------------------------------+
| 1st | root note of the chord |
| 2nd | + 2 tones = 4 semitones |
| 3rd | + 1 tone and a half = 3 semitones |
| 4th | + 1 tone and a half = 3 semitones |
+------+--------------------------------+

For example, for the E chord with 3 voices: E + G# + B; for the
A chord with 4 voices: A + C# + E + G.

