
; Lesson 14-5a.s    ** PLAY VERY LONG SAMPLES **


SECTION    PlayLongSamples,CODE

Start:
bset    #1,$bfe001        ; turns off the low-pass filter

; >>>> PARAMETERS <<<<
lea    sample,a0        ; sample address
move.l    #sample_end-sample,d0    ; sample length in bytes
move.w    #17897,d1        ; read frequency
moveq    #64,d2            ; volume
bsr.s    playlongsample_init    ; INIT routine (start)....
; ....CPU free....
WLMB:
btst    #6,$bfe001        ; head LMB+RMB...try, therefore,
bne.s    wlmb            ; to turn to Wb and you will notice
btst    #10,$dff016        ; that there is NO slowdown
bne.s    wlmb            ; ....the magic of DMA!

bsr.w    playlongsample_restore    ; RESTORE routine (turns everything off)
rts


***************************************
***** Play Long Sample Routines *****
***************************************
;
; a0    = sample adr
; d0.l = sample length, d1.w=frequency, d2.w=volume
;
; The AutoVector Lv4 IRQ must be available


_LVOSupervisor    equ    -30
Clock        equ    3546895
AFB_68010    equ    0
AttnFlags    equ    296

PlayLongSample_init:
movem.l    d2/a0/a6,-(sp)
movem.l    d0/a0,plsregs        ; fixed reference registers
movem.l    d0/a0,plsregs+4*2    ; working registers
sub.l    a0,a0			; FAST CLEAR An
move.l    4.w,a6
btst    #afb_68010,attnflags+1(a6)    ; 68010+ ?
beq.s    .no010
lea    getvbr(pc),a5
jsr    _LVOSupervisor(a6)
.No010:
lea    $dff000,a6
move.w    #$0780,$9c(a6)        ; clear any IRQ requests
move.w    $1c(a6),oldint        ; save OS INTENA
move.w    #$0780,$9a(a6)		; mask INT AUD0-AUD3
move.l    $70(a0),oldlv4        ; save level 4 autovector
move.l    #lv4irq,$70(a0)        ; set new autovector
move.w    d2,$a8(a6)        ; set AUD0VOL
move.w    d2,$b8(a6)        ; set AUD1VOL
move.w    d2,$c8(a6)        ; set AUD2VOL
move.w    d2,$d8(a6)        ; set AUD3VOL
move.l    #clock,d2
divu.w    d1,d2			; d2.w=clock/freq = sampling period
move.w    d2,$a6(a6)        ; set AUD0PER
move.w    d2,$b6(a6)        ; set AUD1PER
move.w    d2,$c6(a6)        ; set AUD2PER
move.w    d2,$d6(a6)		; set AUD3PER
move.w    $2(a6),olddma        ; save DMACON of the OS
move.w    #$8400,$9a(a6)        ; turn on AUD3 IRQ - that's all you need...
move.w    #$8400,$9c(a6)        ; force the IRQ to start...
movem.l	(sp)+,d2/a0/a6
rts

;--------------------------------------
GetVBR:
dc.l    $4e7a8801    ;movec    vbr,a0    ;base of exception vectors
rte
;--------------------------------------

PlayLongSample_restore:
movem.l    d0/a0/a6,-(sp)
sub.l    a0,a0
move.l    4.w,a6
btst    #afb_68010,attnflags+1(a6)
beq.s    .no010
lea    getvbr(pc),a5
jsr    _LVOSupervisor(a6)
.No010:
lea    $dff000,a6
move.w    #$0780,$9c(a6)        ; reset all channel requests
move.w    #$0400,$9a(a6)        ; mask INT AUD3
move.l    oldlv4(pc),$70(a0)    ; reset OS autovector 4
move.w    #$000f,$96(a6)        ; turn off all audio DMAs
move.w    oldint(pc),d0
or.w    #$8000,d0        ; sets SET/CLR, which is 0 in INTENAR
move.w    d0,$9a(a6)        ; resets the OS INTENA
move.w    olddma(pc),d0
or.w    #$8000,d0		; set SET/CLR which is at 0 in DMACONR
move.w    d0,$96(a6)        ; reset the DMACON of the OS
movem.l    (sp)+,d0/a0/a6
rts

;--------------------------------------

