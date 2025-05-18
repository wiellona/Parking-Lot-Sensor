# Parking Lot Sensor

## Anggota Kelompok

- [Ibnu Zaky Fauzi](https://github.com/IbnuZakyFauzi) - 2306161870
- [Muhammad Ikhsan Kurniawan](https://github.com/esuuun) - 2306210784
- [Muhammad Raditya Alif Nugroho](https://github.com/dityalif) - 2306212745
- [Wiellona Darlene Oderia Saragih](https://github.com/wiellona) - 2306264396

## Table of Contents

- [Introduction](#Introduction)
- [Hardware Design and Implementation Details](#hardware-design-and-implementation-details)
- [Software implementation details](#software-implementation-details)
- [Test results and performance evaluation](#test-result-and-performance-evaluation)
- [Conclusion and future work](#conclusion-and-future-work)

## Introduction

### Problem

- Peningkatan jumlah kendaraan pribadi menyebabkan tantangan dalam pengelolaan area parkir akibat keterbatasan lahan.
- Kurangnya informasi real-time tentang ketersediaan slot parkir mengakibatkan kemacetan dan pemborosan waktu.
- Pengemudi menghabiskan waktu tidak produktif untuk mencari tempat parkir yang tersedia.
- Diperlukan sistem yang dapat memberikan informasi ketersediaan parkir secara efisien dan mudah diakses.
- Implementasi ditargetkan untuk lokasi publik seperti pusat perbelanjaan dan gedung perkantoran.

### Solution

- Sistem ini menggunakan sensor ultrasonik HC-SR04 untuk mendeteksi keberadaan kendaraan melalui pengukuran jarak.
- Arsitektur rangkaian terdiri dari Arduino Master (membaca data dari empat sensor) dan Arduino Slave (mengatur indikator LED).
- Indikator visualnya berupa LED hijau untuk slot kosong dan merah untuk slot terisi.
- Komunikasi antar Arduino dilakukan melalui koneksi serial untuk mentransmisikan status slot.
- Monitor virtual real-time menampilkan jumlah slot parkir kosong tanpa perlu pemeriksaan manual.

### Main Features

- **Deteksi Slot Parkir**: Sistem secara otomatis mendeteksi apakah sebuah slot parkir sedang terisi atau kosong menggunakan sensor ultrasonik HC-SR04.
- **Komunikasi Data Serial**: Menggunakan dua unit Arduino (Master dan Slave) yang terhubung melalui komunikasi serial untuk mengirim dan menerima data status slot parkir
- **Indikator LED**: Menggunakan LED hijau dan merah untuk menandakan slot parkir terisi atau kosong
- **Tampilan Jumlah Slot Kosong**: Informasi jumlah slot kosong ditampilkan secara real-time pada monitor virtual untuk memudahkan pengemudi mengetahui ketersediaan parkir tanpa harus memeriksa secara langsung.

## Hardware Design and Implementation Details

Dalam perancangan sistem sensor parkir otomatis ini, digunakan beberapa komponen utama seperti dua unit Arduino Uno, sensor ultrasonik HC-SR04, LED indikator, serta resistor. Arduino Master berperan dalam **membaca dan memproses data** dari sensor ultrasonik yang dipasang pada lot parkir. Sensor tersebut bekerja dengan memancarkan gelombang ultrasonik dan mengukur waktu pantulannya untuk mendeteksi keberadaan kendaraan di slot tersebut. Data hasil deteksi kemudian dikirimkan ke Arduino Slave melalui komunikasi serial. Arduino Slave bertugas **\*menerima data tersebut dan mengendalikan LED** sebagai indikator visual: merah untuk slot terisi dan hijau untuk slot kosong. Selain itu, Arduino Slave juga **menampilkan jumlah slot kosong** secara real-time pada monitor virtual. Penggunaan resistor dalam rangkaian berfungsi untuk mengatur arus listrik agar komponen tetap bekerja dalam batas aman

### Hardware Schematic

![375462](https://hackmd.io/_uploads/rkRMdIPZge.jpg)

### Komponen

| Komponen       | Deskripsi                                           |
| -------------- | --------------------------------------------------- |
| Arduino Uno    | ![image](https://hackmd.io/_uploads/B1viF8wZlx.png) |
| Sensor HC-SR04 | ![image](https://hackmd.io/_uploads/Hkrf5IvZxx.png) |
| LED            | ![image](https://hackmd.io/_uploads/BJpB9LD-xe.png) |
| Resistor       | ![image](https://hackmd.io/_uploads/HkfFqIwWel.png) |

## Software Implementation Details

### Software Implementation

Pada tahap implementasi software, program dikembangkan menggunakan Arduino IDE untuk mengatur komunikasi dan respons antara berbagai komponen sistem. Kode yang ditulis bertugas untuk membaca data dari sensor ultrasonik, memprosesnya melalui mikrokontroler Arduino, lalu mengirimkan informasi ke unit lain melalui komunikasi serial. Arduino Master berperan dalam membaca data dari sensor dan menentukan apakah slot parkir terisi atau tidak. Data ini kemudian dikirimkan ke Arduino Slave, yang bertugas mengatur tampilan LED sebagai indikator status slot. Selain itu, informasi jumlah slot kosong juga dikirim ke monitor virtual agar pengguna dapat mengetahui kondisi parkir secara real-time.

### Software Used

![Visual Studio Code](https://img.shields.io/badge/Visual%20Studio%20Code-0078d7.svg?style=for-the-badge&logo=visual-studio-code&logoColor=white)
![Arduino](https://img.shields.io/badge/Arduino_IDE-00979D?style=for-the-badge&logo=arduino&logoColor=white)
![Proteus](https://img.shields.io/badge/Proteus-Simulation-blue?style=for-the-badge&logoColor=white)
![Assembly](https://img.shields.io/badge/Assembly-Language-critical?style=for-the-badge&logoColor=white)

### Flowchart

##### **Flowchart Slave**

![Flowchart Slave](https://hackmd.io/_uploads/H1_8QPDWxe.png)

##### **Flowchart Master**

![Flowchart Master](https://hackmd.io/_uploads/BJ_IQvPZll.png)

## Test Result and Performance Evaluation

### Test Result

| Parameter   | Gambar Rangkaian                                                             | Output Virtual Monitor                              |
| ----------- | ---------------------------------------------------------------------------- | --------------------------------------------------- |
| Slot kosong | ![Rangkaian Asli - Available](https://hackmd.io/_uploads/SykBhDDblx.jpg)     | ![image](https://hackmd.io/_uploads/ryla6PvWxx.png) |
| Slot terisi | ![Rangkaian Asli - Not Available](https://hackmd.io/_uploads/B1JH3wvbxl.jpg) | ![image](https://hackmd.io/_uploads/HJPTaDvblx.png) |

### Performance Evaluation

Sistem parkir otomatis ini menunjukkan bahwa perangkat telah mampu berfungsi dengan baik sesuai tujuan utama pengembangannya, yaitu memberikan informasi ketersediaan parkir secara real-time dan efisien. Meski demikian, masih terdapat ruang pengembangan, khususnya dalam hal meningkatkan akurasi dan konsistensi pembacaan sensor agar sistem lebih andal ketika digunakan dalam skala besar atau lingkungan parkir yang lebih kompleks.

## Conclusion and Future Work

Berdasarkan hasil pengujian, sistem “Parking Lot Sensor” telah mampu berfungsi dengan baik dalam mendeteksi ketersediaan slot parkir secara otomatis menggunakan sensor HC-SR04 dan komunikasi serial antar Arduino. Sistem ini memberikan informasi visual melalui indikator LED, sehingga memudahkan pengemudi untuk mengetahui status parkir tanpa harus berkeliling area. Namun, masih terdapat beberapa kendala teknis seperti keterlambatan respon LED dan pembacaan sensor yang belum sepenuhnya stabil. Untuk pengembangan ke depan, sistem ini dapat ditingkatkan dengan menambah jumlah sensor agar mampu memantau lebih banyak slot parkir secara simultan, sehingga sistem menjadi lebih skalabel dan sesuai diterapkan pada area parkir berskala besar seperti pusat perbelanjaan atau gedung perkantoran.
