
; Lesson 8i2 - Simple timed equalizers with the music routine
;     - RIGHT KEY to change the speed of the bars

SECTION    MAINPROGRAM,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %100000101000000    ; only copper DMA
;         -----a-bcdefghij

;    a: Blitter Nasty
;    b: Bitplane DMA     (If not set, sprites will also disappear)
;    c: Copper DMA
;    d: Blitter DMA
;    e: Sprite DMA
;    f: Disk DMA
;    g-j: Audio 3-0 DMA

START:
MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #MyCopList,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

bsr.w    mt_init    ; Initialise the music routine

MainLoop:
MOVE.L    #$1ff00,d1    ; bits for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L	4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity1
Wait:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $130 (304)
BEQ.S    Wait

bsr.w    mt_music    ; play music

btst    #2,$dff016    ; right button pressed?
beq.s    Exit        ; if yes, exit

bsr.s    Equalizers    ; Simple equalizer routine

btst    #6,$bfe001    ; LMB pressed?
bne.s    MainLoop    ; If ‘NO’, restart, otherwise change music

lea    music(PC),a0        ; swap music
move.l    (a0),d0
move.l    4(a0),d1
move.l	4*2(a0),d2
move.l    4*3(a0),d3
move.l    d0,4(a0)
move.l    d1,4*2(a0)
move.l    d2,4*3(a0)
move.l    d3,(a0)

move.l    music(PC),mt_data    ; point to current music
bsr.w    mt_init            ; reset the music
WaitLeave:
btst    #6,$bfe001        ; LMB still pressed?
beq.s    WaitLeave        ; wait until released
bra.s    MainLoop

Exit:
bsr.w    mt_end    ; stop the music routine
rts

; Table with music... by rotating the addresses and always copying the
; first one, we can change them...

music:
dc.l    mt_data1,mt_data2,mt_data3,mt_data4


; Here is the equaliser routine, the audio analyser. The first thing to
; know is where to find information on the use of the 4 voices by
; the music routine. Usually, we check the variable of the
; replay routine, which can tell us if a voice is activated to play
; an instrument, usually ‘mt_chanXtemp’, where X can be 1, 2, 3 or 4.
; In this version, the value of mt_chanXtemp is also used for
; additional analysers.

