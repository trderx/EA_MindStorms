//+------------------------------------------------------------------+
//|                                Copyright 2014, cmillion@narod.ru |
//|                                               http://cmillion.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, cmillion@narod.ru"
#property link      "http://cmillion.ru"
#property version   "2.00"
#property strict
#property description "Советник для ручной торговли"
#property description "Помогает выставлять ордера и сопровождать сделки"

 int     StopLoss_Buy      = 0,         //стоплосс
         TakeProfit_Buy    = 0,          //тейкпрофит
         TrailingStop_Buy  = 0,          //трейлингстоп, если 0, то нет трейлинга
         NoLoss_Buy        = 0,          //перевод в безубыток, если 0, то нет перевода в безубыток
         StopLoss_Sell     = 0,         //стоплосс
         TakeProfit_Sell   = 0,          //тейкпрофит
         TrailingStop_Sell = 0,          //трейлингстоп, если 0, то нет трейлинга
         NoLoss_Sell       = 0;          //перевод в безубыток, если 0, то нет перевода в безубыток

input int      TrailingStep      = 1,           //шаг трала
               TrailingStart     = 0;           //минимальная прибыль с которой стартует тралл
               
extern double  Lot               = 0.1;               //лот
input int      slippage          = 3;                 //проскальзывание
input int      delta             = 10;                //отступ от текущей цены до отложенного ордера 
input int      dpips             = 5;   //дискретность изменения стопов
input double   dlot              = 0.1; //дискретность изменения лота
input double   dpr               = 1;   //дискретность изменения %
input bool     confirmation      = true;   //подтверждение действий
extern bool    TradeNoLossBuy    = true;//стопы от уровня безубытка
extern bool    TradeNoLossSell   = true;//стопы от уровня безубытка
extern int     Magic             = 0;  //магик (если -1 то все магики)

input string   Font        = "Times New Roman"; // Шрифт
input int      Width       = 10;                // размер
extern int      TypeWind    = 1;                 // тип окна

extern int      TypeColor   = 0;                 // тип цветового оформления
input color    Color1     = clrBlack;          // цвет 
input color    Color2     = clrWhite;          // цвет 
input color    Color3     = clrBlue;           // цвет 
input color    Color4     = clrRed;            // цвет 
input color    Color5     = clrGreen;          // цвет 
input color    Color6     = clrLemonChiffon;   // цвет 
input color    Color7     = clrLightGray;      // цвет 
input color    Color8     = clrSnow;           // цвет 
input color    Color9     = clrGray;           // цвет 

extern bool    MoveWindow    = true;//перемещать окно 

long X=10;
long Y=10;


