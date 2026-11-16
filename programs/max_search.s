# max_search.s - find the maximum of a signed integer array
# Expected: prints 97 (0x61)
        .data
array:  .word 12, -5, 44, 97, 3, -120, 61, 8
len:    .word 8
max:    .word 0

        .text
main:   la   $s0, array
        la   $t0, len
        lw   $s1, 0($t0)
        lw   $s2, 0($s0)         # max = a[0]
        addi $t1, $zero, 1       # i = 1
loop:   beq  $t1, $s1, done
        sll  $t2, $t1, 2
        add  $t2, $s0, $t2
        lw   $t3, 0($t2)         # t3 = a[i]
        slt  $t4, $s2, $t3       # max < a[i] ?
        beq  $t4, $zero, skip
        move $s2, $t3
skip:   addi $t1, $t1, 1
        j    loop
done:   la   $t0, max
        sw   $s2, 0($t0)
        print $s2
        halt
