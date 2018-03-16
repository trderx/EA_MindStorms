//+------------------------------------------------------------------+
//|                                        cm_orders_profit_info.mq4 |
//|                                Copyright 2014, cmillion@narod.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, cmillion@narod.ru"
#property link      "cmillion@narod.ru"
#property version   "1.00"
#property strict
#property indicator_chart_window
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   for(int j=0; j<OrdersTotal(); j++)
     {
      if(OrderSelect(j,SELECT_BY_POS))
        {
         if(Symbol()==OrderSymbol())
           {
            string name=IntegerToString(OrderTicket());
            ObjectDelete(0,name);
            TextCreate(0,name,0,Time[140],OrderOpenPrice(),StringConcatenate("",DoubleToStr(OrderSwap(),2)), "Arial",8,Color(OrderProfit()<0,clrPink,clrAqua));//"Magic = ",OrderMagicNumber(),"    Profit = ",DoubleToStr(OrderProfit(),2), 
           }
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TextCreate(const long              chart_ID=0,               // ID графика
                const string            name="Text",              // имя объекта
                const int               sub_window=0,             // номер подокна
                datetime                time=0,                   // время точки привязки
                double                  price=0,                  // цена точки привязки
                const string            text="Text",              // сам текст
                const string            font="Arial",             // шрифт
                const int               font_size=10,             // размер шрифта
                const color             clr=clrRosyBrown,               // цвет
                const double            angle=0.0,                // наклон текста
                const ENUM_ANCHOR_POINT anchor=ANCHOR_LOWER,      // способ привязки
                const bool              back=false,               // на заднем плане
                const bool              selection=true,          // выделить для перемещений
                const bool              hidden=false,              // скрыт в списке объектов
                const long              z_order=0)                // приоритет на нажатие мышью
  {
   ResetLastError();
   if(!ObjectCreate(chart_ID,name,OBJ_TEXT,sub_window,time,price))
     {
      Print(__FUNCTION__,
            ": не удалось создать объект \"Текст\"! Код ошибки = ",GetLastError());
      return(false);
     }
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
color Color(bool P,color a,color b)
  {
   if(P) return(a);
   else return(b);
  }
//------------------------------------------------------------------
