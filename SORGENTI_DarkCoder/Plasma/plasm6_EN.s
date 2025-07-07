
; Plasma6.s    4-bitplane RGB plasma with ripple
;        left key to exit

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper,bitplane,blitter DMA

Waitdisk    EQU    10

Largh_plasm    equ    40        ; plasma width expressed
; as number of groups of 8 pixels

; number of bytes occupied in the copperlist by each row of the plasma: each
; copper instruction occupies 4 bytes. Each row consists of 1 WAIT, Largh_plasm
; ‘copper moves’ for the plasma.

BytesPerRiga    equ	(Plasma_width+1)*4

Plasma_height    equ    190        ; plasma height expressed
; as number of lines

NewLineR    equ    -4        ; value added to the R index in the
; SinTab between one line and another
; It can be varied to obtain different plasmas
; but it MUST ALWAYS BE EVEN!

NuovoFrameR    equ    16        ; value subtracted from the R index in the
; SinTab between one frame and another
; It can be varied to obtain different plasmas
; but it MUST ALWAYS BE EVEN!

NewRowG    equ    -22        ; as ‘NewRowR’ but for component G
NewFrameG    equ    2        ; as ‘NewFrameR’ but for component G

NewRowB    equ    40        ; as “NewRowR” but for component B
NewFrameB    equ    4        ; as ‘NewFrameR’ but for component B

NewRowO    equ    4        ; as ‘NewRowR’ but for oscillations
NewFrameO    equ    2        ; as ‘NewFrameR’ but oscillations


START:

;    Point to the image in the copperlist

LEA    COPPERLIST1,A1    ; COP pointers 1
LEA    COPPERLIST2,A2    ; COP pointers 2
MOVE.L    #BUFFER,d0    ; where to point
move.w    d0,6(a1)    ; writes to copperlist 1
move.w    d0,6(a2)	; writes to copperlist 2
swap    d0
move.w    d0,2(a1)    ; writes to copperlist 1
move.w    d0,2(a2)    ; writes to copperlist 2

; bitplane 2 - part 2 bytes further on

MOVE.L    #BUFFER+2,d0
move.w    d0,6+8(a1)
move.w    d0,6+8(a2)
swap    d0
move.w    d0,2+8(a1)
move.w    d0,2+8(a2)

; bitplane 3 - part 2 bytes ahead

MOVE.L    #BUFFER+2,d0
move.w    d0,6+8*2(a1)
move.w    d0,6+8*2(a2)
swap    d0
move.w    d0,2+8*2(a1)
move.w    d0,2+8*2(a2)

; bitplane 4 - part 4 bytes ahead

MOVE.L    #BUFFER+4,d0
move.w    d0,6+8*3(a1)
move.w    d0,6+8*3(a2)
swap    d0
move.w    d0,2+8*3(a1)
move.w    d0,2+8*3(a2)

lea    $dff000,a5        ; CUSTOM REGISTER in a5

bsr	InitPlasma        ; initialise the copperlist

; Initialise the blitter registers

Btst    #6,2(a5)
WaitBlit_init:
Btst    #6,2(a5)        ; wait for the blitter
bne.s    WaitBlit_init

moveq    #-1,d0            ; D0 = $FFFFFFFF
move.l    d0,$44(a5)        ; BLTAFWM/BLTALWM

move.w    #$8000,$42(a5)        ; BLTCON1 - shift 8 pixels channel B
; (used for plasma)

mod_A    set    0            ; channel A module
mod_D    set    BytesPerLine-2        ; channel D module: goes to the next line

move.l	#mod_A<<16+mod_D,$64(a5)    ; load module registers

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
move.w
	#$30b8,$8e(a5)        ; DiwStrt - we use a window smaller than the screen to mask
the wavy edges.
move.w    #$ee90,$90(a5)        ; DiwStop

