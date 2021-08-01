;;*****************************************************************************************
;; Origially based on examples in the zip file found at https://www.chibiakumas.com/z80/
;;
;; Public entry points:
;;
;;	- Screen_Init
;;	- GetScreenPos
;;	- GetNextLine
;; 	- SwitchScreenBuffer
;;
;; Label expectations:
;; 	- ScreenStartAddressFlag
;;	- BackBufferAddress
;;
;;*****************************************************************************************
ScreenSize equ &4000
CRTC_4000 equ 16
CRTC_8000 equ 32
CRTC_C000 equ 48

CRTCOptions:
	defb &3f	; R0 - Horizontal Total
	defb 32	 	; R1 - Horizontal Displayed  (32 chars wide)
	defb 42		; R2 - Horizontal Sync Position (centralises screen)
	defb &86	; R3 - Horizontal and Vertical Sync Widths
	defb 38		; R4 - Vertical Total
	defb 0		; R5 - Vertical Adjust
	defb 24		; R6 - Vertical Displayed (24 chars tall)
	defb 31		; R7 - Vertical Sync Position (centralises screen)
	defb 0		; R8 - Interlace
	defb 7		; R9 - Max Raster 
	defb 0		; R10 - Cursor (not used)
	defb 0		; R11 - Cursor (not used)
	defb &30	; R12 - Screen start (start at &c000)
	defb &00 	; R13 - Screen start

Screen_Init:
	;; Sets the screen to 16 colour/160 wide mode
	ld a,0
	call &BC0E	; scr_set_mode 0 - 16 colors
ret


GetScreenPos:
	;; Inputs: BC - X Y
	;; Returns HL : screen memory locations
	;; Destroys BC

	;; Calculate the ypos first
	ld hl,scr_addr_table	; load the address of the label into h1

	;; Now read two bytes from the address held in hl. We have to do this one at a time
	ld a,c
	add   a, l    ; A = A+L
	ld    l, a    ; L = A+L	
   	adc   a, h    ; A = A+L+H+carry
    	sub   l       ; A = H+carry
    	ld    h, a    ; H = H+carry

	ld a,c
	add   a, l    ; A = A+L
   	ld    l, a    ; L = A+L	
    	adc   a, h    ; A = A+L+H+carry
    	sub   l       ; A = H+carry
    	ld    h, a    ; H = H+carry

	ld a,(hl)		; stash one byte from the address in hl into a
	inc l			; increment the address we are pointing at
	ld h,(hl)		; load the next byte into the address at h into h
	ld l,a			; now put the first byte we read back into l

	;; Now calculate the xpos, this is much easier as these are linear on the screen screen				
	ld a,b				; need to stash b as the next op insists on reading 16bit - we can't to ld c,(label)
	ld bc,(BackBufferAddress)	; bc now contains either &4000 or &C000, depending which cycle we are in
	ld c,a				; bc will now contain &40{x}
	add hl,bc			; hl = hl + bc, add the x and y values together
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
	ld de,&C050
	add hl,de
_getNextLineDone:
ret



SwitchScreenBuffer:
	; Flips all the screen buffer variables and moves the back buffer onto the screen
	ld a,(ScreenStartAddressFlag)
	sub CRTC_8000
	jr nz, _setScreenBase8000
_setScreenBaseC000:
	ld de,CRTC_C000 
	ld (ScreenStartAddressFlag),de
	ld de,&8000
	ld (BackBufferAddress),de
	;; Remember this is the test for drawing to 8000, not C000
	ld hl,&2874		;; Byte code for: Bit 6,JR Z
	ld (_screenBankMod_Minus1+1),hl
	jr _doSwitchScreen
_setScreenBase8000:
	ld de,CRTC_8000
	ld (ScreenStartAddressFlag),de
	ld de,&C000 
	ld (BackBufferAddress),de 
	ld hl,&207C		;; Byte code for: Bit 7,JR NZ
	ld (_screenBankMod_Minus1+1),hl
_doSwitchScreen:
	ld bc,&BC0C 	; CRTC Register to change the start address of the screen
	out (c),c
	inc b
	ld a,(ScreenStartAddressFlag)
	out (c),a
