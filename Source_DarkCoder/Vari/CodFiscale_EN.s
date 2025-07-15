;
; TAX CODE (C)1993 Daniele Paccaloni (DDT / HALF-BRAINS TEAM) !
; This is the fastest routine for calculating a person's tax code
;. The table of municipalities can be expanded as desired.
; Obviously, speed is not essential for calculating the
; tax code of a single person (as is currently the case in prompt mode)
; but, by adjusting everything for batch processing, it would be very useful to
; some government offices, given the shameful slowness with which
; many procedures are carried out :) If all programs were written in
; assembly language, there would be no need for Pentium processors... except for playing
; DOOM !!!
; Have fun finding your friends' tax codes, you'll amaze them
; by guessing all the digits... even the last one, the hardest one!!! :)
; This programme can be addictive... !@#?! Keep away from
; the reach of small children.
;                    Daniele

S:

Input:    move.l    $4.w,a6            ;Take the execbase address,
lea	DosName,a1        ;open the GFXlibrary {
jsr    -408(a6)        ;}.
tst.l    d0
beq.w    Error
move.l    d0,DosBase        ;Save the GFXbase pointer,
move.l    d0,a6


; SURNAME

bsr.w    ClrBuf

InputSurn:
jsr    -60(a6)        ; _LVOOutput
tst.l    d0
beq.w    Error
move.l    d0,OutHandler
move.l    d0,d1
move.l    #OutText1,d2
move.l	#EndOutText1-OutText1,d3
jsr    -48(a6)        ; _LVOWrite

jsr    -54(a6)        ; _LVOInput
tst.l    d0
beq.w    Error
move.l    d0,InHandler    ; d0=string length
move.l    d0,d1
move.l    #InputBuffer,d2
moveq    #80,d3
jsr    -42(a6)        ; _LVORead
tst.l    d0
beq.s    InputSurn
move.l    d0,d1            ;Copy string length

bsr.w    Uppercase
bsr.w    DeleteSpaces

move.w    d1,d0            ;Search for the first 3 consonants
subq.w    #1,d0
moveq    #3,d4
lea    InputBuffer(pc),a0
lea    CODE(pc),a4
ChkNxtC:
move.b	(a0)+,d3
lea    VocalsTab(pc),a2
moveq    #4,d2
ChkVocC:
cmp.b    (a2)+,d3
beq.s    IsVoc
dbra    d2,ChkVocC
cmp.b    #10,d3            ;Check if EOL
beq.s    GetVocs
move.b    d3,(a4)+
subq.w    #1,d4
beq.s    NAME
IsVoc:
dbra    d0,ChkNxtC

GetVocs:
move.w    d1,d0            ;Complete with vowels
subq.w    #1,d0
lea    InputBuffer(pc),a0
ChkNxtV:
move.b    (a0)+,d3
lea    VocalsTab(pc),a2
moveq    #4,d2
ChkVocV:
cmp.b    (a2)+,d3
beq.s    YeVoc
dbra    d2,ChkVocV
dbra    d0,ChkNxtV
bra.s    VDone

YeVoc:
move.b    d3,(a4)+
subq.w    #1,d4
beq.s    NAME
dbra    d0,ChkNxtV
VDone:
PatchX:
move.b    #‘X’,(a4)+    ;Inserts X if necessary
subq.w    #1,d4
bne.s    PatchX

;--------------------------------NAME

NAME:
bsr.w    ClrBuf
InputName:
jsr    -60(a6)		; _LVOOutput
tst.l    d0
beq.w    Error
move.l    d0,OutHandler
move.l    d0,d1
move.l    #OutText2,d2
move.l    #EndOutText2-OutText2,d3
jsr    -48(a6)		; _LVOWrite

jsr    -54(a6)        ; _LVOInput
tst.l    d0
beq.w    Error
move.l    d0,InHandler
move.l    d0,d1
move.l    #InputBuffer,d2
moveq    #80,d3
jsr    -42(a6)		; _LVORead
tst.l    d0        ; d0 = string length
beq.s    InputName
move.l    d0,d1            ;Copy string length

bsr.w    Uppercase
bsr.w    DeleteSpaces

; Copy the first 4 consonants of the name to ConsName:

