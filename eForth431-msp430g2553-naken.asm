;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This is a 430eForth assembler listing based on the original script from
; Dr. Chen Hanson Ting as described in his book: Zen and the Forth Language:
; EFORTH for the MSP430 from Texas Instruments (Kindle Edition). It was first
; written by him in IAR Assembler, then transferred to the CCS and now adapted
; by Michael Kalus for the naken_asm.
;
; MIT License
; ----------------------------------------------------------------------------
; Copyright (c) 2014 Dr. Chen-Hanson Ting  CCS Version    430eForth4.3
;           (c) 2018 Michael Kalus         Naken Version  430eForth4.3n
;           (c) 2018 Manfred Mahlow          Flash Tools  430eForth4.3n1
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
;furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 7/7/2012 430eForth1.0, from eForth86.asm and 430uForth
; 7/4/2012 Move 430uForth2.1 from IAR to CCS 5.2
; 8/5/2014 Move 430eForth2.2 to CCS 6.0.  Fix linkage of OVER.
;	Software UART at 2400 baud.
; 8/10/2014 430eForth2.3 9600 baud, thanks to Dirk Bruehl and
;	Michael Kalus of www.4e4th.org
; 8/10/2014 430eForth2.4 Restore ERASE and WRITE
; 8/20/2014 430eForth2.5 Test Segment D
; 8/25/2014 430eForth2.6 Turnkey
; 8/26/2014 430eForth2.7 Optimize
; 9/16/2014 430eForth3.1 Tail recursion, APP!
; 10/11/2014 430eForth4.1 Direct thread, more optimization
; 10/23/2014 430eForth4.2 Direct thread, pack lists
; 11/12/2014 430eForth4.2 Direct thread, final
;
; Build for and verified on MSP430G2 LaunchPad from TI
; Assembled with Code Composer Sudio 6.0 IDE
; Internal DCO at 8 MHz
; Hardware UART at 9600 baud. TXD and RXD must be crossed.

;CCS:   ;ting
;	.nolist 
;	.title "msp430 eForth 4.3" 
;	.cdecls C,LIST,"msp430g2553.h"  ; Include device header file 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 05/13/2018 Moved 430eForth4.3 from CSS to Michael Kohn's naken_asm (ver.
;            23 april 2018) - ok                                           ;mk
; 20180624 $," - bug fixed. Thanks to Manfred Mahlow.                      ;mk
; 20180628 DIGIT? : bug fix, 0= 0> were handled as numbers                 ;MM
; 20180629 FSCAN added, sets CP to the lowest free flash addr at BOOT time.
;          FSCAN is executed before COLD executes QUIT.
;          Version string changed in HI from 43n to 43n1.                  ;MM
; 20180630 ERASE and WRITE renamed to IERASE IWRITE due to name conflict   ;MM
; 20180701 LITERAL and ALIGNED revealed.                                   ;MM
; 20180707 Flash Test QFLASH ( a -- a ) added. Aborts with message ?flash
;          if a > EDM. (EDM = End of Dictionary Memory space in the flash) ;MM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;naken: ;mk
    .msp430 
    .include "msp430g2553.inc"  ; MCU-specific register equates for naken_asm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Direct Thread Model of eForth

; CCS: .equ ; naken: equ   ;mk
;;	CPU registers
tos	equ	R4
stack   equ	R5
ip	equ	R6
temp0	equ	R7
temp1	equ	R8
temp2	equ	R9
temp3	equ	R10

;; Macros
; CCS: <name> .macro ; naken: .macro <name>   ;mk
.macro pops	;DROP
	mov.w	@stack+,tos
    .endm

.macro pushs ;DUP
	decd.w	stack
	mov.w	tos,0(stack)
    .endm;; Constants

.macro INEXT ;mk renamed (dollar)NEXT to INEXT - inline code for NEXT.
	mov @ip+,pc	; fetch code address into PC
    .endm

.macro INEST ;mk renamed (dollar)NEST to INEST - inline code for NEST.
	.align	16  ; CCS: 2 bytes align ; naken: 16 bit align. mk
	call	#DOLST	; fetch code address into PC, W=PFA
    .endm

.macro ICONST ;mk renamed (dollar)CONST to ICONST - inline code calling DOCON.
	.align	16  ; CCS: 2 bytes align ; naken: 16 bit align. mk
	call	#DOCON	; fetch code address into PC, W=PFA
	.endm

;; Assembler constants

COMPO	equ	040H	;lexicon compile only bit
IMEDD	equ	080H	;lexicon immediate bit
MASKK	equ	07F1FH	;lexicon bit mask
CELLL	equ	2	;size of a cell
BASEE	equ	10	;default radix
VOCSS	equ	8	;depth of vocabulary stack
BKSPP	equ	8	;backspace
LF	    equ	10	;line feed
CRR	    equ	13	;carriage return
ERR	    equ	27	;error escape
TIC	    equ	39	;tick
CALLL	equ	012B0H	;NOP CALL opcodes

UPP	    equ	200H
DPP	    equ	220H
SPP	    equ	378H	;data stack
TIBB	equ	380H	;terminal input buffer
RPP	    equ	3F8H	;return stacl
CODEE	equ	0C000H	;code dictionary
COLDD	equ	0FFFEH	;cold start vector
EM	    equ	0FFFFH	;top of memory

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.list
;;;;
;; Main entry points and COLD start data

;	.text       ; CCS: Predefined Memory Segment Name : Main memory (flash or ROM)
    .org 0C000H ; naken : MSP430G2553 main memory : C000-FFFF = 16KB flash ROM 
                ;                                   FFE0-FFFF = interrupt vectors

;	.global	main ; CCS: File Reference Directive 
                 ; unused in naken

main: 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Device dependent I/O

;   ?KEY	( -- F | c T )
;	Return input character.
	.dw	0
	.db	4,"?KEY",0
QKEY:
	pushs
QKEY1:
	BIT.B   #UCA0RXIFG,&IFG2
	JZ	FALSE	;return false flag
	MOV.B   &UCA0RXBUF,tos	; read character into TOS
	pushs
	jmp	TRUE

;   KEY	( -- c )
;	Return input character.
	.dw	QKEY-6
	.db 3,"KEY"
KEY: ;mk naken needs colon after label. 
	pushs
KEY1:
	BIT.B   #UCA0RXIFG,&IFG2
	JZ	KEY1
	MOV.B   &UCA0RXBUF,tos	; read character into TOS
	INEXT

;   EMIT	( c -- )
;	Send character c to the output device.
	.dw	KEY-4
	.db 4,"EMIT",0
EMIT:
EMIT1:
	BIT.B   #UCA0TXIFG,&IFG2
	JZ	EMIT1
	MOV.B   tos,&UCA0TXBUF
	pops
	INEXT

;   !IO	( -- )
;	Initialize the serial I/O devices.
;	.dw	EMIT-6
;	.db 3,"!IO"
STOIO:
; 8MHz
	mov.b   &CALBC1_8MHZ, &BCSCTL1   ; Set DCO
	mov.b   &CALDCO_8MHZ, &DCOCTL	; to 8 MHz.
	mov.b   #006h, &P1SEL	; Use P1.1/P1.2 for USCI_A0
	mov.b   #006h, &P1SEL2	; Use P1.1/P1.2 for USCI_A0
; Configure UART (Koch)
	bis.b   #UCSSEL_2,&UCA0CTL1	;db2 SMCLK
	mov.b   #65,&UCA0BR0	;db3 8MHz 9600 Insgesamt &833 = $341
	mov.b   #3,&UCA0BR1	;db4 8MHz 9600
	mov.b   #UCBRS_2,&UCA0MCTL	;db5 Modulation UCBRSx = 2
	bic.b   #UCSWRST,&UCA0CTL1	;db6 **Initialize USCI
	INEXT	;called from COLD

;; The kernel

;   doLIT	( -- w )
;	Push an inline literal.
;	.dw	STOIO-4
;	.db COMPO+5,"doLIT"
DOLIT:
	pushs
	mov	@ip+,tos
	INEXT

;   doCON	( -- a )
;	Run time routine for CONSTANT, VARIABLE and CREATE.
;	.dw	DOLIT-6
;	.db COMPO+5,"doCON"
DOCON:
	pushs
	pop	tos
	mov	@tos,tos
	INEXT

;   doLIST	( -- )
;	Process colon list..
;	.dw	EMIT-6
;	.db 6,"doLIST",0
DOLST:
	mov	ip,temp0	;exchange pointers
	pop	ip	;push return stack
	push	temp0	;restore the pointers
	INEXT

