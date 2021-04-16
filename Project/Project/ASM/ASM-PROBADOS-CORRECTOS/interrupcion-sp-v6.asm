;***************************************************************
			list	p=16F88
			#include	<p16F88.inc>
;***************************************************************
BANCO0   	MACRO				; todos los 16F88 son capaces de direccionar bloque un bloque de 8K continuos de palabra de memoria de programa
			BCF     STATUS,RP0	; las instrucciones CALL and GOTO proveen solo 11 bits de direccion para permitir saltar dentro de alguna pagina de 
			BCF     STATUS,RP1	; de memoria de programa de 2K
			ENDM				; PCL tiene 11 bits para direccionar la memoria de programa, 2^11 = 2048 
BANCO1   	MACRO				; Cuando se hace una instruccion CALL o GOTO, los dos bits mas signifitivos de la direccion son entregados 
			BSF     STATUS,RP0	; por PCLATH<4:3>
			BCF     STATUS,RP1 	; Cuando se hace una instruccion CALL o GOTO, el usuario debe asegurar que los bits seleccionados de la pagina
			ENDM				; son programados, asi la pagina de la memoria de programa deseada es direccionada.
BANCO2   	MACRO				; si un retorno de una instruccion CALL (o interrupcion ) es ejecutada. Los 13 bits del PC son POPPED OFF
			BCF     STATUS,RP0	; de la pila. Por lo tanto, la manipulacion de los bits PCLATH<4:3> no son requeridas por la instruccion RETURN
			BSF     STATUS,RP1 	; (el cual POPS la direccion desde la pila)
			ENDM					
BANCO3   	MACRO				; OJO: el contenido del registro PCLATH se mantiene sin cambios despues de una instruccion RETURN, RETFIE
			BSF     STATUS,RP0	; ejecutada. El usuario debe reescribir el contenido de el registro PCLATH para alguna subsecuente llamada
			BSF     STATUS,RP1 	; de subrutina o instruccion GOTO.
			ENDM
;****************************************************************
				; PC de 13 bits							; PC	LATH	 | 4 | 3 |		PCL	|7|6|5|4|3|2|1|0|	11 bits del PROGRAM COUNTER (PC)							
				; MEMORIA			PAGINA 0			----> 0005 a la 07FF		05     a la 2047
	; 4K x 14		; DE PROGRAMA		PAGINA 1			----> 0800 a la 0FFF		2048 a la 4095				2048 a la ( 2^11 = 2048 ) x 2 = 4096 palabras para programar
				; MEMORIA
	;4K x 14		; DE DATOS					CATALOGADA EN 4 BANCOS	-----> 00 a la 1FF					
	
	;14 es la amplitud del bus de la memoria de programa
;****************************************************************
UNI				equ	24h	; RECORDATORIO DE EN DONDE SE ENCUENGRAN ALGUNOS REGISTROS 
DECE			equ 	25h	;	ADRESH	1Eh		banco 0
SP				equ	26h	;	ADRESL	9Eh		banco 1
uni_comodin		equ	27h	;	ANSEL		9Bh		banco 1
dece_comodin	equ	28h	; 	ADCON0	1Fh		banco 0
STATUS_TEMP	equ 29h	;	ADCON1	9Fh		banco 1
PCLATH_TEMP	equ 2Ah	;****************************************************************
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
RETARDO_PULSO		equ	40h
CONTADOR_D_PULS	equ 41h
RETARDO_PULSO_com 	equ 42h
;###################################################################################################################################
			ORG		0x00
			GOTO		INICIO
			ORG		0x04
			GOTO		SP_INTERRUPT
;###################################################################################################################################
			ORG		0x05
INICIO		CALL		limpia_registros
			CALL		configura_oscilador
			;CALL		configura_TMR0
			;CALL		configura_comparadores	; un comparador independiente
			CALL		configura_puertos
			;CALL		configura_convertidor
			CALL		configura_interrupciones
			;----------  PROGRAMA PRINCIPAL -  -------------------------------------------------------------------------
					BANCO0							; INICIA EN BANCO 0
														;TMR0 = 	[255 - {(4MHz)(8.333ms)}/(4*64)] = 255 - 130 = 124d = 7Ch
					MOVLW		H'7D'					; inicializa el TMR= para  8.333 [ms] --> (1/60)/2
					MOVWF		RETARDO_PULSO		; mueve el valo a registro DURACION_PULSO						
					;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
