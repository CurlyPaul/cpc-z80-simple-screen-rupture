org &4000
run start

start:
call Screen_Init
call Palette_Init

di

ld a,&C3
ld (&0038),a
ld hl,InterruptHandler1
ld (&0039),hl

call InitCRTC

;;****************************************************
;; Draw out some initial screens in memory
;;****************************************************
;; Draws a rectangle 96 (12 chars) lines high
;; 9408 Bytes
;; C000, C0001.. C0062
;; C800, C8001
ld hl,&C000
ld b,96
loopLine:
	push bc
		ld b,96 ;; B * 2 = pixels
		push hl
		loopRow:
			ld a,%11001100
			ld (hl),a
			inc hl
			djnz loopRow
			;; next line will be currentLineNumber + &0800
			;; this is still true even with a malformed screen
		pop hl
	pop bc
	ld de,&0800
	add hl,de
	bit 7,h
	jr nz,_loopLineDone
		ld de,&C062
		add hl,de
_loopLineDone:
	djnz loopLine	


;; Now do the same again, in &8000 using a different colour
ld hl,&8000
ld b,96
loopLine1:
	push bc
		ld b,96 ;; B * 2 = pixels
		push hl
		loopRow1:
			ld a,%00001111
			ld (hl),a
			inc hl
			djnz loopRow1
			;; next line will be currentLineNumber + &0800
			;; this is still true even with a malformed screen
		pop hl
	pop bc
	ld de,&0800
	add hl,de
	bit 6,h
	jr z,_loopLineDone1
		ld de,&C062
		add hl,de
_loopLineDone1:
	djnz loopLine1	

ei

loop:
; int 1
	call WaitFrame

	ld bc,&bc07			;Vertical Sync position (VSYNC)
	out (c),c
	ld bc,&bdff			;Set VSCYNC=255 (Impossible...Disables Vsync)
	out (c),c

;	ld bc,&BC06
;	out (c),c
;	ld bc,&BD00
;	out (c),c

	call SetScreenBottom

; int 2
	halt
; int 3
	halt	
; int 4 
	halt
; int 5
	halt
; int 6
	halt
	call SetScreenTop

;ld bc,&BC06
;out (c),c
;ld bc,&BD00
;out (c),c
	

	ld bc,&bc07			;Vertical Sync position (VSYNC)
	out (c),c
	ld bc,&bd00			;Set VSCYNC=0 now!
	out (c),c

jr loop

WaitFrame:                                
         ld bc,#F500	;; PPI Rastor port
         in a,(c)
         rra  		;; Right most bit indicates vSync is happening
         jr nc, WaitFrame
ret

InterruptHandler1:
	exx
	ex af,af'
		ld a,&C3
		ld (&0038),a
		ld hl,InterruptHandler2
		ld (&0039),hl

		ld bc,&7F00 + 17
		ld a,&58
     		out (c),c	;; PENR:&7F{pp} - where pp is the palette/pen number 
		out (c),a	
	ex af,af'
	exx
	ei
ret


InterruptHandler2:
	exx
	ex af,af'
		ld a,&C3
		ld (&0038),a
		ld hl,InterruptHandler1
		ld (&0039),hl

		ld bc,&7F00 + 17
		ld a,&57
     		out (c),c	;; PENR:&7F{pp} - where pp is the palette/pen number 
		out (c),a
	ex af,af'
	exx
	ei
ret

InitCRTC:

;; R0 is the overall frame width, not the display width
;;R0 = 63 (value - 1)
ld bc,&BC00
out (c),c
ld bc,&BD3F
out (c),c

;; R1 is the display width
;;R1 = 40 (value)
ld bc,&BC01
out (c),c
ld bc,&BD00+49
out (c),c


;; MR - Maximum raster address - Scanlines per character row
;;R9 = 7 (value-1)
ld bc,&BC09
out (c),c
ld bc,&BD07
out (c),c

;; R6 * R9+1 = 200

;; Set the HSYNC, again in chars
ld bc,&BC02
out (c),c
ld bc,&BD00+50
out (c),c

;; 06 VDISP Vertical Displayed in characters
;ld bc,&BC06
;out (c),c
;ld bc,&BD00+12 ;; Heigth in chars
;out (c),c

ret

SetScreenTop:
	;; VTOT - Vertical total - number of character rows for the full frame 
	;;R4 = 38 (value - 1)
	ld bc,&BC04
	out (c),c
	ld bc,&BD00+10
	out (c),c

	ld bc,&BC0C ;; R10 DISPH Display start address
	out (c),c
	ld bc,&BD00+48 ;; &C000
	out (c),c
ret

SetScreenBottom:

	ld bc,&BC04
	out (c),c
	ld bc,&BD00+28
	out (c),c

	ld bc,&BC0C ;; R10 DISPH Display start address
	out (c),c
	ld bc,&BD00+32 ;; &8000
	out (c),c

ret

ScreenStartAddressFlag: db 48
BackBufferAddress: dw &8000

;;********************************************************
;; Imports
;;********************************************************
read ".\libs\CPC_V2_SimpleScreenSetUp.asm"
read ".\libs\CPC_V2_SimplePalette.asm"