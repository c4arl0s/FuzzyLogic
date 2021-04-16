;***************************************************************
	; PROGRAMA CONTROL DIFUSO DE TEMPERATURA

	;title	"PIC Sample code: PIC16F88 program"
	;subtitle	"CARLOS SANTIAGO CRUZ - "

;	codigo para el 16f88 a 4 MHz, RELOJ INTERNO RC
;***************************************************************
	list	p=16F88
	#include	<p16F88.inc>
	
#DEFINE	BANCO0	BCF	STATUS,RP0
#DEFINE	BANCO1	BSF	STATUS,RP1

;***************************************************************

z1				equ	20h		;REGISTROS COMODINES
z2				equ	21h
z3				equ	22h
z4				equ	23h
;****************************************************************
UNI				equ	24h
DECE			equ 	25h
SP				equ	26h
uni_comodin		equ	27h
dece_comodin	equ	28h
STATUS_TEMP	equ 29h
PCLATH_TEMP	equ 2Ah
W_TEMP		equ	2Bh
;**************************************************
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
BIN_comodin		equ 35h
;***************************************************************
; RECORDATORIO DE EN DONDE SE ENCUENGRAN ALGUNOS REGISTROS 
;	ADRESH	1Eh		banco 0
;	ADRESL	9Eh		banco 1
;	ANSEL		9Bh		banco 1
; 	ADCON0	1Fh		banco 0
;	ADCON1	9Fh		banco 1
;****************************************************************

;###################################################################################################################################
							ORG		0x00
							GOTO		INICIO
	
							ORG		0x04
							GOTO		SP_INTERRUPT

							ORG		0x05
;###################################################################################################################################

INICIO						CALL 		limpiar_registros					; Limpia todos los registros a usar
							;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
							BANCO1
																		; al reset STATUS=00000000
																		; REGISTRO STATUS = 	IRP 		RP1		RP0		T0_		PD_		Z		DC		C
																		;  RP1 RP0
																		;  0    	0		banco 0
																		;  0    	1		banco 1		
																		;  1    	0		banco 2
																		;  1    	1		banco 3
																		;------------------------------------------------------------------------------------------------------------------------------------------
																		; OSCCON		--	IRCF2	IRCF1	IRCF0	OSTS	IOFS	SCS1	SCS0
																		;				bit 6-4 IRCF<2:0>: Internal RC Oscillator Frequency Select bits
																		;				
																		;				000 = 31.25 kHz
																		;				001 = 125 kHz
																		;				010 = 250 kHz
																		;				011 = 500 kHz
																		;				100 = 1 MHz
																		;				101 = 2 MHz
																		;				110 = 4 MHz
																		;				111 = 8 MHz
							BSF		OSCCON,6						;Pone el oscilador a 4 MHz con el oscilador interno RC; OSCCON controla varios aspectos de operacion del sistema de reloj; Banco 1
							BSF		OSCCON,5						;bit 6-4			110		4 MHZ
							BCF		OSCCON,4						;al reset inicia con 0's el registro.
							;---------------------------------------------------------------------------------------------------------------------------------------------------------------
							BANCO1
							MOVLW		H'07'							;carga el registro W con 07		0000 0111, al reset 0000 0111
							MOVWF		CMCON							;CMCON ->	C2OUT	C1OUT	C2INV	C1INV	CIS	 CM2  CM1  CM0
																		; ver los modos de operacion de los comparadores
																		; comparadores apagados
																													
;##### CONFIGURA LOS PUERTOS  A y B, (A0,A1,A2,A3 = ENTRADAS)  (A4,A5,A6,A7=SALIDAS),  (B0,B1,B2,B3 = ENTRADAS)  (B4,B5,B6,B7=SALIDAS) ##################
							BANCO1
							
							MOVLW		B'10111111'						; RA7	RA6		RA5		RA4		RA3		RA2		RA1		RA0
							MOVWF		TRISA							;    1		  0	          1		  1		  1 		   1		   0		   1	
																		;Puerto A como salida		0 - salida; 	1 - entrada
							MOVLW		B'00000001'						; RA7	RA6		RA5		RA4		RA3		RA2		RA1		RA0
							MOVWF		TRISB							;    0		  0	          0		  0		  0 		   0		   0		   0		   

