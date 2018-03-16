//+------------------------------------------------------------------+
//|   ViperGridEa.mq4
//|   Viper Trading 
//|   Recoded and enhanced by: TradingViper
//|   Base code taken from : FOREXflash (forexfactory)
//|   Original based on: WilliamsA (forexpeacearmy)
//|
//|   Backround: This is a Martingale system which will always win
//|   given unlimited trade capital/margin. This system likes trending 
//|   markets and the system "Death Trade" occurs in sideways markets
//|   where trades are accumulated, never liquidated, until margin is 
//|   exhausted. Therefore, the system should be traded with the largest
//|   capital possible, the maximum leverage available, AND the absolute
//|   smallest position size allowed.
//|
//|   Modifications: I have added a few additional entry filters to try to 
//|   enter the market when it is trending or most likely to be trending,
//|   lessening the chance of hitting the death trade.  More importantly,
//|   I have added code that trys to determine if we may be caught in
//|   the "Death Trade Trap" and enters a "liquidation" mode, in which no 
//|   further open orders are placed, pending orders are cancelled, and 
//|   it attempts to liquidate all open positions for a profit. The logic
//|   is that if we are whipsawing back and forth, we should be able to 
//|   close open positions on both sides for a profit, at the right points
//|   of the whip. Most likely this will not actually be possible, but even 
//|   if we can close "most" positions for a profit, we will minimize the 
//|   losses.  Here's to hoping  :-)
//|   
//+------------------------------------------------------------------+
#property copyright "Viper Trading"
#property link      ""

//#include <stderror.mqh>
#include <OrderReliable_v0_2_5.mqh>


//+------------------------------------------------------------------+
//| Function:  allowSaintTrading
//|            Allow easy access handle to add trading filter code
//|            for my buddy ForexSaint :-) Only change code in designated
//|            space please.
//+------------------------------------------------------------------+
bool
allowSaintTrading() 
{
   bool tradingIsAllowed = true;

   // ************* Enter test code here ************* //
   // Should set variable 'tradingIsAllowed' to false if you want to restrict
   // trading due to whatever test you conceive
   // e.g. if( forexSaint == Sad ) tradingIsAllowed = false;
   
   // Start new trade filter code here...



   // End new trade filter code here.

   return (tradingIsAllowed);
}



//+------------------------------------------------------------------+
//+------------------- Input Parameters -----------------------------+
//+------------------------------------------------------------------+

//+------------------------- Magic Number ---------------------------+
extern int       MagicNumber=847433225;   // VGRIDEA25


//+------------------- Grid Definition Parameters -------------------+
//+ These parameters control the basic Grid structure - from an initial
//+ entry or pivot price, a set of orders is placed. All orders are
//+ initially placed at the same time in a hedging fashion. More orders 
//+ are placed as price moves in such a way that regardless of market 
//+ direction, the trade set will be profitable.
//+
//+ Levels - the number of price levels at which orders placed above the 
//+          pivot (buy stops) and below the pivot price (sell stops).
//+
//+ Increment - the distance (in pips) between the price levels. The same 
//+          distance from the highest level is used for both the take profit
//+          and the stoploss for the orders in the opposite direction
//+
//+ IncrementAdjustForTpSl - an adjustment (in pips) to the take profit
//+          stoploss levels. To remain profitable, should be >= 0
//+
//+ IncrementAdjustFirstLevel - an adjustment (in pips) to the first level 
//+          only. Can be positive or negative. All other levels are 
//+          unaffected and are still spaced by the Increment value.
//+
//+ AutoIncrementPercentATR - percentage (as integer) of daily ATR used
//+          to automatically compute the Increment (if it was equal zero).
//+          The increment is computed in such a way that half the grid 
//+          size will equal the percentage of ATR defined. Using a value
//+          50 will make each half of the grid equal to half the average
//+          ATR or in other words the entire grid equal to one ATR.
//+
extern string    Note0="****** Grid Definition Parameters ******";

extern string    Note0a="--Increment=0 means auto computed, else in pips--";
extern int       Levels = 3;
extern int       Increment = 35;  // release version use 25
extern int       IncrementAdjustForTpSl = 0;
extern int       IncrementAdjustFirstLevel = 0;
extern int       AutoIncrementPercentATR = 50;


//+------- Money Management and Risk Control Parameters -------------+
//+ These parameters control the money management and risk control.
//+ They control the position size for the initial trade, which can be
//+ multiplied in subsequent positions. This strategy will ALWAYS win
//+ given you have enough capital (margin) and a long enough period of
//+ time. Therefore, SMALL is BEAUTIFUL. The agorithm will always use 
//+ the min lot size allowed by your broker unless you choose to risk a 
//+ percentage of margin or set MinLotSize.
//+
//+ ProfitFactor - This is an integer multiple of the increment used to 
//+          determine the desired profit from each trade set. The larger
//+          the number is, the more aggressive the strategy is and the 
//+          more likely the "Death Trade" will occur. A value of 1 is 
//+          pretty conservative, a value of 2 is moderately aggressive
//+          (the value used by original developer), a value of 3 is 
//+          aggressive, and any value greater than 3, and you are simply 
//+          crazy.
//+
//+ PercentToRisk - This is the percentage of your available free margin
//+          to risk on the initial position for each grid level. It is  
//+          a whole percentage, so 1.0 represent one percent, 1.1
//+          represents 1.1 percent, etc - Use 0 to disable and revert to
//+          min lot size allowed.
//+
//+ MinLotSize - This is the minimum position size for each position in the
//+          grid. Later, as more positions are opened, multiples of this
//+          may be used. Setting this to zero will use the min 
//+          size allowed by the broker (recommended).
//+
//+ EntireSetTakeProfit - This is an early profit exit strategy. If set to a
//+          positive number (e.g. +200), the algorithm will close/delete all 
//+          open positions if the intratrade profit in dollars is equal to or 
//+          greater than the value set.
//+
//+ EntireSetStopLoss - This is an early bailout strategy. If set to a
//+          negative number (e.g. -200), the algorithm will close/delete all 
//+          open positions if the intratrade drawdown in dollars is equal to or 
//+          greater than the value set.
//+
//+ Low-Water Mark risk mitigation efforts: This is the first of two "Death Trade"
//+          mitigation strategies. If any of the Low-Water parameters get triggered,
//+          the software will continue to trade as normal but begin decreasing the 
//+          ProfitFactor parameter (above). This will make the strategy less
//+          aggressive, but still remain profitable. Eventually, if the water rises 
//+          to high, the strategy will only open enough new positions 
//+          to prevent a loss.
//+          Each can be turned off with a value of 0.
//+
//+ MaxPercentMarginProfitAdjust - If our total margin consumed is greater
//+          than this parameter value, low-water mitigation is triggered.
//+
//+ MaxLotsAdjust - If our total lots (open and pending) is greater 
//+          than this parameter value, low-water mitigation is triggered.
//+         
//+ MaxOrdersAdjust - If our total number of orders (open and pending) is greater 
//+          than this parameter value, low-water mitigation is triggered.
//+         
//+
//+ High-Water Mark risk mitigation efforts: This, like the Low-Water mark parameter, is a 
//+          "Death Trade" mitigation strategy. This time, if any of the High-Water 
//+          parameters get triggered, we take emergency procedures.
//+          The strategy stops opening new positions, deletes all pending orders,
//+          and begins closing strategic positions which are at least a little 
//+          profitable (at least X increment of pips). 
//+          Each can be turned off with a value of 0.
//+
//+ MaxPercentMarginLiquidate - If our total margin consumed is greater
//+          than this parameter value, high-water mitigation is triggered.
//+
//+ MaxLotsLiquidate - If our total lots (open and pending) is greater 
//+          than this parameter value, high-water mitigation is triggered.
//+          Setting to zero, negates it's use
//+         
//+ MaxOrdersLiquidate - If our total number of orders (open and pending) is greater 
//+          than this parameter value, high-water mitigation is triggered.
//+
//+ StealthMode - If true, EA hides the real stoploss values from the Broker. It still places 
//+          a stoploss with the trade, but a full increment away from the real value. This 
//+          limits the ability of the broker to 'run' the price to your stops or spike the  
//+          spread trigger your stops.
//+
extern string    Note1="****** Money Management and Risk Control *******";

extern string    Note1a="--ProfitFactor-> {0..3}--";
extern int       ProfitFactor = 2;
extern string    Note1b="--PercentToRisk=0.0 means fixed min lot, 1.0=1% equity--";
extern double    PercentToRisk = 0.0;
extern double    MinLotSize = 0.0;

extern string    Note1c="--Both in dollars; Set TP positive(20) SL negative (-300) to use;--";
extern double    EntireSetTakeProfit = 0.0;  
extern double    EntireSetStopLoss = 0.0;  

extern string    Note1d="--Low-Water mark death trade mitigation - will always still profit--";
extern int       MaxPercentMarginProfitAdjust = 0; // low water mark
extern double    MaxLotsAdjust = 0.0;  // Another way to reach the high water mark
extern int       MaxOrdersAdjust = 0;

extern string    Note1e="--High-Water mark death trade mitigation - will likely end in trade set loss--";
extern int       MaxPercentMarginLiquidate = 0;    // high water mark
extern double    MaxLotsLiquidate = 0.0;  // Another way to reach the high water mark
extern int       MaxOrdersLiquidate = 0;  // Another way to reach the high water mark

extern bool      StealthMode = false;