REVISA_CRUCEx0	BANCO0
					BTFSC		PORTA,7				; monitorea el pulso de cruce por cero
					GOTO		REVISA_CRUCEx0		; monitorea el pulso de cruce por cero
					BCF		PORTA,4
					CALL		t1_ms					; 8.333 [ms]/100 = 83.33 [micro s] > 83 [micros s]
					CALL		t1_ms
					CALL		t1_ms
					CALL		t1_ms
					BSF		PORTA,4				; TERCERO: APARECE EL PULSO 
					CALL		t1_ms					; CUARTO: DURACION DEL PULSO DE  1 ms
					BCF		PORTA,4				; QUINTO: DESAPARECE EL PULSO, Y 
					GOTO		REVISA_CRUCEx0		; SEXTO: ESPERA UN NUEVO CRUCE POR CERO
;REVISA_CRUCEx0	BANCO0
;					BTFSC		PORTA,7				; monitorea el pulso de cruce por cero
;					GOTO		REVISA_CRUCEx0		; monitorea el pulso de cruce por cero
														; PRIMERO: DETECTA EL PULSO
;					BCF		PORTA,4				; apago el pulso por si se mantuvo encendido									
;					BTFSS		CONTADOR1,0
;					GOTO		INC_VELOCIDAD
;					GOTO		DEC_VELOCIDAD
					;_______________________________________________________________________________________					
;INC_VELOCIDAD	CALL		retraso8333msVarINC	; SEGUNDO: ENVIA UN TIEMPO DE RETARDO (SERA VARIABLE), 
;					GOTO		CONTINUA_OP
					;_______________________________________________________________________________________					
;DEC_VELOCIDAD	CALL		retraso8333msVarDEC	; SEGUNDO: ENVIA UN TIEMPO DE RETARDO (SERA VARIABLE), 
;					GOTO		CONTINUA_OP
					;_______________________________________________________________________________________					
;CONTINUA_OP		BSF		PORTA,4				; TERCERO: APARECE EL PULSO 
;					CALL		un_ms					; CUARTO: DURACION DEL PULSO DE  1 ms
;					BCF		PORTA,4				; QUINTO: DESAPARECE EL PULSO, Y 
;					GOTO		REVISA_CRUCEx0		; SEXTO: ESPERA UN NUEVO CRUCE POR CERO
;####################################################################################################################
;{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{  SUBRUTINA DE INTERRUPCION }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
				ORG		0x100
SP_INTERRUPT	MOVWF 	W_TEMP 		;Copy W to TEMP register								;codigo propuesto por hoja de especificaciones
				SWAPF 		STATUS,0 		;Swap status to be saved into W							;codigo propuesto por hoja de especificaciones
				CLRF 		STATUS 		;bank 0, regardless of current bank, Clears IRP,RP1,RP0	;codigo propuesto por hoja de especificaciones
				MOVWF 	STATUS_TEMP 	;Save status to bank zero STATUS_TEMP register			;codigo propuesto por hoja de especificaciones
				;MOVF 		PCL,0 			;Only required if using page 1							;codigo propuesto por hoja de especificaciones
				;MOVWF 	PCLATH_TEMP 	;Save PCLATH into W									;codigo propuesto por hoja de especificaciones
				;CLRF 		PCL 			;Page zero, regardless of current page					;codigo propuesto por hoja de especificaciones
				; ================================================
INICIA_SP		MOVLW		H'09'
				MOVWF		UNI
				MOVWF		DECE
				;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------								
				CALL		desplegar_u_bcd
				CALL		desplegar_d_bcd
				;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------				;----------------------------------------------------------------------------------------------				
OTRA_VEZ		MOVLW		H'FF'						;(1)
				MOVWF		CUENTA_SP1				;(1)
				MOVLW		H'FF'						;(1)
				MOVWF		CUENTA_SP2				;(1)
				MOVLW		H'08'						;(1)	;carga un  decimal
				MOVWF		CUENTA_SP3				;(1)
				;MOVLW		H'01'					;(1)	;carga un  decimal
				;MOVWF		CUENTA_SP4			;(1)
				;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
REVISA_U		BTFSS		PORTB,4				;(1)
				GOTO		REVISA_D				;(2)
				CALL		configura_unidades			
				GOTO		OTRA_VEZ
REVISA_D		BTFSS		PORTA,1				;(1)
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
				;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------				;----------------------------------------------------------------------------------------------				
ACCION_out		BANCO0
				MOVLW		H'06'			; 
				MOVWF		CUENTA_SP1	; 
CIRCULOSP		CALL		desplegar_u_bcd  ;despliega UNI
				CALL		desplegar_d_bcd	; despliega DECE
				CALL		tmedio_s		; RETARDO DE MEDIO SEGUNDO
				MOVLW		H'FF'			; despliega NADA 
				MOVWF		PORTB			; despliega NADA 
				BSF		PORTA,6		; despliega NADA 
				CALL		tmedio_s	; RETARDO DE MEDIO SEGUNDO
				DECFSZ	CUENTA_SP1,1	; 			
				GOTO		CIRCULOSP
				; ========== recuperacion de reg import =============
				;MOVF 		PCLATH_TEMP,0 		;Restore PCLATH						;codigo propuesto por hoja de especificaciones
				;MOVWF 	PCL 					;Move W into PCLATH					;codigo propuesto por hoja de especificaciones
SIGUEPROG		SWAPF 		STATUS_TEMP,0 		;Swap STATUS_TEMP register into W	;codigo propuesto por hoja de especificaciones
													;(sets bank to original state)					;codigo propuesto por hoja de especificaciones
				MOVWF 	STATUS 				;Move W into STATUS register			;codigo propuesto por hoja de especificaciones
				SWAPF 		W_TEMP,1 				;Swap W_TEMP						;codigo propuesto por hoja de especificaciones
				SWAPF 		W_TEMP,0 				;Swap W_TEMP into W				;codigo propuesto por hoja de especificaciones
				;==============================================
				BCF		INTCON,1				;limpia bandera de interrupcion RB0						
				RETFIE								;regresa de la interrupcion
;}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} TERMINA SUBRUTINA DE INTERRUPCION }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

