# QiPrime Institutional Signal Engine PRO v2

**Versi:** 2.0
**Platform:** TradingView — Pine Script v6
**Tipe:** Indicator Overlay (bukan strategy)

---

## 📖 Deskripsi

**QiPrime Institutional Signal Engine PRO v2** adalah indikator sinyal trading multi-konfluensi yang menggabungkan konsep **trend following**, **momentum**, **Smart Money Concepts (SMC)**, dan **Volume Profile** dalam satu engine terpadu. Setiap sinyal diberi **skor kualitas 0–100** berdasarkan seberapa banyak faktor konfluensi yang selaras, sehingga trader dapat memfilter setup berdasarkan kekuatan sinyal.

Indikator ini dirancang untuk timeframe menengah (M15 – H4) pada instrumen likuid seperti forex major, XAUUSD, dan indeks.

---

## ✨ Fitur Utama

| Fitur | Deskripsi |
|---|---|
| **Supertrend + ZLEMA** | Filter arah tren dan momentum jangka pendek |
| **ADX / DMI** | Konfirmasi kekuatan tren & dominasi buyer/seller |
| **HTF EMA200** | Filter bias timeframe lebih tinggi (anti-repaint) |
| **BOS / CHoCH** | Deteksi struktur pasar (Break of Structure & Change of Character) |
| **Liquidity Sweep** | Deteksi sweeping swing high/low sebagai sinyal manipulasi |
| **Fair Value Gap (FVG)** | Deteksi imbalance harga dengan filter ukuran minimum |
| **Order Block (OB)** | Deteksi, gambar, dan mitigasi OB secara otomatis |
| **Volume Profile Rolling** | POC, VAH, VAL dari `vpBars` bar terakhir |
| **Skor Konfluensi** | Skor 0–100 per arah (Buy/Sell) |
| **Risk Management** | Hitung SL, TP, dan **lot size** otomatis |
| **Preset Mode** | Loose / Balanced / Tight / Custom |
| **Tabel Info** | Ringkasan status pasar & sinyal terakhir |

---

## 🚀 Cara Menggunakan

### 1. Instalasi
1. Buka TradingView → **Pine Editor**
2. Buat script baru → paste seluruh isi file `.pine`
3. Klik **Save** → **Add to Chart**

### 2. Konfigurasi Cepat (Preset)

| Preset | Min Score | Jendela Konfirmasi | Cocok untuk |
|---|---|---|---|
| **Loose** | 40 | 7 bar | Scalping, sinyal lebih sering |
| **Balanced** | 55 | 5 bar | Intraday (default) |
| **Tight** | 70 | 3 bar | Swing, sinyal lebih selektif |
| **Custom** | manual | manual | Kontrol penuh |

### 3. Membaca Sinyal

Sinyal **BUY** muncul saat:
- Tren Supertrend bullish
- Harga di atas ZLEMA
- Harga di atas HTF EMA200 (jika diaktifkan)
- ADX > minimum dan DI+ > DI- (jika diaktifkan)
- Terjadi BOS/CHoCH bullish dalam `sigWin` bar terakhir
- **Skor Buy ≥ Min Score**

Sinyal **SELL** adalah kebalikannya.

---

## 🎛️ Parameter Utama

### Preset
- `Preset` — Loose / Balanced / Tight / Custom
- `Wajib HTF EMA200`, `Wajib ADX` — filter keras
- `Minimum Score`, `Jendela konfirmasi` — hanya aktif saat Custom

### Trend & Momentum
- `Supertrend ATR` (10), `Supertrend Multiplier` (3.0)
- `ZLEMA Length` (20)
- `ADX Length` (14), `ADX Minimum` (25)
- `HTF Timeframe` (60) — **harus > TF chart**
- `Volume SMA` (20)
- `ATR Length` (14), `ATR Expansion Mult` (1.1)

### Smart Money Concepts
- `Swing Length` (5) — sensitivitas pivot
- `Umur maks. swing untuk sweep` (60 bar)
- `FVG minimum (x ATR)` (0.3)
- `OB lookback maks.` (50 bar), `Jumlah OB aktif maks.` (6)

### Volume Profile
- `Jumlah bar profil` (150)
- `Jumlah baris (bin)` (24)
- `Value Area %` (70)
- `Lebar histogram` (30%)

