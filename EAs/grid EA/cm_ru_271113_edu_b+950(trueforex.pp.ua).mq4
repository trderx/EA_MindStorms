/*
   G e n e r a t e d  by ex4-to-mq4 decompiler 4.0.500.3
   E-mail :  p u R EBe am@gM A IL. c o m
*/
#property copyright "Copyright © 2013, http://cmillion.ru"
#property link      "cmillion@narod.ru"

extern double PercenStart = 0.0;
extern int TF = 5;
extern int step = 20;
extern double k_lot = 1.5;
extern double lot_close = 0.05;
extern int MinProfit = 5;
extern bool включение_лока = FALSE;
extern double просадка_для_открытия_лока = 65.0;
extern double LotPercent = 50.0;
extern int StepLock = 25;
extern int StepModify = 5;
extern int NoLoss = 5;
extern string ID = "cm-ru21";
extern bool Перекрывать_противоположные = TRUE;
extern double К_перекрытия = 3.0;
//extern int key = 0;
int Gi_168 = 2;
bool Gi_172 = TRUE;
int G_fontsize_176 = 10;
int Gi_180 = 65280;
double Gd_184;
double Gd_192;
double G_tickvalue_200;
string Gs_208;
int Gi_unused_216;

// E37F0136AA3FFAF149B351F6A4C948E9
int init() {
   G_tickvalue_200 = MarketInfo(Symbol(), MODE_TICKVALUE);
   if (Digits == 3 || Digits == 5) {
      step = 10 * step;
      MinProfit = 10 * MinProfit;
      StepLock = 10 * StepLock;
      StepModify = 10 * StepModify;
   }
   if (LotPercent > 100.0) LotPercent = 100;
   if (LotPercent < 0.0) LotPercent = 0;
   Gd_192 = MarketInfo(Symbol(), MODE_MINLOT);
   if (lot_close < Gd_192) lot_close = Gd_192;
   Gd_184 = MarketInfo(Symbol(), MODE_MAXLOT);
   Gi_unused_216 = MarketInfo(Symbol(), MODE_STOPLEVEL);
   Gs_208 = " " + AccountCurrency();
   f0_9("infoC", "Copyright © 2013, cmillion@narod.ru", 10, 1, Gray, 3);
   просадка_для_открытия_лока = -1.0 * просадка_для_открытия_лока;
   PercenStart = -1.0 * PercenStart;
   return (0);
}
		 		 	 	 		 					 		  	   					       	 	  					 	 	    				  	   	  	 	  	  	 	 		       	    		 		  			   			   		   	 	 				  	    		 	 		 		
