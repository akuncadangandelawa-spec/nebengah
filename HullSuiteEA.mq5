//+------------------------------------------------------------------+
//|                                              HullSuite_EA.mq5    |
//|   v4.0 - ATR/Pip SL-TP + Hedge Auto-Close + Grid + Time + Daily  |
//| cocok untuk modal 1 juta, kalo dibawahnya jamin loss             |
//+------------------------------------------------------------------+
#property copyright "Pak Anto - EA Build"
#property version   "4.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

CTrade         trade;
CPositionInfo  posInfo;

//--- Enums
enum ENUM_HMA_MODE { MODE_HMA=0, MODE_THMA=1, MODE_EHMA=2 };
enum ENUM_SLTP_MODE { SLTP_ATR=0, SLTP_MANUAL_PIPS=1, SLTP_NONE=2 };

//--- Inputs: Core
input ENUM_HMA_MODE   modeSwitch     = MODE_THMA;
input int             length         = 90;

//--- Inputs: Filter
input bool            UseTrendFilter = true;
input ENUM_TIMEFRAMES TrendTF        = PERIOD_H1;
input int             TrendPeriod    = 200;
input bool            UseAdxFilter   = true;
input int             AdxPeriod      = 14;
input double          AdxThreshold   = 25.0;

//--- Inputs: MM
input double          LotSize        = 0.01;
input int             MagicNumber    = 20250101;

//--- Inputs: SL/TP
input ENUM_SLTP_MODE  SLMode         = SLTP_ATR;
input ENUM_SLTP_MODE  TPMode         = SLTP_ATR;
input int             AtrPeriod      = 14;
input double          AtrSLMultiplier= 2.0;
input double          AtrTPMultiplier= 4.0;
input int             ManualSLPips   = 30;
input int             ManualTPPips   = 60;

//--- Inputs: Trailing & BE
input bool            UseTrailing    = true;
input double          TrailStartAtr  = 1.0;
input double          TrailStepAtr   = 1.0;
input double          TrailMinStepPts= 20;
input bool            UseBreakEven   = true;
input double          BE_TriggerAtr  = 1.0;
input double          BE_LockAtr     = 0.2;

//--- Inputs: Behavior
input bool            CloseOnOpposite= true;
input bool            OnePositionOnly= true;

//--- Inputs: HEDGE
input bool            UseStrictHedge = false;
input int             HedgeTriggerPips     = 30;
input double          HedgeLotRatio        = 1.0;
input int             HedgeNetTPPips       = 10;
input bool            BlockNewSignalDuringHedge = true;

//--- Inputs: HEDGE - Auto Close at Open
input bool            HedgeCloseAtOpen     = true;
input int             HedgeCloseAtOpenPips = 2;

//--- Inputs: HEDGE - Grid
input bool            UseHedgeGrid         = false;
input int             HedgeMaxLevels       = 3;
input int             HedgeGridStepPips    = 30;
input double          HedgeGridMultiplier  = 1.5;

//--- Inputs: HEDGE - Time-based
input bool            UseTimeBasedHedge    = false;
input int             HedgeTimeMinutes     = 30;

//--- Inputs: DAILY LOSS LIMIT
input bool            UseDailyLossLimit    = false;
input double          DailyLossLimitMoney  = 100.0;
input bool            DailyLossStopTrading = true;

//--- Global
int      handleSMA = INVALID_HANDLE;
int      handleADX = INVALID_HANDLE;
int      handleATR = INVALID_HANDLE;
datetime lastBarTime     = 0;
datetime lastTradingDay  = 0;
bool     dailyStopTriggered = false;

