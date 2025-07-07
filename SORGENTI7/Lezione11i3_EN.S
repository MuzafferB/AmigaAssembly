
; Lesson 11i3.s    - Fantasy in COP minor

SECTION    GnippiCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’ ; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET	EQU	%1000001010000000    ; only copper DMA

WaitDisk    EQU    30    ; 50-150 when saving (depending on the case)

START:
bsr.w    Write        ; Create the copperlist...

lea    $dff000,a5
MOVE.W	#DMASET,$96(a5)        ; DMACON - enables bitplane, copper
; and sprites.

move.l    CopperEffPointer,$80(a5)
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$12000,d2	; line to wait for = $FF
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $FF
BNE.S	Waity1
Wait:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $FF
BEQ.S    Wait

bsr.w    main

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse
rts            ; exit


CopperEffPointer:
dc.l    Copperlist

colmemory:
dc.l	colbuf



*****************************************************************************
;	Routine che crea la copperlist
*****************************************************************************

;	__/\__
;	\()()/
;    /_\/_\
;     \/

cxstart        equ    $26    ; X position from which to start
cystart        equ    $1c    ; Y position from which to start
ylinee        equ    280    ; number of Y lines
xlinee        equ    10    ; number of X sections
yDistanza    equ    1    ; vertical distance
xDistance    equ    20    ; HORIZONTAL distance between ‘stripes’


write:
move.l    CopperEffPointer(pc),a0    ; copper address
moveq    #cystart,d0        ; Y start position
move.w    #ylinee-1,d4        ; number of Y lines to draw
cr2loop:
moveq	#cxstart,d1        ; start X position
moveq    #xlinee-1,d3        ; number of horizontal blocks to be done
FaiOrizz:
move.w    d1,d2        ; X in d2
ori.b    #1,d2        ; select only bit 1
move.b    d0,(a0)+    ; WAIT - Y coordinate
move.b    d2,(a0)+    ; WAIT - X coordinate
move.w    #$fffe,(a0)+    ; second word of the wait
move.w    #$180,(a0)+    ; colour register 0
clr.w (a0)+ ; colour0 (now reset)
add.w #xDistance,d1 ; trigger next ‘strip’ X position
dbra d3,FaiOrizz ; draw entire horizontal line

addq.w    #yDistance,d0    ; add the Y distance
dbra    d4,cr2loop    ; draw all the lines
move.l    #$fffffffe,(a0)+ ; end of copperlist!
rts

*****************************************************************************
;    Routine that modifies the copperlist
*****************************************************************************

;    __/\__
;    \ oO /
;    /_<>_\
;     \/

speed        equ    6
stadd        equ	100


main:
move.l    colmemory(pc),a0    ; colour table
lea    pointer1(pc),a1        ; pointer 1
lea    addtable(pc),a2        ; table with values to be added
moveq    #0,d4
move.w    pointer2(pc),d4        ; pointer 2 in d4
addq.w    #speed,d4        ; + speed
andi.w    #$1ff,d4        ; select only 9 bits (max 511)
move.w    d4,pointer2        ; save in pointer 2
bclr.l    #8,d4            ; reset bit 8
beq.s    nosub            ; =0 (was it 256?)
move.w    #$100,d1
sub.w    d4,d1
move.w    d1,d4
nosub:
add.w    #stadd,d4    ; skip 100
moveq	#xlines-1,d1    ; number of X lines
Cstart:
clr.w    d0
move.b    (a2)+,d0    ; take value from addtable
bclr.l    #7,d0
bne.s    pstripe
bclr.l    #6,d0
bne.s    sub
bclr.l    #5,d0
bne.s    add
back:
dbra    d1,Cstart    ; do for all lines
bra.s    copy

*****************************************************************************

add:
bsr.s    addr
bra.s    back

sub:
bsr.s	subr
bra.s	back	

sub1:
bsr.s	subr
bra.s	sback

add1:
bsr.s	addr
bra.s	sback

*****************************************************************************

;	__/\__
;    \-OO-/
;    /_-)_\
;     \/

colours        equ    210    ; number of colours

addr:
moveq    #0,d2
move.w    (a1),d2
add.w    d0,d2
cmp.w    #colours-2,d2    ; are the colours finished?
blo.s    noclr
clr.w    d2
noclr:
move.w    d2,(a1)+
bra.s    do_it

*****************************************************************************

