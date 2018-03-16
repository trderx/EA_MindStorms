
double MathRound(double x, double m) { return m * MathRound(x / m); }
double MathFloor(double x, double m) { return m * MathFloor(x / m); }
double MathCeil(double x, double m) { return m * MathCeil(x / m); }

//+------------------------------------------------------------------+
//|           CalculateProfit                                   |
//+------------------------------------------------------------------+
double CalculateProfit(int MagicNumber) {
    double Profit = 0;
    for (int vg_cnt = OrdersTotal() - 1; vg_cnt >= 0; vg_cnt--) {
        OrderSelect(vg_cnt, SELECT_BY_POS, MODE_TRADES);
        if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber) continue;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            if (OrderType() == OP_BUY || OrderType() == OP_SELL) Profit += OrderProfit();
    }
    return (Profit);
}




   //------------------------------------------------------------------------------------
   // GetTimeFrame()
   //------------------------------------------------------------------------------------
   string GetTimeFrame(int timePeriod)
   {  
      string timeframe="";
      switch (timePeriod)
      {
         case 1: timeframe="M1";break;
         case 5: timeframe="M5";break;
         case 15: timeframe="M15";break;
         case 30: timeframe="M30";break;
         case 60: timeframe="H1";break;
         case 240: timeframe="H4";break;
         case 1440: timeframe="D1";break;
         case 10080: timeframe="W1";break;
      }
      return timeframe;
   }

//+------------------------------------------------------------------+
int OrdersScaner(int vMAGIC, int &orders_buy, int &orders_sell, int &profit, int &MinPriceBuy, int &MaxPriceSell, int &pending)
{

    orders_buy = 0;
    orders_sell = 0;
    profit = 0;
    MinPriceBuy = 0;
    MaxPriceSell = 0;
    pending = 0;
    for (int i = OrdersTotal(); i >= 1; i--)
    {
        if (OrderSelect(i - 1, SELECT_BY_POS, MODE_TRADES) == FALSE)
            break;
        if (OrderSymbol() != Symbol())
            continue;
        if (OrderMagicNumber() != vMAGIC)
            continue;
        if (OrderType() > 1)
            pending++;
        if (OrderType() == OP_BUY)
        {
            orders_buy++;
            if (orders_buy == 1)
                MinPriceBuy = OrderOpenPrice();
            if (orders_buy > 1 && OrderOpenPrice() < MinPriceBuy)
                MinPriceBuy = OrderOpenPrice();
            profit += OrderProfit() + OrderSwap();
        }
        if (OrderType() == OP_SELL)
        {
            orders_sell++;
            if (orders_sell == 1)
                MaxPriceSell = OrderOpenPrice();
            if (orders_sell > 1 && OrderOpenPrice() > MaxPriceSell)
                MaxPriceSell = OrderOpenPrice();
            profit += OrderProfit() + OrderSwap();
        }
    }
    int status = orders_buy + orders_sell;
    return (status);
}

//-----------------------------------------------------------------------------------
void SetHLine(color vColorSetHLine, string vNomeSetHLine = "", double vBidSetHLine = 0.0, int vStyleSetHLine = 0, int vTamanhoSetHLine = 1)
{
    if (vNomeSetHLine == "")
        vNomeSetHLine = DoubleToStr(Time[0], 0);
    if (vBidSetHLine <= 0.0)
        vBidSetHLine = Bid;
    if (ObjectFind(vNomeSetHLine) < 0)
        ObjectCreate(vNomeSetHLine, OBJ_HLINE, 0, 0, 0);
    ObjectSet(vNomeSetHLine, OBJPROP_PRICE1, vBidSetHLine);
    ObjectSet(vNomeSetHLine, OBJPROP_COLOR, vColorSetHLine);
    ObjectSet(vNomeSetHLine, OBJPROP_STYLE, vStyleSetHLine);
    ObjectSet(vNomeSetHLine, OBJPROP_WIDTH, vTamanhoSetHLine);
}