move.w    #$0038,$92(a5)        ; DDFStrt - 40 bytes are fetched
move.w    #$00d0,$94(a5)        ; DDFStop
move.w    d0,$104(a5)        ; BPLCON2
move.w    #$0080,$102(a5)        ; BPLCON1 - even planes are shifted
; 8 pixels to the right
move.w    #4,$108(a5)        ; BPL1MOD = 4 - fetches 40 bytes out of 44
move.w	#4,$10a(a5)        ; BPL2MOD = 4 - fetch 40 bytes out of 44
move.w    #$4200,$100(a5)        ; BPLCON0 - 4 bitplanes active

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
; This routine creates the bitplanes, producing the oscillation effect.
; The buffer at address ‘PlasmaLine’ contains one line of the figure.
; This buffer is copied into the video buffer as many times as the plasma is high
; thus forming the entire figure. Each line is shifted to the right
; by a variable value, thus creating the undulation.
;****************************************************************************

DoOriz:
lea    OrizTab(pc),a0        ; oscillation table address
lea    BUFFER,a1        ; video buffer address (destination)
lea    PlasmaLine,a3        ; buffer address containing the
; line (source)

move.w	#1*64+19,d2        ; blitted size:
; width 40 bytes
; height 1 line

; reads and modifies index

move.w    IndexO(pc),d4        ; reads the starting index of the
; previous frame
sub.w	#NewFrameO,d4        ; modifies the index in the table
; from the previous frame
and.w    #$00FF,d4        ; keeps the index in the range
; 0 - 255 (offset in a table of
; 256 bytes)
move.w    d4,IndexO        ; stores the starting index for
; the next frame

move.w    #Alt_plasm-1,d3        ; loop for each line
OrizLoop:
move.b	0(a0,d4.w),d0        ; read oscillation value

moveq    #0,d1            ; clears D1
move.b    d0,d1            ; copies oscillation value
and.w    #$000f,d0        ; leaves only the 4 low bits
ror.w    #4,d0            ; move them to the first positions
or.w    #$09f0,d0        ; value to be written in BLTCON0

asr.w    #4,d1			
add.w    d1,d1            ; calculates number of bytes
lea    (a1,d1.w),a2        ; source address

Btst    #6,2(a5)
WaitBlit_Oriz:
Btst    #6,2(a5)        ; waits for the blitter
bne.s    WaitBlit_Oriz

move.w    d0,$40(a5)        ; BLTCON0 - copy from A to D with shift
move.l    a3,$50(a5)        ; BLTAPT - source address
move.l    a2,$54(a5)        ; BLTDPT - destination address
move.w    d2,$58(a5)		; BLTSIZE

lea    44(a1),a1        ; points to the next line 
; of the video buffer

; modifies the index for the next line

add.w    #NewLineO,d4        ; modifies the index in the table
; for the next line

and.w    #$00FF,d4		; keeps the index in the range
; 0 - 255 (offset in a table of
; 256 bytes)
dbra    d3,OrizLoop
rts

;****************************************************************************
; This routine creates the ‘double buffer’ between the copperlists.
; In practice, it takes the clist where it is drawn and displays it by copying
; its address to COP1LC. It swaps the variables so that in the
; following frame it is drawn on the other copper list
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
move.l    #$303FFFFE,d0    ; load the first wait instruction into D0.
; wait for line $30 and horizontal position
; $3F

move.w    #Alt_plasm-1,d3        ; loop for each line
InitLoop1:

move.l    d0,(a0)+        ; writes WAIT - (clist 1)
move.l    d0,(a1)+        ; writes WAIT - (clist 2)
add.l    #01000000,d0        ; modifies WAIT to wait
; for the following line

moveq	#Largh_plasm/8-1,d2    ; each iteration writes 8 copper moves

InitLoop2:

; copperlist 1

move.w    #0194,(a0)+        ;comb 10
addq.w    #2,a0            ; space for the second part
; of the ‘copper move’
move.w    #019a,(a0)+        ; colour 13
addq.w    #2,a0
move.w    #018c,(a0)+        ; colour 6
addq.w    #2,a0
move.w    #0196,(a0)+        ; colour 11
addq.w    #2,a0
move.w    #018a,(a0)+        ; colour 5
addq.w    #2,a0
move.w    #0184,(a0)+        ; colour 2
addq.w    #2,a0
move.w    #$0192,(a0)+        ; colour 9
addq.w    #2,a0
move.w    #$0188,(a0)+        ; colour 4
addq.w    #2,a0

; copperlist 2

