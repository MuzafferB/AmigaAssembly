
; Lesson 11o1.s Loading a data file using dos.library

Section DosLoad,code

;    Include    ‘DaWorkBench.s’    ; remove the ; before saving with ‘WO’

Maincode:
movem.l    d0-d7/a0-a6,-(SP)    ; Save the registers in the stack
move.l    4.w,a6            ; ExecBase in a6
LEA    DosName(PC),A1        ; Dos.library
JSR    -$198(A6)        ; OldOpenlib
MOVE.L    D0,DosBase
BEQ.s    EXIT            ; If zero, exit! Error!

Mouse:
btst.b    #6,$bfe001    ; ciaapra - left mouse button
bne.s    Mouse

bsr.s    LoadFile    ; Load a file with dos.library

MOVE.L	DosBase(PC),A1    ; DosBase in A1 to close the library
move.l    4.w,a6        ; ExecBase in A6
jsr    -$19E(a6)    ; CloseLibrary - dos.library CLOSED
EXIT:
movem.l    (SP)+,d0-d7/a0-a6 ; Restore the old register values
RTS             ; Return to ASMONE or Dos/WorkBench


DosName:
dc.b    ‘dos.library’,0
even

DosBase:        ; Pointer to the base of the Dos Library
dc.l    0

*****************************************************************************
; Routine that loads a file of a specified length and with a specified name
;. You must enter the entire path, if it exists!
*****************************************************************************

LoadFile:
move.l    #filename,d1    ; address with string ‘file name + path’
MOVE.L    #$3ED,D2    ; AccessMode: MODE_OLDFILE - File that already exists
; and can therefore be read.
MOVE.L    DosBase(PC),A6
JSR    -$1E(A6)    ; LVOOpen - ‘Open’ the file
MOVE.L    D0,FileHandle    ; Save its handle
BEQ.S    ErrorOpen    ; If d0 = 0 then there is an error!

MOVE.L    D0,D1        ; FileHandle in d1 for Read
MOVE.L    #buffer,D2    ; Destination address in d2
MOVE.L    #42240,D3    ; File length (EXACT!)
MOVE.L DosBase(PC),A6
JSR -$2A(A6) LVORead - read the file and copy it to the buffer

MOVE.L FileHandle(pc),D1 FileHandle in d1
MOVE.L DosBase(PC),A6
JSR    -$24(A6)    ; LVOClose - close the file.
ErrorOpen:
rts


FileHandle:
dc.l    0

; Text string, ending with a 0, which d1 must point to before
; opening dos.lib. It is best to enter the entire path.

Filename:
dc.b	‘assembler2:sorgenti7/amiet.raw’,0	; path+nomefile
even

******************************************************************************
; Buffer where the image is loaded from the disk (or hard disk) via doslib
******************************************************************************

section    mioplanaccio,bss

buffer:
LOGO:
ds.b    6*40*176    ; 6 bitplanes * 176 lines * 40 bytes (HAM)

end

