; Asm Course - LESSON xx: * MODULATING A HARMONIC IN AMPLITUDE AND FREQUENCY *

SECTION    LESSONxx7b,CODE

Start:

lea    modvolfq,a0
moveq    #0,d0
moveq    #123,d1
move.w    #64-1,d7
.Lp1:    move.w    d0,(a0)+
addq.w    #1,d0
move.w    d1,(a0)+
addq.w    #4,d1
dbra    d7,.lp1
move.w    #64-1,d7
.Lp2:    move.w    d0,(a0)+
subq.w    #1,d0
move.w    d1,(a0)+
subq.w    #4,d1
dbra    d7,.lp2

_LVODisable    EQU    -120
_LVOEnable    EQU    -126

move.l    4.w,a6
jsr    _LVODisable(a6)

bset    #1,$bfe001        ;turns off the low-pass filter

lea    $dff000,a6
move.w    $2(a6),d7        ;saves OS DMA
move.w    $10(a6),d6        ;saves OS ADKCON

Clock    equ    3546895

move.l    #harmonica,$b0(a6)
move.w    #16/2,$b4(a6)

move.l    #modvolfq,$a0(a6)
move.w    #(modvolfq_end-modvolfq)/2,$a4(a6)
move.w    #clock/((modvolfq_end-modvolfq)/2),$a6(a6)

move.w    #$8011,$9e(a6)        ;set USE0V1 and USE0P1

move.w    #$8203,$96(a6)        ;turn on AUD0 and AUD1 in DMACONW

WLMB:    btst	#6,$bfe001        ;wait for the left mouse button
bne.s    WLMB

move.w    #$0011,$96(a6)        ;turn off USE0V1 and USE0P1
or.w    #$8000,d6        ;turn on bit 15 (SET/CLR)
move.w    d6,$9e(a6)        ;reset OS ADKCON
move.w    #$0003,$96(a6)        ;turn off AUD0 and AUD1
or.w    #$8000,d7        ;turn on bit 15 (SET/CLR)
move.w    d7,$96(a6)        ;resets OS DMA
move.l    4.w,a6
jsr    _LVOEnable(a6)
rts

SECTION    Sample,DATA_C    ;when read by DMA, must be in CHIP

Harmonica:    ;16-value harmonica created with the IC from the trash'm-one
DC.B    $19,$46,$69,$7C,$7D,$6A,$47,$1A,$E8,$BB,$97,$84,$83,$95,$B8,$E5
ModVolFq:
blk.w    64*2*2
ModVolFq_end:
END

Here's how to modulate both the amplitude and frequency of a sound: the table
consists of 2 alternating values, first a word with the volume at 7 bits for
AUD1VOL and then a second word with the 16-bit period for AUD0PER; with the
same sequence, the data also enters AUD0DAT: first the volume, then
the period.
Of course, both the frequency modulation and
amplitude modulation bits of channel 0 have been set with respect to channel 1.
