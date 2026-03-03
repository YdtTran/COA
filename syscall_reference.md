# MIPS SYSCALL Reference — MARS Simulator

> Source: <https://dpetersanderson.github.io/Help/SyscallHelp.html>

---

## How to Use

```asm
# Step 1: Load service number into $v0
# Step 2: Load arguments into $a0, $a1, $a2, or $f12
# Step 3: Execute syscall
# Step 4: Read return values from result registers
```

**Example** — print value in `$t0`:

```asm
li   $v0, 1          # service 1 = print integer
move $a0, $t0        # argument: integer to print
syscall
```

> Register contents are **not affected** by syscall, except for result registers.

---

## Console I/O

| Code | Service | Arguments | Result |
|------|---------|-----------|--------|
| 1 | Print integer | `$a0` = integer | — |
| 2 | Print float | `$f12` = float | — |
| 3 | Print double | `$f12` = double | — |
| 4 | Print string | `$a0` = address of null-terminated string | — |
| 5 | Read integer | — | `$v0` = integer read |
| 6 | Read float | — | `$f0` = float read |
| 7 | Read double | — | `$f0` = double read |
| 8 | Read string | `$a0` = buffer address, `$a1` = max chars to read | see note |
| 11 | Print character | `$a0` = character (low-order byte) | — |
| 12 | Read character | — | `$v0` = character read |

> **Service 8 note:** Follows UNIX `fgets` semantics. For length `n`, string is at most `n-1` chars; appends newline then null. If `n=1`, input ignored and null written. If `n<1`, nothing written.

### Examples

**Service 1 — Print integer:**

```asm
.text
main:
    li   $t0, 42
    li   $v0, 1          # print integer
    move $a0, $t0        # value to print
    syscall              # outputs: 42
```

**Service 2 — Print float:**

```asm
.data
pi: .float 3.14159

.text
main:
    li   $v0, 2          # print float
    lwc1 $f12, pi        # load float value into $f12
    syscall              # outputs: 3.14159
```

**Service 4 — Print string:**

```asm
.data
msg: .asciiz "Hello, World!\n"

.text
main:
    li   $v0, 4          # print string
    la   $a0, msg        # address of string
    syscall              # outputs: Hello, World!
```

**Service 5 — Read integer:**

```asm
.data
prompt: .asciiz "Enter a number: "

.text
main:
    li   $v0, 4          # print prompt
    la   $a0, prompt
    syscall

    li   $v0, 5          # read integer
    syscall
    move $t0, $v0        # $t0 now holds the entered integer
```

**Service 8 — Read string:**

```asm
.data
buffer: .space 64        # reserve 64 bytes for input
prompt: .asciiz "Enter your name: "

.text
main:
    li   $v0, 4
    la   $a0, prompt
    syscall

    li   $v0, 8          # read string
    la   $a0, buffer     # address of buffer
    li   $a1, 64         # max characters to read
    syscall              # stores input (up to 63 chars + null) in buffer
```

**Service 11 — Print character:**

```asm
.text
main:
    li   $v0, 11         # print character
    li   $a0, 65         # ASCII 65 = 'A'
    syscall              # outputs: A
```

**Service 12 — Read character:**

```asm
.text
main:
    li   $v0, 12         # read character
    syscall
    move $t0, $v0        # $t0 holds the character read (e.g. ASCII code)
```

---

## Memory & Process

| Code | Service | Arguments | Result |
|------|---------|-----------|--------|
| 9 | Allocate heap memory (`sbrk`) | `$a0` = bytes to allocate | `$v0` = address of allocated memory |
| 10 | Exit | — | — |
| 17 | Exit2 (with value) | `$a0` = exit code | see note |

> **Service 17 note:** Exit code in `$a0` is ignored when running under the MARS GUI.

### Examples

**Service 9 — Allocate heap memory:**

```asm
.text
main:
    li   $v0, 9          # sbrk: allocate heap memory
    li   $a0, 100        # number of bytes to allocate
    syscall
    move $t0, $v0        # $t0 = address of the 100-byte block

    # Use $t0 as a pointer to store data
    li   $t1, 255
    sb   $t1, 0($t0)     # store byte 255 at start of allocated block
```

**Service 10 — Exit:**

