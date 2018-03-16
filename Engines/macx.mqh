
extern string MACH__ = "-----------------------------------------------------------------";
extern string MACH = "                                  MODULE MACH GRID               ";
extern string MACH____ = "---------------------------------------------------------------";
string MACH_EAName = "MACH";
input bool InpEnableMACH = true;         //Enable MACH
extern int MACH_MagicNumber = 1101111;   //Magic MACH
extern double MACH_InpTakeProfit = 18.0; //Take Profit
extern double MACH_InpStoploss = 500.0;  //Stoploss
extern double MACH_InpSlip = 3.0;        //Slip
input double MACH_InpMaxLot = 99;        // Max Lot

extern string MACH_Configgrid__ = "---------------------------GRID--------------------------------------";
input ENUM_TYPE_GRID_LOT MACH_TypeGridLot = Step_lot; // Type Grid Lot
extern double MACH_InpLotExponent = 1.3;                // Grid Increment Factor (If Martingale)
extern bool MACH_InpDynamicSizeGrid = true;             // Dynamic Size Grid
extern int MACH_InpStepSizeGridDefault = 12;            // Step Size in Pips [Default if MACH_InpDynamicSizeGrid true]
extern int MACH_InpGlubina = 24;                        //( Dynamic Grid) Qtd Periodos p/ maxima e minima
extern int MACH_InpDEL = 3;                             //( Dynamic Grid) Divizor de (maxima - minima) p/ calculo do tamanho do grid
extern int MACH_InpMaxTrades = 99;                      // Max Lot Open Simultaneo
input int MACH_InpGridStepLot = 3;                      // Level to Change STEP LOT (If  Step Lot)
extern double MACH_InpStepLot = 0.01;                   // STEP LOT (If  Step Lot)

extern string MACH_FilterOpenOneCandle__ = "--------------------Filter One Order by Candle--------------";
input bool MACH_InpOpenOneCandle = false;                        // Open one order by candle
input ENUM_TIMEFRAMES MACH_InpTimeframeBarOpen = PERIOD_CURRENT; // Timeframe OpenOneCandle

extern string MACH_EquityCaution__ = "------------------------Filter Caution of Equity ---------------";
extern bool MACH_InpUseEquityCaution = true;                       //  EquityCaution?
extern double MACH_InpValueEquityRiskCaution = 1;                 // Total $ Risk to EquityCaution
extern ENUM_TIMEFRAMES MACH_InpTimeframeEquityCaution = PERIOD_H1; // Timeframe as EquityCaution
extern string MACH_CloseProfit__ = "------------------------ Close in profit Level X ---------------";
input double MACH_MinProfit = 10.00;   // Minimal Profit Close
input int MACH_QtdTradesMinProfit = 2; // Qtd Trades Open to Minimal Profit Close

//VAR MACH1
double MACH_PriceTarget, MACH_StartEquity, MACH_BuyTarget, MACH_SellTarget, MACH_CurrentPairProfit;
double MACH_AveragePrice, MACH_SellLimit, MACH_BuyLimit, MACH_sumLots;
double MACH_LastBuyPrice, MACH_LastSellPrice, MACH_Stopper = 0.0, MACH_iLots, MACH_ordprof;
int MACH_NumOfTrades = 0, MACH_totalOrdensOpen, MACH_ticket, MACH_timeprev = 0, MACH_expiration, MACH_orders_count;
bool MACH_TradeNow = FALSE, MACH_LongTrade = FALSE, MACH_ShortTrade = FALSE, MACH_flag, MACH_NewOrdersPlaced = FALSE;
datetime MACH_vDatetimeUltCandleOpen, MACH_m_time_equityrisk;
bool MACH_equityrisk;

//VARIAVEIS GLOBAIS MACH
int MACH_vg_cnt = 0;
int MACH_vg_GridSize = 0;
string MACH_ID = "MACH", MACH_vg_filters_on = "";
double MACH_l_sumlot1, MACH_l_sumlot2 = 0, MACH_l_lastlot = 0, MACH_l_lastlot1, MACH_l_lastlot2 = 0;
double MACH_InpLotdecimal; //Lotdecimal

