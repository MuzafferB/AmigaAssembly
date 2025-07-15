; Asm Course - LESSON xx: ** FREQUENCY MODULATION OF A HARMONIC **

SECTION    LESSONxx7b,CODE

Start:

lea    modfq,a0
moveq    #123,d0
move.w    #500-1,d7
.Lp1:    move.w    d0,(a0)+
addq.w    #1,d0
dbra    d7,.lp1
move.w    #500-1,d7
.Lp2:    move.w    d0,(a0)+
subq.w    #1,d0
dbra    d7,.lp2

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
move.w    #64,$b8(a6)

move.l    #modfq,$a0(a6)
move.w    #(modfq_end-modfq)/2,$a4(a6)
move.w    #clock/((modfq_end-modfq)/2),$a6(a6)

move.w    #$8010,$9e(a6)        ;set USE0P1

move.w    #$8203,$96(a6)        ;turn on AUD0 and AUD1 in DMACONW

WLMB:    btst    #6,$bfe001        ;wait for the left mouse button
bne.s    WLMB

move.w    #$0010,$96(a6)        ;turn off USE0P1
or.w    #$8000,d6        ;turn on bit 15 (SET/CLR)
move.w    d6,$9e(a6)        ;reset OS ADKCON
move.w    #$0003,$96(a6)        ;turn off AUD0 and AUD1
or.w    #$8000,d7        ;turn on bit 15 (SET/CLR)
move.w    d7,$96(a6)        ;resets OS DMA
move.l    4.w,a6
jsr    _LVOEnable(a6)
rts

SECTION    Sample,DATA_C    ;when read by DMA, must be in CHIP

Harmonica:    ;16-value harmonica created with the trash'm-one IC
DC.B    $19,$46,$69,$7C,$7D,$6A,$47,$1A,$E8,$BB,$97,$84,$83,$95,$B8,$E5
ModFq:
blk.w    500*2
ModFq_end:
END

This time, AUD1VOL has been set, which is not the case for
AUD1PER, which is continuously modified by the modulator channel; AUD0PER
has been set to read the 1000-word table in 2 seconds
with the clock constant divided by half the length of the table,
thus reading 500 words at 1 Hz, or reading the entire table in ‘half’ Hz.
