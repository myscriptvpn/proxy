# Squid Forward Proxy Auto-Installer (Alpine / Docker)

Skrip instalasi otomatis **Squid Forward Proxy** ringan tanpa autentikasi dengan proteksi bawaan (memblokir akses ke jaringan lokal/internal dan port rawan penyalahgunaan). Dirancang khusus agar berjalan stabil di lingkungan **Alpine Linux** maupun **Docker Container** tanpa kendala *file descriptor* atau *init system*.

## Fitur Utama
- **Zero-Config & Cepat:** Otomatis menginstal dependensi (`squid`, `curl`, `iproute2-ss`), mengonfigurasi Squid, dan langsung menjalankan pengujian koneksi HTTP, HTTPS (`CONNECT`), serta blokir akses internal.
- **Container-Friendly:** Menggunakan manajemen proses langsung dengan penyesuaian `ulimit` dan direktori `/run/squid` otomatis untuk mencegah error `Bad file descriptor` di Docker.
- **Security Guards:**
  - Memblokir akses ke IP privat/internal (`10.0.0.0/8`, `127.0.0.0/8`, `169.254.0.0/16`, `172.16.0.0/12`, `192.168.0.0/16`).
  - Memblokir port rawan *abuse* (`25`, `135`, `137`, `138`, `139`, `445`, `6667`).
- **No-Cache:** Caching dimatikan (`cache deny all`) untuk menghemat RAM dan penyimpanan disk pada VPS/Container kecil.

---

## Penggunaan Cepat (One-Liner)

### 1. Menggunakan Bash (Direkomendasikan)

**Port Default (`3128`):**
```bash
bash <(curl -fsSL [https://raw.githubusercontent.com/myscriptvpn/proxy/main/proxy.sh](https://raw.githubusercontent.com/myscriptvpn/proxy/main/proxy.sh))
```

**Custom Port (contoh: `3129`):**
```bash
bash <(curl -fsSL [https://raw.githubusercontent.com/myscriptvpn/proxy/main/proxy.sh](https://raw.githubusercontent.com/myscriptvpn/proxy/main/proxy.sh)) -p 3129
```

---

### 2. Menggunakan `sh` (Jika `bash` belum terpasang)

**Port Default (`3128`):**
```bash
curl -fsSL [https://raw.githubusercontent.com/myscriptvpn/proxy/main/proxy.sh](https://raw.githubusercontent.com/myscriptvpn/proxy/main/proxy.sh) | sh
```

**Custom Port (contoh: `3129`):**
```bash
curl -fsSL [https://raw.githubusercontent.com/myscriptvpn/proxy/main/proxy.sh](https://raw.githubusercontent.com/myscriptvpn/proxy/main/proxy.sh) | sh -s -- -p 3129
```

---

### 3. Instalasi Permanen sebagai Perintah `prox`

Pasang skrip ke `/usr/local/bin/prox` agar dapat dijalankan kapan saja cukup dengan mengetik `prox`:

```bash
curl -fsSL [https://raw.githubusercontent.com/myscriptvpn/proxy/main/proxy.sh](https://raw.githubusercontent.com/myscriptvpn/proxy/main/proxy.sh) -o /usr/local/bin/prox && chmod +x /usr/local/bin/prox && prox
```

Untuk mengganti port di kemudian hari:
```bash
prox -p 8080
```

---

## Verifikasi & Troubleshooting

Jika instalasi berhasil, terminal akan menampilkan output:
```text
OK: squid proxy up on 3128 (http+https ok, internal blocked)
```

- **Cek Log Akses:**
  ```bash
  tail -f /var/log/squid/access.log
  ```
- **Cek Log Error / Cache:**
  ```bash
  cat /var/log/squid/cache.log
  ```
- **Hentikan Proxy:**
  ```bash
  pkill -9 squid
  ```

---

## Catatan
- Port `53` diblokir oleh skrip karena dicadangkan untuk layanan SlowDNS (`dnstt`).
- File konfigurasi asli sebelum ditimpa otomatis dicadangkan di `/etc/squid/squid.conf.orig`.
