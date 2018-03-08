extern string RSIConfig__ =                                 "-----------------------------RSI-------------------------------";
input bool EnableSinalRSI    = true;                                         //Enable Sinal  RSI
input ENUM_TIMEFRAMES        InpRSIFrame= PERIOD_H1;                                    // RSI TimeFrame
extern double InpRsiMinimum = 30.0;                                                     //Rsi Minimum
extern double InpRsiMaximum = 70.0;                                                     //Rsi Maximum

//-----------------------------------------------
int DivSinalRSI()
{
    if(!EnableSinalRSI) return (0);
    else return (1);
}


int GetSinalRSI()
{
     if(!EnableSinalRSI) return (0);

   double PrevCl = iClose(Symbol(), 0, 2);
    double CurrCl= iClose(Symbol(), 0, 1);
    
    if (PrevCl > CurrCl && iRSI(NULL, PERIOD_H1, 14, PRICE_CLOSE, 1) > InpRsiMinimum) return(1) ;
    if (PrevCl < CurrCl && iRSI(NULL, PERIOD_H1, 14, PRICE_CLOSE, 1) < InpRsiMaximum) return (-1);

    return(0);
}