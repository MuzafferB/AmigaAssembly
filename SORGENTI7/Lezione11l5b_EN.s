
; Lesson 11l5b.s - ‘Zoom’ of an animation measuring only 40*29 pixels.
;         The final resolution is 320*232, i.e. 8 times larger.
;         VERSION OPTIMISED USING TABULATION!

Section ZoomaPer8,code

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with “WO”

*****************************************************************************
include    ‘startup2.s’    ; save interrupt, dma, etc.
*****************************************************************************

; With DMASET we decide which DMA channels to open and which to close

;5432109876543210
DMASET    EQU    %1000001110000000    ; copper,bitplane DMA enabled

WaitDisk	EQU    30    ; 50-150 to save (depending on the case)

scr_bytes    = 40    ; Number of bytes per horizontal line.
; From this, the screen width is calculated
; by multiplying the bytes by 8: normal screen 320/8=40
; E.g. for a screen 336 pixels wide, 336/8=42
; example widths:
; 264 pixels = 33 / 272 pixels = 34 / 280 pixels = 35
; 360 pixels = 45 / 368 pixels = 46 / 376 pixels = 47
; ... 640 pixels = 80 / 648 pixels = 81 ...

scr_h        = 256    ; Screen height in lines
scr_x        = $81    ; Screen start, position XX (normal $xx81) (129)
scr_y        = $2c    ; Start of screen, position YY (normal $2cxx) (44)
scr_res        = 1    ; 2 = HighRes (640*xxx) / 1 = LowRes (320*xxx)
scr_lace	= 0    ; 0 = non-interlace (xxx*256) / 1 = interlace (xxx*512)
ham        = 0    ; 0 = non-ham / 1 = ham
scr_bpl        = 3    ; Number of bitplanes

; parameters calculated automatically

scr_w        = scr_bytes*8        ; screen width
scr_size    = scr_bytes*scr_h    ; screen size in bytes
BPLC0    = ((scr_res&2)<<14)+(scr_bpl<<12)+$200+(scr_lace<<2)+(ham<<11)
DIWS    = (scr_y<<8)+scr_x
DIWSt    = ((scr_y+scr_h/(scr_lace+1))&255)<<8+(scr_x+scr_w/scr_res)&255
DDFS    = (scr_x-(16/scr_res+1))/2
DDFSt    = DDFS+(8/scr_res)*(scr_bytes/2-scr_res)


START:
move.l    #planexpand,d0    ; bitplanebuffer
LEA    BPLPOINTERS,A0
MOVE.W    #3-1,D7        ; Number of planes
PointAnim:
MOVE.W    D0,6(A0)
SWAP    D0
MOVE.W    D0,2(A0)
ADDQ.W    #8,A0
SWAP    D0
ADDI.L    #40*29,D0    ; length of the 1 frame bitplane
DBRA    D7,PointAnim

bsr.w    PrecalcoTabba    ; Do turbo tab with precalculated ‘expanded’ bytes.

bsr.w    FaiCopallung    ; Do the copperlist that lengthens *8 with modules

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.
move.l    #COPPER,$80(a5)        ; Point our COP
move.w    d0,$88(a5)		; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:
MOVE.L	#$1ff00,d1    ; bit for selection via AND
MOVE.L    #$11500,d2    ; line to wait for = $115
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L	D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $115
BNE.S    Waity1
Waity2:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $115
BEQ.S    Waity2

bsr.w    ChangeFrame    ; Expand the current frame horizontally
; by 8 times: in practice, each bit becomes
; a byte.

btst    #6,$bfe001    ; Mouse pressed?
bne.s    mouse
rts            ; exit

****************************************************************************
; Routine that executes ‘ZoomaFrame’ every 7 frames, to slow down
****************************************************************************

ChangeFrame:
addq.b    #1,WaitFlag
cmp.b    #7,WaitFlag    ; Have 7 frames passed? (to slow down)
bne.s    NotNow
clr.b    WaitFlag
bsr.w    ZoomFrame    ; If yes, ‘espandiamo’ il prossimo frame!
NonOra:
rts

WaitFlag:
dc.w	0

****************************************************************************
; ‘expansion’ of the pic: each bit is tested, and depending on whether it
; is set or reset, a byte $FF or $00 is entered.
; This is an OPTIMISED version that uses a table containing
; the ‘expanded’ values for each possible byte (one of 256 possible).
****************************************************************************

;     .----.
;    ___ `-/\-“ ____
;    \_ \_/ \_/ __/
;     \___ ___/
;     _(_\/_)_
;     \ `” /
;     \``“”/
;	 :\ /:
;     ! \/ !
;     _|l_

ZoomaFrame:
move.l    AnimPointer(PC),A0 ; Current small frame (40*29)
lea    Planexpand,A1     ; Destination buffer (for 320*29)
MOVE.W    #(5*29*3)-1,D7     ; 5 bytes per line * 29 lines * 3 bitplanes
Animloop:
moveq    #0,d0
move.b    (A0)+,d0    ; Next byte in d0
lsl.w    #3,d0        ; d0*8 to find the value in the table
; (i.e. the offset from its start)
lea    Precalctab,a2
lea    0(a2,d0.w),a2    ; In a2, the address in the table of the 8 bytes
; needed for the 8-bit ‘expansion’.
move.l    (a2)+,(a1)+	; 4 bytes expanded
move.l    (a2),(a1)+    ; 4 bytes expanded (total 8 bytes!!)

DBRA    D7,Animloop    ; Convert the entire frame

