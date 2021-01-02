	.align	4
	.section .text
	.globl	_start
_start:
    andi	a0,a0,0 
    andi	a1,a1,0
    andi	a2,a2,0 
    andi	a3,a3,0
    li	a0,2
    li	a2,2
	mv	a7,a0
	mv	t1,a1

	mv	a5,a0
	or	a5,a0,a1
	beqz	a5,.L76
	li	a0,0
	li	a1,0
.L75:
	andi	a5,a7,1
	beqz	a5,.L73
	add	a5,a0,a2
	sltu	a0,a5,a0
	add	a4,a1,a3
	add	a1,a0,a4
	mv	a4,a1
	mv	a0,a5
.L73:
	slli	a4,t1,31
	srli	a5,a7,1
	or	a5,a4,a5
	srli	t3,t1,1
	mv	a7,a5
	mv	t1,t3
	srli	a6,a2,31
	slli	a4,a3,1
	mv	a3,a6
	or	a3,a6,a4
	slli	a2,a2,1
	mv	a4,a5
	or	a4,a5,t3
	bnez	a4,.L75
.L76:
.L31:
	j	.L31
	nop
	nop
	nop
