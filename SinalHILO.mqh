extern string HILOConfig__ = "-----------------------------HILO--------------------";
input bool EnableSinalHILO = true;              //Enable Sinal  HILO
input bool InpHILOFilterInverter = false;       // If True Invert Filter
input ENUM_TIMEFRAMES InpHILOFrame = PERIOD_CURRENT; // HILO TimeFrame
input int InpHILOPeriod = 3;                    // HILO Period
input ENUM_MA_METHOD InpHILOMethod = MODE_EMA;  // HILO Method
input int InpHILOShift = 0;                     // HILO Shift

double indicator_low;
double indicator_high;
double diff_highlow;
bool isbidgreaterthanima;

//-----------------------------------------------
int DivSinalHILO()
{
    if (!EnableSinalHILO)
        return (0);
    else
        return (1);
}

int GetSinalHILO()
{
    int vRet = 0;

    if (!EnableSinalHILO)
        vRet;

    indicator_low = iMA(NULL, InpHILOFrame, InpHILOPeriod, 0, InpHILOMethod, PRICE_LOW, InpHILOShift);
    indicator_high = iMA(NULL, InpHILOFrame, InpHILOPeriod, 0, InpHILOMethod, PRICE_HIGH, InpHILOShift);

    diff_highlow = indicator_high - indicator_low;
    isbidgreaterthanima = Bid >= indicator_low + diff_highlow / 2.0;  	

    if(Bid < indicator_low) vRet = -1;
    else
         if (Bid > indicator_high) vRet = 1;

    if (InpHILOFilterInverter)
        vRet = vRet * -1;

    return vRet;
}