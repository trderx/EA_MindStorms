//+------------------------------------------------------------------+
//|                                                 MakeGridLSMA.mq4 |
//|                                            Copyright © 2005, hdb |
//|                                       http://www.dubois1.net/hdb |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, hdb"
#property link      "http://www.dubois1.net/hdb"
//#property version      "1.93"
// DISCLAIMER ***** IMPORTANT NOTE ***** READ BEFORE USING ***** 
// This expert advisor can open and close real positions and hence do real trades and lose real money.
// This is not a 'trading system' but a simple robot that places trades according to fixed rules.
// The author has no pretentions as to the profitability of this system and does not suggest the use
// of this EA other than for testing purposes in demo accounts.
// Use of this system is free - but u may not resell it - and is without any garantee as to its
// suitability for any purpose.
// By using this program you implicitly acknowledge that you understand what it does and agree that 
// the author bears no responsibility for any losses.
// Before using, please also check with your broker that his systems are adapted for the frequest trades
// associated with this expert.
// 1.8 changes
// made wantLongs and wantShorts into local variables. Previously, if u set UseMACD to true, 
//       it did longs and shorts and simply ignored the wantLongs and wantShorts flags. 
//       Now, these flags are not ignored.
// added a loop to check if there are 'illicit' open orders above or below the EMA when the limitEMA34
//       flag is used. These accumulate over time and are never removed and is due to the EMA moving.
// removed the switch instruction as they dont seem to work - replaced with if statements
// made the EMA period variable
//
// 1.9 changes - as per kind suggestions of Gideon
// Added a routine to delete orders and positions if they are older than keepOpenTimeLimit hours.
// Added OsMA as a possible filter. Acts exactly like MACD.
// Added 4 parameters for MACD or OsMA so that we can optimise
// Also cleaned up the code a bit.
// 1.92 changes by dave
// added function openPOsitions to count the number of open positions
// modified the order logic so that openPOsitions is not > GridMaxOpen 
// 1.93 added long term direction indicator 
// Added tradeForMinutes  - will only trade for this time then stop till EA is reset.
//
// modified by cori. Using OrderMagicNumber to identify the trades of the grid
// modified by MrPip to use LSMA and removed a large amount of code that is not needed
// when grid is only open in direction of LSMA
// Also added a second version of Trailing Stop and combined some routines, passing parameteres
// to keep the same functionality.
extern int    uniqueGridMagic = 11111; // Magic number of the trades. must be unique to identify
                                       // the trades of one grid    
extern double Lots = 0.1;              // 
extern double GridSize = 10;            // pips between orders - grid or mesh size
extern double GridSteps = 10;          // total number of orders to place
extern bool ExtendGrid = true;        // Used to limit grid to original when buy and sell stops are filled
extern double TakeProfit = 0 ;        // number of ticks to take profit. normally is = grid size but u can override
extern double StopLoss = 0;            // if u want to add a stop loss. normal grids dont use stop losses
extern int    trailStop = 0;           // will trail if > 0
extern int TrailingStopType = 1;       // Type 1 will trail immediately, type 2 will wait for price to move amount of trailStop
extern double UpdateInterval = 15;      // update orders every x minutes
// Added by MrPip to trade in the direction of the LSMA cross
extern int LSMAShortPeriod=7;          // 
extern int LSMALongPeriod=16;
extern int PipsDifference = 16;
extern int    gridOffset = 0;          // positions are opened at price modulo GridSize and offset with this parameter.
                                       // used essentially to enter at non round numbers
// the following flags set bounds on the prices at which orders may be placed
// this code was developed for and is kindly made public by Exc_ite2


extern bool   suspendGrid = false;       // if set to true, will close all unfilled Orders 
extern bool   shutdownGrid = false;      // if set to true, will close all orders and positions.
                                       
// modified by cori. internal variables only
string   GridName = "Grid";              // identifies the grid. allows for several co-existing grids - old variable.. shold not use any more
double   LastUpdate = 0;                 // counter used to note time of last update
double   startTime = 0;                  // counter to note trade start time.
double   closedProfit = 0;               // counts closed p&l
double   openProfit = 0;                 // counts open p&l
double   accumulatedProfit = 0;          // for back testing only
int      openLongs = 0;                  //  how many longs are open 
int      openShorts = 0;                 // how many shorts are open 
bool     gridActive = true;              // is the grid active

