extern string RSIConfig__ = "-----------------------------RSI-------------------------------";
input bool EnableSinalRSI = true;              //Enable Sinal  RSI
input bool InpRSIFilterInverter = false;       // If True Invert Filter
input ENUM_TIMEFRAMES InpRSIFrame = PERIOD_H1; // RSI TimeFrame
extern double InpRsiMinimum = 30.0;            //Rsi Minimum
extern double InpRsiMaximum = 70.0;            //Rsi Maximum

//-----------------------------------------------
int DivSinalRSI()
{
    if (!EnableSinalRSI)
        return (0);
    else
        return (1);
}

int GetSinalRSI()
{
    int vRet = 0;

    if (!EnableSinalRSI)
        vRet;

    double PrevCl = iClose(Symbol(), 0, 2);
    double CurrCl = iClose(Symbol(), 0, 1);

    if (PrevCl > CurrCl && iRSI(NULL, PERIOD_H1, 14, PRICE_CLOSE, 1) > InpRsiMinimum)
        vRet = 1;
    if (PrevCl < CurrCl && iRSI(NULL, PERIOD_H1, 14, PRICE_CLOSE, 1) < InpRsiMaximum)
        vRet = -1;
    if (InpRSIFilterInverter)
        vRet = vRet * -1;
    return vRet;
}