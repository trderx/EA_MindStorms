
//+------------------------------------------------------------------+
//|                      Hercules A.T.C(barabashkakvn's edition).mq5 |
//|                                                         David J. Lin |
//|                                                                      |
//|Based on a 72-period crossover strategy by something_witty IBFX forum |
//|      Vince ( forexportfolio@hotmail.com )                            |  
//|                                                                      |
//|  - Trigger = price exceeds Trigger pips above/below crossover        |
//|              of current price and 72-period SMA                      |
//|  - Stoploss = low of last bar if long, high of last bar if short     |
//|  - Double order executed at trigger - you can takeprofit with one    |
//|     and let the other one ride with trailing stop.                   |
//|    (Trailing stop is applied to both orders.)                        |
//|  - Timeframe = recommended: H1 or longer, but this EA can be applied |
//|     to any timeframe.                                                |
//|  - Pairs = Any, but with current parameters,                         |
//|     EURUSD shows greatest profit in 2006                             |
//|  - Money Management = stoploss.  WARNING:  this EA does NOT take     |
//|     margin considerations into account, so beware of margin          |
//|                                                                      |
//|Coded by David J. Lin                                                 |
//|                                                                      |
//|Evanston, IL, September 11, 2006                                      |
//|                                                                      |
//|TakeLong, TakeShort, and TrailingAlls coded by Patrick (IBFX tutorial)|
//+----------------------------------------------------------------------+
//| 07/04/08 - Added Money Management routine by Azmel.                  |
//|          - Added H4 RSI 14 filter and H10 High/Low filter.           |
//|          - Added H4 72 SMA 32 filter.                                |
//| 08/04/08 - Replaced SMA filter with Envelope filter.                 |
//|          - Added Blackout time period.                               |
//+----------------------------------------------------------------------+
#property copyright ""
#property link      ""
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
input double InpLots=0.01;          // lots to trade (fractional values ok)
input bool   MoneyManagement=true;
input double Risk=2.5;
input int Trigger=38;            // pips above crossover to trigger   
input int TrailingStop=90;       // pips to trail both orders 
input int TakeProfit1=210;         // pips take profit order #1
input int TakeProfit2=280;         // pips take profit order #2

input int MA1Period=1;           // EMA(1) acts as trigger line to gauge immediate price action 
input int MA1Shift=0;            // Shift
input ENUM_MA_METHOD  MA1Method=MODE_EMA;    // Mode
input ENUM_APPLIED_PRICE  MA1Price=PRICE_CLOSE;  // Method

input int MA2Period=72;          // SMA(72) acts as base line
input int MA2Shift=32;            // Shift
input ENUM_MA_METHOD  MA2Method=MODE_SMA;    // Mode
input ENUM_APPLIED_PRICE  MA2Price=PRICE_OPEN;  // Method

input double RSI_Upper = 55;
input double RSI_Lower = 45;
input int    BlackoutPeriod=144;

string BlackoutStatus="";
datetime BlackoutStart=0;

long Leverage=0;
double BarsCount=0.0;
double RSI=0.0;
double ENU=0.0;
double ENL=0.0;
double ENU2=0.0;
double ENL2=0.0;
double High10H=0.0;
double Low10H=0.0;

bool flag_check=true;             // flag to gauge order status                     
datetime lasttime=0;              // stores current bar's time to trigger MA calculation
datetime crosstime=0;             // stores most recent crossover time
double crossprice=0.0;                // stores price at crossover, calculate 4 point average

double fast1=0.0;                     // stores MA values up to 3 completed bars ago
double fast2=0.0;                     // fast = current price action, approximated by EMA(1)
double fast3=0.0;                     // slow = base line, SMA(10)
double slow1=0.0;
double slow2=0.0;
double slow3=0.0;
//---
ulong          m_magic=204633912;                // magic number
double ExtLots=0;ENUM_ACCOUNT_MARGIN_MODE m_margin_mode;
double            m_adjusted_point;             // point value adjusted for 3 or 5 points
int    handle_iMA_1;                           // variable for storing the handle of the iMA indicator 
int    handle_iMA_2;                           // variable for storing the handle of the iMA indicator 
int    handle_iRSI;                          // variable for storing the handle of the iRSI indicator
int    handle_iEnvelopes_1;                    // variable for storing the handle of the iEnvelopes indicator 
int    handle_iEnvelopes_2;                    // variable for storing the handle of the iEnvelopes indicator 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//SetMarginMode();
//if(!IsHedging())
//  {
//   Print("Hedging only!");
//   return(INIT_FAILED);
//  }
//---
//--- create handle of the indicator iMA
   handle_iMA_1=iMA(Symbol(),Period(),MA1Period,MA1Shift,MA1Method,MA1Price);
