
; Asm Course - LESSON xx: ** PLAY VERY LONG SAMPLES EVEN IN FAST MODE **


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
bne.s    wlmb            ;run through the Wb and you will notice
btst    #10,$dff016		;how there is NO slowdown
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
Clock        equ    3546895
AFB_68010    equ    0
AttnFlags    equ    296

movem.l    d0-d2/a0-a1/a5-a6,-(sp)    ;save many registers because the
;libraries dirty d0-d2/a0-a1
lea    plsregs(pc),a5
movem.l    d0/a0,(a5)        ;fixed reference registers
movem.l    d0/a0,4*2(a5)		;work registers
move.l    4.w,a6
move.l    #MEMF_CHIP!MEMF_LARGEST,d1
jsr    _LVOAvailMem(a6)    ;-> d0.l=large chip block
cmp.l    #2*128*1024,d0		;d0.l > 256 kB ?
bls.s    .okmem            ;if NO: get the length of the block
move.l    #2*128*1024,d0        ;if YES: 256 kB is enough
.OkMem:    and.w	#~%111,d0        ;d0.l=total length aligned to 64 bits
move.l    d0,4*4(a5)
move.l    #MEMF_CHIP!MEMF_CLEAR,d1;MEMF_CLEAR: set allocated RAM to 0
jsr    _LVOAllocMem(a6)    ;allocate 2 adjacent 128 kB banks
tst.l    d0            ;d0.l=0 ?
beq.w    .bye            ;if YES: insufficient RAM -> exit
move.l    d0,4*5(a5)        ;save base of FIRST bank in chip
move.l	4*4(a5),d1
lsr.l    #1,d1
add.l    d1,d0
move.l    d0,4*6(a5)        ;save base of SECOND bank in chip
movem.l    4(sp),d1-d2        ;restore d1-d2 from stack
sub.l    a0,a0
move.l    4.w,a6
btst    #afb_68010,attnflags+1(a6)    ;68010+ ?
beq.s    .no010
lea    getvbr(pc),a5        ;go to routine with privileged commands
jsr    _LVOSupervisor(a6)    ;in supervisor mode with exec
.No010:    lea    $dff000,a6
move.w    #$0780,$9c(a6)        ;reset any IRQ requests
move.w    $1c(a6),oldint        ;save OS INTENA
move.w    #$0780,$9a(a6)		;mask INT AUD0-AUD3
move.l    $70(a0),oldlv4        ;save level 4 autovector
move.l    #lv4irq,$70(a0)        ;set new autovector
move.w    d2,$a8(a6)        ;set AUD0VOL
move.w    d2,$b8(a6)        ;set AUD1VOL
move.w    d2,$c8(a6)        ;set AUD2VOL
move.w    d2,$d8(a6)        ;set AUD3VOL
move.l    #clock,d2
divu.w    d1,d2            ;d2.w=clock/freq = sampling period
move.w    d2,$a6(a6)        ;set AUD0PER
move.w    d2,$b6(a6)		;set AUD1PER
move.w    d2,$c6(a6)        ;set AUD2PER
move.w    d2,$d6(a6)        ;set AUD3PER
move.w    $2(a6),olddma        ;save OS DMACON
move.w	#$c400,$9a(a6)        ;turn on AUD3 IRQ - that's all you need...
move.w    #$8400,$9c(a6)        ;force the IRQ to start...
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
move.w    #$0780,$9c(a6)		;reset all channel requests
move.w    #$0400,$9a(a6)        ;mask INT AUD3
move.l    oldlv4(pc),$70(a0)    ;reset OS autovector 4
move.w    #$000f,$96(a6)		;turns off all audio DMA
move.w    oldint(pc),d0
or.w    #8000,d0        ;sets SET/CLR, which is 0 in INTENAR 
move.w    d0,$9a(a6)        ;resets the OS INTENA
move.w    olddma(pc),d0
or.w    #$8000,d0        ;set SET/CLR which is at 0 in DMACONR
move.w    d0,$96(a6)        ;reset the OS DMACON
move.l    4.w,a6
movem.l    plsregs+4*4(pc),d0/a0-a1
cmp.l    a0,a1            ;a1 < a0 ? (a1 points to the bank with
blo.s    .min            ;the lowest address from which
move.l    a0,a1            ;the allocated memory starts?)
.Min:    jsr    _LVOFreeMem(a6)        ;return RAM to the system
movem.l    (sp)+,d0-d2/a0-a1/a5-a6
rts
;--------------------------------------
PlayLongSample_IRQ:
movem.l    d0-d2/a0-a1/a5-a6,-(sp)
lea    $dff000,a6
lea    plsregs+4*4(pc),a5
movem.l    -4*2(a5),d0/a0        ;d0.l=missing length/a0=sample base
movem.l	(a5),d1/a1        ;d1.l=bank length/a1=bank base
move.l    a1,$a0(a6)        ;set AUDLC
move.l    a1,$b0(a6)
move.l    a1,$c0(a6)
move.l    a1,$d0(a6)
lsr.l    #1,d1            ;meta' bank
cmp.l    d0,d1            ;meta' bank <= missing length ?
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
move.w    #$007,$180(a6)    ;blue when copying starts
.CopyLp:move.l    (a0)+,(a1)+
dbra    d1,.copylp
move.w    #$000,$180(a6)    ;black when finished
move.l    -4*1(a5),a0
add.l    d2,a0            ;point a0 to the next block
sub.l    d2,d0            ;length MINUS length played
bhi.s    .noloop            ;d0 => 1 ? (at least 1 byte still missing)
movem.l    plsregs(pc),d0/a0    ;if NO: reset original registers
.NoLoop:movem.l    d0/a0,-4*2(a5)		;save d0 and a0 in copies anyway
movem.l    4*1(a5),a0/a1        ;swap pointers to the 2 banks
exg    a0,a1        ;only one buffer is used
movem.l    a0/a1,4*1(a5)
move.w	#$820f,$96(a6)
movem.l	(sp)+,d0-d2/a0-a1/a5-a6
rts
;--------------------------------------
OldINT:	dc.w	0
OldDMA:	dc.w	0
OldLv4:    dc.l    0
PLSRegs:dc.l    0,0    ;length, sample pointer - fixed
dc.l    0,0    ;length, sample pointer - variables
dc.l    0,0,0    ;length, bank pointer 1, bank pointer 2 - fixed


