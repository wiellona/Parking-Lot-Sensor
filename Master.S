
#define __SFR_OFFSET 0x00
#include "avr/io.h"
;------------------------
.global main
;==============================================================
main:
;--------------------------------------------------------------
    ; Configure PORTD for outputs (LEDs and buzzers)
    LDI R17, 0b11111100   ; PD2-PD7 as outputs
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
    
    ; Parking spot 2 status
    CPI R18, 2            ; Spot 2 free
    BREQ spot2_free
    CPI R18, 3            ; Spot 2 occupied
    BREQ spot2_occupied
    
    ; Parking spot 3 status
    CPI R18, 4            ; Spot 3 free
    BREQ spot3_free
    CPI R18, 5            ; Spot 3 occupied
    BREQ spot3_occupied
    
    ; Parking spot 4 status
    CPI R18, 6            ; Spot 4 free
    BREQ spot4_free
    CPI R18, 7            ; Spot 4 occupied
    BREQ spot4_occupied
    
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
    
;--------------------------------------------------------------
; Handle Parking Spot 2
spot2_free:
    CBI PORTD, 4          ; Turn off red LED for spot 2
    SBI PORTD, 5          ; Turn on green LED for spot 2
    RJMP wait_data
    
spot2_occupied:
    SBI PORTD, 4          ; Turn on red LED for spot 2
    CBI PORTD, 5          ; Turn off green LED for spot 2
    RJMP wait_data
    
;--------------------------------------------------------------
; Handle Parking Spot 3
spot3_free:
    CBI PORTD, 6          ; Turn off red LED for spot 3
    SBI PORTD, 7          ; Turn on green LED for spot 3
    RJMP wait_data
    
spot3_occupied:
    SBI PORTD, 6          ; Turn on red LED for spot 3
    CBI PORTD, 7          ; Turn off green LED for spot 3
    RJMP wait_data
    
;--------------------------------------------------------------
; Handle Parking Spot 4
spot4_free:
    CBI PORTB, 0          ; Turn off red LED for spot 4
    SBI PORTB, 1          ; Turn on green LED for spot 4
    RJMP wait_data
    
spot4_occupied:
    SBI PORTB, 0          ; Turn on red LED for spot 4
    CBI PORTB, 1          ; Turn off green LED for spot 4
    RJMP wait_data
;==============================================================