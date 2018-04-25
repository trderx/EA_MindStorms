extern string StochConfig__ = "-----------------------------Stoch Sinal -------------------------------";
input bool EnableSinalStoch = true;              //Enable Sinal  Stoch
input bool InpStochFilterInverter = false;       // If True Invert Filter
input ENUM_TIMEFRAMES InpStochFrame = PERIOD_H1; // Stoch TimeFrame
input int          InpStochperiodK              = 16; // Stoch. %K period
input int          InpStochperiodD              = 1;  // Stoch. %D period
input int          InpStochslowing              = 6;  // Stoch. Slowing
input int          InpStochlowLevel             = 20; // overbought zone
input int          InpStochhighLevel            = 80; // overselling zone

//-----------------------------------------------
int DivSinalStoch()
{
    if (!EnableSinalStoch)
        return (0);
    else
        return (1);
}


int GetSinalStoch()
{
    int vRet = 0;

    if (!EnableSinalStoch)
        vRet;

   double stoch1 = iStochastic(NULL, 0, InpStochperiodK, InpStochperiodD, InpStochslowing, MODE_EMA, 0, MODE_MAIN, 1);
   double stoch2 = iStochastic(NULL, 0, InpStochperiodK, InpStochperiodD, InpStochslowing, MODE_EMA, 0, MODE_MAIN, 2);

   if (stoch1 > InpStochlowLevel && stoch2 < InpStochlowLevel)vRet =1;
      
   if (stoch1 < InpStochhighLevel && stoch2 > InpStochhighLevel)vRet =-1;

  if (InpStochFilterInverter)
        vRet = vRet * -1;

  return vRet;
}
