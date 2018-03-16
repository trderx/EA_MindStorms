//+------------------------------------------------------------------+
//|                                                       eurjpy.mq4 |
//|                                       Copyright 2013 Breakermind |
//|                                           http://breakermind.com |
//+------------------------------------------------------------------+
// Not tested use only for training

#property link        "http://breakermind.com"
#property copyright   "Copyright 2013 Breakermind.com"
//+------------------------------------------------------------------+
//|                                                           
//+------------------------------------------------------------------+

extern bool ShowStat = true;
extern double Lots = 0.01;
extern double StartBalance = 1000;
extern bool MultipleLots = true;

extern double StopProfit = 10000;
extern double MaxPositionsLong = 100;
extern double MaxPositionsShort = 100;
extern bool StopWeekend = false;
extern bool CrossWeekend = true;
extern double MaxEquity = 0.5;
extern bool TradeAfterCloseAll = true;
extern double StopLossBack = 60;
extern double PipsBack = 50;
extern double StopLossTrailing = 400;
extern int SL = 0;  // lepiej nie używać nie opłaca się
int Ban = 0;
//+------------------------------------------------------------------+
//|                                                           
//+------------------------------------------------------------------+
int total, total1, MagicNumber, AccountNr, IntBid,cnt1, tmp;
double MarginFree, Balance, Equity, Margin, Lots1, PosUpDouble, PosDnDouble;
int BanUp = 1;
int BanDown = 1; 
int PosUp = 0;
int PosDn = 0;
int LevelUp[2000];
int LevelDn[2000];