```asm
.text
main:
    # ... program logic ...
    li   $v0, 10         # exit
    syscall              # program terminates here
```

**Service 17 — Exit with code:**

```asm
.text
main:
    li   $v0, 17         # exit2
    li   $a0, 1          # exit code 1 (e.g. error)
    syscall
```

---

## File I/O

| Code | Service | Arguments | Result |
|------|---------|-----------|--------|
| 13 | Open file | `$a0` = filename address, `$a1` = flags, `$a2` = mode (ignored) | `$v0` = file descriptor (negative if error) |
| 14 | Read from file | `$a0` = fd, `$a1` = buffer address, `$a2` = max chars | `$v0` = chars read (0=EOF, negative=error) |
| 15 | Write to file | `$a0` = fd, `$a1` = buffer address, `$a2` = chars to write | `$v0` = chars written (negative=error) |
| 16 | Close file | `$a0` = file descriptor | — |

**Open file flags (`$a1`):**

| Value | Meaning |
|-------|---------|
| `0` | Read-only |
| `1` | Write-only (create) |
| `9` | Write-only (create + append) |

> File descriptors: `0`=stdin, `1`=stdout, `2`=stderr. MARS allocates user fds from `3` upward.

### File I/O Example

```asm
.data
fout:   .asciiz "testout.txt"
buffer: .asciiz "The quick brown fox jumps over the lazy dog."

.text
    # Open file for writing
    li   $v0, 13
    la   $a0, fout
    li   $a1, 1        # write-only
    li   $a2, 0
    syscall
    move $s6, $v0      # save file descriptor

    # Write to file
    li   $v0, 15
    move $a0, $s6
    la   $a1, buffer
    li   $a2, 44       # number of bytes
    syscall

    # Close file
    li   $v0, 16
    move $a0, $s6
    syscall
```

---

## System & Timing *(MARS only)*

| Code | Service | Arguments | Result |
|------|---------|-----------|--------|
| 30 | System time | — | `$a0` = low-order 32 bits of time (ms since 1 Jan 1970), `$a1` = high-order 32 bits |
| 32 | Sleep | `$a0` = milliseconds to sleep | — |

### Examples

**Service 30 — System time:**

```asm
.text
main:
    li   $v0, 30         # get system time
    syscall
    move $t0, $a0        # $t0 = low-order 32 bits (milliseconds)
    move $t1, $a1        # $t1 = high-order 32 bits

    # Print the low-order time value
    li   $v0, 1
    move $a0, $t0
    syscall
```

**Service 32 — Sleep:**

```asm
.text
main:
    li   $v0, 4
    la   $a0, msg1       # print "Before sleep"
    syscall

    li   $v0, 32         # sleep
    li   $a0, 2000       # sleep for 2000 ms (2 seconds)
    syscall

    li   $v0, 4
    la   $a0, msg2       # print "After sleep"
    syscall

.data
msg1: .asciiz "Before sleep\n"
msg2: .asciiz "After sleep\n"
```

---

## Alternate Print Formats *(MARS only)*

| Code | Service | Arguments | Result |
|------|---------|-----------|--------|
| 34 | Print integer in hexadecimal | `$a0` = integer | 8 hex digits, zero-padded |
| 35 | Print integer in binary | `$a0` = integer | 32 bits, zero-padded |
| 36 | Print integer as unsigned decimal | `$a0` = integer | unsigned decimal |

### Example

```asm
.text
main:
    li   $t0, 255        # value to display in multiple formats

    li   $v0, 1          # print decimal
    move $a0, $t0
    syscall              # outputs: 255

    li   $v0, 11
    li   $a0, 10         # newline
    syscall

    li   $v0, 34         # print hexadecimal
    move $a0, $t0
    syscall              # outputs: 000000FF

    li   $v0, 11
    li   $a0, 10
    syscall

    li   $v0, 35         # print binary
    move $a0, $t0
    syscall              # outputs: 00000000000000000000000011111111

    li   $v0, 11
    li   $a0, 10
    syscall

    li   $v0, 36         # print unsigned decimal
    li   $a0, -1         # 0xFFFFFFFF as signed = -1, as unsigned = 4294967295
    syscall              # outputs: 4294967295
```

---

## Random Numbers *(MARS only)*

