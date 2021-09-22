org &4000
run start

start:

call Screen_Init
di

;; Create the smallest possible interrupt handler
im 1
ld hl,&C9FB			;; C9 FB are the bytes for the Z80 opcodes EI:RET
ld (&0038),hl			;; setup interrupt handler

call Palette_Init
call InitCRTC
;; Note we need to change the screen mode with the PPI as the 
;; firmware no longer works for us and this seems to be the only way to get 16 colour mode
ld bc,&7F00+128+4+8+0
out (c),c

ei

call SetPalette1

loop:
; int 1
	call WaitFrame
	;; from here I have 16810 clock cycles before I need to force the vsync

	ld bc,&bc07			;Vertical Sync position (VSYNC)
	out (c),c
	ld bc,&bdff			;Set VSCYNC=255 (Impossible...Disables Vsync)
	out (c),c

;; This is VDISP and controls if borders are to be displayed by alternating between 255 and 0?
;; Don't fully understand the values I've seen people use, but seems crucial for keeping the screen stable if it is less than fullscreen
	;ld bc,&BC06
	;out (c),c
	;ld bc,&BD00+25
	;out (c),c

	call SetScreenBottom
	
	ld hl, &C200	;; Screen address of X+Width,Y
	ld de,CEE2
	ld iyl,80		;; Total lines 88, currenlty all minus 1 to allow me to debug
	call DrawSprite
	;; 281 per line
	;; 90 lines = 
	;nop
; int 2 
	;halt
	;nop
; int 3
;; draw the first chunk of the next letter
	
	;halt
	;nop	
; int 4
	;ld iyl,10
	;call DrawSprite

	;nop
	;halt
	;nop
	;nop
; int 5
	;ld iyl,11
	;call DrawSprite

	;halt
	;nop

	;ld iyl,11
	;call DrawSprite
; int 6
	nop
	halt
	nop
	call SetScreenTop

	ld bc,&bc07			;Vertical Sync position (VSYNC)
	out (c),c
	ld bc,&bd00			;Set VSCYNC=0 now!
	out (c),c

jr loop

DrawSprite:
	;; Inputs: 
	;; 	DE - Frame address source
	;; 	HL - Screen address destination	
	;;      IYL - Lines to draw
	;; 	Bytes per line is unfurled at 18	
	;; Advances
	;;	HL
	;; 	DE
	;; Destroys
	;; 	BC
	
	ld bc,maskLookupTable

	SpriteNextLine:	
		push hl
			ld a,(de)	; 1 Sourcebyte
			ld c,a
			ld a,(bc)	;; A now contains the mask corresponding to the byte we are drawing
			and (hl)	;; Preserve parts according the mask
			or c		;; Combine with the byte we are drawing	
			ld (hl),a
			inc de
			inc hl

			ld a,(de)	
			ld c,a
			ld a,(bc)	
			and (hl)	
			or c		
			ld (hl),a
			inc de
			inc hl

			ld a,(de)	
			ld c,a
			ld a,(bc)	
			and (hl)	
			or c		
			ld (hl),a
			inc de
			inc hl

			ld a,(de)	
			ld c,a
			ld a,(bc)	
			and (hl)	
			or c		
			ld (hl),a
			inc de
			inc hl

			ld a,(de)	
			ld c,a
			ld a,(bc)	
			and (hl)	
			or c		
			ld (hl),a
			inc de
			inc hl

			ld a,(de)	
			ld c,a
			ld a,(bc)	
			and (hl)	
			or c		
			ld (hl),a
			inc de
			inc hl

			ld a,(de)	
			ld c,a
			ld a,(bc)	
			and (hl)	
			or c		
			ld (hl),a
			inc de
			inc hl

			ld a,(de)	
			ld c,a
			ld a,(bc)	
			and (hl)	
			or c		
			ld (hl),a
			inc de
			inc hl

			ld a,(de)	
			ld c,a
			ld a,(bc)	
			and (hl)	
			or c		
			ld (hl),a
			inc de
			inc hl

			ld a,(de)	
			ld c,a
			ld a,(bc)	
			and (hl)	
			or c		
			ld (hl),a
			inc de
			inc hl

			ld a,(de)	
			ld c,a
			ld a,(bc)	
			and (hl)	
			or c		
			ld (hl),a
			inc de
			inc hl

			ld a,(de)	
			ld c,a
			ld a,(bc)	
			and (hl)	
			or c		
			ld (hl),a
			inc de
			inc hl

			ld a,(de)	
			ld c,a
			ld a,(bc)	
			and (hl)	
			or c		
			ld (hl),a
			inc de
			inc hl

			ld a,(de)	
			ld c,a
			ld a,(bc)	
			and (hl)	
			or c		
			ld (hl),a
			inc de
			inc hl

			ld a,(de)	
			ld c,a
			ld a,(bc)	
			and (hl)	
			or c		
			ld (hl),a
			inc de
			inc hl

			ld a,(de)	
			ld c,a
			ld a,(bc)	
			and (hl)	
			or c		
			ld (hl),a
			inc de
			inc hl

			ld a,(de)	
			ld c,a
			ld a,(bc)	
			and (hl)	
			or c		
			ld (hl),a
			inc de
			inc hl

			ld a,(de)	
			ld c,a
			ld a,(bc)	
			and (hl)	
			or c		
			ld (hl),a
			inc de
			inc hl
		pop hl
		
	call GetNextLine 		; expected - c051, C0A1, C0F1.. last C9e1
	
	dec iyl
	jp nz,SpriteNextLine
