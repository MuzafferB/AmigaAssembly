
; Lesson11i6.s - ‘pseudo 3D’ copper fade effect

SECTION    Barrex,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup2.s’ ; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %100000101000000    ; copper DMA only

WaitDisk    EQU    30    ; 50-150 when saving (depending on the case)

START:
bsr.s    makerast    ; Make the copperlist

lea    $dff000,a5
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
; and sprites.

move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)		; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

mouse:
MOVE.L	#$1ff00,d1    ; bit for selection via AND
MOVE.L    #$12c00,d2    ; line to wait for = $12c
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $12c
BNE.S    Waity1
Wait:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $12c
BEQ.S    Wait

bsr.s    MakeRast    ; roll colours

btst    #6,$bfe001    ; mouse pressed?
bne.s	mouse
rts

*****************************************************************************
;	Routine che crea la copperlist
*****************************************************************************

;     Oo
;     `--'

MakeRast:
lea Offsets(PC),a2    ; table with 8*20 values of the offsets between the
; wait lines
sub.w    #1*20,AnimWaitCounter
bpl.s    nocolscroll
addq.b    #1,ColourCounter
move.w    #7*20,WaitAnimCounter
nocolscroll:
moveq    #0,d0        ; reset d0
move.w    WaitAnimCounter(PC),d0
add.w    d0,a2        ; find the right offset in the Offsets table
lea    CopBuffer,a0

moveq    #0,d0
move.b    ColourCounter(PC),d0

moveq    #20,d3        ; number of loops DoCopper
lea Colors(PC),a1    ; table with colours
DoCopper:
and.w    #%01111111,d0	; only the first 7 bits of d0 are needed
move.w    d0,d2        ; put the last colour value back into d2
; saved
asl.l    #1,d2        ; and move it to the left by 1 bit, which
; means multiplying the value by 2, given
; that the values in the table are .w (2 bytes)
; this way, the value of d2 is ready
; for the final ‘move.w (a1,d2),(a0)+’

addq.b    #1,d0        ; next colour for the next loop

moveq    #0,d1        ; reset d1
move.b    (a2)+,d1    ; take the next offset from the table

add.b    #$0f,d1        ; offset from line $00, i.e. from the beginning
; of the screen, to be added to the values
; read in TAB
asl.w    #8,d1		; move the value to the left by 8 bits, given that
; this is the vertical coordinate
; e.g.: it was previously $0019, so it becomes $1900

or.w    #$07,d1        ; horizontal line of waits: 07 (with OR,
; the final 07 is added, e.g.: $1907,$fffe...)
move.w    d1,(a0)+    ; first word of the wait with line and column
move.w    #$fffe,(a0)+    ; second word of the WAIT
move.w    #$0180,(a0)+	; COLOR0
move.w    (a1,d2),(a0)+    ; copy the right colour from the table to the
; copperlist
dbra    d3,FaiCopper
rts



;    table with the colours of the gradient. 128 values.w

Colours:
dc.w $111,$444,$222,$777,$333,$aaa,$333,$aaa    ; first grey part
dc.w $333,$aaa,$333,$aaa,$333,$aaa,$333,$aaa
dc.w $222,$777,$222,$444,$111,$000

dc.w $000,$100,$200,$300,$400,$500,$600,$700    ; coloured part
dc.w $800,$900,$a00,$b00,$c00,$d00,$e00
dc.w $f00,$f10,$f20,$f30,$f40,$f50,$f60,$f70
dc.w $f80,$f90,$fa0,$fb0,$fc0,$fd0,$fe0
dc.w $ff0,$ef0,$df0,$cf0,$bf0,$af0,$9f0,$8f0
dc.w $7f0,$6f0,$5f0,$4f0,$3f0,$2f0,$1f0
dc.w $0f0,$0f1,$0f2,$0f3,$0f4,$0f5,$0f6,$0f7
dc.w $0f8,$0f9,$0fa,$0fb,$0fc,$0fd,$0fe
dc.w $0ff,$0ef,$0df,$0cf,$0bf,$0af,$09f,$08f
dc.w $07f,$06f,$05f,$04f,$03f,$02f,$01f
dc.w $00f,$10f,$20f,$30f,$40f,$50f,$60f,$70f
dc.w $80f,$90f,$a0f,$b0f,$c0f,$d0f,$e0f
dc.w $f0f,$e0e,$d0d,$c0c,$b0b,$a0a,$909,$808
dc.w $707,$606,$505,$404,$303,$202,$101,$000


; Table for distances between lines.
; There are 8 lines of 20 values, for a total of 20*8=160 bytes
; Note that while the first values of each line are very far apart
; (0,16,28,37...), the last ones are consecutive (77,78,79)
; Questo e' per rendere una specie di prospettiva:
;
;	------------------------------------------------------------
;
;	------------------------------------------------------------
;	____________________________________________________________
;	____________________________________________________________
;	------------------------------------------------------------
;
; There are 8 lines of 20 values, as each frame the waits “move”
; scrolling upwards (note: 0.16.. first line, 2.18... the second, 6.21 the
; third). In this way, in addition to being arranged in a ‘pseudo-perspective’,
; they scroll upwards, making the effect more credible. We could say that
; this is a table with 8 ‘frames’ of animation of the waits!!!

Offsets:
dc.b 0,16,28,37,44,50,54,58,61,64,66,68,70,72,74,75,76,77,78,79
dc.b 2,18,29,38,45,50,55,58,61,64,66,68,70,72,74,75,76,77,78,79
dc.b 4,20,31,39,45,51,55,58,62,64,67,69,71,72,74,75,76,77,78,79
dc.b 6,21,32,40,46,51,56,59,62,65,67,69,71,72,74,75,76,77,78,79
dc.b 8,23,33,41,47,52,56,60,62,65,67,69,71,72,74,75,76,77,78,79
dc.b 10,24,34,42,48,52,56,60,63,65,68,69,71,73,74,75,76,77,78,79
dc.b 12,25,35,42,48,53,57,60,63,66,68,70,71,73,74,75,76,77,78,79
dc.b 14,27,36,43,49,54,57,61,63,66,68,70,71,73,74,75,76,77,78,79

WaitAnim counter:
dc.w    7*20

Colour counter:
dc.b    0

even

*****************************************************************************
;	Copperlist
*****************************************************************************

Section    Graphics,data_C

copperlist:
dc.w    $8e,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0		; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,40        ; Bpl1Mod
dc.w    $10a,40        ; Bpl2Mod

dc.w    $180,$000    ; Color0 black
dc.w    $100,$200    ; bplcon0 - no bitplanes

CopBuffer:
dcb.w    21*4,0        ; space where the effect is created

dc.w    $6007,$fffe    ; grey ‘flooring’
dc.w    $0180,$0444
dc.w    $6207,$fffe
dc.w    $0180,$0666
dc.w    $6507,$fffe
dc.w    $0180,$0888
dc.w    $6907,$fffe
dc.w    $0180,$0aaa

dc.w    $FFFF,$FFFE    ; End of copperlist


end
