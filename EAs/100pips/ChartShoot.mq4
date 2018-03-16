#property description "The Expert Advisor demonstrates how to create a screenshots of the current chart"

//--- input parameters
int tmp =0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- Disable chart autoscroll
   ChartSetInteger(0,CHART_AUTOSCROLL,true);
//--- Set the shift of the right edge of the chart
   ChartSetInteger(0,CHART_SHIFT,true);
//--- Show a candlestick chart
   ChartSetInteger(0,CHART_MODE,CHART_CANDLES);
//---
   Print("Preparation of the Expert Advisor is completed");
  }
  
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   
   if(Time[0] != tmp)
     {
      tmp = Time[0];      
      //Comment("Breakermind.com,\n Week open: " + iOpen(NULL,PERIOD_W1,0) + "\n Month open: " + iOpen(NULL,PERIOD_MN1,0));
      //--- Prepare a text to show on the chart and a file name
      string name= "chart\\"+Symbol()+ "-" + Period()+".gif";      
      //--- Save the chart screenshot in a file in the terminal_directory\MQL4\Files\
      if(ChartScreenShot(0,name,1366,768,ALIGN_LEFT))Print("We've saved the screenshot ",name);

      ShowLabel();
      datetime LineTime;

         ObjectDelete("V-Line");
         ObjectDelete("V-Line1");
         
         LineTime = iTime( NULL, PERIOD_W1,0);
         ObjectCreate("V-Line",OBJ_VLINE,0,LineTime,0);
         ObjectSet("V-Line",OBJPROP_COLOR,Green);
         ObjectSet("V-Line",OBJPROP_STYLE,0);
         ObjectSet("V-Line",OBJPROP_WIDTH,3);
         ObjectSet("V-Line",OBJPROP_BACK,true);
         
         LineTime = iTime( NULL, PERIOD_MN1,0);
         ObjectCreate("V-Line1",OBJ_VLINE,0,LineTime,0);
         ObjectSet("V-Line1",OBJPROP_COLOR,Red);
         ObjectSet("V-Line1",OBJPROP_STYLE,0);
         ObjectSet("V-Line1",OBJPROP_WIDTH,3);
         ObjectSet("V-Line1",OBJPROP_BACK,true);

     }
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
  }
  
  void ShowLabel()
{
  string LABEL = "week";
  if(!ObjectCreate(LABEL, OBJ_LABEL, 0, 0, 0))
   // Print("Error: can't create label object! ", ErrorDescription(GetLastError()));
  ObjectSet(LABEL, OBJPROP_CORNER, 2);
  ObjectSet(LABEL, OBJPROP_XDISTANCE, 4);
  ObjectSet(LABEL, OBJPROP_YDISTANCE, 4);
  ObjectSetText(LABEL, "Breakermind.com charts, Week open: " + iOpen(NULL,PERIOD_W1,0) + " Month open: " + iOpen(NULL,PERIOD_MN1,0), 11, "Tahoma", Red);
}
