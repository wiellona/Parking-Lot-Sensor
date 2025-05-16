; Arduino B (Slave) - Chemfirus 
#define __SFR_OFFSET 0x00
#include "avr/io.h"

; Vektor interupsi
.org 0x0000
    jmp main              ; Saat reset, lompat ke main
.org 0x0026               ; Alamat interupsi TWI untuk ATmega328
    jmp TWI_ISR           ; Fungsi interupsi TWI
.org 0x0034               ; Setelah tabel interupsi

.global main

; Definisi pin dan alamat
.equ DHT11_PIN, 1       ; DHT11 terhubung ke PB1
.equ SLAVE_ADDR, 0x24   ; Alamat slave (0x48 >> 1)

; Byte perintah data
.equ CMD_TEMP, 0x01     ; Perintah untuk suhu
.equ CMD_HUMID, 0x02    ; Perintah untuk kelembapan

; Variabel global
.section .data
humidity:  .byte 1        ; Simpan nilai kelembapan
temperature: .byte 1      ; Simpan nilai suhu
command:   .byte 1        ; Simpan perintah yang diterima
checksum:  .byte 1        ; Simpan checksum

.section .text
main:
    ; Inisialisasi stack
    ldi r16, hi8(RAMEND)
    out SPH, r16
    ldi r16, lo8(RAMEND)
    out SPL, r16
    
    ; Inisialisasi port
    LDI   R17, 0xFF
    OUT   DDRC, R17       ; Set PORTC sebagai output (untuk debug)

    ; Inisialisasi I2C sebagai slave
    RCALL I2C_slave_init

    ; Aktifkan interupsi global
    sei

    ; Loop utama
loop:
    RCALL read_dht11      ; Baca data dari sensor DHT11
    RCALL delay_2s        ; Tunggu 2 detik
    RJMP  loop            ; Ulang terus

; Fungsi baca DHT11
read_dht11:
    ; Kirim sinyal mulai ke DHT11
    SBI   DDRB, DHT11_PIN    ; Set sebagai output
    CBI   PORTB, DHT11_PIN   ; Tarik pin ke low
    RCALL delay_20ms         ; Tahan selama 20ms
    SBI   PORTB, DHT11_PIN   ; Tarik pin ke high

    ; Tunggu respon dari DHT11
    CBI   DDRB, DHT11_PIN    ; Set sebagai input
wait1:
    SBIC  PINB, DHT11_PIN    ; Tunggu sampai pin low
    RJMP  wait1
wait2:
    SBIS  PINB, DHT11_PIN    ; Tunggu sampai pin high
    RJMP  wait2
wait3:
    SBIC  PINB, DHT11_PIN    ; Tunggu sampai pin low
    RJMP  wait3

    ; Baca byte kelembapan (integer)
    RCALL DHT11_read_byte
    STS   humidity, R18      ; Simpan ke variabel humidity

    ; Baca byte kelembapan (desimal)
    RCALL DHT11_read_byte

    ; Baca byte suhu (integer)
    RCALL DHT11_read_byte
    STS   temperature, R18   ; Simpan ke variabel temperature

    ; Baca byte suhu (desimal)
    RCALL DHT11_read_byte

    ; Baca byte checksum
    RCALL DHT11_read_byte
    STS   checksum, R18      ; Simpan ke variabel checksum

    RET

; Fungsi baca 1 byte dari DHT11
DHT11_read_byte:
    LDI   R17, 8         ; Baca 8 bit
    CLR   R18            ; Kosongkan register data

read_bit_loop:
    ; Tunggu sampai pin high
wait4:
    SBIS  PINB, DHT11_PIN
    RJMP  wait4

    ; Tunggu sekitar 50μs
    RCALL delay_timer0

    ; Cek apakah bit = 1
    SBIS  PINB, DHT11_PIN
    RJMP  bit_zero       ; Kalau low, berarti 0

    ; Bit = 1
    SEC
    ROL   R18
    RJMP  bit_end

