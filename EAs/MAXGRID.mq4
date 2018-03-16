#property copyright " MAXGRID_v1.01"
#property link "rodolfo.leonardo@gmail.com"
#property version "1.01"
#property description "MAXGRID"
#property description "This EA is 100% FREE "
#property description "Coder: rodolfo.leonardo@gmail.com "
#property strict

enum ENUM_TypeOperationEA
  {
   Open_And_Close =1,
   Only_Close =2,
   Stop_And_Close = 3
  };

//----------------------- Externals ----------------------------------------------------------------
extern string TypeOperationEA = "==== Type Operation ====";
extern string TypeOperationStr_1 = "1:Open And Close (normal operations)";
extern string TypeOperationStr_2 = "2:Only Close (waiting for profit)";
extern string TypeOperationStr_3 = "3:Stop And Close (immediate operations)";
extern ENUM_TypeOperationEA TypeOperation = Open_And_Close; 
extern string Money_Management = "==== Money Management ====";
extern double ManualLotSize = 0.01;   // Lot size
extern bool UseAutoLotsSize = false;  // Auto lot
extern double RiskMoneyMngmnt = 10;   // Risk management
extern bool UseMartingale = true;     // Martin lot
extern double MultiplierMartin = 2.0; // Multiplier lots
extern string SetStep = "==== Set Step Parametre ====";
input ENUM_TIMEFRAMES        InpMAFrame= PERIOD_M15;
extern int PeriodMovAvrg = 100;      // Period iMA
extern double StepOrders = 100;      // Pips open next order
extern bool UseMaxStepOrders = true; // Max step
extern double MaxStepOrders = 100;   // Max distance for step
extern string SetOrders = "==== Set Orders Parametre ====";
extern bool UseTakeProfit = false; // Use take profit
extern double TakeProfit = 30;     // Profit for all orders
extern bool UseStopLoss = false;   // Use stop loss
extern double StopLoss = 300;      // Loss for all orders
extern bool AutoCloseOrder = true; // Close Order
extern string ManageOrders = "==== Manage Orders Set ====";
extern double MaxSpread = 0;      // Maximum spread in pips, 0:Not check spread
extern double Slippage = 3;       // Maximum slipage in pips
extern int MagicNumber = 777;     // Identifier
extern int MaxOpenPositions = 10; //Maximum opened orders
extern string SetGeneral = "==== General Set ====";
extern bool RunNDDbroker = false; // If broker not accept sl or tp in open order
extern bool SoundAlert = true;    // Play sound if open, close or modify order
//===================================================================================================================//
string SoundFileAtOpen = "alert.wav";
string SoundFileAtClose = "alert2.wav";
string SoundModify = "tick.wav";
string OrdrCom = "WWI-EA";
string ExpertName;
string ComOrders;
double DigitPoint;
double StopLevel;
double CurrentSpread;
double Spread;
double LotSizeBuy;
double LotSizeSell;
double StartLot;
double ProfitBuy;
double ProfitSell;
double PipsLastBuy;
double PipsLastSell;
int MultiplierPoint;
int SumOpenOrders;
int CntBuy;
int CntSell;
int LevelUp;
int LevelDn;
int LevelStartCycle = 0;
int TypeLevels = 0;
bool CheckSpread;
bool FindLevel = true;
//===================================================================================================================//
//init function
int init()
{
    //------------------------------------------------------
    //Started information
    ExpertName = WindowExpertName();
    //------------------------------------------------------
    //Broker 4 or 5 digits
    DigitPoint = MarketInfo(Symbol(), MODE_POINT);
    MultiplierPoint = 1;
    if (MarketInfo(Symbol(), MODE_DIGITS) == 3 || MarketInfo(Symbol(), MODE_DIGITS) == 5)
    {
        MultiplierPoint = 10;
        DigitPoint *= MultiplierPoint;
    }
    //------------------------------------------------------
    //Minimum step order, take profit and stop loss
    StopLevel = MathMax(MarketInfo(Symbol(), MODE_FREEZELEVEL) / MultiplierPoint, MarketInfo(Symbol(), MODE_STOPLEVEL) / MultiplierPoint);
    if ((TakeProfit > 0) && (TakeProfit < StopLevel))
        TakeProfit = StopLevel;
    if ((StopLoss > 0) && (StopLoss < StopLevel))
        StopLoss = StopLevel;
    if ((StepOrders > 0) && (StepOrders < StopLevel))
        StepOrders = StopLevel;
    //------------------------------------------------------
    //Confirm range
    if ((TypeOperation < 1) || (TypeOperation > 3))
        TypeOperation = 1;
    //------------------------------------------------------
    return (0);
}
//===================================================================================================================//
//deinit function
int deinit()
{
    return (0);
}
//===================================================================================================================//
//start function
int start()
{
    CheckSpread = true;
    //------------------------------------------------------
    //Count orders, pips and profit
    CountOrders();
    SumOpenOrders = CntBuy + CntSell;
    if (SumOpenOrders > 0)
    {
        CommentChart(1); //there are open orders
        ProfitOrdr();
        CountPips();
    }
    //------------------------------------------------------
    //Market spread
    Spread = MarketInfo(Symbol(), MODE_SPREAD) / MultiplierPoint;
    //------------------------------------------------------
    //Check spread
    if (!IsTesting()) //for forward test warning message
    {
        if ((Spread > MaxSpread) && (MaxSpread > 0))
        {
            CheckSpread = false;
            Print("Warning: Spread is greater than MaxSpread!!! (Spread: " + DoubleToStr(Spread, 1) + " || MaxSpread: " + DoubleToStr(MaxSpread, 1) + ")");
            Print("Notice: Expert check again spread....");
            CurrentSpread = Spread;
        }
        //---
        if ((Spread < CurrentSpread) && (Spread <= MaxSpread))
        {
            Print("Notice: Spread now is OK!!!");
            CurrentSpread = 0;
        }
    }
    else if ((Spread > MaxSpread) && (MaxSpread > 0)) //for backtest warning message
    {
        CheckSpread = false;
        Print("Warning: Spread is greater than MaxSpread!!! (Spread: " + DoubleToStr(Spread, 1) + " || MaxSpread: " + DoubleToStr(MaxSpread, 1) + ")");
    }
    //------------------------------------------------------
    //Find level and type level in comment
    if (CheckSpread == true)
    {
        if ((FindLevel == true) && (SumOpenOrders > 0))
        {
            FindLevel = false;
            if (FindLastLevel() < 1000)
            {
                LevelStartCycle = FindLastLevel() - 10;
                TypeLevels = 1;
            }
            if (FindLastLevel() >= 1000)
            {
                LevelStartCycle = FindLastLevel() - 1000;
                TypeLevels = -1;
            }
            ComOrders = OrdrCom + "_" + FindLastLevel(); //order comment
        }
        //------------------------------------------------------
        //Find level up and down of price for start cycle
        if ((FindLevel == true) && (TypeOperation == 1))
        {
            FindLevel = false;
            LevelUp = -999999; //reset LevelUp
            LevelDn = -999999; //reset LevelDn
            TypeLevels = 0;    //reset TypeLevels
            for (int cnt = 0; cnt < 100; cnt++)
            {
                //---
                if (Bid == CountLevels(0, 0))
                    return (0); //bid = iMA
                //---
                if (Bid > CountLevels(0, 0)) //bid higher iMA
                {
                    TypeLevels = 1;
                    if (Bid > CountLevels(cnt, TypeLevels))
                    {
                        LevelDn = MathMax(cnt, LevelDn);
                        LevelUp = LevelDn + 1;
                        if (Bid <= CountLevels(cnt, TypeLevels))
                            break; //stop count and exit of loop
                    }
                }
                //---
                if (Bid < CountLevels(0, 0)) //bid lower iMA
                {
                    TypeLevels = -1;
                    if (Bid < CountLevels(cnt, TypeLevels))
                    {
                        LevelUp = MathMax(cnt, LevelUp);
                        LevelDn = LevelUp + 1;
                        if (Bid >= CountLevels(cnt, TypeLevels))
                            break; //stop count and exit of loop
                    }
                }
                //---
            }
        }
        //------------------------------------------------------
        //Comment in chart
        if (SumOpenOrders == 0)
            CommentChart(2); //there are no open orders
        //------------------------------------------------------
        //Send first orders in cross level
        if ((CntBuy == 0) && (CntSell == 0) && (TypeOperation == 1))
        {
            if (SumOpenOrders == 0)
                LevelStartCycle = 0; //reset current level
            CalcLots();              //Call lots
            //---
            if (Bid >= CountLevels(LevelUp, TypeLevels)) //price cross up level
            {
                LevelStartCycle = LevelUp; //location up level as starting level
                if (TypeLevels == 1)
                    ComOrders = OrdrCom + "_" + (LevelStartCycle + 10); //order comment
                if (TypeLevels == -1)
                    ComOrders = OrdrCom + "_" + (LevelStartCycle + 1000); //order comment
                if (CntBuy == 0)
                {
                    OpenPosition(OP_BUY, LotSizeBuy, ComOrders);
                    Print("Report: " + ExpertName + " open order in cycle, size buy grid: " + DoubleToStr(CntBuy + 1, 0));
                }
                if (CntSell == 0)
                {
                    OpenPosition(OP_SELL, LotSizeSell, ComOrders);
                    Print("Report: " + ExpertName + " open order in cycle, size sell grid: " + DoubleToStr(CntSell + 1, 0));
                }
                Print("Report: " + ExpertName + " start new cycle in Level " + LevelStartCycle);
                return (0);
            }
            //---
            if (Bid <= CountLevels(LevelDn, TypeLevels)) //price cross dn level
            {
                LevelStartCycle = LevelDn; //location dn level as starting level
                if (TypeLevels == 1)
                    ComOrders = OrdrCom + "_" + (LevelStartCycle + 10); //order comment
                if (TypeLevels == -1)
                    ComOrders = OrdrCom + "_" + (LevelStartCycle + 1000); //order comment
                if (CntBuy == 0)
                {
                    OpenPosition(OP_BUY, LotSizeBuy, ComOrders);
                    Print("Report: " + ExpertName + " open order in cycle, size buy grid: " + DoubleToStr(CntBuy + 1, 0));
                }
                if (CntSell == 0)
                {
                    OpenPosition(OP_SELL, LotSizeSell, ComOrders);
                    Print("Report: " + ExpertName + " open order in cycle, size sell grid: " + DoubleToStr(CntSell + 1, 0));
                }
                Print("Report: " + ExpertName + " start new cycle in Level " + LevelStartCycle);
                return (0);
            }
        }
        //------------------------------------------------------
        //Send next order and Close profit order
        if ((SumOpenOrders > 0) && ((TypeOperation == 1) || (TypeOperation == 2)))
        {
            if (((Bid <= CountLevels(LevelStartCycle - (CntBuy * TypeLevels), TypeLevels)) || ((UseMaxStepOrders == true) && (PipsLastBuy * (-1) >= MaxStepOrders))) && (CntBuy >= CntSell)) //&&(ProfitSell>0))//buy grid
            {
                CalcLots(); //Call lots
                if ((AutoCloseOrder == true) && (CntSell == 1))
                    CloseOrders(OP_SELL); //close sell
                if (SumOpenOrders < MaxOpenPositions)
                {
                    OpenPosition(OP_BUY, LotSizeBuy, ComOrders); //open grid buy with next lot buy
                    OpenPosition(OP_SELL, StartLot, ComOrders);  //open single sell with first lot
                }
                Print("Report: " + ExpertName + " open next orders in cycle, size buy grid: " + DoubleToStr(CntBuy + 1, 0));
                return (0);
            }
            //---
            if (((Bid >= CountLevels(LevelStartCycle + (CntSell * TypeLevels), TypeLevels)) || ((UseMaxStepOrders == true) && (PipsLastSell * (-1) >= MaxStepOrders))) && (CntSell >= CntBuy)) //&&(ProfitBuy>0))//sell grid
            {
                CalcLots(); //Call lots
                if ((AutoCloseOrder == true) && (CntBuy == 1))
                    CloseOrders(OP_BUY); //close buy
                if (SumOpenOrders < MaxOpenPositions)
                {
                    OpenPosition(OP_SELL, LotSizeSell, ComOrders); //open grid sell with next lot sell
                    OpenPosition(OP_BUY, StartLot, ComOrders);     //open single buy with first lot
                }
                Print("Report: " + ExpertName + " open next orders in cycle, size sell grid: " + DoubleToStr(CntSell + 1, 0));
                return (0);
            }
        }
        //------------------------------------------------------
        //Finish cycle
        if ((CntBuy > 0) && (CntSell > 0) && ((TypeOperation == 1) || (TypeOperation == 2)))
        {
            //---close buy grid
            if ((CntBuy > CntSell) && (Bid >= CountLevels(LevelStartCycle - ((CntBuy + 2) * TypeLevels), TypeLevels)) && (ProfitBuy + ProfitSell > 0))
            {
                FindLevel = true;
                if (AutoCloseOrder == true)
                {
                    if (CntSell > 0)
                        CloseOrders(OP_SELL); //close sell
                    if (CntBuy > 0)
                        CloseOrders(OP_BUY); //close buy
                    Print("Report: " + ExpertName + " completed last cycle with profit: " + DoubleToStr(ProfitBuy + ProfitSell, 2));
                    return (0);
                }
            }
            //---close sell grid
            if ((CntSell > CntBuy) && (Bid <= CountLevels(LevelStartCycle + ((CntSell - 2) * TypeLevels), TypeLevels)) && (ProfitBuy + ProfitSell > 0))
            {
                FindLevel = true;
                if (AutoCloseOrder == true)
                {
                    if (CntBuy > 0)
                        CloseOrders(OP_BUY); //close buy
                    if (CntSell > 0)
                        CloseOrders(OP_SELL); //close sell
                    Print("Report: " + ExpertName + " completed last cycle with profit: " + DoubleToStr(ProfitBuy + ProfitSell, 2));
                    return (0);
                }
            }
        }
        //------------------------------------------------------
    } //End if((CheckSpread==true)...
    //------------------------------------------------------
    //Close and stop
    if (TypeOperation == 3)
    {
        if (CntBuy > 0)
            CloseOrders(OP_BUY); //close buy
        if (CntSell > 0)
            CloseOrders(OP_SELL); //close sell
    }
    //------------------------------------------------------
    return (0);
}
//===================================================================================================================//
//open orders
void OpenPosition(int PositionType, double Lots, string OrdersComment)
{
    int OpenOrderTicket;
    bool WasOrderModified;
    double Price;
    double OpenPrice;
    color OpenColor;
    //------------------------------------------------------
    //Calculate take profit and stop loss in pips and lots
    double TP, SL;
    double OrderTP = NormalizeDouble(TakeProfit * DigitPoint, Digits);
    double OrderSL = NormalizeDouble(StopLoss * DigitPoint, Digits);
    //------------------------------------------------------
    while (true)
    {
        //------------------------------------------------------
        //Buy stop loss and take profit in price
        if (PositionType == OP_BUY)
        {
            TP = 0;
            SL = 0;
            OpenPrice = NormalizeDouble(Ask, Digits);
            OpenColor = Blue;
            if ((TakeProfit > 0) && (UseTakeProfit == true))
                TP = NormalizeDouble(Ask + OrderTP, Digits);
            if ((StopLoss > 0) && (UseStopLoss == true))
                SL = NormalizeDouble(Bid - OrderSL, Digits);
        }
        //------------------------------------------------------
        //Sell stop loss and take profit in price
        if (PositionType == OP_SELL)
        {
            TP = 0;
            SL = 0;
            OpenPrice = NormalizeDouble(Bid, Digits);
            OpenColor = Red;
            if ((TakeProfit > 0) && (UseTakeProfit == true))
                TP = NormalizeDouble(Bid - OrderTP, Digits);
            if ((StopLoss > 0) && (UseStopLoss == true))
                SL = NormalizeDouble(Ask + OrderSL, Digits);
        }
        //------------------------------------------------------
        //NDD broker, no sl no tp
        if (RunNDDbroker == true)
        {
            TP = 0;
            SL = 0;
        }
        //------------------------------------------------------
        //Send orders
        OpenOrderTicket = OrderSend(Symbol(), PositionType, Lots, OpenPrice, Slippage, SL, TP, OrdersComment, MagicNumber, 0, OpenColor);
        //---
        if (OpenOrderTicket > 0)
        {
            if (SoundAlert == true)
                PlaySound(SoundFileAtOpen);
            break;
        }
        //---
        else
        {
            Print(ExpertName + ": receives new data and try again open order");
            Sleep(100);
            RefreshRates();
        }
        //---
    } //End while(true)
    //------------------------------------------------------
    //NDD send stop loss and take profit
    if ((RunNDDbroker == true) && (OpenOrderTicket > 0))
    {
        if (OrderSelect(OpenOrderTicket, SELECT_BY_TICKET))
        {
            //------------------------------------------------------
            //Modify stop loss and take profit buy order
            if ((OrderType() == OP_BUY) && (OrderStopLoss() == 0) && (OrderTakeProfit() == 0))
            {
                while (true)
                {
                    if ((TakeProfit > 0) && (UseTakeProfit == true))
                        TP = NormalizeDouble(Ask + OrderTP, Digits);
                    else
                        TP = 0;
                    if ((StopLoss > 0) && (UseStopLoss == true))
                        SL = NormalizeDouble(Bid - OrderSL, Digits);
                    else
                        SL = 0;
                    //---
                    WasOrderModified = OrderModify(OrderTicket(), NormalizeDouble(OrderOpenPrice(), Digits), SL, TP, 0, Blue);
                    //---
                    if (WasOrderModified > 0)
                    {
                        if (SoundAlert == true)
                            PlaySound(SoundModify);
                        Print(ExpertName + ": modify buy by NDDmode, ticket: " + OrderTicket());
                        break;
                    }
                    //---
                    else
                    {
                        Print("Error: ", GetLastError() + " || " + ExpertName + ": receives new data and try again modify order");
                        RefreshRates();
                    }
                    //---
                } //End while(true)
            }     //End if((OrderType()
            //------------------------------------------------------
            //Modify stop loss and take profit sell order
            if ((OrderType() == OP_SELL) && (OrderStopLoss() == 0) && (OrderTakeProfit() == 0))
            {
                while (true)
                {
                    if ((TakeProfit > 0) && (UseTakeProfit == true))
                        TP = NormalizeDouble(Bid - OrderTP, Digits);
                    else
                        TP = 0;
                    if ((StopLoss > 0) && (UseStopLoss == true))
                        SL = NormalizeDouble(Ask + OrderSL, Digits);
                    else
                        SL = 0;
                    //---
                    WasOrderModified = OrderModify(OrderTicket(), NormalizeDouble(OrderOpenPrice(), Digits), SL, TP, 0, Red);
                    //---
                    if (WasOrderModified > 0)
                    {
                        if (SoundAlert == true)
                            PlaySound(SoundModify);
                        Print(ExpertName + ": modify sell by NDDmode, ticket: " + OrderTicket());
                        break;
                    }
                    //---
                    else
                    {
                        Print("Error: ", GetLastError() + " || " + ExpertName + ": receives new data and try again modify order");
                        RefreshRates();
                    }
                    //---
                } //End while(true)
            }     //End if((OrderType()
            //------------------------------------------------------
        } //End OrderSelect(...
        //------------------------------------------------------
    } //End if(RunNDDbroker==true)

}
//===================================================================================================================//
//close orders
void CloseOrders(int TypeClose)
{
    bool WasOrderClosed;
    //------------------------------------------------------
    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if ((OrderSymbol() == Symbol()) && (OrderMagicNumber() == MagicNumber))
            {
                //------------------------------------------------------
                //Close buy
                if ((OrderType() == OP_BUY) && (TypeClose == OP_BUY))
                {
                    while (true)
                    {
                        WasOrderClosed = OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(Bid, Digits), Slippage, Yellow);
                        //---
                        if (WasOrderClosed > 0) //exit loop
                        {
                            if (SoundAlert == true)
                                PlaySound(SoundFileAtClose);
                            break;
                        }
                        //---
                        else //try again to close
                        {
                            Print("Error: ", GetLastError() + " || " + ExpertName + ": receives new data and try again close order");
                            RefreshRates();
                        }
                        //---
                    } //End while(...
                }     //End if(OrderType()==OP_BUY)
                //------------------------------------------------------
                //Close sell
                if ((OrderType() == OP_SELL) && (TypeClose == OP_SELL))
                {
                    while (true)
                    {
                        WasOrderClosed = OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(Ask, Digits), Slippage, Yellow);
                        //---
                        if (WasOrderClosed > 0) //exit loop
                        {
                            if (SoundAlert == true)
                                PlaySound(SoundFileAtClose);
                            break;
                        }
                        //---
                        else //try again to close
                        {
                            Print("Error: ", GetLastError() + " || " + ExpertName + ": receives new data and try again close order");
                            RefreshRates();
                        }
                        //---
                    } //End while(...
                }     //End if(OrderType()==OP_SELL)
                //------------------------------------------------------
            } //End if((OrderSymbol()...
        }     //End OrderSelect(...
    }         //End for(...
    
}
//===================================================================================================================//
//lot size
void CalcLots()
{
    double MinLot = MarketInfo(Symbol(), MODE_MINLOT);
    double MaxLot = MarketInfo(Symbol(), MODE_MAXLOT);
    double LotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
    double LotValue = MarketInfo(Symbol(), MODE_LOTSIZE);
    int LotDigit;
    StartLot = 0;
    LotSizeBuy = 0;
    LotSizeSell = 0;
    //------------------------------------------------------
    //Lot digit
    if (LotStep == 1)
        LotDigit = 0;
    if (LotStep == 0.1)
        LotDigit = 1;
    if (LotStep == 0.01)
        LotDigit = 2;
    //------------------------------------------------------
    //Start lot size
    if (UseAutoLotsSize == true)
        StartLot = (AccountBalance() / LotValue) * RiskMoneyMngmnt;
    if (UseAutoLotsSize == false)
        StartLot = ManualLotSize;
    //------------------------------------------------------
    //lot per orders
    if (UseMartingale == false)
    {
        LotSizeBuy = StartLot;  //buy lot
        LotSizeSell = StartLot; //sell lot
    }
    //---
    if (UseMartingale == true)
    {
        if (CntBuy + CntSell == 0)
        {
            LotSizeBuy = StartLot;  //buy lot
            LotSizeSell = StartLot; //sell lot
        }
        else
        {
            LotSizeBuy = StartLot * MathMax(MathPow(MultiplierMartin, CntBuy), 1);   //buy lot
            LotSizeSell = StartLot * MathMax(MathPow(MultiplierMartin, CntSell), 1); //sell lot
        }
    }
    //------------------------------------------------------
    //Normalize lot size
    LotSizeBuy = NormalizeDouble(MathMin(MathMax(LotSizeBuy, MinLot), MaxLot), LotDigit);
    LotSizeSell = NormalizeDouble(MathMin(MathMax(LotSizeSell, MinLot), MaxLot), LotDigit);
    //------------------------------------------------------
   
}
//===================================================================================================================//
//Profit in Order
void ProfitOrdr()
{
    ProfitBuy = 0;
    ProfitSell = 0;
    //------------------------------------------------------
    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if ((OrderSymbol() == Symbol()) && (OrderMagicNumber() == MagicNumber))
            {
                //---
                if (OrderType() == OP_BUY)
                    ProfitBuy += OrderProfit() + OrderCommission() + OrderSwap();
                if (OrderType() == OP_SELL)
                    ProfitSell += OrderProfit() + OrderCommission() + OrderSwap();
                //---
            }
        }
    }
    //------------------------------------------------------
    
}
//===================================================================================================================//
//Count orders
void CountOrders()
{
    CntBuy = 0;
    CntSell = 0;
    //------------------------------------------------------
    for (int i = 0; i < OrdersTotal(); i++)
    {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if ((OrderMagicNumber() == MagicNumber) && (OrderSymbol() == Symbol()))
            {
                if (OrderType() == OP_BUY)
                    CntBuy++;
                if (OrderType() == OP_SELL)
                    CntSell++;
            }
        }
    }
   
}
//===================================================================================================================//
//Count pips
void CountPips()
{
    PipsLastBuy = 0;
    PipsLastSell = 0;
    //------------------------------------------------------
    for (int i = 0; i < OrdersTotal(); i++)
    {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if ((OrderMagicNumber() == MagicNumber) && (OrderSymbol() == Symbol()))
            {
                //---
                if (OrderType() == OP_BUY)
                    PipsLastBuy = (MarketInfo(Symbol(), MODE_BID) - OrderOpenPrice()) / DigitPoint;
                if (OrderType() == OP_SELL)
                    PipsLastSell = (OrderOpenPrice() - MarketInfo(Symbol(), MODE_ASK)) / DigitPoint;
                //---
            }
        }
    }
    
}
//===================================================================================================================//
//Find old level
int FindLastLevel()
{
    int Level = 0;
    string GetComment = "";
    //------------------------------------------------------
    for (int i = 0; i < OrdersTotal(); i++)
    {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if ((OrderSymbol() == Symbol()) && (OrderMagicNumber() == MagicNumber))
                GetComment = OrderComment();
        }
    }
    //------------------------------------------------------
    //Level
    Level = StrToInteger(StringSubstr(GetComment, StringLen(OrdrCom) + 1)); //get level of string
    //------------------------------------------------------
    return (Level);
}
//===================================================================================================================//
//Count levels
double CountLevels(int Cnt, int TypeLevel)
{
    double LevelsCnt;
    //------------------------------------------------------
    //MA price
    double MAclose = iMA(NULL, InpMAFrame, PeriodMovAvrg, 0, MODE_SMA, PRICE_CLOSE, 0);
    //------------------------------------------------------
    //zero level
    if (TypeLevel == 0)
        LevelsCnt = MAclose;
    //------------------------------------------------------
    //Up levels
    if (TypeLevel == 1)
    {
        if (Cnt == 0)
            LevelsCnt = MAclose;
        if (Cnt > 0)
            LevelsCnt = MAclose + ((StepOrders * Cnt) * DigitPoint);
        if (Cnt < 0)
            LevelsCnt = MAclose - ((StepOrders * (Cnt * (-1))) * DigitPoint);
    }
    //------------------------------------------------------
    //Dn levels
    if (TypeLevel == -1)
    {
        if (Cnt == 0)
            LevelsCnt = MAclose;
        if (Cnt > 0)
            LevelsCnt = MAclose - ((StepOrders * Cnt) * DigitPoint);
        if (Cnt < 0)
            LevelsCnt = MAclose + ((StepOrders * (Cnt * (-1))) * DigitPoint);
    }
    //------------------------------------------------------
    return (LevelsCnt);
}
//=====================================================================================================================//
//Comment in chart
void CommentChart(int TypeCom)
{
    //------------------------------------------------------
    //Comment in screen if there are open orders
    if (TypeCom == 1)
    {
        Comment("==================",
                "\n ", OrdrCom, " Starting Level: ", LevelStartCycle,
                "\n==================",
                "\n Sum Buy Orders    : ", CntBuy,
                "\n Total Profit Buy     : ", DoubleToStr(ProfitBuy, 2),
                "\n------------------------------------------",
                "\n Sum Sell Orders    : ", CntSell,
                "\n Total Profit Sell     : ", DoubleToStr(ProfitSell, 2),
                "\n==================",
                "\n Currency_Floating : ", DoubleToStr(ProfitBuy + ProfitSell, 2),
                "\n==================");
    }
    //------------------------------------------------------
    //Comment in screen if there are no open orders
    if (TypeCom == 2)
    {
        Comment("==================",
                "\n ", OrdrCom, "   Wait Cross Level",
                "\n==================",
                "\n Pips cross up level   : ", DoubleToStr((CountLevels(LevelUp, TypeLevels) - Bid) / DigitPoint, 2),
                "\n Pips cross dn level   : ", DoubleToStr((Bid - CountLevels(LevelDn, TypeLevels)) / DigitPoint, 2),
                "\n==================");
    }
    //------------------------------------------------------
   
}
