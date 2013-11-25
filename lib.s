!!! library of convenient functions
!!! RAB 11/05

	_LIB_EXIT = 1
	_LIB_READ = 3
	_LIB_WRITE = 4
	_LIB_OPEN = 5
	_LIB_CLOSE = 6
	_LIB_CREAT = 8
	_LIB_LSEEK = 19

	_LIB_STDIN = 0
	_LIB_STDOUT = 1

	_LIB_GETCHAR = 117
	_LIB_SPRINTF = 121
	_LIB_PUTCHAR = 122
	_LIB_SSCANF = 125
	_LIB_PRINTF = 127


!!! printstr -- print a null-terminated string on standard output
!!!  1 arg -- address of a null-terminated string
!!!  state change -- the chars of arg1 are printed, excluding the
!!!    terminating nullbyte
!!!  return -- none
	
.SECT	.TEXT
printstr:
	PUSH	BX		! save registers
	PUSH	BP
	MOV	BP,SP		! set up BP
	
	PUSH	6(BP)		! calculate length of string (returned in AX)
	CALL	strlen
	ADD	SP,2		! clean up stack
	
	PUSH	AX		! print arg string
	PUSH	6(BP)
	PUSH	_LIB_STDOUT
	PUSH	_LIB_WRITE
	SYS
	ADD	SP,8		! clean stack

	POP	BP		! restore registers
	POP	BX
	RET

!!! printstr2 -- print a null-terminated string on standard output
!!!  2 args -- file descriptor for output, address of a null-terminated string
!!!  state change -- the chars of arg2 are printed on the descriptor arg1, 
!!!	excluding the terminating nullbyte
!!!  return -- none

!!! Arguments:	 file descriptor = 6(BP), string = 8(BP)

.SECT	.TEXT
printstr2:
	PUSH	BX		! save registers
	PUSH	BP
	MOV	BP,SP		! set up BP
	
	PUSH	8(BP)		! calculate length of string (returned in AX)
	CALL	strlen
	ADD	SP,2		! clean up stack
	
	PUSH	AX		! print arg string
	PUSH	8(BP)
	PUSH	6(BP)
	PUSH	_LIB_WRITE
	SYS
	ADD	SP,8		! clean stack

	POP	BP		! restore registers
	POP	BX
	RET

!!! printnl -- print a newline
!!!  0 args
!!!  state change -- prints a newline on standard output
!!!  return -- none

.SECT	.DATA
printnl_nl:
	.BYTE	'\n'
	
.SECT	.TEXT
printnl:
	PUSH	1
	PUSH	printnl_nl
	PUSH	_LIB_STDOUT
	PUSH	_LIB_WRITE
	SYS
	ADD	SP,8
	RET
	

!!! strlen -- return length of a string
!!!  1 arg -- address of a null-terminated string
!!!  state change -- none
!!!  return -- non-negative integer, the length of the string arg1,
!!!     i.e., the number of chars in that string excluding the final nullbyte

.SECT	.TEXT
strlen:
	PUSH	BX		! save registers
	PUSH	BP
	MOV	BP,SP		! set up BP
	MOV	BX,6(BP)	! copy argument to BX 
1:	CMPB	(BX),0		! if the next char (BX) is not a nullbyte...
	JE	2f
	INC	BX		! then add 1 to BX
	JMP	1b		! and look at next char

2:	!! assert - BX holds address of first nullbyte in the arg string
	SUB	BX,6(BP)	! store length of arg string in BX
	MOV	AX,BX		! set up return value
	POP	BP		! restore registers
	POP	BX
	RET
	

.SECT	.DATA
_LIB_num_buff:
	.SPACE	20

.SECT	.TEXT
!!! printdec -- print decimal representation of a word integer
!!!  2 arg -- an output file descriptor and an word integer value to print
!!!  state change -- prints decimal representation of arg2 on descriptor arg1
!!!  return -- integer 1 on success, 0 on failure
.SECT	.TEXT
printdec:
	PUSH	BP		! save and set up frame pointer
	MOV	BP,SP

	PUSH	6(BP)		! create string representation of integer
	PUSH	_LIB_dec_format
	PUSH	_LIB_num_buff
	PUSH	_LIB_SPRINTF
	SYS
	ADD	SP,8
	
	CMP	AX,0            ! on success...
	JE	9f
	!! creation of string representation succeeded
	PUSH	_LIB_num_buff	! determine length of representation
	CALL	strlen
	ADD	SP,2
	PUSH	AX		! write that representation on file descriptor
	PUSH	_LIB_num_buff
	PUSH	4(BP)
	PUSH	_LIB_WRITE
	SYS
	ADD	SP,8

	MOV	AX,1		! load success return value
9:	POP	BP		! restore register and return
	RET