;    __/\__
;    \[oO]/
;    /_{}_\
;     \/

subr:
moveq    #0,d2
move.w    (a1),d2
sub.w    d0,d2
bpl.s    nomove
move.w    #colours-2,d2
nomove:
move.w    d2,(a1)+
do_it:
lea    colortable(pc),a4
add.l    d2,a4
move.w    #ylinee/2-1,d2
do_loop:
move.l    (a4)+,(a0)+    ; put colours in coplist
dbra    d2,do_loop
rts

*****************************************************************************

;    \ _ /
;     \ (ö) /
;     \ '(_)` /
;     \ ¯ ¯ /

pstripe:
move.l    a0,d3
bclr.l    #5,d0
bne.s    add1
bclr.l    #6,d0
bne.s    sub1
	
clear:
move.w    #ylinee/2-1,d2
clloop:
clr.l    (a0)+        ; clear all lines
dbra    d2,clloop
sback:
move.l    d3,a0
add.l    d4,a0
moveq    #stlinee/4-1,d2
lea    stable(pc),a4
csloop:
move.l    (a4)+,(a0)+    ; copy colours in cop from stable
dbra    d2,csloop
move.l    d3,a0
add.l    #ylinee*2,a0
bra.s    back

*****************************************************************************

;     :
;     _|_
;    _ __/__/\__ _
;     \__\/
;     |
;     :

copy:
move.l    colmemory(pc),a0
move.l    CopperEffPointer(pc),a1
addq.w    #6,a1
move.w    #ylinee-1,d0    ; draw all Y lines
coloop:
move.w	(a0),(a1)
move.w    ylinee*2(a0),8(a1)    ; copy from colmemory to coplist
move.w    ylinee*4(a0),8*2(a1)
move.w    ylinee*6(a0),8*3(a1)
move.w    ylinee*8(a0),8*4(a1)
move.w    ylinee*10(a0),8*5(a1)
move.w    ylinee*12(a0),8*6(a1)
move.w    ylinee*14(a0),8*7(a1)
move.w    ylinee*16(a0),8*8(a1)
move.w	ylinee*18(a0),8*9(a1)
lea	8*10(a1),a1
addq.w	#2,a0
dbra	d0,coloop
rts

*****************************************************************************
;			TABELLE DEI COLORI
*****************************************************************************

colortable:
dc.w	$001,$002,$003,$004,$005,$006,$007,$008,$009,$00a
dc.w	$00b,$00c,$00d,$00e,$00f
dc.w    $01f,$02f,$03f,$04f,$05f
dc.w    $06f,$07f,$08f,$09f,$0af,$0bf,$0cf,$0df,$0ef,$0ff
dc.w    $0fe,$0fd,$0fc,$0fb,$0fa,$0f9,$0f8,$0f7,$0f6,$0f5
dc.w	$0f4,$0f3,$0f2,$0f1,$0f0,$1f0,$2f0,$3f0,$4f0,$5f0
dc.w	$6f0,$7f0,$8f0,$9f0,$af0,$bf0,$cf0,$df0,$ef0,$ff0
dc.w	$fe0,$fd0,$fc0,$fb0,$fa0,$f90,$f80,$f70,$f60,$f50
dc.w	$f40,$f30,$f20,$f10,$f00,$f01,$f02,$f03,$f04,$f05
dc.w	$f06,$f07,$f08,$f09,$f0a,$f0b,$f0c,$f0d,$f0e,$f0f
dc.w	$e0e,$d0d,$c0c,$b0b,$a0a,$909,$808,$707,$606
dc.w	$505,$404,$303,$202,$101,$000
colorend:
dc.w	$001,$002,$003,$004,$005,$006,$007,$008,$009,$00a
dc.w    $00b,$00c,$00d,$00e,$00f
dc.w    $01f,$02f,$03f,$04f,$05f
dc.w    $06f,$07f,$08f,$09f,$0af,$0bf,$0cf,$0df,$0ef,$0ff
dc.w    $0fe,$0fd,$0fc,$0fb,$0fa,$0f9,$0f8,$0f7,$0f6,$0f5
dc.w	$0f4,$0f3,$0f2,$0f1,$0f0,$1f0,$2f0,$3f0,$4f0,$5f0
dc.w	$6f0,$7f0,$8f0,$9f0,$af0,$bf0,$cf0,$df0,$ef0,$ff0
dc.w    $fe0,$fd0,$fc0,$fb0,$fa0,$f90,$f80,$f70,$f60,$f50
dc.w	$f40,$f30,$f20,$f10,$f00,$f01,$f02,$f03,$f04,$f05
dc.w	$f06,$f07,$f08,$f09,$f0a,$f0b,$f0c,$f0d,$f0e,$f0f
dc.w	$e0e,$d0d,$c0c,$b0b,$a0a,$909,$808,$707,$606
dc.w	$505,$404,$303,$202,$101,$000
dc.w	$001,$002,$003,$004,$005,$006,$007,$008,$009,$00a
dc.w	$00b,$00c,$00d,$00e,$00f
dc.w	$01f,$02f,$03f,$04f,$05f
dc.w	$06f,$07f,$08f,$09f,$0af,$0bf,$0cf,$0df,$0ef,$0ff
dc.w	$0fe,$0fd,$0fc,$0fb,$0fa,$0f9,$0f8,$0f7,$0f6,$0f5
dc.w	$0f4,$0f3,$0f2,$0f1,$0f0,$1f0,$2f0,$3f0,$4f0,$5f0
dc.w	$6f0,$7f0,$8f0,$9f0,$af0,$bf0,$cf0,$df0,$ef0,$ff0
dc.w	$fe0,$fd0,$fc0,$fb0,$fa0,$f90,$f80,$f70,$f60,$f50
dc.w	$f40,$f30,$f20,$f10,$f00,$f01,$f02,$f03,$f04,$f05
dc.w	$f06,$f07,$f08,$f09,$f0a,$f0b,$f0c,$f0d,$f0e,$f0f
dc.w	$e0e,$d0d,$c0c,$b0b,$a0a,$909,$808,$707,$606
dc.w	$505,$404,$303,$202,$101,$000
dc.w	$001,$002,$003,$004,$005,$006,$007,$008,$009,$00a
dc.w	$00b,$00c,$00d,$00e,$00f
dc.w    $01f,$02f,$03f,$04f,$05f
dc.w    $06f,$07f,$08f,$09f,$0af,$0bf,$0cf,$0df,$0ef,$0ff
dc.w    $0fe,$0fd,$0fc,$0fb,$0fa,$0f9,$0f8,$0f7,$0f6,$0f5
dc.w	$0f4,$0f3,$0f2,$0f1,$0f0,$1f0,$2f0,$3f0,$4f0,$5f0
dc.w	$6f0,$7f0,$8f0,$9f0,$af0,$bf0,$cf0,$df0,$ef0,$ff0
dc.w	$fe0,$fd0,$fc0,$fb0,$fa0,$f90,$f80,$f70,$f60,$f50
dc.w	$f40,$f30,$f20,$f10,$f00,$f01,$f02,$f03,$f04,$f05
dc.w	$f06,$f07,$f08,$f09,$f0a,$f0b,$f0c,$f0d,$f0e,$f0f
dc.w	$e0e,$d0d,$c0c,$b0b,$a0a,$909,$808,$707,$606
dc.w    $505,$404,$303,$202,$101,$000


pointer1:
dcb.w    10,0

pointer2:
dcb.w    10,0

addtable:
dc.b    $c4,$a2,$44,$a0,$24,$42,$a0,$22,$a4,$c2

; colorsequcolorend-colortable

numctab        equ    512


stripe:
dc.w    numctab*4

; The grey bar that ‘crosses’ the coloured ones

stable:
dc.w    $000,$111,$222,$444,$555,$666,$777,$888,$888,$999,$999
dc.w    $aaa,$aaa,$bbb,$bbb,$ccc,$ccc,$ddd,$ddd,$eee,$eee,$eee
dc.w	$fff,$fff,$fff,$fff,$fff,$eee,$eee,$eee,$ddd,$ddd,$ccc
dc.w    $ccc,$bbb,$bbb,$aaa,$aaa,$999,$999,$888,$888,$777,$666
dc.w	$555,$444,$333,$222,$111,$000
stend:

stlinee	equ	stend-stable

*****************************************************************************
;			Buffer vari
*****************************************************************************

section	bau1,bss

clsize		equ	2*xlinee*ylinee

colbuf:
ds.b	clsize


*****************************************************************************
;			Copperlist
*****************************************************************************

section    bau2,bss_c

csize        equ    xlinee*ylinee*8+12

Copperlist:
ds.b    csize

END

You wouldn't think there are no bitplanes enabled, would you?
