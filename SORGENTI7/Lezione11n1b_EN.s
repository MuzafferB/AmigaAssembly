
; Lesson 11n1b.s - Timing routine that allows you to wait a
; certain number of microseconds using a CIAA/B timer

; This test routine allows you to check how many video lines
; correspond to a certain number of microseconds.
; (the RED part of the screen is where the routine is executed)


MICS:    equ    2000        ; ~2000 microseconds = ~2 milliseconds
; value = mics/1.4096837
; 1 microsecond = 1 sec/1 million
; NOTE: to compare this routine with
; the one that waits for the raster lines, bear in mind
; that 200 milliseconds correspond
; to approximately 5 raster lines, 400 milliseconds
; to 9.5 lines, 600 milliseconds to 14 lines, and so on

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$84(a6)    ; forbid
jsr    -$78(a6)    ; disable
LEA    $DFF000,A5

WBLANNY:
MOVE.L    4(A5),D0    ; $dff004 - VPOSR/VHPOSR
ANDI.L    #$1FF00,D0    ; only the bits of the vertical line are of interest
CMPI.L    #$08000,D0    ; wait for line $080
BNE.S    WBLANNY

move.w    #$f00,$180(a5)    ; Colour zero RED

bsr.s    CIAMIC

move.w    #0f0,$180(a5)    ; Colour zero GREEN

btst    #6,$bfe001
bne.s    WBLANNY


move.l    4.w,a6        ; Execbase in a6
jsr    -$7e(a6)	; enable
jsr    -$8a(a6)    ; permit
rts

;    Here is the routine that waits for a specific number of MICROSECONDS,
;    using the CIAB's timer B. To use the CIAA's timer B, simply
;    replace ‘lea $bfd000,a4’ with ‘lea $bfe001,a4’. In the listing
;    it is already present, just remove the semicolon and put it
;    in the base CIAB instead. However, it is better to use the CIAB because the
;    CIAA timer is used by the operating system for various tasks.
; In fact, if you use the CIAA timer B, everything freezes!

CIAMIC:
movem.l    d0/a4,-(sp)        ; save the registers used
lea    $bfd000,a4        ; CIAB base

;     lea    $bfe001,a4        ; CIAA base - BUT THIS WILL CAUSE
; EVERYTHING TO FREEZE, AS IT IS USED BY THE
; OPERATING SYSTEM! DO NOT USE THE CIAA TIMER B
; OF THE CIAA, PLEASE!

move.b $f00(a4),d0        ; $bfde00 - CRB, CIAB control reg. B
andi.b #%11000000,d0        ; reset bits 0-5
ori.b #%00001000,d0        ; One-Shot mode (single run mode)
move.b d0,$f00(a4)        ; CRB - Set the control register
move.b #%01111101,$d00(a4)    ; ICR - Clear CIA interrupts
move.b #(MICS&$FF),$600(a4)    ; TBLO - set the low byte of the time
move.b #(MICS>>8),$700(a4)    ; TBHI - set the high byte of the time
bset.b #0,$f00(a4)        ; CRB - Start timer!!
wait:
btst.b #1,$d00(a4)    ; ICR - Wait for the time to expire.
; note that bit 1 is tested, not
; zero, to wait for timer B.
beq.s wait
movem.l    (sp)+,d0/a4        ; reset the registers
rts

end

Just one last thing. If you have the time to wait in a label, you could
‘split’ it into a low byte and a high byte with an lsr:

lea    $bfd000,a4        ; cia_b base
move.w    TimerValue(PC),d0    ; countdown
move.b    d0,$600(a4)        ; timer B - set the byte
lsr.w    #8,d0
move.b    d0,$700(a4)        ; timer B - set hi byte
; 76543210
move.b #%01111101,$d00(a4)    ; ICR - clear CIA interrupts
move.b    #%00011001,$f00(a4)    ; CRB - start
; 7 - Alarm -> 0
; 6,5 - Inmode bits -> 00
; 4 - Load bit -> 1 (loads the value to the
; timer and starts
; the countdown).
; 3 - RunMode -> 1 (One shot, 1 time)
; 2 - OutMode -> 0 (for receiving pulse)
; 1 - PBON -> 0
; 0 - Start -> starts countdown
; when reaches 0->interrupt
MOVE.B    #%10000010,$d00(a4)    ; ICR - Enable timer interrupt B ciaB
loop:
btst    #1,$d00(a4)        ; ICR - test tb-bit ->clear ICR
beq.s    loop            ; not set->wait
rts


; CIA:    ICR (Interrupt Control Register)                [d]
;
; 0	TA        underflow
; 1    TB        underflow
; 2    ALARM        TOD alarm
; 3    SP        serial port full/empty
; 4    FLAG        flag
; 5-6    unused
; 7 R    IR
; 7 W    set/clear
;
; CIA: CRA, CRB (Control Register)					[e-f]
;
; 0    START        0 = stop / 1 = start TA; {0}=0 when TA underflow
; 1    PBON        1 = TA output on PB / 0 = normal mode
; 2    OUTMODE        1 = toggle / 0 = pulse
; 3    RUNMODE        1 = one-shot / 0 = continuous mode
; 4 S    LOAD        1 = force load (strobe, always 0)
; 5 A    INMODE        1 = TA counts positive CNT transition
;            0 = TA counts 02 pulses
; 6 A    SPMODE        serial port....
; 7 A    unused
; 6-5 B    INMODE		00 = TB counts 02 pulses
;            01 = TB counts positive CNT transition
;            10 = TB counts TA underflow pulses
;            11 = TB counts TA underflow pulses while CNT is high
; 7 B    ALARM        1 = writing TOD sets alarm
;            0 = writing TOD sets clock
;            Reading TOD always reads TOD clock


