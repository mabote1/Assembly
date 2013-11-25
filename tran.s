! Assembly program to translate certain characters
! Tommy Markley 4/2012 - 5/2012

        _EXIT   = 1             
        _READ   = 3             
        _WRITE  = 4             
        _STDIN  = 0             
        _STDOUT = 1
        _GETCHAR = 117
	_STDERR	= 2
	MAXBUFF	= 100

.SECT .TEXT                     
start:

	PUSH	prompt2-prompt	! print the user prompt
	PUSH	prompt
	PUSH	_STDERR		! on standard error
	PUSH	_WRITE
	SYS
	ADD	SP,8		! clean up stack

	PUSH	MAXBUFF		! want one character, a space, second character
	PUSH	inbuff		! will store the first line of input
	CALL	getline
	ADD	SP,4		! clean up stack

	PUSH	inbuff		! use chars manipulated by getline for gettrans
	CALL	gettrans
	ADD	SP,2		! clean up stack

	CMP	AX,0		! if gettrans returned 0, print error
	JE	8f

	PUSH	sum-prompt2	! print the second user prompt
	PUSH	prompt2
	PUSH	_STDERR		! on standard error
	PUSH	_WRITE
	SYS
	ADD	SP,8		! clean up stack
	
1:	! call getline to be translated
	
	PUSH	MAXBUFF		! maxbuff is the max number of characters
	PUSH	inbuff		! inbuff is where characters will be stored
	CALL	getline
	ADD	SP,4		! clean up stack

	MOV	(size),AX	! put AX (num of chars) in a word variable

	PUSH	inbuff		! inbuff holds chars to be translated
	CALL	translate
	ADD	SP,2		! clean up stack

	! print output
        PUSH    (size)          ! number of characters
        PUSH    inbuff		! print string inbuff
        PUSH    _STDOUT         ! on standard output
        PUSH    _WRITE
        SYS
        ADD     SP,8            ! clean up stack

	CMPB	(size),0	! if no characters were read from getline, exit
	JNE	1b		! otherwise read more

	CALL	printnl

	CALL	print_summary	! give the user a summary
	JMP	9f

8:	PUSH	error		! print error string
	CALL	printstr
	ADD	SP,2		! clean up stack
	
9:	PUSH    0               ! exit with normal exit status
        PUSH    _EXIT           
        SYS                     

	
!! getline
!! 2 arg -- the address of a buffer and the size of that buffer in bytes
!! state change -- up to (arg2-1) bytes are read from standard input, using
!!   buffered reads, stopping if a newline character is encountered. Those
!!   input bytes, including newline if any, are stored in arg1 starting at the
!!   beginning and a nullbyte is added after the last character stored.
!! return -- positive integer number of characters stored, excluding the added
!!   nullbyte, or 0 if no bytes could be read

getline:
	PUSH	BX		! save registers
	PUSH	BP
	PUSH	CX
	MOV	BP,SP		! set up BP
	MOV	BX,8(BP)	! BX holds value arg1 (address of first byte)
	MOV	CX,BX		! CX keeps track of where BX is using arg2

1:	ADD	CX,10(BP)	! check to see if arg2-1 chars have been read
	SUB	CX,1
	CMP	CX,BX
	JE	9f		! if so, exit
	SUB	CX,10(BP)
	ADD	CX,1
	
	PUSH	_GETCHAR	! read in a character
	SYS
	ADD	SP,2		! clean up stack

	CMPB	AL,-1		! if the nullbyte was read, exit
	JE	9f		
	MOVB	(BX),AL		! otherwise, put that character in address of BX

	INC	BX		! move to the next character
	
	CMPB	AL,'\n'		! check if the newest character was a newline
	JNE	1b		! and if it wasn't, read another character

9:	MOVB	(BX),0		! put a nullbyte at the end of the char string
	MOV	AX,BX		! put the number of characters read in AX
	SUB	AX,8(BP)	! subtract original address of BX to get size

	POP	CX		! restore values of registers
	POP	BP
	POP	BX
	RET


!! gettrans
!! 1 arg -- a description line, consisting of two characters separated by a
!!    space character
!! state change -- prepare for translation of characters from the first string
!!    to the corresponding characters of the second string
!! return -- integer 1 on success, or 0 if two strings of the same length were
!!    not provided

gettrans:
	PUSH	BX		! save registers
	PUSH	BP
	MOV	BP,SP		! set up BP
	MOV	BX,6(BP)	! BX holds the characters

	MOVB	AL,(BX)		! put character in current address of BX in AL
	MOVB	(inchar),AL	! then put that character into inchar
	CMPB	1(BX),' '	! if the next character isn't a space
	JNE	8f		! user did not provide a one character string

	MOVB	AL,2(BX)	! same with outchar, except we're taking the
	MOVB	(outchar),AL	! third character
	CMPB	3(BX),'\n'	! if next character isn't a newline,
	JNE	8f		! return failure, user didn't provide one char
	MOV	AX,1		! else, return success
	JMP	9f

