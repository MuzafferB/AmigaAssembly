
; Lesson 6q.s    Some ‘chessboards’ created on the screen
;        - ALTERNATE LEFT-RIGHT-LEFT MOUSE BUTTONS to
;        view the chessboards and exit

SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase
jsr    -$78(a6)    ; Disable
lea    GfxName(PC),a1    ; Lib name
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase
move.l    d0,a6
move.l	$26(a6),OldCop    ; save the old COP

;     POINT TO OUR BITPLANE

MOVE.L    #BITPLANE,d0
LEA    BPLPOINTERS,A1
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

move.l    #COPPERLIST,$dff080    ; Point our COP
move.w    d0,$dff088        ; Start the COP
move.w    #0,$dff1fc        ; Disable AGA
move.w    #$c00,$dff106        ; Disable AGA

bsr.w    GRID1

mouse:
btst    #6,$bfe001    ; left button?
bne.s    mouse

bsr.w    GRID2

mouse2:
btst    #2,$dff016    ; right button?
bne.s    Mouse2

bsr.w    GRID3

mouse3:
btst    #6,$bfe001    ; left button?
bne.s    mouse3

bsr.w    GRID4

mouse4:
btst    #2,$dff016    ; right button?
bne.s    Mouse4


move.l    OldCop(PC),$dff080    ; Point to the system cop
move.w    d0,$dff088        ; Start the old cop

move.l    4.w,a6
jsr    -$7e(a6)    ; Enable
move.l    gfxbase(PC),a1
jsr    -$19e(a6)    ; Close library
rts

;    Data

GfxName:
dc.b    ‘graphics.library’,0,0

GfxBase:
dc.l    0

OldCop:
dc.l    0



; this routine creates a chessboard with squares measuring 8 pixels on each side

GRID1:
LEA    BITPLANE,a0    ; Destination bitplane address

MOVEQ    #16-1,d0    ; 16 pairs of 8-pixel squares
; 16*2*8=256 complete screen fill
MakePair:
move.l    #(20*8)-1,d1	; 20 words to fill 1 line
; 8 lines to fill
FaiUNO:
move.w    #%1111111100000000,(a0)+ ; square length at 1 = 8 pixels
; square reset = 8 pixels
dbra    d1,FaiUNO         ; make 8 lines #.#.#.#.#.#.#.#.#.#

move.l    #(20*8)-1,d1    ; 20 words to fill 1 line
; 8 lines to fill
DoMORE:
move.w    #%0000000011111111,(a0)+ ; square length reset = 8
; square at 1 = 8 pixels
dbra    d1,DoMore         ; make 8 lines .#.#.#.#.#.#.#.#.#.

DBRA    d0,MakePairs         ; make 16 pairs of squares
; #.#.#.#.#.#.#.#.#.
rts                 ; .#.#.#.#.#.#.#.#.#.

; this routine creates a chessboard with squares measuring 4 pixels on each side

GRID2:
READ    BITPLANE,a0    ; Destination bitplane address

MOVEQ    #32-1,d0    ; 32 pairs of squares 4 pixels high
; 32*2*4=256 complete screen fill
MakePair2:
move.l    #(40*4)-1,d1    ; 40 bytes to fill 1 line
; 4 lines to fill
MakeONE2:
move.b	#%11110000,(a0)+     ; square length at 1 = 4 pixels
; square reset = 4 pixels
dbra    d1,FaiUNO2        ; make 4 lines #.#.#.#.#.#.#.#.#.#

move.l    #(40*4)-1,d1	; 40 bytes to fill 1 line
; 4 lines to fill
DoMORE2:
move.b    #%00001111,(a0)+     ; square length reset = 4 pixels
; square at 1 = 4 pixels
dbra    d1,DoMore2        ; draw 8 lines .#.#.#.#.#.#.#.#.#.

DBRA    d0,FaiCoppia2         ; make 32 pairs of squares
; #.#.#.#.#.#.#.#.#.#
rts                 ; .#.#.#.#.#.#.#.#.#.

; this routine creates a chessboard with squares measuring 16 pixels on each side

GRID3:
READ    BITPLANE,a0    ; Destination bitplane address

MOVEQ    #8-1,d0        ; 8 pairs of squares measuring 16 pixels high
; 8*2*16=256 complete screen fill
MakePair3:
move.l    #(10*16)-1,d1    ; 10 lingwords to fill 1 line
; 16 lines to fill
MakeONE3:
move.l	#%11111111111111110000000000000000,(a0)+ 
; square length at 1 = 16 pixels
; square reset = 16 pixels
dbra    d1,FaiUNO3        ; make 16 lines #.#.#.#.#.#.#.#.#.#

move.l    #(10*16)-1,d1    ; 10 lingwords to fill 1 line
; 16 lines to fill
DoMORE3:
move.l    #%00000000000000001111111111111111,(a0)+
; square length reset to 16
; square at 1 = 16 pixels
dbra    d1,DoMore3        ; make 8 lines .#.#.#.#.#.#.#.#.#.

DBRA    d0,DoPair3         ; make 8 pairs of squares
; #.#.#.#.#.#.#.#.#.
rts                 ; .#.#.#.#.#.#.#.#.

; ‘fantasy’ grid

GRID4:
LEA    BITPLANE,a0    ; Destination bitplane address

MOVEQ	#8-1,d0        ; 8 pairs of 16-pixel squares
; 8*2*16=256 complete screen fill
MakePairs4:
move.l    #(10*16)-1,d1    ; 10 lingwords to fill 1 line
; 16 lines to fill
MakeONE4:
move.l	#%11111000000000011111000000000000,(a0)+ 
; square length at 1 = 4 pixels
; square reset = 12 pixels
dbra    d1,FaiUNO4        ; make 16 lines #.#.#.#.#.#.#.#.#.#

move.l    #(10*16)-1,d1    ; 10 lingwords to fill 1 line
; 16 lines to fill
DoMORE4:
move.l    #%00000000000011111000000000011111,(a0)+
; square length reset = 12
; square at 1 = 4 pixels
dbra    d1,DoMore4        ; make 8 lines .#.#.#.#.#.#.#.#.#.

DBRA    d0,DoPair4         ; make 8 pairs of squares
; #.#.#.#.#.#.#.#.#.#
rts                 ; .#.#.#.#.#.#.#.#.

SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
dc.w	$12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w	$134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w	$13e,0

dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$0038    ; DdfStart
dc.w    $94,$00d0    ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod
; 5432109876543210
dc.w    $100,%0001001000000000	; 1 LOWRES bitplane 320x256

BPLPOINTERS:
dc.w $e0,0,$e2,0    ;first     bitplane

dc.w    $0180,$000    ; colour0 - BACKGROUND
dc.w    $0182,$19a    ; colour1 - DRAWING

dc.w    $FFFF,$FFFE    ; End of copperlist


SECTION    MIOPLANE,BSS_C

BITPLANE:
ds.b    40*256    ; one lowres 320x256 bitplane

end

If you need a geometric or repetitive background, you can create it with a
routine instead of drawing it, saving space. This is
just an example of what can be done. You can also repeat small
designs on the screen by copying them next to each other like bricks.