move.l    d1,d0
subq.w    #1,d0
moveq    #4,d4            ;Check 4 consonants
lea    InputBuffer(pc),a0
lea    ConsName(pc),a5        ;Copy the first 4 consonants here
NxtLet:
move.b    (a0)+,d3
lea    VocalsTab(pc),a2
moveq    #4,d2
ChkCons:
cmp.b    (a2)+,d3
beq.s    NoCon
dbra    d2,ChkCons
cmp.b    #10,d3            ;Check if EOL
beq.s    NoCon
move.b    d3,(a5)+
subq.w    #1,d4
beq.s    FourCon
NoCon:
dbra    d0,NxtLet
lea    ConsNome(pc),a5        ;Address of first 4 consonants
moveq    #3,d0
sub.w    d4,d0            ;d0=number of consonants in name
bpl.s	CPyCon
subq.w    #1,d4
bra.s    NoCons
CpyCon:
move.b    (a5)+,(a4)+
dbra    d0,CpyCon
subq.w    #1,d4        ;Check if there are 3 consonants,
beq.s    DATA        ; if yes, go to encode the date...
NoCons:
move.w    d1,d0        ;Otherwise, complete with vowels:
subq.w    #1,d0
lea    InputBuffer(pc),a0
ChkNxtN:
move.b    (a0)+,d3
lea    VocalsTab(pc),a2
moveq    #4,d2
ChkVocN:
cmp.b    (a2)+,d3
beq.s    YeVoc2
dbra    d2,ChkVocN
dbra    d0,ChkNxtN
bra.s    VDoneN

YeVoc2:
move.b    d3,(a4)+
subq.w    #1,d4
beq.w	DATA
dbra    d0,ChkNxtN
VDoneN:
PatchXN:
move.b    #‘X’,(a4)+    ;Inserts X if necessary
subq.w    #1,d4
bne.s    PatchXN
bra.s    SkipHere

; Copy the 1',3',4' consonant into the CODE

FourCon:
lea    ConsNome(pc),a5        ; Address of the first 4 consonants
move.b    (a5),(a4)+        ; Copy the first one into the code
move.b    2(a5),(a4)+        ; Copy the third into the code
move.b    3(a5),(a4)+        ; Copy the fourth into the code
SkipHere:
;------------------------------------DATE OF BIRTH
DATE:
bsr.w    ClrBuf
InputData:
jsr    -60(a6)        ; _LVOOutput
tst.l    d0
beq.w    Error
move.l    d0,OutHandler
move.l    d0,d1
move.l    #OutText3,d2
move.l    #EndOutText3-OutText3,d3
jsr    -48(a6)        ; _LVOWrite

jsr    -54(a6)		; _LVOInput
tst.l    d0
beq.w    Error
move.l    d0,InHandler
move.l    d0,d1
move.l    #InputBuffer,d2
moveq	#80,d3
jsr    -42(a6)        ; _LVORead
tst.l    d0        ; d0 = string length
beq.s    InputData
cmp.l    #9,d0
bne.s    InputData
lea    InputBuffer(pc),a0
cmp.b    #‘/’,2(a0)
bne.s    InputData
cmp.b    #‘/’,5(a0)
bne.s    InputData
move.b    (a0),d7
bsr.w	VerifNum
bne.s    InputData
move.b    1(a0),d7
bsr.w    VerifNum
bne.s    InputData
move.b    3(a0),d7
bsr.w    VerifNum
bne.s    InputData
move.b    4(a0),d7
bsr.w	VerifNum
bne.w    InputData
move.b    6(a0),d7
bsr.w    VerifNum
bne.w    InputData
move.b    7(a0),d7
bsr.w    VerifNum
bne.w    InputData
move.l    d0,d1			;Copy string length

cmp.b    #‘2’,(a0)        ;Check if the day is > 29
bls.s    OkGg
cmp.b    #‘1’,1(a0)        ;If day > 31 then
bhi.w    InputData        ; re-input...

OkGg:
move.b    3(a0),d0
sub.b    #$30,d0
mulu.w    #10,d0            ;multiplication not optimised
add.b    4(a0),d0
sub.b    #$30,d0
cmp.b    #12,d0
bhi.w    InputData

move.b    6(a0),(a4)+        ;Copy the last two digits of the
move.b    7(a0),(a4)+        ; year into the code.

subq.w    #1,d0            ;Subtract 1 for deviation in tab
and.w    #00ff,d0        ;Clears upper part of d0
lea    MonthTab(pc),a2        ;a2 points to the table
move.b    (a2,d0.w),d0        ;takes the letter of the month in d0

move.b    d0,(a4)+        ;puts the letter of the month in the code

move.b    (a0),d6            ;d6.b = tens digit of the day
move.b    1(a0),d7        ;d7.b = units digit of the day
;------------------------------------GENDER
bsr.w    ClrBuf
InputGender:
jsr    -60(a6)        ; _LVOOutput
tst.l    d0
beq.w    Error
move.l    d0,OutHandler
move.l    d0,d1
move.l    #OutText4,d2
move.l    #EndOutText4-OutText4,d3
jsr    -48(a6)        ; _LVOWrite

