.text
.global _start
_start:
// choosing # of trials
// 100 = 0x64
// 10000 = 0x2710
// 1000000 = 0xF4240
movz x20, 0x0000, lsl 16
movk x20, 0x2710, lsl 0

// storing # of trials
ldr x0, =current
ldr x1, =total
str x20, [x0, 0]
str x20, [x1, 0]

// clearing # of hits
add x20, xzr, xzr
ldr x2, =hits
str x20, [x2, 0]

// creating divisor
movz x0, #65535, lsl #0 // build a constant that is 7FFF FFFF FFFF FFFF
movk x0, #65535, lsl #16
movk x0, #65535, lsl #32
movk x0, #32767, lsl #48
scvtf d1, x0
ldr x0, =divisor
str d1, [x0, 0] // Store this constant in the divisor variable

// constant 1 for comparison in d26
mov x26, 1
scvtf d26, x26

_loop:
// create an X value in d0
mov x8, #278 // Setup for Syscall 278 - getrandom
ldr x0, =var // buffer address
mov x1, #8 // 8 bytes of randomness
mov x2, #0 // flags
svc #0
ldr x8, =var // get address of variables
ldr x9, [x8, 0] // load random number
scvtf d0, x9 // convert to double precision
ldr x0, =divisor // Load divisor from ram
ldr d1, [x0, 0]
fdiv d0, d0, d1 // make random number be between -1 and 1

// create a Y value in d1
mov x8, #278 // Setup for Syscall 278 - getrandom
ldr x0, =var // buffer address
mov x1, #8 // 8 bytes of randomness
mov x2, #0 // flags
svc #0
ldr x8, =var // get address of variables
ldr x9, [x8, 0] // load random number
scvtf d1, x9 // convert to double precision
ldr x0, =divisor // Load divisor from ram
ldr d2, [x0, 0]
fdiv d1, d1, d2 // make random number be between -1 and 1

_test:
// testing if sqrt(x^2 + y^2) < 1, i.e. within unit circle
fmul d8, d0, d0 // d8 = x^2
fmul d9, d1, d1 // d9 = y^2
fadd d8, d8, d9 // d8 = x^2 + y^2
fsqrt d8, d8 // d8 = sqrt(x^2 + y^2)
fcmp d8, d26
b.ge _miss // if > 1, miss

_hit: // else, hits = hits + 1
ldr x0, =current
ldr x1, =hits
ldr x10, [x0, 0]
ldr x11, [x1, 0]
add x11, x11, 1
str x11, [x1, 0]
sub x10, x10, 1
cbz x10, _done
str x10, [x0, 0]
b _loop

_miss:
// if distance > 1, fail, generate 2 more numbers
ldr x0, =current
ldr x10, [x0, 0]
sub x10, x10, 1
cbz x10, _done
str x10, [x0, 0]
b _loop

_done:
// hits / total = % inside circle, multiply by 4 for approximate pi
ldr x0, =total
ldr x1, =hits
ldr x10, [x0, 0]
ldr x11, [x1, 0]
mov x12, 4
scvtf d10, x10
scvtf d11, x11
scvtf d12, x12
fdiv d10, d11, d10
fmul d0, d10, d12

_print:
// print # of trials and approximate value of pi
ldr x0, =string // Load format string for printf
ldr x10, =total
ldr x1, [x10, 0]
bl printf // x0 - format string, x1 - number of trials, d0 - approximate pi

_exit:
mov x8, #94
mov x0, #0
svc #0

.data
string:
 .asciz "Trials: %i\n Pi: %lf\n"
var:
 .zero 8
divisor:
 .zero 8
current: // current position in count
 .zero 8
total: // total # of trials
 .zero 8
hits: // # of hits or successes
 .zero 8