bit_zero:
    LSL   R18            ; Geser masuk 0

bit_end:
    ; Tunggu sampai pin low lagi
wait5:
    SBIC  PINB, DHT11_PIN
    RJMP  wait5

    ; Lanjut bit berikutnya
    DEC   R17
    BRNE  read_bit_loop
    RET

; Inisialisasi I2C sebagai slave
I2C_slave_init:
    LDI   R21, SLAVE_ADDR
    STS   TWAR, R21        ; Set alamat slave
    LDI   R21, (1<<TWEN)|(1<<TWEA)|(1<<TWINT)
    STS   TWCR, R21        ; Aktifkan TWI dan ACK

    ; Awal perintah = 0
    LDI   R21, 0
    STS   command, R21

    RET

; ISR untuk TWI
TWI_ISR:
    ; Simpan register
    PUSH  R16
    PUSH  R17
    IN    R16, SREG
    PUSH  R16

    ; Cek status TWI
    LDS   R16, TWSR
    ANDI  R16, 0xF8

    ; Cek status dan tangani
    CPI   R16, 0x60       ; Alamat + Write diterima
    BREQ  receive_command
    CPI   R16, 0x80       ; Data diterima
    BREQ  process_data
    CPI   R16, 0xA8       ; Alamat + Read diterima
    BREQ  send_data
    RJMP  TWI_done        ; Tidak dikenali

receive_command:
    ; Siap terima perintah
    LDI   R16, (1<<TWINT)|(1<<TWEN)|(1<<TWEA)
    STS   TWCR, R16
    RJMP  TWI_done

process_data:
    ; Ambil data perintah
    LDS   R16, TWDR
    STS   command, R16

    ; Siap terima byte berikutnya
    LDI   R16, (1<<TWINT)|(1<<TWEN)|(1<<TWEA)
    STS   TWCR, R16
    RJMP  TWI_done

send_data:
    ; Cek perintah dan kirim data sesuai
    LDS   R16, command
    CPI   R16, CMD_TEMP
    BREQ  send_temp
    CPI   R16, CMD_HUMID
    BREQ  send_humid

    ; Default kirim 0
    LDI   R17, 0
    RJMP  transmit_byte

send_temp:
    LDS   R17, temperature
    RJMP  transmit_byte

send_humid:
    LDS   R17, humidity

transmit_byte:
    ; Kirim byte di R17
    STS   TWDR, R17
    LDI   R16, (1<<TWINT)|(1<<TWEN)
    STS   TWCR, R16

TWI_done:
    ; Pulihkan register
    POP   R16
    OUT   SREG, R16
    POP   R17
    POP   R16
    RETI

; Delay 50 μs pakai Timer0
delay_timer0:
    CLR   R20
    OUT   TCNT0, R20        ; Timer mulai dari 0
    LDI   R20, 100
    OUT   OCR0A, R20        ; Nilai banding = 100
    LDI   R20, 0b00001010
    OUT   TCCR0B, R20       ; Timer0, mode CTC, prescaler 8

dt_loop:
    IN    R20, TIFR0
    SBRS  R20, OCF0A
    RJMP  dt_loop

    CLR   R20
    OUT   TCCR0B, R20       ; Matikan timer

    LDI   R20, (1<<OCF0A)
    OUT   TIFR0, R20        ; Bersihkan flag
    RET

; Delay sekitar 20 ms
delay_20ms:
    LDI   R21, 255
l3: LDI   R22, 210
l4: LDI   R23, 2
l5: DEC   R23
    BRNE  l5
    DEC   R22
    BRNE  l4
    DEC   R21
    BRNE  l3
    RET

; Delay sekitar 2 detik
delay_2s:
    LDI   R21, 255
l6: LDI   R22, 255
l7: LDI   R23, 164
l8: DEC   R23
    BRNE  l8
    DEC   R22
    BRNE  l7
    DEC   R21
    BRNE  l6
    RET
