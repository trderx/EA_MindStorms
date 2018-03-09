extern string _BB1_ = "-----------------------------Filter CCI --------------------";
input ENUM_TIMEFRAMES InpCCIFilterFrame = PERIOD_M15; //  Filter CCI TimeFrame
extern double InpDrop = 5000;                         // Drop to Filter CCI
extern int InpCCIFilterPeriod = 55;                   // Drop to Filter CCI
//-----------------------------------------------
int GetFilterCCI(int TypeTrade)
{
  if ((iCCI(NULL, InpCCIFilterFrame, InpCCIFilterPeriod, 0, 0) > InpDrop && TypeTrade == -1) || (iCCI(NULL, InpCCIFilterFrame, InpCCIFilterPeriod, 0, 0) < (-InpDrop) && TypeTrade == 1))
    return (1) else return (0)
}