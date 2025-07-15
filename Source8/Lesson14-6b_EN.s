; Asm Course - LESSON xx: ** PLAY VERY LONG SAMPLES EVEN IN FAST 2 **


SECTION    PlayLongSamples,CODE

Start:
bset    #1,$bfe001        ;turns off the low-pass filter
;>>>> PARAMETERS <<<<
lea    sample,a0        ;sample address
move.l    #sample_end-sample,d0    ;sample length in bytes
move.w    #17897,d1        ;read frequency
moveq    #64,d2            ;volume
bsr.s    playlongsample_init    ;INIT routine (start)....
;....CPU free....
WLMB:    btst    #6,$bfe001        ;head LMB+RMB...try it, then
bne.s    wlmb            ;run through Wb and you will notice
btst    #10,$dff016        ;that there is NO slowdown
bne.s    wlmb            ;....DMA magic!

bsr.w    playlongsample_restore    ;RESTORE routine (turns everything off)
rts


***************************************
***** Play Long Sample Routines *****
***************************************

PlayLongSample_init:
;[a0=sample adr]
;[d0.l=length.b sample, d1.w=frequency, d2.w=volume]
;* The AutoVector Lv4 IRQ must be available *

_LVOSupervisor    equ    -30
_LVOAllocMem    EQU    -198
_LVOFreeMem    EQU    -210
_LVOAvailMem    EQU    -216
MEMF_CHIP    equ    1<<1
MEMF_LARGEST    equ    1<<17
MEMF_CLEAR    equ    1<<16
AFB_68010    equ    0
AttnFlags    equ    296

Clock        equ    3546895
MaxBanco1    equ    32*1024
MaxBanco2    equ    32*1024