PlayLongSample_IRQ:
movem.l    d0-d1/a0-a1/a6,-(sp)
lea    $dff000,a6
movem.l    plsregs+4*2(pc),d0/a0    ; grabs the working registers
move.l    a0,$a0(a6)        ; sets AUD0LC
move.l    a0,$b0(a6)        ; set AUD1LC
move.l    a0,$c0(a6)        ; set AUD2LC
move.l    a0,$d0(a6)        ; set AUD3LC
move.l    d0,d1			; d1.l=missing length
and.l    #~(128*1024-1),d1    ; more than 128 kB still missing
bne.s    .long            ; if YES: go to .long
move.l    d0,d1            ; if NO: use missing length (< 128 kB)
.Long:    lsr.l    #1,d1            ; convert the length to be played to .W
move.w    d1,$a4(a6)        ; set AUD0LEN
move.w    d1,$b4(a6)        ; set AUD1LEN
move.w    d1,$c4(a6)        ; set AUD2LEN
move.w    d1,$d4(a6)        ; set AUD3LEN
add.l    #128*1024,a0        ; point a0 to the next block
sub.l    #128*1024,d0        ; length MINUS 128 kB
bhi.s    .noloop            ; d0 => 1 ? (AT LEAST 1 byte missing)
movem.l    plsregs(pc),d0/a0    ; if NO: reset original registers
.NoLoop:movem.l    d0/a0,plsregs+4*2	; save d0 and a0 in copies
move.w    #$820f,$96(a6)        ; turn on all audio DMAs, and
; generate the IRQ immediately, in case
; the audio is turned on for the first time
movem.l    (sp)+,d0-d1/a0-a1/a6
rts

;--------------------------------------

OldINT:    dc.w    0
OldDMA:    dc.w    0
OldLv4:    dc.l    0
PLSRegs: dc.l    0,0    ; length, pointer - fixed
dc.l    0,0    ; length, pointer - variables


***************************************
***** Level 4 Interrupt Handler *****
***************************************

cnop    0,8
Lv4IRQ:
btst #10-8,$dff01e
beq.s .exit
move.w #$0400,$dff09c		
;immediately turn off the request, because
;the DMA
;is turned on in the routine and the new IRQ is immediately generated:
;by turning off the request after the routine
;you run the risk of cancelling the
;IRQ request on the first cycle
;of the interrupt (as soon as the
;routine is started).
bsr.w    playlongsample_irq
.Exit:
rte



SECTION    Sample,DATA_C

; MammaGamma by Alan Parsons Project (©1981)
Sample:
incbin    ‘assembler2:sorgenti8/Mammagamma.17897’
Sample_end:

END


Now things start to get complicated again... We have started using interrupts
and routines that are no longer - let's say - trivial.
As already mentioned in the LESSON, the audio channels are associated with 4
different interrupts assigned to level 4 of the 680x0; these interrupts are
generated by the hardware whenever a channel is forced to read data
in memory starting from the address contained in its AUDLC: they therefore occur
as soon as the DMA is turned on and every time at the beginning of a new sample loop.
* As soon as a channel starts playing a sample from the beginning, in addition to the IRQ being
‘fired’, its AUDLC remains unchanged and, therefore, ALTERABLE:
This is how the ‘PlayLongSample’ routine works: every time the DMA
begins to read a piece (128 kB or less, depending on whether the
sample missing to be played is longer than the maximum loopable AUDLEN)
the interrupt is generated, and the AUDxLC location registers (all 4, in this
case, since they are all used to play the same data) are
recalculated and advanced or moved backwards according to the ‘piece’ of sample
they were PREVIOUSLY pointing to and which the DMA is NOW reading *.
*** Basically, with this technique, it is possible to play many
128 kB pieces - or less, as far as the last piece is concerned - of audio data
adjacent in memory on the Amiga, without hearing the ‘break’ between one and the other ***.
 

N.B.:    once the routine has started, it continues to loop the sample
indefinitely only from the interrupt code, so ** it is COMPLETELY
INDEPENDENT: in other words, after ‘_init’, return to main
and you will have normal control of all hardware (except the sound,
of course) and the CPU (except the level 4 interrupt, which is
the one used by ‘PlayLongSample’) **.
When you want to turn off the sample, call ‘_restore’ and everything
will return to how it was before calling ‘_init’ (including any
audio interrupt routines!).

P.S.:    One last clarification: only one IRQ has been used here for
all voices, since they all played the same thing at the same time,
 namely that of voice 3, which is the highest
hardware priority.
In theory, nothing should change if you use the one for another voice,
 * provided that the others are masked - or that they are ignored by the handler - otherwise, at the end of each block
read, 4 interrupts would be generated.