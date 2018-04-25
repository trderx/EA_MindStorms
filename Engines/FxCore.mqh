
//+-----------------------------------------------------------------+
//|                                                   FXCORE         |
//|                                      rodolfo.leonardo@gmail.com. |
//+------------------------------------------------------------------+

extern string FxCore__ = "-----------------------------------------------------------------";
extern string FxCore = "                                  MODULE FXCORE                    ";
extern string FxCore____ = "---------------------------------------------------------------";

input bool InpEnableFxCore = true;           //Enable FxCore
extern int InpMagicNumberFxCore = 988827;    //Magic Number FxCore
extern int InpStopLevelFxCore = 20;
extern int InpMaxOrderFxCore = 15;
extern bool InpHabilitaFatorFxCore = true;
extern double InpFatorFxCore = 2.0;
extern bool InpHabilitaSomaFxCore = FALSE;
extern double InpLoteSomaFxCore = 1.0;
extern int InpModoFxCore = 2;
 

int SinalFxCore = 0;
int vg_CountOrdersFxCore = 0;
int vg_OrderTotalFxCore;
int vg_HistTotalFxCore;
int vg_PosFxCore;
int vg_QtdDigitsFxCore;
int vg_TipoOrderFxCore;
int vg_TicketFxCore;
double vg_MinLotOpenOrderFxCore;
double vg_CloseProfitFxCore;
double vg_PointFxCore;
double vg_MinLotFxCore;
double vg_MaxLotFxCore;
double vg_StopLevelFxCore;
double vg_LastOrdemLotsFxCore;
double vg_LastOrdemOpenPriceFxCore;
double vg_ProfitCloseFxCore;
double vg_ProfitTotalFxCore;
double vg_ProfitOpenFxCore;
string vg_PriceFxCore;
string vg_AlertFxCore = "";
string vg_MensagemFxCore;
bool InitFxCore = false;


int init_FxCore() {

    SinalFxCore = 0;
   if (Digits == 3 || Digits == 5) vg_PointFxCore = 10.0 * Point;
   else vg_PointFxCore = Point;
   vg_MinLotFxCore = MarketInfo(Symbol(), MODE_MINLOT);
   if (vg_MinLotFxCore == 0.01) vg_QtdDigitsFxCore = 2;
   else {
      if (vg_MinLotFxCore == 0.1) vg_QtdDigitsFxCore = 1;
      else vg_QtdDigitsFxCore = 0;
   }
   if (vg_MinLotOpenOrderFxCore <= vg_MinLotFxCore) vg_MinLotOpenOrderFxCore = vg_MinLotFxCore;
   vg_StopLevelFxCore = MarketInfo(Symbol(), MODE_STOPLEVEL);
   if (InpStopLevelFxCore <= vg_StopLevelFxCore) InpStopLevelFxCore = vg_StopLevelFxCore;
   double leverage_0 = AccountLeverage();
   if (AccountLeverage() <= 200) vg_MinLotOpenOrderFxCore = NormalizeDouble(AccountBalance() / 10000.0 * (leverage_0 / 200.0), 2);
   else vg_MinLotOpenOrderFxCore = NormalizeDouble(AccountBalance() / 10000.0, 2);
   vg_CloseProfitFxCore = 150.0 * vg_MinLotOpenOrderFxCore;
   vg_MaxLotFxCore = 4.0 * vg_MinLotOpenOrderFxCore;

   return (0);
}