.SECT	.DATA
_LIB_dec_format:
	.ASCIZ	"%d"

!!! printoct -- print octal representation of a word integer
!!!  2 arg -- an output file descriptor and an word integer value to print
!!!  state change -- prints octal representation of arg2 on descriptor arg1
!!!  return -- integer 1 on success, 0 on failure
.SECT	.TEXT
printoct:
	PUSH	BP		! save and set up frame pointer
	MOV	BP,SP

	PUSH	6(BP)		! create string representation of integer
	PUSH	_LIB_oct_format
	PUSH	_LIB_num_buff
	PUSH	_LIB_SPRINTF
	SYS
	ADD	SP,8
	
	CMP	AX,0            ! on success...
	JE	9f
	!! creation of string representation succeeded
	PUSH	_LIB_num_buff	! determine length of representation
	CALL	strlen
	ADD	SP,2
	PUSH	AX		! write that representation on file descriptor
	PUSH	_LIB_num_buff
	PUSH	4(BP)
	PUSH	_LIB_WRITE
	SYS
	ADD	SP,8

	MOV	AX,1		! load success return value
9:	POP	BP		! restore register and return
	RET

.SECT	.DATA
_LIB_oct_format:
	.ASCIZ	"%07o"

!!! printoctb -- print octal representation of a byte integer
!!!  2 arg -- an output file descriptor and an byte integer value to print
!!!  state change -- prints octal representation of arg2 on descriptor arg1
!!!  return -- integer 1 on success, 0 on failure
.SECT	.TEXT
printoctb:
	PUSH	BP		! save and set up frame pointer
	MOV	BP,SP

	PUSH	6(BP)		! create string representation of integer
	PUSH	_LIB_octb_format
	PUSH	_LIB_num_buff
	PUSH	_LIB_SPRINTF
	SYS
	ADD	SP,8
	
	CMP	AX,0            ! on success...
	JE	9f
	!! creation of string representation succeeded
	PUSH	_LIB_num_buff	! determine length of representation
	CALL	strlen
	ADD	SP,2
	PUSH	AX		! write that representation on file descriptor
	PUSH	_LIB_num_buff
	PUSH	4(BP)
	PUSH	_LIB_WRITE
	SYS
	ADD	SP,8

	MOV	AX,1		! load success return value
9:	POP	BP		! restore register and return
	RET

.SECT	.DATA
_LIB_octb_format:
	.ASCIZ	"%03o"

!!! printhex -- print hexadecimal representation of a word integer
!!!  2 arg -- an output file descriptor and an word integer value to print
!!!  state change -- prints hexadecimal representation of arg2 on descriptor arg1
!!!  return -- integer 1 on success, 0 on failure
.SECT	.TEXT
printhex:
	PUSH	BP		! save and set up frame pointer
	MOV	BP,SP

	PUSH	6(BP)		! create string representation of integer
	PUSH	_LIB_hex_format
	PUSH	_LIB_num_buff
	PUSH	_LIB_SPRINTF
	SYS
	ADD	SP,8
	
	CMP	AX,0            ! on success...
	JE	9f
	!! creation of string representation succeeded
	PUSH	_LIB_num_buff	! determine length of representation
	CALL	strlen
	ADD	SP,2
	PUSH	AX		! write that representation on file descriptor
	PUSH	_LIB_num_buff
	PUSH	4(BP)
	PUSH	_LIB_WRITE
	SYS
	ADD	SP,8

	MOV	AX,1		! load success return value
9:	POP	BP		! restore register and return
	RET

.SECT	.DATA
_LIB_hex_format:
	.ASCIZ	"%04x"

!!! printhexb -- print hexadecimal representation of a byte integer
!!!  2 arg -- an output file descriptor and an byte integer value to print
!!!  state change -- prints hexadecimal representation of arg2 on descriptor arg1
!!!  return -- integer 1 on success, 0 on failure
.SECT	.TEXT
printhexb:
	PUSH	BP		! save and set up frame pointer
	MOV	BP,SP

	PUSH	6(BP)		! create string representation of integer
	PUSH	_LIB_hexb_format
	PUSH	_LIB_num_buff
	PUSH	_LIB_SPRINTF
	SYS
	ADD	SP,8
	
	CMP	AX,0            ! on success...
	JE	9f
	!! creation of string representation succeeded
	PUSH	_LIB_num_buff	! determine length of representation
	CALL	strlen
	ADD	SP,2
	PUSH	AX		! write that representation on file descriptor
	PUSH	_LIB_num_buff
	PUSH	4(BP)
	PUSH	_LIB_WRITE
	SYS
	ADD	SP,8

	MOV	AX,1		! load success return value
9:	POP	BP		! restore register and return
	RET

.SECT	.DATA
_LIB_hexb_format:
	.ASCIZ	"%02x"