//+---------------- Entry Control Filter Parameters -----------------+
//+ These parameters control when a new trade set (for the grid) can be initiated.
//+ A trade set includes all orders opened on the grid levels until they are all
//+ closed.
//+ 
//+ INCLUSIVE FILTERS - Each one that is turned on MUST pass the filter to start a  
//+          new trade set
//+ 
//+ MinHourToStart - This is the min time hour that a new trade set can be started.
//+          If the current hour (BROKER TIME) is greater than or equal to the time 
//+          specified, the trade is allowed to begin. Use a value of -1 to not use 
//+          a min start time filter.
//+
//+ MaxHourToStart - This is the max time hour that a new trade set can be started.
//+          If the current hour (BROKER TIME) is less than or equal to the time 
//+          specified, the trade is allowed to begin. Use a value of -1 to not use 
//+          a max start time filter. These two parameters create a "tradable time"
//+
//+ InvertTimeWindow - The two parameters above create a tradable time window. A
//+          time window in which trading is allowed. If this parameter is set to 
//+          true, it changes the definition of the defined time window to one which
//+          cannot be traded. Trading will be allowed only outside the time window.
//+          This is useful to define a time period in which you want to avoid trading.
//+
//+ MaxSetEntryCount - This is the number of trade sets allowed to start and complete.
//+          If a time window is defined, exiting that time window will reset this 
//+          count. This way a user can set a time window and allow only a set number
//+          of trade sets every time we enter that allowed time window (e.g. 1)
//+          If set to zero, there are no counting restrictions. As long as other entry
//+          control parameters do not inhibit trading a new trade will be started.
//+
//+ TradeSunday, TradeMonday, TradeTuesday, TradeWednesday, TradeThursday, TradeFriday -
//+          Set the days of the week to allow trading - This is BROKER TIME, not local
//+          time. The defined time window (if set) will only be active on the days that
//+          allow trading.
//+
//+ MaxSpreadToOpen - This filters trade set starting by current spread. The trade will 
//+          not start until the current spread of the current pair is less than or equal
//+          to the current spread. Once established, all future open positions are placed
//+          using the same spread value used to initiate the grid so all future orders
//+          be placed on the grid with the same take profit and same stop-loss. If the 
//+          spread is vastly different at the desired time of closure than at the start,
//+          all positions will still be closed once one has been closed. Profits may be 
//+          skewed however.
//+
//+ EXCLUSIVE FILTERS - Any single one of the following filters that are turned on MUST pass  
//+          the filter to start a new trade set. e.g If all the following filters are set on then
//+          either the volatility filter OR the trend filter OR the range filter must pass.
//+          It requires only ONE to pass to enter the trade set.
//+ 
//+ UseVolatilityFilterIRegr - If set true, trades will only be taken if the current prices of
//+          CURRENT CHART TIMEFRAME exceed volatility thresholds - Definition of volatility
//+          based on iRegr indicator. Price must exceed bounds in the direction.
//+
//+ UseVolatilityFilterBB - If set true, trades will only be taken if the current prices of
//+          CURRENT CHART TIMEFRAME exceed volatility thresholds - Definition of volatility
//+          based on Bollinger Band width as a ratio to ATR.
//+
//+ UseTrendFilter - If set true, trades will only be taken if the current prices of
//+          CURRENT CHART TIMEFRAME appear to be trending based on some standard indicators.
//+ 
//+ RangeFilterPeriod - Number of bars of current chart used to compute the average range.
//+          If the RangeFilterPeriod equals zero, the filter is turned off.
//+
//+ RangeFilterThreshold - The limit for which the average true range (ATR) must be greater than
//+          to enter a new set. It is defined here in Pips. If it is set to zero, then logically
//+          every possible computed ATR will be greater, effectively turning it off.
//+ 
extern string    Note2="****** Entry Control Filters ******";

// Inclusive Filters - Allow entry if ALL true (of the ones activated)

extern string    Note2a="--Hour(0-23)==-1 means no time filter, can control independently--";
extern int       MinHourToStart   = -1;
extern int       MaxHourToStart   = -1;
extern bool      InvertTimeWindow = false; // if true, can't start new trade sequence in time window
extern int       MaxSetEntryCount = 0;

extern bool      TradeSunday    = true;
extern bool      TradeMonday    = true;
extern bool      TradeTuesday   = true;
extern bool      TradeWednesday = true;
extern bool      TradeThursday  = true;
extern bool      TradeFriday    = true;

extern string    Note2b="--Specific desired starting Pivot price";
extern double    InitialPivotPrice = 0.0;
extern bool      UseStrongPsychSupportPivot = false;

extern string    Note2c="--Max spread to open in pips";
extern int       MaxSpreadToOpen = 10;

// Exclusive Filters - Allow entry if ANY are true (of the ones activated)

extern string    Note2d="--UseVolatilityFilters false to turn off filter--";
extern bool      UseVolatilityFilterBB = false;
extern int       volatilityPeriod=24;

extern bool      UseVolatilityFilterIRegr = false;
extern int       degree = 3;
extern double    kstd = 2.0;
extern int       bars = 250;

extern string    Note2e="--UseTrendFilter false to turn off--";
extern bool      UseTrendFilter = false;

extern string    Note2f="--Range (ATR) test--";
extern int       RangeFilterPeriod = 0;
extern int       RangeFilterThreshold = 0;


//+---------------- Visual/Audio Control Parameters -----------------+
//+ These variables control the look and feel of the user interface. They do not change 
//+          the functionality of the software.
//+
//+ Verbose - If set to false, the software only logs when critical events occur, 
//+          like new trades. If set to true, the logs will get large quickly
//+
//+ AlertsEnabled - If set to true, some events will trigger alerts - Starting a new
//+          trade set or having illegal inputs for instance.
//+
//+ ShowPriceLevels - If true, the EA will draw lines on the chart for each price level,
//+          including the initial pivot price. It will draw them using the colors defined 
//+          below.
//+
//+ PivotColor, BuyColor, SellColor - These are strings but they must be legal single word 
//+          web colors, two word colors were not implemented (have mercy on my fingers)
//+          For example, all the basic colors (e.g. Red, Blue, Purple, Navy,...) including many 
//+          one word exotic colors have been implemented (e.g. Tomato, Cornsilk, Wheat,...) 
//+          Each one must start with a capital letter and contain only one capital letter
//+          since it is a single word. e.g. "DarkBlue", was not implemented, spite it being
//+          a legal web color.
//+ 
extern string    Note3="****** Logging Control ******";
extern bool      AlertsEnabled = true;
extern bool      Verbose = true;

extern string    Note4="****** Visual Control ******";
extern bool      ShowPriceLevels = false;
extern string    PivotColor = "Gold";
extern string    BuyColor  = "Magenta";
extern string    SellColor = "Magenta";

// Will be removed and automated true for forward runs, 
// false for backtesting
extern bool      UseOrdersReliable  = true;

extern bool      WriteLog                 = false;
extern int       LogPeriodSaveTime        = PERIOD_M5;
extern string    DecimalPointChar         = ".";
int FileLog;
bool FileOpened;
//----------------- #define Constants -------------------------------+

#define ACCUMULATE 1
#define LIQUIDATE -1

#define MAX_ENTRY_SLIPPAGE 5
#define MAX_EXIT_SLIPPAGE 15

#define SECOND 1000
#define MINUTE 60000

#define STEALTH_FACTOR 1
#define TOO_MANY_ORDERS 148


//---- Global Variables ---------------------------------------------+

int      Mode = ACCUMULATE;
bool     FirstPass = true;
double   PointValue;
string   Version = "version 2.6.2";
bool     AllowedTradingDay[7]={false};
int      SetCount;
bool     DebugPrint = false;

// Variables to remain fixed throughout set
double   lots, spread, initialPrice; 
int      levels, increment, incrementAdjustStart, incrementAdjustFinal;
bool     stealthy;

// Currently Unused functionality
bool     UseProfitTarget=false;
bool     UsePartialProfitTarget=false;
int      TargetAutoIncrement  = 10;
int      NextTarget = 10;


//+------------------------------------------------------------------+
//| expert initialization function
//+------------------------------------------------------------------+
int init()
{  
   // log on file
   OpenLogFile();
   
   if(Verbose) Print("init() called");

   // Account for brokers that use 5 digit precision
   PointValue = Point;
   if( Digits == 5 || Digits == 3 ) PointValue *= 10;

   if( MinHourToStart < 0 || MinHourToStart > 23 ) MinHourToStart = -1;
   if( MaxHourToStart < 0 || MaxHourToStart > 23 ) MaxHourToStart = 24;
   
   if(TradeSunday)    AllowedTradingDay[0]=true;
   if(TradeMonday)    AllowedTradingDay[1]=true;
   if(TradeTuesday)   AllowedTradingDay[2]=true;
   if(TradeWednesday) AllowedTradingDay[3]=true;
   if(TradeThursday)  AllowedTradingDay[4]=true;
   if(TradeFriday)    AllowedTradingDay[5]=true;

   if( IsTesting() )
   { 
      ShowPriceLevels = false;
      Verbose = false;
      UseOrdersReliable = false;
   }
   
   initializeGridState(); 
   FirstPass = true;

   return(0);
}


//+------------------------------------------------------------------+
//| expert deinitialization function
//+------------------------------------------------------------------+
int deinit()
{  
   if (FileOpened)FileClose(FileLog);
   deletePriceLevels();
   return(0);
}