;   EXIT	( -- )
;	Terminate a colon definition.
	.dw	EMIT-6
	.db 4,"EXIT",0
EXIT:
	mov	@sp+,ip
	INEXT

;   EXECUTE	( ca -- )
;	Execute the word at ca.
	.dw	EXIT-6
	.db 7,"EXECUTE"
EXECU:
	mov	tos,temp0
	pops
	br	temp0

;   @EXECUTE	( a -- )
;	Execute vector stored in address a.
	.dw	EXECU-8
	.db 8,"@EXECUTE",0
ATEXE:
	mov	@tos,temp0
	pops
	br	temp0

;   branch	( -- )
;	Branch to an inline address.
;	.dw	ATEXE-10
;	.db COMPO+6,"branch",0
BRAN:
	mov	@ip+,ip
	INEXT

;   ?branch	( f -- )
;	Branch if flag is zero.
;	.dw	BRAN-8
;	.db COMPO+7,"?branch"
QBRAN:
	tst	tos
	pops
	jz	BRAN
	jmp	SKIP

;   next	( -- )
;	Run time code for the single index loop.
;	: next ( -- ) \ hilevel model
;	r> r> dup if 1 - >r @ >r exit then drop cell+ >r ;
;	.dw	QBRAB-8
;	.db COMPO+4,"next",0
DONXT:
	dec	0(sp)   ;decrement index
	jge	BRAN	;loop back
	incd.w	sp	;discard index
SKIP:
	incd.w	ip	;exit loop
	INEXT

;   !	( w a -- )
;	Pop the data stack to memory.
	.dw	ATEXE-10
	.db 1,"!"
STORE:
	mov.w	@stack+,0(tos)
	pops
	INEXT

;   @	( a -- w )
;	Push memory location to the data stack.
	.dw	STORE-2
	.db 1,"@"
AT:
	mov.w	@tos,tos
	INEXT

;   C!	( c b -- )
;	Pop the data stack to byte memory.
	.dw	AT-2
	.db 2,"C!",0
CSTOR:
	mov.b	@stack+,0(tos)
	inc	stack
	pops
	INEXT

;   C@	( b -- c )
;	Push byte memory location to the data stack.
	.dw	CSTOR-4
	.db 2,"C@",0
CAT:
	mov.b	@tos,tos
	INEXT

;   RP!	( -- )
;	init return stack pointer.
;	.dw	CAT-4
;	.db 3,"RP!"
RPSTO:
	mov	#RPP,SP	;init return stack
	INEXT

;   R>	( -- w )
;	Pop the return stack to the data stack.
	.dw	CAT-4
	.db 2,"R",3EH,0
RFROM:
	pushs
	pop	tos
	INEXT

;   R@	( -- w )
;	Copy top of return stack to the data stack.
	.dw	RFROM-4
	.db 2,"R@",0
RAT:
	pushs
	mov	0(sp),tos
	INEXT

;   >R	( w -- )
;	Push the data stack to the return stack.
	.dw	RAT-4
	.db COMPO+2,">R",0
TOR:
	push	tos
	pops
	INEXT

;   SP!	( -- )
;	Init data stack pointer.
;	.dw	SPAT-4
;	.db 3,"SP!"
SPSTO:
	mov	#SPP,stack	;init parameter stack
	clr	tos
	INEXT

;   DROP	( w -- )
;	Discard top stack item.
	.dw	TOR-4
	.db 4,"DROP",0
DROP:
	pops
	INEXT

;   DUP	( w -- w w )
;	Duplicate the top stack item.
	.dw	DROP-6
	.db 3,"DUP"
DUPP:
	pushs
	INEXT

;   SWAP	( w1 w2 -- w2 w1 )
;	Exchange top two stack items.
	.dw	DUPP-4
	.db 4,"SWAP",0
SWAP:
	mov.w	tos,temp0
	mov.w	@stack,tos
	mov.w	temp0,0(stack)
	INEXT

;   OVER	( w1 w2 -- w1 w2 w1 )
;	Copy second stack item to top.
	.dw	SWAP-6
	.db 4,"OVER",0
OVER:
	mov.w	@stack,temp0
	pushs
	mov.w	temp0,tos
	INEXT

;   0<	( n -- t )
;	Return true if n is negative.
	.dw	OVER-6
	.db 2,"0",3CH,0
ZLESS:
	tst	tos
	jn	TRUE
FALSE:
	clr	tos
	INEXT
TRUE:
	mov	#0x-1,tos
	INEXT

;   AND	( w w -- w )
;	Bitwise AND.
	.dw	ZLESS-4
	.db 3,"AND"
ANDD:
	and	@stack+,tos
	INEXT

;   OR	( w w -- w )
;	Bitwise inclusive OR.
	.dw	ANDD-4
	.db 2,"OR",0
ORR:
	bis	@stack+,tos
	INEXT

;   XOR	( w w -- w )
;	Bitwise exclusive OR.
	.dw	ORR-4
	.db 3,"XOR"
XORR:
	xor	@stack+,tos
	INEXT

;   UM+	( w w -- w cy )
;	Add two numbers, return the sum and carry flag.
	.dw	XORR-4
	.db 3,"UM+"
UPLUS:
	add	@stack,tos
	mov	tos,0(stack)
	clr	tos
	rlc	tos
	INEXT

;; Common functions

;   ?DUP	( w -- w w | 0 )
;	Dup tos if its is not zero.
	.dw	UPLUS-4
	.db 4,"?DUP",0
QDUP:
	tst	tos
	jnz	DUPP
	INEXT

;   ROT	( w1 w2 w3 -- w2 w3 w1 )
;	Rot 3rd item to top.
	.dw	QDUP-6
	.db 3,"ROT"
ROT:
	mov.w	0(stack),temp0
	mov.w	tos,0(stack)
	mov.w	2(stack),tos
	mov.w	temp0,2(stack)
	INEXT

;   2DROP	( w w -- )
;	Discard two items on stack.
	.dw	ROT-4
	.db 5,"2DROP"
DDROP:
	incd.w	stack
	pops
	INEXT

;   2DUP	( w1 w2 -- w1 w2 w1 w2 )
;	Duplicate top two items.
	.dw	DDROP-6
	.db 4,"2DUP",0
DDUP:
	mov.w	@stack,temp0
	pushs
	decd.w	stack
	mov.w	temp0,0(stack)
	INEXT

;   +	( w w -- sum )
;	Add top two items.
	.dw	DDUP-6
	.db 1,"+"
PLUS:
	add	@stack+,tos
	INEXT

;   D+	( d d -- d )
;	Double addition, as an example using UM+.
;
	.dw	PLUS-2
	.db 2,"D+",0
DPLUS:
	mov.w	@stack+,temp0
	mov.w	@stack+,temp1
	add.w	temp0,0(stack)
	addc	temp1,tos
	INEXT

;   NOT	( w -- w )
;	One's complement of tos.
	.dw	DPLUS-4
	.db 3,"NOT"
INVER:
	inv	tos
	INEXT

;   NEGATE	( n -- -n )
;	Two's complement of tos.
	.dw	INVER-4
	.db 6,"NEGATE",0
NEGAT:
	inv	tos
	inc	tos
	INEXT

;   DNEGATE	( d -- -d )
;	Two's complement of top double.
	.dw	NEGAT-8
	.db 7,"DNEGATE"
DNEGA:
	inv	tos
	inv 0(stack)
	inc	0(stack)
	addc	#0,tos
	INEXT

;   -	( n1 n2 -- n1-n2 )
;	Subtraction.
	.dw	DNEGA-8
	.db 1,"-"
SUBB:
	sub	@stack+,tos
	jmp	NEGAT

;   ABS	( n -- n )
;	Return the absolute value of n.
	.dw	SUBB-2
	.db 3,"ABS"
ABSS:
	tst.w	tos
	jn	NEGAT
	INEXT

;   =	( w w -- t )
;	Return true if top two are equal.
	.dw	ABSS-4
	.db 1,3DH
EQUAL:
	xor	@stack+,tos
	jnz	FALSE
	jmp	TRUE

;   U<	( u u -- t )
;	Unsigned compare of top two items.
	.dw	EQUAL-2
	.db 2,"U",3CH,0
ULESS:
	mov	@stack+,temp0
	cmp	tos,temp0
	subc	tos,tos
	INEXT

;   <	( n1 n2 -- t )
;	Signed compare of top two items.
	.dw	ULESS-4
	.db 1,3CH
LESS:
	cmp	@stack+,tos
	jz	FALSE
	jge	TRUE
	jmp	FALSE