;########################################## CONFIGURANDO EL CONVERTIDOR A/D ##########################################################

															;1.	Configure el modulo A/D
															;		•	Configurar E/S analógica/digital 	(ANSEL)	BANCO 1		
							BANCO1						; selecciona banco 1
							
							BSF			ANSEL,0		; Registro ANSEL - ANS6 ANS5 ANS4 ANS3 ANS2 ANS1 ANS0 
															; Configura la funcion de los pines de los puertos
															; pueden ser configurados como entradas analògicas 
															; (RA3,RA2 tambien pueden ser tensiones de referencia)
															; o como entradas/salidas digitales; 
															;	1 - analog I/O; 
															;	0 - digital I/O
															; 
															;----------------------------------------------------------------------------------------------------------------------------------------------------
							BANCO1						; 	(selecciona banco 1)																
															;		•	Configurar tensión de referencia. 	(ADCON1)	BANCO 1

															; ADCON1:	ADFM	ADCS2	VCFG1   	VCFG0	  --	  --	  --	  --
															; Bit 7	ADFM: selección de bit de resultado de formato A/D
															; 				1=justificación derecha: los seis bits mas significantes de ADRESH son leídos como ‘0’
							BCF			ADCON1,7		; 				0=justificación izquierda: los seis bits menos significativos de ADRESL son leidos como ‘0’.	*justificacion izquierda
															; Bit 6	ADSC2: bit de selección de división de reloj por 2 del A/D
															;				1=fuente de reloj es dividida por 2 cuando el sistema de reloj es usado.
							BCF			ADCON1,6		; 				0=deshabilitado.																*deshabilitado
															; Bit 5-4	VCFG <1:0> bits de configuración de las tensiones de referencia del A/D
															; 				Estado lógico    	VREF+ VREF- 
							BCF			ADCON1,5		; 				00                   		AVDD  AVSS		*Elegimos este
							BCF			ADCON1,4		; 				01                   		AVDD   VREF-
															; 				10                  		VREF+   AVSS
															; 				11                  		VREF+   VREF-
															; Bit  3-0	Sin implementación leídos como ‘0’

															;primero vamos a poner el ADSC2=0, pero creo que en el reset es 0 :)							
															;-----------------------------------------------------------------------------------------------------------------------------------------------										BCF		STATUS,RP0		;		•	Seleccionar canal de entrada A/D 	(ADCON0)	BANCO 0
							BANCO0						; selecciona banco 0
															; ADCON0:	ADSC1 	ADCS0	CHS2	CHS1	CHS0	DO/DONE	--	ADON
															;				1		1	   0             0               0                  0               0            0
							BSF		ADCON0,7			;Bit 7-6	ADSC<1:0> selección de bits del reloj de conversión
							BSF		ADCON0,6			;	If ADSC2=0
															;		00 Fosc/2
															;		01 Fosc/8
															;		10 Fosc/32
															;		11 FRC (reloj derivado del oscilador interno RC del modulo A/D) 
															;	if ADSC2=1
															;		00 Fosc/4
															;		01 Fosc/16
															;		10 Fosc/64
															;		11 FRC (reloj derivado del oscilador interno RC del modulo A/D) 
							BCF		ADCON0,5			;Bit 5-3	CHS <2:0> selección de bits para los canales analógicos
							BCF		ADCON0,4			;		000 canal 0 (RA0/AN0)
							BCF		ADCON0,3			;		001 canal 1 (RA1/AN1)
															;		010 canal 2 (RA2/AN2)
															;		011 canal 3 (RA3/AN3)
															;		100 canal 4 (RA4/AN4)
															;		101 canal 5 (RB6/AN5)
															;		110 canal 6 (RB7/AN6)
							;(utilizados en prog princ)			;Bit 2	GO/DONE_ bit de estado de la conversión (A/D)
															;		If ADON=1
															;					1=la conversión esta en progreso (poniendo a ‘1’ este bit empieza la conversión
															;					0=la conversión no esta en progreso (este bit es puesto a ‘0’ por hardware cuando la conversión es completada
															;Bit 1 	Sin implementar: leído como ‘0’
							;(utilizado en prog princ)			;Bit 0	ADON: bit de encendido del A/D
															;					1=modulo convertidor A/D esta operando
															;					0=modulo convertidor esta apagado y no consume corriente de operación.
	
		;hecho arriba											;		•	Seleccionar reloj de conversión A/D	(ADCON0)
;#####################################################################################################################################
;############################### CONFIGURAR FLANCO DE SUBIDA PARA INTERRUPCION EXTERNA POR PIN RB0 ###############################

							BANCO1
							BSF 		OPTION_REG,6					; activa por flanco de subida, bit INTEDG

;#####################################################################################################################################
;################################################# HABILITACION DE INTERRUPCIONES ###########################################################################
							BANCO1
							BSF		INTCON,	4     					; que sea interrupcion externa por RB0, bit INTE bit 4
							BSF		INTCON,	7      				; habilitamos interrupcion global GIE bit 7

;###########################################################################################################################################

;################################# EMPIEZA LA CONVERSION #############################
			BANCO0
			BSF		ADCON0,0			;		•	Encienda el modulo A/D 	(ADCON0)	(biit cero)
											;2.	Configurar interrupción A/D (si se desea)
											;		•	Poner a ‘0’ bit ADIF
			;no deseamos					;		•	Poner a ‘1’ bit ADIE
											;		•	Poner a ‘1’ bit PEIE
											;		•	Poner a ‘1’ bit GIE
REG		CALL 		RETRASO			;3.	Esperar el tiempo de adquisición requerido
											;4.	Empezar conversión.
			BSF		ADCON0,2			;		•	Poner a ‘1’ bit GO/DONE_ (ADCON0)
ESP		BTFSC		ADCON0,2			;5.	Esperar para completar la conversión A/D, por cualquiera de los siguientes:
			GOTO		ESP				;		•	Poleando (modo poleo o de ciclo) para que el bit GO/DONE_ sea puesto a ‘0’ (con interrupción deshabilitada)
											;		•	Esperando por interrupción de A/D
											;6.	Leer el registro par que da el resultado de la conversión. (ADRESH:ADRESL); en este caso nos mostrara los 8 bits mas significativos debido a la justificacion izquierda
			
											;		•	Poner a ‘0’ bit ADIF si es requerido.
											;7.	Para la siguiente conversión, vaya a los pasos 1 o paso 2 como sea requerido. El tiempo de conversión por bit es definido como TAD. Un mínimo de 2TAD es requerido antes de que la siguiente adquisición empiece.
							 				; regresa por otra conversion
			BANCO0
			MOVF		ADRESH,0			;mueve el registro ADRESH al registro W
			
			MOVWF		BIN_comodin			; salva el numero binario en BIN_comodin
			MOVWF		BIN					; salva el numero binario en BIN
			CALL 		BIN_BCD		; llama a la subrutina de conversion de BINARIO A BCD
											; en el registro BCDL se encuentran (NIBBLE decenas)(NIBBLE UNIDADES), necesitamos desplegarlo en el display 7 segmentos
			CALL 		desplegar_bin_bcd												
			CALL 		RETRASO
			GOTO		REG
;***************************************************************;***************************************************************;***************************************************************;***************************************************************
;*************Retraso **************************************************

RETRASO			BANCO0
					MOVLW			D'3'
					MOVWF			z3
					MOVLW			D'137'
					MOVWF			z2
					DECFSZ		z1,f
					GOTO			$-1
					DECFSZ		z2,f
					GOTO			$-3
					DECFSZ		z3,f
					GOTO			$-5
					RETURN

;###################################################################################################################################
;INTERRUPCION

SP_INTERRUPT		RETFIE
;###################################################################################################################################	
BIN_BCD		BANCO0
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
sum3nib_bajo	BANCO0
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
sum3nib_alto		BANCO0
				movlw 		0x30
				addwf 		BCDL,f
				btfss 		STATUS,C
				return
				rlf 			BCDH,f
				return
;###################################################################
; movemos el registro BCDL al puerto B y el bit0 del registro BCDL al pin1 del puerto A

desplegar_bin_bcd	BANCO0

					MOVF		BCDL,0		; mueve el reg BCDL al registro W
					MOVWF		PORTB		; mueve el registro W al PORTB
					BTFSS		BCDL,0		; salta si hay un '1' en el bit0 del registro BCDL
					GOTO		pon_cero	; salta a etiqueta SIGUE
					BSF		PORTA,6	; pon un '1' en el pin1 del PUERTO A
					GOTO		termina
pon_cero			BCF		PORTA,6	; pon un '0' en el pin1 del puerto A					
termina				RETURN					
								
;####################################################################
limpiar_registros				BANCO0
							CLRF		PORTA							; limpia puerto A
							CLRF		PORTB							; limpia puerto B
							CLRF		z1					
							CLRF 		z2				
							CLRF		z3				
							CLRF 		z4				
							;****************************************************************
							CLRF		UNI				
							CLRF 		DECE			
							CLRF 		SP				
							CLRF 		uni_comodin		
							CLRF 		dece_comodin	
							CLRF 		STATUS_TEMP	
							CLRF 		PCLATH_TEMP	
							CLRF 		W_TEMP		
							;**************************************************
							CLRF 		BINARIO			
							CLRF 		CONTADOR1	
							CLRF 		CONTADOR2	
							CLRF 		CONTADOR3	
							;********************** 
							CLRF 		BCDH			
							CLRF 		BCDL			
							CLRF 		BCD_TEMP		
							CLRF 		CUENTA		
							CLRF 		BIN				
							CLRF 		BIN_comodin							
							RETURN
;################################ PARA QUE NO SE PIERDA AQUI ESTA EL FINAL DEL PROGRAMA ##############################################################################################################################	
					END
;###################################################################################################################################
