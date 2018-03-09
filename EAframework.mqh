
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
   Step_lot  = 3  // Step Lot        0.01 / 0.01 / 0.01 / 0.02 / 0.02 / 0.02 / 0.03 / 0.03 / 0.03 / 0.04 / 0.04 / 0.04 /............
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

  double CalcLot(int TypeLot, int TypeOrder, int vQtdTrades, double LastLot, double StartLot, double GridFactor)
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
      // if(TypeOrder==OP_BUY && Ask < BuyMinPrice  ) rezult=BuyMinLot+StartLot;
      // if(TypeOrder==OP_BUY && Ask > BuyMaxPrice  ) rezult=StartLot;

      //if(TypeOrder==OP_SELL&& Bid > SellMaxPrice ) rezult=SellMaxLot+StartLot;
      //if(TypeOrder==OP_SELL&& Bid < SellMinPrice ) rezult=StartLot;
      break;

    case 2: // Martingale lot
      rezult = StartLot * MathPow(GridFactor, vQtdTrades);
      // if(TypeOrder==OP_BUY && Ask < BuyMinPrice  ) rezult=BuyMinLot*GridFactor;
      // if(TypeOrder==OP_BUY && Ask > BuyMaxPrice  ) rezult=StartLot;

      //if(TypeOrder==OP_SELL&& Bid > SellMaxPrice ) rezult=SellMaxLot*GridFactor;
      //if(TypeOrder==OP_SELL&& Bid < SellMinPrice ) rezult=StartLot;
      break;

    case 3: // Step lot
      if (vQtdTrades == 0)
        rezult = StartLot;
      if (vQtdTrades % 3 == 0)
        rezult = LastLot + StartLot;
      else
        rezult = LastLot;

      // if(TypeOrder==OP_BUY && Ask < BuyMinPrice && vQtdTrades%3==0 ) rezult=BuyMinLot+StartLot;
      // if(TypeOrder==OP_BUY && Ask > BuyMaxPrice  ) rezult=StartLot;

      // if(TypeOrder==OP_SELL&& Bid > SellMaxPrice && vQtdTrades%3==0) rezult=SellMaxLot+StartLot;
      // if(TypeOrder==OP_SELL&& Bid < SellMinPrice ) rezult=StartLot;
      break;
    }
    return rezult;
  }