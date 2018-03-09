extern string MovingAverageConfig__ = "-----------------------------Moving Average--------------------";
input bool EnableSinalMovingAverage = true;        //Enable Sinal  Moving Average
input ENUM_TIMEFRAMES InpMaFrame = PERIOD_H4;      // Moving Average TimeFrame
input int InpMaPeriod = 58;                        // Moving Average Period
input ENUM_MA_METHOD InpMaMethod = MODE_EMA;       // Moving Average Method
input ENUM_APPLIED_PRICE InpMaPrice = PRICE_CLOSE; // Moving Average Price
input int InpMaShift = 0;                          // Moving Average Shift

//-----------------------------------------------
int DivSinalMA()
{
    if (!EnableSinalMovingAverage)
        return (0);
    else
        return (1);
}

int GetSinalMA()
{
    if (!EnableSinalMovingAverage)
        return (0);
    if (iClose(NULL, 0, 0) > iMA(NULL, InpMaFrame, InpMaPeriod, 0, InpMaMethod, InpMaPrice, InpMaShift))
        return (1);
    if (iClose(NULL, 0, 0) < iMA(NULL, InpMaFrame, InpMaPeriod, 0, InpMaMethod, InpMaPrice, InpMaShift))
        return (-1);
    return (0);
}