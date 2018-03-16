//+------------------------------------------------------------------+
//|                                                     InvestFX.mq4 |
//|                                                        Fxstar.eu |
//|                                                https://fxstar.eu |
//+------------------------------------------------------------------+
#property copyright "Fxstar.eu"
#property link      "https://fxstar.eu"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
#define LABEL  225588
//--- Inputs
input double Lot = 0.1;
input int    Sl =  50;
input int    Tp =  50;
input int    TrailingStop = 0;
input bool   Week = true;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);      
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
      
  }

//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForOpen()
{
   double ma;
   int    res;
   
   // week level start position
   if(Week == true)
     {
      ma= iOpen(NULL,PERIOD_W1,0);   
     }else{
      ma= iOpen(NULL,PERIOD_MN1,0);
     } 
   
   
   if(Open[1]<ma && Close[1]<ma)
     {
      res=OrderSend(Symbol(),OP_SELL,Lot,Bid,3,ma + Sl*Point*10,Bid - Tp*Point*10,"investFX",LABEL,0,Red);
      return;
     }
   //--- buy conditions
   if(Open[1]>ma && Close[1]>ma)
     {
      res=OrderSend(Symbol(),OP_BUY,Lot,Ask,3,ma - Sl*Point*10,Ask + Tp*Point*10,"investFX",LABEL,0,Green);
      return;
     }
}

void CheckForTrailing(){
   int Trailing = TrailingStop *10;
   int orders=OrdersTotal();
   for(int i=0;i<orders;i++)
     {
      if( OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderCloseTime()==0 ) {
             if( OrderType()==OP_BUY && OrderMagicNumber() == LABEL) {
               //--- check for trailing stop
               if(Trailing>0)
                 {
                  if(Bid-OrderOpenPrice()>Point*Trailing)
                    {
                     if(OrderStopLoss()<Bid-Point*Trailing)
                       {
                        //--- modify order and exit
                        if(!OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*Trailing,OrderTakeProfit(),0,Green))
                           Print("OrderModify error ",GetLastError());
                        return;
                       }
                    }
                 }
              }
             }
             else if( OrderType()==OP_SELL && OrderMagicNumber() == LABEL) {
               //--- check for trailing stop
               if(Trailing>0)
                 {
                  if((OrderOpenPrice()-Ask)>(Point*Trailing))
                    {
                     if((OrderStopLoss()>(Ask+Point*Trailing)) || (OrderStopLoss()==0))
                       {
                        //--- modify order and exit
                        if(!OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*Trailing,OrderTakeProfit(),0,Red))
                           Print("OrderModify error ",GetLastError());
                        return;
                       }
                    }
                 }
            }
      }
}  
  
void OnTick()
{
   if(Bars<10)return;  
   if(OrdersTotal() == 0)CheckForOpen();
   if(OrdersTotal() > 0)CheckForTrailing();
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
  
  }
//+------------------------------------------------------------------+
