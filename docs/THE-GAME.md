# The game

A monkey in a three-storey school, a sum with one digit covered, ten cards
hanging from the platforms and crabs after him. Everything on this page comes
from reading the code that does it and measuring it in the emulator.

## The screen

![Stage 1](imagenes/fase_1.png)

At the top, the equation in big 2×2-tile digits (0x7207), with a `?` on the
digit you have to find. Below, four platforms —the floor, the top one and
two in between, with gaps— and hanging from them the ten cards of the stage,
visible only by their edge (the red 2×2 of 0x5082). Eight fruits hang too,
three flowers decorate, and on the right the panel: TIME, HI, the score, the
lives, STAGE and the ©Konami 1984.

Top right paces the professor, who is the player's monkey sprite in dark red
(0x7ED9). He goes from 0xB8 to 0xE8 and back, one pixel every two frames.

## What to do

1. Stand under a card and jump: if the edge is right above (0x6A1F checks the
   tile at Y+7, X+8), the card slides down three rows and shows its digit.
   You come down with it (state 5) and now hold it (0xE1AF).
2. With the second button (SELECT, or the 0x20 of the demo script) you
   answer: the card blinks five times (0x7760) and its digit is compared with
   the hidden one (0xE1CD). Right: 500 points, sound 0x95, and the card
   closes and **drops to the floor** (0x7899, 0x787E) as a flat yellow sprite
   (0xFC). Wrong: one more crying face on the panel (0xE057) and sound 0x0E;
   **on the third miss** a cyan monkey walks in from the left hanging from a
   balloon, stops under the `?`, the balloon rises and the digit is revealed
   (0x6D27): you lose a life.
3. Pick up the fallen card (0x6ABB): the monkey carries it overhead (sprite
   set 2, 0x5BFF) and a red arrow blinks at row 6, column 23 (0x6CA6): take it
   up to the professor.
4. Touch the professor with it (0x6ADB): the card rises to the top on its
   own, 500 more points, the professor walks it to the `?` and writes it in
   (0x74D5), goes back to his spot and both dance with the big face (0x6DFC).
   Three equations like that and the stage is cleared: the time left turns
   into points, 10 per second (0x77ED).

In between, the crabs.

## Moving

Left and right walk (state 2, one pixel per step, sound 3 every four). Fire
jumps: with no direction, straight up (state 3, the 24-delta table of 0x6423:
up 3 3 3 2 1 1 1 0 1 0 1 0 and down 0 1 0 1 0 1 1 1 2 3 3 3, one every two
frames); with a direction and more than 12 pixels from the edge, up through a
gap (state 4): it climbs four pixels a frame moving one pixel sideways, and
if it finds a platform less than 17 pixels above that covers it (0x696B) it
gets on. Otherwise it falls. Walk off a platform's edge and you fall (state
6), four pixels a frame.

There are no ladders: you go up through the gaps and down over the edges.

## The crabs

Three more actors, with the same states as the monkey (0x602E) and their type
in the low nibble of +0x5B: 1, 2 and 3. All three start hidden with timers of
0x20, 0x40 and 0x60 (0x4B24), appear at the top centre (Y = 0x10, X = 0x60),
lower themselves through the top platform (state 7, one pixel every four
frames while the tile is not empty) and drop to the first floor.

- **Type 1** walks to an edge and falls off.
- **Type 2** thinks about it at the edge: half the time it falls, half it
  turns round.
- **Type 3** is the only one that jumps (0x616F: when the random byte at
  0xE140 comes out zero it sets bit 4, which for a crab is the fire button),
  and so the only one that can grab a hanging fruit and throw it at you.
- **From stage 18** the first one is type 4 (0x47E9: 0x44) and patrols the
  second platform: at the edge it turns round if it is at that height
  (Y = 0x38) and otherwise lets itself fall to it.

How many times per frame they move depends on the stage (0x4850): stage/8 +
1, at most 4, and one frame in four only once. And how long they wait hidden
before coming back: (16 − stage) × 16 + 17 frames up to stage 19, one from
stage 20 (0x6585). Reaching the left edge of the floor they leave through it
(0x61C2).

If one touches you within 16 pixels (0x69B0): scared face (0x65AE), sound
0xA0 and one life less.

## The fruit

Eight per stage (0x6806): apples (0xF8), bananas (0x78) and grapes (0x7C),
hanging in rows 3, 10 and 17. You pick one by **jumping** into it (0x5FA7):
100 points, sound 7, and the monkey carries it on his head (bits 2-3 of
0xE260, sprite set 1 with the arms up). With a fruit on his head fire does
not jump: it **throws** it the way he faces (state 8, 0x64EA), and the fruit
flies along one of the two arcs of 0x742F/0x7451, eight steps and then falls.

A fruit in the air kills whatever it hits: a crab, which dies showing a white
"500" for 0x20 frames (0x5FF5); or the monkey, who loses a life (0x5FE8).
Type 3 crabs do exactly the same to you. Landing on a fruit from above knocks
it down (0x6496), and one that leaves the screen disappears.

## Time, lives and points

Each life starts with **5:00** on the clock (0x47E1) and loses a second every
64 frames (0x6CC6); under ten seconds the 0x0C warning sounds every frame,
and at zero the life is lost. Coming back to play, if less than 0:30 was left
it is set to 0:30 (0x6CEF). Clearing the stage counts the clock down into
points, one second every four frames, and back to 5:00.

Three lives (0x47E1). One more every 20,000 points (0x4974: 0xE052 holds the
ten-thousands of the next one), sound 0x10. Points: 100 a fruit picked, 500 a
crab, 500 the right answer, 500 for delivering it, 10 per second left over.
The high score lives at 0xE040 and is painted at once.

## The levels

At the start of the game, and again after every stage cleared, LEVEL SELECT
appears: keys 1 to 5 (0x765F), a minute of waiting and it goes on with
whatever was set. Each player picks their own (0xE153/0xE154). The level is
the script of the equation (0x7117):

| level | script | shape | measured example |
|---|---|---|---|
| 1 | `0A 0E` | A + B = R | 89+9?=188 |
| 2 | `0B 0E` | A − B = R, signed if negative | 89−9?=−10 |
| 3 | `0D 0E` | (D × E) ÷ D = E | 72÷?=9 |
| 4 | `0C 0E` | A × b = R, b one digit | ?3×3=129 |
| 5 | `0C 10 0A 11 0E` | a × ( b + c ) = R, all one digit | 7×(?+4)=56 |

A and B are two BCD digits with units between 2 and 9. The digit that gets
covered is chosen by subtracting a random 0-15 from the **value** of the
first digit of the equation (0x7253), so it never falls beyond that position:
with a 1 in front the `?` is always in the first operand, and in 400 sampled
equations only 67 have it in the result.

## The title and the demo

At boot the KONAMI rises from row 21 (0x6C42), VIDEO CARTRIDGE appears, and
the "Monkey Academy" sign is painted **one pixel row at a time** (0x4C77)
into tiles 0xB8-0xFF with three colour bands. Below, PLAY SELECT: 1 and 2
with joystick, 3 and 4 with keyboard, for one or two players. Touch nothing
and after 256 frames the demo starts: the equation 3 + ? = 5, with the digit
2 hidden, played by the 120-byte script at 0x4B78, one input every eight
frames.

With two players they alternate on losing a life (state 14 swaps
0xE050-0xE06F with 0xE080-0xE09F), each with their own joystick (0x4905 picks
the port), their own cards and their own equation.
