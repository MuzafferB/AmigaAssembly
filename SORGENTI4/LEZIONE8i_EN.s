
; Lesson 8i - Simple timed equalizers with the music routine
;     - RIGHT KEY to change the speed of the bars

SECTION    MAINPROGRAM,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001010000000    ; only copper DMA
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
move.w    #0,$1fc(a5)		; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

bsr.w    mt_init    ; Initialise music routine

MainLoop:
MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the vertical position bits
CMPI.L    D2,D0        ; wait for line $130 (304)
BNE.S    Waity1

bsr.w    mt_music        ; play music

btst    #2,$dff016    ; right key pressed?
beq.s    GoFast
move.b    #2,EqualSpeed    ; drop speed = 2 pixels per frame
bra.s    GoSlow
GoFast:
move.b    #8,EqualSpeed    ; drop speed = 8 pixels per frame
GoSlow:

bsr.s    Equalizers        ; Simple equalizer routine

MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$13000,d2    ; line to wait for = $130, i.e. 304
Wait:
MOVE.L	4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $130 (304)
BEQ.S    Wait

btst    #6,$bfe001        ; LMB pressed?
bne.s    MainLoop        ; If ‘NO’, restart

bsr.w    mt_end    ; stop the music routine
rts


; Here is the equaliser routine, the audio analyser. The first thing to
; know is where to find information on the use of the 4 voices by
; the music routine. Usually, we check the variable of the
; replay routine, which can tell us if a voice is activated to play
; an instrument, usually ‘mt_chanXtemp’, where X can be 1, 2, 3 or 4.
; However, this system is not perfect, as we can only know
; when the use of one of the 4 voices ‘starts’, so if, for example,
; an instrument is played that continues to play for 10 seconds, the
; bar for that voice will lengthen at the first second, indicating the use
; of that voice at that moment, but then it will lower and remain quiet
; until that voice is used to play another instrument.
; If a voice is used for short sounds, such as drums, this
; fact is not noticeable, since at the moment of the BANG! the bar rises, and when it falls
; again, the sound is finished or about to finish. The problem becomes tragic
when a looping instrument is used, such as voices,
where the bar makes a single “jump” and then stays down during the loop.
This system is the same as the bars on the four tracks of the old
 soundtrackers and protrackers up to version 2. For equalizers of the type
; of protracker 3, which follow the ‘volume’ of the voices more faithfully, it is necessary to
; modify the musical routine itself, the same applies to equalizers
; that display the waveform. Just do a ‘tst.w mt_chanXtemp’, and it
you can proceed accordingly. In this case, bars made with
copper are moved using the horizontal position of the waits in the copperlist.
This way, we only use the background colour, $dff180, without bitplanes.
; Just wait for the start of the line, set the bar colour, and then
; put a wait that waits for a more advanced horizontal position, but
; in the same line, then reset the background colour. In this
; way, by acting on that wait, we ‘move’ the bar forward and backward, as
; we saw in Lesson3g.s and Lesson3h.s
; In practice, the routine does this: each frame lowers the bars until
; they are reset, so if there is no music, they remain reset. If
; the tst of mt_chanXtemp signals a sample played in that voice, it sets
; the maximum value, i.e. $a7, at the corresponding bar.

