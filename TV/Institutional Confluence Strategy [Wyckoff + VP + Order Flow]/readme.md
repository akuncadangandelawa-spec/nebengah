# 📊 Institutional Confluence Strategy [Wyckoff + VP + Order Flow]

**Versi:** Pine Script v6  
**Platform:** TradingView  
**Tipe:** Overlay Indicator (Non-Repaint)  
**Kategori:** Smart Money Concepts (SMC) • Wyckoff • Volume Profile • Order Flow

---

## 🎯 Deskripsi

**Institutional Confluence Strategy** adalah indikator trading canggih yang menggabungkan **tiga metodologi analisis institusional** menjadi satu sistem skoring konfluensi. Indikator ini dirancang untuk mendeteksi **titik entry presisi tinggi** yang biasa digunakan oleh institusi besar (Smart Money) di pasar Forex dan Crypto.

Sistem ini menghitung **skor konfluensi (0–100)** dari tiga komponen utama, dan hanya memberikan sinyal entry ketika skor melampaui ambang batas minimum yang ditentukan.

---

## 🧠 Filosofi Strategi

Sinyal entry hanya muncul ketika **ketiga elemen institusional ini selaras**:

| Komponen | Bobot | Peran |
|----------|-------|-------|
| **Wyckoff Structure** | 40 poin | Konteks pasar (akumulasi/distribusi) |
| **Volume Profile** | 30 poin | Lokasi value (POC, VAL, VAH) |
| **Order Flow / Delta** | 30 poin | Konfirmasi tekanan beli/jual |

> 💡 **Prinsip:** Tidak ada satu sinyal pun yang cukup. Konfluensi = Probabilitas tinggi.

---

## 📖 Komponen Analisis

### 1️⃣ Wyckoff Structure (Bobot: 40 poin)

Mendeteksi dua pola klasik Wyckoff:

- **🟢 Spring (Bullish)** — Liquidity sweep di bawah range rendah, diikuti close kembali ke dalam range → indikasi akumulasi institusional.
- **🔴 UTAD (Bearish)** — Upthrust After Distribution, sweep di atas range tinggi, diikuti close kembali ke dalam range → indikasi distribusi.

**Parameter:**
- `Trading Range Lookback` — Periode lookback untuk range (default: 30)
- `Liquidity Sweep Threshold (%)` — Toleransi sweep di luar range (default: 0.5%)

---

### 2️⃣ Volume Profile (Bobot: 30 poin)

Menghitung distribusi volume pada rentang harga tertentu:

- **POC (Point of Control)** — Level harga dengan volume tertinggi
- **VAL (Value Area Low)** — Batas bawah value area
- **VAH (Value Area High)** — Batas atas value area

**Sinyal:**
- Buy zone: harga mendekati **POC atau VAL** (±0.5%)
- Sell zone: harga mendekati **POC atau VAH** (±0.5%)

**Parameter:**
- `Volume Profile Lookback Bars` — Jumlah bar untuk perhitungan (default: 50)
- `Profile Row Resolution` — Resolusi baris histogram (default: 24)
- `Value Area Percentage (%)` — Persentase value area (default: 70%)

---

### 3️⃣ Order Flow & Delta (Bobot: 30 poin)

Mengestimasi tekanan beli/jual berdasarkan **body ratio** candle dan **volume spike**:

- **Buying Imbalance** — Body bullish dominan + volume spike
- **Selling Imbalance** — Body bearish dominan + volume spike
- **Bullish Delta Divergence** — Harga membuat low baru tapi delta menguat
- **Bearish Delta Divergence** — Harga membuat high baru tapi delta melemah

**Parameter:**
- `Volume Spike Factor (vs SMA)` — Faktor volume terhadap SMA 20 (default: 1.3)
- `Delta Divergence SMA Length` — Periode SMA untuk divergensi delta (default: 14)

---

## 🧮 Sistem Skoring

| Kondisi | Poin |
|---------|------|
| Wyckoff Spring / UTAD aktif | **40** |
| Harga di zona VP (buy/sell zone) | **30** |
| Harga di mid range VP | 10 |
| Order flow trigger tunggal | **20** |
| Order flow ganda (imbalance + divergence) | **30** |
| Tidak ada trigger OF | 0 |

**Syarat Sinyal Entry:**
```
Total Score >= 70
+ Wyckoff aktif
+ Order Flow Trigger aktif
+ Cooldown 5 bar sejak sinyal terakhir
```

---

## ⚙️ Cara Menggunakan

### Instalasi di TradingView

