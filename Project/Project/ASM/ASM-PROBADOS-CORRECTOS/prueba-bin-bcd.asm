;***************************************************************
	; PROGRAMA CONTROL DIFUSO DE TEMPERATURA

	;title	"PIC Sample code: PIC16F88 program"
	;subtitle	"CARLOS SANTIAGO CRUZ - TESIS - prueba del convertidor analógico digital"

;	codigo para el 16f88 a 4 MHz
;***************************************************************
	list	p=16F88
	#include	<p16F88.inc>
	
;	__CONFIG	_CONFIG1 & _CP_OFF & _CCP1_RB0 & _DEBUG_OFF & _CPD_OFF & _LVP_OFF & _BODEN_OFF & _MCLR_ON & _PWRTE_ON & _WDT_OFF & _INTRC_IO
	ERRORLEVEL -302

;***************************************************************

z1				equ	20h		;REGISTROS COMODINES
z2				equ	21h
z3				equ	22h
z4				equ	23h
UNI				equ	24h
DECE			equ 	25h
SP				equ	26h
uni_comodin		equ	27h
dece_comodin	equ	28h
STATUS_TEMP	equ 29h
PCLATH_TEMP	equ 2Ah
W_TEMP		equ	2Bh
BINARIO			equ	2Ch
CONTADOR1	equ 2Dh
CONTADOR2	equ 2Eh
CONTADOR3	equ 2Fh
;********************** 
BCDH			equ 30h
BCDL			equ 31h
BCD_TEMP		equ 32h
CUENTA		equ 33h
BIN				equ 34h
BIN_comodin		equ 34h
;***************************************************************

;***************************************************************
; registros 
;	ADRESH	1Eh		banco 0
;	ADRESL	9Eh		banco 1
;	ANSEL		9Bh		banco 1
; 	ADCON0	1Fh		banco 0
;	ADCON1	9Fh		banco 1
;****************************************************************

;###################################################################################################################################
							ORG		0x0000
							GOTO		INICIO
	
							;ORG		0x04
							;GOTO		SP_INTERRUPT

							ORG		0x05
;###################################################################################################################################

INICIO						CLRF		PORTA							; limpia puerto A
							CLRF		PORTB							; limpia puerto B
							BSF		STATUS,RP0					; selecciona Banco 1; Se encuentran registros TRISA y TRISB
																		; al reset STATUS=00000000
																		; REGISTRO STATUS = 	IRP 		RP1		RP0		T0_		PD_		Z		DC		C
																		;  RP1 RP0
																		;  0    	0		banco 0
																		;  0    	1		banco 1		RP0=1
																		;  1    	0		banco 2
																		;  1    	1		banco 3



							BSF		OSCCON,6						;Pone el oscilador a 4 MHz con el oscilador interno RC; OSCCON controla varios aspectos de operacion del sistema de reloj; Banco 1
							BSF		OSCCON,5						;bit 6-4		110		4 MHZ
																		;al reset inicia con 0's el registro.

							MOVLW		H'07'							;carga el registro W con 07		0000 0111
							MOVWF		CMCON							;CMCON ->	C2OUT	C1OUT	C2INV	C1INV	CIS	 CM2  CM1  CM0
																		; ver los modos de operacion de los comparadores
																		; comparadores apagados
																		;CLRF		TRISA			;Puerto A como salida		0 - salida; 1 - entrada

;##### CONFIGURA LOS PUERTOS  A y B, (A0,A1,A2,A3 = ENTRADAS)  (A4,A5,A6,A7=SALIDAS),  (B0,B1,B2,B3 = ENTRADAS)  (B4,B5,B6,B7=SALIDAS) ##################

							MOVLW		H'0F'							;Puerto B como salida		0 - salida; 1 - entrada
							MOVWF		TRISA		
																	
							MOVLW		H'0F'
							MOVWF		TRISB							;Puerto B como salida		0 - salida; 1 - entrada

							;BCF		STATUS,RP0					;Selecciona Banco 0