| Code | Service | Arguments | Result |
|------|---------|-----------|--------|
| 40 | Set seed | `$a0` = generator ID, `$a1` = seed | — |
| 41 | Random integer | `$a0` = generator ID | `$a0` = random int |
| 42 | Random integer in range \[0, n) | `$a0` = generator ID, `$a1` = upper bound | `$a0` = random int |
| 43 | Random float \[0.0, 1.0) | `$a0` = generator ID | `$f0` = random float |
| 44 | Random double \[0.0, 1.0) | `$a0` = generator ID | `$f0` = random double |

> Use service 40 to set a seed if replicated sequences are needed. Each generator ID maps to a separate `java.util.Random` instance.

### Examples

**Service 40 + 41 — Seeded random integer:**

```asm
.text
main:
    li   $v0, 40         # set seed
    li   $a0, 0          # generator ID = 0
    li   $a1, 12345      # seed value
    syscall

    li   $v0, 41         # random integer
    li   $a0, 0          # generator ID = 0
    syscall
    move $t0, $a0        # $t0 = random int

    li   $v0, 1          # print it
    move $a0, $t0
    syscall
```

**Service 42 — Random integer in range (e.g. simulating a die roll 1–6):**

```asm
.text
main:
    li   $v0, 42         # random int in range
    li   $a0, 0          # generator ID = 0
    li   $a1, 6          # upper bound (exclusive) → range [0, 6)
    syscall
    addi $a0, $a0, 1     # shift to [1, 6]

    li   $v0, 1          # print the result
    syscall
```

**Service 43 — Random float:**

```asm
.text
main:
    li   $v0, 43         # random float
    li   $a0, 0          # generator ID = 0
    syscall              # $f0 = random float in [0.0, 1.0)

    li   $v0, 2          # print float
    mov.s $f12, $f0
    syscall
```

---

## MIDI Output *(MARS only)*

| Code | Service | Description |
|------|---------|-------------|
| 31 | MIDI out (non-blocking) | Generates tone and returns immediately |
| 33 | MIDI out (synchronous) | Generates tone and waits for completion before returning |

### Example

**Service 33 — Play a simple melody (C D E, synchronous):**

```asm
.text
main:
    # Note C (middle C = 60), 500ms, piano (0), volume 80
    li   $v0, 33
    li   $a0, 60         # pitch: middle C
    li   $a1, 500        # duration: 500 ms
    li   $a2, 0          # instrument: Acoustic Grand Piano
    li   $a3, 80         # volume
    syscall

    # Note D
    li   $v0, 33
    li   $a0, 62         # pitch: D
    li   $a1, 500
    li   $a2, 0
    li   $a3, 80
    syscall

    # Note E
    li   $v0, 33
    li   $a0, 64         # pitch: E
    li   $a1, 500
    li   $a2, 0
    li   $a3, 80
    syscall

    li   $v0, 10
    syscall
```

**Parameters for services 31 & 33:**

| Register | Parameter | Range | Default |
|----------|-----------|-------|---------|
| `$a0` | Pitch | 0–127 (middle C = 60) | 60 |
| `$a1` | Duration | ms (positive int) | 1000 |
| `$a2` | Instrument | 0–127 (General MIDI patch) | 0 (Grand Piano) |
| `$a3` | Volume | 0–127 (127 = loudest) | 100 |

**Instrument Families:**

| Range | Family | Range | Family |
|-------|--------|-------|--------|
| 0–7 | Piano | 64–71 | Reed |
| 8–15 | Chromatic Percussion | 72–79 | Pipe |
| 16–23 | Organ | 80–87 | Synth Lead |
| 24–31 | Guitar | 88–95 | Synth Pad |
| 32–39 | Bass | 96–103 | Synth Effects |
| 40–47 | Strings | 104–111 | Ethnic |
| 48–55 | Ensemble | 112–119 | Percussion |
| 56–63 | Brass | 120–127 | Sound Effects |

---

## GUI Dialogs *(MARS only)*