int FxCore(int Sinal ) {

    if(!InpEnableFxCore) return (0);

   if(!InitFxCore ){
       init_FxCore();
       InitFxCore = true;
   }

  SinalFxCore = Sinal;
   string ls_0;

   if (AccountBalance() < 50.0) vg_AlertFxCore = "ERROR: Fundo Insuficiente \nMinimo 50";
   
   if (IsDemo() == TRUE) ls_0 = "Conta: Demo";
   else ls_0 = "Conta: Real";

   if (vg_AlertFxCore != "") {
      Alert(vg_AlertFxCore);
      Comment(vg_MensagemFxCore);
      vg_AlertFxCore = "";

   } else {
      switch (InpModoFxCore) {
      case 0:
         AnalizandoMercadoFxCore();
       
         break;
      case 1:
         ProcessaFechamentoOrdemFxCore();
       
         break;
      case 2:
         VerificandoAberturaOrdemFxCore();
        
      }
      return (0);
   }
   return (0);
}
//-------------------------------------------------------------------------//
int CountOrdersFxCore() {
   vg_OrderTotalFxCore = OrdersTotal();
   vg_CountOrdersFxCore = 0;
   for (vg_PosFxCore = 0; vg_PosFxCore < vg_OrderTotalFxCore; vg_PosFxCore++) {
      OrderSelect(vg_PosFxCore, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol() != Symbol() || OrderMagicNumber() != InpMagicNumberFxCore) continue;
      vg_CountOrdersFxCore++;
   }
   return (vg_CountOrdersFxCore);
}

//-------------------------------------------------------------------------//
int OpenOrdersFxCore(int a_cmd_0, double a_lots_4, double a_price_12, color a_color_20) {
    return (OrderSend(Symbol(), a_cmd_0, a_lots_4, a_price_12, 3, 0, 0, "", InpMagicNumberFxCore, 0, a_color_20));
   return (0);
}

//-------------------------------------------------------------------------//
int CloseOrdersFxCore() {
   vg_OrderTotalFxCore = OrdersTotal();
   for (vg_PosFxCore = vg_OrderTotalFxCore - 1; vg_PosFxCore >= 0; vg_PosFxCore--) {
      OrderSelect(vg_PosFxCore, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol() != Symbol() || OrderMagicNumber() != InpMagicNumberFxCore) continue;
      switch (OrderType()) {
      case OP_BUY:
         OrderClose(OrderTicket(), OrderLots(), Bid, 1, CLR_NONE);
         vg_PriceFxCore = Bid;
         
         break;
      case OP_SELL:
         OrderClose(OrderTicket(), OrderLots(), Ask, 1, CLR_NONE);
         vg_PriceFxCore = Ask;
        
         break;
      case OP_BUYLIMIT:
         OrderDelete(OrderTicket());
         break;
      case OP_SELLLIMIT:
         OrderDelete(OrderTicket());
      }
   }
   return (0);
}

//-------------------------------------------------------------------------//
double GetLastLotFxCore() {
   vg_OrderTotalFxCore = OrdersTotal();
   vg_LastOrdemLotsFxCore = 0;
   for (vg_PosFxCore = 0; vg_PosFxCore < vg_OrderTotalFxCore; vg_PosFxCore++) {
      OrderSelect(vg_PosFxCore, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol() != Symbol() || OrderMagicNumber() != InpMagicNumberFxCore) continue;
      vg_LastOrdemLotsFxCore = OrderLots();
   }


   return (vg_LastOrdemLotsFxCore);
}

//-------------------------------------------------------------------------//
double GetTotalProfitFxCore() {
   vg_OrderTotalFxCore = OrdersTotal();
   vg_ProfitCloseFxCore = 0;
   for (vg_PosFxCore = 0; vg_PosFxCore < vg_OrderTotalFxCore; vg_PosFxCore++) {
      OrderSelect(vg_PosFxCore, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol() != Symbol() || OrderMagicNumber() != InpMagicNumberFxCore) continue;
      vg_ProfitCloseFxCore += OrderProfit();
   }
   return (vg_ProfitCloseFxCore);
}

//-------------------------------------------------------------------------//
int GetSinalFxCore() {
   
   return (SinalFxCore);
}