;#############SUBRUTINAS DE RETRASO DE TIEMPO##################################################################################################
						ORG		0x400				; 1024
;##########################################################################################
retraso8333msVarINC	BANCO1
						BCF		OPTION_REG,5		; 0 = Internal instruction cycle clock (CLKO)	|
						BCF		OPTION_REG,3		; 0= pre scaler asignado al TMR0			|	
						;--------------------------------------------------------------------------------------------------------------------------------------------------------------------
						BSF		OPTION_REG,2		; PS<2:0>: Prescaler Rate Select bits		| QUITAR contar estos microsegundos
						BCF		OPTION_REG,1		; 101 		1:64						| en el retardo
						BSF		OPTION_REG,0		; preescalador a 64						|
						;--------------------------------------------------------------------------------------------------------------------------------------------------------------------
						BANCO0
						MOVF		RETARDO_PULSO,0	;TMR0 = 	[255 - {(fxt)(temporizacion deseada)}/(4*divisor de frecuencia)]
						MOVWF		TMR0				; 8.333 [ms] -->	
AGUANTAretraso8i		BTFSS		INTCON,T0IF			; TMR0 = 	[255 - {(4MHz)(8.333ms)}/(4*64)] = 255 - 130 = 124d = 7Ch
						GOTO		AGUANTAretraso8i
						;--------------------------------------------------------------------------------------------------------------------------------------------------------------------
						BCF		STATUS,2
						INCF		RETARDO_PULSO,1	; incrementa registro, y el resultado lo vuelve a poner en el registro. 		
						BTFSS		STATUS,2			; verifica si se puso la bandera Z a 1
						GOTO		salidaRetrasoINC
						;--------------------------------------------------------------------------------------------------------------------------------------------------------------------
						BSF		CONTADOR1,0						
						MOVLW		 H'FF'
						MOVWF		RETARDO_PULSO
						;--------------------------------------------------------------------------------------------------------------------------------------------------------------------						
salidaRetrasoINC			BCF		INTCON,T0IF			; limpiar bandera 
						RETURN						;Cuando se carga un valor en el registro TMR0 (se escribe mediante una
														;instrucción), se produce un retardo de dos ciclos de instrucción durante los
														;cuales se inhibe tanto el prescaler como TMR0. Será necesario tener en cuenta
														;esa inhibición temporal a la hora de realizar una precarga (compensar sumando
														;los ciclos de instrucción que “se pierden”)
