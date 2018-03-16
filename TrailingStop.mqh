extern string TrailingStop__ = "-------------------------Trailling Stop-------------------------";
extern bool InpUseTrailingStop = TRUE; // Use Trailling Stop´?
extern double InpTrailStart = 17.0;    // TraillingStart
extern double InpTrailStep = 29.0;     // Size Trailling step

// SE TrailingStop  ENABLE
// if (InpUseTrailingStop) TrailingAlls(InpTrailStart, InpTrailStep, AveragePrice, MagicNumber);

//+------------------------------------------------------------------+
//|           TrailingAlls                                   |
//+------------------------------------------------------------------+
void TrailingAlls(double AvgPrice, int MagicNumber)
{
    int profit;
    double stoptrade;
    double stopcal;
    if (InpTrailStep != 0)
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
                        if (profit < InpTrailStart)
                            continue;
                        stoptrade = OrderStopLoss();
                        stopcal = Bid - InpTrailStep * Point;
                        stopcal = ValidStopLoss(OP_BUY, Bid, stopcal);
                        if (stoptrade == 0.0 || (stoptrade != 0.0 && stopcal > stoptrade))
                            OrderModify(OrderTicket(), AvgPrice, stopcal, OrderTakeProfit(), 0, Aqua);
                    }
                    if (OrderType() == OP_SELL)
                    {
                        profit = NormalizeDouble((AvgPrice - Ask) / Point, 0);
                        if (profit < InpTrailStart)
                            continue;
                        stoptrade = OrderStopLoss();
                        stopcal = Ask + InpTrailStep * Point;
                        stopcal = ValidStopLoss(OP_SELL, Ask, stopcal);
                        if (stoptrade == 0.0 || (stoptrade != 0.0 && stopcal < stoptrade))
                            OrderModify(OrderTicket(), AvgPrice, stopcal, OrderTakeProfit(), 0, Red);
                    }
                }
                Sleep(1000);
            }
        }
    }
}

double GetPoint(string mySymbol)
{
   double mPoint, myDigits;
   
   myDigits = MarketInfo (mySymbol, MODE_DIGITS);
   if (myDigits < 4)
      mPoint = 0.01;
   else
      mPoint = 0.0001;
   
   return(mPoint);
}

double ValidStopLoss(int type, double price, double SL)
{

    double mySL;
    double minstop;

    minstop = MarketInfo(Symbol(), MODE_STOPLEVEL);
    if (Digits == 3 || Digits == 5)
        minstop = minstop / 10;

    mySL = SL;
    if (type == OP_BUY)
    {
        if ((price - mySL) < minstop * Point)
            mySL = price - minstop * Point;
    }
    if (type == OP_SELL)
    {
        if ((mySL - price) < minstop * Point)
            mySL = price + minstop * Point;
    }

    return (NormalizeDouble(mySL, MarketInfo(Symbol(), MODE_DIGITS)));
}