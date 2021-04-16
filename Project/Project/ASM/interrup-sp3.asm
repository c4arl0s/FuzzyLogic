;****************************************************************
				; PC de 13 bits							; PC	LATH	 | 4 | 3 |		PCL	|7|6|5|4|3|2|1|0|	11 bits del PROGRAM COUNTER (PC)							
				; MEMORIA			PAGINA 0			----> 0005 a la 07FF		05     a la 2047
	; 4K x 14		; DE PROGRAMA		PAGINA 1			----> 0800 a la 0FFF		2048 a la 4095				2048 a la ( 2^11 = 2048 ) x 2 = 4096 palabras para programar
				; MEMORIA
	;4K x 14		; DE DATOS					CATALOGADA EN 4 BANCOS	-----> 00 a la 1FF					
	;14 es la amplitud del bus de la memoria de programa
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
;****************************************************************************************************************************************************************
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

BIN				equ 34h
BIN_comodin		equ 35h
T_ADQ			equ 36h
;*************************************************
SEIS_CERO		equ	37h
NUEVE_NUEVE	equ  38h
;***************************************************************
DECE_com		equ 	39h
;CUENTASP1	equ 3Ah
;CUENTASP2	equ 3Bh
;CUENTASP3	equ 3Ch
;CUENTASP4	equ 3Dh
REG_REBOTE1	equ 3Eh
REG_REBOTE2	equ	3Fh
RETARDO_PULSO		equ	40h
RETARDO_PULSO_com 	equ 42h
VECES_MISMO_RET		equ 43h
CUENTA				equ 44h
CUENTA100				equ 33h
CONTADOR_D_PULS	equ 41h
COM					equ 42h   
CUENTA100_com		equ 43h
;***************************************************************
CUENTASP1	equ 45h
CUENTASP2	equ 46h
CUENTASP3	equ 47h
CUENTASP4	equ 48h
PORTA_com		equ	49h
PORTB_com		equ	4Ah
UNI_com		equ 	4Bh
;------------------------------------
BINARIO_SP		equ	4Ch
DATO_VELOC	equ 	4Dh
CICLOS60		equ 4Eh
MODO_OPERACION	equ 4Fh
VECES120		equ	50
;###################################################################################################################################
			ORG		0x00					;############################################################################;############################################################################
			GOTO		INICIO					;############################################################################;############################################################################
			ORG		0x04					;############################################################################;############################################################################
			GOTO		SP_INTERRUPT			;############################################################################;############################################################################
;###################################################################################################################################
			ORG		0x05					;############################################################################;############################################################################
INICIO		CALL		limpia_registros			;############################################################################;############################################################################
			CALL		configura_oscilador		;############################################################################
			;CALL		configura_TMR0			;############################################################################
			;CALL		configura_comparadores	;############################################################################
			CALL		configura_puertos			;############################################################################
			;CALL		configura_convertidor		;############################################################################
			CALL		configura_interrupciones	;############################################################################
;===================================================================================================================					
					;=========  PROGRAMA PRINCIPAL -  ==================================================================
INICIO1				;
LEE_MODO			BTFSS		MODO_OPERACION,0			; LEE MODO DE OPERACION
					GOTO		ACCIONA_CONTROL						
					GOTO		LEE_TEMP
LEE_TEMP			CALL		LEER_TEMP_AMB				; MODO EN REPOSO (DESPLIEGA TEMP ACTUAL)
					CALL		DESPLEGAR_TEMP_AMB		; MODO EN REPOSO (DESPLIEGA TEMP ACTUAL)
					GOTO		LEE_MODO						;  MODO EN REPOSO (DESPLIEGA TEMP ACTUAL)
