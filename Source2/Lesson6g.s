
; Lezione6g.s		SCRITTURA "SOPRA" UNA FIGURA (in trasparenza)
;			Tasto sinistro del mouse per avanzare, destro per
;			retrocedere, entrambi per uscire - si puo' scorrere
;			anche tutta la memoria come in Lezione5l.s

	SECTION	CiriCop,CODE

Inizio:
	move.l	4.w,a6		; Execbase in a6
	jsr	-$78(a6)	; Disable - ferma il multitasking
	lea	GfxName(PC),a1	; Indirizzo del nome della lib da aprire in a1
	jsr	-$198(a6)	; OpenLibrary
	move.l	d0,GfxBase	; salvo l'indirizzo base GFX in GfxBase
	move.l	d0,a6
	move.l	$26(a6),OldCop	; salviamo l'indirizzo della copperlist vecchia

;	Puntiamo i bitplanes in copperlist - prima la PIC

	MOVE.L	#PIC,d0		; in d0 mettiamo l'indirizzo della PIC, in
				; questo caso puntiamo piu' avanti di 50
				; linee in modo da far "SALIRE" l'immagine.
	LEA	BPLPOINTERS,A1	; puntatori nella COPPERLIST
	MOVEQ	#2,D1		; numero di bitplanes -1 (qua sono 3)
POINTBP:
	move.w	d0,6(a1)	; copia la word BASSA dell'indirizzo del plane
	swap	d0		; scambia le 2 word di d0 (es: 1234 > 3412)
	move.w	d0,2(a1)	; copia la word ALTA dell'indirizzo del plane
	swap	d0		; scambia le 2 word di d0 (es: 3412 > 1234)
	ADD.L	#40*256,d0	; + lunghezza bitplane -> prossimo bitplane
	addq.w	#8,a1		; andiamo ai prossimi bplpointers nella COP
	dbra	d1,POINTBP	; Rifai D1 volte POINTBP (D1=num of bitplanes)

;	 PUNTIAMO IL NOSTRO BITPLANE

	MOVE.L	#BITPLANE,d0	; in d0 mettiamo l'indirizzo della PIC,
	LEA	BPLPOINTERS2,A1	; puntatori nella COPPERLIST (plane 4!)
	move.w	d0,6(a1)	; copia la word BASSA dell'indirizzo del plane
	swap	d0		; scambia le 2 word di d0 (es: 1234 > 3412)
	move.w	d0,2(a1)	; copia la word ALTA dell'indirizzo del plane

	move.l	#COPPERLIST,$dff080	; Puntiamo la nostra COP
	move.w	d0,$dff088		; Facciamo partire la COP
	move.w	#0,$dff1fc		; Disattiva l'AGA
	move.w	#$c00,$dff106		; Disattiva l'AGA

	bsr.w	print		; Stampa le linee di testo sullo schermo
				; in HIRES

mouse:
	cmpi.b	#$ff,$dff006	; Siamo alla linea 255?
	bne.s	mouse		; Se non ancora, non andare avanti
Aspetta:
	cmpi.b	#$ff,$dff006	; Siamo alla linea 255?
	beq.s	Aspetta		; Se si, non andare avanti, aspetta!

	btst	#2,$dff016	; se il tasto destro e' premuto
	bne.s	NonGiu		; scorri giu!, oppure vai a NonGiu

	bsr.w	VaiGiu		; tasto destro premuto, scorri giu!

Nongiu:
	btst	#6,$bfe001	; tasto sinistro del mouse premuto?
	beq.s	Scorrisu	; se si, scorri in su
	bra.s	mouse		; no? allora ripeti il ciclo il prossimo FRAME

Scorrisu:
	bsr.w	VaiSu		; fa scorrere la figura in alto

	btst	#2,$dff016	; se anche il tasto destro e' premuto allora
	bne.s	mouse		; sono premuti entrambi, esci, oppure "MOUSE"


	move.l	OldCop(PC),$dff080	; Puntiamo la cop di sistema
	move.w	d0,$dff088		; facciamo partire la vecchia cop

	move.l	4.w,a6
	jsr	-$7e(a6)	; Enable - riabilita il Multitasking
	move.l	gfxbase(PC),a1	; Base della libreria da chiudere
	jsr	-$19e(a6)	; Closelibrary - chiudo la graphics lib
	rts			; USCITA DAL PROGRAMMA

;	Dati

GfxName:
	dc.b	"graphics.library",0,0

GfxBase:		; Qua ci va l'indirizzo di base per gli Offset
	dc.l	0	; della graphics.library

