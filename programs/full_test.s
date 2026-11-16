# full_test.s - self-checking test of every supported instruction.
# Each check prints a test number; on failure it jumps to `fail` which prints
# 0xBAD0_00NN (NN = failing test number). On success prints 0x600D (GOOD).
        .text
        # ---- test 1: addi / add
        addi $t0, $zero, 15
        addi $t1, $zero, -5
        add  $t2, $t0, $t1          # 10
        addi $s7, $zero, 1
        addi $t9, $zero, 10
        bne  $t2, $t9, fail
        # ---- test 2: sub
        sub  $t2, $t1, $t0          # -20
        addi $s7, $zero, 2
        addi $t9, $zero, -20
        bne  $t2, $t9, fail
        # ---- test 3: and / or / xor / nor
        li   $t0, 0x0F0F00FF
        li   $t1, 0x00FF0F0F
        and  $t2, $t0, $t1
        li   $t9, 0x000F000F
        addi $s7, $zero, 3
        bne  $t2, $t9, fail
        or   $t2, $t0, $t1
        li   $t9, 0x0FFF0FFF
        bne  $t2, $t9, fail
        xor  $t2, $t0, $t1
        li   $t9, 0x0FF00FF0
        bne  $t2, $t9, fail
        nor  $t2, $t0, $t1
        li   $t9, 0xF000F000
        bne  $t2, $t9, fail
        # ---- test 4: slt / sltu (signed vs unsigned)
        addi $t0, $zero, -1          # 0xFFFFFFFF
        addi $t1, $zero, 1
        addi $s7, $zero, 4
        slt  $t2, $t0, $t1           # -1 < 1  -> 1
        addi $t9, $zero, 1
        bne  $t2, $t9, fail
        sltu $t2, $t0, $t1           # 0xFFFFFFFF < 1 -> 0
        bne  $t2, $zero, fail
        slti $t2, $t0, 0             # -1 < 0 -> 1
        bne  $t2, $t9, fail
        # ---- test 5: shifts
        addi $s7, $zero, 5
        li   $t0, 0x80000010
        sll  $t2, $t0, 4
        li   $t9, 0x00000100
        bne  $t2, $t9, fail
        srl  $t2, $t0, 4
        li   $t9, 0x08000001
        bne  $t2, $t9, fail
        sra  $t2, $t0, 4
        li   $t9, 0xF8000001
        bne  $t2, $t9, fail
        # ---- test 6: andi / ori / xori zero-extend, lui
        addi $s7, $zero, 6
        addi $t0, $zero, -1
        andi $t2, $t0, 0xF0F0
        ori  $t9, $zero, 0xF0F0
        bne  $t2, $t9, fail
        xori $t2, $t0, 0xFFFF
        lui  $t9, 0xFFFF
        bne  $t2, $t9, fail
        # ---- test 7: lw / sw round-trip and $0 hard-wired
        addi $s7, $zero, 7
        li   $t0, 0xCAFEBABE
        sw   $t0, 64($zero)
        lw   $t1, 64($zero)
        bne  $t0, $t1, fail
        addi $zero, $zero, 99       # must be ignored
        bne  $zero, $0, fail
        addi $t3, $zero, 128
        sw   $t0, -4($t3)           # negative offset -> address 124
        lw   $t1, 124($zero)
        bne  $t0, $t1, fail
        # ---- test 8: beq taken / not taken
        addi $s7, $zero, 8
        addi $t0, $zero, 3
        beq  $t0, $zero, fail       # not taken
        beq  $t0, $t0, t8ok         # taken
        j    fail
t8ok:   # ---- test 9: jal / jr
        addi $s7, $zero, 9
        jal  sub1
        addi $t9, $zero, 42
        bne  $v0, $t9, fail
        # ---- test 10: cycle counter MMIO is readable and increasing
        addi $s7, $zero, 10
        ori  $at, $zero, 0xFFF8
        lw   $t0, 0($at)
        lw   $t1, 0($at)            # same cycle? no - next instruction
        sltu $t2, $t0, $t1
        beq  $t2, $zero, fail
        # ---- all passed
        ori  $t0, $zero, 0x600D
        print $t0
        halt

sub1:   addi $v0, $zero, 42
        jr   $ra

fail:   lui  $t0, 0xBAD0
        or   $t0, $t0, $s7
        print $t0
        halt
