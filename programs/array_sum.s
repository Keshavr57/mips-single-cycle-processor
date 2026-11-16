# array_sum.s - sum of a 10-element array stored in data memory
# Expected: prints 55 (0x37) and stores it at label `result`
        .data
array:  .word 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
len:    .word 10
result: .word 0

        .text
main:   la   $s0, array          # s0 = &array[0]
        la   $t0, len
        lw   $s1, 0($t0)         # s1 = n
        addi $t1, $zero, 0       # i   = 0
        addi $s2, $zero, 0       # sum = 0
loop:   beq  $t1, $s1, done
        sll  $t2, $t1, 2         # byte offset = i*4
        add  $t2, $s0, $t2
        lw   $t3, 0($t2)
        add  $s2, $s2, $t3
        addi $t1, $t1, 1
        j    loop
done:   la   $t0, result
        sw   $s2, 0($t0)
        print $s2
        halt
