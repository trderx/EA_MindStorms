
extern string SINAL__ = "------------------------- SINAL NONLANG-------------------------";
input bool EnableSinalNONLANG = true;         //Enable Sinal  NONLANG (Requer NonLagMA_v7.1)
input ENUM_TIMEFRAMES InpNLFrame = PERIOD_H1; // Moving Average TimeFrame
extern int Price = 0;                         //Apply to Price(0-Close;1-Open;2-High;3-Low;4-Median price;5-Typical price;6-Weighted Close)
extern int Length = 4;                        //Period of NonLagMA
extern int Displace = 0;                      //DispLace or Shift
extern double PctFilter = 0;                  //Dynamic filter in decimal
extern int Color = 1;                         //Switch of Color mode (1-color)
extern int ColorBarBack = 1;                  //Bar back for color mode
extern double Deviation = 0;                  //Up/down deviation
extern int AlertMode = 1;                     //Sound Alert switch (0-off,1-on)
extern int WarningMode = 1;                   //Sound Warning switch(0-off,1-on)

//-----------------------------------------------
int DivSinalNONLANG()
{
    if (!EnableSinalNONLANG)
        return (0);
    else
        return (1);
}

int GetSinalNONLANG()
{
    if (!EnableSinalNONLANG)
        return (0);

    return ((int)iCustom(NULL, InpNLFrame, "NonLagMA_v7.1", Price, Length, Displace, PctFilter,
                         Color, ColorBarBack, Deviation, AlertMode, WarningMode, 3, 1));
}