jsr    -54(a6)        ; _LVOInput
tst.l    d0
beq.w    Error
move.l    d0,InHandler
move.l    d0,d1
move.l    #InputBuffer,d2
moveq    #80,d3
jsr    -42(a6)        ; _LVORead
tst.l    d0        ;d0 = string length
beq.s    InputGender
move.l    d0,d1            ;Copy string length

bsr.w    Uppercase

lea    InputBuffer(pc),a2
cmp.b    #‘M’,(a2)
beq.s    Male
cmp.b    #‘F’,(a2)
bne.s    InputGender

addq.b    #4,d6            ;If it's a female, add 4
; to the tens digit!

Male:move.b    d6,(a4)+		;Put the tens digit of the day
; in the code,
move.b    d7,(a4)+        ;Put the ones digit of the day
; in the code.

;------------------------------------COMUNE
bsr.w    ClrBuf
InputComune:
jsr    -60(a6)        ; _LVOOutput
tst.l    d0
beq.w    Error
move.l    d0,OutHandler
move.l    d0,d1
move.l    #OutText5,d2
move.l    #EndOutText5-OutText5,d3
jsr    -48(a6)		; _LVOWrite

jsr    -54(a6)        ; _LVOInput
tst.l    d0
beq.w    Error
move.l    d0,InHandler
move.l    d0,d1
move.l    #InputBuffer,d2
moveq    #80,d3
jsr    -42(a6)        ; _LVORead
tst.l    d0        ; d0 = string length
beq.s    InputComune
move.l    d0,d1            ;Copy string length

bsr.w    Upper case

lea    ComuniTab(pc),a3
SrchNxt:
lea    InputBuffer(pc),a2
move.l    d0,d1
subq.w    #1,d1
CmpCom:
move.b    (a2)+,d2
cmp.b    (a3)+,d2
bne.s    NoThiz
dbra    d1,CmpCom
bra.s    ComFound

NoThiz:
cmp.b    #10,(a3)+
bne.s    NoThiz
addq.w    #4,a3
cmp.l    #ComuniTabEnd,a3
bne.s    SrchNxt

;Not found; enter tax code

InputTaxCode:
jsr    -60(a6)        ; _LVOOutput
tst.l    d0
beq.w    Error
move.l    d0,OutHandler
move.l    d0,d1
move.l    #OutText6,d2
move.l    #EndOutText6-OutText6,d3
jsr    -48(a6)        ; _LVOWrite
jsr    -54(a6)        ; _LVOInput
tst.l    d0
beq.w    Error
move.l    d0,InHandler
move.l    d0,d1
move.l    #InputBuffer,d2
moveq    #80,d3
jsr    -42(a6)            ;d0 = string length
tst.l    d0
beq.s    InputCodeCom
cmp.b    #5,d0            ;Code length = 4 digits
bne.s    InputCodeCom
lea    InputBuffer(pc),a3
bclr.b	#5,(a3)            ;Uppercase code letter
ComFound:
move.b    (a3)+,(a4)+        ;Copy common code
move.b    (a3)+,(a4)+        ; to tax code
move.b    (a3)+,(a4)+
move.b    (a3)+,(a4)+

;------------------------------COMPUTES CONTROL CHARACTER

lea    CODE+1(pc),a0
moveq    #6,d5
moveq    #0,d7
ParLop:
move.b    (a0),d6
cmp.b    #‘9’,d6
bls.s    PNum
sub.b    #“A”-‘0’,d6
PNum:
sub.b    #‘0’,d6
ext.w    d6
add.w    d6,d7
addq.w    #2,a0
dbra    d5,ParLop

lea	CODE(pc),a0
lea    CtrlTab(pc),a2
moveq    #7,d5
DisLop:
moveq    #0,d6
move.b    (a0),d6
cmp.b    #‘9’,d6
bls.s    DNum
sub.b    #“A”-‘0’,d6
DNum:
sub.b    #‘0’,d6
lsl.w    #1,d6
add.w    (a2,d6.w),d7
addq    #2,a0
dbra    d5,DisLop

divu.w    #26,d7
swap    d7
add.b	#‘A’,d7
move.b	d7,(a4)

;------------------------------PRINT CODE

move.l    DosBase(pc),a6
jsr    -60(a6)        ; _LVOOutput - Print tax code
tst.l    d0
beq.s    Error
move.l    d0,OutHandler
move.l    d0,d1
move.l	#CODE,d2
moveq    #17,d3
jsr    -48(a6)        ; _LVOWrite

Error:
move.l    $4.w,a6            ;Execbase address,
move.l    DosBase(pc),a1
jsr    -414(a6)		;Closes the DOS library
rts



;---- UPPERCASE SOUBROUTINE --------
; Parameters:    d0.w = number of characters

