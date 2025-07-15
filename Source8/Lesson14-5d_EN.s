
; Asm Course - LESSON xx: ** FAKE-SURROND EFFECT **
; N.B.: works well on slow computers due to the
; delay between the two voices per speaker.

; debug, same as before

WLMB    macro
\@    btst    #6,$bfe001
bne.s    \@
endm

WRMB    macro
\@    btst    #10,$dff016
bne.s    \@
endm

SECTION    PlayLongSamples,CODE

Start:
bset    #1,$bfe001        ;turns off the low-pass filter
;>>>> PARAMETERS <<<<
lea    sample,a0        ;sample address
move.l    #sample_end-sample,d0    ;sample length in bytes
move.w    #17897,d1        ;read frequency
moveq    #64,d2            ;volume

moveq    #0,d3            ;play voice 0
bsr.w    playlongsample_init
moveq    #3,d3            ;play voice 3
bsr.w    playlongsample_init
WLMB
moveq    #1,d3            ;play voice 1
bsr.s    playlongsample_init
moveq    #2,d3            ;play voice 2
bsr.s    playlongsample_init
WRMB

moveq    #0,d3            ;turn off voice 0 
bsr.w    playlongsample_restore
moveq    #1,d3            ;turn off voice 1
bsr.w    playlongsample_restore
moveq    #2,d3            ;turn off voice 2
bsr.w    playlongsample_restore
moveq    #3,d3            ;turn off voice 3
bsr.w    playlongsample_restore
rts



***************************************
***** Play Long Sample Routines *****
***************************************

PlayLongSample_init:
;[a0=sample adr]
;[d0.l=length.b sample, d1.w=frequency, d2.w=volume]
;[d3.w=voice (0..3)]
;* The Lv4 IRQ vector must be available *

_LVOSupervisor    equ	-30
Clock        equ    3546895
AFB_68010    equ    0
AttnFlags    equ    296