//+------------------------------------------------------------------+
//|           StopLong                                   |
//+------------------------------------------------------------------+
double StopLong(double price, int stop)
{
    if (stop == 0)
        return (0);
    else
        return (price - stop * Point);
}

//+------------------------------------------------------------------+
//|           StopShort                                   |
//+------------------------------------------------------------------+
double StopShort(double price, int stop)
{
    if (stop == 0)
        return (0);
    else
        return (price + stop * Point);
}

//+------------------------------------------------------------------+
//|           TakeLong                                   |
//+------------------------------------------------------------------+
double TakeLong(double price, int stop)
{
    if (stop == 0)
        return (0);
    else
        return (price + stop * Point);
}

//+------------------------------------------------------------------+
//|           TakeShort                                   |
//+------------------------------------------------------------------+
double TakeShort(double price, int stop)
{
    if (stop == 0)
        return (0);
    else
        return (price - stop * Point);
}

//+------------------------------------------------------------------+
//|           CalculateProfit                                   |
//+------------------------------------------------------------------+
double CalculateProfit(int MagicNumber, int &vg_cnt)
{
    double Profit = 0;
    for (vg_cnt = OrdersTotal() - 1; vg_cnt >= 0; vg_cnt--)
    {
        OrderSelect(vg_cnt, SELECT_BY_POS, MODE_TRADES);
        if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
            continue;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            if (OrderType() == OP_BUY || OrderType() == OP_SELL)
                Profit += OrderProfit() + OrderCommission() + OrderSwap();
    }
    return (Profit);
}
//+------------------------------------------------------------------+
//|           TrailingAlls                                   |
//+------------------------------------------------------------------+
void TrailingAlls(int pType, int stop, double AvgPrice, int MagicNumber)
{
    int profit;
    double stoptrade;
    double stopcal;
    if (stop != 0)
    {
        for (int trade = OrdersTotal() - 1; trade >= 0; trade--)
        {
            if (OrderSelect(trade, SELECT_BY_POS, MODE_TRADES))
            {
                if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
                    continue;
                if (OrderSymbol() == Symbol() || OrderMagicNumber() == MagicNumber)
                {
                    if (OrderType() == OP_BUY)
                    {
                        profit = NormalizeDouble((Bid - AvgPrice) / Point, 0);
                        if (profit < pType)
                            continue;
                        stoptrade = OrderStopLoss();
                        stopcal = Bid - stop * Point;
                        if (stoptrade == 0.0 || (stoptrade != 0.0 && stopcal > stoptrade))
                            OrderModify(OrderTicket(), AvgPrice, stopcal, OrderTakeProfit(), 0, Aqua);
                    }
                    if (OrderType() == OP_SELL)
                    {
                        profit = NormalizeDouble((AvgPrice - Ask) / Point, 0);
                        if (profit < pType)
                            continue;
                        stoptrade = OrderStopLoss();
                        stopcal = Ask + stop * Point;
                        if (stoptrade == 0.0 || (stoptrade != 0.0 && stopcal < stoptrade))
                            OrderModify(OrderTicket(), AvgPrice, stopcal, OrderTakeProfit(), 0, Red);
                    }
                }
                Sleep(1000);
            }
        }
    }
}

//+------------------------------------------------------------------+
//|           CountTrades                                   |
//+------------------------------------------------------------------+
int CountTrades(int MagicNumber)
{
    int count = 0;
    for (int trade = OrdersTotal() - 1; trade >= 0; trade--)
    {
        OrderSelect(trade, SELECT_BY_POS, MODE_TRADES);
        if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
            continue;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            if (OrderType() == OP_SELL || OrderType() == OP_BUY)
                count++;
    }
    return (count);
}
//+------------------------------------------------------------------+
//|           CloseAllTicket                                   |
//+------------------------------------------------------------------+
  void CloseAllTicket(int aType,int ticket, int MagicN, int pSlipPage)
  {
   for(int i=OrdersTotal()-1; i>=0; i--)
      if(OrderSelect(i,SELECT_BY_POS))
         if(OrderSymbol()==Symbol())
            if(OrderMagicNumber()==MagicN)
              {
               if(OrderType()==aType && OrderType()==OP_BUY)
                  if(OrderProfit()>0 || OrderTicket()==ticket)
                     if(!OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(Bid,Digits()),pSlipPage,clrRed))
                        Print(" OrderClose OP_BUY Error N",GetLastError());

               if(OrderType()==aType && OrderType()==OP_SELL)
                  if(OrderProfit()>0 || OrderTicket()==ticket)
                     if(!OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(Ask,Digits()),pSlipPage,clrRed))
                        Print(" OrderClose OP_SELL Error N",GetLastError());

              }
  }
