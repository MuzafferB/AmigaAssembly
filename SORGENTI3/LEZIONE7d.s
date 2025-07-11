
; Lezione7d.s	UNO SPRITE MOSSO VERTICALMENTE USANDO UNA TABELLA DI VALORI
;		(ossia di coordinate verticali) PRESTABILITI.
;		- Da notare che possiamo arrivare in basso fino alla linea $FF
;		  e non oltre.

	SECTION	CiriCop,CODE

Inizio:
	move.l	4.w,a6		; Execbase
	jsr	-$78(a6)	; Disable
	lea	GfxName(PC),a1	; Nome lib
	jsr	-$198(a6)	; OpenLibrary
	move.l	d0,GfxBase
	move.l	d0,a6
	move.l	$26(a6),OldCop	; salviamo la vecchia COP

;	Puntiamo la PIC "vuota"

	MOVE.L	#BITPLANE,d0	; dove puntare
	LEA	BPLPOINTERS,A1	; puntatori COP
	move.w	d0,6(a1)
	swap	d0
	move.w	d0,2(a1)

;	Puntiamo lo sprite

	MOVE.L	#MIOSPRITE,d0		; indirizzo dello sprite in d0
	LEA	SpritePointers,a1	; Puntatori in copperlist
	move.w	d0,6(a1)
	swap	d0
	move.w	d0,2(a1)

	move.l	#COPPERLIST,$dff080	; nostra COP
	move.w	d0,$dff088		; START COP
	move.w	#0,$dff1fc		; NO AGA!
	move.w	#$c00,$dff106		; NO AGA!

mouse:
	cmpi.b	#$ff,$dff006	; Linea 255?
	bne.s	mouse

	bsr.s	MuoviSprite	; Muovi lo sprite 0 verticalmente

Aspetta:
	cmpi.b	#$ff,$dff006	; linea 255?
	beq.s	Aspetta

	btst	#6,$bfe001	; mouse premuto?
	bne.s	mouse

	move.l	OldCop(PC),$dff080	; Puntiamo la cop di sistema
	move.w	d0,$dff088		; facciamo partire la vecchia cop

	move.l	4.w,a6
	jsr	-$7e(a6)	; Enable
	move.l	gfxbase(PC),a1
	jsr	-$19e(a6)	; Closelibrary
	rts

;	Dati

GfxName:
	dc.b	"graphics.library",0,0

GfxBase:
	dc.l	0

OldCop:
	dc.l	0

; Questa routine sposta in alto e in basso lo sprite agendo sui suoi byte
; VSTART e VSTOP, ossia i byte della sua posizione Y di inizio e fine,
; immettendoci delle coordinate gia' stabilite nella tabella TABY

MuoviSprite:
	ADDQ.L	#1,TABYPOINT	 ; Fai puntare al byte successivo
	MOVE.L	TABYPOINT(PC),A0 ; indirizzo contenuto in long TABXPOINT
				 ; copiato in a0
	CMP.L	#FINETABY-1,A0  ; Siamo all'ultima longword della TAB?
	BNE.S	NOBSTART	; non ancora? allora continua
	MOVE.L	#TABY-1,TABYPOINT ; Riparti a puntare dalla prima long
NOBSTART:
	moveq	#0,d0		; Pulisci d0
	MOVE.b	(A0),d0		; copia il byte dalla tabella in d0
	MOVE.b	d0,VSTART	; copia il byte in VSTART
	ADD.B	#13,D0		; Aggiungi la lunghezza dello sprite per
				; determinare la posizione finale (VSTOP)
	move.b	d0,VSTOP	; Muovi il valore giusto in VSTOP
	rts

TABYPOINT:
	dc.l	TABY-1		; NOTA: i valori della tabella qua sono bytes,
				; dunque lavoriamo con un ADDQ.L #1,TABYPOINT
				; e non #2 come per quando sono word o con #4
				; come quando sono longword.

; Tabella con coordinate Y dello sprite precalcolate.
; Da notare che la posizione Y per far entrare lo sprite nella finestra video
; deve essere compresa tra $2c e $f2, infatti nella tabella ci sono byte non
; piu' grandi di $f2 e non piu' piccoli di $2c.