OldCop:			; Qua ci va l'indirizzo della vecchia COP di sistema
	dc.l	0

;	Routine che stampa caratteri larghi 8x8 pixel (su schermo LOWRES)

PRINT:
	LEA	TESTO(PC),A0	; Indirizzo del testo da stampare in a0
	LEA	BITPLANE,A3	; Indirizzo del bitplane destinazione in a3
	MOVEQ	#23-1,D3	; NUMERO RIGHE DA STAMPARE: 23
PRINTRIGA:
	MOVEQ	#40-1,D0	; NUMERO COLONNE PER RIGA: 40 (lores)
PRINTCHAR2:
	MOVEQ	#0,D2		; Pulisci d2
	MOVE.B	(A0)+,D2	; Prossimo carattere in d2
	SUB.B	#$20,D2		; TOGLI 32 AL VALORE ASCII DEL CARATTERE, IN
				; MODO DA TRASFORMARE, AD ESEMPIO, QUELLO
				; DELLO SPAZIO (che e' $20), in $00, quello
				; DELL'ASTERISCO ($21), in $01...
	MULU.W	#8,D2		; MOLTIPLICA PER 8 IL NUMERO PRECEDENTE,
				; essendo i caratteri alti 8 pixel
	MOVE.L	D2,A2
	ADD.L	#FONT,A2	; TROVA IL CARATTERE DESIDERATO NEL FONT...

				; STAMPIAMO IL CARATTERE LINEA PER LINEA
	MOVE.B	(A2)+,(A3)	; stampa LA LINEA 1 del carattere
	MOVE.B	(A2)+,40(A3)	; stampa LA LINEA 2  " "
	MOVE.B	(A2)+,40*2(A3)	; stampa LA LINEA 3  " "
	MOVE.B	(A2)+,40*3(A3)	; stampa LA LINEA 4  " "
	MOVE.B	(A2)+,40*4(A3)	; stampa LA LINEA 5  " "
	MOVE.B	(A2)+,40*5(A3)	; stampa LA LINEA 6  " "
	MOVE.B	(A2)+,40*6(A3)	; stampa LA LINEA 7  " "
	MOVE.B	(A2)+,40*7(A3)	; stampa LA LINEA 8  " "

	ADDQ.w	#1,A3		; A1+1, avanziamo di 8 bit (PROSSIMO CARATTERE)

	DBRA	D0,PRINTCHAR2	; STAMPIAMO D0 (40) CARATTERI PER RIGA

	ADD.W	#40*7,A3	; ANDIAMO A CAPO

	DBRA	D3,PRINTRIGA	; FACCIAMO D3 RIGHE

	RTS


		; numero caratteri per linea: 40
TESTO:	     ;		  1111111111222222222233333333334
	     ;	 1234567890123456789012345678901234567890
	dc.b	'                                        ' ; 1
	dc.b	'                SECONDA RIGA            ' ; 2
	dc.b	'     /\  /                              ' ; 3
	dc.b	'    /  \/                               ' ; 4
	dc.b	'                                        ' ; 5
	dc.b	'        SESTA RIGA                      ' ; 6
	dc.b	'                                        ' ; 7
	dc.b	'                                        ' ; 8
	dc.b	'FABIO CIUCCI COMMUNICATION INTERNATIONAL' ; 9
	dc.b	'                                        ' ; 10
	dc.b	'   1234567890 !@#$%^&*()_+|\=-[]{}      ' ; 11
	dc.b	'                                        ' ; 12
	dc.b	' -=- LA PALINGENETICA OBLITERAZIONE -=- ' ; 13
	dc.b	" ##  DELL'IO TRASCENDENTALE CHE SI  ##  " ; 14
	dc.b	' ///    IMMEDESIMA E SI INFUTURA   \\\  ' ; 15
	dc.b	'  Nel mezzo del cammin di nostra vita   ' ; 16
	dc.b	'                                        ' ; 17
	dc.b	'    Mi RitRoVaI pEr UnA sELva oScuRa    ' ; 18
	dc.b	'                                        ' ; 19
	dc.b	'    CHE LA DIRITTA VIA ERA SMARRITA     ' ; 20
	dc.b	'                                        ' ; 21
	dc.b	'  AHI Quanto a DIR QUAL ERA...          ' ; 22
	dc.b	'                                        ' ; 23
	dc.b	'                                        ' ; 24
	dc.b	'                                        ' ; 25
	dc.b	'                                        ' ; 26

	EVEN

;	Questa routine sposta la figura in alto e in basso, agendo sui
;	puntatori ai bitplanes in copperlist (tramite la label BPLPOINTERS)
;	Da Lezione5l.s

VAIGIU:
	LEA	BPLPOINTERS2,A1	; Con queste 4 istruzioni preleviamo dalla
	move.w	2(a1),d0	; copperlist l'indirizzo dove sta puntando
	swap	d0		; attualmente il $dff0e0 e lo poniamo
	move.w	6(a1),d0	; in d0 - il contrario della routine che
	sub.l	#40,d0		; sottraiamo 40, ossia 1 linea, facendo
				; scorrere in BASSO la figura
	bra.s	Finito


VAISU:
	LEA	BPLPOINTERS2,A1	; Con queste 4 istruzioni preleviamo dalla
	move.w	2(a1),d0	; copperlist l'indirizzo dove sta puntando
	swap	d0		; attualmente il $dff0e0 e lo poniamo
	move.w	6(a1),d0	; in d0 - il contrario della routine che
	add.l	#40,d0		; Aggiungiamo 40, ossia 1 linea, facendo
				; scorrere in ALTO la figura
	bra.w	finito


Finito:				; PUNTIAMO I PUNTATORI BITPLANES
	move.w	d0,6(a1)	; copia la word BASSA dell'indirizzo del plane
	swap	d0		; scambia le 2 word di d0 (es: 1234 > 3412)
	move.w	d0,2(a1)	; copia la word ALTA dell'indirizzo del plane
	rts



	SECTION	GRAPHIC,DATA_C

COPPERLIST:
	dc.w	$120,$0000,$122,$0000,$124,$0000,$126,$0000,$128,$0000 ; SPRITE
	dc.w	$12a,$0000,$12c,$0000,$12e,$0000,$130,$0000,$132,$0000
	dc.w	$134,$0000,$136,$0000,$138,$0000,$13a,$0000,$13c,$0000
	dc.w	$13e,$0000

	dc.w	$8e,$2c81	; DiwStrt	(registri con valori normali)
	dc.w	$90,$2cc1	; DiwStop
	dc.w	$92,$0038	; DdfStart
	dc.w	$94,$00d0	; DdfStop
	dc.w	$102,0		; BplCon1
	dc.w	$104,0		; BplCon2
	dc.w	$108,0		; Bpl1Mod
	dc.w	$10a,0		; Bpl2Mod

		    ; 5432109876543210
	dc.w	$100,%0100001000000000	; bit 14 - 4 bitplanes, 16 colori

BPLPOINTERS:
	dc.w $e0,$0000,$e2,$0000	;primo	 bitplane
	dc.w $e4,$0000,$e6,$0000	;secondo bitplane
	dc.w $e8,$0000,$ea,$0000	;terzo	 bitplane
BPLPOINTERS2:
	dc.w $ec,$0000,$ee,$0000	;quarto	 bitplane

	dc.w	$180,$000	; color0 ; colori della figura un po' attenuati
	dc.w	$182,$354	; color1
	dc.w	$184,$678	; color2
	dc.w	$186,$567	; color3
	dc.w	$188,$455	; color4
	dc.w	$18a,$121	; color5
	dc.w	$18c,$455	; color6
	dc.w	$18e,$233	; color7

	dc.w	$190,$454	; color8	; I colori della scritta:
	dc.w	$192,$7a8	; color9	; in questo caso formiamo
	dc.w	$194,$eef	; color10	; 8 diversi colori per le
	dc.w	$196,$cde	; color11	; 8 possibilita' di
	dc.w	$198,$aab	; color12	; sovrapposizione - se notate
	dc.w	$19a,$786	; color13	; sono simili ai primi 8,
	dc.w	$19c,$9aa	; color14	; ma molto piu' luminosi
	dc.w	$19e,$789	; color15	; per creare la "TRASPARENZA"

	dc.w	$FFFF,$FFFE	; Fine della copperlist

;	Il FONT caratteri 8x8

FONT:
	incbin	"metal.fnt"	; Carattere largo
;	incbin	"normal.fnt"	; Simile ai caratteri kickstart 1.3
;	incbin	"nice.fnt"	; Carattere stretto

PIC:
	incbin	"amiga.320*256*3"	; qua carichiamo la figura in RAW,

	SECTION	MIOPLANE,BSS_C	; in CHIP

BITPLANE:
	ds.b	40*256	; un bitplane lores 320x256

	end

Potete scorrere anche tutta la memoria sopra la figura! Se indietreggiate col
tasto destro del mouse troverete i 3 bitplanes della figura, poi il font
caratteri (non ben visibile per l'incongruenza di modulo) eccetera.

