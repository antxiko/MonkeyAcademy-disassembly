# Monkey Academy (Konami, 1984, MSX1) — a commented disassembly

Konami's arithmetic cartridge for the MSX, taken apart byte by byte. All
16,384 bytes are bounded and explained: not one gap left unjustified, not one
"graphics block", not one guessed table.

📖 **[Full documentation](https://antxiko.github.io/MonkeyAcademy-disassembly/)**

[README en castellano](README.es.md)

---

## What this is

*Monkey Academy* is the RC-702, the Konami cartridge in which a monkey looks
for the missing digit of a sum by opening cards hanging from the platforms
while crabs come after him. Here is its code, commented, with the tools to
build it again and check that what comes out is the original.

The machine maps the 16 KB at 0x4000-0x7FFF —page 1—, the BIOS calls the
entry point at 0x40AF, and from there the program never returns: the boot
writes a `jp` into the H.KEYI hook and drops into a two-byte loop, so **the
whole game runs inside the interrupt**, one step per frame. If a step takes
longer than a frame, the next interrupt plays the music and leaves.

## Why this can be trusted

`make` traces the flow, builds the listing and demands that assembling it
gives back exactly the original:

```
  ensamblado : 16384 bytes  fdf62cfa...20b16b01
  original   : 16384 bytes  fdf62cfa...20b16b01
OK: reproducible byte a byte
```

A listing can reassemble perfectly and still be wrong —read drawings as
instructions and the bytes do not change—, so two more checks run: no range
declared as data may come out as code, and no entry point may fall inside
one.

The graphics are checked a third way. `tools/graficos.py` rebuilds video
memory by repeating the cartridge's own copies, in the same order and at the
same addresses, and the result matches a VRAM dump from the emulator sprite
by sprite. And what the code says about the equation generator has been
measured: six hundred equations sampled in the emulator, across the five
levels.

## The game in numbers

| | |
|---|---|
| bytes of code | 8,962 |
| bytes of data | 7,422 |
| bytes unidentified | **0** |
| named labels | 498 |
| anchored comments | 997 |
| explained data ranges | 121 |

## Some things that turned up

- **The digit that gets hidden depends on the one you can see.** The `?` is
  placed by subtracting a random 0-15 from the *value* of the equation's
  first digit (0x7253): with a 1 in front it never leaves the first operand.
  In 400 measured equations, zero exceptions and only 67 with the `?` in the
  result.
- **Operands never end in 0 or 1**, and division is generated backwards: the
  divisor and the quotient are chosen and their product is written in front
  (0x6EDE). All the arithmetic is BCD, multiplication by repeated addition.
- **Five levels are five scripts** of three to five bytes (0x712B): plus,
  minus, divide, times, and a × ( b + c ). A random choice of alternative
  scripts is cancelled with a `xor a` (0x6FBC).
- **The 22 sprites are in VRAM twice**, because the copy preserves HL
  (0x40CF): the game uses the second set, and the professor is the player's
  monkey in dark red.
- **The fruit is thrown back and forth.** You pick it by jumping, throw it
  with the button along two table-driven arcs, and one in the air kills the
  crab (500) or the monkey. Only the third crab jumps, so only it throws.
- **Sound 0xA1 is silence**: three mute tracks pointing at the same 0xFF. And
  the effects belong to the monkey: crab footsteps and jumps make no sound
  (0x78F7).
- **There are no credits** in the binary: only the big KONAMI that rises at
  boot and the ©Konami 1984 in small tiles.

## Getting started

You need `pasmo`, `z80dasm` and Python 3. The cartridge image is **not**
distributed here: put yours in the root as `monkey.rom`, 16384 bytes, sha256
`fdf62cfa6db239fcaa3614b56263dd58e8797b206663e491588c062220b16b01`.

```sh
make          # trace, build the listing and check everything
make verify   # assemble and compare with the cartridge
make sanity   # what reassembly cannot catch
```

## Licence and attribution

The game is not ours: *Monkey Academy* belongs to Konami, and all rights
remain with their holders. What is ours —the tools, the comments and the
documentation— is published under the licence in `LICENSE`. The cartridge
image is not distributed. See [LEGAL-NOTICE.md](LEGAL-NOTICE.md).