;   >	( n1 n2 -- t )
;	Signed compare of top two items.
	.dw	LESS-2
	.db 1,3EH
GREAT:
	cmp	@stack+,tos
	jge	FALSE
	jmp	TRUE

;   MAX	( n n -- n )
;	Return the greater of two top stack items.
	.dw	GREAT-2
	.db 3,"MAX"
MAX:
	cmp	0(stack),tos
MAX1:
	jl	DROP
	incd.w	stack
	INEXT

;   MIN	( n n -- n )
;	Return the smaller of top two stack items.
	.dw	MAX-4
	.db 3,"MIN"
MIN:
	cmp	tos,0(stack)
	jmp	MAX1

;; Divide

;   UM/MOD	( udl udh u -- ur uq )
;	Unsigned divide of a double by a single. Return mod and quotient.
	.dw	MIN-4
	.db 6,"UM/MOD",0
UMMOD:
	mov	tos,temp0
	pops
	mov	#17,temp1
UMMOD2:
	cmp	temp0,tos
	jnc	UMMOD3
	sub	temp0,tos
	setc
	jmp	UMMOD4
UMMOD3:
	clrc
UMMOD4:
	rlc	0(stack)
	rlc	tos
	dec	temp1
	jnz	UMMOD2
	rra	tos
	mov	tos,temp0
	mov	0(stack),tos
	mov	temp0,0(stack)
	INEXT

;   M/MOD	( d n -- r q )
;	Signed floored divide of double by single. Return mod and quotient.
	.dw	UMMOD-8
	.db 5,"M/MOD"
MSMOD:
	INEST
	.dw	DUPP,ZLESS,DUPP,TOR,QBRAN,MMOD1
	.dw	NEGAT,TOR,DNEGA,RFROM
MMOD1:
	.dw	TOR,DUPP,ZLESS,QBRAN,MMOD2
	.dw	RAT,PLUS
MMOD2:
	.dw	RFROM,UMMOD,RFROM,QBRAN,MMOD3
	.dw	SWAP,NEGAT,SWAP
MMOD3:
	.dw	EXIT

;   /MOD	( n n -- r q )
;	Signed divide. Return mod and quotient.
	.dw	MSMOD-6
	.db 4,"/MOD",0
SLMOD:
	INEST
	.dw	OVER,ZLESS,SWAP,MSMOD,EXIT

;   MOD	( n n -- r )
;	Signed divide. Return mod only.
	.dw	SLMOD-6
	.db 3,"MOD"
MODD:
	INEST
	.dw	SLMOD,DROP,EXIT

;   /	( n n -- q )
;	Signed divide. Return quotient only.
	.dw	MODD-4
	.db 1,"/"
SLASH:
	INEST
	.dw	SLMOD,SWAP,DROP,EXIT

;; Multiply

;   UM*	( u u -- ud )
;	Unsigned multiply. Return double product.
	.dw	SLASH-2
	.db 3,"UM*"
UMSTA:
	clr	temp0
	mov	#16,temp1
UMSTA2:
	bit	#1,0(stack)
	jz	UMSTA3
	add	tos,temp0
	jmp	UMSTA4
UMSTA3:
	clrc
UMSTA4:
	rrc	temp0
	rrc	0(stack)
	dec	temp1
	jnz	UMSTA2
	mov	temp0,tos
	INEXT

;   *	( n n -- n )
;	Signed multiply. Return single product.
	.dw	UMSTA-4
	.db 1,"*"
STAR:
	INEST
	.dw	UMSTA,DROP,EXIT

;   M*	( n n -- d )
;	Signed multiply. Return double product.
	.dw	STAR-2
	.db 2,"M*",0
MSTAR:
	INEST
	.dw	DDUP,XORR,ZLESS,TOR
	.dw	ABSS,SWAP,ABSS,UMSTA,RFROM
	.dw	QBRAN,MSTA1
	.dw	DNEGA
MSTA1:
	.dw	EXIT

;   */MOD	( n1 n2 n3 -- r q )
;	Multiply n1 and n2, then divide by n3. Return mod and quotient.
	.dw	MSTAR-4
	.db 5,"*/MOD"
SSMOD:
	INEST
	.dw	TOR,MSTAR,RFROM,MSMOD,EXIT

;   */	( n1 n2 n3 -- q )
;	Multiply n1 by n2, then divide by n3. Return quotient only.
	.dw	SSMOD-6
	.db 2,"*/",0
STASL:
	INEST
	.dw	SSMOD,SWAP,DROP,EXIT

;; Miscellaneous

;   1+	( a -- a+1 )
;	Increment.
;	.dw	STASL-4
;	.db 2,"1+",0
ONEP:
	add	#1,tos
	INEXT

;   1-	( a -- a-1 )
;	Decrement
;	.dw	ONEP-4
;	.db 2,"1-",0
ONEM:
	sub	#1,tos
	INEXT

;   2+	( a -- a+2 )
;	Add cell size in byte to address.
;	.dw	ONEM-4
;	.db 2,"2+",0
CELLP:
	add	#2,tos
	INEXT

;   2-	( a -- a-2 )
;	Subtract cell size in byte from address.
;	.dw	CELLP-4
;	.db 2,"2-",0
CELLM:
	sub	#2,tos
	INEXT

;   2*	( n -- 2*n )
;	Multiply tos by cell size in bytes.
	.dw	STASL-4
	.db 2,"2*",0
CELLS:
	rla	tos
	INEXT

;   2/	( n -- n/2 )
;	Divide tos by cell size in bytes.
	.dw	CELLS-4
	.db 2,"2/",0
TWOSL:
	rra	tos
	INEXT

;   ALIGNED	( b -- a )
;	Align address to the cell boundary.
	.dw	TWOSL-4
	.db 7,"ALIGNED"
ALGND:
	add	#1,tos
	bic	#1,tos
	INEXT

;   >CHAR	( c -- c )
;	Filter non-printing characters.
;	.dw	TWOSL-4
;	.db 5,">CHAR"
TCHAR:
	INEST
	.dw	BLANK,MAX	;mask msb
	.dw	DOLIT,126,MIN	;check for printable
	.dw	EXIT

;   DEPTH	( -- n )
;	Return the depth of the data stack.
;	.dw	TWOSL-4      ;MM180701
  .dw ALGND-8      ;
	.db 5,"DEPTH"
DEPTH:
	mov	stack,temp0
	pushs
	mov	#SPP,tos
	sub	temp0,tos
	rra	tos
	INEXT

;   PICK	( ... +n -- ... w )
;	Copy the nth stack item to tos.
	.dw	DEPTH-6
	.db 4,"PICK",0
PICK:
	rla	tos
	add stack,tos
	mov	@tos,tos
	INEXT

;; Memory access

;   +!	( n a -- )
;	Add n to the contents at address a.
	.dw	PICK-6
	.db 2,"+!",0
PSTOR:
	add @stack+,0(tos)
	pops
	INEXT

;   COUNT	( b -- b +n )
;	Return count byte of a string and add 1 to byte address.
	.dw	PSTOR-4
	.db 5,"COUNT"
COUNT:
	mov.b	@tos+,temp0
	pushs
	mov	temp0,tos
	INEXT

;   CMOVE	( b1 b2 u -- )
;	Copy u bytes from b1 to b2.
	.dw	COUNT-6
	.db 5,"CMOVE"
CMOVE:
	mov	@stack+,temp0	;destination
	mov	@stack+,temp1	;source
	jmp	CMOVE2
CMOVE1:
	mov.b	@temp1+,0(temp0)
	inc	temp0
CMOVE2:
	dec	tos
	jn	CMOVE3	;I need a jp.  Oh, well.
	jmp	CMOVE1
CMOVE3:
	JMP	DROP

;   FILL	( b u c -- )
;	Fill u bytes of character c to area beginning at b.
	.dw	CMOVE-6
	.db 4,"FILL",0
FILL:
	mov	@stack+,temp0	;count
	mov	@stack+,temp1	;destination
	jmp	FIL2
FIL1:
	mov.b	tos,0(temp1)
	inc	temp1
FIL2:
	dec	temp0
	jn	FIL3
	jmp	FIL1
FIL3:
	JMP	DROP

;; User variables

;   'BOOT	( -- a )
;	The application startup vector.
	.dw	FILL-6
	.db 5,"'BOOT"
TBOOT:
	ICONST
	.dw	200H

;   BASE	( -- a )
;	Storage of the radix base for numeric I/O.
	.dw	TBOOT-6
	.db 4,"BASE",0