//  modified by MrPip
double LongTradeRate;                    // Keeps track of where to extend a long grid
double ShortTradeRate;                   // Keeps track of where to extend a short grid
int GridCount;                           // How many Buy Stop or Sell Stop are in the grid
                                         // Used to determine how many to add when extend grid is true
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//---- 
 #property show_inputs                  // shows the parameters - thanks Slawa...    
//----
   GridName = StringConcatenate( "Grid-", Symbol(),"-",uniqueGridMagic );
   return(0);
  }

//+------------------------------------------------------------------------+
//| LSMA - Least Squares Moving Average function calculation               |
//| LSMA_In_Color Indicator plots the end of the linear regression line    |
//| Code is placed here and locked for Daily direction                     |
//+------------------------------------------------------------------------+

double LSMADaily(int Rperiod, int shift)
{
   int i;
   double sum;
   int length;
   double lengthvar;
   double tmp;
   double wt;

   length = Rperiod;
 
   sum = 0;
   for(i = length; i >= 1  ; i--)
   {
     lengthvar = length + 1;
     lengthvar /= 3;
     tmp = 0;
     tmp = ( i - lengthvar)*iClose(NULL,PERIOD_D1,length-i+shift);
     sum+=tmp;
    }
    wt = sum*6/(length*(length+1));
    
    return(wt);
}


//+------------------------------------------------------------------------+
//| LSMA - Least Squares Moving Average function calculation               |
//| LSMA_In_Color Indicator plots the end of the linear regression line    |
//| Cose is placed here for any chart period                               |
//+------------------------------------------------------------------------+

double LSMA(int Rperiod, int shift)
{
   int i;
   double sum;
   int length;
   double lengthvar;
   double tmp;
   double wt;

   length = Rperiod;
 
   sum = 0;
   for(i = length; i >= 1  ; i--)
   {
     lengthvar = length + 1;
     lengthvar /= 3;
     tmp = 0;
     tmp = ( i - lengthvar)*Close[length-i+shift];
     sum+=tmp;
    }
    wt = sum*6/(length*(length+1));
    
    return(wt);
}

//+------------------------------------------------------------------+
//| CheckDailyDirection                                              |
//| Check daily direction for trade                                  |
//| return 1 for up, -1 for down, 0 for flat                         |
//+------------------------------------------------------------------+
int CheckDailyDirection()
{
   double SlowEMA, FastEMA;
   double Dif;
   
 
   Dif = LSMADaily(LSMAShortPeriod,1) - LSMADaily(LSMALongPeriod,1);
   
   if(Dif > 0 ) return(1);
   if(Dif < 0 ) return(-1);
   return(0);
   

}

//+------------------------------------------------------------------+
//| CheckExitCondition                                               |
//| Check if LSMAs cross down to exit BUY or up to exit SELL         |
//+------------------------------------------------------------------+
bool CheckExitCondition(string TradeType)
{
   bool YesClose;
   double Dif;
   
   YesClose = false;
   Dif=LSMA(LSMAShortPeriod,1)-LSMA(LSMALongPeriod,1);
//   Dif=CheckDailyDirection();
   if (TradeType == "BUY" && Dif < 0) YesClose = true;
   if (TradeType == "SELL" && Dif > 0) YesClose = true;
    
   return (YesClose);
}



//+------------------------------------------------------------------+
//| CheckEntryCondition                                              |
//| Check if LSMAs cross up for BUY or down for SELL                 |
//+------------------------------------------------------------------+
bool CheckEntryCondition(string TradeType)
{
   bool YesTrade;
   double Dif;
   
   YesTrade = false;
 
   Dif = LSMA(LSMAShortPeriod,1) - LSMA(LSMALongPeriod,1);
//   Dif=CheckDailyDirection();

//   if (TradeType == "BUY" && Dif > PipsDifference * Point ) YesTrade = true;
//   if (TradeType == "SELL" && Dif < PipsDifference * Point ) YesTrade = true;
   if (TradeType == "BUY" && Dif > 0 ) YesTrade = true;
   if (TradeType == "SELL" && Dif < 0 ) YesTrade = true;
   
   return (YesTrade);
}
  
