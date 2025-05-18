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
    
    ; Initialize all LEDs - turn on green LED initially
    LDI R17, 0b00001000   ; PD3 (green LED) ON, PD2 (red LED) OFF
    OUT PORTD, R17
    
    ; Initialize UART for serial monitor
    RCALL uart_init
    
    ; Initialize R24 and R25 for status comparison
    LDI R24, 0xFF        ; Initial previous value (invalid to force first message)
    LDI R25, 0           ; Default current value
    
    ; Define total parking spots
    LDI R23, 1           ; Total parking spots (currently 1)
    
    ; Show initial available slots (start with all free)
    LDI ZL, lo8(available_slots_msg)
    LDI ZH, hi8(available_slots_msg)
    RCALL print_string
    MOV R18, R23          ; Copy total spots to R18 (initially all available)
    RCALL print_number    ; Print available slots count
    RCALL print_newline
    
    ; Enable SPI as slave
    LDI R17, (1<<SPE)
    OUT SPCR, R17
;--------------------------------------------------------------
wait_data:
    ; Store previous data for comparison
    MOV R24, R25          ; Save previous value to R24
    
    ; Wait for SPI data
    IN R18, SPSR
    SBRS R18, SPIF        ; Wait for byte reception
    RJMP wait_data        ; to complete
    
    ; Get the received data
    IN R25, SPDR          ; Get received byte from data register to R25
    
    ; Only update display if the data changed
    CP R25, R24
    BREQ skip_status_update
    
    ; Process received data
    CPI R25, 0            ; Compare with 0 (spot free)
    BREQ set_spot_free
    CPI R25, 1            ; Compare with 1 (spot occupied)
    BREQ set_spot_occupied
    RJMP wait_data        ; Invalid data, just wait for next
    
skip_status_update:
    ; Clear SPI interrupt flag
    IN R18, SPSR          ; Read SPSR to clear SPIF
    RJMP wait_data
    
;--------------------------------------------------------------
set_spot_free:
    ; Turn off red LED (PD2)
    CBI PORTD, 2
    ; Turn on green LED (PD3)
    SBI PORTD, 3
    
    ; Calculate available slots and display
    LDI ZL, lo8(available_slots_msg)
    LDI ZH, hi8(available_slots_msg)
    RCALL print_string
    MOV R18, R23          ; Copy total spots to R18 (all available when free)
    RCALL print_number    ; Print available slots count
    RCALL print_newline
    
    ; Clear SPI interrupt flag
    IN R18, SPSR          ; Read SPSR to clear SPIF
    RJMP wait_data
    
;--------------------------------------------------------------
set_spot_occupied:
    ; Turn on red LED (PD2)
    SBI PORTD, 2
    ; Turn off green LED (PD3)
    CBI PORTD, 3
    
    ; Calculate available slots and display
    LDI ZL, lo8(available_slots_msg)
    LDI ZH, hi8(available_slots_msg)
    RCALL print_string
    CLR R18               ; 0 slots available when occupied
    RCALL print_number    ; Print available slots count
    RCALL print_newline
    
    ; Clear SPI interrupt flag
    IN R18, SPSR          ; Read SPSR to clear SPIF
    RJMP wait_data

;==============================================================
; UART Functions
;==============================================================
uart_init:
; Initialize UART for 9600 baud rate
    LDI R17, 103          ; For 9600 baud @16MHz
    STS UBRR0L, R17
    LDI R17, 0
    STS UBRR0H, R17
    
    LDI R17, (1<<TXEN0)   ; Enable transmitter
    STS UCSR0B, R17
    
    LDI R17, (1<<UCSZ01)|(1<<UCSZ00) ; 8-bit data
    STS UCSR0C, R17
    RET
;==============================================================
send_char:
; Send single character in R18 to UART
    PUSH R19
wait_tx_ready:
    LDS R19, UCSR0A
    SBRS R19, UDRE0       ; Wait if buffer is full
    RJMP wait_tx_ready
    
    STS UDR0, R18         ; Send data
    POP R19
    RET
;==============================================================
print_string:
; Print null-terminated string pointed to by Z register
    PUSH R18
print_string_loop:
    LPM R18, Z+           ; Load character from program memory
    CPI R18, 0            ; Check for null terminator
    BREQ print_string_done
    RCALL send_char       ; Send character
    RJMP print_string_loop
print_string_done:
    POP R18
    RET
;==============================================================
print_number:
; Print number in R18 (0-255)
    PUSH R18
    PUSH R19
    
    CPI R18, 100          ; Check if number >= 100
    BRLO tens_digit       ; If less than 100, skip to tens digit
    
    ; Print hundreds digit
    LDI R19, '0'          ; Start with '0'
hundreds_loop:
    CPI R18, 100          ; Check if >= 100
    BRLO hundreds_done    ; If < 100, done with hundreds
    SUBI R18, 100         ; Subtract 100
    INC R19               ; Increment digit
    RJMP hundreds_loop    ; Continue loop
hundreds_done:
    PUSH R18              ; Save remainder
    MOV R18, R19          ; Move hundreds digit to R18
    RCALL send_char       ; Print hundreds digit
    POP R18               ; Restore remainder
    
tens_digit:
    CPI R18, 10           ; Check if number >= 10
    BRLO ones_digit       ; If less than 10, skip to ones digit
    
    ; Print tens digit
    LDI R19, '0'          ; Start with '0'
tens_loop:
    CPI R18, 10           ; Check if >= 10
    BRLO tens_done        ; If < 10, done with tens
    SUBI R18, 10          ; Subtract 10
    INC R19               ; Increment digit
    RJMP tens_loop        ; Continue loop
tens_done:
    PUSH R18              ; Save remainder
    MOV R18, R19          ; Move tens digit to R18
    RCALL send_char       ; Print tens digit
    POP R18               ; Restore remainder
    
ones_digit:
    ; Print ones digit
    SUBI R18, -'0'        ; Convert to ASCII
    RCALL send_char       ; Print ones digit
    
    POP R19
    POP R18
    RET
;==============================================================
print_newline:
; Print newline and carriage return
    PUSH R18
    LDI R18, 0x0D         ; Carriage return
    RCALL send_char
    LDI R18, 0x0A         ; Line feed
    RCALL send_char
    POP R18
    RET
;==============================================================

; String constants
welcome_msg:
    .ascii "Parking Spot Monitor Slave Started"
    .byte 0
received_msg:
    .ascii "Received data from master: "
    .byte 0
free_msg:
    .ascii "Spot status: FREE (Green LED ON)"
    .byte 0
occupied_msg:
    .ascii "Spot status: OCCUPIED (Red LED ON)"
    .byte 0
invalid_msg:
    .ascii "Invalid data received"
    .byte 0
pins_config_msg:
    .ascii "DDRD configuration: "
    .byte 0
init_led_msg:
    .ascii "Initial LED state (PORTD): "
    .byte 0
new_led_msg:
    .ascii "Updated LED state (PORTD): "
    .byte 0
setting_free_msg:
    .ascii "Setting LEDs for FREE state (Red OFF, Green ON)"
    .byte 0
setting_occupied_msg:
    .ascii "Setting LEDs for OCCUPIED state (Red ON, Green OFF)"
    .byte 0
waiting_msg:
    .ascii "Waiting for data from master..."
    .byte 0
available_slots_msg:
    .ascii "Available parking slot: "
    .byte 0
;==============================================================