BASE:
	ICONST
	.dw	202H

;   tmp	( -- a )
;	A temporary storage location used in parse and find.
;	.dw	BASE-6
;	.db COMPO+3,"tmp"
TEMP:
	ICONST
	.dw	204H

;   #TIB	( -- a )
;	Hold the character pointer while parsing input stream.
;	.dw	BASE-6
;	.db 4,"#TIB",0
NTIB:
	ICONST
	.dw	206H

;   >IN	( -- a )
;	Hold the character pointer while parsing input stream.
;	.dw	NTIB-6
;	.db 3,">IN"
INN:
	ICONST
	.dw	208H

;   HLD	( -- a )
;	Hold a pointer in building a numeric output string.
;	.dw	INN-4
;	.db 3,"HLD"
HLD:
	ICONST
	.dw	20AH

;   'EVAL	( -- a )
;	A area to specify vocabulary search order.
;	.dw	HLD-4
;	.db 5,"'EVAL"
TEVAL:
	ICONST
	.dw	20CH

;   CONTEXT	( -- a )
;	A area to specify vocabulary search order.
;	.dw	TEVAL-6
;	.db 7,"CONTEXT"
CNTXT:
	ICONST
	.dw	20EH

;   CP	( -- a )
;	Point to the top of the code dictionary.
	.dw	BASE-6
	.db 2,"CP",0
CP:
	ICONST
	.dw	210H

;   DP	( -- a )
;	Point to the bottom of the free ram area.
	.dw	CP-4
	.db 2,"DP",0
DP:
	ICONST
	.dw	212H

;   LAST	( -- a )
;	Point to the last name in the name dictionary.
;	.dw	DP-4
;	.db 4,"LAST",0
LAST:
	ICONST
	.dw	214H

;   HERE	( -- a )
;	Return the top of the code dictionary.
	.dw	DP-4
	.db 4,"HERE",0
HERE:
	INEST
	.dw	DP,AT,EXIT

;   PAD	( -- a )
;	Return the address of a temporary buffer.
	.dw	HERE-6
	.db 3,"PAD"
PAD:
	INEST
	.dw	HERE,DOLIT,80,PLUS,EXIT

;   TIB	( -- a )
;	Return the address of the terminal input buffer.
	.dw	PAD-4
	.db 3,"TIB"
TIB:
	ICONST
	.dw	TIBB

;; Numeric output, single precision

;   DIGIT	( u -- c )
;	Convert digit u to a character.
;	.dw	LAST-6
;	.db 5,"DIGIT"
DIGIT:
	cmp	#10,tos
	jl	DIGIT1
	add	#7,tos
DIGIT1:
	add	#"0",tos
	INEXT

;   EXTRACT	( n base -- n c )
;	Extract the least significant digit from n.
;	.dw	DIGIT-6
;	.db 7,"EXTRACT"
EXTRC:
	INEST
	.dw	DOLIT,0,SWAP,UMMOD
	.dw	SWAP,DIGIT,EXIT

;   <#	( -- )
;	Initiate the numeric output process.
	.dw	TIB-4
	.db 2,"<#",0
BDIGS:
	INEST
	.dw	PAD,HLD,STORE,EXIT

;   HOLD	( c -- )
;	Insert a character into the numeric output string.
	.dw	BDIGS-4
	.db 4,"HOLD",0
HOLD:
	INEST
	.dw	HLD,AT,ONEM
	.dw	DUPP,HLD,STORE,CSTOR,EXIT

;   #	( u -- u )
;	Extract one digit from u and append the digit to output string.
	.dw	HOLD-6
	.db 1,"#"
DIG:
	INEST
	.dw	BASE,AT,EXTRC,HOLD,EXIT

;   #S	( u -- 0 )
;	Convert u until all digits are added to the output string.
	.dw	DIG-2
	.db 2,"#S",0
DIGS:
	INEST
DIGS1:
	.dw	DIG,DUPP,QBRAN,DIGS2
	.dw	BRAN,DIGS1
DIGS2:
	.dw	EXIT

;   SIGN	( n -- )
;	Add a minus sign to the numeric output string.
	.dw	DIGS-4
	.db 4,"SIGN",0
SIGN:
	INEST
	.dw	ZLESS,QBRAN,SIGN1
	.dw	DOLIT,"-",HOLD
SIGN1:
	.dw	EXIT

;   #>	( w -- b u )
;	Prepare the output string to be TYPE'd.
	.dw	SIGN-6
	.db 2,"#",3EH,0
EDIGS:
	INEST
	.dw	DROP,HLD,AT
	.dw	PAD,OVER,SUBB,EXIT

;   str	( n -- b u )
;	Convert a signed integer to a numeric string.
;	.dw	EDIGS-4
;	.db 3,"str"
STR:
	INEST
	.dw	DUPP,TOR,ABSS
	.dw	BDIGS,DIGS,RFROM
	.dw	SIGN,EDIGS,EXIT

;   HEX	( -- )
;	Use radix 16 as base for numeric conversions.
	.dw	EDIGS-4
	.db 3,"HEX"
HEX:
	mov	#16,&0x202
	INEXT

;   DECIMAL	( -- )
;	Use radix 10 as base for numeric conversions.
	.dw	HEX-4
	.db 7,"DECIMAL"
DECIM:
	mov	#10,&0x202
	INEXT

;; Numeric input, single precision

;   DIGIT?	( c base -- u t )
;	Convert a character to its numeric value. A flag indicates success.
;	.dw	DECIM-8
;	.db 6,"DIGIT?",0
DIGTQ:
	mov	@stack,temp0
	sub	#"0",temp0
	jl	FALSE1
	cmp	#10,temp0
	jl	DIGTQ1
	sub	#7,temp0
; -- bug fix MM-180628 --
  cmp #10,temp0
  jl FALSE1
; -----------------------  
DIGTQ1:
	cmp	tos,temp0
	mov	temp0,0(stack)
	jl	TRUE1
FALSE1:
	clr	tos
	INEXT
TRUE1:
	mov	#-1,tos
	INEXT

;   NUMBER?	( a -- n T | a F )
;	Convert a number string to integer. Push a flag on tos.
	.dw	DECIM-8
	.db 7,"NUMBER?"
NUMBQ:
	INEST
	.dw	BASE,AT,TOR,DOLIT,0,OVER,COUNT
	.dw	OVER,CAT,DOLIT,'$',EQUAL,QBRAN,NUMQ1
	.dw	HEX,SWAP,ONEP,SWAP,ONEM
NUMQ1:
	.dw	OVER,CAT,DOLIT,'-',EQUAL,TOR
	.dw	SWAP,RAT,SUBB,SWAP,RAT,PLUS,QDUP
	.dw	QBRAN,NUMQ6
	.dw	ONEM,TOR
NUMQ2:
	.dw	DUPP,TOR,CAT,BASE,AT,DIGTQ
	.dw	QBRAN,NUMQ4
	.dw	SWAP,BASE,AT,STAR,PLUS,RFROM,ONEP
	.dw	DONXT,NUMQ2
	.dw	RAT,SWAP,DROP,QBRAN,NUMQ3
	.dw	NEGAT
NUMQ3:
	.dw	SWAP
	.dw	BRAN,NUMQ5
NUMQ4:
	.dw	RFROM,RFROM,DDROP,DDROP,DOLIT,0
NUMQ5:
	.dw	DUPP
NUMQ6:
	.dw	RFROM,DDROP,RFROM,BASE,STORE,EXIT

;; Terminal output

;   BL	( -- 32 )
;	Return 32, the blank character.
	.dw	NUMBQ-8
	.db 2,"BL",0
BLANK:
	ICONST
	.dw	20H

;   SPACE	( -- )
;	Send the blank character to the output device.
	.dw	BLANK-4
	.db 5,"SPACE"
SPACE:
	INEST
	.dw	BLANK,EMIT,EXIT

;   SPACES	( +n -- )
;	Send n spaces to the output device.
	.dw	SPACE-6
	.db 6,"SPACES",0
SPACS:
	INEST
	.dw	DOLIT,0,MAX,TOR,BRAN,CHAR2
CHAR1:
	.dw	SPACE
CHAR2:
	.dw	DONXT,CHAR1,EXIT

;   TYPE	( b u -- )
;	Output u characters from b.
	.dw	SPACS-8
	.db 4,"TYPE",0
TYPEE:
	INEST
	.dw	TOR,BRAN,TYPE2
TYPE1:
	.dw	DUPP,CAT,TCHAR,EMIT
	.dw	ONEP
