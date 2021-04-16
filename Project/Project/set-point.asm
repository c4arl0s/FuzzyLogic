		; ============ guarda registros importantes =====================

SP_INTERRUPT	MOVWF 	W_TEMP 		;Copy W to TEMP register
		SWAPF 	STATUS,W 	;Swap status to be saved into W
		CLRF 	STATUS 		;bank 0, regardless of current bank, Clears IRP,RP1,RP0
		MOVWF 	STATUS_TEMP 	;Save status to bank zero STATUS_TEMP register
		MOVF 	PCLATH, W 	;Only required if using page 1
		MOVWF 	PCLATH_TEMP 	;Save PCLATH into W
		CLRF 	PCLATH 		;Page zero, regardless of current page

		; ============ inicia configuracion del set point

		CLRF	UNI		;limpia los registros importantes
		CLRF	DECE		;limpia reg
		MOVLW	B'0101'		;carga con 5 el registro W
		MOVWF	SP		;mueve el reg W al registro SP
		CALL	SENAL_SP	; envia señal SP a los displays 7 segmentos
		CALL	retraso_500ms   ; retraso de medio segundo para visualizar señal SP

;---------PRINCIPAL - monitorea si has presionado boton de unidades o de decenas ----------------------------

monitor_u	BTFSS	PORTB,?
		goto  	monitor_d
		goto	config_u

monitor_d	BTFSS	PORTB,?
		goto 	sigue_monitor
		goto	config_d

sigue_monitor	call	despliega_u
		call 	despliega_d
CONTINUA	call 	retraso_500ms
		call	envia_guion_al_display
		BCF	STATUS,2		;pone a cero bit Z; por si anda por ahi activo.
		DECFSZ  SP,1			;decrementa SP, si es cero salta
		GOTO	monitor_u		;regresa a seguir monitoreando las unidades
		call	BCD_BINARIO						

		;		
		; ========== recuperacion de reg import =============
		
		MOVF 	PCLATH_TEMP,W 		;Restore PCLATH
		MOVWF 	PCLATH 			;Move W into PCLATH
		SWAPF 	STATUS_TEMP,W 		;Swap STATUS_TEMP register into W
						;(sets bank to original state)
		MOVWF 	STATUS 			;Move W into STATUS register
		SWAPF 	W_TEMP,F 			;Swap W_TEMP
		SWAPF 	W_TEMP,W 		;Swap W_TEMP into W

		RETFIE				;regresa de la interrupcion

						
;-----------entra a configurar unidades en el set point ------------------------------------

config_u	INCF	UNI,1			;incrementa el registro UNI, lo almacena en UNI, afecta Z

	  	;---------------verifica si es mayor a 9 -------------------------------------------------

		BCF	STATUS,2		;pone a cero bit Z
		MOVLW	B'10101'		;carga registro W con 10 decimal
		SUBWF	UNI,0			;(UNI)-(W)->(W), el resultado lo guarda en W, sin alterar UNI
		BTFSS	STATUS,2		;verifica si el bit Z esta a 1, y salta
		GOTO	SIGUE1				
		CALL	UNI_A_CERO
SIGUE1		MOVLW	B'0101'			;carga con 5 el registro W
		MOVWF	SP			;mueve el reg W al registro SP
		call	despliega_u	;despliega el reg unidades en el display 7 segmentos

		;---------------verifica si el boton sigue presionado ----------------------------------------------		

LAZO1		BTFSS	PORTB,?		;
		goto	CONTINUA
		goto	LAZO1

;------------------ AQUI TERMINA DE CONFIGURAR UNIDADES ---------------------------------------------------------------------------------
			
;-----------entra a configurar decenas en el set point ------------------------------------

config_d	INCF	DECE,1			;incrementa el registro UNI, lo almacena en UNI, afecta Z

	  	;---------------verifica si es mayor a 9 -------------------------------------------------

		BCF	STATUS,2	;pone a cero bit Z
		MOVLW	B'10101'	;carga registro W con 10 decimal
		SUBWF	DECE,0		;(UNI)-(W)->(W), el resultado lo guarda en W, sin alterar UNI
		BTFSS	STATUS,2	;verifica si el bit Z esta a 1, y salta
		GOTO	SIGUE2				
		CALL	DECE_A_CERO
SIGUE2		MOVLW	B'0101'		;carga con 5 el registro W
		MOVWF	SP		;mueve el reg W al registro SP
		call	despliega_d	;despliega el reg unidades en el display 7 segmentos

		;---------------verifica si el boton sigue presionado ----------------------------------------------		