//+------------------------------------------------------------------------+
//| cancels all pending orders    and closes open positions                |
//| Combined several routines that did almost the same thing               |
//+------------------------------------------------------------------------+

void ClosePendingOrdersAndPositions(bool CloseOpenPos,string type)
{
  int totalorders = OrdersTotal();
  for(int i=totalorders-1;i>=0;i--)
 {
    OrderSelect(i, SELECT_BY_POS);
    bool result = false;
// modified by cori. Using OrderMagicNumber to identify the trades of the grid // hdb added or gridname for compatibility
    if ( OrderSymbol()==Symbol() && ( (OrderMagicNumber() == uniqueGridMagic) || (OrderComment() == GridName)) )  // only look if mygrid and symbol...
     {
        if (CloseOpenPos) {
        if (type == "BUY") {
           //Close opened long positions
           if ( OrderType() == OP_BUY )  result = OrderClose( OrderTicket(), OrderLots(),  Bid, 5, Red );
          } 
         if (type == "SELL") {
           //Close opened short positions
           if ( OrderType() == OP_SELL )  result = OrderClose( OrderTicket(), OrderLots(),  Ask, 5, Red );
           }
        }
        //Close pending orders
        if (type == "BUY" && OrderType() == OP_BUYSTOP ) result = OrderDelete( OrderTicket() );
        if (type == "SELL" && OrderType() == OP_SELLSTOP ) result = OrderDelete( OrderTicket() );
      }
  }
  return;
}

//+------------------------------------------------------------------------+
//| counts the number of open positions                                    |
//+------------------------------------------------------------------------+

int openPositions(  )
  {  int op =0;
     int totalorders = OrdersTotal();
     for(int i=totalorders-1;i>=0;i--)                                // scan all orders and positions...
      {
        OrderSelect(i, SELECT_BY_POS);
        if ( OrderSymbol()==Symbol() && ( (OrderMagicNumber() == uniqueGridMagic) || (OrderComment() == GridName)) )  // only look if mygrid and symbol...
         {  
          int type = OrderType();
          if ( type == OP_BUY ) {op=op+1;} 
          if ( type == OP_SELL ) {op=op+1;} 
         }
      } 
   return(op);
  }

//+------------------------------------------------------------------------+
//| counts the number of grid positions                                    |
//+------------------------------------------------------------------------+

int openGrids(  )
  {  int op =0;
     int totalorders = OrdersTotal();
     for(int i=totalorders-1;i>=0;i--)                                // scan all orders and positions...
      {
        OrderSelect(i, SELECT_BY_POS);
        if ( OrderSymbol()==Symbol() && ( (OrderMagicNumber() == uniqueGridMagic) || (OrderComment() == GridName)) )  // only look if mygrid and symbol...
         {  
          int type = OrderType();
          if ( type == OP_BUYSTOP ) {op=op+1;} 
          if ( type == OP_SELLSTOP ) {op=op+1;} 
         }
      } 
   return(op);
  }


//+------------------------------------------------------------------+
//| Check how much profit so far                                     |
//+------------------------------------------------------------------+
void TestForProfit( int forMagic, bool testOpen, bool testHistory )                   // based on trailing stop code from MT site... but modified as per Hiro
  {
         closedProfit = 0;                // counts closed p&l

         if (testHistory == true) {
            int total = HistoryTotal();
            for(int i=0;i<total;i++)                                // scan all closed / cancelled transactions
              {
              OrderSelect(i, SELECT_BY_POS, MODE_HISTORY );
              if ( OrderSymbol() == Symbol() && OrderMagicNumber() == forMagic )  // only look if mygrid and symbol...
                {
                 closedProfit = closedProfit + OrderProfit();
               }
              }
          } else {
             accumulatedProfit =0;
          }
          
         openProfit = 0;                  // counts open p&l

         if (testOpen == true) {
            total = OrdersTotal();
            openLongs = 0;
            openShorts = 0;
            for(i=0;i<total;i++)                                // scan all open orders and positions
              {
              OrderSelect(i, SELECT_BY_POS );
              if ( OrderSymbol() == Symbol() && OrderMagicNumber() == forMagic )  // only look if mygrid and symbol...
                {
                  openProfit = openProfit + OrderProfit();
                  int type = OrderType();
                  if ( type == OP_BUY ) {openLongs=openLongs+1;} 
                  if ( type == OP_SELL ) {openShorts=openShorts+1;} 
                }
              }
           }
           accumulatedProfit = accumulatedProfit + closedProfit + openProfit;
  }