***************************************
***** Level 4 Interrupt Handler *****
***************************************

cnop    0,8
Lv4IRQ:
btst    #10-8,$dff01e        ;IRQ AUD3 ?
beq.s    .exit
move.w    #$0780,$dff09c
bsr.w    playlongsample_irq
.Exit:    rte



SECTION    Sample,DATA_F

; MammaGamma by Alan Parsons Project (©1981)
Sample:
incbin    ‘assembler2:sorgenti8/Mammagamma.17897’
Sample_end:

END

With this sixth section of sources on the Amiga audio, we have moved on to
something more sophisticated: with this source (or, if you prefer to entrust the interrupt handlers
to the exec, modify it YOURSELF as in source 5b so as to use
SetIntVector - not necessary, in principle: the OS does not use
audio interrupts, in fact it has no level 4 server chain) you can
basically play anything you have in memory wherever it is
(as long as it occupies a single continuous block of RAM; making a sample player
into various chunks around the RAM would not be too difficult:
it would be sufficient to use this same source so that it reads different samples
at various points; the only problem would be to include a file by splitting it
- which the assembler does NOT do - with the DOS library routines that
read portions of files: at this point, once you have done the LOAD routine, you have
also made an excellent CLI player! You are finally able to play
a sample located anywhere in memory, in the largest chunk that AllocMem
can find (MEMF_ANY).

The routine is extremely simple: given a sample of
undetermined length in ANY RAM block (chip or fast), a
256 kB chip RAM block (MEMF_CHIP) is allocated - if possible - or not,
which is divided into two buffers of 128 kB - or less - one in which to copy
with a CPU loop, the data of the 128 kB sample - or less - into 128 kB - or less -
in order to be able to read the DMA.
The reason for using two buffers is very simple: while the audio plays one,
the CPU fills the other with the data following the one being read.

N.B.:	in truth, certain CPUs such as the 68040 or 68030 are so fast
that they can copy the entire 128 kB block - or less - in little more
than one raster; so even if you don't use two buffers, especially
when the buffer is very small, it is honestly impossible to hear
the DMA play the same data twice in the same looping buffer,
because the CPU has already copied it while the first words are still being read
.
The reasons why two separate buffers were used are
as follows: first of all, for elegance of coding: IN THEORY, the two
buffers are necessary; furthermore, on slow CPUs such as the 16-bit 68000
with access to the RAM of the Amiga 500, copying is not that instantaneous;
finally, as it stands, the routine would have a bug: the last block of the
sample would be played twice before looping (for practice,
try to understand why and adjust the routine...).

The minimum length for the buffers is 4 bytes each; try
allocating only 8 bytes in total and playing a sample at the maximum read frequency
(approx. 28000 Hz, period=123): yes, the 040
- no one knows how - manages to keep up with the DMA even with
2 longword buffers!!! Try it for yourself...

P.S.: on the _IRQ you will find 2 commented lines: these are used to change the background colour
every time the interrupt is called and the CPU starts
copying data from the source RAM to the buffers: remove the comments
to see what the processor is doing while
the DMA plays, unaware of the data change...