8:	MOV	AX,0		! return failure
9:	POP	BP		! restore registers
	POP	BX
	RET


!! translate
!! 1 arg -- address of a null-terminated buffer of input (which may or may
!!    not include a newline)
!! state change -- the number of characters in arg1 (including newline,
!!    excluding nullbyte) is added to the variable charct, the number of words
!!    in arg1 is added to the variable wordct, and if a newline is encuontered,
!!    1 is added to linect
!! return -- the address of a null-terminated, translated buffer of output,
!!    ready for printing

translate:
	PUSH	BX		! save registers
	PUSH	BP
	PUSH	DX
	MOV	BP,SP		! set up BP
	MOV	BX,8(BP)	! BX contains address of characters
	MOV	DX,0		! not now inside a word

1:	CMPB	(BX),0		! if the char is a nullbyte, exit loop
	JE	9f	

	CMPB	(BX),65		! check if the char is upper-case
	JL	4f		! if it's lower, we're not in a word
	CMPB	(BX),91
	JL	2f		! if it's lower than 91, it is in a word
	CMPB	(BX),97		! also check if it's lower-case
	JL	4f		! since we already checked upper-case,this works
	CMPB	(BX),123	! 122 is z, so check if it's below 123
	JL	2f		
4:	MOV	DX,0		! otherwise, we're not in a word

7:	CMPB	(BX),'\n'	! check if the character is a newline
	JE	5f		

8:	MOVB	AL,(inchar)	! check if character is the same as inchar
	CMPB	(BX),AL
	JE	1f
6:	ADDB	(charct),1	! add one to charct
	INC	BX		! then move on to next character
	JMP	1b

9:	POP	DX		! restore registers
	POP	BP
	POP	BX
	RET

1:	MOVB	AL,(outchar)	! if the character is the same as inchar,
	MOVB	(BX),AL		! replace it with outchar
	JMP	6b

2:	CMP	DX,0		! if the char is a letter, we're not in a word
	JNE	3f
	ADDB	(wordct),1	! then add one to word count
	MOV	DX,1
3:	JMP	7b		! otherwise continue, since we're in a word

5:	ADDB	(linect),1	! add one to linect if the char is a newline
	JMP	8b

!! print_summary
!! 0 args
!! state change -- the cuonts of characters, words, and lines encountered in
!!    input (after the first line of input) are printed on the standard error
!!    _STDERR, together with labels, in the format specified
!! return -- none

print_summary:
	PUSH	sum		! print summary string
	CALL	printstr
	ADD	SP,2		! clean up stack

	PUSH	(charct)	! print number of characters
	PUSH	chars		! and the string 'characters'
	CALL	print_helper
	ADD	SP,4		! clean up stack

	PUSH	(wordct)	! print number of words
	PUSH	words		! and the string 'words'
	CALL	print_helper
	ADD	SP,4		! clean up stack

	PUSH	(linect)	! print number of lines
	PUSH	lines		! and the string 'lines'
	CALL	print_helper
	ADD	SP,4		! clean up stack

	RET

!! print_helper -- helps the print_summary function print output
!! 2 args -- arg1 is the address of the characters, arg2 is the decimal number
!! state change -- print decimal number on standard error, print string with
!!    printstr function
!! return -- none

print_helper:
	PUSH	BX		! save registers
	PUSH	BP
	PUSH	CX
	MOV	BP,SP		! set up BP
	MOV	BX,8(BP)	! BX holds arg1
	MOV	CX,10(BP)	! CX holds arg2

	PUSH	CX		! print the decimal number
	PUSH	_STDERR		! on standard error
	CALL	printdec
	ADD	SP,4		! clean up stack

	PUSH	BX		! calculate the string length 
	CALL	strlen		! to be used as parameter for stderr
	ADD	SP,2		! clean up stack

	PUSH	AX		! print string
	PUSH	BX
	PUSH	_STDERR		! on standard error
	PUSH	_WRITE
	SYS
	ADD	SP,8		! clean up stack

	POP	CX		! restore registers
	POP	BP
	POP	BX
	RET


.SECT .DATA

prompt:
.ASCIZ	"This program takes two different input characters and replaces each\noccurence of the first character with the second.\n Example input: s S (this will capitalize every occurence of the letter s) \nPlease enter your input:\n"

prompt2:
.ASCIZ	"Enter your input to be translated (CTRL+D to quit):\n"

sum:
.ASCIZ	"Summary:\n "

chars:
.ASCIZ	" characters\n "

words:
.ASCIZ	" words\n "

lines:
.ASCIZ	" lines\n"

error:
.ASCIZ	"Two strings of the same length were not provided!\n"

inbuff:
	.SPACE	MAXBUFF

size:
	.WORD	0
	
.SECT .BSS

inchar:
	.BYTE	0

outchar:
	.BYTE	0

charct:
	.WORD	0

wordct:
	.WORD	0

linect:
	.WORD	0

