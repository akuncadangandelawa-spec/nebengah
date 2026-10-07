# 4H/H1 Candle Close — Sweep & Reclaim [Signals]

Indikator TradingView (Pine v6) yang menerjemahkan strategi **"4H Candle Close"**
(SMC/ICT style): bias dari candle HTF (H4/H1), mencari **sweep likuiditas**
terhadap high/low candle HTF sebelumnya, lalu konfirmasi **BOS + FVG** di
timeframe kecil sebelum entry.

> ⚠️ Bukan alat entry otomatis. Ini **alat sinyal + visualisasi** — pemutus
> akhir tetap di tangan trader. Backtest/simulasikan dulu di akun demo.

---

## 1. Syarat Timeframe Chart

| Mode | Chart | Input `HTF` |
|---|---|---|
| Default | **M15** | `240` (H4) |
| Alternatif | **M5** | `60` (H1) |

Larangan:
- Jangan pasang di chart HTF (mis. chart H4) — sinyal tidak akan pernah terbentuk.
- Panel status kiri-atas akan menampilkan **⚠ TF SALAH** jika kombinasi TF keliru.

---

## 2. Alur Trading (7 Langkah)

```
HTF close → Sweep? → BOS → FVG → Entry → TP/SL
   ①②              ③④         ⑤        ⑥
```

Sinyal dievaluasi **hanya saat bar pertama bucket HTF baru** (candle HTF
sebelumnya barusan close) → tidak ada repaint.

| # | Kondisi Alert | Arti | Tindakan Trader |
|---|---|---|---|
| ① | Sinyal LONG | Candle HTF sweep low sebelumnya lalu close kembali naik | Mulai pantau chart |
| ② | Sinyal SHORT | Mirror dari ① | Mulai pantau chart |
| ③ | BOS Bullish | Struktur M15 break ke atas markah pivot | Cari FVG |
| ④ | BOS Bearish | Mirror dari ③ | Cari FVG |
| ⑤ | FVG valid | Kotak FVG terbentuk + setup lolos filter | Pasang limit di mid FVG |
| ⑥ | ENTRY hit | Mid FVG tersentuh | Posisi aktif — jangan garu-garu |
| ⑦ | Setup hangus | Melewati window, tidak entry | Tuning keluar, tunggu HTF baru |

### Cara set alert
1. Klik ikon **⏰ Alarm** → Kondisi = nama indikator ini.
2. Pilih salah satu dari ①–⑦ di daftar.
3. **Ekspirasi**: sesuai kebutuhan (mis. batasi jam market).
4. **Aktivasi**: pilih **"Sekali Per Bar Tutup"**.
   → Semua kondisi memang dievaluasi di bar close, jadi tidak akan flip-flop.

> Pakai alert ⑥ sebagai konfirmasi terakhir sebelum eksekusi — ⑤ hanya bilang
> "siapkan alat", belum "tembak".

---

## 3. Panduan Parameter

| Input | Default | Catatan tuning |
|---|---|---|
| `HTF` | 240 | 60 jika pakai chart M5 |
| `Sweep Buffer (% ATR HTF)` | 5.0 | Naikkan (8–10) jika banyak false-sweep (news) |
| `Reward : Risk` | 2.0 | 2.0–3.0 umum untuk trend day |
| `TP = Liquidity HTF` | ON | OFF jika sering terbalik arah likuiditas |
| `Lookback Liquidity HTF` | 10 | Makin besar = target makin jauh |
| `Spread Estimasi (ticks)` | 2 | EURUSD ≈1, XAUUSD ≈10–30, sesuaikan brokermu |
| `Pivot LTF` | 2 | 3 untuk struktur bersih tapi telat |
| `FVG dalam N bar` | 4 | 6 jika sering busted |
| `Setup hangus dalam N bar` | 8 | Shorten jika sinyal kedaluwarsa cepat |
| `Skip mid FVG dilewati` | ON | OFF = agresif, bisa entry gas |
| `Filter Sesi` | kosong | Mis. `07:00-17:00` (UTC) untuk London+NY |
| `Setup LONG/SHORT` | ON/ON | OFF pilih arah untuk backtest/forward test terpisah |

---

## 4. Legenda Visual di Chart

| Elemen | Warna / Simbol |
|---|---|
| Prev HTF High / Low | Garis **merah / hijau** |
| HTF Open (candle berjalan) | Garis **abu-abu** |
| Box candle HTF sebelumnya | Hijau = bullish close, Merah = bearish close |
| SWEEP HI / LO | Label + **diamond** — likuiditas sudah diambil |
| Sinyal ▲/▼ "HTF-SWEEP" | **Triangle** besar |
| BOS | Garis pivot→break + label **BOS** |
| FVG | Kotak **teal/merah** transparan (auto-menghilang saat ter-seal) |
| ENTRY | Label **flag** teal (LONG) / oranye (SHORT) |
| Setup hangus | Silang kecil |
| Garis Entry (teal) / Stop (merah) / Target (hijau) | Muncul setelah FVG valid |

---

## 5. Workflow Harian

**Pagi (sebelum HTF close)**
- [ ] Cek panel: TF benar? Spread input sesuai broker/instrumen?
- [ ] Filter Sesi sesuai jam sibukmu (opsional).

**Saat alert ①/② bunyi**
- [ ] Tunggu ③/④ (BOS), jangan entry dulu.
- [ ] ⑤ bunyi → cek garis E/S/T di chart; entry = **mid FVG**.
- [ ] Risiko: max **0.5–1%** equity; SL **di luar low/high candle HTF sinyal**.
- [ ] ⑥ bunyi → posisi aktif; biarkan jalan sampai TP/SL.
- [ ] Kalau ⑦ → tidak apa-apa, nafas; tunggu HTF bundel berikutnya.

**Malam (jurnal)**
- [ ] Catat: pair, arah, waktunya HTF, TP/SL, hasil, screenshot chart.

---

## 6. FAQ

**Q: Sinyal tidak pernah muncul.**
A: Cek (1) TF chart harus M15/M5, (2) `Setup LONG/SHORT` ON, (3) candle HTF
sebelumnya harus benar-benar sweep + reclaim — memang sinyal ini selektif.
Turunkan `Sweep Buffer` ke 0–2 untuk versi paling longgar.

**Q: Panel bilang "TF SALAH".**
A: Kombinasi chart↔HTF salah. M15 → 240, M5 → 60.

**Q: Kenapa FVG kadang nggak muncul meski BOS sudah ada?**
A: Minimal 3 candle gap dan ukuran gap harus ≥ threshold. Setup hangus setelah
window `FVG dalam N bar` lewat — normal.

**Q: Bisa bot otomatis?**
A: Belum dari indikator ini (sinyal-only). Webhook bisa dirantai via
alertconditions + strategy runner di luar TradingView (Python/MT5 EA terpisah).

---

## 7. Disclaimer

Dibagikan untuk tujuan edukasi/pengujian. **Tidak ada jaminan profit.**
Hasil visual di chart ≠ hasil live (slippage, spread dinamis, lonjakan berita).
Selalu uji di demo minimal 2–4 minggu sebelum uang nyata. Kelola risiko sendiri.
