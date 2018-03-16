#property copyright "Copyright © 2013, http://cmillion.narod.ru"
#property link      "cmillion@narod.ru"

extern int Step = 20;
extern double Lots = 0.1;
extern double RiskPercent = 0.01;
extern int N_1 = 5;
extern int N_2 = 10;
extern double K_Lot_1 = 2.0;
extern double K_Lot_2 = 1.5;
extern double K_Lot_3 = 1.1;
extern int DigitsLot = 2;
extern int OrdersNoTP = 2;
extern int Minprofit = 2;
extern string _____________ = "Filter Time";
extern int TimeStart = 0;
extern int TimeEnd = 24;
extern int FridayHourClose = 16;
extern double ProfitPercentClose = 0.0;
extern string ____________ = "";
extern bool DrawInfo = TRUE;
int G_fontsize_180 = 10;
int Gi_184 = 65280;
extern int Magic = 1000;
string G_comment_196 = "cm_head_on";
double Gd_212;
double Gd_220;
double G_price_228;
double G_price_236;
double Gd_260;
double Gd_268;
double Gd_276;
double Gd_unused_284 = 0.0000000000123;
double Gd_292 = 0.0000000000222;
string Gs_300;
string Gs_308;
int G_slippage_332 = 3;

// E37F0136AA3FFAF149B351F6A4C948E9
int init() {
   int Li_0;
   if (Digits == 3 || Digits == 5) {
      Step = 10 * Step;
      G_slippage_332 = 30;
   }
   Gd_220 = MarketInfo(Symbol(), MODE_MINLOT);
   Gd_212 = MarketInfo(Symbol(), MODE_MAXLOT);
   Gs_308 = " " + AccountCurrency();
   if (DrawInfo) {
      Li_0 = 30;
      f0_8("infoIsTradeAllowed", "", 10, Li_0, Gray, 1);
      Li_0 += 2.5 * G_fontsize_180;
      f0_8("infoBalance", "", 10, Li_0, Gray, 1);
      Li_0 += 1.5 * G_fontsize_180;
      f0_8("infoEquity", "", 10, Li_0, Gray, 1);
      Li_0 += 1.5 * G_fontsize_180;
      f0_8("infoFreeMargin", "", 10, Li_0, Gray, 1);
      Li_0 += 2.5 * G_fontsize_180;
      f0_8("infoProfit", "", 10, Li_0, Gray, 1);
      Li_0 += 2.5 * G_fontsize_180;
      f0_8("infoОрдеров Buy", "", 10, Li_0, Gray, 1);
      Li_0 += 1.5 * G_fontsize_180;
      f0_8("infoОрдеров Buy1", "", 10, Li_0, Gray, 1);
      Li_0 += 2.5 * G_fontsize_180;
      f0_8("infoОрдеров Sell", "", 10, Li_0, Gray, 1);
      Li_0 += 1.5 * G_fontsize_180;
      f0_8("infoОрдеров Sell1", "", 10, Li_0, Gray, 1);
      Li_0 += 2.5 * G_fontsize_180;
      f0_8("info Max Loss", "", 10, Li_0, Gray, 1);
      Li_0 += 1.5 * G_fontsize_180;
      f0_8("info Profit 1", "", 10, Li_0, Gray, 1);
      Li_0 += 1.5 * G_fontsize_180;
      Li_0 = 30;
      f0_8("infoпараметры 1", "Параметры", 10, Li_0, White, 0);
      Li_0 += 2.5 * G_fontsize_180;
      f0_8("infoпараметры 2", StringConcatenate("Step ", Step), 10, Li_0, Gi_184, 0);
      Li_0 += 2.0 * G_fontsize_180;
      f0_8("infoпараметры 5", "Lot ", 10, Li_0, MediumBlue, 0);
      Li_0 += 1.5 * G_fontsize_180;
      if (Lots != 0.0) Gs_300 = DoubleToStr(Lots, DigitsLot);
      else Gs_300 = StringConcatenate(RiskPercent, " % ");
      if (K_Lot_1 != 1.0) Gs_300 = StringConcatenate(Gs_300, " х ", K_Lot_1);
      if (K_Lot_2 != 1.0) Gs_300 = StringConcatenate(Gs_300, " х ", K_Lot_2);
      if (K_Lot_3 != 1.0) Gs_300 = StringConcatenate(Gs_300, " х ", K_Lot_3);
      f0_8("infoпараметры 6", Gs_300, 10, Li_0, Gi_184, 0);
      Li_0 += 2.0 * G_fontsize_180;
      f0_8("infoпараметры 7", "Время работы", 10, Li_0, MediumBlue, 0);
      Li_0 += 1.5 * G_fontsize_180;
      f0_8("infoпараметры 8", StringConcatenate(TimeStart, ":00 до ", TimeEnd, ":00"), 10, Li_0, Gi_184, 0);
      Li_0 += 1.5 * G_fontsize_180;
      f0_8("infoпараметры 9", StringConcatenate("В пт до ", FridayHourClose, ":00"), 10, Li_0, Gi_184, 0);
      Li_0 += 1.5 * G_fontsize_180;
   }
   f0_8("Copyright", "Copyright © 2012, http://cmillion.narod.ru", 5, 5, Gray, 3);
   Comment("Cтарт ", TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES));
   return (0);
}
                                                                               
