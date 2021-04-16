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
	
							ORG		0x04
							GOTO		SP_INTERRUPT

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

							MOVLW		H'0F'
							MOVWF		TRISA		
																		;Puerto B como salida		0 - salida; 1 - entrada
							MOVLW		H'0F'
							MOVWF		TRISB

							;BCF		STATUS,RP0					;Selecciona Banco 0

;############################### CONFIGURAR FLANCO DE SUBIDA PARA INTERRUPCION EXTERNA POR PIN RB0 ###############################
							BSF		STATUS,RP0					; selecciona banco 1
							BCF		STATUS,RP1					; selecciona banco 1
							BSF 		OPTION_REG,6						; activa por flanco de bajada

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
															; ADCON1:	ADFM	ADCS2	VCFG1   	VCFG0	-	-	-	-
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



;################################# PRUEBA EL SET POINT, AUNQUE NO SE SIMULE  #############################

;{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{ {{{{{{{{{{{{{{{{{{{{{{{{  SUBRUTINA DE INTERRUPCION }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

		; ============ guarda registros importantes =====================

SP_INTERRUPT	MOVWF 	W_TEMP 		;Copy W to TEMP register
				SWAPF 		STATUS,W 		;Swap status to be saved into W
				CLRF 		STATUS 		;bank 0, regardless of current bank, Clears IRP,RP1,RP0
				MOVWF 	STATUS_TEMP 	;Save status to bank zero STATUS_TEMP register
				MOVF 		PCLATH, W 		;Only required if using page 1
				MOVWF 	PCLATH_TEMP 	;Save PCLATH into W
				CLRF 		PCLATH 		;Page zero, regardless of current page

				; ============ inicia configuracion del set point

				CLRF		UNI				;limpia los registros importantes
				CLRF		DECE			;limpia reg
				MOVLW		B'0101'			;carga con 5 el registro W
				MOVWF		SP				;mueve el reg W al registro SP
				CALL		SENAL_SP		; envia señal SP a los displays 7 segmentos
				CALL		retraso_500ms   	; retraso de medio segundo para visualizar señal SP

				;---------subrutina principal de la interrupcion del set poin  - monitorea si has presionado boton de unidades o de decenas ----------------------------

monitor_u		BTFSS		PORTB,1
				goto  		monitor_d
				goto		config_u

monitor_d		BTFSS		PORTB,2
				goto 		sigue_monitor
				goto		config_d

sigue_monitor	call			despliega_u
				call 			despliega_d
CONTINUA		call 			retraso_500ms
				;call			envia_nada_al_display
				BCF		STATUS,2				;pone a cero bit Z; por si anda por ahi activo.
				DECFSZ 	 SP,1					;decrementa SP, si es cero salta
				GOTO		monitor_u				;regresa a seguir monitoreando las unidades
				CALL		BCD_BINARIO						

			;		
			; ========== recuperacion de reg import =============
		
				MOVF 		PCLATH_TEMP,W 		;Restore PCLATH
				MOVWF 	PCLATH 				;Move W into PCLATH
				SWAPF 		STATUS_TEMP,W 		;Swap STATUS_TEMP register into W
												;(sets bank to original state)
				MOVWF 	STATUS 				;Move W into STATUS register
				SWAPF 		W_TEMP,F 				;Swap W_TEMP
				SWAPF 		W_TEMP,W 				;Swap W_TEMP into W

				GOTO		INICIO								;regresa de la interrupcion

						
;-----------entra a configurar unidades en el set point ------------------------------------

config_u		INCF		UNI,1			;incrementa el registro UNI, lo almacena en UNI, afecta Z

	  		;----------------------verifica si es mayor a 9 -------------------------------------------------

			BCF		STATUS,2		;pone a cero bit Z
			MOVLW		B'10101'			;carga registro W con 10 decimal
			SUBWF		UNI,0			;(UNI)-(W)->(W), el resultado lo guarda en W, sin alterar UNI
			BTFSS		STATUS,2		;verifica si el bit Z esta a 1, y salta
			GOTO		SIGUE1				
			CALL		UNI_A_CERO
SIGUE1		MOVLW		B'0101'			;carga con 5 el registro W
			MOVWF		SP				;mueve el reg W al registro SP
			CALL		despliega_u		;despliega el reg unidades en el display 7 segmentos

		;---------------verifica si el boton sigue presionado ----------------------------------------------		

LAZO1		BTFSS		PORTB,1		;
			goto		CONTINUA
			goto		LAZO1

;------------------ AQUI TERMINA DE CONFIGURAR UNIDADES ---------------------------------------------------------------------------------
			
;-----------entra a configurar decenas en el set point ------------------------------------

config_d		INCF		DECE,1			;incrementa el registro UNI, lo almacena en UNI, afecta Z

	  		;------------------------------------ verifica si es mayor a 9 -------------------------------------------------

			BCF		STATUS,2	;pone a cero bit Z
			MOVLW		B'10101'		;carga registro W con 10 decimal
			SUBWF		DECE,0		;(UNI)-(W)->(W), el resultado lo guarda en W, sin alterar UNI
			BTFSS		STATUS,2	;verifica si el bit Z esta a 1, y salta
			GOTO		SIGUE2				
			CALL		DECE_A_CERO
SIGUE2		MOVLW		B'0101'		;carga con 5 el registro W
			MOVWF		SP			;mueve el reg W al registro SP
			CALL		despliega_d	;despliega el reg unidades en el display 7 segmentos

			;---------------------------------  verifica si el boton sigue presionado ----------------------------------------------		

LAZO2		BTFSS		PORTB,1		;
			goto		CONTINUA
			goto		LAZO2

;------------------ AQUI TERMINA DE CONFIGURAR DECENAS ---------------------------------------------------------------------------------

;---------------- subrutina que despliega el registro UNI en el display de 7 segmentos --------------------
	
despliega_u	MOVF		UNI,0					; mueve el contenido de UNI al registro W
											; RA4,RA5,RA6,RA7 	UNIDADES
											; RB4,RB5,RB6,RB7	DECENAS
			MOVWF		uni_comodin			; mueve W al registro unidades comodin
			RLF		uni_comodin,1		; rota a la izq. el registo uni_comodin y el resultado ponlo ahi mismo
			RLF		uni_comodin,1
			RLF 		uni_comodin,1
			RLF		uni_comodin,1	

			MOVF		uni_comodin,0		;mueve el contenido de uni_comodin al registro W
			MOVWF		PORTA				;mueve W al puerto A
			RETURN	
;---------------------------------------------------------------------------------------------

;-------------- subrutina que despliega el registro DECE en el display de 7 segmentos --------------------
	
despliega_d	MOVF		DECE,0			; mueve el contenido de DEE al registro W
										; RA4,RA5,RA6,RA7 	UNIDADES
										; RB4,RB5,RB6,RB7	DECENAS
			MOVWF		dece_comodin	; mueve W al registro unidades comodin
			RLF		dece_comodin,1	; rota a la izq. el registo dece_comodin y el resultado ponlo ahi mismo
			RLF		dece_comodin,1
			RLF 		dece_comodin,1
			RLF		dece_comodin,1	

			MOVF		dece_comodin,0	;mueve el contenido de uni_comodin al registro W
			MOVWF		PORTB			;mueve W al puerto B
			RETURN	
;---------------------------------------------------------------------------------------------


;------------ subrutina que limpia el registro UNI -------------------------------------------

UNI_A_CERO		CLRF		UNI		;pone a ceros registro UNI, Z es afectado.
					RETURN			;regresa al flujo del programa		
;---------------------------------------------------------------------------------------------

;------------- subrutina que limpia el registro DECE -----------------------------------------

DECE_A_CERO		CLRF		DECE		;pone a ceros registro UNI, Z es afectado.
					RETURN				;regresa al flujo del programa		
;----------------------------------------------------------------------------------------------

;------------ subrutina para enviar señal SP al display ---------------------------

SENAL_SP	MOVLW		B'0101'		; carga un 5, para mostrarlo como S
			MOVWF		dece_comodin	; mueve W al registro decenas comodin
			RLF		dece_comodin,1	; rota a la izq. el registo dece_comodin y el resultado ponlo ahi mismo
			RLF		dece_comodin,1
			RLF 		dece_comodin,1
			RLF		dece_comodin,1		

			MOVF		dece_comodin,0	;mueve el contenido de dece_comodin al registro W
			MOVWF		PORTB		;mueve W al puerto B

			MOVLW		B'1110'		; carga un 14, para mostrar un E, al reves ja
			MOVWF		uni_comodin	; mueve W al registro decenas comodin
			RLF		uni_comodin,1	; rota a la izq. el registo uni_comodin y el resultado ponlo ahi mismo
			RLF		uni_comodin,1
			RLF 		uni_comodin,1
			RLF		uni_comodin,1		
		
			MOVF		uni_comodin,0	;mueve el contenido de uni_comodin al registro W
			MOVWF		PORTA		;mueve W al puerto A

			RETURN			
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

;-------------------------------------Envia nada al display para hacer que parpadee la configuracion puesta------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

envia_nada_al_display	MOVLW		B'1111'				; carga un 15, para mostrar nada en el display
						MOVWF		dece_comodin		; mueve W al registro decenas comodin
						RLF		dece_comodin,1		; rota a la izq. el registo dece_comodin y el resultado ponlo ahi mismo
						RLF		dece_comodin,1
						RLF 		dece_comodin,1
						RLF		dece_comodin,1		

						MOVF		dece_comodin,0		;mueve el contenido de dece_comodin al registro W
						MOVWF		PORTB				;mueve W al puerto B

						MOVLW		B'1111'				; carga un 15, para mostrar un E
						MOVWF		dece_comodin			; mueve W al registro decenas comodin
						RLF		dece_comodin,1		; rota a la izq. el registo uni_comodin y el resultado ponlo ahi mismo
						RLF		dece_comodin,1
						RLF 		dece_comodin,1
						RLF		dece_comodin,1		
		
						MOVF		dece_comodin,0		;mueve el contenido de uni_comodin al registro W
						MOVWF		PORTA				;mueve W al puerto A

						RETURN			
;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

;--------------- subrutina para convertir de BCD a BINARIO ----------------------------------------

BCD_BINARIO	MOVF		DECE,0				; mueve el contenido de DECE al registro W
				MOVWF		dece_comodin		; mueve W al registro decenas comodin					
				RLF		dece_comodin,1		; rota a la izq. el registo dece_comodin y el resultado ponlo ahi mismo
				RLF		dece_comodin,1		; rota a la izq. el registo dece_comodin y el resultado
				MOVF    		dece_comodin,0  		; mueve dece_comodin al registro W
				ADDWF		DECE,1				; suma W+DECE, el resultado almacenalo en DECE
				RLF		DECE,0				; rota a la izq. el registo, el resultado ponlo en W
				ADDWF		UNI,1				; suma W+UNI, el resultado almacenalo en W
				MOVWF		BINARIO				; mueve W al registro BINARIO
				RETURN						; regresa de la Subrutina
;-------------------------------------------------------------------------------------------

;***************************************************************

retraso_500ms		MOVLW			D'3'
					;MOVWF			z3
					;MOVLW			D'137'
					;MOVWF			z2
					;DECFSZ		z1,f
					;GOTO			$-1
					;DECFSZ		z2,f
					;GOTO			$-3
					;DECFSZ		z3,f
					;GOTO			$-5
					RETURN
	
;***************************************************************
;*************Retraso **************************************************

RETRASO			MOVLW			D'3'
					;MOVWF			z3
					;MOVLW			D'137'
					;MOVWF			z2
					;DECFSZ			z1,f
					;GOTO			$-1
					;DECFSZ			z2,f
					;GOTO			$-3
					;DECFSZ			z3,f
					;GOTO			$-5
					RETURN
	
;###################################################################################################################################
Un_segundo			MOVLW		H'04'			;mueve 4 al registro contador	
					MOVWF		CONTADOR3			;mueve el contenido de W a contador3	
								
					MOVLW		H'FA'			;mueve 255 al registro contador	
					MOVWF		CONTADOR2			;mueve el contenido de W a contador2	
								
					MOVLW		H'A6'			;mueve A6 al registro contador	MOVLW
					MOVWF		CONTADOR1			;mueve el contenido de W a contador1	MOVWF
								
Has_4				DECFSZ	CONTADOR3,1				
					GOTO		Has_250				
					GOTO		Sigue				
								
Has_250								
					DECFSZ	CONTADOR2,1				
					GOTO		Un_ms				
					GOTO		Has_4				
								
Un_ms				CALL		Medio_ms			;retraso ½ ms	(2)
					CALL		Medio_ms			;retraso ½ ms	
					GOTO		Has_250				
								
Sigue				RETURN						; SALE DE LA SUBRUTINA DE 1 SEGUNDO

;############ SUBRUTINA DE MEDIO MILISEGUNDO ##################################################################################################								
Medio_ms								
ETIQUETA			DECFSZ	CONTADOR1,1		;drecrementa CONTADOR en una unidad,almacenalo en el mismo registro	LAZO
					GOTO		ETIQUETA				;y salta si es zero.	
					RETURN						

;###################################################################################################################################	
					END
;###################################################################################################################################
