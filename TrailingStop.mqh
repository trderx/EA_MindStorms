extern string TrailingStop__=                              "-------------------------Trailling Stop-------------------------";
extern bool   InpUseTrailingStop = TRUE;                                       // Use Trailling Stop´?  
extern double InpTrailStart = 17.0;                                             // TraillingStart
extern double InpTrailStep = 29.0;                                              // Size Trailling step

    // SE TrailingStop  ENABLE
   // if (InpUseTrailingStop) TrailingAlls(InpTrailStart, InpTrailStep, AveragePrice, MagicNumber);

//+------------------------------------------------------------------+
//|           TrailingAlls                                   |
//+------------------------------------------------------------------+
void TrailingAlls( double AvgPrice, int MagicNumber) {
    int profit;
    double stoptrade;
    double stopcal;
    if (InpTrailStep != 0) {
        for (int trade = OrdersTotal() - 1; trade >= 0; trade--) {
            if (OrderSelect(trade, SELECT_BY_POS, MODE_TRADES)) {
                if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber) continue;
                if (OrderSymbol() == Symbol() || OrderMagicNumber() == MagicNumber) {
                    if (OrderType() == OP_BUY) {
                        profit = NormalizeDouble((Bid - AvgPrice) / Point, 0);
                        if (profit < InpTrailStart) continue;
                        stoptrade = OrderStopLoss();
                        stopcal = Bid - InpTrailStep * Point;
                        if (stoptrade == 0.0 || (stoptrade != 0.0 && stopcal > stoptrade)) OrderModify(OrderTicket(), AvgPrice, stopcal, OrderTakeProfit(), 0, Aqua);
                    }
                    if (OrderType() == OP_SELL) {
                        profit = NormalizeDouble((AvgPrice - Ask) / Point, 0);
                        if (profit < InpTrailStart) continue;
                        stoptrade = OrderStopLoss();
                        stopcal = Ask + InpTrailStep * Point;
                        if (stoptrade == 0.0 || (stoptrade != 0.0 && stopcal < stoptrade)) OrderModify(OrderTicket(), AvgPrice, stopcal, OrderTakeProfit(), 0, Red);
                    }
                }
                Sleep(1000);
            }
        }
    }
}