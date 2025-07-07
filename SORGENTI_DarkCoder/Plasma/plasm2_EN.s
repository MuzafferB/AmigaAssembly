
; Plasma2.s    0-bitplane RGB plasma
;        left key to exit

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include    ‘startup2.s’    ; Save Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET	EQU	%1000001111000000	; copper,bitplane,blitter DMA

Waitdisk    EQU    10

Largh_plasm    equ    40        ; plasma width expressed
; as a number of groups of 8 pixels

BytesPerRiga    equ    (Largh_plasm+2)*4    ; number of bytes occupied
; in the copperlist by each col.
; of the plasma: each copper instruction
; occupies 4 bytes

Alt_plasm    equ    190        ; plasma height expressed
; as number of lines

NuovaColR    equ    -2        ; value added to the R index in the
; SinTab between one column and another
; Can be varied to obtain different plasmas
; but MUST ALWAYS BE EVEN!!

NuovoFrameR    equ    8        ; value subtracted from the R index in the
; SinTab between one frame and another
; It can be varied to obtain different plasmas
; but MUST ALWAYS BE EVEN!

NuovaColG    equ    2        ; as ‘NuovaColR’ but for component G
NuovoFrameG    equ    2		; as ‘NewFrameR’ but for component G

NewColB    equ    4        ; as “NewColR” but for component B
NewFrameB    equ    -6        ; as ‘NewFrameR’ but for component B


START:
lea    $dff000,a5        ; CUSTOM REGISTER in a5

bsr    InitPlasma        ; initialise the copperlist

; Initialise the blitter registers

Btst    #6,2(a5)
WaitBlit_init:
Btst    #6,2(a5)        ; wait for the blitter
bne.s    WaitBlit_init

move.l	#$4FFE8000,$40(a5)    ; BLTCON0/1 - D=A+B+C
; shift A = 4 pixels
; shift B = 8 pixels

moveq    #-1,d0            ; D0 = $FFFFFFFF
move.l    d0,$44(a5)        ; BLTAFWM/BLTALWM

mod_A    set    0            ; channel module A
mod_D    set    2            ; channel module D: next column

move.l    #mod_A<<16+mod_D,$64(a5)    ; load module registers

; channel modules B and C = 0

moveq    #0,d0
move.l    d0,$60(a5)        ; writes BLTBMOD and BLTCMOD


; Initialise other hardware registers

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST1,$80(a5)    ; Point our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA
move.w    #$000,$180(a5)        ; COLOR00 - black
move.w    #$0200,$100(a5)        ; BPLCON0 - no active bitplanes

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity1

bsr.s    SwapClists    ; swap the copperlists

bsr.s    DoPlasma

btst    #6,$bfe001    ; mouse pressed?
bne.w    mouse
rts

;****************************************************************************
; This routine creates the ‘double buffer’ between the copperlists.
; In practice, it takes the clist where it is drawn and displays it by copying
; its address to COP1LC. It swaps the variables so that in the following frame
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
lea    Plasma1,a0    ; plasma address 1
lea    Plasma2,a1    ; plasma address 2
move.l    #$383dFFFE,d0    ; loads the first wait instruction into $3d.
; waits for line $60 and horizontal position
; $58
move.w	#$180,d1    ; puts the first half of an instruction in D1 
; ‘copper move’ in COLOR00 (=$dff180)

move.w    #Alt_plasm-1,d3        ; loop for each line
InitLoop1:
move.l	d0,(a0)+        ; writes WAIT - (clist 1)
move.l    d0,(a1)+        ; writes WAIT - (clist 2)
add.l    #$01000000,d0        ; modifies WAIT to wait
; for the next line

moveq    #Largh_plasm,d2        ; loop for the entire width
; of the plasma + once for
; the last ‘copper move’ that restores
; black as the background

InitLoop2:
move.w    d1,(a0)+        ; writes the first part of the
; ‘copper move’ - clist 1
addq.l    #2,a0            ; space for the second part
; of the ‘copper move’ - clist 1

move.w    d1,(a1)+        ; writes the first part of the
; ‘copper move’ - clist 2
addq.l    #2,a1            ; space for the second part
; of the ‘copper move’ - clist 2

dbra    d2,InitLoop2

dbra    d3,InitLoop1
rts


;****************************************************************************
; This routine creates the plasma. It performs a loop of blits, each
; of which writes a ‘line’ of plasma, i.e. it writes the colours in the
; COPPERMOVES placed in a row.
; An RGB plasma is created. The 3 components are read separately
; and ‘OR-ed’ together. A single table is used for the 3 components, but
; it is read in different positions and ‘traversed’ at different speeds between
; one line and another and between one frame and another. This is like having
; 3 different tables.
; The table actually contains the values of the R component. To obtain
; the values of the other components G, it is necessary to shift the data read on the
; right by 4 for G and 8 for B. This is done ‘on the fly’ by the
; blitter shifters.
;****************************************************************************

