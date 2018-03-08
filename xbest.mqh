

enum ENUM_LOT_MODE
  {
   LOT_MODE_FIXED=1,// Fixed Lot
   LOT_MODE_PERCENT=2,// Percent Lot
  };


//--- input parameters
extern string               XBEST_Version__="----------------------------------------------------------------";
extern string               XBEST_Version1__ = "-----------------xBest   EA  --------------------------------";
extern string               XBEST_Version2__ = "----------------------------------------------------------------";


extern string XBEST_Magic="--------XBEST_Magic Number Engine---------";
input bool                  XBEST_InpEnableEngineA  = false;     // Enable Engine      
input int                   XBEST_InpMagic= 7799;                // XBEST_Magic Number   

extern string XBEST_Config__="---------------------------Config--------------------------------------";
input int                  XBEST_InpGridSize=3;                 // Step Size in Pips
input int                  XBEST_InpTakeProfit=3;               // Take Profit in Pips
input ENUM_LOT_MODE        XBEST_InpLotMode= LOT_MODE_PERCENT;  // Lot Mode
input double               XBEST_InpFixedLot= 0.01;             // Fixed Lot
input double               XBEST_InpPercentLot= 0.03;           // Percent Lot
input double               XBEST_InpGridFactor= 1.1;            // Grid Increment Factor
input int                  XBEST_InpHedge= 0;                   // Hedge After Level
input int                  XBEST_InpDailyTarget= 50;             // Daily Target in Money
input double                  XBEST_InpMaxLot = 99;                // Max Lot 
input double               XBEST_MinProfit   = 30.00;     // Minimal Profit Close
input int                  XBEST_QtdTradesMinProfit   = 10;     // Qtd Trades to Minimal Profit Close

extern string XBEST_FilterOpenOneCandle__="--------------------Filter One Order by Candle--------------";
input bool                 XBEST_InpOpenOneCandle=true;          // Open one order by candle
input ENUM_TIMEFRAMES      XBEST_InpTimeframeBarOpen=PERIOD_CURRENT; // Timeframe OpenOneCandle

//LOT_MODE_FIXED
//---
int XBEST_SlipPage=3;
int XBEST_Spread=2.0;
//---

bool XBEST_m_hedging1,XBEST_m_target_filter1;
int XBEST_m_direction1,XBEST_m_current_day1,XBEST_m_previous_day1;
double XBEST_m_level1,XBEST_m_buyer1,XBEST_m_seller1,XBEST_m_target1,XBEST_m_profit1;
double XBEST_m_pip1,XBEST_m_size1,XBEST_m_take1,XBEST_m_spread1;
datetime   XBEST_m_datetime_ultcandleopen1;
datetime XBEST_m_time_equityrisk1;
double XBEST_m_mediaprice1;
int XBEST_m_orders_count1;
double XBEST_m_lastlot1;