// EA2B2676C28C0DB26D39331A336C6B92
int start() {
   bool Li_4;
   int cmd_12;
   int Li_16;
   int Li_20;
   double Ld_24;
   double Ld_32;
   double Ld_40;
   double Ld_unused_48;
   double Ld_unused_56;
   double order_lots_64;
   double order_lots_72;
   double order_lots_80;
   double Ld_88;
   double Ld_96;
   double Ld_104;
   double Ld_112;
   double Ld_120;
   double Ld_128;
   double Ld_136;
   double Ld_144;
   double Ld_152;
   double Ld_160;
   double Ld_196;
   double maxlot_196;
   if (!IsDllsAllowed()) {
      Comment("Включите разрешить использование DLL");
      return;
   }
   if (!IsTradeAllowed()) {
      if (!(DrawInfo)) return (0);
      f0_8("infoIsTradeAllowed", "Торговля запрещена", 5, 0, Yellow, 1);
      return (0);
   }
   if (DrawInfo) f0_8("infoIsTradeAllowed", "Торговля разрешена", 5, 0, White, 1);
   int hour_0 = Hour();
   if (TimeStart < TimeEnd && hour_0 >= TimeStart && hour_0 < TimeEnd) Li_4 = TRUE;
   else {
      if (TimeStart > TimeEnd && hour_0 >= TimeStart || hour_0 < TimeEnd) Li_4 = TRUE;
      else Li_4 = FALSE;
   }
   if (Li_4 && DayOfWeek() == 5)
      if (FridayHourClose <= hour_0) Li_4 = FALSE;
   int Li_unused_8 = MarketInfo(Symbol(), MODE_STOPLEVEL);
   double tickvalue_168 = MarketInfo(Symbol(), MODE_TICKVALUE);
   for (int pos_176 = 0; pos_176 < OrdersTotal(); pos_176++) {
      if (OrderSelect(pos_176, SELECT_BY_POS, MODE_TRADES)) {
         if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic) {
            cmd_12 = OrderType();
            Ld_24 = NormalizeDouble(OrderStopLoss(), Digits);
            Ld_32 = NormalizeDouble(OrderTakeProfit(), Digits);
            Ld_40 = NormalizeDouble(OrderOpenPrice(), Digits);
            order_lots_64 = OrderLots();
            Ld_unused_48 = Ld_24;
            Ld_unused_56 = Ld_32;
            if (cmd_12 == OP_BUY) {
               Li_16++;
               Ld_152 += Ld_40 * order_lots_64;
               Ld_136 += order_lots_64;
               if (order_lots_72 < order_lots_64) order_lots_72 = order_lots_64;
               Ld_120 += OrderProfit() + OrderSwap() + OrderCommission();
               if (Ld_88 > Ld_40 || Ld_88 == 0.0) Ld_88 = Ld_40;
               if (Ld_112 < Ld_40 || Ld_112 == 0.0) Ld_112 = Ld_40;
            }
            if (cmd_12 == OP_SELL) {
               Li_20++;
               Ld_160 += Ld_40 * order_lots_64;
               Ld_144 += order_lots_64;
               if (order_lots_80 < order_lots_64) order_lots_80 = order_lots_64;
               Ld_128 += OrderProfit() + OrderSwap() + OrderCommission();
               if (Ld_104 > Ld_40 || Ld_104 == 0.0) Ld_104 = Ld_40;
               if (Ld_96 < Ld_40 || Ld_96 == 0.0) Ld_96 = Ld_40;
            }
         }
      }
   }
   if (!Li_4)
      if (Li_16 + Li_20 == 0) return;
   double Ld_180 = AccountBalance();
   double Ld_188 = Ld_120 + Ld_128;
   if (100.0 * Ld_188 / Ld_180 >= ProfitPercentClose && ProfitPercentClose != 0.0) {
      f0_2();
      return;
   }
   if (Gd_260 > Ld_188) {
      Gd_260 = Ld_188;
      f0_8("info Max Loss", StringConcatenate("Max Loss ", DoubleToStr(Gd_260, 2), Gs_308), 5, 0, Red, 1);
   }
   if (Gd_276 > Ld_136 + Ld_144) {
      Gd_268 += Gd_276 - (Ld_136 + Ld_144);
      f0_8("info Profit 1", StringConcatenate("Sum Lot ", DoubleToStr(Gd_268, 2)), 5, 0, Gi_184, 1);
   }
   Gd_276 = Ld_136 + Ld_144;
   if (DrawInfo) {
      ObjectDelete("infoБезубыток Buy");
      ObjectDelete("infoБезубыток Sell");
      ObjectDelete("info Безубыток Buy");
      ObjectDelete("info Безубыток Sell");
   }
   if (Li_16 > 0) {
      G_price_228 = NormalizeDouble(Ld_152 / Ld_136 + Minprofit * Point, Digits);
      if (DrawInfo) {
         ObjectCreate("infoБезубыток Buy", OBJ_ARROW, 0, Time[0], G_price_228, 0, 0, 0, 0);
         ObjectSet("infoБезубыток Buy", OBJPROP_ARROWCODE, SYMBOL_RIGHTPRICE);
         ObjectSet("infoБезубыток Buy", OBJPROP_COLOR, Blue);
      }
   } else G_price_228 = 0;
   if (Li_20 > 0) {
      G_price_236 = NormalizeDouble(Ld_160 / Ld_144 - Minprofit * Point, Digits);
      if (DrawInfo) {
         ObjectCreate("infoБезубыток Sell", OBJ_ARROW, 0, Time[0], G_price_236, 0, 0, 0, 0);
         ObjectSet("infoБезубыток Sell", OBJPROP_ARROWCODE, SYMBOL_RIGHTPRICE);
         ObjectSet("infoБезубыток Sell", OBJPROP_COLOR, Red);
      }
   } else G_price_236 = 0;
   if (Li_20 > 0 && Li_16 > 0 && Bid > G_price_228 && Ask < G_price_236) f0_2();
   f0_8("infoBalance", StringConcatenate("Balance ", DoubleToStr(AccountBalance(), 2), Gs_308), 0, 0, Gi_184, 1);
   f0_8("infoEquity", StringConcatenate("Equity ", DoubleToStr(AccountEquity(), 2), Gs_308), 0, 0, Gi_184, 1);
   f0_8("infoFreeMargin", StringConcatenate("Free ", DoubleToStr(AccountFreeMargin(), 2), Gs_308), 0, 0, Gi_184, 1);
   f0_8("infoProfit", StringConcatenate("Profit ", DoubleToStr(Ld_188, 2), Gs_308, " ", DoubleToStr(100.0 * Ld_188 / Ld_180, 2), " %"), 0, 0, f0_7(Ld_188 >= 0.0, 65280,
      255), 1);
   f0_8("infoОрдеров Sell", StringConcatenate("Sell ", Li_20, "    Lot ", DoubleToStr(Ld_144, 2)), 5, 30, f0_7(Ld_128 < 0.0, 255, 65280), 2);
   f0_8("infoОрдеров Sell1", StringConcatenate("Profit ", DoubleToStr(Ld_128, 2), Gs_308), 5, 30, f0_7(Ld_128 < 0.0, 255, 65280), 2);
   f0_8("infoОрдеров Buy", StringConcatenate("Buy ", Li_16, "    Lot ", DoubleToStr(Ld_136, 2)), 5, 15, f0_7(Ld_120 < 0.0, 255, 65280), 2);
   f0_8("infoОрдеров Buy1", StringConcatenate("Profit ", DoubleToStr(Ld_120, 2), Gs_308), 5, 15, f0_7(Ld_120 < 0.0, 255, 65280), 2);
   if (Bid > High[1]) {
      if (Li_16 == 0) {
         if (Li_4) {
            maxlot_196 = f0_5();
            if (Ld_196 > 0.0) f0_3(OP_BUY, maxlot_196, NormalizeDouble(Ask, Digits));
            else Comment("Недостаточно средств для открытия " + DoubleToStr(maxlot_196, 2) + " лота buylimit");
         }
      } else {
         if (Li_16 < N_1) maxlot_196 = NormalizeDouble(order_lots_72 * K_Lot_1, DigitsLot);
         else {
            if (Li_16 < N_2) maxlot_196 = NormalizeDouble(order_lots_72 * K_Lot_2, DigitsLot);
            else maxlot_196 = NormalizeDouble(order_lots_72 * K_Lot_3, DigitsLot);
         }
         if (Ld_196 > Gd_212) Ld_196 = Gd_212;
         if (Ld_196 >= Gd_220) {
            if (Ask <= Ld_88 - Step * Point) f0_3(OP_BUY, Ld_196, NormalizeDouble(Ask, Digits));
            if (Bid >= Ld_112 + Step * Point && Li_20 - Li_16 > OrdersNoTP) {
               Ld_196 = f0_5();
               if (Ld_196 > Gd_212) Ld_196 = Gd_212;
               f0_3(OP_BUY, Ld_196, NormalizeDouble(Ask, Digits));
            }
         }
      }
   }
   if (Bid < Low[1]) {
      if (Li_20 == 0) {
         if (Li_4) {
            Ld_196 = f0_5();
            if (Ld_196 > 0.0) f0_3(OP_SELL, Ld_196, NormalizeDouble(Bid, Digits));
            else Comment("Недостаточно средств для открытия " + DoubleToStr(Ld_196, 0) + " лота selllimit");
         }
      } else {
         if (Li_20 < N_1) Ld_196 = NormalizeDouble(order_lots_80 * K_Lot_1, DigitsLot);
         else {
            if (Li_20 < N_2) Ld_196 = NormalizeDouble(order_lots_80 * K_Lot_2, DigitsLot);
            else Ld_196 = NormalizeDouble(order_lots_80 * K_Lot_3, DigitsLot);
         }
         if (Ld_196 > Gd_212) Ld_196 = Gd_212;
         if (Ld_196 >= Gd_220) {
            if (Bid >= Ld_96 + Step * Point) f0_3(OP_SELL, Ld_196, NormalizeDouble(Bid, Digits));
            if (Ask <= Ld_104 - Step * Point && Li_16 - Li_20 > OrdersNoTP) {
               Ld_196 = f0_5();
               if (Ld_196 > Gd_212) Ld_196 = Gd_212;
               f0_3(OP_SELL, Ld_196, NormalizeDouble(Bid, Digits));
            }
         }
      }
   }
   return (0);
}
                                                                       
