//+------------------------------------------------------------------+
//|                                    EMA_MACD_BOS_Scalper_EA.mq5   |
//|       v1.30  FULL REWRITE: Scalper (ATR-SL) + Trend (Swing-SL)   |
//|  Progressive trailing, 2-bar exit, trend strength, fill guard,   |
//|  Telegram queue, file persistence, stats rebuild, mode switch.   |
//+------------------------------------------------------------------+
#property copyright   "DelawaMC"
#property link        ""
#property version     "1.30"
#property description "EMA_MACD_BOS EA v1.30 - Scalper/Trend Full Production"
#property description "PENTING: whitelist https://api.telegram.org di Tools > Options > Expert Advisors"

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| ENUM                                                             |
//+------------------------------------------------------------------+
enum ENUM_TRAIL_MODE
  {
   TRAIL_ATR  = 0,   // ATR Trailing Stop
   TRAIL_EMA8 = 1    // EMA 8 Trailing Stop
  };

enum ENUM_STRATEGY_MODE
  {
   MODE_SCALPER = 0, // Scalper (ATR-SL, tanpa runner)
   MODE_TREND   = 1  // Trend Follower (Swing-SL, runner + progressive trail)
  };

enum ENUM_ON_OFF_AUTO
  {
   OA_AUTO = 0,  // Ikuti mode
   OA_ON   = 1,  // Paksa AKTIF
   OA_OFF  = 2   // Paksa NONAKTIF
  };

enum ENUM_MARKET_STATUS
  {
   MS_ACTIVE          = 0,
   MS_SPREAD_HIGH     = 1,
   MS_OUT_OF_SESSION  = 2,
   MS_TRADE_DISABLED  = 3,
   MS_DAILY_HALTED    = 4,
   MS_PAUSED          = 5
  };

//+------------------------------------------------------------------+
//| INPUT PARAMETER                                                  |
//+------------------------------------------------------------------+
input group "=== MODE STRATEGI ==="
input ENUM_STRATEGY_MODE InpMode            = MODE_SCALPER;
input int    InpMaxPositions     = 1;
input int    InpMaxTradesPerDay  = 0;
input bool   InpSignalOnClosedBar= true;

input group "=== ORDER & LOT ==="
input ulong  InpMagic            = 20260711;
input double InpLotSize          = 0.03;
input int    InpDeviation        = 30;
input string InpComment          = "EMA_MACD_BOS";
input int    InpPointsPerPip     = 0;
input double InpMaxFillSlippage  = 1.5;

input group "=== PROTEKSI RISIKO ==="
input double InpMaxDailyLossPct   = 3.0;
input double InpMaxDailyProfitPct = 0.0;
input bool   InpUseRiskLot        = false;
input double InpRiskPercent       = 1.0;
input double InpMinFreeMarginPct  = 20.0;
input int    InpConsecLossHalt    = 0;
input int    InpConsecLossPauseMin= 120;
input int    InpStatLookbackDays  = 30;
input bool   InpClearGVOnRemove   = false;

input group "=== INDIKATOR ==="
input int    InpEMAMajor         = 50;
input int    InpEMAFast          = 8;
input int    InpEMASlow          = 13;
input int    InpMACDFast         = 12;
input int    InpMACDSlow         = 26;
input int    InpMACDSignal       = 9;
input double InpMACDThrNorm      = 0.0;
input int    InpBOSLookback      = 0;
input int    InpBOSTolerancePoints = 2;
input int    InpATRPeriod        = 14;
input double InpMinATRSpreadRatio= 3.0;
input double InpMinEMASepATR     = 0.0;
input double InpMinRangeATR      = 0.0;
input double InpMinTrendSlope    = 0.0;
input ENUM_ON_OFF_AUTO InpUseEMA50 = OA_AUTO;

input group "=== STOP LOSS ==="
input int    InpSwingLookback    = 5;
input double InpSLBufferPips     = 1.0;
input double InpMinSLPips        = 2.0;
input double InpMaxSLPips        = 0.0;
input double InpScalpSLMult      = 0.0;

input group "=== TP & TRAILING ==="
input double InpTP1RR            = 0.0;
input double InpTP1MinPips       = 2.0;
input double InpPartialPercent   = 0.0;
input ENUM_ON_OFF_AUTO InpUseRunner  = OA_AUTO;
input double InpBEPlusPips       = 1.0;
input ENUM_TRAIL_MODE InpTrailMode   = TRAIL_ATR;
input double InpATRMult          = 0.0;
input double InpTrailBufferPips  = 1.0;
input double InpTrailStepPips    = 0.5;
input double InpTrailStartR      = 0.0;
input ENUM_ON_OFF_AUTO InpExitOnCross = OA_AUTO;

input group "=== FILTER KEAMANAN ==="
input bool   EnableSpreadFilter  = true;
input int    MaxSpread_Points    = 30;
input bool   EnableTimeFilter    = true;
input int    InpStartHour        = 8;
input int    InpEndHour          = 20;
input bool   EnableTradePerBar   = true;
input int    InpMaxTradesPerBar  = 1;
input bool   EnableInvalidation  = true;
input int    InpInvalidationBars = 0;
input int    InpMaxReconcileMs   = 500;
input int    InpDragTimeoutMs    = 2000;

input group "=== DASHBOARD ==="
input bool   InpShowPanel        = true;
input int    InpPanelX           = 20;
input int    InpPanelY           = 30;

input group "=== TELEGRAM ==="
input bool   EnableTelegram      = false;
input string TelegramToken       = "";
input string TelegramChatID      = "";

//+------------------------------------------------------------------+
//| STRUKTUR DATA                                                    |
//+------------------------------------------------------------------+
struct SIndData
  {
   double ema50, ema8, ema13;
   double hist;
   double atr, close;
   double hh, ll;
   double swingLow, swingHigh;
  };

struct STracked
  {
   ulong    posId;
   datetime openTime;
   double   initVol;
   double   entry;
   double   slPips;
   double   tp1Pips;
   double   beLevel;
   int      type;
   int      stage;
   bool     beDone;
   string   reason;
   datetime missSince;
  };

//+------------------------------------------------------------------+
//| GLOBAL VARIABEL                                                  |
//+------------------------------------------------------------------+
CTrade   g_trade;

int      g_hEMA50 = INVALID_HANDLE;
int      g_hEMA8  = INVALID_HANDLE;
int      g_hEMA13 = INVALID_HANDLE;
int      g_hMACD  = INVALID_HANDLE;
int      g_hATR   = INVALID_HANDLE;

STracked g_pos[];

int      g_wins = 0, g_losses = 0, g_breakeven = 0;
string   g_gvKey = "";

datetime g_barTime   = 0;
int      g_barTrades = 0;
datetime g_entryBar  = 0;
int      g_pointsPerPip = 10;
SIndData g_cacheD;
int      g_cacheSig = 0;
datetime g_cacheBar = 0;

double   g_dayStartBalance = 0.0;
datetime g_dayStartStamp   = 0;
bool     g_tradingHalted   = false;
bool     g_profitHalted    = false;
int      g_tradesToday     = 0;
int      g_consecLoss      = 0;
datetime g_pauseUntil      = 0;

ulong    g_lastReconcileMs = 0;
ulong    g_lastDragMs      = 0;
bool     g_pendingReconcile = false;

//--- resolved mode params
double   g_tp1RR, g_partialPct, g_atrMult, g_macdThr, g_minEMASep;
double   g_maxSLPips, g_minSLPips, g_trailStartR, g_minTrendSlope, g_scalpSLMult;
int      g_invalBars, g_bosLookback, g_maxTradesDay, g_consecHalt;
bool     g_useRunner, g_exitOnCross, g_useEMA50;

//--- telegram queue
string   g_tgQueue[];

//--- dashboard
#define PFX        "EMB_"
#define PANEL_W    380
#define HDR_H      26
#define ROW_H      20
#define ROW_COUNT  13

int      g_panelX = 20, g_panelY = 30;
bool     g_dragging = false, g_prevDown = false;
int      g_offX = 0, g_offY = 0;
long     g_origScroll = 1, g_origMouseEvt = 0;
datetime g_lastPanelUpdate = 0;

//+------------------------------------------------------------------+
//| UTILITAS DASAR                                                   |
//+------------------------------------------------------------------+
double PipSize() { return (double)g_pointsPerPip * _Point; }

int VolDigits(const double step)
  {
   int d = 0; double s = step;
   while(d < 8 && MathAbs(s - MathRound(s)) > 1e-9) { s *= 10.0; d++; }
   return d;
  }

double FloorVol(const double v)
  {
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double mx   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(step <= 0.0) step = 0.01;
   double r = MathFloor(v / step + 1e-9) * step;
   if(r > mx) r = mx;
   return NormalizeDouble(r, VolDigits(step));
  }

double MinStopDist()
  {
   double stops  = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double freeze = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   double sp     = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   return (MathMax(stops, freeze) + sp + 1.0) * _Point;
  }

double GetBuf(const int handle, const int bufIdx, const int shift)
  {
   double a[]; ArraySetAsSeries(a, true);
   if(CopyBuffer(handle, bufIdx, shift, 1, a) != 1) return 0.0;
   return a[0];
  }