TYPE2:
	.dw	DONXT,TYPE1
	.dw	DROP,EXIT

;   CR	( -- )
;	Output a carriage return and a line feed.
	.dw	TYPEE-6
	.db 2,"CR",0
CR:
	INEST
	.dw	DOLIT,CRR,EMIT
	.dw	DOLIT,LF,EMIT,EXIT

;   do$	( -- a )
;	Return the address of a compiled string.
;	.dw	CR-4
;	.db COMPO+3,"do$"
DOSTR:
	INEST
	.dw	RFROM,RAT,RFROM,COUNT,PLUS
	.dw	ALGND,TOR,SWAP,TOR,EXIT

;   $"|	( -- a )
;	Run time routine compiled by $". Return address of a compiled string.
;	.dw	CR-4
;	.db COMPO+3,"$""|"
STRQP:
	INEST
	.dw	DOSTR,EXIT	;force a call to do$

;   ."|	( -- )
;	Run time routine of ." . Output a compiled string.
;	.dw	STRQP-4
;	.db COMPO+3,".""|"
DOTQP:
	INEST
	.dw	DOSTR,COUNT,TYPEE,EXIT

;   .R	( n +n -- )
;	Display an integer in a field of n columns, right justified.
	.dw	CR-4
	.db 2,".R",0
DOTR:
	INEST
	.dw	TOR,STR,RFROM,OVER,SUBB
	.dw	SPACS,TYPEE,EXIT

;   U.R	( u +n -- )
;	Display an unsigned integer in n column, right justified.
	.dw	DOTR-4
	.db 3,"U.R"
UDOTR:
	INEST
	.dw	TOR,BDIGS,DIGS,EDIGS
	.dw	RFROM,OVER,SUBB,SPACS,TYPEE,EXIT

;   U.	( u -- )
;	Display an unsigned integer in free format.
	.dw	UDOTR-4
	.db 2,"U.",0
UDOT:
	INEST
	.dw	BDIGS,DIGS,EDIGS,SPACE,TYPEE,EXIT

;   .	( w -- )
;	Display an integer in free format, preceeded by a space.
	.dw	UDOT-4
	.db 1,"."
DOT:
	INEST
	.dw	BASE,AT,DOLIT,10,XORR	;?decimal
	.dw	QBRAN,DOT1
	.dw	UDOT,EXIT	;no, display unsigned
DOT1:	.dw	STR,SPACE,TYPEE,EXIT	;yes, display signed

;   ?	( a -- )
;	Display the contents in a memory cell.
	.dw	DOT-2
	.db 1,"?"
QUEST:
	INEST
	.dw	AT,DOT,EXIT

;; Parsing

;   parse	( b u c -- b u delta ; <string> )
;	Scan string delimited by c. Return found string and its offset.
;	.dw	QUEST-2
;	.db 5,"parse"
PARS:
	INEST
	.dw	TEMP,STORE,OVER,TOR,DUPP,QBRAN,PARS8
	.dw	ONEM,TEMP,AT,BLANK,EQUAL,QBRAN,PARS3
	.dw	TOR
PARS1:
	.dw	BLANK,OVER,CAT	;skip leading blanks ONLY
	.dw	SUBB,ZLESS,INVER,QBRAN,PARS2
	.dw	ONEP,DONXT,PARS1
	.dw	RFROM,DROP,DOLIT,0,DUPP,EXIT
PARS2:
	.dw	RFROM
PARS3:
	.dw	OVER,SWAP,TOR
PARS4:
	.dw	TEMP,AT,OVER,CAT,SUBB	;scan for delimiter
	.dw	TEMP,AT,BLANK,EQUAL,QBRAN,PARS5
	.dw	ZLESS
PARS5:
	.dw	QBRAN,PARS6
	.dw	ONEP,DONXT,PARS4
	.dw	DUPP,TOR,BRAN,PARS7
PARS6:
	.dw	RFROM,DROP,DUPP,ONEP,TOR
PARS7:
	.dw	OVER,SUBB,RFROM,RFROM,SUBB,EXIT
PARS8:
	.dw	OVER,RFROM,SUBB,EXIT

;   PARSE	( c -- b u ; <string> )
;	Scan input stream and return counted string delimited by c.
;	.dw	QUEST-2
;	.db 5,"PARSE"
PARSE:
	INEST
	.dw	TOR,TIB,INN,AT,PLUS	;current input buffer pointer
	.dw	NTIB,AT,INN,AT,SUBB	;remaining count
	.dw	RFROM,PARS,INN,PSTOR,EXIT

;   .(	( -- )
;	Output following string up to next ) .
	.dw	QUEST-2
	.db IMEDD+2,".(",0
DOTPR:
	INEST
	.dw	DOLIT,")",PARSE,TYPEE,EXIT

;   (	( -- )
;	Ignore following string up to next ) . A comment.
	.dw	DOTPR-4
	.db IMEDD+1,"("
PAREN:
	INEST
	.dw	DOLIT,")",PARSE,DDROP,EXIT

;   \	( -- )
;	Ignore following text till the end of line.
	.dw	PAREN-2
	.db IMEDD+1
    .db 5Ch ; CC: "\" ; naken: [char] \    ;mk
BKSLA:
	INEST
	.dw	NTIB,AT,INN,STORE,EXIT

;   CHAR	( -- c )
;	Parse next word and return its first character.
	.dw	BKSLA-2
	.db 4,"CHAR",0
CHAR:
	INEST
	.dw	BLANK,PARSE,DROP,CAT,EXIT

;   TOKEN	( -- a ; <string> )
;	Parse a word from input stream and copy it to name dictionary.
	.dw	CHAR-6
	.db 5,"TOKEN"
TOKEN:
	INEST
	.dw	BLANK,PARSE,DOLIT,31,MIN
TOKEN1:
	.dw	HERE,DDUP,CSTOR,ONEP
	.dw	SWAP,CMOVE,HERE
	.dw	DOLIT,0,HERE,COUNT,PLUS,CSTOR,EXIT

;   WORD	( c -- a ; <string> )
;	Parse a word from input stream and copy it to code dictionary.
	.dw	TOKEN-6
	.db 4,"WORD",0
WORDD:
	INEST
	.dw	PARSE,BRAN,TOKEN1

;; Dictionary search

;   NAME>	( na -- ca )
;	Return a code address given a name address.
;	.dw	WORDD-6
;	.db 5,"NAME>"
NAMET:
	mov.b	@tos+,temp0
	and	#0x1F,temp0
	add	temp0,tos
	inc	tos
	bic	#1,tos
	INEXT

;   SAME?	( a a -- a a f \ -0+ )
;	Compare u cells in two strings. Return 0 if identical.
;	.dw	NAMET-6
;	.db 5,"SAME?"
SAMEQ:
	pushs
	mov	2(stack),tos
	mov.b	@tos,tos
SAME1:
	mov	2(stack),temp0
	add	tos,temp0
	mov.b	0(temp0),temp0
	mov	0(stack),temp1
	add	tos,temp1
	mov.b	0(temp1),temp1
	sub	temp1,temp0
	jnz	SAME2
	dec	tos
	jnz	SAME1
	INEXT
SAME2:
	jmp TRUE1

;   NAME?	( a -- ca na | a F )
;	Search all context vocabularies for a string.
;	.dw	WORDD-6
;	.db 5,"NAME?"
NAMEQ:
	INEST
	.dw	CNTXT,AT
FIND1:
	.dw	DUPP,QBRAN,FIND3	;end of dictionary
	.dw	OVER,AT,OVER,AT,DOLIT,MASKK,ANDD,EQUAL
	.dw	QBRAN,FIND4
	.dw	SAMEQ,QBRAN,FIND2	;match
FIND4:
	.dw	CELLM,AT,BRAN,FIND1
FIND2:
	.dw	SWAP,DROP,DUPP,NAMET,SWAP,EXIT
FIND3:
	.dw	EXIT

;; Terminal input

;   ^H	( bot eot cur -- bot eot cur )
;	Backup the cursor by one character.
;	.dw	NAMEQ-6
;	.db 2,"^H",0
BKSP:
	INEST
	.dw	TOR,OVER,RFROM,SWAP,OVER,XORR
	.dw	QBRAN,BACK1
	.dw	DOLIT,BKSPP,EMIT,ONEM
	.dw	BLANK,EMIT,DOLIT,BKSPP,EMIT
BACK1:
	.dw	EXIT

;   TAP	( bot eot cur c -- bot eot cur )
;	Accept and echo the key stroke and bump the cursor.
;	.dw	BKSP-4
;	.db 3,"TAP"
TAP:
	INEST
	.dw	DUPP,EMIT,OVER,CSTOR,ONEP,EXIT