// 52D46093050F38C27267BCE42543EF60
int deinit() {
   if (!IsTesting()) f0_0("info");
   return (0);
}
                                                                         
// 2208AB04CCD91A8303FE0D7679EA198F
int f0_2() {
   int error_4;
   int Li_8;
   int cmd_12;
   int ticket_20;
   int ticket_24;
   int count_28;
   bool is_closed_0 = TRUE;
   while (Gd_292 > 0.0) {
      RefreshRates();
      ticket_20 = 0;
      ticket_24 = 0;
      for (int pos_16 = OrdersTotal() - 1; pos_16 >= 0; pos_16--) {
         if (OrderSelect(pos_16, SELECT_BY_POS)) {
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic) {
               cmd_12 = OrderType();
               if (cmd_12 == OP_BUY) ticket_20 = OrderTicket();
               if (cmd_12 == OP_SELL) ticket_24 = OrderTicket();
            }
         }
         if (ticket_20 != 0 && ticket_24 != 0) {
            OrderCloseBy(ticket_20, ticket_24);
            break;
         }
      }
      if (ticket_20 == 0 || ticket_24 == 0) break;
   }
   if (ticket_20 == 0 && ticket_24 == 0) return (1);
   while (Gd_292 > 0.0) {
      for (pos_16 = OrdersTotal() - 1; pos_16 >= 0; pos_16--) {
         if (OrderSelect(pos_16, SELECT_BY_POS)) {
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic) {
               cmd_12 = OrderType();
               if (cmd_12 == OP_BUY) is_closed_0 = OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(Bid, Digits), 3, Blue);
               if (cmd_12 == OP_SELL) is_closed_0 = OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(Ask, Digits), 3, Red);
               if (!is_closed_0) {
                  error_4 = GetLastError();
                  if (error_4 >= 2/* COMMON_ERROR */) {
                     if (error_4 == 129/* INVALID_PRICE */) {
                        RefreshRates();
                        continue;
                     }
                     if (error_4 == 146/* TRADE_CONTEXT_BUSY */) {
                        if (!(IsTradeContextBusy())) continue;
                        Sleep(2000);
                        continue;
                     }
                     Print("Ошибка ", error_4, " закрытия ордера N ", OrderTicket(), "     ", TimeToStr(TimeCurrent(), TIME_SECONDS));
                  }
               }
            }
         }
      }
      count_28 = 0;
      for (pos_16 = 0; pos_16 < OrdersTotal(); pos_16++) {
         if (OrderSelect(pos_16, SELECT_BY_POS)) {
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic) {
               cmd_12 = OrderType();
               if (cmd_12 == OP_BUY || cmd_12 == OP_SELL) count_28++;
            }
         }
      }
      if (count_28 == 0) break;
      Li_8++;
      if (Li_8 > 10) {
         Alert(Symbol(), " Не удалось закрыть все сделки, осталось еще ", count_28);
         return (0);
      }
      Sleep(1000);
      RefreshRates();
   }
   return (1);
}
                                                                     
