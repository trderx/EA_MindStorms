
extern string MACH2__ = "-----------------------------------------------------------------";
extern string MACH2 = "                                  MODULE MACH2 GRID               ";
extern string MACH2____ = "---------------------------------------------------------------";
string MACH2_EAName = "MACH2";
input bool InpEnableMACH2 = true;         //Enable MACH2
extern int MACH2_MagicNumber = 6601111;   //Magic MACH2
extern int MACH2_InpLotdecimal = 2;       //Lotdecimal
extern double MACH2_InpTakeProfit = 18.0; //Take Profit
extern double MACH2_InpStoploss = 500.0;  //Stoploss
extern double MACH2_InpSlip = 3.0;        //Slip
input double MACH2_InpMaxLot = 99;        // Max Lot

extern string MACH2_Configgrid__ = "---------------------------GRID--------------------------------------";
extern double MACH2_InpLotExponent = 1.3;  // Grid Increment Factor
extern bool MACH2_InpDynamicPips = true;      // Dynamic Grid
extern int MACH2_InpStepSizeGridDefault = 12; // Step Size in Pips [Default if MACH2_InpDynamicPips true]
extern int MACH2_InpGlubina = 24;             //Qtd Periodos p/ maxima e minima
extern int MACH2_InpDEL = 3;                  //Divizor de (maxima - minima) p/ calculo do tamanho do grid
extern int MACH2_InpMaxTrades = 21;           // Max Lot Open Simultaneo

extern string MACH2_FilterOpenOneCandle__ = "--------------------Filter One Order by Candle--------------";
input bool MACH2_InpOpenOneCandle = false;                        // Open one order by candle
input ENUM_TIMEFRAMES MACH2_InpTimeframeBarOpen = PERIOD_CURRENT; // Timeframe OpenOneCandle

extern string MACH2_EquityCaution__ = "------------------------Filter Caution of Equity ---------------";
extern bool MACH2_InpUseEquityCaution = true;                       //  EquityCaution?
extern double MACH2_InpValueEquityRiskCaution = 10;                 // Total $ Risk to EquityCaution
extern ENUM_TIMEFRAMES MACH2_InpTimeframeEquityCaution = PERIOD_H4; // Timeframe as EquityCaution
extern string MACH2_CloseProfit__ = "------------------------ Close in profit Level X ---------------";
input double MACH2_MinProfit = 10.00;   // Minimal Profit Close
input int MACH2_QtdTradesMinProfit = 2; // Qtd Trades Open to Minimal Profit Close

//VAR MACH21
double MACH2_PriceTarget, MACH2_StartEquity, MACH2_BuyTarget, MACH2_SellTarget, MACH2_CurrentPairProfit;
double MACH2_AveragePrice, MACH2_SellLimit, MACH2_BuyLimit, MACH2_sumLots;
double MACH2_LastBuyPrice, MACH2_LastSellPrice, MACH2_Stopper = 0.0, MACH2_iLots, MACH2_ordprof;
int MACH2_NumOfTrades = 0, MACH2_totalOrdensOpen, MACH2_ticket, MACH2_timeprev = 0, MACH2_expiration, MACH2_orders_count;
bool MACH2_TradeNow = FALSE, MACH2_LongTrade = FALSE, MACH2_ShortTrade = FALSE, MACH2_flag, MACH2_NewOrdersPlaced = FALSE;
datetime MACH2_vDatetimeUltCandleOpen, MACH2_m_time_equityrisk;
bool MACH2_equityrisk;

//VARIAVEIS GLOBAIS MACH2
int MACH2_vg_cnt = 0;
int MACH2_vg_GridSize = 0;
string MACH2_ID = "MACH2", MACH2_vg_filters_on = "";

