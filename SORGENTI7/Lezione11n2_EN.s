
; Lesson 11n2.s - Timing routine that allows you to wait for a
;         certain number of Hertz

Start:
move.l    4.w,a6        ; Execbase in a6
jsr    -$84(a6)    ; forbid
jsr    -$78(a6)    ; disable
LEA    $DFF000,A5

bsr.s    CIAHZ    ; Wait a couple of seconds

move.l    4.w,a6        ; Execbase in a6
jsr    -$7e(a6)    ; enable
jsr    -$8a(a6)    ; permit
rts


; bfe801 todlo    -	1=~0.02 secs or 1/50 sec (PAL) or 1/60 sec (NTSC)
; bfe901 todmid    -    1=~3 secs
; bfea01 todhi    -    1=~21 mins
;
; Basically, it is a timer that can contain a 23-bit number, and this number
; is divided into: bits 0-7 in TODLO, bits 8-15 in TODMID and bits 16-23 in TODHI.


CIAHZ:
MOVE.L    A2,-(SP)
LEA    $BFE001,A2    ; CIAA base -> USED
;    LEA    $BFD000,A2	; CIAB base

MOVE.B    #0,$800(A2)    ; TODLO - bits 7-0 of the timer at 50-60hz
; reset timer!
WCIA:
CMPI.B    #50*2,$800(A2)    ; TODLO - Wait time = 2 seconds...
BGE.S    DONE
BRA.S    WCIA
DONE:
MOVE.L    (SP)+,A2
RTS

end

Note that if you want to use CIAB, you switch to a horizontal sync timer
rather than a vertical one, which is much faster. To wait
about 2 seconds, you need to use TODMID:

CIAHZ:
MOVE.L    A2,-(SP)
;    LEA    $BFE001,A2    ; CIAA base
LEA    $BFD000,A2    ; CIAB base -> USED

MOVE.B    #0,$800(A2)    ; TODLO - bit 7-0 of the timer at 50-60hz
; reset timer!
WCIA:
CMPI.B    #120,$900(A2)    ; TODMID - Wait time = 2 seconds...
BGE.S    DONE
BRA.S    WCIA
DONE:
MOVE.L    (SP)+,A2
RTS

Please note that the CIAA TOD is used by timer.device, while the
CIAB TOD is used by graphics.library!

If possible, wait for short times using the classic routine:

lea    $dff006,a0    ; VHPOSR
moveq    #XXX-1,d0    ; Number of lines to wait
waitlines:
move.b	(a0),d1        ; $dff006 - current vertical line in d1
stepline:
cmp.b    (a0),d1        ; are we still on the same line?
beq.s    stepline    ; if so, wait
dbra    d0,waitlines    ; ‘waited’ line, wait d0-1 lines