double StopLossB,TakeProfitB,TrailingStopB,NoLossB,StopLossS,TakeProfitS,TrailingStopS,NoLossS;
string InpName="cm-Trade System";
double bid,risk=1,cz=100;
int STOPLEVEL;
string AC,knTpB,knSlB,knTsB,knNlB,knTpS,knSlS,knTsS,knNlS,knTrNlB,knTrNlS;
color Color_1,Color_2,Color_3,Color_4,Color_5,Color_6,Color_7,Color_8,Color_9;
//+------------------------------------------------------------------+
void _color(int t)
{
   switch(t)
   {
   case 0:
      Color_1     = Color1;
      Color_2     = Color2;
      Color_3     = Color3;
      Color_4     = Color4;
      Color_5     = Color5;
      Color_6     = Color6;
      Color_7     = Color7;
      Color_8     = Color8;
      Color_9     = Color9;
      break;
   case 1:
      Color_1     = clrWhite; 
      Color_2     = clrBlack;  
      Color_3     = clrLime;   
      Color_4     = clrRed;    
      Color_5     = clrLime;   
      Color_6     = clrGray;   
      Color_7     = clrGray;   
      Color_8     = clrDarkGray;
      Color_9     = clrBlack;  
      break;
   case 2:
      Color_2     = clrBlack; 
      Color_1     = clrWhite;  
      Color_3     = clrLime;   
      Color_4     = clrRed;    
      Color_5     = clrLime;   
      Color_6     = clrSlateGray; 
      Color_7     = clrSlateGray;
      Color_8     = clrLightSteelBlue;
      Color_9     = clrBlack; 
      break;
   case 3:
      Color_2     = clrBlack;  
      Color_1     = clrWhite;  
      Color_3     = clrLime;   
      Color_4     = clrRed;    
      Color_5     = clrLime;   
      Color_6     = clrDarkGray;
      Color_7     = clrDarkGray;
      Color_8     = clrSilver;  
      Color_9     = clrBlack;
      break;
   default:
      Color_1     = clrWhite;  
      Color_2     = clrBlack;  
      Color_3     = clrLime;   
      Color_4     = clrRed;    
      Color_5     = clrLime;   
      Color_6     = clrDarkGray;
      Color_7     = clrDarkGray;
      Color_8     = clrSilver;  
      Color_9     = clrBlack;
      break;
   }
}
//+------------------------------------------------------------------+
int OnInit()
{
   _color(TypeColor);
   AC=" "+AccountCurrency();
   knTpB = StringConcatenate("kn TakeProfit B ",Symbol());
   knSlB = StringConcatenate("kn StopLoss B ",Symbol());
   knTsB = StringConcatenate("kn TrailingStop B ",Symbol());
   knNlB = StringConcatenate("kn NoLoss B ",Symbol());
   
   knTpS = StringConcatenate("kn TakeProfit S ",Symbol());
   knSlS = StringConcatenate("kn StopLoss S ",Symbol());
   knTsS = StringConcatenate("kn TrailingStop S ",Symbol());
   knNlS = StringConcatenate("kn NoLoss S ",Symbol());

   knTrNlB = StringConcatenate("kn Tr NoLoss B ",Symbol());
   knTrNlS = StringConcatenate("kn Tr NoLoss S ",Symbol());

   GV();
   
   RectLabelCreate(0,InpName,0,10,30,270,360,Color_2,Color_1,STYLE_SOLID,1,false,MoveWindow,true,0);
   Redr(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
   bid=Bid;Redraw();
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectDelete(0,InpName);
   Del();
   ObjectDelete(0,"kn min");
   ObjectDelete(0,"kn color");
   ObjectDelete(0,"Symbol");
   ObjectDelete(0,"_fon1_");
   ObjectDelete(0,"_fon2_");
   ObjectDelete(0,"NoLoss_NLb");
   ObjectDelete(0,"NoLoss_NLs");
   ObjectDelete(0,"NoLoss_NL");
}
//--------------------------------------------------------------------
void Del()
{
   ObjectDelete(0,"_fon3_");
   ObjectDelete(0,"_5_");
   ObjectDelete(0,"_6_");
   ObjectDelete(0,"_7_");
   ObjectDelete(0,"_8_");
   ObjectDelete(0,"_9_");
   ObjectDelete(0,"_10_");
   ObjectDelete(0,"_11_");
   ObjectDelete(0,"_12_");
   ObjectDelete(0,"_13_");
   ObjectDelete(0,"_14_");
   ObjectDelete(0,"_15_");
   ObjectDelete(0,"_16_");
   ObjectDelete(0,"_17_");
   ObjectDelete(0,"2");
   ObjectDelete(0,"3");
   ObjectDelete(0,"4");
   ObjectDelete(0,"5");
   ObjectDelete(0,"6");
   ObjectDelete(0,"7");
   ObjectDelete(0,"8");
   ObjectDelete(0,"9");
   ObjectDelete(0,"10");
   ObjectDelete(0,"11");
   ObjectDelete(0,"12");
   ObjectDelete(0,"kn Buy");
   ObjectDelete(0,"kn Sell");
   ObjectDelete(0,"kn BuyStop");
   ObjectDelete(0,"kn SellLimit");
   ObjectDelete(0,"kn BuyLimit");
   ObjectDelete(0,"kn SellStop");
   ObjectDelete(0,"kn Del BuyStop");
   ObjectDelete(0,"kn Del SellLimit");
   ObjectDelete(0,"kn Close Buy");
   ObjectDelete(0,"kn Close Sell");
   ObjectDelete(0,"kn Del BuyLimit");
   ObjectDelete(0,"kn Del SellStop");
   
   ObjectDelete(0,knTpB);
   ObjectDelete(0,knSlB);
   ObjectDelete(0,knTsB);
   ObjectDelete(0,knNlB);
   ObjectDelete(0,knTpS);
   ObjectDelete(0,knSlS);
   ObjectDelete(0,knTsS);
   ObjectDelete(0,knNlS);
   ObjectDelete(0,knTrNlB);
   ObjectDelete(0,knTrNlS);
   
   ObjectDelete(0,StringConcatenate(knTpB," up"));
   ObjectDelete(0,StringConcatenate(knSlB," up"));
   ObjectDelete(0,StringConcatenate(knTsB," up"));
   ObjectDelete(0,StringConcatenate(knNlB," up"));
   
   ObjectDelete(0,StringConcatenate(knTpS," up"));
   ObjectDelete(0,StringConcatenate(knSlS," up"));
   ObjectDelete(0,StringConcatenate(knTsS," up"));
   ObjectDelete(0,StringConcatenate(knNlS," up"));
   
   ObjectDelete(0,StringConcatenate(knTpB," dn"));
   ObjectDelete(0,StringConcatenate(knSlB," dn"));
   ObjectDelete(0,StringConcatenate(knTsB," dn"));
   ObjectDelete(0,StringConcatenate(knNlB," dn"));
   
   ObjectDelete(0,StringConcatenate(knTpS," dn"));
   ObjectDelete(0,StringConcatenate(knSlS," dn"));
   ObjectDelete(0,StringConcatenate(knTsS," dn"));
   ObjectDelete(0,StringConcatenate(knNlS," dn"));
   
   
   ObjectDelete(0,"lot_");
   ObjectDelete(0,"kn lot pr");
   ObjectDelete(0,"kn lot l");
   ObjectDelete(0,"kn lot up");
   ObjectDelete(0,"kn lot dn");
   
   ObjectDelete(0,"kn CZ1");
   ObjectDelete(0,"_CZ1_");
   ObjectDelete(0,"kn CZ");
   
   ObjectDelete(0,"kn cz up");
   ObjectDelete(0,"kn cz dn");
   
   ObjectDelete(0,"spread");
   ObjectDelete(0,"Profit");
   ObjectDelete(0,"_Profit");
   ObjectDelete(0,"Equity");
   ObjectDelete(0,"_Equity");
   ObjectDelete(0,"Balance");
   ObjectDelete(0,"_Balance");
}
//--------------------------------------------------------------------
int start()
{
   chekbuttom();

   return(0);
}
//--------------------------------------------------------------------
bool ButtonCreate(const long              chart_ID=0,               // ID графика
                  const string            name="Button",            // имя кнопки
                  const int               sub_window=0,             // номер подокна
                  const long               x=0,                     // координата по оси X
                  const long               y=0,                     // координата по оси y
                  const int               width=50,                 // ширина кнопки
                  const int               height=18,                // высота кнопки
                  const string            text="Button",            // текст
                  const string            font="Arial",             // шрифт
                  const int               font_size=10,             // размер шрифта
                  const color             clr=clrNONE,      //цвет текста
                  const color             clrON=clrNONE,    //цвет фона
                  const color             clrOFF=clrNONE,   //цвет фона
                  const bool              state=false)              // нажата/отжата
  {
   if (ObjectFind(chart_ID,name)==-1)
   {
      ObjectCreate(chart_ID,name,OBJ_BUTTON,sub_window,0,0);
      ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
      ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
      ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      //ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,ANCHOR_CENTER);
      ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
      ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,0);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,0);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,0);
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,1);
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,0);
      ObjectSetInteger(chart_ID,name,OBJPROP_STATE,state);
      ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,clrNONE);
   }
   color back_clr;
   if (ObjectGetInteger(chart_ID,name,OBJPROP_STATE)) back_clr=clrON; else back_clr=clrOFF;
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
   return(true);
}
//--------------------------------------------------------------------
bool RectLabelCreate(const long             chart_ID=0,               // ID графика
                     const string           name="RectLabel",         // имя метки
                     const int              sub_window=0,             // номер подокна
                     const long              x=0,                      // координата по оси X
                     const long              y=0,                      // координата по оси y
                     const int              width=50,                 // ширина
                     const int              height=18,                // высота
                     const color            back_clr=clrNONE,  // цвет фона
                     const color            clr=clrNONE,       //цвет плоской границы (Flat)
                     const ENUM_LINE_STYLE  style=STYLE_SOLID,        // стиль плоской границы
                     const int              line_width=1,             // толщина плоской границы
                     const bool             back=false,               // на заднем плане
                     const bool             selection=false,          // выделить для перемещений
                     const bool             hidden=true,              // скрыт в списке объектов
                     const long             z_order=0)                // приоритет на нажатие мышью
  {
   ResetLastError();
   if (ObjectFind(chart_ID,name)==-1)
   {
      ObjectCreate(chart_ID,name,OBJ_RECTANGLE_LABEL,sub_window,0,0);
      ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
      ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,line_width);
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
   }
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
   return(true);
}
//--------------------------------------------------------------------
bool LabelCreate(const long              chart_ID=0,               // ID графика
                 const string            name="Label",             // имя метки
                 const int               sub_window=0,             // номер подокна
                 const long              x=0,                      // координата по оси X
                 const long              y=0,                      // координата по оси y
                 const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // угол графика для привязки
                 const string            text="Label",             // текст
                 const string            font="Arial",             // шрифт
                 const int               font_size=10,             // размер шрифта
                 const color             clr=clrNONE,      
                 const double            angle=0.0,                // наклон текста
                 const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // способ привязки
                 const bool              back=false,               // на заднем плане
                 const bool              selection=false,          // выделить для перемещений
                 const bool              hidden=true,              // скрыт в списке объектов
                 const long              z_order=0)                // приоритет на нажатие мышью
{
   ResetLastError();
   if (ObjectFind(chart_ID,name)==-1)
   {
      if(!ObjectCreate(chart_ID,name,OBJ_LABEL,sub_window,0,0))
      {
         Print(__FUNCTION__,": не удалось создать текстовую метку! Код ошибки = ",GetLastError());
         return(false);
      }
      ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
      ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
      ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
      ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
      ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
   }
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
   return(true);
  }
