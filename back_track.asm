.data
greeting: .asciiz "Hello world!\n"

.text

main:
    li $v0, 4
    la $a0, greeting
    syscall
    jr $ra