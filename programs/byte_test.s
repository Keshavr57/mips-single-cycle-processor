# byte_test.s - Phase II self-checking test for lb, lbu, lh, lhu, sb, sh and mul.
# Prints 0x600D on success, or 0xBAD0_00NN where NN is the failing test number.
        .data
w0:     .word 0x8899AABB, 0x11223344
buf:    .word 0, 0

        .text
        la   $s0, w0
        # ---- test 1: lb / lbu on every byte of 0x8899AABB (little-endian)
        addi $s7, $zero, 1
        lb   $t0, 0($s0)            # 0xBB -> sign-extended
        li   $t9, 0xFFFFFFBB
        bne  $t0, $t9, fail
        lbu  $t0, 0($s0)            # 0xBB -> zero-extended
        addi $t9, $zero, 0xBB
        bne  $t0, $t9, fail
        lbu  $t0, 3($s0)            # most significant byte = 0x88
        addi $t9, $zero, 0x88
        bne  $t0, $t9, fail
        lb   $t0, 4($s0)            # 0x44 (positive)
        addi $t9, $zero, 0x44
        bne  $t0, $t9, fail
        # ---- test 2: lh / lhu
        addi $s7, $zero, 2
        lh   $t0, 0($s0)            # 0xAABB -> 0xFFFFAABB
        li   $t9, 0xFFFFAABB
        bne  $t0, $t9, fail
        lhu  $t0, 2($s0)            # 0x8899
        ori  $t9, $zero, 0x8899
        bne  $t0, $t9, fail
        lh   $t0, 6($s0)            # 0x1122 (positive)
        ori  $t9, $zero, 0x1122
        bne  $t0, $t9, fail
        # ---- test 3: sb builds a word byte by byte
        addi $s7, $zero, 3
        la   $s1, buf
        addi $t0, $zero, 0x44
        sb   $t0, 0($s1)
        addi $t0, $zero, 0x33
        sb   $t0, 1($s1)
        addi $t0, $zero, 0x22
        sb   $t0, 2($s1)
        addi $t0, $zero, 0x11
        sb   $t0, 3($s1)
        lw   $t1, 0($s1)
        li   $t9, 0x11223344
        bne  $t1, $t9, fail
        # ---- test 4: sh writes only its half, other half unchanged
        addi $s7, $zero, 4
        ori  $t0, $zero, 0xBEEF
        sh   $t0, 2($s1)
        lw   $t1, 0($s1)
        li   $t9, 0xBEEF3344
        bne  $t1, $t9, fail
        # ---- test 5: mul (signed operands, low 32 bits)
        addi $s7, $zero, 5
        addi $t0, $zero, -12
        addi $t1, $zero, 11
        mul  $t2, $t0, $t1
        addi $t9, $zero, -132
        bne  $t2, $t9, fail
        li   $t0, 100000
        mul  $t2, $t0, $t0          # 10^10 mod 2^32 = 0x540BE400
        li   $t9, 0x540BE400
        bne  $t2, $t9, fail
        # ---- all passed
        ori  $t0, $zero, 0x600D
        print $t0
        halt

fail:   lui  $t0, 0xBAD0
        or   $t0, $t0, $s7
        print $t0
        halt