//+------------------------------------------------------------------+
//|           EA MACH2 x                                              |
//+------------------------------------------------------------------+
void MACH2x(int vSinal, bool LotInformado, double Lots)
{

    if (!InpEnableMACH2)
        return;

    if (MACH2_m_time_equityrisk == iTime(NULL, MACH2_InpTimeframeEquityCaution, 0))
    {
        MACH2_vg_filters_on += "Filter EquityCaution MACH2  ON \n";

        return;
    }
    else
    {
        MACH2_vg_filters_on = "";
        MACH2_m_time_equityrisk = -1;
    }

    color avgLine = Blue;
    if (MACH2_ShortTrade)
        avgLine = Red;

    if (MACH2_LongTrade || MACH2_ShortTrade)
        SetHLine(avgLine, "Avg" + MACH2_ID, MACH2_AveragePrice, 0, 3);
    else
        ObjectDelete("Avg" + MACH2_ID);

    //NORMALIZA LOT
    if (Lots < MarketInfo(Symbol(), 23))
        Lots = MarketInfo(Symbol(), 23);
    if (Lots > MarketInfo(Symbol(), 25))
        Lots = MarketInfo(Symbol(), 25);

    // SE DynamicPips  ENABLE
    if (MACH2_InpDynamicPips)
    {

        // calculate highest and lowest price from last bar to 24 bars ago
        double hival = High[iHighest(NULL, 0, MODE_HIGH, MACH2_InpGlubina, 1)];

        // chart used for symbol and time period
        double loval = Low[iLowest(NULL, 0, MODE_LOW, MACH2_InpGlubina, 1)];
        // calculate pips for spread between orders
        MACH2_vg_GridSize = NormalizeDouble((hival - loval) / MACH2_InpDEL / Point, 0);

        if (MACH2_vg_GridSize < MACH2_InpStepSizeGridDefault / MACH2_InpDEL)
            MACH2_vg_GridSize = NormalizeDouble(MACH2_InpStepSizeGridDefault / MACH2_InpDEL, 0);

        // if dynamic pips fail, assign pips extreme value
        if (MACH2_vg_GridSize > MACH2_InpStepSizeGridDefault * MACH2_InpDEL)
            MACH2_vg_GridSize = NormalizeDouble(MACH2_InpStepSizeGridDefault * MACH2_InpDEL, 0);
    }
    else
        MACH2_vg_GridSize = MACH2_InpStepSizeGridDefault;

    MACH2_CurrentPairProfit = CalculateProfit(MACH2_MagicNumber);

    // CONTROL DRAWDOWN
    if (MACH2_CurrentPairProfit < 0.0 && (MACH2_CurrentPairProfit < MACH2_InpValueEquityRiskCaution * -1))
    {
        MACH2_m_time_equityrisk = iTime(NULL, MACH2_InpTimeframeEquityCaution, 0);
        MACH2_equityrisk = true;
    }
    else
    {
        MACH2_m_time_equityrisk = -1;
        MACH2_equityrisk = false;
    }

    //VERIFICA SE POSSUI TRADER ATIVO
    MACH2_totalOrdensOpen = CountTrades(MACH2_MagicNumber);
    if (MACH2_totalOrdensOpen == 0)
        MACH2_flag = FALSE;
    for (MACH2_vg_cnt = OrdersTotal() - 1; MACH2_vg_cnt >= 0; MACH2_vg_cnt--)
    {
        OrderSelect(MACH2_vg_cnt, SELECT_BY_POS, MODE_TRADES);
        if (OrderSymbol() != Symbol() || OrderMagicNumber() != MACH2_MagicNumber)
            continue;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MACH2_MagicNumber)
        {
            if (OrderType() == OP_BUY)
            {
                MACH2_LongTrade = TRUE;
                MACH2_ShortTrade = FALSE;
                break;
            }
        }
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MACH2_MagicNumber)
        {
            if (OrderType() == OP_SELL)
            {
                MACH2_LongTrade = FALSE;
                MACH2_ShortTrade = TRUE;
                break;
            }
        }
    }

    //VERIFY GRID SPACE TO TRADE
    if (MACH2_totalOrdensOpen > 0 && MACH2_totalOrdensOpen <= MACH2_InpMaxTrades)
    {
        RefreshRates();
        double l_lastlot1, l_lastlot2 = 0;
        MACH2_LastBuyPrice = FindLastBuyPrice(MACH2_MagicNumber, l_lastlot1);
        MACH2_LastSellPrice = FindLastSellPrice(MACH2_MagicNumber, l_lastlot2);
        MACH2_sumLots = l_lastlot1 + l_lastlot2;

        if (MACH2_LongTrade && MACH2_LastBuyPrice - Ask >= MACH2_vg_GridSize * Point)
            MACH2_TradeNow = TRUE;
        if (MACH2_ShortTrade && Bid - MACH2_LastSellPrice >= MACH2_vg_GridSize * Point)
            MACH2_TradeNow = TRUE;
    }

    if (MACH2_totalOrdensOpen < 1)
    {
        MACH2_ShortTrade = FALSE;
        MACH2_LongTrade = FALSE;
        MACH2_TradeNow = TRUE;
        MACH2_StartEquity = AccountEquity();
    }

    // SE OpenOneCandle   ENABLE
    if (!MACH2_InpOpenOneCandle || (MACH2_InpOpenOneCandle && MACH2_vDatetimeUltCandleOpen != iTime(NULL, MACH2_InpTimeframeBarOpen, 0)))
    {

        // ORDEM DE GRID
        if (MACH2_TradeNow && (MACH2_ShortTrade || MACH2_LongTrade))
        {
            MACH2_LastBuyPrice = FindLastBuyPrice(MACH2_MagicNumber, MACH2_sumLots);
            MACH2_LastSellPrice = FindLastSellPrice(MACH2_MagicNumber, MACH2_sumLots);

            MACH2_NumOfTrades = MACH2_totalOrdensOpen;

            //if(LotInformado)
            //   MACH2_iLots = Lots;
            //else
            MACH2_iLots = NormalizeDouble(Lots * MathPow(MACH2_InpLotExponent, MACH2_NumOfTrades), MACH2_InpLotdecimal);

            if (MACH2_iLots < MarketInfo(Symbol(), 23))
                MACH2_iLots = MarketInfo(Symbol(), 23);
            if (MACH2_iLots > MarketInfo(Symbol(), 25))
                MACH2_iLots = MarketInfo(Symbol(), 25);
            if (MACH2_iLots > MACH2_InpMaxLot && !LotInformado)
                MACH2_iLots = MACH2_InpMaxLot;

            RefreshRates();

            //SELL
            if (MACH2_ShortTrade && vSinal == -1)
            {

                MACH2_ticket = OpenOrder(1, MACH2_iLots, Bid, MACH2_InpSlip, Ask, 0, 0, MACH2_ID + "-" + MACH2_NumOfTrades + "-" + MACH2_vg_GridSize, MACH2_MagicNumber, 0, HotPink);
                if (MACH2_ticket < 0)
                {
                    Print("Error: ", GetLastError());
                    return;
                }
                MACH2_LastSellPrice = FindLastSellPrice(MACH2_MagicNumber, MACH2_sumLots);
                MACH2_TradeNow = FALSE;
                MACH2_vDatetimeUltCandleOpen = iTime(NULL, MACH2_InpTimeframeBarOpen, 0);
                MACH2_NewOrdersPlaced = TRUE;
            }

            //BUY
            if (MACH2_LongTrade && vSinal == 1)
            {

                MACH2_ticket = OpenOrder(0, MACH2_iLots, Ask, MACH2_InpSlip, Bid, 0, 0, MACH2_ID + "-" + MACH2_NumOfTrades + "-" + MACH2_vg_GridSize, MACH2_MagicNumber, 0, Lime);
                if (MACH2_ticket < 0)
                {
                    Print("Error: ", GetLastError());
                    return;
                }
                MACH2_LastBuyPrice = FindLastBuyPrice(MACH2_MagicNumber, MACH2_sumLots);
                MACH2_TradeNow = FALSE;
                MACH2_vDatetimeUltCandleOpen = iTime(NULL, MACH2_InpTimeframeBarOpen, 0);
                MACH2_NewOrdersPlaced = TRUE;
            }
        }
    }

    //  OpenOneCandle
    if (!MACH2_InpOpenOneCandle || (MACH2_InpOpenOneCandle && MACH2_vDatetimeUltCandleOpen != iTime(NULL, MACH2_InpTimeframeBarOpen, 0)))
    {

        // 1ª ORDEM DO GRID
        if (MACH2_TradeNow && MACH2_totalOrdensOpen < 1)
        {

            MACH2_SellLimit = Bid;
            MACH2_BuyLimit = Ask;
            if (!MACH2_ShortTrade && !MACH2_LongTrade)
            {

                MACH2_NumOfTrades = MACH2_totalOrdensOpen;

                if (LotInformado)
                    MACH2_iLots = Lots;
                else
                    MACH2_iLots = NormalizeDouble(Lots * MathPow(MACH2_InpLotExponent, MACH2_NumOfTrades), MACH2_InpLotdecimal);

                if (MACH2_iLots < MarketInfo(Symbol(), 23))
                    MACH2_iLots = MarketInfo(Symbol(), 23);
                if (MACH2_iLots > MarketInfo(Symbol(), 25))
                    MACH2_iLots = MarketInfo(Symbol(), 25);

                if (MACH2_iLots > MACH2_InpMaxLot && !LotInformado)
                    MACH2_iLots = MACH2_InpMaxLot;

                //SELL
                if (vSinal == -1)
                {
                    MACH2_ticket = OpenOrder(1, MACH2_iLots, MACH2_SellLimit, MACH2_InpSlip, MACH2_SellLimit, 0, 0, MACH2_ID + "-" + MACH2_NumOfTrades, MACH2_MagicNumber, 0, HotPink);
                    if (MACH2_ticket < 0)
                    {
                        Print("Error: ", GetLastError());
                        return;
                    }

                    MACH2_LastSellPrice = FindLastSellPrice(MACH2_MagicNumber, MACH2_sumLots);
                    MACH2_TradeNow = FALSE;
                    MACH2_vDatetimeUltCandleOpen = iTime(NULL, MACH2_InpTimeframeBarOpen, 0);
                    MACH2_NewOrdersPlaced = TRUE;
                }

                //BUY
                if (vSinal == 1)
                {

                    MACH2_ticket = OpenOrder(0, MACH2_iLots, MACH2_BuyLimit, MACH2_InpSlip, MACH2_BuyLimit, 0, 0, MACH2_ID + "-" + MACH2_NumOfTrades, MACH2_MagicNumber, 0, Lime);
                    if (MACH2_ticket < 0)
                    {
                        Print("Error: ", GetLastError());
                        return;
                    }
                    MACH2_LastBuyPrice = FindLastBuyPrice(MACH2_MagicNumber, MACH2_sumLots);
                    MACH2_TradeNow = FALSE;
                    MACH2_vDatetimeUltCandleOpen = iTime(NULL, MACH2_InpTimeframeBarOpen, 0);
                    MACH2_NewOrdersPlaced = TRUE;
                }

                // if (MACH2_ticket > 0) MACH2_expiration = TimeCurrent() + 60.0 * (60.0 * InpMaxTradeOpenHours);
            }
        }
    }

    //CALC MACH2_AveragePrice / Count Total Lots
    MACH2_totalOrdensOpen = CountTrades(MACH2_MagicNumber);
    MACH2_AveragePrice = 0;
    double BuyProfit = 0;
    double SellProfit = 0;
    double order_open_price, order_lots;
    int index, orders_total, order_ticket, order_type, ticket, hour;
    int buy_ticket = 0, sell_ticket = 0;
    int buyer_counter = 0, seller_counter = 0, orders_count = 0;
    double buyer_lots = 0.0, seller_lots = 0.0;
    double Count = 0;
    for (MACH2_vg_cnt = OrdersTotal() - 1; MACH2_vg_cnt >= 0; MACH2_vg_cnt--)
    {
        OrderSelect(MACH2_vg_cnt, SELECT_BY_POS, MODE_TRADES);
        if (OrderSymbol() != Symbol() || OrderMagicNumber() != MACH2_MagicNumber)
            continue;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MACH2_MagicNumber)
        {
            if (OrderType() == OP_BUY || OrderType() == OP_SELL)
            {
                order_ticket = OrderTicket();
                order_type = OrderType();
                order_open_price = OrderOpenPrice();
                MACH2_AveragePrice += OrderOpenPrice() * OrderLots();
                Count += OrderLots();
                if (order_type == OP_BUY)
                {
                    //--- Set Last Buy Order
                    if (order_ticket > buy_ticket)
                    {

                        buy_ticket = order_ticket;
                    }
                    buyer_counter++;
                    if (OrderProfit() > 0)
                        BuyProfit += OrderProfit() + OrderCommission() + OrderSwap();
                }
                //---
                if (order_type == OP_SELL)
                {
                    //--- Set Last Sell Order
                    if (order_ticket > sell_ticket)
                    {

                        sell_ticket = order_ticket;
                    }
                    seller_counter++;
                    if (OrderProfit() > 0)
                        SellProfit += OrderProfit() + OrderCommission() + OrderSwap();
                }
            }
        }
    }

    if (BuyProfit >= MACH2_MinProfit && buyer_counter >= MACH2_QtdTradesMinProfit)
        CloseAllTicket(OP_BUY, buy_ticket, MACH2_MagicNumber,3);

    if (SellProfit >= MACH2_MinProfit && seller_counter >= MACH2_QtdTradesMinProfit)
        CloseAllTicket(OP_SELL, sell_ticket, MACH2_MagicNumber,3);

    if (MACH2_totalOrdensOpen > 0)
        MACH2_AveragePrice = NormalizeDouble(MACH2_AveragePrice / Count, Digits);
    MACH2_sumLots = Count;

    //CALC MACH2_PriceTarget/MACH2_BuyTarget/MACH2_Stopper
    if (MACH2_NewOrdersPlaced)
    {
        for (MACH2_vg_cnt = OrdersTotal() - 1; MACH2_vg_cnt >= 0; MACH2_vg_cnt--)
        {
            OrderSelect(MACH2_vg_cnt, SELECT_BY_POS, MODE_TRADES);
            if (OrderSymbol() != Symbol() || OrderMagicNumber() != MACH2_MagicNumber)
                continue;
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == MACH2_MagicNumber)
            {
                if (OrderType() == OP_BUY)
                {
                    MACH2_PriceTarget = MACH2_AveragePrice + MACH2_InpTakeProfit * Point;
                    MACH2_BuyTarget = MACH2_PriceTarget;
                    MACH2_Stopper = MACH2_AveragePrice - MACH2_InpStoploss * Point;
                    MACH2_flag = TRUE;
                }
            }
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == MACH2_MagicNumber)
            {
                if (OrderType() == OP_SELL)
                {
                    MACH2_PriceTarget = MACH2_AveragePrice - MACH2_InpTakeProfit * Point;
                    MACH2_SellTarget = MACH2_PriceTarget;
                    MACH2_Stopper = MACH2_AveragePrice + MACH2_InpStoploss * Point;
                    MACH2_flag = TRUE;
                }
            }
        }
    }

    //ADD TAKE PROFIT
    if (MACH2_NewOrdersPlaced)
    {
        if (MACH2_flag == TRUE)
        {
            for (MACH2_vg_cnt = OrdersTotal() - 1; MACH2_vg_cnt >= 0; MACH2_vg_cnt--)
            {
                OrderSelect(MACH2_vg_cnt, SELECT_BY_POS, MODE_TRADES);
                if (OrderSymbol() != Symbol() || OrderMagicNumber() != MACH2_MagicNumber)
                    continue;
                if (OrderSymbol() == Symbol() && OrderMagicNumber() == MACH2_MagicNumber)
                    OrderModify(OrderTicket(), NormalizeDouble(MACH2_AveragePrice, Digits), NormalizeDouble(OrderStopLoss(), Digits), NormalizeDouble(MACH2_PriceTarget, Digits), 0, Yellow);
                MACH2_NewOrdersPlaced = FALSE;
            }
        }
    }

    //CLOSE ALL IF MaxTrades
    if (MACH2_totalOrdensOpen > MACH2_InpMaxTrades)
    {
        for (int pos = 0; pos < OrdersTotal(); pos++)
        {
            OrderSelect(pos, SELECT_BY_POS);
            if (OrderSymbol() != Symbol() || OrderMagicNumber() != MACH2_MagicNumber)
                continue;
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == MACH2_MagicNumber)
                if (OrderType() == OP_SELL)
                {
                    OrderClose(OrderTicket(), OrderLots(), Ask, 5, White);
                    MACH2_ordprof = OrderSwap() + OrderProfit() + OrderCommission();
                    if (GetLastError() == 0)
                    {
                        SendNotification("SellOrder: " + Symbol() + ", " + OrderType() + ", " + DoubleToStr(Ask, Digits) + ", " + DoubleToStr(OrderLots(), 2) + ", " + DoubleToStr(MACH2_ordprof, 2));
                    }
                    pos = OrdersTotal();
                }
            if (OrderType() == OP_BUY)
            {
                OrderClose(OrderTicket(), OrderLots(), Bid, 5, White);
                MACH2_ordprof = OrderSwap() + OrderProfit() + OrderCommission();
                if (GetLastError() == 0)
                {
                    SendNotification("BuyOrder: " + Symbol() + ", " + OrderType() + ", " + DoubleToStr(Ask, Digits) + ", " + DoubleToStr(OrderLots(), 2) + ", " + DoubleToStr(MACH2_ordprof, 2));
                }
                pos = OrdersTotal();
            }
        }
    }
}