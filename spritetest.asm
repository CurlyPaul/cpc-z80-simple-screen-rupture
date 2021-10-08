org &4000
ld sp,&BFFF

;write ".\raw.bin"

run start
start:
ld hl,&C9FB			;; C9 FB are the bytes for the Z80 opcodes EI:RET
ld (&0038),hl			;; setup interrupt handler


;call &BC0E

ld bc,&7F00+128+4+8+0
out (c),c
call Palette_Init

ld hl,&c000
ld d,h
ld e,l
inc de
ld bc,&3DFF		;; Number of bytes to clear
ld (hl),%11110000
ldir	


xor a
;Build a lookup table for masking sprite bytes
	ld hl,TranspLUT
	ld (hl),%11111111	;Both pixels kept
BuildLutAgain:
	inc l
	jr z,LUTdone		;Done all 256
	ld a,l
	and %01010101		;Right Pixel Mask
	jr nz,BuildLut2
	ld (hl),%01010101	;Mask to keep back Right pixel
	jr BuildLutAgain
BuildLut2
	ld a,l
	and %10101010		;Left Pixel Mask
	jr nz,BuildLutAgain
	ld (hl),%10101010	;Mask to keep back Left pixel
	jr BuildLutAgain
LUTdone:

ld de,CEE
ld hl,&d800
ld ixh,90
call DrawSprite

halt

ld de,ARR
ld hl,&d810
ld ixh,90
call DrawSprite

halt

ld de,TEE
ld hl,&d820
ld ixh,90
call DrawSprite

halt

ld de,CEE2
ld hl,&d831
ld ixh,90
call DrawSprite



halt
loop:
halt
jr loop;

DrawSprite:
	;; Inputs: 
	;; 	DE - Source address
	;; 	HL - Screen address 	
	;; 	IXH  - Lines per sprite
	;; 	IHL  - Bytes per line
	ld bc,transpLUT
	SpriteNextLine:
		push hl
			ld ixl,18	;Bytes per line (Width)
	SpriteNextByte:
			ld a,(de)	; Sourcebyte
			
			ld c,a 		; C now has the source byte, which can of be one of the 256 possible pallete combinations  
			ld a,(bc)	; Which are laid out ready for us starting at the address that is now in BC
			and (hl)	; combine with the desitantion
			or c		; add the new byte
			
			ld (hl),a

			inc de
			inc hl
			dec ixl
			jr nz,SpriteNextByte
		pop hl
	call GetNextLine 		; expected - c051, C0A1, C0F1.. last C9e1
	dec ixh
	jr nz,SpriteNextLine
ret

GetNextLine:
	;; Inputs: HL Current screen memory location
	;; Returns: HL updated to the start of the next line
	ld a,h				; load the high byte of hl into a
	add &08				; it's just a fact that each line is + &0800 from the last one
	ld h,a				; put the value back in h

_screenBankMod_Minus1:
	bit 7,h		;Change this to bit 6,h if your screen is at &8000!
	jr nz,_getNextLineDone
	push de
		ld de,&C050 ;; Bytes per line
		add hl,de
	pop de
_getNextLineDone:
ret

ColourPalette: ; hardware colours

defb &4D ;; #0 Magenta 
defb &4A ;; #1 Yellow 
defb &54 ;; #2 
defb &54 ;; #3 
defb &4B ;; #4 White
defb &54 ;; #5 Black
defb &59 ;; #6 Pastel green
defb &54 ;; #7 
defb &55 ;; #8 
defb &54 ;; #9 
defb &4d ;; #10 
defb &5B ;; #11 
defb &53 ;; #12 
defb &5f ;; #13
defb &57 ;; #14 
defb &46 ;; #15 
defb &46 ;; Border

Palette_Init:
	;; CPC has some quirks here as well, seems to be caused by the ability to flash each colour
	;;
	;; http://www.cpcwiki.eu/forum/programming/screen-scrolling-and-ink-commands/
	;; https://www.cpcwiki.eu/forum/programming/bios-call-scr_set_ink-and-interrupts/
	ld hl,ColourPalette
	call SetupColours
ret


SetupColours:
	;; Inputs: HL Address the palette values are stored
	ld b,17			;; 16 colours + 1 border
	xor a			;; start with pen 0

DoColours:
	push bc			;; need to stash b as we are using it for our loop and need it
				;; below to write to the port 		
		ld e,(hl)	;; read the value of the colour we want into e
		inc hl          ;; move along ready for next time

		ld bc,&7F00
     		out (c),a	;; PENR:&7F{pp} - where pp is the palette/pen number 
		out (c),e	;; INKR:&7F{hc} - where hc is the hardware colour number
	pop bc
	inc a			;; increment pen number
	djnz DoColours
ret

align 256
transpLUT: ds 256

read ".\res\C2.asm"