;==================================================================================================================				
ACCIONA_CONTROL	CALL		LEE_TEMP_ACTUAL			; MODO ACCION DE CONTROL (CONTROLA LA TEMP)
					CALL		DESPLEGAR_TEMP_ACTUAL; DESPLIEGA LA TEMPERATURA ACTUAL 
					,================================================================================================
					CALL		ERROR_DE_TEMP1			; CALCULA EL ERROR DE LA TEMP (TEMP_DESEADA-TEMP_ACTUAL)
					
					;----------------------------------------------------------------|	LOS DOS DATOS ANTERIORES ENTRAN EN LA MAQUINA DE INFERENCIA
					CALL		MAQUINA_DE_INFERENCIA	;|	REALIZANDO EL PROCESO DE INFERIR LA SALIDA DESEADA
					;----------------------------------------------------------------|	
					;=================================================================================================
					MOVF		ALFA,0						;mueve al registro W el valor de ALFA (RETARDO)
					MOVWF		ALFA_A_ENVIAR			;carga w al registro ALFA_A_ENVIAR
					;=====================================================================================================							
					MOVLW		H'120'						; si lo hace 120 veces, entonces ha transcurrido 1 [s] ---> 83.33 [micro s] x 120 = 1 [s]
					MOVWF		VECES120					; y sensa cada 1 [s]
					;=====================================================================================================																
DETECTA_CRUCE	BTFSC		BTFSC,7					; DETECTA EL CRUCE POR CERO
					GOTO		DETECTA_CRUCE			; DETECTA EL CRUCE POR CERO
					;==================================================================================================					
					CALL		ENVIA_ALFA				; ENVIA EL RETRASO DEL PULSO PARA ACCIONAR EL SCR Y POR LO TANTO LA POTENCIA
					;==================================================================================================
					DECFSZ	VECES120
					GOTO		DETECTA_CRUCE
					;==================================================================================================
					CALL		CALC_dT_dt					; CALCULA LA RAPIDEZ DE VARIACION DE LA TEMPERATURA
					GOTO		ACCIONA_CONTROL			;SE SALE DEL CICLO DESPUES DE UN SEGUNDO 