;   kTAP	( bot eot cur c -- bot eot cur )
;	Process a key stroke, CR or backspace.
;	.dw	TAP-4
;	.db 4,"kTAP",0
KTAP:
	INEST
	.dw	DUPP,DOLIT,CRR,XORR,QBRAN,KTAP2
	.dw	DOLIT,BKSPP,XORR,QBRAN,KTAP1
	.dw	BLANK,TAP,EXIT
KTAP1:
	.dw	BKSP,EXIT
KTAP2:
	.dw	DROP,SWAP,DROP,DUPP,EXIT

;   accept	( b u -- b u )
;	Accept characters to input buffer. Return with actual count.
	.dw	WORDD-6
	.db 6,"ACCEPT",0
ACCEP:
	INEST
	.dw	OVER,PLUS,OVER
ACCP1:
	.dw	DDUP,XORR,QBRAN,ACCP4
	.dw	KEY,DUPP,BLANK,SUBB,DOLIT,95,ULESS
	.dw	QBRAN,ACCP2
	.dw	TAP,BRAN,ACCP1
ACCP2:
	.dw	KTAP
ACCP3:
	.dw	BRAN,ACCP1
ACCP4:
	.dw	DROP,OVER,SUBB,EXIT

;   QUERY	( -- )
;	Accept input stream to terminal input buffer.
	.dw	ACCEP-8
	.db 5,"QUERY"
QUERY:
	INEST
	.dw	TIB,DOLIT,80,ACCEP,NTIB,STORE
	.dw	DROP,DOLIT,0,INN,STORE,EXIT

;; Error handling

; QUIT inits return stack. ERROR inits both stacks.

;   ERROR	( a -- )
;	Return address of a null string with zero count.
;	.dw	QUERY-6
;	.db 5,"ERROR"
ERROR:
	INEST
	.dw	SPACE,COUNT,TYPEE,DOLIT
	.dw	3FH,EMIT,CR,SPSTO,QUIT


;   abort"	( f -- )
;	Run time routine of ABORT" . Abort with a message.
;	.dw	ERROR-6
;	.db COMPO+6,"abort""",0
ABORQ:
	INEST
	.dw	QBRAN,ABOR1	;text flag
	.dw	DOSTR,COUNT,TYPEE,SPSTO,QUIT	;pass error string
ABOR1:
	.dw	DOSTR,DROP,EXIT

;; Text interpreter

;   $INTERPRET	( a -- )
;	Interpret a word. If failed, try to convert it to an integer.
;	.dw	ERROR-6
;	.db 10,"$INTERPRET",0
INTER:
	INEST
	.dw	NAMEQ,QDUP	;?defined
	.dw	QBRAN,INTE1
	.dw	AT,DOLIT,COMPO,ANDD	;?compile only lexicon bits
	.dw	ABORQ
	.db 13," compile only"
	.dw	EXECU,EXIT	;execute defined word
INTE1:
	.dw	NUMBQ	;convert a number
	.dw	QBRAN,INTE2,EXIT
INTE2:
	.dw	ERROR	;error