//--------------------------------------------------------------------
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{

   if(id==CHARTEVENT_OBJECT_CLICK)
   {
      string clickedChartObject=sparam;
      if (clickedChartObject=="kn min")
      {
         PlaySound("Ok.wav");
         TypeWind++;
         if (TypeWind>2) TypeWind=0;
         Del();
      }
      if (clickedChartObject=="kn color")
      {
         PlaySound("Ok.wav");
         TypeColor++;
         if (TypeColor>4) TypeColor=0;
      }
      Comment(clickedChartObject);
      chekbuttom();
   }
}
//--------------------------------------------------------------------
bool SendOrder(int tip, double lot, double p)
{
   if (confirmation)
   {
      string txt;
      if (tip==OP_BUY) txt=StringConcatenate("Откыть позицию BUY ",DoubleToStr(lot,2)," лот по цене ",DoubleToStr(p,Digits)," ?");
      if (tip==OP_SELL) txt=StringConcatenate("Откыть позицию SELL ",DoubleToStr(lot,2)," лот по цене ",DoubleToStr(p,Digits)," ?");
      if (tip==OP_BUYSTOP) txt=StringConcatenate("Откыть ордер BUYSTOP ",DoubleToStr(lot,2)," лот по цене ",DoubleToStr(p,Digits)," ?");
      if (tip==OP_SELLSTOP) txt=StringConcatenate("Откыть ордер SELLSTOP ",DoubleToStr(lot,2)," лот по цене ",DoubleToStr(p,Digits)," ?");
      if (tip==OP_BUYLIMIT) txt=StringConcatenate("Откыть ордер BUYLIMIT ",DoubleToStr(lot,2)," лот по цене ",DoubleToStr(p,Digits)," ?");
      if (tip==OP_SELLLIMIT) txt=StringConcatenate("Откыть ордер SELLLIMIT ",DoubleToStr(lot,2)," лот по цене ",DoubleToStr(p,Digits)," ?");
      int ret=MessageBox(txt,"", MB_YESNO);
      if (ret==IDNO) return(1);
   }
   int nn;
   while(true)
   {
      RefreshRates();
      if (OrderSend(Symbol(),tip,lot,p,slippage,0,0,NULL,Magic,0,clrNONE)==-1)
      {
         Print("Order Send Error ",GetLastError()," Lot ",lot);
         Sleep(1000);
      }
      else return(1);
      nn++;
      if (nn>10) return(0);
   }
   return(0);
}
//--------------------------------------------------------------------
int Redraw()
{
   RefreshRates();
   double StLo,OSL,OTP,OOP,SL,TP;
   STOPLEVEL=StrToInteger(DoubleToStr(MarketInfo(Symbol(),MODE_STOPLEVEL),0));
   double stoplevel=STOPLEVEL*Point;
   int b=0,s=0,bs=0,ss=0,bl=0,sl=0,tip;
   double OL,LB=0,LS=0,ProfitB=0,ProfitS=0;
   
   StopLossB     = Kn(knSlB,StopLossB);
   TakeProfitB   = Kn(knTpB,TakeProfitB);
   NoLossB       = Kn(knNlB,NoLossB);
   TrailingStopB = Kn(knTsB,TrailingStopB);
   StopLossS     = Kn(knSlS,StopLossS);
   TakeProfitS   = Kn(knTpS,TakeProfitS);
   NoLossS       = Kn(knNlS,NoLossS);
   TrailingStopS = Kn(knTsS,TrailingStopS);

   bool TrNoLossB = Kn(knTrNlB,1)==1;
   bool TrNoLossS = Kn(knTrNlS,1)==1;
   
   int i,Ticket;

   double price_b=0,price_s=0;
   for (i=0; i<OrdersTotal(); i++)
   {    
      if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      { 
         if (OrderSymbol()==Symbol() && (Magic==-1 || Magic==OrderMagicNumber()))
         { 
            OSL = NormalizeDouble(OrderStopLoss(),Digits);
            OTP = NormalizeDouble(OrderTakeProfit(),Digits);
            OOP = NormalizeDouble(OrderOpenPrice(),Digits);
            Ticket=OrderTicket();
            SL=OSL;TP=OTP;
            tip = OrderType(); 
            OL = OrderLots();
            if (tip==OP_BUY)             
            {  
               b++; 
               LB+=OL;price_b+=(Bid-OOP)*OL+(OrderCommission()+OrderSwap())*Point;
               ProfitB+=OrderProfit()+OrderCommission()+OrderSwap();
               if (OSL==0 && Bid-NormalizeDouble(OOP - StopLossB   * Point,Digits)>=stoplevel && StopLossB!=0)
               {
                  SL = NormalizeDouble(OOP - StopLossB   * Point,Digits);
               } 
               if (StopLossB==0 && NoLossB==0 && TrailingStopB==0) SL=0;
               if (TakeProfitB==0) TP=0;
               if (!TrNoLossB)
               {
                  if (OTP==0 && NormalizeDouble(OOP + TakeProfitB * Point,Digits)-Ask>=stoplevel && TakeProfitB!=0)
                  {
                     TP = NormalizeDouble(OOP + TakeProfitB * Point,Digits);
                  } 
                  if (OSL<OOP && NoLossB!=0)
                  {
                     if (Bid-OOP >= NoLossB*Point && Bid-OOP >= stoplevel) SL = OOP;
                  }
                  if (TrailingStopB!=0)
                  {
                     StLo = NormalizeDouble(Bid - TrailingStopB*Point,Digits); 
                     if (StLo >= OOP+TrailingStart*Point && StLo > OSL+TrailingStep*Point && StLo <= NormalizeDouble(Bid - stoplevel,Digits)) SL = StLo;
                  }
               }
               if (SL != OSL || TP != OTP)
               {  
                  Comment("Модификация ордера ",Ticket," Buy, SL ",OSL,"->",SL,", TP ",OTP,"->",TP);
                  if (!OrderModify(Ticket,OOP,SL,TP,0,White)) Print("Error OrderModify ",GetLastError());
               }
            }                                         
            if (tip==OP_SELL)        
            {
               s++;
               LS+=OL;price_s+=(OOP-Ask)*OL+(OrderCommission()+OrderSwap())*Point;
               ProfitS+=OrderProfit()+OrderCommission()+OrderSwap();
               if (OSL==0 && NormalizeDouble(OOP + StopLossS   * Point,Digits)-Ask>=stoplevel && StopLossS!=0)
               {
                  SL = NormalizeDouble(OOP + StopLossS   * Point,Digits);
               }
               if (StopLossS==0 && NoLossS==0 && TrailingStopS==0) SL=0;
               if (TakeProfitS==0) TP=0;
               if (!TrNoLossS)
               {
                  if (OTP==0 && Bid-NormalizeDouble(OOP - TakeProfitS * Point,Digits)>=stoplevel && TakeProfitS!=0)
                  {
                     TP = NormalizeDouble(OOP - TakeProfitS * Point,Digits);
                  }
                  if ((OSL>OOP || OSL==0) && NoLossS!=0)
                  {
                     if (OOP-Ask >= NoLossS*Point && (OOP < OSL || OSL==0) && OOP-Ask >= stoplevel) SL = OOP;
                  }
                  if (TrailingStopS!=0)
                  {
                     StLo = NormalizeDouble(Ask + TrailingStopS*Point,Digits); 
                     if (StLo <= OOP-TrailingStart*Point && (StLo < OSL-TrailingStep*Point || OSL==0) && StLo >= NormalizeDouble(Ask + stoplevel,Digits)) SL = StLo;
                  }
               }
               if (SL != OSL || TP != OTP)
               {  
                  Comment("Модификация ордера ",Ticket," Sell, SL ",OSL,"->",SL,", TP ",OTP,"->",TP);
                  if (!OrderModify(Ticket,OOP,SL,TP,0,White)) Print("Error OrderModify ",GetLastError());
               }
            } 
            if (tip==OP_BUYSTOP)             
            {  
               bs++; 
            }                                         
            if (tip==OP_SELLLIMIT)        
            {
               sl++;
            } 
            if (tip==OP_BUYLIMIT)             
            {  
               bl++; 
            }                                         
            if (tip==OP_SELLSTOP)        
            {
               ss++;
            } 
         }
      }
   }
//---
   double NL=0,NLb=0,NLs=0;
   if(LB>0) NLb=Bid-price_b/LB;
   ARROW("NoLoss_NLb", NLb, 6, Color_3);
   if(LS>0) NLs=Ask+price_s/LS;
   ARROW("NoLoss_NLs", NLs, 6, Color_4);
   if(LB-LS>0) NL=Bid-(price_b+price_s)/(LB-LS);
   if(LB-LS<0) NL=Ask-(price_b+price_s)/(LB-LS);
   ARROW("NoLoss_NL", NL, 6, clrYellow);

//---
   if (TrNoLossB || TrNoLossS)
   {
      for (i=0; i<OrdersTotal(); i++)
      {    
         if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         { 
            if (OrderSymbol()==Symbol() && (Magic==-1 || Magic==OrderMagicNumber()))
            { 
               OSL = NormalizeDouble(OrderStopLoss(),Digits);
               OTP = NormalizeDouble(OrderTakeProfit(),Digits);
               OOP = NormalizeDouble(OrderOpenPrice(),Digits);
               Ticket=OrderTicket();
               SL=OSL;TP=OTP;
               tip = OrderType(); 
               OL = OrderLots();
               if (tip==OP_BUY && TrNoLossB)             
               {  
                  if (NormalizeDouble(NLb + TakeProfitB * Point,Digits)-Ask>=stoplevel && TakeProfitB!=0)
                  {
                     TP = NormalizeDouble(NLb + TakeProfitB * Point,Digits);
                  } 
                  if (OSL<OOP && NoLossB!=0)
                  {
                     if (Bid-NLb >= NoLossB*Point && Bid-NLb >= stoplevel) SL = NLb;
                  }
                  if (TrailingStopB!=0)
                  {
                     StLo = NormalizeDouble(Bid - TrailingStopB*Point,Digits); 
                     if (StLo >= NLb+TrailingStart*Point && StLo > OSL+TrailingStep*Point && StLo <= NormalizeDouble(Bid - stoplevel,Digits)) SL = StLo;
                  }
                  if (SL != OSL || TP != OTP)
                  {  
                     Comment("Модификация ордера ",Ticket," от безубытка Buy SL ",OSL,"->",SL,", TP ",OTP,"->",TP);
                     if (!OrderModify(Ticket,OOP,SL,TP,0,White)) Print("Error OrderModify ",GetLastError());
                  }
               }                                         
               if (tip==OP_SELL && TrNoLossS)        
               {
                  if (Bid-NormalizeDouble(NLs - TakeProfitS * Point,Digits)>=stoplevel && TakeProfitS!=0)
                  {
                     TP = NormalizeDouble(NLs - TakeProfitS * Point,Digits);
                  }
                  if ((OSL>NLs || OSL==0) && NoLossS!=0)
                  {
                     if (NLs-Ask >= NoLossS*Point && (NLs < OSL || OSL==0) && NLs-Ask >= stoplevel) SL = NLs;
                  }
                  if (TrailingStopS!=0)
                  {
                     StLo = NormalizeDouble(Ask + TrailingStopS*Point,Digits); 
                     if (StLo <= NLs-TrailingStart*Point && (StLo < OSL-TrailingStep*Point || OSL==0) && StLo >= NormalizeDouble(Ask + stoplevel,Digits)) SL = StLo;
                  }
                  if (SL != OSL || TP != OTP)
                  {  
                     Comment("Модификация ордера ",Ticket," от безубытка Sell SL ",OSL,"->",SL,", TP ",OTP,"->",TP);
                     if (!OrderModify(Ticket,OOP,SL,TP,0,White)) Print("Error OrderModify ",GetLastError());
                  }
               } 
            }
         }
      }
   }
   Redr(LB, LS, ProfitB, ProfitS, bs, ss, b, s, sl, bl);
   return(0);
}
//+------------------------------------------------------------------+
bool close(int tip)
{
   if (confirmation)
   {
      string txt="Закрыть все позиции ";
      if (tip==OP_BUY) txt=StringConcatenate(txt,"BUY ?");
      if (tip==OP_SELL) txt=StringConcatenate(txt,"SELL ?");
      int ret=MessageBox(txt,"", MB_YESNO);
      if (ret==IDNO) return(1);
   }
   bool error=true;
   int j,err,nn,OT;
   while(!IsStopped())
   {
      for (j = OrdersTotal()-1; j >= 0; j--)
      {
         if (OrderSelect(j, SELECT_BY_POS))
         {
            if (OrderSymbol() == Symbol() && (Magic==-1 || Magic==OrderMagicNumber()))
            {
               OT = OrderType();
               if (tip!=OT) continue;
               if (OT==OP_BUY) 
               {
                  error=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(Bid,Digits),3,Blue);
               }
               if (OT==OP_SELL) 
               {
                  error=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(Ask,Digits),3,Red);
               }
               if (!error) 
               {
                  err = GetLastError();
                  if (err<2) continue;
                  if (err==129) 
                  {
                     RefreshRates();
                     continue;
                  }
                  if (err==146) 
                  {
                     if (IsTradeContextBusy()) Sleep(2000);
                     continue;
                  }
                  Print("Error ",err," close order N ",OrderTicket(),"     ",TimeToStr(TimeCurrent(),TIME_SECONDS));
               }
            }
         }
      }
      int n=0;
      for (j = 0; j < OrdersTotal(); j++)
      {
         if (OrderSelect(j, SELECT_BY_POS))
         {
            if (OrderSymbol() == Symbol() && (Magic==-1 || Magic==OrderMagicNumber()))
            {
               OT = OrderType();
               if (tip!=OT) continue;
               if (OT==OP_BUY || OT==OP_SELL) n++;
            }
         }  
      }
      if (n==0) break;
      nn++;
      if (nn>10) 
      {
         return(0);
      }
      Sleep(1000);
      RefreshRates();
   }
   return(1);
}
//--------------------------------------------------------------------
bool Delete(int tip)
{
   if (confirmation)
   {
      string txt="Удалить ордера ";
      if (tip==OP_BUYSTOP)  txt=StringConcatenate(txt,"BUYSTOP ?");
      if (tip==OP_SELLSTOP) txt=StringConcatenate(txt,"SELLSTOP ?");
      if (tip==OP_BUYLIMIT)  txt=StringConcatenate(txt,"BUYLIMIT ?");
      if (tip==OP_SELLLIMIT) txt=StringConcatenate(txt,"SELLLIMIT ?");
      int ret=MessageBox(txt,"", MB_YESNO);
      if (ret==IDNO) return(1);
   }
   bool error=true;
   int OT;
      for (int j = OrdersTotal()-1; j >= 0; j--)
      {
         if (OrderSelect(j, SELECT_BY_POS))
         {
            if (OrderSymbol() == Symbol() && (Magic==-1 || Magic==OrderMagicNumber()))
            {
               OT = OrderType();
               if (tip!=OT || OT<2) continue;
               error=OrderDelete(OrderTicket());
            }
         }
      }
   return(1);
}
//--------------------------------------------------------------------
void chekbuttom()
{
   if (ObjectGetInteger(0,"kn Buy",OBJPROP_STATE))
   {
      if (SendOrder(OP_BUY,Lot,NormalizeDouble(Ask,Digits))) ObjectSetInteger(0,"kn Buy",OBJPROP_STATE,false);
   }
   if (ObjectGetInteger(0,"kn Sell",OBJPROP_STATE))
   {
      if (SendOrder(OP_SELL,Lot,NormalizeDouble(Bid,Digits))) ObjectSetInteger(0,"kn Sell",OBJPROP_STATE,false);
   }
   if (ObjectGetInteger(0,"kn BuyStop",OBJPROP_STATE))
   {
      if (SendOrder(OP_BUYSTOP,Lot,NormalizeDouble(Ask+delta*Point,Digits))) ObjectSetInteger(0,"kn BuyStop",OBJPROP_STATE,false);
   }
   if (ObjectGetInteger(0,"kn SellLimit",OBJPROP_STATE))
   {
      if (SendOrder(OP_SELLLIMIT,Lot,NormalizeDouble(Ask+delta*Point,Digits))) ObjectSetInteger(0,"kn SellLimit",OBJPROP_STATE,false);
   }
   if (ObjectGetInteger(0,"kn BuyLimit",OBJPROP_STATE))
   {
      if (SendOrder(OP_BUYLIMIT,Lot,NormalizeDouble(Bid-delta*Point,Digits))) ObjectSetInteger(0,"kn BuyLimit",OBJPROP_STATE,false);
   }
   if (ObjectGetInteger(0,"kn SellStop",OBJPROP_STATE))
   {
      if (SendOrder(OP_SELLSTOP,Lot,NormalizeDouble(Bid-delta*Point,Digits))) ObjectSetInteger(0,"kn SellStop",OBJPROP_STATE,false);
   }
   if (ObjectGetInteger(0,"kn Close Buy",OBJPROP_STATE))
   {
      close(OP_BUY);ObjectSetInteger(0,"kn Close Buy",OBJPROP_STATE,false);
   }
   if (ObjectGetInteger(0,"kn Close Sell",OBJPROP_STATE))
   {
      close(OP_SELL);ObjectSetInteger(0,"kn Close Sell",OBJPROP_STATE,false);
   }
   if (ObjectGetInteger(0,"kn Del BuyStop",OBJPROP_STATE))
   {
      Delete(OP_BUYSTOP);ObjectSetInteger(0,"kn Del BuyStop",OBJPROP_STATE,false);
   }
   if (ObjectGetInteger(0,"kn Del SellLimit",OBJPROP_STATE))
   {
      Delete(OP_SELLLIMIT);ObjectSetInteger(0,"kn Del SellLimit",OBJPROP_STATE,false);
   }
   if (ObjectGetInteger(0,"kn Del BuyLimit",OBJPROP_STATE))
   {
      Delete(OP_BUYLIMIT);ObjectSetInteger(0,"kn Del BuyLimit",OBJPROP_STATE,false);
   }
   if (ObjectGetInteger(0,"kn Del SellStop",OBJPROP_STATE))
   {
      Delete(OP_SELLSTOP);ObjectSetInteger(0,"kn Del SellStop",OBJPROP_STATE,false);
   }
   
   if (ObjectGetInteger(0,"kn lot l",OBJPROP_STATE)) ObjectSetInteger(0,"kn lot pr",OBJPROP_STATE,false);
   else ObjectSetInteger(0,"kn lot pr",OBJPROP_STATE,true);

   if (ObjectGetInteger(0,"kn lot up",OBJPROP_STATE))
   {
      PlaySound("Ok.wav");
      if (ObjectGetInteger(0,"kn lot l",OBJPROP_STATE)) Lot+=dlot;
      else {risk+=dpr;Lot = AccountBalance()*risk/100/MarketInfo(Symbol(),MODE_MARGINREQUIRED);}
      ObjectSetInteger(0,"kn lot up",OBJPROP_STATE,false);
      if (Lot>MarketInfo(Symbol(),MODE_MAXLOT)) Lot=MarketInfo(Symbol(),MODE_MAXLOT);
   }
   if (ObjectGetInteger(0,"kn lot dn",OBJPROP_STATE))
   {
      PlaySound("Ok.wav");
      if (ObjectGetInteger(0,"kn lot l",OBJPROP_STATE)) Lot-=dlot;
      else {risk-=dpr;Lot = AccountBalance()*risk/100/MarketInfo(Symbol(),MODE_MARGINREQUIRED);}
      ObjectSetInteger(0,"kn lot dn",OBJPROP_STATE,false);
      if (Lot<MarketInfo(Symbol(),MODE_MINLOT)) Lot=MarketInfo(Symbol(),MODE_MINLOT);
   }

   if (ObjectGetInteger(0,"kn cz up",OBJPROP_STATE))
   {
      PlaySound("Ok.wav");
      cz+=10;
      ObjectSetInteger(0,"kn cz up",OBJPROP_STATE,false);
      if (cz>100) cz=100;
   }
   if (ObjectGetInteger(0,"kn cz dn",OBJPROP_STATE))
   {
      PlaySound("Ok.wav");
      cz-=10;
      ObjectSetInteger(0,"kn cz dn",OBJPROP_STATE,false);
      if (cz<0) cz=0;
   }

   kn_UP_DN(knSlB,StopLossB);
   kn_UP_DN(knTpB,TakeProfitB);
   kn_UP_DN(knTsB,TrailingStopB);
   kn_UP_DN(knNlB,NoLossB);
   
   kn_UP_DN(knSlS,StopLossS);
   kn_UP_DN(knTpS,TakeProfitS);
   kn_UP_DN(knTsS,TrailingStopS);
   kn_UP_DN(knNlS,NoLossS);
   
   GV();
   
/*   if (StopLossB<STOPLEVEL) StopLossB=STOPLEVEL;
   if (StopLossB<STOPLEVEL) StopLossB=0;
   if (TakeProfitB<STOPLEVEL) TakeProfitB=STOPLEVEL;
   if (TakeProfitB<STOPLEVEL) TakeProfitB=0;
   if (TrailingStopB<STOPLEVEL) TrailingStopB=STOPLEVEL;
   if (TrailingStopB<STOPLEVEL) TrailingStopB=0;
   if (NoLossB<STOPLEVEL) NoLossB=STOPLEVEL;
   if (NoLossB<STOPLEVEL) NoLossB=0;

   if (StopLossS<STOPLEVEL) StopLossS=STOPLEVEL;
   if (StopLossS<STOPLEVEL) StopLossS=0;
   if (TakeProfitS<STOPLEVEL) TakeProfitS=STOPLEVEL;
   if (TakeProfitS<STOPLEVEL) TakeProfitS=0;
   if (TrailingStopS<STOPLEVEL) TrailingStopS=STOPLEVEL;
   if (TrailingStopS<STOPLEVEL) TrailingStopS=0;
   if (NoLossS<STOPLEVEL) NoLossS=STOPLEVEL;
   if (NoLossS<STOPLEVEL) NoLossS=0;*/

   if (ObjectGetInteger(0,"kn CZ",OBJPROP_STATE))
   {
      closeCZ();PlaySound("Ok.wav");
      ObjectSetInteger(0,"kn CZ",OBJPROP_STATE,false);
   }
   
   Redraw();
   return;
}
//--------------------------------------------------------------------
void kn_UP_DN(string name, double Price)
{
   double Par;
   if (GlobalVariableCheck(StringConcatenate(name," PIPS"))) Par=GlobalVariableGet(StringConcatenate(name," PIPS"));
   else Par=Price;
   if (ObjectGetInteger(0,StringConcatenate(name," up"),OBJPROP_STATE))
   {
      PlaySound("Ok.wav");
      Par+=dpips;
      GlobalVariableSet(StringConcatenate(name," PIPS"),Par);
      ObjectSetInteger(0,StringConcatenate(name," up"),OBJPROP_STATE,false);
   }
   if (ObjectGetInteger(0,StringConcatenate(name," dn"),OBJPROP_STATE))
   {
      PlaySound("Ok.wav");
      Par-=dpips;
      if (Par<=0) GlobalVariableDel(StringConcatenate(name," PIPS"));
      else
      {
         GlobalVariableSet(StringConcatenate(name," PIPS"),Par);
      }
      ObjectSetInteger(0,StringConcatenate(name," dn"),OBJPROP_STATE,false);
   }
}
//--------------------------------------------------------------------
bool closeCZ()
{
   if (confirmation)
   {
      int ret=MessageBox(StringConcatenate("Закрыть ",cz,"% всех позиции ?"),"", MB_YESNO);
      if (ret==IDNO) return(1);
   }
   bool error=true;
   int j,OT;
   for (j = OrdersTotal()-1; j >= 0; j--)
   {
      if (OrderSelect(j, SELECT_BY_POS))
      {
         if (OrderSymbol() == Symbol() && (Magic==-1 || Magic==OrderMagicNumber()))
         {
            OT = OrderType();
            if (OT>1) continue;
            if (OT==OP_BUY) 
            {
               error=OrderClose(OrderTicket(),NormalizeDouble(OrderLots()/100*cz,2),NormalizeDouble(Bid,Digits),3,Blue);
            }
            if (OT==OP_SELL) 
            {
               error=OrderClose(OrderTicket(),NormalizeDouble(OrderLots()/100*cz,2),NormalizeDouble(Ask,Digits),3,Red);
            }
         }
      }
   }
   return(1);
}
//--------------------------------------------------------------------
double Kn(string Name, double Price)
{
   if (ObjectFind(0,Name)!=-1)
   {
      if (ObjectGetInteger(0,Name,OBJPROP_STATE))
      {
         if (Price==0) 
         {
            Alert(Name," Установите значение больше стоплевел");
            ObjectSetInteger(0,Name,OBJPROP_STATE,false);
            GlobalVariableDel(Name);
         }
         if (!GlobalVariableCheck(Name)) GlobalVariableSet(Name,1);
         return(Price);
      }
      else
      {
         if (GlobalVariableCheck(Name)) GlobalVariableDel(Name);
         return(0);
      }
   }
return(Price);
}      
//--------------------------------------------------------------------
void ARROW(string Name, double Price, int ARROWCODE, color c)
{
   ObjectDelete(Name);
   ObjectCreate(Name,OBJ_ARROW,0,Time[0],Price,0,0,0,0);                     
   ObjectSetInteger(0,Name,OBJPROP_ARROWCODE,ARROWCODE);
   ObjectSetInteger(0,Name,OBJPROP_COLOR, c);
   ObjectSetInteger(0,Name,OBJPROP_WIDTH, 1);
}
//--------------------------------------------------------------------
void GV()
{
   if (GlobalVariableCheck(StringConcatenate(knSlB," PIPS"))) StopLossB    = GlobalVariableGet(StringConcatenate(knSlB," PIPS")); else StopLossB      = StopLoss_Buy;
   if (GlobalVariableCheck(StringConcatenate(knTpB," PIPS"))) TakeProfitB  = GlobalVariableGet(StringConcatenate(knTpB," PIPS")); else TakeProfitB    = TakeProfit_Buy;
   if (GlobalVariableCheck(StringConcatenate(knTsB," PIPS"))) TrailingStopB= GlobalVariableGet(StringConcatenate(knTsB," PIPS")); else TrailingStopB  = TrailingStop_Buy;
   if (GlobalVariableCheck(StringConcatenate(knNlB," PIPS"))) NoLossB      = GlobalVariableGet(StringConcatenate(knNlB," PIPS")); else NoLossB        = NoLoss_Buy;
   
   if (GlobalVariableCheck(StringConcatenate(knSlS," PIPS"))) StopLossS    = GlobalVariableGet(StringConcatenate(knSlS," PIPS")); else StopLossS      = StopLoss_Sell;
   if (GlobalVariableCheck(StringConcatenate(knTpS," PIPS"))) TakeProfitS  = GlobalVariableGet(StringConcatenate(knTpS," PIPS")); else TakeProfitS    = TakeProfit_Sell;
   if (GlobalVariableCheck(StringConcatenate(knTsS," PIPS"))) TrailingStopS= GlobalVariableGet(StringConcatenate(knTsS," PIPS")); else TrailingStopS  = TrailingStop_Sell;
   if (GlobalVariableCheck(StringConcatenate(knNlS," PIPS"))) NoLossS      = GlobalVariableGet(StringConcatenate(knNlS," PIPS")); else NoLossS        = NoLoss_Sell;
}
//--------------------------------------------------------------------
void Redr(double LB, double LS, double ProfitB, double ProfitS, int bs, int ss, int b, int s, int sl, int bl)
{
   color cl;
   _color(TypeColor);
   double Profit=ProfitB+ProfitS;
   if (ObjectFind(InpName)==0)
   {
      ObjectGetInteger(0,InpName,OBJPROP_XDISTANCE,0,X);
      ObjectGetInteger(0,InpName,OBJPROP_YDISTANCE,0,Y);
      if (TypeWind==0) 
      {
         RectLabelCreate(0,InpName,0,X,Y,152,140,Color_2,Color_1,STYLE_SOLID,3,false,true,true,1);
         Del();
      }
      else
      {
         if (TypeWind==1) RectLabelCreate(0,InpName,0,X,Y,300,240,Color_2,Color_2,STYLE_SOLID,3,false,true,true,1);
         if (TypeWind==2) RectLabelCreate(0,InpName,0,X,Y,300,360,Color_2,Color_2,STYLE_SOLID,3,false,true,true,1);
      }
   }
   long y=Y;
   RectLabelCreate(0,"_fon1_",0,X    ,y,150,40,Color_6,Color_7,STYLE_SOLID,1,false,false,true,0);
   if (TypeWind>0) RectLabelCreate(0,"_fon2_",0,X+150,y,150,40,Color_6,Color_7,STYLE_SOLID,1,false,false,true,0);
   else ObjectDelete("_fon2_");
   ButtonCreate(0,"kn min",0   ,X+2  ,y+2,18 ,18,CharToStr(244),"Wingdings",Width,Color_1,Color_8,Color_7,false);
   ButtonCreate(0,"kn color",0 ,X+2  ,y+20,18 ,18,CharToStr(83),"Wingdings",Width,Color_1,Color_8,Color_7,false);
   LabelCreate(0,"Symbol",0    ,X+80 ,y+20 ,CORNER_LEFT_UPPER,Symbol(),Font,Width+4,Color_1,0,ANCHOR_CENTER,false,false,true,0);
   if (TypeWind>0)
   {
      GV();
      if (bid>NormalizeDouble(Bid,Digits)) cl=Color_4; else cl=Color_3;
      bid=NormalizeDouble(Bid,Digits);
      LabelCreate(0,"2",0        ,X+225,y+20,CORNER_LEFT_UPPER,DoubleToStr(Bid,Digits),Font,Width+4,cl,0,ANCHOR_CENTER,false,false,true,0);
      LabelCreate(0,"spread",0   ,X+285,y+32,CORNER_LEFT_UPPER,DoubleToStr(MarketInfo(Symbol(),MODE_SPREAD),0),Font,Width-2,Color_1,0,ANCHOR_CENTER,false,false,true,0);
      y+=42;
      ButtonCreate(0,"kn lot l",0 ,X+2 ,y,130,18,StringConcatenate(DoubleToStr(Lot,2)," Lot"),Font,Width,Color_1,Color_8,Color_7,true);
      
      ButtonCreate(0,"kn lot up",0,X+131,y,18,18,CharToStr(217),"Wingdings",8,Color_1,Color_8,Color_7,false);
      ButtonCreate(0,"kn cz up",0 ,X+281,y,18,18,CharToStr(217),"Wingdings",8,Color_1,Color_8,Color_7,false);
      
      RectLabelCreate(0,"_CZ1_",0 ,X+151,y,128,18,Color_2,Color_7,STYLE_SOLID,1,false,false,true,0);
      LabelCreate(0,"kn CZ1",0    ,X+220,y+9,CORNER_LEFT_UPPER,StringConcatenate("Закрыть ",cz,"%"),Font,Width,Color_1,0,ANCHOR_CENTER,false,false,true,0);
      ButtonCreate(0,"kn CZ",0    ,X+151,y+20,128,18,StringConcatenate(DoubleToStr(Profit/100*cz,2),AC),Font,Width,Color_1,Color_8,Color_7,false);y+=20;
      
      ButtonCreate(0,"kn lot pr",0,X+2,y,130,18,StringConcatenate(DoubleToStr(Lot*100*MarketInfo(Symbol(),MODE_MARGINREQUIRED)/AccountBalance(),2)," %"),Font,Width,Color_1,Color_8,Color_7,false);
      ButtonCreate(0,"kn lot dn",0,X+131,y,18,18,CharToStr(218),"Wingdings",8,Color_1,Color_8,Color_7,false);
      ButtonCreate(0,"kn cz dn" ,0,X+281,y,18,18,CharToStr(218),"Wingdings",8,Color_1,Color_8,Color_7,false);y+=22;
      
      
      if (TypeWind==2)
      {
         RectLabelCreate(0,"_5_",0        ,X+151,y,73,26,Color_2,Color_7,STYLE_SOLID,1,false,false,true,0);
         LabelCreate(0,"5",0              ,X+185,y+13,CORNER_LEFT_UPPER,DoubleToStr(bs,0),Font,Width+0,Color_1,0,ANCHOR_CENTER,false,false,true,0);
         ButtonCreate(0,"kn Del BuyStop",0,X+225,y,73,26,"del",Font,Width,Color_5,Color_9,Color_7,false);
         ButtonCreate(0,"kn BuyStop",0    ,X+1  ,y,148,26,StringConcatenate("BuyStop ",delta),Font,Width,Color_5,Color_9,Color_7,false);y+=30;
         
         RectLabelCreate(0,"_6_",0          ,X+151,y,73,26,Color_2,Color_7,STYLE_SOLID,1,false,false,true,0);
         LabelCreate(0,"6",0                ,X+185,y+13,CORNER_LEFT_UPPER,DoubleToStr(sl,0),Font,Width+0,Color_1,0,ANCHOR_CENTER,false,false,true,0);
         ButtonCreate(0,"kn Del SellLimit",0,X+225,y,73,26,"del",Font,Width,Color_4,Color_9,Color_7,false);
         ButtonCreate(0,"kn SellLimit",0    ,X+1  ,y,148,26,StringConcatenate("SellLimit ",delta),Font,Width,Color_4,Color_9,Color_7,false);y+=30;
      }
      else
      {
         ObjectDelete("5");
         ObjectDelete("6");
         ObjectDelete("_5_");
         ObjectDelete("_6_");
         ObjectDelete("kn BuyStop");
         ObjectDelete("kn SellLimit");
         ObjectDelete("kn Del BuyStop");
         ObjectDelete("kn Del SellLimit");
      }
   } else y+=42;
   int W=26;
   if (TypeWind>0) W=56;
   ButtonCreate(0,"kn Buy",0,X+2  ,y,66,W,"BUY",Font,Width,Color_5,Color_9,Color_7,false);
   RectLabelCreate(0,"_7_",0,X+70 ,y,30,27,Color_2,Color_7,STYLE_SOLID,1,false,false,true,0);
   RectLabelCreate(0,"_8_",0,X+100,y,50,27,Color_2,Color_7,STYLE_SOLID,1,false,false,true,0);
   LabelCreate(0,"7",0      ,X+85,y+13,CORNER_LEFT_UPPER,DoubleToStr(b,0),Font,Width+0,Color_1,0,ANCHOR_CENTER,false,false,true,0);
   LabelCreate(0,"8",0      ,X+125,y+13,CORNER_LEFT_UPPER,DoubleToStr(LB,2),Font,Width+0,Color_1,0,ANCHOR_CENTER,false,false,true,0);
   if (TypeWind>0)
   {
      ButtonCreate(0,knTrNlB,0,X+151 ,y,18,56,"TrNlB",Font,Width,Color_1,Color_8,Color_7,GlobalVariableCheck(knTrNlB));

      ButtonCreate(0,knSlB,0     ,X+170  ,y,50,28,StringConcatenate("SL ",StopLossB)     ,Font,Width,Color_1,Color_8,Color_7,GlobalVariableCheck(knSlB));
      ButtonCreate(0,knTpB,0     ,X+235 ,y,50,28,StringConcatenate("TP ",TakeProfitB)   ,Font,Width,Color_1,Color_8,Color_7,GlobalVariableCheck(knTpB));
      ButtonCreate(0,StringConcatenate(knSlB," up"),0,X+222,y,13,13,CharToStr(217),"Wingdings",5,Color_1,Color_8,Color_7,false);
      ButtonCreate(0,StringConcatenate(knTpB," up"),0,X+285,y,13,13,CharToStr(217),"Wingdings",5,Color_1,Color_8,Color_7,false);y+=15;
      ButtonCreate(0,StringConcatenate(knSlB," dn"),0,X+222,y,13,13,CharToStr(218),"Wingdings",5,Color_1,Color_8,Color_7,false);
      ButtonCreate(0,StringConcatenate(knTpB," dn"),0,X+285,y,13,13,CharToStr(218),"Wingdings",5,Color_1,Color_8,Color_7,false);y+=15;

      if (ProfitB>0) cl=Color_5; else cl=Color_4;
      ButtonCreate(0,"kn Close Buy",0,X+68,y,82,26,DoubleToStr(ProfitB,2),Font,Width,cl,Color_9,Color_7,false);

      ButtonCreate(0,knNlB,0     ,X+170,y,50,28,StringConcatenate("NL ",NoLossB)       ,Font,Width,Color_1,Color_8,Color_7,GlobalVariableCheck(knNlB));
      ButtonCreate(0,knTsB,0     ,X+235,y,50,28,StringConcatenate("TS ",TrailingStopB) ,Font,Width,Color_1,Color_8,Color_7,GlobalVariableCheck(knTsB));
      ButtonCreate(0,StringConcatenate(knNlB," up"),0,X+222,y,13,13,CharToStr(217),"Wingdings",5,Color_1,Color_8,Color_7,false);
      ButtonCreate(0,StringConcatenate(knTsB," up"),0,X+285,y,13,13,CharToStr(217),"Wingdings",5,Color_1,Color_8,Color_7,false);y+=15;
      ButtonCreate(0,StringConcatenate(knNlB," dn"),0,X+222,y,13,13,CharToStr(218),"Wingdings",5,Color_1,Color_8,Color_7,false);
      ButtonCreate(0,StringConcatenate(knTsB," dn"),0,X+285,y,13,13,CharToStr(218),"Wingdings",5,Color_1,Color_8,Color_7,false);y+=15;
   } 
   else y+=31;
   ButtonCreate(0,"kn Sell",0 ,X+2  ,y,66,W,"SELL",Font,Width,Color_4,Color_9,Color_7,false);
   RectLabelCreate(0,"_9_",0  ,X+70 ,y,30,27,Color_2,Color_7,STYLE_SOLID,1,false,false,true,0);
   RectLabelCreate(0,"_10_",0 ,X+100,y,50,27,Color_2,Color_7,STYLE_SOLID,1,false,false,true,0);
   LabelCreate(0,"9",0        ,X+85 ,y+13,CORNER_LEFT_UPPER,DoubleToStr(s,0),Font,Width+0,Color_1,0,ANCHOR_CENTER,false,false,true,0);
   LabelCreate(0,"10",0       ,X+125,y+13,CORNER_LEFT_UPPER,DoubleToStr(LS,2),Font,Width+0,Color_1,0,ANCHOR_CENTER,false,false,true,0);
   if (TypeWind>0)
   {
      ButtonCreate(0,knTrNlS,0,X+151 ,y,18,56,"TrNlS",Font,Width,Color_1,Color_8,Color_7,GlobalVariableCheck(knTrNlS));

      ButtonCreate(0,knSlS,0     ,X+170  ,y,50,28,StringConcatenate("SL ",StopLossS)     ,Font,Width,Color_1,Color_8,Color_7,GlobalVariableCheck(knSlS));
      ButtonCreate(0,knTpS,0     ,X+235 ,y,50,28,StringConcatenate("TP ",TakeProfitS)   ,Font,Width,Color_1,Color_8,Color_7,GlobalVariableCheck(knTpS));
      ButtonCreate(0,StringConcatenate(knSlS," up"),0,X+222,y,13,13,CharToStr(217),"Wingdings",5,Color_1,Color_8,Color_7,false);
      ButtonCreate(0,StringConcatenate(knTpS," up"),0,X+285,y,13,13,CharToStr(217),"Wingdings",5,Color_1,Color_8,Color_7,false);y+=15;
      ButtonCreate(0,StringConcatenate(knSlS," dn"),0,X+222,y,13,13,CharToStr(218),"Wingdings",5,Color_1,Color_8,Color_7,false);
      ButtonCreate(0,StringConcatenate(knTpS," dn"),0,X+285,y,13,13,CharToStr(218),"Wingdings",5,Color_1,Color_8,Color_7,false);y+=15;

      if (ProfitS>0) cl=Color_5; else cl=Color_4;
      ButtonCreate(0,"kn Close Sell",0,X+68,y,82,26,DoubleToStr(ProfitS,2),Font,Width,cl,Color_9,Color_7,false);

      ButtonCreate(0,knNlS,0     ,X+170,y,50,28,StringConcatenate("NL ",NoLossS)       ,Font,Width,Color_1,Color_8,Color_7,GlobalVariableCheck(knNlS));
      ButtonCreate(0,knTsS,0     ,X+235,y,50,28,StringConcatenate("TS ",TrailingStopS) ,Font,Width,Color_1,Color_8,Color_7,GlobalVariableCheck(knTsS));
      ButtonCreate(0,StringConcatenate(knNlS," up"),0,X+222,y,13,13,CharToStr(217),"Wingdings",5,Color_1,Color_8,Color_7,false);
      ButtonCreate(0,StringConcatenate(knTsS," up"),0,X+285,y,13,13,CharToStr(217),"Wingdings",5,Color_1,Color_8,Color_7,false);y+=15;
      ButtonCreate(0,StringConcatenate(knNlS," dn"),0,X+222,y,13,13,CharToStr(218),"Wingdings",5,Color_1,Color_8,Color_7,false);
      ButtonCreate(0,StringConcatenate(knTsS," dn"),0,X+285,y,13,13,CharToStr(218),"Wingdings",5,Color_1,Color_8,Color_7,false);y+=15;

      if (TypeWind==2) 
      {
         RectLabelCreate(0,"_12_",0          ,X+151,y,73,26,Color_2,Color_7,STYLE_SOLID,1,false,false,true,0);
         LabelCreate(0,"11",0                ,X+185,y+13,CORNER_LEFT_UPPER,DoubleToStr(bl,0),Font,Width+0,Color_1,0,ANCHOR_CENTER,false,false,true,0);
         ButtonCreate(0,"kn BuyLimit",0      ,X+2  ,y,148,26,StringConcatenate("BuyLimit ",delta),Font,Width,Color_5,Color_9,Color_7,false);
         ButtonCreate(0,"kn Del BuyLimit",0  ,X+225,y,73,26,"del",Font,Width,Color_5,Color_9,Color_7,false);y+=30;
   
         RectLabelCreate(0,"_14_",0          ,X+151,y,73,26,Color_2,Color_7,STYLE_SOLID,1,false,false,true,0);
         LabelCreate(0,"12",0                ,X+185,y+13,CORNER_LEFT_UPPER,DoubleToStr(ss,0),Font,Width+0,Color_1,0,ANCHOR_CENTER,false,false,true,0);
         ButtonCreate(0,"kn SellStop",0      ,X+2  ,y,148,26,StringConcatenate("SellStop ",delta),Font,Width,Color_4,Color_9,Color_7,false);
         ButtonCreate(0,"kn Del SellStop",0  ,X+225,y,73,26,"del",Font,Width,Color_4,Color_9,Color_7,false);y+=30;
      }
      else
      {
         ObjectDelete("11");
         ObjectDelete("12");
         ObjectDelete("_14_");
         ObjectDelete("_12_");
         ObjectDelete("kn BuyLimit");
         ObjectDelete("kn SellStop");
         ObjectDelete("kn Del BuyLimit");
         ObjectDelete("kn Del SellStop");
      }
      RectLabelCreate(0,"_fon3_",0 ,X  ,y,300,40,Color_6,Color_7,STYLE_SOLID,1,false,false,true,0);
      if (Profit>0) cl=Color_5; else cl=Color_4;
      LabelCreate(0,"Profit",0  ,X+50  ,y+10,CORNER_LEFT_UPPER,"Profit",Font,Width,cl,0,ANCHOR_CENTER,false,false,true,0);
      LabelCreate(0,"Equity",0  ,X+135 ,y+10,CORNER_LEFT_UPPER,"Equity",Font,Width,cl,0,ANCHOR_CENTER,false,false,true,0);
      LabelCreate(0,"Balance",0 ,X+220 ,y+10,CORNER_LEFT_UPPER,"Balance",Font,Width,cl,0,ANCHOR_CENTER,false,false,true,0);
      y+=10;
      LabelCreate(0,"_Profit",0 ,X+50 ,y+20,CORNER_LEFT_UPPER,DoubleToStr(Profit,2),Font,Width,cl,0,ANCHOR_CENTER,false,false,true,0);
      LabelCreate(0,"_Equity",0 ,X+135,y+20,CORNER_LEFT_UPPER,DoubleToStr(AccountEquity(),2),Font,Width,cl,0,ANCHOR_CENTER,false,false,true,0);
      LabelCreate(0,"_Balance",0,X+240,y+20,CORNER_LEFT_UPPER,StringConcatenate(DoubleToStr(AccountBalance(),2),AC),Font,Width,cl,0,ANCHOR_CENTER,false,false,true,0);
   }
   else
   {
      y+=30;
      RectLabelCreate(0,"_fon3_",0 ,X     ,y,150,40,Color_6,Color_7,STYLE_SOLID,1,false,false,true,0);
      if (Profit>0) cl=Color_5; else cl=Color_4;
      LabelCreate(0,"Profit",0  ,X+35  ,y+10,CORNER_LEFT_UPPER,"Profit",Font,Width,cl,0,ANCHOR_CENTER,false,false,true,0);
      LabelCreate(0,"Equity",0  ,X+110 ,y+10,CORNER_LEFT_UPPER,"Equity",Font,Width,cl,0,ANCHOR_CENTER,false,false,true,0);
      y+=10;
      LabelCreate(0,"_Profit",0 ,X+35 ,y+20,CORNER_LEFT_UPPER,DoubleToStr(Profit,2),Font,Width,cl,0,ANCHOR_CENTER,false,false,true,0);
      LabelCreate(0,"_Equity",0 ,X+110,y+20,CORNER_LEFT_UPPER,DoubleToStr(AccountEquity(),2),Font,Width,cl,0,ANCHOR_CENTER,false,false,true,0);
   }
   ChartRedraw();
   return;
}
//+------------------------------------------------------------------+