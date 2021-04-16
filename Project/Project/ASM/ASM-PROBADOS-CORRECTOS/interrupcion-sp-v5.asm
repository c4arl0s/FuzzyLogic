;***************************************************************
				list	p=16F88
				#include	<p16F88.inc>
;***************************************************************
BANCO0   	MACRO
			BCF     STATUS,RP0	
			BCF     STATUS,RP1
			ENDM
BANCO1   	MACRO
			BSF     STATUS,RP0	
			BCF     STATUS,RP1 
			ENDM
BANCO2   	MACRO
			BCF     STATUS,RP0	
			BSF     STATUS,RP1 
			ENDM
BANCO3   	MACRO
			BSF     STATUS,RP0	
			BSF     STATUS,RP1 
			ENDM
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
T_ADQ			equ 36h
;*************************************************
SEIS_CERO		equ	37h
NUEVE_NUEVE	equ  38h

;***************************************************************
DECE_com		equ 	39h
CUENTA_SP1	equ 3Ah
CUENTA_SP2	equ 3Bh
CUENTA_SP3	equ 3Ch
CUENTA_SP4	equ 3Dh
REG_REBOTE1	equ 3Eh
REG_REBOTE2	equ	3Fh
DURACION_PULSO		equ	40
CONTADOR_D_PULS	equ 41
;____________________________________________

; RECORDATORIO DE EN DONDE SE ENCUENGRAN ALGUNOS REGISTROS 
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
INICIO		CALL		limpia_registros
			CALL		configura_oscilador
			CALL		configura_TMR0
			;CALL		configura_comparadores	; un comparador independiente
			CALL		configura_puertos
			;CALL		configura_convertidor
			CALL		configura_interrupciones
			;----------  PROGRAMA PRINCIPAL -  -------------------------------------------------------------------------
					BANCO0
					MOVLW		 H'7C'				; inicializa el TMR= para  8.333 [ms] --> (1/60)/2
					MOVWF		DURACION_PULSO	; mueve el valo a registro DURACION_PULSO						
					
					MOVLW		H'FF'					; (1)
					MOVWF		CONTADOR1			; (1 )	mueve 255 a registro CONTADOR1
					MOVF		DURACION_PULSO,0		; (1) mueve 	DURACION_PULSO a W	
					SUBWF		CONTADOR1,1			; (1) resta (CONTADOR1 - DURACION_PULSO) -->  CONTADOR1 ejemplo (255-124=131), 
					MOVLW		H'01'					; le suma un uno
					ADDWF		CONTADOR1,1			; SE HACE EL CALCULO DEL NUMERO DE CUENTAS HASTA FF de TMR0	
														; Y SE ALMACENA EN CONTADOR1, PARA HACERLO EXACTO
					MOVF		CONTADOR1,0
					MOVWF		CONTADOR3			; CONSTANTE 					

					BANCO0
REVISA_PULSO		BTFSC		PORTA,4				; monitorea el pulso de cruce por cero
					GOTO		REVISA_PULSO			; monitorea el pulso de cruce por cero
					BSF		PORTA,7				; envia pulso al puerto PA0
					CALL		RETARDO_VARIABLE	; 
					GOTO		REVISA_PULSO
			;------------------------------------------------------------------------------------------------------------------------------------
CIRC		BANCO0
			MOVLW		H'09'
			MOVWF		UNI
CIRCULO	CALL		desplegar_u_bcd
			CALL		medio_segundo
			MOVLW		H'FF'
			MOVWF		PORTB
			BSF		PORTA,6		
			CALL		medio_segundo
			DECFSZ	UNI,1			
			GOTO		CIRCULO
			GOTO		CIRC
			;--------------------------------------------------------------------------------------------------------------------------------------------