;   [	( -- )
;	Start the text interpreter.
	.dw	QUERY-6
	.db IMEDD+1,"["
LBRAC:
	INEST
	.dw	DOLIT,INTER,TEVAL,STORE,EXIT

;   .OK	( -- )
;	Display 'ok' only while interpreting.
;	.dw	LBRAC-2
;	.db 3,".OK"
DOTOK:
	INEST
	.dw	DOLIT,INTER,TEVAL,AT,EQUAL
	.dw	QBRAN,DOTO1
	.dw	DOTQP
	.db 3," ok"
DOTO1:	.dw	CR,EXIT


;   ?STACK	( -- )
;	Abort if the data stack underflows.
;	.dw	DOTOK-4
;	.db 6,"?STACK",0
QSTAC:
	INEST
	.dw	DEPTH,ZLESS	;check only for underflow
	.dw	ABORQ
	.db 10," underflow",0
	.dw	EXIT

;   EVAL	( -- )
;	Interpret the input stream.
;	.dw	QSTAC-8
;	.db 4,"EVAL",0
EVAL:
	INEST
EVAL1:
	.dw	TOKEN,DUPP,CAT	;?input stream empty
	.dw	QBRAN,EVAL2
	.dw	TEVAL,ATEXE,QSTAC	;evaluate input, check stack
	.dw	BRAN,EVAL1
EVAL2:
	.dw	DROP,DOTOK,EXIT	;prompt

;   QUIT	( -- )
;	Reset return stack pointer and start text interpreter.
	.dw	LBRAC-2
	.db 4,"QUIT",0
QUIT:
	INEST
	.dw	RPSTO,LBRAC	;start interpretation
QUIT1:
	.dw	QUERY,EVAL	;get input
	.dw	BRAN,QUIT1	;continue till error

;; Compiler utilities

;   ALLOT	( n -- )
;	Allocate n bytes to the RAM dictionary.
	.dw	QUIT-6
	.db 5,"ALLOT"
ALLOT:
	INEST
	.dw	DP,PSTOR,EXIT	;adjust code pointer

;   IALLOT	( n -- )
;	Allocate n bytes to the code dictionary.
	.dw	ALLOT-6
	.db 6,"IALLOT",0
IALLOT:
	INEST
	.dw	CP,PSTOR,EXIT	;adjust code pointer

;   I!	( n a -- )
;	Store n to address a in code dictionary.
	.dw	IALLOT-8
	.db 2,"I!",0
ISTORE:
	mov	#FWKEY,&FCTL3 ; Clear LOCK
	mov	#FWKEY+WRT,&FCTL1 ; Enable write
;	call	#STORE
	mov.w	@stack+,0(tos)
	pops
	mov	#FWKEY,&FCTL1 ; Done. Clear WRT
	mov	#FWKEY+LOCK,&FCTL3 ; Set LOCK
	INEXT

;--------------------------------------- ; MM-180707
; ?I! ( n a -- )
;	Store n to address a in code dictionary.
; Abort if user dictionary space is full.
QISTOR:
  INEST 
  .dw QFLASH,ISTORE,EXIT
; --------------------------------------

;   IERASE	( a -- )
;	Erase a segment at address a.
	.dw	ISTORE-4
;	.db 5,"ERASE"   MM-180630
	.db 6,"IERASE",0
IERASE:
	mov	#FWKEY,&FCTL3 ; Clear LOCK
	mov	#FWKEY+ERASE,&FCTL1 ; Enable erase
	clr	0(tos)
	mov	#FWKEY+LOCK,&FCTL3 ; Set LOCK
	pops
	INEXT

;   IWRITE	( src dest n -- )
;	Copy n byte from src to dest.  Dest is in flash memory.
;	.dw	IERASE-6   MM-180630
	.dw	IERASE-8
;	.db 5,"WRITE"  MM-180630
	.db 6,"IWRITE",0
IWRITE:
	INEST
	.dw	TWOSL,TOR
IWRITE1:
;	.dw	OVER,AT,OVER,ISTORE    ;MM-180707
	.dw	OVER,AT,OVER,QISTOR    ;
	.dw	CELLP,SWAP,CELLP,SWAP
	.dw	DONXT,IWRITE1
	.dw	DDROP,EXIT

;   ,	( w -- )
;	Compile an integer into the code dictionary.
;	.dw	WRITE-6   MM-180630
	.dw	IWRITE-8
	.db 1,","
COMMA:
	INEST
;	.dw	CP,AT,DUPP,CELLP	;cell boundary                     ;MM-180707
	.dw	CP,AT,QFLASH,DUPP,CELLP	;cell boundary + flash test  ;
	.dw	CP,STORE,ISTORE,EXIT

;   call,	( w -- )
;	Compile a call instruction into the code dictionary.
;	.dw	COMMA-2
;	.db 5,"call,"
CALLC:
	INEST
	.dw	DOLIT,CALLL,COMMA
	.dw	COMMA,EXIT

;   [COMPILE]	( -- ; <string> )
;	Compile the next immediate word into code dictionary.
;	.dw	COMMA-2
;	.db IMEDD+9,"[COMPILE]"
BCOMP:
	INEST
	.dw	TICK,COMMA,EXIT

;   COMPILE	( -- )
;	Compile the next address in colon list to code dictionary.
;	.dw	BCOMP-10
;	.db COMPO+7,"COMPILE"
COMPI:
	INEST
	.dw	RFROM,DUPP,AT,COMMA	;compile address
	.dw	CELLP,TOR,EXIT	;adjust return address

;   LITERAL	( w -- )
;	Compile tos to code dictionary as an integer literal.
;	.dw	COMPI-8
  .dw COMMA-2               ; MM-180701
	.db IMEDD+7,"LITERAL"     ;
LITER:
	INEST
	.dw	COMPI,DOLIT,COMMA,EXIT

;   $,"	( -- )
;	Compile a literal string up to next " .
;	.dw	LITER-8
;	.db 3,"$,"""
STRCQ:
	INEST
;   .dw     DOLIT,""""      ; MM-180624 assembles to |DOLIT|0000H|
    .dw     DOLIT,0022H     ;           should be |DOLIT|ASCII(")|
	.dw	WORDD	;move string to code dictionary
	.dw	STRCQ1,EXIT

STRCQ1:
	INEST
	.dw	DUPP,CAT,TWOSL	;calculate aligned end of string
	.dw	TOR
STRCQ2:
	.dw	DUPP,AT,COMMA,CELLP
	.dw	DONXT,STRCQ2
	.dw	DROP,EXIT

;; Structures

;   FOR	( -- a )
;	Start a FOR-NEXT loop structure in a colon definition.
;	.dw	COMMA-2     ; MM-180701
  .dw LITER-8
	.db IMEDD+3,"FOR"
FOR:
	INEST
	.dw	COMPI,TOR,BEGIN,EXIT

;   BEGIN	( -- a )
;	Start an infinite or indefinite loop structure.
	.dw	FOR-4
	.db IMEDD+5,"BEGIN"
BEGIN:
	INEST
	.dw	CP,AT,EXIT

;   NEXT	( a -- )
;	Terminate a FOR-NEXT loop structure.
	.dw	BEGIN-6
	.db IMEDD+4,"NEXT",0
NEXT:
	INEST
	.dw	COMPI,DONXT,COMMA,EXIT

;   UNTIL	( a -- )
;	Terminate a BEGIN-UNTIL indefinite loop structure.
	.dw	NEXT-6
	.db IMEDD+5,"UNTIL"
UNTIL:
	INEST
	.dw	COMPI,QBRAN,COMMA,EXIT

;   AGAIN	( a -- )
;	Terminate a BEGIN-AGAIN infinite loop structure.
	.dw	UNTIL-6
	.db IMEDD+5,"AGAIN"
AGAIN:
	INEST
	.dw	COMPI,BRAN,COMMA,EXIT

;   IF	( -- A )
;	Begin a conditional branch structure.
	.dw	AGAIN-6
	.db IMEDD+2,"IF",0
IFF:
	INEST
	.dw	COMPI,QBRAN,BEGIN
	.dw	DOLIT,2,IALLOT,EXIT

;   AHEAD	( -- A )
;	Compile a forward branch instruction.
;	.dw	IFF-4
;	.db IMEDD+5,"AHEAD"
AHEAD:
	INEST
	.dw	COMPI,BRAN,BEGIN
	.dw	DOLIT,2,IALLOT,EXIT

;   REPEAT	( A a -- )
;	Terminate a BEGIN-WHILE-REPEAT indefinite loop.
	.dw	IFF-4
	.db IMEDD+6,"REPEAT",0
REPEA:
	INEST
	.dw	AGAIN,BEGIN,SWAP,ISTORE,EXIT

;   THEN	( A -- )
;	Terminate a conditional branch structure.
	.dw	REPEA-8
	.db IMEDD+4,"THEN",0
THENN:
	INEST
	.dw	BEGIN,SWAP,QISTOR,EXIT

;   AFT	( a -- a A )
;	Jump to THEN in a FOR-AFT-THEN-NEXT loop the first time through.
	.dw	THENN-6
	.db IMEDD+3,"AFT"
AFT:
	INEST
	.dw	DROP,AHEAD,BEGIN,SWAP,EXIT

;   ELSE	( A -- A )
;	Start the false clause in an IF-ELSE-THEN structure.
	.dw	AFT-4
	.db IMEDD+4,"ELSE",0
ELSEE:
	INEST
	.dw	AHEAD,SWAP,THENN,EXIT

;   WHILE	( a -- A a )
;	Conditional branch out of a BEGIN-WHILE-REPEAT loop.
	.dw	ELSEE-6
	.db IMEDD+5,"WHILE"
WHILE:
	INEST
	.dw	IFF,SWAP,EXIT

;   ABORT"	( -- ; <string> )
;	Conditional abort with an error message.
	.dw	WHILE-6
	.db IMEDD+6,"ABORT",022H,0 ;mk CCS: "ABORT""" ; naken: "ABORT",022H,
ABRTQ:
	INEST
	.dw	COMPI,ABORQ,STRCQ,EXIT

;   $"	( -- ; <string> )
;	Compile an inline string literal.
	.dw	ABRTQ-8
	.db IMEDD+2,024H,022H,0 ;mk CCS: "$""" ; naken: 024H,022H,
STRQ:
	INEST
	.dw	COMPI,STRQP,STRCQ,EXIT

;   ."	( -- ; <string> )
;	Compile an inline string literal to be typed out at run time.
	.dw	STRQ-4
	.db IMEDD+2,02EH,022H,0 ;mk CCS: ".""" ; naken: 02EH,022H,
DOTQ:
	INEST
	.dw	COMPI,DOTQP,STRCQ,EXIT

;; Colon compiler

;   ?UNIQUE	( a -- a )
;	Display a warning message if the word already exists.
;	.dw	DOTQ-4
;	.db 7,"?UNIQUE"
UNIQU:
	INEST
	.dw	DUPP,NAMEQ	;?name exists
	.dw	QBRAN,UNIQ1	;redefinitions are OK
	.dw	DOTQP
	.db 7," reDef "	;but warn the user
	.dw	OVER,COUNT,TYPEE	;just in case its not planned
UNIQ1:
	.dw	DROP,EXIT

;   $,n	( na -- )
;	Build a new dictionary name using the string at na.
;	.dw	UNIQU-8
;	.db 3,"$,n"
SNAME:
	INEST
	.dw	DUPP,CAT	;?null input
	.dw	QBRAN,SNAM1
	.dw	UNIQU	;?redefinition
	.dw	LAST,AT,COMMA	;save na for vocabulary link
	.dw	CP,AT,LAST,STORE
	.dw	STRCQ1,EXIT	;fill name field
SNAM1:
	.dw	STRQP
	.db 5," name"	;null input
	.dw	ERROR

;   $COMPILE	( a -- )
;	Compile next word to code dictionary as a token or literal.
;	.dw	UNIQU-8
;	.db 8,"$COMPILE",0
SCOMP:
	INEST
	.dw	NAMEQ,QDUP	;?defined
	.dw	QBRAN,SCOM2
	.dw	AT,DOLIT,IMEDD,ANDD	;?immediate
	.dw	QBRAN,SCOM1
	.dw	EXECU,EXIT	;its immediate, execute
SCOM1:	.dw	COMMA,EXIT	;its not immediate, compile
SCOM2:	.dw	NUMBQ	;try to convert to number
	.dw	QBRAN,SCOM3
	.dw	LITER,EXIT	;compile number as integer
SCOM3:	.dw	ERROR	;error

;   OVERT	( -- )
;	Link a new word into the current vocabulary.
;	.dw	SCOMP-10
;	.db 5,"OVERT"
OVERT:
	INEST
	.dw	LAST,AT,CNTXT,STORE,EXIT

;   ;	( -- )
;	Terminate a colon definition.
	.dw	DOTQ-4
	.db IMEDD+COMPO+1,";"
SEMIS:
	INEST
	.dw	COMPI,EXIT,LBRAC,OVERT,EXIT

;   ]	( -- )
;	Start compiling the words in the input stream.
	.dw	SEMIS-2
	.db 1,"]"
RBRAC:
	INEST
	.dw	DOLIT,SCOMP,TEVAL,STORE,EXIT

;   :	( -- ; <string> )
;	Start a new colon definition using next word as its name.
	.dw	RBRAC-2
	.db 1,":"
COLON:
	INEST
	.dw	TOKEN,SNAME,DOLIT,DOLST
	.dw	CALLC,RBRAC,EXIT

;; Defining words

;   HEADER	( -- ; <string> )
;	Compile a new array entry without allocating code space.
;	.dw	DOCON-6
;	.db 6,"HEADER",0
HEADER:
	INEST
	.dw	TOKEN,SNAME,OVERT
	.dw	DOLIT,DOCON,CALLC,EXIT