//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(20);
   trade.SetTypeFillingBySymbol(_Symbol);

   handleSMA = iMA(_Symbol, TrendTF, TrendPeriod, 0, MODE_SMA, PRICE_CLOSE);
   handleADX = iADX(_Symbol, _Period, AdxPeriod);
   handleATR = iATR(_Symbol, _Period, AtrPeriod);

   if(handleSMA==INVALID_HANDLE || handleADX==INVALID_HANDLE || handleATR==INVALID_HANDLE)
     { Print("Gagal buat handle"); return INIT_FAILED; }

   lastTradingDay = iTime(_Symbol, PERIOD_D1, 0);
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   if(handleSMA != INVALID_HANDLE) IndicatorRelease(handleSMA);
   if(handleADX != INVALID_HANDLE) IndicatorRelease(handleADX);
   if(handleATR != INVALID_HANDLE) IndicatorRelease(handleATR);
  }

//+------------------------------------------------------------------+
//| Helpers                                                          |
//+------------------------------------------------------------------+
double PipSize()
  {
   int d = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   return (d == 3 || d == 5) ? _Point * 10.0 : _Point;
  }

double GetMoneyPerPip(double lot)
  {
   double pip = PipSize();
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(ts <= 0) return 0;
   return (pip / ts) * tv * lot;
  }

double GetWMA(const int index, const int period, const double &price[])
  {
   if(period <= 0) return 0;
   double sum=0, wsum=0;
   for(int j=0;j<period;j++) { double w=period-j; sum += price[index+j]*w; wsum += w; }
   return (wsum>0) ? sum/wsum : 0;
  }

double GetHull(const int shift, const double &close[], const int dataSize)
  {
   int halfLength  = (int)MathFloor(length/2.0);
   int sqrtLength  = (int)MathFloor(MathSqrt(length));
   int thirdLength = (int)MathFloor(length/3.0);

   if(modeSwitch == MODE_HMA)
     {
      if(shift + 2*length + 5 >= dataSize) return 0;
      double inner[]; ArrayResize(inner, sqrtLength);
      for(int k=0;k<sqrtLength;k++)
        { int idx=shift+k; inner[k]=2.0*GetWMA(idx,halfLength,close)-GetWMA(idx,length,close); }
      return GetWMA(0, sqrtLength, inner);
     }
   else if(modeSwitch == MODE_THMA)
     {
      if(shift + 2*length + 5 >= dataSize) return 0;
      double inner[]; ArrayResize(inner, length);
      for(int k=0;k<length;k++)
        {
         int idx=shift+k;
         inner[k]=3.0*GetWMA(idx,thirdLength,close)-GetWMA(idx,halfLength,close)-GetWMA(idx,length,close);
        }
      return GetWMA(0, length, inner);
     }
   else
     {
      double k=2.0/(length+1.0), kH=2.0/(halfLength+1.0), kS=2.0/(sqrtLength+1.0);
      int oldestIdx = shift + length + 20;
      if(oldestIdx >= dataSize) return 0;
      double eF=close[oldestIdx], eH=close[oldestIdx], h=close[oldestIdx];
      for(int i=oldestIdx-1;i>=shift;i--)
        {
         double neF = close[i]*k + eF*(1.0-k);
         double neH = close[i]*kH + eH*(1.0-kH);
         double inner = 2.0*neH - neF;
         h = inner*kS + h*(1.0-kS);
         eF = neF; eH = neH;
        }
      return h;
     }
  }

int GetSignal(const double &close[], const int dataSize)
  {
   double h1=GetHull(1,close,dataSize);
   double h2=GetHull(2,close,dataSize);
   double h4=GetHull(4,close,dataSize);
   if(h1==0||h2==0||h4==0) return 0;

   bool isUpNow=h1>h2, wasUp=h2>h4;
   bool raw_buy = isUpNow && !wasUp;
   bool raw_sell= !isUpNow &&  wasUp;
   if(!raw_buy && !raw_sell) return 0;

   bool allow_buy=true, allow_sell=true;
   double cClose=close[1];

   if(UseTrendFilter && handleSMA!=INVALID_HANDLE)
     {
      double s[1];
      if(CopyBuffer(handleSMA,0,1,1,s)>0)
        {
         if(cClose < s[0]) allow_buy  = false;
         if(cClose > s[0]) allow_sell = false;
        }
     }
   if(UseAdxFilter && handleADX!=INVALID_HANDLE)
     {
      double a[1];
      if(CopyBuffer(handleADX,0,1,1,a)>0)
         if(a[0] < AdxThreshold) { allow_buy=false; allow_sell=false; }
     }

   if(raw_buy  && allow_buy)  return  1;
   if(raw_sell && allow_sell) return -1;
   return 0;
  }

