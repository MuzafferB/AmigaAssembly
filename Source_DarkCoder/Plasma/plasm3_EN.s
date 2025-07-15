
; Plasma3.s    0-bitplane RGB plasma
;        right click to activate ripple, left click to exit

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper,bitplane,blitter DMA

Waitdisk    EQU    10

Largh_plasm    equ    48        ; plasma width expressed
; as number of groups of 8 pixels
; the plasma is wider than the screen

BytesPerRiga    equ    (Largh_plasm+2)*4    ; number of bytes occupied
; in the copperlist by each row
; of the plasma: each copper instruction
; occupies 4 bytes

Alt_plasm    equ    190        ; plasma height expressed
; as number of lines

NuovaRigaR    equ    4        ; value added to the R index in the
; SinTab between one line and another
; Can be varied to obtain different plasmas
; but MUST ALWAYS BE EVEN!!

NuovoFrameR    equ    6        ; value subtracted from the R index in
; SinTab between one frame and another
; It can be varied to obtain different plasmas
; but MUST ALWAYS BE EVEN!

NewRowG    equ    2        ; as ‘NewRowR’ but for component G
NewFrameG    equ    8        ; as ‘NewFrameR’ but component G

NewRowB    equ    8        ; as “NewRowR” but for component B
NewFrameB    equ    4        ; as ‘NewFrameR’ but component B

NewRowO    equ    4        ; as ‘NewRowR’ but for oscillations
NewFrameO    equ    2        ; as ‘NewFrameR’ but oscillations


START:
lea    $dff000,a5        ; CUSTOM REGISTER in a5

bsr    InitPlasma        ; initialise the copperlist

; Initialise the blitter registers

Btst    #6,2(a5)
WaitBlit_init:
Btst    #6,2(a5)        ; wait for the blitter
bne.s    WaitBlit_init

move.l    #$4FFE8000,$40(a5)    ; BLTCON0/1 - D=A+B+C
; shift A = 4 pixels
; shift B = 8 pixels

moveq    #-1,d0            ; D0 = $FFFFFFFF
move.l    d0,$44(a5)        ; BLTAFWM/BLTALWM

mod_A    set    0            ; channel module A
mod_D    set    BytesPerLine-2        ; channel module D: goes to the next line

move.l    #mod_A<<16+mod_D,$64(a5)    ; loads the module registers

; channel modules B and C = 0

moveq    #0,d0
move.l    d0,$60(a5)        ; writes BLTBMOD and BLTCMOD

; Initialise other hardware registers

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST1,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w	#$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA
move.w    #$000,$180(a5)        ; COLOR00 - black
move.w    #$0200,$100(a5)		; BPLCON0 - no active bitplanes

; first loop: without horizontal oscillation

mouse1:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity1

bsr    SwapClists    ; swap copperlists

bsr    DoPlasma    ; plasma routine

btst    #2,$dff016    ; right mouse button pressed?
bne.s    mouse1

; second loop: with horizontal oscillation

mouse2:
MOVE.L    #$1ff00,d1	; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Waity2:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity2

bsr    SwapClists    ; swap the copperlists

bsr    DoOriz        ; horizontal oscillation effect
bsr	DoPlasma

btst	#6,$bfe001	; mouse premuto?
bne.s	mouse2

rts

;****************************************************************************
; This routine creates the horizontal oscillation effect.
 
; The effect is achieved by modifying the horizontal position
; of the start of the plasma at each line, i.e. the horizontal position of the WAIT that starts
; the line. The position values are read from a table.
;****************************************************************************

DoOriz:
lea    OrizTab(pc),a0        ; oscillation table address
move.l    draw_clist(pc),a1    ; copperlist address where to write
addq.w    #1,a1            ; address of the second byte of the first
; word of WAIT
; reads and modifies the index

move.w    IndiceO(pc),d4        ; reads the starting index of the
; previous frame
sub.w    #NuovoFrameO,d4        ; modifies the index in the table
; from the previous frame
and.w    #$007F,d4        ; keeps the index in the range
; 0 - 127 (offset in a table of
; 128 bytes)
move.w    d4,IndexO        ; stores the starting index for
; the next frame

move.w    #Alt_plasm-1,d3        ; loop for each row
OrizLoop:
move.b    0(a0,d4.w),d0        ; read oscillation value
or.b    #01,d0            ; set bit 0 to 1 (necessary
; for the WAIT instruction)
move.b    d0,(a1)            ; write the horizontal position
; of WAIT in the copperlist

