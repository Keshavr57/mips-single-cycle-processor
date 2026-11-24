# factorial_hw.s - Phase II: same recursive factorial as factorial.s but using
# the hardware `mul` instruction instead of the software shift-and-add loop.
# Used for the performance comparison in the report.
# Expected: prints 1, 2, 6, 24, 120, 720, 5040, then 5040 again
        .text
main:   addi $s0, $zero, 1
        addi $s1, $zero, 8
outer:  move $a0, $s0
        jal  fact
        print $v0
        addi $s0, $s0, 1
        bne  $s0, $s1, outer
        move $s7, $v0
        print $s7
        halt

fact:   addi $sp, $sp, -8
        sw   $ra, 4($sp)
        sw   $a0, 0($sp)
        slti $t0, $a0, 2
        beq  $t0, $zero, recurse
        addi $v0, $zero, 1
        addi $sp, $sp, 8
        jr   $ra
recurse: addi $a0, $a0, -1
        jal  fact
        lw   $a0, 0($sp)
        lw   $ra, 4($sp)
        addi $sp, $sp, 8
        mul  $v0, $a0, $v0          # one instruction instead of a loop
        jr   $ra
