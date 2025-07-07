
; Plasma1.s    Plasma 0-bitplanes
;        left key to exit

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001111000000    ; copper,bitplane,blitter DMA

Waitdisk    EQU    10

Largh_plasm    equ    30        ; plasma width expressed
; as number of groups of 8 pixels

BytesPerRiga    equ    (Largh_plasm+2)*4    ; number of bytes occupied
; in the copperlist by each row
; of the plasma: each copper instruction
; occupies 4 bytes

Alt_plasm    equ    100        ; plasma height expressed
; as number of lines

NuovaRiga    equ    4        ; value added to the index in the
; SinTab between one line and another
; Can be varied to obtain different plasmas
; but MUST ALWAYS BE EVEN!!

NuovoFrame    equ    6        ; value subtracted from the index in the
; SinTab between one frame and another
; Can be varied to obtain different plasmas
; but MUST ALWAYS BE EVEN!

START:
lea    $dff000,a5        ; CUSTOM REGISTER in a5

bsr.s    InitPlasma        ; initialise the copperlist

; Initialise the blitter registers

Btst    #6,2(a5)
WaitBlit_init:
Btst    #6,2(a5)        ; wait for the blitter
bne.s    WaitBlit_init

move.l    #$09f00000,$40(a5)    ; BLTCON0/1 - normal copy
moveq    #-1,d0            ; D0 = $FFFFFFFF
move.l    d0,$44(a5)        ; BLTAFWM/BLTALWM

mod_A    set    0            ; channel module A
mod_D    set    BytesPerLine-2        ; channel module D: goes to next line
move.l    #mod_A<<16+mod_D,$64(a5)    ; load module registers

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

; Initialise other hardware registers

move.w    #$000,$180(a5)        ; COLOR00 - black
move.w    #$0200,$100(a5)        ; BPLCON0 - no active bitplanes

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S	Waity1

bsr	DoPlasma

btst	#6,$bfe001	; mouse premuto?
bne.w	mouse

rts

;****************************************************************************
; This routine initialises the copperlist that generates the plasma. It sets the
; WAIT instructions and the first half of the COPPERMOVE instructions. At the end of the
; plasma line, a final COPPERMOVE is inserted that loads the colour
; black into COLOR00.
;****************************************************************************

InitPlasma:
lea    Plasma,a0    ; plasma address
move.l    #$6051FFFE,d0    ; loads the first wait instruction into D0.
; wait for line $60 and horizontal position
; $51
move.w    #$180,d1    ; puts the first half of a 
; ‘copper move’ instruction in COLOR00 (=$dff180)

moveq    #Alt_plasm-1,d3		; loop for each line
InitLoop1:
move.l    d0,(a0)+        ; writes WAIT
add.l    #$01000000,d0        ; modifies WAIT to wait
; for the next line

moveq    #Largh_plasm,d2        ; loop for the entire width
; of the plasma + once for
; the last ‘copper move’ that restores
; black as the background

InitLoop2:
move.w    d1,(a0)+        ; writes the first part of the
; ‘copper move’
addq.l    #2,a0            ; space for the second part
; of the ‘copper move’
; (filled later by the DoPlasma routine)

dbra    d2,InitLoop2

dbra    d3,InitLoop1

rts


;****************************************************************************
; This routine creates the plasma. It performs a loop of blits, each
; of which writes a ‘column’ of plasma, i.e. it writes the colours in
; COPPERMOVES placed in columns.
; The colours written in each column are read from a table, starting from
; an address that varies between columns based on offsets
; read from another table. Furthermore, between one frame and another, the offsets
; vary, creating the movement effect.
;****************************************************************************

DoPlasma:
lea    Colour,a0        ; colour address
lea    SinTab,a3        ; offset table address
lea    Plasma+6,a1        ; address of the first word of the first
; plasma column

move.w	Index(pc),d0        ; reads the starting index of the
; previous frame
sub.w    #NewFrame,d0        ; modifies the index in the table
; from the previous frame
and.w    #$00FF,d0        ; keeps the index in the range
; 0 - 255 (offset in a table of
; 128 words)
move.w    d0,Index        ; stores the starting index for
; the next frame

move.w    #Alt_plasm<<6+1,d3    ; blitted size
; width 1 word, height entire plasma

moveq    #Wide_plasm-1,d2    ; loop for entire width
PlasmaLoop:				; start of bleed loop

move.w    (a3,d0.w),d1        ; read offset from table

lea    (a0,d1.w),a2        ; starting address = colour index
; plus offset

Btst    #6,2(a5)
WaitBlit:
Btst	#6,2(a5)        ; wait for the blitter
bne.s    WaitBlit

move.l    a2,$50(a5)        ; BLTAPT - source address
move.l    a1,$54(a5)        ; BLTDPT - destination address
move.w    d3,$58(a5)        ; BLTSIZE

addq.w    #4,a1            ; points to the next column of 
; ‘copper moves’ in the copper list

add.w    #NewRow,d0        ; modifies the index in the table
; for the next row

and.w    #$00FF,d0        ; keeps the index in the range
; 0 - 255 (offset in a table of
; 128 words)

dbra    d2,PlasmaLoop
rts


; This variable contains the index value for the first column

Index:    dc.w    0

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

SECTION    GRAPHIC,DATA_C

COPPERLIST:

dc.w    $4007,$fffe    ; wait line $40
dc.w    $0180,$c00    ; colour0
dc.w    $4407,$fffe    ; wait line $44
dc.w    $0180,$000    ; colour0

; Here, some space is left blank for the copperlist piece that generates
; the plasma. This space is filled by the effect routines.

PLASMA:
dcb.b    alt_plasm*BytesPerLine,0

dc.w    $e007,$fffe    ; wait line $e0
dc.w    $0180,$c00    ; colour0
dc.w    $e407,$fffe    ; wait line $e4
dc.w    $0180,$000    ; colour0

dc.w	$FFFF,$FFFE	; Fine della copperlist


;****************************************************************************
; Here is the colour table that is written in the plasma.
; There must be enough colours to be read regardless of the starting address
;. In this example, the starting address can vary from
; ‘Colour’ (first colour) to ‘Colour+100’ (50th colour), because
; 100 is the maximum offset contained in the ‘SinTab’.
; If Alt_plasm=100, it means that each blit reads 100 colours.
; So there must be 150 colours in total.
;****************************************************************************

Color:
dc.w	$100,$200,$300,$400,$500,$600,$700
dc.w	$800,$900,$A00,$B00,$C00,$D00,$E00,$F00

dc.w	$F00,$E00,$D00,$C00,$B00,$A00,$900,$800
dc.w	$700,$600,$500,$400,$300,$200

dc.w	$002,$003,$004,$005,$006,$007
dc.w	$008,$009,$00A,$00B,$00C,$00D,$00E,$00F

dc.w $00e,$01d,$02d,$03d,$04d,$05d,$06d,$07d,$08d,$09d	; blu-verde
dc.w $0Ad,$0Bd,$0Cd,$0Dd,$0Ed,$0Fd,$0Fd,$0Ed,$0Dd,$0Cd
dc.w $0Bd,$0Ad,$09d,$08d,$07d,$06d,$05d,$04d,$03d,$02d
dc.w $01d,$00e

dc.w $00e,$01d,$02c,$03b,$04a,$059,$068,$077,$086,$095	; blu-verde
dc.w $0A4,$0B3,$0C2,$0D1,$0E0


dc.w	$0F0,$0E0,$0D0,$0C0,$0B0,$0A0,$090,$080
dc.w	$070,$060,$050,$040,$030,$020,$010

dc.w	$010,$020,$030,$040,$050,$060,$070
dc.w	$080,$090,$0A0,$0B0,$0C0,$0D0,$0E0,$0F0

dc.w    $1F0,$2F0,$3F0,$4F0,$5F0,$6F0,$7F0,$8F0
dc.w    $9F0,$AF0,$BF0,$CF0,$DF0,$EF0,$FF0

dc.w	$FF0,$EE0,$DD0,$CC0,$BB0,$AA0,$990,$880
dc.w	$770,$660,$550,$440,$330,$220,$110

end

;****************************************************************************

In this example we have a 0-bitplane plasma.
The effect is based on a piece of copperlist that is constructed by the
‘InitPlasma’ routine. This piece works as follows: for each line of the
screen it performs a series of ‘copper moves’ that change the value of COLOR00.
The last ‘copper move’ sets the value $000 (black) back in COLOR00. This forms
a rectangular table of ‘copper moves’. The number of ‘copper
moves’ in each row (excluding the last one, which sets the background to
black) is equal to the value of the ‘Largh_plasm’ parameter. The number of rows that
make up the plasma is equal to the “Alt_plasm” parameter. In total, we therefore have
a number of ‘copper moves’ (again excluding those that reset the black)
equal to Largh_plasm*Alt_plasm. The ‘InitPlasma’ routine does not write the colours
loaded by these ‘copper moves’ (i.e. it does not write the second words).
This task is left to the ‘DoPlasma’ routine, which is executed at
every frame, and which each time writes different values in the second words
of the ‘copper moves’. Writing is done using a bleed loop.
Each bleed fills a “column” of ‘copper moves’. For example, the
first bleed writes the second word of the first ‘copper move’ of each
row. The colour values are read from a table. At each iteration,
 the colours are read starting from a different position in the table. Even between
frames, the starting position is varied. All position variations
are based on tables and can be varied by adjusting the
two parameters ‘NewRow’ and ‘NewFrame’.
Note that the routine has been optimised by initialising all blitter registers
at the beginning of the programme.
