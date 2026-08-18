# Getting started

## What you need

`pasmo` and `z80dasm` to assemble and disassemble, and Python 3 for the
tools. Nothing else.

The cartridge is not distributed with this repository: you need your own
copy, named `monkey.rom` in the project root. It is exactly 16384 bytes with
this sha256:

    fdf62cfa6db239fcaa3614b56263dd58e8797b206663e491588c062220b16b01

With any other dump the listing will not reassemble. `make comprueba` tells
you in one line.

## The commands

```sh
make          # trace, generate the listing and check everything
make verify   # assemble the listing and compare its sha256 with the cartridge
make sanity   # what reassembly cannot catch
make test     # the 17 tests on the listing, which do not need the cartridge
make web      # the pictures and these pages
```

`make` chains the first four. If all goes well, the line that matters is
this one:

```
  ensamblado : 16384 bytes  fdf62cfa...20b16b01
  original   : 16384 bytes  fdf62cfa...20b16b01
OK: reproducible byte a byte
```

## What is in each folder

| | |
|---|---|
| `src/monkey.asm` | the commented listing, generated; never edited by hand |
| `src/monkey.notes` | the annotations: labels, comments, headers and data ranges, anchored to addresses |
| `src/monkey.entries` | the entry points the trace cannot deduce, each with its justification |
| `src/monkey.nocode` | the zones the tracer must not read as code |
| `tools/` | the tracer, the listing generator, the checks and the drawing tools |
| `tests/` | 17 tests on the listing and the notes |
| `docs/` | this site |
| `work/` | what `make` produces along the way |

## How to read the listing

Every routine has an uppercase name and a comment saying what it does and
what it takes. Data blocks are labelled `DATA_<use>`, with the width of their
structure, and each has an explanation of what it is and how that is known.
Addresses are the real ones of the cartridge in page 1: 0x4000-0x7FFF.

To change anything, edit `src/monkey.notes` and run `make` again: the listing
is regenerated and the checks say whether it still holds.

## How it was done

The tracer (`tools/z80trace.py`) follows the flow from the header's entry
point and from what `monkey.entries` declares: the interrupt and the targets
of the two dispatchers, which jump through tables. Whatever is not code is
left as a gap, and every gap is closed by finding the instruction that reads
it (`tools/quien_apunta.py`, `tools/refs.py`) and checking the format the
consuming code implies: the two RLE blocks decompress and end exactly on the
byte they should, and the tile lists run to their 0xFF.

What cannot be read is measured. `tools/graficos.py` builds video memory by
repeating INIT's copies and the result matches a dump from the emulator
sprite by sprite; the equation generator was sampled six hundred times in
the emulator to check what the code says about it.

## Reproducibility

- assembling returns the cartridge's sha256
- no range declared as data comes out as code in the trace
- no entry point falls inside a data range
- all 16384 bytes are assigned: 8962 of code, 7422 of data, 0 unidentified
