
extern string MACH3__ = "-----------------------------------------------------------------";
extern string MACH3 = "                                  MODULE MACH3 GRID               ";
extern string MACH3____ = "---------------------------------------------------------------";
string MACH3_EAName = "MACH3";
input bool InpEnableMACH3 = true;         //Enable MACH3
extern int MACH3_MagicNumber = 3301111;   //Magic MACH3
extern int MACH3_InpLotdecimal = 2;       //Lotdecimal
extern double MACH3_InpTakeProfit = 18.0; //Take Profit
extern double MACH3_InpStoploss = 500.0;  //Stoploss
extern double MACH3_InpSlip = 3.0;        //Slip
input double MACH3_InpMaxLot = 99;        // Max Lot

extern string MACH3_Configgrid__ = "---------------------------GRID--------------------------------------";
extern double MACH3_InpLotExponent = 1.3;  // Grid Increment Factor
extern bool MACH3_InpDynamicPips = true;      // Dynamic Grid
extern int MACH3_InpStepSizeGridDefault = 12; // Step Size in Pips [Default if MACH3_InpDynamicPips true]
extern int MACH3_InpGlubina = 24;             //Qtd Periodos p/ maxima e minima
extern int MACH3_InpDEL = 3;                  //Divizor de (maxima - minima) p/ calculo do tamanho do grid
extern int MACH3_InpMaxTrades = 21;           // Max Lot Open Simultaneo

extern string MACH3_FilterOpenOneCandle__ = "--------------------Filter One Order by Candle--------------";
input bool MACH3_InpOpenOneCandle = false;                        // Open one order by candle
input ENUM_TIMEFRAMES MACH3_InpTimeframeBarOpen = PERIOD_CURRENT; // Timeframe OpenOneCandle

extern string MACH3_EquityCaution__ = "------------------------Filter Caution of Equity ---------------";
extern bool MACH3_InpUseEquityCaution = true;                       //  EquityCaution?
extern double MACH3_InpValueEquityRiskCaution = 10;                 // Total $ Risk to EquityCaution
extern ENUM_TIMEFRAMES MACH3_InpTimeframeEquityCaution = PERIOD_H4; // Timeframe as EquityCaution
extern string MACH3_CloseProfit__ = "------------------------ Close in profit Level X ---------------";
input double MACH3_MinProfit = 10.00;   // Minimal Profit Close
input int MACH3_QtdTradesMinProfit = 2; // Qtd Trades Open to Minimal Profit Close

//VAR MACH31
double MACH3_PriceTarget, MACH3_StartEquity, MACH3_BuyTarget, MACH3_SellTarget, MACH3_CurrentPairProfit;
double MACH3_AveragePrice, MACH3_SellLimit, MACH3_BuyLimit, MACH3_sumLots;
double MACH3_LastBuyPrice, MACH3_LastSellPrice, MACH3_Stopper = 0.0, MACH3_iLots, MACH3_ordprof;
int MACH3_NumOfTrades = 0, MACH3_totalOrdensOpen, MACH3_ticket, MACH3_timeprev = 0, MACH3_expiration, MACH3_orders_count;
bool MACH3_TradeNow = FALSE, MACH3_LongTrade = FALSE, MACH3_ShortTrade = FALSE, MACH3_flag, MACH3_NewOrdersPlaced = FALSE;
datetime MACH3_vDatetimeUltCandleOpen, MACH3_m_time_equityrisk;
bool MACH3_equityrisk;

//VARIAVEIS GLOBAIS MACH3
int MACH3_vg_cnt = 0;
int MACH3_vg_GridSize = 0;
string MACH3_ID = "MACH3", MACH3_vg_filters_on = "";