;############################### CONFIGURAR FLANCO DE SUBIDA PARA INTERRUPCION EXTERNA POR PIN RB0 ###############################
							BSF		STATUS,RP0					; selecciona banco 1
							BCF		STATUS,RP1					; selecciona banco 1
							BSF 		OPTION_REG,6					; activa por flanco de bajada

;######################### HABILITACION DE INTERRUPCIONES ###########################################################################
							
							BSF		INTCON,	GIE      					; habilitamos todas las interrupciones
							BSF		INTCON,	INTE     					; que sean interrupciones externas

;########################################## CONFIGURANDO EL CONVERTIDOR A/D ##########################################################

															;1.	Configure el modulo A/D
															;		•	Configurar E/S analógica/digital 	(ANSEL)	BANCO 1		
							BSF		STATUS,RP0		; selecciona banco 1
							MOVLW		H'0F'
							MOVWF		ANSEL				; Registro ANSEL - ANS6 ANS5 ANS4 ANS3 ANS2 ANS1 ANS0 
															; Configura la funcion de los pines de los puertos
															; pueden ser configurados como entradas analògicas 
															; (RA3,RA2 tambien pueden ser tensiones de referencia)
															; o como entradas/salidas digitales; 
															;	1 - analog I/O; 
															;	0 - digital I/O
															; 
							MOVLW			H'00'							;		
							MOVWF			ADCON1		;		•	Configurar tensión de referencia. 	(ADCON1)	BANCO 1
															; ADCON1:	ADFM	ADCS2	  VCFG1   VCFG0	-	        -               -               -
															
																			0		0		0		0		0		0		0		0
																			
															; Bit 7	ADFM: selección de bit de resultado de formato A/D
															; 				1=justificación derecha: los seis bits mas significantes de ADRESH son leídos como ‘0’
															; 				0=justificación izquierda: los seis bits menos significativos de ADRESL son leidos como ‘0’.	*justificacion izquierda
															; Bit 6	ADSC2: bit de selección de división de reloj por 2 del A/D
															;				1=fuente de reloj es dividida por 2 cuando el sistema de reloj es usado.
															; 				0=deshabilitado.																*deshabilitado
															; Bit 5-4	VCFG <1:0> bits de configuración de las tensiones de referencia del A/D
															; 				Estado lógico    VREF+ VREF- 
															; 				00                   AVDD  AVSS		*Elegimos este
															; 				01                   AVDD   VREF-
															; 				10                   VREF+   AVSS
															; 				11                   VREF+   VREF-
															; Bit  3-0	Sin implementación leídos como ‘0’

															;primero vamos a poner el ADSC2=0, pero creo que en el reset es 0 :)							

							BCF		STATUS,RP0		;seleccionamos banco 0

							MOVLW		H'C0'
							MOVWF		ADCON0		 	;		•	Seleccionar canal de entrada A/D 	(ADCON0)	BANCO 0

															; ADCON0:	ADSC1 	ADCS0	CHS2	CHS1	CHS0	DO/DONE	-	ADON
															;Bit 7-6	ADSC<1:0> selección de bits del reloj de conversión
															;	If ADSC2=0
															;		00 Fosc/2
															;		01 Fosc/8
															;		10 Fosc/32
															;		11 FRC (reloj derivado del oscilador interno RC del modulo A/D) 
															;	if ADSC2=1
															;		00 Fosc/4
															;		01 Fosc/16
															;		10 Fosc/64
															;		11 FRC (reloj derivado del oscilador interno RC del modulo A/D) 
															;Bit 5-3	CHS <2:0> selección de bits para los canales analógicos
															;		000 canal 0 (RA0/AN0)
															;		001 canal 1 (RA1/AN1)
															;		010 canal 2 (RA2/AN2)
															;		011 canal 3 (RA3/AN3)
															;		100 canal 4 (RA4/AN4)
															;		101 canal 5 (RB6/AN5)
															;		110 canal 6 (RB7/AN6)
															;Bit 2	GO/DONE_ bit de estado de la conversión (A/D)
															;		If ADON=1
															;					1=la conversión esta en progreso (poniendo a ‘1’ este bit empieza la conversión
															;					0=la conversión no esta en progreso (este bit es puesto a ‘0’ por hardware cuando la conversión es completada
															;Bit 1 	Sin implementar: leído como ‘0’
															;Bit 0	ADON: bit de encendido del A/D
															;					1=modulo convertidor A/D esta operando
															;					0=modulo convertidor esta apagado y no consume corriente de operación.
	
		;hecho arriba											;		•	Seleccionar reloj de conversión A/D	(ADCON0)

;*********************************************************************************************************
REGRESA		MOVLW				B'01001101'
					MOVWF				BIN
				
				CALL 				BIN2BCD_RS3		; llama a la subrutina de conversion de BINARIO A BCD
														; en el registro BCDL se encuentran (NIBBLE decenas)(NIBBLE UNIDADES), necesitamos desplegarlo en el display 7 segmentos
				CALL 				desplegar_bin_bcd	
				GOTO				REGRESA																			

;********************************************* PROBANDO CONVERSION BINARIO A BCD
BIN2BCD_RS3
        			clrf     		BCDH
        			clrf     		BCDL

        			movlw    	0x08
        			movwf    	CUENTA

CONVERSION1
        			bcf     		 STATUS,C
        			rlf      		BIN,f
        			rlf      		BCDL,f
        			decfsz   		CUENTA,f
        			goto     		$+2
        			goto     		TERMINA_CONVERSION
        			movlw    	b'00001111'
        			andwf    		BCDL,w
        			movwf    	BCD_TEMP
        			movlw    	0x05
       				subwf    		BCD_TEMP,w
        			btfsc    		STATUS,C
        			call     		sum3nib_bajo
        			movlw    	b'11110000'
        			andwf    		BCDL,w
        			movwf    	BCD_TEMP
       				movlw    	0x50
        			subwf   		 BCD_TEMP,w
        			btfsc    		STATUS,C
        			call     		sum3nib_alto
			        goto     		CONVERSION1

TERMINA_CONVERSION
				return
				
				;*******************************
				;Subrutina que se encarga de
				;sumar 3 al nibble bajo de BCDL
				;*******************************
sum3nib_bajo
				movlw 		0x03
				addwf 		BCDL,f
				btfss 		STATUS,C
				return
				rlf 			BCDH,f
				return
				
				;*******************************
				;Subrutina que se encarga de
				;sumar 3 al nibble alto de BCDL
				;*******************************
sum3nib_alto
				movlw 		0x30
				addwf 		BCDL,f
				btfss 		STATUS,C
				return
				rlf 			BCDH,f
				return
;###################################################################
; como tenemos que desplegar el nibble mas alto que son las decenas, solamente moveremos el BCDL al puerto B, ya usanos RB4 a RB7
desplegar_bin_bcd	MOVF		BCDL,0
					MOVWF		PORTB
										; ahora necesitamos mover al puerto A de RA4 a RB7 el nibble mas bajo de BCDL
					RLF		BCDL,1	;recorremos una vez a la izquierda, lo guardamos en el mismo BCDL
					RLF		BCDL,1	;recorremos una vez a la izquierda, lo guardamos en el mismo BCDL
					RLF		BCDL,1  ;recorremos una vez a la izquierda, lo guardamos en el mismo BCDL
					RLF		BCDL,0  ;recorremos una vez a la izquierda, lo guardamos en el registro W
					
					MOVWF		PORTA	; movemos el registro W al puerto A
					RETURN						
;####################################################################
;###################################################################################################################################	
					END
;###################################################################################################################################