;####################################################################################################################
;{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{  SUBRUTINA DE INTERRUPCION }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
SP_INTERRUPT	;MOVWF 	W_TEMP 		;Copy W to TEMP register								;codigo propuesto por hoja de especificaciones
				;SWAPF 		STATUS,0 		;Swap status to be saved into W							;codigo propuesto por hoja de especificaciones
				;CLRF 		STATUS 		;bank 0, regardless of current bank, Clears IRP,RP1,RP0	;codigo propuesto por hoja de especificaciones
				;MOVWF 	STATUS_TEMP 	;Save status to bank zero STATUS_TEMP register			;codigo propuesto por hoja de especificaciones
				;MOVF 		PCL,0 		;Only required if using page 1							;codigo propuesto por hoja de especificaciones
				;MOVWF 	PCLATH_TEMP 	;Save PCLATH into W									;codigo propuesto por hoja de especificaciones
				;CLRF 		PCL 			;Page zero, regardless of current page					;codigo propuesto por hoja de especificaciones
				; ================================================
INICIA_SP		MOVLW		H'09'
				MOVWF		UNI
				MOVWF		DECE
				
				CALL		desplegar_u_bcd
				CALL		desplegar_d_bcd
				;----------------------------------------------------------------------------------------------				
OTRA_VEZ		MOVLW		H'FF'						;(1)
				MOVWF		CUENTA_SP1				;(1)
				MOVLW		H'FF'						;(1)
				MOVWF		CUENTA_SP2				;(1)
				MOVLW		H'09'						;(1)	;carga un  decimal
				MOVWF		CUENTA_SP3				;(1)
				;MOVLW		H'01'					;(1)	;carga un  decimal
				;MOVWF		CUENTA_SP4			;(1)
				
				
REVISA_U		BTFSS		PORTA,1				;(1)
				GOTO		REVISA_D				;(2)
				CALL		configura_unidades			
				GOTO		OTRA_VEZ
REVISA_D		BTFSS		PORTA,5				;(1)
				GOTO		QUITA_TIEMPO			;(2)
				CALL		configura_decenas
				GOTO		OTRA_VEZ		
QUITA_TIEMPO	DECFSZ	CUENTA_SP1,1			;(1)
				GOTO		REVISA_U				;(2)

				DECFSZ	CUENTA_SP2,1			;(1)
				GOTO		REVISA_U				;(2)

				DECFSZ	CUENTA_SP3,1			;(1)
				GOTO		ACCION_out				;(2)

				;DECFSZ	CUENTA_SP4,1			;(1)
				;GOTO		ACCION_out				;(2)
				;----------------------------------------------------------------------------------------------				

ACCION_out		
				BANCO0
				
				MOVLW		H'03'
				MOVWF		CUENTA_SP1
CIRCULOSP		CALL		desplegar_u_bcd
				CALL		desplegar_d_bcd
				CALL		medio_segundo
				MOVLW		H'FF'
				MOVWF		PORTB
				BSF		PORTA,6		
				CALL		medio_segundo
				DECFSZ	CUENTA_SP1,1			
				GOTO		CIRCULOSP
				
				
				;-------------------------------------------------------------------
SIGUEPROG		
				
				; ========== recuperacion de reg import =============
				;MOVF 		PCLATH_TEMP,0 		;Restore PCLATH						;codigo propuesto por hoja de especificaciones
				;MOVWF 	PCL 					;Move W into PCLATH					;codigo propuesto por hoja de especificaciones
				;SWAPF 		STATUS_TEMP,0 		;Swap STATUS_TEMP register into W	;codigo propuesto por hoja de especificaciones
													;(sets bank to original state)					;codigo propuesto por hoja de especificaciones
				;MOVWF 	STATUS 				;Move W into STATUS register			;codigo propuesto por hoja de especificaciones
				;SWAPF 		W_TEMP,1 				;Swap W_TEMP						;codigo propuesto por hoja de especificaciones
				;SWAPF 		W_TEMP,0 				;Swap W_TEMP into W				;codigo propuesto por hoja de especificaciones
				;==============================================
				BCF		INTCON,1				;limpia bandera de interrupcion RB0						
				RETFIE								;regresa de la interrupcion
;}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} TERMINA SUBRUTINA DE INTERRUPCION }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
;------------ subrutina que configura unidades -------------------------------------------
configura_unidades		;CALL		REBOTE
						DECFSZ	UNI
						GOTO		SIGUE_U
						GOTO		VUELVE_a9U
VUELVE_a9U			CALL		desplegar_u_bcd
						MOVLW		H'09'
						MOVWF		UNI		
SIGUE_U				CALL		desplegar_u_bcd
AUN_SIGUE_U			BTFSC		PORTA,4
						GOTO		AUN_SIGUE_U
						RETURN
;------------ subrutina que configura decenas --------------------------------------------------
configura_decenas		;CALL		REBOTE
						DECFSZ	DECE
						GOTO		SIGUE_D
						GOTO		VUELVE_a9D
VUELVE_a9D			CALL		desplegar_d_bcd
						MOVLW		H'09'
						MOVWF		DECE		
SIGUE_D				CALL		desplegar_d_bcd
AUN_SIGUE_D			BTFSC		PORTA,4
						GOTO		AUN_SIGUE_D
						RETURN
;------------------------------------------------------------------------------------------------------------------
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
;###################################################################
desplegar_u_bcd		BANCO0
					MOVF		UNI,0		; mueve el reg UNI al registro W
					MOVWF		PORTB		; mueve el registro W al PORTB
					BTFSS		UNI,0		; salta si hay un '1' en el bit0 del registro UNI
					GOTO		pon_ceroU	; salta a etiqueta SIGUE
					BSF		PORTA,6	; pon un '1' en el pin1 del PUERTO A
					GOTO		terminaU