// EA2B2676C28C0DB26D39331A336C6B92
int start() {
   double Ld_24;
   double Ld_32;
   double Ld_40;
   double Ld_48;
   double Ld_56;
   double Ld_64;
   double price_72;
   double lots_80;
   double Ld_88;
   double Ld_96;
   double Ld_104;
   double price_112;
   double price_120;
   double Ld_128;
   double Ld_136;
   double Ld_144;
   double Ld_152;
   double Ld_160;
   double Ld_168;
   double Ld_176;
   double Ld_184;
   double price_192;
   double price_200;
   double Ld_208;
   double Ld_216;
   double Ld_224;
   double Ld_232;
   int cmd_240;
   int Li_244;
   int Li_248;
   int ticket_252;
   int ticket_256;
   double Ld_260;
   double price_268;
   double Ld_276;
   double price_284;
   double Ld_292;
   double price_300;
   double Ld_308;
   double Ld_316;
   int Li_unused_324;
   int Li_328;
   int ticket_332;
   int ticket_336;
   int ticket_340;
   int ticket_344;
   int ticket_348;
   int Li_352;
   double price_360;
   double Ld_368;
   double Ld_384;
   double Ld_392;
   int hour_400;
   double Ld_0 = AccountBalance();
   double Ld_8 = AccountEquity();
   double free_magrin_16 = AccountFreeMargin();
   f0_9("infoBalance", StringConcatenate("Balance ", DoubleToStr(Ld_0, 2), Gs_208), 10, 35, Gi_180, 1);
   f0_9("infoFreeMargin", StringConcatenate("Free ", DoubleToStr(free_magrin_16, 2), Gs_208), 10, 75, Gi_180, 1);
   for (int pos_356 = 0; pos_356 < OrdersTotal(); pos_356++) {
      if (OrderSelect(pos_356, SELECT_BY_POS, MODE_TRADES)) {
         if (OrderSymbol() == Symbol()) {
            cmd_240 = OrderType();
            lots_80 = OrderLots();
            ticket_340 = OrderTicket();
            price_72 = NormalizeDouble(OrderOpenPrice(), Digits);
            Ld_260 = NormalizeDouble(OrderStopLoss(), Digits);
            Ld_88 = OrderProfit() + OrderSwap() + OrderCommission();
            if (StringFind(OrderComment(), "lock") != -1) {
               Li_352++;
               Li_unused_324 = ticket_340;
               f0_4("lock", OrderOpenTime(), price_72, 0, 73, Yellow);
               if (cmd_240 == OP_BUY) {
                  if (NoLoss != 0 && Ld_260 == 0.0) {
                     price_268 = NormalizeDouble(price_72 + NoLoss * Point, Digits);
                     if (price_268 > Ld_260 && price_268 > price_72)
                        if (!OrderModify(OrderTicket(), price_72, price_268, OrderTakeProfit(), 0, White)) Print("Error OrderModify ", GetLastError());
                  }
               }
               if (cmd_240 == OP_SELL) {
                  if (NoLoss != 0 && Ld_260 == 0.0) {
                     price_268 = NormalizeDouble(price_72 - NoLoss * Point, Digits);
                     if (price_268 < Ld_260 || price_268 == 0.0 && price_268 < price_72)
                        if (!OrderModify(OrderTicket(), price_72, price_268, OrderTakeProfit(), 0, White)) Print("Error OrderModify ", GetLastError());
                  }
               }
               if (cmd_240 > OP_SELL && (!включение_лока)) OrderDelete(ticket_340);
            }
            if (StringFind(OrderComment(), ID) != -1) {
               Li_328++;
               if (cmd_240 == OP_BUY) {
                  if (price_192 > price_72 || price_192 == 0.0) {
                     price_192 = price_72;
                     Ld_224 = lots_80;
                  }
                  Ld_24 += price_72 * lots_80;
                  Ld_208 += Ld_88;
                  Ld_160 += lots_80;
                  Li_244++;
               }
               if (cmd_240 != OP_SELL) continue;
               if (price_200 < price_72 || price_200 == 0.0) {
                  price_200 = price_72;
                  Ld_232 = lots_80;
               }
               Ld_32 += price_72 * lots_80;
               Ld_216 += Ld_88;
               Ld_168 += lots_80;
               Li_248++;
               continue;
            }
            if (cmd_240 == OP_BUY) {
               if (Ld_144 > Bid - price_72 || Ld_144 == 0.0) {
                  Ld_144 = Bid - price_72;
                  ticket_252 = ticket_340;
                  price_112 = price_72;
                  if (lots_80 > lot_close) {
                     Ld_56 = Ld_88 / lots_80 * lot_close;
                     Ld_128 = lot_close;
                     Ld_40 = price_72 * lot_close;
                  } else {
                     Ld_56 = Ld_88;
                     Ld_128 = lots_80;
                     Ld_40 = price_72 * lots_80;
                  }
               }
               Ld_96 += Ld_88;
               Ld_176 += lots_80;
               if (Ld_88 > 0.0 && lots_80 >= lot_close * К_перекрытия && Ld_316 < Ld_88 / lots_80 * lot_close * К_перекрытия || Ld_316 == 0.0) {
                  Ld_316 = Ld_88 / lots_80 * lot_close * К_перекрытия;
                  ticket_344 = ticket_340;
               }
            }
            if (cmd_240 == OP_SELL) {
               if (Ld_152 > price_72 - Ask || Ld_152 == 0.0) {
                  Ld_152 = price_72 - Ask;
                  ticket_256 = ticket_340;
                  price_120 = price_72;
                  if (lots_80 > lot_close) {
                     Ld_64 = Ld_88 / lots_80 * lot_close;
                     Ld_136 = lot_close;
                     Ld_48 = price_72 * lot_close;
                  } else {
                     Ld_64 = Ld_88;
                     Ld_136 = lots_80;
                     Ld_48 = price_72 * lots_80;
                  }
               }
               Ld_104 += Ld_88;
               Ld_184 += lots_80;
               if (Ld_88 > 0.0 && lots_80 >= lot_close * К_перекрытия && Ld_308 < Ld_88 / lots_80 * lot_close * К_перекрытия || Ld_308 == 0.0) {
                  Ld_308 = Ld_88 / lots_80 * lot_close * К_перекрытия;
                  ticket_348 = ticket_340;
               }
            }
            if (cmd_240 == OP_BUYSTOP) {
               Ld_276 = lots_80;
               ticket_336 = OrderTicket();
               price_284 = price_72;
            }
            if (cmd_240 == OP_SELLSTOP) {
               Ld_292 = lots_80;
               ticket_332 = OrderTicket();
               price_300 = price_72;
            }
         }
      }
   }
   Ld_88 = Ld_208 + Ld_96 + Ld_216 + Ld_104;
   double Ld_376 = 100.0 * (Ld_88 / Ld_0);
   f0_9("infoEquity", StringConcatenate("Profit ", DoubleToStr(Ld_88, 2), Gs_208, "  ", DoubleToStr(Ld_376, 2), " %"), 10, 55, f0_8(Ld_376 < просадка_для_открытия_лока,
      255, 65280), 1);
   if (price_192 == 0.0) {
      price_192 = price_112;
      Ld_224 = lot_close;
   }
   if (price_200 == 0.0) {
      price_200 = price_120;
      Ld_232 = lot_close;
   }
   f0_9("infoProfitB", StringConcatenate("Profit Buy ", DoubleToStr(Ld_96 + Ld_208, 2), Gs_208), 10, 100, f0_8(Ld_96 + Ld_208 > 0.0, 65280, 255), 1);
   f0_9("infoProfitS", StringConcatenate("Profit Sell ", DoubleToStr(Ld_104 + Ld_216, 2), Gs_208), 10, 115, f0_8(Ld_104 + Ld_216 > 0.0, 65280, 255), 1);
   if (ticket_252 > 0) f0_9("infoLossB", StringConcatenate("убыточный Buy ", ticket_252, " ", DoubleToStr(Ld_144 / Point, 0), "п"), 10, 140, Red, 1);
   else f0_9("infoLossB", "убыточных Buy нет", 10, 140, Gray, 1);
   if (ticket_256 > 0) f0_9("infoLossS", StringConcatenate("убыточный Sell ", ticket_256, " ", DoubleToStr(Ld_152 / Point, 0), "п"), 10, 155, Red, 1);
   else f0_9("infoLossS", "убыточных Sell нет", 10, 155, Gray, 1);
   if (Li_244 > 0) {
      f0_9("inforBru", StringConcatenate(Li_244, " уср. Buy ", DoubleToStr(Ld_160, Gi_168), " лот ", DoubleToStr(Ld_208 + Ld_56, 2), Gs_208), 10, 180, f0_8(Ld_208 + Ld_56 > 0.0,
         65280, 255), 1);
   } else ObjectDelete("inforBru");
   if (Li_248 > 0) {
      f0_9("inforSru", StringConcatenate(Li_248, " уср. Sell ", DoubleToStr(Ld_168, Gi_168), " лот ", DoubleToStr(Ld_216 + Ld_64, 2), Gs_208), 10, 195, f0_8(Ld_216 + Ld_64 > 0.0,
         65280, 255), 1);
   } else ObjectDelete("inforSru");
   f0_9("inforB", StringConcatenate("Всего Buy ", DoubleToStr(Ld_176 + Ld_160, Gi_168), " лот"), 10, 220, Gi_180, 1);
   f0_9("inforS", StringConcatenate("Всего Sell ", DoubleToStr(Ld_184 + Ld_168, Gi_168), " лот"), 10, 235, Gi_180, 1);
   if (включение_лока) f0_9("infoLock", StringConcatenate("Lock ", Li_352, " шт"), 10, 255, Gi_180, 1);
   if (ticket_256 == 0 && ticket_252 == 0) {
      f0_9("infoIsTradeAllowed", "Ордеров требующих усреднения не существует", 10, 15, Red, 1);
      if (IsTesting()) {
         f0_2(OP_SELL, 30.0 * lot_close, NormalizeDouble(Bid, Digits), "");
         f0_2(OP_BUY, 30.0 * lot_close, NormalizeDouble(Ask, Digits), "");
         f0_6(StringConcatenate("Start ", TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES)), Time[0], Gray);
      }
   } else {
      if (PercenStart != 0.0 && Ld_376 >= PercenStart && Li_328 == 0) f0_9("infoIsTradeAllowed", StringConcatenate("просадка ", DoubleToStr(Ld_376, 2), "%, менее заданной, советник не работает"), 10, 15, Red, 1);
      else {
         if (включение_лока) {
            Ld_368 = NormalizeDouble((Ld_184 + Ld_168 - Ld_176 - Ld_160) / 100.0 * LotPercent, Gi_168);
            if (Ld_368 <= lot_close) Ld_368 = 0;
            price_360 = NormalizeDouble(Ask + StepLock * Point, Digits);
            if (price_284 != 0.0) {
               if (MathAbs(Ld_276 - Ld_368) > lot_close * К_перекрытия || Ld_376 >= 0.9 * просадка_для_открытия_лока) OrderDelete(ticket_336);
               else {
                  if (price_284 - StepModify * Point > price_360) {
                     if (!OrderModify(ticket_336, price_360, 0, 0, 0, White)) Print("Error ", GetLastError(), "   Order Modify Buy   OOP ", price_284, "->", price_360);
                     else Print("Order Buy Modify   OOP ", price_72, "->", price_360);
                  }
               }
            } else {
               if (Ld_376 < просадка_для_открытия_лока) {
                  if (Ld_368 >= Gd_192) {
                     if (AccountFreeMarginCheck(Symbol(), OP_BUY, Ld_368) > 0.0) {
                        if (OrderSend(Symbol(), OP_BUYSTOP, Ld_368, price_360, 10, 0, 0, "lock", 0, 0, Blue) == -1) Print("Ошибка ", GetLastError(), " невозможно выставить ордер BUYSTOP Lot ", DoubleToStr(Ld_368, 2), " Price ", price_360, " Ask ", Ask);
                     } else f0_9("infoLock", "Недостаточно средств для открытия лок ордера BUYSTOP", 10, 255, Red, 1);
                  }
               }
            }
            Ld_368 = NormalizeDouble((Ld_176 + Ld_160 - Ld_184 - Ld_168) / 100.0 * LotPercent, Gi_168);
            if (Ld_368 <= lot_close) Ld_368 = 0;
            price_360 = NormalizeDouble(Bid - StepLock * Point, Digits);
            if (price_300 != 0.0) {
               if (MathAbs(Ld_292 - Ld_368) > lot_close * К_перекрытия || Ld_376 >= 0.9 * просадка_для_открытия_лока) OrderDelete(ticket_332);
               else {
                  if (price_300 + StepModify * Point < price_360) {
                     if (!OrderModify(ticket_332, price_360, 0, 0, 0, White)) Print("Error ", GetLastError(), "   Order Modify Sell   OOP ", price_300, "->", price_360);
                     else Print("Order Sell Modify   OOP ", price_72, "->", price_360);
                  }
               }
            } else {
               if (Ld_376 < просадка_для_открытия_лока) {
                  if (Ld_368 >= Gd_192) {
                     if (AccountFreeMarginCheck(Symbol(), OP_SELL, Ld_368) > 0.0) {
                        if (OrderSend(Symbol(), OP_SELLSTOP, Ld_368, price_360, 10, 0, 0, "lock", 0, 0, Red) == -1) Print("Ошибка ", GetLastError(), " невозможно выставить ордер SELLSTOP Lot ", DoubleToStr(Ld_368, 2), " Price ", price_360, " Bid ", Bid);
                     } else f0_9("infoLock", "Недостаточно средств для открытия лок ордера SELLSTOP", 10, 255, Red, 1);
                  }
               }
            }
         }
         if (Ld_160 != 0.0) {
            Ld_384 = NormalizeDouble((Ld_40 + Ld_24) / (Ld_160 + Ld_128) + MinProfit * Point, Digits);
            f0_4("NLb", Time[0], Ld_384, 0, SYMBOL_RIGHTPRICE, Lime);
         }
         if (Ld_168 != 0.0) {
            Ld_392 = NormalizeDouble((Ld_48 + Ld_32) / (Ld_168 + Ld_136) - MinProfit * Point, Digits);
            f0_4("NLs", Time[0], Ld_392, 0, SYMBOL_RIGHTPRICE, Red);
         }
         if (!IsTradeAllowed()) {
            f0_9("infoIsTradeAllowed", "Торговля запрещена", 10, 15, Red, 1);
            return (0);
         }
         f0_9("infoIsTradeAllowed", "Торговля разрешена", 10, 15, Gi_180, 1);
         hour_400 = Hour();
         /*if ((!IsDemo()) && !IsTesting() && 5 * AccountNumber() - 1245 != key && StringFind(AccountName(), "Хлыстов", 0) == -1) {
            f0_9("infoIsTradeAllowed", "Вы используете демо версию", 10, 15, Red, 1);
            Comment("Уважаемый ", AccountName(), " Вы используете демо версию советника, для получения полной версии обращайтесь cmillion@narod.ru для получения Key");
         } else*/
          {
            if (Bid >= Ld_384 && Ld_384 != 0.0 && Li_244 != 0) {
               f0_3(OP_BUY, ticket_252);
               f0_5(TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES), Time[0], Bid, DoubleToStr(Ld_208 + Ld_56, 2), f0_8(Ld_208 + Ld_56 < 0.0, 255, 65280));
            }
            if (Ask <= Ld_392 && Ld_392 != 0.0 && Li_248 != 0) {
               f0_3(OP_SELL, ticket_256);
               f0_5(TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES), Time[0], Bid, DoubleToStr(Ld_216 + Ld_64, 2), f0_8(Ld_216 + Ld_64 < 0.0, 255, 65280));
            }
            if (Ld_88 > G_tickvalue_200 * (Ld_176 + Ld_160 + Ld_184 + Ld_168)) {
               f0_1();
               f0_5(TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES), Time[0], Bid, DoubleToStr(Ld_88, 2), Yellow);
            }
            if (Перекрывать_противоположные) {
               Comment("Верхний Buy ", ticket_252, "  ", DoubleToStr(Ld_56, 2), Gs_208, "  Прибыльный Sell ", ticket_348, "  ", DoubleToStr(Ld_308, 2), Gs_208, "  итого ", DoubleToStr(Ld_56 + Ld_308, 2), Gs_208, "  закрытие при ", DoubleToStr(G_tickvalue_200 * lot_close, 2), 
               "\nНижний Sell ", ticket_256, "  ", DoubleToStr(Ld_64, 2), Gs_208, "  Прибыльный Buy ", ticket_344, "  ", DoubleToStr(Ld_316, 2), Gs_208, "  итого ", DoubleToStr(Ld_64 +
                  Ld_316, 2), Gs_208, "  закрытие при ", DoubleToStr(G_tickvalue_200 * lot_close, 2));
               if (Ld_64 + Ld_316 > G_tickvalue_200 * lot_close && Ld_176 >= Ld_184 && ticket_256 != 0 && ticket_344 != 0) {
                  if (OrderSelect(ticket_256, SELECT_BY_TICKET)) {
                     lots_80 = OrderLots();
                     if (lots_80 > lot_close) lots_80 = lot_close;
                     OrderClose(ticket_256, lots_80, NormalizeDouble(Ask, Digits), 3, Red);
                     if (OrderSelect(ticket_344, SELECT_BY_TICKET)) {
                        lots_80 = OrderLots();
                        if (lots_80 > lot_close * К_перекрытия) lots_80 = lot_close * К_перекрытия;
                        OrderClose(ticket_344, lots_80, NormalizeDouble(Bid, Digits), 3, Blue);
                     }
                  }
                  f0_5(TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES), Time[0], Bid, DoubleToStr(Ld_64 + Ld_316, 2), Violet);
                  Print("<=======================>", Ld_64, " + ", Ld_316, " = ", Ld_64 + Ld_316);
               }
               if (Ld_56 + Ld_308 > G_tickvalue_200 * lot_close && Ld_176 <= Ld_184 && ticket_252 != 0 && ticket_348 != 0) {
                  if (OrderSelect(ticket_252, SELECT_BY_TICKET)) {
                     lots_80 = OrderLots();
                     if (lots_80 > lot_close) lots_80 = lot_close;
                     OrderClose(ticket_252, lots_80, NormalizeDouble(Bid, Digits), 3, Blue);
                     if (OrderSelect(ticket_348, SELECT_BY_TICKET)) {
                        lots_80 = OrderLots();
                        if (lots_80 > lot_close * К_перекрытия) lots_80 = lot_close * К_перекрытия;
                        OrderClose(ticket_348, lots_80, NormalizeDouble(Ask, Digits), 3, Red);
                     }
                  }
                  f0_5(TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES), Time[0], Bid, DoubleToStr(Ld_56 + Ld_308, 2), CadetBlue);
                  Print("<=======================>", Ld_56, " + ", Ld_308, " = ", Ld_56 + Ld_308);
               }
               if (AccountBalance() < Ld_0) f0_6(StringConcatenate("закрываем противоположные ", TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES)), Time[0], Red);
            }
            if (ticket_252 != 0 && Bid > iHigh(NULL, TF, 1)) {
               if (Ask <= price_192 - step * Point) {
                  lots_80 = NormalizeDouble(Ld_224 * k_lot, Gi_168);
                  if (lots_80 > Gd_184) lots_80 = Gd_184;
                  if (lots_80 >= Gd_192 && AccountFreeMarginCheck(Symbol(), OP_BUY, lots_80) > 0.0) f0_2(OP_BUY, lots_80, NormalizeDouble(Ask, Digits), ID);
               }
            }
            if (!(ticket_256 != 0 && Bid < iLow(NULL, TF, 1))) return (0);
            if (Bid < price_200 + step * Point) return (0);
            lots_80 = NormalizeDouble(Ld_232 * k_lot, Gi_168);
            if (lots_80 > Gd_184) lots_80 = Gd_184;
            if (!(lots_80 >= Gd_192 && AccountFreeMarginCheck(Symbol(), OP_SELL, lots_80) > 0.0)) return (0);
            f0_2(OP_SELL, lots_80, NormalizeDouble(Bid, Digits), ID);
         }
      }
   }
   return (0);
}
		 	  	   						 	 	   		  	 				   	  			   			  	     				   		  		 	    		 	   			   	  		    	 	   	 	  					  	      	  				 	 	  	  	  	 	 
