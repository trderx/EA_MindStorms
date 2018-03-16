//+------------------------------------------------------------------+
//|                                              MGH EA_v4.2.mq4
//+------------------------------------------------------------------+
#property copyright "Copyright   18.11.2014, SwingMan"

#property description "MGH System (Martingale Grid & Hedging) by Kfx"
#property description "http://www.forexfactory.com/showthread.php?t=497448"
#property description "EA autor: GoldenEA; some changes: SwingMan"
#property description "minor modifications proposed by Paracelsus #post 707"

/*--------------------------------------------------------------------
07.11.2014  -  v2.4  -  error corrections
08.11.2014  -  v3.1  -  lot calculation with the new algorithm, not on line
10.11.2014  -  v4.1  -  Grid calculation with ATR
18.11.2014  -  v4.2  -  get Batch infos after a program restart
--------------------------------------------------------------------*/

#include <WinUser32.mqh>
#include "OrderSendReliable_v2.1.mqh"
//
enum ENUM_ENTRY_METHOD
  {
   EMA_Slope,
   Close_And_EMA_200
  };
//--- input parameters
//===================================================================
input bool Enable_Variable_ATRgrid=false;
input bool Entry_OnlyAtNewBars=false;
extern   int   BaseOrder_Grid=10;
extern double  BaseLot=0.10;
extern double  SecondLot_PercentBaseLot=50;
input bool Use_LotMultiplier=false;
input double LotMultiplier=2.50;
input double TakeProfit_GridFactor=2.0;
input double Basket_TakeProfit=0;
input int Maximum_Baskets=15;
int     MaxLevel=2;
extern int     MagicNo=4200;
input ENUM_ENTRY_METHOD Entry_Method=EMA_Slope;
input string ___Parameter_EMA_Slope="-------------------------------------------";
input int ma_period=32;
input ENUM_MA_METHOD ma_method=MODE_EMA;
input ENUM_APPLIED_PRICE applied_price=PRICE_TYPICAL;
input ENUM_TIMEFRAMES timeFrameDirection=PERIOD_M15;
input string ___Parameter_EMA_200="-------------------------------------------";
input int ema_period=200;
input ENUM_APPLIED_PRICE ema_price=PRICE_CLOSE;
input ENUM_TIMEFRAMES ema_timeFrameDirection=PERIOD_H1;
input string ____ATR="-----------------------------------------------";
input int ATR_Period=14;
input int ATR_SmoothingPeriod=5;
input string ____Show_Infos="-----------------------------------------------";
input bool Show_Comment=true;
input bool Show_CheckReport=true;
//
//....................................................................
double OrderGap;

//===================================================================
//
string  TextDisplay;
double  pt;
//---- constants
string TradeComment="mghA";
string CR="\n";
color cColorBUY=clrDodgerBlue;
color cColorSELL=clrRed;
color cColorCLOSE=clrGoldenrod;

//---- variables
int    numBuy,numSell,prevnumBuy,prevnumSell,numPenBuy,numPenSell;
double maxBuyLots,maxSellLots,totalProfit,AllProfit,prevEquity=0,currEquity=0;

double lowestBuyPrice,highestSellPrice,lowestSellPrice,highestBuyPrice;
double lastBuyPrice,lastSellPrice;
double totalSellProfit,totalBuyProfit;
int lastBatchType;
int maxBatchCount;
double lastLotsNumber;
double AveragePrice,TotalVolume;
double maxLots;

double firstBuyTP,firstSellTP;
int nBatchCount;