//+------------------------------------------------------------------+
//| Trailing stop procedure                                          |
//| Added new type of trailing stop(Type 1) that moves the stoploss  |
//| without delay. Old version (Type 2) waited for price to move the |
//| amount of the trailStop before moving stop loss                  |
//+------------------------------------------------------------------+
void TrailIt( int byPips )                   // based on trailing stop code from MT site... thanks MT!
  {
  if (byPips >=5)
  {
  for (int i = 0; i < OrdersTotal(); i++) {
     OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
     if ( OrderSymbol()==Symbol() && ( (OrderMagicNumber() == uniqueGridMagic) || (OrderComment() == GridName)) )  // only look if mygrid and symbol...
        {
            if (OrderType() == OP_BUY) {
               //if (Bid > (OrderValue(cnt,VAL_OPENPRICE) + TrailingStop * Point)) {
               //   OrderClose(OrderTicket(), OrderLots(), Bid, 3, Violet);
               //   break;
               //}
               if (TrailingStopType == 1) {
                 if (Bid - OrderStopLoss() > StopLoss * Point) {
                       OrderModify(OrderTicket(), OrderOpenPrice(), Bid - StopLoss * Point, OrderTakeProfit(),0, Red);
                 }
               }
               else {
                 if (Bid - OrderOpenPrice() > byPips * Point) {
                    if (OrderStopLoss() < Bid - byPips * Point) {
                       OrderModify(OrderTicket(), OrderOpenPrice(), Bid - byPips * Point, OrderTakeProfit(),0, Red);
                    }
                 }
               }
            } else if (OrderType() == OP_SELL) {
               if (TrailingStopType == 1) {
                    if ((OrderStopLoss()  - Ask > StopLoss * Point) || 
                        (OrderStopLoss() == 0)) {
                       OrderModify(OrderTicket(), OrderOpenPrice(),
                          Ask + StopLoss * Point, OrderTakeProfit(),0, Red);
                    }
               }
               else {
                 if (OrderOpenPrice() - Ask > byPips * Point) {
                    if ((OrderStopLoss() > Ask + byPips * Point) || 
                        (OrderStopLoss() == 0)) {
                       OrderModify(OrderTicket(), OrderOpenPrice(),
                          Ask + byPips * Point, OrderTakeProfit(),0, Red);
                    }
                 }
               }
            }
        }
	  }
	  }

  } // proc TrailIt()




//+------------------------------------------------------------------+
//| New Long Grid                                                    |
//| Open a new grid using Buy Stops                                  |
//| No counter trades are placed                                     |
//| If Stop Loss or TakeProfit are used the values are calculated    |
//| for each trade                                                   |
//+------------------------------------------------------------------+
void NewLongGrid()
{
   int i,ticket;
   double myStopLoss = 0;
   
   LongTradeRate = Ask;
   for( i=1;i<=GridSteps;i++)
   {
       LongTradeRate = LongTradeRate + Point*GridSize;
       myStopLoss = 0;
       if ( StopLoss > 0 ) myStopLoss = LongTradeRate-Point*StopLoss ;
 // modified by cori. Using OrderMagicNumber to identify the trades of the grid
       if (TakeProfit>0)
       {
           ticket=OrderSend(Symbol(),OP_BUYSTOP,Lots,LongTradeRate,0,myStopLoss,LongTradeRate+Point*TakeProfit,GridName,uniqueGridMagic,0,Green); 
       }
       else
       {
           ticket=OrderSend(Symbol(),OP_BUYSTOP,Lots,LongTradeRate,0,myStopLoss,0,GridName,uniqueGridMagic,0,Green); 
       }
    }
    GridCount=GridSteps;
}

