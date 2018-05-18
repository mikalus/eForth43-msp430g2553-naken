# eForth

*** debug release ***

eForth Version 4.3 for MSP430G2553 
Chen-Hanson Ting, Offete Enterprises, Inc. 2015
Ported to Naken Assembler by M.Kalus 2018

Assemble a fresh eForth:
 naken_asm -l -o eForth43-msp430g2553-naken.hex eForth43-msp430g2553-naken.asm 

Have fun, mk

---

- Quickstart: Run eForth, compile and save demo forth applikation: blink.4th
  eForth is CASE SENSITIVE : Type all words in uppercase.

- New to forth? : https://wiki.forth-ev.de/doku.php/en:projects:a-start-with-forth:start0
  There are various forth system mentioned, but the handling is the same.

- New to LaunchPad? : https://wiki.forth-ev.de/doku.php/projects:4e4th:start
  That's another forth, but the handling is the same. 

- New to eForth? 
  Read the included eForth_Overview.pdf to understand eforth.

- Programmer? : https://www.elprotronic.com/
  "Lite FET-Pro430 Elprotronic Programer" burns image into MCU.
  
---

Verifikation: 

430eforth.a43
Reading Code File ...........................	 done
-- Code size = 0x1058 ( 4184 ) bytes

eForth43-msp430g2553-naken.hex
Reading Code File ...........................	 done
-- Code size = 0x1044 ( 4164 ) bytes

The eForth43-msp430g2553-naken.hex image differs from the original 430eforth.a43 file.
A code-block had to be put to an end position.

eForth WORDS are the same. See: screenshots of old (CCS) an new (naken_am) version.

WORDS .S and some compiling are ok.
 
---

To do: Discard input stream if an error occurs.

(finis)