;{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{  SUBRUTINA DE INTERRUPCION }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
				ORG		0x100
;#########################################################################################################################
SP_INTERRUPT	MOVWF 	W_TEMP 		;Copy W to TEMP register								;codigo propuesto por hoja de especificaciones
				SWAPF 		STATUS,0 		;Swap status to be saved into W							;codigo propuesto por hoja de especificaciones
				CLRF 		STATUS 		;bank 0, regardless of current bank, Clears IRP,RP1,RP0	;codigo propuesto por hoja de especificaciones
				MOVWF 	STATUS_TEMP 	;Save status to bank zero STATUS_TEMP register			;codigo propuesto por hoja de especificaciones
				;MOVF 		PCL,0 			;Only required if using page 1							;codigo propuesto por hoja de especificaciones
				;MOVWF 	PCLATH_TEMP 	;Save PCLATH into W									;codigo propuesto por hoja de especificaciones
				;CLRF 		PCL 			;Page zero, regardless of current page					;codigo propuesto por hoja de especificaciones
				; ================================================
INICIA_SP		CLRF		PORTB_com		;INICIALIZA REGISTROS IMPORTANTES
				BCF		PORTA,6		;INICIALIZA REGISTROS IMPORTANTES
				BCF		PORTA_com,6	;INICIALIZA REGISTROS IMPORTANTES
				MOVLW		H'09'			;INICIALIZA REGISTROS IMPORTANTES
				MOVWF		UNI				;INICIALIZA REGISTROS IMPORTANTES
				MOVWF		DECE			;INICIALIZA REGISTROJS IMPORTANTES
				;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------								
				CALL		desplegar_u_bcd	;DESPLIEGA VALOR INICIAL EN EL DISPLAY	
				CALL		desplegar_d_bcd	;DESPLIEGA VALOR INICIAL EN EL DISPLAY
				;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				;GOTO		HASTAELFINAL
				;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------				;----------------------------------------------------------------------------------------------				
OTRA_VEZ		MOVLW		H'FF'						;(1)
				MOVWF		CUENTASP1				;(1)
				MOVLW		H'FF'						;(1)
				MOVWF		CUENTASP2				;(1)
				MOVLW		H'09'						;(1)	carga un  decimal
				MOVWF		CUENTASP3				;(1)  255x255x(9 ciclos de instruccion)x9x1 micro sec = 5.26 [s]
				;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				;GOTO 		HASTAELFINAL
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
REVISA_U		BTFSS		PORTA,0				;(1)			; REVISA SI PRESIONASTE U
				GOTO		REVISA_D				;(2)			; REVISA SI PRESIONASTE U	
				;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				CALL		t250_ms					; REBOTE
				CALL		configura_unidades			
				GOTO		OTRA_VEZ
				;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
REVISA_D		BTFSS		PORTA,5				;(1)			;REVISA SI PRESIONASTE D	
				GOTO		QUITA_TIEMPO			;(2)			;REVISA SI PRESIONASTE D
				;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				CALL		t250_ms					; REBOTE
				CALL		configura_decenas
				GOTO		OTRA_VEZ
				;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
QUITA_TIEMPO	DECFSZ	CUENTASP1,1			;(1)
				GOTO		REVISA_U				;(2)
;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				DECFSZ	CUENTASP2,1			;(1)
				GOTO		REVISA_U				;(2)
				DECFSZ	CUENTASP3,1			;(1)
				GOTO		REVISA_U				;(2)
				;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------				;----------------------------------------------------------------------------------------------				
ACCION_out		BANCO0
				MOVLW		H'05'			; PARA DESPLEGAR 6 VECES EL NUMERO ESTABLECIDO 
				MOVWF		CUENTASP1	; PARA DESPLEGAR 6 VECES EL NUMERO ESTABLECIDO 
				;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ 
CIRCULO_SP	CALL		desplegar_u_bcd  ;despliega UNI
				CALL		desplegar_d_bcd	; despliega DECE
				CALL		tmedio_s		; RETARDO DE MEDIO SEGUNDO
				MOVLW		H'FF'			; despliega NADA 
				MOVWF		PORTB			; despliega NADA 
				BSF		PORTA,6		; despliega NADA 
				CALL		tmedio_s		; RETARDO DE MEDIO SEGUNDO
				DECFSZ	CUENTASP1,1	; 			
				GOTO		CIRCULO_SP	
				;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
HASTAELFINAL	CALL		BCD_BINARIO		; llama a la subrutina de conversion de BCD A BINARIO
				;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				; ========== RECUPERACION DE REGISTROS IMPORTANTES =====================================================
				;MOVF 		PCLATH_TEMP,0 		;Restore PCLATH						;codigo propuesto por hoja de especificaciones
				;MOVWF 	PCL 					;Move W into PCLATH					;codigo propuesto por hoja de especificaciones
SIGUEPROG		SWAPF 		STATUS_TEMP,0 		;Swap STATUS_TEMP register into W	;codigo propuesto por hoja de especificaciones
													;(sets bank to original state)					;codigo propuesto por hoja de especificaciones
				MOVWF 	STATUS 				;Move W into STATUS register			;codigo propuesto por hoja de especificaciones
				SWAPF 		W_TEMP,1 				;Swap W_TEMP						;codigo propuesto por hoja de especificaciones
				SWAPF 		W_TEMP,0 				;Swap W_TEMP into W				;codigo propuesto por hoja de especificaciones
				;==========================================================================================================
				BANCO0
				BCF		INTCON,1				;limpia bandera de interrupcion RB0						
				RETFIE								;regresa de la interrupcion
;}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} TERMINA SUBRUTINA DE INTERRUPCION }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

;#############SUBRUTINAS DE RETRASO DE TIEMPO##################################################################################################
						ORG		0x400				; 1024 decimal
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
;########################################################################################################################
t250_ms			CALL		t50msTMR0
				CALL		t50msTMR0			;100 ms
				CALL		t50msTMR0
				CALL		t50msTMR0			;200 ms
				CALL		t50msTMR0			;250 ms
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
PRECARGA_un_ms 		MOVLW		 H'FB'			;(1)	; 
						MOVWF		TMR0			;(1)	;	TMR0 = 	[255 - {(fxt)(temporizacion deseada)}/(4*divisor de frecuencia)]
AGUANTA_un_ms		BTFSS		INTCON,T0IF		;(2) ;		TMR0 = 	[255 - {(4MHz)(1ms)}/(4*256)]= 255 - 3.9 = 255-4 = 251d=FB
						GOTO		AGUANTA_un_ms		;(2)
						BCF		INTCON,T0IF		;(1)	; limpiar bandera 
						RETURN					;(2)
													;Cuando se carga un valor en el registro TMR0 (se escribe mediante una
													;instrucción), se produce un retardo de dos ciclos de instrucción durante los
													;cuales se inhibe tanto el prescaler como TMR0. Será necesario tener en cuenta
													;esa inhibición temporal a la hora de realizar una precarga (compensar sumando
													;los ciclos de instrucción que “se pierden”)
