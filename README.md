# Squid Forward Proxy Auto-Installer

Auto-installer **Squid forward proxy** tanpa autentikasi dengan proteksi bawaan: blokir jaringan internal dan port rawan abuse. Stabil di **Alpine Linux** dan **Docker Container** — tanpa error *file descriptor*, tanpa masalah *init system*.

## Fitur

- **Zero-config:** instal `squid`, `curl`, `iproute2-ss`, tulis config, lalu self-test HTTP, HTTPS (`CONNECT`), dan blokir internal.
- **Container-friendly:** proses dijalankan langsung dengan `ulimit -n 65535` dan direktori `/run/squid` otomatis, jadi tidak kena `Bad file descriptor`.
- **Security guards:**
  - Blokir IP privat/internal: `10.0.0.0/8`, `127.0.0.0/8`, `169.254.0.0/16`, `172.16.0.0/12`, `192.168.0.0/16`.
  - Blokir port abuse: `25`, `135`, `137`, `138`, `139`, `445`, `6667`.
- **No-cache:** `cache deny all`, hemat RAM dan disk di VPS/container kecil.

## Penggunaan

### 1. Bash (direkomendasikan)

Port default (`3128`):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/myscriptvpn/proxy/main/proxy.sh)
```

Custom port (contoh `3129`):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/myscriptvpn/proxy/main/proxy.sh) -p 3129
```

### 2. `sh` (jika `bash` belum terpasang)

Port default (`3128`):

```bash
curl -fsSL https://raw.githubusercontent.com/myscriptvpn/proxy/main/proxy.sh | sh
```

Custom port (contoh `3129`):

```bash
curl -fsSL https://raw.githubusercontent.com/myscriptvpn/proxy/main/proxy.sh | sh -s -- -p 3129
```

### 3. Instalasi permanen sebagai perintah `prox`

```bash
curl -fsSL https://raw.githubusercontent.com/myscriptvpn/proxy/main/proxy.sh -o /usr/local/bin/prox && chmod +x /usr/local/bin/prox && prox
```

Ganti port kapan saja:

```bash
prox -p 8080
```

## Verifikasi & Troubleshooting

Kalau berhasil, terminal menampilkan:

```text
OK: squid proxy up on 3128 (http+https ok, internal blocked)
```

Cek log akses:

```bash
tail -f /var/log/squid/access.log
```

Cek log error:

```bash
cat /var/log/squid/cache.log
```

Hentikan proxy:

```bash
pkill -9 squid
```

## Catatan

- Port `53` ditolak skrip karena dipakai layanan SlowDNS (`dnstt`).
- Config asli dibackup sekali ke `/etc/squid/squid.conf.orig` sebelum ditimpa.
- Butuh akses `root` (menulis ke `/etc/squid`, `/run/squid`, `/var/log/squid`).
