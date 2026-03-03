.data
# greeting: .asciiz "Hello world!\n"

.text

main:
    addi $t0, $zero, 5  # Initialize counter to 5
    li $v0, 1
    move $a0, $t0  # Move counter value to $a0 for printing
    syscall