#define __SFR_OFFSET 0x00
#include "avr/io.h"
;------------------------
.global main
;==============================================================
main:
.equ SCK, 5    ; PB5 (pin 13)
.equ MOSI, 3   ; PB3 (pin 11)
.equ SS, 2     ; PB2 (pin 10)
.equ TRIG1, 1  ; PB1 (pin 9)
.equ ECHO1, 0  ; PB0 (pin 8)

.equ TOTAL_SPOTS, 1   ; Only one parking spot

;--------------------------------------------------------------
    ; Initialize UART for Serial Monitor first
    RCALL uart_init
    
    ; Print welcome message to serial monitor
    LDI ZL, lo8(welcome_msg)
    LDI ZH, hi8(welcome_msg)
    RCALL print_string
    RCALL print_newline

    ; Initialize SPI as master
    LDI R17, (1<<MOSI)|(1<<SCK)|(1<<SS)
    OUT DDRB, R17      ; Set MOSI, SCK, SS as output
    LDI R17, (1<<SPE)|(1<<MSTR)|(1<<SPI2X)|(1<<SPR0)
    OUT SPCR, R17      ; Enable SPI as master, fsck=fosc/8, SPI mode 0
    
    ; Initial test message
    LDI ZL, lo8(spi_initialized_msg)
    LDI ZH, hi8(spi_initialized_msg)
    RCALL print_string
    RCALL print_newline
;--------------------------------------------------------------
    ; Set trigger pin as output and echo pin as input
    SBI DDRB, TRIG1    ; PB1 as output (Trigger1)
    CBI DDRB, ECHO1    ; PB0 as input (Echo1)
    
    ; Send a test command to verify SPI is working
    LDI ZL, lo8(sending_test_msg)
    LDI ZH, hi8(sending_test_msg)
    RCALL print_string
    RCALL print_newline
    
    ; Send test value 0 (LED free status)
    LDI R18, 0
    RCALL send_spi
    
    ; Send test value 1 (LED occupied status)
    LDI R18, 1
    RCALL send_spi
    
    ; Send test value 0 again (LED free status)
    LDI R18, 0
    RCALL send_spi
    
    ; Initialize available spot counter
    LDI R24, TOTAL_SPOTS   ; Start with all spots available
    
;--------------------------------------------------------------
main_loop:
    ; Print separator for clarity
    LDI ZL, lo8(separator_msg)
    LDI ZH, hi8(separator_msg)
    RCALL print_string
    RCALL print_newline

    ; Sensor 1 check
    LDI ZL, lo8(checking_sensor_msg)
    LDI ZH, hi8(checking_sensor_msg)
    RCALL print_string
    RCALL print_newline
    
    ; Generate trigger pulse for sensor
    SBI PORTB, TRIG1       ; Set trigger high
    RCALL delay_10us       ; Wait 10 microseconds
    CBI PORTB, TRIG1       ; Set trigger low
    
    ; Measure echo pulse
    RCALL check_echo_PB0
    
    ; Print distance to serial monitor
    LDI ZL, lo8(distance_msg)
    LDI ZH, hi8(distance_msg)
    RCALL print_string
    
    MOV R18, R28          ; Copy distance value to R18
    RCALL print_number    ; Print the distance value
    
    LDI R18, 'c'          ; Print 'cm'
    RCALL send_char
    LDI R18, 'm'
    RCALL send_char
    RCALL print_newline
    
    ; Debug raw sensor value
    LDI ZL, lo8(raw_sensor_msg)
    LDI ZH, hi8(raw_sensor_msg)
    RCALL print_string
    MOV R18, R28
    RCALL print_number
    RCALL print_newline
    
    ; Check if spot is occupied
    CPI R28, 30           ; Compare with threshold (30cm)
    BRSH spot1_free       ; If distance >= 30cm, spot is free
    
    ; Spot is occupied (distance < 30cm)
    LDI R18, 1            ; Spot occupied code = 1
    
    ; Print spot status
    LDI ZL, lo8(occupied_msg)
    LDI ZH, hi8(occupied_msg)
    RCALL print_string
    RCALL print_newline
    
    RJMP spot1_status_set
    
spot1_free:
    LDI R18, 0            ; Spot free code = 0
    
    ; Print spot status
    LDI ZL, lo8(free_msg)
    LDI ZH, hi8(free_msg)
    RCALL print_string
    RCALL print_newline
    
spot1_status_set:
    ; Save status value for later use
    MOV R19, R18
    
    ; Debug print the value being sent via SPI
    LDI ZL, lo8(sending_msg)
    LDI ZH, hi8(sending_msg)
    RCALL print_string
    MOV R18, R19
    RCALL print_number
    RCALL print_newline
    
    ; Send status to slave via SPI
    MOV R18, R19          ; Restore value to R18 for SPI
    RCALL send_spi        ; Send to slave
    
    ; Calculate available spots and send to serial monitor
    LDI R24, TOTAL_SPOTS   ; Start with all spots available
    
    ; Check spot 1
    CPI R19, 1
    BRNE send_to_monitor
    DEC R24               ; Decrease available spots if occupied
    
send_to_monitor:
    ; Print available spots message
    LDI ZL, lo8(available_msg)
    LDI ZH, hi8(available_msg)
    RCALL print_string
    
    ; Send available spots count to serial monitor
    MOV R18, R24
    RCALL print_number    ; Print available spots count
    RCALL print_newline
    
    RCALL delay_500ms     ; Delay before next loop
    RJMP main_loop
    
;==============================================================
send_spi:
; Function to send data via SPI
; Input: R18 = data to send
    PUSH R19
    PUSH R20

    ; Debug message
    MOV R20, R18          ; Preserve data byte
    LDI ZL, lo8(spi_sending_msg)
    LDI ZH, hi8(spi_sending_msg)
    RCALL print_string
    MOV R18, R20
    RCALL print_number
    RCALL print_newline
    
    CBI PORTB, SS         ; Enable slave device (SS low)
    
    OUT SPDR, R20         ; Transmit byte to slave
    
spi_wait:
    IN R19, SPSR
    SBRS R19, SPIF        ; Wait for byte transmission
    RJMP spi_wait         ; to complete
    
    SBI PORTB, SS         ; Disable slave device (SS high)
    
    ; Debug message
    LDI ZL, lo8(spi_complete_msg)
    LDI ZH, hi8(spi_complete_msg)
    RCALL print_string
    RCALL print_newline
    
    POP R20
    POP R19
    RET
;==============================================================
check_echo_PB0:
; Function to measure echo pulse width on PB0
    LDI R20, 0b00000000
    STS TCCR1A, R20       ; Timer 1 normal mode
    LDI R20, 0b11000101   ; Set for rising edge detection &
    STS TCCR1B, R20       ; prescaler=1024, noise cancellation ON
    
wait_rise_pb0:
    IN R21, TIFR1
    SBRS R21, ICF1
    RJMP wait_rise_pb0    ; Loop until rising edge is detected
    
    LDS R16, ICR1L        ; Store count value at rising edge
    
    OUT TIFR1, R21        ; Clear flag for falling edge detection
    LDI R20, 0b10000101
    STS TCCR1B, R20       ; Set for falling edge detection
    
wait_fall_pb0:
    IN R21, TIFR1
    SBRS R21, ICF1
    RJMP wait_fall_pb0    ; Loop until falling edge is detected
    
    LDS R28, ICR1L        ; Store count value at falling edge
    
    SUB R28, R16          ; Count diff R28 = R28 - R16
    OUT TIFR1, R21        ; Clear flag for next sensor reading
    RET
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
delay_10us:
; 10 microsecond delay using Timer0
    CLR R20
    OUT TCNT0, R20        ; Initialize timer0 with count=0
    LDI R20, 20
    OUT OCR0A, R20        ; OCR0 = 20
    LDI R20, 0b00001010
    OUT TCCR0B, R20       ; Timer0: CTC mode, prescaler 8
    
delay_10us_loop:
    IN R20, TIFR0
    SBRS R20, OCF0A       ; If OCF0=1, skip next instruction
    RJMP delay_10us_loop  ; Else, loop back & check OCF0 flag
    
    CLR R20
    OUT TCCR0B, R20       ; Stop timer0
    
    LDI R20, (1<<OCF0A)
    OUT TIFR0, R20        ; Clear OCF0 flag
    RET
;==============================================================
delay_ms:
; Short delay (milliseconds)
    LDI R21, 10
d1: LDI R22, 50
d2: LDI R23, 50
d3: DEC R23
    BRNE d3
    DEC R22
    BRNE d2
    DEC R21
    BRNE d1
    RET
;==============================================================
delay_500ms:
; Longer delay (500 milliseconds)
    LDI R21, 100
d4: LDI R22, 100
d5: LDI R23, 100
d6: DEC R23
    BRNE d6
    DEC R22
    BRNE d5
    DEC R21
    BRNE d4
    RET
;==============================================================

; String constants
welcome_msg:
    .ascii "Parking System Master Started"
    .byte 0
distance_msg:
    .ascii "Distance: "
    .byte 0
raw_sensor_msg:
    .ascii "Raw sensor value: "
    .byte 0
free_msg:
    .ascii "Spot FREE"
    .byte 0
occupied_msg:
    .ascii "Spot OCCUPIED"
    .byte 0
available_msg:
    .ascii "Available spots: "
    .byte 0
sending_msg:
    .ascii "Sending status to slave: "
    .byte 0
spi_initialized_msg:
    .ascii "SPI initialized as master"
    .byte 0
spi_sending_msg:
    .ascii "SPI sending byte: "
    .byte 0
spi_complete_msg:
    .ascii "SPI transmission complete"
    .byte 0
sending_test_msg:
    .ascii "Sending test SPI commands on startup"
    .byte 0
checking_sensor_msg:
    .ascii "Checking ultrasonic sensor"
    .byte 0
separator_msg:
    .ascii "----------------------------------------"
    .byte 0
;==============================================================