;###############################################################################################################
t4_ms					BANCO1					; (2) CALL 
						BCF		OPTION_REG,5	;(1)	; 0 = Internal instruction cycle clock (CLKO)	|
						BCF		OPTION_REG,3	;(1)	; 0= pre scaler asignado al TMR0			|	
						;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
						BSF		OPTION_REG,2	;(1)	; PS<2:0>: Prescaler Rate Select bits		| QUITAR contar estos microsegundos
						BSF		OPTION_REG,1	;(1)	; 111 		1:256						| en el retardo
						BSF		OPTION_REG,0	;(1)	; preescalador a 256						|
						;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------						BANCO0
						BANCO0
PRECARGA_4_ms 		MOVLW		 H'EF'			;(1)	; 
						MOVWF		TMR0			;(1)	;	TMR0 = 	[255 - {(fxt)(temporizacion deseada)}/(4*divisor de frecuencia)]
AGUANTA_4_ms			BTFSS		INTCON,T0IF		;(2) ;		TMR0 = 	[255 - {(4MHz)(4ms)}/(4*256)]= 255 - 15.625 = 255-16 = 239d=EFh
						GOTO		AGUANTA_4_ms		;(2)
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
t600_micros		BANCO0					;  selecciona banco 0
				MOVLW		H'C7'			; (1) ciclo de instruccion
				MOVWF		T_ADQ			; (1)
esp_t600_micros	DECFSZ	T_ADQ,1		; (1)		el decremento lo pone en el mismo registro
				GOTO		esp_t600_micros	; (2)					
				RETURN					; (2)		600-4=596;	  (3 ciclos)x()=496;	199d=C7h
;###############################################################################################################
t500_micros		BANCO0					;  selecciona banco 0
				MOVLW		H'A5'			; (1) ciclo de instruccion
				MOVWF		T_ADQ			; (1)
esp_t500_micros	DECFSZ	T_ADQ,1		; (1)		el decremento lo pone en el mismo registro
				GOTO		esp_t500_micros	; (2)					
				RETURN					; (2)		500-4=496;	  (3 ciclos)x()=496;	165d=A5h
;###############################################################################################################
t83_micros		BANCO0					; selecciona banco 0
				MOVLW		H'1A'			; (1) ciclo de instruccion
				MOVWF		T_ADQ			; (1)
esp_83micros	DECFSZ	T_ADQ,1		; (1)		el decremento lo pone en el mismo registro
				GOTO		esp_83micros	; (2)					
				RETURN					; (2)		83-4=79;	  (3 ciclos)x()=26.3333		26d=1Ah
;######################SUBRUTINAS DE CONFIGURACION DE REGISTROS Y PERIFERICOS ###################################################################################################
					ORG		0x200
;###################################################################################################################
;---------------------------------------------------- subrutina que configura unidades -------------------------------------------------------------------------------------------------------------------------------------------------------------------
configura_unidades	BANCO0
					;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------					
					BCF		STATUS,2		; limpia registro Z
					MOVLW		H'00'			
					MOVWF		UNI_com		; inicializa el registro UNI_com a CERO
					MOVF		UNI,0				;mueve el registro UNI a W
					SUBWF		UNI_com,1		; resultado en registro (DECE_com - 0)= 0
					BTFSS		STATUS,2		; salta si hay un 1 en la bandera Z
					GOTO		uni_no_es_cero
					GOTO		si_es_cero_uni					
					;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------					
uni_no_es_cero		DECFSZ	UNI,1
					GOTO		sigue_despleg_u
					GOTO 		despliega_cero_u
					;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
si_es_cero_uni		MOVLW		H'09'
					MOVWF		UNI
					CALL		desplegar_u_bcd
					GOTO		si_sigue_opr
					;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------										
despliega_cero_u		MOVLW		H'00'
					MOVWF		UNI
					CALL		desplegar_u_bcd
					GOTO		si_sigue_opr_u
					;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sigue_despleg_u		CALL		desplegar_u_bcd
					GOTO		si_sigue_opr_u
					;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------						
si_sigue_opr_u		CALL		tmedio_s
					BTFSC		PORTA,0
					GOTO		configura_unidades
					GOTO		TERMINA_C_U
					;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------					