// 52D46093050F38C27267BCE42543EF60
int deinit() {
   if (!IsTesting()) f0_0("info");
   Comment("");
   return (0);
}
	    		 			 	 			    	 	 	    		 	 			 	   	  						 	    	  	 	 	  			 		  			 			 		   	  		  	    	 		  		 		 	   	  				  		 					 					   		
// 2208AB04CCD91A8303FE0D7679EA198F
int f0_1() {
   double order_lots_4;
   int error_12;
   int Li_16;
   int cmd_20;
   int ticket_24;
   int count_32;
   bool is_closed_0 = TRUE;
   while (true) {
      for (int pos_28 = OrdersTotal() - 1; pos_28 >= 0; pos_28--) {
         if (OrderSelect(pos_28, SELECT_BY_POS)) {
            if (OrderSymbol() == Symbol()) {
               cmd_20 = OrderType();
               order_lots_4 = OrderLots();
               ticket_24 = OrderTicket();
               if (cmd_20 > OP_SELL) OrderDelete(ticket_24);
               if (cmd_20 == OP_BUY) is_closed_0 = OrderClose(ticket_24, order_lots_4, NormalizeDouble(Bid, Digits), 3, Blue);
               if (cmd_20 == OP_SELL) is_closed_0 = OrderClose(ticket_24, order_lots_4, NormalizeDouble(Ask, Digits), 3, Red);
               if (!is_closed_0) {
                  error_12 = GetLastError();
                  if (error_12 >= 2/* COMMON_ERROR */) {
                     if (error_12 == 129/* INVALID_PRICE */) {
                        RefreshRates();
                        continue;
                     }
                     if (error_12 == 146/* TRADE_CONTEXT_BUSY */) {
                        if (!(IsTradeContextBusy())) continue;
                        Sleep(2000);
                        continue;
                     }
                     Print("Ошибка ", error_12, " закрытия ордера N ", OrderTicket(), "     ", TimeToStr(TimeCurrent(), TIME_SECONDS));
                  }
               }
            }
         }
      }
      count_32 = 0;
      for (pos_28 = 0; pos_28 < OrdersTotal(); pos_28++) {
         if (OrderSelect(pos_28, SELECT_BY_POS))
            if (OrderSymbol() == Symbol()) count_32++;
      }
      if (count_32 == 0) break;
      Li_16++;
      if (Li_16 > 10) {
         Alert(Symbol(), " Не удалось закрыть все сделки, осталось еще ", count_32);
         return (0);
      }
      Sleep(1000);
      RefreshRates();
   }
   return (1);
}
	  	  	 									  	   	 	 	 			 	  	  	     						       		   	 	 		 	 		 		 	 					    	 		   	  	   		   				 	 	    			  			 		 	  				  	 		
// 53BB9515C362D5BE7CC2D9AEB44F468A
int f0_3(int A_cmd_0, int Ai_4) {
   double lots_12;
   int error_20;
   int Li_24;
   int cmd_28;
   int ticket_32;
   int count_40;
   bool is_closed_8 = TRUE;
   while (true) {
      for (int pos_36 = OrdersTotal() - 1; pos_36 >= 0; pos_36--) {
         if (OrderSelect(pos_36, SELECT_BY_POS)) {
            if (OrderSymbol() == Symbol()) {
               cmd_28 = OrderType();
               if (cmd_28 == A_cmd_0) {
                  lots_12 = OrderLots();
                  ticket_32 = OrderTicket();
                  if (Ai_4 == ticket_32) {
                     if (lots_12 > lot_close) lots_12 = lot_close;
                  } else
                     if (OrderComment() != ID) continue;
                  if (cmd_28 == OP_BUY) is_closed_8 = OrderClose(ticket_32, lots_12, NormalizeDouble(Bid, Digits), 3, Blue);
                  if (cmd_28 == OP_SELL) is_closed_8 = OrderClose(ticket_32, lots_12, NormalizeDouble(Ask, Digits), 3, Red);
                  if (!is_closed_8) {
                     error_20 = GetLastError();
                     if (error_20 >= 2/* COMMON_ERROR */) {
                        if (error_20 == 129/* INVALID_PRICE */) {
                           RefreshRates();
                           continue;
                        }
                        if (error_20 == 146/* TRADE_CONTEXT_BUSY */) {
                           if (!(IsTradeContextBusy())) continue;
                           Sleep(2000);
                           continue;
                        }
                        Print("Ошибка ", error_20, " закрытия ордера N ", OrderTicket(), "     ", TimeToStr(TimeCurrent(), TIME_SECONDS));
                     }
                  }
               }
            }
         }
      }
      count_40 = 0;
      for (pos_36 = 0; pos_36 < OrdersTotal(); pos_36++) {
         if (OrderSelect(pos_36, SELECT_BY_POS)) {
            if (OrderSymbol() == Symbol()) {
               if (OrderType() == A_cmd_0)
                  if (OrderComment() == ID) count_40++;
            }
         }
      }
      if (count_40 == 0) break;
      Li_24++;
      if (Li_24 > 10) {
         Alert(Symbol(), " Не удалось закрыть все сделки, осталось еще ", count_40);
         return (0);
      }
      Sleep(1000);
      RefreshRates();
   }
   return (1);
}
			 	        	 	 		 	 			 	 		 		 		  								 	   		 	 		  	 			 	       	           	 	 	   	  		 	 		 			 	 		 	 	 	    			 		  	  		   					 