bool newBar;
datetime oldTime;
//
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void init()
  {
   pt=Point;
   if(Digits==3 || Digits==5) pt=10*pt;
   oldTime=0;

//-- to get on restarts!
   lastBatchType=-1;

//-- draw missing order arrows and trendlines; possible after restarts
   Get_BatchInfos();
   Draw_MissingTrendLines();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void deinit()
  {
   if(IsTesting()==false)
      Comment("");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void start()
  {
   CountOrders();
   if(numBuy==0 && numSell==0)
     {
      prevEquity=AccountEquity();
     }
   if(numBuy!=0 || numSell!=0) currEquity=AccountEquity();

   prevnumSell=numSell;
   prevnumBuy=numBuy;
   double tp=0;

//-- check new bar
   datetime thisTime=Time[0];
   if(thisTime!=oldTime)
     {
      newBar=true;
      oldTime=thisTime;
     }
   else
      newBar=false;

   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderSymbol()==Symbol() && OrderTakeProfit()==0)
        {
         //-- set TakeProfit for SELL orders -----------
         if(OrderType()==OP_SELL && numSell<=MaxLevel)
           {
            if(numSell==1)
              {
               tp=lowestSellPrice -OrderGap*TakeProfit_GridFactor *pt;
               firstSellTP=tp;
               SetTakeProfit(OP_SELL,tp);
              }
            if(numSell>1 && nBatchCount==1)
              {
               if(firstBuyTP==0) //possible after restarts
                 {
                  tp=lowestSellPrice -OrderGap*TakeProfit_GridFactor *pt;
                  firstSellTP=tp;
                 }
               else
                  tp=firstSellTP;
               if(Ask<tp) //possible after restarts
                 {
                  CloseOpenPairPositions();
                 }
               else
                  SetTakeProfit(OP_SELL,tp);
              }
           }
         //-- set TakeProfit for BUY orders ------------
         if(OrderType()==OP_BUY && numBuy<=MaxLevel)
           {
            if(numBuy==1)
              {
               tp=highestBuyPrice+OrderGap*TakeProfit_GridFactor *pt;
               firstBuyTP=tp;
               SetTakeProfit(OP_BUY,tp);
              }
            if(numBuy>1 && nBatchCount==1)
              {
               if(firstBuyTP==0) //possible after restarts
                 {
                  tp=highestBuyPrice+OrderGap*TakeProfit_GridFactor *pt;
                  firstBuyTP=tp;
                 }
               else
                  tp=firstBuyTP;
               if(Bid>=tp) //possible after restarts
                 {
                  CloseOpenPairPositions();
                 }
               else
                  SetTakeProfit(OP_BUY,tp);
              }
           }
        }
     }

//=========================================================
   double OpenProfit=totalBuyProfit+totalSellProfit;
   string sEmpty="                                ";
   TextDisplay="\n\n"+sEmpty+"Order Grid= "+NormalizeDouble(OrderGap,0)+"   Spread= "+MarketInfo(Symbol(),MODE_SPREAD)+
               "\n"+sEmpty+"Open Buy: "+numBuy+" Open Sell: "+numSell+"   maxLot= "+MarketInfo(Symbol(),MODE_MAXLOT)+
               "\n"+sEmpty+"Open Sell Profit: "+DoubleToString(totalSellProfit,2)+"  Open Buy Profit: "+DoubleToString(totalBuyProfit,2)+
               "\n"+sEmpty+"Open Profit: "+DoubleToString(OpenProfit,2)+
               "\n"+sEmpty+"BatchCount= "+nBatchCount+"   (maxBatchCount= "+maxBatchCount+"  maxLots= "+DoubleToString(maxLots,2)+")"+
               "\n\n"+sEmpty+"highestBuyPrice= "+DoubleToString(highestBuyPrice,Digits)+"   lowestBuyPrice= "+DoubleToString(lowestBuyPrice,Digits)+
               "\n"+sEmpty+"highestSellPrice = "+DoubleToString(highestSellPrice,Digits)+"   lowestSellPrice= "+DoubleToString(lowestSellPrice,Digits);

   if(Show_CheckReport==true)
      TextDisplay=CheckReport()+TextDisplay;

   if(Show_Comment==true)
      Comment(TextDisplay);

//-- close all orders
   if(numBuy+numSell>1 && OpenProfit>=Basket_TakeProfit && nBatchCount>1)
      CloseOpenPairPositions();

   ManageOrders();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ManageOrders()
  {
   CountOrders();
   double Lots=0;

   int iDirection=Get_TrendDirection();
   if(numBuy==0 && numSell==0 && iDirection!=OP_BUY && iDirection!=OP_SELL)
      return;

   double dNumBuy=1.0*numBuy;
   double dNumSell=1.0*numSell;
   double dMaxLevel=1.0*MaxLevel;

   if(OrderGap==0)
     {
      if(Enable_Variable_ATRgrid==true) OrderGap=NormalizeDouble(Get_ATRvalue()/pt,0);
      else OrderGap=BaseOrder_Grid;
     }

//===================================================================
//-- BUY orders
//===================================================================
//== Batch 1 BUY =========
   if(numSell==0)
     {
      //-- Batch 1; first BUY order
      if(numBuy==0 && iDirection==OP_BUY)
        {
         if(Entry_OnlyAtNewBars==true && newBar==false)
            return;
         if(Enable_Variable_ATRgrid==true) OrderGap=NormalizeDouble(Get_ATRvalue()/pt,0);
         else OrderGap=BaseOrder_Grid;

         nBatchCount=1;
         if(nBatchCount>maxBatchCount) maxBatchCount=nBatchCount;
         Lots=Get_LotsNumber(nBatchCount,1);
         lastBatchType=OP_BUY;
         Print("  ### BUY;  BatchCount= ",nBatchCount,"   Lots= ",DoubleToStr(Lots,2),"  Time= ",TimeToString(TimeCurrent()),
               "   Ask= ",DoubleToString(Bid,Digits),"   maxBatchCount= ",maxBatchCount);
         RefreshRates();
         PlaceSingleOrder(Symbol(),OP_BUY,Lots,Ask);
         return;
        }
      else
      //-- Batch 1; second BUY order
      if(numBuy>0 && numBuy<MaxLevel)
        {
         if(Ask<=(highestBuyPrice-OrderGap*pt))
           {
            Lots=Get_LotsNumber(nBatchCount,2);
            RefreshRates();
            PlaceSingleOrder(Symbol(),OP_BUY,Lots,Ask);
            return;
           }
        }
     }
   else
//== Batch N BUY =========
   if(numSell>0 && MathMod(dNumSell,dMaxLevel)==0)
     {
      //-- Batch N;  first BUY order above SELL Batch
      if(MathMod(dNumBuy,dMaxLevel)==0 && lastBatchType==OP_SELL)
        {
         if(nBatchCount==Maximum_Baskets)
           {
            Print("  ### CLOSE ALL BATCHES","  BatchCount= ",nBatchCount);
            CloseOpenPairPositions();
            nBatchCount=0;
            return;
           }
         if(Ask>=(highestSellPrice+OrderGap*pt))
           {
            if(nBatchCount==1)
               DeleteTakeProfit(OP_SELL);
            nBatchCount++;
            if(nBatchCount>maxBatchCount) maxBatchCount=nBatchCount;
            Lots=Get_LotsNumber(nBatchCount,1);
            lastBatchType=OP_BUY;
            Print("  ### BUY;  BatchCount= ",nBatchCount,"   Lots= ",DoubleToStr(Lots,2),"  Time= ",TimeToString(TimeCurrent()),
                  "   Ask= ",DoubleToString(Ask,Digits),"   maxBatchCount= ",maxBatchCount);
            RefreshRates();
            PlaceSingleOrder(Symbol(),OP_BUY,Lots,Ask);
            return;
           }
        }
      else
      //-- Batch N; second BUY order
      if(MathMod(dNumBuy,dMaxLevel)>0)
        {
         if(Ask<=(highestBuyPrice-OrderGap*pt))
           {
            Lots=Get_LotsNumber(nBatchCount,2);
            RefreshRates();
            PlaceSingleOrder(Symbol(),OP_BUY,Lots,Ask);
            return;
           }
        }
     }

//===================================================================
//-- SELL orders
//===================================================================
//== Batch 1 SELL =========
   if(numBuy==0)
     {
      //-- Batch 1; first SELL order
      if(numSell==0 && iDirection==OP_SELL)
        {
         if(Entry_OnlyAtNewBars==true && newBar==false)
            return;
         if(Enable_Variable_ATRgrid==true) OrderGap=NormalizeDouble(Get_ATRvalue()/pt,0);
         else OrderGap=BaseOrder_Grid;
         nBatchCount=1;
         if(nBatchCount>maxBatchCount) maxBatchCount=nBatchCount;
         Lots=Get_LotsNumber(nBatchCount,1);
         lastBatchType=OP_SELL;
         Print("  ### SELL;  BatchCount= ",nBatchCount,"   Lots= ",DoubleToStr(Lots,2),"  Time= ",TimeToString(TimeCurrent()),
               "   Bid= ",DoubleToString(Bid,Digits),"   maxBatchCount= ",maxBatchCount);
         RefreshRates();
         PlaceSingleOrder(Symbol(),OP_SELL,Lots,Bid);
         return;
        }
      else
      //-- Batch 1; second SELL order
      if(numSell>0 && numSell<MaxLevel)
        {
         if(Bid>=(lowestSellPrice+OrderGap*pt))
           {
            Lots=Get_LotsNumber(nBatchCount,2);
            RefreshRates();
            PlaceSingleOrder(Symbol(),OP_SELL,Lots,Bid);
            return;
           }
        }
     }
   else
//== Batch N SELL =========     
   if(numBuy>0 && MathMod(dNumBuy,dMaxLevel)==0)
     {
      //-- Batch N;  first SELL order belove BUY Batch
      if(MathMod(dNumSell,dMaxLevel)==0 && lastBatchType==OP_BUY)
        {
         if(nBatchCount==Maximum_Baskets)
           {
            Print("  ### CLOSE ALL BATCHES","  BatchCount= ",nBatchCount);
            CloseOpenPairPositions();
            nBatchCount=0;
            return;
           }
         if(Bid<=(lowestBuyPrice-OrderGap*pt))
           {
            if(nBatchCount==1)
               DeleteTakeProfit(OP_BUY);
            nBatchCount++;
            if(nBatchCount>maxBatchCount) maxBatchCount=nBatchCount;
            Lots=Get_LotsNumber(nBatchCount,1);
            lastBatchType=OP_SELL;
            Print("  ### SELL;  BatchCount= ",nBatchCount,"   Lots= ",DoubleToStr(Lots,2),"  Time= ",TimeToString(TimeCurrent()),
                  "   Bid= ",DoubleToString(Bid,Digits),"   maxBatchCount= ",maxBatchCount);
            RefreshRates();
            PlaceSingleOrder(Symbol(),OP_SELL,Lots,Bid);
            return;
           }
        }
      else
      //-- Batch N;  second SELL order
      if(MathMod(dNumSell,dMaxLevel)>0)
        {
         if(Bid>=(lowestSellPrice+OrderGap*pt))
           {
            Lots=Get_LotsNumber(nBatchCount,2);
            RefreshRates();
            PlaceSingleOrder(Symbol(),OP_SELL,Lots,Bid);
            return;
           }
        }
     }
  }
//  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Get_LotsNumber(int BatchCount,int tradeNumber)
  {
   double dLots;

//-- version Paracelsus ----------------------
   if(Use_LotMultiplier==true)
     {
      if(tradeNumber==1)
        {
         dLots=BaseLot*MathPow(LotMultiplier,BatchCount-1);
         lastLotsNumber=dLots;
        }
      else
         dLots=lastLotsNumber;
     }
   else
//-- values for initial lots 0.10 and 0.05 ---
     {
      double baseLotFactor=BaseLot/0.10;
      double secondLotFactor=BaseLot*(SecondLot_PercentBaseLot/100.0)/0.05;

      //-- first order --------------------------------
      if(tradeNumber==1)
        {
         if(BatchCount==1) dLots=0.10; else
         if(BatchCount==2) dLots=0.28; else
         if(BatchCount==3) dLots=0.48; else
         if(BatchCount==4) dLots=1.08; else
         if(BatchCount==5) dLots=2.43; else
         if(BatchCount==6) dLots=5.47; else
         if(BatchCount==7) dLots=12.30; else
         if(BatchCount==8) dLots=27.68; else
         if(BatchCount==9) dLots=62.28; else
         if(BatchCount==10) dLots=140.13; else
         if(BatchCount==11) dLots=315.30; else
         if(BatchCount==12) dLots=709.42; else
         if(BatchCount==13) dLots=1596.20; else
         if(BatchCount==14) dLots=3591.45; else
         if(BatchCount==15) dLots=8080.75;
         dLots=dLots*baseLotFactor;
        }
      else
      //-- second order -------------------------------
      if(tradeNumber==2)
        {
         if(BatchCount==1) dLots=0.05; else
         if(BatchCount==2) dLots=0.06; else
         if(BatchCount==3) dLots=0.14; else
         if(BatchCount==4) dLots=0.32; else
         if(BatchCount==5) dLots=0.73; else
         if(BatchCount==6) dLots=1.64; else
         if(BatchCount==7) dLots=3.69; else
         if(BatchCount==8) dLots=8.30; else
         if(BatchCount==9) dLots=18.68; else
         if(BatchCount==10) dLots=42.04; else
         if(BatchCount==11) dLots=94.59; else
         if(BatchCount==12) dLots=212.83; else
         if(BatchCount==13) dLots=478.86; else
         if(BatchCount==14) dLots=1077.43; else
         if(BatchCount==15) dLots=2424.23;
         dLots=dLots*secondLotFactor;
        }
     }
   dLots=NormalizeDouble(dLots,2);
   double marketMaxLots=MarketInfo(Symbol(),MODE_MAXLOT);
   if(dLots>marketMaxLots) dLots=marketMaxLots;
   if(dLots>maxLots) maxLots=dLots;
   return(dLots);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CheckReport()
  {
   static string   ProfitReport="";
   static int   TimeToReport = 0;
   static int   TradeCounter = 0;
#define Daily    0
#define Weekly   1
#define Monthly  2
#define All      3

   if(TradeCounter!=HistoryTotal())
     {
      TradeCounter = HistoryTotal();
      TimeToReport = 0;
     }

   if(TimeLocal()>TimeToReport)
     {
      TimeToReport=TimeLocal()+300;
      double   Profit[10],Lots[10],Count[10];
      ArrayInitialize(Profit,0);
      ArrayInitialize(Lots,0.000001);
      ArrayInitialize(Count,0.000001);

      int Today     = TimeCurrent() - (TimeCurrent() % 86400);
      int ThisWeek  = Today - TimeDayOfWeek(Today)*86400;
      int ThisMonth = TimeMonth(TimeCurrent());
      for(int i=0; i<HistoryTotal(); i++)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) && OrderSymbol()==Symbol() && OrderCloseTime()>0 && OrderComment()==TradeComment)
           {
            Count[All]+=1;
            Profit[All]+=OrderProfit()+OrderSwap();
            Lots[All]+=OrderLots();
            if(OrderCloseTime()>=Today)
              {
               Count[Daily]+=1;
               Profit[Daily]+=OrderProfit()+OrderSwap();
               Lots[Daily]+=OrderLots();
              }
            if(OrderCloseTime()>=ThisWeek)
              {
               Count[Weekly]+=1;
               Profit[Weekly]+=OrderProfit()+OrderSwap();
               Lots[Weekly]+=OrderLots();
              }
            if(TimeMonth(OrderCloseTime())==ThisMonth)
              {
               Count[Monthly]+=1;
               Profit[Monthly]+=OrderProfit()+OrderSwap();
               Lots[Monthly]+=OrderLots();
              }
           }
        }
      double OpenProfit=totalBuyProfit+totalSellProfit;

      ProfitReport="\n\n                                 PROFIT REPORT ( "+AccountCurrency()+" )"+
                   "\n                                Today: "+DoubleToStr(Profit[Daily],2)+
                   "\n                                This Week: "+DoubleToStr(Profit[Weekly],2)+
                   "\n                                This Month: "+DoubleToStr(Profit[Monthly],2)+
                   "\n                                ## All Profits: "+DoubleToStr(Profit[All],2)+" ##"+
                   "\n                                All Trades: "+DoubleToStr(Count[All],0)+"  (Average "+DoubleToStr(Profit[All]/Count[All],2)+" per trade)"+
                   "\n                                All Lots: "+DoubleToStr(Lots[All],2)+"  (Average "+DoubleToStr(Profit[All]/Lots[All],2)+" per lot)";
     }
   return (ProfitReport);
  }