;         ,,,,,,,
;         ,)))))))))
;         | _______¡ ___
;         | _¬©)©) ( )))
;         l_ | ,\| / ¯/
;         __| l___¯|__ / /
;         /¯ l__ ¬ _! ¬\/ /
;        / /::`---':\ \ /
;        \ \:::...::¡\__/
;         \ \:::::::|
;         \ \::::::|
;         /),,)¯¯¯¯¯¯\
;         / ¯¯¯ /\ \ xCz
;		 \ \_\ \
;         \______// /
;         / ¬/ / /
;         (___/ /____/_
;         ¯\_____)


Equalizers:
move.b    EqualSpeed(PC),d0 ; speed of ‘drop’ of the bars in d0
cmp.b    #$07,WaitEqu1+1    ; has the first bar dropped to zero?
bls.s    NonAbbass1    ; if so, do not lower it further!
; * bls means less than or equal to, it is better
; to use it instead of beq because by subtracting
; from d0, a number that is too large can
; cause it to go to $05 or $03!
sub.b    d0,WaitEqu1+1    ; otherwise, lower the bar, consisting of
sub.b    d0,WaitEqu1b+1    ; two coloured lines and one black line
sub.b    d0,WaitEqu1c+1
NonAbbass1:
tst.w    mt_chan1temp    ; voice 1 not ‘played’?
beq.s    anal2        ; if not, jump to Anal2
clr.w    mt_chan1temp    ; reset to wait for the next write
move.b    #$a7,WaitEqu1+1	; BAR AT MAXIMUM!
move.b    #$a7,WaitEqu1b+1
move.b    #$a7,WaitEqu1c+1
anal2:
cmp.b    #$07,WaitEqu2+1    ; has the second bar dropped to zero?
bls.s    NonAbbass2    ; if so, do not lower it further!
sub.b    d0,WaitEqu2+1    ; otherwise, lower the bar
sub.b    d0,WaitEqu2b+1
sub.b    d0,WaitEqu2c+1
Don'tLower2:
tst.w    mt_chan2temp    ; voice 2 not ‘played’?
beq.s    anal3        ; if not, jump to Anal3
clr.w    mt_chan2temp    ; reset to wait for the next write
move.b    #$a7,WaitEqu2+1    ; BAR AT MAXIMUM!
move.b    #$a7,WaitEqu2b+1
move.b    #$a7,WaitEqu2c+1
anal3:
cmp.b    #$07,WaitEqu3+1    ; has the third bar dropped to zero?
bls.s    NonAbbass3    ; if so, do not lower it further!
sub.b    d0,WaitEqu3+1    ; otherwise lower the bar
sub.b    d0,WaitEqu3b+1
sub.b    d0,WaitEqu3c+1
NonAbbass3:
tst.w    mt_chan3temp    ; voice 3 not ‘played’?
beq.s    anal4        ; if not, jump to Anal4
clr.w    mt_chan3temp    ; reset to wait for the next write
move.b    #$a7,WaitEqu3+1    ; BAR AT MAXIMUM!
move.b    #$a7,WaitEqu3b+1
move.b    #$a7,WaitEqu3c+1
anal4:
cmp.b    #$07,WaitEqu4+1	; has the fourth bar dropped to zero?
bls.s    NonAbbass4    ; if so, do not lower it further!
sub.b    d0,WaitEqu4+1    ; otherwise, lower the bar
sub.b    d0,WaitEqu4b+1
sub.b    d0,WaitEqu4c+1
Don'tLower4:
tst.w    mt_chan4temp    ; voice 4 not ‘played’?
beq.s    analizerend    ; if not, exit!
clr.w     mt_chan4temp    ; reset to wait for the next write
move.b    #$a7,WaitEqu4+1    ; BAR AT MAXIMUM!
move.b	#$a7,WaitEqu4b+1
move.b	#$a7,WaitEqu4c+1
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
dc.w    $100,$200    ; Bplcon0 - no bitplanes
dc.w    $180,$00e    ; colour0 blue
dc.w    $ffdf,$fffe    ; wait for line $FF

;    wait&mode of the analyzer routine - use the horizontal position
;    of the waits to move the bars ‘forward’ and ‘backward’

dc.w    $1507,$fffe    ; wait start of line
dc.w    $180,$00e    ; colour0 blue

dc.w    $1607,$fffe    ; wait start line
dc.w    $180,$f55    ; colour0 RED - colour first BAR
WaitEqu1:
dc.w    $1617,$fffe    ; wait (will be modified as end of line, then
; will decrease by 4 until it returns to $07)
dc.w    $180,$00e    ; colour0 blue
dc.w    $1707,$fffe    ; wait start of line
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
dc.w	$1b17,$fffe    ; wait (modified for bar length)
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
dc.w    $180,$ff0	; THIRD BAR colour
WaitEqu3:
dc.w    $2017,$fffe    ; wait (modified for bar length)
dc.w    $180,$00e    ; colour0 blue
dc.w    $2107,$fffe    ; wait start line
dc.w    $180,$ff0	; THIRD BAR colour (2 lines high!)
WaitEqu3b:
dc.w	$2117,$fffe    ; wait (modified for bar length)
dc.w    $180,$00e    ; colour0 blue
dc.w    $2207,$fffe    ; wait start line
dc.w    $180,$002    ; colour0 black (‘shadow’)
WaitEqu3c:
dc.w    $2217,$fffe    ; wait (modified for bar length)
dc.w    $180,$00e    ; colour0 blue

; fourth bar

dc.w    $2507,$fffe    ; wait start line
dc.w    $180,$5F0    ; colour FOURTH BAR
WaitEqu4:
dc.w     $2517,$fffe    ; wait (modified for bar length)
dc.w    $180,$00e    ; colour0 blue
dc.w    $2607,$fffe    ; wait start line
dc.w    $180,$5F0	; colour FOURTH BAR (2 lines high!)
WaitEqu4b:
dc.w     $2617,$fffe    ; wait (modified for bar length)
dc.w    $180,$00e    ; colour0 blue
dc.w    $2707,$fffe    ; wait start line
dc.w    $180,$002    ; colour0 black (‘shadow’)
WaitEqu4c:
dc.w     $2717,$fffe    ; wait (modified for bar length)
dc.w    $180,$00e    ; colour0 blue

DC.W    $FFFF,$FFFE    ; end copperlist


; Music. Warning: the ‘music.s’ routine on disc 2 is not the same as
; the one on disc 1. The two changes are the removal of a bug that
; sometimes caused a crash when exiting the programme, and the fact that mt_data
; is a pointer to the music, and not THE music. This makes it easier to change
; the music.

; You can choose one of the four tunes on the disc.

mt_data:
dc.l    mt_data1

Mt_data1:
;    incbin    ‘mod.fairlight’        ; by d-zire/silents 92 (only 2k long!)
incbin    ‘mod.fuck the bass’    ; by m.c.m/remedy 91
;    incbin    ‘mod.yellowcandy’    ; by sire/supplex
;    incbin    ‘mod.JamInexcess’    ; by raiser/ram jam

end

You can use this source to listen to the four protracker tunes on this
disc. ‘mod.fairlight’ is one of the most ‘synthetic’ tunes possible,
in fact it is only 2374 bytes long, and when compressed with PowerPacker it becomes
952 bytes long!!!
