
; Plasma4.s    1-bitplane RGB plasma and ripple
;        left button to exit

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper, bitplane, blitter DMA

Waitdisk    EQU    10

Largh_plasm    equ    38        ; plasma width expressed
; as number of groups of 8 pixels

; number of bytes occupied in the copperlist by each line of the plasma: each
copper instruction occupies 4 bytes. Each row consists of 1 ‘copper move’ in
BPLCON1, 1 WAIT,Largh_plasm ‘copper moves’ for the plasma (including the
final ‘copper move’ in COLOR00 to make the background black.

BytesPerRiga    equ    (Largh_plasm+2)*4

Alt_plasm    equ    190        ; height of the plasma expressed
; as a number of lines

NuovaRigaR    equ    -24        ; value added to the R index in the
; SinTab between one line and another
; It can be varied to obtain different plasmas
; but MUST ALWAYS BE EVEN!!

NewFrameR    equ    6        ; value subtracted from index R in
; SinTab between one frame and another
; Can be varied to obtain different plasmas
; but MUST ALWAYS BE EVEN!!

NewRowG    equ    12        ; as ‘NewRowR’ but for component G
NewFrameG	equ    8        ; as ‘NewFrameR’ but for component G

NewRowB    equ    18        ; as ‘NewRowR’ but for component B
NewFrameB    equ    4        ; as “NewFrameR” but for component B

NewRowO    equ    8        ; as ‘NewRowR’ but for oscillations
NewFrameO	equ    2        ; as ‘NewFrameR’ but oscillations


START:

;    Point the image in the copperlist

MOVE.L    #BITPLANE,d0    ; where to point
LEA    COPPERLIST1,A1    ; COP 1 pointers
LEA    COPPERLIST2,A2    ; COP 2 pointers
move.w    d0,6(a1)    ; writes to copperlist 1
move.w    d0,6(a2)    ; writes to copperlist 2
swap    d0
move.w    d0,2(a1)    ; writes to copperlist 1
move.w    d0,2(a2)    ; writes to copperlist 2

lea    $dff000,a5        ; CUSTOM REGISTER in a5

bsr    InitPlasma        ; initialise the copperlist

; Initialise the blitter registers

Btst    #6,2(a5)
WaitBlit_init:
Btst    #6,2(a5)		; wait for the blitter
bne.s    WaitBlit_init

move.l    #$4FFE8000,$40(a5)    ; BLTCON0/1 - D=A+B+C
; shift A = 4 pixels
; shift B = 8 pixels

moveq    #-1,d0            ; D0 = $FFFFFFFF
move.l    d0,$44(a5)        ; BLTAFWM/BLTALWM

mod_A    set    0            ; channel A module
mod_D    set    BytesPerLine-2        ; channel D module: goes to the next line

move.l    #mod_A<<16+mod_D,$64(a5)	; load the module registers

; channel modules B and C = 0

moveq    #0,d0
move.l    d0,$60(a5)        ; write BLTBMOD and BLTCMOD

MOVE.W    #DMASET,$96(a5)		; DMACON - enable bitplane, copper
move.l    #COPPERLIST1,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP

; Initialise other hardware registers
; D0=0
move.w    d0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA
move.l    d0,$180(a5)        ; COLOR00 and COLOR01 - black
move.w    #$3e90,$8e(a5)        ; DiwStrt - use a window smaller
; than the screen
move.w    #$fcb1,$90(a5)        ; DiwStop
move.w    #$0036,$92(a5)        ; DDFStrt - 40 bytes are fetched
move.w    #$00ce,$94(a5)        ; DDFStop
move.l    d0,$102(a5)		; BPLCON1/2
move.w    #-40,$108(a5)        ; BPL1MOD = -40 always repeats the same
; line
move.w    #$1200,$100(a5)        ; BPLCON0 - 1 bitplane active

mouse2:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Waity2:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity2

bsr    SwapClists    ; swap the copperlists

bsr    DoOriz        ; horizontal oscillation effect
bsr    DoPlasma

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse2

rts

;****************************************************************************
; This routine creates the horizontal oscillation effect.
; The effect is achieved by modifying the hardware scroll value of bitplane 1 on each line
;. The values are read from a table and written to the
; copperlist.
;****************************************************************************

DoOriz:
lea    OrizTab(pc),a0        ; oscillation table address
move.l    draw_clist(pc),a1    ; copperlist address where to write
lea    11(a1),a1		; address of the second byte of the second
; word of the ‘copper move’ in BPLCON1
; reads and modifies the index

move.w    IndexO(pc),d4        ; reads the starting index of the
; previous frame
sub.w    #NewFrameO,d4        ; modifies the index in the table
; from the previous frame
and.w	#$007F,d4        ; keeps the index in the range
; 0 - 127 (offset in a table of
; 128 bytes)
move.w    d4,IndexO        ; stores the starting index for
; the next frame

move.w	#Alt_plasm-1,d3        ; loop for each row
OrizLoop:
move.b    0(a0,d4.w),d0        ; read oscillation value

move.b    d0,(a1)            ; writes the scroll value in the
; ‘copper move’ in BPLCON1

lea    BytesPerRow(a1),a1    ; points to the next row 
; in the copper list
; modifies index for next row

add.w	#NewLineO,d4        ; change the index in the table
; for the next line

and.w    #$007F,d4        ; keep the index in the range
; 0 - 127 (offset in a table of
; 128 bytes)
dbra    d3,OrizLoop
rts

;****************************************************************************
; This routine creates the ‘double buffer’ between the copper lists.
; In practice, it takes the clist where it is drawn and displays it by copying
; its address to COP1LC. It swaps the variables so that in the next frame
; it is drawn on the other copper list
;****************************************************************************

SwapClists:
move.l    draw_clist(pc),d0    ; clist address where it is written
move.l    view_clist(pc),draw_clist    ; swaps the clists
move.l    d0,view_clist

move.l    d0,$80(a5)		; copy the address of the clist
; to COP1LC so that it is
; displayed in the next frame
rts


;****************************************************************************
; This routine initialises the copper list that generates the plasma. It sets the
; WAIT instructions and the first half of the COPPERMOVE instructions.
;****************************************************************************

InitPlasma:
lea    Plasma1,a0    ; plasma address 1
lea    Plasma2,a1    ; plasma address 2
move.l    #$3e43FFFE,d0    ; load the first wait instruction into D0.
; wait for line $30 and horizontal position
; $24
move.w    #$180,d1    ; put the first half of a
; ‘copper move’ instruction in COLOR00 (=$dff180)
move.w	#$182,d4    ; puts the first half of a 
; ‘copper move’ instruction in COLOR01 (=$dff182)
move.w    #$102,d5    ; puts the first half of a
; ‘copper move’ instruction in BPLCON1 (=$dff102)

move.w    #Alt_plasm-1,d3        ; loop for each line
InitLoop1:
move.w    d5,(a0)+        ; writes the first part of the
; ‘copper move’ in BPLCON1 - clist 1
addq.w    #2,a0            ; space for the second part
; of the ‘copper move’ - clist 1

move.w    d5,(a1)+        ; writes the first part of the
; ‘copper move’ in BPLCON1 - clist 2
addq.w    #2,a1            ; space for the second part
; of the ‘copper move’ - clist 2

move.l    d0,(a0)+        ; writes WAIT - (clist 1)
move.l    d0,(a1)+        ; writes WAIT - (clist 2)
add.l    #$01000000,d0        ; modifies the WAIT to wait
; for the following line

moveq    #Largh_plasm/2-1,d2    ; loop for the entire width
; of the plasma + 2 ‘copper moves’
; that put black back in COLOR00/01
InitLoop2:
move.w    d4,(a0)+        ; writes the first part of the
; ‘copper move’ in COLOR00 - clist 1
addq.w    #2,a0            ; space for the second part
; of the ‘copper move’ - clist 1

move.w    d4,(a1)+		; writes the first part of the
; ‘copper move’ in COLOR00 - clist 2
addq.w    #2,a1            ; space for the second part
; of the ‘copper move’ - clist 2

move.w    d1,(a0)+        ; writes the first part of the
; ‘copper move’ in COLOR01 - clist 1
addq.w    #2,a0            ; space for the second part
; of the ‘copper move’ - clist 1

move.w    d1,(a1)+        ; writes the first part of the
; ‘copper move’ in COLOR01 - clist 2
addq.w    #2,a1            ; space for the second part
; of the ‘copper move’ - clist 2
dbra    d2,InitLoop2
dbra    d3,InitLoop1
rts

;****************************************************************************
; This routine creates the plasma. It performs a loop of blits, each
; of which writes a ‘column’ of plasma, i.e. it writes the colours in the
; COPPERMOVES placed in columns.
; The colours written in each column are read from a table, starting from
; an address that varies between columns based on offsets
; read from another table. Furthermore, between one frame and another, the offsets
; vary, creating the movement effect.
;****************************************************************************

DoPlasma:
lea    Colour,a0        ; colour address
lea    SinTab,a6        ; offset table address
move.l    draw_clist(pc),a1    ; copperlist address where to write
lea	18(a1),a1        ; address of the first word of the first
; plasma column
; reads and modifies the R component index

move.w    IndiceR(pc),d4        ; reads the starting index of the
; previous frame
sub.w    #NuovoFrameR,d4		; modifies the index in the table
; from the previous frame
and.w    #$00FF,d4        ; keeps the index in the range
; 0 - 255 (offset in a table of
; 128 words)
move.w    d4,IndexR        ; stores the starting index for
; the next frame
; reads and modifies the G component index

move.w    IndexG(pc),d5        ; reads the starting index of the
; previous frame
sub.w    #NewFrameG,d5        ; modifies the index in the table
; from the previous frame
and.w    #$00FF,d5        ; keeps the index in the range
; 0 - 255 (offset in a table of
; 128 words)
move.w    d5,IndiceG        ; stores the starting index for
; the next frame
; reads and modifies component index B

move.w    IndexB(pc),d6        ; reads the starting index of the
; previous frame
sub.w    #NewFrameB,d6        ; modifies the index in the table
; from the previous frame
and.w    #00FF,d6        ; keeps the index in the range
; 0 - 255 (offset in a table of
; 128 words)
move.w    d6,IndexB        ; stores the starting index for
; the next frame

move.w    #Alt_plasm<<6+1,d3    ; blitted size
; width 1 word, height entire plasma

moveq	#Largh_plasm-2,d2    ; the loop is NOT repeated for the entire
; width. The last 2 columns
; are left alone so that
; they rewrite the colour black in
; registers COLOR01 and COLOR00

PlasmaLoop:                ; start of bleed loop

; calculate start address of component R

move.w    (a6,d4.w),d1        ; read offset from table

lea    (a0,d1.w),a2        ; starting address = colour index
; plus offset

; calculate starting address of component G

move.w    (a6,d5.w),d1        ; read offset from table

lea    (a0,d1.w),a3        ; start address = colour index
; plus offset

; calculate start address of component B

move.w    (a6,d6.w),d1        ; read offset from table

lea    (a0,d1.w),a4        ; start address = colour index
; plus offset

Btst	#6,2(a5)
WaitBlit:
Btst	#6,2(a5)		; wait for the blitter
bne.s    WaitBlit

move.l    a2,$48(a5)        ; BLTCPT - source address R
move.l    a3,$50(a5)        ; BLTAPT - source address G
move.l    a4,$4C(a5)		; BLTBPT - source address B
move.l    a1,$54(a5)        ; BLTDPT - destination address
move.w    d3,$58(a5)        ; BLTSIZE

addq.w    #4,a1            ; points to next column of 
; ‘copper moves’ in the copper list

; modifies R component index for next line

add.w    #NewRigaR,d4        ; change the index in the table
; for the next row

and.w    #$00FF,d4        ; keep the index in the range
; 0 - 255 (offset in a table of
; 128 words)

; change component G index for next line

add.w    #NewLineG,d5        ; change the index in the table
; for the next line

and.w    #$00FF,d5        ; keep the index in the range
; 0 - 255 (offset in a table of
; 128 words)

; change component B index for next line

add.w    #NewLineB,d6        ; change the index in the table
; for the next line

and.w    #$00FF,d6        ; keeps the index in the range
; 0 - 255 (offset in a table of
; 128 words)
dbra    d2,PlasmaLoop
rts


; These 2 variables contain the addresses of the 2 copperlists

view_clist:    dc.l    COPPERLIST1    ; address of the displayed clist
draw_clist:    dc.l	COPPERLIST2    ; clist address where to draw

; This variable contains the index value in the
; oscillation table (horizontal positions of the WAITs)

IndiceO:    dc.w    0

; This table contains the oscillation values (scroll values)

OrizTab:
DC.B	$03,$03,$03,$03,$04,$04,$04,$04,$04,$04,$04,$05,$05,$05,$05,$05
DC.B	$05,$05,$05,$05,$05,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06
DC.B	$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$05,$05,$05,$05
DC.B	$05,$05,$05,$05,$05,$05,$04,$04,$04,$04,$04,$04,$04,$03,$03,$03
DC.B	$03,$03,$03,$03,$02,$02,$02,$02,$02,$02,$02,$01,$01,$01,$01,$01
DC.B	$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DC.B	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01
DC.B	$01,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$02,$02,$03,$03,$03

; These variables contain the index values for the first column

IndexR:    dc.w    0
IndexG:    dc.w    0
IndexB:    dc.w    0

; This table contains the offsets for the starting address in the
; colour table

SinTab:
DC.W	$0034,$0036,$0038,$003A,$003C,$0040,$0042,$0044,$0046,$0048
DC.W	$004A,$004C,$004E,$0050,$0052,$0054,$0056,$0058,$005A,$005A
DC.W	$005C,$005E,$005E,$0060,$0060,$0062,$0062,$0062,$0064,$0064
DC.W	$0064,$0064,$0064,$0064,$0064,$0064,$0062,$0062,$0062,$0060
DC.W	$0060,$005E,$005E,$005C,$005A,$005A,$0058,$0056,$0054,$0052
DC.W	$0050,$004E,$004C,$004A,$0048,$0046,$0044,$0042,$0040,$003C
DC.W	$003A,$0038,$0036,$0034,$0030,$002E,$002C,$002A,$0028,$0024
DC.W	$0022,$0020,$001E,$001C,$001A,$0018,$0016,$0014,$0012,$0010
DC.W	$000E,$000C,$000A,$000A,$0008,$0006,$0006,$0004,$0004,$0002
DC.W	$0002,$0002,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
DC.W	$0002,$0002,$0002,$0004,$0004,$0006,$0006,$0008,$000A,$000A
DC.W	$000C,$000E,$0010,$0012,$0014,$0016,$0018,$001A,$001C,$001E
DC.W	$0020,$0022,$0024,$0028,$002A,$002C,$002E,$0030
EndSinTab:

;****************************************************************************

SECTION    GRAPHIC,DATA_C

; We have 2 copperlists 

COPPERLIST1:
dc.w    $e0,$0000,$e2,$0000    ;first     bitplane

; Here we leave some empty space for the piece of copperlist that generates
; the plasma. This space is filled by the effect routines.

PLASMA1:
dcb.b    alt_plasm*BytesPerLine,0
dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

COPPERLIST2:
dc.w    $e0,$0000,$e2,$0000    ;first     bitplane

; Here, some empty space is left for the piece of copperlist that generates
; the plasma. This space is filled by the effect routines.

PLASMA2:
dcb.b	alt_plasm*BytesPerRiga,0

dc.w	$FFFF,$FFFE	; Fine della copperlist


;****************************************************************************
; Here is the colour table that is written to the plasma.
; There must be enough colours to be read regardless of the starting address
; . In this example, the starting address can vary from
; ‘Colour’ (first colour) to ‘Color+100’ (50th colour), because
; 100 is the maximum offset contained in the ‘SinTab’.
; If Alt_plasm=190, it means that each blit reads 190 colours.
; So there must be 240 colours in total.
;****************************************************************************

Color:
dc.w	$0f00,$0f00,$0e00,$0e00,$0e00,$0d00,$0d00,$0d00
dc.w	$0c00,$0c00,$0c00,$0b00,$0b00,$0b00,$0a00,$0a00,$0a00
dc.w	$0900,$0900,$0900,$0800,$0800,$0800,$0700,$0700,$0700
dc.w	$0600,$0600,$0600,$0500,$0500,$0500,$0400,$0400,$0400
dc.w	$0300,$0300,$0300,$0200,$0200,$0200,$0100,$0100,$0100
dcb.w	18,0
dc.w	$0100,$0100,$0100,$0100,$0200,$0200,$0200,$0200
dc.w	$0300,$0300,$0300,$0300,$0400,$0400,$0400,$0400
dc.w	$0500,$0500,$0500,$0500,$0600,$0600,$0600,$0600
dc.w	$0700,$0700,$0700,$0700,$0800,$0800,$0800,$0800
dc.w	$0900,$0900,$0900,$0900,$0a00,$0a00,$0a00,$0a00
dc.w	$0b00,$0b00,$0b00,$0b00,$0c00,$0c00,$0c00,$0c00
dc.w	$0d00,$0d00,$0d00,$0d00,$0e00,$0e00,$0e00,$0e00
dc.w	$0f00,$0f00,$0f00,$0f00

dc.w	$0f00,$0f00,$0f00,$0f00,$0e00,$0e00,$0e00,$0e00
dc.w	$0d00,$0d00,$0d00,$0d00,$0c00,$0c00,$0c00,$0c00
dc.w	$0b00,$0b00,$0b00,$0b00,$0a00,$0a00,$0a00,$0a00
dc.w	$0900,$0900,$0900,$0800,$0800,$0800,$0800
dc.w	$0700,$0700,$0700,$0700,$0600,$0600,$0600,$0600
dc.w	$0500,$0500,$0500,$0500,$0400,$0400,$0400,$0400
dc.w	$0300,$0300,$0300,$0300,$0200,$0200,$0200,$0200
dc.w	$0100,$0100,$0100
dcb.w	18,0
dc.w	$0100,$0100,$0100,$0200,$0200,$0200,$0300,$0300,$0300
dc.w	$0400,$0400,$0400,$0500,$0500,$0500,$0600,$0600,$0600
dc.w	$0700,$0700,$0700,$0800,$0800,$0900,$0900,$0900
dc.w	$0a00,$0a00,$0a00,$0b00,$0b00,$0b00,$0c00,$0c00,$0c00
dc.w	$0d00,$0d00,$0d00,$0e00,$0e00,$0e00,$0f00

; Image line that is repeated with BPLMOD1
; consists of 40 bytes alternating between 0 and $FF

BITPLANE:    dcb.w    20,$00FF

end


;****************************************************************************

In this example, we show a 1-bitplane plasma with a wave
created using hardware scrolling.
A vertical striped bitplane is used, as explained in the theory.
Since all the lines of the bitplane would have been the same, we have
stored only one, which is repeated using the negative module trick.
 The image is 40 bytes wide. However, it is not displayed in its entirety
to allow hardware scrolling. A ‘display window’ narrower than usual is therefore used,
 also to mask some minor defects in the plasma at the
edges. The values of the DDFSTRT, DDFSTOP, DIWSTRT and DIWSTOP are therefore
slightly different from usual, and were found by trial and error.
To achieve the wave effect, the hardware scroll value is varied on each line.
 As usual, the values are read from a table.
The copperlist for each line of the plasma has a ‘copper move’ in BPLCON1
(to write the scroll value), followed by a WAIT to synchronise
with the start of the bitplane fetch, and finally there are the ‘copper moves’
of the plasma, whose destination is alternately COLOR01 and COLOR00.
The first ‘copper move’ of each row is in COLOR01 and starts 8 pixels before
the image starts to be displayed. This is because this ‘copper move’
is used to determine the colour of the pixels entering from the right edge of the
screen via the hardware scroll; since these are pixels set to 1,
it is necessary to write to COLOR01. The next ‘copper move’ in COLOR00 is
aligned with the start of the video window. Then
other ‘copper moves’ in COLOR01 and COLOR00 follow alternately. The ‘DoPlasma’ routine writes one
column at a time, except for the last 2, which are used to put black back into the
2 colour registers.