lea    BytesPerLine(a1),a1    ; point to the next line 
; in the copper list
; modify index for next line

add.w    #NewLineO,d4        ; modify the index in the table
; for the next line

and.w    #$007F,d4        ; keeps the index in the range
; 0 - 127 (offset in a table of
; 128 bytes)
dbra    d3,OrizLoop
rts

;****************************************************************************
; This routine creates the ‘double buffer’ between the copperlists.
; In practice, it takes the clist where it is drawn and displays it by copying
; its address to COP1LC. It swaps the variables so that in the next frame
; it is drawn on the other copper list
;****************************************************************************

SwapClists:
move.l    draw_clist(pc),d0    ; clist address where it is written
move.l    view_clist(pc),draw_clist    ; swaps the clists
move.l    d0,view_clist

move.l    d0,$80(a5)        ; copy the clist address
; to COP1LC so that it is
; displayed in the next frame
rts


;****************************************************************************
; This routine initialises the copperlist that generates the plasma. It sets the
; WAIT instructions and the first half of the COPPERMOVE. At the end of the
; plasma line, a final COPPERMOVE is inserted that loads the colour
; black into COLOR00.
;****************************************************************************

InitPlasma:
lea    Copperlist1,a0    ; copperlist address 1
lea    Copperlist2,a1    ; copperlist address 2
move.l    #$3025FFFE,d0    ; loads the first wait instruction into D0.
; waits for line $30 and horizontal position
; $24
move.w    #$180,d1	; puts the first half of a 
; ‘copper move’ instruction in D1 in COLOR00 (=$dff180)

move.w    #Alt_plasm-1,d3        ; loop for each line
InitLoop1:
move.l    d0,(a0)+        ; writes WAIT - (clist 1)
move.l    d0,(a1)+        ; writes WAIT - (clist 2)
add.l    #$01000000,d0        ; modifies WAIT to wait
; for the next line

moveq    #Largh_plasm,d2        ; loop for the entire width
; of the plasma + once for
; the last ‘copper move’ that restores
; black as the background

InitLoop2:
move.w    d1,(a0)+		; writes the first part of the
; ‘copper move’ - clist 1
addq.w    #2,a0            ; space for the second part
; of the ‘copper move’ - clist 1

move.w    d1,(a1)+        ; writes the first part of the
; ‘copper move’ - clist 2
addq.w    #2,a1            ; space for the second part
; of the ‘copper move’ - clist 2

dbra    d2,InitLoop2
dbra    d3,InitLoop1
rts

;****************************************************************************
; This routine creates the plasma. It performs a loop of blits, each
; of which writes a ‘column’ of the plasma, i.e. it writes the colours in the
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
addq.w    #6,a1            ; address of the first word of the first
; plasma column
; reads and modifies the R component index

move.w	IndiceR(pc),d4        ; reads the starting index of the
; previous frame
sub.w    #NuovoFrameR,d4        ; modifies the index in the table
; from the previous frame
and.w    #$00FF,d4        ; keeps the index in the range
; 0 - 255 (offset in a table of
; 128 words)
move.w    d4,IndexR        ; stores the starting index for
; the next frame
; reads and modifies component index G

move.w    IndiceG(pc),d5        ; reads the starting index of the
; previous frame
sub.w    #NuovoFrameG,d5        ; modifies the index in the table
; from the previous frame
and.w	#00FF,d5        ; keeps the index in the range
; 0 - 255 (offset in a table of
; 128 words)
move.w    d5,IndiceG        ; stores the starting index for
; the next frame
; reads and modifies component index B

move.w	IndexB(pc),d6        ; reads the starting index of the
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

moveq    #Wide_plasm-1,d2    ; loop for entire width
PlasmaLoop:                ; start of bleed loop

; calculate start address of R component

move.w    (a6,d4.w),d1        ; reads offset from table

lea    (a0,d1.w),a2        ; starting address = colour index
; plus offset
; calculates starting address of G component

move.w    (a6,d5.w),d1		; read offset from table

lea    (a0,d1.w),a3        ; start address = colour index
; plus offset
; calculate start address of component B

move.w    (a6,d6.w),d1        ; read offset from table

lea    (a0,d1.w),a4		; start address = colour index
; plus offset
Btst    #6,2(a5)
WaitBlit:
Btst    #6,2(a5)        ; wait for the blitter
bne.s    WaitBlit

move.l    a2,$48(a5)        ; BLTCPT - source address R
move.l    a3,$50(a5)        ; BLTAPT - source address G
move.l    a4,$4C(a5)        ; BLTBPT - source address B
move.l    a1,$54(a5)        ; BLTDPT - destination address
move.w    d3,$58(a5)		; BLTSIZE

