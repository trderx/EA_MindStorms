
extern string SINAL__ = "------------------------- SINAL Heiken Ashi Smoothed-------------------------";
input bool EnableSinalHASMA = false;             //Enable Sinal  Heiken Ashi Smoothed
input ENUM_TIMEFRAMES InpHASMAFrame = PERIOD_H1; // Heiken Ashi Smoothed TimeFrame
input bool InpHASMAFilterInverter = false;       // If True Invert Filter
input int InpHASMAPeriod = 30;                   // HASMA -Moving Average Period
input ENUM_MA_METHOD InpHASMAMethod = MODE_EMA;  // HASMA - Moving Average Method
input int InpHASMAShift = 0;                     // HASMA - Moving Average Shift

//-----------------------------------------------
int DivSinalHASMA()
{
    if (!EnableSinalHASMA)
        return (0);
    else
        return (1);
}

int GetSinalHASMA()
{
    double maOpen, maClose, maLow, maHigh;
    double haOpen, haHigh, haLow, haClose;

    int vRet = 0;

    if (!EnableSinalHASMA)
        return (0);

    maOpen = iMA(NULL, InpHASMAFrame, InpHASMAPeriod, 0, InpHASMAMethod, PRICE_OPEN, InpHASMAShift);
    maClose = iMA(NULL, InpHASMAFrame, InpHASMAPeriod, 0, InpHASMAMethod, PRICE_CLOSE, InpHASMAShift);
    maLow = iMA(NULL, InpHASMAFrame, InpHASMAPeriod, 0, InpHASMAMethod, PRICE_LOW, InpHASMAShift);
    maHigh = iMA(NULL, InpHASMAFrame, InpHASMAPeriod, 0, InpHASMAMethod, PRICE_HIGH, InpHASMAShift);

    //haOpen = (ExtMapBuffer5[InpHASMAShift + 1] + ExtMapBuffer6[InpHASMAShift + 1]) / 2;
    haClose = (maOpen + maHigh + maLow + maClose) / 4;
    //haHigh = MathMax(maHigh, MathMax(haOpen, haClose));
    //haLow = MathMin(maLow, MathMin(haOpen, haClose));
    
    if(Bid > haClose)vRet =1;
    if(Bid < haClose)vRet =-1;

    if(InpHASMAFilterInverter)vRet=vRet*-1;

    return (vRet);
}


int GetSinalHASMA2(ENUM_TIMEFRAMES InpHASMAFrame2)
{
    double maOpen, maClose, maLow, maHigh;
    double haOpen, haHigh, haLow, haClose;

    int vRet = 0;

    if (!EnableSinalHASMA)
        return (0);

    maOpen = iMA(NULL, InpHASMAFrame2, InpHASMAPeriod, 0, InpHASMAMethod, PRICE_OPEN, InpHASMAShift);
    maClose = iMA(NULL, InpHASMAFrame2, InpHASMAPeriod, 0, InpHASMAMethod, PRICE_CLOSE, InpHASMAShift);
    maLow = iMA(NULL, InpHASMAFrame2, InpHASMAPeriod, 0, InpHASMAMethod, PRICE_LOW, InpHASMAShift);
    maHigh = iMA(NULL, InpHASMAFrame2, InpHASMAPeriod, 0, InpHASMAMethod, PRICE_HIGH, InpHASMAShift);

    //haOpen = (ExtMapBuffer5[InpHASMAShift + 1] + ExtMapBuffer6[InpHASMAShift + 1]) / 2;
    haClose = (maOpen + maHigh + maLow + maClose) / 4;
    //haHigh = MathMax(maHigh, MathMax(haOpen, haClose));
    //haLow = MathMin(maLow, MathMin(haOpen, haClose));
    
    if(Bid > haClose)vRet =1;
    if(Bid < haClose)vRet =-1;

    if(InpHASMAFilterInverter)vRet=vRet*-1;

    return (vRet);
}