bool RetOK(const uint rc)
  {
   return (rc == TRADE_RETCODE_DONE || rc == TRADE_RETCODE_PLACED || rc == TRADE_RETCODE_DONE_PARTIAL);
  }

bool IsMarketOpen()
  {
   ENUM_SYMBOL_TRADE_MODE tm = (ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE);
   if(tm == SYMBOL_TRADE_MODE_DISABLED) return false;
   datetime lastTick = (datetime)SymbolInfoInteger(_Symbol, SYMBOL_TIME);
   if(lastTick > 0 && TimeCurrent() - lastTick > 300) return false;
   return true;
  }

//+------------------------------------------------------------------+
//| TELEGRAM - queue non-blocking                                     |
//+------------------------------------------------------------------+
string UrlEncode(const string s)
  {
   uchar b[];
   int n = StringToCharArray(s, b, 0, WHOLE_ARRAY, CP_UTF8);
   string out = "";
   for(int i = 0; i < n - 1; i++)
     {
      uchar c = b[i];
      if((c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
         c == '-' || c == '_' || c == '.' || c == '~')
         out += CharToString(c);
      else
         out += StringFormat("%%%02X", c);
     }
   return out;
  }

void TgEnqueue(const string text)
  {
   if(!EnableTelegram) return;
   if(MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_OPTIMIZATION)) return;
   int n = ArraySize(g_tgQueue);
   if(n >= 50) return;
   ArrayResize(g_tgQueue, n + 1);
   g_tgQueue[n] = text;
  }

void SendTelegram(const string text)
  {
   if(!EnableTelegram) return;
   if(MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_OPTIMIZATION)) return;
   if(StringLen(TelegramToken) < 10 || StringLen(TelegramChatID) < 1)
     { Print("Telegram: Token/Chat ID belum diisi."); return; }
   string url  = "https://api.telegram.org/bot" + TelegramToken + "/sendMessage";
   string body = "chat_id=" + UrlEncode(TelegramChatID) + "&text=" + UrlEncode(text);
   char post[], res[];
   string resHeaders;
   int len = StringToCharArray(body, post, 0, WHOLE_ARRAY, CP_UTF8);
   if(len > 0) ArrayResize(post, len - 1);
   string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
   ResetLastError();
   int code = WebRequest("POST", url, headers, 2000, post, res, resHeaders);
   if(code == -1)
      PrintFormat("Telegram: WebRequest gagal err=%d (whitelist URL)", GetLastError());
   else if(code != 200)
      PrintFormat("Telegram: HTTP %d", code);
  }

void TgPump()
  {
   int n = ArraySize(g_tgQueue);
   if(n == 0) return;
   SendTelegram(g_tgQueue[0]);
   for(int i = 0; i < n - 1; i++) g_tgQueue[i] = g_tgQueue[i + 1];
   ArrayResize(g_tgQueue, n - 1);
  }

//+------------------------------------------------------------------+
//| PERSISTENSI STATUS (file)                                         |
//+------------------------------------------------------------------+
string StateFileName()
  {
   return "EMB_" + IntegerToString((long)InpMagic) + "_" + _Symbol + ".state";
  }

void SaveDailyState()
  {
   if(MQLInfoInteger(MQL_TESTER)) return;
   int h = FileOpen(StateFileName(), FILE_WRITE | FILE_CSV | FILE_COMMON, ';');
   if(h == INVALID_HANDLE) return;
   FileWrite(h, "DDST",  (double)g_dayStartStamp);
   FileWrite(h, "DDSB",  g_dayStartBalance);
   FileWrite(h, "HALT",  g_tradingHalted ? 1.0 : 0.0);
   FileWrite(h, "PHALT", g_profitHalted ? 1.0 : 0.0);
   FileWrite(h, "TTD",   (double)g_tradesToday);
   FileWrite(h, "CL",    (double)g_consecLoss);
   FileWrite(h, "PAUSE", (double)g_pauseUntil);
   FileClose(h);
  }

void LoadDailyState()
  {
   if(MQLInfoInteger(MQL_TESTER)) return;
   int h = FileOpen(StateFileName(), FILE_READ | FILE_CSV | FILE_COMMON, ';');
   if(h == INVALID_HANDLE) return;
   while(!FileIsEnding(h))
     {
      string key = FileReadString(h);
      if(key == "") continue;
      double val = FileReadDouble(h);
      if(key == "DDST")  g_dayStartStamp   = (datetime)val;
      if(key == "DDSB")  g_dayStartBalance = val;
      if(key == "HALT")  g_tradingHalted   = (val > 0.5);
      if(key == "PHALT") g_profitHalted    = (val > 0.5);
      if(key == "TTD")   g_tradesToday     = (int)val;
      if(key == "CL")    g_consecLoss      = (int)val;
      if(key == "PAUSE") g_pauseUntil      = (datetime)val;
     }
   FileClose(h);
  }

//+------------------------------------------------------------------+
//| REBUILD STATISTIK DARI HISTORY                                    |
//+------------------------------------------------------------------+
void RebuildStatsFromHistory()
  {
   g_wins = 0; g_losses = 0; g_breakeven = 0; g_consecLoss = 0;

   datetime from = TimeCurrent() - (datetime)InpStatLookbackDays * 86400;
   if(!HistorySelect(from, TimeCurrent())) return;

   ulong    pid[];
   double   pnet[];
   datetime pclose[];
   int      pn = 0;

   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
     {
      ulong dt = HistoryDealGetTicket(i);
      if(dt == 0) continue;
      if(HistoryDealGetString(dt, DEAL_SYMBOL) != _Symbol) continue;
      if((ulong)HistoryDealGetInteger(dt, DEAL_MAGIC) != InpMagic) continue;
      long en = HistoryDealGetInteger(dt, DEAL_ENTRY);
      if(en != DEAL_ENTRY_OUT && en != DEAL_ENTRY_OUT_BY && en != DEAL_ENTRY_INOUT) continue;

      ulong    id  = (ulong)HistoryDealGetInteger(dt, DEAL_POSITION_ID);
      double   net = HistoryDealGetDouble(dt, DEAL_PROFIT) +
                     HistoryDealGetDouble(dt, DEAL_SWAP) +
                     HistoryDealGetDouble(dt, DEAL_COMMISSION) +
                     HistoryDealGetDouble(dt, DEAL_FEE);
      datetime ct  = (datetime)HistoryDealGetInteger(dt, DEAL_TIME);

      int idx = -1;
      for(int k = 0; k < pn; k++) if(pid[k] == id) { idx = k; break; }
      if(idx < 0)
        {
         ArrayResize(pid, pn+1); ArrayResize(pnet, pn+1); ArrayResize(pclose, pn+1);
         pid[pn] = id; pnet[pn] = net; pclose[pn] = ct; pn++;
        }
      else
        { pnet[idx] += net; if(ct > pclose[idx]) pclose[idx] = ct; }
     }

   for(int k = 0; k < pn; k++)
     {
      if(pnet[k] > 0.0)      g_wins++;
      else if(pnet[k] < 0.0) g_losses++;
      else                   g_breakeven++;
     }

   bool used[];
   ArrayResize(used, pn);
   for(int k = 0; k < pn; k++) used[k] = false;
   bool counting = true;
   for(int step = 0; step < pn; step++)
     {
      int best = -1; datetime bt = 0;
      for(int k = 0; k < pn; k++)
         if(!used[k] && pclose[k] > bt) { bt = pclose[k]; best = k; }
      if(best < 0) break;
      used[best] = true;
      if(counting) { if(pnet[best] < 0.0) g_consecLoss++; else counting = false; }
     }
   PrintFormat("Rebuild statistik: %dW/%dL/%dBE | consecLoss=%d", g_wins, g_losses, g_breakeven, g_consecLoss);
  }

//+------------------------------------------------------------------+
//| FILTER & STATUS                                                  |
//+------------------------------------------------------------------+
bool IsInSession()
  {
   if(!EnableTimeFilter) return true;
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   int h = dt.hour;
   if(InpStartHour == InpEndHour) return true;
   if(InpStartHour < InpEndHour) return (h >= InpStartHour && h < InpEndHour);
   return (h >= InpStartHour || h < InpEndHour);
  }

void UpdateDailyState()
  {
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime todayStart = StructToTime(dt);
   if(g_dayStartStamp != todayStart)
     {
      g_dayStartStamp   = todayStart;
      g_dayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      g_tradingHalted   = false;
      g_profitHalted    = false;
      g_tradesToday     = 0;
      PrintFormat("Daily state reset | StartBalance=%.2f", g_dayStartBalance);
      SaveDailyState();
     }
  }