Uppercase:
movem.l    d0/a0,-(sp)
subq.w    #1,d0
lea	InputBuffer(pc),a0
Caps:
cmp.b    #‘ ’,(a0)
bne.s    OkM
addq.w    #1,a0
bra.s    After

OkM:
bclr.b    #5,(a0)+
After:
dbra    d0,Caps
movem.l    (sp)+,d0/a0
rts


;---- SOUBROUTINE ELIMINASPAZII --------
; Parameters:    [none]

EliminaSpazii:
movem.l    d0/a0/a1/a2,-(sp)
lea    InputBuffer(pc),a0
HuntS:
move.b    (a0),d6
cmp.b    #10,d6
beq.s    EDone
cmp.b    #‘ ’,d6
beq.s    Argh
addq.w    #1,a0
bra.s    HuntS

Argh:
move.l    a0,a1
move.l    a0,a2
Yop:
addq.w    #1,a2
move.b    (a2),(a1)+
cmp.b    #10,(a2)
beq.s    SEOL
bra.s    Yop

SEOL:
addq.w    #1,a0
bra.s    HuntS
EDone:
movem.l    (sp)+,d0/a0/a1/a2
rts


;---- SOUBROUTINE CLEAR BUFFER --------
; Parameters:    none

ClrBuf:
lea    InputBuffer(pc),a0
moveq    #(80/4)-1,d0
ClrB:
clr.l    (a0)+
dbra    d0,ClrB
rts

;---- NUMBER CHECK SUBROUTINE --------
; Parameters:    d7.b = character to be checked
; Result:    Zflag set if equal

VerifNum:
cmp.b    #$30,d7
bhi.s    OKBnd1
rts

OkBnd1:
cmp.b    #$39,d7
bhi.s    ExitVM
moveq    #0,d7
ExitVM:
rts

;---------------------------------------------------
DosName:    dc.b    ‘dos.library’,0
DosBase:    dc.l    0

OutHandler:    dc.l    0
InHandler:    dc.l    0

OutText1:    dc.b    10,$9b,“33”,$6d,‘ TAX CODE ’,$9b,“31”,$6d,‘of D.Paccaloni & T.Labruzzo’
dc.b    10,10,‘SURNAME > ’
EndOutText1:
OutText2:    dc.b    10,‘NAME > ’
EndOutText2:
OutText3:    dc.b    10,‘DATE OF BIRTH (dd/mm/yy) > ’
EndOutText3:
OutText4:    dc.b    10,‘GENDER > ’
EndOutText4:
OutText5:    dc.b    10,‘PLACE OF BIRTH > ’
EndOutText5:
OutText6:    dc.b    10,‘Municipality code not found, please enter (4 digits) > ’
EndOutText6:

even

InputBuffer:    dcb.b    80,0

VocalsTab:    dc.b    ‘AEIOU’

MonthTab:    dc.b	‘ABCDEHLMPRST’

; Table of municipalities, to be expanded if necessary !
MunicipalitiesTab:    dc.b    ‘AREZZO’,10,“A390”
dc.b    ‘ASCOLI PICENO’,10,‘A462’
dc.b	‘ASTI’,10,‘A479’
dc.b	‘BARI’,10,‘A662’
dc.b	‘BERGAMO’,10,‘A794’
dc.b	‘BOLOGNA’,10,‘A944’
dc.b	“BRESCIA”,10,‘B157’
dc.b	‘CATANIA’,10,‘C351’
dc.b	‘CATANZARO’,10,‘C352’
dc.b	“COMO”,10,‘C933’
dc.b	‘FERRARA’,10,‘D548’
dc.b	‘IMPERIA’,10,‘E290’
dc.b	‘LA SPEZIA’,10,‘E463’
dc.b	‘LECCE’,10,‘E506’
dc.b	“MILANO”,10,‘F205’
dc.b	‘NAPOLI’,10,‘F839’
dc.b	‘PALERMO’,10,‘G273’
dc.b	‘PISA’,10,‘G702’
dc.b	“ROMA”,10,‘H501’
dc.b	‘SIRACUSA’,10,‘I754’
dc.b	‘TORINO’,10,‘L219’
dc.b	‘TRIESTE’,10,‘L424’
dc.b	‘TRENTO’,10,‘L378’
dc.b	“UDINE”,10,‘L483’
dc.b	‘VENEZIA’,10,‘L736’
dc.b	“VERONA”,10,‘L781’
ComuniTabEnd:

even
CtrlTab:	dc.w	1,0,5,7,9,13,15,17,19,21,2,4,18,20,11,3,6,8
dc.w    12,14,16,10,22,25,24,23

even
ConsName:    dcb.b    4,0

CODE:        dcb.b    16,0    ;16 characters
dc.b    10    ;EOL


end
