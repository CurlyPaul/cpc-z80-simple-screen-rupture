org &4000
write ".\small.bin"

ld hl,&c000
ld d,h
ld e,l
inc de
ld bc,&3DFF		;; Number of bytes to clear
ld (hl),%11110000
ldir