bool CheckDailyGuard()
  {
   if(g_dayStartBalance <= 0.0) return true;
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   if(InpMaxDailyLossPct > 0.0 && !g_tradingHalted)
     {
      double ddPct = (g_dayStartBalance - eq) / g_dayStartBalance * 100.0;
      if(ddPct >= InpMaxDailyLossPct)
        {
         g_tradingHalted = true;
         TgEnqueue(StringFormat("KILL-SWITCH DD HARIAN\nDD: %.2f%% (limit %.2f%%)", ddPct, InpMaxDailyLossPct));
         SaveDailyState();
        }
     }
   if(InpMaxDailyProfitPct > 0.0 && !g_profitHalted)
     {
      double pfPct = (eq - g_dayStartBalance) / g_dayStartBalance * 100.0;
      if(pfPct >= InpMaxDailyProfitPct)
        {
         g_profitHalted = true;
         TgEnqueue(StringFormat("TARGET PROFIT HARIAN\nProfit: %.2f%% (limit %.2f%%)", pfPct, InpMaxDailyProfitPct));
         SaveDailyState();
        }
     }
   return (!g_tradingHalted && !g_profitHalted);
  }

ENUM_MARKET_STATUS GetMarketStatus()
  {
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED) ||
      !AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) ||
      SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_DISABLED)
      return MS_TRADE_DISABLED;
   if(g_tradingHalted || g_profitHalted) return MS_DAILY_HALTED;
   if(g_pauseUntil > 0 && TimeCurrent() < g_pauseUntil) return MS_PAUSED;
   if(EnableSpreadFilter && (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > MaxSpread_Points)
      return MS_SPREAD_HIGH;
   if(!IsInSession()) return MS_OUT_OF_SESSION;
   return MS_ACTIVE;
  }

string StatusText(const ENUM_MARKET_STATUS s)
  {
   switch(s)
     {
      case MS_ACTIVE:         return "Active";
      case MS_SPREAD_HIGH:    return "Spread Too High";
      case MS_OUT_OF_SESSION: return "Out of Session";
      case MS_DAILY_HALTED:   return "Daily Halt";
      case MS_PAUSED:         return "Paused (consec loss)";
      default:                return "Trading Disabled";
     }
  }

bool TradesPerBarOK()
  {
   datetime bt = iTime(_Symbol, _Period, 0);
   if(bt != g_barTime) { g_barTime = bt; g_barTrades = 0; }
   if(!EnableTradePerBar) return true;
   return (g_barTrades < InpMaxTradesPerBar);
  }

bool TradesPerDayOK()
  {
   return (g_maxTradesDay <= 0 || g_tradesToday < g_maxTradesDay);
  }

//+------------------------------------------------------------------+
//| SWING DETECTION (pivot close-based)                               |
//+------------------------------------------------------------------+
double FindSwingLow(const int sh, const MqlRates &r[], const int count, const double ref)
  {
   int size = ArraySize(r), arms = 2;
   double best = 0.0; bool found = false;
   for(int i = sh + arms; i <= sh + count - arms; i++)
     {
      if(i - arms < 0 || i + arms >= size) continue;
      bool pivot = true;
      for(int k = 1; k <= arms; k++)
         if(r[i].close > r[i-k].close || r[i].close > r[i+k].close) { pivot = false; break; }
      if(!pivot || r[i].low >= ref) continue;
      if(!found || r[i].low > best) { best = r[i].low; found = true; }
     }
   if(found) return best;
   double lows[]; int m = 0;
   for(int i = sh; i < sh + count && i < size; i++)
     { ArrayResize(lows, m+1); lows[m++] = r[i].low; }
   if(m == 0) return 0.0;
   ArraySort(lows);
   return (m >= 2) ? lows[1] : lows[0];
  }

double FindSwingHigh(const int sh, const MqlRates &r[], const int count, const double ref)
  {
   int size = ArraySize(r), arms = 2;
   double best = 0.0; bool found = false;
   for(int i = sh + arms; i <= sh + count - arms; i++)
     {
      if(i - arms < 0 || i + arms >= size) continue;
      bool pivot = true;
      for(int k = 1; k <= arms; k++)
         if(r[i].close < r[i-k].close || r[i].close < r[i+k].close) { pivot = false; break; }
      if(!pivot || r[i].high <= ref) continue;
      if(!found || r[i].high < best) { best = r[i].high; found = true; }
     }
   if(found) return best;
   double highs[]; int m = 0;
   for(int i = sh; i < sh + count && i < size; i++)
     { ArrayResize(highs, m+1); highs[m++] = r[i].high; }
   if(m == 0) return 0.0;
   ArraySort(highs);
   return (m >= 2) ? highs[m-2] : highs[m-1];
  }

//+------------------------------------------------------------------+
//| DATA & SINYAL                                                     |
//+------------------------------------------------------------------+
bool LoadData(const int sh, SIndData &d)
  {
   int need = MathMax(g_bosLookback, InpSwingLookback) + sh + 4;
   MqlRates r[]; ArraySetAsSeries(r, true);
   if(CopyRates(_Symbol, _Period, 0, need, r) < need) return false;

   double b50[], b8[], b13[], bm[], bs[], ba[];
   ArraySetAsSeries(b50,true); ArraySetAsSeries(b8,true); ArraySetAsSeries(b13,true);
   ArraySetAsSeries(bm,true);  ArraySetAsSeries(bs,true);  ArraySetAsSeries(ba,true);

   if(CopyBuffer(g_hEMA50,0,0,3,b50) < 3) return false;
   if(CopyBuffer(g_hEMA8, 0,0,3,b8)  < 3) return false;
   if(CopyBuffer(g_hEMA13,0,0,3,b13) < 3) return false;
   if(CopyBuffer(g_hMACD, 0,0,3,bm)  < 3) return false;
   if(CopyBuffer(g_hMACD, 1,0,3,bs)  < 3) return false;
   if(CopyBuffer(g_hATR,  0,0,3,ba)  < 3) return false;

   d.ema50 = b50[sh]; d.ema8 = b8[sh]; d.ema13 = b13[sh];
   d.atr   = ba[sh];
   d.hist  = bm[sh] - bs[sh];
   d.close = r[sh].close;

   double hh = -DBL_MAX, ll = DBL_MAX;
   for(int i = sh+1; i <= sh + g_bosLookback; i++)
     {
      if(i >= ArraySize(r)) break;
      if(r[i].high > hh) hh = r[i].high;
      if(r[i].low  < ll) ll = r[i].low;
     }
   d.hh = hh; d.ll = ll;
   d.swingLow  = FindSwingLow(sh, r, InpSwingLookback, d.close);
   d.swingHigh = FindSwingHigh(sh, r, InpSwingLookback, d.close);
   return true;
  }

double TrendStrength(const int dir)
  {
   int bars = 10;
   double eNow  = GetBuf(g_hEMA50, 0, 1);
   double ePast = GetBuf(g_hEMA50, 0, 1 + bars);
   double atr   = GetBuf(g_hATR, 0, 1);
   if(eNow <= 0.0 || ePast <= 0.0 || atr <= 0.0) return 0.0;
   double slope = (eNow - ePast) / (atr * bars);
   return (dir > 0) ? slope : -slope;
  }

int EvaluateSignal(const SIndData &d, const double spreadPts)
  {
   if(d.atr <= 0.0) return 0;

   if(InpMinATRSpreadRatio > 0.0)
     {
      double atrPts = d.atr / _Point;
      if(atrPts < InpMinATRSpreadRatio * spreadPts) return 0;
     }

   double emaSep = MathAbs(d.ema8 - d.ema13) / d.atr;
   if(g_minEMASep > 0.0 && emaSep < g_minEMASep) return 0;

   if(InpMinRangeATR > 0.0 && (d.hh - d.ll) < InpMinRangeATR * d.atr) return 0;

   double tol      = InpBOSTolerancePoints * _Point;
   double histNorm = d.hist / d.atr;

   bool trendUp = (d.ema8 > d.ema13) && (!g_useEMA50 || d.close > d.ema50);
   bool trendDn = (d.ema8 < d.ema13) && (!g_useEMA50 || d.close < d.ema50);
   bool momUp   = (histNorm >  g_macdThr);
   bool momDn   = (histNorm < -g_macdThr);
   bool bosUp   = (d.close > d.hh + tol);
   bool bosDn   = (d.close < d.ll - tol);

   bool buy  = trendUp && momUp && bosUp;
   bool sell = trendDn && momDn && bosDn;

   if(g_minTrendSlope > 0.0)
     {
      if(buy  && TrendStrength(1)  < g_minTrendSlope) buy  = false;
      if(sell && TrendStrength(-1) < g_minTrendSlope) sell = false;
     }

   if(buy && !sell)  return 1;
   if(sell && !buy)  return -1;
   return 0;
  }

//+------------------------------------------------------------------+
//| POSITION TRACKING                                                 |
//+------------------------------------------------------------------+
int FindIdx(const ulong posId)
  {
   for(int i = 0; i < ArraySize(g_pos); i++)
      if(g_pos[i].posId == posId) return i;
   return -1;
  }

void RemoveAt(const int idx)
  {
   int n = ArraySize(g_pos);
   for(int i = idx; i < n-1; i++) g_pos[i] = g_pos[i+1];
   ArrayResize(g_pos, n-1);
  }

void SnapshotTickets(ulong &tix[])
  {
   ArrayResize(tix, 0);
   for(int i = PositionsTotal()-1; i >= 0; i--)
     {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      int n = ArraySize(tix);
      ArrayResize(tix, n+1);
      tix[n] = t;
     }
  }

