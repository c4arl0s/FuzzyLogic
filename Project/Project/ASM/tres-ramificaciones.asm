;***************************************************************
				list	p=16F88
				#include	<p16F88.inc>
;***************************************************************				; RECORDATORIO DE EN DONDE SE ENCUENGRAN ALGUNOS REGISTROS 
BANCO0   	MACRO											;	ADRESH	1Eh		banco 0
			BCF     STATUS,RP0								;	ADRESL	9Eh		banco 1
			BCF     STATUS,RP1								;	ANSEL		9Bh		banco 1
			ENDM											; 	ADCON0	1Fh		banco 0
BANCO1   	MACRO											;	ADCON1	9Fh		banco 1
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
STATUS_TEMP	equ 29h
PCLATH_TEMP	equ 2Ah
W_TEMP		equ	2Bh
;***************************************************************
;###################################################################################################################################
				ORG		0x0000
				GOTO		INICIO
				ORG		0x04
				GOTO		SP_INTERRUPT
				ORG		0x05
;###################################################################################################################################
INICIO			BANCO0
										;Uno de estos posibles valores llevarlos a W y en una parte del programa tratarlos así:
				MOVF		PORTA,0
			

				MOVLW		H'02'
DECISION 								; SITIO EN DONDE LA PREGUNTA "?" TENDRÍA SOLUCIÓN
				ADDWF 	PCL,1		; carga 
				GOTO 		ACCION1
				GOTO 		ACCION2
				GOTO 		ACCION3

ACCION1
						 				; INSTRUCCIONES CORRESPONDIENTES A LA ACCIÓN 1

				GOTO 		SIGUEPROG
ACCION2
						 				; INSTRUCCIONES CORRESPONDIENTES A LA ACCIÓN 2

				GOTO 		SIGUEPROG
ACCION3
										; INSTRUCCIONES CORRESPONDIENTES A LA ACCIÓN 3
SIGUEPROG 							; SITIO DE ENCUENTRO LUEGO DE UNA DE LAS ACCIONES
										; CONTINUACIÓN DEL PROGRAMA
				GOTO		INICIO
;####################################################################################################################
;{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{  SUBRUTINA DE INTERRUPCION }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
SP_INTERRUPT	MOVWF 	W_TEMP 		;Copy W to TEMP register								;codigo propuesto por hoja de especificaciones
				SWAPF 		STATUS,W 		;Swap status to be saved into W							;codigo propuesto por hoja de especificaciones
				CLRF 		STATUS 		;bank 0, regardless of current bank, Clears IRP,RP1,RP0	;codigo propuesto por hoja de especificaciones
				MOVWF 	STATUS_TEMP 	;Save status to bank zero STATUS_TEMP register			;codigo propuesto por hoja de especificaciones
				MOVF 		PCLATH, W 		;Only required if using page 1							;codigo propuesto por hoja de especificaciones
				MOVWF 	PCLATH_TEMP 	;Save PCLATH into W									;codigo propuesto por hoja de especificaciones
				CLRF 		PCLATH 		;Page zero, regardless of current page					;codigo propuesto por hoja de especificaciones

				; ============ 
				;		
				; ========== recuperacion de reg import =============
		
				MOVF 		PCLATH_TEMP,W 		;Restore PCLATH						;codigo propuesto por hoja de especificaciones
				MOVWF 	PCLATH 				;Move W into PCLATH					;codigo propuesto por hoja de especificaciones
				SWAPF 		STATUS_TEMP,W 		;Swap STATUS_TEMP register into W	;codigo propuesto por hoja de especificaciones
													;(sets bank to original state)					;codigo propuesto por hoja de especificaciones
				MOVWF 	STATUS 				;Move W into STATUS register			;codigo propuesto por hoja de especificaciones
				SWAPF 		W_TEMP,F 				;Swap W_TEMP						;codigo propuesto por hoja de especificaciones
				SWAPF 		W_TEMP,W 				;Swap W_TEMP into W				;codigo propuesto por hoja de especificaciones

				RETFIE								;regresa de la interrupcion
;}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} TERMINA SUBRUTINA DE INTERRUPCION }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

;################################ PARA QUE NO SE PIERDA AQUI ESTA EL FINAL DEL PROGRAMA ##############################################################################################################################	
						END
;###################################################################################################################################
