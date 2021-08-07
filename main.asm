org &4000
run start

start:
call Screen_Init
di

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
read ".\res\bottom1.asm"

org &C000
read ".\res\top.asm"