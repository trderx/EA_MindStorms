//             P L E A S E   -   D O    N O T    D E L E T E    A N Y T H I N G ! ! !
// -------------------------------------------------------------------------------------------------
//                                   MACH2_MindStorms v1.01
//
//                       				  	  by Rodolfo
//                             rodolfo.leonardo@gmail.com
//
//--------------------------------------------------------------------------------------------------
//   THIS EA IS 100 % FREE OPENSOURCE, WHICH MEANS THAT IT'S NOT A COMMERCIAL PRODUCT
// -------------------------------------------------------------------------------------------------

#property copyright " MACH2_MindStorms_v1.01"
#property link "rodolfo.leonardo@gmail.com"
#property version "1.01"
#property description "MACH2_MindStorms_v1"
#property description "Strategy: When the signal is buy motor 1 MACHx starts, when the signal is sold the motor 2 MACHx starts"
#property description "This EA is 100% FREE OpenSource"
#property description "Coder: rodolfo.leonardo@gmail.com "
#property strict

extern string Version__ = "-----------------------------------------------------------------";
extern string vg_versao = "            MACH2_MindStorms_v1 2018-03-12  DEVELOPER EDITION             ";
extern string Version____ = "-----------------------------------------------------------------";

#include "EAframework.mqh"
#include "macx.mqh"
#include "macx2.mqh"
#include "TrailingStop.mqh"

#include "SinalMA.mqh"
#include "SinalHILO.mqh"
//#include "SinalBB.mqh"
//#include "SinalRSI.mqh"

#include "FFCallNews.mqh"
#include "FilterTime.mqh"
#include "FilterVolatility.mqh"
#include "FilterMarginLevel.mqh"
#include "FilterStopOut.mqh"

double vg_Spread = 0;
string vg_filters_on = "";
string vg_initpainel = false;
//+------------------------------------------------------------------+
//|  input parameters                                                |
//+------------------------------------------------------------------+

extern string Filter_Spread__ = "----------------------------Filter Max Spread----------------";
input int InpMaxvg_Spread = 24; // Max Spread

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
    Comment(vg_filters_on);
    vg_filters_on = "";
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

    //FILTER Volatility
    if (FilterVolatility())
    {
        vg_filters_on += "Filter Volatility ON \n";

        return;
    }

    //FILTER MarginLevel
    if (FilterMargiLevel())
    {
        vg_filters_on += "Filter MarginLevel ON \n";

        return;
    }

    if (FilterStopOut(MACH_CurrentPairProfit, MACH_MagicNumber) || FilterStopOut(MACH2_CurrentPairProfit, MACH2_MagicNumber))
        return;

    int Sinal = (GetSinalMA() + GetSinalHILO()) / (DivSinalMA() + DivSinalHILO());
    double lotsinitMACH2 = 0.01;
    double lotsinitMACH1 = 0.01;
    if (Sinal == -1)
    {

        // CloseThisSymbolAll(MACH2_MagicNumber,0);
        if (MACH2_equityrisk)
            MACHx(-1, true, MACH2_l_lastlot*0.2);
        else
            MACHx(-1, false, lotsinitMACH1);
    }

    if (Sinal == 1)
    {

        //CloseThisSymbolAll(MACH_MagicNumber,0);
        if (MACH_equityrisk)
            MACH2x(1, true, MACH_l_lastlot*0.2);
        else
            MACH2x(1, false, lotsinitMACH2);
    }

    // SE TrailingStop  ENABLE
    if (InpUseTrailingStop)
        TrailingAlls(InpTrailStart, InpTrailStep, MACH_AveragePrice, MACH_MagicNumber);
    if (InpUseTrailingStop)
        TrailingAlls(InpTrailStart, InpTrailStep, MACH2_AveragePrice, MACH2_MagicNumber);
}