1. Buka TradingView → **Pine Editor**
2. Copy seluruh kode indikator
3. Klik **Save** → beri nama
4. Klik **Add to Chart**

### Rekomendasi Penggunaan

| Timeframe | Penggunaan |
|-----------|------------|
| **M15 – H1** | Intraday trading (Forex/Crypto) |
| **H4 – D1** | Swing trading |
| **M5 – M15** | Scalping (hati-hati noise) |

### Interpretasi Sinyal

- **🟢 Segitiga Hijau + Label "BUY ENTRY"** → Potensi long
- **🔴 Segitiga Merah + Label "SELL ENTRY"** → Potensi short
- **Label menampilkan skor** (misal: `Score: 80/100`)

---

## 📊 Dashboard Real-Time

Panel di kanan atas menampilkan status pasar saat ini:

| Metric | Deskripsi |
|--------|-----------|
| **Wyckoff Context** | Spring / UTAD / Neutral |
| **VP Retest Zone** | Near Buy Zone / Near Sell Zone / Mid Range |
| **Order Flow Trigger** | Bullish / Bearish / Neutral |
| **Confluence Score** | Skor total (0–100) |

Warna sel menunjukkan bias:
- 🟢 Hijau = Bullish
- 🔴 Merah = Bearish
- ⚪ Abu-abu = Netral

---

## 🛡️ Manajemen Risiko Institusional

Indikator ini **tidak** memberikan TP/SL. Gunakan aturan berikut:

### Entry
- Entry saat candle sinyal **close** (bukan saat muncul).
- Konfirmasi dengan price action tambahan.

### Stop Loss
- **Buy:** SL di bawah low sweep atau di bawah VAL.
- **Sell:** SL di atas high sweep atau di atas VAH.
- Gunakan buffer 0.2–0.5 × ATR.

### Take Profit
- **TP1:** POC (partial close 50%)
- **TP2:** VAH (buy) / VAL (sell)
- **TP3:** Range high/low Wyckoff

### Position Sizing
- Risiko maksimal **1–2% per trade**.
- Hindari entry jika skor < 80 saat volatilitas tinggi (news).

---

## ✅ Keunggulan

- ✔️ **Non-Repaint** — Sinyal tidak berubah setelah candle close
- ✔️ **Multi-Konfluensi** — 3 metodologi institusional
- ✔️ **Skor Transparan** — Setiap sinyal punya skor terukur
- ✔️ **Real-Time Dashboard** — Status pasar langsung terlihat
- ✔️ **Optimized** — Volume Profile hanya dihitung saat diperlukan (tidak lag)
- ✔️ **Cooldown System** — Mencegah sinyal spam

---

## ⚠️ Disclaimer

> Indikator ini adalah **alat bantu analisis**, bukan jaminan profit.  
> Selalu gunakan **manajemen risiko yang ketat** dan backtest terlebih dahulu di akun demo.  
> Performa masa lalu tidak menjamin hasil di masa depan.  
> Trading mengandung risiko kehilangan modal.

---

## 🔧 Changelog

### v1.0 (Current)
- ✅ Rilis awal
- ✅ Wyckoff Spring/UTAD detection
- ✅ Volume Profile (POC/VAL/VAH) real-time
- ✅ Order Flow imbalance + delta divergence
- ✅ Confluence scoring system
- ✅ Real-time dashboard
- ✅ Non-repaint signal

### Bug Fixes (v1.0)
- 🐛 Fixed: VP hanya dihitung di `barstate.islast` → sekarang efisien
- 🐛 Fixed: Reset Wyckoff salah menggunakan `last_signal_bar`
- 🐛 Fixed: Repaint pada sinyal intra-bar
- 🐛 Fixed: Guard `na` dan pembagian nol
- 🐛 Fixed: Visualisasi VP menggunakan `line.new` update

---

## 📚 Referensi

- **Wyckoff Method** — Richard Wyckoff (1931)
- **Volume Profile** — Market Profile / TPO (CBOT)
- **Order Flow** — Tape Reading & Delta Analysis
- **Smart Money Concepts** — ICT / SMC Community

---

## 👨‍💻 Author

**Institutional AI Advisor**  
Senior Technical Analyst — Smart Money Concepts • Volume Profile • Risk Management

---

## 📞 Support

Jika menemukan bug atau ingin request fitur, sertakan:
1. Screenshot chart
2. Timeframe & pair
3. Nilai input parameter
4. Deskripsi masalah

---

**⚡ Trade Smart. Trade Institutional. ⚡**
