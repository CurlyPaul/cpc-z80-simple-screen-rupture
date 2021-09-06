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

loop:
; int 1
	call WaitFrame

	ld bc,&bc07			;Vertical Sync position (VSYNC)
	out (c),c
	ld bc,&bdff			;Set VSCYNC=255 (Impossible...Disables Vsync)
	out (c),c

;; This is VDISP and controls if borders are to be displayed by alternating between 255 and 0?
;; Don't fully understand the values I've seen people use, but seems crucial for keeping the screen stable if it is less than fullscreen
;	ld bc,&BC06
;	out (c),c
;	ld bc,&BD00
;	out (c),c

	call SetScreenBottom
	
	ld a,(Ticker)
	inc a
	ld (Ticker),a

	bit 2,a
	jr z, checkForPalette2
	call SetPalette1	
	jr waitForBeam
checkForPalette2:
	call SetPalette2
waitForBeam:
	
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

	ld bc,&bc07			;Vertical Sync position (VSYNC)
	out (c),c
	ld bc,&bd00			;Set VSCYNC=0 now!
	out (c),c

;; TODO Wait here for a while before calling draw letter
;; 13471 clock cycles to draw a letter
	call DrawLetter
jr loop

DrawLetter:

	ld de,(C2)
	ld bc, &1020 ;; X Y
	call GetScreenPosition
	ld b,10
	ld c,25
	call DrawSprite
ret
	
DrawSprite:
	;; Inputs: 
	;; 	DE - Frame address
	;; 	HL - Screen address 	
	;; 	B  - Lines per sprite
	;; 	C  - Bytes per line
	SpriteNextLine:
		push hl
		push bc
	SpriteNextByte:
			ld a,(de)	; Sourcebyte	
			ld (hl),a	; Screen desintation

			inc de
			inc hl
			dec c
			jr nz,SpriteNextByte
		pop bc
		pop hl
	call GetNextLine 		; expected - c051, C0A1, C0F1.. last C9e1
	djnz SpriteNextLine 		; djnz - decreases b and jumps when it's not zero
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

defb &44 ;; #0 Darkest Blue 
defb &4A ;; #1 Yellow 
defb &57 ;; #2 
defb &5B ;; #3 
defb &4B ;; #4 White
defb &54 ;; #5 Black
defb &53 ;; #6
defb &5E ;; #7 
defb &58 ;; #8 
defb &5D ;; #9 
defb &5F ;; #10 
defb &5B ;; #11 
defb &4B ;; #12 
defb &4C ;; #13
defb &54 ;; #14 
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

ScreenStartAddressFlag: db 48
BackBufferAddress: dw &8000
Ticker: db &00

;;********************************************************
;; Imports
;;********************************************************
read ".\libs\CPC_V2_SimpleScreenSetUp.asm"
read ".\libs\CPC_V2_SimplePalette.asm"

read ".\res\C2.asm"

org &8000
read ".\res\bottom.asm"

org &C000
read ".\res\top.asm"