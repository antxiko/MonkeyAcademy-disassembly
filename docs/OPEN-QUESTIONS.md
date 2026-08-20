# Open questions

What the binary does not settle on its own. The whole cartridge is explained
byte by byte; this is what remains to be measured or decided.

## What the eight lists at 0x67C2 are

Between the platforms and the fruit there are eight lists of X positions
ending in 0xFF, one per stage, and no instruction in the trace points at
them. By their place and shape they look like an earlier layout of flowers
or fruit that went unused. No instruction that reads them has been found in
the trace.

## The cancelled random choice of scripts

`GENERA_ECUACION` computes a random offset from 0 to 7 to choose among
several scripts per level and discards it with a `xor a`. The offset tables
that remain are one byte long, so today there is one script per level.
Whether there were ever more, or whether the `xor a` is what left level 5
with its single five-symbol script, the binary does not say.

## How long a full game lasts

The stage is BCD and `PINTA_FASE` (0x4A24) resets it to 0 on reaching 100,
and the tables of platforms, cards and fruit are indexed by (stage − 1) & 7,
so the eight stages repeat. What grows is how many crabs are in play (one up
to stage 7, two from stage 8 to 15, all three from stage 16; 0x4850) and how
little they wait hidden (from stage 20, one frame). It remains to actually
play that far to see whether the game becomes unplayable before that or
whether the wrap to stage 0 has any effect the code does not show. One
measurement so far: a novice player's game, at levels 4 and 5, lasted 5 min
37 s from LEVEL SELECT to GAME OVER, with one stage cleared and 8,360 points
(replay in `work/omsx/partida`).

## The demo's fixed script against random crabs

`ESTADO_6_DEMO_MONTA` (0x42FF) puts digits 2 to 7 in cards 4 to 9, leaves 0
to 3 with digit 0, and the hidden digit is 2. The input script at 0x4B78
takes the demo to the right card, but what happens if the fruit or the crabs
—which are random— push it off course has not been checked: the script is
fixed and the crabs are not.
