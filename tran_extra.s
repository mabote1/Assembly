! Assembly program to translate certain characters
! Includes extra options, such as whitespace counter, a counter for the number
!   of changes made after translating, and it has the option to translate
!   multiple characters

!!     Example input/output:
!!       abcd ABCD
!!       That dastardly assembly code!
!!	 ThAt DAstArDly AseemBly CoDe!
!!	 (press CTRL+D for summary)
!!       Summary:
!!        30 characters
!!        3 whitespace characters
!!        4 words
!!        1 line(s)
!!        9 changes

! Tommy Markley 4/2012 - 5/2012

        _EXIT   = 1             
        _READ   = 3             
        _WRITE  = 4             
        _STDIN  = 0             
        _STDOUT = 1
        _GETCHAR = 117
	_STDERR	= 2
	MAXBUFF	= 1000

.SECT .TEXT                     
start:

	PUSH	prompt2-prompt	! print the user prompt
	PUSH	prompt
	PUSH	_STDERR		! on standard error
	PUSH	_WRITE
	SYS
	ADD	SP,8		! clean up stack

	PUSH	prompt3-prompt2	! continue printing the beginning prompt
	PUSH	prompt2
	PUSH	_STDERR		! on standard error
	PUSH	_WRITE
	SYS
	ADD	SP,8		! clean up stack

	PUSH	MAXBUFF		! want one character, a space, second character
	PUSH	inbuff		! will store the first line of input
	CALL	getline1
	ADD	SP,4		! clean up stack

	PUSH	inbuff		! use chars manipulated by getline for gettrans
	PUSH	inchar
	PUSH	outchar
	PUSH	brange
	PUSH	erange
	CALL	gettrans
	ADD	SP,10		! clean up stack

	CMP	AX,2
	JE	5f

	CMP	AX,0		! if gettrans returned 0, print error
	JE	8f

	JMP	6f

5:	MOV	(range),AX

6:	PUSH	sum-prompt3	! print the second user prompt
	PUSH	prompt3
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

	CMPB	(range),2
	JNE	2f
	PUSH	inbuff
	PUSH	brange
	PUSH	erange
	CALL	translate2
	ADD	SP,2
	JMP	3f

2:	PUSH	inbuff		! inbuff holds chars to be translated
	CALL	translate
	ADD	SP,2		! clean up stack

3:	CALL	printnl

	! print output
        PUSH    (size)          ! number of characters
        PUSH    inbuff		! print string inbuff
        PUSH    _STDOUT         ! on standard output
        PUSH    _WRITE
        SYS
        ADD     SP,8            ! clean up stack

	CALL	printnl

	CMPB	(size),0	! if no characters were read from getline, exit
	JNE	1b		! otherwise read more

	CALL	print_summary	! give the user a summary
	JMP	9f

8:	PUSH	error		! print error message for a string mismatch
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
	JMP	1b

9:	MOVB	(BX),0		! put a nullbyte at the end of the char string
	MOV	AX,BX		! put the number of characters read in AX
	SUB	AX,8(BP)	! subtract original address of BX to get size

	POP	CX		! restore values of registers
	POP	BP
	POP	BX
	RET


!! getline1
!! same as getline except this is used for the translation input

getline1:
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
	CMPB	AL,'\n'
	JNE	1b

9:	MOVB	(BX),0		! put a nullbyte at the end of the char string
	MOV	AX,BX		! put the number of characters read in AX
	SUB	AX,8(BP)	! subtract original address of BX to get size

	POP	CX		! restore values of registers
	POP	BP
	POP	BX
	RET

!! gettrans
!! 3 args -- two addresses to strings, outchar and inchar, and a description
!!    line, consisting of two characters separated by a space character
!! state change -- prepare for translation of characters from the first string
!!    to the corresponding characters of the second string
!! return -- integer 1 on success, or 0 if two strings of the same length were
!!    not provided

gettrans:
	PUSH	BX		! save registers
	PUSH	BP
	MOV	BP,SP		! set up BP
	MOV	BX,14(BP)	! BX holds address of inbuff

	MOVB	AL,1(BX)	! check the second character entered by the user
	CMPB	AL,'-'		! if it's a hyphen, then they gave a range
	JE	5f		! so jump ahead to get the range values

	MOV	SI,12(BP)	! SI holds address of inchar
	MOV	DI,10(BP)	! DI holds address of outchar

1:	MOVB	AL,(BX)		! put character in current address of BX in AL
	CMPB	AL,' '		! if the char is a space, done with inchar
	JE	2f
	MOVB	(SI),AL		! put the character into inchar
	INC	BX		! go to the next character in inbuff
	INC	SI		! and the next character in inchar
	ADDB	(numchars1),1	
	JMP	1b		! check again
2:	INC	BX		! skip the space and go to outchar

3:	MOVB	AL,(BX)		
	CMPB	AL,'\n'		! if newline, done with description line
	JE	4f
	MOVB	(DI),AL		! otherwise put the char in outchar
	INC	BX		! go to next character in inbuff
	INC	DI		! go to next character in outchar
	ADDB	(numchars2),1
	JMP	3b		! check next character

4:	MOVB	AL,(numchars1)	
	CMPB	(numchars2),AL	! check if both strings were same length
	JNE	8f	
	MOV	AX,1		! if they were, return 1
	JMP	9f

8:	MOV	AX,0		! if not, return 0
9:	POP	BP		! restore registers
	POP	BX
	RET