pon_ceroU			BCF		PORTA,6	; pon un '0' en el pin1 del puerto A					
terminaU				RETURN					
;###################################################################
desplegar_d_bcd		BANCO0
					MOVF		DECE,0				; mueve el reg DECE_com al registro W
					MOVWF		DECE_com

					RLF		DECE_com,1
					RLF		DECE_com,1
					RLF		DECE_com,1
					RLF		DECE_com,1

					MOVF		DECE_com,0		; mueve el reg DECE_com al registro W
					
					XORWF		PORTB,0	; xor el registro W con con el puerto B
					MOVWF		PORTB		; mueve el registro W al puerto B
					BTFSS		DECE,0		; salta si hay un '1' en el bit0 del registro DECE
					GOTO		pon_ceroD	; salta a etiqueta SIGUE
					BSF		PORTA,6	; pon un '1' en el pin1 del PUERTO A
					GOTO		terminaD
pon_ceroD			BCF		PORTA,6	; pon un '0' en el pin1 del puerto A					
terminaD			RETURN					
;####################################################################
limpia_registros				CLRF		PORTA							; limpia puerto A
							CLRF		PORTB							; limpia puerto B
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
							
							CLRF		SEIS_CERO		
							CLRF		NUEVE_NUEVE
							RETURN
;##########################################################################################################################
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
configura_oscilador			BANCO1					; selecciona Banco 1; Se encuentran registros TRISA y TRISB
														; al reset STATUS=00000000
														; REGISTRO STATUS = 	IRP 		RP1		RP0		T0_		PD_		Z		DC		C
														;  RP1 RP0
														;  0    	0		banco 0
														;  0    	1		banco 1		RP0=1
														;  1    	0		banco 2
														;  1    	1		banco 3
							BSF		OSCCON,6		;Pone el oscilador a 4 MHz con el oscilador interno RC; OSCCON controla varios aspectos de operacion del sistema de reloj; Banco 1
							BSF		OSCCON,5		;bit 6-4		110		4 MHZ
														;al reset inicia con 0's el registro.
							RETURN
;###################################################################################################################################
;##### CONFIGURA LOS PUERTOS  A y B, (A0,A1,A2,A3 = ENTRADAS)  (A4,A5,A6,A7=SALIDAS),  (B0,B1,B2,B3 = ENTRADAS)  (B4,B5,B6,B7=SALIDAS) ##################
configura_puertos				BANCO1
							
							MOVLW		B'10101110'			; RA7	RA6		RA5		RA4		RA3		RA2		RA1		RA0
							MOVWF		TRISA				;    1		  0	          1		  0		  1 		   1		   1		   1	
															;Puerto A como salida		0 - salida; 	1 - entrada
							MOVLW		B'00000001'			; RB7	RB6		RB5		RB4		RB3		RB2		RB1		RB0
							MOVWF		TRISB				;    0		  0	          0		  0		  0 		   0		   0		   1		   
						
							RETURN
;#####################################################################################################################							
;########################################### CONFIGURAR INTERRUPCIONES  #######################################################
configura_interrupciones	BANCO1
		
						BCF 		OPTION_REG,INTEDG				; activa por flanco de bajada, bit INTEDG
						;-----------------------------------------------------  HABILITACION DE INTERRUPCIONES ------------------------------------------------------------------------------------------------------------------
						BSF		INTCON,	INTE     						; que sea interrupcion externa por RB0, bit INTE bit 4
						BSF		INTCON,	GIE      						; habilitamos interrupcion global GIE bit 7
							
						RETURN
;###########################################################################################################################################
configura_TMR0			BANCO1

						BCF		OPTION_REG,5					; 0 = Internal instruction cycle clock (CLKO)
						BCF		OPTION_REG,3					; 0= pre scaler asignado al TMR0
						BSF		OPTION_REG,2					; PS<2:0>: Prescaler Rate Select bits
						BSF		OPTION_REG,1					; 111 		1:256
						BSF		OPTION_REG,0					; preescalador a 256
						
						BCF		INTCON,2						; limpiar bandera 
						RETURN
;#####################################################################################################################
retraso_50msTMR0		BANCO1
						BCF		OPTION_REG,5		; 0 = Internal instruction cycle clock (CLKO)	|
						BCF		OPTION_REG,3		; 0= pre scaler asignado al TMR0			|	
						BSF		OPTION_REG,2		; PS<2:0>: Prescaler Rate Select bits		| QUITAR contar estos microsegundos
						BSF		OPTION_REG,1		; 111 		1:256						| en el retardo
						BSF		OPTION_REG,0		; preescalador a 256						|
						BANCO0
PRECARGA 				MOVLW		 H'3C'			; 50ms -->
						MOVWF		TMR0	
