#include <avr/io.h>

; Constants
.equ N_SLOTS, 4
.equ THRESHOLD, 147         ; ~5cm

; Start
.section .text
.global main

main:
    ; Initialize USART0 - 9600bps for 16MHz
    ldi r19, 103
    sts UBRR0L, r19
    clr r19
    sts UBRR0H, r19
    ldi r19, (1<<TXEN0)
    sts UCSR0B, r19

    ; Set PORTD (Trigger) as output
    ldi r19, 0x0F          ; PD0 - PD3 = trigger
    out DDRD, r19

    ; Set PORTC (Echo) as input
    clr r19
    out DDRC, r19

    ; Set PORTB as output (LED)
    ldi r19, 0xFF
    out DDRB, r19

main_loop:
    clr r18        ; idx = 0
    clr r16        ; slot_cnt = 0

sensor_loop:
    ; Trigger pulse on PDx (sensor #idx)
    ldi r19, 1
    mov r20, r19   ; mask = 1
    tst r18        ; test idx
    breq skip_shift
shift_loop:
    lsl r20        ; shift mask left
    dec r18
    brne shift_loop
skip_shift:
    ; Trigger pulse (10us)
    out PORTD, r20
    rcall delay_10us
    clr r19
    out PORTD, r19

    ; Wait for ECHO (from PCx)
    in r19, PINC
wait_echo_start:
    in r19, PINC
    and r19, r20
    breq wait_echo_start

    ; Measure high time (pulse width)
    clr r17        ; dist = 0
wait_echo_end:
    in r19, PINC
    and r19, r20
    breq done_measuring
    inc r17
    rjmp wait_echo_end

done_measuring:
    ; Compare with THRESHOLD
    ldi r19, THRESHOLD
    cp r17, r19
    brlo slot_terisi

slot_kosong:
    inc r16        ; slot_cnt++
    ; Green LED (PB0-PB3)
    out PORTB, r20
    rjmp lanjut

slot_terisi:
    ; Red LED (PB4-PB7)
    mov r21, r20
    lsl r21
    lsl r21
    lsl r21
    lsl r21        ; shift left 4 bits
    out PORTB, r21

lanjut:
    ; Increment index
    inc r18
    cpi r18, N_SLOTS
    brlo sensor_loop

    ; Send slot_cnt via USART
    mov r20, r16
    rcall send_usart

    ; Delay between cycles
    rcall delay_500ms

    rjmp main_loop

; =======================================
; Subroutine to send byte in r20 via USART
; =======================================
send_usart:
wait_udre:
    lds r19, UCSR0A
    sbrs r19, UDRE0
    rjmp wait_udre
    sts UDR0, r20
    ret

; Delay 10us
delay_10us:
    ldi r19, 40
delay10_loop:
    dec r19
    brne delay10_loop
    ret

; Delay ~500ms (rough)
delay_500ms:
    ldi r21, 50
loop_500:
    rcall delay_10ms
    dec r21
    brne loop_500
    ret

; Delay 10ms
delay_10ms:
    ldi r22, 200
delay10ms_loop1:
    ldi r23, 255
delay10ms_loop2:
    dec r23
    brne delay10ms_loop2
    dec r22
    brne delay10ms_loop1
    ret