int CountPositions()
  {
   ulong tix[]; SnapshotTickets(tix);
   return ArraySize(tix);
  }

bool HasOpposite(const int sig)
  {
   ulong tix[]; SnapshotTickets(tix);
   for(int j = 0; j < ArraySize(tix); j++)
     {
      if(!PositionSelectByTicket(tix[j])) continue;
      long ty = PositionGetInteger(POSITION_TYPE);
      if((sig > 0 && ty == POSITION_TYPE_SELL) || (sig < 0 && ty == POSITION_TYPE_BUY)) return true;
     }
   return false;
  }

bool PositionExistsById(const ulong posId)
  {
   ulong tix[]; SnapshotTickets(tix);
   for(int j = 0; j < ArraySize(tix); j++)
     {
      if(!PositionSelectByTicket(tix[j])) continue;
      if((ulong)PositionGetInteger(POSITION_IDENTIFIER) == posId) return true;
     }
   return false;
  }

void SyncTracked()
  {
   ulong tix[]; SnapshotTickets(tix);
   for(int j = 0; j < ArraySize(tix); j++)
     {
      if(!PositionSelectByTicket(tix[j])) continue;
      ulong id = (ulong)PositionGetInteger(POSITION_IDENTIFIER);
      if(FindIdx(id) >= 0) continue;

      STracked s;
      s.posId    = id;
      s.openTime = (datetime)PositionGetInteger(POSITION_TIME);
      s.initVol  = 0.0;
      s.entry    = PositionGetDouble(POSITION_PRICE_OPEN);
      s.type     = (int)PositionGetInteger(POSITION_TYPE);
      s.reason   = "";
      s.missSince= 0;
      s.beLevel  = 0.0;
      s.tp1Pips  = 0.0;
      s.slPips   = 0.0;

      bool partialDone = false;
      if(HistorySelectByPosition(id))
        {
         for(int k = HistoryDealsTotal()-1; k >= 0; k--)
           {
            ulong dk = HistoryDealGetTicket(k);
            if(dk == 0) continue;
            long en = HistoryDealGetInteger(dk, DEAL_ENTRY);
            if(en == DEAL_ENTRY_IN) s.initVol += HistoryDealGetDouble(dk, DEAL_VOLUME);
            else if(en == DEAL_ENTRY_OUT || en == DEAL_ENTRY_OUT_BY) partialDone = true;
           }
        }
      if(s.initVol <= 0.0) s.initVol = PositionGetDouble(POSITION_VOLUME);

      double sl = PositionGetDouble(POSITION_SL);
      bool beLike = (sl > 0.0) &&
                    ((s.type == POSITION_TYPE_BUY  && sl >= s.entry - _Point) ||
                     (s.type == POSITION_TYPE_SELL && sl <= s.entry + _Point));
      s.stage  = partialDone ? 2 : 1;
      s.beDone = (partialDone && beLike);
      if(beLike) s.beLevel = sl;

      int n = ArraySize(g_pos);
      ArrayResize(g_pos, n+1);
      g_pos[n] = s;
     }
  }

int FindIdxByNewOpen(const datetime t0, const int type)
  {
   int best = -1; datetime bt = t0 - 1;
   for(int i = 0; i < ArraySize(g_pos); i++)
     {
      if(g_pos[i].type != type) continue;
      if(g_pos[i].openTime < t0) continue;
      if(g_pos[i].openTime >= bt) { bt = g_pos[i].openTime; best = i; }
     }
   return best;
  }

//+------------------------------------------------------------------+
//| SL CALCULATION - MODE-SPECIFIC                                    |
//+------------------------------------------------------------------+
//|  SCALPER: ATR-based SL (adaptif volatilitas)                      |
//|  TREND  : Swing pivot-based SL                                    |
//+------------------------------------------------------------------+
bool CalcSL(const int sig, const SIndData &d, const double entry,
            double &sl, double &slPips)
  {
   double pip  = PipSize();
   double minD = MinStopDist();
   double sp   = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
   double spP  = sp / pip;

   if(InpMode == MODE_SCALPER)
     {
      //--- SCALPER: SL berbasis ATR
      double mult   = (g_scalpSLMult > 0.0) ? g_scalpSLMult : 1.5;
      double atrPip = d.atr / pip;
      double slP    = atrPip * mult;

      //--- minimal 2x spread
      if(slP < 2.0 * spP) slP = 2.0 * spP;

      //--- clamp min
      if(slP < g_minSLPips) slP = g_minSLPips;

      //--- cek max: jika ATR terlalu besar, pasar terlalu volatil untuk scalping
      if(g_maxSLPips > 0.0 && slP > g_maxSLPips) return false;

      sl = (sig > 0) ? entry - slP * pip : entry + slP * pip;
      slPips = slP;
     }
   else
     {
      //--- TREND: SL berbasis swing pivot
      if(sig > 0)
        {
         sl = d.swingLow - InpSLBufferPips * pip;
         if(entry - sl < minD) sl = entry - minD;
        }
      else
        {
         sl = d.swingHigh + InpSLBufferPips * pip;
         if(sl - entry < minD) sl = entry + minD;
        }

      double swingP = MathAbs(entry - sl) / pip;
      if(g_maxSLPips > 0.0 && swingP > g_maxSLPips) return false;

      //--- extend ke min SL
      if(g_minSLPips > 0.0 && swingP < g_minSLPips)
        {
         sl = (sig > 0) ? entry - g_minSLPips * pip : entry + g_minSLPips * pip;
         swingP = g_minSLPips;
        }
      slPips = swingP;
     }

   //--- pastikan SL menghormati min stop distance
   if(sig > 0)
     {
      sl = NormalizeDouble(sl, _Digits);
      if(entry - sl < minD) { sl = NormalizeDouble(entry - minD, _Digits); slPips = (entry - sl) / pip; }
     }
   else
     {
      sl = NormalizeDouble(sl, _Digits);
      if(sl - entry < minD) { sl = NormalizeDouble(entry + minD, _Digits); slPips = (sl - entry) / pip; }
     }

   return true;
  }

//+------------------------------------------------------------------+
//| ENTRY EXECUTION                                                   |
//+------------------------------------------------------------------+
double CalcEntryLot(const double slDistance)
  {
   if(!InpUseRiskLot || InpRiskPercent <= 0.0 || slDistance <= 0.0)
      return FloorVol(InpLotSize);
   double balance  = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmt  = balance * InpRiskPercent / 100.0;
   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize <= 0.0 || tickVal <= 0.0) return FloorVol(InpLotSize);
   double lossPerLot = (slDistance / tickSize) * tickVal;
   if(lossPerLot <= 0.0) return FloorVol(InpLotSize);
   return FloorVol(riskAmt / lossPerLot);
  }

bool CloseTracked(const int idx, const ulong ticket, const string reason)
  {
   g_pos[idx].reason = reason;
   ResetLastError();
   if(g_trade.PositionClose(ticket, InpDeviation) && RetOK(g_trade.ResultRetcode()))
      return true;
   g_pos[idx].reason = "";
   PrintFormat("Close gagal (%s): rc=%u err=%d", reason, g_trade.ResultRetcode(), GetLastError());
   return false;
  }