//+------------------------------------------------------------------+
int Get_TrendDirection()
//+------------------------------------------------------------------+
  {
   int iDirection;

//-- entry PARACELSUS -----------------------------------------------
   if(Entry_Method==Close_And_EMA_200)
     {
      double dClose1=iClose(Symbol(),ema_timeFrameDirection,1);
      double dEMA1=iMA(Symbol(),ema_timeFrameDirection,ema_period,0,MODE_EMA,ema_price,1);
      if(dClose1>=dEMA1)
         iDirection=OP_BUY;
      else
      if(dClose1<dEMA1)
         iDirection=OP_SELL;
     }
   else
   if(Entry_Method==EMA_Slope)
     {
      //-- entry SnowBall -------------------------------------------------  
      int signalBar=1;

      double avg10 = iMA(Symbol(),timeFrameDirection,ma_period,0,ma_method,applied_price,signalBar);
      double avg11 = iMA(Symbol(),timeFrameDirection,ma_period,1,ma_method,applied_price,signalBar);
      double diff10= 10000*(avg10-avg11)/avg10;

      double avg20 = iMA(Symbol(),timeFrameDirection,ma_period,0,ma_method,applied_price,signalBar+1);
      double avg21 = iMA(Symbol(),timeFrameDirection,ma_period,1,ma_method,applied_price,signalBar+1);
      double diff20= 10000*(avg20-avg21)/avg20;

      double avg30 = iMA(Symbol(),timeFrameDirection,ma_period,0,ma_method,applied_price,signalBar+2);
      double avg31 = iMA(Symbol(),timeFrameDirection,ma_period,1,ma_method,applied_price,signalBar+2);
      double diff30= 10000*(avg30-avg31)/avg30;

      double avg40 = iMA(Symbol(),timeFrameDirection,ma_period,0,ma_method,applied_price,signalBar+3);
      double avg41 = iMA(Symbol(),timeFrameDirection,ma_period,1,ma_method,applied_price,signalBar+3);
      double diff40= 10000*(avg40-avg41)/avg40;

      double trigger1= (diff10+diff20+diff30)/3.0;
      double trigger2= (diff20+diff30+diff40)/3.0;

      //-- trend direction; condition for two bars
      iDirection=-100;
      if( (diff10>0 && diff10>trigger1) || (diff20>0 && diff20>trigger2)) iDirection= OP_BUY; else
      if( (diff10<0 && diff10<trigger1) || (diff20<0 && diff30<trigger2)) iDirection= OP_SELL;
     }
   return(iDirection);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PlaceSingleOrder(string sym,int type,double lotsize,double price)
  {
   int ticket;
   color cColor;
   if(type==OP_BUY) cColor=cColorBUY; else
   if(type==OP_SELL) cColor=cColorSELL;

   lotsize=NormalizeDouble(lotsize,2);

   ticket=OrderSendReliable(sym,type,lotsize,price,0,0,0,TradeComment,MagicNo,0,cColor);

   if(ticket>0 && type==OP_SELL)
     {
      while(prevnumSell==numSell)
        {
         CountOrders();
        }
      prevnumSell=numSell;
     }

   if(ticket>0 && type==OP_BUY)
     {
      while(prevnumBuy==numBuy)
        {
         CountOrders();
        }
      prevnumBuy=numBuy;
     }

   if(ticket<0)
     {
      // error handling: to be implemented
      int e=GetLastError();
      Print("Error: "+DoubleToStr(e,0));
     }
// }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CountOrders()
  {
   numBuy=0; numSell=0; maxBuyLots=0; maxSellLots=0; totalSellProfit=0; totalBuyProfit=0;
   double buyProfit1=0; double buyProfit2=0; double sellProfit1=0; double sellProfit2=0;
   lowestBuyPrice=9999; lowestSellPrice=9999;
   highestBuyPrice=0;   highestSellPrice=0;
   bool bRes;

   for(int cnt=0; cnt<OrdersTotal(); cnt++)
     {
      bRes=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         //-- BUY order -------------------------
         if(OrderType()==OP_BUY)
           {
            numBuy++;
            buyProfit1+=OrderProfit()+OrderSwap()+OrderCommission();
            if(OrderOpenPrice()<lowestBuyPrice)
               lowestBuyPrice=OrderOpenPrice();

            if(OrderOpenPrice()>highestBuyPrice)
               highestBuyPrice=OrderOpenPrice();

            if(OrderLots()>maxBuyLots)
               maxBuyLots=OrderLots();
           }
         //-- SELL order ------------------------
         else if(OrderType()==OP_SELL)
           {
            numSell++;
            sellProfit1+=OrderProfit()+OrderSwap()+OrderCommission();
            if(OrderOpenPrice()>highestSellPrice)
               highestSellPrice=OrderOpenPrice();

            if(OrderOpenPrice()<lowestSellPrice)
               lowestSellPrice=OrderOpenPrice();

            if(OrderLots()>maxSellLots)
               maxSellLots=OrderLots();
           }

         totalBuyProfit=buyProfit1;
         totalSellProfit=sellProfit1;
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Get_BatchInfos()
  {
   int cnt;
   int previousOrderType=-1;
   bool bRes;
   string sOrderType;
   int numOrder=0;
   double open1,open2;

   nBatchCount=0;
   maxBatchCount=0;
   maxLots=0;
   numBuy=0;
   numSell=0;

   for(cnt=0; cnt<OrdersTotal(); cnt++)
     {
      bRes=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         //-- BUY orders ------------------------
         if(OrderType()==OP_BUY)
           {
            numBuy++;
            if(numOrder==0)
              {
               numOrder++;
               open1=OrderOpenPrice();
              }
            else
            if(numOrder==1)
              {
               numOrder++;
               open2=OrderOpenPrice();
              }
            if(OrderType()!=previousOrderType)
              {
               nBatchCount++;
               if(nBatchCount>maxBatchCount) maxBatchCount=nBatchCount;
               if(OrderLots()>maxLots) maxLots=OrderLots();
               previousOrderType=OrderType();
               lastBatchType=OP_BUY;
               lastLotsNumber=OrderLots();
              }
            Check_OpenOrderArrow(OrderTicket(),"buy",OrderLots(),OrderSymbol(),OrderOpenTime(),OrderOpenPrice(),cColorBUY);
            sOrderType="BUY";
           }
         else
         //-- SELL orders -----------------------
         if(OrderType()==OP_SELL)
           {
            numSell++;
            if(numOrder==0)
              {
               numOrder++;
               open1=OrderOpenPrice();
              }
            else
            if(numOrder==1)
              {
               numOrder++;
               open2=OrderOpenPrice();
              }
            if(OrderType()!=previousOrderType)
              {
               nBatchCount++;
               if(nBatchCount>maxBatchCount) maxBatchCount=nBatchCount;
               if(OrderLots()>maxLots) maxLots=OrderLots();
               previousOrderType=OrderType();
               lastBatchType=OP_SELL;
               lastLotsNumber=OrderLots();
              }
            Check_OpenOrderArrow(OrderTicket(),"sell",OrderLots(),OrderSymbol(),OrderOpenTime(),OrderOpenPrice(),cColorSELL);
            sOrderType="SELL";
           }
        }
     }

   if(open1!=0 && open2!=0)
     {
      OrderGap=MathAbs(open1 -open2)/pt;
     }
   else   
     {
      if(Enable_Variable_ATRgrid==true) OrderGap=NormalizeDouble(Get_ATRvalue()/pt,0);
      else OrderGap=BaseOrder_Grid;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Check_OpenOrderArrow(int iTicket,string sType,double dLots,string sSymbol,datetime tTime,double dPrice,color cColor)
  {
   int iArrowCode=1;
//-- example:
//-- #52384454 sell 0.32 USDJPY at 115.73600
   string sTicket="#"+iTicket+" "+sType;
   string sArrow="#"+iTicket+" "+sType+DoubleToString(dLots,2)+" "+sSymbol+" at "+DoubleToString(dPrice,Digits);

   int obj_total=ObjectsTotal();

   for(int i=obj_total; i>=0; i--)
     {
      string objName=ObjectName(i);
      if(StringFind(objName,sTicket,0)!=-1)
         return;
     }
//-- draw arrow
   ObjectCreate(sArrow,OBJ_ARROW,0,tTime,dPrice);
   ObjectSet(sArrow,OBJPROP_COLOR,cColor);
   ObjectSet(sArrow,OBJPROP_ARROWCODE,iArrowCode);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void  DeleteTakeProfit(int type)
  {
//-- delete take profit for Batch 2
   if(nBatchCount>1)
      return;

   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderSymbol()==Symbol() && OrderType()==type)
         ModifySelectedOrder(type,0);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void  SetTakeProfit(int type,double tp)
  {
//-- set take profit only for Batch 1
   if(nBatchCount>1)
      return;

   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderSymbol()==Symbol() && OrderType()==type)
         ModifySelectedOrder(type,tp);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseOpenPairPositions()
  {
   bool bRes;
   for(int i=10; i>=0; i--)
     {
      for(int cnt=OrdersTotal()-1; cnt>=0; cnt--)
        {
         bRes=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
         if(OrderMagicNumber()==MagicNo)
           {
            if(OrderType()==OP_BUY && OrderSymbol()==Symbol())
               OrderCloseReliable(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),5);
            else
            if(OrderType()==OP_SELL && OrderSymbol()==Symbol())
               OrderCloseReliable(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),5);
           }
        }
     }
//-- draw the trendlines, becausae MT4 dont do this
   Draw_MissingTrendLines();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ModifySelectedOrder(int type,double tp)
  {
   bool ok=OrderModifyReliable(OrderTicket(),OrderOpenPrice(),0,tp,0);
   if(!ok)
     {
      int err=GetLastError();
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Punto(string symbol)
  {
   if(StringFind(symbol,"JPY")>=0)
     {
      return(0.01);
     }
   else
     {
      return(0.0001);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SPREAD()
  {
   double vthis=(Ask-Bid)/Punto(Symbol());
   return(vthis);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Get_ATRvalue()
  {
   int iBar=1;
   double thisATR=0;
   double sumI=0;
   double xATR;
   int timeFrame=Period();

   double lastATR=iATR(Symbol(),PERIOD_D1,ATR_Period,iBar);
   for(int ia=0; ia<ATR_SmoothingPeriod; ia++)
     {
      thisATR=thisATR+iATR(Symbol(),timeFrame,ATR_Period,iBar+ia);
      sumI++;
     }
   xATR=thisATR/sumI;
   return (xATR);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Draw_MissingTrendLines()
  {
   int cnt;
   bool bRes;

   for(cnt=OrdersHistoryTotal()-1; cnt>=0; cnt--)
     {
      bRes=OrderSelect(cnt,SELECT_BY_POS,MODE_HISTORY);
      if(OrderSymbol()==Symbol())
        {
         //-- BUY orders ------------------------
         if(OrderType()==OP_BUY)
           {
            Check_CloseOrderArrow(OrderTicket(),"buy",OrderLots(),OrderSymbol(),
                                  OrderOpenTime(),OrderOpenPrice(),
                                  OrderCloseTime(),OrderClosePrice(),cColorCLOSE,cColorBUY);
           }
         else
         //-- SELL orders -----------------------
         if(OrderType()==OP_SELL)
           {
            Check_CloseOrderArrow(OrderTicket(),"sell",OrderLots(),OrderSymbol(),
                                  OrderOpenTime(),OrderOpenPrice(),
                                  OrderCloseTime(),OrderClosePrice(),cColorCLOSE,cColorSELL);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Check_CloseOrderArrow(int iTicket,string sType,double dLots,string sSymbol,
                           datetime tOpenTime,double dOpenPrice,
                           datetime tCloseTime,double dClosePrice,color cColorCloseArrow,color cColorTrend)
  {
//-- example:
//-- #52378378 buy 0.10 EURUSD at 1.24369 close at 1.24632
//-- #52378378 1.24369 -> 1.24632
   int iOpenArrowCode=1;
   int iCloseArrowCode=3;
   bool objExist;
   int i;
   string objName;
   int obj_total=ObjectsTotal();

//===============================================
//-- check open arrow
//===============================================
   string sOpenArrow="#"+(string)iTicket+" "+sType+" "+DoubleToString(dLots,2)+" "+sSymbol+" at "+DoubleToString(dOpenPrice,Digits);

   objExist=false;
   for(i=obj_total; i>=0; i--)
     {
      objName=ObjectName(i);
      if(StringFind(objName,sOpenArrow,0)!=-1)
        {
         objExist=true;
         break;
        }
     }
   if(objExist==false)
     {
      ObjectCreate(sOpenArrow,OBJ_ARROW,0,tOpenTime,dOpenPrice);
      ObjectSet(sOpenArrow,OBJPROP_COLOR,cColorTrend);
      ObjectSet(sOpenArrow,OBJPROP_ARROWCODE,iOpenArrowCode);
     }

//===============================================
//-- check close arrow
//===============================================
   string sCloseArrow="#"+(string)iTicket+" "+sType+" "+DoubleToString(dLots,2)+" "+sSymbol+" at "+DoubleToString(dOpenPrice,Digits)+
                      " close at "+DoubleToString(dClosePrice,Digits);

   objExist=false;
   for(i=obj_total; i>=0; i--)
     {
      objName=ObjectName(i);
      if(StringFind(objName,sCloseArrow,0)!=-1)
        {
         objExist=true;
         break;
        }
     }
   if(objExist==false)
     {
      ObjectCreate(sCloseArrow,OBJ_ARROW,0,tCloseTime,dClosePrice);
      ObjectSet(sCloseArrow,OBJPROP_COLOR,cColorCloseArrow);
      ObjectSet(sCloseArrow,OBJPROP_ARROWCODE,iCloseArrowCode);
     }

//===============================================
//-- check trend line
//===============================================
   string sTrendLine="#"+(string)iTicket+" "+DoubleToString(dOpenPrice,Digits)+" -> "+DoubleToString(dClosePrice,Digits);

   objExist=false;
   for(i=obj_total; i>=0; i--)
     {
      objName=ObjectName(i);
      if(StringFind(objName,sTrendLine,0)!=-1)
        {
         objExist=true;
         break;
        }
     }
   if(objExist==false)
     {
      ObjectCreate(sTrendLine,OBJ_TREND,0,tOpenTime,dOpenPrice,tCloseTime,dClosePrice);
      ObjectSet(sTrendLine,OBJPROP_COLOR,cColorTrend);
      ObjectSet(sTrendLine,OBJPROP_STYLE,STYLE_DOT);
      ObjectSet(sTrendLine,OBJPROP_RAY,false);
     }
  }
//+------------------------------------------------------------------+
