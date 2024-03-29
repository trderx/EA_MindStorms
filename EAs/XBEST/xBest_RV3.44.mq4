
//+-----------------------------------------------------------------+
//|                                                  xBest_Rv3.44.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "3.44"
#property description "xBest   Rv3.44 - Grid Hedging Expert Advisor  "
#property description "This EA init a cycle of buy or sell depending of signaling, it start with the base"
#property description "lot and increase the size at every step by its factor and set a global take profit,"
#property description "if daily target profit is hit then close all orders, also have a time filtering,"
#property description "you can enable hedging after especified quantity of loss orders."
#property description "Coder: xJhamil, Mail: yamilhurtado@gmail.com"
#property description "Alter 2018-02-27: Rmorais, Mail: rodolfo.leonardo@gmail.com"
#property strict
//---
enum ENUM_LOT_MODE
{
  LOT_MODE_FIXED = 1,   // Fixed Lot
  LOT_MODE_PERCENT = 2, // Percent Lot
};
//--- input parameters
extern string Version__ = "----------------------------------------------------------------";
extern string Version1__ = "-----------------xBest   Rv3.44 --------------------------------";
extern string Version2__ = "----------------------------------------------------------------";

extern string InpChartDisplay__ = "------------------------Display Info--------------------";
extern bool InpChartDisplay = true;             // Display Info
extern bool InpDisplayInpBackgroundColor = TRUE; // Display background color
extern color InpBackgroundColor = Teal;          // background color

extern string Magic = "--------Magic Number Engine---------";
extern string Magic_ = "--------If all the engines are disabled runs a motor in buy and sell ---------";
input bool InpEnableEngineA = true;  // Enable Engine A   [BUY]
input int InpMagic = 7799;            // Magic Number  A
input bool InpEnableEngineB = true;  // Enable Engine B   [SELL]
input int InpMagic2 = 9977;           // Magic Number  B
extern bool InpManualInitGrid = TRUE; // 1ª Order Grid Manual (Only if A / B Enable)
extern string MovingAverageConfig__ = "-----------------------------Moving Average-----------------------";
input ENUM_TIMEFRAMES InpMaFrame = PERIOD_CURRENT; // Moving Average TimeFrame
input int InpMaPeriod = 34;                        // Moving Average Period
input ENUM_MA_METHOD InpMaMethod = MODE_EMA;       // Moving Average Method
input ENUM_APPLIED_PRICE InpMaPrice = PRICE_OPEN;  // Moving Average Price
input int InpMaShift = 0;                          // Moving Average Shift

extern string Config__ = "---------------------------Config--------------------------------------";
input int InpGridSize = 3;                         // Step Size in Pips
input int InpTakeProfit = 3000;                    // Take Profit in Pips
input ENUM_LOT_MODE InpLotMode = LOT_MODE_PERCENT; // Lot Mode
input double InpFixedLot = 0.01;                   // Fixed Lot
input double InpPercentLot = 0.03;                 // Percent Lot
input double InpGridFactor = 1.1;                  // Grid Increment Factor
input int InpHedge = 0;                            // Hedge After Level
input int InpHedgex = 2;                           // After Level Change Lot A to B (Necessari all Engine Enable)
input int InpDailyTarget = 50;                     // Daily Target in Money
input double InpMaxLot = 99;                       // Max Lot
input bool InpEnableMinProfit = true;              // Enable  Minimal Profit Close
input double MinProfit = 10.00;                    // Minimal Profit Close
input int QtdTradesMinProfit = 10;                 // Qtd Trades to Minimal Profit Close
extern string TrailingStop__ = "--------------------Trailling Stop--------------";
extern bool InpUseTrailingStop = true; // Use Trailling Stop´?
extern int InpTrailStart = 5;           //   TraillingStart
extern int InpTrailStop = 1;            // Size Trailling stop

extern string FilterOpenOneCandle__ = "--------------------Filter One Order by Candle--------------";
input bool InpOpenOneCandle = true;                         // Open one order by candle
input ENUM_TIMEFRAMES InpTimeframeBarOpen = PERIOD_CURRENT; // Timeframe OpenOneCandle

extern string FilterSpread__ = "----------------------------Filter Max Spread--------------------";
input double InpMaxSpread = 0.24; // Max Spread in Pips

extern string EquityCaution__ = "------------------------Filter Caution of Equity ---------------";
extern bool InpUseEquityCaution = TRUE;                       //  EquityCaution?
extern double InpTotalEquityRiskCaution = 20;                 // Total % Risk to EquityCaution
extern ENUM_TIMEFRAMES InpTimeframeEquityCaution = PERIOD_D1; // Timeframe as EquityCaution

extern string EquitySTOP__ = "------------------------Filter  Equity STOP ---------------";
extern bool InpUseEquityStop = true;        // Usar EquityStop?
extern double InpTotalEquityRisk = 60.0;    // Total % Risk to EquityStop
extern bool InpAlertPushEquityLoss = false; //Send Alert to Celular
extern bool InpCloseAllEquityLoss = false;  // Close all orders in TotalEquityRisk

/////////////////////////////////////////////////////
extern string FFCall__ = "----------------------------Filter News FFCall------------------------";

extern int InpMinsBeforeNews = 60; // mins before an event to stay out of trading
extern int InpMinsAfterNews = 20;  // mins after  an event to stay out of trading
extern bool InpUseFFCall = true;
extern bool InpIncludeHigh = true;

///////////////////////////////////////////////
extern string TimeFilter__ = "-------------------------Filter DateTime---------------------------";
extern bool InpUtilizeTimeFilter = true;
extern bool InpTrade_in_Monday = true;
extern bool InpTrade_in_Tuesday = true;
extern bool InpTrade_in_Wednesday = true;
extern bool InpTrade_in_Thursday = true;
extern bool InpTrade_in_Friday = true;

extern string InpStartHour = "00:00";
extern string InpEndHour = "23:59";

//LOT_MODE_FIXED
//---
int SlipPage = 3;
//---

