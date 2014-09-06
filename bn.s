	.file	"bn.s"
	.text
.LC0:
	.string "%x"
	.globl	bn_new
	.type	bn_new, @function
bn_new:
	pushl	%ebp
	movl	%esp, %ebp
	movl	$16, %edi
	call 	malloc
	test	%eax, %eax
	jnz	mem
	leave
	ret
mem:	movl	$0, (%eax)
	movl	$0, 4(%eax)
	movl	$0, 8(%eax)
	leave
	ret
	.size	bn_new, .-bn_new

	.globl	bn_free
	.type	bn_free, @function
bn_free:
	pushl	%ebp
	movl	%esp, %ebp
	pushl	%edi
	movl	8(%edi), %edi
	call	free
	movl	(%esp), %edi
	call	free
	popl	%edi
	leave
	ret
	.size	bn_new, .-bn_new


	.globl	bn_hex2bn
	.type	bn_hex2bn, @function
bn_hex2bn:
	pushl	%ebp
	movl	%esp, %ebp

	# Return -1
	movl	$-1, %eax

	leave
	ret
	.size	bn_hex2bn, .-bn_hex2bn

	.globl	bn_bn2hex
	.type	bn_bn2hex, @function
bn_bn2hex:
	push	%ebp
	movl	%esp, %ebp
	push	%edx
	movl	4(%edx), %eax #how many limbs?
	subl	$1, %eax
	movl	8(%edx, %eax, 4), %ecx #get last limb to get size
	cmpl	$0x00010000, %ecx
	jl	subfive
	cmpl	$0x01000000, %ecx
	jl	fivesix
	cmpl	$0x10000000, %ecx
	jl	seven
	movl	$8, %eax
	jmp	bhbody
seven:	movl	$7, %eax
	jmp	bhbody
fivesix:
	cmpl	$0x00100000, %ecx
	jl	five
	movl	$6, %eax
	jmp	bhbody
five:	movl	$5, %eax
	jmp	bhbody
subfive:
	cmpl	$0x00000100, %ecx
	jl	sub3
	cmpl	$0x00001000, %ecx
	jl	three
	movl	$4, %eax
	jmp	bhbody
three:	movl	$3, %eax
	jmp	bhbody
sub3:	cmpl	$0x00000010, %ecx
	jl	one
	movl	$2, %eax
	jmp	bhbody
one:	movl	$1, %eax
bhbody:	movl	4(%edx), %ecx
	subl	$1, %ecx
	mull	$8, %ecx
	addl	$1, %ecx
	addl	%eax, %ecx
	cmpl	%esi, %ecx
	jle	bncont
	# Return -1
	movl	$-1, %eax
	leave
	ret
bhcont:	movl	$.LC0, %esi
	movl	4(%edx), %ecx
	subl	$1, %ecx
	mull	$8, %ecx
	movl	8(%edx), %edx
	addl	%ecx, %edx
	call	sprintf
	addl	%eax, %edi
	subl	$8, %edx
	movl	(%esp), %ecx
	subl	$1, ecx
	jz	bhfinish
bhloop:
	call	sprintf
	addl	$8, %edi
	subl	$8, %edx
	loop	bhloop
bnfinish:
	subl	$7, %edi
	movb	$0, (%edi)
	leave
	ret
	.size	bn_bn2hex, .-bn_bn2hex

	.globl	bn_add
	.type	bn_add, @function
bn_add:
	push	%ebp
	movl	%esp, %ebp
	push	%ebx
	push	%edi
	push	%esi
	push	%edx

	# Make sure r has the correct size
	movl	(%edi), %eax #holds size r
	movl	4(%esi), %ecx #holds nlimb x
	movl	4(%edx), %ebx #holds nlimb y
	cmp	%ecx, %ebx #compare nlimb x and y
	je	equal
	jl	bigx #if x is bigger
	cmp	$0xFFFFFFFF, %ebx #can y overflow?
	jne	sizey #if not max size is y
	addl	$1, %ebx #else to be sure add 1
	cmp	%eax, %ebx #compare max size of result
	movl	%ebx, %ecx
	jle	adding #if fine continue to add
	movl	8(%edi), %edi
	mull	$4, %ebx
	movl	%ebx, %esi
	call	realloc
	test	%eax, %eax
	jz	addleave
	movl	4(%esp), %edi
	movl	%eax, 8(%edi)
	movl	%ecx, (%edi)
adding:
	pop	%edx
	pop	%esi
	pop	%edi
	movl	%ecx, %eax
	mull	$4, %eax
	subl	%eax, %esp
	movl	%esp, %eax
	push	%edi
	push	%esi
	push	%edx
	movl	4(%esi), %edi #xlimb in edi
	movl	4(%edx), %ebx #ylimb in ebx
	cmpl	%edi, %ebx
	je	xyequal
	jl	xgreat
	movl	%edi, %ecx
	movl	8(%esi), %esi
	movl	8(%edx), %edi
	clc
top:	movl	(%esi), %ebx
	movl	(%edi), %edx
	jnc	addnumy
	addl	$1, %edx
addnum:	addl	%ebx, %edx
	movl	%edx, (%eax)
	addl	$4, %esi
	addl	$4, %edi
	addl	$4, %eax
	loop	top
	movl	(%esp), %ecx
	movl	4(%ecx), %ecx
	movl	4(%esp), %esi
	movl	4(%esi), %esi
	sub	%esi, %ecx
ystack:	movl	(%edi), %edx
	jnc	ystackc
	addl	$1, %edx
ystackc:
	movl	%edx, (%eax)
	addl	$4, %edi
	addl	$4, %eax
	loop	ystack

	# Return -1
	movl	$-1, %eax

addleave:
	pop	%edx
	pop	%esi
	pop	%edi
	pop	%ebx
	leave
	ret
	.size	bn_add, .-bn_add