TERMINA_C_U		RETURN
;###################################################################################################################
;------------------------------------------------------------------ subrutina que configura decenas --------------------------------------------------
configura_decenas	BANCO0
					;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
					BCF		STATUS,2
					MOVLW		H'00'
					MOVWF		DECE_com
					MOVF		DECE,0				;mueve el registro UNI a W
					SUBWF		DECE_com,1		; resultado en registro (DECE_com - 0)=
					BTFSS		STATUS,2			; salta si hay un 1 en la bandera Z
					GOTO		dece_no_es_cero
					GOTO		si_es_cero					
					;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
dece_no_es_cero		DECFSZ	DECE,1
					GOTO		sigue_despleg
					GOTO 		despliega_cero
					;;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
si_es_cero			MOVLW		H'09'
					MOVWF		DECE
					CALL		desplegar_d_bcd
					GOTO		si_sigue_opr
					;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------					
despliega_cero		MOVLW		H'00'
					MOVWF		DECE
					CALL		desplegar_d_bcd
					GOTO		si_sigue_opr
					;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sigue_despleg		CALL		desplegar_d_bcd
					GOTO		si_sigue_opr
					;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------						
si_sigue_opr			CALL		tmedio_s
					BTFSC		PORTA,5
					GOTO		configura_decenas
					GOTO		TERMINA_C_D
					;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
TERMINA_C_D		RETURN
;###################################################################################################################
ENCIENDE_MOTOR	BANCO0
					CLRF		CONTADOR_D_PULS
					MOVLW		H'58'						; 88 decimal = 58h
					MOVWF		CUENTA100
					
					MOVLW		H'58'						; 60 decimal				; dice cuantas veces hara el mismo retardo	
					MOVWF		CICLOS60
					
REVISA_CRUCEx0	BTFSC		PORTA,7				; monitorea el pulso de cruce por cero
					GOTO		REVISA_CRUCEx0		; monitorea el pulso de cruce por cero
					BCF		PORTA,4
					
					MOVF		CUENTA100,0			; la primera vez mueve un 88 al registro W
					MOVWF		RETARDO_PULSO		; mueve el 88 al registro RETARDO de PULSO
HAZ					CALL		t83_micros			
					DECFSZ	RETARDO_PULSO,1		; decrementa el registro y almacenalo en el mismo	
					GOTO		HAZ
					INCF		CONTADOR_D_PULS														; 8.333 [ms]/100 = 83.33 [micro s] > 83 [micros s]

					BSF		PORTA,4				; TERCERO: APARECE EL PULSO 
					CALL		t1_ms					; CUARTO: DURACION DEL PULSO DE  1 ms
					BCF		PORTA,4				; QUINTO: DESAPARECE EL PULSO, Y 

					DECFSZ	CICLOS60,1
					GOTO		SALIR_AOTRO	

					MOVLW		H'58'
					MOVWF		CICLOS60		
					GOTO		DEC_CUENTA
		
DEC_CUENTA		DECFSZ	CUENTA100,1
					GOTO		SALIR_AOTRO
					GOTO 		FINALIZA
SALIR_AOTRO		GOTO		REVISA_CRUCEx0		; SEXTO: ESPERA UN NUEVO CRUCE POR CERO

FINALIZA			BCF		PORTA,4
					GOTO		FINALIZA
					RETURN
;###################################################################################################################
LEER_TEMP_ACTUAL			NOP
								RETURN
;###################################################################################################################
DESPLEGAR_TEMP_ACTUAL	NOP
								CALL	BIN_BCD	;CONVIERTE EL DATO BINARIO DE TEMPERATURA A BCD PARA DESPLEGARLO
								
								
								RETURN								
;###################################################################################################################
ERROR_DE_TEMP				MOVF		TEMP_ACTUAL1,0		;MUEVE EL DATO DE TEMPERATURA ACTUAL AL REGISTRO W
								SUBWF		TEMP_OBJETIVO,0		; e1=Tobj - Tact1		error 1		; la diferencia almacenarla en W
																	; e2=Tobj - Tact2		error 2	
																	; de/dt = (e2-e1)/1[segundo] 
								MOVWF		ERROR_TEMPi			; error de temperatura i-ésimo								
								RETURN
;###################################################################################################################
CALC_de_dt						
								RETURN
;###################################################################################################################
MAQUINA_DE_INFERENCIA		NOP
								RETURN