//+------------------------------------------------------------------+
//|           EA MACH x                                              |
//+------------------------------------------------------------------+
void MACHx(int vSinal, bool LotInformado, double Lots)
{

    if (!InpEnableMACH)
        return;

    if (MACH_InpUseEquityCaution && (MACH_m_time_equityrisk == iTime(NULL, MACH_InpTimeframeEquityCaution, 0)))
    {
        MACH_vg_filters_on += "Filter EquityCaution MACH  ON \n";
        MACH_equityrisk= true;
        return;
    }
    else
    {
        MACH_equityrisk = false;
        MACH_vg_filters_on = "";
        MACH_m_time_equityrisk = -1;
    }

    color avgLine = Blue;
    if (MACH_ShortTrade)
        avgLine = Red;

    if (MACH_LongTrade || MACH_ShortTrade)
        SetHLine(avgLine, "Avg" + MACH_ID, MACH_AveragePrice, 0, 3);
    else
        ObjectDelete("Avg" + MACH_ID);

    //NORMALIZA LOT
    if (Lots < MarketInfo(Symbol(), 23))
        Lots = MarketInfo(Symbol(), 23);
    if (Lots > MarketInfo(Symbol(), 25))
        Lots = MarketInfo(Symbol(), 25);

    // SE DynamicPips  ENABLE
    if (MACH_InpDynamicSizeGrid)
    {

        // calculate highest and lowest price from last bar to 24 bars ago
        double hival = High[iHighest(NULL, 0, MODE_HIGH, MACH_InpGlubina, 1)];

        // chart used for symbol and time period
        double loval = Low[iLowest(NULL, 0, MODE_LOW, MACH_InpGlubina, 1)];
        // calculate pips for spread between orders
        MACH_vg_GridSize = NormalizeDouble((hival - loval) / MACH_InpDEL / Point, 0);

        if (MACH_vg_GridSize < MACH_InpStepSizeGridDefault / MACH_InpDEL)
            MACH_vg_GridSize = NormalizeDouble(MACH_InpStepSizeGridDefault / MACH_InpDEL, 0);

        // if dynamic pips fail, assign pips extreme value
        if (MACH_vg_GridSize > MACH_InpStepSizeGridDefault * MACH_InpDEL)
            MACH_vg_GridSize = NormalizeDouble(MACH_InpStepSizeGridDefault * MACH_InpDEL, 0);
    }
    else
        MACH_vg_GridSize = MACH_InpStepSizeGridDefault;

    MACH_CurrentPairProfit = CalculateProfit(MACH_MagicNumber);

    // CONTROL DRAWDOWN
    if (MACH_InpUseEquityCaution && (MACH_CurrentPairProfit < 0.0 && (MACH_CurrentPairProfit < MACH_InpValueEquityRiskCaution * -1)))
    {
        MACH_m_time_equityrisk = iTime(NULL, MACH_InpTimeframeEquityCaution, 0);
        MACH_equityrisk = true;
    }
    else
    {
        MACH_m_time_equityrisk = -1;
        MACH_equityrisk = false;
    }

    //VERIFICA SE POSSUI TRADER ATIVO
    MACH_totalOrdensOpen = CountTrades(MACH_MagicNumber);
    if (MACH_totalOrdensOpen == 0)
        MACH_flag = FALSE;
    for (MACH_vg_cnt = OrdersTotal() - 1; MACH_vg_cnt >= 0; MACH_vg_cnt--)
    {
        OrderSelect(MACH_vg_cnt, SELECT_BY_POS, MODE_TRADES);
        if (OrderSymbol() != Symbol() || OrderMagicNumber() != MACH_MagicNumber)
            continue;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MACH_MagicNumber)
        {
            if (OrderType() == OP_BUY)
            {
                MACH_LongTrade = TRUE;
                MACH_ShortTrade = FALSE;
                break;
            }
        }
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MACH_MagicNumber)
        {
            if (OrderType() == OP_SELL)
            {
                MACH_LongTrade = FALSE;
                MACH_ShortTrade = TRUE;
                break;
            }
        }
    }

    //VERIFY GRID SPACE TO TRADE
    if (MACH_totalOrdensOpen > 0 && MACH_totalOrdensOpen <= MACH_InpMaxTrades)
    {
        RefreshRates();
        MACH_l_sumlot1 = 0;
        MACH_l_sumlot2 = 0;
        MACH_LastBuyPrice = FindLastBuyPrice(MACH_MagicNumber, MACH_l_sumlot1);
        MACH_LastSellPrice = FindLastSellPrice(MACH_MagicNumber, MACH_l_sumlot2);
        MACH_sumLots = MACH_l_sumlot1 + MACH_l_sumlot2;

        if (MACH_LongTrade && MACH_LastBuyPrice - Ask >= MACH_vg_GridSize * Point)
            MACH_TradeNow = TRUE;
        if (MACH_ShortTrade && Bid - MACH_LastSellPrice >= MACH_vg_GridSize * Point)
            MACH_TradeNow = TRUE;
    }

    if (MACH_totalOrdensOpen < 1)
    {
        MACH_ShortTrade = FALSE;
        MACH_LongTrade = FALSE;
        MACH_TradeNow = TRUE;
        MACH_StartEquity = AccountEquity();
    }

    // SE OpenOneCandle   ENABLE
    if (!MACH_InpOpenOneCandle || (MACH_InpOpenOneCandle && MACH_vDatetimeUltCandleOpen != iTime(NULL, MACH_InpTimeframeBarOpen, 0)))
    {

        // ORDEM DE GRID
        if (MACH_TradeNow && (MACH_ShortTrade || MACH_LongTrade))
        {
            MACH_l_lastlot1 = 0;
            MACH_l_lastlot2 = 0;
            MACH_l_sumlot1 = 0;
            MACH_l_sumlot2 = 0;
            MACH_LastBuyPrice = FindLastBuyPriceLL(MACH_MagicNumber, MACH_l_sumlot1, MACH_l_lastlot1);
            MACH_LastSellPrice = FindLastSellPriceLL(MACH_MagicNumber, MACH_l_sumlot2, MACH_l_lastlot2);
            MACH_sumLots = MACH_l_sumlot1 + MACH_l_sumlot2;
            MACH_l_lastlot = MACH_l_lastlot1 + MACH_l_lastlot2;

            MACH_NumOfTrades = MACH_totalOrdensOpen;

            MACH_InpLotdecimal = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);

            //if(LotInformado)
            //   MACH_iLots = Lots;
            //else
            if (MACH_ShortTrade)
                MACH_iLots = MathRound(CalcLot(MACH_TypeGridLot, OP_BUY, MACH_NumOfTrades, MACH_l_lastlot, Lots, MACH_InpLotExponent, MACH_InpGridStepLot, MACH_InpStepLot), MACH_InpLotdecimal);
            if (MACH_LongTrade)
                MACH_iLots = MathRound(CalcLot(MACH_TypeGridLot, OP_SELL, MACH_NumOfTrades, MACH_l_lastlot, Lots, MACH_InpLotExponent, MACH_InpGridStepLot, MACH_InpStepLot), MACH_InpLotdecimal);

            if (MACH_iLots < MarketInfo(Symbol(), 23))
                MACH_iLots = MarketInfo(Symbol(), 23);
            if (MACH_iLots > MarketInfo(Symbol(), 25))
                MACH_iLots = MarketInfo(Symbol(), 25);
            if (MACH_iLots > MACH_InpMaxLot && !LotInformado)
                MACH_iLots = MACH_InpMaxLot;

            RefreshRates();

            //SELL
            if (MACH_ShortTrade && vSinal == -1)
            {

                MACH_ticket = OpenOrder(1, MACH_iLots, Bid, MACH_InpSlip, Ask, 0, 0, MACH_ID + "-" + MACH_NumOfTrades + "-" + MACH_vg_GridSize, MACH_MagicNumber, 0, HotPink);
                if (MACH_ticket < 0)
                {
                    Print("Error: ", GetLastError());
                    return;
                }
                MACH_LastSellPrice = FindLastSellPrice(MACH_MagicNumber, MACH_sumLots);
                MACH_TradeNow = FALSE;
                MACH_vDatetimeUltCandleOpen = iTime(NULL, MACH_InpTimeframeBarOpen, 0);
                MACH_NewOrdersPlaced = TRUE;
            }

            //BUY
            if (MACH_LongTrade && vSinal == 1)
            {

                MACH_ticket = OpenOrder(0, MACH_iLots, Ask, MACH_InpSlip, Bid, 0, 0, MACH_ID + "-" + MACH_NumOfTrades + "-" + MACH_vg_GridSize, MACH_MagicNumber, 0, Lime);
                if (MACH_ticket < 0)
                {
                    Print("Error: ", GetLastError());
                    return;
                }
                MACH_LastBuyPrice = FindLastBuyPrice(MACH_MagicNumber, MACH_sumLots);
                MACH_TradeNow = FALSE;
                MACH_vDatetimeUltCandleOpen = iTime(NULL, MACH_InpTimeframeBarOpen, 0);
                MACH_NewOrdersPlaced = TRUE;
            }
        }
    }

    //  OpenOneCandle
    if (!MACH_InpOpenOneCandle || (MACH_InpOpenOneCandle && MACH_vDatetimeUltCandleOpen != iTime(NULL, MACH_InpTimeframeBarOpen, 0)))
    {

        // 1ª ORDEM DO GRID
        if (MACH_TradeNow && MACH_totalOrdensOpen < 1)
        {

            MACH_SellLimit = Bid;
            MACH_BuyLimit = Ask;
            if (!MACH_ShortTrade && !MACH_LongTrade)
            {

                MACH_NumOfTrades = MACH_totalOrdensOpen;

                if (LotInformado)
                    MACH_iLots = Lots;
                else
                {
                     MACH_iLots = Lots;
                    //if (vSinal == -1)
                    //    MACH_iLots = MathRound(CalcLot(MACH_TypeGridLot, OP_BUY, MACH_NumOfTrades, MACH_l_lastlot, Lots, MACH_InpLotExponent, MACH_InpGridStepLot, MACH_InpStepLot), MACH_InpLotdecimal);
                   // if (vSinal == 1)
                    //    MACH_iLots = MathRound(CalcLot(MACH_TypeGridLot, OP_SELL, MACH_NumOfTrades, MACH_l_lastlot, Lots, MACH_InpLotExponent, MACH_InpGridStepLot, MACH_InpStepLot), MACH_InpLotdecimal);
                }

                if (MACH_iLots < MarketInfo(Symbol(), 23))
                    MACH_iLots = MarketInfo(Symbol(), 23);
                if (MACH_iLots > MarketInfo(Symbol(), 25))
                    MACH_iLots = MarketInfo(Symbol(), 25);

                if (MACH_iLots > MACH_InpMaxLot && !LotInformado)
                    MACH_iLots = MACH_InpMaxLot;

                //SELL
                if (vSinal == -1)
                {
                    MACH_ticket = OpenOrder(1, MACH_iLots, MACH_SellLimit, MACH_InpSlip, MACH_SellLimit, 0, 0, MACH_ID + "-" + MACH_NumOfTrades, MACH_MagicNumber, 0, HotPink);
                    if (MACH_ticket < 0)
                    {
                        Print("Error: ", GetLastError());
                        return;
                    }

                    MACH_LastSellPrice = FindLastSellPrice(MACH_MagicNumber, MACH_sumLots);
                    MACH_TradeNow = FALSE;
                    MACH_vDatetimeUltCandleOpen = iTime(NULL, MACH_InpTimeframeBarOpen, 0);
                    MACH_NewOrdersPlaced = TRUE;
                }

                //BUY
                if (vSinal == 1)
                {

                    MACH_ticket = OpenOrder(0, MACH_iLots, MACH_BuyLimit, MACH_InpSlip, MACH_BuyLimit, 0, 0, MACH_ID + "-" + MACH_NumOfTrades, MACH_MagicNumber, 0, Lime);
                    if (MACH_ticket < 0)
                    {
                        Print("Error: ", GetLastError());
                        return;
                    }
                    MACH_LastBuyPrice = FindLastBuyPrice(MACH_MagicNumber, MACH_sumLots);
                    MACH_TradeNow = FALSE;
                    MACH_vDatetimeUltCandleOpen = iTime(NULL, MACH_InpTimeframeBarOpen, 0);
                    MACH_NewOrdersPlaced = TRUE;
                }

                // if (MACH_ticket > 0) MACH_expiration = TimeCurrent() + 60.0 * (60.0 * InpMaxTradeOpenHours);
            }
        }
    }

    //CALC MACH_AveragePrice / Count Total Lots
    MACH_totalOrdensOpen = CountTrades(MACH_MagicNumber);
    MACH_AveragePrice = 0;
    double BuyProfit = 0;
    double SellProfit = 0;
    double order_open_price, order_lots;
    int index, orders_total, order_ticket, order_type, ticket, hour;
    int buy_ticket = 0, sell_ticket = 0;
    int buyer_counter = 0, seller_counter = 0, orders_count = 0;
    double buyer_lots = 0.0, seller_lots = 0.0;
    double Count = 0;
    for (MACH_vg_cnt = OrdersTotal() - 1; MACH_vg_cnt >= 0; MACH_vg_cnt--)
    {
        OrderSelect(MACH_vg_cnt, SELECT_BY_POS, MODE_TRADES);
        if (OrderSymbol() != Symbol() || OrderMagicNumber() != MACH_MagicNumber)
            continue;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MACH_MagicNumber)
        {
            if (OrderType() == OP_BUY || OrderType() == OP_SELL)
            {
                order_ticket = OrderTicket();
                order_type = OrderType();
                order_open_price = OrderOpenPrice();
                MACH_AveragePrice += OrderOpenPrice() * OrderLots();
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

    if (BuyProfit >= MACH_MinProfit && buyer_counter >= MACH_QtdTradesMinProfit)
        CloseAllTicket(OP_BUY, buy_ticket, MACH_MagicNumber, 3);

    if (SellProfit >= MACH_MinProfit && seller_counter >= MACH_QtdTradesMinProfit)
        CloseAllTicket(OP_SELL, sell_ticket, MACH_MagicNumber, 3);

    if (MACH_totalOrdensOpen > 0)
        MACH_AveragePrice = NormalizeDouble(MACH_AveragePrice / Count, Digits);
    MACH_sumLots = Count;

    //CALC MACH_PriceTarget/MACH_BuyTarget/MACH_Stopper
    if (MACH_NewOrdersPlaced)
    {
        for (MACH_vg_cnt = OrdersTotal() - 1; MACH_vg_cnt >= 0; MACH_vg_cnt--)
        {
            OrderSelect(MACH_vg_cnt, SELECT_BY_POS, MODE_TRADES);
            if (OrderSymbol() != Symbol() || OrderMagicNumber() != MACH_MagicNumber)
                continue;
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == MACH_MagicNumber)
            {
                if (OrderType() == OP_BUY)
                {
                    MACH_PriceTarget = MACH_AveragePrice + MACH_InpTakeProfit * Point;
                    MACH_BuyTarget = MACH_PriceTarget;
                    MACH_Stopper = MACH_AveragePrice - MACH_InpStoploss * Point;
                    MACH_flag = TRUE;
                }
            }
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == MACH_MagicNumber)
            {
                if (OrderType() == OP_SELL)
                {
                    MACH_PriceTarget = MACH_AveragePrice - MACH_InpTakeProfit * Point;
                    MACH_SellTarget = MACH_PriceTarget;
                    MACH_Stopper = MACH_AveragePrice + MACH_InpStoploss * Point;
                    MACH_flag = TRUE;
                }
            }
        }
    }

    //ADD TAKE PROFIT
    if (MACH_NewOrdersPlaced)
    {
        if (MACH_flag == TRUE)
        {
            for (MACH_vg_cnt = OrdersTotal() - 1; MACH_vg_cnt >= 0; MACH_vg_cnt--)
            {
                OrderSelect(MACH_vg_cnt, SELECT_BY_POS, MODE_TRADES);
                if (OrderSymbol() != Symbol() || OrderMagicNumber() != MACH_MagicNumber)
                    continue;
                if (OrderSymbol() == Symbol() && OrderMagicNumber() == MACH_MagicNumber)
                    OrderModify(OrderTicket(), NormalizeDouble(MACH_AveragePrice, Digits), NormalizeDouble(OrderStopLoss(), Digits), NormalizeDouble(MACH_PriceTarget, Digits), 0, Yellow);
                MACH_NewOrdersPlaced = FALSE;
            }
        }
    }

    //CLOSE ALL IF MaxTrades
    if (MACH_totalOrdensOpen > MACH_InpMaxTrades)
    {
        for (int pos = 0; pos < OrdersTotal(); pos++)
        {
            OrderSelect(pos, SELECT_BY_POS);
            if (OrderSymbol() != Symbol() || OrderMagicNumber() != MACH_MagicNumber)
                continue;
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == MACH_MagicNumber)
                if (OrderType() == OP_SELL)
                {
                    OrderClose(OrderTicket(), OrderLots(), Ask, 5, White);
                    MACH_ordprof = OrderSwap() + OrderProfit() + OrderCommission();
                    if (GetLastError() == 0)
                    {
                        SendNotification("SellOrder: " + Symbol() + ", " + OrderType() + ", " + DoubleToStr(Ask, Digits) + ", " + DoubleToStr(OrderLots(), 2) + ", " + DoubleToStr(MACH_ordprof, 2));
                    }
                    pos = OrdersTotal();
                }
            if (OrderType() == OP_BUY)
            {
                OrderClose(OrderTicket(), OrderLots(), Bid, 5, White);
                MACH_ordprof = OrderSwap() + OrderProfit() + OrderCommission();
                if (GetLastError() == 0)
                {
                    SendNotification("BuyOrder: " + Symbol() + ", " + OrderType() + ", " + DoubleToStr(Ask, Digits) + ", " + DoubleToStr(OrderLots(), 2) + ", " + DoubleToStr(MACH_ordprof, 2));
                }
                pos = OrdersTotal();
            }
        }
    }
}