bool m_hedging1, m_target_filter1;
int m_direction1, m_current_day1, m_previous_day1;
double m_level1, m_buyer1, m_seller1, m_target1, m_profit1;
double m_pip1, m_size1, m_take1;
datetime m_datetime_ultcandleopen1;
datetime m_time_equityrisk1;
double m_mediaprice1;
int m_orders_count1;
double m_lastlot1;

bool m_hedging2, m_target_filter2;
int m_direction2, m_current_day2, m_previous_day2;
double m_level2, m_buyer2, m_seller2, m_target2, m_profit2;
double m_pip2, m_size2, m_take2;
datetime m_datetime_ultcandleopen2;
datetime m_time_equityrisk2;
double m_mediaprice2;
int m_orders_count2;
double m_lastlot2;

string m_symbol;
bool m_news_time;
double m_spreadX;
bool m_initpainel;
string m_filters_on;
double m_profit_all;
datetime m_time_equityriskstopall;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{

  if (InpManualInitGrid)
  {

    DrawRects(300, 15, Gray, 150, 50, "SELL");
    DrawRects(500, 15, Gray, 150, 50, "BUY");
  }

  //---
  m_symbol = Symbol();

  if (Digits == 3 || Digits == 5)
    m_pip1 = 10.0 * Point;
  else
    m_pip1 = Point;
  m_size1 = InpGridSize * m_pip1;
  m_take1 = InpTakeProfit * m_pip1;
  m_hedging1 = false;
  m_target_filter1 = false;
  m_direction1 = 0;

  m_datetime_ultcandleopen1 = -1;
  m_time_equityrisk1 = -1;
  m_orders_count1 = 0;
  m_lastlot1 = 0;

  if (Digits == 3 || Digits == 5)
    m_pip2 = 10.0 * Point;
  else
    m_pip2 = Point;
  m_size2 = InpGridSize * m_pip2;
  m_take2 = InpTakeProfit * m_pip2;
  m_hedging2 = false;
  m_target_filter2 = false;
  m_direction2 = 0;

  m_datetime_ultcandleopen2 = -1;
  m_time_equityrisk2 = -1;
  m_orders_count2 = 0;
  m_lastlot2 = 0;

  m_filters_on = "";
  m_initpainel = true;

  //---
  printf("xBest v3.2 - Grid Hedging Expert Advisor");
  return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  //---
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Informacoes()
{

  string Ls_64;

  int Li_84;

  if (!IsOptimization())
  {

    Ls_64 = "==========================\n";
    Ls_64 = Ls_64 + " " + " xBest FULL Hedge v3.4 2018-02-19 " + "\n";
    Ls_64 = Ls_64 + "==========================\n";
    // Ls_64 = Ls_64 + "  Broker:  " + AccountCompany() + "\n";
    Ls_64 = Ls_64 + "  Time of Broker:" + TimeToStr(TimeCurrent(), TIME_DATE | TIME_SECONDS) + "\n";
    // Ls_64 = Ls_64 + "  Currenci: " + AccountCurrency() + "\n";
    Ls_64 = Ls_64 + "  Spread: " + m_spreadX + " pips\n";
    //Ls_64 = Ls_64 + "==========================\n";
    Ls_64 = Ls_64 + "  Grid Size : " + (string)InpGridSize + " Pips \n";
    Ls_64 = Ls_64 + "  TakeProfit: " + (string)InpTakeProfit + " Pips \n";
    Ls_64 = Ls_64 + "  Lot Mode : " + (string)InpLotMode + "  \n";
    Ls_64 = Ls_64 + "  Exponent Factor: " + (string)InpGridFactor + " pips\n";
    Ls_64 = Ls_64 + "  Daily Target: " + (string)InpDailyTarget + "\n";
    Ls_64 = Ls_64 + "  Hedge After Level: " + (string)InpHedge + " \n";
    Ls_64 = Ls_64 + "  InpMaxSpread: " + (string)InpMaxSpread + " pips\n";
    Ls_64 = Ls_64 + "==========================\n";
    Ls_64 = Ls_64 + "  Spread: " + (string)MarketInfo(Symbol(), MODE_SPREAD) + " \n";
    Ls_64 = Ls_64 + "  Equity:      " + DoubleToStr(AccountEquity(), 2) + " \n";
    Ls_64 = Ls_64 + "  Last Lot : | A : " + DoubleToStr(m_lastlot1, 2) + " | B : " + DoubleToStr(m_lastlot2, 2) + " \n";
    Ls_64 = Ls_64 + "  Orders Opens :   " + string(CountTrades()) + " | A : " + (string)m_orders_count1 + " | B : " + (string)m_orders_count2 + " \n";
    Ls_64 = Ls_64 + "  Profit/Loss: " + DoubleToStr(m_profit_all, 2) + " | A : " + DoubleToStr(CalculateProfit(InpMagic), 2) + " | B : " + DoubleToStr(CalculateProfit(InpMagic2), 2) + " \n";
    Ls_64 = Ls_64 + " ==========================\n";
    Ls_64 = Ls_64 + " EquityCautionFilter : " + (string)InpUseEquityCaution + " \n";
    Ls_64 = Ls_64 + " TotalEquityRiskCaution : " + DoubleToStr(InpTotalEquityRiskCaution, 2) + " % \n";
    Ls_64 = Ls_64 + " EquityStopFilter : " + (string)InpUseEquityStop + " \n";
    Ls_64 = Ls_64 + " TotalEquityRiskStop : " + DoubleToStr(InpTotalEquityRisk, 2) + " % \n";
    Ls_64 = Ls_64 + " NewsFilter : " + (string)InpUseFFCall + " \n";
    Ls_64 = Ls_64 + " TimeFilter : " + (string)InpUtilizeTimeFilter + " \n";
    Ls_64 = Ls_64 + " ==========================\n";
    Ls_64 = Ls_64 + m_filters_on;

    Comment(Ls_64);
    Li_84 = 16;
    if (InpDisplayInpBackgroundColor)
    {
      if (m_initpainel || Seconds() % 5 == 0)
      {
        m_initpainel = FALSE;
        for (int count_88 = 0; count_88 < 12; count_88++)
        {
          for (int count_92 = 0; count_92 < Li_84; count_92++)
          {
            ObjectDelete("background" + (string)count_88 + (string)count_92);
            ObjectDelete("background" + (string)count_88 + ((string)(count_92 + 1)));
            ObjectDelete("background" + (string)count_88 + ((string)(count_92 + 2)));
            ObjectCreate("background" + (string)count_88 + (string)count_92, OBJ_LABEL, 0, 0, 0);
            ObjectSetText("background" + (string)count_88 + (string)count_92, "n", 30, "Wingdings", InpBackgroundColor);
            ObjectSet("background" + (string)count_88 + (string)count_92, OBJPROP_XDISTANCE, 20 * count_88);
            ObjectSet("background" + (string)count_88 + (string)count_92, OBJPROP_YDISTANCE, 23 * count_92 + 9);
          }
        }
      }
    }
    else
    {
      if (m_initpainel || Seconds() % 5 == 0)
      {
        m_initpainel = FALSE;
        for (int count_88 = 0; count_88 < 9; count_88++)
        {
          for (int count_92 = 0; count_92 < Li_84; count_92++)
          {
            ObjectDelete("background" + (string)count_88 + (string)count_92);
            ObjectDelete("background" + (string)count_88 + ((string)(count_92 + 1)));
            ObjectDelete("background" + (string)count_88 + ((string)(count_92 + 2)));
          }
        }
      }
    }
  }
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{

  m_profit_all = CalculateProfit();
  m_lastlot2 = FindLastSellLot(InpMagic2);
  m_lastlot1 = FindLastBuyLot(InpMagic);

  if (InpManualInitGrid)
  {
    if (m_lastlot1 > 0 || !InpEnableEngineA)
      ObjectSetInteger(0, "_lBUY", OBJPROP_BGCOLOR, Gray);
    else
      ObjectSetInteger(0, "_lBUY", OBJPROP_BGCOLOR, Blue);

    if (m_lastlot2 > 0 || !InpEnableEngineB)
      ObjectSetInteger(0, "_lSELL", OBJPROP_BGCOLOR, Gray);
    else
      ObjectSetInteger(0, "_lSELL", OBJPROP_BGCOLOR, Red);
  }

  if (InpChartDisplay)
    Informacoes();

  RefreshRates();

  m_filters_on = "";

  //FILTER SPREAD
  m_spreadX = (int)MarketInfo(Symbol(), MODE_SPREAD) * m_pip1;
  if (m_spreadX > InpMaxSpread)
  {
    m_filters_on += "Filter InpMaxSpread ON \n";
    return;
  }

  //FILTER NEWS
  if (InpUseFFCall)
    NewsHandling();

  if (m_news_time && InpUseFFCall)
  {
    m_filters_on += "Filter News ON \n";
    return;
  }

  //FILTER DATETIME
  if (InpUtilizeTimeFilter && !TimeFilter())
  {
    m_filters_on += "Filter TimeFilter ON \n";
  }

  if (m_time_equityriskstopall == iTime(NULL, PERIOD_W1, 0))
  {
    m_filters_on += "Filter EquitySTOP  ON \n";
    return;
  }

  int Sinal = 0;

  if (iClose(NULL, 0, 0) > iMA(NULL, InpMaFrame, InpMaPeriod, 0, InpMaMethod, InpMaPrice, InpMaShift))
    Sinal = 1;
  if (iClose(NULL, 0, 0) < iMA(NULL, InpMaFrame, InpMaPeriod, 0, InpMaMethod, InpMaPrice, InpMaShift))
    Sinal = -1;

  double LotsHedge = 0;

  //FILTER EquityCaution
  if (m_orders_count1 == 0)
    m_time_equityrisk1 = -1;

  //Se todos Motores estiverem desabilitados
  if (!InpEnableEngineB && !InpEnableEngineA)
  {
    if (m_time_equityrisk1 == iTime(NULL, InpTimeframeEquityCaution, 0))
    {
      m_filters_on += "Filter EquityCaution S ON \n";
    }
    else
    {

      xBest("S", Sinal, LotsHedge, InpMagic, m_orders_count1, m_mediaprice1, m_hedging1, m_target_filter1,
            m_direction1, m_current_day1, m_previous_day1, m_level1, m_buyer1, m_seller1,
            m_target1, m_profit1, m_pip1, m_size1, m_take1, m_datetime_ultcandleopen1,
            m_time_equityrisk1);
    }
  }
  else
  {
    if (!InpManualInitGrid)
    {
      if (m_time_equityrisk1 == iTime(NULL, InpTimeframeEquityCaution, 0) && m_time_equityrisk2 != iTime(NULL, InpTimeframeEquityCaution, 0))
      {
        m_filters_on += "Filter EquityCaution A ON \n";
      }
      else
      {
        // if(m_time_equityrisk2 == iTime(NULL, InpTimeframeEquityCaution, 0)) {
        if (m_orders_count2 > InpHedgex)
        {
          LotsHedge = m_lastlot2 / InpGridFactor;
        }

        if (Sinal == 1 && InpEnableEngineA)
          xBest("A", 1, LotsHedge, InpMagic, m_orders_count1, m_mediaprice1, m_hedging1, m_target_filter1,
                m_direction1, m_current_day1, m_previous_day1, m_level1, m_buyer1, m_seller1,
                m_target1, m_profit1, m_pip1, m_size1, m_take1, m_datetime_ultcandleopen1,
                m_time_equityrisk1);
      }

      if (m_orders_count2 == 0)
        m_time_equityrisk2 = -1;

      if (m_time_equityrisk2 == iTime(NULL, InpTimeframeEquityCaution, 0) && m_time_equityrisk1 != iTime(NULL, InpTimeframeEquityCaution, 0))
      {
        m_filters_on += "Filter EquityCaution B ON \n";
      }
      else
      {
        // if(m_time_equityrisk1 == iTime(NULL, InpTimeframeEquityCaution, 0)) {
        if (m_orders_count1 > InpHedgex)
        {
          LotsHedge = m_lastlot1 / InpGridFactor;
        }

        if (Sinal == -1 && InpEnableEngineB)
          xBest("B", -1, LotsHedge, InpMagic2, m_orders_count2, m_mediaprice2, m_hedging2,
                m_target_filter2, m_direction2, m_current_day2, m_previous_day2,
                m_level2, m_buyer2, m_seller2, m_target2, m_profit2, m_pip2,
                m_size2, m_take2, m_datetime_ultcandleopen2,
                m_time_equityrisk2);
      }
    }else{

     xBest("A", 0, LotsHedge, InpMagic, m_orders_count1, m_mediaprice1, m_hedging1, m_target_filter1,
                m_direction1, m_current_day1, m_previous_day1, m_level1, m_buyer1, m_seller1,
                m_target1, m_profit1, m_pip1, m_size1, m_take1, m_datetime_ultcandleopen1,
                m_time_equityrisk1);

       xBest("B", 0, LotsHedge, InpMagic2, m_orders_count2, m_mediaprice2, m_hedging2,
                m_target_filter2, m_direction2, m_current_day2, m_previous_day2,
                m_level2, m_buyer2, m_seller2, m_target2, m_profit2, m_pip2,
                m_size2, m_take2, m_datetime_ultcandleopen2,
                m_time_equityrisk2);
    }
  }

  if (InpUseEquityStop)
  {
    if (m_profit_all < 0.0 && MathAbs(m_profit_all) > InpTotalEquityRisk / 100.0 * AccountEquity())
    {
      if (InpCloseAllEquityLoss)
      {
        CloseThisSymbolAll();
        Print("Closed All due_Hilo to Stop Out");
      }
      if (InpAlertPushEquityLoss)
        SendNotification("EquityLoss Alert " + (string)m_profit_all);

      m_time_equityriskstopall = iTime(NULL, PERIOD_W1, 0);
      // m_filters_on += "Filter UseEquityStop ON \n";
      return;
    }
    else
    {
      m_time_equityriskstopall = -1;
    }
  }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void xBest(string Id, int Sinal, double LotsHedge, int vInpMagic, int &m_orders_count, double &m_mediaprice, bool &m_hedging, bool &m_target_filter,
           int &m_direction, int &m_current_day, int &m_previous_day,
           double &m_level, double &m_buyer, double &m_seller, double &m_target, double &m_profit,
           double &m_pip, double &m_size, double &m_take, datetime &vDatetimeUltCandleOpen,
           datetime &m_time_equityrisk)
{

  //--- Variable Declaration
  int index, orders_total, order_ticket, order_type, ticket, hour;
  double volume_min, volume_max, volume_step, lots;
  double account_balance, margin_required, risk_balance;
  double order_open_price, order_lots;

  //--- Variable Initialization
  int buy_ticket = 0, sell_ticket = 0, orders_count = 0;
  int buyer_counter = 0, seller_counter = 0;
  bool was_trade = false, close_filter = false;
  bool long_condition = false, short_condition = false;
  double orders_profit = 0.0, level = 0.0;
  double buyer_lots = 0.0, seller_lots = 0.0;
  double buyer_sum = 0.0, seller_sum = 0.0;
  double buy_price = 0.0, sell_price = 0.0;
  double bid_price = Bid, ask_price = Ask;
  double close_price = iClose(NULL, 0, 0);
  double open_price = iOpen(NULL, 0, 0);
  datetime time_current = TimeCurrent();
  bool res = false;

  //--- Base Lot Size
  account_balance = AccountBalance();
  volume_min = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
  volume_max = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
  volume_step = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
  lots = volume_min;

  if (InpLotMode == LOT_MODE_FIXED)
    lots = InpFixedLot;
  else if (InpLotMode == LOT_MODE_PERCENT)
  {
    risk_balance = InpPercentLot * AccountBalance() / 100.0;
    margin_required = MarketInfo(m_symbol, MODE_MARGINREQUIRED);
    lots = MathRound(risk_balance / margin_required, volume_step);
    if (lots < volume_min)
      lots = volume_min;
    if (lots > volume_max)
      lots = volume_max;
  }

  //--- Daily Calc
  m_current_day = TimeDayOfWeek(time_current);
  if (m_current_day != m_previous_day)
  {
    m_target_filter = false;
    m_target = 0.0;
  }
  m_previous_day = m_current_day;

  //--- Calculation Loop
  orders_total = OrdersTotal();
  m_mediaprice = 0;
  double BuyProfit = 0;
  double SellProfit = 0;
  for (index = orders_total - 1; index >= 0; index--)
  {
    if (!OrderSelect(index, SELECT_BY_POS, MODE_TRADES))
      continue;
    if (OrderMagicNumber() != vInpMagic || OrderSymbol() != m_symbol)
      continue;
    order_open_price = OrderOpenPrice();
    order_ticket = OrderTicket();
    order_type = OrderType();
    order_lots = OrderLots();
    //---
    if (order_type == OP_BUY)
    {
      //--- Set Last Buy Order
      if (order_ticket > buy_ticket)
      {
        buy_price = order_open_price;
        buy_ticket = order_ticket;
      }
      buyer_sum += (order_open_price + m_spreadX) * order_lots;

      buyer_lots += order_lots;
      buyer_counter++;
      orders_count++;
      m_mediaprice += order_open_price * order_lots;
      if (OrderProfit() > 0)
        BuyProfit += OrderProfit() + OrderCommission() + OrderSwap();
    }
    //---
    if (order_type == OP_SELL)
    {
      //--- Set Last Sell Order
      if (order_ticket > sell_ticket)
      {
        sell_price = order_open_price;
        sell_ticket = order_ticket;
      }
      seller_sum += (order_open_price - m_spreadX) * order_lots;

      seller_lots += order_lots;
      seller_counter++;
      orders_count++;
      m_mediaprice += order_open_price * order_lots;
      if (OrderProfit() > 0)
        SellProfit += OrderProfit() + OrderCommission() + OrderSwap();
    }

    //---
    orders_profit += OrderProfit();
  }

  m_orders_count = orders_count;
  m_profit = orders_profit;
  if ((seller_counter + buyer_counter) > 0)
    m_mediaprice = NormalizeDouble(m_mediaprice / (buyer_lots + seller_lots), Digits);

  if (InpUseTrailingStop)
    TrailingAlls(InpTrailStart, InpTrailStop, m_mediaprice, vInpMagic);

  //--- Calc
  if (orders_count == 0)
  {
    m_target += m_profit;
    m_hedging = false;
  }

  //--- Close Conditions
  if (InpDailyTarget > 0 && m_target + orders_profit >= InpDailyTarget)
    m_target_filter = true;
  //--- This ensure that buy and sell positions close at the same time when hedging is enabled
  if (m_hedging && ((m_direction > 0 && bid_price >= m_level) || (m_direction < 0 && ask_price <= m_level)))
    close_filter = true;

  //--- Close All Orders on Conditions
  if (m_target_filter || close_filter)
  {

    CloseThisSymbolAll(vInpMagic);

    // m_spread=0.0;
    return;
  }

  //--- Open Trade Conditions
  if (!m_hedging)
  {
    if (orders_count > 0)
    {
      if (buyer_counter > 0 && buy_price - ask_price >= m_size)
        long_condition = true;
      if (seller_counter > 0 && bid_price - sell_price >= m_size)
        short_condition = true;
    }
    else
    {
      hour = TimeHour(time_current);
      if (InpManualInitGrid || (!InpUtilizeTimeFilter || (InpUtilizeTimeFilter && TimeFilter())))
      {

        if (Sinal == 1)
          long_condition = true;
        if (Sinal == -1)
          short_condition = true;
      }
    }
  }
  else
  {
    if (m_direction > 0 && bid_price <= m_seller)
      short_condition = true;
    if (m_direction < 0 && ask_price >= m_buyer)
      long_condition = true;
  }

  // CONTROL DRAWDOWN
  double vProfit = CalculateProfit(vInpMagic);

  if (vProfit < 0.0 && MathAbs(vProfit) > InpTotalEquityRiskCaution / 100.0 * AccountEquity())
  {
    m_time_equityrisk = iTime(NULL, InpTimeframeEquityCaution, 0);
  }
  else
  {
    m_time_equityrisk = -1;
  }

  //--- Hedging
  if (InpHedge > 0 && !m_hedging)
  {
    if (long_condition && buyer_counter == InpHedge)
    {
      // m_spread = Spread * m_pip;
      m_seller = bid_price;
      m_hedging = true;
      return;
    }
    if (short_condition && seller_counter == InpHedge)
    {
      // m_spread= Spread * m_pip;
      m_buyer = ask_price;
      m_hedging = true;
      return;
    }
  }

  //--- Lot Size
  if (LotsHedge != 0)
  {
    lots = LotsHedge;
  }
  else
  {
    lots = MathRound(lots * MathPow(InpGridFactor, orders_count), volume_step);
    if (m_hedging)
    {
      if (long_condition)
        lots = MathRound(seller_lots * InpGridFactor, volume_step) - buyer_lots;
      if (short_condition)
        lots = MathRound(buyer_lots * InpGridFactor, volume_step) - seller_lots;
    }
  }
  if (lots < volume_min)
    lots = volume_min;
  if (lots > volume_max)
    lots = volume_max;
  if (lots > InpMaxLot)
    lots = InpMaxLot;

  //--- Open Trades Based on Conditions
  if ((InpManualInitGrid && orders_count == 0) || (!InpOpenOneCandle || (InpOpenOneCandle && vDatetimeUltCandleOpen != iTime(NULL, InpTimeframeBarOpen, 0))))
  {
    vDatetimeUltCandleOpen = iTime(NULL, InpTimeframeBarOpen, 0);
    if (long_condition)
    {
      if (buyer_lots + lots == seller_lots)
        lots = seller_lots + volume_min;
      ticket = OpenTrade(OP_BUY, lots, ask_price, vInpMagic, Id);
      if (ticket > 0)
      {
        res = OrderSelect(ticket, SELECT_BY_TICKET);
        order_open_price = OrderOpenPrice();
        buyer_sum += order_open_price * lots;
        buyer_lots += lots;
        m_level = NormalizeDouble((buyer_sum - seller_sum) / (buyer_lots - seller_lots), Digits) + m_take;
        if (!m_hedging)
          level = m_level;
        else
          level = m_level + m_take;
        if (buyer_counter == 0)
          m_buyer = order_open_price;
        m_direction = 1;
        was_trade = true;
      }
    }

    if (short_condition)
    {
      if (seller_lots + lots == buyer_lots)
        lots = buyer_lots + volume_min;
      ticket = OpenTrade(OP_SELL, lots, bid_price, vInpMagic, Id);
      if (ticket > 0)
      {
        res = OrderSelect(ticket, SELECT_BY_TICKET);
        order_open_price = OrderOpenPrice();
        seller_sum += order_open_price * lots;
        seller_lots += lots;
        m_level = NormalizeDouble((seller_sum - buyer_sum) / (seller_lots - buyer_lots), Digits) - m_take;
        if (!m_hedging)
          level = m_level;
        else
          level = m_level - m_take;
        if (seller_counter == 0)
          m_seller = order_open_price;
        m_direction = -1;
        was_trade = true;
      }
    }
  }
  if (InpEnableMinProfit)
  {
    if (BuyProfit >= MinProfit && buyer_counter >= QtdTradesMinProfit)
      CloseAllTicket(OP_BUY, buy_ticket, vInpMagic);

    if (SellProfit >= MinProfit && seller_counter >= QtdTradesMinProfit)
      CloseAllTicket(OP_SELL, sell_ticket, vInpMagic);
  }

  //--- Setup Global Take Profit
  if (was_trade)
  {
    orders_total = OrdersTotal();
    for (index = orders_total - 1; index >= 0; index--)
    {
      if (!OrderSelect(index, SELECT_BY_POS, MODE_TRADES))
        continue;
      if (OrderMagicNumber() != vInpMagic || OrderSymbol() != m_symbol)
        continue;
      order_type = OrderType();
      if (m_direction > 0)
      {
        if (order_type == OP_BUY)
          res = OrderModify(OrderTicket(), OrderOpenPrice(), 0.0, level, 0);
        if (order_type == OP_SELL)
          res = OrderModify(OrderTicket(), OrderOpenPrice(), level, 0.0, 0);
      }
      if (m_direction < 0)
      {
        if (order_type == OP_BUY)
          res = OrderModify(OrderTicket(), OrderOpenPrice(), level, 0.0, 0);
        if (order_type == OP_SELL)
          res = OrderModify(OrderTicket(), OrderOpenPrice(), 0.0, level, 0);
      }
    }
  }
}
//+------------------------------------------------------------------+
int OpenTrade(int cmd, double volume, double price, int vInpMagic, string coment, double stop = 0.0, double take = 0.0)
{
  return OrderSend(m_symbol, cmd, volume, price, SlipPage, stop, take, coment, vInpMagic, 0);
}
double MathRound(double x, double m) { return m * MathRound(x / m); }
double MathFloor(double x, double m) { return m * MathFloor(x / m); }
double MathCeil(double x, double m) { return m * MathCeil(x / m); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountTrades()
{
  int l_count_0 = 0;
  for (int l_pos_4 = OrdersTotal() - 1; l_pos_4 >= 0; l_pos_4--)
  {
    if (!OrderSelect(l_pos_4, SELECT_BY_POS, MODE_TRADES))
    {
      continue;
    }
    if (OrderSymbol() != Symbol() || (OrderMagicNumber() != InpMagic && OrderMagicNumber() != InpMagic2))
      continue;
    if (OrderSymbol() == Symbol() && (OrderMagicNumber() == InpMagic || OrderMagicNumber() == InpMagic2))
      if (OrderType() == OP_SELL || OrderType() == OP_BUY)
        l_count_0++;
  }
  return (l_count_0);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountTrades(int vInpMagic)
{
  int l_count_0 = 0;
  for (int l_pos_4 = OrdersTotal() - 1; l_pos_4 >= 0; l_pos_4--)
  {
    if (!OrderSelect(l_pos_4, SELECT_BY_POS, MODE_TRADES))
    {
      continue;
    }
    if (OrderSymbol() != Symbol() || (OrderMagicNumber() != vInpMagic))
      continue;
    if (OrderSymbol() == Symbol() && (OrderMagicNumber() == vInpMagic))
      if (OrderType() == OP_SELL || OrderType() == OP_BUY)
        l_count_0++;
  }
  return (l_count_0);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountTradesSell(int vInpMagic)
{
  int l_count_0 = 0;
  for (int l_pos_4 = OrdersTotal() - 1; l_pos_4 >= 0; l_pos_4--)
  {
    if (!OrderSelect(l_pos_4, SELECT_BY_POS, MODE_TRADES))
    {
      continue;
    }
    if (OrderSymbol() != Symbol() || (OrderMagicNumber() != vInpMagic))
      continue;
    if (OrderSymbol() == Symbol() && (OrderMagicNumber() == vInpMagic))
      if (OrderType() == OP_SELL)
        l_count_0++;
  }
  return (l_count_0);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountTradesBuy(int vInpMagic)
{
  int l_count_0 = 0;
  for (int l_pos_4 = OrdersTotal() - 1; l_pos_4 >= 0; l_pos_4--)
  {
    if (!OrderSelect(l_pos_4, SELECT_BY_POS, MODE_TRADES))
    {
      continue;
    }
    if (OrderSymbol() != Symbol() || (OrderMagicNumber() != vInpMagic))
      continue;
    if (OrderSymbol() == Symbol() && (OrderMagicNumber() == vInpMagic))
      if (OrderType() == OP_BUY)
        l_count_0++;
  }
  return (l_count_0);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateProfit()
{
  double ld_ret_0 = 0;
  for (int g_pos_344 = OrdersTotal() - 1; g_pos_344 >= 0; g_pos_344--)
  {
    if (!OrderSelect(g_pos_344, SELECT_BY_POS, MODE_TRADES))
    {
      continue;
    }
    if (OrderSymbol() != Symbol() || (OrderMagicNumber() != InpMagic && OrderMagicNumber() != InpMagic2))
      continue;
    if (OrderSymbol() == Symbol() && (OrderMagicNumber() == InpMagic || OrderMagicNumber() == InpMagic2))
      if (OrderType() == OP_BUY || OrderType() == OP_SELL)
        ld_ret_0 += OrderProfit();
  }
  return (ld_ret_0);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateProfit(int vInpMagic)
{
  double ld_ret_0 = 0;
  for (int g_pos_344 = OrdersTotal() - 1; g_pos_344 >= 0; g_pos_344--)
  {
    if (!OrderSelect(g_pos_344, SELECT_BY_POS, MODE_TRADES))
    {
      continue;
    }
    if (OrderSymbol() != Symbol() || (OrderMagicNumber() != vInpMagic))
      continue;
    if (OrderSymbol() == Symbol() && (OrderMagicNumber() == vInpMagic))
      if (OrderType() == OP_BUY || OrderType() == OP_SELL)
        ld_ret_0 += OrderProfit();
  }
  return (ld_ret_0);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TimeFilter()
{

  bool _res = false;
  datetime _time_curent = TimeCurrent();
  datetime _time_start = StrToTime(DoubleToStr(Year(), 0) + "." + DoubleToStr(Month(), 0) + "." + DoubleToStr(Day(), 0) + " " + InpStartHour);
  datetime _time_stop = StrToTime(DoubleToStr(Year(), 0) + "." + DoubleToStr(Month(), 0) + "." + DoubleToStr(Day(), 0) + " " + InpEndHour);
  if (((InpTrade_in_Monday == true) && (TimeDayOfWeek(Time[0]) == 1)) ||
      ((InpTrade_in_Tuesday == true) && (TimeDayOfWeek(Time[0]) == 2)) ||
      ((InpTrade_in_Wednesday == true) && (TimeDayOfWeek(Time[0]) == 3)) ||
      ((InpTrade_in_Thursday == true) && (TimeDayOfWeek(Time[0]) == 4)) ||
      ((InpTrade_in_Friday == true) && (TimeDayOfWeek(Time[0]) == 5)))

    if (_time_start > _time_stop)
    {
      if (_time_curent >= _time_start || _time_curent <= _time_stop)
        _res = true;
    }
    else if (_time_curent >= _time_start && _time_curent <= _time_stop)
      _res = true;

  return (_res);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isCloseLastOrderNotProfit(int MagicNumber)
{
  datetime t = 0;
  double ocp, osl, otp;
  int i, j = -1, k = OrdersHistoryTotal();
  for (i = 0; i < k; i++)
  {
    if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
    {
      if (OrderType() == OP_BUY || OrderType() == OP_SELL)
      {
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
        {
          if (t < OrderCloseTime())
          {
            t = OrderCloseTime();
            j = i;
          }
        }
      }
    }
  }
  if (OrderSelect(j, SELECT_BY_POS, MODE_HISTORY))
  {
    ocp = NormalizeDouble(OrderClosePrice(), Digits);
    osl = NormalizeDouble(OrderStopLoss(), Digits);
    otp = NormalizeDouble(OrderTakeProfit(), Digits);
    if (OrderProfit() < 0)
      return (True);
  }
  return (False);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double FindLastSellLot(int MagicNumber)
{
  double l_lastLote = 0;
  int l_ticket_8;
  //double ld_unused_12 = 0;
  int l_ticket_20 = 0;
  for (int l_pos_24 = OrdersTotal() - 1; l_pos_24 >= 0; l_pos_24--)
  {
    if (!OrderSelect(l_pos_24, SELECT_BY_POS, MODE_TRADES))
    {
      continue;
    }
    if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
      continue;
    if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == OP_SELL)
    {
      l_ticket_8 = OrderTicket();
      if (l_ticket_8 > l_ticket_20)
      {
        l_lastLote += OrderLots();
        //ld_unused_12 = l_ord_open_price_0;
        l_ticket_20 = l_ticket_8;
      }
    }
  }
  return (l_lastLote);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double FindLastBuyLot(int MagicNumber)
{
  double l_lastorder = 0;
  int l_ticket_8;
  //double ld_unused_12 = 0;
  int l_ticket_20 = 0;
  for (int l_pos_24 = OrdersTotal() - 1; l_pos_24 >= 0; l_pos_24--)
  {
    if (!OrderSelect(l_pos_24, SELECT_BY_POS, MODE_TRADES))
    {
      continue;
    }
    if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
      continue;
    if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == OP_BUY)
    {
      l_ticket_8 = OrderTicket();
      if (l_ticket_8 > l_ticket_20)
      {
        l_lastorder += OrderLots();
        //ld_unused_12 = l_ord_open_price_0;
        l_ticket_20 = l_ticket_8;
      }
    }
  }
  return (l_lastorder);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ShowError(int error, string complement)
{

  if (error == 1 || error == 130)
  {
    return;
  }

  //string ErrorText=ErrorDescription(error);
  // StringToUpper(ErrorText);
  Print(complement, ": Ordem: ", OrderTicket(), ". Falha ao tentar alterar ordem: ", error, " ");
  ResetLastError();
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailingAlls(int ai_0, int ai_4, double a_price_8, int MagicNumber)
{
  int li_16;

  double m_pip = 1.0 / MathPow(10, Digits - 1);
  if (Digits == 3 || Digits == 5)
      m_pip = 10.0 * Point;
    else
      m_pip = Point;

 

  double l_ord_stoploss_20;
  double l_price_28;
  bool foo = false;
  if (ai_4 != 0)
  {
    for (int l_pos_36 = OrdersTotal() - 1; l_pos_36 >= 0; l_pos_36--)
    {
      if (OrderSelect(l_pos_36, SELECT_BY_POS, MODE_TRADES))
      {
        if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
          continue;
        if (OrderSymbol() == Symbol() || OrderMagicNumber() == MagicNumber)
        {
          if (OrderType() == OP_BUY)
          {
            li_16 = (int)NormalizeDouble((Bid - a_price_8) / Point, 0);
            if (li_16 < (ai_0 * m_pip))
              continue;
            l_ord_stoploss_20 = OrderStopLoss();
            l_price_28 = Bid - (ai_4 * m_pip);
            if (l_ord_stoploss_20 == 0.0 || (l_ord_stoploss_20 != 0.0 && l_price_28 > l_ord_stoploss_20))
            {
              // Somente ajustar a ordem se ela estiver aberta
              if (CanModify(OrderTicket()))
              {
                ResetLastError();
                foo = OrderModify(OrderTicket(), a_price_8, l_price_28, OrderTakeProfit(), 0, Aqua);
                if (!foo)
                {
                  ShowError(GetLastError(), "Normal");
                }
              }
            }
          }
          if (OrderType() == OP_SELL)
          {
            li_16 = (int)NormalizeDouble((a_price_8 - Ask) / Point, 0);
            if (li_16 < (ai_0 * m_pip))
              continue;
            l_ord_stoploss_20 = OrderStopLoss();
            l_price_28 = Ask + (ai_4 * m_pip);
            if (l_ord_stoploss_20 == 0.0 || (l_ord_stoploss_20 != 0.0 && l_price_28 < l_ord_stoploss_20))
            {
              // Somente ajustar a ordem se ela estiver aberta
              if (CanModify(OrderTicket()))
              {
                ResetLastError();
                foo = OrderModify(OrderTicket(), a_price_8, l_price_28, OrderTakeProfit(), 0, Red);
                if (!foo)
                {
                  ShowError(GetLastError(), "Normal");
                }
              }
            }
          }
        }
        Sleep(1000);
      }
    }
  }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseThisSymbolAll(int vInpMagic)
{
  bool foo = false;
  for (int l_pos_0 = OrdersTotal() - 1; l_pos_0 >= 0; l_pos_0--)
  {
    if (!OrderSelect(l_pos_0, SELECT_BY_POS, MODE_TRADES))
    {
      continue;
    }
    if (OrderSymbol() == Symbol())
    {
      if (OrderSymbol() == Symbol() && (OrderMagicNumber() == vInpMagic))
      {
        if (OrderType() == OP_BUY)
          foo = OrderClose(OrderTicket(), OrderLots(), Bid, SlipPage, Blue);

        if (OrderType() == OP_SELL)
          foo = OrderClose(OrderTicket(), OrderLots(), Ask, SlipPage, Red);
      }
      Sleep(1000);
    }
  }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseThisSymbolAll()
{
  bool foo = false;
  for (int l_pos_0 = OrdersTotal() - 1; l_pos_0 >= 0; l_pos_0--)
  {
    if (!OrderSelect(l_pos_0, SELECT_BY_POS, MODE_TRADES))
    {
      continue;
    }
    if (OrderSymbol() == Symbol())
    {
      if (OrderSymbol() == Symbol() && (OrderMagicNumber() == InpMagic || OrderMagicNumber() == InpMagic2))
      {
        if (OrderType() == OP_BUY)
          foo = OrderClose(OrderTicket(), OrderLots(), Bid, SlipPage, Blue);

        if (OrderType() == OP_SELL)
          foo = OrderClose(OrderTicket(), OrderLots(), Ask, SlipPage, Red);
      }
      Sleep(1000);
    }
  }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CanModify(int ticket)
{

  return OrdersTotal() > 0;
  /*
    if( OrderType() == OP_BUY || OrderType() == OP_SELL)
       return OrderCloseTime() == 0;
       
    return false;
 
    /*
    bool result = false;
    
    OrderSelect(ticket, SELECT_BY_TICKET
    for(int i=OrdersHistoryTotal()-1;i>=0;i--){
       if( !OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) ){ continue; }
       if(OrderTicket()==ticket){
          result=true;
          break;
       }
    }
    
    return result;
    */
}
// Function to check if it is news time
void NewsHandling()
{
  static int PrevMinute = -1;

  if (Minute() != PrevMinute)
  {
    PrevMinute = Minute();

    // Use this call to get ONLY impact of previous event
    int impactOfPrevEvent =
        (int)iCustom(NULL, 0, "FFCal", true, true, false, true, true, 2, 0);

    // Use this call to get ONLY impact of nexy event
    int impactOfNextEvent =
        (int)iCustom(NULL, 0, "FFCal", true, true, false, true, true, 2, 1);

    int minutesSincePrevEvent =
        (int)iCustom(NULL, 0, "FFCal", true, true, false, true, false, 1, 0);

    int minutesUntilNextEvent =
        (int)iCustom(NULL, 0, "FFCal", true, true, false, true, false, 1, 1);

    m_news_time = false;
    if ((minutesUntilNextEvent <= InpMinsBeforeNews) ||
        (minutesSincePrevEvent <= InpMinsAfterNews))
    {
      m_news_time = true;
    }
  }
} //newshandling

void CloseAllTicket(int aType, int ticket, int MagicN)
{
  for (int i = OrdersTotal() - 1; i >= 0; i--)
    if (OrderSelect(i, SELECT_BY_POS))
      if (OrderSymbol() == Symbol())
        if (OrderMagicNumber() == MagicN)
        {
          if (OrderType() == aType && OrderType() == OP_BUY)
            if (OrderProfit() > 0 || OrderTicket() == ticket)
              if (!OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(Bid, Digits()), SlipPage, clrRed))
                Print(" OrderClose OP_BUY Error N", GetLastError());

          if (OrderType() == aType && OrderType() == OP_SELL)
            if (OrderProfit() > 0 || OrderTicket() == ticket)
              if (!OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(Ask, Digits()), SlipPage, clrRed))
                Print(" OrderClose OP_SELL Error N", GetLastError());
        }
}

void DrawRects(int xPos, int yPos, color clr, int width = 150, int height = 17, string Texto = "")
{

  string id = "_l" + Texto;

  ObjectDelete(0, id);

  ObjectCreate(0, id, OBJ_BUTTON, 0, 100, 100);
  ObjectSetInteger(0, id, OBJPROP_XDISTANCE, xPos);
  ObjectSetInteger(0, id, OBJPROP_YDISTANCE, yPos);
  ObjectSetInteger(0, id, OBJPROP_BGCOLOR, clr);
  ObjectSetInteger(0, id, OBJPROP_COLOR, clrWhite);
  ObjectSetInteger(0, id, OBJPROP_XSIZE, 150);
  ObjectSetInteger(0, id, OBJPROP_YSIZE, 35);

  ObjectSetInteger(0, id, OBJPROP_WIDTH, 0);
  ObjectSetString(0, id, OBJPROP_FONT, "Arial");
  ObjectSetString(0, id, OBJPROP_TEXT, Texto);
  ObjectSetInteger(0, id, OBJPROP_SELECTABLE, 0);
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{

  //sparam: Name of the graphical object, on which the event occurred

  // did user click on the chart ?
  if (id == CHARTEVENT_OBJECT_CLICK)
  {
    // and did he click on on of our objects
    if (StringSubstr(sparam, 0, 2) == "_l")
    {

      // did user click on the name of a pair ?
      int len = StringLen(sparam);
      // Alert(sparam);
      //
      if (StringSubstr(sparam, len - 3, 3) == "BUY" || StringSubstr(sparam, len - 3, 3) == "ELL")
      {
        if (InpManualInitGrid)
        {

          
          //Aciona 1ª Ordem do Grid
          if (StringSubstr(sparam, len - 3, 3) == "BUY" && !(m_orders_count1 > 0 || !InpEnableEngineA))
          {
            //BUY
            xBest("A", 1, 0, InpMagic, m_orders_count1, m_mediaprice1, m_hedging1, m_target_filter1,
                  m_direction1, m_current_day1, m_previous_day1, m_level1, m_buyer1, m_seller1,
                  m_target1, m_profit1, m_pip1, m_size1, m_take1, m_datetime_ultcandleopen1,
                  m_time_equityrisk1);
            //  Alert("BUY");
          }
          if (StringSubstr(sparam, len - 3, 3) == "ELL" && !(m_orders_count2 > 0 || !InpEnableEngineA))
          {
            //SELL
            xBest("B", -1, 0, InpMagic2, m_orders_count2, m_mediaprice2, m_hedging2,
                  m_target_filter2, m_direction2, m_current_day2, m_previous_day2,
                  m_level2, m_buyer2, m_seller2, m_target2, m_profit2, m_pip2,
                  m_size2, m_take2, m_datetime_ultcandleopen2,
                  m_time_equityrisk2);
            //  Alert("SELL");
          }
        }
      }
    }
  }
}