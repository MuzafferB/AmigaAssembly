
; Lesson 14-4a.s    ** PLAY COMPLEX WAVEFORMS **


section    samplemono,code

Start:
move.l    4.w,a6
jsr    -$78(A6)        ; _LVODisable
bset    #1,$bfe001		; Turns off the low-pass filter
lea    $dff000,a6
move.w    $2(a6),d7        ; dmaconr - Save OS DMA

move.l    #sample,$a0(a6)        ; AUD0LCH.w+AUD0LCL.w=AUD0LC.l
move.l    #sample,$b0(a6)        ; AUD1LCH.w+AUD1LCL.w=AUD1LC.l
move.w    #(sample_end-sample)/2,$a4(a6)    ; length in words (AUD0LEN)
move.w    #(sample_end-sample)/2,$b4(a6)	; length in words (AUD1LEN)

Clock    equ    3546895

move.w    #clock/21056,$a6(a6)    ; AUD0PER at 168
move.w    #clock/21056,$b6(a6)    ; AUD1PER at 168

move.w    #64,$a8(a6)        ; AUD0VOL at maximum (0 dB)
move.w    #64,$b8(a6)        ; AUD1VOL at maximum (0 dB)
move.w    #$8003,$96(a6)        ; Turns on AUD0-AUD1 DMA in DMACONW


WLMB:
btst    #6,$bfe001        ;wait for left mouse button
bne.s    WLMB

or.w    #$8000,d7        ; turn on bit 15 (SET/CLR)
move.w    #$0003,$96(a6)		; turns off DMA
move.w    d7,$96(a6)        ; resets OS DMA
move.l    4.w,a6
jsr    -$7e(a6)        ; _LVOEnable
rts

******************************************************************************

SECTION    Sample,DATA_C

; Note: the sample is taken from ‘NASP’ by Pyratronik/IBB

Sample:	incbin	‘assembler2:sorgenti8/carrasco.21056’
Sample_end:

END

******************************************************************************

As far as this example is concerned, there is not much to explain:
there are no new features; in fact, it is very similar to example 1, and we are used to
much more challenging listings.
I would just like to point out one thing: the sample sampling frequency is
21056 Hz, equal to the original recording frequency: it is necessary to
set a SAMPLING SPEED equal to the digitisation speed
if you want to hear the sound at the correct speed... try changing
the sampling period in AUDxPER...

*** I would like to emphasise that 21056 does NOT express the number of times
the entire sample is read, but the frequency of reading byte by byte:
21056 bytes are read per second in a sample of arbitrary length;
the hardware must be informed of the sampling period relative
to the reading speed.
As we did for the harmonica: first we established how many times the ENTIRE wave had to be
read, then we calculated the sampling period
by multiplying the frequency of the note by the length of the sample in bytes, to
obtain the reading speed ***.

