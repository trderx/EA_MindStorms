

extern string _BB1_ = "-----------------------------Bollinger Bands--------------------";
input bool EnableSinalBB = false;             //Enable Sinal  Bollinger Bands
input bool InpBBFilterInverter   = false;     // If True Invert Filter
input ENUM_TIMEFRAMES InpBBFrame = PERIOD_M5; // Bollinger Bands TimeFrame
input int InpperiodBB = 10;                   //averaging period
input int InpdeviationBB = 2;                 // standard deviations
input int Inpbands_shiftBB = 0;               // bands shift
extern int InppriceBBUP = PRICE_CLOSE;        //price BB UP
extern int InppriceBBDN = PRICE_CLOSE;        //price BB DOWN
input int InpCheckBarsBB = 10;                //Check Bars BB

int CloseDown = 0, CloseUp = 0;
double BandsUP, BandsDown, BandsDiff;

//-----------------------------------------------
int DivSinalBB()
{
  if (!EnableSinalBB)
    return (0);
  else
    return (1);
}

int GetSinalBB()
{
  int vRet = 0;
  
  if (!EnableSinalBB)
    return (vRet);

 

  CloseDown = 0;
  CloseUp = 0;

  int j;
  int ii = 1;
  for (j = ii; j <= ii + InpCheckBarsBB; j++)
  {
    BandsUP = iBands(NULL, InpBBFrame, InpperiodBB, InpdeviationBB, Inpbands_shiftBB, InppriceBBUP, MODE_UPPER, j);
    BandsDown = iBands(NULL, InpBBFrame, InpperiodBB, InpdeviationBB, Inpbands_shiftBB, InppriceBBDN, MODE_LOWER, j);
    BandsDiff = BandsUP - BandsDown;

    if (Close[j] >= BandsUP)
    {
      CloseDown++;
      break;
    }
    if (Close[j] <= BandsDown)
    {
      CloseUp++;
      break;
    }
  }
  if (CloseDown > 0)
    vRet= -1;
  if (CloseUp > 0)
    vRet =1;

  if(InpBBFilterInverter) return vRet = vRet*-1;

  return vRet;
}