//-------------------------------------------------------------------------//
int AnalizandoMercadoFxCore() {
   if (GetTotalProfitFxCore() >= vg_CloseProfitFxCore) CloseOrdersFxCore();
   if (CountOrdersFxCore() == 0 && GetLastLotFxCore() == 0.0) {
      if (GetSinalFxCore() == -15)
         if (OpenOrdersFxCore(OP_BUY, vg_MinLotOpenOrderFxCore, Ask, Blue) > 0) return (0);
      if (GetSinalFxCore() == 15)
         if (OpenOrdersFxCore(OP_SELL, vg_MinLotOpenOrderFxCore, Bid, Red) > 0) return (0);
   }
   if (CountOrdersFxCore() > 0 && CountOrdersFxCore() < InpMaxOrderFxCore) {
      vg_TipoOrderFxCore = -1;
      vg_LastOrdemOpenPriceFxCore = 0;
      vg_OrderTotalFxCore = OrdersTotal();
      for (vg_PosFxCore = 0; vg_PosFxCore < vg_OrderTotalFxCore; vg_PosFxCore++) {
         OrderSelect(vg_PosFxCore, SELECT_BY_POS, MODE_TRADES);
         if (OrderSymbol() != Symbol() || OrderMagicNumber() != InpMagicNumberFxCore) continue;
         vg_TipoOrderFxCore = OrderType();
         vg_LastOrdemOpenPriceFxCore = OrderOpenPrice();
      }
      if (vg_TipoOrderFxCore == OP_BUY) {
         if (Ask > vg_LastOrdemOpenPriceFxCore - InpStopLevelFxCore * vg_PointFxCore) return (0);
         if (InpHabilitaFatorFxCore) {
            if (NormalizeDouble(vg_MinLotOpenOrderFxCore * MathPow(InpFatorFxCore, CountOrdersFxCore()), vg_QtdDigitsFxCore) > vg_MaxLotFxCore) return (0);
            if (OpenOrdersFxCore(OP_BUY, NormalizeDouble(vg_MinLotOpenOrderFxCore * MathPow(InpFatorFxCore, CountOrdersFxCore()), vg_QtdDigitsFxCore), Ask, Blue) > 0) return (0);
         }
         if (InpHabilitaSomaFxCore) {
            if (NormalizeDouble(vg_MinLotOpenOrderFxCore + (GetLastLotFxCore() + InpLoteSomaFxCore), vg_QtdDigitsFxCore) > vg_MaxLotFxCore) return (0);
            vg_TicketFxCore = OpenOrdersFxCore(OP_BUY, NormalizeDouble(GetLastLotFxCore() + InpLoteSomaFxCore, vg_QtdDigitsFxCore), Ask, Blue);
         }
      }
      if (vg_TipoOrderFxCore == OP_SELL) {
         if (Bid < vg_LastOrdemOpenPriceFxCore + InpStopLevelFxCore * vg_PointFxCore) return (0);
         if (InpHabilitaFatorFxCore) {
            if (NormalizeDouble(vg_MinLotOpenOrderFxCore * MathPow(InpFatorFxCore, CountOrdersFxCore()), vg_QtdDigitsFxCore) > vg_MaxLotFxCore) return (0);
            if (OpenOrdersFxCore(OP_SELL, NormalizeDouble(vg_MinLotOpenOrderFxCore * MathPow(InpFatorFxCore, CountOrdersFxCore()), vg_QtdDigitsFxCore), Bid, Red) > 0) return (0);
         }
         if (InpHabilitaSomaFxCore) {
            if (NormalizeDouble(vg_MinLotOpenOrderFxCore + (GetLastLotFxCore() + InpLoteSomaFxCore), vg_QtdDigitsFxCore) > vg_MaxLotFxCore) return (0);
            if (OpenOrdersFxCore(OP_SELL, NormalizeDouble(vg_MinLotOpenOrderFxCore + InpLoteSomaFxCore * vg_PosFxCore, vg_QtdDigitsFxCore), Bid, Blue) > 0) return (0);
         }
      }
   }
   return (0);
}


