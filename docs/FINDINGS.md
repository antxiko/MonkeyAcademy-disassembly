# Findings

What turned up when taking it apart and cannot be seen by playing. Each item
with its address; what was measured in the emulator, with the measurement.

## The `?` never goes beyond what the first digit is worth

`ELIGE_INCOGNITA` (0x7253) picks the digit to cover by subtracting a random
0-15 from the **value** of the equation's first digit, and takes that as the
position. With a 9 in front the `?` can land on any of the first ten
positions; with a 1 in front, only in the first operand. Measured with 400
level-1 equations in the emulator: 0 exceptions, 238 of 400 with the `?` in
the first two positions and only 67 in the result. The digit that gets hidden
depends on the digit you can see.

## Operands never end in 0 or 1

`OPERANDO` (0x6F45) rolls again until the units come out between 2 and 9. In
400 equations there is not one operand ending in 0 or 1: 3?+7, 82+6, 89+9?…
The result can.

## Division is generated backwards

For level 3 (`DIVISION`, 0x6EDE) no two numbers are divided: D and E are
chosen between 1 and 9, D × E is written, then the division sign, then D, and
the result is E. Division is always exact because it is built from the
quotient. And level 5 does a × ( b + c ) with the multiplication of 0x6EC1:
adding the number to itself b − 1 times, in BCD.

## A random choice of scripts, cancelled with a `xor a`

`GENERA_ECUACION` (0x6FBC) does `call AZAR / and 7 / xor a / call HL_MAS_A`:
it computes a random offset from 0 to 7 and throws it away before using it,
so every level always uses the first script of its table. The table at 0x7117
carries a second pointer per level for those offsets, and it points at the 0
that closes the script itself.

## The five levels are five scripts of three to five bytes

`0A 0E` (+ =), `0B 0E` (− =), `0D 0E` (÷ =), `0C 0E` (× =) and `0C 10 0A 11
0E` (× ( + ) =) at 0x712B: that is all that tells one level from another.
The rest —which operands, how many digits, whether there is a sign— the
generator decides on seeing the symbol. A `jp z,7117h` for symbol 0x0F,
which appears in no script, would jump into the table if it ever came up.

## The 22 sprites are in VRAM twice

INIT copies 0xC0 bytes from 0x56BF to 0x1800 and then 0x2C0 to 0x18C0
without reloading HL: `COPIA_A_VRAM` (0x4894) saves and restores it. The
first six sprites end up at 0-5 and the 22 again at 6-27, and the game uses
the second set: the monkey is pattern 0x18, the crab 0x30. Patterns 0-5 are
overwritten later by whichever sprite set is due (0x6044).

## The professor is the player's monkey, in red

Sprites 8 and 9 (0x7ED9) have the monkey's patterns 0x00 and 0x0C with
colours 6 and 15, and he walks with the same phases (0x7585, 0x758D). The
monkey that brings the answer by balloon on the third miss is the player
too: the climbing patterns mirrored (0xC8/0xCC), arms up holding the balloon,
in cyan and light red (0x6D76).

## The card's edge places itself

`PINTA_TARJETAS` (0x4F42) computes `8c + Y` in A —where the edge should go
according to how far the card has come down— and never uses it: it calls
`PINTA_BLOQUE` with the D it had. But since `PINTA_BLOQUE` (0x6906) returns D
advanced by as many rows as it painted, the edge lands right under the card
anyway. The calculation is redundant and the result is correct.

## Only the third crab jumps, so only it throws fruit

`ACTOR_ANDA_X` (0x616F) only lets type 3 stop at random and set bit 4, which
for a crab is the fire button. Since jumping is the only way to grab a
hanging fruit, a fruit carried by a crab always follows the sprite at 0xE0C8
(0x7371): actor 4's, which is type 3's. The code takes it for granted instead
of checking who carries it.

## Sound 0xA1 is silence

The three entries for 0xA1 in the table at 0x7A7B point at the same byte, a
0xFF at 0x7B1B: three mute tracks that shut the three channels. That is what
plays when the title starts and while the monkey is with the professor. And
0xA0 (losing a life) gets in over anything but is recorded as 0x20 (0x7929),
so afterwards whatever comes overrides it.

## The effects belong to the monkey

`SONIDO_DEL_ACTOR` (0x78F7): an effect requested from an actor only plays if
the actor is the monkey, with one exception, number 9, the crab dying. Crab
footsteps, jumps and falls make no sound.

## The crabs speed up by table, not by velocity

There is no velocity: `MONO_Y_CANGREJOS` (0x4850) calls `ACTOR_PASO` for each
crab stage/8 + 1 times per frame, at most four, and one frame in four only
once. And they wait hidden (16 − stage) × 16 + 17 frames up to stage 19; from
20, one (0x6585).

## READY can be hurried

READY (0x43EE) counts 15 seconds in BCD (0xE242) and starts only on reaching
zero, or earlier with any new button. And LEVEL SELECT (0x762F) waits 0x0F00
frames —64 seconds— and goes on with whatever level was set.

## The random generator reads the BIOS

`AZAR` (0x6F0D) takes a word from the system ROM at 0x0000-0x3FFF, using the
seed as the address, and mixes it with the seed and the R register. The BIOS
serves as a noise table. And the `daa` in the mix leaves the nibbles between
0 and 9: randomness comes out already in BCD.

## There are no credits

There are no initials or names in the binary: only the big KONAMI of tiles
0x16-0x2F, which rises at boot, and the small "©Konami 1984" (0x3A-0x3F),
written under the title and at the foot of the panel.

## Leftovers

A list-driven platform painter (0x664F → 0x6624 → 0x65F8) that does the same
as 0x6685 and nobody calls; eight position lists aligned with the eight
stages (0x67C2) that nothing points at, between the platforms and the fruit;
and 287 bytes of 0xFF at the end.
