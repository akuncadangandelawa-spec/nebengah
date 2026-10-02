# 📊 QiPrime Institutional BB + RSI Ranging Strategy [SCORING]

> *"Retail traders trade every signal. Institutional traders trade the highest probability setups."*  
> — QiPrime Institutional AI Advisor

## 📖 Deskripsi
**QiPrime BB + RSI Ranging Strategy [SCORING]** adalah indikator Pine Script v6 tingkat lanjut yang dirancang khusus untuk mengeksploitasi pasar yang sedang *ranging* (konsolidasi) menggunakan logika *Mean Reversion*. 

Berbeda dengan indikator Bollinger Bands + RSI standar yang sering menghasilkan *false signal* (whipsaw) saat pasar *trending*, script ini mengintegrasikan **Sistem Scoring Konfluensi Institusional**. Indikator ini tidak hanya mencari persilangan indikator, tetapi juga memvalidasi jejak *Smart Money* melalui Volume, Price Action (Liquidity Sweep), dan kekuatan tren (ADX).

## 🧠 Filosofi & Logika Institusional
Strategi ini dibangun di atas 3 pilar analisis teknikal institusional:
1. **Statistical Extremes (Bollinger Bands):** Mencari anomali harga di mana *overextension* terjadi, namun gagal bertahan (gagal *breakout*).
2. **Momentum Exhaustion (RSI):** Memastikan bahwa tekanan jual/beli di area ekstrem telah benar-benar habis.
3. **Institutional Footprint (Volume & Wick):** Memvalidasi bahwa pergerakan balik harga didukung oleh absorpsi volume institusional dan sapuan likuiditas (*liquidity sweep*).

---

## 🏆 Sistem Scoring Konfluensi (Maksimal 5 Poin)
Agar trader tidak terjebak dalam sinyal palsu, setiap sinyal BUY/SELL akan dinilai dari **1 hingga 5**. Label sinyal akan berubah warna berdasarkan skor konfluensinya.

| Poin | Kondisi Konfluensi | Penjelasan Institusional |
|:---:|---|---|
| **2** | **Base Logic** | Harga *close* kembali ke dalam BB setelah menembus band + RSI pulih dari area Overbought/Oversold. |
| **+1** | **Volume Absorption** | Volume candle rejection > 1.5x rata-rata volume 20 periode. (Menandakan institusi sedang menyerap likuiditas). |
| **+1** | **Liquidity Sweep (Wick)** | Ekor candle > 50% dari total range candle. (Menandakan *false breakout* / sapuan Stop Loss retail yang kuat). |
| **+1** | **Deep Ranging Market** | ADX < 20. (Memastikan pasar benar-benar *sideways* ketat, bukan sekadar koreksi dalam tren kuat). |

### 🎨 Membaca Label Sinyal:
* 🟢 **Hijau Terang (Score 4 - 5):** *High Conviction*. Semua konfluensi terpenuhi. Setup A+.
* 🟡 **Kuning (Score 3):** *Medium Conviction*. Setup valid, namun ada 1 konfirmasi institusional yang lemah.
* 🟠 **Oranye (Score 2):** *Low Conviction / Warning*. Hanya mengandalkan indikator dasar. Rentan *fakeout*.

---

## ⚙️ SOP Trading & Manajemen Risiko Institusional

Sebagai trader, Anda **TIDAK BOLEH** mengambil semua sinyal. Gunakan Standard Operating Procedure (SOP) berikut:

### 📌 Aturan Entry Berdasarkan Score
* **Score 4-5 (Hijau):** Eksekusi dengan ukuran posisi standar (Risiko 1% - 2% per trade). Stop Loss diletakkan ketat di bawah/atas ekor candle *rejection*.
* **Score 3 (Kuning):** Eksekusi dengan **setengah ukuran posisi** (Risiko 0.5%), ATAU tunggu konfirmasi *Change of Character (ChoCh)* di timeframe yang lebih kecil (LTF).
* **Score 2 (Oranye):** **SKIP / ABBAIKAN.** Biarkan pasar membuktikan dirinya. Disiplin adalah kunci profitabilitas jangka panjang.

### 🎯 Take Profit (Scaling Out)
* **TP 1 (50% Posisi):** Di *Middle Band* (Basis BB / SMA 20). Pindahkan Stop Loss ke *Break Even (BE)*.
* **TP 2 (50% Posisi):** Di *Upper Band* (untuk BUY) atau *Lower Band* (untuk SELL).

### 🚫 Kapan TIDAK Menggunakan Indikator Ini?
* Saat ADX > 25 (Pasar sedang *trending* kuat).
* 30 menit sebelum dan sesudah rilis berita *High Impact* (NFP, CPI, FOMC).
* Jika harga *closing* di luar Bollinger Band selama 3 candle atau lebih (Ini adalah *breakout* tren baru, bukan *mean reversion*).

---

## 🛠️ Panduan Instalasi di TradingView

1. Buka chart di **TradingView**.
2. Klik menu **Pine Editor** di bagian bawah layar.
3. Hapus semua kode default, lalu **Copy-Paste** kode `QiPrime BB + RSI Ranging Strategy [SCORING]` ke dalam editor.
4. Klik **Save** (ikon disket), lalu klik **Add to Chart** (ikon '+').
5. Indikator akan muncul di chart Anda. Klik ikon **Settings (Gear)** untuk menyesuaikan parameter sesuai dengan aset yang Anda tradingkan (Forex/Crypto).

### ⚙️ Pengaturan Parameter yang Disarankan:
* **Forex Major (EURUSD, GBPUSD):** Timeframe M15 atau H1. Biarkan default.
* **Crypto (BTC, ETH):** Timeframe H1 atau H4. Pertimbangkan menaikkan `Volume Spike Multiplier` menjadi `2.0` karena volatilitas crypto yang lebih tinggi.

---

## 📢 Alert Conditions
Script ini dilengkapi dengan alert bawaan. Anda bisa mengatur alert di TradingView khusus untuk sinyal berkualitas tinggi:
* `QiPrime HIGH SCORE BUY`: Hanya memicu jika score BUY >= 4.
* `QiPrime HIGH SCORE SELL`: Hanya memicu jika score SELL >= 4.

---

## ⚠️ Disclaimer
*Indikator ini disediakan "APA ADANYA" untuk tujuan edukasi dan analisis teknikal. QiPrime Institutional AI Advisor tidak bertanggung jawab atas kerugian finansial yang terjadi akibat penggunaan indikator ini. Trading Forex dan Cryptocurrency melibatkan risiko tinggi. Selalu lakukan backtesting dan gunakan manajemen risiko yang ketat (uang yang Anda rela untuk kehilangan) sebelum trading dengan uang sungguhan. Ini bukan nasihat keuangan.*

---
**Dikembangkan oleh:** QiPrime Institutional AI Advisor  
**Versi:** 1.0.0 (Pine Script v6)  
**Fokus:** Mean Reversion, Smart Money Concepts (SMC), Volume Profile, Institutional Risk Management.