//-------------------------------------------------------------------------//
int ProcessaFechamentoOrdemFxCore() {
   if (CountOrdersFxCore() == 0) vg_CountOrdersFxCore = 0;
   vg_HistTotalFxCore = OrdersHistoryTotal();
   vg_OrderTotalFxCore = OrdersTotal();
   vg_ProfitCloseFxCore = 0;
   for (vg_PosFxCore = vg_HistTotalFxCore - vg_CountOrdersFxCore; vg_PosFxCore < vg_HistTotalFxCore; vg_PosFxCore++) {
      OrderSelect(vg_PosFxCore, SELECT_BY_POS, MODE_HISTORY);
      if (OrderSymbol() != Symbol() || OrderMagicNumber() != InpMagicNumberFxCore) continue;
      vg_ProfitCloseFxCore += OrderProfit();
   }
   vg_ProfitOpenFxCore = 0;
   for (vg_PosFxCore = 0; vg_PosFxCore < vg_OrderTotalFxCore; vg_PosFxCore++) {
      OrderSelect(vg_PosFxCore, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol() != Symbol() || OrderMagicNumber() != InpMagicNumberFxCore) continue;
      vg_ProfitOpenFxCore += OrderProfit();
   }
   vg_ProfitTotalFxCore = vg_ProfitCloseFxCore + vg_ProfitOpenFxCore;
   if (vg_ProfitTotalFxCore >= vg_CloseProfitFxCore) CloseOrdersFxCore();
   
   if (CountOrdersFxCore() == 0 && GetLastLotFxCore() == 0.0 && vg_CountOrdersFxCore == 0) {
      if (GetSinalFxCore() == -15) {
         
         vg_TicketFxCore = OpenOrdersFxCore(OP_BUY, vg_MinLotOpenOrderFxCore, Ask, Blue);
         if (vg_TicketFxCore > 0) {
            vg_CountOrdersFxCore++;
            return (0);
         }
      }
      if (GetSinalFxCore() == 15) {
         
         vg_TicketFxCore = OpenOrdersFxCore(OP_SELL, vg_MinLotOpenOrderFxCore, Bid, Red);
         if (vg_TicketFxCore > 0) {
            vg_CountOrdersFxCore++;
            return (0);
         }
      }
   }
   if (CountOrdersFxCore() > 0 && CountOrdersFxCore() < InpMaxOrderFxCore) {
      vg_TipoOrderFxCore = -1;
      vg_LastOrdemOpenPriceFxCore = 0;
      vg_OrderTotalFxCore = OrdersTotal();
      for (vg_PosFxCore = 0; vg_PosFxCore < vg_OrderTotalFxCore; vg_PosFxCore++) {
         OrderSelect(vg_PosFxCore, SELECT_BY_POS, MODE_TRADES);
         if (OrderSymbol() != Symbol() || OrderMagicNumber() != InpMagicNumberFxCore) continue;
         vg_TipoOrderFxCore = OrderType();
         vg_LastOrdemOpenPriceFxCore = OrderOpenPrice();
      }
      if (vg_TipoOrderFxCore == OP_BUY) {
         if (Ask > vg_LastOrdemOpenPriceFxCore - InpStopLevelFxCore * vg_PointFxCore) return (0);
         if (InpHabilitaFatorFxCore) {
            if (NormalizeDouble(vg_MinLotOpenOrderFxCore * MathPow(InpFatorFxCore, vg_CountOrdersFxCore), vg_QtdDigitsFxCore) > vg_MaxLotFxCore) return (0);
            vg_TicketFxCore = OpenOrdersFxCore(OP_BUY, NormalizeDouble(vg_MinLotOpenOrderFxCore * MathPow(InpFatorFxCore, vg_CountOrdersFxCore), vg_QtdDigitsFxCore), Ask, Blue);
            if (vg_TicketFxCore > 0) {
               vg_CountOrdersFxCore++;
               vg_OrderTotalFxCore = OrdersTotal();
               for (vg_PosFxCore = 0; vg_PosFxCore < vg_OrderTotalFxCore; vg_PosFxCore++) {
                  OrderSelect(vg_PosFxCore, SELECT_BY_POS, MODE_TRADES);
                  if (OrderSymbol() != Symbol() || OrderMagicNumber() != InpMagicNumberFxCore) continue;
                  if (OrderTicket() != vg_TicketFxCore) OrderClose(OrderTicket(), OrderLots(), Bid, 3, CLR_NONE);
               }
            }
         }
         if (InpHabilitaSomaFxCore) {
            if (NormalizeDouble(vg_MinLotOpenOrderFxCore + (GetLastLotFxCore() + InpLoteSomaFxCore), vg_QtdDigitsFxCore) > vg_MaxLotFxCore) return (0);
            vg_TicketFxCore = OpenOrdersFxCore(OP_BUY, NormalizeDouble(GetLastLotFxCore() + InpLoteSomaFxCore, vg_QtdDigitsFxCore), Ask, Blue);
            if (vg_TicketFxCore > 0) {
               vg_CountOrdersFxCore++;
               vg_OrderTotalFxCore = OrdersTotal();
               for (vg_PosFxCore = 0; vg_PosFxCore < vg_OrderTotalFxCore; vg_PosFxCore++) {
                  OrderSelect(vg_PosFxCore, SELECT_BY_POS, MODE_TRADES);
                  if (OrderSymbol() != Symbol() || OrderMagicNumber() != InpMagicNumberFxCore) continue;
                  if (OrderTicket() != vg_TicketFxCore) OrderClose(OrderTicket(), OrderLots(), Bid, 3, CLR_NONE);
               }
            }
         }
      }
      if (vg_TipoOrderFxCore == OP_SELL) {
         if (Bid < vg_LastOrdemOpenPriceFxCore + InpStopLevelFxCore * vg_PointFxCore) return (0);
         if (InpHabilitaFatorFxCore) {
            if (NormalizeDouble(vg_MinLotOpenOrderFxCore * MathPow(InpFatorFxCore, vg_CountOrdersFxCore), vg_QtdDigitsFxCore) > vg_MaxLotFxCore) return (0);
            vg_TicketFxCore = OpenOrdersFxCore(OP_SELL, NormalizeDouble(vg_MinLotOpenOrderFxCore * MathPow(InpFatorFxCore, vg_CountOrdersFxCore), vg_QtdDigitsFxCore), Bid, Red);
            if (vg_TicketFxCore > 0) {
               vg_CountOrdersFxCore++;
               vg_OrderTotalFxCore = OrdersTotal();
               for (vg_PosFxCore = 0; vg_PosFxCore < vg_OrderTotalFxCore; vg_PosFxCore++) {
                  OrderSelect(vg_PosFxCore, SELECT_BY_POS, MODE_TRADES);
                  if (OrderSymbol() != Symbol() || OrderMagicNumber() != InpMagicNumberFxCore) continue;
                  if (OrderTicket() != vg_TicketFxCore) OrderClose(OrderTicket(), OrderLots(), Ask, 3, CLR_NONE);
               }
            }
         }
         if (InpHabilitaSomaFxCore) {
            if (NormalizeDouble(vg_MinLotOpenOrderFxCore + (GetLastLotFxCore() + InpLoteSomaFxCore), vg_QtdDigitsFxCore) > vg_MaxLotFxCore) return (0);
            vg_TicketFxCore = OpenOrdersFxCore(OP_SELL, NormalizeDouble(vg_MinLotOpenOrderFxCore + InpLoteSomaFxCore * vg_CountOrdersFxCore, vg_QtdDigitsFxCore), Bid, Blue);
            if (vg_TicketFxCore > 0) {
               vg_CountOrdersFxCore++;
               vg_OrderTotalFxCore = OrdersTotal();
               for (vg_PosFxCore = 0; vg_PosFxCore < vg_OrderTotalFxCore; vg_PosFxCore++) {
                  OrderSelect(vg_PosFxCore, SELECT_BY_POS, MODE_TRADES);
                  if (OrderSymbol() != Symbol() || OrderMagicNumber() != InpMagicNumberFxCore) continue;
                  if (OrderTicket() != vg_TicketFxCore) OrderClose(OrderTicket(), OrderLots(), Ask, 3, CLR_NONE);
               }
            }
         }
      }
   }
   return (0);
}