ret


WaitFrame:                                
         ld bc,#F500	;; PPI Rastor port
         in a,(c)
         rra  		;; Right most bit indicates vSync is happening
         jr nc, WaitFrame
ret

SetPalette1:
	ld hl,ColourPalette1
	call SetupColours
ret

SetPalette2:
	ld hl,ColourPalette2
	call SetupColours
ret

ColourPalette1: ; hardware colours

defb &4D ;; #0 Magenta 
defb &4A ;; #1 Yellow 
defb &57 ;; #2 
defb &5B ;; #3 
defb &4B ;; #4 White
defb &54 ;; #5 Black
defb &53 ;; #6
defb &5E ;; #7 
defb &58 ;; #8 
defb &54 ;; #9 
defb &55 ;; #10 
defb &5B ;; #11 
defb &53 ;; #12 
defb &5f ;; #13
defb &57 ;; #14 
defb &46 ;; #15 
defb &46 ;; Border

ColourPalette2: ; hardware colours

defb &44 ;; #0 Darkest Blue 
defb &4A ;; #1 Yellow 
defb &57 ;; #2  
defb &5B ;; #3 
defb &4B ;; #4 White
defb &54 ;; #5 Black
defb &53 ;; #6
defb &5E ;; #7 
defb &58 ;; #8 Darkest Purple
defb &5D ;; #9 Purple
defb &5F ;; #10 Purple
defb &5B ;; #11 Brightest Purple (actually blue looks best here)
defb &4B ;; #12 Another white
defb &4C ;; #13
defb &54 ;; #14 Black
defb &46 ;; #15 Background
defb &46 ;; Border




InitCRTC:

;; R0 is the overall frame width, not the display width
;;R0 = 63 (value - 1)
ld bc,&BC00
out (c),c
ld bc,&BD3F
out (c),c

;; R1 is the display width in chars
ld bc,&BC01
out (c),c
ld bc,&BD00+49 ;; 49 * 4 = 196 pixels
out (c),c


;; MR - Maximum raster address - Scanlines per character row
;;R9 = 7 (value-1)
ld bc,&BC09
out (c),c
ld bc,&BD07
out (c),c

;; Set the HSYNC, again in chars
;; Hysnc + HsyncWid (R03) < HTOT (R0)
ld bc,&BC02
out (c),c
ld bc,&BD00+50
out (c),c

ret

SetScreenTop:
	;; VTOT - Vertical total - number of character rows for the full frame 
	;;R4 = 20 (value - 1)
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

	;; R4 = 19 (value - 1)
	ld bc,&BC04
	out (c),c
	ld bc,&BD00+19
	out (c),c

	ld bc,&BC0C ;; R10 DISPH Display start address
	out (c),c
	ld bc,&BD00+32 ;; &8000
	out (c),c

ret

ScreenStartAddressFlag: db 48
BackBufferAddress: dw &8000
Ticker: db &00
StackBackUp: dw 0

;;********************************************************
;; Imports
;;********************************************************
read ".\libs\CPC_V2_SimpleScreenSetUp.asm"
read ".\libs\CPC_V2_SimplePalette.asm"

align 256
.maskLookupTable ; lookup table for masks, indexed by sprite byte. AND with screen data, then OR with pixel data.
defb &FF,&AA,&55,&00,&AA,&AA,&00,&00,&55,&00,&55,&00,&00,&00,&00,&00,&AA,&AA,&00,&00,&AA,&AA,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
defb &55,&00,&55,&00,&00,&00,&00,&00,&55,&00,&55,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
defb &AA,&AA,&00,&00,&AA,&AA,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&AA,&AA,&00,&00,&AA,&AA,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
defb &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
defb &55,&00,&55,&00,&00,&00,&00,&00,&55,&00,&55,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
defb &55,&00,&55,&00,&00,&00,&00,&00,&55,&00,&55,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
defb &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
defb &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00

.CEE
incbin ".\res\cee.bin"

.ARR
incbin ".\res\arr.bin"

.TEE
incbin ".\res\tee.bin"

.CEE2
incbin ".\res\cee2.bin"

org &8000
incbin ".\res\bottom.bin"

org &C000
incbin ".\res\top.bin"