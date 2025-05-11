#include <avr/io.h>

; Constants
.equ N_SLOTS, 4

; Start
.section .text
.global slave_main

slave_main:
    ; Initialize sensor PORTD2..5 as input pull-up
    ldi r19, (1<<2)|(1<<3)|(1<<4)|(1<<5)
    out _SFR_IO_ADDR(DDRD), r19
    out _SFR_IO_ADDR(PORTD), r19

    ; Initialize LED PORTB0..PB7 as output
    ldi r19, 0xFF
    out _SFR_IO_ADDR(DDRB), r19
    ldi r19, 0x00
    out _SFR_IO_ADDR(PORTB), r19

    ; Initialize SPI Slave
    ldi r19, (1<<6)    ; SPE is bit 6 in SPCR
    out _SFR_IO_ADDR(SPCR), r19

main_loop:
    ; Count empty slots
    ldi r16, 0       ; slot_cnt = 0
    in r17, _SFR_IO_ADDR(PIND)     ; inport = PIND
    ldi r18, 1       ; bitmask = 1

check_loop:
    ; Check active-low sensor
    mov r19, r17     ; tmp = inport
    and r19, r18     ; tmp = tmp & bitmask
    brne slot_empty
    ; Occupied: Red LED
    ; Set PB4..7
    ; Example implementation:
    ; mov r19, r18
    ; lsl r19
    ; lsl r19
    ; lsl r19
    ; lsl r19
    ; out _SFR_IO_ADDR(PORTB), r19
    rjmp next_bit

slot_empty:
    ; Empty: Green LED +1
    ; out _SFR_IO_ADDR(PORTB), r18  ; bitmask
    inc r16          ; slot_cnt++

next_bit:
    lsl r18          ; bitmask <<= 1
    cpi r18, (1<<N_SLOTS)
    brlt check_loop

    ; Wait for SPI request
wait_spi:
    in r19, _SFR_IO_ADDR(SPSR)
    sbrs r19, 7      ; SPIF is bit 7 in SPSR
    rjmp wait_spi
    ; Send slot_cnt
    out _SFR_IO_ADDR(SPDR), r16
    rjmp main_loop