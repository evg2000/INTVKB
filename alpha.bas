
REM -------------------------------------------------------------------------
REM Program: alpha.bas
REM
REM Author: Charles Dysert - EVG2000
REM Date: 20250517
REM Version: .1
REM 
REM Requirements:
REM	 *	constants.bas must be in the build path, compile with compiler in 
REM     sample directory
REM  *	Keyboard on port 1 sending encoded keystrokes, order is defined
REM     by list in the Alpha: label at bottom of source.
REM	 *  If you change the order of characters the procedure ValidCharacter
REM     must be updated.
REM
REM known issues:
REM 1. currently no check for characters running off the bottom, wether
REM    just displaying characters, or if debug data runs off.
REM    you'll get 'CPU off in the weeds!' Hit clear befor this and screen
REM    clears and your good to test some more. No screen scrolling
REM 2. " doesn't work - can't get it to map on INTV side
REM 3. If debug is on the key press just flashes in the corner, so look quickly
REM -------------------------------------------------------------------------

REM -------------------------------------------------------------------------
	' get the constants we need
	include "constants.bas"
REM -------------------------------------------------------------------------

REM -------------------------------------------------------------------------
REM define splecial keys
REM -------------------------------------------------------------------------
CONST clear = 136
CONST enter = 40
CONST del = 127
CONST TAB = 9

REM -------------------------------------------------------------------------
REM height is not used, at least yet, more for me to remember screen size
REM width is used for calculating location when tab or delete is used
REM -------------------------------------------------------------------------
REM CONST height =12
CONST width = 20

REM -------------------------------------------------------------------------
REM stuff for debug
REM debug set to 1 will display cont1 value at debugPrintLoc
REM if hexDebug is set to 1 then display 2 digit hex, else 3 digit decimal
REM debugPrintLoc screen location to print debug values
REM debugKeyPrintLoc location to print current key, it just flashes on screen
REM -------------------------------------------------------------------------
CONST debug = 1 ' turn on printing of raw encoded value
CONST hexDebug = 1
debugPrintLoc = 100
debugKeyPrintLoc = 235

REM -------------------------------------------------------------------------
REM color is used to display the current character
REM screenLocation is where next character will print 0 - 239 (unless degub is on) 
REM 'boolean' indicating if current input is a valid character
REM -------------------------------------------------------------------------
validChar = 0
color = CS_WHITE 
screenLocation = 0 

REM -------------------------------------------------------------------------
REM current row and column, I started at -1 for both because that's how
REM my mind works :)
REM -------------------------------------------------------------------------
x = -1 ' so we start with column one, cause we do some math later
y = -1 ' so we start on row one, cause we do some math later

REM -------------------------------------------------------------------------
REM Key last value, storing it is enough to prevent most double key strokes.
REM -------------------------------------------------------------------------
lastContVal = "\0"

REM -------------------------------------------------------------------------
REM Main loop
REM -------------------------------------------------------------------------
WHILE 1
	cont1Current = cont1 ' seems to have an issue with just using cont1 directly, seems like it has to be read to process.
	IF cont1Current = lastContVal THEN
		lastContVal = "\0"
	ELSE
		IF debug THEN
			PRINT AT debugKeyPrintLoc COLOR 1, <3>cont1Current ' if debug on then display the value of cont toward bottom right corner
		END IF
		IF cont1Current = clear THEN
			CLS
			x = -1
			y = -1
			debugPrintLoc = 100
			GOSUB DebugPrint
		ELSEIF cont1Current = enter THEN
			x = -1
			GOSUB DebugPrint			
		ELSEIF cont1Current = del THEN 'currently non descructive more like the back key.  
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
    lastContVal = cont1Current
WEND 

REM -------------------------------------------------------------------------
REM if debug is set to 1 then display raw encoded value from JS port
REM -------------------------------------------------------------------------	
DebugPrint: PROCEDURE
	IF debug THEN
		if hexDebug THEN
		GOSUB hex
			PRINT AT debugPrintLoc COLOR 1, <1>HI
			PRINT AT debugPrintLoc + 1 COLOR 1, <1>LOW
			debugPrintLoc = debugPrintLoc + 3
		ELSE
			PRINT AT debugPrintLoc COLOR 1, <3>cont1Current
			debugPrintLoc = debugPrintLoc + 4
		END IF
	END IF
	RETURN
END

REM -------------------------------------------------------------------------
REM Calculate High and Low digit and then call hex digit to get the HI and 
REM LOW values to display in hex
REM -------------------------------------------------------------------------
hex: PROCEDURE
	' HI = HEXVALUES(cont1Current / 16)
	' LOW = HEXVALUES(cont1Current % 16)
	a = cont1Current / 16
	HI = a
	GOSUB getHexDigit	
	b = cont1Current % 16
	LOW = b
	GOSUB getHexDigit
	RETURN
END

REM -------------------------------------------------------------------------
REM Get the hex digit to display, just quick and easy.
REM -------------------------------------------------------------------------
getHexDigit: PROCEDURE
	a = HEXVALUES(a)
	RETURN
END

REM -------------------------------------------------------------------------
REM Check if the encoded value sent from over the JS port is a valid character
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
	RETURN
END

REM -------------------------------------------------------------------------
REM ProcessInput - deal with the keystroke.
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
	RETURN
END

REM -------------------------------------------------------------------------
REM PrintChar - Prints a character 
REM Based on PrintChar routine by Mark Ball
REM -------------------------------------------------------------------------
PrintChar: PROCEDURE
	#addr = (varptr Alpha(0))  + index
	#data=(peek(#addr) * 8) + color	' Get the character and convert it into BACKTAB card format.
	poke #where,#data				' Write it to BACKTAB.
	RETURN
END

HEXVALUES:
	DATA PACKED "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"

REM -------------------------------------------------------------------------
REM PrintChar - END
REM I have not been able to map a quote character successfully. It get an error if I don't use \ but it's not found at 133 or 134
REM -------------------------------------------------------------------------
Alpha:
    asm DECLE @@AlphaEnd-@@AlphaStart
    asm @@AlphaStart:
	REM                                                                                                      1                                                                                                   2
    REM            1         2         3         4         5         6         7         8         9         0         1         2         3         4         5         6         7         8         9         0
    REM   1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345    
	data "~~~~~~~~~~~~~~~~~~~~~~ABCDE!~#$ 36&9%('~)*+,-./~~~~~~~~~~:;<=>?@25H8~FG0IJKLMNOPQRSTUVWXYZ[\]^~~abcdefghijklmnopqrstuvwxyz{|}~~~14~7\"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    asm @@AlphaEnd: