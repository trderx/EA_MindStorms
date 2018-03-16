//+------------------------------------------------------------------+
//|                                                     InvestFX.mq4 |
//|                                                        Fxstar.eu |
//|                                                https://fxstar.eu |
//+------------------------------------------------------------------+
#property copyright "Fxstar.eu"
#property link      "https://fxstar.eu"
#property version   "1.00"
#property strict

#define LABEL  225588
//--- Inputs
input int    TrailingStop = 100;

int OnInit()
  {
   return(INIT_SUCCEEDED);
  }

void CheckForTrailing(){
   int Trailing = TrailingStop *10;
   int orders=OrdersTotal();
   for(int i=0;i<orders;i++)
     {
      if( OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderCloseTime()==0 ) {
             if( OrderType()==OP_BUY) {
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
             else if( OrderType()==OP_SELL) {
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
   if(OrdersTotal() > 0)CheckForTrailing();
}