void TryEntry()
  {
   if(CountPositions() >= InpMaxPositions) return;
   if(GetMarketStatus() != MS_ACTIVE)      return;
   if(!TradesPerBarOK())                   return;
   if(!TradesPerDayOK())                   return;

   datetime bt = iTime(_Symbol, _Period, 0);
   if(InpSignalOnClosedBar && bt == g_entryBar) return;

   int sh = InpSignalOnClosedBar ? 1 : 0;
   SIndData d;
   int sig = 0;
   int sp  = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);

   if(InpSignalOnClosedBar && g_cacheBar == bt)
     { d = g_cacheD; sig = g_cacheSig; }
   else
     {
      if(!LoadData(sh, d)) return;
      sig = EvaluateSignal(d, (double)sp);
      if(InpSignalOnClosedBar) { g_cacheD = d; g_cacheSig = sig; g_cacheBar = bt; }
     }
   if(sig == 0) return;
   if(HasOpposite(sig)) return;

   double pip   = PipSize();
   double entry = (sig > 0) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                            : SymbolInfoDouble(_Symbol, SYMBOL_BID);

   //--- MODE-SPECIFIC SL
   double sl, slPips;
   if(!CalcSL(sig, d, entry, sl, slPips))
     {
      PrintFormat("Entry dilewati: SL > max (%.1f) — terlalu volatil untuk %s",
                  g_maxSLPips, (InpMode == MODE_SCALPER ? "scalping" : "trend"));
      return;
     }

   //--- TP1 berbasis R
   double tp1Pips = MathMax(InpTP1MinPips, slPips * g_tp1RR);

   double lot    = CalcEntryLot(MathAbs(entry - sl));
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if(lot < minLot) lot = minLot;
   if(lot <= 0.0)   { Print("Entry dilewati: lot 0"); return; }

   //--- margin check
   double margin = 0.0;
   ENUM_ORDER_TYPE ot = (sig > 0) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   if(OrderCalcMargin(ot, _Symbol, lot, entry, margin))
     {
      double freeM = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      double needM = margin * (1.0 + InpMinFreeMarginPct / 100.0);
      if(needM > freeM)
        {
         PrintFormat("Entry dilewati: margin butuh %.2f, free %.2f", margin, freeM);
         return;
        }
     }

   //--- execute
   datetime tBefore = TimeCurrent();
   bool ok = false;
   for(int att = 0; att < 3; att++)
     {
      ResetLastError();
      ok = (sig > 0) ? g_trade.Buy(lot, _Symbol, 0.0, sl, 0.0, InpComment)
                     : g_trade.Sell(lot, _Symbol, 0.0, sl, 0.0, InpComment);
      uint rc = g_trade.ResultRetcode();
      if(ok && RetOK(rc)) { ok = true; break; }
      ok = false;
      if(rc == TRADE_RETCODE_REQUOTE || rc == TRADE_RETCODE_PRICE_CHANGED ||
         rc == TRADE_RETCODE_PRICE_OFF || rc == TRADE_RETCODE_TIMEOUT ||
         rc == TRADE_RETCODE_CONNECTION || rc == TRADE_RETCODE_TOO_MANY_REQUESTS)
        { Sleep(250); continue; }
      break;
     }
   if(!ok) return;

   //--- fill guard
   double fill = g_trade.ResultPrice();
   if(fill <= 0.0) fill = entry;
   double slipPips  = MathAbs(fill - entry) / pip;
   double realSLPip = MathAbs(fill - sl) / pip;

   SyncTracked();
   int idx = FindIdxByNewOpen(tBefore, (sig > 0) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL);

   if((InpMaxFillSlippage > 0.0 && slipPips > InpMaxFillSlippage) ||
      (g_maxSLPips > 0.0 && realSLPip > g_maxSLPips))
     {
      if(idx >= 0)
        {
         g_pos[idx].reason = "Fill guard (slippage)";
         g_trade.PositionClose(g_pos[idx].posId, InpDeviation);
        }
      g_entryBar = bt;
      return;
     }

   if(idx >= 0)
     {
      g_pos[idx].slPips  = realSLPip;
      g_pos[idx].tp1Pips = tp1Pips;
     }

   g_barTrades++;
   g_tradesToday++;
   g_entryBar = bt;
   SaveDailyState();

   string msg = StringFormat("%s %s [%s]\nLot: %s%s\nHarga: %s (slip %.1f pip)\nSL: %s (%.1f pips)\nTP1: %.1f pips (%.2f R)",
                             (sig > 0 ? "BUY" : "SELL"), _Symbol,
                             (InpMode == MODE_SCALPER ? "Scalper" : "Trend"),
                             DoubleToString(lot, 2),
                             (InpUseRiskLot ? StringFormat(" [risk %.2f%%]", InpRiskPercent) : ""),
                             DoubleToString(fill, _Digits), slipPips,
                             DoubleToString(sl, _Digits), realSLPip,
                             tp1Pips, tp1Pips / MathMax(realSLPip, 0.01));
   Print("Trade baru: ", msg);
   TgEnqueue("TRADE BARU\n" + msg);
  }

//+------------------------------------------------------------------+
//| MANAJEMEN POSISI                                                  |
//+------------------------------------------------------------------+
bool ApplyBE(const int idx, const ulong ticket)
  {
   if(!PositionSelectByTicket(ticket)) return false;
   double pip = PipSize(), minD = MinStopDist();
   double curSL = PositionGetDouble(POSITION_SL);
   double tp    = PositionGetDouble(POSITION_TP);
   double entry = g_pos[idx].entry;
   double be;

   if(g_pos[idx].type == POSITION_TYPE_BUY)
     {
      double bid   = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double limit = bid - minD;
      be = MathMin(entry + InpBEPlusPips * pip, limit);
      be = MathMax(be, entry + _Point);
      if(curSL > 0.0 && curSL >= be - _Point)
        { g_pos[idx].beDone = true; g_pos[idx].beLevel = curSL; return true; }
      if(be <= curSL + _Point) return false;
     }
   else
     {
      double ask   = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double limit = ask + minD;
      be = MathMax(entry - InpBEPlusPips * pip, limit);
      be = MathMin(be, entry - _Point);
      if(curSL > 0.0 && curSL <= be + _Point)
        { g_pos[idx].beDone = true; g_pos[idx].beLevel = curSL; return true; }
      if(be >= curSL - _Point) return false;
     }

   be = NormalizeDouble(be, _Digits);
   ResetLastError();
   if(g_trade.PositionModify(ticket, be, tp) && RetOK(g_trade.ResultRetcode()))
     { g_pos[idx].beDone = true; g_pos[idx].beLevel = be; return true; }
   return false;
  }

void DoTP1(const int idx, const ulong ticket)
  {
   if(!PositionSelectByTicket(ticket)) return;

   //--- Scalper: close full
   if(!g_useRunner)
     {
      CloseTracked(idx, ticket, "TP1 (scalper full close)");
      return;
     }

   //--- Trend: partial close
   double vol    = PositionGetDouble(POSITION_VOLUME);
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double closeV = FloorVol(g_pos[idx].initVol * g_partialPct / 100.0);
   double remain = NormalizeDouble(vol - closeV, 8);

   if(closeV < minLot - 1e-9 || remain < minLot - 1e-9)
     {
      CloseTracked(idx, ticket, "Full TP (lot too small for partial)");
      return;
     }

   ResetLastError();
   if(!g_trade.PositionClosePartial(ticket, closeV, InpDeviation) || !RetOK(g_trade.ResultRetcode()))
     {
      PrintFormat("Partial close gagal: rc=%u", g_trade.ResultRetcode());
      return;
     }

   double secured = 0.0;
   ulong dl = g_trade.ResultDeal();
   if(dl > 0 && HistoryDealSelect(dl))
      secured = HistoryDealGetDouble(dl, DEAL_PROFIT) + HistoryDealGetDouble(dl, DEAL_SWAP) +
                HistoryDealGetDouble(dl, DEAL_COMMISSION) + HistoryDealGetDouble(dl, DEAL_FEE);

   g_pos[idx].stage = 2;
   bool be = ApplyBE(idx, ticket);
   TgEnqueue(StringFormat("PARTIAL TP %s\nClose: %s (sisa %s)\nProfit: %.2f %s | BE+: %s",
                          _Symbol, DoubleToString(closeV,2), DoubleToString(remain,2),
                          secured, AccountInfoString(ACCOUNT_CURRENCY), (be ? "OK" : "Waiting")));
  }

bool ExitOnThesisBreak(const int idx, const ulong ticket)
  {
   if(!g_exitOnCross) return false;
   double e8_1  = GetBuf(g_hEMA8,  0, 1);
   double e13_1 = GetBuf(g_hEMA13, 0, 1);
   double e8_2  = GetBuf(g_hEMA8,  0, 2);
   double e13_2 = GetBuf(g_hEMA13, 0, 2);
   double c1 = iClose(_Symbol, _Period, 1);
   double c2 = iClose(_Symbol, _Period, 2);
   if(e8_1 <= 0.0 || e13_1 <= 0.0 || e8_2 <= 0.0 || e13_2 <= 0.0) return false;

   if(g_pos[idx].type == POSITION_TYPE_BUY)
     {
      if((e8_1 < e13_1) && (e8_2 < e13_2) && (c1 < e13_1) && (c2 < e13_2))
         return CloseTracked(idx, ticket, "Trend break (2-bar EMA cross BUY)");
     }
   else
     {
      if((e8_1 > e13_1) && (e8_2 > e13_2) && (c1 > e13_1) && (c2 > e13_2))
         return CloseTracked(idx, ticket, "Trend break (2-bar EMA cross SELL)");
     }
   return false;
  }

