extern string CloseCandleConfig__ = "-----------------------------CloseCandle Sinal -------------------------------";
input bool EnableSinalCloseCandle = true;              //Enable Sinal  Close Candle
input bool InpCloseCandleFilterInverter = false;       // If True Invert Filter
input ENUM_TIMEFRAMES InpCloseCandleFrame = PERIOD_H1; // Close Candle TimeFrame


//-----------------------------------------------
int DivSinalCloseCandle()
{
    if (!EnableSinalCloseCandle)
        return (0);
    else
        return (1);
}


int GetSinalCloseCandle()
{
    int vRet = 0;

    if (!EnableSinalCloseCandle)
        vRet;

   if(iClose(Symbol(),InpCloseCandleFrame,1) > iOpen(Symbol(),InpCloseCandleFrame,1) )vRet =1;
   if(iClose(Symbol(),InpCloseCandleFrame,1) < iOpen(Symbol(),InpCloseCandleFrame,1) ) vRet =-1;


  if (InpCloseCandleFilterInverter)
        vRet = vRet * -1;

  return vRet;
}