TABY:
	dc.b	$EE,$EB,$E8,$E5,$E2,$DF,$DC,$D9,$D6,$D3,$D0,$CD ; salto in
	dc.b	$CA,$C7,$C4,$C1,$BE,$BB,$B8,$B5,$B2,$AF,$AC,$A9 ; alto da
	dc.b	$A6,$A4,$A1,$9E,$9B,$98,$96,$93,$90,$8E,$8B,$88 ; record!
	dc.b	$86,$83,$81,$7E,$7C,$79,$77,$74,$72,$70,$6D,$6B ; 200 valori
	dc.b	$69,$66,$64,$62,$60,$5E,$5C,$5A,$58,$56,$54,$52
	dc.b	$51,$4F,$4D,$4B,$4A,$48,$47,$45,$44,$42,$41,$3F
	dc.b	$3E,$3D,$3C,$3A,$39,$38,$37,$36,$35,$34,$33,$33
	dc.b	$32,$31,$30,$30,$2F,$2F,$2E,$2E,$2D,$2D,$2D,$2C
	dc.b	$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2D,$2D,$2D
	dc.b	$2E,$2E,$2F,$2F,$30,$30,$31,$32,$33,$33,$34,$35
	dc.b	$36,$37,$38,$39,$3A,$3C,$3D,$3E,$3F,$41,$42,$44
	dc.b	$45,$47,$48,$4A,$4B,$4D,$4F,$51,$52,$54,$56,$58
	dc.b	$5A,$5C,$5E,$60,$62,$64,$66,$69,$6B,$6D,$70,$72
	dc.b	$74,$77,$79,$7C,$7E,$81,$83,$86,$88,$8B,$8E,$90
	dc.b	$93,$96,$98,$9B,$9E,$A1,$A4,$A6,$A9,$AC,$AF,$B2
	dc.b	$B5,$B8,$BB,$BE,$C1,$C4,$C7,$CA,$CD,$D0,$D3,$D6
	dc.b	$D9,$DC,$DF,$E2,$E5,$E8,$EB,$EE
FINETABY:


	SECTION	GRAPHIC,DATA_C

COPPERLIST:
SpritePointers:
	dc.w	$120,0,$122,0,$124,0,$126,0,$128,0 ; SPRITE
	dc.w	$12a,0,$12c,0,$12e,0,$130,0,$132,0
	dc.w	$134,0,$136,0,$138,0,$13a,0,$13c,0
	dc.w	$13e,0

	dc.w	$8E,$2c81	; DiwStrt
	dc.w	$90,$2cc1	; DiwStop
	dc.w	$92,$38		; DdfStart
	dc.w	$94,$d0		; DdfStop
	dc.w	$102,0		; BplCon1
	dc.w	$104,0		; BplCon2
	dc.w	$108,0		; Bpl1Mod
	dc.w	$10a,0		; Bpl2Mod

		    ; 5432109876543210
	dc.w	$100,%0001001000000000	; bit 12 acceso!! 1 bitplane lowres

BPLPOINTERS:
	dc.w $e0,0,$e2,0	;primo	 bitplane

	dc.w	$180,$000	; color0	; sfondo nero
	dc.w	$182,$123	; color1	; colore 1 del bitplane, che
						; in questo caso e' vuoto,
						; per cui non compare.

	dc.w	$1A2,$F00	; color17, ossia COLOR1 dello sprite0 - ROSSO
	dc.w	$1A4,$0F0	; color18, ossia COLOR2 dello sprite0 - VERDE
	dc.w	$1A6,$FF0	; color19, ossia COLOR3 dello sprite0 - GIALLO

	dc.w	$FFFF,$FFFE	; Fine della copperlist


; ************ Ecco lo sprite: OVVIAMENTE deve essere in CHIP RAM! ************

MIOSPRITE:		; lunghezza 13 linee
VSTART:
	dc.b $50	; Posizione verticale di inizio sprite (da $2c a $f2)
