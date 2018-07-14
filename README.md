# eForth

eForth for the TI MSP430G2553 chip.  
One of the few processors still available in the breadboard friendy 20 Pin DIL Package.  
eForth and application will run ON this chip. 

Chen-Hanson Ting, Offete Enterprises, Inc. 2015

Uses here the free Naken Assembler https://github.com/mikeakohn/naken_asm  
Ported to Naken Assembler by M.Kalus, May 2018  
Debuged and contribution of Flash Tools by Manfred Mahlow, Jul 2018

## Contributions

430eForth43n1 ( eForth431-msp430g2553-naken.asm )

is 430eForth43 with the following extensions/modifications:

  * two tiny (hidden) Flash Tools added (FSCAN and QFLASH)
  * LITERAL and ALIGNED revealed (made visible)
  * ERASE and WRITE renamed to IERASE and IWRITE (because of a name conflict)

FSCAN
Scans the Flash on COLD start and makes CP point to the start of the
unused Flash area. So 430eForth43n1 behaves like a Forth in RAM until the
Flash is full. Only then you have to re-flash.

QFLASH
Aborts compilation with message "?flash" when the flash is full (CP >= $FFC0)

### FlashTools43n1.efs

Source code file to be included in a newly flashed 430eForth43n1. Adds the words SAVE, RESET and MARKER.

SAVE ( -- )
Saves the current eForth state to the COLD start data.

RESET ( -- )
Erases the Flash Memory, resets the user variables and the reset vector and restarts eForth.

MARKER ( <name> -- )
Creates a word <name>. When <name> is executed it erases itself and all later defined words from the dictionary, updates the user variables and executes SAVE.

## Assembling eForth
Open a command prompt window. Change to the directory where your source code is. Type:  
naken_asm -l -o eForth431-msp430g2553-naken.hex eForth431-msp430g2553-naken.asm

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

eForth431-msp430g2553-naken.hex  
Reading Code File ........................... done
Code size = 0x10B8 ( 4280 ) bytes

The eForth431-msp430g2553-naken.hex image differs from the original 430eforth.a43 file. A code-block had to be put to an end position, 2 bugs fixed, tiny tools added. Original eForth WORDS are the same. See: screenshots of old (CCS) and new (naken) version.  
WORDS .S and some compiling are ok.  

## Why Version 4.3.1 ?

430eForth43 (n) has the serious shortcoming of the reset trap. Curious,
be it beginners or professionals, quickly fall in without suspecting
what's going on there. They usually do not know anything about  
  ' HI APP!  
Their experience: again a software that does not work properly.
Or worse, keep away from Forth. :-(
Therefore, there is the version 43n1 without reset trap. You can work with it like
with Forth in RAM until the flash is full. Then there is the error message
"? Flash". The interpreter still works, but compiling is no longer possible, 
again the error message. You have to re-flash.
Otherwise, 43n1 behaves like 43 (n), so also fits to Jürgen's books
and will also work fully with the IDE as described.

Those interested should use the newer version 43n1.

Background knowledge on the reset trap:  
Vierte Dimension 3/2017, "Das RAM–ROM–Dilemma von interaktivem Forth in kleinen MCUs", Michael Kalus.  
https://wiki.forth-ev.de/lib/exe/fetch.php/vd-archiv:4d2017-03.pdf  
https://wiki.forth-ev.de/lib/exe/fetch.php/events:430eforth-tips_tools_tests2017.pdf  

## To Do
Discard input stream if an error occurs.

19 May 2018   (finis)
