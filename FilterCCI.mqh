extern string _BB1_ = "-----------------------------Filter CCI --------------------";
input ENUM_TIMEFRAMES InpCCIFilterFrame = PERIOD_M15; //  Filter CCI TimeFrame
input bool InpCCIFilterInverter   = false;             // If True Invert Filter
extern double InpDrop = 5000;                         // Drop to Filter CCI
extern int InpCCIFilterPeriod = 55;                   // Drop to Filter CCI
//-----------------------------------------------
bool GetFilterCCI(int TypeTrade)
{
  bool vRet = false;

  if ((iCCI(NULL, InpCCIFilterFrame, InpCCIFilterPeriod, 0, 0) > InpDrop && TypeTrade == -1) || (iCCI(NULL, InpCCIFilterFrame, InpCCIFilterPeriod, 0, 0) < (-InpDrop) && TypeTrade == 1))
    vRet =  true;

  if(InpCCIFilterInverter)vRet = !vRet;
  return vRet;
}