addq.w    #4,a1            ; points to the next column of 
; ‘copper moves’ in the copper list
; modifies the R component index for the next row

add.w    #NewRowR,d4        ; modifies the index in the table
; for the next row

and.w    #$00FF,d4        ; keeps the index in the range
; 0 - 255 (offset in a table of
; 128 words)
; modify component G index for next row

add.w	#NewRowG,d5        ; change the index in the table
; for the next row

and.w    #$00FF,d5        ; keep the index in the range
; 0 - 255 (offset in a table of
; 128 words)

; change component index B for next row

add.w	#NewRowB,d6        ; change the index in the table
; for the next row

and.w    #00FF,d6        ; keep the index in the range
; 0 - 255 (offset in a table of
; 128 words)
dbra    d2,PlasmaLoop
rts


; These 2 variables contain the addresses of the 2 copperlists

view_clist:    dc.l    COPPERLIST1    ; address of the clist displayed
draw_clist:    dc.l    COPPERLIST2    ; address of the clist where to draw

; This variable contains the value of the index in the table of
; oscillations (horizontal positions of the WAITs)

IndexO:    dc.w    0

; This table contains the oscillation values (horizontal positions
; of the WAITs)

OrizTab:
DC.B    $2C,$2C,$2C,$2E,$2E,$2E,$2E,$2E,$30,$30,$30,$30,$30,$30,$32,$32
DC.B	$32,$32,$32,$32,$32,$32,$34,$34,$34,$34,$34,$34,$34,$34,$34,$34
DC.B	$34,$34,$34,$34,$34,$34,$34,$34,$34,$34,$32,$32,$32,$32,$32,$32
DC.B	$32,$32,$30,$30,$30,$30,$30,$30,$2E,$2E,$2E,$2E,$2E,$2C,$2C,$2C
DC.B	$2C,$2C,$2C,$2A,$2A,$2A,$2A,$2A,$28,$28,$28,$28,$28,$28,$26,$26
DC.B	$26,$26,$26,$26,$26,$26,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
DC.B	$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$26,$26,$26,$26,$26,$26
DC.B    $26,$26,$28,$28,$28,$28,$28,$28,$2A,$2A,$2A,$2A,$2A,$2C,$2C,$2C

; These variables contain the index values for the first column

IndexR:    dc.w    0
IndexG:    dc.w    0
IndexB:    dc.w    0

; This table contains the offsets for the starting address in the
; colour table

SinTab:
DC.W    $0034,$0036,$0038,$003A,$003C,$0040,$0042,$0044,$0046,$0048
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

SECTION	GRAPHIC,DATA_C

; We have 2 copperlists 

COPPERLIST1:

; Here we leave some empty space for the piece of copperlist that generates
; the plasma. This space is filled by the effect routines.

dcb.b    alt_plasm*BytesPerRiga,0
dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

COPPERLIST2:

; Here, some space is left for the piece of copperlist that generates
; the plasma. This space is filled by the effect routines.

dcb.b    alt_plasm*BytesPerRiga,0

dc.w    $FFFF,$FFFE    ; End of copperlist


;****************************************************************************
; Here is the colour table that is written to the plasma.
; There must be enough colours to be read regardless of the starting address
;. In this example, the starting address can vary from
; ‘Colour’ (first colour) to ‘Colour+100’ (50th colour), because
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

end

;****************************************************************************

In this example we have an RGB plasma made by columns (i.e. the colours
are blitted in the copperlist one column at a time) to which we add
a horizontal oscillation. When the programme is run, the
oscillation effect is not active at first. Pressing the right button activates it.
To achieve the oscillation, you need a plasma that is wider than the screen,
so that only part of it is visible. By varying the starting position of
each line (i.e. the horizontal position of the WAIT at the beginning of the line),
you can show different areas of the plasma. In the programme, each
line is assigned a different starting position, which is read from a
sinusoidal table. The table is read in the same way as the
R,G, and B. For this table, too, the increments to which the indices are subjected
can be varied by adjusting the parameters
at the beginning of the listing.
This effect has a good visual impact when the ‘NuovaRigaX’
parameters of the R, G, and B components take on low values. Increasing these values
(e.g. 20) highlights the limits of this effect. In particular
,
 the horizontal ripple is made in 4-pixel increments, as this is
the minimum resolution of WAIT. We will see later how to achieve
less jagged ripples.