double GetATR()
  {
   double a[1];
   if(CopyBuffer(handleATR,0,1,1,a) <= 0) return 0;
   return a[0];
  }

//+------------------------------------------------------------------+
//| Position queries                                                 |
//+------------------------------------------------------------------+
bool HasPosition()
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Symbol()==_Symbol && posInfo.Magic()==MagicNumber) return true;
     }
   return false;
  }

bool HasPositionOfType(ENUM_POSITION_TYPE t)
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Symbol()==_Symbol && posInfo.Magic()==MagicNumber
         && posInfo.PositionType()==t) return true;
     }
   return false;
  }

void ClosePositionsByType(ENUM_POSITION_TYPE t)
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Symbol()==_Symbol && posInfo.Magic()==MagicNumber
         && posInfo.PositionType()==t) trade.PositionClose(posInfo.Ticket());
     }
  }

void CloseAllPositions()
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Symbol()==_Symbol && posInfo.Magic()==MagicNumber)
         trade.PositionClose(posInfo.Ticket());
     }
  }

int CountHedges(ENUM_POSITION_TYPE hedgeType)
  {
   int count=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Symbol()!=_Symbol || posInfo.Magic()!=MagicNumber) continue;
      if(posInfo.PositionType()!=hedgeType) continue;
      if(StringFind(posInfo.Comment(), "Hedge") == 0) count++;
     }
   return count;
  }

bool IsHedged()
  {
   if(!UseStrictHedge) return false;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Symbol()!=_Symbol || posInfo.Magic()!=MagicNumber) continue;
      if(StringFind(posInfo.Comment(), "Hedge") == 0) return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
void CalcSLTP(ENUM_ORDER_TYPE type, double price, double atr, double &sl, double &tp)
  {
   sl=0; tp=0;
   double pip=PipSize();

   if(SLMode == SLTP_ATR && atr>0)
      sl=(type==ORDER_TYPE_BUY)? price - atr*AtrSLMultiplier : price + atr*AtrSLMultiplier;
   else if(SLMode == SLTP_MANUAL_PIPS && ManualSLPips>0)
      sl=(type==ORDER_TYPE_BUY)? price - ManualSLPips*pip : price + ManualSLPips*pip;

   if(TPMode == SLTP_ATR && atr>0)
      tp=(type==ORDER_TYPE_BUY)? price + atr*AtrTPMultiplier : price - atr*AtrTPMultiplier;
   else if(TPMode == SLTP_MANUAL_PIPS && ManualTPPips>0)
      tp=(type==ORDER_TYPE_BUY)? price + ManualTPPips*pip : price - ManualTPPips*pip;

   sl=NormalizeDouble(sl,_Digits);
   tp=NormalizeDouble(tp,_Digits);
  }

void OpenTrade(ENUM_ORDER_TYPE type, double volume = -1)
  {
   double atr = GetATR();
   double vol = (volume > 0) ? volume : LotSize;
   double price = (type==ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol,SYMBOL_ASK)
                                         : SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double sl=0, tp=0;
   if(volume <= 0) CalcSLTP(type, price, atr, sl, tp);

   string cmt = (volume > 0) ? "Hedge" : "HullSuite";
   if(type==ORDER_TYPE_BUY) trade.Buy(vol,_Symbol,price,sl,tp,cmt);
   else                     trade.Sell(vol,_Symbol,price,sl,tp,cmt);
  }

