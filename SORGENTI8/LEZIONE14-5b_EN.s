
; Asm Course - LESSON xx: ** PLAY VERY LONG SAMPLES UNDER OS **


SECTION    PlayLongSamples_OS,CODE

Start:
bset    #1,$bfe001

lea    sample,a0
move.l    #sample_end-sample,d0
move.w    #17897,d1
moveq    #64,d2
bsr.s    playlongsample_init

WLMB:    btst    #6,$bfe001
bne.s    wlmb
btst    #10,$dff016
bne.s    wlmb

bsr.w    playlongsample_restore
rts


***************************************
***** Play Long Sample Routines *****
***************************************

PlayLongSample_init:
;[a0=sample adr]
;[d0.l=length.b sample, d1.w=frequency, d2.w=volume]

Clock        equ    3546895
NT_Interrupt    equ    2
LN_Type        equ    8
LN_Pri        equ    9
LN_Name        equ    10
IS_Data        equ    14
IS_Code        equ    18
IS_SIZE        equ    22
_LVOSetIntVector    equ    -162

movem.l    d0/d2/a1/a6,-(sp)
movem.l    d0/a0,plsregs
movem.l    d0/a0,plsregs+4*2
movem.l    d1-d2,-(sp)
move.l    4.w,a6                ;exec base in a6
lea    aud1int_node(pc),a1        ;interrupt structure/node
move.b    #nt_interrupt,ln_type(a1)    ;node type: interrupt
move.l    #aud1int_name,ln_name(a1)	;node name public
move.l    #aud1int_data,is_data(a1)    ;point to data (a1-scratch)
move.l    #aud1int_code,is_code(a1)    ;point to code (a5-scratch)
moveq    #8,d0                ;INTENA/INTREQ bit (AUD1)
jsr    _LVOSetIntVector(a6)
move.l    d0,oldaud1int_node        ;d0.l=previous node
movem.l    (sp)+,d1-d2
lea    $dff000,a6
move.w    d2,$a8(a6)
move.w    d2,$b8(a6)
move.w    d2,$c8(a6)
move.w    d2,$d8(a6)
move.l    #clock,d2
divu.w    d1,d2
move.w    d2,$a6(a6)
move.w    d2,$b6(a6)
move.w    d2,$c6(a6)
move.w    d2,$d6(a6)
move.w    $2(a6),olddma
move.w    $1c(a6),oldint
move.w    #$8100,$9a(a6)
move.w    #$8100,$9c(a6)
movem.l	(sp)+,d0/d2/a1/a6
rts
;--------------------------------------
PlayLongSample_restore:
movem.l	d0/a1/a6,-(sp)
move.l    4.w,a6
move.l    oldaud1int_node(pc),a1        ;reset previous node
moveq     #8,d0                ;INTENA/INTREQ bit (AUD1)
jsr    _LVOSetIntVector(a6)
lea    $dff000,a6
move.w    #$0780,$9c(a6)            ;turns off all IRQ requests
move.w    #$0100,$9a(a6)
move.w    oldint(pc),d0
or.w    #$8000,d0
move.w    d0,$9a(a6)
move.w	#$000f,$96(a6)
move.w	olddma(pc),d0
or.w	#$8000,d0
move.w	d0,$96(a6)
movem.l	(sp)+,d0/a1/a6
rts
;--------------------------------------
PlayLongSample_IRQ:            ;<<< this routine is identical
movem.l    d0-d1/a0-a1/a6,-(sp)
lea    $dff000,a6
movem.l    plsregs+4*2(pc),d0/a0
move.l    a0,$a0(a6)
move.l    a0,$b0(a6)
move.l    a0,$c0(a6)
move.l    a0,$d0(a6)
move.l    d0,d1
and.l    #~(128*1024-1),d1
bne.s    .long
move.l    d0,d1
.Long:    lsr.l    #1,d1
move.w    d1,$a4(a6)
move.w    d1,$b4(a6)
move.w    d1,$c4(a6)
move.w    d1,$d4(a6)
add.l    #128*1024,a0
sub.l    #128*1024,d0
bhi.s    .noloop
movem.l    plsregs(pc),d0/a0
.NoLoop:movem.l    d0/a0,plsregs+4*2
move.w    #$820f,$96(a6)
movem.l	(sp)+,d0-d1/a0-a1/a6
rts
;--------------------------------------
OldDMA:	dc.w	0
OldInt:	dc.w	0
OldAud1Int_Node:dc.l	0
Aud1Int_Node:
blk.b    is_size        ;InterruptStructure length
even
Aud1Int_Name:
dc.b    ‘PlayLongSampleIRQ’,0
even
Aud1Int_Data:
PLSRegs:dc.l    0,0    ;length,pointer - fixed
dc.l    0,0	;length, pointer - variables

cnop 0,8
Aud1Int_Code:
move.w    #$0100,$dff09c
bsr.w    playlongsample_irq
rts



SECTION    Sample,DATA_C

; MammaGamma by Alan Parsons Project (©1981)
Sample:
incbin    ‘assembler2:sources8/Mammagamma.17897’
Sample_end:

END


This time, almost nothing has changed compared to the previous source:
we have only allocated the interrupt handler with the exec library, in order
to make everything a little more ‘friendly’ towards the operating system.

N.B.:    channel 1 interrupt has been used because, for the pseudo
software priorities of the exec, it is the first to be detected in the
internal handler in level 4 ROM.

P.S.:    a clarification regarding the difference between Server Chain
and interrupt Handler for the exec: certain interrupts (VERTB, COPER,
PORTS, EXTER and NMI) are more useful than others and are often used
by both the OS and user tasks; the exec must therefore allow
everyone to have their own interrupt routines, thus forming
“chains” of routines with different and specifiable
execution priorities managed by a single handler.
All other Paula interrupts (TBE, DSKBLK, SOFT, BLIT, AUD0-3,
RBF and DSKSYNC) are not seen as server chains but as handlers: each
can take complete possession of the interrupt data, without linking
or sharing it with any other task.
In our case, we have allocated channel 1 interrupt, the one with the
highest software priority, for exec (...and don't ask me why),
with _LVOSetIntVector because it requires a handler, not a server;
Furthermore, in the case of handlers, the priority of the interrupt structure node
does not need to be set because there are no
other servers in the chain, it is alone.

P.P.S.:    all the notes in the previous source code - apart from those that have been changed -
also apply here.

N.B.:    the EQUs come from the ‘exec/interrupt.i’ and
‘LVO1.3/exec_lib.i’ includes.