//+------------------------------------------------------------------+
//|           EA MACH3 x                                              |
//+------------------------------------------------------------------+
void MACH3x(int vSinal, bool LotInformado, double Lots)
{

    if (!InpEnableMACH3)
        return;

    if (MACH3_m_time_equityrisk == iTime(NULL, MACH3_InpTimeframeEquityCaution, 0))
    {
        MACH3_vg_filters_on += "Filter EquityCaution MACH3  ON \n";

        return;
    }
    else
    {
        MACH3_vg_filters_on = "";
        MACH3_m_time_equityrisk = -1;
    }

    color avgLine = Blue;
    if (MACH3_ShortTrade)
        avgLine = Red;

    if (MACH3_LongTrade || MACH3_ShortTrade)
        SetHLine(avgLine, "Avg" + MACH3_ID, MACH3_AveragePrice, 0, 3);
    else
        ObjectDelete("Avg" + MACH3_ID);

    //NORMALIZA LOT
    if (Lots < MarketInfo(Symbol(), 23))
        Lots = MarketInfo(Symbol(), 23);
    if (Lots > MarketInfo(Symbol(), 25))
        Lots = MarketInfo(Symbol(), 25);

    // SE DynamicPips  ENABLE
    if (MACH3_InpDynamicPips)
    {

        // calculate highest and lowest price from last bar to 24 bars ago
        double hival = High[iHighest(NULL, 0, MODE_HIGH, MACH3_InpGlubina, 1)];

        // chart used for symbol and time period
        double loval = Low[iLowest(NULL, 0, MODE_LOW, MACH3_InpGlubina, 1)];
        // calculate pips for spread between orders
        MACH3_vg_GridSize = NormalizeDouble((hival - loval) / MACH3_InpDEL / Point, 0);

        if (MACH3_vg_GridSize < MACH3_InpStepSizeGridDefault / MACH3_InpDEL)
            MACH3_vg_GridSize = NormalizeDouble(MACH3_InpStepSizeGridDefault / MACH3_InpDEL, 0);

        // if dynamic pips fail, assign pips extreme value
        if (MACH3_vg_GridSize > MACH3_InpStepSizeGridDefault * MACH3_InpDEL)
            MACH3_vg_GridSize = NormalizeDouble(MACH3_InpStepSizeGridDefault * MACH3_InpDEL, 0);
    }
    else
        MACH3_vg_GridSize = MACH3_InpStepSizeGridDefault;

    MACH3_CurrentPairProfit = CalculateProfit(MACH3_MagicNumber);

    // CONTROL DRAWDOWN
    if (MACH3_CurrentPairProfit < 0.0 && (MACH3_CurrentPairProfit < MACH3_InpValueEquityRiskCaution * -1))
    {
        MACH3_m_time_equityrisk = iTime(NULL, MACH3_InpTimeframeEquityCaution, 0);
        MACH3_equityrisk = true;
    }
    else
    {
        MACH3_m_time_equityrisk = -1;
        MACH3_equityrisk = false;
    }

    //VERIFICA SE POSSUI TRADER ATIVO
    MACH3_totalOrdensOpen = CountTrades(MACH3_MagicNumber);
    if (MACH3_totalOrdensOpen == 0)
        MACH3_flag = FALSE;
    for (MACH3_vg_cnt = OrdersTotal() - 1; MACH3_vg_cnt >= 0; MACH3_vg_cnt--)
    {
        OrderSelect(MACH3_vg_cnt, SELECT_BY_POS, MODE_TRADES);
        if (OrderSymbol() != Symbol() || OrderMagicNumber() != MACH3_MagicNumber)
            continue;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MACH3_MagicNumber)
        {
            if (OrderType() == OP_BUY)
            {
                MACH3_LongTrade = TRUE;
                MACH3_ShortTrade = FALSE;
                break;
            }
        }
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MACH3_MagicNumber)
        {
            if (OrderType() == OP_SELL)
            {
                MACH3_LongTrade = FALSE;
                MACH3_ShortTrade = TRUE;
                break;
            }
        }
    }

    //VERIFY GRID SPACE TO TRADE
    if (MACH3_totalOrdensOpen > 0 && MACH3_totalOrdensOpen <= MACH3_InpMaxTrades)
    {
        RefreshRates();
        double l_lastlot1, l_lastlot2 = 0;
        MACH3_LastBuyPrice = FindLastBuyPrice(MACH3_MagicNumber, l_lastlot1);
        MACH3_LastSellPrice = FindLastSellPrice(MACH3_MagicNumber, l_lastlot2);
        MACH3_sumLots = l_lastlot1 + l_lastlot2;

        if (MACH3_LongTrade && MACH3_LastBuyPrice - Ask >= MACH3_vg_GridSize * Point)
            MACH3_TradeNow = TRUE;
        if (MACH3_ShortTrade && Bid - MACH3_LastSellPrice >= MACH3_vg_GridSize * Point)
            MACH3_TradeNow = TRUE;
    }

    if (MACH3_totalOrdensOpen < 1)
    {
        MACH3_ShortTrade = FALSE;
        MACH3_LongTrade = FALSE;
        MACH3_TradeNow = TRUE;
        MACH3_StartEquity = AccountEquity();
    }

    // SE OpenOneCandle   ENABLE
    if (!MACH3_InpOpenOneCandle || (MACH3_InpOpenOneCandle && MACH3_vDatetimeUltCandleOpen != iTime(NULL, MACH3_InpTimeframeBarOpen, 0)))
    {

        // ORDEM DE GRID
        if (MACH3_TradeNow && (MACH3_ShortTrade || MACH3_LongTrade))
        {
            MACH3_LastBuyPrice = FindLastBuyPrice(MACH3_MagicNumber, MACH3_sumLots);
            MACH3_LastSellPrice = FindLastSellPrice(MACH3_MagicNumber, MACH3_sumLots);

            MACH3_NumOfTrades = MACH3_totalOrdensOpen;

            //if(LotInformado)
            //   MACH3_iLots = Lots;
            //else
            MACH3_iLots = NormalizeDouble(Lots * MathPow(MACH3_InpLotExponent, MACH3_NumOfTrades), MACH3_InpLotdecimal);

            if (MACH3_iLots < MarketInfo(Symbol(), 23))
                MACH3_iLots = MarketInfo(Symbol(), 23);
            if (MACH3_iLots > MarketInfo(Symbol(), 25))
                MACH3_iLots = MarketInfo(Symbol(), 25);
            if (MACH3_iLots > MACH3_InpMaxLot && !LotInformado)
                MACH3_iLots = MACH3_InpMaxLot;

            RefreshRates();

            //SELL
            if (MACH3_ShortTrade && vSinal == -1)
            {

                MACH3_ticket = OpenOrder(1, MACH3_iLots, Bid, MACH3_InpSlip, Ask, 0, 0, MACH3_ID + "-" + MACH3_NumOfTrades + "-" + MACH3_vg_GridSize, MACH3_MagicNumber, 0, HotPink);
                if (MACH3_ticket < 0)
                {
                    Print("Error: ", GetLastError());
                    return;
                }
                MACH3_LastSellPrice = FindLastSellPrice(MACH3_MagicNumber, MACH3_sumLots);
                MACH3_TradeNow = FALSE;
                MACH3_vDatetimeUltCandleOpen = iTime(NULL, MACH3_InpTimeframeBarOpen, 0);
                MACH3_NewOrdersPlaced = TRUE;
            }

            //BUY
            if (MACH3_LongTrade && vSinal == 1)
            {

                MACH3_ticket = OpenOrder(0, MACH3_iLots, Ask, MACH3_InpSlip, Bid, 0, 0, MACH3_ID + "-" + MACH3_NumOfTrades + "-" + MACH3_vg_GridSize, MACH3_MagicNumber, 0, Lime);
                if (MACH3_ticket < 0)
                {
                    Print("Error: ", GetLastError());
                    return;
                }
                MACH3_LastBuyPrice = FindLastBuyPrice(MACH3_MagicNumber, MACH3_sumLots);
                MACH3_TradeNow = FALSE;
                MACH3_vDatetimeUltCandleOpen = iTime(NULL, MACH3_InpTimeframeBarOpen, 0);
                MACH3_NewOrdersPlaced = TRUE;
            }
        }
    }

    //  OpenOneCandle
    if (!MACH3_InpOpenOneCandle || (MACH3_InpOpenOneCandle && MACH3_vDatetimeUltCandleOpen != iTime(NULL, MACH3_InpTimeframeBarOpen, 0)))
    {

        // 1ª ORDEM DO GRID
        if (MACH3_TradeNow && MACH3_totalOrdensOpen < 1)
        {

            MACH3_SellLimit = Bid;
            MACH3_BuyLimit = Ask;
            if (!MACH3_ShortTrade && !MACH3_LongTrade)
            {

                MACH3_NumOfTrades = MACH3_totalOrdensOpen;

                if (LotInformado)
                    MACH3_iLots = Lots;
                else
                    MACH3_iLots = NormalizeDouble(Lots * MathPow(MACH3_InpLotExponent, MACH3_NumOfTrades), MACH3_InpLotdecimal);

                if (MACH3_iLots < MarketInfo(Symbol(), 23))
                    MACH3_iLots = MarketInfo(Symbol(), 23);
                if (MACH3_iLots > MarketInfo(Symbol(), 25))
                    MACH3_iLots = MarketInfo(Symbol(), 25);

                if (MACH3_iLots > MACH3_InpMaxLot && !LotInformado)
                    MACH3_iLots = MACH3_InpMaxLot;

                //SELL
                if (vSinal == -1)
                {
                    MACH3_ticket = OpenOrder(1, MACH3_iLots, MACH3_SellLimit, MACH3_InpSlip, MACH3_SellLimit, 0, 0, MACH3_ID + "-" + MACH3_NumOfTrades, MACH3_MagicNumber, 0, HotPink);
                    if (MACH3_ticket < 0)
                    {
                        Print("Error: ", GetLastError());
                        return;
                    }

                    MACH3_LastSellPrice = FindLastSellPrice(MACH3_MagicNumber, MACH3_sumLots);
                    MACH3_TradeNow = FALSE;
                    MACH3_vDatetimeUltCandleOpen = iTime(NULL, MACH3_InpTimeframeBarOpen, 0);
                    MACH3_NewOrdersPlaced = TRUE;
                }

                //BUY
                if (vSinal == 1)
                {

                    MACH3_ticket = OpenOrder(0, MACH3_iLots, MACH3_BuyLimit, MACH3_InpSlip, MACH3_BuyLimit, 0, 0, MACH3_ID + "-" + MACH3_NumOfTrades, MACH3_MagicNumber, 0, Lime);
                    if (MACH3_ticket < 0)
                    {
                        Print("Error: ", GetLastError());
                        return;
                    }
                    MACH3_LastBuyPrice = FindLastBuyPrice(MACH3_MagicNumber, MACH3_sumLots);
                    MACH3_TradeNow = FALSE;
                    MACH3_vDatetimeUltCandleOpen = iTime(NULL, MACH3_InpTimeframeBarOpen, 0);
                    MACH3_NewOrdersPlaced = TRUE;
                }

                // if (MACH3_ticket > 0) MACH3_expiration = TimeCurrent() + 60.0 * (60.0 * InpMaxTradeOpenHours);
            }
        }
    }

    //CALC MACH3_AveragePrice / Count Total Lots
    MACH3_totalOrdensOpen = CountTrades(MACH3_MagicNumber);
    MACH3_AveragePrice = 0;
    double BuyProfit = 0;
    double SellProfit = 0;
    double order_open_price, order_lots;
    int index, orders_total, order_ticket, order_type, ticket, hour;
    int buy_ticket = 0, sell_ticket = 0;
    int buyer_counter = 0, seller_counter = 0, orders_count = 0;
    double buyer_lots = 0.0, seller_lots = 0.0;
    double Count = 0;
    for (MACH3_vg_cnt = OrdersTotal() - 1; MACH3_vg_cnt >= 0; MACH3_vg_cnt--)
    {
        OrderSelect(MACH3_vg_cnt, SELECT_BY_POS, MODE_TRADES);
        if (OrderSymbol() != Symbol() || OrderMagicNumber() != MACH3_MagicNumber)
            continue;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MACH3_MagicNumber)
        {
            if (OrderType() == OP_BUY || OrderType() == OP_SELL)
            {
                order_ticket = OrderTicket();
                order_type = OrderType();
                order_open_price = OrderOpenPrice();
                MACH3_AveragePrice += OrderOpenPrice() * OrderLots();
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

    if (BuyProfit >= MACH3_MinProfit && buyer_counter >= MACH3_QtdTradesMinProfit)
        CloseAllTicket(OP_BUY, buy_ticket, MACH3_MagicNumber,3);

    if (SellProfit >= MACH3_MinProfit && seller_counter >= MACH3_QtdTradesMinProfit)
        CloseAllTicket(OP_SELL, sell_ticket, MACH3_MagicNumber,3);

    if (MACH3_totalOrdensOpen > 0)
        MACH3_AveragePrice = NormalizeDouble(MACH3_AveragePrice / Count, Digits);
    MACH3_sumLots = Count;

    //CALC MACH3_PriceTarget/MACH3_BuyTarget/MACH3_Stopper
    if (MACH3_NewOrdersPlaced)
    {
        for (MACH3_vg_cnt = OrdersTotal() - 1; MACH3_vg_cnt >= 0; MACH3_vg_cnt--)
        {
            OrderSelect(MACH3_vg_cnt, SELECT_BY_POS, MODE_TRADES);
            if (OrderSymbol() != Symbol() || OrderMagicNumber() != MACH3_MagicNumber)
                continue;
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == MACH3_MagicNumber)
            {
                if (OrderType() == OP_BUY)
                {
                    MACH3_PriceTarget = MACH3_AveragePrice + MACH3_InpTakeProfit * Point;
                    MACH3_BuyTarget = MACH3_PriceTarget;
                    MACH3_Stopper = MACH3_AveragePrice - MACH3_InpStoploss * Point;
                    MACH3_flag = TRUE;
                }
            }
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == MACH3_MagicNumber)
            {
                if (OrderType() == OP_SELL)
                {
                    MACH3_PriceTarget = MACH3_AveragePrice - MACH3_InpTakeProfit * Point;
                    MACH3_SellTarget = MACH3_PriceTarget;
                    MACH3_Stopper = MACH3_AveragePrice + MACH3_InpStoploss * Point;
                    MACH3_flag = TRUE;
                }
            }
        }
    }

    //ADD TAKE PROFIT
    if (MACH3_NewOrdersPlaced)
    {
        if (MACH3_flag == TRUE)
        {
            for (MACH3_vg_cnt = OrdersTotal() - 1; MACH3_vg_cnt >= 0; MACH3_vg_cnt--)
            {
                OrderSelect(MACH3_vg_cnt, SELECT_BY_POS, MODE_TRADES);
                if (OrderSymbol() != Symbol() || OrderMagicNumber() != MACH3_MagicNumber)
                    continue;
                if (OrderSymbol() == Symbol() && OrderMagicNumber() == MACH3_MagicNumber)
                    OrderModify(OrderTicket(), NormalizeDouble(MACH3_AveragePrice, Digits), NormalizeDouble(OrderStopLoss(), Digits), NormalizeDouble(MACH3_PriceTarget, Digits), 0, Yellow);
                MACH3_NewOrdersPlaced = FALSE;
            }
        }
    }

    //CLOSE ALL IF MaxTrades
    if (MACH3_totalOrdensOpen > MACH3_InpMaxTrades)
    {
        for (int pos = 0; pos < OrdersTotal(); pos++)
        {
            OrderSelect(pos, SELECT_BY_POS);
            if (OrderSymbol() != Symbol() || OrderMagicNumber() != MACH3_MagicNumber)
                continue;
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == MACH3_MagicNumber)
                if (OrderType() == OP_SELL)
                {
                    OrderClose(OrderTicket(), OrderLots(), Ask, 5, White);
                    MACH3_ordprof = OrderSwap() + OrderProfit() + OrderCommission();
                    if (GetLastError() == 0)
                    {
                        SendNotification("SellOrder: " + Symbol() + ", " + OrderType() + ", " + DoubleToStr(Ask, Digits) + ", " + DoubleToStr(OrderLots(), 2) + ", " + DoubleToStr(MACH3_ordprof, 2));
                    }
                    pos = OrdersTotal();
                }
            if (OrderType() == OP_BUY)
            {
                OrderClose(OrderTicket(), OrderLots(), Bid, 5, White);
                MACH3_ordprof = OrderSwap() + OrderProfit() + OrderCommission();
                if (GetLastError() == 0)
                {
                    SendNotification("BuyOrder: " + Symbol() + ", " + OrderType() + ", " + DoubleToStr(Ask, Digits) + ", " + DoubleToStr(OrderLots(), 2) + ", " + DoubleToStr(MACH3_ordprof, 2));
                }
                pos = OrdersTotal();
            }
        }
    }
}