//+------------------------------------------------------------------+
//| Trailing + Break Even (skip kalau sedang hedged)                 |
//+------------------------------------------------------------------+
void ManageTrailingBE()
  {
   if(IsHedged()) return;

   double atr=GetATR(); if(atr<=0) return;
   double point=_Point;
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);

   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Symbol()!=_Symbol || posInfo.Magic()!=MagicNumber) continue;

      ENUM_POSITION_TYPE t=posInfo.PositionType();
      double op=posInfo.PriceOpen(), curSL=posInfo.StopLoss(), curTP=posInfo.TakeProfit();
      double pDist = (t==POSITION_TYPE_BUY) ? (bid-op) : (op-ask);
      if(pDist<=0) continue;

      double cand=0;
      if(UseBreakEven && pDist >= atr*BE_TriggerAtr)
         cand=(t==POSITION_TYPE_BUY)? op + atr*BE_LockAtr : op - atr*BE_LockAtr;

      if(UseTrailing && pDist >= atr*TrailStartAtr)
        {
         double tSL=(t==POSITION_TYPE_BUY)? bid - atr*TrailStepAtr : ask + atr*TrailStepAtr;
         if(cand==0) cand=tSL;
         else cand=(t==POSITION_TYPE_BUY)? MathMax(cand,tSL) : MathMin(cand,tSL);
        }
      if(cand<=0) continue;
      cand=NormalizeDouble(cand,_Digits);

      bool need=false;
      if(curSL==0) need=true;
      else if(t==POSITION_TYPE_BUY  && cand>curSL + TrailMinStepPts*point) need=true;
      else if(t==POSITION_TYPE_SELL && cand<curSL - TrailMinStepPts*point) need=true;
      if(!need) continue;

      long slv=SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
      if(slv>0)
        {
         double md=slv*point;
         if(t==POSITION_TYPE_BUY  && bid-cand<md) continue;
         if(t==POSITION_TYPE_SELL && cand-ask<md) continue;
        }
      trade.PositionModify(posInfo.Ticket(), cand, curTP);
     }
  }

