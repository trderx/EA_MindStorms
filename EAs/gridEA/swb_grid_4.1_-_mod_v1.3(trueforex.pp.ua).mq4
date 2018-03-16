//+------------------------------------------------------------------+
//|                                                  swb grid 4 .mq4 |
//|                                                totom sukopratomo |
//|                                            forexengine@gmail.com |
//|                                      										|
//|   Modified code by Raj4x for www.worldwide-invest.org            |
//|   mod version 1.0 - July 2013 												|
//|																						|
//+------------------------------------------------------------------+

#property copyright "totom sukopratomo"
#property link      "forexengine@gmail.com"

#include <stdlib.mqh>
#include <stderror.mqh>

#define buy -2
#define sell 2

extern double    start_lot				= 1;
extern bool      lot_multiplier		= true;
extern double    multiplier			= 1.3;
extern double    increment				= 0.1;
extern double    TP_pips				= 10.0;

extern int       max_levels			= 6;
extern double    range_step1			= 30;
extern double    range_step2			= 40;
extern double    range_step3			= 60;
extern double    range_step4			= 80;
extern double    range_step5			= 100;

extern bool      use_bb					= true;
extern int       bb_period				= 20;
extern int       bb_deviation			= 2;
extern int       bb_shift				= 0;

extern bool      use_stoch				= true;
extern int       k						= 5;
extern int       d						= 3;
extern int       slowing				= 3;
extern int       price_field			= 0;
extern int       stoch_shift			= 0;
extern int       lo_level				= 30;
extern int       up_level				= 70;

extern color     TP_Line_color_long	= Aqua;
extern color     TP_Line_color_short= Magenta;

extern bool      use_daily_target	= false;
extern double    daily_target			= 100;
extern bool      trade_in_fri			= true;
extern int       magiclong				= 152845;
extern int       magicshort			= 152846;
extern string	  eacomment 			= "SWB_mod";


bool     use_sl_and_tp	= false;
double   sl					= 60;
double   tp					= 30;
bool     use_rsi			= false;
int      rsi_period		= 12;
int      rsi_shift		= 0;
int      lower				= 30;
int      upper				= 70;

double 	pt;
double 	minlot;
double 	stoplevel;
int 		prec=0;
int 		i,a=0;
int 		ticket=0; 
int 		type;
double   PipValue;
double   tp_in_money;
double   slippage = 3;

double	rangesteps[8];
double  	target_TP_buy,target_TP_sell;
double   profitlong, profitshort;


//---------------------------------------------------------------------------------------------------------------------------------------------------

int init() {

	if(Period() != PERIOD_M5) Alert("Please run on M5 timeframe");
   
   if(Digits==3 || Digits==5) {
   	pt = 10*Point;
   	slippage *= 10;
   } else pt = Point;
   
   minlot    = MarketInfo(Symbol(),MODE_MINLOT);
   stoplevel = MarketInfo(Symbol(),MODE_STOPLEVEL);

   if(minlot==0.01) prec=2;
   if(minlot==0.1)  prec=1;

   if(start_lot<minlot)    Print("lotsize is to small.");
   if(sl<stoplevel)    		Print("stoploss is to tight.");
   if(tp<stoplevel) 			Print("takeprofit is to tight.");

   PipValue = getPipValue(Symbol());
	tp_in_money = TP_pips * PipValue;
	
   deleteLine();
   
   Comment("");	
	
	if(max_levels > 6) max_levels = 6;
	
	rangesteps[0]	= 0;
	rangesteps[1]	= range_step1;
	rangesteps[2]	= range_step2 + range_step1;	
	rangesteps[3]	= range_step3 + range_step2 + range_step1;	
	rangesteps[4]	= range_step4 + range_step3 + range_step2 + range_step1;	
	rangesteps[5]	= range_step5 + range_step4 + range_step3 + range_step2 + range_step1;	
	
	O_R_Config_use2step(true);
   O_R_Config_UseInBacktest(false);
   O_R_SetVerbosity(1);
   O_R_SetRetries(10);
   O_R_Config_FinetuneEntries(false);

   return(0);
}

//---------------------------------------------------------------------------------------------------------------------------------------------------

int deinit() {
   deleteLine();
   Comment("");
   return(0);
}

//---------------------------------------------------------------------------------------------------------------------------------------------------

int start() {
   
   if(use_daily_target && dailyprofit()>=daily_target) {
     Comment("\ndaily target achieved.");
     return(0);
   }
   
   if(!trade_in_fri && DayOfWeek()==5 && total()==0) {
     Comment("\nstop trading in Friday.");
     return(0);
   }
   
	if(total() > 0) manageLine();
	else deleteLine();
	
	//--- Initiate Trades --------------------------------------------------------------------------
   
	if(total()==0 && a==0) {
		if(signal()==buy) {
			if(use_sl_and_tp) {
				if(OrderSendReliable(Symbol(),OP_BUY,start_lot,Ask,slippage,Ask-sl*pt,Ask+tp*pt,eacomment,magiclong,0,LimeGreen)>0) {
					for(int i=1; i<max_levels; i++) {
						if(lot_multiplier) ticket=OrderSendReliable(Symbol(),OP_BUYLIMIT,NormalizeDouble(start_lot*MathPow(multiplier,i),prec),Ask-(rangesteps[i])*pt,slippage,(Ask-(rangesteps[i])*pt)-sl*pt,(Ask-(rangesteps[i])*pt)+tp*pt,eacomment,magiclong,0,CLR_NONE);
						else               ticket=OrderSendReliable(Symbol(),OP_BUYLIMIT,NormalizeDouble(start_lot+increment*i,prec)          ,Ask-(rangesteps[i])*pt,slippage,(Ask-(rangesteps[i])*pt)-sl*pt,(Ask-(rangesteps[i])*pt)+tp*pt,eacomment,magiclong,0,CLR_NONE);
					}
				}
			} else {
				if(OrderSendReliable(Symbol(),OP_BUY,start_lot,Ask,slippage,0,0,eacomment,magiclong,0,LimeGreen)>0) {
					for(i=1; i<max_levels; i++) {
						if(lot_multiplier) ticket=OrderSendReliable(Symbol(),OP_BUYLIMIT,NormalizeDouble(start_lot*MathPow(multiplier,i),prec),Ask-(rangesteps[i])*pt,slippage,0,0,eacomment,magiclong,0,CLR_NONE);
						else               ticket=OrderSendReliable(Symbol(),OP_BUYLIMIT,NormalizeDouble(start_lot+increment*i,prec)          ,Ask-(rangesteps[i])*pt,slippage,0,0,eacomment,magiclong,0,CLR_NONE);
					}
				}
			}
		}

		if(signal()==sell) {
			if(use_sl_and_tp) {
				if(OrderSendReliable(Symbol(),OP_SELL,start_lot,Bid,slippage,Bid+sl*pt,Bid-tp*pt,eacomment,magicshort,0,Red)>0) {
					for(i=1; i<max_levels; i++) {
						if(lot_multiplier) ticket=OrderSendReliable(Symbol(),OP_SELLLIMIT,NormalizeDouble(start_lot*MathPow(multiplier,i),prec),Bid+(rangesteps[i])*pt,slippage,(Bid+(rangesteps[i])*pt)+sl*pt,(Bid+(rangesteps[i])*pt)-tp*pt,eacomment,magicshort,0,CLR_NONE);
						else               ticket=OrderSendReliable(Symbol(),OP_SELLLIMIT,NormalizeDouble(start_lot+increment*i,prec)          ,Bid+(rangesteps[i])*pt,slippage,(Bid+(rangesteps[i])*pt)+sl*pt,(Bid+(rangesteps[i])*pt)-tp*pt,eacomment,magicshort,0,CLR_NONE);
					}
				}
			} else {

				if(OrderSendReliable(Symbol(),OP_SELL,start_lot,Bid,slippage,0,0,eacomment,magicshort,0,Red)>0) {
					for(i=1; i<max_levels; i++) {
						if(lot_multiplier) ticket=OrderSendReliable(Symbol(),OP_SELLLIMIT,NormalizeDouble(start_lot*MathPow(multiplier,i),prec),Bid+(rangesteps[i])*pt,slippage,0,0,eacomment,magicshort,0,CLR_NONE);
						else               ticket=OrderSendReliable(Symbol(),OP_SELLLIMIT,NormalizeDouble(start_lot+increment*i,prec)          ,Bid+(rangesteps[i])*pt,slippage,0,0,eacomment,magicshort,0,CLR_NONE);
					}
				}
			}
		}
	}
	
	//--- Modify SL and TP -------------------------------------------------------------------------

   if(use_sl_and_tp && total()>1) {
   	double s_l, t_p;
     	for(i=0; i<OrdersTotal(); i++) {
		  	if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderSymbol() == Symbol() && (OrderMagicNumber() == magiclong || OrderMagicNumber() == magicshort)) {
         	type = OrderType();
         	s_l  = OrderStopLoss();
         	t_p  = OrderTakeProfit();
	     	}
   	}
     	for(i=OrdersTotal()-1; i>=0; i--) {
		  	if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderSymbol() == Symbol() && (OrderMagicNumber() == magiclong || OrderMagicNumber() == magicshort)) {
       		if(OrderType()==type) {
         		if(OrderStopLoss()!=s_l || OrderTakeProfit()!=t_p) {
            		OrderModifyReliable(OrderTicket(),OrderOpenPrice(),s_l,t_p,0,CLR_NONE);
          		}
				}
       	}
     	}
   }
   
   //--- Check Profit and Close trades -----------------------------------------------------------

   profitlong  = 0;
   profitshort = 0;

	for(i=0; i<OrdersTotal(); i++) {
  		if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderSymbol() == Symbol() && (OrderMagicNumber() == magiclong || OrderMagicNumber() == magicshort)) {
 			if(OrderType() == OP_BUY)  profitlong  += OrderProfit();
 			if(OrderType() == OP_SELL) profitshort += OrderProfit();
		}
	}
	   
   Comment(  "\n Floating Profit BUY    = " + DoubleToStr(profitlong,2)
   		  + "\n Floating Profit SELL   = " + DoubleToStr(profitshort,2)
   		  + "\n Target TP in money   = " + DoubleToStr(tp_in_money,2)
   		  );
   
   if(profitlong >= tp_in_money)  closeall(magiclong);
   if(profitshort >= tp_in_money) closeall(magicshort);

   return(0);
}
  
  
//---------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------------

double dailyprofit() {
  	int day=Day(); double res=0;
  	for(int i=0; i<OrdersHistoryTotal(); i++) {
  		if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderSymbol() == Symbol() && (OrderMagicNumber() == magiclong || OrderMagicNumber() == magicshort)) {
			if(TimeDay(OrderOpenTime())==day) res+=OrderProfit();
  		}
	}
  	return(res);
}

