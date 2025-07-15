
; Lesson 11h2.s    - Routine that generates shaded bars - USE THE
;         RIGHT MOUSE BUTTON TO INCREASE THE HEIGHT OF THE BARS.

SECTION    Barrex,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’ ; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001010000000    ; copper DMA only

WaitDisk    EQU    30    ; 50-150 when saving (depending on the case)

LINES:    equ    211

START:
bsr.s    FaiCopp1

lea    $dff000,a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.

move.l    #OURCOPPER,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)		; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$10500,d2    ; line to wait for = $105
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $105
BNE.S	Waity1

BSR.s    changecop    ; call the routine that changes the copper

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse
rts

*****************************************************************************
; routine that creates the copperlist
*****************************************************************************

FaiCopp1:
LEA    copcols,a0    ; buffer address in copperlist
MOVE.L	#$2c07fffe,d1    ; copper wait instruction, which starts
; waiting at line $2c
MOVE.L    #$1800000,d2    ; $dff180 = colour 0 for the copper
MOVE.w    #LINEE-1,d0    ; number of lines for the loop
MOVEQ    #$000,d3	; colour to set = black
coploop:
MOVE.L    d1,(a0)+    ; Set WAIT
MOVE.L    d2,(a0)+    ; Set $180 (colour0) to BLACK
ADD.L    #01000000,d1    ; Wait for WAIT 1 line after
DBRA    d0,coploop    ; repeat until the end of the lines
rts

*****************************************************************************
; routine that changes the colours in the copperlist
*****************************************************************************

;     ________________________
;     / \
;     ___ ___\ ehHHHHhHh? \
;     /_ ¯¯¯ _\\_ ______________________/
;     \ \_____/ / / /
;     \_(°I°)_/ / /
;     _l_¯U¯_l_ \/
;     / T¯¬¯T \
;    / _________ \ xCz
;    ¯¯ ¯¯

changecop:
btst    #2,$dff016    ; right key pressed?
bne.s    noadd        ; if not, jump to noadd
cmp.b    #$24,barlen    ; otherwise check if we are already at $24
beq.s    noadd        ; if so, jump to noadd
addq.b    #1,barlen    ; or enlarge the bar (BARLEN)
noadd:
LEA    copcols,a0    ; buffer address in copperlist
MOVE.w    #LINEE-1,d0    ; number of lines for the loop
MOVE.L    PuntatoreTABCol(PC),a1    ; start of the colour table in a1
move.l    a1,PuntatTemporaneo    ; saved in PuntatoreTemporaneo
moveq    #0,d1            ; reset d1
LineeLoop:
move.w	(a1)+,6(a0)    ; copy the colour from the table to the copperlist
addq.w    #8,a0        ; next colour0 in copperlist
addq.b    #1,d1        ; note the length of the sub-bar in d1
cmp.b    barlen(PC),d1    ; end of sub-bar?
bne.s	WaitUnderBar

MOVE.L    TemporaryPoint(PC),a1
addq.w    #2,a1            ; point to the next colour
cmp.l    #FINETABColBar,TemporaryPoint    ; are we at the end of the tab?
bne.s    DoNotRestart        ; if not, go to DoNotRestart
lea	TABColoriBarra(pc),a1    ; otherwise restart from the first colour!
NonRipartire:
move.l    a1,PuntatTemporaneo    ; and save the value in the temporary pointer
moveq    #0,d1            ; reset d1
AspettaSottoBarra:
dbra d0,LineeLoop    ; draw all the lines


addq.l    #2,TABColPointer         ; next colour
cmp.l    #FINETABColBar+2,TABColPointer ; are we at the end of the
; colour table?
bne.s EndRoutine             ; if not, exit, otherwise...
move.l #TABColBar,TABColPointer	 ; start again from the first value of
; TABColoriBarra
FineRoutine:
rts

;    bar height

barlen:
dc.b    1

even


;    Table with RGB colour values. In this case, they are shades of BLUE

TABColoriBarra:
dc.w	$000,$001,$002,$003,$004,$005,$006,$007
dc.w	$008,$009,$00A,$00B,$00C,$00D,$00D,$00E
dc.w	$00E,$00F,$00F,$00F,$00E,$00E,$00D,$00D
dc.w	$00C,$00B,$00A,$009,$008,$007,$006,$005
dc.w	$004,$003,$002,$001,$000,$000,$000,$000
dcb.w	10,$000
FINETABColBarra:
dc.w	$000,$001,$002,$003,$004,$005,$006,$007    ; these values are needed
dc.w    $008,$009,$00A,$00B,$00C,$00D,$00D,$00E ; for the sub-bars
dc.w	$00E,$00F,$00F,$00F,$00E,$00E,$00D,$00D
dc.w	$00C,$00B,$00A,$009,$008,$007,$006,$005
dc.w    $004,$003,$002,$001,$000,$000,$000,$000


Temporary pointer:
dc.l    TABColoriBarra

TABCol pointer:
DC.L    TABColoriBarra

*****************************************************************************

Section    Coppy,data_C

OURCOPPER:
dc.w    $180,$000    ; Colour0 black
dc.w    $100,$200    ; bplcon0 - no bitplanes

copcols:
dcb.b    LINEE*8,0    ; space for 100 lines in this format:
; WAIT xx07,$fffe
; MOVE $xxx,$180    ; colour0
dc.w    $ffdf,$fffe
dc.w    $0107,$fffe
dc.w    $180,$010
dc.w    $0207,$fffe
dc.w    $180,$020
dc.w    $0307,$fffe
dc.w    $180,$030
dc.w    $0507,$fffe
dc.w    $180,$040
dc.w    $0707,$fffe
dc.w    $180,$050
dc.w    $0907,$fffe
dc.w    $180,$060
dc.w    $0c07,$fffe
dc.w    $180,$070
dc.w    $0f07,$fffe
dc.w    $180,$080
dc.w    $1207,$fffe
dc.w    $180,$090
dc.w    $1507,$fffe
dc.w    $180,$0a0

dc.w    $180,$000    ; colour0 black
dc.w    $FFFF,$FFFE    ; End of copperlist

end