//+------------------------------------------------------------------+
//| STRICT HEDGE — Auto Close + Grid + Time-based                    |
//+------------------------------------------------------------------+
void ManageStrictHedge()
  {
   if(!UseStrictHedge) return;

   double pip=PipSize();
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);

   // Agregat posisi
   double oLotBuy=0, oLotSell=0;
   double oOpenBuy=0, oOpenSell=0;
   datetime oTimeBuy=0, oTimeSell=0;
   double profitOrigBuy=0, profitOrigSell=0;
   double profitHedged=0;
   double hedgedLotBuy=0, hedgedLotSell=0;

   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Symbol()!=_Symbol || posInfo.Magic()!=MagicNumber) continue;

      bool isHedge = (StringFind(posInfo.Comment(),"Hedge")==0);
      double pl = posInfo.Profit() + posInfo.Swap() + posInfo.Commission();

      if(posInfo.PositionType()==POSITION_TYPE_BUY)
        {
         if(isHedge) { hedgedLotBuy += posInfo.Volume(); profitHedged += pl; }
         else
           {
            oLotBuy += posInfo.Volume();
            oOpenBuy = posInfo.PriceOpen();
            oTimeBuy = (datetime)posInfo.Time();
            profitOrigBuy += pl;
           }
        }
      else
        {
         if(isHedge) { hedgedLotSell += posInfo.Volume(); profitHedged += pl; }
         else
           {
            oLotSell += posInfo.Volume();
            oOpenSell = posInfo.PriceOpen();
            oTimeSell = (datetime)posInfo.Time();
            profitOrigSell += pl;
           }
        }
     }

   bool hasOrigBuy  = (oLotBuy  > 0);
   bool hasOrigSell = (oLotSell > 0);
   bool hasHedge    = (hedgedLotBuy > 0 || hedgedLotSell > 0);

   //========================
   // A. Original BUY
   //========================
   if(hasOrigBuy)
     {
      int level = CountHedges(POSITION_TYPE_SELL);

      // A1. Auto close at open
      if(level > 0 && HedgeCloseAtOpen)
        {
         double diffPips = MathAbs(bid - oOpenBuy)/pip;
         if(diffPips <= HedgeCloseAtOpenPips)
           {
            PrintFormat("Auto-close at open (BUY): diff=%.2f pip", diffPips);
            CloseAllPositions();
            return;
           }
        }

      // A2. Net TP
      if(level > 0 && HedgeNetTPPips > 0)
        {
         double totalPL = profitOrigBuy + profitHedged;
         double maxLot  = MathMax(oLotBuy, hedgedLotSell);
         double target  = GetMoneyPerPip(maxLot) * HedgeNetTPPips;
         if(target > 0 && totalPL >= target)
           {
            PrintFormat("Hedge net TP: %.2f >= %.2f", totalPL, target);
            CloseAllPositions();
            return;
           }
        }

      // A3. Grid: buka hedge level berikutnya
      if(level < HedgeMaxLevels)
        {
         double floatingPips = (oOpenBuy - bid)/pip;

         bool trigPip  = (floatingPips >= HedgeTriggerPips);
         bool trigTime = false;
         if(UseTimeBasedHedge && oTimeBuy > 0)
           {
            double mins = (double)(TimeCurrent() - oTimeBuy)/60.0;
            if(mins >= HedgeTimeMinutes && floatingPips > 0) trigTime = true;
           }

         if(trigPip || trigTime)
           {
            int nextLevel = level + 1;
            double stepPips = HedgeTriggerPips + (nextLevel-1)*HedgeGridStepPips;

            // Grid butuh harga sudah lewat step; time-based bypass grid
            bool go = trigTime || (floatingPips >= stepPips);

            if(go)
              {
               double mult = 1.0;
               if(UseHedgeGrid && nextLevel > 1) mult = MathPow(HedgeGridMultiplier, nextLevel-1);

               double vol = NormalizeDouble(oLotBuy * HedgeLotRatio * mult, 2);
               vol = MathMax(vol, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN));

               PrintFormat("Hedge SELL L%d: loss=%.1f pip / %.1f min / vol=%.2f",
                           nextLevel, floatingPips,
                           (double)(TimeCurrent()-oTimeBuy)/60.0, vol);
               OpenTrade(ORDER_TYPE_SELL, vol);
              }
           }
        }
      return;
     }

   //========================
   // B. Original SELL
   //========================
   if(hasOrigSell)
     {
      int level = CountHedges(POSITION_TYPE_BUY);

      if(level > 0 && HedgeCloseAtOpen)
        {
         double diffPips = MathAbs(ask - oOpenSell)/pip;
         if(diffPips <= HedgeCloseAtOpenPips)
           {
            PrintFormat("Auto-close at open (SELL): diff=%.2f pip", diffPips);
            CloseAllPositions();
            return;
           }
        }

      if(level > 0 && HedgeNetTPPips > 0)
        {
         double totalPL = profitOrigSell + profitHedged;
         double maxLot  = MathMax(oLotSell, hedgedLotBuy);
         double target  = GetMoneyPerPip(maxLot) * HedgeNetTPPips;
         if(target > 0 && totalPL >= target)
           {
            PrintFormat("Hedge net TP: %.2f >= %.2f", totalPL, target);
            CloseAllPositions();
            return;
           }
        }

      if(level < HedgeMaxLevels)
        {
         double floatingPips = (ask - oOpenSell)/pip;

         bool trigPip  = (floatingPips >= HedgeTriggerPips);
         bool trigTime = false;
         if(UseTimeBasedHedge && oTimeSell > 0)
           {
            double mins = (double)(TimeCurrent() - oTimeSell)/60.0;
            if(mins >= HedgeTimeMinutes && floatingPips > 0) trigTime = true;
           }

         if(trigPip || trigTime)
           {
            int nextLevel = level + 1;
            double stepPips = HedgeTriggerPips + (nextLevel-1)*HedgeGridStepPips;
            bool go = trigTime || (floatingPips >= stepPips);

            if(go)
              {
               double mult = 1.0;
               if(UseHedgeGrid && nextLevel > 1) mult = MathPow(HedgeGridMultiplier, nextLevel-1);

               double vol = NormalizeDouble(oLotSell * HedgeLotRatio * mult, 2);
               vol = MathMax(vol, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN));

               PrintFormat("Hedge BUY L%d: loss=%.1f pip / %.1f min / vol=%.2f",
                           nextLevel, floatingPips,
                           (double)(TimeCurrent()-oTimeSell)/60.0, vol);
               OpenTrade(ORDER_TYPE_BUY, vol);
              }
           }
        }
      return;
     }
  }