string XBEST_m_symbol;
bool XBEST_m_news_time;
int XBEST_m_spreadX;
bool XBEST_m_initpainel;
string XBEST_m_filters_on;
double XBEST_m_profit_all;
datetime XBEST_m_time_equityriskstopall;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int XBEST_OnInit()
  {
//---
   XBEST_m_symbol=Symbol();

   XBEST_m_pip1=1.0/MathPow(10,Digits-1);
   XBEST_m_size1 = XBEST_InpGridSize * XBEST_m_pip1;
   XBEST_m_take1 = XBEST_InpTakeProfit * XBEST_m_pip1;
   XBEST_m_hedging1=false;
   XBEST_m_target_filter1=false;
   XBEST_m_direction1=0;
   XBEST_m_spread1=0.0;
   XBEST_m_datetime_ultcandleopen1=-1;
   XBEST_m_time_equityrisk1=-1;
   XBEST_m_orders_count1=0;
   XBEST_m_lastlot1=0;

   XBEST_m_filters_on = "";
   XBEST_m_initpainel = true;


//---
   printf("xBest v3.2 - Grid Hedging Expert Advisor");
   return (0);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void XBEST_OnTick(int Sinal)
  {
  

         xBest("S",Sinal,XBEST_InpHedge,XBEST_InpMagic,XBEST_m_orders_count1,XBEST_m_mediaprice1,XBEST_m_hedging1,XBEST_m_target_filter1,
               XBEST_m_direction1,XBEST_m_current_day1,XBEST_m_previous_day1,XBEST_m_level1,XBEST_m_buyer1,XBEST_m_seller1,
               XBEST_m_target1,XBEST_m_profit1,XBEST_m_pip1,XBEST_m_size1,XBEST_m_take1,XBEST_m_spread1,XBEST_m_datetime_ultcandleopen1,
               XBEST_m_time_equityrisk1);
  
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void xBest(string Id,int Sinal,double LotsHedge,int vXBEST_InpMagic,int  &m_orders_count,double  &m_mediaprice,bool  &m_hedging,bool  &m_target_filter,
           int  &m_direction,int  &m_current_day,int  &m_previous_day,
           double  &m_level,double  &m_buyer,double  &m_seller,double  &m_target,double  &m_profit,
           double  &m_pip,double  &m_size,double  &m_take,double  &m_spread,datetime  &vDatetimeUltCandleOpen,
           datetime  &m_time_equityrisk
           )
  {

//--- Variable Declaration
   int index,orders_total,order_ticket,order_type,ticket,hour;
   double volume_min,volume_max,volume_step,lots;
   double account_balance,margin_required,risk_balance;
   double order_open_price,order_lots;

//--- Variable Initialization
   int buy_ticket=0,sell_ticket=0,orders_count=0;
   int buyer_counter=0,seller_counter=0;
   bool was_trade=false,close_filter=false;
   bool long_condition=false,short_condition=false;
   double orders_profit=0.0,level=0.0;
   double buyer_lots=0.0,seller_lots=0.0;
   double buyer_sum= 0.0, seller_sum = 0.0;
   double buy_price= 0.0, sell_price = 0.0;
   double bid_price= Bid, ask_price = Ask;
   double close_price=iClose(NULL,0,0);
   double open_price=iOpen(NULL,0,0);
   datetime time_current=TimeCurrent();
   bool res=false;

//--- Base Lot Size
   account_balance=AccountBalance();
   volume_min = SymbolInfoDouble(XBEST_m_symbol, SYMBOL_VOLUME_MIN);
   volume_max = SymbolInfoDouble(XBEST_m_symbol, SYMBOL_VOLUME_MAX);
   volume_step= SymbolInfoDouble(XBEST_m_symbol,SYMBOL_VOLUME_STEP);
   lots=volume_min;

   if(XBEST_InpLotMode==LOT_MODE_FIXED) lots=XBEST_InpFixedLot;
    else if (XBEST_InpLotMode == LOT_MODE_PERCENT) {
   risk_balance=XBEST_InpPercentLot*AccountBalance()/100.0;
   margin_required=MarketInfo(XBEST_m_symbol,MODE_MARGINREQUIRED);
   lots=MathRound(risk_balance/margin_required,volume_step);
   if(lots < volume_min) lots = volume_min;
   if(lots > volume_max) lots = volume_max;
   }

//--- Daily Calc
   m_current_day=TimeDayOfWeek(time_current);
   if(m_current_day!=m_previous_day)
     {
      m_target_filter=false;
      m_target=0.0;
     }
   m_previous_day=m_current_day;

//--- Calculation Loop
   orders_total = OrdersTotal();
   m_mediaprice = 0;
    double BuyProfit  = 0;
    double SellProfit = 0;
   for(index=orders_total-1; index>=0; index--)
     {
      if(!OrderSelect(index,SELECT_BY_POS,MODE_TRADES)) continue;
      if(OrderMagicNumber()!=vXBEST_InpMagic || OrderSymbol()!=XBEST_m_symbol) continue;
      order_open_price=OrderOpenPrice(); order_ticket=OrderTicket();
      order_type=OrderType(); order_lots=OrderLots();
      //---
      if(order_type==OP_BUY)
        {
         //--- Set Last Buy Order
         if(order_ticket>buy_ticket)
           {
            buy_price=order_open_price;
            buy_ticket=order_ticket;
           }
         buyer_sum+=(order_open_price+m_spread)*order_lots;

         buyer_lots+=order_lots;
         buyer_counter++;
         orders_count++;
         m_mediaprice+=order_open_price*order_lots;
           if(OrderProfit()>0)BuyProfit+=OrderProfit()+OrderCommission()+OrderSwap();
        }
      //---
      if(order_type==OP_SELL)
        {
         //--- Set Last Sell Order
         if(order_ticket>sell_ticket)
           {
            sell_price=order_open_price;
            sell_ticket=order_ticket;
           }
         seller_sum+=(order_open_price-m_spread)*order_lots;

         seller_lots+=order_lots;
         seller_counter++;
         orders_count++;
         m_mediaprice+=order_open_price*order_lots;
           if(OrderProfit()>0)SellProfit+=OrderProfit()+OrderCommission()+OrderSwap();
        }

      //---
      orders_profit+=OrderProfit();

     }

   m_orders_count=orders_count;
   m_profit=orders_profit;
   if((seller_counter+buyer_counter)>0) m_mediaprice=NormalizeDouble(m_mediaprice/(buyer_lots+seller_lots),Digits);

 
//--- Calc
   if(orders_count==0)
     {
      m_target += m_profit;
      m_hedging = false;
     }

//--- Close Conditions
   if(XBEST_InpDailyTarget>0 && m_target+orders_profit>=XBEST_InpDailyTarget) m_target_filter=true;
//--- This ensure that buy and sell positions close at the same time when hedging is enabled
   if(m_hedging && ((m_direction>0 && bid_price>=m_level) || (m_direction<0 && ask_price<=m_level))) close_filter=true;

//--- Close All Orders on Conditions
   if(m_target_filter || close_filter)
     {

      XBEST_CloseThisSymbolAll(vXBEST_InpMagic);

      m_spread=0.0;
      return;
     }

//--- Open Trade Conditions
   if(!m_hedging)
     {
      if(orders_count>0)
        {
         if(buyer_counter>0  &&  buy_price-ask_price>=m_size) long_condition=true;
         if(seller_counter>0 && bid_price-sell_price>=m_size) short_condition=true;
           } else {
         hour=TimeHour(time_current);
         if(!InpUtilizeTimeFilter || (InpUtilizeTimeFilter && TimeFilter()))
           {

            if(Sinal == 1) long_condition = true;
            if(Sinal == -1) short_condition = true;


           }

        }
        } else {
      if(m_direction > 0 && bid_price <= m_seller) short_condition = true;
      if(m_direction < 0 && ask_price >= m_buyer) long_condition = true;
     }

// CONTROL DRAWDOWN
   //double vProfit=XBEST_CalculateProfit(vXBEST_InpMagic);

  // if(vProfit<0.0 && MathAbs(vProfit)>InpTotalEquityRiskCaution/100.0*AccountEquity())
    // {
    //  m_time_equityrisk=iTime(NULL,InpTimeframeEquityCaution,0);
     //   } else {
     // m_time_equityrisk=-1;
    // }

//--- Hedging
   if(XBEST_InpHedge>0 && !m_hedging)
     {
      if(long_condition && buyer_counter==XBEST_InpHedge)
        {
         m_spread = XBEST_Spread * m_pip;
         m_seller = bid_price;
         m_hedging= true;
         return;
        }
      if(short_condition && seller_counter==XBEST_InpHedge)
        {
         m_spread= XBEST_Spread * m_pip;
         m_buyer = ask_price;
         m_hedging=true;
         return;
        }
     }

//--- Lot Size
   if(LotsHedge!=0) { lots=LotsHedge; }
   else
     {
      lots=MathRound(lots*MathPow(XBEST_InpGridFactor,orders_count),volume_step);
      if(m_hedging)
        {
         if(long_condition) lots=MathRound(seller_lots*XBEST_InpGridFactor,volume_step)-buyer_lots;
         if(short_condition) lots=MathRound(buyer_lots*XBEST_InpGridFactor,volume_step)-seller_lots;
        }
     }
   if(lots < volume_min) lots = volume_min;
   if(lots > volume_max) lots = volume_max;
   if(lots>XBEST_InpMaxLot) lots=XBEST_InpMaxLot;

//--- Open Trades Based on Conditions
   if(!XBEST_InpOpenOneCandle || (XBEST_InpOpenOneCandle && vDatetimeUltCandleOpen!=iTime(NULL,XBEST_InpTimeframeBarOpen,0)))
     {
      vDatetimeUltCandleOpen=iTime(NULL,XBEST_InpTimeframeBarOpen,0);
      if(long_condition)
        {
         if(buyer_lots+lots==seller_lots) lots=seller_lots+volume_min;
         ticket=XBEST_OpenTrade(OP_BUY,lots,ask_price,vXBEST_InpMagic,Id);
         if(ticket>0)
           {
            res=OrderSelect(ticket,SELECT_BY_TICKET);
            order_open_price=OrderOpenPrice(); buyer_sum+=order_open_price*lots; buyer_lots+=lots;
            m_level=NormalizeDouble((buyer_sum-seller_sum)/(buyer_lots-seller_lots),Digits)+m_take;
            if(!m_hedging) level=m_level; else level=m_level+m_take;
            if(buyer_counter==0) m_buyer=order_open_price;
            m_direction=1; was_trade=true;
           }
        }

      if(short_condition)
        {
         if(seller_lots+lots==buyer_lots) lots=buyer_lots+volume_min;
         ticket=XBEST_OpenTrade(OP_SELL,lots,bid_price,vXBEST_InpMagic,Id);
         if(ticket>0)
           {
            res=OrderSelect(ticket,SELECT_BY_TICKET);
            order_open_price=OrderOpenPrice(); seller_sum+=order_open_price*lots; seller_lots+=lots;
            m_level=NormalizeDouble((seller_sum-buyer_sum)/(seller_lots-buyer_lots),Digits)-m_take;
            if(!m_hedging) level=m_level; else level=m_level-m_take;
            if(seller_counter==0) m_seller=order_open_price;
            m_direction=-1; was_trade=true;
           }
        }

     }


    if(BuyProfit>= XBEST_MinProfit && buyer_counter >= XBEST_QtdTradesMinProfit)
      XBEST_CloseAllTicket(OP_BUY,buy_ticket, vXBEST_InpMagic);

   if(SellProfit>=XBEST_MinProfit &&  seller_counter >= XBEST_QtdTradesMinProfit)
      XBEST_CloseAllTicket(OP_SELL,sell_ticket, vXBEST_InpMagic);

//--- Setup Global Take Profit
   if(was_trade)
     {
      orders_total=OrdersTotal();
      for(index=orders_total-1; index>=0; index--)
        {
         if(!OrderSelect(index,SELECT_BY_POS,MODE_TRADES)) continue;
         if(OrderMagicNumber()!=vXBEST_InpMagic || OrderSymbol()!=XBEST_m_symbol) continue;
         order_type=OrderType();
         if(m_direction>0)
           {
            if(order_type == OP_BUY) res=OrderModify(OrderTicket(), OrderOpenPrice(), 0.0, level, 0);
            if(order_type == OP_SELL) res=OrderModify(OrderTicket(), OrderOpenPrice(), level, 0.0, 0);
           }
         if(m_direction<0)
           {
            if(order_type == OP_BUY) res=OrderModify(OrderTicket(), OrderOpenPrice(), level, 0.0, 0);
            if(order_type == OP_SELL) res=OrderModify(OrderTicket(), OrderOpenPrice(), 0.0, level, 0);
           }
        }
     }

  }
//+------------------------------------------------------------------+
int XBEST_OpenTrade(int cmd,double volume,double price,int vXBEST_InpMagic,string coment, double stop=0.0,double take=0.0)
  {
   return OrderSend(XBEST_m_symbol, cmd, volume, price, XBEST_SlipPage, stop, take, coment, vXBEST_InpMagic, 0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int XBEST_CountTrades()
  {
   int l_count_0=0;
   for(int l_pos_4=OrdersTotal()-1; l_pos_4>=0; l_pos_4--)
     {
      if(!OrderSelect(l_pos_4,SELECT_BY_POS,MODE_TRADES)) { continue; }
      if(OrderSymbol()!=Symbol() || (OrderMagicNumber()!=XBEST_InpMagic )) continue;
      if(OrderSymbol()==Symbol() && (OrderMagicNumber()==XBEST_InpMagic ))
         if(OrderType()==OP_SELL || OrderType()==OP_BUY) l_count_0++;
     }
   return (l_count_0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int XBEST_CountTrades(int vXBEST_InpMagic)
  {
   int l_count_0=0;
   for(int l_pos_4=OrdersTotal()-1; l_pos_4>=0; l_pos_4--)
     {
      if(!OrderSelect(l_pos_4,SELECT_BY_POS,MODE_TRADES)) { continue; }
      if(OrderSymbol()!=Symbol() || (OrderMagicNumber()!=vXBEST_InpMagic)) continue;
      if(OrderSymbol()==Symbol() && (OrderMagicNumber()==vXBEST_InpMagic))
         if(OrderType()==OP_SELL || OrderType()==OP_BUY) l_count_0++;
     }
   return (l_count_0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int XBEST_CountTradesSell(int vXBEST_InpMagic)
  {
   int l_count_0=0;
   for(int l_pos_4=OrdersTotal()-1; l_pos_4>=0; l_pos_4--)
     {
      if(!OrderSelect(l_pos_4,SELECT_BY_POS,MODE_TRADES)) { continue; }
      if(OrderSymbol()!=Symbol() || (OrderMagicNumber()!=vXBEST_InpMagic)) continue;
      if(OrderSymbol()==Symbol() && (OrderMagicNumber()==vXBEST_InpMagic))
         if(OrderType()==OP_SELL) l_count_0++;
     }
   return (l_count_0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int XBEST_CountTradesBuy(int vXBEST_InpMagic)
  {
   int l_count_0=0;
   for(int l_pos_4=OrdersTotal()-1; l_pos_4>=0; l_pos_4--)
     {
      if(!OrderSelect(l_pos_4,SELECT_BY_POS,MODE_TRADES)) { continue; }
      if(OrderSymbol()!=Symbol() || (OrderMagicNumber()!=vXBEST_InpMagic)) continue;
      if(OrderSymbol()==Symbol() && (OrderMagicNumber()==vXBEST_InpMagic))
         if(OrderType()==OP_BUY) l_count_0++;
     }
   return (l_count_0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double XBEST_CalculateProfit()
  {
   double ld_ret_0=0;
   for(int g_pos_344=OrdersTotal()-1; g_pos_344>=0; g_pos_344--)
     {
      if(!OrderSelect(g_pos_344,SELECT_BY_POS,MODE_TRADES)) { continue; }
      if(OrderSymbol()!=Symbol() || (OrderMagicNumber()!=XBEST_InpMagic )) continue;
      if(OrderSymbol()==Symbol() && (OrderMagicNumber()==XBEST_InpMagic))
         if(OrderType()==OP_BUY || OrderType()==OP_SELL) ld_ret_0+=OrderProfit();
     }
   return (ld_ret_0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double XBEST_CalculateProfit(int vXBEST_InpMagic)
  {
   double ld_ret_0=0;
   for(int g_pos_344=OrdersTotal()-1; g_pos_344>=0; g_pos_344--)
     {
      if(!OrderSelect(g_pos_344,SELECT_BY_POS,MODE_TRADES)) { continue; }
      if(OrderSymbol()!=Symbol() || (OrderMagicNumber()!=vXBEST_InpMagic)) continue;
      if(OrderSymbol()==Symbol() && (OrderMagicNumber()==vXBEST_InpMagic))
         if(OrderType()==OP_BUY || OrderType()==OP_SELL) ld_ret_0+=OrderProfit();
     }
   return (ld_ret_0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool XBEST_isCloseLastOrderNotProfit(int XBEST_MagicNumber)
  {
   datetime t=0;
   double   ocp,osl,otp;
   int      i,j=-1,k=OrdersHistoryTotal();
   for(i=0; i<k; i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
        {
         if(OrderType()==OP_BUY || OrderType()==OP_SELL)
           {
            if(OrderSymbol()==Symbol() && OrderMagicNumber()==XBEST_MagicNumber)
              {
               if(t<OrderCloseTime())
                 {
                  t = OrderCloseTime();
                  j = i;
                 }
              }
           }
        }
     }
   if(OrderSelect(j,SELECT_BY_POS,MODE_HISTORY))
     {
      ocp = NormalizeDouble(OrderClosePrice(), Digits);
      osl = NormalizeDouble(OrderStopLoss(), Digits);
      otp = NormalizeDouble(OrderTakeProfit(), Digits);
      if(OrderProfit() < 0) return (True);
     }
   return (False);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double XBEST_FindLastSellLot(int XBEST_MagicNumber)
  {
   double l_lastLote=0;
   int l_ticket_8;
//double ld_unused_12 = 0;
   int l_ticket_20=0;
   for(int l_pos_24=OrdersTotal()-1; l_pos_24>=0; l_pos_24--)
     {
      if(!OrderSelect(l_pos_24,SELECT_BY_POS,MODE_TRADES)) { continue; }
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=XBEST_MagicNumber) continue;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==XBEST_MagicNumber && OrderType()==OP_SELL)
        {
         l_ticket_8=OrderTicket();
         if(l_ticket_8>l_ticket_20)
           {
            l_lastLote+=OrderLots();
            //ld_unused_12 = l_ord_open_price_0;
            l_ticket_20=l_ticket_8;
           }
        }
     }
   return (l_lastLote);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double XBEST_FindLastBuyLot(int XBEST_MagicNumber)
  {
   double l_lastorder=0;
   int l_ticket_8;
//double ld_unused_12 = 0;
   int l_ticket_20=0;
   for(int l_pos_24=OrdersTotal()-1; l_pos_24>=0; l_pos_24--)
     {
      if(!OrderSelect(l_pos_24,SELECT_BY_POS,MODE_TRADES)) { continue; }
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=XBEST_MagicNumber) continue;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==XBEST_MagicNumber && OrderType()==OP_BUY)
        {
         l_ticket_8=OrderTicket();
         if(l_ticket_8>l_ticket_20)
           {
            l_lastorder+=OrderLots();
            //ld_unused_12 = l_ord_open_price_0;
            l_ticket_20=l_ticket_8;
           }
        }
     }
   return (l_lastorder);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void XBEST_ShowError(int error,string complement)
  {

   if(error==1 || error==130) { return; }

   //string ErrorText=ErrorDescription(error);
  // StringToUpper(ErrorText);
   Print(complement,": Ordem: ",OrderTicket(),". Falha ao tentar alterar ordem: ",error," ");
   ResetLastError();

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void XBEST_TrailingAlls(int ai_0,int ai_4,double a_price_8,int XBEST_MagicNumber)
  {
   int li_16;

   double m_pip=1.0/MathPow(10,Digits-1);

   double l_ord_stoploss_20;
   double l_price_28;
   bool foo=false;
   if(ai_4!=0)
     {
      for(int l_pos_36=OrdersTotal()-1; l_pos_36>=0; l_pos_36--)
        {
         if(OrderSelect(l_pos_36,SELECT_BY_POS,MODE_TRADES))
           {
            if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=XBEST_MagicNumber) continue;
            if(OrderSymbol()==Symbol() || OrderMagicNumber()==XBEST_MagicNumber)
              {
               if(OrderType()==OP_BUY)
                 {
                  li_16=(int)NormalizeDouble((Bid-a_price_8)/Point,0);
                  if(li_16<ai_0) continue;
                  l_ord_stoploss_20=OrderStopLoss();
                  l_price_28=Bid-ai_4*Point;
                  if(l_ord_stoploss_20==0.0 || (l_ord_stoploss_20!=0.0 && l_price_28>l_ord_stoploss_20))
                    {
                     // Somente ajustar a ordem se ela estiver aberta
                     if(XBEST_CanModify(OrderTicket()))
                       {
                        ResetLastError();
                        foo=OrderModify(OrderTicket(),a_price_8,l_price_28,OrderTakeProfit(),0,Aqua);
                        if(!foo) { XBEST_ShowError(GetLastError(),"Normal"); }
                       }
                    }
                 }
               if(OrderType()==OP_SELL)
                 {
                  li_16=(int)NormalizeDouble((a_price_8-Ask)/Point,0);
                  if(li_16<ai_0) continue;
                  l_ord_stoploss_20=OrderStopLoss();
                  l_price_28=Ask+ai_4*Point;
                  if(l_ord_stoploss_20==0.0 || (l_ord_stoploss_20!=0.0 && l_price_28<l_ord_stoploss_20))
                    {
                     // Somente ajustar a ordem se ela estiver aberta
                     if(XBEST_CanModify(OrderTicket()))
                       {
                        ResetLastError();
                        foo=OrderModify(OrderTicket(),a_price_8,l_price_28,OrderTakeProfit(),0,Red);
                        if(!foo) { XBEST_ShowError(GetLastError(),"Normal"); }
                       }
                    }
                 }
              }
            Sleep(1000);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void XBEST_CloseThisSymbolAll(int vXBEST_InpMagic)
  {
   bool foo=false;
   for(int l_pos_0=OrdersTotal()-1; l_pos_0>=0; l_pos_0--)
     {
      if(!OrderSelect(l_pos_0,SELECT_BY_POS,MODE_TRADES)) { continue; }
      if(OrderSymbol()==Symbol())
        {
         if(OrderSymbol()==Symbol() && (OrderMagicNumber()==vXBEST_InpMagic))
           {
            if(OrderType()==OP_BUY)
               foo=OrderClose(OrderTicket(),OrderLots(),Bid,XBEST_SlipPage,Blue);

            if(OrderType()==OP_SELL)
               foo=OrderClose(OrderTicket(),OrderLots(),Ask,XBEST_SlipPage,Red);
           }
         Sleep(1000);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void XBEST_CloseThisSymbolAll()
  {
   bool foo=false;
   for(int l_pos_0=OrdersTotal()-1; l_pos_0>=0; l_pos_0--)
     {
      if(!OrderSelect(l_pos_0,SELECT_BY_POS,MODE_TRADES)) { continue; }
      if(OrderSymbol()==Symbol())
        {
         if(OrderSymbol()==Symbol() && (OrderMagicNumber()==XBEST_InpMagic ))
           {
            if(OrderType()==OP_BUY)
               foo=OrderClose(OrderTicket(),OrderLots(),Bid,XBEST_SlipPage,Blue);

            if(OrderType()==OP_SELL)
               foo=OrderClose(OrderTicket(),OrderLots(),Ask,XBEST_SlipPage,Red);
           }
         Sleep(1000);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool XBEST_CanModify(int ticket)
  {

   return OrdersTotal() > 0;
/*
    if( OrderType() == OP_BUY || OrderType() == OP_SELL)
       return OrderCloseTime() == 0;
       
    return false;
 
    /*
    bool result = false;
    
    OrderSelect(ticket, SELECT_BY_TICKET
    for(int i=OrdersHistoryTotal()-1;i>=0;i--){
       if( !OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) ){ continue; }
       if(OrderTicket()==ticket){
          result=true;
          break;
       }
    }
    
    return result;
    */

  }

  void XBEST_CloseAllTicket(int aType,int ticket, int XBEST_MagicN)
  {
   for(int i=OrdersTotal()-1; i>=0; i--)
      if(OrderSelect(i,SELECT_BY_POS))
         if(OrderSymbol()==Symbol())
            if(OrderMagicNumber()==XBEST_MagicN)
              {
               if(OrderType()==aType && OrderType()==OP_BUY)
                  if(OrderProfit()>0 || OrderTicket()==ticket)
                     if(!OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(Bid,Digits()),XBEST_SlipPage,clrRed))
                        Print(" OrderClose OP_BUY Error N",GetLastError());

               if(OrderType()==aType && OrderType()==OP_SELL)
                  if(OrderProfit()>0 || OrderTicket()==ticket)
                     if(!OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(Ask,Digits()),XBEST_SlipPage,clrRed))
                        Print(" OrderClose OP_SELL Error N",GetLastError());

              }
  }