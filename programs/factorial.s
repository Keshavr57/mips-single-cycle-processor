# factorial.s - recursive factorial using jal / jr and the stack
# Tests: jal, jr, sw/lw on the stack ($sp), bne, slti, function calls.
# Multiplication is done in software (shift-and-add), since the core has no MUL.
# Expected: prints 1, 2, 6, 24, 120, 720, 5040 (n = 1..7), then 5040 again
        .text
main:   addi $s0, $zero, 1       # n = 1
        addi $s1, $zero, 8
outer:  move $a0, $s0
        jal  fact
        print $v0
        addi $s0, $s0, 1
        bne  $s0, $s1, outer
        move $s7, $v0
        print $s7
        halt

# int fact(int n) { return n < 2 ? 1 : n * fact(n-1); }
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
        move $a1, $v0            # v0 = a0 * a1
        jal  mul                 # (clobbers $ra -> restore after)
        lw   $ra, 4($sp)
        addi $sp, $sp, 8
        jr   $ra

# v0 = a0 * a1 (unsigned shift-and-add, leaf function)
mul:    addi $v0, $zero, 0
        move $t1, $a0
        move $t2, $a1
mloop:  beq  $t2, $zero, mdone
        andi $t3, $t2, 1
        beq  $t3, $zero, mskip
        addu $v0, $v0, $t1
mskip:  sll  $t1, $t1, 1
        srl  $t2, $t2, 1
        j    mloop
mdone:  jr   $ra