AGUANTA				BTFSS		INTCON,T0IF
						GOTO		AGUANTA
						BCF		INTCON,T0IF		; limpiar bandera 
						RETURN
													;Cuando se carga un valor en el registro TMR0 (se escribe mediante una
													;instrucción), se produce un retardo de dos ciclos de instrucción durante los
													;cuales se inhibe tanto el prescaler como TMR0. Será necesario tener en cuenta
													;esa inhibición temporal a la hora de realizar una precarga (compensar sumando
													;los ciclos de instrucción que “se pierden”)
;#######################################################################################################################
t_adq_20micros			BANCO0					;selecciona banco 0
						MOVLW		H'06'			; (1) ciclo de instruccion
						MOVWF		T_ADQ			; (1)
esp_t_adq				DECFSZ	T_ADQ,1		; (1)		el decremento lo pone en el mismo registro
						GOTO		esp_t_adq		; (2)					
						RETURN					; (2)		20-4=16;	  (3 ciclos)x(6)=18,         en realidad serian como 22 microsegundos
;##########################################################################################
medio_segundo	CALL		retraso_50msTMR0
				CALL		retraso_50msTMR0
				CALL		retraso_50msTMR0
				CALL		retraso_50msTMR0
				CALL		retraso_50msTMR0
				CALL		retraso_50msTMR0
				CALL		retraso_50msTMR0
				CALL		retraso_50msTMR0
				CALL		retraso_50msTMR0
				CALL		retraso_50msTMR0
				RETURN
;##########################################################################################
RETARDO_VARIABLE	; esta subrutina no debe ser mayor a 64 [micro segundos]

				BANCO1						; configura el TMR0
				BCF		OPTION_REG,5		; (1)	0 = Internal instruction cycle clock (CLKO)
				BCF		OPTION_REG,3		; (1)	0= pre scaler asignado al TMR0
				BSF		OPTION_REG,2		; (1)	PS<2:0>: Prescaler Rate Select bits
				BCF		OPTION_REG,1		; (1)	101 		1:64
				BSF		OPTION_REG,0		; (1) preescalador a 64
				BCF		INTCON,2			; (1) limpiar bandera 

				BANCO0
PRECARGA_RV 	MOVF		DURACION_PULSO,0		; mueve el registro DURACION al registro W
				MOVWF		TMR0					; (1) mueve el registro W al registro TMR0

AGUANTA_RV	BTFSS		INTCON,T0IF				; (1) espera  la bandera 
				GOTO		AGUANTA_RV			; (2)	
				
				BTFSS		CONTADOR2,0			; revisa si va a incrementar la velocidad o la va a disminuir.
				GOTO		INC_VELOC
				GOTO		DEC_VELOC
				
INC_VELOC		INCF		DURACION_PULSO		; (1)	 incrementa de 124+1,
				DECFSZ	CONTADOR1,1
				GOTO		SALIDA
				
				MOVF		CONTADOR3,0			; mueve el registro CONTADOR4, al registro W
				MOVWF		CONTADOR1
				BSF		CONTADOR2,0
				GOTO		SALIDA

DEC_VELOC	DECF		DURACION_PULSO
				DECFSZ	CONTADOR1,1
				GOTO		SALIDA
				
				MOVF		CONTADOR3,0			; mueve el registro CONTADOR4, al registro W
				MOVWF		CONTADOR1
				BCF		CONTADOR2,0
				GOTO		SALIDA
								
SALIDA			BCF		INTCON,T0IF				; (1) limpiar bandera 
				RETURN							; (2)
													;Cuando se carga un valor en el registro TMR0 (se escribe mediante una
													;instrucción), se produce un retardo de dos ciclos de instrucción durante los
				;									;cuales se inhibe tanto el prescaler como TMR0. Será necesario tener en cuenta
													;esa inhibición temporal a la hora de realizar una precarga (compensar sumando
													;los ciclos de instrucción que “se pierden”)

;################################ PARA QUE NO SE PIERDA AQUI ESTA EL FINAL DEL PROGRAMA ##############################################################################################################################	
						END
;###################################################################################################################################
;Design Tips
;Question 1: Program execution seems to get lost.
;Answer 1:
;When a device with more then 2K words of program memory is used, the calling of subroutines
;may require that the PCLATH register be loaded prior to the CALL (or GOTO) instruction to specify
;the correct program memory page that the routine is located on. The following instructions will
;correctly load PCLATH register, regardless of the program memory location of the label SUB_1.
;MOVLW HIGH (SUB_1) ; Select Program Memory Page of
;MOVWF PCLATH ; Routine.
;:CALL SUB_1 ; Call the desired routine
;:
;:
;SUB_1 : ; Start of routine
;:
;RETURN ;