HSTART:
	dc.b $90	; Posizione orizzontale di inizio sprite (da $40 a $d8)
VSTOP:
	dc.b $5d	; $50+13=$5d	; posizione verticale di fine sprite
	dc.b $00
 dc.w	%0000000000000000,%0000110000110000 ; Formato binario per modifiche
 dc.w	%0000000000000000,%0000011001100000
 dc.w	%0000000000000000,%0000001001000000
 dc.w	%0000000110000000,%0011000110001100 ;BINARIO 00=COLORE 0 (TRASPARENTE)
 dc.w	%0000011111100000,%0110011111100110 ;BINARIO 10=COLORE 1 (ROSSO)
 dc.w	%0000011111100000,%1100100110010011 ;BINARIO 01=COLORE 2 (VERDE)
 dc.w	%0000110110110000,%1111100110011111 ;BINARIO 11=COLORE 3 (GIALLO)
 dc.w	%0000011111100000,%0000011111100000
 dc.w	%0000011111100000,%0001111001111000
 dc.w	%0000001111000000,%0011101111011100
 dc.w	%0000000110000000,%0011000110001100
 dc.w	%0000000000000000,%1111000000001111
 dc.w	%0000000000000000,%1111000000001111
 dc.w	0,0	; 2 word azzerate definiscono la fine dello sprite.


	SECTION	PLANEVUOTO,BSS_C	; Il bitplane azzerato che usiamo,
					; perche' per vedere gli sprite
					; e' necessario che ci siano bitplanes
					; abilitati
BITPLANE:
	ds.b	40*256		; bitplane azzerato lowres

	end

I movimenti complessi e realistici si fanno con le tabelle!
Provate a sostituire la tabella corrente con questa, ed otterrete un ondeggio
dello sprite. (Amiga+b+c+i per copiare), (amiga+b+x per cancellare un pezzo)


TABY:
	dc.b	$8E,$91,$94,$97,$9A,$9D,$A0,$A3,$A6,$A9,$AC,$AF ; ondeggio
	dc.b	$B2,$B4,$B7,$BA,$BD,$BF,$C2,$C5,$C7,$CA,$CC,$CE ; 200 valori
	dc.b	$D1,$D3,$D5,$D7,$D9,$DB,$DD,$DF,$E0,$E2,$E3,$E5
	dc.b	$E6,$E7,$E9,$EA,$EB,$EC,$EC,$ED,$EE,$EE,$EF,$EF
	dc.b	$EF,$EF,$F0,$EF,$EF,$EF,$EF,$EE,$EE,$ED,$EC,$EC
	dc.b	$EB,$EA,$E9,$E7,$E6,$E5,$E3,$E2,$E0,$DF,$DD,$DB
	dc.b	$D9,$D7,$D5,$D3,$D1,$CE,$CC,$CA,$C7,$C5,$C2,$BF
	dc.b	$BD,$BA,$B7,$B4,$B2,$AF,$AC,$A9,$A6,$A3,$A0,$9D
	dc.b	$9A,$97,$94,$91,$8E,$8B,$88,$85,$82,$7F,$7C,$79
	dc.b	$76,$73,$70,$6D,$6A,$68,$65,$62,$5F,$5D,$5A,$57
	dc.b	$55,$52,$50,$4E,$4B,$49,$47,$45,$43,$41,$3F,$3D
	dc.b	$3C,$3A,$39,$37,$36,$35,$33,$32,$31,$30,$30,$2F
	dc.b	$2E,$2E,$2D,$2D,$2D,$2D,$2C,$2D,$2D,$2D,$2D,$2E
	dc.b	$2E,$2F,$30,$30,$31,$32,$33,$35,$36,$37,$39,$3A
	dc.b	$3C,$3D,$3F,$41,$43,$45,$47,$49,$4B,$4E,$50,$52
	dc.b	$55,$57,$5A,$5D,$5F,$62,$65,$68,$6A,$6D,$70,$73
	dc.b	$76,$79,$7C,$7F,$82,$85,$88,$8B
FINETABY:

