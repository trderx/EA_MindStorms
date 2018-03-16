#property copyright "fxstar.eu"
#property link      "https://fxstar.eu"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(6);
      
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
      
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---

      int isBuyOpen = 0;
      int isSellOpen = 0;
   
      for (int i = OrdersTotal()-1; i > 0; i--)
      {
         if ( OrderSelect(i, SELECT_BY_POS) )
         {
            if (OrderType() == OP_BUY)isBuyOpen = 1;
            if (OrderType() == OP_SELL)isSellOpen = 1;
         }     
      }
   
        int i = 100;
        double time = 0;
        int level =0;
        int level1 = 0; 
        int level66 = 0;
       
        Print("Next bar time ========= "+ time);
        for(i=1;i<300;i++)
        {

         double high  = High[i];
         double low   = Low[i];
         double open  = Open[i];
         double close = Close[i];
      
         //Print("Prev Bar Open " + DoubleToStr(open) );
         
         level66 = (int)(Ask * 100000/500000);
         level = level66 * 5;
         level1 = level+5;
         
         
         if( close < level || open < level || high < level || low < level && isBuyOpen == 0)
           {
            Alert("UP " + level1 + " DN " + level + " Ostatni level 500Pips " + level + " BUY Position ");
            Print("UP " + level1 + " DN " + level + " Ostatni level 500Pips " + level + " BUY Position ");
           }
           
         
         if( close > level1 || open > level1 || high > level1 || low > level1 && isSellOpen == 0)
           {
            Alert("UP " + level1 + " DN " + level + " Ostatni level 500Pips " + level1 + " SELL Position ");
            Print("UP " + level1 + " DN " + level + " Ostatni level 500Pips " + level1 + " SELL Position ");
         }
                      
        }
        
        
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