// CB5FEB1B7314637725A2E73BDC9F7295
int f0_7(bool Ai_0, int Ai_4, int Ai_8) {
   if (Ai_0) return (Ai_4);
   return (Ai_8);
}
                                                                       
// 3CC94C06370D2627C52A1F5EBCAEC673
int f0_3(int A_cmd_0, double A_lots_4, double A_price_12) {
   int Li_20;
   while (true) {
      RefreshRates();
      if (OrderSend(Symbol(), A_cmd_0, A_lots_4, A_price_12, G_slippage_332, 0, 0, G_comment_196, Magic, 0, f0_4(A_cmd_0)) == -1) {
         Print("OrderSend Error ", GetLastError(), " Lot ", A_lots_4);
         Sleep(1000);
      } else return (1);
      Li_20++;
      if (Li_20 <= 10) continue;
      break;
   }
   return (0);
}
                                                                     
// 8F1AC13E8F78925727604F020A757F75
int f0_4(int Ai_0) {
   if (Ai_0 == 0) return (65280);
   if (Ai_0 == 2) return (16711680);
   if (Ai_0 == 1) return (2763429);
   if (Ai_0 == 3) return (255);
   return (8421504);
}
                                                                       
// DABC5DBF75D151A587AD2276CD6849E6
void f0_8(string A_name_0, string A_text_8, int A_x_16, int A_y_20, color A_color_24, int A_corner_28) {
   if (DrawInfo) {
      if (ObjectFind(A_name_0) == -1) {
         ObjectCreate(A_name_0, OBJ_LABEL, 0, 0, 0);
         ObjectSet(A_name_0, OBJPROP_CORNER, A_corner_28);
         ObjectSet(A_name_0, OBJPROP_XDISTANCE, A_x_16);
         ObjectSet(A_name_0, OBJPROP_YDISTANCE, A_y_20);
      }
      ObjectSetText(A_name_0, A_text_8, G_fontsize_180, "Arial", A_color_24);
   }
}
                                                                         
// 995300535F52F2AF36E77BEA0739E9C5
double f0_5() {
   if (Lots > 0.0) return (Lots);
   double Ld_ret_0 = NormalizeDouble(AccountBalance() * RiskPercent / 100.0 / MarketInfo(Symbol(), MODE_MARGINREQUIRED), DigitsLot);
   if (Ld_ret_0 > Gd_212) Ld_ret_0 = Gd_212;
   if (Ld_ret_0 < Gd_220) Ld_ret_0 = Gd_220;
   return (Ld_ret_0);
}

// 01FDFC7FC92C3F23C8A326305AA47634
int f0_0(string As_0) {
   string name_12;
   string Ls_20;
   for (int Li_8 = ObjectsTotal() - 1; Li_8 >= 0; Li_8--) {
      name_12 = ObjectName(Li_8);
      Ls_20 = StringSubstr(name_12, 0, StringLen(As_0));
      if (Ls_20 == As_0) ObjectDelete(name_12);
   }
   Comment("");
   return (0);
}