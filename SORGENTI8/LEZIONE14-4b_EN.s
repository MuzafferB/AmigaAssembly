
; Lesson 14-4b.s    ** PLAY MORE COMPLEX WAVEFORMS **

section    samplestereo,code

Start:
move.l    4.w,a6
jsr    -$78(A6)        ; _LVODisable
bset    #1,$bfe001        ; Turns off the low-pass filter
lea    $dff000,a6
move.w    $2(a6),d7        ; dmaconr - Save OS DMA

move.l    #sample1,$a0(a6)    ; AUD0LCH.w+AUD0LCL.w=AUD0LC.l
move.l    #sample2,$b0(a6)    ; AUD1LCH.w+AUD1LCL.w=AUD1LC.l
move.w    #(sample1_end-sample1)/2,$a4(a6) ; length in words (AUD0LEN)
move.w    #(sample2_end-sample2)/2,$b4(a6) ; length in words (AUD1LEN)

Clock    equ    3546895

move.w    #clock/21056,$a6(a6)    ; AUD0PER at 168
move.w    #clock/21056,$b6(a6)    ; AUD1PER at 168

move.w    #64,$a8(a6)		; AUD0VOL at maximum (0 dB)
move.w    #64,$b8(a6)        ; AUD1VOL at maximum (0 dB)
move.w    #$8003,$96(a6)        ; Turns on AUD0-AUD1 DMA in DMACONW
WLMB:
btst    #6,$bfe001		; Wait for left mouse button
bne.s    WLMB

or.w    #$8000,d7        ; Turn on bit 15 (SET/CLR)
move.w    #$0003,$96(a6)        ; Turn off DMA
move.w    d7,$96(a6)		; reset OS DMA
move.l    4.w,a6
jsr    -$7e(a6)        ; _LVOEnable
rts

******************************************************************************

SECTION    Sample,DATA_C

; Note: samples are taken from ‘NASP’ by Pyratronik/IBB

Sample1:
incbin    ‘assembler2:sorgenti8/carrasco.21056’
Sample1_end:

Sample2:
incbin	‘assembler2:sorgenti8/lee3.21056’
Sample2_end:

END

******************************************************************************

We simply played two different samples in stereo, two samples
that had the same ideal reading frequency (but they could have had
different frequencies: it wouldn't have changed anything!) and the same length (which is
very important, because when read at the same frequency they have the same
duration and loop synchronously).