//+------------------------------------------------------------------+
//| expert start function
//+------------------------------------------------------------------+
int start()
{
   WriteLogLine();
   
   int ticket, cpt, profitTarget=0, buyGoalProfit=0, sellGoalProfit=0;
   int totalOpenOrderCount=0, numLongPositions=0, numShortPositions=0, 
       numLongPendingOrders=0, numShortPendingOrders=0;
   double buyGoal=0.0, sellGoal=0.0, buyPrice=0.0, sellPrice=0.0;
   int percentMarginUsed=0, tradeProfit=0, errorCode;
   double totalPositionSize=0.0, longPositionLotSize=0.0, shortPositionLotSize=0.0, 
          longPendingOrderLotSize=0.0, shortPendingOrderLotSize=0.0;
   string initialSetKey="";


   // Gather some basic information about current state of trade
   computeSessionStats( numLongPositions, longPositionLotSize, numShortPositions, shortPositionLotSize, 
                        numLongPendingOrders, longPendingOrderLotSize, numShortPendingOrders, shortPendingOrderLotSize,
                        tradeProfit, percentMarginUsed, initialSetKey );

   totalOpenOrderCount = numLongPositions+numShortPositions+numLongPendingOrders+numShortPendingOrders;
   totalPositionSize = longPositionLotSize+shortPositionLotSize+longPendingOrderLotSize+shortPendingOrderLotSize;

   // If program is restarted in middle of set,
   // restore grid state of set
   if( FirstPass )
   {
      if( totalOpenOrderCount > 0 )
      {
         if(Verbose) Print("EA Reloaded, FirstPass==true and we have ",totalOpenOrderCount," open orders");
         restoreGridState();
         drawPriceLevels();
      }
      FirstPass = false;
   }

   double stopLossStealthAdjust = 0.0;
   if( stealthy ) stopLossStealthAdjust = STEALTH_FACTOR*increment*PointValue;

   if( totalOpenOrderCount <= 0 )
   {
      // Check to see if this is a good time to enter a new set - 
      // If it fails to be a good time, wait before checking again
      if( !tradingIsDesirable() ) 
      {
         return (0);
      }
      
      // If we have no open positions, reset mode to ACCUMULATE
      Mode = ACCUMULATE;
      DebugPrint = false;
      
      // Set all variables which should remain fixed for duration of trade sequence
      SetCount++;
      
      initializeGridState(); 
      saveGridState();
      
      initialSetKey = currentDatetimeStr()+";@"+DoubleToStr(initialPrice,Digits);
      
      if( AlertsEnabled ) Alert(Symbol()," - STARTING NEW TRADE SET; Set: ",SetCount);
      
      Print("STARTING NEW TRADE SET; Set: ",SetCount,"; "+
            "StartTime: "+initialSetKey,"; InitialPrice: ",DoubleToStr(initialPrice,Digits) );
      
      // Delete all objects that may have been drawn on window for previous set
      // and draw the new levels for the new grid
      deletePriceLevels();
      drawPriceLevels();
      
      //+------------------------------------------------------------------+
      // - Open Check - Start Cycle
      
      sellGoal = initialPrice-((levels+1)*increment+incrementAdjustFinal+incrementAdjustStart)*PointValue;
      buyGoal  = initialPrice+((levels+1)*increment+incrementAdjustFinal+incrementAdjustStart)*PointValue;
      
      for(cpt=1; cpt <= levels; cpt++)
      {
         buyPrice  = initialPrice+(cpt*increment+incrementAdjustStart)*PointValue;
         sellPrice = initialPrice-(cpt*increment+incrementAdjustStart)*PointValue;
         
         if( UseOrdersReliable  ) {
         OrderSendReliable(Symbol(),OP_BUYSTOP,lots,buyPrice,MAX_ENTRY_SLIPPAGE,sellGoal-stopLossStealthAdjust,
                           buyGoal,initialSetKey,MagicNumber,0);
         OrderSendReliable(Symbol(),OP_SELLSTOP,lots,sellPrice,MAX_ENTRY_SLIPPAGE,buyGoal+spread+stopLossStealthAdjust,
                           sellGoal+spread,initialSetKey,MagicNumber,0);
         }
         else {
         OrderSend(Symbol(),OP_BUYSTOP,lots,buyPrice,MAX_ENTRY_SLIPPAGE,sellGoal-stopLossStealthAdjust,
                   buyGoal,initialSetKey,MagicNumber,0);
         OrderSend(Symbol(),OP_SELLSTOP,lots,sellPrice,MAX_ENTRY_SLIPPAGE,buyGoal+spread+stopLossStealthAdjust,
                   sellGoal+spread,initialSetKey,MagicNumber,0);
         }
         Sleep(1*SECOND);
      }
      
      // Should we check here that all orders were sucessful...  if not endsession();

   } // initial entry setup done - all channels are set up
   
   else if(Mode == ACCUMULATE) // We are in the middle of a trade set
   {
      // Check for partial profits
      checkForPartialProfits();
      
      if( haveClosedOrdersFromSet(initialSetKey) ) 
      {
         if(Verbose) Print("have Closed Orders From Set - Closing all orders for a profit");
         endSession();
         return(0);
      }
      
      int profitFactorUsed = adjustedProfitFactor(percentMarginUsed, totalPositionSize, totalOpenOrderCount);
      profitTarget = increment*profitFactorUsed;
      
      // if we have hit the low water mark, take reduced profits if available
      if( profitFactorUsed != ProfitFactor && checkCurrentProfit(lots,initialSetKey) >= profitTarget) 
      {
         if(Verbose) Print("Reduced Profit Target (",profitTarget," pips) achieved; Closing all orders");
         endSession();
         return(0);
      }
      
      buyGoal  = initialPrice+((levels+1)*increment+incrementAdjustFinal+incrementAdjustStart)*PointValue;
      sellGoal = initialPrice-((levels+1)*increment+incrementAdjustFinal+incrementAdjustStart)*PointValue;
      
      // Get the current profit in pips
      buyGoalProfit  = checkPendingProfit(lots,OP_BUY, initialSetKey);
      sellGoalProfit = checkPendingProfit(lots,OP_SELL,initialSetKey);
      
      if(buyGoalProfit < profitTarget)   // - Increment lots Buy
      {
         for(cpt=levels; cpt >= 1 && buyGoalProfit < profitTarget; cpt--)
         {
            if(Verbose) Print("Need to buy; Lvl:",cpt,"; Bid:",DoubleToStr(Bid,Digits),
                              "; Long positions:",numLongPositions,"; Pending Orders:",numLongPendingOrders,
                              "; ProfitTarget=",profitTarget,", Current Profit at BuyGoal=",buyGoalProfit);
            
            buyPrice = initialPrice+(cpt*increment+incrementAdjustStart)*PointValue;
            
            if(Ask <= buyPrice-MarketInfo(Symbol(),MODE_STOPLEVEL)*PointValue)
            {
               if( UseOrdersReliable ) {
               ticket =
               OrderSendReliable(Symbol(),OP_BUYSTOP,cpt*lots,buyPrice,MAX_ENTRY_SLIPPAGE,sellGoal-stopLossStealthAdjust,
                                 buyGoal,initialSetKey,MagicNumber,0);
               }
               else {
               ticket =
               OrderSend(Symbol(),OP_BUYSTOP,cpt*lots,buyPrice,MAX_ENTRY_SLIPPAGE,sellGoal-stopLossStealthAdjust,
                         buyGoal,initialSetKey,MagicNumber,0);
               }
               
               // Base profits on 'normal' grid without TP profit adjustment
               if(ticket > 0) buyGoalProfit += cpt*(buyGoal - buyPrice)/PointValue - incrementAdjustFinal;
               else
               {
                  errorCode = GetLastError();
                  if(Verbose) Print("Unable to buy - error "+errorCode+" during OrderSend");
                  
                  if(errorCode==TOO_MANY_ORDERS) 
                  {
                     if(Verbose) Print("Too many orders - setting mode to Liquidate!!");
                     Mode = LIQUIDATE;
                  }
                  else Sleep(10*SECOND); // Prevent trying every tick
               }
            }
            else
            {
               if(Verbose) Print("Unable to buy - market price (Ask:",DoubleToStr(Ask,Digits),
                                 ") too close or greater than buy price (",
                                 DoubleToStr(buyPrice,Digits),") for level ",cpt);
               
               if( Bid > buyGoal+(MarketInfo(Symbol(),MODE_STOPLEVEL)+5)*PointValue )
               {
                  DebugPrint = true;
                  haveClosedOrdersFromSet(initialSetKey);
                  Print("Price has exceeded buyGoal; Closing all orders..."); 
                  endSession();
               }
            }
            Sleep(1*SECOND);
         }
      }
      
      if(sellGoalProfit < profitTarget)   // - increment Lots Sell
      {
         for(cpt=levels; cpt >= 1 && sellGoalProfit < profitTarget; cpt--)
         {
            if(Verbose) Print("Need to sell; Lvl:",cpt,"; Ask:",DoubleToStr(Ask,Digits),
                              "; Short positions:",numShortPositions,"; Pending Orders:",numShortPendingOrders,
                              "; ProfitTarget=",profitTarget,", Current Profit at SellGoal=",sellGoalProfit);
            
            sellPrice = initialPrice-(cpt*increment+incrementAdjustStart)*PointValue;
            
            if(Bid >= sellPrice-MarketInfo(Symbol(),MODE_STOPLEVEL)*PointValue)
            {
               if( UseOrdersReliable ) {
               ticket =
               OrderSendReliable(Symbol(),OP_SELLSTOP,cpt*lots,sellPrice,MAX_ENTRY_SLIPPAGE,buyGoal+spread+stopLossStealthAdjust,
                                 sellGoal+spread,initialSetKey,MagicNumber,0);
               }
               else {
               ticket =
               OrderSend(Symbol(),OP_SELLSTOP,cpt*lots,sellPrice,MAX_ENTRY_SLIPPAGE,buyGoal+spread+stopLossStealthAdjust,
                         sellGoal+spread,initialSetKey,MagicNumber,0);
               }
               
               // Base profits on 'normal' grid without TP profit adjustment
               if(ticket > 0) sellGoalProfit += cpt*(sellPrice - sellGoal - spread)/PointValue + incrementAdjustFinal;
               else
               {
                  errorCode = GetLastError();
                  if(Verbose) Print("Unable to sell - error "+errorCode+" during OrderSend");
                  
                  if(errorCode==TOO_MANY_ORDERS) 
                  {
                     if(Verbose) Print("Too many orders - setting mode to Liquidate!!");
                     Mode = LIQUIDATE;
                  }
                  else Sleep(10*SECOND); // Prevent trying every tick
               }
            }
            else
            {
               if(Verbose) Print("Unable to sell - market price (Bid:",DoubleToStr(Bid,Digits),
                                 ") too close or less than sell price (",
                                 DoubleToStr(sellPrice,Digits),") for level ",cpt);
               
               if( Ask < buyGoal-(MarketInfo(Symbol(),MODE_STOPLEVEL)+5)*PointValue )
               {
                  DebugPrint = true;
                  haveClosedOrdersFromSet(initialSetKey);
                  Print("Price has exceeded sellGoal; Closing all orders..."); 
                  endSession();
               }
            }
            
            Sleep(1*SECOND);
         }
      }
      
      // Check for high-water mark
      if( (MaxPercentMarginLiquidate > 0 && percentMarginUsed > MaxPercentMarginLiquidate) ||
          (MaxLotsLiquidate > 0 && totalPositionSize >= MaxLotsLiquidate) ||
          (MaxOrdersLiquidate > 0 && totalOpenOrderCount >= MaxOrdersLiquidate) ||
          (Mode==LIQUIDATE)
        ) 
      {
         // Transition into LIQUIDATE mode - and take some first steps
         
         Mode = LIQUIDATE;
         if( AlertsEnabled ) Alert(Symbol()," ** EXCEEDED HIGH-WATER MARK - LIQUIDATING!! **");
         Print("** EXCEEDED HIGH-WATER MARK - LIQUIDATING!! ****"+ 
               ", percentMarginUsed:",percentMarginUsed,
               ", positionLotSize:",DoubleToStr(totalPositionSize,2),
               ", totalOpenOrderCount:",totalOpenOrderCount);

         // First delete all pending orders - lets not dig ourselves any deeper  
         
         deletePendingOrders();
         
         // We need to remove the effects of stealthy stops because we are no longer going to close 
         // the entire set when one order gets liquidated. So orders will be closed at the take profit 
         // or the "stealthy stops" which will add a lot of loss. 
         
         if(stealthy)
         { 
            reduceOrdersStopLoss(STEALTH_FACTOR*increment);
            stealthy = false;
         }
         
         // Increase logging levels for T/S
         DebugPrint = true;
      }
   }
   else  // Mode == LIQUIDATE
   {
      // If we can exit the entire set for a profit or breakeven, do it
      // You escaped to live and trade another day
      
      if( tradeProfit >= 0 )
      { 
         if(Verbose) Print("Trade profit found in Liquidation Mode - Liquidating entire set!");
         endSession();
      }
      
      // Ideally, we want to liquidate every order we can for a profit.
      // Try to get at least a single increments worth of profit out to minimize the loss when 
      // the TP/SL is finally triggered. 
      // In the best situation, the market will continue sideways long enough and wide enough 
      // to allow us to liquidate everything for a profit - after all, that is what it did to get
      // us into this mess  :-)
      
      // We want to liquidate the strongest profit side positions only for a profit if possible. 
      // Then the other side will increase its strength and if that becomes the strongest side, 
      // start liquidating that side. 
      // We want to do this to prevent getting killed if the price moves through the weaker side.
      
      // Also think about / study the effects of moving in the TP/SL on the weak side... hmmm...
      
      // Get the current profit in pips
      buyGoalProfit  = checkPendingProfit(lots,OP_BUY, initialSetKey);
      sellGoalProfit = checkPendingProfit(lots,OP_SELL,initialSetKey);
      
      if(Seconds()==0) // log 1 min situation updates
      {
         if(Verbose && DebugPrint) 
         {
            Print("Liquidation Update: Current Open Orders: "+totalOpenOrderCount+
                  ", TotalPositionSize: "+DoubleToStr(totalPositionSize,2)+
                  ", Margin Used: "+percentMarginUsed+"%"+
                  ", buyGoalProfit="+buyGoalProfit+" pips"+
                  ", sellGoalProfit="+sellGoalProfit+" pips"+
                  ", Current Ask/Bid="+DoubleToStr(Ask,Digits)+"/"+DoubleToStr(Bid,Digits) );
            
            DebugPrint = false;
         }
      }
      else DebugPrint = true;
      
      int bailProfit = 1*increment;
      if( buyGoalProfit >= sellGoalProfit )
      {
         if( buyGoalProfit > 0 ) exitProfitPosition(OP_BUY, 0); // buy side really strong
         else                    exitProfitPosition(OP_BUY, bailProfit);
      }
      else  // sellGoalProfit > buyGoalProfit 
      {
         if( sellGoalProfit > 0 ) exitProfitPosition(OP_SELL, 0); // sell side really strong
         else                     exitProfitPosition(OP_SELL, bailProfit);
      }
   }
   
   // Check TakeProfit for Entire Set - Take early profit
   if( EntireSetTakeProfit > 0.0 && tradeProfit >= EntireSetTakeProfit )
   {
      if( AlertsEnabled ) Alert(Symbol()," ** EXCEEDED INTRASET TAKE PROFIT ($"+tradeProfit+") - EXITING POSITIONS! **");
      else                Print("** EXCEEDED INTRASET TAKE PROFIT ($"+tradeProfit+") - EXITING POSITIONS! **");
      endSession();
   }
   
   
   // Check StopLoss for Entire Set - Cut Losses
   if( EntireSetStopLoss < 0.0 && tradeProfit <= EntireSetStopLoss )
   {
      if( AlertsEnabled ) Alert(Symbol()," ** EXCEEDED MAX INTRASET LOSS ($"+tradeProfit+") - EXITING POSITIONS! **");
      else                Print("** EXCEEDED MAX INTRASET LOSS ($"+tradeProfit+") - EXITING POSITIONS! **");
      endSession();
   }
   
   
   //+------------------------------------------------------------------+   
   //+ Display pertinent data to the screen
   
   string stealthModeStr = "FALSE";
   if( stealthy ) stealthModeStr = "TRUE";
   
   Comment( "ViperGridEA "+Version +"\n",
            "Date: "+currentDatetimeStr()+", ProfitFactor: "+profitFactorUsed+", StealthMode: "+stealthModeStr+"\n",
            "Fixed Spread:  "+DoubleToStr(spread/PointValue,1)+", "+"MaxSpread: "+MaxSpreadToOpen+", "+
            "Current Spread:  "+DoubleToStr((Ask-Bid)/PointValue,1)+"\n",
            "SetCount: "+SetCount+", Increment: "+increment+", Levels: "+levels+", Unit Lot Size:  "+DoubleToStr(lots,2)+"\n",
            "Set Start Time: "+initialSetKey+", Initial Price: "+DoubleToStr(initialPrice,Digits)+"\n",
            "Current Open Orders: "+totalOpenOrderCount+", TotalPositionSize: "+DoubleToStr(totalPositionSize,2)+", "+
            "Percent Margin Used: "+percentMarginUsed+"%\n",
            "Long Positions: "+numLongPositions+", Long Position Lots: "+DoubleToStr(longPositionLotSize,2)+"\n",
            "Long Pending Orders: "+numLongPendingOrders+", Long Pending Lots: "+DoubleToStr(longPendingOrderLotSize,2)+"\n",
            "Short Positions: "+numShortPositions+", Short Position Lots: "+DoubleToStr(shortPositionLotSize,2)+"\n",
            "Short Pending Orders: "+numShortPendingOrders+", Short Pending Lots: "+DoubleToStr(shortPendingOrderLotSize,2)+"\n",
            "Account Balance: $"+DoubleToStr(AccountBalance(),2)+", "+
            "Free Margin: $"+DoubleToStr(AccountFreeMargin(),2)+", "+
            "Margin Used: $"+DoubleToStr(AccountMargin(),2)+"\n",
            "Current Set Profit: $"+tradeProfit+"\n" 
          );
   
   return(0);  // end of start()
}


//+------------------------------------------------------------------+
//| Function:  currentDatetimeStr
//+------------------------------------------------------------------+
string 
currentDatetimeStr()
{
   // return a datetime string in the following format 2009.11.02-07:30:01

   string datetimeString = Year()+"."+Month()+"."+Day()+"-"+Hour()+":"+Minute()+":"+Seconds();
   return (datetimeString);
}


//+------------------------------------------------------------------+
//| Function:  checkCurrentProfit
//+------------------------------------------------------------------+
int 
checkCurrentProfit(double lotsize, string commentKey)
{
   int profit=0, cpt;
   
   if(lotsize==0.0) Alert(Symbol(),"; checkCurrentProfit()-lotsize==0.0 causing divide by zero");
   
   //return current profit
   
   for(cpt=0;cpt<OrdersTotal();cpt++)
   {
      OrderSelect(cpt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber && OrderComment()==commentKey)
      {
         if(OrderType()==OP_BUY)  profit+=(Bid-OrderOpenPrice())/PointValue*OrderLots()/lotsize;
         if(OrderType()==OP_SELL) profit+=(OrderOpenPrice()-Ask)/PointValue*OrderLots()/lotsize;
      }
   }
   return(profit);
}


//+------------------------------------------------------------------+
//| Function:  checkPendingProfit
//+------------------------------------------------------------------+
int 
checkPendingProfit(double lotsize, int orderType, string commentKey)
{
   int profit=0, cpt;
   double realStopLoss, tpAdj = incrementAdjustFinal*PointValue;
   
   if(lotsize==0.0) Alert(Symbol(),"; checkPendingProfit()-lotsize==0.0 causing divide by zero");
   
   if(orderType==OP_BUY)
   {
      for(cpt=0;cpt<OrdersTotal();cpt++)
      {
         OrderSelect(cpt, SELECT_BY_POS, MODE_TRADES);
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber && OrderComment()==commentKey)
         {
            realStopLoss = OrderStopLoss();
            if( stealthy ) realStopLoss -=STEALTH_FACTOR*increment*PointValue; 

            //Compute profit at "normal" TP, without the TP adjustment
            if(OrderType()==OP_BUY)     profit+=(OrderTakeProfit()-tpAdj-OrderOpenPrice())/PointValue*OrderLots()/lotsize;
            if(OrderType()==OP_SELL)    profit-=(realStopLoss-OrderOpenPrice())/PointValue*OrderLots()/lotsize;
            if(OrderType()==OP_BUYSTOP) profit+=(OrderTakeProfit()-tpAdj-OrderOpenPrice())/PointValue*OrderLots()/lotsize;
         }
      }
   }
   else // orderType==OP_SELL
   {
      for(cpt=0;cpt<OrdersTotal();cpt++)
      {
         OrderSelect(cpt, SELECT_BY_POS, MODE_TRADES);
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber && OrderComment()==commentKey)
         {
            realStopLoss = OrderStopLoss();
            if( stealthy ) realStopLoss +=STEALTH_FACTOR*increment*PointValue;

            //Compute profit at "normal" TP, without the TP adjustment
            if(OrderType()==OP_BUY)      profit-=(OrderOpenPrice()-realStopLoss)/PointValue*OrderLots()/lotsize;
            if(OrderType()==OP_SELL)     profit+=(OrderOpenPrice()-OrderTakeProfit()+tpAdj)/PointValue*OrderLots()/lotsize;
            if(OrderType()==OP_SELLSTOP) profit+=(OrderOpenPrice()-OrderTakeProfit()+tpAdj)/PointValue*OrderLots()/lotsize;              
         }
      }
   }
   
   return(profit);
}


//+------------------------------------------------------------------+
//| Function:  adjustedProfitFactor
//+------------------------------------------------------------------+
int
adjustedProfitFactor( int percentMarginUsed, double positionLotSize, int openOrders )
{
   static int reportThreshold = 0;
   int overRatio=0;
   bool checkForAdjustments = false;
   
   if( MaxPercentMarginProfitAdjust > 0 )
   {
      overRatio = MathMax(percentMarginUsed / MaxPercentMarginProfitAdjust, overRatio);
      checkForAdjustments = true;
   }   
   if( MaxLotsAdjust > 0 )
   {
      overRatio = MathMax(positionLotSize / MaxLotsAdjust, overRatio);
      checkForAdjustments = true;
   }
   if( MaxOrdersAdjust > 0 )
   {
      overRatio = MathMax(openOrders / MaxOrdersAdjust, overRatio);
      checkForAdjustments = true;
   }
   
   if( checkForAdjustments )
   {      
      int modifiedProfitFactor = MathMax(ProfitFactor - overRatio,0);
      
      // Check low-water marks 
      if( overRatio > reportThreshold )
      {
         if( AlertsEnabled ) 
            Alert(Symbol()," ** WARNING - EXCEEDED LOW-WATER Mark - Reducing ProfitFactor to ",modifiedProfitFactor," !! **");
         Print("** WARNING - EXCEEDED LOW-WATER Mark - Reducing ProfitFactor to ",modifiedProfitFactor,
                   ", overRatio:",overRatio,", reportThreshold:",reportThreshold,
                   ", percentMarginUsed:",percentMarginUsed,", positionLotSize:",DoubleToStr(positionLotSize,2),
                   ", openOrders:",openOrders);
      }
      reportThreshold = overRatio;

      return (modifiedProfitFactor);
   }
   
   return (ProfitFactor);
}


//+------------------------------------------------------------------+
//| Function:  endSession
//+------------------------------------------------------------------+
void 
endSession()
{
   if(Verbose) Print("** endSession() called - closing all positions **");

   // Close open positions first
   closeOpenOrders();

   // Delete remaining pending orders
   deletePendingOrders();

   // Close open orders again in case any pending orders became open 
   // positions after open positions were closed
   closeOpenOrders();

   // Clean up lines drawn on chart
   deletePriceLevels();
}


//+------------------------------------------------------------------+
//| Function:  closeOpenOrders
//+------------------------------------------------------------------+
void 
closeOpenOrders()
{
   int cpt, openOrderCount=OrdersTotal();
   
   for(cpt=openOrderCount-1; cpt >= 0; cpt--)
   {
      OrderSelect(cpt,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber)
      {
         if(OrderType()==OP_BUY)  
            if( UseOrdersReliable  ) OrderCloseReliable(OrderTicket(),OrderLots(),Bid,MAX_EXIT_SLIPPAGE);
            else                     OrderClose(OrderTicket(),OrderLots(),Bid,MAX_EXIT_SLIPPAGE);
         if(OrderType()==OP_SELL) 
            if( UseOrdersReliable  ) OrderCloseReliable(OrderTicket(),OrderLots(),Ask,MAX_EXIT_SLIPPAGE);
            else                     OrderClose(OrderTicket(),OrderLots(),Ask,MAX_EXIT_SLIPPAGE);
      }
   }
}


//+------------------------------------------------------------------+
//| Function:  deletePendingOrders
//+------------------------------------------------------------------+
void 
deletePendingOrders()
{
   int cpt, openOrderCount=OrdersTotal();
   
   for(cpt=openOrderCount-1; cpt >= 0; cpt--)
   {
      OrderSelect(cpt,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber)
      {
         if(OrderType()!=OP_BUY && OrderType()!=OP_SELL) OrderDelete(OrderTicket());
      }
   }
}


//+------------------------------------------------------------------+
//| Function:  exitProfitPosition
//+------------------------------------------------------------------+
void 
exitProfitPosition(int orderType, int minProfitInPips)
{
   double exitPrice;
   
   int totalOrders = OrdersTotal();
   for(int cpt=totalOrders-1; cpt >= 0; cpt--)
   {
      OrderSelect(cpt,SELECT_BY_POS,MODE_TRADES);
      if( OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber )
      {
         if(OrderType()==orderType)
         {
            int currentProfit = getPipValue(OrderOpenPrice(),orderType);
            if(currentProfit >= minProfitInPips)
            {
               if(orderType==OP_BUY) 
               {      
                  exitPrice = Bid;
                  if(Verbose) Print("exitProfitPosition; Exiting long position for profit=",currentProfit," pips");
               }
               else if(orderType==OP_SELL) 
               {
                  exitPrice = Ask;
                  if(Verbose) Print("exitProfitPosition; Exiting short position for profit=",currentProfit," pips");
               }
               
               if(UseOrdersReliable) OrderCloseReliable(OrderTicket(),OrderLots(),exitPrice,MAX_EXIT_SLIPPAGE);
               else                  OrderClose(OrderTicket(),OrderLots(),exitPrice,MAX_EXIT_SLIPPAGE);
            }
         }          
      }
   }
}


//+------------------------------------------------------------------+
//| Function:  reduceOrdersStopLoss
//+------------------------------------------------------------------+
void
reduceOrdersStopLoss(int stopLossReductionInPips)
{
   double stopLossPriceMod = NormalizeDouble(stopLossReductionInPips*PointValue,Digits);
   int stopModDirection = 0;

   int totalOrders = OrdersTotal();
   for(int cpt=totalOrders-1; cpt >= 0; cpt--)
   {
      OrderSelect(cpt,SELECT_BY_POS,MODE_TRADES);
      if( OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber )
      {
         if(OrderType()==OP_BUY) 
         {      
            stopModDirection = 1;
            if(Verbose) Print("reduceStopLossOrders; Adding ",stopLossReductionInPips,
                              " pips to OP_BUY stoploss");
         }
         else if(OrderType()==OP_SELL) 
         {
            stopModDirection = -1;
            if(Verbose) Print("reduceStopLossOrders; Subtracting ",stopLossReductionInPips,
                              " pips to OP_SELL stop loss");
         }
               
         if(UseOrdersReliable) OrderModifyReliable(OrderTicket(),OrderOpenPrice(),
                                                   OrderStopLoss()+stopModDirection*stopLossPriceMod,0,0);
         else                  OrderModify(OrderTicket(),OrderOpenPrice(),
                                                   OrderStopLoss()+stopModDirection*stopLossPriceMod,0,0);
      }
   }
}


//+------------------------------------------------------------------+
//| Function:  haveClosedOrdersFromSet
//+------------------------------------------------------------------+
bool 
haveClosedOrdersFromSet(string commentKey)
{
   if(Verbose && DebugPrint) Print("haveClosedOrdersFromSet; input commentKey="+commentKey);

   // If we have closed any orders from the set, close them all
   int totalOldOrders = OrdersHistoryTotal();
   
   for(int cpt=totalOldOrders-1; cpt >= 0; cpt--)
   {
      OrderSelect(cpt,SELECT_BY_POS,MODE_HISTORY);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber)
      {
         // For closed orders, MQ4 appends their own "close reason" comments to the end of yours. 
         // Use only your comment portion for comparison
         string closedOrderCommentKey = StringSubstr(OrderComment(),0,StringLen(commentKey));
         if(Verbose && DebugPrint) Print("haveClosedOrdersFromSet; closed order commentKey="+closedOrderCommentKey);

         if(closedOrderCommentKey==commentKey)
         {
            DebugPrint = false;
            return(true);
         }
      }
   }
   
   return (false);
}


//+------------------------------------------------------------------+
//| Function:  checkForPartialProfits
//+------------------------------------------------------------------+
void 
checkForPartialProfits()
{
   for( int cpt=0; cpt < OrdersTotal(); cpt++ )
   {
      OrderSelect(cpt,SELECT_BY_POS,MODE_TRADES);
      if(OrderMagicNumber()==MagicNumber && OrderSymbol()==Symbol())
      {
         if(UsePartialProfitTarget && UseProfitTarget && OrderType() < 2)
         {
            double val=getPipValue(OrderOpenPrice(),OrderType());
            takeProfit(val,OrderTicket()); 
         }
      }
   }
}


//+------------------------------------------------------------------+
//| Function:  getPipValue                            
//+------------------------------------------------------------------+
double 
getPipValue(double entryPrice, int dir)
{
   double val;
   RefreshRates();
   if(dir==OP_SELL) val = (NormalizeDouble(entryPrice,Digits) - NormalizeDouble(Ask,Digits));
   else             val = (NormalizeDouble(Bid,Digits) - NormalizeDouble(entryPrice,Digits));
   
   val /= PointValue;
   
   return(val);   
}


//+------------------------------------------------------------------+
//| Function:  takeProfit
//+------------------------------------------------------------------+
void 
takeProfit(int current_pips, int ticket)
{
   if(OrderSelect(ticket, SELECT_BY_TICKET))
   {
      if(current_pips >= NextTarget && current_pips < (NextTarget + TargetAutoIncrement ))
      {
         double price;
         if(OrderType()==1) price = Ask;
         else               price = Bid;
         
         bool success;
         if( UseOrdersReliable ) success = OrderCloseReliable(ticket, OrderLots(), price, MAX_EXIT_SLIPPAGE);
         else                    success = OrderClose(ticket, OrderLots(), Ask, MAX_EXIT_SLIPPAGE);
         
         if( success )
            NextTarget+=TargetAutoIncrement;
         else
            Print("Error closing order : ",GetLastError()); 
      }
   }
}

void OpenLogFile()
{
    if (WriteLog)
    {
        string FileName = WindowExpertName()+" "+Symbol() + " log.csv";
        FileLog = FileOpen(FileName,FILE_READ|FILE_CSV,';');                           
        if (FileLog < 1)
        {
            // the file not exist, create new with header
            FileLog = FileOpen(FileName,FILE_WRITE|FILE_CSV,';');
            FileWrite(FileLog,"Date","Balance","Equity","FLoatPL","Profit","UsedMargin","FreeMargin");
        }
        else
        {
            FileClose(FileLog);
            FileLog = FileOpen(FileName,FILE_READ|FILE_WRITE|FILE_CSV,';');
            FileSeek(FileLog, 0, SEEK_END);
        }
        FileOpened = true ;
    }     
}
void WriteLogLine()
{
    static int PrecBarTime;

    // write log
    if(WriteLog && FileOpened && PrecBarTime != iTime(Symbol(),LogPeriodSaveTime,0))
    {
        // save last write time
        PrecBarTime = iTime(Symbol(),LogPeriodSaveTime,0);
        double FLoatPL = AccountEquity() - AccountBalance();
       
        // write in file
        // "Date","Balance","Equity","FLoatPL","Profit","Margin","FreeMargin"
        FileWrite(      FileLog,
                        ChangePointData(TimeToStr(TimeCurrent(),TIME_DATE|TIME_MINUTES|TIME_SECONDS)),
                        ChangePointNum(DoubleToStr(AccountBalance(),2)),
                        ChangePointNum(DoubleToStr(AccountEquity(),2)),
                        ChangePointNum(DoubleToStr(FLoatPL ,2)),
                        ChangePointNum(DoubleToStr(AccountProfit(),2)),
                        ChangePointNum(DoubleToStr(AccountMargin(),2)),
                        ChangePointNum(DoubleToStr(AccountFreeMargin(),2))
                        );
        // save immediately on disk
        FileFlush(FileLog);
    }
}


string ChangePointNum (string Numero)
{
    if(DecimalPointChar == "" || DecimalPointChar == ".") return(Numero);
    return(StringSetChar(Numero, StringFind(Numero,"."), StringGetChar( DecimalPointChar, 0)));
}

string ChangePointData (string Data)
{
    Data = StringSetChar(Data, 4,47);
    Data = StringSetChar(Data, 7,47);
    return (Data);
}

//+------------------------------------------------------------------+
//| Function:  computeAutoIncrement
//+------------------------------------------------------------------+
int 
computeAutoIncrement()
{
   //----Collect daily range info
   double  riskToRewardRatio =  3.0;  

   int R1=0, R5=0, R10=0, R20=0, autoIncrement=0;
   int RAvg=0;
   int spreadValue = (Ask - Bid) / PointValue;
   
   int CURRENT_INDEX = 1;
   
   // Get the average daily range in pips
   R1  = iATR(NULL,PERIOD_D1, 1,CURRENT_INDEX) / PointValue;
   R5  = iATR(NULL,PERIOD_D1, 5,CURRENT_INDEX) / PointValue;
   R10 = iATR(NULL,PERIOD_D1,10,CURRENT_INDEX) / PointValue;
   R20 = iATR(NULL,PERIOD_D1,20,CURRENT_INDEX) / PointValue;
   RAvg  =  (3*R1+2*R5+R10+R20) / 7;
   
   // AutoIncrement calculation  R1 = Previous Day range, R5 = 5 day,  R10 = 10 Day
   // AutoIncrement replaces the need to manaully set increment.  PreviousDay R1 is more heavily weighted
   // then the R5 range.  
   double percentATR = AutoIncrementPercentATR /100.0;                  // Equation history for reference
   autoIncrement = (RAvg  / (levels + 1) ) * percentATR;               //  ((((R5*0.4) + (R1*0.6))/(Levels + 1)) / (2));
                                                                      //   (((R5)/(Levels + 1))/2);
   
   if(Verbose) Print("Setting autoincrement; RAvg="+RAvg+"; autoIncrement="+autoIncrement);

   double minStopLevel = MarketInfo(Symbol(),MODE_STOPLEVEL)*Point/PointValue;

   if(autoIncrement <= minStopLevel+spreadValue)
   {
      autoIncrement = minStopLevel+spreadValue+1;
   }
   
   return(autoIncrement);
}


//+------------------------------------------------------------------+
//| Function:  computeSessionStats
//+------------------------------------------------------------------+
void
computeSessionStats( int & longPositions, double & longPositionSize,
                     int & shortPositions, double & shortPositionSize,
                     int & longPendingOrders, double & longPendingSize,
                     int & shortPendingOrders, double & shortPendingSize, 
                     int & tradeProfit, int & percentMarginUsed,
                     string & setCommentKey ) 
{
   int orderType; 
   double lotSize;
   
   for( int cpt=0; cpt < OrdersTotal(); cpt++ )
   {
      OrderSelect(cpt,SELECT_BY_POS,MODE_TRADES);
      if(OrderMagicNumber()==MagicNumber && OrderSymbol()==Symbol())
      {
         if(setCommentKey=="") setCommentKey = OrderComment();

         orderType = OrderType();
         lotSize = OrderLots();
         
         if(orderType==OP_BUY) 
         {
            longPositions++;
            longPositionSize += lotSize;
         }
         else if(orderType==OP_SELL)
         {
            shortPositions++;
            shortPositionSize += lotSize;
         }
         else if(orderType==OP_BUYSTOP)
         {
            longPendingOrders++;
            longPendingSize += lotSize;
         }
         else if(orderType==OP_SELLSTOP)
         {
            shortPendingOrders++;
            shortPendingSize += lotSize;
         }
         
         tradeProfit += OrderProfit();
      }
   }
   
   percentMarginUsed = MathCeil(AccountMargin()/(AccountMargin()+AccountFreeMargin())*100);
}


//+------------------------------------------------------------------+
//| Function:  computeLots
//+------------------------------------------------------------------+
double
computeLots( double percentEquityToRisk ) 
{
   double MINLOT = MarketInfo(Symbol(),MODE_MINLOT);
   double lotsize = MINLOT;
   
   if( MinLotSize > 0.0 )
   { 
      MinLotSize = NormalizeDouble(MinLotSize/MINLOT,0)*MINLOT;
      lotsize = MinLotSize;
   }
   if( percentEquityToRisk > 0 )
   {
      lotsize = MathMax(lotsize,NormalizeDouble(AccountBalance()*percentEquityToRisk/10000,0)*MINLOT);
   }
   
   if(lotsize < MINLOT) lotsize = MINLOT;
   
   return (lotsize);
}


//+------------------------------------------------------------------+
//| Function:  tradingIsDesirable
//| Run all entry condition filters in here (trend, volatility, time of day, etc.) 
//| to try to maxamize chances of avoiding the dreaded death trade
//+------------------------------------------------------------------+
bool
tradingIsDesirable()
{
   bool isDesirableInclusive = true;
   string failReason = "ViperGridEA: "+Symbol()+"; No trade allowed;\n";
   
   
   //-----------------------------------------------------------------------------
   //-----------------------------------------------------------------------------
   //  INCLUSIVE FILTERS 

   //-----------------------------------------------------------------------------
   // Perform time of day test
   int currentHour = Hour();
   bool inDefinedWindow = (currentHour >= MinHourToStart && currentHour <= MaxHourToStart);
   if( (!InvertTimeWindow && !inDefinedWindow) ||
       ( InvertTimeWindow && inDefinedWindow)  )
   {
      isDesirableInclusive = false;
      failReason = failReason + "Not within allowed time window;\n";
      SetCount = 0;
   }
   
   
   //-----------------------------------------------------------------------------
   // Perform day of week test
   int currentDay = DayOfWeek();
   if( AllowedTradingDay[currentDay] == false )
   {
      isDesirableInclusive = false;
      failReason = failReason + "Not within allowed day of week;\n";
   }
   
   
   //-----------------------------------------------------------------------------
   // Perform max set count test
   if( MaxSetEntryCount > 0 && SetCount >= MaxSetEntryCount )
   {
      isDesirableInclusive = false;
      failReason = failReason + "Already executed max number of allowed sets: "+SetCount+"\n";
   }
   

   //-----------------------------------------------------------------------------
   // Perform specified pivot price test
   if( InitialPivotPrice > 0.0 && Ask != InitialPivotPrice )
   {
      isDesirableInclusive = false;
      failReason = failReason + "Ask Price not at specified pivot price: "+
                   DoubleToStr(InitialPivotPrice,Digits)+", Current Ask: "+
                   DoubleToStr(Ask,Digits)+"\n";
   }
   

   //-----------------------------------------------------------------------------
   // Perform Psychological support pivot price test
   if( UseStrongPsychSupportPivot && !isStrongPsychSupportLevel(Ask) )
   {
      isDesirableInclusive = false;
      failReason = failReason + "Ask Price not at strong psychological support pivot price: "+
                   ", Current Ask: "+DoubleToStr(Ask,Digits)+"\n";
   }
   

   //-----------------------------------------------------------------------------
   // Perform Spread test
   // 
   
   int currentSpread = (Ask-Bid)/PointValue;
   if( MaxSpreadToOpen > 0 && currentSpread > MaxSpreadToOpen )
   {
      isDesirableInclusive = false;
      failReason = failReason + "Spread too wide; Currently: "+currentSpread+" (pips)\n";
   }
   
   
   //-----------------------------------------------------------------------------
   // Perform generic user test
   // 
   
   if( allowSaintTrading()==false )
   {
      isDesirableInclusive = false;
      failReason = failReason + "allowSaintTrading() failed;\n";
   }
   
   

   //-----------------------------------------------------------------------------
   //-----------------------------------------------------------------------------
   //  EXCLUSIVE FILTERS - Only one of the turned on filters is needed to pass

   bool exclusiveFiltersOff = true;
   bool isDesirableExclusive = false;
   
   //-----------------------------------------------------------------------------
   // Perform Volatilities test
   
   if( UseVolatilityFilterIRegr != 0.0 )
   {
      exclusiveFiltersOff = false;
      if(!isVolatile(Period()))
      {
         failReason = failReason + "Insufficient volatility according to iRegr;\n";
      }
      else isDesirableExclusive = true;
   }
   
   
   if( UseVolatilityFilterBB != 0.0 )
   {
      exclusiveFiltersOff = false;
      if(!isVolatile2(Period()))
      {
         failReason = failReason + "Insufficient volatility according to Bollinger Bands;\n";
      }
      else isDesirableExclusive = true;
   }  

 
   //-----------------------------------------------------------------------------
   // Perform trending test
   // Don't care if it is moving up or down just that it is moving
   // Can force to pass multiple timeframes if desired -
   
   if( UseTrendFilter )
   {
      exclusiveFiltersOff = false;
      if( trendDirection(Period()) == 0 )
      {
         failReason = failReason + "Insufficient trend strength;\n";
      }
      else isDesirableExclusive = true;
   }
   
   
   //-----------------------------------------------------------------------------
   // Perform range test
   // 
   
   if( RangeFilterPeriod > 0 )
   {
      exclusiveFiltersOff = false;
      int atrPips = iATR(NULL,0,RangeFilterPeriod,1) / PointValue;
      
      if( atrPips <= RangeFilterThreshold )
      {
         failReason = failReason + "Insufficient price movement (bar range);\n";
      }
      else isDesirableExclusive = true;
   }
   
   
   //-----------------------------------------------------------------------------
   // Completed all Entry filters - If fails, comment on failed entry
   
   bool isDesirable = isDesirableInclusive && (isDesirableExclusive || exclusiveFiltersOff);
   
   if( !isDesirable )
   {
      Comment( "                                          ","\n",   
               "**Unable to Enter Market due to the following reason(s)**","\n",
               failReason ,"\n");
   }
   
   // return result of filter tests
   return (isDesirable);
}


//+------------------------------------------------------------------+
//| Function:  trendDirection
//+------------------------------------------------------------------+
int
trendDirection(int timeframe)
{
   int currentTrend = 0;
   
   // Check for trend - (non-flat)
   
   int rsiPeriod = 24, cciPeriod = 50;
   int shortEma = 21, longEma = 55;
   
   double rsi          = iRSI(NULL,timeframe,rsiPeriod,PRICE_CLOSE,1);
   double cci          = iCCI(NULL,timeframe,cciPeriod,PRICE_TYPICAL,1);
   double ShortMaOpen  = iMA(NULL,timeframe,shortEma,0,MODE_EMA,PRICE_OPEN,1);
   double ShortMaClose = iMA(NULL,timeframe,shortEma,0,MODE_EMA,PRICE_CLOSE,1);
   double LongMaHi     = iMA(NULL,timeframe,longEma,0,MODE_EMA,PRICE_HIGH,1);
   double LongMaLo     = iMA(NULL,timeframe,longEma,0,MODE_EMA,PRICE_LOW,1);
   
   if(ShortMaClose >= ShortMaOpen && ShortMaClose >= LongMaHi && rsi >= 50 && cci >= 0) currentTrend =  1;
   if(ShortMaClose <= ShortMaOpen && ShortMaClose <= LongMaLo && rsi <= 50 && cci <= 0) currentTrend = -1;
   
   return( currentTrend );
}


//+------------------------------------------------------------------+
//| Function:  isVolatile
//+------------------------------------------------------------------+
bool
isVolatile(int timeFrame)
{
   bool isVolatile = false;

//   int volatilityPeriod=24;
//   int volatilityFactor=2;
   
//   double iBandHiCurrent = 
//   iBands(NULL,timeFrame,volatilityPeriod,volatilityFactor,0,PRICE_CLOSE,MODE_UPPER,1);
   
//   double iBandLoCurrent = 
//   iBands(NULL,timeFrame,volatilityPeriod,volatilityFactor,0,PRICE_CLOSE,MODE_LOWER,1);
   
//   double iBandHiPrevious = 
//   iBands(NULL,timeFrame,volatilityPeriod,volatilityFactor,0,PRICE_CLOSE,MODE_UPPER,2);
   
//   double iBandLoPrevious = 
//   iBands(NULL,timeFrame,volatilityPeriod,volatilityFactor,0,PRICE_CLOSE,MODE_LOWER,2);
   
   // Use the last closed bar for all computations
   // If the bands are moving down and price closes above the upper band OR
   // if the bands are moving up and the price closes below the lower band

//   if( iBandHiCurrent < iBandLoCurrent  && Close[1] > iBandHiCurrent ) isVolatile = true;
//   if( iBandLoCurrent > iBandLoPrevious && Close[1] < iBandLoCurrent ) isVolatile = true;

   int shift = 0;

   double topCurrent=iCustom(NULL,timeFrame,"i-Regr",degree,kstd,bars,shift,1,1);
   double botCurrent=iCustom(NULL,timeFrame,"i-Regr",degree,kstd,bars,shift,2,1);

   double topPrevious=iCustom(NULL,timeFrame,"i-Regr",degree,kstd,bars,shift,1,2);
   double botPrevious=iCustom(NULL,timeFrame,"i-Regr",degree,kstd,bars,shift,2,2);

   // Use the last closed bar for all computations
   // If the bands are moving down and price closes above the upper band OR
   // if the bands are moving up and the price closes below the lower band

   if( topCurrent < topPrevious && iClose(NULL,timeFrame,1) > topCurrent ) isVolatile = true;
   if( botCurrent > botPrevious && iClose(NULL,timeFrame,1) < botCurrent ) isVolatile = true;
   
   return (isVolatile);   
}


//+------------------------------------------------------------------+
//| Function:  isVolatile2
//+------------------------------------------------------------------+
bool
isVolatile2(int timeFrame)
{
   int volatilityFactor=2;
   double TEN_PERCENT = 0.10;
   
   double iBandHi = 
   iBands(NULL,timeFrame,volatilityPeriod,volatilityFactor,0,PRICE_CLOSE,MODE_UPPER,1);
   
   double iBandLo = 
   iBands(NULL,timeFrame,volatilityPeriod,volatilityFactor,0,PRICE_CLOSE,MODE_LOWER,1);
   
   double bandDiff = iBandHi - iBandLo;
   
   double averageTrueRange = iATR(NULL,timeFrame,volatilityPeriod,1);
   
   bool swingVolatility = bandDiff / averageTrueRange > volatilityFactor+1;
   bool spikeVolatility = High[1] - iBandHi > averageTrueRange * TEN_PERCENT ||
                          iBandLo - Low[1]  > averageTrueRange * TEN_PERCENT;
                          
   return (swingVolatility || spikeVolatility);
}


//+------------------------------------------------------------------+
//| Function:  isStrongPsychSupportLevel
//+------------------------------------------------------------------+
bool
isStrongPsychSupportLevel(double price)
{
   int divisor=100;
   if(Digits>3) price*=divisor;
   if(Digits%2==1) divisor*=10;
   int intPrice=price*divisor;
   return (intPrice%divisor==0);
} 


//+------------------------------------------------------------------+
//| Function:  drawPriceLevels
//+------------------------------------------------------------------+
void
drawPriceLevels() 
{
   //
   // Draw Line at each priceLevel
   //
   if( !ShowPriceLevels ) return (0);

   if(Verbose) Print("drawPriceLevels() called");
   
   double sGoal = initialPrice-((levels+1)*increment+incrementAdjustFinal+incrementAdjustStart)*PointValue;
   double bGoal = initialPrice+((levels+1)*increment+incrementAdjustFinal+incrementAdjustStart)*PointValue;
      
   drawLevel( initialPrice, "Pivot",    StringToColor(PivotColor) );
   drawLevel( sGoal    ,    "SellGoal", StringToColor(SellColor) );
   drawLevel( bGoal     ,   "BuyGoal",  StringToColor(BuyColor) );
   
   for(int cpt=1; cpt <= levels; cpt++)
   {
      double bPrice = initialPrice+(cpt*increment+incrementAdjustStart)*PointValue;
      double sPrice = initialPrice-(cpt*increment+incrementAdjustStart)*PointValue;
   
      drawLevel( bPrice, "b"+cpt, StringToColor(BuyColor) );
      drawLevel( sPrice, "s"+cpt, StringToColor(SellColor) );
   }
}


//+------------------------------------------------------------------+
//| Function:  drawLevel
//+------------------------------------------------------------------+
void
drawLevel(double priceLevel, string priceLabel, int priceColor) 
{
   //
   // Draw Line at priceLevel
   //
   string objectTag = getObjectTagPrefix()+"_"+priceLabel;
   ObjectCreate(objectTag, OBJ_HLINE, 0, CurTime(), priceLevel);
   ObjectSet(objectTag, OBJPROP_COLOR, priceColor);
   ObjectSet(objectTag, OBJPROP_STYLE, STYLE_SOLID);
   
   if(ObjectFind(objectTag) != 0)
   {
//      ObjectCreate(objectTag, OBJ_TEXT, 0, Time[0], priceLevel);
//      ObjectSetText(objectTag, priceLabel, 14, "Arial", priceColor);
   }
   else
   {
      ObjectMove(objectTag, 0, Time[0],  priceLevel);
      ObjectMove(objectTag, 0, CurTime(),priceLevel);
   }
   
   ObjectsRedraw();
}


//+------------------------------------------------------------------+
//| Function:  deletePriceLevels
//+------------------------------------------------------------------+
void
deletePriceLevels() 
{
   // Delete Lines at all priceLevels
   // Search all objects and delete those that start with ObjectTagPrefix.
   
   if(ShowPriceLevels && Verbose) Print("deletePriceLevels() - ");
   
   string objectTagPrefix=getObjectTagPrefix();
   int objectTagPrefixSize = StringLen(objectTagPrefix);
   
   int totalNumObjects = ObjectsTotal();
   
   for( int ii=0; ii < totalNumObjects; ii++ )
   {
      string objectName = ObjectName(ii);
                                           
      if( StringSubstr(objectName,0,objectTagPrefixSize) == objectTagPrefix )
      {
         //  if(ShowPriceLevels && Verbose) Print("deletePriceLevels; Deleting object: "+objectName);
         ObjectDelete(objectName);
      }
   }
}


//+------------------------------------------------------------------+
//| Function:  getObjectTagPrefix
//+------------------------------------------------------------------+
string
getObjectTagPrefix() 
{
   return ("vg"+MagicNumber);
}


//+------------------------------------------------------------------+
//| Function:  initializeGridState
//+------------------------------------------------------------------+
void
initializeGridState() 
{
   // Set variables which should remain fixed throughout a trade set
   
   if(Verbose) Print("initializeGridState; setting new Grid State");
   
   lots = computeLots( PercentToRisk );
   initialPrice = Ask;
   spread = Ask - Bid;
   
   // Compute the best grid increment for this set of trades - 
   // then remains fixed for the entire set
   increment = Increment;
   if( increment == 0 ) increment = computeAutoIncrement();
   
   if( IncrementAdjustForTpSl < 0 ) IncrementAdjustForTpSl = 0;
   incrementAdjustFinal = IncrementAdjustForTpSl;
   incrementAdjustStart = IncrementAdjustFirstLevel;
   stealthy = StealthMode;

   levels = Levels;
}


//+------------------------------------------------------------------+
//| Function:  printGridState
//+------------------------------------------------------------------+
void
printGridState() 
{
   if(Verbose) 
   {
      Print("printGridState; Current state: ",
            "Levels="+levels+", ",
            "Increment="+increment+"(pips), ",
            "IncrementAdjustStart="+incrementAdjustStart+"(pips), ", 
            "IncrementAdjustFinal="+incrementAdjustFinal+"(pips), ", 
            "Lots="+DoubleToStr(lots,2),", ",
            "initialPrice="+DoubleToStr(initialPrice,Digits),", ",
            "fixed spread="+DoubleToStr(spread,Digits),", ",
            "SetCount=",SetCount,", ", 
            "StealthMode=",stealthy);
   }
}


//+------------------------------------------------------------------+
//| Function:  saveGridState
//+------------------------------------------------------------------+
void
saveGridState() 
{
   // Save grid state to file saved data
   
   if(Verbose) Print("saveGridState; saving grid state");
   printGridState();
   
   string fileName = getFileName();
   int file = FileOpen(fileName, FILE_CSV|FILE_WRITE);
   if( file > 0 )
   {
      FileWrite(file,levels,increment,incrementAdjustStart,incrementAdjustFinal,
                lots,initialPrice,spread,SetCount,stealthy);
      FileClose(file);
   }
   else
   {
      int error=GetLastError();
      Print("saveGridState; Error opening file "+fileName+"; "+
            "error code="+error+"; "+ErrorDescription(error));
   }
}


//+------------------------------------------------------------------+
//| Function:  restoreGridState
//+------------------------------------------------------------------+
void
restoreGridState() 
{
   // Restore grid state from file saved data
   
   if(Verbose) Print("restoreGridState; restoring grid state");
   
   string fileName = getFileName();
   int file = FileOpen(fileName, FILE_CSV|FILE_READ);
   if( file > 0 )
   {
      levels               = FileReadNumber(file);
      increment            = FileReadNumber(file);
      incrementAdjustStart = FileReadNumber(file);
      incrementAdjustFinal = FileReadNumber(file);
      lots                 = FileReadNumber(file);
      initialPrice         = FileReadNumber(file);
      spread               = FileReadNumber(file);
      SetCount             = FileReadNumber(file);
      stealthy             = FileReadNumber(file);
      
      FileClose(file);   
   }
   else
   {
      int error=GetLastError();
      Print("restoreGridState; Error opening file "+fileName+"; "+
            "error code="+error+"; "+ErrorDescription(error));
      
      // We have failed to restore - 
      string displayStr = " ** Data file problem, re-setting GridState to current settings **";
      if( AlertsEnabled ) Alert(Symbol(),displayStr);
      else                Print(displayStr);
      
      initializeGridState();
      saveGridState();
   }
   printGridState();
}


//+------------------------------------------------------------------+
//| Function:  getFileName
//+------------------------------------------------------------------+
string
getFileName() 
{
   string filename = "vgrid"+Symbol()+MagicNumber+".txt";
   return (filename);
}


//+------------------------------------------------------------------+
//| Function:  StringToColor
//|            Should move to seperate include file...
//+------------------------------------------------------------------+
color
StringToColor(string colorString) 
{
   if(colorString == "Black")      return (Black);
   if(colorString == "Olive")      return (Olive);
   if(colorString == "Green")      return (Green);
   if(colorString == "Teal")       return (Teal);
   if(colorString == "Navy")       return (Navy);
   if(colorString == "Purple")     return (Purple);
   if(colorString == "Maroon")     return (Maroon);
   if(colorString == "Indigo")     return (Indigo);
   if(colorString == "Sienna")     return (Sienna);
   if(colorString == "Brown")      return (Brown);
   if(colorString == "Chocolate")  return (Chocolate);
   if(colorString == "Crimson")    return (Crimson);
   if(colorString == "Orange")     return (Orange);
   if(colorString == "Gold")       return (Gold);
   if(colorString == "Yellow")     return (Yellow);
   if(colorString == "Chartreuse") return (Chartreuse);
   if(colorString == "Lime")       return (Lime);
   if(colorString == "Aqua")       return (Aqua);
   if(colorString == "Blue")       return (Blue);
   if(colorString == "Magenta")    return (Magenta);
   if(colorString == "Red")        return (Red);
   if(colorString == "Gray")       return (Gray);
   if(colorString == "Peru")       return (Peru);
   if(colorString == "Tomato")     return (Tomato);
   if(colorString == "Orchid")     return (Orchid);
   if(colorString == "Coral")      return (Coral);
   if(colorString == "Tan")        return (Tan);
   if(colorString == "Salmon")     return (Salmon);
   if(colorString == "Violet")     return (Violet);
   if(colorString == "Plum")       return (Plum);
   if(colorString == "Khaki")      return (Khaki);
   if(colorString == "Silver")     return (Silver);
   if(colorString == "Thistle")    return (Thistle);
   if(colorString == "Wheat")      return (Wheat);
   if(colorString == "Moccasin")   return (Moccasin);
   if(colorString == "Gainsboro")  return (Gainsboro);
   if(colorString == "Pink")       return (Pink);
   if(colorString == "Bisque")     return (Bisque);
   if(colorString == "Beige")      return (Beige);
   if(colorString == "Cornsilk")   return (Cornsilk);
   if(colorString == "Linen")      return (Linen);
   if(colorString == "Lavender")   return (Lavender);
   if(colorString == "Seashell")   return (Seashell);
   if(colorString == "Ivory")      return (Ivory);
   if(colorString == "Honeydew")   return (Honeydew);
   if(colorString == "Snow")       return (Snow);
   if(colorString == "White")      return (White);
   
   if( AlertsEnabled )
   {
      Alert(Symbol(),"; Undefined Color: ", colorString,"; Returning Magenta");
   }
   else Print("Undefined Color: ", colorString,"; Returning Magenta");
   return (Magenta);
   
   
   
   
}


