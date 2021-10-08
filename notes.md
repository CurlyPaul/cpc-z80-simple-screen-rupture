;; 50 frames a second == 66,000 cycles per frame


0.000001 cycle per second
vblank every 1/50 seconds

cycles per vetical blank = (1/50) / 0.000001 = 20,000

;; 3,333 cycles between interrupts
;; Win Ape rougly agrees with 3327 seeming to be the limit before it pops

Basic drawing of a sprite: 27681, no trans
-17000 for precalculated line address

Compiled sprite: 15612, but it's massive, I couldn't fit all the text in memory with both screen

Next things to try...

As a I don't plan on moving them:

- Remove the movenextline calls from the compiled sprite, in favour of hard coded screen addresses, still too huge to hold in memory though

- use &4000 as a back buffer for whichever screen is being animated, and when it's ready, flip it to the screen at the appropiate time
- use load files from disk in order to manage the memory issues? or bank switch?

- Preprocess the sprite as if it were a loading screen? Could this work if it's not filling all the screen? would also need huge amounts of padding to line up the lines

as I don't intend on moving these..

if they were laid out in memory to match the screen::

$4000 line 1 byte 1
$4800 line 2 byte 1

then they would still consume 16k in order to copy them directly. Won't work

but I could precalculate the results of getnextline, which would give me 1700 clock cycles back.

Not enough

Can't do it on one interupt cycle
but I can probably just about do it within a vertical blank

- Have a look at drawing with the SP, can I copy the bytes fast enough before the beam hits the bottom?


** Next plan        

So even with fastest code, I can't draw an entire letter on the screen in one frame

But... have I got time while

drawing screen 8000 (bottom), bank switch C000 out and back buffer in
draw half of it, and bank switch back again before time runs out
does this even work in theory?? 

** even further plan..

How could I animate the background??








