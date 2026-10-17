# AI XAUUSD Analyzer 📈🤖

Aplikasi Android Native production-ready untuk menganalisa chart forex **XAUUSD (OANDA)** menggunakan berbagai model AI (Gemini, OpenAI, Groq, OpenRouter) dengan antarmuka Jetpack Compose Material 3 (Dark Theme Default).

---

## 🌟 Fitur Utama
1. **Interactive TradingView Advanced Chart**:
   - Embed TradingView widget resmi pair `OANDA:XAUUSD`.
   - Selector **Timeframe**: 1m, 5m, 15m, 30m, 1H, 4H, 1D, 1W.
   - Selector Multi-select **Indicators**: EMA 20, EMA 50, EMA 200, RSI, MACD, Bollinger Bands, Volume, Stochastic, Fibonacci.
2. **📸 Snapshot & Analisa Chart**:
   - Ambil snapshot chart WebView menggunakan `PixelCopy` / `Canvas`.
   - Dialog BottomSheet untuk memasukkan instruksi manual atau analisa instan.
3. **💬 AI Chat Interaction & Bubble Chips**:
   - Chat interaktif dengan riwayat pesan dan timestamp.
   - Chip prompt siap pakai ("Analisa trend saat ini", "Cari area support & resistance", "Rekomendasi SL & TP", dsb).
   - Dukungan lampiran gambar dari Galeri dan Kamera.
4. **⚙️ Multi-Provider AI Support**:
   - **Gemini**: Gemini Flash, Gemini Pro Preview, Gemini Flash Preview, dan Custom Gemini API Key.
   - **OpenAI**: Dukungan kustom Base URL, Model Name (misal `gpt-4o-mini`), dan API Key.
   - **Groq**: Free tier (Default Model: `llama-3.3-70b-versatile`).
   - **OpenRouter**: Dukungan model kustom seperti `google/gemini-flash-1.5`.
5. **🎛️ Pengaturan Parameter AI**:
   - Kontrol **Temperature** (0.0 - 2.0).
   - Kontrol **Max Tokens** (256 - 4096).
   - Pengeditan **System Instruction** dengan tombol Reset ke Default.
   - Fitur **Test Endpoint** (ping check latency & konektivitas).
6. **💾 Persistence & Security**:
   - Menyimpan riwayat chat & riwayat analisa ke **Room Database**.
   - Menyimpan konfigurasi & API Key secara aman ke **DataStore Preferences**.

---

## 🛠️ Stack Teknologi
- **Bahasa**: Kotlin 2.0+
- **UI**: Jetpack Compose + Material 3 (Dark Theme)
- **Arsitektur**: MVVM + Clean Architecture
- **Dependency Injection**: Hilt
- **Penyimpanan Lokal**: Room DB & DataStore Preferences
- **Networking**: Retrofit 2 + OkHttp + Gson
- **Image Loading**: Coil
- **Chart**: WebView + HTML5 TradingView Widget

---

## 🚀 Cara Build & Output APK

### Persyaratan System
- Android Studio Jellyfish / Ladybug (atau versi lebih baru)
- JDK 17 / JDK 21
- Android SDK Platform 34

### Langkah Build:
1. Clone repositori ini.
2. Buka proyek di Android Studio.
3. Jalankan Gradle sync.
4. Untuk membuat file APK Debug melalui terminal:
   ```bash
   ./gradlew assembleDebug
   ```
5. APK yang dihasilkan berada di folder `app/build/outputs/apk/debug/app-debug.apk`.

---

## 🔑 Cara Konfigurasi API Key

1. Jalankan aplikasi **AI XAUUSD Analyzer**.
2. Klik ikon **Settings ⚙️** di pojok kanan atas TopAppBar.
3. Pilih **Model AI Active** yang ingin digunakan.
4. Masukkan **API Key** pada kolom provider yang sesuai:
   - **Gemini**: Dapatkan API Key gratis di [Google AI Studio](https://aistudio.google.com/).
   - **Groq**: Dapatkan API Key gratis di [Groq Console](https://console.groq.com/).
   - **OpenAI**: Dapatkan API Key di [OpenAI Platform](https://platform.openai.com/).
   - **OpenRouter**: Dapatkan API Key di [OpenRouter.ai](https://openrouter.ai/).
5. (Opsional) Klik tombol **Test Endpoint** di bagian bawah untuk memastikan API Key dan jaringan berfungsi (akan memunculkan respon `200 OK — Latency: XX ms`).
6. Klik tombol **Simpan** untuk menyimpan pengaturan ke DataStore.