//+------------------------------------------------------------------+
//|           CloseThisSymbolAll                                   |
//+------------------------------------------------------------------+
void CloseThisSymbolAll(int MagicNumber, int InpSlip)
{
    for (int trade = OrdersTotal() - 1; trade >= 0; trade--)
    {
        OrderSelect(trade, SELECT_BY_POS, MODE_TRADES);
        if (OrderSymbol() == Symbol())
        {
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
                if (OrderType() == OP_BUY)
                    OrderClose(OrderTicket(), OrderLots(), Bid, InpSlip, Blue);
                if (OrderType() == OP_SELL)
                    OrderClose(OrderTicket(), OrderLots(), Ask, InpSlip, Red);
            }
            Sleep(1000);
        }
    }
}

//+------------------------------------------------------------------+
//|           AccountEquityHigh                       |
//+------------------------------------------------------------------+
double AccountEquityHigh(int MagicNumber, double vg_AccountEquityHighAmt, double vg_PrevEquity)
{
    if (CountTrades(MagicNumber) == 0)
        vg_AccountEquityHighAmt = AccountEquity();
    if (vg_AccountEquityHighAmt < vg_PrevEquity)
        vg_AccountEquityHighAmt = vg_PrevEquity;
    else
        vg_AccountEquityHighAmt = AccountEquity();
    vg_PrevEquity = AccountEquity();
    return (vg_AccountEquityHighAmt);
}

//+------------------------------------------------------------------+
//|           FindLastBuyPrice                                     |
//+------------------------------------------------------------------+
double FindLastBuyPrice(int MagicNumber, double &v_sumLots)
{

    v_sumLots = 0;
    double oldorderopenprice;
    int oldticketnumber;
    double unused = 0;
    int ticketnumber = 0;
    for (int vg_cnt = OrdersTotal() - 1; vg_cnt >= 0; vg_cnt--)
    {
        OrderSelect(vg_cnt, SELECT_BY_POS, MODE_TRADES);
        if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
            continue;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == OP_BUY)
        {
            oldticketnumber = OrderTicket();
            if (oldticketnumber > ticketnumber)
            {
                oldorderopenprice = OrderOpenPrice();
                //unused = oldorderopenprice;
                v_sumLots += OrderLots();
                ticketnumber = oldticketnumber;
            }
        }
    }
    return (oldorderopenprice);
}

//+------------------------------------------------------------------+
//|           FindLastBuyPrice                                     |
//+------------------------------------------------------------------+
double FindLastBuyPriceLL(int MagicNumber, double &v_sumLots, double &v_lastLots)
{

    v_sumLots = 0;
    double oldorderopenprice;
    int oldticketnumber;
    double unused = 0;
    int ticketnumber = 0;
    for (int vg_cnt = OrdersTotal() - 1; vg_cnt >= 0; vg_cnt--)
    {
        OrderSelect(vg_cnt, SELECT_BY_POS, MODE_TRADES);
        if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
            continue;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == OP_BUY)
        {
            oldticketnumber = OrderTicket();
            if (oldticketnumber > ticketnumber)
            {
                oldorderopenprice = OrderOpenPrice();
                //unused = oldorderopenprice;
                v_sumLots += OrderLots();
                v_lastLots =  OrderLots();
                ticketnumber = oldticketnumber;
            }
        }
    }
    return (oldorderopenprice);
}