;###################################################################################################################
ENVIA_ALFA					NOP
								RETURN;
;####################################################################################################################
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
					;***************************************************************************************************************************************************************************************
					CLRF 		BINARIO			
					CLRF 		CONTADOR1	
					CLRF 		CONTADOR2	
					CLRF 		CONTADOR3	
					;********************** ******** ******** ******** ******** ******** ******** ******** ******** ******** ******** ******** 
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
				MOVLW		B'10101111'		; RA7	RA6		RA5		RA4		RA3		RA2		RA1		RA0
				MOVWF		TRISA			;    1		  0	          1		  0		  1 		   1		   1		   1	
				;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------										
				MOVLW		B'00000001'		; RB7	RB6		RB5		RB4		RB3		RB2		RB1		RB0
				MOVWF		TRISB			;    0		  0	          0		  0		  0 		   0		   0		   1		   
				;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------						
				RETURN
;########################################### CONFIGURAR INTERRUPCIONES  #######################################################
configura_interrupciones	BANCO1
						;----------------------------------------------------------------------------------------------------------------------------------------------------------------		
						BCF 		OPTION_REG,INTEDG				; activa por flanco de bajada, bit INTEDG
						;-----------------------------------------------------  HABILITACION DE INTERRUPCIONES ------------------------------------------------------------------------------------------------------------------
						BSF		INTCON,	INTE     						; que sea interrupcion externa por RB0, bit INTE bit 4
						BSF		INTCON,	GIE      						; habilitamos interrupcion global GIE bit 7
																		; INTCON TAMBIEN ESTA EN BANCO 1
						RETURN
;###########################################################################################################################################;################################ PARA QUE NO SE PIERDA AQUI ESTA EL FINAL DEL PROGRAMA ##############################################################################################################################	
desplegar_u_bcd		BANCO0
					;-------------------------------------------------------------------------------------------------------------------------------------------------------		
					MOVLW		B'11110000'
					ANDWF		PORTB_com,0
					IORWF		UNI,0			; resultado en W, no altera UNI
					MOVWF		PORTB
					MOVWF		PORTB_com
					;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------					
					BTFSS		UNI,0		; salta si hay un '1' en el bit0 del registro UNI
					GOTO		pon_ceroU	; salta a etiqueta SIGUE
					BSF		PORTA,6	; pon un '1' en el pin1 del PUERTO A
					GOTO		terminaU
pon_ceroU			BCF		PORTA,6	; pon un '0' en el pin1 del puerto A					
					;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
terminaU				RETURN					
	;####################################################################################################################################
desplegar_d_bcd		BANCO0
					MOVF		DECE,0				; mueve el reg DECE_com al registro W
					MOVWF		DECE_com
					;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
					RLF		DECE_com,1
					RLF		DECE_com,1
					RLF		DECE_com,1
					RLF		DECE_com,1
					;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------			
					MOVLW		B'00001111'
					ANDWF		PORTB_com,0
					IORWF		DECE_com,0			; resultado en W, no altera UNI
					MOVWF		PORTB_com
					MOVWF		PORTB
					;-------------------------------------------------------------------------------------------------------------
terminaD			RETURN					
;##########################################################################################################################
;--------------- subrutina para convertir de BCD a BINARIO ----------------------------------------
BCD_BINARIO	MOVF		DECE,0				; mueve el contenido de DECE al registro W
				MOVWF		DECE_com		; mueve W al registro decenas comodin					
				RLF		DECE_com,1		; rota a la izq. el registo dece_comodin y el resultado ponlo ahi mismo
				RLF		DECE_com,1		; rota a la izq. el registo dece_comodin y el resultado
				MOVF    		DECE_com,0  		; mueve dece_comodin al registro W
				ADDWF		DECE,1				; suma W+DECE, el resultado almacenalo en DECE
				RLF		DECE,0				; rota a la izq. el registo, el resultado ponlo en W
				ADDWF		UNI,0				; suma W+UNI, el resultado almacenalo en W
				MOVWF		BINARIO_SP				; mueve W al registro BINARIO
				MOVWF		DATO_VELOC
				RETURN						; regresa de la Subrutina
;#################################################################################################################
LEER_TEMP_ACTUAL	NOP
						RETURN
;##################################################################################################################
DESPLEGAR_TEMP		NOP
						RETURN
;$#################################################################################################################
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