move.w    #$0194,(a1)+		; colour 10
addq.w    #2,a1            ; space for the second part
; of the ‘copper move’
move.w    #019a,(a1)+        ; colour 13
addq.w    #2,a1
move.w    #018c,(a1)+        ; colour 6
addq.w    #2,a1
move.w    #0196,(a1)+        ; colour 11
addq.w    #2,a1
move.w    #018a,(a1)+        ; colour 5
addq.w    #2,a1
move.w    #0184,(a1)+        ; colour 2
addq.w    #2,a1
move.w    #0192,(a1)+        ; colour 9
addq.w	#2,a1
move.w	#$0188,(a1)+		; colore 4
addq.w	#2,a1
dbra	d2,InitLoop2
dbra	d3,InitLoop1
rts


;****************************************************************************
; This routine creates the plasma. It performs a loop of blits, each
; of which writes a ‘column’ of plasma, i.e. it writes the colours in
; COPPERMOVES placed in columns.
; The colours written in each column are read from a table, starting from
; an address that varies between columns based on offsets
; read from another table. Furthermore, between one frame and another, the offsets
; vary, creating the effect of movement.
;****************************************************************************

DoPlasma:
lea    Colour,a0        ; colour address
lea    SinTab,a6        ; offset table address
move.l    draw_clist(pc),a1    ; copperlist address where to write
lea    38(a1),a1        ; address of the first word of the first
; plasma column
; reads and modifies the R component index

move.w    IndiceR(pc),d4        ; reads the starting index of the
; previous frame
sub.w    #NuovoFrameR,d4        ; modifies the index in the table
; from the previous frame
and.w    #$00FF,d4        ; keeps the index in the range
; 0 - 255 (offset in a table of
; 128 words)
move.w    d4,IndiceR        ; stores the starting index for
; the next frame
; reads and modifies component index G

move.w    IndiceG(pc),d5        ; reads the starting index of the
; previous frame
sub.w	#NewFrameG,d5        ; modifies the index in the table
; from the previous frame
and.w    #$00FF,d5        ; keeps the index in the range
; 0 - 255 (offset in a table of
; 128 words)
move.w    d5,IndiceG        ; stores the starting index for
; the next frame
; reads and modifies component B index

move.w    IndiceB(pc),d6        ; reads the starting index of the
; previous frame
sub.w    #NewFrameB,d6        ; modifies the index in the table
; from the previous frame
and.w    #$00FF,d6        ; keeps the index in the range
; 0 - 255 (offset in a table of
; 128 words)
move.w    d6,IndexB        ; stores the starting index for
; the next frame

move.w    #Alt_plasm<<6+1,d3    ; blitted size
; width 1 word, height entire plasma

moveq    #Largh_plasm-6-1,d2    ; the loop is NOT repeated for the entire
; width. The columns furthest to the
; right are not visible,
; so there is no point in blitting them.

Btst    #6,2(a5)        ; initialise the blitter registers
WaitBlit_Plasma:            ; for the plasma
Btst    #6,2(a5)        ; wait for the blitter
bne.s    WaitBlit_Plasma

move.w    #$4FFE,$40(a5)        ; BLTCON0 - D=A+B+C, shift A = 4 pixels

PlasmaLoop:                ; start bleed loop

; calculate start address of R component

move.w    (a6,d4.w),d1        ; read offset from table

lea    (a0,d1.w),a2        ; start address = colour index
; plus offset

; calculate start address of G component

move.w    (a6,d5.w),d1        ; read offset from table

lea    (a0,d1.w),a3        ; start address = colour index
; plus offset

; calculate start address of component B

move.w    (a6,d6.w),d1        ; read offset from table

lea    (a0,d1.w),a4        ; start address = colour index
; plus offset

Btst    #6,2(a5)
WaitBlit:
Btst    #6,2(a5)        ; wait for the blitter
bne.s    WaitBlit

move.l    a2,$48(a5)        ; BLTCPT - source address R
move.l    a3,$50(a5)        ; BLTAPT - source address G
move.l    a4,$4C(a5)        ; BLTBPT - source address B
move.l    a1,$54(a5)		; BLTDPT - destination address
move.w    d3,$58(a5)        ; BLTSIZE

addq.w    #4,a1            ; points to next column of 
; ‘copper moves’ in the copper list

; modifies R component index for next line

add.w	#NewRowR,d4        ; modify the index in the table
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

