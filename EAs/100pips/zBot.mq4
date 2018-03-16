//+------------------------------------------------------------------+
//|                                                         zBot.mq4 |
//|                                        Copyright 2016, fxstar.eu |
//|                                                https://fxstar.eu |
//|                If you earn donate 10% from profit                |
//|                   paypal hello@breakermind.com                   |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2000-2016, fxstar.eu"
#property link        "http://fxstar.eu"
#property description "zBot harvester"

#define MAGICMA  20160225
//--- Inputs
// min 10000$ from 1 Lot
input double Lots          = 1;
input double MaximumRisk   =0.02;
input double DecreaseFactor=3;
input int    MovingPeriod  =60;
input int    MovingShift   =6;
input int    sl   =1000;
input int    tp   =5000;
input int    tp2   =5000;
//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
int CalculateCurrentOrders(string symbol)
  {
   int buys=0,sells=0;
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
        }
     }
//--- return orders volume
   if(buys>0) return(buys);
   else       return(-sells);
  }
//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double LotsOptimized()
  {
   double lot=Lots;
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
//--- select lot size
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
//--- calcuulate number of losses orders without a break
   if(DecreaseFactor>0)
     {
      for(int i=orders-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
           {
            Print("Error in history!");
            break;
           }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL)
            continue;
         //---
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++;
        }
      if(losses>1)
         lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
//--- return lot size
   if(lot<0.1) lot=0.1;
   return(3);   
  }
//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForOpen()
  {
   double ma;
   int    res;
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get Moving Average 
   ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
//--- sell conditions
   if(Open[1]<ma && Close[1]<ma)
     {
      res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,Ask+(sl*Point),Bid-(tp*Point),"zBot",MAGICMA,0,Red);
      OrderSend(Symbol(), OP_SELLSTOP, LotsOptimized(), Bid-1000*Point, 0, Bid-1000*Point+sl*Point, Bid-1000*Point-tp2*Point);
      OrderSend(Symbol(), OP_SELLSTOP, LotsOptimized(), Bid-1000*Point, 0, Bid-1000*Point+sl*Point, Bid-1000*Point-tp2*Point);
      OrderSend(Symbol(), OP_SELLSTOP, LotsOptimized(), Bid-1000*Point, 0, Bid-1000*Point+sl*Point, Bid-1000*Point-tp2*Point);
      return;
     }
//--- buy conditions
   if(Open[1]>ma && Close[1]>ma)
     {
      res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,Ask-(sl*Point),Bid+(tp*Point),"zBot",MAGICMA,0,Blue);
      OrderSend(Symbol(), OP_BUYSTOP, LotsOptimized(), Ask+1000*Point, 0, Ask+1000*Point-sl*Point, Ask+1000*Point+tp2*Point, "zBot",MAGICMA,0,Blue);
      OrderSend(Symbol(), OP_BUYSTOP, LotsOptimized(), Ask+1000*Point, 0, Ask+1000*Point-sl*Point, Ask+1000*Point+tp2*Point, "zBot",MAGICMA,0,Blue);
      OrderSend(Symbol(), OP_BUYSTOP, LotsOptimized(), Ask+1000*Point, 0, Ask+1000*Point-sl*Point, Ask+1000*Point+tp2*Point, "zBot",MAGICMA,0,Blue);
      
      return;
     }
//---
  }
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose()
  {
   double ma;
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get Moving Average 
   ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      //--- check order type 
      if(OrderType()==OP_BUY)
        {
         if(Open[1]>ma && Close[1]<ma)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               Print("OrderClose error ",GetLastError());
           }
         break;
        }
      if(OrderType()==OP_SELL)
        {
         if(Open[1]<ma && Close[1]>ma)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
               Print("OrderClose error ",GetLastError());
           }
         break;
        }
     }
//---
  }
//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- check for history and trading
   if(Bars<100 || IsTradeAllowed()==false)
      return;
//--- calculate open orders by current symbol
   if(CalculateCurrentOrders(Symbol())==0){
   CheckForOpen();
   }else{
   CheckForClose();
   }
//---
  }
//+------------------------------------------------------------------+
