# bubble_sort.s - in-place bubble sort of 8 words, then prints them in order
# Expected output: -7 0 3 9 15 22 41 88
        .data
array:  .word 22, 9, -7, 88, 3, 41, 0, 15
len:    .word 8

        .text
main:   la   $s0, array
        la   $t0, len
        lw   $s1, 0($t0)         # n
        addi $s2, $s1, -1        # i = n-1
outer:  beq  $s2, $zero, show
        addi $t0, $zero, 0       # j = 0
        move $t1, $s0            # p = &a[0]
inner:  beq  $t0, $s2, next
        lw   $t2, 0($t1)
        lw   $t3, 4($t1)
        slt  $t4, $t3, $t2       # a[j+1] < a[j] ?
        beq  $t4, $zero, noswap
        sw   $t3, 0($t1)
        sw   $t2, 4($t1)
noswap: addi $t0, $t0, 1
        addi $t1, $t1, 4
        j    inner
next:   addi $s2, $s2, -1
        j    outer
show:   addi $t0, $zero, 0
        move $t1, $s0
ploop:  beq  $t0, $s1, end
        lw   $t2, 0($t1)
        print $t2
        addi $t0, $t0, 1
        addi $t1, $t1, 4
        j    ploop
end:    halt
