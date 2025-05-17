#define __SFR_OFFSET 0x00
#include "avr/io.h"
;------------------------
.global main
;==============================================================
main:
;--------------------------------------------------------------
    ; Configure PORTD for outputs (LEDs)
    LDI R17, 0b00001100   ; PD2-PD3 as outputs (for spot 1 LEDs)
    OUT DDRD, R17
    
    ; Initialize all LEDs as OFF
    LDI R17, 0b00000000
    OUT PORTD, R17
    
    ; Enable SPI as slave
    LDI R17, (1<<SPE)
    OUT SPCR, R17
;--------------------------------------------------------------
wait_data:
    IN R18, SPSR
    SBRS R18, SPIF        ; Wait for byte reception
    RJMP wait_data        ; to complete
    
    IN R18, SPDR          ; Get received byte from data register
    
    ; Process received data
    ; Parking spot 1 status
    CPI R18, 0            ; Spot 1 free
    BREQ spot1_free
    CPI R18, 1            ; Spot 1 occupied
    BREQ spot1_occupied
    
    RJMP wait_data        ; Invalid data, wait for next byte
    
;--------------------------------------------------------------
; Handle Parking Spot 1
spot1_free:
    CBI PORTD, 2          ; Turn off red LED for spot 1
    SBI PORTD, 3          ; Turn on green LED for spot 1
    RJMP wait_data
    
spot1_occupied:
    SBI PORTD, 2          ; Turn on red LED for spot 1
    CBI PORTD, 3          ; Turn off green LED for spot 1
    RJMP wait_data
;==============================================================