//---------------------------------------------------------------------------------------------------------------------------------------------------

int total() {
	int total=0;
  	for(int i=0; i<OrdersTotal(); i++) {
	  	if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderSymbol() == Symbol() && (OrderMagicNumber() == magiclong || OrderMagicNumber() == magicshort)) {
  			total++;
  		}
	}
  	return(total);
}

//---------------------------------------------------------------------------------------------------------------------------------------------------

int signal() {
  
  double upBB	= iBands(Symbol(),0,bb_period,bb_deviation,0,PRICE_CLOSE,MODE_UPPER,bb_shift);
  double loBB	= iBands(Symbol(),0,bb_period,bb_deviation,0,PRICE_CLOSE,MODE_LOWER,bb_shift);
  double stoch	= iStochastic(Symbol(),0,k,d,slowing,MODE_SMA,price_field,MODE_SIGNAL,stoch_shift);
  double rsi	= iRSI(Symbol(),0,rsi_period,PRICE_CLOSE,rsi_shift);
  
  if(use_bb && use_stoch && use_rsi) {
     if(High[bb_shift]>upBB && stoch>up_level && rsi>upper) return(sell);
     if(Low[bb_shift]<loBB && stoch<lo_level && rsi<lower)   return(buy);
  }
  if(use_bb && use_stoch && !use_rsi) {
     if(High[bb_shift] > upBB && stoch > up_level)   return(sell);
     if(Low [bb_shift] < loBB && stoch < lo_level)   return(buy);
  }
  if(use_bb && !use_stoch && !use_rsi) {
     if(High[bb_shift]>upBB) return(sell);
     if(Low[bb_shift]<loBB)   return(buy);
  }
  if(!use_bb && use_stoch && use_rsi) {
     if(stoch>up_level && rsi>upper) return(sell);
     if(stoch<lo_level && rsi<lower)   return(buy);
  }
  if(!use_bb && use_stoch && !use_rsi) {
     if(stoch>up_level) return(sell);
     if(stoch<lo_level)  return(buy);
  }
  if(use_bb && !use_stoch && use_rsi) {
     if(High[bb_shift]>upBB && rsi>upper) return(sell);
     if(Low[bb_shift]<loBB && rsi<lower)   return(buy);
  }
  if(!use_bb && !use_stoch && use_rsi) {
     if(rsi > upper) return(sell);
     if(rsi < lower)  return(buy);
  }
  return(0);
}

//---------------------------------------------------------------------------------------------------------------------------------------------------

void closeall(int magic) {
	for(int i=OrdersTotal()-1; i>=0; i--) {
		if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
	      	  if(OrderType() > 1) 			OrderDeleteReliable(OrderTicket());
   	   else if(OrderType() == OP_SELL)  OrderCloseReliable(OrderTicket(),OrderLots(),Ask,slippage,Gold);
      	else  									OrderCloseReliable(OrderTicket(),OrderLots(),Bid,slippage,Gold);
		}
	}
	return;
}

//---------------------------------------------------------------------------------------------------------------------------------------------------

void manageLine() {

	deleteLine();
		
	target_TP_buy		= 0;
	target_TP_sell		= 0;

   double   total_openprice_buy    = 0;
   double   average_openprice_buy  = 0;
   double   total_openprice_sell   = 0;
   double   average_openprice_sell = 0;
   
   double   buylots           = 0;
   double   selllots          = 0;
   int      buycount          = 0;
   int      sellcount         = 0;
   double   totallots         = 0;

  	for(int i=0; i<OrdersTotal(); i++) {
		if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderSymbol() == Symbol() && (OrderMagicNumber() == magiclong || OrderMagicNumber() == magicshort)) {
            
      	if (OrderType() == OP_BUY) {
         	total_openprice_buy = total_openprice_buy + OrderOpenPrice() * OrderLots();
         	buycount++;
         	buylots += OrderLots();
      	}         
      	if (OrderType() == OP_SELL) {
         	total_openprice_sell = total_openprice_sell + OrderOpenPrice() * OrderLots();
         	sellcount++;
         	selllots += OrderLots();
      	}
   	}   
   }
   if (sellcount >= 1) {
      average_openprice_sell = total_openprice_sell / selllots;
      target_TP_sell = average_openprice_sell - TP_pips*pt;
	   if(Ask <= target_TP_sell) closeall(magicshort);
      drawLine(target_TP_sell, TP_Line_color_short, "Short");
   }
   if (buycount >= 1) {
      average_openprice_buy = total_openprice_buy / buylots;
		target_TP_buy = average_openprice_buy + TP_pips*pt;
		if(Bid >= target_TP_buy) closeall(magiclong);
      drawLine(target_TP_buy, TP_Line_color_long, "Long");
   }
   return;
}   

//---------------------------------------------------------------------------------------------------------------------------------------------------
   
void drawLine(double price, color theColor, string dir) {
   string name = "TP_LINE " + dir;
   ObjectDelete(name);
   ObjectCreate(name, OBJ_HLINE    , 0, 0, price);
      ObjectSet(name, OBJPROP_COLOR, theColor);
      ObjectSet(name, OBJPROP_STYLE, 4);
      ObjectSet(name, OBJPROP_WIDTH, 0);
      ObjectSet(name, OBJPROP_BACK , true);
	return;
}

void deleteLine() {
   string name;
   int count = 0;
   int objs_total = ObjectsTotal();
   for (int i = objs_total - 1; i >= 0; i--) {
      name = ObjectName(i);
      if (StringFind(name, "TP_LINE") == 0) {
         ObjectDelete(name);
         count++;
      }
   }
	return;
}

//---------------------------------------------------------------------------------------------------------------------------------------------------

double getPipValue(string eSymbol) {
   double iPipValue, iPipSize;
   double iTickSize, iTickValue;

	iTickValue = MarketInfo(eSymbol, MODE_TICKVALUE);
   iTickSize = MarketInfo(eSymbol, MODE_TICKSIZE);
   iPipSize = getPipSize(eSymbol);
   
   iPipValue = iTickValue * (iPipSize / iTickSize);

	return(iPipValue);
}

//---------------------------------------------------------------------------------------------------------------------------------------------------

double getPipSize(string eSymbol) {
   double iPipSize;
   int iDigits;

	iDigits = MarketInfo(eSymbol, MODE_DIGITS);
   iPipSize = 0.0001;   // For most European / American Currency pairs

	if (iDigits == 2 || iDigits == 3) // Like case JPY
	   iPipSize = 0.01;

	return(iPipSize);
}

//---------------------------------------------------------------------------------------------------------------------------------------------------


//=============================================================================
//                            LibOrderReliable4.mq4
//
//         Copyright © 2006, Matthew Kennel  (mbkennelfx@gmail.com)
//         Copyright © 2007, Derk Wehler     (derkwehler@gmail.com)
//         Copyright © 2007, Jack Tomlinson  (jack.tomlinson@gmail.com)
//         Copyright © 2010, Matthew Kennel  (mbkennelfx@gmail.com)
//
//  In order to read this code most clearly in the Metaeditor, it is advised
//  that you set your tab settings to 4 (instead of the default 3):
//  Tools->Options->General Tab, set Tab Size to 4, uncheck "Insert spaces"
//
//                        CURRENT REVISION STATUS (Inserted by SOS):
//                       |$Workfile:: LibOrderReliable.mq4                $|
//                       |$Revision:: 39                                  $|
//                       |$Author  :: Derk                                $|
//                       |$Date    :: 12/21/07 4:18p                      $|
//
// ***************************************************************************
// ***************************************************************************
//  LICENSING:  This is free, open source software, licensed under
//              Version 2 of the GNU General Public License (GPL).
//
//  In particular, this means that distribution of this software in a binary
//  format, e.g. as compiled in as part of a .ex4 format, must be accompanied
//  by the non-obfuscated source code of both this file, AND the .mq4 source
//  files which it is compiled with, or you must make such files available at
//  no charge to binary recipients.	If you do not agree with such terms you
//  must not use this code.  Detailed terms of the GPL are widely available
//  on the Internet.  The Library GPL (LGPL) was intentionally not used,
//  therefore the source code of files which link to this are subject to
//  terms of the GPL if binaries made from them are publicly distributed or
//  sold.
//
//  ANY USE OF THIS CODE NOT CONFORMING TO THIS LICENSE MUST FIRST RECEIVE
//  PRIOR AUTHORIZATION FROM THE AUTHOR(S).  ANY COMMERCIAL USE MUST FIRST
//  OBTAIN A COMMERCIAL LICENSE FROM THE AUTHOR(S).
//
//  Copyright (2006), Matthew Kennel, mbkennelfx@gmail.com
//  Copyright (2007), Derk Wehler, derkwehler@gmail.com
// ***************************************************************************
// ***************************************************************************
//===========================================================================

string 	OrderReliableVersion = "v4.1";
string 	OrderReliable_Fname = "OrderReliable fname unset";

int 		O_R_Setting_max_retries 	= 10;
double 	O_R_Setting_sleep_time 		= 4.0; /* seconds */
double 	O_R_Setting_sleep_max 		= 15.0; /* seconds */

int 		O_R_ErrorLevel 			= 1;
int   	O_R_LastErr             = 0;  // save last error
int 		O_R_Verbosity 				= 1;

bool    	O_R_Setting_use2step        	= true; /* use 2 step orders for ECN? */
bool		O_R_Setting_limit2market 	 	= false;
bool		O_R_Setting_UseForTesting 	 	= false;
bool		O_R_Setting_finetune_entries	= true;


void O_R_SetRetries(int retries)
{
   O_R_Setting_max_retries = MathMax(1, MathMin(20, retries));
}

void O_R_SetVerbosity(int verb)
{
   O_R_Verbosity = MathMin(2, MathMax(0, verb));
}

void O_R_Config_FinetuneEntries(bool b)
{
   O_R_Setting_finetune_entries = b;
}

//=============================================================================
//							 OrderSendReliable()
//
//  This is intended to be a drop-in replacement for OrderSend() which,
//  one hopes, is more resistant to various forms of errors prevalent
//  with MetaTrader.
//
//	RETURN VALUE:
//     Ticket number or -1 under some error conditions.
//
//  FEATURES:
//     * Re-trying under some error conditions, sleeping a random
//       time defined by an exponential probability distribution.
//
//     * Automatic normalization of Digits
//
//     * Automatically makes sure that stop levels are more than
//       the minimum stop distance, as given by the server. If they
//       are too close, they are adjusted.
//
//     * Automatically converts stop orders to market orders
//       when the stop orders are rejected by the server for
//       being to close to market.  NOTE: This intentionally
//       applies only to OP_BUYSTOP and OP_SELLSTOP,
//       OP_BUYLIMIT and OP_SELLLIMIT are not converted to market
//       orders and so for prices which are too close to current
//       this function is likely to loop a few times and return
//       with the "invalid stops" error message.
//       Note, the commentary in previous versions erroneously said
//       that limit orders would be converted.  Note also
//       that entering a BUYSTOP or SELLSTOP new order is distinct
//       from setting a stoploss on an outstanding order; use
//       OrderModifyReliable() for that.
//
//     * Displays various error messages on the log for debugging.
//
//  ORIGINAL AUTHOR AND DATE:
//     Matt Kennel, 2006-05-28
//
//=============================================================================
int OrderSendReliable(string symbol, int cmd, double volume, double price,
                      int slippage, double stoploss, double takeprofit,
                      string comment, int magic, datetime expiration = 0,
                      color arrow_color = CLR_NONE)
{
   if (O_R_Setting_use2step) {
      return(OrderSendReliable2Step(symbol,cmd,volume,price,slippage,stoploss,takeprofit,
                             comment,magic,expiration,arrow_color));

   } else {
      return(OrderSendReliable1Step(symbol,cmd,volume,price,slippage,stoploss,takeprofit,
                             comment,magic,expiration,arrow_color));
   }

}

/*
int OrderSendReliableMKT(string symbol, int cmd, double volume, double price,
                         int slippage, double stoploss, double takeprofit,
                         string comment, int magic, datetime expiration = 0,
                         color arrow_color = CLR_NONE)
{
   if (O_R_Setting_use2step) {
      return(OrderSendReliableMKT2Step(symbol,cmd,volume,price,slippage,stoploss,takeprofit,
                                comment,magic,expiration,arrow_color));

   } else {
      return(OrderSendReliableMKT1Step(symbol,cmd,volume,price,slippage,stoploss,takeprofit,
                                comment,magic,expiration,arrow_color));
   }

}
*/