void TrailRunner(const int idx, const ulong ticket)
  {
   if(!PositionSelectByTicket(ticket)) return;
   if(EnableSpreadFilter && (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > MaxSpread_Points) return;

   double pip    = PipSize();
   double slPips = MathMax(g_pos[idx].slPips, 0.01);
   double price  = (g_pos[idx].type == POSITION_TYPE_BUY)
                   ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double profitPips = (g_pos[idx].type == POSITION_TYPE_BUY)
                       ? (price - g_pos[idx].entry) / pip : (g_pos[idx].entry - price) / pip;
   double profitR = profitPips / slPips;

   if(g_trailStartR > 0.0 && profitR < g_trailStartR) return;

   //--- PROGRESSIVE TRAILING: lebar di awal, rapat di profit besar
   double atrMult;
   if(profitR < 1.5)       atrMult = g_atrMult;
   else if(profitR < 3.0)  atrMult = g_atrMult * 0.70;
   else if(profitR < 5.0)  atrMult = g_atrMult * 0.50;
   else                    atrMult = g_atrMult * 0.35;

   double step  = InpTrailStepPips * pip;
   double minD  = MinStopDist();
   double curSL = PositionGetDouble(POSITION_SL);
   double tp    = PositionGetDouble(POSITION_TP);
   double atr   = GetBuf(g_hATR, 0, 1);
   double ema8  = GetBuf(g_hEMA8, 0, 1);
   if(atr <= 0.0 || ema8 <= 0.0) return;

   if(g_pos[idx].type == POSITION_TYPE_BUY)
     {
      double bid  = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double cand = (InpTrailMode == TRAIL_ATR) ? bid - atr * atrMult : ema8 - InpTrailBufferPips * pip;
      if(cand > bid - minD) cand = bid - minD;
      if(g_pos[idx].beLevel > 0.0 && cand < g_pos[idx].beLevel) cand = g_pos[idx].beLevel;
      cand = NormalizeDouble(cand, _Digits);
      if(curSL <= 0.0 || cand > curSL + step)
        {
         ResetLastError();
         if(g_trade.PositionModify(ticket, cand, tp) && RetOK(g_trade.ResultRetcode()))
            g_pos[idx].beLevel = MathMax(g_pos[idx].beLevel, cand);
        }
     }
   else
     {
      double ask  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double cand = (InpTrailMode == TRAIL_ATR) ? ask + atr * atrMult : ema8 + InpTrailBufferPips * pip;
      if(cand < ask + minD) cand = ask + minD;
      if(g_pos[idx].beLevel > 0.0 && cand > g_pos[idx].beLevel) cand = g_pos[idx].beLevel;
      cand = NormalizeDouble(cand, _Digits);
      if(curSL <= 0.0 || cand < curSL - step)
        {
         ResetLastError();
         if(g_trade.PositionModify(ticket, cand, tp) && RetOK(g_trade.ResultRetcode()))
            g_pos[idx].beLevel = (g_pos[idx].beLevel > 0.0) ? MathMin(g_pos[idx].beLevel, cand) : cand;
        }
     }
  }

void ManagePositions()
  {
   if(!IsMarketOpen()) return;
   SyncTracked();
   ulong tix[]; SnapshotTickets(tix);
   double pip = PipSize();

   for(int j = 0; j < ArraySize(tix); j++)
     {
      ulong ticket = tix[j];
      if(!PositionSelectByTicket(ticket)) continue;
      int idx = FindIdx((ulong)PositionGetInteger(POSITION_IDENTIFIER));
      if(idx < 0) continue;

      int    type  = g_pos[idx].type;
      double price = (type == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                                                 : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double profitPips = (type == POSITION_TYPE_BUY) ? (price - g_pos[idx].entry) / pip
                                                      : (g_pos[idx].entry - price) / pip;

      if(g_pos[idx].stage == 1)
        {
         if(EnableInvalidation && g_invalBars > 0)
           {
            int bars = iBarShift(_Symbol, _Period, g_pos[idx].openTime, false);
            if(bars >= g_invalBars)
              {
               if(CloseTracked(idx, ticket, "Timeout")) continue;
              }
           }
         if(g_pos[idx].stage == 1 && profitPips >= g_pos[idx].tp1Pips)
            DoTP1(idx, ticket);
        }
      else if(g_useRunner)
        {
         if(ExitOnThesisBreak(idx, ticket)) continue;
         if(!g_pos[idx].beDone) ApplyBE(idx, ticket);
         TrailRunner(idx, ticket);
        }
     }
  }

//+------------------------------------------------------------------+
//| FINALISASI & RECONCILE                                            |
//+------------------------------------------------------------------+
bool Finalize(const int idx)
  {
   if(!HistorySelectByPosition(g_pos[idx].posId)) return false;
   double total = 0.0;
   int reasonC = -1;
   bool hasOut = false;

   int n = HistoryDealsTotal();
   for(int i = 0; i < n; i++)
     {
      ulong dt = HistoryDealGetTicket(i);
      if(dt == 0) continue;
      total += HistoryDealGetDouble(dt, DEAL_PROFIT) + HistoryDealGetDouble(dt, DEAL_SWAP) +
               HistoryDealGetDouble(dt, DEAL_COMMISSION) + HistoryDealGetDouble(dt, DEAL_FEE);
      long en = HistoryDealGetInteger(dt, DEAL_ENTRY);
      if(en == DEAL_ENTRY_OUT || en == DEAL_ENTRY_OUT_BY || en == DEAL_ENTRY_INOUT)
        { hasOut = true; reasonC = (int)HistoryDealGetInteger(dt, DEAL_REASON); }
     }
   if(!hasOut) return false;

   string reason = g_pos[idx].reason;
   if(reason == "")
     {
      switch(reasonC)
        {
         case DEAL_REASON_SL: reason = (g_pos[idx].stage >= 2) ? "Trailing SL / BE SL" : "Stop Loss"; break;
         case DEAL_REASON_TP: reason = "Full TP";  break;
         case DEAL_REASON_SO: reason = "Stop Out"; break;
         default:             reason = "Manual / Lainnya";
        }
     }

   total = NormalizeDouble(total, 2);
   if(total > 0.0)      g_wins++;
   else if(total < 0.0) g_losses++;
   else                 g_breakeven++;

   if(total < 0.0)
     {
      g_consecLoss++;
      if(g_consecHalt > 0 && g_consecLoss >= g_consecHalt && g_pauseUntil < TimeCurrent())
        {
         g_pauseUntil = TimeCurrent() + (datetime)InpConsecLossPauseMin * 60;
         TgEnqueue(StringFormat("CIRCUIT BREAKER\n%d loss beruntun. Jeda %d menit.",
                                g_consecLoss, InpConsecLossPauseMin));
        }
     }
   else g_consecLoss = 0;

   SaveDailyState();
   int tot = g_wins + g_losses;
   double wr = (tot > 0) ? 100.0 * g_wins / tot : 0.0;
   TgEnqueue(StringFormat("POSISI DITUTUP %s\nAlasan: %s\nHasil: %+.2f %s\nWinrate: %.1f%% [%dW/%dL/%dBE]",
                          _Symbol, reason, total, AccountInfoString(ACCOUNT_CURRENCY),
                          wr, g_wins, g_losses, g_breakeven));
   return true;
  }

void Reconcile()
  {
   ulong now = GetTickCount64();
   if(now - g_lastReconcileMs < (ulong)InpMaxReconcileMs) return;
   g_lastReconcileMs = now;
   for(int i = ArraySize(g_pos)-1; i >= 0; i--)
     {
      if(PositionExistsById(g_pos[i].posId)) continue;
      if(Finalize(i)) RemoveAt(i);
      else
        {
         if(g_pos[i].missSince == 0) g_pos[i].missSince = TimeCurrent();
         else if(TimeCurrent() - g_pos[i].missSince > 60)
           { Print("History pos ", g_pos[i].posId, " tidak ditemukan."); RemoveAt(i); }
        }
     }
  }

//+------------------------------------------------------------------+
//| DASHBOARD                                                         |
//+------------------------------------------------------------------+
void MakeRect(const string name, const int x, const int y, const int w, const int h,
              const color bg, const color border)
  {
   if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_COLOR, border);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
  }

void MakeLabel(const string name, const int x, const int y, const string text,
               const color clr, const int fs)
  {
   if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fs);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
  }

void CreatePanel()
  {
   int totalH = HDR_H + ROW_COUNT * ROW_H + 12;
   MakeRect(PFX+"BG", g_panelX, g_panelY, PANEL_W, totalH, C'18,20,26', C'60,66,80');
   MakeRect(PFX+"HD", g_panelX, g_panelY, PANEL_W, HDR_H, C'36,41,56', C'60,66,80');
   MakeLabel(PFX+"HT", g_panelX+8, g_panelY+6,
             "EMA-MACD-BOS v1.30 | " + (InpMode == MODE_SCALPER ? "SCALPER" : "TREND"), clrWhite, 9);
   for(int i = 0; i < ROW_COUNT; i++)
      MakeLabel(PFX+"R"+IntegerToString(i), g_panelX+10, g_panelY+HDR_H+8+i*ROW_H, "", clrWhiteSmoke, 9);
  }

void PanelMove(const int x, const int y)
  {
   g_panelX = x; g_panelY = y;
   ObjectSetInteger(0, PFX+"BG", OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, PFX+"BG", OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, PFX+"HD", OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, PFX+"HD", OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, PFX+"HT", OBJPROP_XDISTANCE, x+8);
   ObjectSetInteger(0, PFX+"HT", OBJPROP_YDISTANCE, y+6);
   for(int i = 0; i < ROW_COUNT; i++)
     {
      string nm = PFX+"R"+IntegerToString(i);
      ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, x+10);
      ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, y+HDR_H+8+i*ROW_H);
     }
  }

void SetRow(const int i, const string text, const color clr)
  {
   string nm = PFX+"R"+IntegerToString(i);
   ObjectSetString(0, nm, OBJPROP_TEXT, text);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, clr);
  }