//+------------------------------------------------------------------+
//|Functions                                            
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|Start                                               
//+------------------------------------------------------------------+
int start(){
double Ma5=iMA(NULL,0,200,0,MODE_EMA,PRICE_CLOSE,0);
double Ma5p=iMA(NULL,0,200,0,MODE_EMA,PRICE_CLOSE,3);
double Ma200=iMA(NULL,0,200,0,MODE_LWMA,PRICE_MEDIAN,0);


if(MultipleLots == true){
Lots1 = Lots;
int ilerazy = Balance/StartBalance;
if(ilerazy <= 0){ilerazy = 1;}
Lots1 = ilerazy*Lots;
}else{Lots1 = Lots;}

//=== Stop ea on weekends
if(StopWeekend == true){
if(DayOfWeek() > 4 && Hour() == 21 && Minute() > 30){
CloseAll();
return;
}
}
// ===   
if(CrossWeekend == true){
if(DayOfWeek() > 4 && Hour() == 21 && Minute() > 30){
ClosePending();
total1 = OrdersTotal();
double OpenLongLot = 0, OpenShortLot = 0;
for(int q=0;q<total;q++)       
{
OrderSelect(q, SELECT_BY_POS );
if ( OrderSymbol() == Symbol())
{
int type1 = OrderType();
if (type1 == OP_BUY )       {OpenLongLot=OpenLongLot+OrderLots();}
if (type1 == OP_SELL )      {OpenShortLot=OpenShortLot+OrderLots();}
}
}
//===
if(OpenLongLot > OpenShortLot){
OrderSend(Symbol(),OP_SELL,OpenLongLot-OpenShortLot,Bid,3,0,0,"breakermind",0,0,Red);
}
//===
if(OpenShortLot > OpenLongLot){
OrderSend(Symbol(),OP_BUY,OpenShortLot-OpenLongLot,Ask,3,0,0,"breakermind",0,0,Green);
}
// ===
} 
}


//===
if(StopLossTrailing <= 0){
StopLossTrailing = 400;
}
for(int z = 0; z < 2001;z++){
LevelUp[z] = 0;
LevelDn[z] = 0;
}
double Dayline = iOpen(NULL, PERIOD_D1, 0);
ObjectsDeleteAll(0);
ObjectCreate("Dayline", OBJ_HLINE, 0, Time[0], Dayline);


IntBid = Bid*10000/10000;
//+------------------------------------------------------------------+
//|Policz pozycje
//+------------------------------------------------------------------+
total = OrdersTotal();
double OpenLongOrders = 0, OpenShortOrders = 0, PendLongs =0, PendShorts =0;
for(int i=0;i<total;i++)       
{
OrderSelect(i, SELECT_BY_POS );
if ( OrderSymbol() == Symbol())
{
int type = OrderType();
int cena = OrderMagicNumber();

if (type == OP_BUY || type == OP_BUYSTOP){
LevelUp[cena]= 1;
}  
if (type == OP_SELL || type == OP_SELLSTOP){
LevelDn[cena]= 1;
} 

if (type == OP_BUY )       {OpenLongOrders=OpenLongOrders+1;}
if (type == OP_SELL )      {OpenShortOrders=OpenShortOrders+1;}
if (type == OP_BUYSTOP )   {PendLongs=PendLongs+1;}
if (type == OP_SELLSTOP )  {PendShorts=PendShorts+1;}

}
}
int AllLong = OpenLongOrders+PendLongs;
int AllShort = OpenShortOrders+PendShorts;
//+------------------------------------------------------------------+
//|Parametry konta
//+------------------------------------------------------------------+
   Equity = AccountEquity();
   Balance = AccountBalance();
   MarginFree = AccountFreeMargin();
   Margin = AccountMargin();
   AccountNr = AccountNumber();
   double MaxEq = Balance*MaxEquity;    
   
 
if(ShowStat){
double ddd = MarketInfo( Symbol(), MODE_STOPLEVEL )*Point;
Comment("Account Number: ", AccountNr, 
        " \nDayline: ", Dayline, 
        " \nHigh: ", iHigh(NULL, PERIOD_D1, 0), 
        " \nLow: ", iLow(NULL, PERIOD_D1, 0), 
        " \nTotal positions: ", total, 
        " \nPend positions BUY:  ", PendLongs, 
        " \nPend positions SELL: ", PendShorts,        
        " \nOpen positions BUY:  ", OpenLongOrders, 
        " \nOpen positions SELL: ", OpenShortOrders, 
        " \nAccount balance = ",Balance, 
        " \nAccount equity = ",Equity, 
        " \nAccount free margin = ",MarginFree, 
        " \nMaxEquity = ", MaxEq,
        " \nStopLevelMin ", ddd);
}

//+------------------------------------------------------------------+
//|                                                             
//+------------------------------------------------------------------+

if(Equity > StopProfit){
CloseAll();
Ban=1;
TradeAfterCloseAll = false;
return;
}

//+------------------------------------------------------------------+
//|                                                             
//+------------------------------------------------------------------+

if(Equity < MaxEq || Ban == 1){
CloseAll();
Alert("Close all positions Equity limit !!!");
// deselect if you want trade befor close all poss
Ban = 1;
if(TradeAfterCloseAll){Ban = 0;}
return;
}

if(tmp != Time[0]){
tmp = Time[0];
int MBid = Bid*10000/10000;
int MBid2 = MBid +1;


if(AllLong < MaxPositionsLong){
for(int a = 1; a < 5; a++){
if(LevelUp[MBid+a] == 0 && AllLong < MaxPositionsLong ){
OrderSend(Symbol(),OP_BUYSTOP,Lots1+Lots1,MBid+a,3,0,0,"breakermind",MBid+a,0,Green);
OrderSend(Symbol(),OP_BUYSTOP,Lots1,MBid+a+0.75,3,0,0,"breakermind",0,0,Green);
OrderSend(Symbol(),OP_BUYSTOP,Lots1,MBid+a+0.55,3,0,0,"breakermind",0,0,Green);
OrderSend(Symbol(),OP_BUYSTOP,Lots1+Lots1,MBid+a+0.25,3,0,0,"breakermind",0,0,Green);
}
}
}

// ====

if(AllLong < MaxPositionsLong){
for(int b = 1; b < 5; b++){
if(LevelDn[MBid2-b] == 0 && AllShort < MaxPositionsShort){
OrderSend(Symbol(),OP_SELLSTOP,Lots1,MBid2-b,3,0,0,"breakermind",MBid2-b,0,Red);
OrderSend(Symbol(),OP_SELLSTOP,Lots1,MBid2-b-0.75,3,0,0,"breakermind",0,0,Red);
OrderSend(Symbol(),OP_SELLSTOP,Lots1+Lots1,MBid2-b-0.55,3,0,0,"breakermind",0,0,Red);
OrderSend(Symbol(),OP_SELLSTOP,Lots1,MBid2-b-0.25,3,0,0,"breakermind",0,0,Red);
}
}
}

}


//+------------------------------------------------------------------+
//|                                                             
//+------------------------------------------------------------------+
   for(int cnt=0;cnt<total;cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()<=OP_SELL &&   
         OrderSymbol()==Symbol())  
        {
         if(OrderType()==OP_BUY)   
           {

            // check for stop back
            if(StopLossBack>0)  
              {                 
               if(Bid-OrderOpenPrice()>Point*StopLossBack)
                 {
                  if(OrderStopLoss() == 0 || OrderStopLoss() < OrderOpenPrice())
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+Point*PipsBack,OrderTakeProfit(),0,Green);
                     return(0);
                    }
                 }
              }  
                           
            // check for stop loss
            if(StopLossTrailing>0)  
              {                 
                   if(OrderStopLoss()==0 && SL > 0)
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-SL*Point,OrderTakeProfit(),0,Green);
                    }    
               if(Bid-OrderOpenPrice()>Point*StopLossTrailing)
                 {
                  if(OrderStopLoss()<Bid-Point*StopLossTrailing)
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*StopLossTrailing,OrderTakeProfit(),0,Green);
                     return(0);
                    }
                 }
              }
     
           }
         else // go to short position
           {
 
             if(StopLossBack>0)  
              {                 
               if((OrderOpenPrice()-Ask)>(Point*StopLossBack))
                 {
                  if(OrderStopLoss()==0 || OrderStopLoss() > OrderOpenPrice())
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-Point*PipsBack,OrderTakeProfit(),0,Red);
                     //OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-Point*PipsBack,OrderTakeProfit(),0,Red);
                     return(0);
                    }
                 }
              } 
                    
            // check for stop loss
            if(StopLossTrailing>0)  
              {             
                  if(OrderStopLoss()==0 && SL > 0)
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-SL*Point,OrderTakeProfit(),0,Red);
                    }                    
               if((OrderOpenPrice()-Ask)>(Point*StopLossTrailing))
                 {                         
                  if((OrderStopLoss()>(Ask+Point*StopLossTrailing)) || (OrderStopLoss()==0))
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*StopLossTrailing,OrderTakeProfit(),0,Red);
                     return(0);
                    }
                 }
              }

           }
        }
     }
     

}//end

void CloseAll() {
   for (int i=0; i<OrdersTotal(); i++) { 
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { 
         if (OrderSymbol()==Symbol()) { 
            if (OrderType()==OP_BUY) 
               OrderClose(OrderTicket(),OrderLots(),Bid,0,0);
            if (OrderType()==OP_SELL) 
               OrderClose(OrderTicket(),OrderLots(),Ask,0,0);
            if (OrderType()==OP_SELLSTOP || OrderType()==OP_SELLLIMIT || 
                OrderType()==OP_BUYSTOP || OrderType()==OP_BUYLIMIT) 
               OrderDelete(OrderTicket());
         }
      }
   }
}


void ClosePending() {
   for (int w=0; w<OrdersTotal(); w++) { 
      if (OrderSelect(w, SELECT_BY_POS, MODE_TRADES)) { 
         if (OrderSymbol()==Symbol()) { 
            if (OrderType()==OP_SELLSTOP || OrderType()==OP_SELLLIMIT || 
                OrderType()==OP_BUYSTOP || OrderType()==OP_BUYLIMIT) 
               OrderDelete(OrderTicket());
         }
      }
   }
}