// 3CC94C06370D2627C52A1F5EBCAEC673
int f0_2(int A_cmd_0, double A_lots_4, double A_price_12, string A_comment_20) {
   int Li_28;
   while (true) {
      RefreshRates();
      if (OrderSend(Symbol(), A_cmd_0, A_lots_4, A_price_12, 0, 0, 0, A_comment_20, 0, 0, f0_7(A_cmd_0)) == -1) {
         Print("OrderSend Error ", GetLastError(), " Lot ", A_lots_4);
         Sleep(1000);
      } else return (1);
      Li_28++;
      if (Li_28 <= 10) continue;
      break;
   }
   return (0);
}
				 		    		 		 			 	 		 		  			 	 		 				   		     	  		 	 	 		 					   					    			  	 				   			 	 	 		 	 			 		 	        			   		 	       	 
// 8F1AC13E8F78925727604F020A757F75
int f0_7(int Ai_0) {
   if (Ai_0 == 0) return (65280);
   if (Ai_0 == 2) return (16711680);
   if (Ai_0 == 1) return (2763429);
   if (Ai_0 == 3) return (255);
   return (8421504);
}
		 		   	 		 	 			 		 		   			 	      		 	  		 		 	 	 	  				 		   	    	  	    	 		  	    	  	 		 		 				   	 	   		 	 	 	 		 	  	   			 	 					
// DABC5DBF75D151A587AD2276CD6849E6
void f0_9(string A_name_0, string A_text_8, int A_x_16, int A_y_20, color A_color_24, int A_corner_28) {
   if (Gi_172) {
      if (ObjectFind(A_name_0) == -1) {
         ObjectCreate(A_name_0, OBJ_LABEL, 0, 0, 0);
         ObjectSet(A_name_0, OBJPROP_CORNER, A_corner_28);
         ObjectSet(A_name_0, OBJPROP_XDISTANCE, A_x_16);
         ObjectSet(A_name_0, OBJPROP_YDISTANCE, A_y_20);
      }
      ObjectSetText(A_name_0, A_text_8, G_fontsize_176, "Arial", A_color_24);
   }
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
   return (0);
}
	 	  		  	  	 		  	  	 				   								 		 		  		 	 	 	  	    	 				 			  		 			  	  		  			 		    	  	 	  			 					  	   	 	  				 			 	 	 	   	 
// 6DA99C665EBCC48FAB3A001114BA2561
int f0_5(string A_name_0, int A_datetime_8, double A_price_12, string A_text_20, color A_color_28) {
   ObjectDelete(A_name_0);
   ObjectCreate(A_name_0, OBJ_TEXT, 0, A_datetime_8, A_price_12, 0, 0, 0, 0);
   ObjectSetText(A_name_0, A_text_20, 12, "Arial");
   ObjectSet(A_name_0, OBJPROP_COLOR, A_color_28);
   return (0);
}
	  		 						 		 	  		    	 				  	          			 			 	  	  			    	 	  				 	  						   	 	 	   		  		   	    		  	 		  				 			  		     			 		  	