;###################################################################################################################################################
retraso8333msVarDEC	BANCO1
						BCF		OPTION_REG,5		; 0 = Internal instruction cycle clock (CLKO)	|
						BCF		OPTION_REG,3		; 0= pre scaler asignado al TMR0			|	
						;--------------------------------------------------------------------------------------------------------------------------------------------------------------------
						BSF		OPTION_REG,2		; PS<2:0>: Prescaler Rate Select bits		| QUITAR contar estos microsegundos
						BCF		OPTION_REG,1		; 101 		1:64							| en el retardo
						BSF		OPTION_REG,0		; 										|
						BANCO0
						;--------------------------------------------------------------------------------------------------------------------------------------------------------------------						
						MOVF		RETARDO_PULSO,0	;TMR0 = 	[255 - {(fxt)(temporizacion deseada)}/(4*divisor de frecuencia)]
						MOVWF		TMR0				; 8.333 [ms] -->	
AGUANTAretraso8d		BTFSS		INTCON,T0IF			; TMR0 = 	[255 - {(4MHz)(8.333ms)}/(4*64)] = 255 - 130 = 124d = 7Ch
						GOTO		AGUANTAretraso8d
						;--------------------------------------------------------------------------------------------------------------------------------------------------------------------
						DECF		RETARDO_PULSO,1	; incrementa registro, y el resultado lo vuelve a poner en el registro. 		
						BCF		STATUS,2
						MOVF		RETARDO_PULSO,0
						MOVWF		RETARDO_PULSO_com
						MOVLW		H'7C'						
						SUBWF		RETARDO_PULSO_com,0				
						BTFSS		STATUS,2			; verifica si se puso la bandera Z a 1
						GOTO		salidaRetrasoDEC
						;--------------------------------------------------------------------------------------------------------------------------------------------------------------------
						BCF		CONTADOR1,0
						MOVLW		 H'7C'
						MOVWF		RETARDO_PULSO						
						;--------------------------------------------------------------------------------------------------------------------------------------------------------------------
salidaRetrasoDEC		BCF		INTCON,T0IF			; limpiar bandera 
						RETURN						;Cuando se carga un valor en el registro TMR0 (se escribe mediante una
														;instrucción), se produce un retardo de dos ciclos de instrucción durante los
														;cuales se inhibe tanto el prescaler como TMR0. Será necesario tener en cuenta
														;esa inhibición temporal a la hora de realizar una precarga (compensar sumando
														;los ciclos de instrucción que “se pierden”)
;###################################################################################################################
tmedio_s		CALL		t50msTMR0
				CALL		t50msTMR0			;100 ms
				CALL		t50msTMR0
				CALL		t50msTMR0			;200 ms
				CALL		t50msTMR0
				CALL		t50msTMR0			; 300 ms
				CALL		t50msTMR0
				CALL		t50msTMR0			; 400 ms 
				CALL		t50msTMR0
				CALL		t50msTMR0			; 500 ms
				RETURN
;#####################################################################################################################################
t50msTMR0				BANCO1
						BCF		OPTION_REG,5		; 0 = Internal instruction cycle clock (CLKO)	|
						BCF		OPTION_REG,3		; 0= pre scaler asignado al TMR0			|	
						;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
						BSF		OPTION_REG,2		; PS<2:0>: Prescaler Rate Select bits		| QUITAR contar estos microsegundos
						BSF		OPTION_REG,1		; 111 		1:256						| en el retardo
						BSF		OPTION_REG,0		; preescalador a 256						|
						;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
						BANCO0
PRECARGA 				MOVLW		 H'3C'			; 50ms -->
						MOVWF		TMR0			;	TMR0 = 	[255 - {(fxt)(temporizacion deseada)}/(4*divisor de frecuencia)]
AGUANTAretraso50ms	BTFSS		INTCON,T0IF
						GOTO		AGUANTAretraso50ms
						BCF		INTCON,T0IF		; limpiar bandera 
						RETURN					;Cuando se carga un valor en el registro TMR0 (se escribe mediante una
													;instrucción), se produce un retardo de dos ciclos de instrucción durante los
													;cuales se inhibe tanto el prescaler como TMR0. Será necesario tener en cuenta
													;esa inhibición temporal a la hora de realizar una precarga (compensar sumando
													;los ciclos de instrucción que “se pierden”)