;     ...._____
;     .:::ии____ \_______
;     .:и: / г\ \ \
;     .::: / \________\
;     .::: / (O \`-o---'/
;     ::\_ \ » /_, _/
;     и/ \ / \ \
;     / _____\____/ \ /
;     / / T \ (,_/ /
;     / /\_l___/\ /
;    / /_________\ __/
;    \ » ----- » /
;     \_______________/ xCz
;     T T
;     `--------'

Equalizers:
move.b    EqualSpeed(PC),d0 ; speed of ‘drop’ of the bars in d0
cmp.b    #$07,WaitEqu1+1    ; has the first bar dropped to zero?
bls.s    NonAbbass1    ; if so, do not lower it further!
; * bls means less than or equal to, it is better
; use it instead of beq because subtracting
; too large a number with d0 can
; cause it to go to $05 or $03!
sub.b    d0,WaitEqu1+1    ; otherwise lower the bar, composed of
sub.b    d0,WaitEqu1b+1	; two coloured lines and one black
sub.b    d0,WaitEqu1c+1
NonAbbass1:
tst.w    mt_chan1temp    ; voice 1 not “played”?
beq.s    anal2        ; if not, jump to Anal2
move.w    mt_chan1temp,COLOUR1
move.w mt_chan1temp,COLOUR1b
and.w #$f0,COLOUR1 ; select only blue component
ori.w #$330,COLOUR1	
; minimum $30!
and.w    #$0f,COLOUR1b    ; select only green component
ori.w    #$303,COLOUR1b    ; minimum $03!
clr.w    mt_chan1temp    ; reset to wait for next write
move.b    #$a7,WaitEqu1+1    ; BAR AT MAXIMUM!
move.b    #$a7,WaitEqu1b+1
move.b    #$a7,WaitEqu1c+1
anal2:
cmp.b    #$07,WaitEqu2+1    ; has the second bar dropped to zero?
bls.s    NonAbbass2	; if so, don't lower it any further!
sub.b    d0,WaitEqu2+1    ; otherwise lower the bar
sub.b    d0,WaitEqu2b+1
sub.b    d0,WaitEqu2c+1
Don'tLower2:
tst.w    mt_chan2temp    ; voice 2 not ‘played’?
beq.s    anal3        ; if not, jump to Anal3
move.w    mt_chan2temp,COLOUR2
move.w    mt_chan2temp,COLOUR2b
and.w    #$f0,COLOUR2    ; select only blue component
ori.w    #$330,COLOUR2    ; minimum $30!
and.w    #$0f,COLOUR2b    ; select only green component
ori.w    #$303,COLOUR2b    ; minimum $03!
clr.w    mt_chan2temp    ; reset to wait for next write
move.b    #$a7,WaitEqu2+1    ; BAR AT MAXIMUM!
move.b    #$a7,WaitEqu2b+1
move.b    #$a7,WaitEqu2c+1
anal3:
cmp.b    #$07,WaitEqu3+1    ; has the third bar dropped to zero?
bls.s    NonAbbass3    ; if so, do not lower it further!
sub.b    d0,WaitEqu3+1    ; otherwise, lower the bar
sub.b    d0,WaitEqu3b+1
sub.b    d0,WaitEqu3c+1
NonAbbass3:
tst.w    mt_chan3temp    ; voice 3 not ‘played’?
beq.s    anal4        ; if not, jump to Anal4
move.w    mt_chan3temp,COLOUR3
move.w    mt_chan3temp,COLOUR3b
and.w    #$f0,COLOUR3    ; select only blue component
ori.w    #$330,COLOUR3    ; minimum $30!
and.w    #$0f,COLOUR3b    ; select only green component
ori.w    #$303,COLOUR3b    ; minimum $03!
clr.w    mt_chan3temp    ; reset to wait for next write
move.b    #$a7,WaitEqu3+1    ; BAR AT MAXIMUM!
move.b    #$a7,WaitEqu3b+1
move.b    #$a7,WaitEqu3c+1
anal4:
cmp.b    #$07,WaitEqu4+1    ; has the fourth bar dropped to zero?
bls.s    NonAbbass4    ; if so, do not lower it further!
sub.b    d0,WaitEqu4+1	; otherwise lower the bar
sub.b    d0,WaitEqu4b+1
sub.b    d0,WaitEqu4c+1
NonAbbass4:
tst.w    mt_chan4temp    ; voice 4 not ‘played’?
beq.s    analizerend    ; if not, exit!
move.w    mt_chan4temp,COLOUR4
move.w    mt_chan4temp,COLOUR4b
and.w    #$f0,COLOUR4    ; select only blue component
ori.w    #$330,COLOUR4    ; minimum $30!
and.w    #$0f,COLOUR4b    ; select only green component
ori.w    #$303,COLOUR4b	; minimum $03!
clr.w     mt_chan4temp    ; reset to wait for the next write
move.b    #$a7,WaitEqu4+1    ; BAR AT MAXIMUM!
move.b    #$a7,WaitEqu4b+1
move.b    #$a7,WaitEqu4c+1
analizerend:
rts

EqualSpeed:
dc.b	4
even

*******************************************************************************
;	ROUTINE MUSICALE

include	‘music.s’
*******************************************************************************

Section	DatiChippy,data_C

MyCopList:
dc.w	$100,$200	; Bplcon0 - no bitplanes
dc.w    $180,$00e    ; colour0 blue

dc.w    $4807,$fffe
dc.w    $180,$ddd
dc.w    $4a07,$fffe
dc.w    $180,$777

dc.w    $5007,$fffe    ; wait start line
dc.w    $180
COLOUR1:
dc.w    $060
dc.w    $5507,$fffe    ; wait start line
dc.w    $180
COLOUR2:
dc.w    $060
dc.w    $5a07,$fffe    ; wait start of line
dc.w    $180
COLOUR3:
dc.w    $060
dc.w    $5f07,$fffe    ; wait start of line
dc.w    $180
COLOUR4:
dc.w    $060
dc.w    $6407,$fffe    ; wait start of line
dc.w	$180
COLOUR1b:
dc.w    $00e
dc.w    $6907,$fffe    ; wait start of line
dc.w    $180
COLOUR2b:
dc.w    $00e
dc.w    $6e07,$fffe    ; wait start of line
dc.w	$180
COLOUR3b:
dc.w    $00e
dc.w    $7307,$fffe    ; wait start of line
dc.w    $180
COLOUR4b:
dc.w    $00e
dc.w    $7807,$fffe    ; wait start of line
dc.w	$180,$777
dc.w    $7e07,$fffe
dc.w    $180,$333
dc.w    $8007,$fffe
dc.w    $180,$00e

dc.w    $ffdf,$fffe    ; wait for line $FF

;    wait&mode of the analyzer routine - use the horizontal position
;    of the waits to move the bars ‘forward’ and ‘backward’

dc.w    $1507,$fffe    ; wait start line
dc.w    $180,$00e    ; colour0 blue

dc.w    $1607,$fffe    ; wait start line
dc.w    $180,$f55    ; colour0 RED - colour of first BAR
WaitEqu1:
dc.w    $1617,$fffe    ; wait (will be modified as end of line, then
; it will decrease by 4 until it returns to $07)
dc.w    $180,$00e    ; colour0 blue
dc.w    $1707,$fffe    ; wait start line
dc.w    $180,$f55    ; colour0 RED (bar height 2 lines!)
WaitEqu1b:
dc.w    $1717,$fffe    ; wait (modified for bar length)
dc.w    $180,$00e    ; colour0 blue
dc.w    $1807,$fffe    ; wait start of line
dc.w    $180,$002    ; colour0 BLACK (‘shadow’ under the first bar)
WaitEqu1c:
dc.w    $1817,$fffe    ; wait (modified for bar length)
dc.w    $180,$00e    ; colour0 blue

; second bar

dc.w    $1b07,$fffe    ; wait start line
dc.w    $180,$a5f    ; colour0 PURPLE (second BAR)
WaitEqu2:
dc.w    $1b17,$fffe    ; wait (modified for bar length)
dc.w    $180,$00e    ; colour0 blue
dc.w    $1c07,$fffe    ; wait start line
dc.w    $180,$a5f    ; colour SECOND BAR (2 lines high!)
WaitEqu2b:
dc.w    $1c17,$fffe    ; wait (modified for bar length)
dc.w    $180,$00e    ; colour0 blue
dc.w    $1d07,$fffe    ; wait start line
dc.w    $180,$002    ; colour0 black (‘shadow’)
WaitEqu2c:
dc.w    $1d17,$fffe    ; wait (modified for bar length)
dc.w    $180,$00e    ; colour0 blue

; third bar

dc.w    $2007,$fffe    ; wait start line
dc.w    $180,$ff0    ; colour THIRD BAR
WaitEqu3:
dc.w    $2017,$fffe    ; wait (modified for bar length)
dc.w    $180,$00e    ; colour0 blue
dc.w    $2107,$fffe    ; wait start line
dc.w    $180,$ff0    ; colour THIRD BAR (2 lines high!)
WaitEqu3b:
dc.w    $2117,$fffe    ; wait (modified for bar length)
dc.w	$180,$00e    ; colour0 blue
dc.w    $2207,$fffe    ; wait start line
dc.w    $180,$002    ; colour0 black (‘shadow’)
WaitEqu3c:
dc.w    $2217,$fffe    ; wait (modified for bar length)
dc.w	$180,$00e    ; colour0 blue

; fourth bar

dc.w    $2507,$fffe    ; wait start line
dc.w    $180,$5F0    ; colour FOURTH BAR
WaitEqu4:
dc.w     $2517,$fffe    ; wait (modified for bar length)
dc.w    $180,$00e    ; colour0 blue
dc.w    $2607,$fffe    ; wait start line
dc.w    $180,$5F0    ; colour FOURTH BAR (2 lines high!)
WaitEqu4b:
dc.w     $2617,$fffe    ; wait (modified for bar length)
dc.w    $180,$00e    ; colour0 blue
dc.w    $2707,$fffe    ; wait start line
dc.w    $180,$002    ; colour0 black (‘shadow’)
WaitEqu4c:
dc.w     $2717,$fffe    ; wait (modified for bar length)
dc.w    $180,$00e    ; colour0 blue

DC.W    $FFFF,$FFFE    ; end copperlist


; music - you can choose one of the 4 tunes on the disc.
; here you can ‘understand’ the usefulness of mt_data used as a pointer.

mt_data:
dc.l    mt_data1


mt_data1:
incbin    ‘mod.fuck the bass’    ; by m.c.m/remedy 91
mt_data2:
incbin    ‘mod.yellowcandy’	; by sire/supplex
mt_data3:
incbin    ‘mod.fairlight’        ; by d-zire/silents 92 (only 2k long!)
mt_data4:
incbin    ‘mod.JamInexcess’    ; by raiser/ram jam

end
