
; Lesson 6l.s    FLASHING COLOUR USING A TABLE with routine
;        which, once the table is finished, reads it backwards


SECTION    CiriCop,CODE

Start:
move.l    4.w,a6        ; Execbase
jsr    -$78(a6)    ; Disable
lea    GfxName(PC),a1    ; Lib name
jsr    -$198(a6)    ; OpenLibrary
move.l    d0,GfxBase
move.l    d0,a6
move.l    $26(a6),OldCop    ; save the old COP

move.l    #COPPERLIST,$dff080    ; our COP
move.w    d0,$dff088        ; START COP
move.w    #0,$dff1fc        ; NO AGA!
move.w    #$c00,$dff106        ; NO AGA!

mouse:
cmpi.b    #$ff,$dff006    ; Line 255?
bne.s    mouse

btst    #2,$dff016    ; right button?
beq.s    wait

bsr.w    Flash    ; Flashes Color0 in copperlist

Wait:
cmpi.b    #$ff,$dff006    ; line 255?
beq.s    Wait

btst    #6,$bfe001    ; mouse pressed?
bne.s    mouse

move.l    OldCop(PC),$dff080	; Point to the system cop
move.w    d0,$dff088        ; start the old cop

move.l    4.w,a6
jsr    -$7e(a6)    ; Enable
move.l    gfxbase(PC),a1
jsr    -$19e(a6)    ; Closelibrary
rts

;    Data

GfxName:
dc.b    ‘graphics.library’,0,0

GfxBase:
dc.l    0

OldCop:
dc.l    0

;    Flashing routine that uses a TABLE of shades that are already
;    ready. The TABLE is nothing more than a series of words containing
;    the various RGB values that COLOR1 will have to assume in the various frames.
;    Note that the table is ‘read’ in this way: start by
;    copying the first word, then each time it is re-executed in the
;    following frames, the routine copies the second word, the third, the
;    fourth and so on, until it reaches the last value of the
;    table, at the label FINECOLORTAB, then it reverses the direction with
;    BCHG.B    #1,DIREZFLAG, and proceeds reading ‘backwards’ each time
;    until it returns to the first word, then it changes DIREZFLAG again
;    and resumes reading ‘forwards’.
;    NOTE: this routine is useful when the ‘increasing’ values in the
;    table, once they reach the ‘maximum’, decrease in the same way
;    as they increased: in this case, we would have had to write
;    a table of this type:
;
;    dc.w    0,1,2,3,4,5,6,7,8,9,10 ; progression to the maximum
;    dc.w    10,9,8,7,6,5,4,3,2,1,0 ; decrease to the minimum
;
;	But with this routine, only half of the TABLE can be written,
;    i.e. up to 10, the routine will “go back” once
;    the maximum has been reached: 9,8,7,6,5,4..., saving space in the
;    listing, and time if the values are written ‘by hand’.
;    If the table was not ‘mirrored’, i.e. of this type:
;
;    dc.b    0,2,3,5,6,7,8,9,10
;    dc.b    9,8,7,6,4,3,2,1,0
;
;    A routine would have been used that reads the entire table, from the first
;    value to the last, but instead of rereading backwards once
;    it reached the end, it would start over from the beginning.

Flashing:
BTST    #1,DIREZFLAG    ; we have to read forwards and backwards the
BEQ.S    GIUT2        ; words of the table??
SUT2:
SUBQ.L    #2,COLTABPOINT    ; Point to the previous word
MOVE.L    COLTABPOINT(PC),A0 ; address contained in long COLTABPOINT
; copied to a0
CMP.L    #COLORTAB,A0    ; Have we reached the first value of the TABLE?
BNE.S    NOBSTART2
BCHG.B    #1,DIREZFLAG    ; change direction, go forward!
NOBSTART2:
MOVE.W    (A0),COLORE0    ; copy the word from the table to the colour COP
rts

GIUT2:
ADDQ.L    #2,COLTABPOINT     ; Point to the next word
MOVE.L	COLTABPOINT(PC),A0 ; Address in COLTABPOINT copied to a0
CMP.L    #FINECOLORTAB-2,A0 ; Are we at the last word of the TAB?
BNE.S    NONCAMBDIREZ     ; If not, don't change anything
BCHG.B	#1,DIREZFLAG     ; change direction, go backwards!
NONCAMBDIREZ:
MOVE.W    (A0),COLORE0    ; copy the word from the table to the colour COP
rts

DIREZFLAG:            ; FLAG label used to indicate the
DC.W    0        ; reading direction.


