; Asm Course - LESSON xx: ** MODULATING THE AMPLITUDE OF A STEREO HARMONICA**

SECTION    LESSONxx7a2,CODE

Start:

lea    modvol1,a0
moveq    #0,d0
moveq    #65-1,d7
.Lp1:    move.w    d0,(a0)+
addq.w    #1,d0
dbra    d7,.lp1
subq.w    #1,d0
.Lp2:    move.w    d0,(a0)+
dbra    d0,.lp2

lea    modvol2,a0
moveq    #65,d0
moveq    #65-1,d7
.Lp3:    subq.w    #1,d0
move.w    d0,(a0)+
dbra    d7,.lp3
moveq    #65-1,d7
.Lp4:    move.w    d0,(a0)+
addq.w	#1,d0
dbra    d7,.lp4

_LVODisable    EQU    -120
_LVOEnable    EQU    -126

move.l    4.w,a6
jsr    _LVODisable(a6)

bset    #1,$bfe001        ;turns off the low-pass filter

lea    $dff000,a6
move.w    $2(a6),d7        ;save OS DMA
move.w    $10(a6),d6        ;save OS ADKCON

Clock    equ    3546895

move.l    #harmonica,$b0(a6)
move.w    #16/2,$b4(a6)
move.w    #clock/(16*440),$b6(a6)    ;LA2
move.l    #harmonica,$d0(a6)
move.w    #16/2,$d4(a6)
move.w    #clock/(16*440),$d6(a6)    ;LA2

move.l    #modvol1,$a0(a6)
move.w    #(modvol1_end-modvol1)/2,$a4(a6)
move.w    #clock/((modvol1_end-modvol1)/2),$a6(a6)
move.l    #modvol2,$c0(a6)
move.w    #(modvol2_end-modvol2)/2,$c4(a6)
move.w    #clock/((modvol2_end-modvol2)/2),$c6(a6)

move.w    #$8005,$9e(a6)        ;set USE0V1 and USE2V3

move.w    #$820f,$96(a6)        ;turns on AUD0-AUD3 in DMACONW

WLMB:    btst    #6,$bfe001        ;waits for the left mouse button
bne.s    WLMB

move.w    #0005,$9e(a6)        ;turns off USE0V1 and USE2V3
or.w    #8000,d6        ;turns on bit 15 (SET/CLR)
move.w    d6,$9e(a6)        ;reset OS ADKCON
move.w    #$000f,$96(a6)        ;turn off AUD0-AUD3
or.w    #$8000,d7        ;turn on bit 15 (SET/CLR)
move.w    d7,$96(a6)        ;resets OS DMA
move.l    4.w,a6
jsr    _LVOEnable(a6)
rts

SECTION    Sample,DATA_C    ;when read by DMA, must be in CHIP

Harmonica:    ;16-value harmonica created with the trash'm-one IC
DC.B    $19,$46,$69,$7C,$7D,$6A,$47,$1A,$E8,$BB,$97,$84,$83,$95,$B8,$E5
ModVol1:
blk.w    65*2
ModVol1_end:
ModVol2:
blk.w    65*2
ModVol2_end:
END


This time we have created two ‘phase-shifted’ tables: the first, read from channel 0,
modulates the volume of channel 1 from 0 to 64 and from 64 to 0; the second, read from
channel 2, modulates the amplitude of channel 3 from 64 to 0 and from 0 to 64.
This causes an apparent ‘decentring’ effect of the sound output
in a STEREO system.
Here, the tables are read at a frequency of ‘half’ Hz, as
half the table is read at 1 Hz.

N.B.:    if you have a MONO system, you should hear a continuous note without
any modulation, as when the volume of one speaker decreases,
 the other increases and compensates for the output.
