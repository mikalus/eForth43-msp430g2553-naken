# eForth
*** debug release ***

eForth Version 4.3 for the TI MSP430G2553 chip.  
One of the few processors still available in the breadboard friendy 20 Pin DIL Package.  
eForth and application will run ON this chip. 

Chen-Hanson Ting, Offete Enterprises, Inc. 2015

Uses here the free Naken Assembler https://github.com/mikeakohn/naken_asm  
Ported to Naken Assembler by M.Kalus 2018

## Assembling eForth
Open a command prompt window. Change to the directory where your source code is. Type:  
naken_asm -l -o eForth43-msp430g2553-naken.hex eForth43-msp430g2553-naken.asm

Have fun, mk

## Try it out directly
It is easy to program eForth into the TI MSP430 Launchpad.  
Download and install the free 430 version of the elprotronic programmer at  
https://www.elprotronic.com/productdata;jsessionid=8FA5E1E626677AABC3683EC0D712B01F  
Select the correct processor 430G2553, point to the hex file you find here:  
https://github.com/mikalus/eForth43-msp430g2553-naken/blob/master/eForth43-msp430g2553-naken.hex  
and follow the steps.  
Do not forget RESET after programming.

Then start your favourite Terminal program and start writing short examples, like in  
https://wiki.forth-ev.de/doku.php/en:projects:a-start-with-forth:start0  
and there probably chapter 11c as a good starting point.

## Start with Forth

- Quickstart: Connect to eForth on your Launchpad using a terminal emulator.  
Compile and save demo forth application: blink.4th.  
eForth is CASE SENSITIVE : Type all Forth words in uppercase.

- New to Forth?  
https://wiki.forth-ev.de/doku.php/en:projects:a-start-with-forth:start0  
There are various Forth systems mentioned, but the handling is the same.

- New to the TI LaunchPad?  
https://wiki.forth-ev.de/doku.php/projects:4e4th:start  
That is for another Forth, but the handling is the same.

- New to eForth?  
Read the included eForth_Overview.pdf to understand eforth.

- Need the Programmer?  
https://www.elprotronic.com/  
"Lite FET-Pro430 Elprotronic Programmer" burns image into MCU. Get the free version there.

- More books  
https://wiki.forth-ev.de/doku.php/projects:ting_s_electronic_forth_bookshelf

## Verification:
430eforth.a43  
Reading Code File ........................... done  
Code size = 0x1058 ( 4184 ) bytes

eForth43-msp430g2553-naken.hex  
Reading Code File ........................... done  
Code size = 0x1044 ( 4164 ) bytes

The eForth43-msp430g2553-naken.hex image differs from the original 430eforth.a43 file. A code-block had to be put to an end position.  
eForth WORDS are the same. See: screenshots of old (CCS) and new (naken) version.  
WORDS .S and some compiling are ok.  

## To Do
Discard input stream if an error occurs.

19 May 2018   (finis)
