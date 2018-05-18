# eForth

*** debug release ***

eForth Version 4.3 for MSP430G2553 
Chen-Hanson Ting, Offete Enterprises, Inc. 2015
Ported to Naken Assembler by M.Kalus 2018
[added 1 word: \ ( -- ) "backslash"]

Assemble a fresh eForth:
 naken_asm -l -o eForth43-msp430g2553-naken.hex eForth43-msp430g2553-naken.asm 

Have fun, mk


- Quickstart: Run eForth, compile and save demo forth applikation: blink.4th
  eForth is CASE SENSITIVE : Type all words in uppercase.

- New to forth? : https://wiki.forth-ev.de/doku.php/en:projects:a-start-with-forth:start0
  There are various forth system mentioned, but the handling is the same.

- New to LaunchPad? : https://wiki.forth-ev.de/doku.php/projects:4e4th:start
  That's another forth, but the handling is the same. 

- New to eForth? 
  Read the included eForth_Overview.pdf to understand eforth.


---

verifikation

---
To do: Discard input stream if an error occurs.

(finis)