; modifies component B index for next line

add.w    #NewLineB,d6        ; modifies the index in the table
; for the next line

and.w	#$00FF,d6        ; keeps the index in the range
; 0 - 255 (offset in a table of
; 128 words)
dbra    d2,PlasmaLoop
rts


; These 2 variables contain the addresses of the 2 copperlists

view_clist:    dc.l    COPPERLIST1    ; address of the clist being displayed
draw_clist:    dc.l    COPPERLIST2    ; address of the clist to draw

; This variable contains the index value in the
; oscillation

IndexO:    dc.w    0

; This table contains the oscillation values

OrizTab:
DC.B	$1C,$1D,$1E,$1E,$1F,$20,$20,$21,$22,$22,$23,$24,$24,$25,$25,$26
DC.B    $27,$27,$28,$28,$29,$2A,$2A,$2B,$2B,$2C,$2C,$2D,$2D,$2E,$2E,$2F
DC.B	$2F,$30,$30,$31,$31,$31,$32,$32,$33,$33,$33,$34,$34,$34,$35,$35
DC.B	$35,$35,$36,$36,$36,$36,$36,$36,$37,$37,$37,$37,$37,$37,$37,$37
DC.B	$37,$37,$37,$37,$37,$37,$37,$37,$36,$36,$36,$36,$36,$36,$35,$35
DC.B	$35,$35,$34,$34,$34,$33,$33,$33,$32,$32,$31,$31,$31,$30,$30,$2F
DC.B    $2F,$2E,$2E,$2D,$2D,$2C,$2C,$2B,$2B,$2A,$2A,$29,$28,$28,$27,$27
DC.B	$26,$25,$25,$24,$24,$23,$22,$22,$21,$20,$20,$1F,$1E,$1E,$1D,$1C
DC.B	$1C,$1B,$1A,$1A,$19,$18,$18,$17,$16,$16,$15,$14,$14,$13,$13,$12
DC.B    $11,$11,$10,$10,$0F,$0E,$0E,$0D,$0D,$0C,$0C,$0B,$0B,$0A,$0A,$09
DC.B	$09,$08,$08,$07,$07,$07,$06,$06,$05,$05,$05,$04,$04,$04,$03,$03
DC.B	$03,$03,$02,$02,$02,$02,$02,$02,$01,$01,$01,$01,$01,$01,$01,$01
DC.B	$01,$01,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$02,$03,$03
DC.B	$03,$03,$04,$04,$04,$05,$05,$05,$06,$06,$07,$07,$07,$08,$08,$09
DC.B	$09,$0A,$0A,$0B,$0B,$0C,$0C,$0D,$0D,$0E,$0E,$0F,$10,$10,$11,$11
DC.B    $12,$13,$13,$14,$14,$15,$16,$16,$17,$18,$18,$19,$1A,$1A,$1B,$1C

; These variables contain the index values for the first column

IndexR:    dc.w	0
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

SECTION	GRAPHIC,DATA_C

; Abbiamo 2 copperlists 

COPPERLIST1:
dc.w	$e0,$0000,$e2,$0000	; bitplane 1
dc.w    $e4,$0000,$e6,$0000
dc.w    $e8,$0000,$ea,$0000
dc.w    $ec,$0000,$ee,$0000

; Here, some space is left for the copperlist piece that generates
; the plasma. This space is filled by the effect routines.

PLASMA1:
dcb.b    alt_plasm*BytesPerLine,0
dc.w    $FFFF,$FFFE    ; End of copperlist

;****************************************************************************

COPPERLIST2:
dc.w	$e0,$0000,$e2,$0000	; bitplane 1
dc.w	$e4,$0000,$e6,$0000	; bitplane 2
dc.w    $e8,$0000,$ea,$0000    ; bitplane 3
dc.w    $ec,$0000,$ee,$0000    ; bitplane 4

; Here, some space is left for the piece of copperlist that generates
; the plasma. This space is filled by the effect routines.

PLASMA2:
dcb.b	alt_plasm*BytesPerRiga,0

dc.w	$FFFF,$FFFE	; Fine della copperlist