COLTABPOINT:            ; This longword ‘POINTS’ to COLORTAB, i.e.
dc.l    COLORTAB-2    ; contains the address of COLORTAB. It will
; hold the address of the last word “read” in
; the table.

;    The table with the ‘precalculated’ values of the colour0 flashing

COLORTAB:
dc.w    $000,$000,$001,$011,$011,$011,$012,$012    ; start DARK
dc.w    $022,$022,$022,$023,$023
dc.w    $033,$033,$034
dc.w    $044,$044
dc.w    $045,$055,$055
dc.w    $056,$056,$066,$066,$066
dc.w	$167,$167,$177,$177,$177,$177,$177
dc.w	$278,$278,$278,$288,$288,$288,$288,$288
dc.w	$389,$389,$399,$399,$399,$399
dc.w    $39a,$39a,$3aa,$3aa,$3aa
dc.w    $3ab,$3bb,$3bb,$3bb
dc.w    $4bc,$4cc,$4cc,$4cc
dc.w    $4cd,$4cd,$4dd,$4dd,$4dd
dc.w    $5de,$5de,$5ee,$5ee,$5ee,$5ee
dc.w    $6ef,$6ff,$6ff,$7ff,$7ff,$8ff,$8ff,$9ff    ; ,maximum CLEAR
FINECOLORTAB:


SECTION    GRAPHIC,DATA_C

COPPERLIST:
dc.w    $120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
dc.w	$12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w	$134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w	$13e,0

dc.w    $8E,$2c81    ; DiwStrt
dc.w    $90,$2cc1    ; DiwStop
dc.w    $92,$38		; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,0        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod
; 5432109876543210
dc.w    $100,%0000001000000000    ; 0 bitplane LOWRES

dc.w    $180,$000    ; colour0

dc.w    $a007,$fffe    ; Wait line $a0
dc.w    $180
COLOUR0:
dc.w    $000    ; colour0

dc.w    $c007,$fffe    ;Wait line $c0
dc.w    $180,$000    ; colour0

dc.w    $FFFF,$FFFE    ; End of copperlist

end

This is one of the many variations of the routine that reads values from a
table. This routine can only be used in cases of ‘mirror’ tables,
 i.e. with ascending values equal to the descending ones, with the ‘maximum’
reached right in the middle.
The effect is in fact more symmetrical than that in Lesson6i.s

Try changing TABLE and everything will change: (Amiga+b+c+i)

COLORTAB:
dc.w $000,$100,$200,$300,$400,$500,$600,$700
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
FINECOLORTAB:

Try this TABLE too:

COLORTAB:
dc.w 0,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
dc.w $10f,$20f,$30f,$40f,$50f,$60f,$70f,$80f
dc.w $90f,$a0f,$b0f,$c0f,$d0f,$e0f,$f0f
dc.w $f1e,$f2d,$f3c,$f4b,$f5a,$f69,$f78,$f87
dc.w $f96,$fa5,$fb4,$fc3,$fd2,$fe1,$ff0
dc.w $ff0,$ff0,$fe0,$fd0,$fc0,$fb0,$fa0,$f90
dc.w $f80,$f70,$f60,$f50,$f40,$f30,$f20,$f10
dc.w $f00,$f00,$e01,$d02,$c03,$b04,$a05,$906
dc.w $807,$708,$609,$50a,$40b,$30c,$20d,$10e,15
dc.w $0f,$1f,$2f,$3f,$4f,$5f,$6f,$7f,$8f,$9f,$af
dc.w $bf,$cf,$df,$ef,$ff,$ff,$fe,$fd,$fc,$fb,$fa
dc.w $f9,$f8,$f7,$f6,$f5,$f4,$f3,$f2,$f1,$f0
dc.w $1f1,$2f2,$3f3,$4f4,$5f5,$6f6,$7f7,$8f8,$9f9
dc.w $afa,$bfb,$cfc,$dfd,$efe,$fff,$ffe,$ffd,$ffc,$ffb
dc.w $ffa,$ff9,$ff8,$ff7,$ff6,$ff5,$ff4,$ff3,$ff2,$ff1,$ff0
dc.w $fe0,$fd0,$fc0,$fb0,$fa0,$f90,$f80,$f70,$f60,$f50,$f40
dc.w $f30,$f20,$f10,$f00,$f00,$e00,$d00,$c00,$b00,$a00,$900
dc.w $800,$700,$600,$500,$400,$300,$200,$100,$0,0
FINECOLORTAB:
