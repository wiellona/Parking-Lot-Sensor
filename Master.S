#define __SFR_OFFSET 0x00
#include "avr/io.h"
;------------------------
.global main
;==============================================================
main:
.equ SCK, 5
.equ MOSI, 3
.equ SS, 2
.equ TRIG1, 1
.equ ECHO1, 0
.equ TRIG2, 7 
.equ ECHO2, 6
.equ TRIG3, 5
.equ ECHO3, 4
.equ TRIG4, 3
.equ ECHO4, 2

.equ TOTAL_SPOTS, 4   ; Total available parking spots

;--------------------------------------------------------------
    ; Initialize SPI as master
    LDI R17, (1<<MOSI)|(1<<SCK)|(1<<SS)
    OUT DDRB, R17      ; Set MOSI, SCK, SS as output
    LDI R17, (1<<SPE)|(1<<MSTR)|(1<<SPI2X)|(1<<SPR0)
    OUT SPCR, R17      ; Enable SPI as master, fsck=fosc/8, SPI mode 0
;--------------------------------------------------------------
    ; Set trigger pins as output and echo pins as input
    SBI DDRB, TRIG1    ; PB1 as output (Trigger1)
    CBI DDRB, ECHO1    ; PB0 as input (Echo1)
    
    SBI DDRC, TRIG2    ; PC7 as output (Trigger2)
    CBI DDRC, ECHO2    ; PC6 as input (Echo2)
    
    SBI DDRC, TRIG3    ; PC5 as output (Trigger3)
    CBI DDRC, ECHO3    ; PC4 as input (Echo3)
    
    SBI DDRC, TRIG4    ; PC3 as output (Trigger4)
    CBI DDRC, ECHO4    ; PC2 as input (Echo4)
    
    ; Initialize UART for Serial Monitor
    RCALL uart_init
    
    ; Initialize available spot counter
    LDI R24, TOTAL_SPOTS   ; Start with all spots available
    
;--------------------------------------------------------------
main_loop:
    ; Sensor 1 check
    SBI PORTB, TRIG1
    RCALL delay_10us
    CBI PORTB, TRIG1
    RCALL check_echo_PB0
    CPI R28, 30           ; Compare with threshold (30cm)
    BRLO spot1_occupied   ; If distance < 30cm, spot is occupied
    LDI R18, 0            ; Spot free code = 0
    RJMP spot1_status_set
spot1_occupied:
    LDI R18, 1            ; Spot occupied code = 1
spot1_status_set:
    MOV R19, R18          ; Save status to R19
    RCALL send_spi        ; Send to slave
    RCALL delay_ms        ; Small delay
    
    ; Sensor 2 check
    SBI PORTC, TRIG2
    RCALL delay_10us
    CBI PORTC, TRIG2
    RCALL check_echo_PC6
    CPI R28, 30           ; Compare with threshold
    BRLO spot2_occupied
    LDI R18, 2            ; Spot 2 free code = 2
    RJMP spot2_status_set
spot2_occupied:
    LDI R18, 3            ; Spot 2 occupied code = 3
spot2_status_set:
    MOV R20, R18          ; Save status to R20
    RCALL send_spi
    RCALL delay_ms
    
    ; Sensor 3 check
    SBI PORTC, TRIG3
    RCALL delay_10us
    CBI PORTC, TRIG3
    RCALL check_echo_PC4
    CPI R28, 30           ; Compare with threshold
    BRLO spot3_occupied
    LDI R18, 4            ; Spot 3 free code = 4
    RJMP spot3_status_set
spot3_occupied:
    LDI R18, 5            ; Spot 3 occupied code = 5
spot3_status_set:
    MOV R21, R18          ; Save status to R21
    RCALL send_spi
    RCALL delay_ms
    
    ; Sensor 4 check
    SBI PORTC, TRIG4
    RCALL delay_10us
    CBI PORTC, TRIG4
    RCALL check_echo_PC2
    CPI R28, 30           ; Compare with threshold
    BRLO spot4_occupied
    LDI R18, 6            ; Spot 4 free code = 6
    RJMP spot4_status_set
spot4_occupied:
    LDI R18, 7            ; Spot 4 occupied code = 7
spot4_status_set:
    MOV R22, R18          ; Save status to R22
    RCALL send_spi
    RCALL delay_ms
    
    ; Calculate available spots and send to serial monitor
    LDI R24, TOTAL_SPOTS   ; Start with all spots available
    
    ; Check spot 1
    CPI R19, 1
    BRNE check_spot2
    DEC R24               ; Decrease available spots
    
check_spot2:
    ; Check spot 2
    CPI R20, 3
    BRNE check_spot3
    DEC R24               ; Decrease available spots
    
check_spot3:
    ; Check spot 3
    CPI R21, 5
    BRNE check_spot4
    DEC R24               ; Decrease available spots
    
check_spot4:
    ; Check spot 4
    CPI R22, 7
    BRNE send_to_monitor
    DEC R24               ; Decrease available spots
    
send_to_monitor:
    ; Send available spots count to serial monitor
    MOV R18, R24
    RCALL send_uart       ; Send available spots to UART
    
    RCALL delay_500ms     ; Delay before next loop
    RJMP main_loop
    
;==============================================================
send_spi:
; Function to send data via SPI
    CBI PORTB, SS         ; Enable slave device
    OUT SPDR, R18         ; Transmit byte to slave
    
spi_wait:
    IN R19, SPSR
    SBRS R19, SPIF        ; Wait for byte transmission
    RJMP spi_wait         ; to complete
    
    SBI PORTB, SS         ; Disable slave device
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
check_echo_PC6:
; Function to measure echo pulse width on PC6
    ; Similar to check_echo_PB0 but for PC6
    ; Use different timer or input capture for PC6
    ; For simplicity, we'll mimic the behavior here
    RCALL delay_10us      ; Simulate measurement
    LDI R28, 40           ; Return a value (adjust as needed)
    RET
;==============================================================
check_echo_PC4:
; Function to measure echo pulse width on PC4
    ; Similar to check_echo_PB0 but for PC4
    RCALL delay_10us      ; Simulate measurement
    LDI R28, 40           ; Return a value (adjust as needed)
    RET
;==============================================================
check_echo_PC2:
; Function to measure echo pulse width on PC2
    ; Similar to check_echo_PB0 but for PC2
    RCALL delay_10us      ; Simulate measurement
    LDI R28, 40           ; Return a value (adjust as needed)
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
send_uart:
; Send R18 register to UART
    LDS R19, UCSR0A
    SBRS R19, UDRE0       ; Wait if buffer is full
    RJMP send_uart
    
    STS UDR0, R18         ; Send data
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