5:	MOV	SI,8(BP)	! holds address of brange
	MOV	DI,6(BP)	! holds address of erange
	MOVB	AL,(BX)	
	MOVB	(SI),AL

	MOVB	AL,2(BX)
	MOVB	(DI),AL
	MOV	AX,2
	JMP	9b


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
	PUSH	CX
	PUSH	DX
	MOV	BP,SP		! set up BP
	MOV	BX,10(BP)	! BX contains address of characters
	MOV	DX,0		! not now inside a word
	MOV	CX,0		! CX is a counter for inchar,outchar
	MOV	SI,inchar	! SI holds address of inchar
	MOV	DI,outchar	! DI holds address of outchar

1:	CMPB	(BX),0		! if the char is a nullbyte, exit loop
	JE	9f

	CMPB	(BX),32		! check if the char is a space
	JNE	2f
	ADDB	(whitespace),1	! add one to whitespace if it is

2:				! otherwise continue	

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
	JNE	5f
	ADDB	(linect),1	! add one to linect if the char is a newline

5:	MOV	AX,(numchars1)
	CMP	CX,AX		! see if (numchars1) chars have been checked
	JG	6f

	MOVB	AL,(SI)		! check if character is the same as inchar
	CMPB	(BX),AL
	JE	1f

	INC	CX		! have to check all chars in inchar
	INC	SI		! by incrementing address of SI
	JMP 	5b

6:	ADDB	(charct),1	! add one to charct
	INC	BX		! then move on to next character
	MOV	SI,inchar	! reset the addresses
	MOV	DI,outchar
	MOV	CX,0		! reset CX
	JMP	1b		! go to next character in inbuff

9:	POP	DX		! restore registers
	POP	CX
	POP	BP
	POP	BX
	RET

1:	ADD	DI,CX		! replace char with correct char from outchar
	MOVB	AL,(DI)		! since the character is same as inchar,
	MOVB	(BX),AL		! replace it with outchar
	ADDB	(changes),1	! add 1 to number of changes
	JMP	6b

2:	CMP	DX,0		! if the char is a letter, we're not in a word
	JNE	3f
	ADDB	(wordct),1	! then add one to word count
	MOV	DX,1
3:	JMP	7b		! otherwise continue, since we're in a word
	

!! translate2
!! if user gives a range, use this function

translate2:

	PUSH	BX		! save registers
	PUSH	BP
	PUSH	DX
	MOV	BP,SP		! set up BP
	MOV	BX,12(BP)	! BX contains address of characters
	MOV	DX,0		! not now inside a word
	MOV	SI,10(BP)	! holds address of brange
	MOV	DI,8(BP)	! holds address of erange

1:	CMPB	(BX),0		! if the char is a nullbyte, exit loop
	JE	9f

	CMPB	(BX),32		! check if the char is a space
	JNE	2f
	ADDB	(whitespace),1	! add one to whitespace if it is

2:				! otherwise continue	

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
	JNE	5f
	ADDB	(linect),1	! add one to linect if the char is a newline

5:	MOVB	AL,(SI)
	CMPB	(BX),AL
	JL	6f

	MOVB	AL,(DI)
	CMPB	(BX),AL
	JG	6f

	JMP	1f

6:	ADDB	(charct),1	! add one to charct
	INC	BX		! then move on to next character
	JMP	1b		! go to next character in inbuff

9:	POP	DX		! restore registers
	POP	BP
	POP	BX
	RET

1:	SUBB	(BX),32		! replace it with outchar
	ADDB	(changes),1	! add 1 to number of changes
	JMP	6b

2:	CMP	DX,0		! if the char is a letter, we're not in a word
	JNE	3f
	ADDB	(wordct),1	! then add one to word count
	MOV	DX,1
3:	JMP	7b		! otherwise continue, since we're in a word

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

	PUSH	(whitespace)	! print number of whitespace characters
	PUSH	wchars		! and the string 'whitespace characters'
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

	PUSH	(changes)	! print number of changes
	PUSH	change		! and the string 'changes'
	CALL	print_helper
	ADD	SP,4		! clean up stack

	CALL	printnl		! put a newline at the end to look nice

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
.ASCIZ	"This program takes two strings of input characters and replaces each\noccurence of a character in the first string with the corresponding\ncharacter in the second.\n Example input: abc ABC  (have a bad couch --> hAve A BAd CouCh)\n\n"

prompt2:
.ASCIZ	"You also have the option of giving a range of lower-case letters to be\ncapitalized. For example: a-z capitalizes every occurence of any letter.\n\nPlease enter your translation input:\n"

prompt3:
.ASCIZ	"\nEnter your input to be translated (Enter,CTRL+D to translate):\n"

sum:
.ASCIZ	"Summary:\n "

chars:
.ASCIZ	" characters\n "

wchars:
.ASCIZ	" whitespace characters\n "

words:
.ASCIZ	" words\n "

lines:
.ASCIZ	" line(s)\n "

change:
.ASCIZ	" changes"

error:
.ASCIZ	"Two strings of the same length were not provided!\n"

inbuff:
	.SPACE	MAXBUFF

inchar:
	.SPACE	MAXBUFF

outchar:
	.SPACE	MAXBUFF

brange:
	.BYTE	0

erange:
	.BYTE	0

size:
	.WORD	0

range:
	.WORD	0
	
.SECT .BSS

numchars1:
	.WORD	0

numchars2:
	.WORD	0

charct:
	.WORD	0

wordct:
	.WORD	0

linect:
	.WORD	0

changes:
	.WORD	0

whitespace:
	.WORD	0