;****************************************************************************
; Here is the colour table that is written to the plasma.
; There must be enough colours to be read regardless of the starting address
; . In this example, the starting address can vary from
‘Colour’ (first colour) to ‘Colour+100’ (50th colour), because
100 is the maximum offset contained in the ‘SinTab’.
If Alt_plasm=190, it means that each blit reads 190 colours.
Therefore, there must be a total of 240 colours.

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

;****************************************************************************
; Buffer containing one line of the image (44 bytes) that makes up the planes
; The image is formed by copying this buffer as many times as the
; plasma in the video buffer is high.
;****************************************************************************

PlasmaLine:
rept	5
dc.l	$00ff00ff,$ff00ff00
endr
dc.l	$00ff00ff

;****************************************************************************

SECTION    PlasmaBit,BSS_C

; Space for the bitplanes. For all 4 bitplanes, an image 44 bytes wide
and as high as the entire plasma is used

BUFFER:
ds.b    44*Alt_Plasm

end



;****************************************************************************

In this example, we show a 4-bitplane plasma with amplitude modulation
of 56 pixels.
To achieve this result, we use 8 colour registers in the plasma that
are changed cyclically. This means that a register maintains a
constant value for 8*8=64 pixels. Therefore, a group of 8 pixels can move
by 64-8=56 pixels while always remaining within the range where the colour is
constant. To achieve such large ripples, we cannot use hardware scrolling
. As a result, we cannot use the same
line repeated with the negative module for the entire image. We need a complete image,
so that each line can be shifted independently of the
others. Let's proceed in this way. We have a buffer where the
line that makes up the image is stored. The contents of this buffer are copied
into video buffer, as many times as there are lines that make up the plasma
in order to build the desired image line by line. Each line is
appropriately shifted to create the wave.
If we had to copy all the lines of all the bitplanes, we would have to perform
a large number of bleeds. To reduce the number of blits, we use a
trick. In practice, we use the same image for all bitplanes.
The starting buffer is created as follows:

dc.l    $00ff00ff,$ff00ff00,$00ff00ff,$ff00ff00 - - -

Once we have copied it to the video buffer, we point the first bitplane
to the beginning of the video buffer, the second and third 2 bytes after the beginning
of the video buffer, and the fourth 4 bytes after the beginning of the video buffer.
In addition, we shift the even bitplanes by 8 pixels.
To sum up:
bitplane 1 points to BUFFER
bitplane 2 points to BUFFER+2 + shift of 8 pixels to the right
bitplane 3 points to BUFFER+2
bitplane 4 points to BUFFER+4 + shift of 8 pixels to the right

The planes overlap, generating 8 colours:

bitplane 1: dc.l $00ff00ffff00ff0000 ff00ffff00ff0000 ff00ffff00ff0000
bitplane 2: dc.l $--00ffff00ff0000ff 00ffff00ff0000ff 00ffff00ff0000
bitplane 3: dc.l $00ffff00ff0000ff00 ffff00ff0000ff00 ffff00ff0000
bitplane 4: dc.l $--ff00ff0000ff00ff ff00ff0000ff00ff ff00ff0000
| | | | | | | | | | | | | | | | |
colour -- 06 05 09 10 06 05 09 10
13 11 02 04 13 11 02 04

As you can see, a cyclic repetition of 8 colours is generated, which are used
in the copperlist to generate the plasma.
In this way, we have a single image that is used for all 4
planes, and therefore by copying this single image we copy 4 bitplanes with one stroke,
 greatly speeding up the effect.
Let's now look at the technical details.
 Each bitplane is 40 bytes wide. Since bitplane 4 starts 4 bytes after bitplane 1, it must also end 4 bytes after.
Because of this, the video buffer (which contains all 4 bitplanes)
is 44 bytes wide, so the BPLxMOD registers will have a value of 4.
Furthermore, due to the bitplane shifts, the image is not rectangular but
has wavy edges. In addition, at the left edge, the bitplanes do not match
perfectly. To avoid showing the defects at the edges, we have narrowed the
video window with the DIWSTRT and DIWSTOP registers. If you want to see what happens
at the edges, enlarge it.
 
Because of this narrowing, the columns furthest to the right of the plasma are not
visible and therefore it is useless to bleed them (the ones furthest to the left, even if they are not
visible, must still be bled because the band in which a colour remains
constant is partially visible).
