
extern string SINAL__ = "------------------------- SINAL Heiken Ashi Smoth-------------------------";
input bool EnableSinalHAS = true;         //Enable Sinal  Heiken Ashi Smoth (Requer Heiken Ashi Smoth)
input ENUM_TIMEFRAMES InpHASFrame = PERIOD_CURRENT; // Heiken Ashi Smoth TimeFrame
extern int degree = 3;
extern double kstd = 2.0;
extern int bars = 2000;
extern int shift = 0;


//-----------------------------------------------
int DivSinalHAS()
{
    if (!EnableSinalHAS)
        return (0);
    else
        return (1);
}

int GetSinalHAS()
{
    int vRet = 0;

    if (!EnableSinalHAS)
        return (0);

     vRet = (int)iCustom(NULL, InpHASFrame, "Regression", degree,kstd, bars, shift, 3, 1);
  // Comment("GetSinalRL : "+ vRet);
    


    return (vRet);

}