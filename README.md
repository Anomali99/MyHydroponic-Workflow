# MyHydroponic Workflow (Server)

Repositori ini berisi konfigurasi server untuk sistem otomasi hidroponik **MyHydroponic**. Infrastruktur ini menggunakan **n8n** sebagai _logic engine_, **Eclipse Mosquitto (MQTT)** untuk komunikasi IoT dengan ESP32, **MariaDB** sebagai basis data, dan **Cloudflare Tunnels** untuk ekspose layanan ke publik secara aman.

---

## 📋 Prasyarat

Sebelum memulai, pastikan Anda memiliki:

1. Server Linux (seperti Ubuntu/Armbian).
2. Akun Cloudflare yang sudah terhubung dengan domain Anda (misal: `anomali99.my.id`).
3. Akses root atau sudo pada server.

---

## 🚀 Panduan Instalasi

### 1. Setup Cloudflare Tunnel

Langkah pertama adalah membuat _tunnel_ agar n8n dan broker MQTT dapat diakses dari luar tanpa perlu membuka port (Port Forwarding) pada _router_.

1. Masuk ke dasbor **Cloudflare Zero Trust** > **Networks** > **Tunnels** (atau **Connectors** untuk tampilan baru).
2. Klik **Create a tunnel**, pilih **Cloudflared**, dan beri nama (misal: `myhydroponic-tunnel`).
3. Salin **Token** yang diberikan oleh Cloudflare (kita akan memasukkannya ke dalam `docker-compose.yml` nanti).
4. Pada tab **Public Hostname**, buat dua rute:
   - **n8n**: Domain `n8n.anomali99.my.id` (atau sesuai keinginan) ➔ Service `http://n8n:5678`
   - **MQTT**: Domain `mqtt.anomali99.my.id` (atau sesuai keinginan) ➔ Service `http://mqtt-broker:9001`

### 2. Instalasi Docker

Jika Docker belum terinstal pada server, jalankan perintah berikut:

```bash
# Menginstal Docker
curl -fsSL [https://get.docker.com](https://get.docker.com) -o get-docker.sh
sh get-docker.sh

# Menginstal Docker Compose
sudo apt-get install docker-compose-plugin -y
```

### 3. Membuat Volume dan Network Docker

Buat _network_ tertutup untuk komunikasi antar kontainer dan _volume_ untuk persistensi basis data.

```bash
docker network create private-net
docker volume create mariadb
```

### 4. Konfigurasi `docker-compose.yml`

Pastikan file `docker-compose.yml` Anda telah memuat variabel lingkungan dan konfigurasi jaringan yang tepat. Berikut adalah penyesuaian yang perlu diperhatikan:

```yaml
# ...
cloudflared:
  # ...
  command: tunnel --no-autoupdate run --token TOKEN_ANDA_DISINI # Masukkan token Cloudflare Anda
  # ...

n8n:
  # ...
  environment:
    - WEBHOOK_URL=https://n8n.anomali99.my.id/
  # ...

mariadb:
  # ...
  environment:
    - MARIADB_ROOT_PASSWORD=password_root_rahasia
    - MARIADB_USER=nama_user_database
    - MARIADB_PASSWORD=password_user_database
  # ...
```

Ganti `TOKEN_ANDA_DISINI`, `password_root_rahasia`, dll. dengan kredensial Anda sendiri.

Jalankan semua kontainer di latar belakang:

```bash
docker compose up -d
```

### 5. Konfigurasi Akun MQTT

Kita membutuhkan 3 akun terpisah pada broker MQTT (untuk ESP32, n8n, dan aplikasi Mobile). Jalankan perintah berikut di dalam kontainer MQTT Anda (asumsi nama kontainernya adalah `mqtt-broker`):

```bash
# Masuk ke dalam kontainer
docker exec -it mqtt-broker sh

# Membuat user untuk ESP (akan diminta memasukkan password)
mosquitto_passwd -c /mosquitto/config/passwd esp_user

# Membuat user untuk n8n (tanpa flag -c agar file tidak tertimpa)
mosquitto_passwd /mosquitto/config/passwd n8n_user

# Membuat user untuk Mobile
mosquitto_passwd /mosquitto/config/passwd mobile_user

# Keluar dari kontainer
exit
```

Catatan: Pastikan `mosquitto.conf` Anda sudah diatur ke `allow_anonymous false` dan mengarah ke file `passwd` tersebut. Setelah selesai, restart kontainer MQTT: docker restart `mqtt-broker`.

### 6. Import Database

Masukkan skema tabel yang ada di file `database/Database.sql` ke dalam kontainer MariaDB:

```bash
# Asumsi nama kontainer adalah 'mariadb'
cat database/Database.sql | docker exec -i mariadb mysql -u root -p'password_root_rahasia'
```

### 7. Setup n8n & Workflow

Setelah semua layanan berjalan, lakukan konfigurasi akhir pada n8n:

1. Buka browser dan akses `https://n8n.anomali99.my.id/`.

2. Selesaikan proses pembuatan akun admin n8n untuk pertama kali.

3. **Instal Library Notifikasi**:
   - Buka menu **Settings** > **Community Nodes**.

   - Klik **Install** dan masukkan npm package name: `@digital-boss/n8n-nodes-google-firebase-notifications`.

   - Klik **Install** dan tunggu hingga selesai.

4. **Buat Credentials**:
   - Buka menu **Credentials** di sebelah kiri.

   - Buat 3 kredensial baru:
     - **MySQL**: Hubungkan ke host `mariadb` (karena dalam satu jaringan `private-net`), masukkan user, password, dan nama database yang disetel di Docker.

     - **MQTT**: Hubungkan ke host `mqtt-broker` port `1883` (atau sesuai konfigurasi), masukkan username n8n_user dan passwordnya.

     - **Firebase**: Masukkan _credentials_ menggunakan data file JSON _Service Account_ dari project Firebase Anda untuk mengaktifkan push notifikasi.

5. **Import Workflow**:
   - Buka menu **Workflows** > klik **Add Workflow**.

   - Klik ikon titik tiga di pojok kanan atas > **Import from File**.

   - Pilih file JSON yang ada di dalam folder `/workflow/` repositori ini.

   - Pastikan semua _node_ yang membutuhkan _credentials_ (seperti node MySQL, MQTT Trigger, dan Firebase) sudah memilih kredensial yang baru saja Anda buat.

   - **Save** dan aktifkan (_toggle_ ke posisi Aktif) workflow tersebut.

---
