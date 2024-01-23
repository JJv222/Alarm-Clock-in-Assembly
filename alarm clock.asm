;-----------------------------------------------------------------------


;                            USTAWIENIA 


;-----------------------------------------------------------------------
LED EQU P1.7
DZWONEK EQU P1.5
    LJMP START
;-----------------------------------------------------------------------
;                            PRZERWANIA 
;-----------------------------------------------------------------------
    ORG 1BH
    MOV TH1,#76 
    DJNZ R0,NO_1SEK ;czy minęła 1 sek 
    CPL LED ;zmiana stanu diody
    CPL DZWONEK ;zmiana stanu głośnika
    CLR TR1
NO_1SEK: 
    RETI 
;-----------------------------------------------------------------------


;                            PROGRAM GŁÓWNY


;-----------------------------------------------------------------------
    ORG 100H
START:
    CLR RS0
    LCALL LCD_CLR
    LCALL WAIT_KEY
    MOV R0,A
    LCALL WAIT_ENTER
;-----------------------------------------------------------------------
;                            Wybór wtrybu timera
;-----------------------------------------------------------------------
    MOV A,R0
    CJNE A,#0,TYP_1
TYP_0:
    MOV TMOD,#16

    MOV TH0,#112 
    MOV TL0,#0 
    
    MOV TH1,#76
    MOV TL1,#0 
    LJMP SET_IT

TYP_1:
    CJNE A,#1,TYP_2
    MOV TMOD,#17

    MOV TH0,#76 
    MOV TL0,#0 
    
    MOV TH1,#76 
    MOV TL1,#0
    LJMP SET_IT
TYP_2:
    CJNE A,#2,TYP_3
    MOV TMOD,#18

    MOV TH0,#0
    MOV TL0,#0 
    
    MOV TH1,#76 
    MOV TL1,#0
    LJMP SET_IT
TYP_3:
    MOV TMOD,#19
    MOV TH0,#0
    MOV TL0,#0 
    
    MOV TH1,#76 
    MOV TL1,#0
;---------------------------------

SET_IT:
    SETB EA
    SETB ET1
    SETB TR0
    ; ustawienie zegara
    LCALL WPROWADZ
    MOV R1,A
    LCALL WPROWADZ
    MOV R2,A
    LCALL WPROWADZ
    MOV R3,A
    LCALL WAIT_ENTER
    LCALL LCD_CLR
    ; ustawienie stopera
    LCALL WPROWADZ
    MOV R4,A
    LCALL WPROWADZ
    MOV R5,A
    LCALL WPROWADZ
    MOV R6,A
    LCALL DISPLEE
    MOV A,R0
    CJNE A,#0,LOP1
;informacje R1-HH,R2-MM,R3-SS
;-----------------------------------------------------------------------
;                               PĘTLA GŁÓWNA
;-----------------------------------------------------------------------
;--mode 0
LOOP0:
    LCALL CHECK_ALARM
    MOV R7,#200 
    LCALL HOUR_UPDATE
    LCALL DISPLAY_CLOCK_0
	SJMP LOOP0

;--mode 1
LOP1:
    MOV A,R0
    CJNE A,#1,LOP2
LOOP1:
    LCALL CHECK_ALARM
    MOV R7,#20 
    LCALL HOUR_UPDATE
    LCALL DISPLAY_CLOCK_1
	SJMP LOOP1

;--mode 2
LOP2:
    CJNE A,#2,LOOP3
LOOP2:
    LCALL CHECK_ALARM
    MOV R7,#180 
    LCALL HOUR_UPDATE
    LCALL DISPLAY_CLOCK_2
	SJMP LOOP2
;--mode 3
LOOP3:
    LCALL CHECK_ALARM
    MOV R7,#180 
    LCALL HOUR_UPDATE
    LCALL DISPLAY_CLOCK_2
	SJMP LOOP3
    NOP
;-----------------------------------------------------------------------


;                        FUNKCJE DODATKOWE


;-----------------------------------------------------------------------
WPROWADZ: ;wprowadzanie 2 liczb 2 cyfrowych w bcd
    LCALL WAIT_KEY ; Wczytaj liczbę dziesiątek
    MOV B,#10 ; pomnóż
    MUL AB ; przez 10
    PUSH ACC
    LCALL WAIT_KEY ;wczytaj liczbę jedności
    POP B
    ADD A,B ; dodaj liczbę jedności do R1
    RET ; wyjdź z podprogramu. Wynik w A.


BCD:    ;funkcja przelicza hex na bcd 2cyfrowe
    ; ACC-liczba do zamiany np: 93 albo 255
    MOV B,#10
    DIV AB
    SWAP A
    ADD A,B
    LCALL WRITE_HEX
    RET
DISPLEE:; funkcja wyswietla zegar
    LCALL LCD_CLR
    MOV A,R1
    LCALL BCD
    MOV A,#':'
    LCALL WRITE_DATA
    MOV A,R2
    LCALL BCD
    MOV A,#':'
    LCALL WRITE_DATA
    MOV A,R3
    LCALL BCD
    RET

HOUR_UPDATE: ;funkcja aktualizuje czas zegara
    INC 03
;sekundy
    CJNE R3,#60,FIN
    INC 02
    MOV R3,#0
;minuty
    CJNE R2,#60,FIN
    INC 01
    MOV R2,#0
;godziny
    CJNE R1,#24,FIN
    MOV R1,#0
FIN:
    RET


CHECK_ALARM: ;funkcja sprawdza czy włączyć alarm
    MOV A,R3
    CJNE A,06,Fin
    MOV A,R2
    CJNE A,05,Fin
    MOV A,R1
    CJNE A,04,Fin
    MOV R0,#80 ; alarm to dioda i dziwek trwajacy około 4sekundy
    CPL LED
    CPL DZWONEK
    SETB TR1 ;start Timera 1
Fin:
    RET


DISPLAY_CLOCK_0: ;funkcja odpowiada za wywołanie timera który wykonue skip czasu 50ms*R7
START_TIMER_0:
	JNB TF0,$			;czekaj, aż Timer 0
	MOV TH0,#112 	;TH0 na 5ms
	CLR TF0 			;zerowanie flagi timera 0
	DJNZ R7,START_TIMER_0 	;odczekanie 200*5ms=1s
    ;wyswietl zegar
    LCALL DISPLEE
    RET

DISPLAY_CLOCK_1: ;funkcja odpowiada za wywołanie timera który wykonue skip czasu 50ms*R7
START_TIMER_1:
	JNB TF0,$			;czekaj, aż Timer 0
	MOV TH0,#76 	;TH0 na 50ms
	CLR TF0 			;zerowanie flagi timera 0
	DJNZ R7,START_TIMER_1 	;odczekanie 20*50ms=1s
    ;wyswietl zegar
    LCALL DISPLEE
    RET
DISPLAY_CLOCK_2: ;funkcja odpowiada za wywołanie timera który wykonue skip czasu 50ms*R7
    MOV A,#20
UPD:
    PUSH ACC
START_TIMER_2:
	JNB TF0,$			;czekaj, aż Timer 0	
	CLR TF0 			;zerowanie flagi timera 0
	DJNZ R7,START_TIMER_2 	;odczekanie 20*50ms=1s
    MOV R7,#180
    POP ACC
    DJNZ ACC,UPD
    ;wyswietl zegar
    LCALL DISPLEE
    RET



STOP: ;funkcja końcowa
	LJMP STOP
	NOP
    RET