//+------------------------------------------------------------------+
//|           FindLastSellPrice                                     |
//+------------------------------------------------------------------+
double FindLastSellPriceLL(int MagicNumber, double &v_sumLots, double &v_lastLots)
{

    v_sumLots = 0;
    double oldorderopenprice;
    int oldticketnumber;
    double unused = 0;
    int ticketnumber = 0;
    for (int vg_cnt = OrdersTotal() - 1; vg_cnt >= 0; vg_cnt--)
    {
        OrderSelect(vg_cnt, SELECT_BY_POS, MODE_TRADES);
        if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
            continue;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == OP_SELL)
        {
            oldticketnumber = OrderTicket();
            if (oldticketnumber > ticketnumber)
            {
                oldorderopenprice = OrderOpenPrice();
                //unused = oldorderopenprice;
                v_sumLots += OrderLots();
                v_lastLots =  OrderLots();
                ticketnumber = oldticketnumber;
            }
        }
    }
    return (oldorderopenprice);
}
//+------------------------------------------------------------------+
//|           OpenOrder                                   |
//+------------------------------------------------------------------+
int OpenOrder(int pType, double pLots, double pLevel, int sp, double pr, int sl, int tp, string pComment, int pMagic, int pDatetime, color pColor)
{
    int ticket = 0;
    int err = 0;
    int c = 0;
    int NumberOfTries = 100;
    switch (pType)
    {
    case 2:
        for (c = 0; c < NumberOfTries; c++)
        {
            ticket = OrderSend(Symbol(), OP_BUYLIMIT, pLots, pLevel, sp, StopLong(pr, sl), TakeLong(pLevel, tp), pComment, pMagic, pDatetime, pColor);
            err = GetLastError();
            if (err == 0 /* NO_ERROR */)
            {
                SendNotification("BUYLIMIT " + Symbol() + ", BuyLimit, " + DoubleToStr(pLevel, Digits) + ", " + DoubleToStr(pLots, 2));
                break;
            }
            if (!(err == 4 /* SERVER_BUSY */ || err == 137 /* BROKER_BUSY */ || err == 146 /* TRADE_CONTEXT_BUSY */ || err == 136 /* OFF_QUOTES */))
                break;
            Sleep(1000);
        }
        break;
    case 4:
        for (c = 0; c < NumberOfTries; c++)
        {
            ticket = OrderSend(Symbol(), OP_BUYSTOP, pLots, pLevel, sp, StopLong(pr, sl), TakeLong(pLevel, tp), pComment, pMagic, pDatetime, pColor);
            err = GetLastError();
            if (err == 0 /* NO_ERROR */)
            {
                SendNotification("BUYSTOP " + Symbol() + ", BuyStop, " + DoubleToStr(pLevel, Digits) + ", " + DoubleToStr(pLots, 2));
                break;
            }
            if (!(err == 4 /* SERVER_BUSY */ || err == 137 /* BROKER_BUSY */ || err == 146 /* TRADE_CONTEXT_BUSY */ || err == 136 /* OFF_QUOTES */))
                break;
            Sleep(5000);
        }
        break;
    case 0:
        for (c = 0; c < NumberOfTries; c++)
        {
            RefreshRates();
            ticket = OrderSend(Symbol(), OP_BUY, pLots, NormalizeDouble(Ask, Digits), sp, NormalizeDouble(StopLong(Bid, sl), Digits), NormalizeDouble(TakeLong(Ask, tp), Digits), pComment, pMagic, pDatetime, pColor);
            err = GetLastError();
            if (err == 0 /* NO_ERROR */)
            {
                SendNotification("BuyOrder: " + Symbol() + ", Buy, " + DoubleToStr(Ask, Digits) + ", " + DoubleToStr(pLots, 2));
                break;
            }
            if (!(err == 4 /* SERVER_BUSY */ || err == 137 /* BROKER_BUSY */ || err == 146 /* TRADE_CONTEXT_BUSY */ || err == 136 /* OFF_QUOTES */))
                break;
            Sleep(5000);
        }
        break;
    case 3:
        for (c = 0; c < NumberOfTries; c++)
        {
            ticket = OrderSend(Symbol(), OP_SELLLIMIT, pLots, pLevel, sp, StopShort(pr, sl), TakeShort(pLevel, tp), pComment, pMagic, pDatetime, pColor);
            err = GetLastError();
            if (err == 0 /* NO_ERROR */)
            {
                SendNotification("SELLLIMIT " + Symbol() + ", SellLimit, " + DoubleToStr(pLevel, Digits) + ", " + DoubleToStr(pLots, 2));
                break;
            }
            if (!(err == 4 /* SERVER_BUSY */ || err == 137 /* BROKER_BUSY */ || err == 146 /* TRADE_CONTEXT_BUSY */ || err == 136 /* OFF_QUOTES */))
                break;
            Sleep(5000);
        }
        break;
    case 5:
        for (c = 0; c < NumberOfTries; c++)
        {
            ticket = OrderSend(Symbol(), OP_SELLSTOP, pLots, pLevel, sp, StopShort(pr, sl), TakeShort(pLevel, tp), pComment, pMagic, pDatetime, pColor);
            err = GetLastError();
            if (err == 0 /* NO_ERROR */)
            {
                SendNotification("SELLSTOP " + Symbol() + ", SellStop, " + DoubleToStr(pLevel, Digits) + ", " + DoubleToStr(pLots, 2));
                break;
            }
            if (!(err == 4 /* SERVER_BUSY */ || err == 137 /* BROKER_BUSY */ || err == 146 /* TRADE_CONTEXT_BUSY */ || err == 136 /* OFF_QUOTES */))
                break;
            Sleep(5000);
        }
        break;
    case 1:
        for (c = 0; c < NumberOfTries; c++)
        {
            ticket = OrderSend(Symbol(), OP_SELL, pLots, NormalizeDouble(Bid, Digits), sp, NormalizeDouble(StopShort(Ask, sl), Digits), NormalizeDouble(TakeShort(Bid, tp), Digits), pComment, pMagic, pDatetime, pColor);
            err = GetLastError();
            if (err == 0 /* NO_ERROR */)
            {
                SendNotification("SELL " + Symbol() + ", Sell, " + DoubleToStr(Bid, Digits) + ", " + DoubleToStr(pLots, 2));
                break;
            }
            if (!(err == 4 /* SERVER_BUSY */ || err == 137 /* BROKER_BUSY */ || err == 146 /* TRADE_CONTEXT_BUSY */ || err == 136 /* OFF_QUOTES */))
                break;
            Sleep(5000);
        }
    }
    return (ticket);
}
//+------------------------------------------------------------------+
//|           FindLastSellPrice                                     |
//+------------------------------------------------------------------+
double FindLastSellPrice(int MagicNumber, double &v_sumLots)
{
    v_sumLots = 0;
    double oldorderopenprice;
    int oldticketnumber;
    double unused = 0;
    int ticketnumber = 0;
    for (int vg_cnt = OrdersTotal() - 1; vg_cnt >= 0; vg_cnt--)
    {
        OrderSelect(vg_cnt, SELECT_BY_POS, MODE_TRADES);
        if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
            continue;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == OP_SELL)
        {
            oldticketnumber = OrderTicket();
            if (oldticketnumber > ticketnumber)
            {
                oldorderopenprice = OrderOpenPrice();
                //unused = oldorderopenprice;
                v_sumLots += OrderLots();
                ticketnumber = oldticketnumber;
            }
        }
    }
    return (oldorderopenprice);
}
void PainelUPER(string textpainel)
{
    string Ygs_104 = "A";
    string name_0 = Ygs_104 + "L_1";
    if (ObjectFind(name_0) == -1)
    {
        ObjectCreate(name_0, OBJ_LABEL, 0, 0, 0);
        ObjectSet(name_0, OBJPROP_CORNER, 0);
        ObjectSet(name_0, OBJPROP_XDISTANCE, 500);
        ObjectSet(name_0, OBJPROP_YDISTANCE, 10);
    }
    ObjectSetText(name_0, textpainel, 12, "Arial", White);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_TYPE_GRID_LOT
  {
   fix_lot   = 0, // Fixed Start Lot 0.01 / 0.01 / 0.01 / 0.01 / 0.01 /.............
   Summ_lot  = 1, // Summ Sart Lot   0.01 / 0.02 / 0.03 / 0.04 / 0.05 /.............
   Martingale= 2, // Martingale Lot  0.01 / 0.02 / 0.04 / 0.08 / 0.16 /.............
   Step_lot  = 3 , // Step Lot        0.01 / 0.01 / 0.01 / 0.02 / 0.02 / 0.02 / 0.03 / 0.03 / 0.03 / 0.04 / 0.04 / 0.04 /............
   Step_Invert_lot  = 4  // Step Invert Lot        0.10 / 0.10 / 0.10 / 0.09 / 0.09 / 0.09 / 0.08 / 0.08 / 0.08 / 0.08 / 0.08 / 0.07 /............
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_Trade
  {
   Only_BUY,   // Only BUY
   Only_SELL,  // Only SELL
   All_Trade    // BUY and SELL
  };

 
  double CalcLot(int TypeLot, int TypeOrder, int vQtdTrades, double LastLot, double StartLot, double GridFactor, int GridStepLot, double StepLot)
  {
    double rezult = 0;
    switch (TypeLot)
    {
    case 0: // Standart lot
      if (TypeOrder == OP_BUY || TypeOrder == OP_SELL)
        rezult = StartLot;
      break;

    case 1: // Summ lot
      rezult = StartLot * vQtdTrades;
  
      break;

    case 2: // Martingale lot
      rezult = StartLot * MathPow(GridFactor, vQtdTrades);

      break;

    case 3: // Step lot
      if (vQtdTrades == 0)
        return StartLot;
      if (vQtdTrades % GridStepLot == 0)
        rezult = LastLot + StepLot;
      else
        rezult = LastLot;

 
      break;
       case 4: // Step Invert lot
      if (vQtdTrades == 0)
        return StartLot;
      if (vQtdTrades % GridStepLot == 0)
        rezult = LastLot - StepLot;
      else
        rezult = LastLot;

 
      break;
    }
    return rezult;
  }

// add leading zeros that the resulting string has 'digits' length.
string sub_maketimestring ( int par_number, int par_digits )
{
	string result;

	result = DoubleToStr ( par_number, 0 );
	while ( StringLen ( result ) < par_digits ) 
		result = "0" + result;
	
	return ( result );
}


// Make a screenshoot / printscreen
void sub_makescreenshot ( string par_sx = "" )
{
	static int no = 0;

	no ++;
	string fn = "SnapShot" + Symbol() + Period() + "\\"+Year() + "-" + sub_maketimestring ( Month(), 2 ) + "-" + sub_maketimestring ( Day(), 2 )
	+ " " + sub_maketimestring ( Hour(), 2 ) + "_" + sub_maketimestring ( Minute(), 2 ) + "_" + sub_maketimestring ( Seconds( ), 2 ) + " " + no + par_sx + ".gif";
	if ( !ScreenShot ( fn, 640, 480 ) ) 
		Print ( "ScreenShot error: ",  GetLastError() );
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

//--------------------------------------------------------------------
bool ButtonCreate(const long              chart_ID=0,               // ID ãðàôèêà
                  const string            name="Button",            // èìÿ êíîïêè
                  const int               sub_window=0,             // íîìåð ïîäîêíà
                  const long               x=0,                      // êîîðäèíàòà ïî îñè X
                  const long               y=0,                      // êîîðäèíàòà ïî îñè Y
                  const int               width=50,                 // øèðèíà êíîïêè
                  const int               height=18,                // âûñîòà êíîïêè
                  const string            text="Button",            // òåêñò
                  const string            font="Arial",             // øðèôò
                  const int               font_size=8,             // ðàçìåð øðèôòà
                  const color             clr=clrBlack,               // öâåò òåêñòà
                  const color             clrON=clrLightGray,            // öâåò ôîíà
                  const color             clrOFF=clrLightGray,          // öâåò ôîíà
                  const color             border_clr=clrNONE,       // öâåò ãðàíèöû
                  const bool              state=false,       //
                  const ENUM_BASE_CORNER  CORNER=CORNER_RIGHT_UPPER)
  {
   if (ObjectFind(chart_ID,name)==-1)
   {
      ObjectCreate(chart_ID,name,OBJ_BUTTON,sub_window,0,0);
      ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
      ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
      ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,CORNER);
      ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
      ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,0);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,0);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,0);
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,1);
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,1);
      ObjectSetInteger(chart_ID,name,OBJPROP_STATE,state);
   }
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,border_clr);
   color back_clr;
   if (ObjectGetInteger(chart_ID,name,OBJPROP_STATE)) back_clr=clrON; else back_clr=clrOFF;
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
   return(true);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawLABEL(int c,string name,string Name,int X,int Y,color clr)
  {
   if(ObjectFind(name)==-1)
     {
      ObjectCreate(name,OBJ_LABEL,0,0,0);
      ObjectSet(name,OBJPROP_CORNER,c);
      ObjectSet(name,OBJPROP_XDISTANCE,X);
      ObjectSet(name,OBJPROP_YDISTANCE,Y);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
     }
   ObjectSetText(name,Name,10,"Arial",clr);
  }
  
