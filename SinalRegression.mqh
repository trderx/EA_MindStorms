
extern string SINAL__ = "------------------------- SINAL Regression-------------------------";
input bool EnableSinalRL = true;         //Enable Sinal  Regression (Requer Regression)
input ENUM_TIMEFRAMES InpRLFrame = PERIOD_CURRENT; // Regression TimeFrame
extern int degree = 3;
extern double kstd = 2.0;
extern int bars = 2000;
extern int shift = 0;


//-----------------------------------------------
int DivSinalRL()
{
    if (!EnableSinalRL)
        return (0);
    else
        return (1);
}

int GetSinalRL()
{
    int vRet = 0;

    if (!EnableSinalRL)
        return (0);

     vRet = (int)iCustom(NULL, InpRLFrame, "Regression", degree,kstd, bars, shift, 3, 1);
  // Comment("GetSinalRL : "+ vRet);
    


    return (vRet);

}