// 57C173A83F8039F90F1F4BB5AD208B6F
int f0_4(string A_str_concat_0, int A_datetime_8, double A_price_12, int A_window_20, int Ai_24, color A_color_28) {
   A_str_concat_0 = StringConcatenate("info ", A_str_concat_0);
   ObjectDelete(A_str_concat_0);
   ObjectCreate(A_str_concat_0, OBJ_ARROW, A_window_20, A_datetime_8, A_price_12, 0, 0, 0, 0);
   ObjectSet(A_str_concat_0, OBJPROP_COLOR, A_color_28);
   ObjectSet(A_str_concat_0, OBJPROP_WIDTH, 1);
   ObjectSet(A_str_concat_0, OBJPROP_ARROWCODE, Ai_24);
   return (0);
}
	 					  	 	  		  				 						 					  	 		 	 	 		 	  		  	  			 					 		  			 		  	 	 	  				 	    				 	  	   								   	  	 				   	 	 	  	  	 
// CB5FEB1B7314637725A2E73BDC9F7295
int f0_8(bool Ai_0, int Ai_4, int Ai_8) {
   if (Ai_0) return (Ai_4);
   return (Ai_8);
}
				  	 	  									   	  		 			  	 	  	 		  				        	 	   	  			 	 	 			 	 	  		     			   				   				 				  		    	    			    	  		    	 		
// 885F672A70E2256F08117FDE619150E3
int f0_6(string A_name_0, int A_datetime_8, color A_color_12) {
   ObjectCreate(A_name_0, OBJ_VLINE, 0, A_datetime_8, 0);
   ObjectSet(A_name_0, OBJPROP_COLOR, A_color_12);
   ObjectSet(A_name_0, OBJPROP_STYLE, STYLE_DOT);
   ObjectSet(A_name_0, OBJPROP_WIDTH, 1);
   return (0);
}