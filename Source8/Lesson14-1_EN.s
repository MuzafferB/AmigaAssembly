
; Lesson 14-1.s            ** PLAYING THE HARMONICA **


SECTION    harmonica,CODE

Start:
move.l    4.w,a6
jsr    -$78(A6)        ; _LVODisable

bset    #1,$bfe001        ; Turns off the low-pass filter

lea    $dff000,a6
move.w    $2(a6),d7        ; dmaconr - Save OS DMA

Clock    equ    3546895

move.l    #harmonica,$a0(a6)    ; AUD0LCH.w+AUD0LCL.w=AUD0LC.l
move.w    #16/2,$a4(a6)        ; 16 bytes/2=8 words of data (AUD0LEN)
move.w    #clock/(16*880),$a6(a6)    ; AUD0PER at 251
move.w    #64,$a8(a6)        ; AUD0VOL at maximum (0 dB)
move.w    #$8201,$96(a6)        ; Turns on AUD0 DMA in DMACONW

WLMB:
btst	#6,$bfe001        ; Wait for left mouse button
bne.s    WLMB

or.w    #$8000,d7        ; Turn on bit 15 (SET/CLR)
move.w    #$0001,$96(a6)        ; dmacon - Turn off aud0
move.w    d7,$96(a6)        ; dmacon - Reset OS DMA
move.l    4.w,a6
jsr    -$7e(a6)        ; _LVOEnable
rts

******************************************************************************

SECTION    Sample,DATA_C    ;when read by the DMA, it must be in CHIP

; 16-value harmonic created with the IS of trash'm-one

Armonica:
DC.B	$19,$46,$69,$7C,$7D,$6A,$47,$1A,$E8,$BB,$97,$84,$83,$95,$B8,$E5

END

******************************************************************************

The Harmonica is a 16-byte sample that is played on channel 0 with a
sampling period of 251.
To play 16 bytes in 1 second (1 Hz), the AUDPER value should be 
1/16 of the clock constant value, since the DMA should wait
1/16 of the clock for 16 = the entire clock = 1 second.
To generate an A3, for example (=440 Hz), you would need to sample at 880 Hz according to
Nyquist's theorem, so the harmonic would be read with a
reading frequency of 880 Hz, and the sampling period (=value to be entered in
AUDPER) would be 1/880 of 1/16 of the clock constant:
3546895/16 = 221680 = 1 Hz, a value that cannot be entered in the register
because it is greater than the 16-bit range (AUDxPER = 1 unsigned word);
(3546895/16)/880 = 3546895/(16*880) = 251 = 880 Hz.

N.B.:    The two JSRs for the ‘Disable’ and ‘Enable’ functions of the exec could
be omitted, but for the sake of elegant coding, they are mandatory:
under the operating system, it would not be possible to directly access
the DMA channels (not even the audio ones), not so much because of the risk of
crashing the computer (the exec is not able to control any
access to the hardware registers, since the hardware has no protection circuits
and the system libraries cannot perform miracles), but rather because
your task/process will certainly conflict with other
tasks/processes that are using the audio resources: the Amiga has only
one sound chip and all of them must access it in order to play sound; the
Kernel in ROM provides AUDIO.DEVICE to allow
any task to use the chip and to arbitrarily control
access and use between processes via software.
Since this course involves the use of hardware through direct access
to registers, we will not use devices, and therefore we will always be
obliged (even if, in the event that no one is accessing
the sound hardware, it would not actually be necessary) to shut down
the operating system “legally” (with an exec function).

