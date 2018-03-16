//+------------------------------------------------------------------+
//| Magnified Market Price.mq4        ver1.5             by Habeeb   |
//+------------------------------------------------------------------+

#property indicator_chart_window

  extern bool   Show_the_Time = True;
  extern bool   Show_the_Price = True; 

  extern color  Price_Up_Color = LawnGreen;
  extern color  Price_Down_Color = Tomato;
  extern int    Price_X_Position = 10;
  extern int    Price_Y_Position = 10;
  extern int    Price_Size=20;
  double        Old_Price;
  
  
   extern int    Porcent_X_Position = 10;
  extern int    Porcent_Y_Position = 70;
  extern int    Porcent_Size=20;
  
  extern int    Symbol_X_Position = 10;
  extern int    Symbol_Y_Position = 40;
  extern int    Symbol_Size=20;
  

  extern int    Chart_Timezone = -5;
  extern color  Time_Color = Yellow;
  extern int    Time_Size=17;
  extern int    Time_X_Position = 10;
  extern int    Time_Y_Position = 10;
  
   extern int    Spread_Size=10;
  extern int    Spread_X_Position = 10;
  extern int    Spread_Y_Position = 100;

color  FontColor=Black;
int init()
  {
   return(0);
  }

int deinit()
  {
  ObjectDelete("Market_Price_Label");
  ObjectDelete("Time_Label");
  ObjectDelete("Porcent_Price_Label");
  ObjectDelete("Spread_Price_Label");
  ObjectDelete("Simbol_Price_Label");
  
  return(0);
  }

int start()
  {
if (Show_the_Price==true)
 {
   string Market_Price = DoubleToStr(Bid, Digits);
   
   ObjectCreate("Market_Price_Label", OBJ_LABEL, 0, 0, 0);
   
   if (Bid > Old_Price)
    ObjectSetText("Market_Price_Label", Market_Price, Price_Size, "Comic Sans MS", Price_Up_Color);
   if (Bid < Old_Price)
    ObjectSetText("Market_Price_Label", Market_Price, Price_Size, "Comic Sans MS", Price_Down_Color);
   Old_Price = Bid;

   ObjectSet("Market_Price_Label", OBJPROP_XDISTANCE, Price_X_Position);
   ObjectSet("Market_Price_Label", OBJPROP_YDISTANCE, Price_Y_Position);
    ObjectSet("Market_Price_Label", OBJPROP_CORNER, 1);
 }
   
  
      if (Bid > iClose(0,1440,1)) FontColor=LawnGreen;
      if (Bid < iClose(0,1440,1)) FontColor=Tomato;
    
     
   string Porcent_Price=DoubleToStr(((iClose(0,1440,0)/iClose(0,1440,1))-1)*100,3) +" %";
//----   
   ObjectCreate("Porcent_Price_Label", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("Porcent_Price_Label", Porcent_Price, Porcent_Size, "Arial", FontColor);
     ObjectSet("Porcent_Price_Label", OBJPROP_CORNER, 1);
   ObjectSet("Porcent_Price_Label", OBJPROP_XDISTANCE, Porcent_X_Position);
   ObjectSet("Porcent_Price_Label", OBJPROP_YDISTANCE, Porcent_Y_Position );
   
   
   
   string Symbol_Price = Symbol();
   
    ObjectCreate("Simbol_Price_Label", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("Simbol_Price_Label", Symbol_Price, Symbol_Size, "Arial", DeepSkyBlue);
     ObjectSet("Simbol_Price_Label", OBJPROP_CORNER, 1);
   ObjectSet("Simbol_Price_Label", OBJPROP_XDISTANCE, Symbol_X_Position);
   ObjectSet("Simbol_Price_Label", OBJPROP_YDISTANCE, Symbol_Y_Position  );
   
   
   string Spreead = "Spread : "+ (MarketInfo(Symbol(),MODE_SPREAD)) +" pips";
   ObjectCreate("Spread_Price_Label", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("Spread_Price_Label", Spreead, Spread_Size, "Arial", White);
     ObjectSet("Spread_Price_Label", OBJPROP_CORNER, 1);
   ObjectSet("Spread_Price_Label", OBJPROP_XDISTANCE, Spread_X_Position);
   ObjectSet("Spread_Price_Label", OBJPROP_YDISTANCE, Spread_Y_Position  );
//----------------------------------

if (Show_the_Time==true)
 {
   int MyHour = TimeHour(TimeCurrent());
   int MyMinute = TimeMinute(TimeCurrent());
   int MyDay = TimeDay(TimeCurrent());
   int MyMonth = TimeMonth(TimeCurrent());
   int MyYear = TimeYear(TimeCurrent());
   string MySemana = TimeDayOfWeek(TimeCurrent());
   
   if (MyMinute < 10)
    {
     string NewMinute = ("0" + MyMinute);
    }
   else  
   { 
    NewMinute = DoubleToStr(TimeMinute(TimeCurrent()),0);   
   }
   
   string NewHour = DoubleToStr(MyHour + Chart_Timezone, 0);
 
   ObjectCreate("Time_Label", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("Time_Label",  MyDay +"-"+MyMonth+"-"+  MyYear +" "+ NewHour + ":" + NewMinute, Time_Size,  "Comic Sans MS", Time_Color);
   
   ObjectSet("Time_Label", OBJPROP_XDISTANCE, Time_X_Position);
   ObjectSet("Time_Label", OBJPROP_YDISTANCE, Time_Y_Position);
  }
 }