//--------------------------------------------------------------------
bool RectLabelCreate(const long             chart_ID=0,               // ID ãðàôèêà
                     const string           name="RectLabel",         // èìÿ ìåòêè
                     const int              sub_window=0,             // íîìåð ïîäîêíà
                     const long              x=0,                     // êîîðäèíàòà ïî îñè X
                     const long              y=0,                     // êîîðäèíàòà ïî îñè y
                     const int              width=50,                 // øèðèíà
                     const int              height=18,                // âûñîòà
                     const color            back_clr=clrWhite,        // öâåò ôîíà
                     const color            clr=clrBlack,             // öâåò ïëîñêîé ãðàíèöû (Flat)
                     const ENUM_LINE_STYLE  style=STYLE_SOLID,        // ñòèëü ïëîñêîé ãðàíèöû
                     const int              line_width=1,             // òîëùèíà ïëîñêîé ãðàíèöû
                     const bool             back=false,               // íà çàäíåì ïëàíå
                     const bool             selection=false,          // âûäåëèòü äëÿ ïåðåìåùåíèé
                     const bool             hidden=true,              // ñêðûò â ñïèñêå îáúåêòîâ
                     const long             z_order=0)                // ïðèîðèòåò íà íàæàòèå ìûøüþ
  {
   ResetLastError();
   if (ObjectFind(chart_ID,name)==-1)
   {
      ObjectCreate(chart_ID,name,OBJ_RECTANGLE_LABEL,sub_window,0,0);
      ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
      ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
      ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,line_width);
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
      //ObjectSetInteger(chart_ID,name,OBJPROP_ALIGN,ALIGN_RIGHT); 
   }
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
   return(true);
}
//--------------------------------------------------------------------
bool LabelCreate(const long              chart_ID=0,               // ID �������
                 const string            name="Label",             // ��� �����
                 const int               sub_window=0,             // ����� �������
                 const long              x=0,                      // ���������� �� ��� X
                 const long              y=0,                      // ���������� �� ��� y
                 const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // ���� ������� ��� ��������
                 const string            text="Label",             // �����
                 const string            font="Arial",             // �����
                 const int               font_size=10,             // ������ ������
                 const color             clr=clrNONE,      
                 const double            angle=0.0,                // ������ ������
                 const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // ������ ��������
                 const bool              back=false,               // �� ������ �����
                 const bool              selection=false,          // �������� ��� �����������
                 const bool              hidden=true,              // ����� � ������ ��������
                 const long              z_order=0)                // ��������� �� ������� �����
{
   ResetLastError();
   if (ObjectFind(chart_ID,name)==-1)
   {
      if(!ObjectCreate(chart_ID,name,OBJ_LABEL,sub_window,0,0))
      {
         Print(__FUNCTION__,": �� ������� ������� ��������� �����! ��� ������ = ",GetLastError());
         return(false);
      }
      ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
      ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
      ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
      ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
      ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
   }
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
   return(true);
  }