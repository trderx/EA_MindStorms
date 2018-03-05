extern string RSIConfig__ =                                 "-----------------------------RSI-------------------------------";
input ENUM_TIMEFRAMES        InpRSIFrame= PERIOD_H1;                                    // RSI TimeFrame
extern double InpRsiMinimum = 30.0;                                                     //Rsi Minimum
extern double InpRsiMaximum = 70.0;                                                     //Rsi Maximum

//-----------------------------------------------
int GetSinalRSI()
{
   double PrevCl = iClose(Symbol(), 0, 2);
    double CurrCl= iClose(Symbol(), 0, 1);
    
    if (PrevCl > CurrCl && iRSI(NULL, PERIOD_H1, 14, PRICE_CLOSE, 1) > InpRsiMinimum) return(1) ;
    if (PrevCl < CurrCl && iRSI(NULL, PERIOD_H1, 14, PRICE_CLOSE, 1) < InpRsiMaximum) return (-1);

    return(0);
}