void UpdatePanel()
  {
   if(!InpShowPanel) return;
   static ulong lastUpd = 0;
   ulong nowMs = GetTickCount64();
   if(nowMs - lastUpd < 900) return;
   lastUpd = nowMs;

   string cur = AccountInfoString(ACCOUNT_CURRENCY);
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   double eq  = AccountInfoDouble(ACCOUNT_EQUITY);

   double fl = 0.0; int np = 0, stg = 0;
   ulong tix[]; SnapshotTickets(tix);
   for(int j = 0; j < ArraySize(tix); j++)
     {
      if(!PositionSelectByTicket(tix[j])) continue;
      fl += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      np++;
      int ix = FindIdx((ulong)PositionGetInteger(POSITION_IDENTIFIER));
      if(ix >= 0) stg = g_pos[ix].stage;
     }

   int tot = g_wins + g_losses;
   double wr = (tot > 0) ? 100.0 * g_wins / tot : 0.0;
   ENUM_MARKET_STATUS ms = GetMarketStatus();
   int sp = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);

   color stClr = clrLime;
   if(ms == MS_SPREAD_HIGH)    stClr = clrOrangeRed;
   if(ms == MS_OUT_OF_SESSION) stClr = clrGold;
   if(ms == MS_TRADE_DISABLED) stClr = clrRed;
   if(ms == MS_DAILY_HALTED)   stClr = clrMagenta;
   if(ms == MS_PAUSED)         stClr = clrOrange;

   double ddPct = 0.0;
   if(g_dayStartBalance > 0.0)
      ddPct = (g_dayStartBalance - eq) / g_dayStartBalance * 100.0;

   string slMethod = (InpMode == MODE_SCALPER) ? "ATR-SL" : "Swing-SL";

   SetRow(0,  StringFormat("Balance : %.2f %s", bal, cur), clrWhiteSmoke);
   SetRow(1,  StringFormat("Equity  : %.2f %s", eq, cur), clrWhiteSmoke);
   SetRow(2,  StringFormat("Float PL: %+.2f %s", fl, cur), (fl >= 0.0 ? clrLime : clrTomato));
   SetRow(3,  StringFormat("Winrate : %.1f%% [%dW/%dL/%dBE]", wr, g_wins, g_losses, g_breakeven), clrDeepSkyBlue);
   SetRow(4,  "Status  : " + StatusText(ms), stClr);
   SetRow(5,  StringFormat("Spread  : %d pts (max %d)", sp, MaxSpread_Points),
            (EnableSpreadFilter && sp > MaxSpread_Points) ? clrOrangeRed : clrWhiteSmoke);
   SetRow(6,  StringFormat("Posisi  : %d (Stage %s) | Hari ini: %d",
            np, (np > 0 ? IntegerToString(stg) : "-"), g_tradesToday), clrWhiteSmoke);
   SetRow(7,  StringFormat("DD Hari : %.2f%% (max %.2f%%)", ddPct, InpMaxDailyLossPct),
            (InpMaxDailyLossPct > 0 && ddPct >= InpMaxDailyLossPct) ? clrRed : (ddPct > 0 ? clrOrange : clrLime));
   SetRow(8,  StringFormat("Mode    : %s | %s | Runner %s",
            (InpMode == MODE_SCALPER ? "Scalper" : "Trend"), slMethod,
            (g_useRunner ? "ON" : "OFF")), clrKhaki);
   SetRow(9,  StringFormat("TP1     : %.2fR (min %.1f pip) | Partial %.0f%%",
            g_tp1RR, InpTP1MinPips, g_partialPct), clrWhiteSmoke);
   SetRow(10, StringFormat("SL      : [%.1f-%.1f] pip | Mult %.1fx | Trail %.2fx prog",
            g_minSLPips, g_maxSLPips, g_scalpSLMult, g_atrMult), clrWhiteSmoke);
   SetRow(11, StringFormat("Consec  : %d loss%s", g_consecLoss,
            (g_pauseUntil > TimeCurrent() ? StringFormat(" | pause s/d %s", TimeToString(g_pauseUntil, TIME_MINUTES)) : "")),
            (g_consecLoss > 0 ? clrOrange : clrLime));
   SetRow(12, StringFormat("Filter  : EMA50=%s | Slope=%.3f | ATR/Spd=%.1f",
            (g_useEMA50 ? "ON" : "OFF"), g_minTrendSlope, InpMinATRSpreadRatio), clrSilver);
   ChartRedraw(0);
  }

bool InHeader(const int mx, const int my)
  {
   return (mx >= g_panelX && mx <= g_panelX + PANEL_W && my >= g_panelY && my <= g_panelY + HDR_H);
  }

void StopDrag()
  {
   g_dragging = false;
   ChartSetInteger(0, CHART_MOUSE_SCROLL, g_origScroll);
   GlobalVariableSet(g_gvKey + "_PX", g_panelX);
   GlobalVariableSet(g_gvKey + "_PY", g_panelY);
  }

//+------------------------------------------------------------------+
//| RESOLUSI PARAMETER MODE                                           |
//+------------------------------------------------------------------+
void ResolveModeParams()
  {
   bool scal = (InpMode == MODE_SCALPER);

   g_tp1RR      = (InpTP1RR > 0.0)          ? InpTP1RR          : (scal ? 0.50 : 2.50);
   g_partialPct = (InpPartialPercent > 0.0) ? InpPartialPercent : (scal ? 100.0 : 20.0);
   g_atrMult    = (InpATRMult > 0.0)        ? InpATRMult        : (scal ? 1.20 : 3.50);
   g_macdThr    = (InpMACDThrNorm > 0.0)    ? InpMACDThrNorm    : (scal ? 0.15 : 0.30);
   g_minEMASep  = (InpMinEMASepATR > 0.0)   ? InpMinEMASepATR   : (scal ? 0.08 : 0.18);
   g_maxSLPips  = (InpMaxSLPips > 0.0)      ? InpMaxSLPips      : (scal ? 12.0 : 35.0);
   g_minSLPips  = InpMinSLPips;
   g_trailStartR= (InpTrailStartR > 0.0)    ? InpTrailStartR    : (scal ? 0.80 : 1.50);
   g_invalBars  = (InpInvalidationBars > 0) ? InpInvalidationBars : (scal ? 8 : 0);
   g_bosLookback= (InpBOSLookback > 0)      ? InpBOSLookback    : (scal ? 10 : 25);
   g_maxTradesDay = (InpMaxTradesPerDay > 0)? InpMaxTradesPerDay: (scal ? 30 : 0);
   g_consecHalt = (InpConsecLossHalt > 0)   ? InpConsecLossHalt : (scal ? 4 : 6);

   g_useRunner  = (InpUseRunner == OA_AUTO) ? !scal : (InpUseRunner == OA_ON);
   g_exitOnCross= (InpExitOnCross == OA_AUTO) ? g_useRunner : (InpExitOnCross == OA_ON);
   g_useEMA50   = (InpUseEMA50 == OA_AUTO)  ? !scal : (InpUseEMA50 == OA_ON);

   if(!g_useRunner) g_partialPct = 100.0;

   g_minTrendSlope = (InpMinTrendSlope > 0.0) ? InpMinTrendSlope : (scal ? 0.0 : 0.04);
   g_scalpSLMult   = (InpScalpSLMult > 0.0)   ? InpScalpSLMult   : (scal ? 1.5 : 0.0);

   PrintFormat("=== MODE %s ===", scal ? "SCALPER (ATR-SL)" : "TREND FOLLOWER (Swing-SL)");
   PrintFormat("TP1=%.2fR | Partial=%.0f%% | Runner=%s | ExitCross=%s | EMA50=%s",
               g_tp1RR, g_partialPct, (g_useRunner?"ON":"OFF"),
               (g_exitOnCross?"ON":"OFF"), (g_useEMA50?"ON":"OFF"));
   PrintFormat("SL: method=%s | [%.1f-%.1f] pip | ScalpMult=%.1fx | ATRTrail=%.2fx",
               (scal?"ATR":"Swing"), g_minSLPips, g_maxSLPips, g_scalpSLMult, g_atrMult);
   PrintFormat("TrendSlope=%.3f | BOS_LB=%d | Timeout=%s | MaxTrades/Day=%s | ConsecHalt=%d",
               g_minTrendSlope, g_bosLookback,
               (g_invalBars>0?IntegerToString(g_invalBars)+" bar":"OFF"),
               (g_maxTradesDay>0?IntegerToString(g_maxTradesDay):"UNLIMITED"), g_consecHalt);
  }

