REM -------------------------------------------------------------------------
	' get the constants we need
	include "constants.bas"
REM -------------------------------------------------------------------------

CONST clear = 136
CONST enter = 40
CONST del = 127
CONST TAB = 9
CONST width = 20
CONST height =12
CONST debug = 0 ' turn on printing of raw encoded value
validChar = 0
printLocation = 100
x = -1 ' so we start with column one, cause we do some math later
y = -1 ' so we start on row one, cause we do some math later
color = CS_WHITE 
screenLocation = 0 
cont1Copy = "\0"
WHILE 1
	cont1Current = cont1
	' PRINT AT 235 COLOR 1, <3>cont1Current ' will display the value of cont toward bottom right corner
	IF cont1Current = cont1Copy THEN
		cont1Copy = "\0"
	ELSE
		IF debug THEN
			PRINT AT 235 COLOR 1, <3>cont1Current
		END IF
		IF cont1Current = clear THEN
			CLS
			x = -1
			y = -1
			printLocation = 100
			GOSUB DebugPrint
		ELSEIF cont1Current = enter THEN
			x = -1
			GOSUB DebugPrint			
		ELSEIF cont1Current = del THEN
			x = x - 1
			if (x < 1) THEN
				 x = width -1
				 y = y - 1
				 x1 = x1
				 y1 = y1
				GOSUB  ProcessInput
				x = x1
				y = y1
			END IF
			GOSUB DebugPrint
		ELSEIF cont1Current = TAB THEN
			x = x + 5
			IF (X > width - 1) THEN
				y = y + x - 19
				x = 0
			END IF
			GOSUB DebugPrint
		ELSE
			GOSUB ValidCharacter 
		 	IF validChar THEN
				GOSUB DebugPrint
				GOSUB  ProcessInput
			END IF
		END IF
	END IF
    cont1Copy = cont1Current
WEND 

REM -------------------------------------------------------------------------
REM Main loop
REM -------------------------------------------------------------------------	
WHILE 1
	WAIT
WEND

REM -------------------------------------------------------------------------
REM if debug is set to 1 then display raw encoded value from JS port
REM -------------------------------------------------------------------------	
DebugPrint: PROCEDURE
	IF debug THEN
		PRINT AT printLocation COLOR 1, <3>cont1Current
		printLocation = printLocation + 4
	END IF
END

REM -------------------------------------------------------------------------
REM CHeck if the encoded value sent from over the JS port is a valid character
REM -------------------------------------------------------------------------	
ValidCharacter: PROCEDURE
	IF ( cont1Current >= 23 AND cont1Current <= 39 ) \
	OR ( cont1Current >=41 AND cont1Current <= 47 ) \
	OR ( cont1Current >=58 AND cont1Current <= 68 ) \
	OR ( cont1Current >=70 AND cont1Current <= 94 ) \
	OR ( cont1Current >=97 AND cont1Current <= 126 ) \
	OR ( cont1Current >= 129 AND cont1Current <= 130 ) \
	OR ( cont1Current >= 132 AND cont1Current <= 134 ) THEN 
		validChar = 1
	ELSE	
		validChar = 0
	END IF
END

REM -------------------------------------------------------------------------
REM ProcessInput - deal with the key stroke.
REM -------------------------------------------------------------------------
ProcessInput: PROCEDURE
	IF screenLocation / x = 0  AND x <> 0 THEN
		y = y + 1
		x = 0
	ELSE
		x = X + 1
	END IF

	index = cont1Current
	#where=SCREENADDR(x,y)	' Where the character is going to on the screen.
	gosub PrintChar		' Print the character on the screen.
	screenLocation = screenLocation + 1
END

REM -------------------------------------------------------------------------
REM PrintChar - Prints a character 
REM Based on PrintChar routine by Mark Ball
REM -------------------------------------------------------------------------

PrintChar: PROCEDURE
	#addr = (varptr Alpha(0))  + index
	#data=(peek(#addr) * 8) + color	' Get the character and convert it into BACKTAB card format.
	poke #where,#data				' Write it to BACKTAB.
END

REM -------------------------------------------------------------------------
REM PrintChar - END
REM -------------------------------------------------------------------------
Alpha:
    asm DECLE @@AlphaEnd-@@AlphaStart
    asm @@AlphaStart:
	data "~~~~~~~~~~~~~~~~~~~~~~ABCDE!~#$ 36&9%('~)*+,-./~~~~~~~~~~:;<=>?@25H8~FG0IJKLMNOPQRSTUVWXYZ[\]^~~abcdefghijklmnopqrstuvwxyz{|}~~~14~7\"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    asm @@AlphaEnd: