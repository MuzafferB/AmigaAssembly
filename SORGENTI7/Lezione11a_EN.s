
; Lesson 11a.s        Execution of a pair of privileged instructions.

Start:
move.l    4.w,a6            ; ExecBase in a6
lea    SuperCode(PC),a5    ; Routine to be executed in supervisor
jsr    -$1e(a6)        ; LvoSupervisor - execute the routine
; (do not save the registers! caution!)
rts                ; exit, after executing the routine
; ‘SuperCode’ in supervisor.

; Routine executed in supervisor mode
;     __
;     \/
;    - -
;    
;     / \

SuperCode:
move.w    SR,d0        ; privileged instruction
move.w    d0,sr        ; privileged instruction
RTE    ; Return From Exception: like RTS, but for exceptions.

end

By executing this listing, you obtain the value of the Status Register at the moment
of the exception, so at the end of the execution, d0 will contain a value,
usually $2000, which is also proof that an exception was occurring,
since bit 13 of the SR, if set, indicates supervisor mode.

(((
oO Oo
\"/
~		5432109876543210
($2000=%0010000000000000)

NOTE: move.w SR, destination is privileged only from 68010 onwards, in
68000 it is also executable in user mode. In fact, those who used it in
old demos or games in user mode made it work only on 68000,
with lots of swearing and cursing for owners of 68020+.