movem.l    d0-d7/a0-a1/a6,-(sp)
and.w    #3,d3            ;maximum 3 channels
lea    $dff000,a6
moveq    #1,d4
lsl.w    d3,d4
move.w    d4,d6
and.w    $2(a6),d4        ;voice DMA mask
move.w    #1<<7,d5
lsl.w    d3,d5
move.w    d5,d7
and.w    $1c(a6),d5        ;INT mask of the entry
add.w    d3,d3            ;d3=d3*2: expresses word offset
lea    olddmas(pc),a1
move.w    d4,(a1,d3.w)		;save old status of DMA of entry
lea    oldints(pc),a1
move.w    d5,(a1,d3.w)        ;save old status of INT of entry
move.w    d7,$9c(a6)        ;reset any IRQs
move.w    d6,$96(a6)        ;turn off DMA of entry
move.w    d7,$9a(a6)        ;turn off INT of entry
sub.l    a1,a1				;FAST CLEAR An
move.l    4.w,a6
btst    #afb_68010,attnflags+1(a6)    ;68010+ ?
beq.s    .no010
lea    .getvbr(pc),a5
jsr    _LVOSupervisor(a6)
.No010:    cmp.l    #lv4irq,$70(a1)
beq.s    .nochg
move.l    $70(a1),oldlv4        ;save the level 4 autovector
move.l    #lv4irq,$70(a1)        ;set the new autovector
.NoChg:    lsl.w    #4-1,d3            ;d3=d3*8: now expresses an offset of 16 bytes
lea    $dff0a0,a6
move.w    d2,$8(a6,d3.w)        ;sets AUDxVOL
move.l    #clock,d2
divu.w    d1,d2            ;d2.w=clock/freq = sampling period
move.w    d2,$6(a6,d3.w)        ;set AUDxPER
lea    $dff000,a6
or.w    #$8000,d7
move.w    d7,$9a(a6)		;turns on INT of entry
lea    plsregs(pc,d3.w),a1
movem.l    d0/a0,(a1)        ;fixed registers
movem.l    d0/a0,4*2(a1)        ;working registers
move.w    d7,$9c(a6)        ;force IRQ of entry...
movem.l    (sp)+,d0-d7/a0-a1/a6
rts
.GetVBR:
dc.l    $4e7a9801    ;movec    vbr,a1    ;exception vector base
rte
;--------------------------------------
PLSRegs:    ;MUST BE BETWEEN _INIT AND _IRQ FOR THE ADDRESSING MODE
;USED: XX(pc,Rn) WHICH ALLOWS ONLY 8 BITS WITH SIGN AT ‘XX’
PLSAud0Regs:    dc.l    0,0    ;length, pointer - fixed
dc.l    0,0    ;length, pointer - variables
PLSAud1Regs:    dc.l    0,0    ;length, pointer - fixed
dc.l    0,0    ;length, pointer - variables
PLSAud2Regs:    dc.l    0,0    ;length, pointer - fixed
dc.l    0,0    ;length, pointer - variables
PLSAud3Regs:    dc.l    0,0    ;length, pointer - fixed
dc.l    0,0    ;length, pointer - variables
;--------------------------------------
PlayLongSample_IRQ:
;[a1=PLSAudxRegs]
;[d3.w=voce]
movem.l	d0-d3/a0-a1/a6,-(sp)
and.w    #3,d3            ;maximum 3 voices
move.w    d3,d2
lsl.w    #4,d3            ;d3=d3*16: expresses offset of 16 bytes
lea    plsregs(pc,d3.w),a1
movem.l    4*2(a1),d0/a0		;grab the work registers
lea    $dff0a0,a6
move.l    a0,$0(a6,d3.w)        ;set AUDxLC
move.l    d0,d1            ;d1.l=missing length
and.l    #~(128*1024-1),d1	;more than 128 kB still missing
bne.s    .long            ;if YES: go to .long
move.l    d0,d1            ;if NO: use missing length (< 128 kB)
.Long:    lsr.l    #1,d1            ;convert length to be played into WORD
move.w    d1,$4(a6,d3.w)        ;set AUDxLEN
add.l    #128*1024,a0		;point a0 to the next block
sub.l    #128*1024,d0        ;length MINUS 128 kB
bhi.s    .noloop            ;d0 => 1 ? (at least 1 byte still missing)
movem.l    (a1),d0/a0        ;if NO: reset original registers
.NoLoop:movem.l    d0/a0,4*2(a1)        ;save d0 and a0 in copies anyway
move.w    #%1<<7,d0
lsl.w    d2,d0
move.w    d0,$dff09c        ;reset IRQ of the voice so as not to suffer
;a new interrupt as soon as it exits
moveq    #%1,d0
lsl.w    d2,d0
or.w    #$8200,d0        ;turn on DMA of the voice
move.w    d0,$dff096
movem.l	(sp)+,d0-d3/a0-a1/a6
rts
;--------------------------------------
PlayLongSample_restore:
;[d3.w=voce (0..3)]
movem.l	d0-d1/d3/a0/a6,-(sp)
and.w    #3,d3            ;maximum 3 voices
lea    $dff000,a6
moveq    #1,d0
lsl.w    d3,d0
move.w    #1<<7,d1
lsl.w    d3,d1
move.w    d1,$9c(a6)        ;reset any IRQs for the voice
move.w    d0,$96(a6)        ;turn off DMA for the voice
move.w    d1,$9a(a6)        ;turn off INT for the voice
move.w    $1c(a6),d0
and.w    #0780,d0        ;turn off all entries = last entry?
bne.s    .NoOFF
sub.l    a0,a0            ;if YES:...
move.l    4.w,a6
btst    #afb_68010,attnflags+1(a6)
beq.s    .no010
lea    .getvbr(pc),a5
jsr    _LVOSupervisor(a6)
.No010:    move.l    oldlv4(pc),$70(a0)    ;...reset the old autovector
.NoOFF:    lea    $dff000,a6
add.w    d3,d3            ;d3=d3*2: expresses word offset
move.w    oldints(pc,d3.w),d0
or.w    #$8000,d0
move.w    d0,$9a(a6)        ;turns on old INT
move.w    olddmas(pc,d3.w),d0
or.w    #$8000,d0
move.w    d0,$96(a6)		;turns on old DMAs
movem.l    (sp)+,d0-d1/d3/a0/a6
rts
.GetVBR:
dc.l    $4e7a8801    ;movec    vbr,a0    ;exception vector base
rte
;--------------------------------------
OldINTs:dc.w	0,0,0,0
OldDMAs:dc.w	0,0,0,0
OldLv4:	dc.l	0


***************************************
***** Level 4 Interrupt Handler *****
***************************************

cnop    0,8
Lv4IRQ:
move.w    d3,-(sp)
pea    .exit(pc)        ;pushes the return for the RTS onto the stack

moveq    #3,d3
btst    #10-8,$dff01e        ;aud3 IRQ ?
bne.w    playlongsample_irq    ;if YES: bracha (no return) to _IRQ

moveq    #2,d3
btst    #9-8,$dff01e        ;aud2 IRQ ?
bne.w    playlongsample_irq

moveq    #1,d3
btst    #8-8,$dff01e        ;aud1 IRQ ?
bne.w    playlongsample_irq

moveq    #0,d3            ;aud0 IRQ ?
btst    #7,$dff01f
bne.w    playlongsample_irq

.Exit:    move.w    (sp)+,d3		;also return for the _IRQ RTS
rte




SECTION    Sample,DATA_C

; MammaGamma by Alan Parsons Project (©1981)
Sample:
incbin    ‘assembler2:sorgenti8/Mammagamma.17897’
Sample_end:

END


There's not much to say... It's not real surround, but it sounds like it... Try
delaying the two voices more with a loop or something similar and listen
to the effect (it can produce a ‘power saw’ effect with a long delay).
...Be careful not to delay too much: you'll create an echo...