;#######################################################################################################################
t_20micros
t_adq_20micros			BANCO0					;selecciona banco 0
						MOVLW		H'06'			; (1) ciclo de instruccion
						MOVWF		T_ADQ			; (1)
esp_t_adq				DECFSZ	T_ADQ,1		; (1)		el decremento lo pone en el mismo registro
						GOTO		esp_t_adq		; (2)					
						RETURN					; (2)		20-4=16;	  (3 ciclos)x(6)=18,         en realidad serian como 22 microsegundos
;################################################################################################################
t1_ms					BANCO1					; (2) CALL 
						BCF		OPTION_REG,5	;(1)	; 0 = Internal instruction cycle clock (CLKO)	|
						BCF		OPTION_REG,3	;(1)	; 0= pre scaler asignado al TMR0			|	
						;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
						BSF		OPTION_REG,2	;(1)	; PS<2:0>: Prescaler Rate Select bits		| QUITAR contar estos microsegundos
						BSF		OPTION_REG,1	;(1)	; 111 		1:256						| en el retardo
						BSF		OPTION_REG,0	;(1)	; preescalador a 256						|
						;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------						BANCO0
						BANCO0
PRECARGA_un_ms 		MOVLW		 H'FB'			;(1)	; 50ms -->
						MOVWF		TMR0			;(1)	;	TMR0 = 	[255 - {(fxt)(temporizacion deseada)}/(4*divisor de frecuencia)]
;AGUANTA_un_ms		BTFSS		INTCON,T0IF		;(2) ;		TMR0 = 	[255 - {(4MHz)(1ms)}/(4*256)]= 255 - 3.9 = 255-4 = 251d=FB
;						GOTO		AGUANTA_un_ms		;(2)
						BCF		INTCON,T0IF		;(1)	; limpiar bandera 
						RETURN					;(2)
													;Cuando se carga un valor en el registro TMR0 (se escribe mediante una
													;instrucción), se produce un retardo de dos ciclos de instrucción durante los
													;cuales se inhibe tanto el prescaler como TMR0. Será necesario tener en cuenta
													;esa inhibición temporal a la hora de realizar una precarga (compensar sumando
													;los ciclos de instrucción que “se pierden”)
;###############################################################################################################
t100_micros		BANCO0					;selecciona banco 0
				MOVLW		H'20'			; (1) ciclo de instruccion
				MOVWF		T_ADQ			; (1)
esp_100micros	DECFSZ	T_ADQ,1		; (1)		el decremento lo pone en el mismo registro
				GOTO		esp_100micros	; (2)					
				RETURN					; (2)		100-4=96;	  (3 ciclos)x(32)=96		32d=20h
;###############################################################################################################
t250_micros		BANCO0					;selecciona banco 0
				MOVLW		H'52'			; (1) ciclo de instruccion
				MOVWF		T_ADQ			; (1)
esp_t250_micros	DECFSZ	T_ADQ,1		; (1)		el decremento lo pone en el mismo registro
				GOTO		esp_t250_micros	; (2)					
				RETURN					; (2)		250-4=246;	  (3 ciclos)x(82)=246;	82d=52h
;###############################################################################################################
t600_micros		BANCO0					;selecciona banco 0
				MOVLW		H'C7'			; (1) ciclo de instruccion
				MOVWF		T_ADQ			; (1)
esp_t600_micros	DECFSZ	T_ADQ,1		; (1)		el decremento lo pone en el mismo registro
				GOTO		esp_t600_micros	; (2)					
				RETURN					; (2)		600-4=596;	  (3 ciclos)x()=496;	199d=C7h
;###############################################################################################################
t83_micros		BANCO0					;selecciona banco 0
				MOVLW		H'1A'			; (1) ciclo de instruccion
				MOVWF		T_ADQ			; (1)
esp_83micros	DECFSZ	T_ADQ,1		; (1)		el decremento lo pone en el mismo registro
				GOTO		esp_83micros	; (2)					
				RETURN					; (2)		83-4=79;	  (3 ciclos)x()=26.3333		26d=1Ah
;###############################################################################################################
;######################SUBRUTINAS DE CONFIGURACION DE REGISTROS Y PERIFERICOS ###################################################################################################
						ORG		0x200
;------------ subrutina que configura unidades -------------------------------------------
configura_unidades	BANCO0
					;CALL		REBOTE
					DECFSZ	UNI
					GOTO		SIGUE_U
					GOTO		VUELVE_a9U
