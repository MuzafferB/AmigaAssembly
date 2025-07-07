
ICONSTARTUP:
MOVEM.L    D0/A0-A1/A4/A6,-(SP)    ; save registers to stack
SUBA.L    A1,A1
MOVEA.L    4.w,A6
JSR    -$126(A6)    ; _LVOFindTask(a6)
MOVEA.L    D0,A4
TST.L    $AC(A4)        ; pr_CLI(a4) are we running from CLI?
BNE.S    FROMCLI        ; if so, skip the formalities
LEA    $5C(A4),A0    ; pr_MsgPort
MOVEA.L    4.W,A6        ; Execbase in a6
JSR    -$180(A6)    ; _LVOWaitPort
LEA    $5C(A4),A0    ; pr_MsgPort
JSR    -$174(A6)    ; _LVOGetMsg
LEA    RETURNMSG(PC),A0
MOVE.L    D0,(A0)
FROMCLI:
MOVEM.L    (SP)+,D0/A0-A1/A4/A6    ; restore registers from stack
BSR.w    MAINCODE    ; execute our program
MOVEM.L    D0/A6,-(SP)
LEA    RETURNMSG(PC),A6
TST.L    (A6)        ; Did we start from CLI?
BEQ.S    ExitToDos    ; if so, skip the formalities
MOVEA.L    4.w,A6
JSR    -$84(A6)    ; _LVOForbid - note! No permit needed
MOVEA.L    RETURNMSG(PC),A1
JSR    -$17A(A6)    ; _LVOReplyMsg
ExitToDos:
MOVEM.L    (SP)+,D0/A6        ; exit code
MOVEQ    #0,d0
RTS

RETURNMSG:
dc.l    0