//--- if the handle is not created 
   if(handle_iMA_1==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iMA
   handle_iMA_2=iMA(Symbol(),Period(),MA2Period,MA2Shift,MA2Method,MA2Price);
//--- if the handle is not created 
   if(handle_iMA_2==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iRSI
   handle_iRSI=iRSI(Symbol(),PERIOD_H1,10,PRICE_TYPICAL);
//--- if the handle is not created 
   if(handle_iRSI==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iRSI indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(PERIOD_H1),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iEnvelopes
   handle_iEnvelopes_1=iEnvelopes(Symbol(),PERIOD_D1,24,80,MODE_SMA,PRICE_CLOSE,0.99);
//--- if the handle is not created 
   if(handle_iEnvelopes_1==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iEnvelopes indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(PERIOD_D1),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iEnvelopes
   handle_iEnvelopes_2=iEnvelopes(Symbol(),PERIOD_H4,96,24,MODE_SMA,PRICE_CLOSE,0.1);
//--- if the handle is not created 
   if(handle_iEnvelopes_2==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iEnvelopes indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(PERIOD_D1),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }

   m_symbol.Name(Symbol());                  // sets symbol name
   if(!RefreshRates())
     {
      Print("Error RefreshRates. Bid=",DoubleToString(m_symbol.Bid(),Digits()),
            ", Ask=",DoubleToString(m_symbol.Ask(),Digits()));
      return(INIT_FAILED);
     }
   m_symbol.Refresh();
//---
   m_trade.SetExpertMagicNumber(m_magic);    // sets magic number
   m_trade.SetDeviationInPoints(100);
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;
//---
   BlackoutStatus="NONE";
// hello world
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- MONEY MANAGEMENT ROUTINE BY AZMEL
   if(MoneyManagement)
     {
      Leverage=m_account.Leverage();
      ExtLots=MathFloor((m_account.Balance()*Risk*(Leverage/100))/
                        (m_symbol.ContractSize()*m_symbol.LotsMin()))*m_symbol.LotsMin();
     }

   PositionsStatus();   // Check order status
   if(flag_check)
      CheckTrigger();   // Trigger order execution
   else
      MonitorOrders();  // Monitor open orders
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PositionsStatus() // Check order status
  {

   flag_check=true;           // first assume we have no open/pending orders
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==Symbol() && m_position.Magic()==m_magic)
           {
            flag_check=false;        // deselect flag_check if there are open/pending orders for this pair
            break;
           }
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckTrigger() // Trigger order execution
  {
   double triggerprice=0.0;       // price to trigger order execution
   double StopLoss=0.0;           // stop-loss price
   bool flag=false;                 // flag to indicate whether to go long or go short

   if(lasttime==iTime(0)) // only need to calculate MA values at the start of each bar
     {
      //Calculate Indicators
      // up to 3 completed bars ago:
      fast1=iMAGet(handle_iMA_1,1);
      fast2=iMAGet(handle_iMA_1,2);
      fast3=iMAGet(handle_iMA_1,3);
      slow1=iMAGet(handle_iMA_2,1);
      slow2=iMAGet(handle_iMA_2,2);
      slow3=iMAGet(handle_iMA_2,3);
      //Check for MA cross
      if(fast1>slow1 && fast2<slow2) // cross up 1 bar ago
        {
         flag=true;
         crossprice=(fast1+fast2+slow1+slow2)/4.0;
         crosstime=iTime(1);
         triggerprice=crossprice+(Trigger*m_adjusted_point);
        }
      else if(fast2>slow2 && fast3<slow3) // cross up 2 bars ago
        {
         flag=true;
         crossprice=(fast2+fast3+slow2+slow3)/4.0;
         crosstime=iTime(2);
         triggerprice=crossprice+(Trigger*m_adjusted_point);
        }

      if(fast1<slow1 && fast2>slow2) // cross down 1 bar ago
        {
         flag=false;
         crossprice=(fast1+fast2+slow1+slow2)/4.0;
         crosstime=iTime(1);
         triggerprice=crossprice-(Trigger*m_adjusted_point);
        }
      else if(fast2<slow2 && fast3>slow3) // cross down 2 bars ago
        {
         flag=false;
         crossprice=(fast2+fast3+slow2+slow3)/4.0;
         crosstime=iTime(2);
         triggerprice=crossprice-(Trigger*m_adjusted_point);
        }
     }
   lasttime=iTime(0);

//--- Display countdown timer (seconds left)
   long countdown=(2*PeriodSeconds()*60)-(TimeCurrent()-crosstime);

   if(!RefreshRates())
      return;

   if(countdown>=0)
     {
      double triggerpips=((m_symbol.Ask()+m_symbol.Bid())/2.0-crossprice)/Point();
      Comment("\n","Hercules v1.3","\n\n"
              ,"Copyright © 2006-2008 Edward Clark","\n"
              ,"EA coded by David Lin","\n"
              ,"Modificatios by Azmel Ainul","\n\n"
              ,"Minutes in window of opportunity = ",countdown/60,". Cross-Price = ",
              DoubleToString(crossprice,Digits()),". Pips from Trigger = ",
              DoubleToString(triggerpips,0),".");
     }
   else
     {
      Comment("\n","Hercules v1.3","\n\n"
              ,"Copyright © 2006-2008 Edward Clark","\n"
              ,"EA coded by David Lin","\n"
              ,"Modificatios by Azmel Ainul");
     }

   BarsCount=120/PeriodSeconds();
   High10H=0;
   Low10H=iLow(1);
   for(int i=1;i<=BarsCount;i++)
     {
      High10H=MathMax(High10H,iHigh(i));
      Low10H=MathMin(Low10H,iLow(i));
     }

   RSI=iRSIGet(0);

   ENU=iEnvelopesGet(handle_iEnvelopes_1,UPPER_LINE,0);
   ENL=iEnvelopesGet(handle_iEnvelopes_1,LOWER_LINE,0);

   ENU2=iEnvelopesGet(handle_iEnvelopes_2,UPPER_LINE,0);
   ENL2=iEnvelopesGet(handle_iEnvelopes_2,LOWER_LINE,0);

   if(!RefreshRates())
      return;

//--- Enter Long      
   if(m_symbol.Ask()>=triggerprice && flag==true && countdown>=0)
     {
      StopLoss=iLow(4);
      if(RSI>RSI_Upper && m_symbol.Ask()>High10H && m_symbol.Ask()>ENU && m_symbol.Ask()>ENU2 && BlackoutStatus=="NONE")
        {
         bool trade_1=false;
         bool trade_2=false;
         trade_1=m_trade.Buy(ExtLots,Symbol(),m_symbol.Ask(),StopLoss,TakeLong(m_symbol.Ask(),TakeProfit1));
         if(!trade_1)
           {
            Print("Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription(),
                  ", ticket of deal: ",m_trade.ResultDeal());
           }
         trade_2=m_trade.Buy(ExtLots,Symbol(),m_symbol.Ask(),StopLoss,TakeLong(m_symbol.Ask(),TakeProfit2));
         if(!trade_2)
           {
            Print("Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription(),
                  ", ticket of deal: ",m_trade.ResultDeal());
           }
         if(trade_1 && trade_2)
           {
            BlackoutStatus="ACTIVE";
            BlackoutStart=TimeCurrent();
           }
        }
     }

//--- Enter Short 
   if(m_symbol.Bid()<=triggerprice && flag==false && countdown>=0)
     {
      StopLoss=iHigh(4);
      if(RSI<RSI_Lower && m_symbol.Bid()<Low10H && m_symbol.Bid()<ENL && m_symbol.Bid()<ENL2 && BlackoutStatus=="NONE")
        {
         bool trade_1=false;
         bool trade_2=false;
         trade_1=m_trade.Sell(ExtLots,Symbol(),m_symbol.Bid(),StopLoss,TakeShort(m_symbol.Bid(),TakeProfit1));
         if(!trade_1)
           {
            Print("Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription(),
                  ", ticket of deal: ",m_trade.ResultDeal());
           }
         trade_2=m_trade.Sell(ExtLots,Symbol(),m_symbol.Bid(),StopLoss,TakeShort(m_symbol.Bid(),TakeProfit2));
         if(!trade_2)
           {
            Print("Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription(),
                  ", ticket of deal: ",m_trade.ResultDeal());
           }
         if(trade_1 && trade_2)
           {
            BlackoutStatus="ACTIVE";
            BlackoutStart=TimeCurrent();
           }
        }
     }

   if(BlackoutStatus=="ACTIVE")
     {
      if(TimeCurrent()>BlackoutStart+(BlackoutPeriod*3600))
        {
         BlackoutStatus="NONE";
        }
     }

   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MonitorOrders() //Monitor open orders
  {
//--- More sophisticated exit monitoring system may be needed here
   TrailingAlls(TrailingStop);   //Trailing Stop
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double TakeLong(double price,int take) // function to calculate takeprofit if long
  {
   if(take==0)
      return(0.0); // if no take profit
   return(price+(take*m_adjusted_point));
// plus, since the take profit is above us for long positions
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double TakeShort(double price,int take) // function to calculate takeprofit if short
  {
   if(take==0)
      return(0.0); // if no take profit
   return(price-(take*m_adjusted_point));
// minus, since the take profit is below us for short positions
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailingAlls(int trail) // client-side trailing stop
  {
   if(trail==0)
      return;

   double stopcrnt=0.0;
   double stopcal=0.0;

   if(!RefreshRates())
      return;

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==Symbol() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               stopcrnt=m_position.StopLoss();
               stopcal=m_symbol.Bid()-(trail*m_adjusted_point);
               if(stopcrnt==0.0)
                 {
                  m_trade.PositionModify(m_position.Ticket(),stopcal,m_position.TakeProfit());
                 }
               else
                 {
                  if(stopcal>stopcrnt)
                    {
                     m_trade.PositionModify(m_position.Ticket(),stopcal,m_position.TakeProfit());
                    }
                 }
              }

            if(m_position.PositionType()==POSITION_TYPE_SELL)
              {
               stopcrnt=m_position.StopLoss();
               stopcal=m_symbol.Ask()+(trail*m_adjusted_point);
               if(stopcrnt==0)
                 {
                  m_trade.PositionModify(m_position.Ticket(),stopcal,m_position.TakeProfit());
                 }
               else
                 {
                  if(stopcal<stopcrnt)
                    {
                     m_trade.PositionModify(m_position.Ticket(),stopcal,m_position.TakeProfit());
                    }
                 }
              }
           }
   return;
  }
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates()
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
      return(false);
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iMA                                 |
//+------------------------------------------------------------------+
double iMAGet(int handle,const int index)
  {
   double MA[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iMABuffer array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle,0,index,1,MA)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iMA indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(MA[0]);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iRSI                                |
//+------------------------------------------------------------------+
double iRSIGet(const int index)
  {
   double arr_RSI[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iRSI array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iRSI,0,index,1,arr_RSI)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iRSI indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(arr_RSI[0]);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iEnvelopes                          |
//|  the buffer numbers are the following:                           |
//|   0 - UPPER_LINE, 1 - LOWER_LINE                                 |
//+------------------------------------------------------------------+
double iEnvelopesGet(int handle,const int buffer,const int index)
  {
   double Envelopes[1];
//ArraySetAsSeries(Bands,true);
//--- reset error code 
   ResetLastError();
//--- fill a part of the iEnvelopesBuffer array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle,buffer,index,1,Envelopes)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iBands indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(Envelopes[0]);
  }
//+------------------------------------------------------------------+ 
//| Get Time for specified bar index                                 | 
//+------------------------------------------------------------------+ 
datetime iTime(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=Symbol();
   if(timeframe==0)
      timeframe=Period();
   datetime Time[1];
   datetime time=0;
   int copied=CopyTime(symbol,timeframe,index,1,Time);
   if(copied>0) time=Time[0];
   return(time);
  }
//+------------------------------------------------------------------+ 
//| Get Low for specified bar index                                  | 
//+------------------------------------------------------------------+ 
double iLow(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=Symbol();
   if(timeframe==0)
      timeframe=Period();
   double Low[1];
   double low=0;
   int copied=CopyLow(symbol,timeframe,index,1,Low);
   if(copied>0) low=Low[0];
   return(low);
  }
//+------------------------------------------------------------------+ 
//| Get the High for specified bar index                             | 
//+------------------------------------------------------------------+ 
double iHigh(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=Symbol();
   if(timeframe==0)
      timeframe=Period();
   double High[1];
   double high=0;
   int copied=CopyHigh(symbol,timeframe,index,1,High);
   if(copied>0) high=High[0];
   return(high);
  }
//+------------------------------------------------------------------+