VUELVE_a9U		CALL		desplegar_u_bcd
					MOVLW		H'09'
					MOVWF		UNI		
SIGUE_U			CALL		desplegar_u_bcd
AUN_SIGUE_U		BTFSC		PORTA,4
					GOTO		AUN_SIGUE_U
					RETURN
;------------ subrutina que configura decenas --------------------------------------------------
configura_decenas	BANCO0
					;CALL		REBOTE
					DECFSZ	DECE
					GOTO		SIGUE_D
					GOTO		VUELVE_a9D
VUELVE_a9D		CALL		desplegar_d_bcd
					MOVLW		H'09'
					MOVWF		DECE		
SIGUE_D			CALL		desplegar_d_bcd
AUN_SIGUE_D		BTFSC		PORTA,4
					GOTO		AUN_SIGUE_D
					RETURN
;###################################################################################################################
limpia_registros		BANCO0
					CLRF		PORTA							; limpia puerto A
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
;################################################################################################################
configura_oscilador	BANCO1			; selecciona Banco 1; Se encuentran registros TRISA y TRISB
										; al reset STATUS=00000000
										; REGISTRO STATUS = 	IRP 		RP1		RP0		T0_		PD_		Z		DC		C
										;  RP1 RP0
										;  0    	0		banco 0
										;  0    	1		banco 1		RP0=1
										;  1    	0		banco 2
										;  1    	1		banco 3
					BSF	OSCCON,6	;Pone el oscilador a 4 MHz con el oscilador interno RC; OSCCON controla varios aspectos de operacion del sistema de reloj; Banco 1
					BSF	OSCCON,5	;bit 6-4		110		4 MHZ
										;al reset inicia con 0's el registro.
					RETURN
;###################################################################################################################################
;##### CONFIGURA LOS PUERTOS  A y B, (A0,A1,A2,A3 = ENTRADAS)  (A4,A5,A6,A7=SALIDAS),  (B0,B1,B2,B3 = ENTRADAS)  (B4,B5,B6,B7=SALIDAS) ##################
configura_puertos	BANCO1					;;Puerto A como salida		0 - salida; 	1 - entrada
				MOVLW		B'10101100'		; RA7	RA6		RA5		RA4		RA3		RA2		RA1		RA0
				MOVWF		TRISA			;    1		  0	          1		  0		  1 		   1		   1		   1	
				;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------										
				MOVLW		B'00000001'		; RB7	RB6		RB5		RB4		RB3		RB2		RB1		RB0
				MOVWF		TRISB			;    0		  0	          0		  0		  0 		   0		   0		   1		   
				;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------						
				RETURN
;#####################################################################################################################							
;########################################### CONFIGURAR INTERRUPCIONES  #######################################################
configura_interrupciones	BANCO1
		
						BCF 		OPTION_REG,INTEDG				; activa por flanco de bajada, bit INTEDG
						;-----------------------------------------------------  HABILITACION DE INTERRUPCIONES ------------------------------------------------------------------------------------------------------------------
						BSF		INTCON,	INTE     						; que sea interrupcion externa por RB0, bit INTE bit 4
						BSF		INTCON,	GIE      						; habilitamos interrupcion global GIE bit 7
																		; INTCON TAMBIEN ESTA EN BANCO 1
						RETURN
;###########################################################################################################################################;################################ PARA QUE NO SE PIERDA AQUI ESTA EL FINAL DEL PROGRAMA ##############################################################################################################################	
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
					;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
					RLF		DECE_com,1
					RLF		DECE_com,1
					RLF		DECE_com,1
					RLF		DECE_com,1
					;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
					MOVF		DECE_com,0		; mueve el reg DECE_com al registro W
					;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------					
					XORWF		PORTB,0	; xor el registro W con con el puerto B
					MOVWF		PORTB		; mueve el registro W al puerto B
					BTFSS		DECE,0		; salta si hay un '1' en el bit0 del registro DECE
					GOTO		pon_ceroD	; salta a etiqueta SIGUE
					BSF		PORTA,6	; pon un '1' en el pin1 del PUERTO A
					GOTO		terminaD
pon_ceroD			BCF		PORTA,6	; pon un '0' en el pin1 del puerto A					
terminaD			RETURN					
;##########################################################################################################################
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
