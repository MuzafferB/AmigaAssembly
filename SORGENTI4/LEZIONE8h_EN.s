
; Lesson 8h.s - Using the UniMuoviSprite routine to create a control panel
;        with gadgets

SECTION    CiriCop,CODE

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

*****************************************************************************
include	‘startup1.s’	; Salva Copperlist Etc.
*****************************************************************************

;5432109876543210
DMASET    EQU    %1000001110100000    ; only copper, bitplane, sprite DMA
;         -----a-bcdefghij

;    a: Blitter Nasty
;    b: Bitplane DMA
;	c: Copper DMA
;    d: Blitter DMA
;    e: Sprite DMA
;    f: Disk DMA
;    g-j: Audio 3-0 DMA

START:
bsr.w    PuntaFig1    ; Point to Fig.1
bsr.w    PuntaFigBase    ; Point to Fig.base

move.l	#BufferVuoto,d0    ; point to a zeroed space where it will be
LEA    BPLPOINTER2,A1    ; print the text
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)

MOVE.W    #DMASET,$96(a5)        ; DMACON - enable bitplane, copper
move.l    #COPPERLIST,$80(a5)    ; Point to our COP
move.w    d0,$88(a5)        ; Start the COP
move.w    #0,$1fc(a5)        ; Disable AGA
move.w    #$c00,$106(a5)        ; Disable AGA
move.w    #$11,$10c(a5)        ; Disable AGA

move.b    $dff00a,mouse_y        ; Give the mouse_y-x variables the
move.b    $dff00b,mouse_x        ; current value read from the mouse

;*****************************************************************************
; 				LOOP PRINCIPALE
;*****************************************************************************

Clear:
clr.b    Action        ; Reset variables
clr.b    KeyPressed
clr.b    ExitVar

Program:
****1
btst    #6,$bfe001    ; Left mouse button pressed? If not
bne.s    Contprog    ; continue the program, otherwise:
bsr.w    CheckAction    ; Check which key has been pressed
cmpi.b    #1,KeyPressed; If one of the ‘keys’ has been pressed, the
beq.s    Command        ; ‘KeyPressed’ variant is=1; let's
; check which key has been clicked!
Contprog:
bsr.w    MoveArrow    ; routine that reads/moves the mouse
bra.s    Program    ; End of program: let's start over!

;*****************************************************************************
;    ‘Command’ routine for interpreting the pressed key
;*****************************************************************************

; In the ‘ACTION’ variable we find a value, which was previously entered
; by the “CheckAction” routine. By checking its value
; we can know which key we have ‘clicked’ and execute
; its corresponding program.