| Code | Service | Arguments | Result |
|------|---------|-----------|--------|
| 50 | Confirm dialog | `$a0` = message string address | `$a0`: `0`=Yes, `1`=No, `2`=Cancel |
| 51 | Input dialog — int | `$a0` = message string address | `$a0`=int read, `$a1`=status |
| 52 | Input dialog — float | `$a0` = message string address | `$f0`=float read, `$a1`=status |
| 53 | Input dialog — double | `$a0` = message string address | `$f0`=double read, `$a1`=status |
| 54 | Input dialog — string | `$a0`=message, `$a1`=buffer, `$a2`=max chars | `$a1`=status |
| 55 | Message dialog | `$a0`=message, `$a1`=type | — |
| 56 | Message dialog — int | `$a0`=label, `$a1`=int value | — |
| 57 | Message dialog — float | `$a0`=label, `$f12`=float value | — |
| 58 | Message dialog — double | `$a0`=label, `$f12`=double value | — |
| 59 | Message dialog — string | `$a0`=label, `$a1`=second string address | — |

### Examples

**Service 50 — Confirm dialog:**

```asm
.data
question: .asciiz "Do you want to continue?"
yes_msg:  .asciiz "You chose Yes\n"
no_msg:   .asciiz "You chose No or Cancel\n"

.text
main:
    li   $v0, 50         # confirm dialog
    la   $a0, question
    syscall              # $a0 = 0 (Yes), 1 (No), 2 (Cancel)

    bne  $a0, $zero, not_yes
    li   $v0, 4
    la   $a0, yes_msg
    syscall
    j    done
not_yes:
    li   $v0, 4
    la   $a0, no_msg
    syscall
done:
    li   $v0, 10
    syscall
```

**Service 51 — Input dialog (integer):**

```asm
.data
prompt: .asciiz "Enter an integer:"

.text
main:
    li   $v0, 51         # input dialog int
    la   $a0, prompt
    syscall
    # $a0 = value entered, $a1 = status (0 = OK)
    beq  $a1, $zero, ok  # check status
    j    error
ok:
    move $t0, $a0        # save the integer
    li   $v0, 1          # print it back
    move $a0, $t0
    syscall
    j    done
error:
    li   $v0, 10
done:
    li   $v0, 10
    syscall
```

**Service 55 — Message dialog (information):**

```asm
.data
msg: .asciiz "Operation completed successfully!"

.text
main:
    li   $v0, 55         # message dialog
    la   $a0, msg
    li   $a1, 1          # type 1 = Information
    syscall

    li   $v0, 10
    syscall
```

**Service 56 — Message dialog with integer value:**

```asm
.data
label: .asciiz "Result: "

.text
main:
    li   $t0, 42

    li   $v0, 56         # message dialog int
    la   $a0, label
    move $a1, $t0        # integer value to display
    syscall              # shows dialog: "Result: 42"

    li   $v0, 10
    syscall
```

**Input dialog status codes (`$a1`):**

| Value | Meaning |
|-------|---------|
| `0` | OK — valid input received |
| `-1` | Input could not be parsed |
| `-2` | Cancel was chosen |
| `-3` | OK chosen but no data entered |
| `-4` | Input exceeded max length *(service 54 only)* |

**Message dialog types (`$a1` for service 55):**

| Value | Icon |
|-------|------|
| `0` | Error |
| `1` | Information |
| `2` | Warning |
| `3` | Question |
| other | Plain (no icon) |

---

## Quick Reference

| Code | Service |
|------|---------|
| 1 | Print int |
| 2 | Print float |
| 3 | Print double |
| 4 | Print string |
| 5 | Read int |
| 6 | Read float |
| 7 | Read double |
| 8 | Read string |
| 9 | Alloc heap |
| 10 | Exit |
| 11 | Print char |
| 12 | Read char |
| 13 | Open file |
| 14 | Read file |
| 15 | Write file |
| 16 | Close file |
| 17 | Exit2 |
| 30 | System time |
| 31 | MIDI out |
| 32 | Sleep |
| 33 | MIDI out sync |
| 34 | Print hex |
| 35 | Print binary |
| 36 | Print unsigned |
| 40 | Set RNG seed |
| 41 | Random int |
| 42 | Random int range |
| 43 | Random float |
| 44 | Random double |
| 50 | Confirm dialog |
| 51 | Input int dialog |
| 52 | Input float dialog |
| 53 | Input double dialog |
| 54 | Input string dialog |
| 55 | Message dialog |
| 56 | Message int dialog |
| 57 | Message float dialog |
| 58 | Message double dialog |
| 59 | Message string dialog |
