; Asm Course - LESSON xx: ** MODULATING THE AMPLITUDE OF A HARMONICA **

SECTION    LESSONxx1,CODE

Start:

lea    modvol,a0
moveq    #0,d0
moveq    #65-1,d7
.Lp1:    move.w    d0,(a0)+
addq.w    #1,d0
dbra    d7,.lp1
subq.w    #1,d0
.Lp2:    move.w    d0,(a0)+
dbra    d0,.lp2

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
move.w    #clock/(16*880),$b6(a6)

move.l    #modvol,$a0(a6)
move.w    #(modvol_end-modvol)/2,$a4(a6)
move.w    #clock/(modvol_end-modvol),$a6(a6)

move.w    #$8001,$9e(a6)        ;set USE0V1

move.w    #$8203,$96(a6)        ;turn on AUD0 and AUD1 in DMACONW

WLMB:    btst    #6,$bfe001        ;wait for left mouse button
bne.s    WLMB

move.w    #$0001,$96(a6)        ;turn off USE0V1
or.w    #$8000,d6        ;turn on bit 15 (SET/CLR)
move.w    d6,$9e(a6)        ;reset OS ADKCON
move.w    #$0003,$96(a6)        ;turn off AUD0 and AUD1
or.w    #$8000,d7        ;turn on bit 15 (SET/CLR)
move.w    d7,$96(a6)        ;reset OS DMA
move.l    4.w,a6
jsr    _LVOEnable(a6)
rts

SECTION    Sample,DATA_C    ;when read by the DMA, it must be in CHIP

Harmonica:	;16-value harmonica created with the IC from the trash'm-one
DC.B    $19,$46,$69,$7C,$7D,$6A,$47,$1A,$E8,$BB,$97,$84,$83,$95,$B8,$E5
ModVol:
blk.w    65*2
ModVol_end:
END


Quite simply, we first generated a table of 130 values
from 0 to 64 and from 64 to 0 for the AUD1VOL volumes, which we had channel 0 read, while channel 1 read the harmonic at the frequency of A3 (880 Hz
wave frequency).
As the modulator channel period, we pretended that it was reading a normal sample and we gave it the read speed: for the table to be read in 1 second, the sampling period must be equal to the constant
As the modulator channel period, we pretended that it was reading a
normal sample and gave it the reading speed: for the table
to be read in 1 second, the sampling period must be equal
to the clock constant divided by the length of the table in bytes = 1 Hz.

N.B.:    note that the volume of channel 0 (AUD0VOL) has not been set,
as it is not necessary because its output is not
deamplified (64 = -0 dB) and goes directly to the AUD1VOL register.
AUD1VOL was not set at the beginning either, as it is immediately
modified by the modulator.