//-------------------------------------------------------------------------//
int VerificandoAberturaOrdemFxCore() {
   if (GetTotalProfitFxCore() >= vg_CloseProfitFxCore) CloseOrdersFxCore();
   if (CountOrdersFxCore() == 0 && GetLastLotFxCore() == 0.0) {
      if (GetSinalFxCore() == -15) {
         
         if (OpenOrdersFxCore(OP_BUY, vg_MinLotOpenOrderFxCore, Ask, Blue) > 0) return (0);
      }
      if (GetSinalFxCore() == 15) {
        
         if (OpenOrdersFxCore(OP_SELL, vg_MinLotOpenOrderFxCore, Bid, Red) > 0) return (0);
      }
   }
   if (CountOrdersFxCore() == 1 && GetLastLotFxCore() == vg_MinLotOpenOrderFxCore) {
      vg_TipoOrderFxCore = -1;
      vg_LastOrdemOpenPriceFxCore = 0;
      vg_OrderTotalFxCore = OrdersTotal();
      for (vg_PosFxCore = 0; vg_PosFxCore < vg_OrderTotalFxCore; vg_PosFxCore++) {
         OrderSelect(vg_PosFxCore, SELECT_BY_POS, MODE_TRADES);
         if (OrderSymbol() != Symbol() || OrderMagicNumber() != InpMagicNumberFxCore) continue;
         vg_TipoOrderFxCore = OrderType();
         vg_LastOrdemOpenPriceFxCore = OrderOpenPrice();
      }
      if (vg_TipoOrderFxCore == OP_BUY) {
         for (vg_PosFxCore = 1; vg_PosFxCore <= InpMaxOrderFxCore; vg_PosFxCore++) {
            if (InpHabilitaFatorFxCore) {
               if (NormalizeDouble(vg_MinLotOpenOrderFxCore * MathPow(InpFatorFxCore, vg_PosFxCore), vg_QtdDigitsFxCore) > vg_MaxLotFxCore) return (0);
               OpenOrdersFxCore(OP_BUYLIMIT, NormalizeDouble(vg_MinLotOpenOrderFxCore * MathPow(InpFatorFxCore, vg_PosFxCore), vg_QtdDigitsFxCore), Ask - InpStopLevelFxCore * vg_PosFxCore * vg_PointFxCore, Blue);
            }
            if (InpHabilitaSomaFxCore) {
               if (NormalizeDouble(vg_MinLotOpenOrderFxCore + InpLoteSomaFxCore * vg_PosFxCore, vg_QtdDigitsFxCore) > vg_MaxLotFxCore) return (0);
               OpenOrdersFxCore(OP_BUYLIMIT, NormalizeDouble(vg_MinLotOpenOrderFxCore + InpLoteSomaFxCore * vg_PosFxCore, vg_QtdDigitsFxCore), Ask - InpStopLevelFxCore * vg_PosFxCore * vg_PointFxCore, Blue);
            }
         }
      }
      if (vg_TipoOrderFxCore == OP_SELL) {
         for (vg_PosFxCore = 1; vg_PosFxCore <= InpMaxOrderFxCore; vg_PosFxCore++) {
            if (InpHabilitaFatorFxCore) {
               if (NormalizeDouble(vg_MinLotOpenOrderFxCore * MathPow(InpFatorFxCore, vg_PosFxCore), vg_QtdDigitsFxCore) > vg_MaxLotFxCore) return (0);
               OpenOrdersFxCore(OP_SELLLIMIT, NormalizeDouble(vg_MinLotOpenOrderFxCore * MathPow(InpFatorFxCore, vg_PosFxCore), vg_QtdDigitsFxCore), Bid + InpStopLevelFxCore * vg_PosFxCore * vg_PointFxCore, Red);
            }
            if (InpHabilitaSomaFxCore) {
               if (NormalizeDouble(vg_MinLotOpenOrderFxCore + InpLoteSomaFxCore * vg_PosFxCore, vg_QtdDigitsFxCore) > vg_MaxLotFxCore) return (0);
               OpenOrdersFxCore(OP_SELLLIMIT, NormalizeDouble(vg_MinLotOpenOrderFxCore + InpLoteSomaFxCore * vg_PosFxCore, vg_QtdDigitsFxCore), Bid + InpStopLevelFxCore * vg_PosFxCore * vg_PointFxCore, Blue);
            }
         }
      }
   }
   return (0);
}
