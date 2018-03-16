//             P L E A S E   -   D O    N O T    D E L E T E    A N Y T H I N G ! ! ! 
// -------------------------------------------------------------------------------------------------
//                                   EA_MindStorms v1.01 
//
//                       				  	  by Rodolfo
//                             rodolfo.leonardo@gmail.com
//
//--------------------------------------------------------------------------------------------------
//   THIS EA IS 100 % FREE OPENSOURCE, WHICH MEANS THAT IT'S NOT A COMMERCIAL PRODUCT
// -------------------------------------------------------------------------------------------------

#property copyright " EA_MindStorms_v1.01"
#property link "rodolfo.leonardo@gmail.com"
#property version "1.01"
#property description "MACH3_MindStorms_v1"
#property description "This EA is 100% FREE "
#property description "Strategy: When engine 1 MACHx triggers level 10, engine 2 MACHx starts when engine 2 MACHx triggers level 10, engine 3 MACHx starts"
#property description "Coder: rodolfo.leonardo@gmail.com "
#property strict

extern string Version__ = "-----------------------------------------------------------------";
extern string vg_versao = "           MACH3_MindStorms_v1 2018-03-07  DEVELOPER EDITION             ";
extern string Version____ = "-----------------------------------------------------------------";
extern string      __chartTemplate              = " ------- Chart template ------------";
extern string      InpChartTemplate                = "EA_MindStorm.tpl";

string vg_Debug = "";
double vg_Spread = 0;
string vg_filters_on = "";
string vg_initpainel = false;

#include "EAframework.mqh"
#include "macx.mqh"
#include "macx2.mqh"
#include "macx3.mqh"
#include "TrailingStop.mqh"

#include "SinalMA.mqh"
#include "SinalBB.mqh"
#include "SinalRSI.mqh"
#include "SinalNONLANG.mqh"
#include "SinalRegression.mqh"

#include "FFCallNews.mqh"
#include "FilterTime.mqh"
#include "FilterStopOut.mqh"



//+------------------------------------------------------------------+
//|  input parameters                                                |
//+------------------------------------------------------------------+

extern string Filter_Spread__ = "----------------------------Filter Max Spread----------------";
input int InpMaxvg_Spread = 24; // Max Spread

void OnStart()
  {
//--- example of applying template, located in \MQL4\Files
   if(FileIsExist(InpChartTemplate))
     {
      Print("The file "+ InpChartTemplate +" found in \Files'");
      //--- apply template
      if(ChartApplyTemplate(0,"\\Files\\"+ InpChartTemplate))
        {
         Print("The template '"+ InpChartTemplate +"' applied successfully");
        }
      else
         Print("Failed to apply '"+ InpChartTemplate +"', error code ",GetLastError());
     }
   else
     {
      Print("File '"+ InpChartTemplate +"' not found in "
            +TerminalInfoString(TERMINAL_PATH)+"\\MQL4\\Files");
     }
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    
    vg_Spread = MarketInfo(Symbol(), MODE_SPREAD) * Point;

    vg_filters_on = "";
    vg_initpainel = true;

    printf(vg_versao + " - INIT");

    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    vg_Debug = "";

    PainelUPER(vg_versao);
    RefreshRates();

    //FILTER SPREAD
    if (vg_Spread > InpMaxvg_Spread)
    {
        vg_filters_on += "Filter InpMaxvg_Spread ON \n";
        return;
    }

    //FILTER NEWS
    if (InpUseFFCall)
    {
        NewsHandling();

        if (vg_news_time)
        {
            vg_filters_on += "Filter News ON \n";
            return;
        }
    }

    //FILTER DATETIME
    if (TimeFilter())
    {
        vg_filters_on += "Filter TimeFilter ON \n";

        return;
    }
    
    if (FilterStopOut(MACH_CurrentPairProfit, MACH_MagicNumber) || FilterStopOut(MACH2_CurrentPairProfit, MACH2_MagicNumber))
        return;

    int Sinal = (GetSinalMA() + GetSinalBB() + GetSinalRSI() + GetSinalNONLANG()) / (DivSinalMA() + DivSinalBB() + DivSinalRSI() + DivSinalNONLANG());

    MACHx(Sinal, false, 0.01);

    if (MACH_vg_cnt > 5 || MACH2_NumOfTrades > 0)
    {

        MACH2x(Sinal, false, MACH_sumLots);
    }

    if (MACH2_vg_cnt > 5 || MACH3_NumOfTrades > 0)
    {

        MACH3x(Sinal, false, MACH2_sumLots);
    }

    // SE TrailingStop  ENABLE
    if (InpUseTrailingStop)
        TrailingAlls(InpTrailStart, InpTrailStep, MACH_AveragePrice, MACH_MagicNumber);
    if (InpUseTrailingStop)
        TrailingAlls(InpTrailStart, InpTrailStep, MACH2_AveragePrice, MACH2_MagicNumber);
}