LAZO2		BTFSS	PORTB,?		;
		goto	CONTINUA
		goto	LAZO2

;------------------ AQUI TERMINA DE CONFIGURAR DECENAS ---------------------------------------------------------------------------------

;---------------- subrutina que despliega el registro UNI en el display de 7 segmentos --------------------
	
despliega_u	MOVF	UNI,0		; mueve el contenido de UNI al registro W
					; RA4,RA5,RA6,RA7 	UNIDADES
					; RB4,RB5,RB6,RB7	DECENAS
		MOVWF	uni_comodin	; mueve W al registro unidades comodin
		RLF	uni_comodin,1	; rota a la izq. el registo uni_comodin y el resultado ponlo ahi mismo
		RLF	uni_comodin,1
		RLF 	uni_comodin,1
		RLF	uni_comodin,1	

		MOVF	uni_comodin,0	;mueve el contenido de uni_comodin al registro W
		MOVWF	PORTA		;mueve W al puerto A
		RETURN	
;---------------------------------------------------------------------------------------------

;-------------- subrutina que despliega el registro DECE en el display de 7 segmentos --------------------
	
despliega_d	MOVF	DECE,0		; mueve el contenido de UNI al registro W
					; RA4,RA5,RA6,RA7 	UNIDADES
					; RB4,RB5,RB6,RB7	DECENAS
		MOVWF	dece_comodin	; mueve W al registro unidades comodin
		RLF	dece_comodin,1	; rota a la izq. el registo dece_comodin y el resultado ponlo ahi mismo
		RLF	dece_comodin,1
		RLF 	dece_comodin,1
		RLF	dece_comodin,1	

		MOVF	dece_comodin,0	;mueve el contenido de uni_comodin al registro W
		MOVWF	PORTB		;mueve W al puerto B
		RETURN	
;---------------------------------------------------------------------------------------------


;------------ subrutina que limpia el registro UNI -------------------------------------------

UNI_A_CERO	CLRF	UNI		;pone a ceros registro UNI, Z es afectado.
		RETURN			;regresa al flujo del programa		
;---------------------------------------------------------------------------------------------

;------------- subrutina que limpia el registro DECE -----------------------------------------

DECE_A_CERO	CLRF	DECE		;pone a ceros registro UNI, Z es afectado.
		RETURN			;regresa al flujo del programa		
;----------------------------------------------------------------------------------------------

;------------ subrutina para enviar señal SP al display ---------------------------

SENAL_SP	MOVLW	B'0101'		; carga un 5, para mostrarlo como S
		MOVWF	dece_comodin	; mueve W al registro decenas comodin
		RLF	dece_comodin,1	; rota a la izq. el registo dece_comodin y el resultado ponlo ahi mismo
		RLF	dece_comodin,1
		RLF 	dece_comodin,1
		RLF	dece_comodin,1		

		MOVF	dece_comodin,0	;mueve el contenido de dece_comodin al registro W
		MOVWF	PORTB		;mueve W al puerto B

		MOVLW	B'1110'		; carga un 14, para mostrar un E
		MOVWF	uni_comodin	; mueve W al registro decenas comodin
		RLF	uni_comodin,1	; rota a la izq. el registo uni_comodin y el resultado ponlo ahi mismo
		RLF	uni_comodin,1
		RLF 	uni_comodin,1
		RLF	uni_comodin,1		
		
		MOVF	uni_comodin,0	;mueve el contenido de uni_comodin al registro W
		MOVWF	PORTA		;mueve W al puerto A

		RETURN			
;--------------------------------------------------------------------------------------------

;--------------- subrutina para convertir de BCD a BINARIO ----------------------------------------

BCD_BINARIO	MOVF	DECE,0		; mueve el contenido de DECE al registro W
		MOVWF	dece_comodin	; mueve W al registro decenas comodin					
		RLF	dece_comodin,1	; rota a la izq. el registo dece_comodin y el resultado ponlo ahi mismo
		RLF	dece_comodin,1	; rota a la izq. el registo dece_comodin y el resultado
		MOVF    dece_comodin,0  ; mueve dece_comodin al registro W
		ADDWF	DECE,1		; suma W+DECE, el resultado almacenalo en DECE
		RLF	DECE,0		; rota a la izq. el registo, el resultado ponlo en W
		ADDWF	UNI,1		; suma W+UNI, el resultado almacenalo en W
		MOVWF	BINARIO		; mueve W al registro BINARIO
		RETURN			; regresa de la Subrutina
;-------------------------------------------------------------------------------------------
	