;   CREATE	( -- ; <string> )
;	Compile a new array entry without allocating code space.
	.dw	COLON-2
	.db 6,"CREATE",0
CREAT:
	INEST
	.dw	HEADER,DP,AT,COMMA,EXIT

;   CONSTANT	( n -- ; <string> )
;	Compile a new constant.
	.dw	CREAT-8
	.db 8,"CONSTANT",0
CONST:
	INEST
	.dw	HEADER,COMMA,EXIT

;   VARIABLE	( -- ; <string> )
;	Compile a new variable initialized to 0.
	.dw	CONST-10
	.db 8,"VARIABLE",0
VARIA:
	INEST
	.dw	CREAT,DOLIT,2,ALLOT,EXIT

;; Tools

;   '	( -- ca )
;	Search context vocabularies for the next word in input stream.
	.dw	VARIA-10
	.db 1,"'"
TICK:
	INEST
	.dw	TOKEN,NAMEQ	;?defined
	.dw	QBRAN,TICK1
	.dw	EXIT	;yes, push code address
TICK1:
	.dw	ERROR	;no, error

;   DUMP	( a u -- )
;	Dump u bytes from a, in a formatted manner.
	.dw	TICK-2
	.db 4,"DUMP",0
DUMP:
	INEST
	.dw	DOLIT,7,TOR	;start count down loop
DUMP1:
	.dw	CR,DUPP,DOLIT,5,UDOTR
	.dw	DOLIT,15,TOR
DUMP2:
	.dw	COUNT,DOLIT,3,UDOTR
	.dw	DONXT,DUMP2	;loop till done
	.dw	SPACE,DUPP,DOLIT,16,SUBB
	.dw	DOLIT,16,TYPEE	;display printable characters
	.dw	DONXT,DUMP1	;loop till done
	.dw	DROP,EXIT

;   .S	( ... -- ... )
;	Display the contents of the data stack.
	.dw	DUMP-6
	.db 2,".S",0
DOTS:
	INEST
	.dw	CR,DEPTH	;stack depth
	.dw	TOR	;start count down loop
	.dw	BRAN,DOTS2	;skip first pass
DOTS1:
	.dw	RAT,PICK,DOT	;index stack, display contents
DOTS2:
	.dw	DONXT,DOTS1	;loop till done
	.dw	DOTQP
	.db 4," <sp",0
	.dw	EXIT

;   >NAME	( ca -- na | F )
;	Convert code address to a name address.
;	.dw	DOTS-4
;	.db 5,">NAME"
TNAME:
	INEST
	.dw	TOR,CNTXT,AT	;vocabulary link
TNAM1:
	.dw	DUPP,QBRAN,TNAM2
	.dw	DUPP,NAMET,RAT,XORR	;compare
	.dw	QBRAN,TNAM2
	.dw	CELLM	;continue with next word
	.dw	AT,BRAN,TNAM1
TNAM2:
	.dw	RFROM,DROP,EXIT

;   .ID	( na -- )
;	Display the name at address.
;	.dw	TNAME-6
;	.db 3,".ID"
DOTID:
	INEST
	.dw	COUNT,DOLIT,01FH,ANDD	;mask lexicon bits
	.dw	TYPEE,EXIT

;   WORDS	( -- )
;	Display the names in the context vocabulary.
	.dw	DOTS-4
	.db 5,"WORDS"
WORDS:
	INEST
	.dw	CR,CNTXT,AT	;only in context
WORS1:
	.dw	QDUP	;?at end of list
	.dw	QBRAN,WORS2
	.dw	DUPP,SPACE,DOTID	;display a name
	.dw	CELLM,AT,BRAN,WORS1
WORS2:
	.dw	EXIT

;; Cold boot

;   HI	( -- )
;	Display the sign-on message of eForth.
	.dw	WORDS-6
	.db 2,"HI",0
HI:
	INEST
	.dw	CR,DOTQP
	.db 13,"430eForth43n1"	;model
;	.dw	CR,EXIT   ; MM-180629
	.dw	EXIT

;   APP!	( a -- )	Turnkey
;	HEX : APP! 200 ! 1000 IERASE 200 1000 20 IWRITE ;
	.dw	HI-4
	.db 4,"APP!",0
APPST:
	INEST
	.dw	TBOOT,STORE,DOLIT,0x1000,IERASE
	.dw	TBOOT,DOLIT,0x1000,DOLIT,0x20
	.dw	IWRITE,EXIT

; -- Flash tools ------------------------ ; MM-180629 ...

EDM equ 0FFC0H-2  ; top of users dictionary space in the flash memory

; FSCAN ( -- )  ; MM-180629
; Scan the Flash memory from EDM downwards and set CP to the next free cell
; above the last used one.
FSCAN:
  INEST
   .dw DOLIT,EDM
FSCN1:
   .dw DOLIT,2,SUBB,DUPP,AT,DOLIT,EM,SUBB
   .dw QBRAN,FSCN1
   .dw DOLIT,2,PLUS,CP,AT,ALGND,MAX,CP,STORE,EXIT  ;

; ?flash ( a -- a )  ; MM-180707
; Abort if user dictionary is full ( a > EDM )
QFLASH:
; EDM OVER U< ABORT"  ?Flash"
  INEST 
  .dw DOLIT,EDM,OVER,ULESS,ABORQ,
  .db 7," ?flash"
  .dw EXIT

; ---------------------------------------------------------

;   COLD	( -- )
;	The hilevel cold start sequence.
 	.dw	APPST-6
	.db 4,"COLD",0
COLD:
	INEST
	.dw	STOIO
	.dw	DOLIT,UZERO,DOLIT,UPP
	.dw	DOLIT,ULAST-UZERO,CMOVE	;initialize user area
	.dw	TBOOT,ATEXE	;application boot
  .dw FSCAN,CR                                    ;MM-180629
	.dw	QUIT	;start interpretation

init:                ;mk Put it closer to cold : jmp was out of range.
	mov	#RPP,SP	; set up stack
	mov	#SPP,stack
	clr	tos
	mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop watchdog timer
	bis.b   #041h,&P1DIR	; P1.0/6 output
	jmp	COLD

CTOP:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;
; COLD start moves the following to user variables.

;	.sect	".infoD"  ; CCS: .sect ; naken: .org   ;mk
    .org 01000H ;mk
;   1000-10FF = 256B information memory   ;mk
;   INFO+000h (INFOD):  RAM save area, user variables ;mk
;   INFO+040h (INFOC):  RAM save area ??? ;mk
;   INFO+080h (INFOB):  user interrupt vectors ??? ;mk
;   INFO+0C0h (INFOA):  configuration data - do not use!! ;mk

UZERO:
	.dw	HI	;200H, boot routine
	.dw	BASEE	;202H, BASE
	.dw	0	;204H, tmp
	.dw	0	;206H, >IN
	.dw	0	;208H, #TIB
	.dw	0	;20AH, HLD
	.dw	INTER	;20CH, 'EVAL
	.dw	COLD-6	;20EH, CONTEXT pointer
	.dw	CTOP+8	;210H, CP; pass ISR
	.dw	DPP	;220H, DP
	.dw	COLD-6	;214H, LAST
ULAST:

;===============================================================
;	.sect   ".reset"	; MSP430 RESET Vector  ;mk

; Interrupt vectors are located in the range FFE0-FFFFh.
;       .org 0FFE0h
intvecs: 
;        DC16 VECAREA+00      ; FFE0 - not used
;        DC16  VECAREA+04     ; FFE2 - not used
;        DC16  VECAREA+08     ; FFE4 - IO port P1
;        DC16  VECAREA+12     ; FFE6 - IO port P2
;        DC16  VECAREA+16     ; FFE8 - not used
;        DC16  VECAREA+20     ; FFEA - ADC10
;        DC16  VECAREA+24     ; FFEC - USCI A0/B0 tx, I2C tx/rx
;        DC16  VECAREA+28     ; FFEE - USCI A0/B0 rx, I2C status
;        DC16  VECAREA+32     ; FFF0 - Timer 0_A3
;        DC16  VECAREA+36     ; FFF2 - Timer 0_A3
;        DC16  VECAREA+40     ; FFF4 - Watchdog
;        DC16  VECAREA+44     ; FFF6 - Comparator A
;        DC16  VECAREA+48     ; FFF8 - Timer 1_A3
;        DC16  VECAREA+52     ; FFFA - Timer 1_A3
;        DC16  VECAREA+56     ; FFFC - NMI, osc.fault, flash violation
         .org 0FFFEh
         DC16  init           ; FFFE - Reset

	.end
;===============================================================

