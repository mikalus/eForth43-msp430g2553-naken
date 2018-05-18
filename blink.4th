  DECIMAL
  
  \ Application example.
  : BLINK  ( -- )   
    BEGIN 
        RED CSETB GREEN CCLRB 100 MS
        RED CCLRB GREEN CSETB 100 MS
    KEY? UNTIL  
    KEY DROP  ;  \ Consume last key to avoid terminal echo.
  
  \ SAVE last word as autostart routine.
  : MAIN  ( -- )  
    BLINK 
    QUIT ;  \ Quit application to enter forth.
  
---

Damit eine Anwendung automatisch startet, wenn die MCU hochfährt, nach reset oder einschalten des Stromes, packe deine Anwendung in das zuletzt definierte Wort ein. Falls deine Anwendung einen sicheren Ausgang ins Forth haben soll, muss sie mit QUIT beendet werden. QUIT startet den Forth Interpreter.  

For an application to start automatically when the MCU powers up, pack your application in the last word you've defined. If your application should have a safe exit to the Forth, it must be quit with QUIT. QUIT starts the Forth interpreter.