ret

; Each word in the table is the memory address offest for the start of each screen line
; eg line 1 is at 0000 (scr_start_adr +C000 normally)
;    line 2 is at 0800
;    line 3 is at 1000
;    line 4 is at 1800
;    line 5 is at 2000 etc

;; This is the screen address table for a normal width screen
align2
scr_addr_table:
	defb &00,&00, &00,&08, &00,&10, &00,&18, &00,&20, &00,&28, &00,&30, &00,&38;1
	defb &50,&00, &50,&08, &50,&10, &50,&18, &50,&20, &50,&28, &50,&30, &50,&38;2
	defb &A0,&00, &A0,&08, &A0,&10, &A0,&18, &A0,&20, &A0,&28, &A0,&30, &A0,&38;3
	defb &F0,&00, &F0,&08, &F0,&10, &F0,&18, &F0,&20, &F0,&28, &F0,&30, &F0,&38;4
	defb &40,&01, &40,&09, &40,&11, &40,&19, &40,&21, &40,&29, &40,&31, &40,&39;5
	defb &90,&01, &90,&09, &90,&11, &90,&19, &90,&21, &90,&29, &90,&31, &90,&39;6
	defb &E0,&01, &E0,&09, &E0,&11, &E0,&19, &E0,&21, &E0,&29, &E0,&31, &E0,&39;7
	defb &30,&02, &30,&0A, &30,&12, &30,&1A, &30,&22, &30,&2A, &30,&32, &30,&3A;8
	defb &80,&02, &80,&0A, &80,&12, &80,&1A, &80,&22, &80,&2A, &80,&32, &80,&3A;9
	defb &D0,&02, &D0,&0A, &D0,&12, &D0,&1A, &D0,&22, &D0,&2A, &D0,&32, &D0,&3A;10
	defb &20,&03, &20,&0B, &20,&13, &20,&1B, &20,&23, &20,&2B, &20,&33, &20,&3B;11
	defb &70,&03, &70,&0B, &70,&13, &70,&1B, &70,&23, &70,&2B, &70,&33, &70,&3B;12
	defb &C0,&03, &C0,&0B, &C0,&13, &C0,&1B, &C0,&23, &C0,&2B, &C0,&33, &C0,&3B;13
	defb &10,&04, &10,&0C, &10,&14, &10,&1C, &10,&24, &10,&2C, &10,&34, &10,&3C;14
	defb &60,&04, &60,&0C, &60,&14, &60,&1C, &60,&24, &60,&2C, &60,&34, &60,&3C;15
	defb &B0,&04, &B0,&0C, &B0,&14, &B0,&1C, &B0,&24, &B0,&2C, &B0,&34, &B0,&3C;16
	defb &00,&05, &00,&0D, &00,&15, &00,&1D, &00,&25, &00,&2D, &00,&35, &00,&3D;17
	defb &50,&05, &50,&0D, &50,&15, &50,&1D, &50,&25, &50,&2D, &50,&35, &50,&3D;18
	defb &A0,&05, &A0,&0D, &A0,&15, &A0,&1D, &A0,&25, &A0,&2D, &A0,&35, &A0,&3D;19
	defb &F0,&05, &F0,&0D, &F0,&15, &F0,&1D, &F0,&25, &F0,&2D, &F0,&35, &F0,&3D;20
	defb &40,&06, &40,&0E, &40,&16, &40,&1E, &40,&26, &40,&2E, &40,&36, &40,&3E;21
	defb &90,&06, &90,&0E, &90,&16, &90,&1E, &90,&26, &90,&2E, &90,&36, &90,&3E;22
	defb &E0,&06, &E0,&0E, &E0,&16, &E0,&1E, &E0,&26, &E0,&2E, &E0,&36, &E0,&3E;23
	defb &30,&07, &30,&0F, &30,&17, &30,&1F, &30,&27, &30,&2F, &30,&37, &30,&3F;24
	defb &80,&07, &80,&0F, &80,&17, &80,&1F, &80,&27, &80,&2F, &80,&37, &80,&3F;25