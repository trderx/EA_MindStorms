
extern string NivelMAConfig__ = "-----------------------------Sinal Nivel MA --------------------";
input bool EnableSinalNivelMA = true;              //Enable Sinal  Nivel MA
input bool InpNivelMAFilterInverter = false;       // If True Invert Filter
input ENUM_TIMEFRAMES InpNivelMAFrame = PERIOD_CURRENT; // Nivel MA TimeFrame
input int InpNivelMAPeriod = 13;                    // Nivel MA Period
input ENUM_MA_METHOD InpNivelMAMethod = MODE_SMMA;  // Nivel MA Method
input int InpNivelMAShift = 0;                     // Nivel MA Shift


double NivelMAma_1=0;
double NivelMAma_2=0;

//-----------------------------------------------
int DivSinalNivelMA()
{
    if (!EnableSinalNivelMA)
        return (0);
    else
        return (1);
}

int GetSinalNivelMA()
{
    int vRet = 0;

    if (!EnableSinalNivelMA)
        vRet;

    NivelMAma_1=iMA(NULL,InpNivelMAFrame,InpNivelMAPeriod,InpNivelMAShift,InpNivelMAMethod,PRICE_MEDIAN,1);
    NivelMAma_2=iMA(NULL,InpNivelMAFrame,InpNivelMAPeriod,InpNivelMAShift,InpNivelMAMethod,PRICE_MEDIAN,5);



    if((NivelMAma_1-NivelMAma_2)>3*Point()) vRet = 1;
    else
         if ((NivelMAma_2-NivelMAma_1)>3*Point()) vRet = -1;

    if (InpNivelMAFilterInverter)
        vRet = vRet * -1;

    return vRet;
}