int OrderSendReliable1Step(string symbol, int cmd, double volume, double price,
                           int slippage, double stoploss, double takeprofit,
                           string comment, int magic, datetime expiration = 0,
                           color arrow_color = CLR_NONE)
{
   int ticket = -1;
   // ========================================================================
   // If testing or optimizing, there is no need to use this lib, as the
   // orders are not real-world, and always get placed optimally.  By
   // refactoring this option to be in this library, one no longer needs
   // to create similar code in each EA.
   if (!O_R_Setting_UseForTesting) {
      if (IsOptimization()  ||  IsTesting()) {
         O_R_EnsureValidStops( symbol,  cmd,  price, stoploss, takeprofit, true);
   
      
         ticket = OrderSend(symbol, cmd, volume, price, slippage, stoploss,
                            takeprofit, comment, magic, expiration, arrow_color);
         return(ticket);
      }
   }
   // ========================================================================

   OrderReliable_Fname = "OrderSendReliable";
   OrderReliablePrint(2, "•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   OrderReliablePrint(1, "Attempted " + OrderType2String(cmd) + " " + volume +
                      " lots @" + price + " sl:" + stoploss + " tp:" + takeprofit);

   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   // Get information about this order
   double realPoint = MarketInfo(symbol, MODE_POINT);
   int digits;
   double point;
   double bid, ask;
   double sl, tp;
   O_R_GetOrderDetails(0, symbol, cmd, digits, point, sl, tp, bid, ask, false);
   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


   // Normalize all price / stoploss / takeprofit to the proper # of digits.
   price = O_R_NormalizePrice(symbol, price);
   stoploss = O_R_NormalizePrice(symbol, stoploss);
   takeprofit = O_R_NormalizePrice(symbol, takeprofit);
   volume = O_R_NormalizeLots(symbol, volume);

   // Check stop levels, adjust if necessary
   O_R_EnsureValidStops(symbol, cmd, price, stoploss, takeprofit);

   int cnt;
   int err = GetLastError(); // clear the global variable.
   err = 0;
   bool exit_loop = false;
   bool limit_to_market = false;

   // limit/stop order.
   bool fixed_invalid_price = false;
   if (cmd == OP_BUYSTOP  ||  cmd == OP_SELLSTOP  ||  cmd == OP_BUYLIMIT  ||  cmd == OP_SELLLIMIT) {
      cnt = 0;
      while (!exit_loop) {
         ticket = OrderSend(symbol, cmd, volume, price, slippage, stoploss,
                            takeprofit, comment, magic, expiration, arrow_color);
         err = GetLastError();

         switch (err) {
         case ERR_NO_ERROR:
            exit_loop = true;
            break;

            // retryable errors
         case ERR_SERVER_BUSY:
         case ERR_NO_CONNECTION:
         case ERR_OFF_QUOTES:
         case ERR_BROKER_BUSY:
         case ERR_TRADE_CONTEXT_BUSY:
         case ERR_TRADE_TIMEOUT:
            cnt++;
            break;

         case ERR_PRICE_CHANGED:
         case ERR_REQUOTE:
            cnt++;
            RefreshRates();
            break;	// we can apparently retry immediately according to MT docs.

         case ERR_INVALID_PRICE:
         case ERR_INVALID_STOPS:
            cnt++;
            double servers_min_stop = MarketInfo(symbol, MODE_STOPLEVEL) * realPoint;
            double old_price;
            if (cmd == OP_BUYSTOP || cmd == OP_BUYLIMIT) {
               // If we are too close to put in a limit/stop order so go to market.
               if (MathAbs(ask - price) <= servers_min_stop) {
                  if (O_R_Setting_limit2market) {
                     limit_to_market = true;
                     exit_loop = true;
                  } else {
                     if (fixed_invalid_price) {
                        if (cmd == OP_BUYSTOP) {
                           price += point;
                           if (stoploss > 0) {
                              stoploss += point;
                           }
                           if (takeprofit > 0) {
                              takeprofit += point;
                           }
                           OrderReliablePrint(2, "Pending BuyStop Order still has ERR_INVALID_STOPS, adding 1 pip; new price = " + DoubleToStr(price, digits));
                           if (stoploss > 0  ||  takeprofit > 0) {
                              OrderReliablePrint(2, "NOTE: SL (now " + DoubleToStr(stoploss, digits) + ") & TP (now " + DoubleToStr(takeprofit, digits) + ") were adjusted proportionately");
                           }
                        } else if (cmd == OP_BUYLIMIT) {
                           price -= point;
                           if (stoploss > 0) {
                              stoploss -= point;
                           }
                           if (takeprofit > 0) {
                              takeprofit -= point;
                           }
                           OrderReliablePrint(2, "Pending BuyLimit Order still has ERR_INVALID_STOPS, subtracting 1 pip; new price = " + DoubleToStr(price, digits));
                           if (stoploss > 0  ||  takeprofit > 0) {
                              OrderReliablePrint(2, "NOTE: SL (now " + DoubleToStr(stoploss, digits) + ") & TP (now " + DoubleToStr(takeprofit, digits) + ") were adjusted proportionately");
                           }
                        }
                     } else if (O_R_Setting_finetune_entries) {
                        if (cmd == OP_BUYLIMIT) {
                           old_price = price;
                           price = ask - servers_min_stop;
                           if (stoploss > 0) {
                              stoploss += (price - old_price);
                           }
                           if (takeprofit > 0) {
                              takeprofit += (price - old_price);
                           }
                           OrderReliablePrint(2, "Pending BuyLimit has ERR_INVALID_STOPS; new price = " + DoubleToStr(price, digits));
                           if (stoploss > 0  ||  takeprofit > 0) {
                              OrderReliablePrint(2, "NOTE: SL (now " + DoubleToStr(stoploss, digits) + ") & TP (now " + DoubleToStr(takeprofit, digits) + ") were adjusted proportionately");
                           }
                        } else if (cmd == OP_BUYSTOP) {
                           old_price = price;
                           price = ask + servers_min_stop;
                           if (stoploss > 0) {
                              stoploss += (price - old_price);
                           }
                           if (takeprofit > 0) {
                              takeprofit += (price - old_price);
                           }
                           OrderReliablePrint(2, "Pending BuyStop has ERR_INVALID_STOPS; new price = " + DoubleToStr(price, digits));
                           if (stoploss > 0  ||  takeprofit > 0) {
                              OrderReliablePrint(2, "NOTE: SL (now " + DoubleToStr(stoploss, digits) + ") & TP (now " + DoubleToStr(takeprofit, digits) + ") were adjusted proportionately");
                           }
                        }
                        fixed_invalid_price = true;
                     }
                     O_R_EnsureValidStops(symbol, cmd, price, stoploss, takeprofit);
                  }
               }
            } else if (cmd == OP_SELLSTOP || cmd == OP_SELLLIMIT) {
               // If we are too close to put in a limit/stop order so go to market.
               if (MathAbs(bid - price) <= servers_min_stop) {
                  if (O_R_Setting_limit2market) {
                     limit_to_market = true;
                     exit_loop = true;
                  } else if (O_R_Setting_finetune_entries) {
                     if (fixed_invalid_price) {
                        if (cmd == OP_SELLSTOP) {
                           price -= point;
                           if (stoploss > 0) {
                              stoploss -= point;
                           }
                           if (takeprofit > 0) {
                              takeprofit -= point;
                           }
                           OrderReliablePrint(2, "Pending SellStop Order still has ERR_INVALID_STOPS, subtracting 1 pip; new price = " + DoubleToStr(price, digits));
                           if (stoploss > 0  ||  takeprofit > 0) {
                              OrderReliablePrint(2, "NOTE: SL (now " + DoubleToStr(stoploss, digits) + ") & TP (now " + DoubleToStr(takeprofit, digits) + ") were adjusted proportionately");
                           }
                        } else if (cmd == OP_SELLLIMIT) {
                           price += point;
                           if (stoploss > 0) {
                              stoploss += point;
                           }
                           if (takeprofit > 0) {
                              takeprofit += point;
                           }
                           OrderReliablePrint(2, "Pending SellLimit Order still has ERR_INVALID_STOPS, adding 1 pip; new price = " + DoubleToStr(price, digits));
                           if (stoploss > 0  ||  takeprofit > 0) {
                              OrderReliablePrint(2, "NOTE: SL (now " + DoubleToStr(stoploss, digits) + ") & TP (now " + DoubleToStr(takeprofit, digits) + ") were adjusted proportionately");
                           }
                        }
                     } else {
                        if (cmd == OP_SELLSTOP) {
                           old_price = price;
                           price = bid - servers_min_stop;
                           if (stoploss > 0) {
                              stoploss -= (old_price - price);
                           }
                           if (takeprofit > 0) {
                              takeprofit -= (old_price - price);
                           }
                           OrderReliablePrint(2, "Pending SellStop has ERR_INVALID_STOPS; new price = " + DoubleToStr(price, digits));
                           if (stoploss > 0  ||  takeprofit > 0) {
                              OrderReliablePrint(2, "NOTE: SL (now " + DoubleToStr(stoploss, digits) + ") & TP (now " + DoubleToStr(takeprofit, digits) + ") were adjusted proportionately");
                           }
                        } else if (cmd == OP_SELLLIMIT) {
                           old_price = price;
                           price = bid + servers_min_stop;
                           if (stoploss > 0) {
                              stoploss -= (old_price - price);
                           }
                           if (takeprofit > 0) {
                              takeprofit -= (old_price - price);
                           }
                           OrderReliablePrint(2, "Pending SellLimit has ERR_INVALID_STOPS; new price = " + DoubleToStr(price, digits));
                           if (stoploss > 0  ||  takeprofit > 0) {
                              OrderReliablePrint(2, "NOTE: SL (now " + DoubleToStr(stoploss, digits) + ") & TP (now " + DoubleToStr(takeprofit, digits) + ") were adjusted proportionately");
                           }
                        }
                        fixed_invalid_price = true;
                     }
                     O_R_EnsureValidStops(symbol, cmd, price, stoploss, takeprofit);
                  }
               }
            }
            break;

         case ERR_INVALID_TRADE_PARAMETERS:
         default:
            // an apparently serious error.
            exit_loop = true;
            break;

         }  // end switch

         if (cnt > O_R_Setting_max_retries) {
            exit_loop = true;
         }

         if (exit_loop) {
            if (err != ERR_NO_ERROR  &&  err != ERR_NO_RESULT) {
               OrderReliablePrint(2, "Non-retryable error: " + OrderReliableErrTxt(err));
            }
            if (cnt > O_R_Setting_max_retries) {
               OrderReliablePrint(2, "Retry attempts maxed at " + O_R_Setting_max_retries);
            }
         } else {
            OrderReliablePrint(2, "Result of attempt " + cnt + " of " + O_R_Setting_max_retries + ": Retryable error: " + OrderReliableErrTxt(err));
            OrderReliablePrint(2, "~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~");
            O_R_Sleep(O_R_Setting_sleep_time, O_R_Setting_sleep_max);
            RefreshRates();
         }
      }
      O_R_LastErr = err; 
     

      // We have now exited from loop.
      if (err == ERR_NO_ERROR  ||  err == ERR_NO_RESULT) {
         OrderReliablePrint(1, "Ticket #" + ticket + ": Successful " + OrderType2String(cmd) + " order placed, details follow.");
         OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES);
         OrderPrint();
         OrderReliablePrint(2, "•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
         O_R_CheckForHistory(ticket); 
         return(ticket); // SUCCESS!
      }
      if (!limit_to_market) {
         OrderReliablePrint(1, "Failed to execute stop or limit order after " + O_R_Setting_max_retries + " retries");
         OrderReliablePrint(1, "Failed trade: " + OrderType2String(cmd) + " " + DoubleToStr(volume, 2) + " lots  " + symbol +
                            "@" + price + " tp@" + takeprofit + " sl@" + stoploss);
         OrderReliablePrint(1, "Last error: " + OrderReliableErrTxt(err));
         OrderReliablePrint(2, "•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
         return(-1);
      }
   }  // end

   if (limit_to_market) {
      OrderReliablePrint(1, "Going from stop/limit order to market order because market is too close.");
      if ((cmd == OP_BUYSTOP) || (cmd == OP_BUYLIMIT)) {
         cmd = OP_BUY;
         price = ask;
      } else if ((cmd == OP_SELLSTOP) || (cmd == OP_SELLLIMIT)) {
         cmd = OP_SELL;
         price = bid;
      }
   }

   // we now have a market order.
   err = GetLastError(); // so we clear the global variable.
   err = 0;
   ticket = -1;
   exit_loop = false;

   if ((cmd == OP_BUY) || (cmd == OP_SELL)) {
      cnt = 0;
      while (!exit_loop) {
         ticket = OrderSend(symbol, cmd, volume, price, slippage,
                            stoploss, takeprofit, comment, magic,
                            expiration, arrow_color);
         err = GetLastError();

         switch (err) {
         case ERR_NO_ERROR:
            exit_loop = true;
            break;

         case ERR_SERVER_BUSY:
         case ERR_NO_CONNECTION:
         case ERR_INVALID_PRICE:
         case ERR_OFF_QUOTES:
         case ERR_BROKER_BUSY:
         case ERR_TRADE_CONTEXT_BUSY:
         case ERR_TRADE_TIMEOUT:
            cnt++; // a retryable error
            break;

         case ERR_PRICE_CHANGED:
         case ERR_REQUOTE:
            RefreshRates();
            cnt++;
            break; // we can apparently retry immediately according to MT docs.

         default:
            // an apparently serious, unretryable error.
            exit_loop = true;
            break;
         }

         if (cnt > O_R_Setting_max_retries) {
            exit_loop = true;
         }

         if (!exit_loop) {
            OrderReliablePrint(2, "Result of attempt " + cnt + " of " + O_R_Setting_max_retries + ": Retryable error: " + OrderReliableErrTxt(err));
            OrderReliablePrint(2, "~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~");
            O_R_Sleep(O_R_Setting_sleep_time, O_R_Setting_sleep_max);
            RefreshRates();
         } else {
            if (err != ERR_NO_ERROR  &&  err != ERR_NO_RESULT) {
               OrderReliablePrint(2, "Non-retryable error: " + OrderReliableErrTxt(err));
            }
            if (cnt > O_R_Setting_max_retries) {
               OrderReliablePrint(2, "Retry attempts maxed at " + O_R_Setting_max_retries);
            }
         }
      }
      O_R_LastErr = err; 

      // we have now exited from loop.
      if (err == ERR_NO_ERROR  ||  err == ERR_NO_RESULT) {
         OrderReliablePrint(1, "Ticket #" + ticket + ": Successful " + OrderType2String(cmd) + " order placed, details follow.");
         OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES);
         OrderPrint();
         OrderReliablePrint(2, "•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
         O_R_CheckForHistory(ticket);
         return(ticket); // SUCCESS!
      }
      OrderReliablePrint(1, "Failed to execute OP_BUY/OP_SELL, after " + O_R_Setting_max_retries + " retries");
      OrderReliablePrint(1, "Failed trade: " + OrderType2String(cmd) + " " + DoubleToStr(volume, 2) + " lots  " + symbol +
                         "@" + price + " tp@" + takeprofit + " sl@" + stoploss);
      OrderReliablePrint(1, "Last error: " + OrderReliableErrTxt(err));
      OrderReliablePrint(2, "•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
      return(-1);
   }
}


//=============================================================================
//							 OrderSendReliableMKT()
//
//  This is intended to be an alternative for OrderSendReliable() which
//  will update market-orders in the retry loop with the current Bid or Ask.
//  Hence with market orders there is a greater likelihood that the trade will
//  be executed versus OrderSendReliable(), and a greater likelihood it will
//  be executed at a price worse than the entry price due to price movement.
//
//  RETURN VALUE:
//     Ticket number or -1 under some error conditions.  Check
//     final error returned by Metatrader with OrderReliableLastErr().
//     This will reset the value from GetLastError(), so in that sense it cannot
//     be a total drop-in replacement due to Metatrader flaw.
//
//  FEATURES:
//     * Most features of OrderSendReliable() but for market orders only.
//       Command must be OP_BUY or OP_SELL, and specify Bid or Ask at
//       the time of the call.
//
//     * If price moves in an unfavorable direction during the loop,
//       e.g. from requotes, then the slippage variable it uses in
//       the real attempt to the server will be decremented from the passed
//       value by that amount, down to a minimum of zero.   If the current
//       price is too far from the entry value minus slippage then it
//       will not attempt an order, and it will signal, manually,
//       an ERR_INVALID_PRICE (displayed to log as usual) and will continue
//       to loop the usual number of times.
//
//     * Displays various error messages on the log for debugging.
//
//  ORIGINAL AUTHOR AND DATE:
//	   Matt Kennel, 2006-08-16
//
//=============================================================================
/*
int OrderSendReliableMKT1Step(string symbol, int cmd, double volume, double price,
                              int slippage, double stoploss, double takeprofit,
                              string comment, int magic, datetime expiration = 0,
                              color arrow_color = CLR_NONE)
{
   int ticket = -1;
   // ========================================================================
   // If testing or optimizing, there is no need to use this lib, as the
   // orders are not real-world, and always get placed optimally.  By
   // refactoring this option to be in this library, one no longer needs
   // to create similar code in each EA.
   if (!O_R_Setting_UseForTesting) {
      if (IsOptimization()  ||  IsTesting()) {
         ticket = OrderSend(symbol, cmd, volume, price, slippage, stoploss,
                            takeprofit, comment, magic, expiration, arrow_color);
         return(ticket);
      }
   }
   // ========================================================================

   // Cannot use this function for pending orders
   if (cmd > OP_SELL) {
      ticket = OrderSendReliable(symbol, cmd, volume, price, slippage, 0, 0,
                                 comment, magic, expiration, arrow_color);
      return(ticket);
   }

   OrderReliable_Fname = "OrderSendReliableMKT";
   OrderReliablePrint(2, "•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   OrderReliablePrint(1, "Attempted " + OrderType2String(cmd) + " " + volume +
                      " lots @" + price + " sl:" + stoploss + " tp:" + takeprofit);

   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   // Get information about this order
   int digits;
   double point;
   double bid, ask;
   double sl, tp;
   O_R_GetOrderDetails(0, symbol, cmd, digits, point, sl, tp, bid, ask, false);
   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

   price = O_R_NormalizePrice(symbol, price);
   stoploss = O_R_NormalizePrice(symbol, stoploss);
   takeprofit = O_R_NormalizePrice(symbol, takeprofit);
   volume = O_R_NormalizeLots(symbol, volume);
   O_R_EnsureValidStops(symbol, cmd, price, stoploss, takeprofit);

   int cnt;
   int err = GetLastError(); // clear the global variable.
   err = 0;
   bool exit_loop = false;

   if ((cmd == OP_BUY) || (cmd == OP_SELL)) {
      cnt = 0;
      while (!exit_loop) {
         double pnow = price;
         int slippagenow = slippage;
         if (cmd == OP_BUY) {
            // modification by Paul Hampton-Smith to replace RefreshRates()
            pnow = O_R_NormalizePrice(symbol, MarketInfo(symbol, MODE_ASK)); // we are buying at Ask
            if (pnow > price) {
               slippagenow = slippage - (pnow - price) / point;
            }
         } else if (cmd == OP_SELL) {
            // modification by Paul Hampton-Smith to replace RefreshRates()
            pnow = O_R_NormalizePrice(symbol, MarketInfo(symbol, MODE_BID)); // we are buying at Bid
            if (pnow < price) {
               // moved in an unfavorable direction
               slippagenow = slippage - (price - pnow) / point;
            }
         }
         if (slippagenow > slippage) {
            slippagenow = slippage;
         }
         if (slippagenow >= 0) {

            ticket = OrderSend(symbol, cmd, volume, pnow, slippagenow,
                               stoploss, takeprofit, comment, magic,
                               expiration, arrow_color);
            err = GetLastError();
         } else {
            // too far away, manually signal ERR_INVALID_PRICE, which
            // will result in a sleep and a retry.
            err = ERR_INVALID_PRICE;
         }

         switch (err) {
         case ERR_NO_ERROR:
            exit_loop = true;
            break;

         case ERR_SERVER_BUSY:
         case ERR_NO_CONNECTION:
         case ERR_INVALID_PRICE:
         case ERR_OFF_QUOTES:
         case ERR_BROKER_BUSY:
         case ERR_TRADE_CONTEXT_BUSY:
         case ERR_TRADE_TIMEOUT:
            cnt++; // a retryable error
            break;

         case ERR_PRICE_CHANGED:
         case ERR_REQUOTE:
            // Paul Hampton-Smith removed RefreshRates() here and used MarketInfo() above instead
            cnt++;
            break; // we can apparently retry immediately according to MT docs.

         default:
            // an apparently serious, unretryable error.
            exit_loop = true;
            break;

         }  // end switch

         if (cnt > O_R_Setting_max_retries) {
            exit_loop = true;
         }

         if (!exit_loop) {
            OrderReliablePrint(2, "Result of attempt " + cnt + " of " + O_R_Setting_max_retries + ": Retryable error: " + OrderReliableErrTxt(err));
            OrderReliablePrint(2, "~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~");
            O_R_Sleep(O_R_Setting_sleep_time, O_R_Setting_sleep_max);
         } else {
            if (err != ERR_NO_ERROR  &&  err != ERR_NO_RESULT) {
               OrderReliablePrint(2, "Non-retryable error: " + OrderReliableErrTxt(err));
            }
            if (cnt > O_R_Setting_max_retries) {
               OrderReliablePrint(2, "Retry attempts maxed at " + O_R_Setting_max_retries);
            }
         }
      }
      O_R_LastErr = err; 

      // we have now exited from loop.
      if (err == ERR_NO_ERROR  ||  err == ERR_NO_RESULT) {
         OrderReliablePrint(2, "Ticket #" + ticket + ": Successful " + OrderType2String(cmd) + " order placed, details follow.");
         OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES);
         OrderPrint();
         OrderReliablePrint(2, "•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
         O_R_CheckForHistory(ticket);
         return(ticket); // SUCCESS!
      }
      OrderReliablePrint(1, "Failed to execute OP_BUY/OP_SELL, after " + O_R_Setting_max_retries + " retries");
      OrderReliablePrint(1, "Failed trade: " + OrderType2String(cmd) + " " + DoubleToStr(volume, 2) + " lots  " + symbol +
                         "@" + price + " tp@" + takeprofit + " sl@" + stoploss);
      OrderReliablePrint(1, "Last error: " + OrderReliableErrTxt(err));
      OrderReliablePrint(2, "•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
      return(-1);
   }
}
*/

//=============================================================================
//							 OrderSendReliable2Step()
//
//  Some brokers don't allow the SL and TP settings as part of the initial
//  market order (Water House Capital).  Therefore, this routine will first
//  place the market order with no stop-loss and take-profit but later
//  update the order accordingly
//
//	RETURN VALUE:
//     Same as OrderSendReliable; the ticket number
//
//  NOTES:
//     Order will not be updated if an error continues during
//     OrderSendReliableMKT.  No additional information will be logged
//     since OrderSendReliableMKT would have already logged the error
//     condition
//
//  ORIGINAL AUTHOR AND DATE:
//     Jack Tomlinson, 2007-05-29
//
//=============================================================================
int OrderSendReliable2Step(string symbol, int cmd, double volume, double price,
                           int slippage, double stoploss, double takeprofit,
                           string comment, int magic, datetime expiration = 0,
                           color arrow_color = CLR_NONE)
{
   int ticket = -1;
   // ========================================================================
   // If testing or optimizing, there is no need to use this lib, as the
   // orders are not real-world, and always get placed optimally.  By
   // refactoring this option to be in this library, one no longer needs
   // to create similar code in each EA.
   if (!O_R_Setting_UseForTesting) {
      if (IsOptimization()  ||  IsTesting()) {
         ticket = OrderSend(symbol, cmd, volume, price, slippage, 0, 0,
                            comment, magic, expiration, arrow_color);

         OrderModify(ticket, 0, stoploss, takeprofit, 0, arrow_color);

         return(ticket);
      }
   }
   // ========================================================================

   OrderReliable_Fname = "OrderSendReliable2Step";
   OrderReliablePrint(2, "");
   OrderReliablePrint(1, "Doing OrderSendReliable, followed by OrderModifyReliable:");

   ticket = OrderSendReliable1Step(symbol, cmd, volume, price, slippage,
                                   0, 0, comment, magic, expiration, arrow_color);

   if (stoploss != 0 || takeprofit != 0) {
      if (ticket >= 0) {
         OrderModifyReliable(ticket, price,	stoploss, takeprofit, 0, arrow_color);
      }
   } else {
      OrderReliablePrint(2, "Skipping OrderModifyReliable because no SL or TP specified.");
   }

   return(ticket);
}

//=============================================================================
//							 OrderSendReliableMKT2Step()
//
//  Some brokers don't allow the SL and TP settings as part of the initial
//  market order (Water House Capital).  Therefore, this routine will first
//  place the market order with no stop-loss and take-profit but later
//  update the order accordingly
//
//	RETURN VALUE:
//     Same as OrderSendReliable; the ticket number
//
//=============================================================================
/*
int OrderSendReliableMKT2Step(string symbol, int cmd, double volume, double price,
                              int slippage, double stoploss, double takeprofit,
                              string comment, int magic, datetime expiration = 0,
                              color arrow_color = CLR_NONE)
{
   int ticket = -1;
   // ========================================================================
   // If testing or optimizing, there is no need to use this lib, as the
   // orders are not real-world, and always get placed optimally.  By
   // refactoring this option to be in this library, one no longer needs
   // to create similar code in each EA.
   if (!O_R_Setting_UseForTesting) {
      if (IsOptimization()  ||  IsTesting()) {
         ticket = OrderSend(symbol, cmd, volume, price, slippage, 0, 0,
                            comment, magic, expiration, arrow_color);

         OrderModifyReliable(ticket, 0, stoploss, takeprofit, 0, arrow_color);

         return(ticket);
      }
   }
   // ========================================================================

   OrderReliable_Fname = "OrderSendReliable2Step";
   OrderReliablePrint(2, "");
   OrderReliablePrint(2, "Doing OrderSendReliable, followed by OrderModifyReliable:");

   ticket = OrderSendReliableMKT1Step(symbol, cmd, volume, price, slippage,
                                      0, 0, comment, magic, expiration, arrow_color);

   if (stoploss != 0 || takeprofit != 0) {
      if (ticket >= 0) {
         OrderModifyReliable(ticket, price,	stoploss, takeprofit, 0, arrow_color);
      }
   } else {
      OrderReliablePrint(2, "Skipping OrderModifyReliable because no SL or TP specified.");
   }

   return(ticket);
}
*/

//=============================================================================
//							 OrderModifyReliable()
//
//  This is intended to be a drop-in replacement for OrderModify() which,
//  one hopes, is more resistant to various forms of errors prevalent
//  with MetaTrader.
//
//  RETURN VALUE:
//     TRUE if successful, FALSE otherwise
//
//  FEATURES:
//     * Re-trying under some error conditions, sleeping a random
//       time defined by an exponential probability distribution.
//
//     * Displays various error messages on the log for debugging.
//
//
//  ORIGINAL AUTHOR AND DATE:
//     Matt Kennel, 2006-05-28
//
//=============================================================================
bool OrderModifyReliable(int ticket, double price, double stoploss,
                         double takeprofit, datetime expiration,
                         color arrow_color = CLR_NONE)
{
   bool result = false;
   bool non_retryable_error = false;

   OrderReliable_Fname = "OrderModifyReliable";
   OrderReliablePrint(2, "•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   OrderReliablePrint(1, "Attempted modify of #" + ticket + " price:" + price +
                      " sl:" + stoploss + " tp:" + takeprofit);

   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   // Get information about this order
   string symbol = "ALLOCATE";		// This is so it has memory space allocated
   int type;
   int digits;
   double point;
   double bid, ask;
   double sl, tp;
   O_R_GetOrderDetails(ticket, symbol, type, digits, point, sl, tp, bid, ask);
   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

   // Below, we call "O_R_EnsureValidStops".  If the order we are modifying
   // is a pending order, then we should use the price passed in.  But
   // if it's an open order, the price passed in is irrelevant; we need
   // to use the appropriate bid or ask, so get those...
   double prc = price;
   if (type == OP_BUY) {
      prc = bid;
   } else if (type == OP_SELL)	{
      prc = ask;
   }

   // With the requisite info, we can do error checking on SL & TP
   prc = O_R_NormalizePrice(symbol, prc);
   price = O_R_NormalizePrice(symbol, price);
   stoploss = O_R_NormalizePrice(symbol, stoploss);
   takeprofit = O_R_NormalizePrice(symbol, takeprofit);

   // ========================================================================
   // If testing or optimizing, there is no need to use this lib, as the
   // orders are not real-world, and always get placed optimally.  By
   // refactoring this option to be in this library, one no longer needs
   // to create similar code in each EA.
   if (!O_R_Setting_UseForTesting) {
      if (IsOptimization()  ||  IsTesting()) {
         result = OrderModify(ticket, price, stoploss,
                              takeprofit, expiration, arrow_color);
         return(result);
      }
   }
   // ========================================================================

   // If SL/TP are not changing then send in zeroes to O_R_EnsureValidStops(),
   // so that it does not bother to try to change them
   double newSL = stoploss;
   double newTP = takeprofit;
   if (stoploss == sl) {
      newSL = 0;
   }
   if (takeprofit == tp)	{
      newTP = 0;
   }
   O_R_EnsureValidStops(symbol, type, prc, newSL, newTP, false);
   if (stoploss != sl) {
      stoploss = newSL;
   }
   if (takeprofit != tp)	{
      takeprofit = newTP;
   }


   int cnt = 0;
   int err = GetLastError(); // so we clear the global variable.
   err = 0;
   bool exit_loop = false;

   while (!exit_loop) {
      result = OrderModify(ticket, price, stoploss,
                           takeprofit, expiration, arrow_color);
      err = GetLastError();

      if (result == true) {
         exit_loop = true;
      } else {
         switch (err) {
         case ERR_NO_ERROR:
            exit_loop = true;
            OrderReliablePrint(2, "ERR_NO_ERROR received, but OrderClose() returned false; exiting");
            break;

         case ERR_NO_RESULT:
            // Modification to same value as before
            // See below for reported result
            exit_loop = true;
            result=true;  // this is a good exit. 
            break;

            // Shouldn't be any reason stops are invalid (and yet I've seen it); try again
         case ERR_INVALID_STOPS:
            OrderReliablePrint(2, "OrderModifyReliable, ERR_INVALID_STOPS, should not happen; stops already adjusted");
            //	O_R_EnsureValidStops(symbol, price, stoploss, takeprofit);
         case ERR_COMMON_ERROR:
         case ERR_SERVER_BUSY:
         case ERR_NO_CONNECTION:
         case ERR_TOO_FREQUENT_REQUESTS:
         case ERR_TRADE_TIMEOUT:		// for modify this is a retryable error, I hope.
         case ERR_INVALID_PRICE:
         case ERR_OFF_QUOTES:
         case ERR_BROKER_BUSY:
         case ERR_TOO_MANY_REQUESTS:
         case ERR_TRADE_CONTEXT_BUSY:
            cnt++; 	// a retryable error
            break;

         case ERR_TRADE_MODIFY_DENIED:
            // This one may be important; have to Ensure Valid Stops AND valid price (for pends)
            break;

         case ERR_PRICE_CHANGED:
         case ERR_REQUOTE:
            RefreshRates();
            cnt++;
            break; 	// we can apparently retry immediately according to MT docs.

         default:
            // an apparently serious, unretryable error.
            exit_loop = true;
            non_retryable_error = true;
            break;

         }  // end switch
      }

      if (cnt >= O_R_Setting_max_retries) {
         exit_loop = true;
      }

      if (!exit_loop) {
         OrderReliablePrint(2, "Result of attempt " + cnt + " of " + O_R_Setting_max_retries + ": Retryable error: " + OrderReliableErrTxt(err));
         OrderReliablePrint(2, "~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~");
         O_R_Sleep(O_R_Setting_sleep_time, O_R_Setting_sleep_max);
         RefreshRates();
      } else {
         if (cnt > O_R_Setting_max_retries) {
            OrderReliablePrint(2, "Retry attempts maxed at " + O_R_Setting_max_retries);
         } else if (non_retryable_error) {
            OrderReliablePrint(2, "Non-retryable error: "  + OrderReliableErrTxt(err));
         }
      }
   }

   // we have now exited from loop.
      O_R_LastErr = err; 

   if (result) {
      if (err == ERR_NO_RESULT) {
          OrderReliablePrint(1, "Server reported OrderModify() did not change TP or SL: " + ticket + " " + symbol +
                         "@" + price + " tp@" + takeprofit + " sl@" + stoploss);
          OrderReliablePrint(1, "Suggest modifying code logic to avoid.");
      
      } else {   
         OrderReliablePrint(1, "Ticket #" + ticket + ": Modification successful, updated trade details follow.");
         OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES);
         OrderPrint();
      }
   } else {
      OrderReliablePrint(1, "Failed to execute modify after " + cnt + " retries");
      OrderReliablePrint(1, "Failed modification: "  + ticket + " " + symbol +
                         "@" + price + " tp@" + takeprofit + " sl@" + stoploss);
      OrderReliablePrint(1, "Last error: " + OrderReliableErrTxt(err));
   }
   OrderReliablePrint(2, "•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   return(result);
}


//=============================================================================
//                            OrderCloseReliable()
//
//  This is intended to be a drop-in replacement for OrderClose() which,
//  one hopes, is more resistant to various forms of errors prevalent
//  with MetaTrader.
//
//  RETURN VALUE:
//     TRUE if successful, FALSE otherwise
//
//  FEATURES:
//     * Re-trying under some error conditions, sleeping a random
//       time defined by an exponential probability distribution.
//
//     * Displays various error messages on the log for debugging.
//
//  ORIGINAL AUTHOR AND DATE:
//     Derk Wehler, 2006-07-19
//
//=============================================================================
bool OrderCloseReliable(int ticket, double volume, double price,
                        int slippage, color arrow_color = CLR_NONE)
{
   bool result = false;
   bool non_retryable_error = false;

   OrderReliable_Fname = "OrderCloseReliable";
   OrderReliablePrint(2, "•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   OrderReliablePrint(1, "Attempted close of #" + ticket + " price:" + price +
                      " lots:" + volume + " slippage:" + slippage);

   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   // Get information about this order
   string symbol = "ALLOCATE";		// This is so it has memory space allocated
   int type;
   int digits;
   double point;
   double bid, ask;
   double sl, tp;
   O_R_GetOrderDetails(ticket, symbol, type, digits, point, sl, tp, bid, ask);
   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

   if (type != OP_BUY && type != OP_SELL) {
      OrderReliablePrint(1, "Error: Trying to close ticket #" + ticket + ", which is " + OrderType2String(type) + ", not OP_BUY or OP_SELL");
      return(false);
   }

   price = O_R_NormalizePrice(symbol, price);
   volume = O_R_NormalizeLots(symbol, volume);

   // ========================================================================
   // If testing or optimizing, there is no need to use this lib, as the
   // orders are not real-world, and always get placed optimally.  By
   // refactoring this option to be in this library, one no longer needs
   // to create similar code in each EA.
   if (!O_R_Setting_UseForTesting) {
      if (IsOptimization()  ||  IsTesting()) {
         result = OrderClose(ticket, volume, price, slippage, arrow_color);
         return(result);
      }
   }
   // ========================================================================


   int cnt = 0;
   int err = GetLastError(); // so we clear the global variable.
   err = 0;
   bool exit_loop = false;

   while (!exit_loop) {
      result = OrderClose(ticket, volume, price, slippage, arrow_color);
      err = GetLastError();

      if (result == true) {
         exit_loop = true;
      } else {
         switch (err) {
         case ERR_NO_ERROR:
            exit_loop = true;
            OrderReliablePrint(2, "ERR_NO_ERROR received, but OrderClose() returned false; exiting");
            break;

         case ERR_NO_RESULT:
            exit_loop = true;
            OrderReliablePrint(2, "ERR_NO_RESULT received, but OrderClose() returned false; exiting");
            break;

         case ERR_COMMON_ERROR:
         case ERR_SERVER_BUSY:
         case ERR_NO_CONNECTION:
         case ERR_TOO_FREQUENT_REQUESTS:
         case ERR_TRADE_TIMEOUT:		// for close this is a retryable error, I hope.
         case ERR_TRADE_DISABLED:
         case ERR_PRICE_CHANGED:
         case ERR_INVALID_PRICE:
         case ERR_OFF_QUOTES:
         case ERR_BROKER_BUSY:
         case ERR_REQUOTE:
         case ERR_TOO_MANY_REQUESTS:
         case ERR_TRADE_CONTEXT_BUSY:
            cnt++; 	// a retryable error
            break;

         default:
            // Any other error is an apparently serious, unretryable error.
            exit_loop = true;
            non_retryable_error = true;
            break;

         }  // end switch
      }

      if (cnt > O_R_Setting_max_retries) {
         exit_loop = true;
      }

      if (!exit_loop) {
         OrderReliablePrint(2, "Result of attempt " + cnt + " of " + O_R_Setting_max_retries + ": Retryable error: " + OrderReliableErrTxt(err));
         OrderReliablePrint(2, "~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~");
         O_R_Sleep(O_R_Setting_sleep_time, O_R_Setting_sleep_max);
      }

      if (exit_loop) {
         if (cnt > O_R_Setting_max_retries) {
            OrderReliablePrint(2, "Retry attempts maxed at " + O_R_Setting_max_retries);
         } else if (non_retryable_error) {
            OrderReliablePrint(2, "Non-retryable error: " + OrderReliableErrTxt(err));
         }
      }
   }

   O_R_LastErr = err; 
   // we have now exited from loop.
   if (result) {
      /*		if (OrderStillOpen(ticket))
      		{
      			OrderReliablePrint(1, "Close result reported success, but order remains!  Must re-try close from EA logic!");
      			OrderReliablePrint(1, "Close Failed: Ticket #" + ticket + ", Price: " +
      		                   		price + ", Slippage: " + slippage);
      			OrderReliablePrint(1, "Last error: " + OrderReliableErrTxt(err));
      			result = false;
      		}
      		else
      */
      OrderReliablePrint(1, "Successful close of Ticket #" + ticket + "     [ Last error: " + OrderReliableErrTxt(err) + " ]");
   } else {
      OrderReliablePrint(1, "Failed to execute close after " + O_R_Setting_max_retries + " retries");
      OrderReliablePrint(1, "Failed close: Ticket #" + ticket + ", Price: " +
                         price + ", Slippage: " + slippage);
      OrderReliablePrint(1, "Last error: " + OrderReliableErrTxt(err));
   }
   OrderReliablePrint(2, "•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   return(result);
}


//=============================================================================
//                           OrderCloseReliableMKT()
//
//	This function is intended for closing orders ASAP; the principal
//  difference is that in its internal retry-loop, it uses the new "Bid"
//  and "Ask" real-time variables as opposed to the OrderCloseReliable(),
//  which uses only the price given upon entry to the routine.  More likely
//  to get the order closed if price moves, but more likely to "slip"
//
//  RETURN VALUE:
//     TRUE if successful, FALSE otherwise
//
//  FEATURES:
//     * Re-trying under some error conditions, sleeping a random
//       time defined by an exponential probability distribution.
//
//     * Displays various error messages on the log for debugging.
//
//  ORIGINAL AUTHOR AND DATE:
//     Derk Wehler, 2009-04-03
//
//=============================================================================
/*
bool OrderCloseReliableMKT(int ticket, double volume, double price,
                           int slippage, color arrow_color = CLR_NONE)
{
   bool result = false;
   bool non_retryable_error = false;

   OrderReliable_Fname = "OrderCloseReliableMKT";
   OrderReliablePrint(2, "•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   OrderReliablePrint(1, "Attempted close of #" + ticket + " initial price:" + price +
                      " lots:" + volume + " slippage:" + slippage);

   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   // Get information about this order
   string symbol = "ALLOCATE";		// This is so it has memory space allocated
   int type;
   int digits;
   double point;
   double bid, ask;
   double sl, tp;
   O_R_GetOrderDetails(ticket, symbol, type, digits, point, sl, tp, bid, ask);
   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

   if (type != OP_BUY && type != OP_SELL) {
      OrderReliablePrint(1, "Error: Trying to close ticket #" + ticket + ", which is " + OrderType2String(type) + ", not OP_BUY or OP_SELL");
      return(false);
   }

   price = O_R_NormalizePrice(symbol, price);
   volume = O_R_NormalizeLots(symbol, volume);

   // ========================================================================
   // If testing or optimizing, there is no need to use this lib, as the
   // orders are not real-world, and always get placed optimally.  By
   // refactoring this option to be in this library, one no longer needs
   // to create similar code in each EA.
   if (!O_R_Setting_UseForTesting) {
      if (IsOptimization()  ||  IsTesting()) {
         result = OrderClose(ticket, volume, price, slippage, arrow_color);
         return(result);
      }
   }
   // ========================================================================


   int cnt = 0;
   int err = GetLastError(); // so we clear the global variable.
   err = 0;
   bool exit_loop = false;
   double pnow;
   int slippagenow;

   while (!exit_loop) {
      if (type == OP_BUY) {
         pnow = O_R_NormalizePrice(symbol, MarketInfo(symbol, MODE_ASK)); // we are buying at Ask
         if (pnow > price) {
            // Do not allow slippage to go negative; will cause error
            slippagenow = MathMax(0, slippage - (pnow - price) / point);
         }
      } else if (type == OP_SELL) {
         pnow = O_R_NormalizePrice(symbol, MarketInfo(symbol, MODE_BID)); // we are buying at BID
         if (pnow < price) {
            // Do not allow slippage to go negative; will cause error
            slippagenow = MathMax(0, slippage - (price - pnow) / point);
         }
      }

      result = OrderClose(ticket, volume, pnow, slippagenow, arrow_color);
      err = GetLastError();

      if (result == true) {
         exit_loop = true;
      } else {
         switch (err) {
         case ERR_NO_ERROR:
            exit_loop = true;
            OrderReliablePrint(2, "ERR_NO_ERROR received, but OrderClose() returned false; exiting");
            break;

         case ERR_NO_RESULT:
            exit_loop = true;
            OrderReliablePrint(2, "ERR_NO_RESULT received, but OrderClose() returned false; exiting");
            break;

         case ERR_COMMON_ERROR:
         case ERR_SERVER_BUSY:
         case ERR_NO_CONNECTION:
         case ERR_TOO_FREQUENT_REQUESTS:
         case ERR_TRADE_TIMEOUT:		// for close this is a retryable error, I hope.
         case ERR_TRADE_DISABLED:
         case ERR_PRICE_CHANGED:
         case ERR_INVALID_PRICE:
         case ERR_OFF_QUOTES:
         case ERR_BROKER_BUSY:
         case ERR_REQUOTE:
         case ERR_TOO_MANY_REQUESTS:
         case ERR_TRADE_CONTEXT_BUSY:
            cnt++; 	// a retryable error
            break;

         default:
            // Any other error is an apparently serious, unretryable error.
            exit_loop = true;
            non_retryable_error = true;
            break;

         }  // end switch
      }

      if (cnt > O_R_Setting_max_retries) {
         exit_loop = true;
      }

      if (!exit_loop) {
         OrderReliablePrint(2, "Result of attempt " + cnt + " of " + O_R_Setting_max_retries + ": Retryable error: " + OrderReliableErrTxt(err));
         OrderReliablePrint(2, "~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~");
         O_R_Sleep(O_R_Setting_sleep_time, O_R_Setting_sleep_max);
      }

      if (exit_loop) {
         if (cnt > O_R_Setting_max_retries) {
            OrderReliablePrint(2, "Retry attempts maxed at " + O_R_Setting_max_retries);
         } else if (non_retryable_error) {
            OrderReliablePrint(2, "Non-retryable error: " + OrderReliableErrTxt(err));
         }
      }
   }

   O_R_LastErr = err; 
   // we have now exited from loop.
   if (result) {
      OrderReliablePrint(1, "Successful close of Ticket #" + ticket + " @ " + pnow + "     [ Last error: " + OrderReliableErrTxt(err) + " ]");
   } else {
      OrderReliablePrint(1, "Failed to execute close after " + O_R_Setting_max_retries + " retries");
      OrderReliablePrint(1, "Failed close: Ticket #" + ticket + " @ Price: " +
                         pnow + " (Initial Price: " + price + "), Slippage: " +
                         slippagenow + " (Initial Slippage: " + slippage + ")");
      OrderReliablePrint(1, "Last error: " + OrderReliableErrTxt(err));
   }
   OrderReliablePrint(2, "•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   return(result);
}
*/

//=============================================================================
//                            OrderDeleteReliable()
//
//  This is intended to be a drop-in replacement for OrderDelete() which,
//  one hopes, is more resistant to various forms of errors prevalent
//  with MetaTrader.
//
//  RETURN VALUE:
//     TRUE if successful, FALSE otherwise
//
//
//  FEATURES:
//     * Re-trying under some error conditions, sleeping a random
//       time defined by an exponential probability distribution.
//
//     * Displays various error messages on the log for debugging.
//
//  ORIGINAL AUTHOR AND DATE:
//     Derk Wehler, 2006-12-21
//
//=============================================================================
bool OrderDeleteReliable(int ticket)
{
   bool result = false;
   bool non_retryable_error = false;

   // ========================================================================
   // If testing or optimizing, there is no need to use this lib, as the
   // orders are not real-world, and always get placed optimally.  By
   // refactoring this option to be in this library, one no longer needs
   // to create similar code in each EA.
   if (!O_R_Setting_UseForTesting) {
      if (IsOptimization()  ||  IsTesting()) {
         result = OrderDelete(ticket);
         return(result);
      }
   }
   // ========================================================================

   OrderReliable_Fname = "OrderDeleteReliable";
   OrderReliablePrint(2, "•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   OrderReliablePrint(1, "Attempted deletion of pending order, #" + ticket);


   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   // Get information about this order
   string symbol = "ALLOCATE";		// This is so it has memory space allocated
   int type;
   int digits;
   double point;
   double bid, ask;
   double sl, tp;
   O_R_GetOrderDetails(ticket, symbol, type, digits, point, sl, tp, bid, ask);
   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

   if (type != OP_BUYSTOP && type != OP_BUYLIMIT && type != OP_SELLSTOP && type != OP_SELLLIMIT) {
      OrderReliablePrint(1, "error: Trying to close ticket #" + ticket +
                         ", which is " + OrderType2String(type) +
                         ", not OP_BUYSTOP, OP_SELLSTOP, OP_BUYLIMIT, or OP_SELLLIMIT");
      return(false);
   }


   int cnt = 0;
   int err = GetLastError(); // so we clear the global variable.
   err = 0;
   bool exit_loop = false;

   while (!exit_loop) {
      result = OrderDelete(ticket);
      err = GetLastError();

      if (result == true) {
         exit_loop = true;
      } else {
         switch (err) {
         case ERR_NO_ERROR:
            exit_loop = true;
            OrderReliablePrint(2, "ERR_NO_ERROR received, but OrderDelete() returned false; exiting");
            break;

         case ERR_NO_RESULT:
            exit_loop = true;
            OrderReliablePrint(2, "ERR_NO_RESULT received, but OrderDelete() returned false; exiting");
            break;

         case ERR_COMMON_ERROR:
         case ERR_SERVER_BUSY:
         case ERR_NO_CONNECTION:
         case ERR_TOO_FREQUENT_REQUESTS:
         case ERR_TRADE_TIMEOUT:		// for delete this is a retryable error, I hope.
         case ERR_TRADE_DISABLED:
         case ERR_OFF_QUOTES:
         case ERR_PRICE_CHANGED:
         case ERR_BROKER_BUSY:
         case ERR_REQUOTE:
         case ERR_TOO_MANY_REQUESTS:
         case ERR_TRADE_CONTEXT_BUSY:
            cnt++; 	// a retryable error
            break;

         default:	// Any other error is an apparently serious, unretryable error.
            exit_loop = true;
            non_retryable_error = true;
            break;

         }  // end switch
      }

      if (cnt > O_R_Setting_max_retries) {
         exit_loop = true;
      }

      if (!exit_loop) {
         OrderReliablePrint(2, "Result of attempt " + cnt + " of " + O_R_Setting_max_retries + ": Retryable error: " + OrderReliableErrTxt(err));
         OrderReliablePrint(2, "~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~  ~");
         O_R_Sleep(O_R_Setting_sleep_time, O_R_Setting_sleep_max);
      } else {
         if (cnt > O_R_Setting_max_retries) {
            OrderReliablePrint(2, "Retry attempts maxed at " + O_R_Setting_max_retries);
         } else if (non_retryable_error) {
            OrderReliablePrint(2, "Non-retryable error: " + OrderReliableErrTxt(err));
         }
      }
   }

   O_R_LastErr = err; 
   // we have now exited from loop.
   if (result) {
      OrderReliablePrint(1, "Successful deletion of Ticket #" + ticket);
      return(true); // SUCCESS!
   } else {
      OrderReliablePrint(1, "Failed to execute delete after " + O_R_Setting_max_retries + " retries");
      OrderReliablePrint(1, "Failed deletion: Ticket #" + ticket);
      OrderReliablePrint(1, "Last error: " + OrderReliableErrTxt(err));
   }
   OrderReliablePrint(2, "•  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •  •");
   return(result);
}



//=============================================================================
//                           O_R_CheckForHistory()
//
//  This function is to work around a very annoying and dangerous bug in MT4:
//      immediately after you send a trade, the trade may NOT show up in the
//      order history, even though it exists according to ticket number.
//      As a result, EA's which count history to check for trade entries
//      may give many multiple entries, possibly blowing your account!
//
//  This function will take a ticket number and loop until
//  it is seen in the history.
//
//  RETURN VALUE:
//     TRUE if successful, FALSE otherwise
//
//
//  FEATURES:
//     * Re-trying under some error conditions, sleeping a random
//       time defined by an exponential probability distribution.
//
//     * Displays various error messages on the log for debugging.
//
//  ORIGINAL AUTHOR AND DATE:
//     Matt Kennel, 2010
//
//=============================================================================
bool O_R_CheckForHistory(int ticket)
{
   int lastTicket = OrderTicket();

   int cnt = 0;
   int err = GetLastError(); // so we clear the global variable.
   err = 0;
   bool exit_loop = false;
   bool success=false;

   while (!exit_loop) {
      /* loop through open trades */
      int total=OrdersTotal();
      for(int c = 0; c < total; c++) {
         if(OrderSelect(c,SELECT_BY_POS,MODE_TRADES) == true) {
            if (OrderTicket() == ticket) {
               success = true;
               exit_loop = true;
            }
         }
      }
      if (cnt > 3) {
         /* look through history too, as order may have opened and closed immediately */
         total=OrdersHistoryTotal();
         for(c = 0; c < total; c++) {
            if(OrderSelect(c,SELECT_BY_POS,MODE_HISTORY) == true) {
               if (OrderTicket() == ticket) {
                  success = true;
                  exit_loop = true;
               }
            }
         }
      }

      cnt = cnt+1;
      if (cnt > O_R_Setting_max_retries) {
         exit_loop = true;
      }
      if (!(success || exit_loop)) {
         OrderReliablePrint(2, "Did not find #"+ticket+" in history, sleeping, then doing retry #"+cnt);
         O_R_Sleep(O_R_Setting_sleep_time, O_R_Setting_sleep_max);
      }
   }
   // Select back the prior ticket num in case caller was using it.
   if (lastTicket >= 0) {
      OrderSelect(lastTicket, SELECT_BY_TICKET, MODE_TRADES);
   }
   if (!success) {
      OrderReliablePrint(1, "Never found #"+ticket+" in history! crap!");
   }
   return(success);
}



//=============================================================================
//=============================================================================
//								Utility Functions
//=============================================================================
//=============================================================================

string OrderReliableErrTxt(int err)
{
   return (err + "  ::  " + ErrorDescription(err));
}


// Defaut level is 3
// Use level = 1 to Print all but "Retry" messages
// Use level = 0 to Print nothing
/*
void OrderReliableSetO_R_ErrorLevel(int level)
{
   O_R_ErrorLevel = level;
}
*/

void OrderReliablePrint(int v, string s)
{
   if (v > O_R_Verbosity)
      return;

   // Print to log prepended with stuff;
   //if (O_R_ErrorLevel >= 99 || (!(IsOptimization()))) {
   //   if (O_R_ErrorLevel > 0) {
         Print(OrderReliable_Fname + " " + OrderReliableVersion + ":     " + s);
   //   }
   //}
}


string OrderType2String(int type)
{
   if (type == OP_BUY) {
      return("BUY");
   }
   if (type == OP_SELL) {
      return("SELL");
   }
   if (type == OP_BUYSTOP) {
      return("BUY STOP");
   }
   if (type == OP_SELLSTOP)	{
      return("SELL STOP");
   }
   if (type == OP_BUYLIMIT) {
      return("BUY LIMIT");
   }
   if (type == OP_SELLLIMIT)	{
      return("SELL LIMIT");
   }
   return("None (" + type + ")");
}



//=============================================================================
//                        O_R_EnsureValidStops()
//
//  Most MQ4 brokers have a minimum stop distance, which is the number of
//  pips from price where a pending order can be placed or where a SL & TP
//  can be placed.  THe purpose of this function is to detect when the
//  requested SL or TP is too close, and to move it out automatically, so
//  that we do not get ERR_INVALID_STOPS errors.
//
//  FUNCTION COMPLETELY OVERHAULED:
//     Derk Wehler, 2008-11-08
//
//  Getting invalid errors from this function - stops being moved then requote
//  errors when the actual change is executed, whereas a plain call of OrderModify
//  with the original stops works just fine.  Added a return at the start of the
//  function until I can figure out what's up.   Andrew Sumner, 2013-04-08
//=============================================================================
void O_R_EnsureValidStops(string symbol, int cmd, double price, double& sl, double& tp, bool isNewOrder=true)
{
   return;  // remove when this function is fixed
   string prevName = OrderReliable_Fname;
   OrderReliable_Fname = "O_R_EnsureValidStops";

   double point = MarketInfo(symbol, MODE_POINT);

   // We only use point for StopLevel, and StopLevel is reported as 10 times
   // what you expect on a 5-digit broker, so leave it as is.
   //if (point == 0.001  ||  point == 0.00001)
   //	point *= 10;

   double 	orig_sl = sl;
   double 	orig_tp = tp;
   double 	new_sl, new_tp;
   int 	min_stop_level = MarketInfo(symbol, MODE_STOPLEVEL);
   double 	servers_min_stop = min_stop_level * point;
   double 	spread = MarketInfo(symbol, MODE_ASK) - MarketInfo(symbol, MODE_BID);
   //Print("        O_R_EnsureValidStops: Symbol = " + symbol + ",  servers_min_stop = " + servers_min_stop);

   // Skip if no S/L (zero)
   if (sl != 0) {
      if (cmd % 2 == 0) {	// we are long
         // for pending orders, sl/tp can bracket price by servers_min_stop
         new_sl = price - servers_min_stop;
         //Print("        O_R_EnsureValidStops: new_sl [", new_sl, "] = price [", price, "] - servers_min_stop [", servers_min_stop, "]");

         // for market order, sl/tp must bracket bid/ask
         if (cmd == OP_BUY  &&  isNewOrder) {
            new_sl -= spread;
            //Print("        O_R_EnsureValidStops: Minus spread [", spread, "]");
         }
         sl = MathMin(sl, new_sl);
      } else {	// we are short
         new_sl = price + servers_min_stop;	// we are short
         //Print("        O_R_EnsureValidStops: new_sl [", new_sl, "] = price [", price, "] + servers_min_stop [", servers_min_stop, "]");

         // for market order, sl/tp must bracket bid/ask
         if (cmd == OP_SELL  &&  isNewOrder) {
            new_sl += spread;
            //Print("        O_R_EnsureValidStops: Plus spread [", spread, "]");
         }

         sl = MathMax(sl, new_sl);
      }
      sl = O_R_NormalizePrice(symbol, sl);
   }


   // Skip if no T/P (zero)
   if (tp != 0) {
      // check if we have to adjust the stop
      if (MathAbs(price - tp) <= servers_min_stop) {
         if (cmd % 2 == 0) {	// we are long
            new_tp = price + servers_min_stop;	// we are long
            tp = MathMax(tp, new_tp);
         } else {	// we are short
            new_tp = price - servers_min_stop;	// we are short
            tp = MathMin(tp, new_tp);
         }
         tp = O_R_NormalizePrice(symbol, tp);
      }
   }

   // notify if changed
   if (sl != orig_sl) {
      OrderReliablePrint(1, "SL was too close to brokers min distance (" + min_stop_level + "); moved SL to: " + sl);
   }
   if (tp != orig_tp) {
      OrderReliablePrint(1, "TP was too close to brokers min distance (" + min_stop_level + "); moved TP to: " + tp);
   }

   OrderReliable_Fname = prevName;
}

//=============================================================================
//                              GetLastErrorReliable()
//
// return the saved error from OrderReliable library,
//      a replacement for GetLastError()
/*
int GetLastErrorReliable() {
   return(O_R_LastErr); 
}
*/

//=============================================================================
//                              O_R_Sleep()
//
//  This sleeps a random amount of time defined by an exponential
//  probability distribution. The mean time, in Seconds is given
//  in 'mean_time'.
//  This returns immediately if we are backtesting
//  and does not sleep.
//
//=============================================================================
void O_R_Sleep(double mean_time, double max_time)
{
   if (IsTesting()) {
      return;   // return immediately if backtesting.
   }

   double p = (MathRand()+1) / 32768.0;
   double t = -MathLog(p)*mean_time;
   t = MathMin(t,max_time);
   int ms = t*1000;
   if (ms < 10) {
      ms=10;
   }
   Sleep(ms);
}


//=============================================================================
//                              O_R_Config_use2step()
//
//  Setting to toggle if OrderReliable does 1 step (setting SL and TP) or
//  2-step orders (open, then modify, as needed by many ECN's)
//
//
void O_R_Config_use2step(bool twostep)
{
   O_R_Setting_use2step = twostep;
}



//=============================================================================
//                              O_R_Config_LimitToMarket()
//
//  Setting to toggle what OrderSendReliable does with Stop or Limit orders
//  that are requested to be placed too close to the current price.
//
//  When set True, it will turn any such conundrum from a stop/limit order
/*
void O_R_Config_limit2mkt(bool limit2market)
{
   O_R_Setting_limit2market = limit2market;
}
*/

//=============================================================================
//                      O_R_Config_UseForTesting()
//
//  Setting to toggle whether this OrderReliable library is used in testing
//  and optimization.  By default, it is set to false, and will thus just pass
//  orders straight through to MT4, because those are simulated, not real-time.
//
//  When set true, it will use the full functions as normally all the time,
//  including testing / optimization.
//
//=============================================================================
void O_R_Config_UseInBacktest(bool use)
{
   O_R_Setting_UseForTesting = use;
}


//=============================================================================
//                              O_R_GetOrderDetails()()
//
//  For some OrderReliable functions (such as Modify), we need to know some
//  things about the order (such as direction and symbol).  To do this, we
//  need to select the order.  However, the caller may already have an order
//  selected so we need to be responsible and put it back when done.
//
//  Return false if there is a problem, true otherwise.
//
//=============================================================================
bool O_R_GetOrderDetails(int ticket, string& symb, int& type, int& digits,
                         double& point, double& sl, double& tp, double& bid,
                         double& ask, bool exists=true)
{
   // If this is existing order, select it and get symbol and type
   if (exists) {
      int lastTicket = OrderTicket();
      if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
         OrderReliablePrint(1, "OrderSelect() error: " + ErrorDescription(GetLastError()));
         return(false);
      }
      symb = OrderSymbol();
      type = OrderType();
      tp = OrderTakeProfit();
      sl = OrderStopLoss();

      // Select back the prior ticket num in case caller was using it.
      if (lastTicket >= 0) {
         OrderSelect(lastTicket, SELECT_BY_TICKET, MODE_TRADES);
      }
   }

   // Get bid, ask, point & digits
   bid = O_R_NormalizePrice(symb, MarketInfo(symb, MODE_BID));
   ask = O_R_NormalizePrice(symb, MarketInfo(symb, MODE_ASK));
   point = MarketInfo(symb, MODE_POINT);
   if (point == 0.001  ||  point == 0.00001) {
      point *= 10;
   }

   digits = MarketInfo(symb, MODE_DIGITS);

   if (digits == 0) {
      string prevName = OrderReliable_Fname;
      OrderReliable_Fname = "GetDigits";
      OrderReliablePrint(1, "error: MarketInfo(symbol, MODE_DIGITS) == 0");
      OrderReliable_Fname = prevName;
      return(false);
   } else if (exists) {
      tp = O_R_NormalizePrice(symb, tp);
      sl = O_R_NormalizePrice(symb, sl);
   }

   return(true);
}

double O_R_NormalizePrice(string symbol, double price)
{
   double ts = MarketInfo(symbol, MODE_TICKSIZE);
   return(MathRound(price/ts) * ts);
}

double O_R_NormalizeLots(string symbol, double lots)
{
   double ls = MarketInfo(symbol, MODE_LOTSTEP);
   return(MathRound(lots/ls)*ls);
}

//---------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------------