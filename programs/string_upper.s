# string_upper.s - Phase II: string processing with lb / sb.
# Converts a null-terminated string to upper case in place, then prints
# its length and a checksum (sum of all bytes), then prints each word.
# Input  : "hello, mips world!"
# Expect : length 18, checksum of "HELLO, MIPS WORLD!" = 1218
        .data
str:    .asciiz "hello, mips world!"

        .text
main:   la   $s0, str
        addi $s1, $zero, 0          # length
        addi $s2, $zero, 0          # checksum
loop:   add  $t0, $s0, $s1
        lbu  $t1, 0($t0)            # c = str[i]
        beq  $t1, $zero, done
        slti $t2, $t1, 97           # c < 'a' ?
        bne  $t2, $zero, store
        slti $t2, $t1, 123          # c <= 'z' ?
        beq  $t2, $zero, store
        addi $t1, $t1, -32          # to upper case
        sb   $t1, 0($t0)
store:  add  $s2, $s2, $t1
        addi $s1, $s1, 1
        j    loop
done:   print $s1
        print $s2
        # print the first word "HELL" as a little-endian word: 0x4C4C4548
        lw   $t3, 0($s0)
        print $t3
        halt