//+------------------------------------------------------------------+
//| OnInit                                                            |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(MQLInfoInteger(MQL_OPTIMIZATION))
     { Print("Tidak untuk Optimization mode."); return INIT_FAILED; }

   //--- validasi indikator
   if(InpEMAMajor < 1 || InpEMAFast < 1 || InpEMASlow < 1 ||
      InpMACDFast < 1 || InpMACDSlow <= InpMACDFast || InpMACDSignal < 1 ||
      InpSwingLookback < 1 || InpATRPeriod < 1)
     { Print("Input indikator tidak valid."); return INIT_PARAMETERS_INCORRECT; }

   //--- validasi order & SL/TP
   if(InpLotSize <= 0.0 || InpPointsPerPip < 0 || InpMaxPositions < 1 ||
      InpDeviation < 0 || InpMaxFillSlippage < 0.0 ||
      InpSLBufferPips < 0.0 || InpBEPlusPips < 0.0 || InpTrailStepPips < 0.0 ||
      InpTrailBufferPips < 0.0 || InpTP1MinPips <= 0.0 || InpMinSLPips < 0.0 ||
      InpATRMult < 0.0 || InpTP1RR < 0.0 || InpTrailStartR < 0.0 ||
      InpMACDThrNorm < 0.0 || InpMinEMASepATR < 0.0 || InpMinRangeATR < 0.0 ||
      InpMinATRSpreadRatio < 0.0 || InpMaxSLPips < 0.0 || InpScalpSLMult < 0.0 ||
      InpMinTrendSlope < 0.0)
     { Print("Input SL/TP/Trailing tidak valid."); return INIT_PARAMETERS_INCORRECT; }

   //--- validasi risiko & filter
   if(InpMaxDailyLossPct < 0.0 || InpMaxDailyProfitPct < 0.0 ||
      InpRiskPercent < 0.0 || InpMinFreeMarginPct < 0.0 ||
      InpConsecLossHalt < 0 || InpConsecLossPauseMin < 0 ||
      InpMaxTradesPerDay < 0 || InpStatLookbackDays < 1 ||
      InpBOSLookback < 0 || InpInvalidationBars < 0 ||
      InpMaxTradesPerBar < 1 || InpBOSTolerancePoints < 0 ||
      InpMaxReconcileMs < 0 || InpDragTimeoutMs < 0 ||
      InpStartHour < 0 || InpStartHour > 23 || InpEndHour < 0 || InpEndHour > 23)
     { Print("Input risiko/filter tidak valid."); return INIT_PARAMETERS_INCORRECT; }

   ResolveModeParams();

   //--- auto-detect pip
   g_pointsPerPip = InpPointsPerPip;
   if(g_pointsPerPip <= 0)
     {
      string up = _Symbol; StringToUpper(up);
      bool metal = (StringFind(up,"XAU") >= 0 || StringFind(up,"GOLD") >= 0);
      if(metal) g_pointsPerPip = (_Digits >= 3) ? 100 : 10;
      else      g_pointsPerPip = (_Digits == 3 || _Digits == 5) ? 10 : 1;
     }
   PrintFormat("Pip: Symbol=%s Digits=%d PointsPerPip=%d", _Symbol, _Digits, g_pointsPerPip);

   //--- validasi simbol
   double vMin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vStep= SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_DISABLED ||
      vMin <= 0.0 || vStep <= 0.0)
     { Print("Simbol tidak dapat diperdagangkan."); return INIT_FAILED; }

   //--- CTrade
   g_trade.SetExpertMagicNumber(InpMagic);
   g_trade.SetDeviationInPoints(InpDeviation);
   g_trade.SetTypeFillingBySymbol(_Symbol);
   g_trade.SetAsyncMode(false);

   //--- handle indikator
   g_hEMA50 = iMA(_Symbol, _Period, InpEMAMajor, 0, MODE_EMA, PRICE_CLOSE);
   g_hEMA8  = iMA(_Symbol, _Period, InpEMAFast,  0, MODE_EMA, PRICE_CLOSE);
   g_hEMA13 = iMA(_Symbol, _Period, InpEMASlow,  0, MODE_EMA, PRICE_CLOSE);
   g_hMACD  = iMACD(_Symbol, _Period, InpMACDFast, InpMACDSlow, InpMACDSignal, PRICE_CLOSE);
   g_hATR   = iATR(_Symbol, _Period, InpATRPeriod);
   if(g_hEMA50 == INVALID_HANDLE || g_hEMA8 == INVALID_HANDLE || g_hEMA13 == INVALID_HANDLE ||
      g_hMACD == INVALID_HANDLE || g_hATR == INVALID_HANDLE)
     { Print("Gagal handle indikator: ", GetLastError()); return INIT_FAILED; }

   //--- GV key
   g_gvKey = "EMB_" + IntegerToString((long)InpMagic) + "_" + _Symbol;

   //--- rebuild statistik
   RebuildStatsFromHistory();

   //--- load daily state
   LoadDailyState();
   MqlDateTime dn; TimeToStruct(TimeCurrent(), dn);
   dn.hour = 0; dn.min = 0; dn.sec = 0;
   datetime todayStart = StructToTime(dn);
   if(g_dayStartStamp != todayStart)
     {
      g_dayStartStamp = 0; g_dayStartBalance = 0.0;
      g_tradingHalted = false; g_profitHalted = false; g_tradesToday = 0;
     }
   UpdateDailyState();

   //--- sync posisi
   ArrayResize(g_pos, 0);
   SyncTracked();

   //--- dashboard
   g_panelX = InpPanelX; g_panelY = InpPanelY;
   if(InpShowPanel)
     {
      if(!MQLInfoInteger(MQL_TESTER) &&
         GlobalVariableCheck(g_gvKey+"_PX") && GlobalVariableCheck(g_gvKey+"_PY"))
        {
         g_panelX = (int)GlobalVariableGet(g_gvKey+"_PX");
         g_panelY = (int)GlobalVariableGet(g_gvKey+"_PY");
        }
      int cw0 = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
      int ch0 = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
      int ph  = HDR_H + ROW_COUNT * ROW_H + 12;
      if(cw0 > PANEL_W) g_panelX = MathMax(0, MathMin(g_panelX, cw0 - PANEL_W));
      if(ch0 > ph)      g_panelY = MathMax(0, MathMin(g_panelY, ch0 - ph));
      g_origScroll   = ChartGetInteger(0, CHART_MOUSE_SCROLL);
      g_origMouseEvt = ChartGetInteger(0, CHART_EVENT_MOUSE_MOVE);
      ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
      CreatePanel();
      PanelMove(g_panelX, g_panelY);
      UpdatePanel();
     }

   EventSetTimer(1);
   PrintFormat("EMA_MACD_BOS v1.30 siap | %s %s | Magic=%I64u", _Symbol, EnumToString(_Period), InpMagic);
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| OnDeinit                                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   if(g_dragging) StopDrag();
   SaveDailyState();
   if(InpShowPanel)
     {
      ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, g_origMouseEvt);
      ObjectsDeleteAll(0, PFX);
      ChartRedraw(0);
     }
   if(g_hEMA50 != INVALID_HANDLE) IndicatorRelease(g_hEMA50);
   if(g_hEMA8  != INVALID_HANDLE) IndicatorRelease(g_hEMA8);
   if(g_hEMA13 != INVALID_HANDLE) IndicatorRelease(g_hEMA13);
   if(g_hMACD  != INVALID_HANDLE) IndicatorRelease(g_hMACD);
   if(g_hATR   != INVALID_HANDLE) IndicatorRelease(g_hATR);
   if(InpClearGVOnRemove && (reason == REASON_REMOVE || reason == REASON_CHARTCLOSE))
     {
      GlobalVariableDel(g_gvKey+"_PX");
      GlobalVariableDel(g_gvKey+"_PY");
     }
  }

//+------------------------------------------------------------------+
//| OnTick                                                            |
//+------------------------------------------------------------------+
void OnTick()
  {
   UpdateDailyState();
   CheckDailyGuard();
   Reconcile();
   ManagePositions();
   TryEntry();
   if(TimeCurrent() != g_lastPanelUpdate)
     { g_lastPanelUpdate = TimeCurrent(); UpdatePanel(); }
  }

//+------------------------------------------------------------------+
//| OnTimer                                                           |
//+------------------------------------------------------------------+
void OnTimer()
  {
   UpdateDailyState();
   CheckDailyGuard();
   Reconcile();
   ManagePositions();
   TgPump();
   UpdatePanel();
   if(g_dragging && g_lastDragMs > 0 && GetTickCount64() - g_lastDragMs > (ulong)InpDragTimeoutMs)
      StopDrag();
   if(g_pendingReconcile)
     { g_pendingReconcile = false; g_lastReconcileMs = 0; Reconcile(); }
  }

//+------------------------------------------------------------------+
//| OnTradeTransaction                                                |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD ||
      trans.type == TRADE_TRANSACTION_HISTORY_ADD)
      g_pendingReconcile = true;
  }

//+------------------------------------------------------------------+
//| OnChartEvent                                                      |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(!InpShowPanel) return;
   if(id == CHARTEVENT_MOUSE_MOVE)
     {
      int  mx = (int)lparam, my = (int)dparam;
      uint st = (uint)StringToInteger(sparam);
      bool down = ((st & 1) == 1);
      if(down)
        {
         if(!g_dragging && !g_prevDown && InHeader(mx, my))
           {
            g_dragging = true;
            g_offX = mx - g_panelX; g_offY = my - g_panelY;
            g_origScroll = ChartGetInteger(0, CHART_MOUSE_SCROLL);
            ChartSetInteger(0, CHART_MOUSE_SCROLL, false);
           }
         else if(g_dragging)
           {
            int cw = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
            int ch = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
            int ph = HDR_H + ROW_COUNT * ROW_H + 12;
            int nx = MathMax(0, MathMin(mx - g_offX, cw - PANEL_W));
            int ny = MathMax(0, MathMin(my - g_offY, ch - ph));
            if(nx != g_panelX || ny != g_panelY) { PanelMove(nx, ny); ChartRedraw(0); }
           }
         if(g_dragging) g_lastDragMs = GetTickCount64();
        }
      else if(g_dragging) StopDrag();
      g_prevDown = down;
     }
   else if(id == CHARTEVENT_CLICK)
     { if(g_dragging) StopDrag(); }
  }
//+------------------------------------------------------------------+
