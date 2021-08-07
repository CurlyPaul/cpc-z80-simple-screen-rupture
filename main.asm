org &4000
run start

start:
call Screen_Init
di

;; I'm over the maximum width here
;; 98 wide, and 21*8 height puts me at address 80A 
;; for the starting point of line two, breaking the 800 line rule


;; Create the smallest possible interrupt handler
im 1
ld hl,&C9FB			;; C9 FB are the bytes for the Z80 opcodes EI:RET
ld (&0038),hl			;; setup interrupt handler

;call Palette_Init
call InitCRTC

;; Note we need to change the screen mode with the PPI as the 
;; firmware no longer works for us
ld bc,&7F00+128+4+8+0
out (c),c

;;****************************************************
;; Draw out some initial screens in memory
;;****************************************************
;; Draws a rectangle 96 (12 chars) lines high
;; 9408 Bytes
;; C000, C0001.. C0062
;; C800, C8001
;ld hl,&C000
;ld b,160
;loopLine:
;	push bc
;		ld b,96 ;; B * 2 = pixels
;		push hl
;		loopRow:
;			ld a,%00001100
;			ld (hl),a
;			inc hl
;			djnz loopRow
			;; next line will be currentLineNumber + &0800
			;; this is still true even with a malformed screen
;		pop hl
;	pop bc
;	ld de,&0800
;	add hl,de
;	bit 7,h
;	jr nz,_loopLineDone
;		ld de,&C062
;		add hl,de
;_loopLineDone:
;	djnz loopLine	

	;ld hl,&8000
	;ld d,h
	;ld e,l
	;inc de
	;ld bc,&3DFF		;; Number of bytes to clear
	;ld (hl),&00
	;ldir	

;; Now do the same again, in &8000 using a different colour
;ld hl,&8000
;ld b,1
;loopLine1:
;	push bc
;		ld b,96 ;; B * 2 = pixels
;		push hl
;		loopRow1:
;			ld a,&30
;			ld (hl),a
;			inc hl
;			djnz loopRow1
			;; next line will be currentLineNumber + &0800
			;; this is still true even with a malformed screen
;		pop hl
;	pop bc
;	ld de,&0800
;	add hl,de
;	bit 6,h
;	jr z,_loopLineDone1
;		ld de,&C062
;		add hl,de
;_loopLineDone1:
;	djnz loopLine1	

ei

loop:
; int 1
	call WaitFrame

	ld bc,&bc07			;Vertical Sync position (VSYNC)
	out (c),c
	ld bc,&bdff			;Set VSCYNC=255 (Impossible...Disables Vsync)
	out (c),c
;; This is VDISP and controls if borders are to be displayed by alternating between 255 and 0? Don't fully understand
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

;	ld bc,&BC06
;	out (c),c
;	ld bc,&BD00
;	out (c),c
	
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

ret

SetScreenTop:
	;; VTOT - Vertical total - number of character rows for the full frame 
	;;R4 = 38 (value - 1)
	ld bc,&BC04
	out (c),c
	ld bc,&BD00+19
	out (c),c

	ld bc,&BC0C ;; R10 DISPH Display start address
	out (c),c
	ld bc,&BD00+48 ;; &C000
	out (c),c
ret

SetScreenBottom:

	ld bc,&BC04
	out (c),c
	ld bc,&BD00+19
	out (c),c

	ld bc,&BC0C ;; R10 DISPH Display start address
	out (c),c
	ld bc,&BD00+32 ;; &8000
	out (c),c

ret

ScreenStartAddressFlag: db 48
BackBufferAddress: dw &8000

;;********************************************************
;; Imports
;;********************************************************
read ".\libs\CPC_V2_SimpleScreenSetUp.asm"
read ".\libs\CPC_V2_SimplePalette.asm"

org &8000
;read ".\screentest.asm"
read ".\bottom1.asm"

org &C000
read ".\top.asm"