//+-----------------------------------------------------------------+
//|                                      EA_MindStorms_v1.01.mq4 |
//|                                      rodolfo.leonardo@gmail.com. |
//+------------------------------------------------------------------+
#property copyright " EA_MindStorms_v1.01"
#property link "rodolfo.leonardo@gmail.com"
#property version "1.01"
#property description "MACH3_MindStorms_v1"
#property description "This EA is 100% FREE "
#property description "Strategy: When engine 1 MACHx triggers level 2, engine 2 MACHx starts when engine 2 MACHx triggers level 2, engine 3 MACHx starts"
#property description "Coder: rodolfo.leonardo@gmail.com "
#property strict



extern string Version__ = "-----------------------------------------------------------------";
extern string vg_versao = "           MACH3_MindStorms_v1 2018-03-07  DEVELOPER EDITION             ";
extern string Version____ = "-----------------------------------------------------------------";

#include "EAframework.mqh"
#include "macx.mqh"
#include "macx2.mqh"
#include "macx3.mqh"
#include "TrailingStop.mqh"

#include "SinalMA.mqh"
//#include "SinalBB.mqh"
//#include "SinalRSI.mqh"

#include "FFCallNews.mqh"
#include "FilterTime.mqh"
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
    if (InpUtilizeTimeFilter && !TimeFilter())
    {
        vg_filters_on += "Filter TimeFilter ON \n";

        return;
    }
    if(FilterStopOut(MACH_CurrentPairProfit,MACH_MagicNumber)
     || FilterStopOut(MACH2_CurrentPairProfit,MACH2_MagicNumber)
    ) return;
   
    int SinalMA = GetSinalMA();

     MACHx(SinalMA, false, 0.01);


    if (MACH_orders_count > 2){
     
        MACH2x(SinalMA, false,0.01);
    }

     if (MACH2_orders_count > 2){
     
        MACH3x(SinalMA, false,0.01);
    }

    // SE TrailingStop  ENABLE
    if (InpUseTrailingStop)
        TrailingAlls(InpTrailStart, InpTrailStep, MACH_AveragePrice, MACH_MagicNumber);
    if (InpUseTrailingStop)
        TrailingAlls(InpTrailStart, InpTrailStep, MACH2_AveragePrice, MACH2_MagicNumber);

        
  

}