	DSK RAIN

**************************************************
* A simple simulation of random raindrops falling, 
* hitting a puddle and splashing. Use K and I
* to increase/decrease the amount of falling rain.
**************************************************
* Variables
**************************************************

ROW				EQU		$FA			; row/col in text screen
COLUMN			EQU		$FB
CHAR			EQU		$FC			; char/pixel to plot
PROGRESS 		EQU		$FD			; write to main or alt
PLOTROW			EQU		$FE			; row/col in text page
PLOTCOLUMN		EQU		$FF
RNDSEED			EQU		$EA			; +eb +ec
UPPERLIMIT		EQU		$ED			; threshold for random raindrops

**************************************************
* Apple Standard Memory Locations
**************************************************
CLRLORES     EQU   $F832
LORES        EQU   $C050
TXTSET       EQU   $C051
MIXCLR       EQU   $C052
MIXSET       EQU   $C053
TXTPAGE1     EQU   $C054
TXTPAGE2     EQU   $C055
KEY          EQU   $C000
C80STOREOFF  EQU   $C000
C80STOREON   EQU   $C001
STROBE       EQU   $C010
SPEAKER      EQU   $C030
VBL          EQU   $C02E
RDVBLBAR     EQU   $C019       ;not VBL (VBL signal low
WAIT		 EQU   $FCA8 
RAMWRTAUX    EQU   $C005
RAMWRTMAIN   EQU   $C004
SETAN3       EQU   $C05E       ;Set annunciator-3 output to 0
SET80VID     EQU   $C00D       ;enable 80-column display mode (WR-only)
HOME 		 EQU   $FC58			; clear the text screen
CH           EQU   $24			; cursor Horiz
CV           EQU   $25			; cursor Vert
VTAB         EQU   $FC22       ; Sets the cursor vertical position (from CV)
COUT         EQU   $FDED       ; Calls the output routine whose address is stored in CSW,
                               ;  normally COUTI
STROUT		 EQU   $DB3A 		;Y=String ptr high, A=String ptr low

ALTTEXT		EQU		$C055
ALTTEXTOFF	EQU		$C054

ROMINIT      EQU        $FB2F
ROMSETKBD    EQU        $FE89
ROMSETVID    EQU        $FE93

ALTCHAR		EQU		$C00F		; enables alternative character set - mousetext

BLINK		EQU		$F3
SPEED		EQU		$F1

**************************************************
* START - sets up various fiddly zero page bits
**************************************************

				ORG $2000			; PROGRAM DATA STARTS AT $2000

				JSR ROMSETVID            ;Init char output hook at $36/$37
				JSR ROMSETKBD            ;Init key input hook at $38/$39
				JSR ROMINIT                ;GR/HGR off, Text page 1

				LDA #$01
				STA SPEED						; string/char output speed
				STA ALTCHAR						; enable mousetext
				STA PROGRESS					; which page do we write to
				LDA #$00
				STA BLINK						; blinking text? no thanks.

				STA LORES						; low res graphics mode
				JSR CLRLORES					; clear screen						

DRAWBOARD		JSR HOME							
				STA ALTTEXTOFF						; display main text page
				JSR RNDINIT							; *should* cycle the random seed.
			
				INC PROGRESS

				LDA #$F7
				STA UPPERLIMIT

					

**************************************************
*	blanks the screen, sets the "puddle" to dk blue
**************************************************
; FOR EACH ROW/COLUMN

				LDA #$18				; X = 24
				STA PLOTROW
ROWLOOP2 								; (ROW 20 to 0)
				DEC PLOTROW

										;	start columnloop (COLUMN 0 to 40)
				LDA #$28
				STA PLOTCOLUMN
COLUMNLOOP2		DEC PLOTCOLUMN	

				LDA PLOTROW				; last 4 lines, #$22
				CMP #$14				; > 20
				BCC PLOTZERO
				LDA #$22				; last 4 lines, #$22
				JMP PLOTLINE
PLOTZERO		LDA #$0					; set all pixels to 00
PLOTLINE		STA CHAR
				JSR PLOTCHAR			; plot 00
				INC PROGRESS
				JSR PLOTCHAR			; plot 00 to alt
				INC PROGRESS

				LDA PLOTCOLUMN			; last COLUMN?
				BNE COLUMNLOOP2			; loop

;	/columnloop2
			
				LDA PLOTROW				; last ROW?
				BNE ROWLOOP2			; loop 
	
; 	/rowloop2		
								
; draw raindrop

; DK blue = 2
; MD blue = 6
; LT blue = 7
; white = 	F
; black = 	0
; grey = 	5

; drop:
; == F7 76 02
; fast drop:
; == 27 60 20

; F7 -> 76 -> 02
; 27 -> 60 -> 20
				
**************************************************
*	MAIN LOOP
*	waits for keyboard input, moves cursor, etc
**************************************************

MAIN		
MAINLOOP		LDA KEY					; check for keydown
;				CMP #$A0				; space bar		pause?
;				BEQ GOTSPACE
				CMP #$D2				; R
				BEQ GOTRESET

				CMP #$9B				; ESC
				BEQ END					; exit on ESC?

				

				CMP #$C9				; I
				BEQ GOTUP
				CMP #$CB				; K
				BEQ GOTDOWN
;				CMP #$CA				; J			shift the falling drops left/right to 
;				BEQ GOTLEFT				;			simulate wind?
;				CMP #$CC				; L
;				BEQ GOTRIGHT
				
				JSR NEXTSCREEN			; animate one frame per loop

				BNE MAINLOOP			; loop until a key


GOTUP			STA STROBE
				DEC UPPERLIMIT
				JMP MAINLOOP			; back to waiting for a key
GOTDOWN			STA STROBE
				INC UPPERLIMIT
				JMP MAINLOOP			; back to waiting for a key
;GOTLEFT		STA STROBE
;				STA ALTTEXTOFF
;				JMP MAINLOOP			; back to waiting for a key
;				
;GOTRIGHT		STA STROBE
;				STA ALTTEXT
;				JMP MAINLOOP			; back to waiting for a key
;
;GOTSPACE		JSR SPACE
;				JMP MAINLOOP			; back to waiting for a key

GOTRESET		STA STROBE
				STA ALTTEXTOFF
				JMP DRAWBOARD

END				STA STROBE
				STA ALTTEXTOFF
				STA TXTSET
				JSR HOME
				RTS						; END	
					
;SPACE			STA STROBE				; 
;				JSR NEXTSCREEN			; animate
;				RTS
				
;/GOTSPACE
	


**************************************************
*	subroutines
*
**************************************************

**************************************************
*	main animation loop - checks each pixel for non-zero values
**************************************************

NEXTSCREEN								; FOR EACH ROW/COLUMN

				LDA #$14				; X = 20
				STA PLOTROW
ROWLOOP 								; (ROW 20 to 0)
				DEC PLOTROW

										;	start columnloop (COLUMN 0 to 40)
				LDA #$28
				STA PLOTCOLUMN
COLUMNLOOP		DEC PLOTCOLUMN	

				JSR GETCHAR
				BEQ ZEROFOUND		
															
				JSR EXPAND				; do the thing					


ZEROFOUND		LDA PLOTCOLUMN			; last COLUMN?
				BNE COLUMNLOOP			; loop
;/columnloop
			
				LDA PLOTROW				; last ROW?
				BEQ ROWONE				; top of the screen, do some random raindrops
				BNE ROWLOOP				; loop 
	
;/rowloop		
ROWONE									; row == 0, if RND > upperlimit, draw start of a new drop
				LDA #$28
				STA PLOTCOLUMN
COLUMNLOOP3		DEC PLOTCOLUMN			; next column


DODROPS			JSR RND					; grab a random number
				CMP UPPERLIMIT			; drop threshold
				BCC NODROP				; 	less than limit, no drop
				LDA PLOTCOLUMN
				ROR						;  on an odd/even column
				BCS LGDROP				; small/fast drops on even, large slow on odd
SMALLDROP		LDA #$27
				JMP STOREDROP	
LGDROP			LDA #$F7				; draw a drop
STOREDROP		STA CHAR
				INC PROGRESS
				JSR PLOTCHAR
				INC PROGRESS
				JMP NODROP				
				
				JSR GETCHAR
				BEQ NODROP		
				JSR EXPAND				; found a non-zero pixel, process it

NODROP			LDA PLOTCOLUMN			; last COLUMN?
				BNE COLUMNLOOP3			; loop on each column for top row
;/columnloop2




				INC PROGRESS			; every other refresh, show alt page, normal page
				ROR PROGRESS			; lowest bit into carry
				BCC ALTSCREEN			; carry set on odd, not on even
				STA ALTTEXTOFF
				JMP NORMSCREEN
ALTSCREEN		STA ALTTEXT

NORMSCREEN		ROL PROGRESS

				RTS
;/NEXTSCREEN




**************************************************
*	process raindrop animations.
**************************************************

DOSPLASH		JSR SPLASH				; made it to the bottom of the screen
				RTS						; show the splash animation

EXPAND			
										; found CHAR in A
; drop:
; == F7 76 02
; 27 -> 60 -> 20
; bottom up
				CMP #$F7				; if it's F7, plot 76, inc row, plot F7, 
				BNE SMDROP0				; not F7, skip
				INC PROGRESS			
				STA CHAR				; puts found character (F7) into CHAR	
				INC PLOTROW				; down 1
				LDA PLOTROW
				CMP #$15				; lower than row 20?
				JSR PLOTCHAR			; plot F7
DROP1			DEC PLOTROW				; back up
				LDA #$76				
				STA CHAR
				JSR PLOTCHAR			; plot 76
				INC PROGRESS			

				LDA PLOTROW
				CMP #$13				; lower than row 20?
				BEQ DOSPLASH

				JMP DROPDONE

SMDROP0			CMP #$27
				BNE DROP2
				INC PROGRESS			
				STA CHAR				; puts found character (27) into CHAR	
				INC PLOTROW				; down 1
				INC PLOTROW				; down 1
				LDA PLOTROW
				CMP #$14				; lower than row 20?
				BCS SMDROP1				; if > 20 skip over 
				JSR PLOTCHAR			; plot 27 down 2 px
SMDROP1			DEC PLOTROW				; back up
				DEC PLOTROW				; back up
				LDA #$20				; plot 20 down 0 px
				STA CHAR
				JSR PLOTCHAR			; plot 20
				INC PROGRESS			
				JMP DROPDONE
				
DROP2			CMP #$76				; if it's 76, plot 02
				BNE SMDROP2				; not 76, skip
				INC PROGRESS
				LDA #$02
				STA CHAR
				JSR PLOTCHAR
				INC PROGRESS
				
				LDA PLOTROW				; if we're at row 20ish
				CMP #$13				; should have triggered the splash
				BEQ UNDOSPLASH			; undo the first splash frame
				
				JMP DROPDONE
									
UNDOSPLASH		JSR UNSPLASH
				RTS
				
			
SMDROP2			CMP #$60				; if it's 60, plot 60 down 2 px
				BNE DROP3				; not 60, skip
				INC PLOTROW				; down 1
				INC PLOTROW				; down 1
				INC PROGRESS
				STA CHAR
				JSR PLOTCHAR
				INC PROGRESS
				DEC PLOTROW
				DEC PLOTROW
				LDA #$0					; erase behind
				JSR PLOTCHAR
				JMP DROPDONE
			
DROP3			CMP #$02				; if it's 02, erase behind it
				BNE SMDROP3
				LDA #$0
				STA CHAR
				JSR PLOTCHAR
				INC PROGRESS
				JSR PLOTCHAR
				INC PROGRESS

				LDA PLOTROW				; if we're at row 20ish
				CMP #$13				; should have triggered the splash
				BEQ UNDOSPLASH			; undo the second splash frame


				JMP DROPDONE

SMDROP3			CMP #$20				; if it's 20, erase behind it
				BNE DROPDONE
				LDA #$0
				STA CHAR
				JSR PLOTCHAR
				INC PROGRESS
				JSR PLOTCHAR
				INC PROGRESS
		
				
DROPDONE		RTS


**************************************************
*	prints one CHAR at PLOTROW,PLOTCOLUMN - clobbers A,Y
**************************************************
PLOTCHAR
				LDY PLOTROW
				TYA
				CMP #$18
				BCS OUTOFBOUNDS			; stop plotting if dimensions are outside screen
				
	
				;LDA PROGRESS			; even or odd frame
				ROR PROGRESS
				BCC PLOTCHARALT			; every other frame, write to alt text page

				LDA LoLineTableL,Y
				STA $0
				LDA LoLineTableH,Y
				STA $1       		  	; now word/pointer at $0+$1 points to line 
				JMP LOADCHAR

PLOTCHARALT		LDA AltLineTableL,Y
				STA $0
				LDA AltLineTableH,Y
				STA $1       		  	; now word/pointer at $0+$1 points to line 

LOADCHAR		ROL PROGRESS			; return progress state for next ROR

				LDY PLOTCOLUMN
				TYA
				CMP #$28
				BCS OUTOFBOUNDS			; stop plotting if dimensions are outside screen
				
				LDA CHAR				; this would be a byte with two pixels
				STA ($0),Y  


OUTOFBOUNDS		RTS
;/PLOTCHAR				   


**************************************************
*	GETS one CHAR at PLOTROW,PLOTCOLUMN - value returns in Accumulator 
**************************************************
GETCHAR

				LDY PLOTROW
				ROR PROGRESS
				BCC GETCHARALT			; every other frame, write to alt text page

				LDA LoLineTableL,Y
				STA $0
				LDA LoLineTableH,Y
				JMP STORECHAR

GETCHARALT		LDA AltLineTableL,Y
				STA $0
				LDA AltLineTableH,Y

STORECHAR		STA $1       		  	; now word/pointer at $0+$1 points to line 
				LDY PLOTCOLUMN
				ROL PROGRESS			; return progress state for next ROR
				LDA ($0),Y  			; byte at row,col is now in accumulator
				RTS
;/GETCHAR					   






**************************************************
*	CLICKS and BEEPS
**************************************************
CLICK			LDX #$06
CLICKLOOP		LDA #$10				; SLIGHT DELAY
				JSR WAIT
				LDA SPEAKER				
				DEX
				BNE CLICKLOOP
				RTS
;/CLICK

BEEP			LDX #$30
BEEPLOOP		LDA #$08				; short DELAY
				JSR WAIT
				LDA SPEAKER				
				DEX
				BNE BEEPLOOP
				RTS
;/BEEP


BONK			LDX #$50
BONKLOOP		LDA #$20				; longer DELAY
				JSR WAIT
				LDA SPEAKER				
				DEX
				BNE BONKLOOP
				RTS
;/BONK



**************************************************
* DATASOFT RND 6502
* BY JAMES GARON
* 10/02/86
* Thanks to John Brooks for this. I modified it slightly.
**************************************************


RNDINIT
               LDA   $C030			; #$AB
               STA   RNDSEED
               LDA   $4E			; #$55
               STA   RNDSEED+1
               LDA   PROGRESS		; #$7E
               STA   RNDSEED+2
               RTS

* RESULT IN ACC
RND            LDA   RNDSEED
               ROL   RNDSEED
               EOR   RNDSEED
               ROR   RNDSEED
               INC   RNDSEED+1
               BNE   RND10
               LDA   RNDSEED+2
               INC   RNDSEED+2
RND10          ADC   RNDSEED+1
               BVC   RND20
               INC   RNDSEED+1
               BNE   RND20
               LDA   RNDSEED+2
               INC   RNDSEED+2
RND20          STA   RNDSEED
               RTS




**************************************************
* Draws the two frames of the splash animation when
* a drop reaches the bottom of the screen
**************************************************

; TO DO: if progress is odd, splash further down? 

SPLASH			LDA PLOTROW
				STA ROW
				LDA PLOTCOLUMN
				STA COLUMN				

				INC PLOTROW

;DROPDOWN		ROL PROGRESS
				INC PROGRESS		; draw on next frame
DECCOL			DEC PLOTCOLUMN		; decrement 3 columns
				DEC PLOTCOLUMN		; decrement 3 columns
				DEC PLOTCOLUMN		; decrement 3 columns
				LDX #$06			; for 6 to 0 in Y
SPLASHTOP		LDA SPLASH1,X		; load SPLASH1,Y
				STA CHAR			; store CHAR
				JSR PLOTCHAR
				INC PLOTCOLUMN		; INC PLOTCOLUMN
				DEX					; next Y
				BPL SPLASHTOP		; x!=0, return 
				
				INC PLOTROW			; INC ROW
				LDX #$06			; for 6 to 0 in Y
SPLASHBOTTOM	LDA SPLASH2,X		; load SPLASH2,Y
				STA CHAR			; store CHAR
				DEC PLOTCOLUMN		; DEC PLOTCOLUMN
				JSR PLOTCHAR
				DEX
				BPL SPLASHBOTTOM	; next Y
				
				DEC PLOTROW
				INC PROGRESS		; draw on current frame
				
SPLASHF2		LDX #$06			; for 6 to 0 in Y
SPLASHTOPF2		LDA SPLASH3,X		; load SPLASH1,Y
				STA CHAR			; store CHAR
				JSR PLOTCHAR
				INC PLOTCOLUMN		; INC PLOTCOLUMN
				DEX					; next Y
				BPL SPLASHTOPF2		; x!=0, return 
				
				INC PLOTROW			; INC ROW
				LDX #$06			; for 6 to 0 in Y
SPLASHBOTTOMF2	LDA SPLASH4,X		; load SPLASH2,Y
				STA CHAR			; store CHAR
				DEC PLOTCOLUMN		; DEC PLOTCOLUMN
				JSR PLOTCHAR
				DEX
				BPL SPLASHBOTTOMF2	; next Y


				LDA ROW			; reset to row/column for next pass
				STA PLOTROW
				LDA COLUMN
				STA PLOTCOLUMN

				RTS



UNSPLASH		LDA PLOTROW
				STA ROW
				LDA PLOTCOLUMN
				STA COLUMN				

				INC PLOTROW

;DROPDOWN2		ROL PROGRESS
				INC PROGRESS

;				JSR CLICK
DECCOL2			DEC PLOTCOLUMN		; decrement 3 columns
				DEC PLOTCOLUMN		; decrement 3 columns
				DEC PLOTCOLUMN		; decrement 3 columns
				LDX #$06			; for 6 to 0 in Y
UNDOSPLASHTOP	LDA #$22			; load SPLASH1,Y
				STA CHAR			; store CHAR
				JSR PLOTCHAR
				INC PLOTCOLUMN		; INC PLOTCOLUMN
				DEX					; next Y
				BPL UNDOSPLASHTOP		; x!=0, return 
				INC PLOTROW			; INC ROW
				LDX #$06			; for 6 to 0 in Y
				INC PROGRESS
UNDOSPLASHBOTTOM 
				LDA #$22			; load SPLASH2,Y
				STA CHAR			; store CHAR
				DEC PLOTCOLUMN		; DEC PLOTCOLUMN
				JSR PLOTCHAR
				DEX
				BPL UNDOSPLASHBOTTOM	; next Y

				LDA ROW			; reset to row/column for next pass
				STA PLOTROW
				LDA COLUMN
				STA PLOTCOLUMN

				RTS




**************************************************
* Data Tables
*
**************************************************

SPLASH1				HEX 62,22,72,F2,72,22,62
SPLASH2				HEX 26,62,67,67,67,62,26

SPLASH3				HEX 22,72,22,22,22,72,22
SPLASH4				HEX 22,22,26,26,26,22,22

**************************************************
* Lores/Text lines
* Thanks to Dagen Brock for this.
**************************************************
Lo01                 equ   $400
Lo02                 equ   $480
Lo03                 equ   $500
Lo04                 equ   $580
Lo05                 equ   $600
Lo06                 equ   $680
Lo07                 equ   $700
Lo08                 equ   $780
Lo09                 equ   $428
Lo10                 equ   $4a8
Lo11                 equ   $528
Lo12                 equ   $5a8
Lo13                 equ   $628
Lo14                 equ   $6a8
Lo15                 equ   $728
Lo16                 equ   $7a8
Lo17                 equ   $450
Lo18                 equ   $4d0
Lo19                 equ   $550
Lo20                 equ   $5d0
* the "plus four" lines
Lo21                 equ   $650
Lo22                 equ   $6d0
Lo23                 equ   $750
Lo24                 equ   $7d0


Alt01                 equ   $800
Alt02                 equ   $880
Alt03                 equ   $900
Alt04                 equ   $980
Alt05                 equ   $A00
Alt06                 equ   $A80
Alt07                 equ   $B00
Alt08                 equ   $B80
Alt09                 equ   $828
Alt10                 equ   $8a8
Alt11                 equ   $928
Alt12                 equ   $9a8
Alt13                 equ   $A28
Alt14                 equ   $Aa8
Alt15                 equ   $B28
Alt16                 equ   $Ba8
Alt17                 equ   $850
Alt18                 equ   $8d0
Alt19                 equ   $950
Alt20                 equ   $9d0
* the "plus four" lines
Alt21                 equ   $A50
Alt22                 equ   $Ad0
Alt23                 equ   $B50
Alt24                 equ   $Bd0




LoLineTable          da    	Lo01,Lo02,Lo03,Lo04
                     da    	Lo05,Lo06,Lo07,Lo08
                     da		Lo09,Lo10,Lo11,Lo12
                     da    	Lo13,Lo14,Lo15,Lo16
                     da		Lo17,Lo18,Lo19,Lo20
                     da		Lo21,Lo22,Lo23,Lo24

AltLineTable         da    	Alt01,Alt02,Alt03,Alt04
                     da    	Alt05,Alt06,Alt07,Alt08
                     da		Alt09,Alt10,Alt11,Alt12
                     da    	Alt13,Alt14,Alt15,Alt16
                     da		Alt17,Alt18,Alt19,Alt20
                     da		Alt21,Alt22,Alt23,Alt24


** Here we split the table for an optimization
** We can directly get our line numbers now
** Without using ASL
LoLineTableH         db    >Lo01,>Lo02,>Lo03
                     db    >Lo04,>Lo05,>Lo06
                     db    >Lo07,>Lo08,>Lo09
                     db    >Lo10,>Lo11,>Lo12
                     db    >Lo13,>Lo14,>Lo15
                     db    >Lo16,>Lo17,>Lo18
                     db    >Lo19,>Lo20,>Lo21
                     db    >Lo22,>Lo23,>Lo24
LoLineTableL         db    <Lo01,<Lo02,<Lo03
                     db    <Lo04,<Lo05,<Lo06
                     db    <Lo07,<Lo08,<Lo09
                     db    <Lo10,<Lo11,<Lo12
                     db    <Lo13,<Lo14,<Lo15
                     db    <Lo16,<Lo17,<Lo18
                     db    <Lo19,<Lo20,<Lo21
                     db    <Lo22,<Lo23,<Lo24

AltLineTableH        db    >Alt01,>Alt02,>Alt03
                     db    >Alt04,>Alt05,>Alt06
                     db    >Alt07,>Alt08,>Alt09
                     db    >Alt10,>Alt11,>Alt12
                     db    >Alt13,>Alt14,>Alt15
                     db    >Alt16,>Alt17,>Alt18
                     db    >Alt19,>Alt20,>Alt21
                     db    >Alt22,>Alt23,>Alt24
AltLineTableL        db    <Alt01,<Alt02,<Alt03
                     db    <Alt04,<Alt05,<Alt06
                     db    <Alt07,<Alt08,<Alt09
                     db    <Alt10,<Alt11,<Alt12
                     db    <Alt13,<Alt14,<Alt15
                     db    <Alt16,<Alt17,<Alt18
                     db    <Alt19,<Alt20,<Alt21
                     db    <Alt22,<Alt23,<Alt24