add.l    #(5*29)*3,AnimPointer    ; Point to the next frame
move.l    AnimPointer(PC),A0
lea    EndAnim(PC),a1
cmp.l    a0,a1            ; Was it the last frame?
bne.s    Don't restart
move.l    #cannoanim,AnimPointer    ; If so, restart from the first
Don't restart:
rts

AnimPointer:
dc.l    cannoanim

****************************************************************************
; Routine that creates the copperlist that lengthens the pic by 8 times, using the
; modules in this way: waita one line, then set the modules to 0, so
; that it triggers the next line, then riwaita the line below and set the
; module to -40, so that the same line is ‘replicated’ every line
; below. After 7 wait lines, set the module to 0 for one line, causing
; the next line to trigger, then set the module back to -40 for another 7 lines
; to replicate it. The result is that each line is repeated 8 times.
****************************************************************************

FaiCopallung:
lea    AllungaCop,a0    ; Buffer in copperlist
move.l    #$3407fffe,d0    ; wait start
move.l    #$1080000,d1    ; bpl1mod 0
move.l    #$10a0000,d2    ; bpl2mod 0
move.l    #$108FFD8,d3    ; bpl1mod -40
move.l    #10aFFD8,d4    ; bpl1mod -40
moveq    #28-1,d7    ; number of loops
FaiCoppa:
move.l    d0,(a0)+    ; wait1
move.l    d1,(a0)+    ; bpl1mod = 0
move.l    d2,(a0)+    ; bpl2mod = 0
add.l    #$01000000,d0    ; skip 1 line
move.l    d0,(a0)+    ; wait2
move.l    d3,(a0)+    ; bpl1mod = -40
move.l    d4,(a0)+    ; bpl2mod = -40
add.l    #$07000000,d0    ; skip 7 lines
cmp.l    #$0407fffe,d0    ; Are we below $ff?
bne.s    NonPAl
move.l    #$ffdffffe,(a0)+ ; to access the pal area
NonPal:
dbra    d7,FaiCoppa
move.l    d0,(a0)+    ; final wait
rts

****************************************************************************
; Routine that precalculates all possible 8 bytes paired with possible
; 8 bits. All refers to $FF, i.e. 255.
****************************************************************************

PrecalcoTabba:
lea    Precalctabba,a1    ; Destination
moveq    #0,d0        ; Start from zero
FaiTabba:
MOVEQ    #8-1,D1        ; 8 bits to check and expand.
BYTELOOP:
BTST.l    D1,d0        ; Test the current loop bit
BEQ.S    bitclear    ; Is it zero?
ST.B    (A1)+        ; If not, set the byte (=$FF)
BRA.S    bitset
bitclear:
clr.B	(A1)+        ; If it is zero, reset the byte
bitset:
DBRA    D1,BYTELOOP    ; Check and expand all bits of the byte:
; D1 decrements each time, causing btst to be performed on
; all bits.
ADDQ.W    #1,D0        ; Next value
CMP.W    #256,d0        ; Have we done them all? (max $FF)
bne.s    FaiTabba
rts

****************************************************************************
; ANIMATION: 8 frames 40*29 pixels wide, 8 colours (3 bitplanes)
****************************************************************************

; Animation. Each frame measures 40*29 pixels, 3 bitplanes. Total 8 frames

cannoanim:
incbin    ‘frame1’    ; 40*29 at 3 bitplanes (8 colours)
incbin    ‘frame2’
incbin    ‘frame3’
incbin    ‘frame4’
incbin    ‘frame5’
incbin    ‘frame6’
incbin    “frame7”
incbin    ‘frame8’
FineAnim:

****************************************************************************
;			COPPERLISTOZZA
****************************************************************************

Section	Copper,DATA_C

COPPER:
dc.w	$8e,DIWS	; DiwStrt
dc.w	$90,DIWSt	; DiwStop
dc.w    $92,DDFS    ; DdfStart
dc.w    $94,DDFSt    ; DdfStop

dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0		; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

BPLPOINTERS:
dc.w $e0,0,$e2,0        ;first bitplane
dc.w $e4,0,$e6,0		;second ‘
dc.w $e8,0,$ea,0        ;third ’

; 8 Colours

dc.w    $180,$000,$182,$080,$184,$8c6
dc.w    $186,$c20,$188,$d50,$18a,$e80,$18c,$0fb0
dc.w    $18e,$ff0

dc.w    $2c07,$FFFE    ; wait

dc.w    $100,BPLC0    ; bplcon0 - 3 planes

dc.w    $108,-40    ; negative module - repeat same line!
dc.w    $10A,-40
ExtendCop:
ds.b    6*4*28		; 2 wait + 4 move = 6*4 bytes * 21 loops
; This copperlist lengthens *8 what is
; displayed, using modules 0 and -40
; alternating every 8 lines.
ds.b    4*2        ; For the $ffdffffe and for the last wait

dc.w    $100,$200	; bplcon0 - no bitplanes
dc.w    $FFFF,$FFFE    ; End copperlist

****************************************************************************
; Buffer for the ‘precalculated’ zoom table
****************************************************************************

section	precalcolone,bss

PrecalcTabba:
ds.b	256*8

****************************************************************************
; Buffer dove viene ‘espanso’ ogni fotogramma.
****************************************************************************

SECTION    BitPlanes,BSS_C

PLANEXPAND:            ; Where each frame is expanded.
ds.b    40*29*3        ; 40 bytes * 29 lines * 3 bitplanes

end