DoPlasma:

lea    Colour,a0        ; colour address
lea    SinTab,a6        ; table offsets address
move.l    draw_clist(pc),a1    ; copperlist address where to write
lea    22(a1),a1        ; adds the offset needed to
; point to the first word of the first
; row of the plasma
; (you need to skip the first 4 instructions
; the start-of-line wait
; and the first word of the ‘copper move’)

; reads and modifies component index R

move.w    IndexR(pc),d4        ; reads the starting index of the
; previous frame
sub.w    #NewFrameR,d4        ; modifies the index in the table
; from the previous frame
and.w    #$00FF,d4        ; keeps the index in the range
; 0 - 255 (offset in a table of
; 128 words)
move.w    d4,IndiceR        ; stores the starting index for
; the next frame

; reads and modifies component G index

move.w    IndiceG(pc),d5        ; reads the starting index of the
; previous frame
sub.w    #NuovoFrameG,d5        ; modifies the index in the table
; from the previous frame
and.w    #$00FF,d5        ; keeps the index in the range
; 0 - 255 (offset in a table of
; 128 words)
move.w    d5,IndiceG        ; stores the starting index for
; the next frame

; reads and modifies component B index

move.w    IndexB(pc),d6        ; reads the starting index of the
; previous frame
sub.w	#NewFrameB,d6        ; modifies the index in the table
; from the previous frame
and.w    #$00FF,d6        ; keeps the index in the range
; 0 - 255 (offset in a table of
; 128 words)
move.w    d6,IndexB        ; stores the starting index for
; the next frame

move.w    #Largh_plasm<<6+1,d3    ; blitted size
; width 1 word, as high as
; the width of the plasma

move.w    #Alt_plasm-1,d2        ; loop for the entire height

PlasmaLoop:                ; start bleed loop

; calculate start address of R component

move.w    (a6,d4.w),d1        ; read offset from table

lea	(a0,d1.w),a2        ; starting address = colour index
; plus offset

; calculate starting address of component G

move.w    (a6,d5.w),d1        ; read offset from table

lea    (a0,d1.w),a3        ; starting address = colour index
; plus offset

; calculate start address of component B

move.w    (a6,d6.w),d1        ; read offset from table

lea    (a0,d1.w),a4        ; start address = colour index
; plus offset

Btst    #6,2(a5)
WaitBlit:
Btst    #6,2(a5)		; wait for the blitter
bne.s    WaitBlit

move.l    a2,$48(a5)        ; BLTCPT - source address R
; (copied as is)
move.l    a3,$50(a5)        ; BLTAPT - source address G
; (shifted 4 to the right)
move.l    a4,$4C(a5)        ; BLTBPT - source address B
; (shifted 8 to the right)
move.l    a1,$54(a5)        ; BLTDPT - destination address
move.w    d3,$58(a5)		; BLTSIZE

lea    BytesPerLine(a1),a1    ; points to the next line of 
; ‘copper moves’ in the copper list

; modifies component index R for next col.

add.w    #NewColR,d4        ; modifies the index in the table
; for the next col.

and.w    #$00FF,d4        ; keeps the index in the range
; 0 - 255 (offset in a table of
; 128 words)

; change component index G for next col.

add.w    #NewColG,d5        ; change the index in the table
; for the next col.

and.w    #$00FF,d5        ; keeps the index in the range
; 0 - 255 (offset in a table of
; 128 words)

; modifies the B component index for the next col.

add.w    #NewColB,d6        ; change the index in the table
; for the next col.

and.w    #$00FF,d6        ; keep the index in the range
; 0 - 255 (offset in a table of
; 128 words)
dbra    d2,PlasmaLoop
rts


; These 2 variables contain the addresses of the 2 copperlists

view_clist:    dc.l    COPPERLIST1    ; address of the clist displayed
draw_clist:    dc.l    COPPERLIST2    ; address of the clist where to draw


; These variables contain the index values for the first column

IndexR:    dc.w    0
IndexG:    dc.w    0
IndexB:    dc.w    0

; This table contains the offsets for the starting address in the
; colour table

