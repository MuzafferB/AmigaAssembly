
; Lesson 11n1.s - Timing routine that allows you to wait a
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
ANDI.L    #$1FF00,D0    ; only the bits of the vertical line are of interest.
CMPI.L    #$08000,D0    ; wait for line $080
BNE.S    WBLANNY

move.w    #$f00,$180(a5)    ; Colour zero RED

bsr.s    CIAMIC

move.w    #$0f0,$180(a5)    ; Colour zero GREEN

btst    #6,$bfe001
bne.s    WBLANNY


move.l    4.w,a6        ; Execbase in a6
jsr    -$7e(a6)    ; enable
jsr    -$8a(a6)    ; permit
rts

;    Here is the routine that waits for a specific number of MICROSECONDS,
;    using the CIAB's timer A. To use the CIAA's timer A, simply
;    replace ‘lea $bfd000,a4’ with ‘lea $bfe001,a4’. In the listing
;    it is already present, just remove the semicolon and put it
;    instead at the CIAB base. However, it is better to use the CIAB because the
;    CIAA timer is used by the operating system for various tasks.

CIAMIC:
movem.l    d0/a4,-(sp)        ; save the registers used
lea    $bfd000,a4        ; CIAB base
lea    $bfe001,a4        ; CIAA base (if you want to use B)
move.b $e00(a4),d0        ; $bfde00 - CRA, CIAB control reg. A
andi.b #%11000000,d0        ; reset bits 0-5
ori.b #%00001000,d0        ; One-Shot mode (single run mode)
move.b d0,$e00(a4)        ; CRA - Set the control register
move.b #%01111110,$d00(a4)    ; ICR - Clear CIA interrupts
move.b #(MICS&$FF),$400(a4)    ; TALO - set the low byte of the time
move.b #(MICS>>8),$500(a4)    ; TAHI - set the high byte of the time
bset.b #0,$e00(a4)        ; CRA - Start timer!!
wait:
btst.b #0,$d00(a4)    ; ICR - Wait for the time to expire
beq.s wait
movem.l    (sp)+,d0/a4        ; reset the registers
rts

end

; CIA:    ICR (Interrupt Control Register)                [d]
;
; 0    TA        underflow
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