//+------------------------------------------------------------------+
//| DAILY LOSS LIMIT                                                 |
//+------------------------------------------------------------------+
void CheckDailyReset()
  {
   datetime today = iTime(_Symbol, PERIOD_D1, 0);
   if(today != lastTradingDay)
     {
      lastTradingDay = today;
      dailyStopTriggered = false;
      Print("=== Hari baru: daily loss limit di-reset ===");
     }
  }

double GetClosedDailyProfit()
  {
   datetime dayStart = iTime(_Symbol, PERIOD_D1, 0);
   if(!HistorySelect(dayStart, TimeCurrent()+60)) return 0;

   double total = 0;
   int deals = HistoryDealsTotal();
   for(int i=0;i<deals;i++)
     {
      ulong t = HistoryDealGetTicket(i);
      if(t==0) continue;
      if((long)HistoryDealGetInteger(t, DEAL_MAGIC) != MagicNumber) continue;
      long entry = HistoryDealGetInteger(t, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT) continue;
      total += HistoryDealGetDouble(t, DEAL_PROFIT);
      total += HistoryDealGetDouble(t, DEAL_SWAP);
      total += HistoryDealGetDouble(t, DEAL_COMMISSION);
     }
   return total;
  }

double GetFloatingProfit()
  {
   double total=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Symbol()!=_Symbol || posInfo.Magic()!=MagicNumber) continue;
      total += posInfo.Profit() + posInfo.Swap() + posInfo.Commission();
     }
   return total;
  }

void ManageDailyLoss()
  {
   if(!UseDailyLossLimit) return;

   if(!dailyStopTriggered)
     {
      double dayPL = GetClosedDailyProfit() + GetFloatingProfit();
      if(dayPL <= -DailyLossLimitMoney)
        {
         PrintFormat(">>> Daily loss limit HIT: %.2f <= -%.2f. Close all & stop.",
                     dayPL, DailyLossLimitMoney);
         CloseAllPositions();
         dailyStopTriggered = true;
        }
     }
  }

//+------------------------------------------------------------------+
void OnTick()
  {
   CheckDailyReset();
   ManageDailyLoss();

   if(dailyStopTriggered && DailyLossStopTrading) return;

   ManageStrictHedge();
   ManageTrailingBE();

   datetime barTime = iTime(_Symbol, _Period, 0);
   if(barTime == lastBarTime) return;
   lastBarTime = barTime;

   if(BlockNewSignalDuringHedge && IsHedged())
     { Print("Hedge aktif, sinyal diblokir."); return; }

   int need = length*2 + 50;
   double close[];
   ArraySetAsSeries(close, true);
   if(CopyClose(_Symbol, _Period, 0, need, close) < need) return;

   int signal = GetSignal(close, need);
   if(signal == 0) return;

   if(CloseOnOpposite)
     {
      if(signal ==  1) ClosePositionsByType(POSITION_TYPE_SELL);
      if(signal == -1) ClosePositionsByType(POSITION_TYPE_BUY);
     }
   if(OnePositionOnly && HasPosition()) return;

   if(signal ==  1 && !HasPositionOfType(POSITION_TYPE_BUY))
      OpenTrade(ORDER_TYPE_BUY);
   else if(signal == -1 && !HasPositionOfType(POSITION_TYPE_SELL))
      OpenTrade(ORDER_TYPE_SELL);
  }
//+------------------------------------------------------------------+