### Manajemen Risiko
- `Buffer SL di luar swing (x ATR)` (0.2)
- `SL ATR (jika swing tidak valid)` (1.5)
- `Batas jarak SL maks. (x ATR)` (3.0)
- `Risk:Reward` (2.0)
- `Ekuitas akun` (10000)
- `Risiko per trade (%)` (1.0)
- `Contract size per 1 lot` (100000 untuk forex, **100 untuk XAUUSD**)

---

## 🧮 Sistem Skor (0–100)

| Komponen | Bobot | Arah |
|---|---|---|
| Struktur (BOS/CHoCH) | 25 | Buy / Sell |
| Volume > SMA | 15 | Buy / Sell |
| ATR Expansion | 10 | Buy / Sell |
| Liquidity Sweep | 15 | Buy / Sell |
| FVG | 10 | Buy / Sell |
| Retest Order Block | 15 | Buy / Sell |
| Konfirmasi Volume Profile | 10 | Buy / Sell |
| **Total** | **100** | |

> **Catatan:** Filter keras (tren, ZLEMA, HTF, ADX) **tidak** dihitung dalam skor — sudah menjadi syarat wajib sinyal muncul.

---

## 💰 Rumus Position Sizing

```
SL_Buy  = max(SwingLow - ATR·buf, Close - ATR·maxSL)
TP_Buy  = Close + (Close - SL)·RR

Lot     = (Equity × Risk% ÷ 100) ÷ ((Close - SL) × ContractSize)
```

Untuk **XAUUSD**, ubah `Contract size` menjadi `100` (bukan 100000).

> ⚠️ Perhitungan lot akurat hanya jika mata uang kuotasi = mata uang akun.

---

## 🔔 Alert

Dua alertcondition tersedia:

- **QiPrime BUY** — memicu payload JSON dengan field: `signal`, `ticker`, `price`, `score`, `sl`, `tp`, `tf`
- **QiPrime SELL** — payload serupa

**Cara set:** Klik ikon lonceng → pilih indikator → pilih **Once Per Bar Close**.

Contoh payload:
```json
{
  "signal": "BUY",
  "ticker": "EURUSD",
  "price": 1.0845,
  "score": 75,
  "sl": 1.0810,
  "tp": 1.0915,
  "tf": "60"
}
```

---

## 📊 Tabel Info (Top Right)

Menampilkan real-time:
- Preset & Minimum Score
- Status Supertrend, Struktur, HTF EMA200
- Nilai ADX
- Skor Buy / Sell
- POC, VAH, VAL
- Sinyal terakhir + skor
- Entry / SL / TP
- Ukuran lot rekomendasi

---

## ⚠️ Catatan & Peringatan

1. **Anti-Repaint** — HTF EMA memakai `[1]` + `lookahead_on`. Volume Profile memakai bar `[1..vpBars]`. Sinyal final dihitung saat `barstate.isconfirmed`.
2. **Timeframe HTF** harus lebih tinggi dari TF chart, jika tidak nilai EMA tidak akan update.
3. **Volume Profile & OB boxes** hanya digambar pada bar terakhir untuk hemat resource.
4. **Backtest manual** disarankan sebelum live — sinyal tidak menjamin profit.
5. Indikator ini adalah **alat bantu keputusan**, bukan ajakan trading. Selalu gunakan manajemen risiko.

---

## 🐛 Troubleshooting

| Masalah | Penyebab | Solusi |
|---|---|---|
| Tidak ada sinyal muncul | Preset Tight / filter terlalu ketat | Coba Preset Loose atau kurangi Min Score |
| Sinyal muncul terlalu sering | Min Score rendah | Naikkan Min Score atau ubah ke Tight |
| Lot size aneh (0.00 atau besar) | Contract size salah | Sesuaikan dengan instrumen (XAUUSD = 100) |
| Volume Profile kosong | Bar chart < `vpBars + 1` | Turunkan `Jumlah bar profil` |

---

## 📝 Changelog

**v2.0**
- Migrasi ke Pine Script v6
- Perbaikan error `nz()` pada `series bool`
- Deteksi BOS/CHoCH berbasis state
- Mitigasi Order Block otomatis
- Preset Loose/Balanced/Tight
- Volume Profile rolling dengan Value Area

---

## 📄 Lisensi

Bebas digunakan untuk trading pribadi. Dilarang menjual ulang tanpa modifikasi signifikan.

**Disclaimer:** Trading mengandung risiko. Performa masa lalu tidak menjamin hasil di masa depan.
