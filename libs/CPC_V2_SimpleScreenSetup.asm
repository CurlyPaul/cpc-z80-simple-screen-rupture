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


GetScreenPosition:
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
	ld bc,&C000	; bc now contains either &4000 or &C000, depending which cycle we are in
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
	push de
		ld de,&C062 ;; Bytes per line
		add hl,de
	pop de
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


;; This is the look up for 98 bytes per row
;; Mode 0 = 50 bytes per row
;; 256*197 = 60 bytes per row
align2
scr_addr_table:
	defw &0000,&0800,&1000,&1800,&2000,&2800,&3000,&3800
	defw &0062,&0862,&1062,&1862,&2062,&2862,&3062,&3862
	defw &00C4,&08C4,&10C4,&18C4,&20C4,&28C4,&30C4,&38C4
	defw &0126,&0926,&1126,&1926,&2126,&2926,&3126,&3926
	defw &0188,&0988,&1188,&1988,&2188,&2988,&3188,&3988
	defw &01EA,&09EA,&11EA,&19EA,&21EA,&29EA,&31EA,&39EA
	defw &024C,&0A4C,&124C,&1A4C,&224C,&2A4C,&324C,&3A4C
	defw &02AE,&0AAE,&12AE,&1AAE,&22AE,&2AAE,&32AE,&3AAE
	defw &0310,&0B10,&1310,&1B10,&2310,&2B10,&3310,&3B10
	defw &0372,&0B72,&1372,&1B72,&2372,&2B72,&3372,&3B72
	defw &03D4,&0BD4,&13D4,&1BD4,&23D4,&2BD4,&33D4,&3BD4
	defw &0436,&0C36,&1436,&1C36,&2436,&2C36,&3436,&3C36
	defw &0498,&0C98,&1498,&1C98,&2498,&2C98,&3498,&3C98
	defw &04FA,&0CFA,&14FA,&1CFA,&24FA,&2CFA,&34FA,&3CFA
	defw &055C,&0D5C,&155C,&1D5C,&255C,&2D5C,&355C,&3D5C
	defw &05BE,&0DBE,&15BE,&1DBE,&25BE,&2DBE,&35BE,&3DBE
	defw &0620,&0E20,&1620,&1E20,&2620,&2E20,&3620,&3E20
	defw &0682,&0E82,&1682,&1E82,&2682,&2E82,&3682,&3E82
	defw &06E4,&0EE4,&16E4,&1EE4,&26E4,&2EE4,&36E4,&3EE4
	defw &0746,&0F46,&1746,&1F46,&2746,&2F46,&3746,&3F46
	defw &07A8,&0FA8,&17A8,&1FA8,&27A8,&2FA8,&37A8,&3FA8