//+------------------------------------------------------------------+
//| Add To Long Grid                                                 |
//| Add new positions to a long grid using Buy Stops                 |
//| No counter trades are placed                                     |
//| If Stop Loss or TakeProfit are used the values are calculated    |
//| for each trade                                                   |
//| LongTradeRate is used to determine where new Buy Stops occur     |
//| GridCount is used to determine how many new grid trades to add   |
//+------------------------------------------------------------------+
void AddToLongGrid()
{
   int i,ticket,Num2Add;
   double myStopLoss = 0;
   
   Num2Add = GridSteps - GridCount;
   for( i=1;i<=Num2Add;i++)
   {
       LongTradeRate = LongTradeRate + Point*GridSize;
         
       myStopLoss = 0;
       if ( StopLoss > 0 ) myStopLoss = LongTradeRate-Point*StopLoss ;
 // modified by cori. Using OrderMagicNumber to identify the trades of the grid
       if (TakeProfit>0)
       {
           ticket=OrderSend(Symbol(),OP_BUYSTOP,Lots,LongTradeRate,0,myStopLoss,LongTradeRate+Point*TakeProfit,GridName,uniqueGridMagic,0,Green); 
       }
       else
       {
           ticket=OrderSend(Symbol(),OP_BUYSTOP,Lots,LongTradeRate,0,myStopLoss,0,GridName,uniqueGridMagic,0,Green); 
       }
    }
    GridCount=GridSteps;
}


//+------------------------------------------------------------------+
//| New Short Grid                                                   |
//| Open a new grid using Sell Stops                                 |
//| No counter trades are placed                                     |
//| If Stop Loss or TakeProfit are used the values are calculated    |
//| for each trade                                                   |
//+------------------------------------------------------------------+
void NewShortGrid()
{
   int i, ticket;
   double myStopLoss = 0;
   
   ShortTradeRate = Bid;
   for( i=1;i<=GridSteps;i++)
   {
       ShortTradeRate = ShortTradeRate - Point*GridSize;
       myStopLoss = 0;
       if ( StopLoss > 0 ) myStopLoss = ShortTradeRate+Point*StopLoss ;
 // modified by cori. Using OrderMagicNumber to identify the trades of the grid
       if (TakeProfit > 0)
       {
           ticket=OrderSend(Symbol(),OP_SELLSTOP,Lots,ShortTradeRate,0,myStopLoss,ShortTradeRate-Point*TakeProfit,GridName,uniqueGridMagic,0,Red); 
       }
       else
       {
           ticket=OrderSend(Symbol(),OP_SELLSTOP,Lots,ShortTradeRate,0,myStopLoss,0,GridName,uniqueGridMagic,0,Red); 
       }
    }
    GridCount=GridSteps;
}

//+------------------------------------------------------------------+
//| Add To Short Grid                                                |
//| Add new positions to a short grid using Sell Stops               |
//| No counter trades are placed                                     |
//| If Stop Loss or TakeProfit are used the values are calculated    |
//| for each trade                                                   |
//| ShortTradeRate is used to determine where new Sell Stops occur   |
//| GridCount is used to determine how many new grid trades to add   |
//+------------------------------------------------------------------+
void AddToShortGrid()
{
   int i, ticket,Num2Add;
   double myStopLoss = 0;
   
   Num2Add = GridSteps - GridCount;
   for( i=1;i<=Num2Add;i++)
   {
       ShortTradeRate = ShortTradeRate - Point*GridSize;
       myStopLoss = 0;
       if ( StopLoss > 0 ) myStopLoss = ShortTradeRate+Point*StopLoss ;
 // modified by cori. Using OrderMagicNumber to identify the trades of the grid
       if (TakeProfit > 0)
       {
           ticket=OrderSend(Symbol(),OP_SELLSTOP,Lots,ShortTradeRate,0,myStopLoss,ShortTradeRate-Point*TakeProfit,GridName,uniqueGridMagic,0,Red); 
       }
       else
       {
           ticket=OrderSend(Symbol(),OP_SELLSTOP,Lots,ShortTradeRate,0,myStopLoss,0,GridName,uniqueGridMagic,0,Red); 
       }
    }
    GridCount=GridSteps;
}


//+------------------------------------------------------------------+
//| DetermineLots                                                    |
//| Attempt at money management                                      |
//+------------------------------------------------------------------+
double DetermineLots()
{
   double MyLots, AB;
   
   MyLots = Lots;
   AB = AccountBalance();
   if (AB > 20000) MyLots = 0.2;
   if (AB > 40000) MyLots = 0.3;
   if (AB > 60000) MyLots = 0.4;
   if (AB > 80000) MyLots = 0.5;
   if (AB > 100000) MyLots = 1;
   
   return (MyLots);
}


//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
  {
//---- 
   int currentOpen = 0;
   bool haveLongGrid=false,haveShortGrid=false;
//---- setup parameters 


 bool myWantLongs = true;
 bool myWantShorts = true;

//---- test if we want to shutdown or suspend
   if (suspendGrid == true) {       // close unfilled orders and then test if profit target
      ClosePendingOrdersAndPositions(false,"BUY");
      ClosePendingOrdersAndPositions(false,"SELL");
      return(0);
   }
   if (shutdownGrid == true) {      // close all positions and orders. then exit.. there is nothing more to do
      ClosePendingOrdersAndPositions(true,"BUY");
      ClosePendingOrdersAndPositions(false,"SELL");
      return(0);
   }
//----
   if (gridActive == false) {       // if grid not active, do nothing.
     return(0);
   }

//----

  if (MathAbs(CurTime()-LastUpdate)> UpdateInterval*60)           // we update the first time it is called and every UpdateInterval minutes
   {
   
        TestForProfit(uniqueGridMagic, true, false );
        if (!IsTesting()) {
            Comment(" v 1.93  "," Server time is ",TimeToStr(CurTime( )),
               "\n",
//               "\n","                  Closed p&l  = ",closedProfit,
               "\n","                  Open p&l    = ",openProfit,
//               "\n","                  Total p&l   = ",closedProfit + openProfit,  
               "\n","                  Long, Short = ",openLongs,"  ",openShorts, 
               "\n","                  Net pos     = ",openLongs-openShorts,
               "\n",
               "\n","                  Balance     = ",AccountBalance(),
               "\n","                  Equity      = ",AccountEquity(),
               "\n","                  Margin      = ",AccountMargin(),
               "\n","                  Free mrg    = ",AccountFreeMargin()
               );
            }

   
   
       LastUpdate = CurTime();
   }
   
   
   
   Lots = DetermineLots();
   
// Check if open positions need to be closed because of change in trend

   if (CheckExitCondition("BUY"))
//   if (haveLongGrid && CheckExitCondition("BUY"))
   {
//      CloseAllPendingOrders();
//      if ( CloseOpenPositions == true ) { ClosePendingOrdersAndPositions(); }
        ClosePendingOrdersAndPositions(true,"BUY");
        haveLongGrid = false;
        GridCount = 0;
        myWantLongs = false;
        myWantShorts = true;
   }
   if (CheckExitCondition("SELL"))
//   if (haveShortGrid && CheckExitCondition("SELL"))
   {
//      CloseAllPendingOrders();
//      if ( CloseOpenPositions == true ) { ClosePendingOrdersAndPositions(); }
        ClosePendingOrdersAndPositions(true,"SELL");
        haveShortGrid = false;
        GridCount = 0;
        myWantLongs = true;
        myWantShorts = false;
    }
    
// Check if any open positions

   currentOpen = openPositions();
   if (currentOpen > 0)
   {
      if (trailStop > 0) TrailIt(trailStop);
      
   }
   GridCount = openGrids();
   
   if ( myWantLongs && CheckEntryCondition("BUY") )
   {
      if (GridCount == 0 && currentOpen != GridSteps)
      {
        NewLongGrid();
        haveLongGrid = true;
      }
      else
      {
        if (GridCount != GridSteps && ExtendGrid) AddToLongGrid();
      }
      
   }
   if ( myWantShorts && CheckEntryCondition("SELL"))
   {
        if ( GridCount == 0 && currentOpen != GridSteps)
        {
          NewShortGrid();
          haveShortGrid = true;
        }
        else
        {
          if (GridCount != GridSteps && ExtendGrid) AddToShortGrid();
        }
        
   }
   return(0);
  }
//+------------------------------------------------------------------+