movem.l    d0-d2/a0-a1/a5-a6,-(sp)
lea    plsregs(pc),a5
movem.l    d0/a0,(a5)        ;fixed reference registers
movem.l    d0/a0,4*2(a5)        ;working registers
move.l    4.w,a6
move.l    #MEMF_CHIP!MEMF_LARGEST,d1
jsr    _LVOAvailMem(a6)    ;-> d0.l=large chip block
cmp.l    #maxbank1,d0        ;d0.l > MaxBank1 kB ?
bls.s    .okmem1            ;if NO: get the length of the block
move.l    #maxbank1,d0        ;if YES: MaxBank1 kB is sufficient
.OkMem1:and.w    #~%11,d0        ;d0.l=length of bank aligned to 32 bits
move.l    d0,4*4(a5)
move.l    #MEMF_CHIP!MEMF_CLEAR,d1;MEMF_CLEAR: set allocated RAM to 0
jsr    _LVOAllocMem(a6)    ;allocate 1 bank from MaxBanco1 kB
tst.l    d0            ;d0.l=0 ?
beq.w    .bye            ;if YES: insufficient RAM -> exit
move.l    d0,4*5(a5)        ;save base of FIRST bank in chip
move.l    #MEMF_CHIP!MEMF_LARGEST,d1
jsr    _LVOAvailMem(a6)    ;-> d0.l=large chip block
cmp.l    #maxbank2,d0        ;d0.l > MaxBank2 kB ?
bls.s    .okmem2            ;if NO: get the length of the block
move.l    #maxbank2,d0        ;if YES: MaxBank2 kB is sufficient
.OkMem2:and.w    #~%11,d0        ;d0.l=length of bank aligned to 32 bits
move.l    d0,4*6(a5)
move.l    #MEMF_CHIP!MEMF_CLEAR,d1;MEMF_CLEAR: set allocated RAM to 0
jsr    _LVOAllocMem(a6)    ;allocate 1 bank from MaxBanco2 kB
tst.l    d0            ;d0.l=0 ?
beq.w .bye            ;if YES: insufficient RAM -> exit
move.l d0,4*7(a5)        ;save base of SECOND bank in chip
movem.l 4(sp),d1-d2        ;restore d1-d2 from stack
sub.l a0,a0
move.l 4.w,a6
btst    #afb_68010,attnflags+1(a6)    ;68010+ ?
beq.s    .no010
lea    getvbr(pc),a5        ;goes to routine with privileged commands
jsr    _LVOSupervisor(a6)    ;in supervisor mode with exec
.No010:    lea    $dff000,a6
move.w    #$0780,$9c(a6)        ;reset any IRQ requests
move.w    $1c(a6),oldint        ;save OS INTENA
move.w	#$0780,$9a(a6)        ;mask INT AUD0-AUD3
move.l    $70(a0),oldlv4        ;save level 4 autovector
move.l    #lv4irq,$70(a0)        ;set new autovector
move.w    d2,$a8(a6)        ;set AUD0VOL
move.w    d2,$b8(a6)        ;set AUD1VOL
move.w    d2,$c8(a6)        ;set AUD2VOL
move.w    d2,$d8(a6)        ;set AUD3VOL
move.l    #clock,d2
divu.w    d1,d2            ;d2.w=clock/freq = sampling period
move.w    d2,$a6(a6)        ;set AUD0PER
move.w    d2,$b6(a6)        ;set AUD1PER
move.w    d2,$c6(a6)        ;set AUD2PER
move.w    d2,$d6(a6)        ;set AUD3PER
move.w    $2(a6),olddma        ;save OS DMACON
move.w    #$c400,$9a(a6)        ;turn on AUD3 IRQ - that's all you need...
move.w    #$8400,$9c(a6)        ;force IRQ to start...
movem.l    (sp)+,d0-d2/a0-a1/a5-a6
.Bye:    rts
;--------------------------------------
GetVBR:
dc.l    $4e7a8801    ;movec    vbr,a0    ;base of exception vectors
rte
;--------------------------------------
PlayLongSample_restore:
movem.l    d0-d2/a0-a1/a5-a6,-(sp)
sub.l    a0,a0
move.l    4.w,a6
btst    #afb_68010,attnflags+1(a6)
beq.s    .no010
lea    getvbr(pc),a5
jsr    _LVOSupervisor(a6)
.No010:    lea    $dff000,a6
move.w    #$0780,$9c(a6)        ;reset all channel requests
move.w    #$0400,$9a(a6)        ;mask INT AUD3
move.l    oldlv4(pc),$70(a0)    ;reset OS autovector 4
move.w	#000f,$96(a6)        ;turns off all audio DMAs
move.w    oldint(pc),d0
or.w    #8000,d0        ;sets SET/CLR, which is 0 in INTENAR 
move.w    d0,$9a(a6)        ;reset the OS INTENA
move.w    olddma(pc),d0
or.w    #$8000,d0        ;set SET/CLR which is at 0 in DMACONR
move.w    d0,$96(a6)        ;reset the DMACON of the OS
move.l    4.w,a6
movem.l    plsregs+4*4(pc),d0/a1
jsr    _LVOFreeMem(a6)        ;free the RAM of the FIRST bank
movem.l    plsregs+4*6(pc),d0/a1
jsr    _LVOFreeMem(a6)        ;frees the RAM of the SECOND bank
movem.l    (sp)+,d0-d2/a0-a1/a5-a6
rts
;--------------------------------------
PlayLongSample_IRQ:
movem.l    d0-d2/a0-a1/a5-a6,-(sp)
lea    $dff000,a6
lea    plsregs(pc),a5
movem.l    4*2(a5),d0/a0		;d0.l=missing length/a0=sample base
movem.l    4*4(a5),d1/a1        ;d1.l=bank length/a1=bank base
move.l    a1,$a0(a6)        ;set the AUDLC
move.l    a1,$b0(a6)
move.l    a1,$c0(a6)
move.l    a1,$d0(a6)
cmp.l    d0,d1            ;bank <= missing length?
bls.s    .longc
move.l    d0,d1            ;if NO: copy and play missing length
.LongC:    move.l    d1,d2
lsr.l    #1,d1            ;divide by 2 for AUDLEN in word
move.w    d1,$a4(a6)        ;set AUDLEN
move.w    d1,$b4(a6)
move.w    d1,$c4(a6)
move.w    d1,$d4(a6)
lsr.l    #1,d1            ;divide by 2 to copy longword
subq.w    #1,d1
move.w    #$007,$180(a6)	;blue when it starts copying
.CopyLp:move.l    (a0)+,(a1)+
dbra    d1,.copylp
move.w    #$000,$180(a6)    ;black when it finishes
move.l    4*3(a5),a0
add.l    d2,a0            ;points a0 to the next block
sub.l    d2,d0            ;length MINUS length played
bhi.s    .noloop            ;d0 => 1 ? (at least 1 byte still missing)
movem.l    (a5),d0/a0		;if NO: reset original registers
.NoLoop:movem.l    d0/a0,4*2(a5)        ;save d0 and a0 in copies anyway
movem.l    4*4(a5),d0-d1/a0-a1    ;swap pointers and length
exg    d0,a0		;only one buffer is used
exg    d1,a1        ;
movem.l    d0-d1/a0-a1,4*4(a5)
move.w    #$820f,$96(a6)
movem.l    (sp)+,d0-d2/a0-a1/a5-a6
rts
;--------------------------------------
OldINT:    dc.w    0
OldDMA:    dc.w    0
OldLv4:    dc.l    0
PLSRegs:dc.l    0,0    ;length, sample pointer - fixed
dc.l    0,0    ;length, sample pointer - variables
dc.l    0,0    ;length, bank pointer 1 - fixed
dc.l    0,0    ;length, bank pointer 2 - fixed


***************************************
***** Level 4 Interrupt Handler *****
***************************************

cnop    0,8
Lv4IRQ:
btst #10-8,$dff01e        ;IRQ AUD3 ?
beq.s .exit
move.w #$0780,$dff09c
bsr.w playlongsample_irq
.Exit: rte



SECTION    Sample,DATA_F

; MammaGamma by Alan Parsons Project (©1981)
Sample:
incbin    ‘assembler2:sorgenti8/Mammagamma.17897’
Sample_end:

END


This time, not much has changed: now the banks are of independent length and
position, no longer adjacent or of equal length.
The routine has not undergone any particular changes: it allocates the two buffers
separately, and in the _IRQ it simply exchanges their lengths,
in addition to the pointers.

N.B.:    The notes from the previous example also apply here.
