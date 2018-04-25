
extern string 2xMAConfig__ = "-----------------------------Sinal Nivel 2x MA --------------------";
input bool EnableSinal2xlMA = true;              //Enable Sinal  Nivel MA
input bool Inp2xlMAFilterInverter = false;       // If True Invert Filter
input ENUM_TIMEFRAMES Inp2xlMAFrame = PERIOD_CURRENT; // Nivel MA TimeFrame
input int Inp2xlMAPeriod = 5;                    // Nivel MA Period
input int Inp2xlMALonfPeriod =20;                    // Nivel MA Period
input ENUM_MA_METHOD Inp2xlMAMethod = MODE_SMMA;  // Nivel MA Method
input int Inp2xlMAShift = 0;                     // Nivel MA Shift


double 2xlMAma_1=0;
double 2xlMAma_2=0;
double 2xlMAma_3=0;
//-----------------------------------------------
int DivSinal2xlMA()
{
    if (!EnableSinal2xlMA)
        return (0);
    else
        return (1);
}

int GetSinal2xlMA()
{
    int vRet = 0;

    if (!EnableSinal2xlMA)
        vRet;

    2xlMAma_1=iMA(NULL,Inp2xlMAFrame,Inp2xlMAPeriod,Inp2xlMAShift,Inp2xlMAMethod,PRICE_CLOSE,0);
    2xlMAma_2=iMA(NULL,Inp2xlMAFrame,Inp2xlMAPeriod,Inp2xlMAShift,Inp2xlMAMethod,PRICE_CLOSE,1);
    2xlMAma_3=iMA(NULL,Inp2xlMAFrame,Inp2xlMALonfPeriod,Inp2xlMAShift,Inp2xlMAMethod,PRICE_CLOSE,1);


   ima_0 = iMA(Symbol(), InpIMAFrame, InpPeriodoIMAFxCore, 0, MODE_SMA, PRICE_CLOSE, 0);
      ima_8 = iMA(Symbol(), InpIMAFrame, InpPeriodoIMAFxCore, 0, MODE_SMA, PRICE_CLOSE, 1);
      ima_16 = iMA(Symbol(), InpIMAFrame, InpPeriodoLongIMAFxCore, 0, MODE_SMA, PRICE_CLOSE, 1);


      if (2xlMAma_1 > 2xlMAma_2 && 2xlMAma_2 > 2xlMAma_3) vRet = 1;
      else if (!(2xlMAma_1 < 2xlMAma_2 && 2xlMAma_2 < 2xlMAma_3)) vRet = 0;
      else vRet = -1;

    if (Inp2xlMAFilterInverter)
        vRet = vRet * -1;

    return vRet;

}