SinTab:
DC.W	$000E,$0010,$0010,$0010,$0012,$0012,$0012,$0014,$0014,$0014
DC.W	$0014,$0016,$0016,$0016,$0018,$0018,$0018,$0018,$001A,$001A
DC.W	$001A,$001A,$001A,$001A,$001C,$001C,$001C,$001C,$001C,$001C
DC.W	$001C,$001C,$001C,$001C,$001C,$001C,$001C,$001C,$001C,$001C
DC.W	$001A,$001A,$001A,$001A,$001A,$001A,$0018,$0018,$0018,$0018
DC.W	$0016,$0016,$0016,$0014,$0014,$0014,$0014,$0012,$0012,$0012
DC.W	$0010,$0010,$0010,$000E,$000E,$000C,$000C,$000C,$000A,$000A
DC.W	$000A,$0008,$0008,$0008,$0008,$0006,$0006,$0006,$0004,$0004
DC.W	$0004,$0004,$0002,$0002,$0002,$0002,$0002,$0002,$0000,$0000
DC.W	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
DC.W	$0000,$0000,$0000,$0000,$0002,$0002,$0002,$0002,$0002,$0002
DC.W	$0004,$0004,$0004,$0004,$0006,$0006,$0006,$0008,$0008,$0008
DC.W	$0008,$000A,$000A,$000A,$000C,$000C,$000C,$000C
EndSinTab:

;****************************************************************************

SECTION    GRAPHIC,DATA_C

; We have 2 copperlists

COPPERLIST1:
dc.w    $3007,$fffe    ; wait line $40
dc.w    $0180,$c00    ; colour0
dc.w    $3407,$fffe    ; wait line $44
dc.w	$0180,$000    ; colour0

; Here, some space is left for the copperlist piece that generates
; the plasma. This space is filled by the effect routines.

Plasma1:
dcb.b    alt_plasm*BytesPerLine,0

dc.w    $FA07,$fffe    ; wait line $e0
dc.w    $0180,$c00    ; colour0
dc.w    $FE07,$fffe    ; wait line $e4
dc.w    $0180,$000    ; colour0

dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

COPPERLIST2:
dc.w    $3007,$fffe    ; wait line $40
dc.w    $0180,$c00    ; colour0
dc.w    $3407,$fffe    ; wait line $44
dc.w    $0180,$000    ; colour0

; Here, some empty space is left for the piece of copperlist that generates
; the plasma. This space is filled by the effect routines.

Plasma2:
dcb.b    alt_plasm*BytesPerLine,0

dc.w    $FA07,$fffe    ; wait line $e0
dc.w    $0180,$c00    ; colour0
dc.w    $FE07,$fffe    ; wait line $e4
dc.w    $0180,$000    ; colour0

dc.w    $FFFF,$FFFE    ; End of copperlist


;****************************************************************************
; Here is the table from which the colour components are read.
; The table contains R components. To obtain the G and
; B components, simply shift the data read with the blitter.
; There must be enough values to be read regardless of the starting address
; . In this example, the starting address can vary from
; ‘Color’ (first colour) to ‘Color+28’ (14th colour), because
; 60 is the maximum offset contained in the ‘SinTab’.
; If Largh_plasm=40, it means that each blitter reads 40 values.
; So there must be 54 values in total.
;****************************************************************************

Color:
dcb.w	2,0

DC.W	$0100,$0300,$0500,$0600,$0800,$0A00,$0B00,$0C00,$0D00,$0E00
DC.W	$0F00,$0F00,$0F00,$0F00,$0F00,$0E00,$0D00,$0C00,$0B00,$0A00
DC.W	$0800,$0600,$0500,$0300,$0100

dcb.w	2,0

DC.W	$0100,$0300,$0500,$0600,$0800,$0A00,$0B00,$0C00,$0D00,$0E00
DC.W	$0F00,$0F00,$0F00,$0F00,$0F00,$0E00,$0D00,$0C00,$0B00,$0A00
DC.W	$0800,$0600,$0500,$0300,$0100

end

;****************************************************************************

In this example, we see an RGB plasma.
Given the size of the plasma and the complexity of the blitting (3 channels), it would not
be possible to modify the entire copperlist before the vertical blank ends
and, as a result, part of the copperlist is displayed before
being modified. To solve this problem, it is necessary to use
‘double buffering’ of the copperlists. This is a technique we have
already seen in the example lesson11i2.s: two copperlists are used, which are
displayed alternately. While one of the two is displayed, the
plasma routine writes to the other. Exactly like the ‘double buffering’
of the bitplanes. The copperlists are exchanged by the
‘ScambiaClists’ routine.
To create the RGB plasma, a blitter is used which combines with an
OR operation the R, G and B components of a colour that are read
separately. To save memory, a single table of
components is used. This table contains the R components. To obtain the
G and B components, it is sufficient to shift the read data to the right, an operation that can
be performed ‘on the fly’ by the blitter. Note, however, that the values of the
components are read from different points in the table. In fact, for each
component we have an index that is incremented separately (and at a
different speed).
In this plasma, unlike the one seen in plasm1.s, the blits
occur ‘by row’. Each blit fills a row of the plasma,
while in plsm1.s each blit filled a column.