Command:
cmpi.b    #$f,Action	; If action is ‘f’, we clicked on the key
beq.s    Green        ; GREEN
cmpi.b    #$e,Action    ; If action is ‘e’, we clicked on the key
beq.w    Red        ; GREEN
cmpi.b    #$d,Action    ; If action is ‘d’, we clicked on the button
beq.w    Yellow        ; YELLOW
cmpi.b    #7,Action    ; If action is “7”, we clicked on the button
beq.w    Music_On    ; Music_On
cmpi.b    #6,Action    ; If action is ‘6’, we clicked on the button
beq.w    Music_Off    ; Music_Off
cmpi.b    #5,Action    ; If action is ‘5’, we clicked on the button
beq.w    Exit        ; Quit
cmpi.b    #4,Action    ; If action is ‘4’, we clicked on the button
beq.w    PalNtsc        ; PalNtsc
cmpi.b    #3,Action    ; If action is ‘3’, we clicked on the button
beq.w    More        ; More
cmpi.b    #$2,Action	; If action is ‘2’, we clicked on the button
beq.w    Minus        ; Minus
;    cmpi.b    #1,Action    ; If action is ‘1’, we clicked on the button
bra.w    UpDown        ; UpDown (Actually, this is the only option left
; so we skip directly to

;*****************************************************************************

Green:
bsr.w    MoveArrow    ; routine that reads/moves the mouse
lea    Bar+6,a6    ; To return the multiplication
move.b    #$1,ColorB    ; We memorise which colour we are displaying
move.w    #$0030,(a6)    ; Change the COLOURS of the bar (the distance
move.w    #$0060,8(a6)    ; between one wait and the next is 8 bytes)
move.w    #$0090,8*2(a6)
move.w    #$00c0,8*3(a6)
move.w    #00f0,8*4(a6)
move.w    #00c0,8*5(a6)
move.w    #0090,8*6(a6)
move.w    #0060,8*7(a6)
move.w    #0030,8*8(a6)
bra.w    Clear        ; Let's start again!

;*****************************************************************************

Red:
bsr.w    MoveArrow    ; routine that reads/moves the mouse
lea    Bar+6,a6    ; To return the multiplication
move.b    #$2,ColorB    ; Let's memorise which colour we are displaying
move.w    #$0300,(a6)    ; Change the bar waits (the distance
move.w    #$0600,8(a6)    ; between one wait and the next is 8 bytes)
move.w    #$0900,8*2(a6)
move.w    #$0c00,8*3(a6)
move.w	#$0f00,8*4(a6)
move.w	#$0c00,8*5(a6)
move.w	#$0900,8*6(a6)
move.w	#$0600,8*7(a6)
move.w	#$0300,8*8(a6)
bra.w	Clear        ; Let's start again!

;*****************************************************************************

Yellow:
bsr.w    MoveArrow    ; routine that reads/moves the mouse
lea    Bar+6,a6    ; To return the multiplication
clr.b    ColorB		; Let's memorise which colour we are displaying
move.w    #$0310,(a6)    ; Let's change the bar waits (the distance
move.w    #$0640,8(a6)    ; between one wait and another is 8 bytes)
move.w	#$0970,8*2(a6)
move.w	#$0ca0,8*3(a6)
move.w	#$0fd0,8*4(a6)
move.w	#$0ca0,8*5(a6)
move.w	#$0970,8*6(a6)
move.w	#$0640,8*7(a6)
move.w	#$0310,8*8(a6)
bra.w	Clear		; Ritorniamo da capo!

;*****************************************************************************

PaNtFlag:
dc.w    0

PalNtsc:
bchg.b    #1,PaNtflag
btst.b    #1,PaNtflag
beq.s    VaiPal
move.w    #0,$1dc(a5)    ; BEAMCON0 (ECS+) NTSC video resolution
bra.w	Clear        ; Let's start over!
VaiPal
move.w    #$20,$1dc(a5)    ; BEAMCON0 (ECS+) PAL video resolution
bra.w    Clear


;*****************************************************************************

; Remember to ALWAYS put the ‘MoveArrow’ routine in places such
; as the following, which does not return to execute the main program
; until the left mouse button is pressed. If omitted,
; the mouse would not move until we release the mouse button!

More:
bsr.w    MoveArrow    ; routine that reads/moves the mouse
lea    bar,a6    ; Put the address of ‘BARRA’ in a5, the address of ‘BARRA’, thus
; avoiding rewriting it every time, and
; also making execution faster!
cmpi.b    #$84,8*9(a6)    ; Have we reached line $84?
beq.s	EndMore        ; If so, we are at the top, and we stop.
addq.b    #1,(a6)        ; Move the position of the bar by one pixel
addq.b    #1,8(a6)    ; alla volta
addq.b	#1,8*2(a6)
addq.b	#1,8*3(a6)
addq.b	#1,8*4(a6)
addq.b	#1,8*5(a6)
addq.b	#1,8*6(a6)
addq.b	#1,8*7(a6)
addq.b	#1,8*8(a6)
addq.b    #1,8*9(a6)

**2
btst.b    #6,$bfe001    ; Until the left button is released
beq.s    Piu        ; the bar continues to move, even though the
; mouse is no longer over the ‘+’ button:
; Try adding the following below the first line
; ‘bsr.w MoveArrow’ the label “PIU2”, and
; also change the line below ***2 to
; ‘beq.s Piu2’. Even if you move the 
; mouse, the arrow will not move!

bra.w    Clear        ; Let's start again!

; Have we reached the end? Then BLUE bar

FinePiu:
bsr.w    MoveArrow    ; routine that reads/moves the mouse
lea    Bar+6,a6	; Bar in coplist
move.w    #$0003,(a6)    ; Change the COLOURS of the bar to BLUE
move.w    #$0006,8(a6)
move.w    #$0009,8*2(a6)
move.w    #$000c,8*3(a6)
move.w	#$000f,8*4(a6)
move.w	#$000c,8*5(a6)
move.w	#$0009,8*6(a6)
move.w	#$0006,8*7(a6)
move.w	#$0003,8*8(a6)
btst.b    #6,$bfe001    ; Until the left button is released
beq.s    FinePiu        ; the bar continues to move, even though the
; mouse is no longer over the ‘+’ button‘
cmp.b    #1,ColorB    ; Check what colour the bar was before
; using the ColorB variable:
; If the value is ’1", then the bar is
; green:
beq.w    Green        ; Go to the GREEN label, thus returning the
; bar to its original colour
cmp.b    #2,ColorB    ; Here too, if the variable is
beq.w    Red        ; ‘2’, go to the RED label
bra.w	Yellow        ; If none of the previous conditions
; have been met, the bar is
; YELLOW, because there are only
; three possible colours: red, green or yellow!

;*****************************************************************************

Less:
bsr.w    Move arrow    ; The same applies as above, except that 
lea    bar,a6    ; add the value ‘1’ to ‘bar’,
cmpi.b    #$36.8*9(a6)    ; Have we reached the end?
beq.s    EndLess    ; if everything stops and colours the bar BLUE
subq.b    #1,(a6)        ; subtract, moving it in the opposite direction
subq.b	#1,8(a6)    ; opposite (upwards)
subq.b    #1,8*2(a6)
subq.b    #1,8*3(a6)
subq.b    #1,8*4(a6)
subq.b	#1,8*5(a6)
subq.b	#1,8*6(a6)
subq.b	#1,8*7(a6)
subq.b	#1,8*8(a6)
subq.b    #1,8*9(a6)
**3
btst.b    #6,$bfe001
beq.s    Meno
bra.w    Clear        ; Let's start again!

; Have we reached the top? Then blue bar!

FineMeno:
bsr.w    MoveArrow	; routine that reads/moves the mouse
lea    Bar+6,a6
move.w    #$0003,(a6)    ; colour BLUE
move.w    #$0006,8(a6)
move.w    #$0009,8*2(a6)
move.w	#$000c,8*3(a6)
move.w	#$000f,8*4(a6)
move.w	#$000c,8*5(a6)
move.w	#$0009,8*6(a6)
move.w	#$0006,8*7(a6)
move.w    #$0003,8*8(a6)
btst.b    #6,$bfe001
beq.s    EndLess
cmpi.b	#$1,ColorB    ; Check what colour the bar was
beq.w    Green
cmpi.b    #$2,ColorB
beq.w    Red
bra.w    Yellow

;*****************************************************************************

Music_On:
move.b    #1,MusicFlag    ; By giving the variable MusicFlag the value ‘1’,
; every time we test it, we will know 
; when the music has been activated.
move.l    a5,-(SP)    ; save a5 in the stack
bsr.w    mt_init        ; Jump to the routine that plays the music
move.l	(SP)+,a5    ; retrieve a5 from the stack

**4
;    bsr.w    MoveArrow    ; routine that reads/moves the mouse
bra.w    Clear        ; Let's start over!

;*****************************************************************************

Music_Off:
clr.b    MusicFlag    ; By giving the variable MusicFlag the value ‘0’,
; every time we test it, we will know 
; when the music has been turned off.
move.l    a5,-(SP)    ; save a5 in the stack
bsr.w    mt_end		; Jump to the routine that stops the music
move.l    (SP)+,a5    ; retrieve a5 from the stack
**5
;    bsr.w    MoveArrow    ; routine that reads/moves the mouse
bra.w    Clear        ; Let's start over!

;*****************************************************************************
;			Rirtono alla OldCop
;*****************************************************************************

Exit:                ; Let's exit the programme!!!
move.l    a5,-(SP)    ; save a5 in the stack
bsr.w    mt_end        ; Let's turn off the music!!!: If we pressed
; the ‘EXIT’ key while the music was
; playing, chaos ensues
move.l    (SP)+,a5    ; retrieve a5 from the stack
rts


*******************************************************************************
*				Vari BSR				 *
*******************************************************************************

PuntaFig1:
MOVE.L	#picture1,d0
moveq    #4-1,d1        ; 4 bitplane!
LEA    BPLPOINTERS,A1
POINTBPa:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L    #40*84,d0    ; The figure is 84 lines high, not 256!!
addq.w    #8,a1
dbra    d1,POINTBPa

;    Point all sprites to the null sprite to make sure
;    there are no problems.

MOVE.L    #SpriteNullo,d0        ; address of the sprite in d0
LEA    SpritePointers,a1    ; Pointers in copperlist
MOVEQ    #8-1,d1            ; all 8 sprites
NulLoop:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
addq.w    #8,a1
dbra    d1,NulLoop

; Point to the first sprite

MOVE.L    #MIOSPRITE0,d0
LEA    SpritePointers,a1
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
rts            ; Return to BSR

PuntaFigBase:    
MOVE.L    #picturebase,d0
LEA	BPLPOINTERSbase,A1
moveq    #0,d1        ; 1 bitplane!
POINTBPbasenew:
move.w    d0,6(a1)
swap    d0
move.w    d0,2(a1)
swap    d0
ADD.L    #40*105,d0	; The figure is 105 lines high, not 256!!
addq.w    #8,a1
dbra    d1,POINTBPbasenew
rts            ; Return

******************************************************************************
; This routine checks whether we have pressed a ‘button’/‘gadget’ or
; where there are no commands. If a “button” has been pressed, it assigns
; the value corresponding to the pressed ‘button’ to the Action variable.
******************************************************************************


; _,“| _.-”'``-...___..--“;)
; /_ \”. __..-“ , ,--...--”''
; ¶ .`--“”' ` /“
; `-”;' ; ; ;
; __...--“” ___...--_..“ .;.”
; (,__....----“”' (,..--“”
;||||||||///|||||||||||||||||||||||||||||||||||||||||||||||||||||

CheckAction:

; First check the Y positions

move.b    #$1,KeyPressed    ; Let's assume in advance that
; we have pressed one of the keys
; giving the variable ‘KeyPressed’
; the value ‘1’
cmpi.w	#$00fc,Sprite_y        ; Is the arrow under the position of the
; keys, i.e.
; Sprite_y is > 00fc, If yes:
bhi.s    rtnCheck        ; We're out!
cmpi.w    #00f1,Sprite_y        ; Is the arrow aligned with the line
; of ‘Change colour GREEN’?
;
bhi.w    Green_Effect        ; If yes: go to Green action
;
cmpi.w    #00fe,Sprite_y        ; Are we between 00f1 and 00fe? If yes:
bhi.s    rtnCheck        ; We're out!
cmpi.w    #$00e4,Sprite_y        ; Is the arrow aligned with the line
; of ‘Change colour RED’?
;
bhi.w    Effetto_Rosso		; If yes: go to Action red
;
cmpi.w    #$00e1,Sprite_y        ; Are we between 00e1 and 00d7? If yes:
bhi.s    rtnCheck        ; We're out!
cmpi.w    #$00d7,Sprite_y        ; Is the arrow aligned with the line
; of ‘Change colour to YELLOW’ line?
;
bhi.w    Effetto_Giallo        ; If yes: go to Action yellow
;
cmpi.w    #$00d0,Sprite_y        ; Are we between 00d7 and 00d0? If yes:
bhi.s    rtnCheck        ; We're out!

cmpi.w    #$00b0,Sprite_y        ; The arrow is between the ‘+’ and ‘-’ keys,
;                    ; ‘Pal-Ntsc’,‘Exit’...
bhi.s    KeyAction        ; If yes: go to KeyAction
;
rtnCheck:
clr.b    KeyPressed        ; Since no key has been pressed,
rts                ; we avoid the program wasting
; time by immediately re-reading 
; the mouse position using the
; variable ‘KeyPressed’

;*****************************************************************************
; Now that we know that Y is one of the ‘buttons’, let's check
; if X is the right one too!
;*****************************************************************************

Key_Action:
cmpi.w    #$0111,Sprite_x        ; Is the arrow beyond the
; ‘Music Off’ key? If so:
bhi.s    rtnCheck        ; We're out!
cmpi.w    #$00ea,Sprite_x        ; Is the arrow between the
‘Music Off’ button? If yes:
bhi.w    Effetto_Off_Music    ; Go to Effetto_Off_Music

cmpi.w    #$00dc,Sprite_x        ; Is the arrow between 00ea and 00dc? If yes:
bhi.s    rtnCheck        ; We're out!
cmpi.w    #$00b3,Sprite_x        ; The arrow is above the key
; ‘Music_On’? If yes:
bhi.w    Effect_On_Music    ; Go to Effect_On_Music
cmpi.w    #$00ab,Sprite_x        ; Is the arrow beyond the buttons
; ‘Pal/Ntsc’ and ‘Quit’?
bhi.s    rtnCheck        ; We're out!
cmpi.w    #0077,Sprite_x        ; Is the arrow between the
; ‘Pal/Ntsc,Quit’ buttons?
bhi.s    Which_Two2		; Let's see which of ‘Pal/Ntsc’ or ‘Quit’
cmpi.w    #$006c,Sprite_x        ; Is the arrow between 77 and 6c?
bhi.s    rtnCheck        ; We're out!
cmpi.w    #$005d,Sprite_x        ; The arrow is between the keys
; ‘+’ and ‘-’?
bhi.s    Which_Two1        ; Let's see which of ‘+’ or ‘-’
cmpi.w    #004f,Sprite_x        ; Is the arrow between 77 and 6c?
bhi.s    rtnCheck        ; We're out!
cmpi.w	#$003e,Sprite_x        ; The arrow is on the shit key:-><-!!
bhi.s    Effetto_GiuSu        ; Let's go to Effetto_GiuSu
bra.s    rtnCheck        ; If no action has occurred
; then let's go to rtnCheck

Quale_Due2:
cmpi.w    #$00c3,Sprite_y        ; The arrow is above the key
bhi.w    Effetto_Quit        ; ‘Quit’? If yes, go to Effetto_Quit
cmpi.w    #$00bc,Sprite_y		; Is the arrow between 00c3 and 00bc?
bhi.w    rtnCheck        ; We are between the two keys!
cmpi.w    #$00b0,Sprite_y		; Is the arrow between 00bc and 00b0?
bhi.w    Effetto_Pal        ; Go to Effetto_Pal

Quale_Due1:
cmpi.w    #$00c3,Sprite_y        ; Is the arrow above the key?
bhi.s    Effetto_Piu        ; ‘Piu’? If yes, go to Effect_More
cmpi.w    #$00bc,Sprite_y     ; Is the arrow between 00bc and 00c3?
bhi.w    rtnCheck        ; We are between the two buttons!
cmpi.w    #$00b0,Sprite_y		; Is the arrow between 00b0 and 00bc?
bhi.w    Effetto_Meno        ; Go to Effetto_Meno


;*****************************************************************************
; Now give the Action variable the value of the key that is pressed
;*****************************************************************************

Effetto_Verde:                ; If this condition is true
move.b    #$d,Azione        ; it means we are above the 
rts                ; GREEN bar! So we inform the 
; program that this ‘key’ has been pressed
; via the variable
; Azione, giving it the value ‘d’.
Red_Effect:
move.b    #$e,Action        ; Same as above, except that for the
rts                ; -Red- button we give the value ‘e’.

Yellow_Effect:
move.b    #$f,Action        ; Same as above, except that for the
rts                ; -Yellow- button we give the value ‘f’.

DownUp_Effect:
move.b    #$1,Action		; Same as above, except that for the
rts                ; -Down- key, we give the value ‘1’.

Effect_Up:
move.b    #$2,Action        ; Same as above, except that for the
rts                ; -Up- key, we give the value ‘2’.

Effect_Minus:
move.b    #$3,Action        ; Same as above, except that for the
rts                ; -Minus- key, we give the value ‘3’.

Effect_Pal:
move.b    #$4,Action        ; Same as above, except that for the
rts                ; -Pal- key, we give the value ‘4’.

Effect_Quit:
move.b    #$5,Action        ; Same as above, except that for the
rts                ; -Quit- key, we give the value ‘5’.

Effect_Off_Music
move.b    #$6,Action        ; Same as above, except that for the
rts                ; -Off_Misic- key, we give the value ‘6’.

Effect_On_Music
move.b    #$7,Action        ; Same as above, except that for the
rts				; -On_Music- we give the value ‘7’.

*************************************************************************
* Routine that reads the mouse position                *
* entering the coordinates in Mouse_x/Mouse_y - Sprite_x/Sprite_Y    *
*************************************************************************

ReadMouse:
move.b    $a(a5),d1    ; $dff00a - JOY0DAT high byte
move.b    d1,d0
sub.b    mouse_y(PC),d0
beq.s    no_vert
ext.w    d0
add.w    d0,sprite_y
no_vert:
move.b    d1,mouse_y
move.b    $b(a5),d1    ; $dff00a - JOY0DAT - low byte
move.b    d1,d0
sub.b	mouse_x(PC),d0
beq.s    no_oriz
ext.w    d0
add.w    d0,sprite_x
no_oriz:
move.b    d1,mouse_x
cmpi.w    #0021,sprite_x        ; Minimum x position? (left edge)
bpl.b    s1            ; if not yet, no need to lock.
move.w    #$0021,sprite_x        ; Otherwise, lock it at
; position $21.. NOT BEYOND!!
s1:
cmpi.w    #$0004,sprite_y        ; Minimum y position? (top of screen)
bpl.b    s2            ; if not yet, do not lock
move.w    #$0004,sprite_y        ; otherwise, lock the sprite to the
; upper left edge
s2:
cmpi.w    #$011d,sprite_x        ; Maximum x position? (right edge)
ble.b    s3            ; if not yet, no need to lock
move.w	#$011d,sprite_x        ; Otherwise, lock it at $11d
s3:
cmpi.w    #$00ff,sprite_y        ; Maximum y position? (bottom of screen)
ble.b    s4            ; if not yet, do not block
move.w    #00ff,sprite_y        ; Otherwise block at $ff
s4:
rts

*********************************************************
*        Routine that moves sprite0        *
*********************************************************
;    a1 = Sprite address
;    d0 = Vertical position Y of the sprite on the screen (0-255)
;    d1 = Horizontal position X of the sprite on the screen (0-320)
;    d2 = Height of the sprite

UniMoveSprite:
ADD.W    #$2c,d0
MOVE.b    d0,(a1)
btst.l    #8,d0
beq.s    NonVSTARTSET
bset.b    #2,3(a1)
bra.s    ToVSTOP
NonVSTARTSET:
bclr.b    #2,3(a1)
ToVSTOP:
ADD.w    D2,D0
move.b    d0,2(a1)
btst.l    #8,d0
beq.s    NonVSTOPSET
bset.b    #1,3(a1)
bra.b    VstopFIN
NonVSTOPSET:
bclr.b	#1,3(a1)
VstopFIN:
add.w    #128,D1
btst    #0,D1
beq.s    BitBassoZERO
bset    #0,3(a1)
bra.s    PlaceCoords
BitBassoZERO:
bclr    #0,3(a1)
PlaceCoords:
lsr.w    #1,D1
move.b    D1,1(a1)
rts

*******************************************************************************
*        Timing and sprite update LOOP         *
*******************************************************************************

MoveArrow:

; This is a timing routine because it uses the electronic brush as a reference
; at 50Hz (unless you are using the NTSC system
; (60Hz!) ). In fact, the brush has the same speed on all computers
; , both on the old A500 and on the A4000.

MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #$0fe00,d2    ; line to wait for = $fe, i.e. 254
Waity1:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $fe (254)
BNE.S    Waity1


tst.b    MusicFlag    ; If MusicFlag is ‘0’, then the music is not
beq.w    NoMusic2        ; turned on, so we skip the 
; following
line move.l    a5,-(SP)    ; save a5 in the stack
bsr.w    mt_music	; Play music if the
; ‘On_Music’
move.l    (SP)+,a5    ; retrieve a5 from the stack

NoMusic2:
bsr.w    LeggiMouse    ; Jump to the routine that reads the position of the
; mouse
move.w    sprite_y(pc),d0	; Prepare the y coordinates
move.w    sprite_x(pc),d1    ; Prepare the x coordinates
lea    miosprite0,a1	; select the sprite to move
moveq    #13,d2        ; Prepare the length of the sprite
bsr.w    UniMuoviSprite    ; Jump to the routine that moves the sprite
bsr.w    PrintCarattere    ; Write the text

MOVE.L    #$1ff00,d1    ; bit for selection via AND
MOVE.L    #0fe00,d2    ; line to wait for = $0fe, i.e. 254
Wait:
MOVE.L    4(A5),D0    ; VPOSR and VHPOSR - $dff004/$dff006
ANDI.L    D1,D0        ; Select only the bits of the vertical position
CMPI.L    D2,D0        ; wait for line $0fe (254)
BEQ.S    Wait

rts

;***************************************************************************
; ‘Special’ effect of closing and opening with DIWSTART/STOP
;***************************************************************************


GiuSu:
bsr.w    CloseScreen    ; Jump to the routine that closes the screen
bsr.w    OpenScreen    ; Jump to the routine that opens the screen
bra.w    Clear        ; Return to the beginning!

;*****************************************************************************

ScreenClose:
bsr.w    MoveArrow    ; wait for 1 FRAME cycle to pass!!
ADDQ.B    #1,DiwYStart    ; Lower the upper screen by one pixel
SUBQ.B    #1,DIWySTOP    ; Raise the lower screen by one pixel
CMPI.b    #$ad,DiwYStart    ; If we have reached the desired position,
beq.s    Finito3        ; then exit, otherwise reset the
bra.s    ScreenClose    ; pixel
Finito3:
rts

ScreenOpen:
bsr.w    MoveArrow    ; instead of increasing it, we decrease it
; that is, we invert it:
; addq #1,DiwyStart
SUBQ.B    #5,DiwYStart    ; subq #1,DiwyStop
ADDQ.B    #5,DIWySTOP    ; respectively with
CMPI.B    #$2c,DiwYStop    ; subq #5,DiwyStart
beq.w    Finito4        ; addq #5,DiwyStop
bra.s    ScreenOpen
Finito4:
rts


*******************************************************************************
*                Data                     *
*******************************************************************************
Action:
dc.l    0
KeyPressed:
dc.l    0
ExitVar
dc.l    0
ColorB:
dc.b    2
even

MusicFlag:
dc.w    0

SPRITE_Y:    dc.w    $a0    ; here the Y of the sprite is stored
; By changing this value we can change Y
; the initial position of the mouse 
SPRITE_X:    dc.w    0    ; the X of the sprite is stored here
; By changing this value, we can change X
; the initial position of the mouse
MOUSE_Y:    dc.b    0    ; the Y of the mouse is stored here
MOUSE_X:    dc.b    0    ; the X of the mouse is stored here

*****************************************************************************
;			Routine di Print
*****************************************************************************

PRINTcharacter:
MOVE.L    PointTEXT(PC),A0 ; Address of the text to be printed in a0
MOVEQ    #0,D2        ; Clear d2
MOVE.B    (A0)+,D2    ; Next character in d2
CMP.B	#$ff,d2        ; End of text signal? ($FF)
beq.s    EndText    ; If yes, exit without printing
TST.B    d2        ; End of line signal? ($00)
bne.s    NotEndLine    ; If no, do not go to the next line

ADD.L    #40*7,PuntaBITPLANE    ; GO TO NEW LINE
ADDQ.L    #1,PuntaTesto        ; first character of the next line
; (skip ZERO)
move.b    (a0)+,d2        ; first character of the next line
; (skip ZERO)

NonFineRiga:
SUB.B    #$20,D2        ; SUBTRACT 32 FROM THE ASCII VALUE OF THE CHARACTER, IN
; ORDER TO TRANSFORM, FOR EXAMPLE, THE
; OF THE SPACE (which is $20) IN $00, THAT OF THE
; ASTERISK ($21) IN $01...
LSL.W	#3,D2        ; MULTIPLY THE PREVIOUS NUMBER BY 8,
; since the characters are 8 pixels high
MOVE.L    D2,A2
ADD.L    #FONT,A2    ; FIND THE DESIRED CHARACTER IN THE FONT...

MOVE.L    PuntaBITPLANE(PC),A3 ; Address of the destination bitplane in a3

; PRINT THE CHARACTER LINE BY LINE
MOVE.B    (A2)+,(A3)    ; print LINE 1 of the character
MOVE.B	(A2)+,40(A3)    ; print LINE 2 ‘ ’
MOVE.B    (A2)+,40*2(A3)    ; print LINE 3 ‘ ’
MOVE.B    (A2)+,40*3(A3)    ; print LINE 4 ‘ ’
MOVE.B    (A2)+,40*4(A3)    ; print LINE 5 ‘ ’
MOVE.B    (A2)+,40*5(A3)    ; print LINE 6 ‘ ’
MOVE.B    (A2)+,40*6(A3)	; print LINE 7 ‘ ’
MOVE.B    (A2)+,40*7(A3)    ; print LINE 8 ‘ ’

ADDQ.L    #1,PuntaBitplane ; advance 8 bits (NEXT CHARACTER)
ADDQ.L    #1,PuntaTesto    ; next character to print

EndText:
RTS


PuntaTesto:
dc.l	TEXT

BitplanePointer:
dc.l    BufferEmpty+40*3

;    $00 for ‘end of line’ - $FF for ‘end of text’

; number of characters per line: 40
TEXT:	 ;         1111111111222222222233333333334
; 1234567890123456789012345678901234567890
dc.b    “ ”,0 ; 1
dc.b    ' Use the mouse to move the ',0 ; 2
dc.b	“ ”,0 ; 3
dc.b    “ bar, change its colour, ”,0 ; 4
dc.b    “ ”,0 ; 5
dc.b    “ play music or ‘close’ ”,0 ; 6
dc.b    “ ”,0 ; 7
dc.b    “ the screen with DIWSTART/STOP ”,$FF ; 12

EVEN

;    The 8x8 character FONT copied to CHIP by the CPU and not by the blitter,
;    so it can also be in fast RAM. In fact, that would be better!

FONT:
incbin    ‘assembler2:sorgenti4/nice.fnt’

*******************************************************************************
*			ROUTINE MUSICALE
*******************************************************************************

include	‘music.s’

*******************************************************************************
;			MEGACOPPERLISTONA GALATTICA (quasi...)
*******************************************************************************


SECTION    GRAPHIC,DATA_C


COPPERLIST:
SpritePointers:
dc.w	$120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
dc.w	$12a,0,$12c,0,$12e,0,$130,0,$132,0
dc.w	$134,0,$136,0,$138,0,$13a,0,$13c,0
dc.w	$13e,0

dc.w	$8E	; DiwStrt
DiwYStart:
dc.b    $30
DIWXSTART:
dc.b    $81
dc.w    $90    ; DiwStop
DIWYSTOP:
dc.b    $2c
DIWXSTOP:
dc.b    $c1
dc.w    $92,$38        ; DdfStart
dc.w    $94,$d0        ; DdfStop
dc.w    $102,0        ; BplCon1
dc.w    $104,$24        ; BplCon2
dc.w    $108,0        ; Bpl1Mod
dc.w    $10a,0        ; Bpl2Mod

; 5432109876543210
dc.w    $100,%0100001000000000    ; BPLCON0 - 4 low-resolution planes (16 colours)

; Bitplane pointers

BPLPOINTERS:
dc.w $e0,0,$e2,0    ;first     bitplane
dc.w $e4,0,$e6,0	;second bitplane
dc.w $e8,0,$ea,0    ;third     bitplane
dc.w $ec,0,$ee,0    ;fourth     bitplane

; the first 16 colours are for the LOGO

dc.w $180,$000,$182,$fff,$184,$200,$186,$310
dc.w $188,$410,$18a,$620,$18c,$841,$18e,$a73
dc.w $190,$b95,$192,$db6,$194,$dc7,$196,$111
dc.w $198,$222,$19a,$334,$19c,$99b,$19e,$446


dc.w	$1A2,$fff    ; colour17 Colour
dc.w    $1A4,$fa6    ; colour18 of
dc.w    $1A6,$000    ; colour19 mouse

BAR:
dc.w    $5c07,$FFFE    ; appearance of line $50
dc.w	$180,$300    ; start red bar: red at 3
dc.w    $5d07,$FFFE    ; next line
dc.w    $180,$600    ; red at 6
dc.w    $5e07,$FFFE
dc.w    $180,$900    ; red at 9
dc.w	$5f07,$FFFE
dc.w    $180,$c00    ; red at 12
dc.w    $6007,$FFFE
dc.w    $180,$f00    ; red at 15 (maximum)
dc.w    $6107,$FFFE
dc.w    $180,$c00    ; red at 12
dc.w    $6207,$FFFE
dc.w    $180,$900    ; red at 9
dc.w    $6307,$FFFE
dc.w    $180,$600    ; red at 6
dc.w    $6407,$FFFE
dc.w    $180,$300    ; red at 3
dc.w    $6507,$FFFE
dc.w    $180,$000    ; colour BLACK


; red bar below the logo

dc.w    $8407,$fffe    ; end of logo

BPLPOINTER2:
dc.w $e0,$0000,$e2,$0000    ;first     bitplane

dc.w    $100,$1200    ; 1 bitplane (reset)

dc.w    $8507,$FFFE    ; next line
dc.w    $180,$606	; purple
dc.w    $8607,$FFFE
dc.w    $180,$909    ; purple
dc.w    $8707,$FFFE
dc.w    $180,$c0c    ; purple
dc.w    $8807,$FFFE
dc.w    $180,$f0f    ; purple (maximum)
dc.w    $8907,$FFFE
dc.w    $180,$c0c    ; purple
dc.w	$8a07,$FFFE
dc.w    $180,$909    ; purple
dc.w    $8b07,$FFFE
dc.w    $180,$606    ; purple
dc.w    $8c07,$FFFE
dc.w    $180,$303    ; purple
dc.w    $8d07,$FFFE
dc.w    $180,$000    ; colour BLACK

dc.w    $182,$fe3    ; Text colour

; central bar

dc.w    $9007,$FFFE    ; next line

dc.w    $180,$011    ; light blue at 11
dc.w    $9507,$FFFE
dc.w    $180,$022    ; light blue at 22
dc.w    $9a07,$FFFE
dc.w    $180,$033    ; light blue at 33
dc.w    $9f07,$FFFE
dc.w    $180,$055    ; light blue at 55
dc.w    $a407,$FFFE
dc.w    $180,$077    ; celestino at 77
dc.w    $a907,$FFFE
dc.w    $180,$099    ; celestino at 99
dc.w    $ae07,$FFFE
dc.w    $180,$077    ; celestino at 77
dc.w    $b307,$FFFE
dc.w    $180,$055    ; light blue at 55
dc.w    $b807,$FFFE
dc.w    $180,$033    ; light blue at 33
dc.w    $bd07,$FFFE
dc.w    $180,$022    ; light blue at 22
dc.w    $c207,$FFFE
dc.w    $180,$011    ; light blue at 11

*****Basic figure:

dc.w    $c607,$FFFE    ; Wait for line c6
dc.w    $180,$000    ; BLACK colour

; 5432109876543210
dc.w    $100,%0001001000000000    ; 1 bitplane always LoRes

BPLPOINTERSbase:
dc.w $e0,$0000,$e2,$0000
CopBase:
dc.w $0180,$0000,$0182,$0877

; red bar above the panel

dc.w    $ca07,$FFFE    ; following line
dc.w    $180,$606    ; red
dc.w    $cb07,$FFFE
dc.w    $180,$909    ; red
dc.w    $cc07,$FFFE
dc.w    $180,$c0c    ; red
dc.w	$cd07,$FFFE
dc.w    $180,$f0f    ; red (maximum)
dc.w    $ce07,$FFFE
dc.w    $180,$c0c    ; red
dc.w	$cf07,$FFFE
dc.w    $180,$909    ; red
dc.w    $d007,$FFFE
dc.w    $180,$606    ; red
dc.w    $d107,$FFFE
dc.w    $180,$303    ; red
dc.w    $d207,$FFFE
dc.w    $180,$000    ; BLACK colour

dc.w    $ca07,$FFFE    ; WAIT - Wait for line $ca
dc.w    $180,$001    ; COLOUR0 - very dark blue
dc.w    $cc07,$FFFE    ; WAIT - line 74 ($4a)
dc.w    $180,$002    ; slightly more intense blue
dc.w    $ce07,$FFFE    ; line 75 ($4b)
dc.w    $180,$003    ; blue at 3
dc.w    $d007,$FFFE	; next line
dc.w    $180,$004    ; blue at 4
dc.w    $d207,$FFFE    ; next line
dc.w    $180,$005    ; blue at 5
dc.w    $d407,$FFFE    ; next line
dc.w    $180,$006    ; blue at 6
dc.w    $d607,$FFFE    ; jump 2 lines: from $4e to $50, i.e. from 78 to 80
dc.w    $180,$007    ; blue at 7
dc.w    $d807,$FFFE    ; jump 2 lines
dc.w    $180,$008    ; blue at 8
dc.w    $da07,$FFFE    ; jump 3 lines
dc.w    $180,$009    ; blue at 9
dc.w    $e007,$FFFE    ; jump 3 lines
dc.w    $180,$00a    ; blue at 10
dc.w    $e507,$FFFE	; jump 3 lines
dc.w    $180,$00b    ; blue at 11
dc.w    $ea07,$FFFE    ; jump 3 lines
dc.w    $180,$00c    ; blue at 12
dc.w    $f007,$FFFE	; jump 4 lines
dc.w    $180,$00d    ; blue at 13
dc.w    $f507,$FFFE    ; jump 5 lines
dc.w    $180,$00e    ; blue at 14
dc.w    $fa07,$FFFE	; jump 6 lines
dc.w    $180,$00f    ; blue at 15

dc.w    $ffdf,$FFFE    ; wait for line $ff

dc.w    $0207,$FFFE    ; aspect
dc.w    $182,$0f0    ; colour 1 green

dc.w    $0f07,$FFFE    ; wait
dc.w    $182,$f22    ; colour 1 red

dc.w    $1c07,$FFFE    ; wait
dc.w    $182,$ff0    ; colour 1 yellow

dc.w    $2907,$FFFE    ; appearance
dc.w    $182,$877    ; colour 1 grey

dc.w    $FFFF,$FFFE    ; End of copperlist

*******************************************************************************
*                Sprite                     *
*******************************************************************************
; As always, graphics should ONLY be loaded into CHIP like the Copperlist!

MIOSPRITE0:
VSTART0:
dc.b $50
HSTART0:
dc.b $45
VSTOP0:
dc.b $5d
VHBITS0:
dc.b $00
dc.w	%0110000000000000,%1000000000000000
dc.w	%0001100000000000,%1110000000000000
dc.w	%1000011000000000,%1111100000000000
dc.w	%1000000110000000,%1111111000000000
dc.w	%0100000000000000,%0111111110000000
dc.w	%0100000000000000,%0111111000000000
dc.w	%0010000100000000,%0011111000000000
dc.w	%0010010010000000,%0011111100000000
dc.w	%0001001001000000,%0001101110000000
dc.w	%0001000100100000,%0001100111000000
dc.w	%0000000010000000,%0000000011100000
dc.w	%0000000000000000,%0000000000000000
dc.w	%0000000000000000,%0000000000000000
dc.w	0,0


SpriteNullo:            ; Null sprite to point to in copperlist
dc.l    0,0,0,0        ; in any unused pointers

PICTUREbase:
incbin    ‘base320*105*1.raw’

; Drawing 320 pixels wide, 84 pixels high, with 4 bitplanes (16 colours).

PICTURE1:
incbin    ‘logo320*84*16c.raw’


; Music. Warning: the ‘music.s’ routine on disc 2 is not the same as
; the one on disc 1.
 The two changes are the removal of a bug that sometimes caused a crash when exiting the programme, and the fact that in mt_data
; it is a pointer to the music, and not THE music. This makes it easier to change
; the music.

mt_data:
dc.l    mt_data1

mt_data1:
incbin    ‘mod.JamInExcess’

Section    MiniBitplane,bss_c

;    The text is printed in this buffer

BufferVuoto:
ds.b    40*68

end            ; The computer does not read beyond END!
; Now we can write anything without
; SEMICOLONS or ASTERISKS


If we want a different video effect for each ‘key pressed’, we need to know
if the left key is pressed and, if so, the position of the
mouse sprite. In short, we need to know which key has been pressed 
to perform a different video effect:

As soon as we start the programme, we find a control: “Left key pressed?”,
if the key has not been pressed, we continue with the programme, updating
the position of the mouse, moving the arrow across the screen, if, on the other hand, it has been
pressed, we jump to a routine that compares the position of:
- Sprite_x
- Sprite_y
with the coordinates where our keys are located!

**************************** Trick of the trade *************************

But how do we know the X and Y coordinates of our “buttons”? Don't worry,
you don't have to do billions of tests or calculations by eye! Since ASMONE has
a built-in L.M. monitor, we can do it this way: draw the
control panel you want, with your buttons; once you have pointed
and displayed everything with the mouse routine, it's time to
find out which coordinates correspond to the buttons.

If you want to check the position of each button, just put this simple loop at the beginning of the
program (instead of ****1):

Wait:
bsr.w    ReadMouse
move.w    sprite_y(pc),d0
move.w    sprite_x(pc),d1
lea    miosprite0,a1
moveq    #13,d2
bsr.w    UniMuoviSprite
btst    #2,$dff016
bne.w    Wait
bra.w    exit

which updates the position of the mouse, moves it and, when the
left mouse button is pressed, simply exits the programme!
Position yourself at the coordinate you want to know, for example, the corner of a
button, and exit with the left mouse button while remaining at that point.
Now, all you have to do is see the last positions taken by the mouse with the
legendary command ‘M’ (after pressing the ESC key):

m Sprite_x (press RETURN)
m Sprite_y (press RETURN)

The ‘M’ command is very useful. It is often used to check what “point”
or what ‘value’ has been reached. For example, if you want to stop a
sprite or a bar at a certain point, just make a loop that moves it forward
until you press the mouse. Launch the program, press the mouse
when it reaches the point you want, and do ‘M variable’. Simple!!!

***************************************************************************

As a test, try making the sprite appear in different places on the screen when
the programme starts, and also try keeping the
mouse pointer in the rectangle in the figure below.

One thing you will have noticed is that if you press the “+”
or ‘-’ and do not release the left mouse button, the bar continues
to move even if we move the arrow away from the button:
this is because, as explained in point **2, until we release
the mouse button, the program does not recheck the position of the mouse!
To change this, simply add to point **2:

bsr.s    MoveArrow

obviously omitting the 

btst.b    #6,$bfe001
beq.s    Piu

Also try changing point **3

Now just add:

brs.s    MoveArrow

At points **4 and **5, look what happens:
just enter or exit the key that triggers its effect!

Unlike the other keys, for the ‘change colour to bar’ keys, just
hover over them with the mouse button pressed to get the desired effect!
Now you should be able to figure out why!

Finally, the keys that activate and deactivate the music also ‘lock’ the
arrow.... it's up to you to figure out why.
