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
OTRA_VEZ		MOVLW		H'FF'					;(1)
				MOVWF		CUENTA_SP1			;(1)
				MOVLW		H'FF'					;(1)
				MOVWF		CUENTA_SP2			;(1)
				MOVLW		H'FF'					;(1)	;carga un 22 decimal
				MOVWF		CUENTA_SP3			;(1)
				MOVLW		H'01'				;(1)	;carga un 22 decimal
				MOVWF		CUENTA_SP4		;(1)
				
				
REVISA_U		BTFSS		PORTA,4				;(1)
				GOTO		REVISA_D				;(2)
				CALL		configura_unidades			
				GOTO		OTRA_VEZ
REVISA_D		BTFSS		PORTA,7				;(1)
				GOTO		QUITA_TIEMPO			;(2)
				CALL		configura_decenas
				GOTO		OTRA_VEZ		
QUITA_TIEMPO	DECFSZ	CUENTA_SP1			;(1)
				GOTO		REVISA_U				;(2)
				DECFSZ	CUENTA_SP2			;(1)
				GOTO		REVISA_U				;(2)
				DECFSZ	CUENTA_SP3			;(1)
				GOTO		REVISA_U				;(2)
				DECFSZ	CUENTA_SP4			;(1)
				GOTO		ACCION_out				;(2)
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
;--------------- subrutina para convertir de BCD a BINARIO ----------------------------------------

BCD_BINARIO	BANCO0
				MOVF		DECE,0				; mueve el contenido de DECE al registro W
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
;########################################## SUBRUTINA DE UN SEGUNDO DE TIEMPO ###################################################################################################################
;############################	
BIN2BCD_RS3	BANCO0
        			CLRF     	BCDH
        			CLRF     	BCDL

        			movlw    	0x08
        			movwf    	CUENTA

CONVERSION1
        			bcf     		 STATUS,C
        			rlf      		BIN,f
        			rlf      		BCDL,f
        			decfsz   		CUENTA,f
        			goto     		$+2
        			goto     		FIN_CONV
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
FIN_CONV
				RETURN
				
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
				RETURN
				
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
				RETURN
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

;##################################################################################################################
;##### CONFIGURA LOS PUERTOS  A y B, (A0,A1,A2,A3 = ENTRADAS)  (A4,A5,A6,A7=SALIDAS),  (B0,B1,B2,B3 = ENTRADAS)  (B4,B5,B6,B7=SALIDAS) ##################
configura_puertos				BANCO1
							
							MOVLW		B'10111111'						; RA7	RA6		RA5		RA4		RA3		RA2		RA1		RA0
							MOVWF		TRISA							;    1		  0	          1		  1		  1 		   1		   1		   1	
																		;Puerto A como salida		0 - salida; 	1 - entrada
							MOVLW		B'00000001'						; RB7	RB6		RB5		RB4		RB3		RB2		RB1		RB0
							MOVWF		TRISB							;    0		  0	          0		  0		  0 		   0		   0		   0		   
						
							RETURN
;#####################################################################################################################							
;##############################################################
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
retraso_50msTMR0		BANCO0
						
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
REBOTE	MOVLW		H'FF'	 		 ;Carga el acumulador con 0FFh
			MOVWF		REG_REBOTE1	 ;Mueve el contenido del acumulador a RETARDO
			MOVLW		H'01'
			MOVWF		REG_REBOTE2
REBO1		DECFSZ	REG_REBOTE1,1 		;\
			GOTO		REBO1      		; No retorna hasta que RETARDO llega a cero
			DECFSZ	REG_REBOTE2,1
			GOTO		REBOTE
			RETURN            						;/
;##################################################################
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
;################################ PARA QUE NO SE PIERDA AQUI ESTA EL FINAL DEL PROGRAMA ##############################################################################################################################	
						END
;###################################################################################################################################
