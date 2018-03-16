//===========================================================================
//        OrderReliable.mqh
//
//   A library for MT4 expert advisors,  intended to give more
//   reliable order handling.   This is under development.
//
//                       Instructions:
//
//  Put this file in the experts/include directory.
//  Include the line
//     #include <OrderReliable_V?_?_?.mqh>
// 
// in the beginning of your EA with the question marks replaced by
// the actual version number and file name of the library, i.e.
// this file.  
// 
// YOU MUST EDIT THE EA MANUALLY IN ORDER TO USE THIS LIBRARY, 
// BY BOTH SPECIFYING THE INCLUDE FILE AND THEN MODIFYING THE EA
// CODE TO USE THE FUNCTIONS.  In particular you must change, in the EA,
// OrderSend() commands to OrderSendReliable() and OrderModify() commands
// to OrderModifyReliable(), or any others which are appropriate.
//
// DO NOT COMPILE THIS FILE ON ITS OWN.  It is meaningless.  You only
// compile your "main" EA. 
//
//===========================================================================
//  Version:   0.2.4
//  Contents:
//
//      OrderSendReliable()  
//           This is intended to be a drop-in replacement for OrderSend() which, one hopes
//           is more resistant to various forms of errors prevalent with MetaTrader.
//
//      OrderModifyReliable
//            A replacement for OrderModify with more error handling, similar to
//            OrderSendReliable()
//
//      OrderModifyReliableSymbol()
//            Adds a "symbol" field to OrderModifyReliable (not drop in any more)
//            so that it can fix problems with stops/take profits which are
//            too close to market, as well as normalization problems.
// 
//      OrderReliableLastErr()
//            Returns the last error seen by an Order*Reliable() call.
//            NOTE: GetLastError()  WILL NOT WORK to return the error
//            after a call.  This is a flaw in Metatrader design, in that
//            GetLastError() also clears it.  Hence in this way
//            this library cannot be a total drop-in replacement.
// 
//===========================================================================
//  History:
//   2006-07-14:  ERR_TRADE_TIMEOUT now a retryable error for modify   0.2.4
//                only.  Unclear about what to do for send. 
//                Adds OrderReliableLastErr()
//
//   2006-06-07:  Version number now in log comments.  Docs updated.   0.2.3
//                OP_BUYLIMIT/OP_SELLLIMIT added. Increase retry time  
//   2006-06-07:  Fixed int/bool type mismatch compiler ignored        0.2.2
//   2006-06-06:  Returns success if modification is redundant         0.2.1
//   2006-06-06:  Added OrderModifyReliable                            0.2.0
//   2006-06-05:  Fixed idiotic typographical bug.                     0.1.2
//   2006-06-05:  Added ERR_TRADE_CONTEXT_BUSY to retryable errors.    0.1.1
//   2006-05-29:  Created.  Only OrderSendReliable() implemented       0.1
//       
// LICENSING:  This is free, open source software, licensed under
// Version 2 of the GNU General Public License (GPL). 
// 
// In particular, this means that distribution of this software in a binary format,
// e.g. as compiled in as part of a .ex4, must be
// accompanied by the non-obfuscated source code of both this file, AND the
// .mq4 source files which it is compiled with, or you must make such files available at 
// no charge to binary recipients.   If you do not agree with such terms
// you must not use this code.  Detailed terms of the GPL are widely 
// available on the Internet.  The Library GPL (LGPL) was intentionally not used,
// therefore the source code of files which link to this are subject to
// terms of the GPL if binaries made from them are publicly distributed or sold. 
//  
// Copyright (2006), Matthew Kennel     
//===========================================================================


//===========================================================================
//                         OrderSendReliable()
//
/*         This is intended to be a drop-in replacement for OrderSend() which, one hopes
           is more resistant to various forms of errors prevalent with MetaTrader.
           
syntax:
         
    int OrderSendReliable(string symbol, int cmd, double volume, double price,
		   int slippage, double stoploss, double takeprofit,
		   string comment, int magic, datetime expiration =
		   0, color arrow_color = CLR_NONE) //    

returns: ticket number or -1 under some error conditions. 

    Features:
       * re-trying under some error conditions, sleeping
         a random time defined by an exponential probability distribution.
       * automatic normalization of Digits
       * automatically makes sure that stop levels are more than
         the minimum stop distance, as given by the server.
       * automatically converts limit orders to market orders 
         when the limit orders are rejected by the server for being
         to close to market.
       * displays various error messages on the log for debugging.
 
  Matt Kennel, mbkennel@gmail.com  2006-05-28
 */

//===========================================================================
#include <stdlib.mqh>
#include <stderror.mqh> 

string OrderReliableVersion="V0_2_3";

int retry_attempts=10;
double sleep_time=4.0,sleep_maximum=25.0;  // in seconds

string OrderReliable_Fname="OrderReliable fname unset";

static int _OR_err=0; // 
                      //Matt's O-R stuff
int             O_R_Setting_max_retries=10;
double          O_R_Setting_sleep_time=4.0; /* seconds */
double          O_R_Setting_sleep_max=15.0; /* seconds */
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OrderSendReliable(string symbol,int cmd,double volume,double price,
                      int slippage,double stoploss,double takeprofit,
                      string comment,int magic,datetime expiration=
                      0,color arrow_color=CLR_NONE) 
  {

//
// check basic conditions see if trade is possible. 
//
   OrderReliable_Fname="OrderSendReliable";
   OrderReliablePrint(" attempted "+OrderReliable_CommandString(cmd)+" "+volume+" lots @"+price+" sl:"+stoploss+" tp:"+takeprofit);
   if(!IsConnected()) 
     {
      OrderReliablePrint("error: IsConnected() == false");
      _OR_err=ERR_NO_CONNECTION;
      return(-1);
     }
   if(IsStopped()) 
     {
      OrderReliablePrint("error: IsStopped() == true");
      _OR_err=ERR_COMMON_ERROR;
      return(-1);
     }
   int cnt=0;
   while(!IsTradeAllowed() && cnt<retry_attempts) 
     {
      OrderReliable_SleepRandomTime(sleep_time,sleep_maximum);
      cnt++;
     }
   if(!IsTradeAllowed()) 
     {
      OrderReliablePrint("error: no operation possible because IsTradeAllowed()==false, even after retries.");
      _OR_err=ERR_TRADE_CONTEXT_BUSY;

      return(-1);
     }

// let's normalize all price/stoploss/takeprofit to the proper # of digits.
   int digits=MarketInfo(symbol,MODE_DIGITS);
   if(digits>0) 
     {
      price=NormalizeDouble(price,digits);
      stoploss=NormalizeDouble(stoploss,digits);
      takeprofit=NormalizeDouble(takeprofit,digits);
     }
   if(stoploss!=0) OrderReliable_EnsureValidStop(symbol,price,stoploss);

   int err=GetLastError(); // so we clear the global variable.  
   err=0;
   _OR_err=0;
   bool exit_loop=false;
   bool limit_to_market=false;
// limit/stop order. 
   int ticket=-1;

   if((cmd==OP_BUYSTOP) || (cmd==OP_SELLSTOP) || (cmd==OP_BUYLIMIT) || (cmd==OP_SELLLIMIT)) 
     {
      cnt= 0;
      while(!exit_loop) 
        {
         if(IsTradeAllowed()) 
           {
            ticket=OrderSend(symbol,cmd,volume,price,slippage,stoploss,takeprofit,comment,magic,expiration,arrow_color);
            err=GetLastError();
            _OR_err=err;
              } else {
            cnt++;
           }
         switch(err) 
           {
            case ERR_NO_ERROR:
               exit_loop=true;
               break;
            case ERR_SERVER_BUSY:
            case ERR_NO_CONNECTION:
            case ERR_INVALID_PRICE:
            case ERR_OFF_QUOTES:
            case ERR_BROKER_BUSY:
            case ERR_TRADE_CONTEXT_BUSY:
               cnt++; // a retryable error
               break;
            case ERR_PRICE_CHANGED:
            case ERR_REQUOTE:
               RefreshRates();
               continue; // we can apparently retry immediately according to MT docs.
            case ERR_INVALID_STOPS:
               double servers_min_stop=MarketInfo(symbol,MODE_STOPLEVEL)*MarketInfo(symbol,MODE_POINT);
               if(cmd==OP_BUYSTOP) 
                 {
                  if(MathAbs(Ask-price)<=servers_min_stop)
                     // we are too close to put in a limit/stop order so go to market.
                     limit_to_market=true;
                    } else if(cmd==OP_SELLSTOP) {
                  if(MathAbs(Bid-price)<=servers_min_stop)
                     limit_to_market=true;
                 }
               exit_loop=true;
               break;
            default:
               // an apparently serious error.
               exit_loop=true;
               break;
           }  // end switch 

         if(cnt>retry_attempts) exit_loop=true;
         if(exit_loop) 
           {
            if(err!=ERR_NO_ERROR) 
              {
               OrderReliablePrint("non-retryable error: "+OrderReliableErrTxt(err));
              }
            if(cnt>retry_attempts) 
              {
               OrderReliablePrint("retry attempts maxed at "+retry_attempts);
              }
           }
         if(!exit_loop) 
           {
            OrderReliablePrint("retryable error ("+cnt+"/"+retry_attempts+"): "+OrderReliableErrTxt(err));
            OrderReliable_SleepRandomTime(sleep_time,sleep_maximum);
            RefreshRates();
           }
        }
      // we have now exited from loop. 
      bool bRes;
      if(err==ERR_NO_ERROR) 
        {
         OrderReliablePrint("apparently successful OP_BUYSTOP or OP_SELLSTOP order placed, details follow.");
         bRes=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
         OrderPrint();
         return(ticket); // SUCCESS! 
        }
      if(!limit_to_market) 
        {
         OrderReliablePrint("failed to execute stop or limit order after "+cnt+" retries");
         OrderReliablePrint("failed trade: "+OrderReliable_CommandString(cmd)+" "+symbol+"@"+price+" tp@"+takeprofit+" sl@"+stoploss);
         OrderReliablePrint("last error: "+OrderReliableErrTxt(err));
         return(-1);
        }
     }  // end     

   if(limit_to_market) 
     {
      OrderReliablePrint("going from limit order to market order because market is too close.");
      if((cmd==OP_BUYSTOP) || (cmd==OP_BUYLIMIT)) 
        {
         cmd = OP_BUY;
         price=Ask;
           } else if((cmd==OP_SELLSTOP) || (cmd==OP_SELLLIMIT)) {
         cmd=OP_SELL;
         price=Bid;
        }
     }

// we now have a market order.
   err=GetLastError(); // so we clear the global variable.  
   err= 0;
   _OR_err=0;
   ticket=-1;

   if((cmd==OP_BUY) || (cmd==OP_SELL)) 
     {
      cnt= 0;
      while(!exit_loop) 
        {
         if(IsTradeAllowed()) 
           {
            ticket=OrderSend(symbol,cmd,volume,price,slippage,stoploss,takeprofit,comment,magic,expiration,arrow_color);
            err=GetLastError();
            _OR_err=err;
              } else {
            cnt++;
           }
         switch(err) 
           {
            case ERR_NO_ERROR:
               exit_loop=true;
               break;
            case ERR_SERVER_BUSY:
            case ERR_NO_CONNECTION:
            case ERR_INVALID_PRICE:
            case ERR_OFF_QUOTES:
            case ERR_BROKER_BUSY:
            case ERR_TRADE_CONTEXT_BUSY:
               cnt++; // a retryable error
               break;
            case ERR_PRICE_CHANGED:
            case ERR_REQUOTE:
               RefreshRates();
               continue; // we can apparently retry immediately according to MT docs.
            default:
               // an apparently serious, unretryable error.
               exit_loop=true;
               break;
           }  // end switch 

         if(cnt>retry_attempts) exit_loop=true;
         if(!exit_loop) 
           {
            OrderReliablePrint("retryable error ("+cnt+"/"+retry_attempts+"): "+OrderReliableErrTxt(err));
            OrderReliable_SleepRandomTime(sleep_time,sleep_maximum);
            RefreshRates();
           }
         if(exit_loop) 
           {
            if(err!=ERR_NO_ERROR) 
              {
               OrderReliablePrint("non-retryable error: "+OrderReliableErrTxt(err));
              }
            if(cnt>retry_attempts) 
              {
               OrderReliablePrint("retry attempts maxed at "+retry_attempts);
              }
           }
        }
      // we have now exited from loop. 
      if(err==ERR_NO_ERROR) 
        {
         OrderReliablePrint("apparently successful OP_BUY or OP_SELL order placed, details follow.");
         O_R_CheckForHistory(ticket);
         bRes=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
         OrderPrint();
         return(ticket); // SUCCESS! 
        }
      OrderReliablePrint("failed to execute OP_BUY/OP_SELL, after "+cnt+" retries");
      OrderReliablePrint("failed trade: "+OrderReliable_CommandString(cmd)+" "+symbol+"@"+price+" tp@"+takeprofit+" sl@"+stoploss);
      OrderReliablePrint("last error: "+OrderReliableErrTxt(err));
      return(-1);
     }
     return(-1);
  }  // end     
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool OrderModifyReliable(int ticket,double price,double stoploss,double takeprofit,datetime expiration,color arrow_color=CLR_NONE) 
  {
// Replacement for OrderModifyReliable 
   OrderReliable_Fname="OrderModifyReliable";

   OrderReliablePrint(" attempted modify of #"+ticket+" price:"+price+" sl:"+stoploss+" tp:"+takeprofit);

   if(!IsConnected()) 
     {
      OrderReliablePrint("error: IsConnected() == false");
      _OR_err=ERR_NO_CONNECTION;
      return(false);
     }
   if(IsStopped()) 
     {
      OrderReliablePrint("error: IsStopped() == true");
      return(false);
     }
   int cnt=0;
   while(!IsTradeAllowed() && cnt<retry_attempts) 
     {
      OrderReliable_SleepRandomTime(sleep_time,sleep_maximum);
      cnt++;
     }
   if(!IsTradeAllowed()) 
     {
      OrderReliablePrint("error: no operation possible because IsTradeAllowed()==false, even after retries.");
      _OR_err=ERR_TRADE_CONTEXT_BUSY;
      return(false);
     }

   bool bRes;
   if(false) 
     {
      // This section is 'nulled out', because
      // it would have to involve an 'OrderSelect()' to obtain
      // the symbol string, and that would change the global context of the
      // existing OrderSelect, and hence would not be a drop-in replacement
      // for OrderModify().
      //
      // See OrderModifyReliableSymbol() where the user passes in the Symbol 
      // manually.

      bRes=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
      string symbol=OrderSymbol();
      int digits=MarketInfo(symbol,MODE_DIGITS);
      if(digits>0) 
        {
         price=NormalizeDouble(price,digits);
         stoploss=NormalizeDouble(stoploss,digits);
         takeprofit=NormalizeDouble(takeprofit,digits);
        }
      if(stoploss!=0) OrderReliable_EnsureValidStop(symbol,price,stoploss);
     }
   int err=GetLastError(); // so we clear the global variable.  
   err=0;
   _OR_err=0;
   bool exit_loop=false;
   cnt=0;
   bool result=false;

   while(!exit_loop) 
     {
      if(IsTradeAllowed()) 
        {
         result=OrderModify(ticket,price,stoploss,takeprofit,expiration,arrow_color);
         err=GetLastError();
         _OR_err=err;
           } else {
         cnt++;
        }
      if(result==true) 
        {
         exit_loop=true;
        }
      switch(err) 
        {
         case ERR_NO_ERROR:
            exit_loop=true;
            break;
         case ERR_NO_RESULT:
            // modification without changing a parameter. 
            // if you get this then you may want to change the code.
            exit_loop=true;
            break;
         case ERR_SERVER_BUSY:
         case ERR_NO_CONNECTION:
         case ERR_INVALID_PRICE:
         case ERR_OFF_QUOTES:
         case ERR_BROKER_BUSY:
         case ERR_TRADE_CONTEXT_BUSY:
         case ERR_TRADE_TIMEOUT:   // for modify this is a retryable error, I hope. 
            cnt++; // a retryable error
            break;
         case ERR_PRICE_CHANGED:
         case ERR_REQUOTE:
            RefreshRates();
            continue; // we can apparently retry immediately according to MT docs.
         default:
            // an apparently serious, unretryable error.
            exit_loop=true;
            break;
        }  // end switch 

      if(cnt>retry_attempts) exit_loop=true;
      if(!exit_loop) 
        {
         OrderReliablePrint("retryable error ("+cnt+"/"+retry_attempts+"): "+OrderReliableErrTxt(err));
         OrderReliable_SleepRandomTime(sleep_time,sleep_maximum);
         RefreshRates();
        }
      if(exit_loop) 
        {
         if((err!=ERR_NO_ERROR) && (err!=ERR_NO_RESULT)) 
           {
            OrderReliablePrint("non-retryable error: "+OrderReliableErrTxt(err));
           }
         if(cnt>retry_attempts) 
           {
            OrderReliablePrint("retry attempts maxed at "+retry_attempts);
           }
        }
     }
// we have now exited from loop. 
   if((result==true) || (err==ERR_NO_ERROR)) 
     {
      OrderReliablePrint("apparently successful modification order, updated trade details follow.");
      bRes=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
      OrderPrint();
      return(true); // SUCCESS! 
     }
   if(err==ERR_NO_RESULT) 
     {
      OrderReliablePrint("Server reported modify order did not actually change parameters.");
      OrderReliablePrint("redundant modification: "+ticket+" "+symbol+"@"+price+" tp@"+takeprofit+" sl@"+stoploss);
      OrderReliablePrint("Suggest modifying code logic to avoid.");
      return(true);
     }
   OrderReliablePrint("failed to execute modify after "+cnt+" retries");
   OrderReliablePrint("failed modification: "+ticket+" "+symbol+"@"+price+" tp@"+takeprofit+" sl@"+stoploss);
   OrderReliablePrint("last error: "+OrderReliableErrTxt(err));
   return(false);


  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool OrderModifyReliableSymbol(string symbol,int ticket,double price,double stoploss,double takeprofit,datetime expiration,color arrow_color=CLR_NONE) 
  {
// This has the same calling sequence as OrderModify() except that the user must provide the symbol.
// This function will then be able to ensure proper normalization and stop levels.

   int digits=MarketInfo(symbol,MODE_DIGITS);
   if(digits>0) 
     {
      price=NormalizeDouble(price,digits);
      stoploss=NormalizeDouble(stoploss,digits);
      takeprofit=NormalizeDouble(takeprofit,digits);
     }
   if(stoploss!=0) OrderReliable_EnsureValidStop(symbol,price,stoploss);
   return(OrderModifyReliable(ticket,price,stoploss,takeprofit,expiration,arrow_color));

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OrderReliableLastErr() 
  {
   return (_OR_err);
  }
//===========================================================================

//===========================================================================
//                          Utility Functions
//===========================================================================

string OrderReliableErrTxt(int err) 
  {
   return (""+err+":"+ErrorDescription(err));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OrderReliablePrint(string s) 
  {
// Print to log prepended with stuff;
   Print(OrderReliable_Fname+" "+OrderReliableVersion+":"+s);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OrderReliable_EnsureValidStop(string symbol,double price,double &sl) 
  {
// adjust stop loss so that it is legal.
   if(sl == 0) return;

   double servers_min_stop=MarketInfo(symbol,MODE_STOPLEVEL)*MarketInfo(symbol,MODE_POINT);

   if(MathAbs(price-sl)<=servers_min_stop) 
     {
      // we have to adjust the stop.
      if(price>sl) 
        { // we are buying
         sl=price-servers_min_stop;
           } else if(price<sl) {
         sl=price+servers_min_stop;
           } else {
         OrderReliablePrint("EnsureValidStop: error, passed in price == sl, cannot adjust");
        }
      sl=NormalizeDouble(sl,MarketInfo(symbol,MODE_DIGITS));
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string OrderReliable_CommandString(int cmd) 
  {
   if(cmd==OP_BUY) 
     {
      return("OP_BUY");
     }
   if(cmd==OP_SELL) 
     {
      return("OP_SELL");
     }
   if(cmd==OP_BUYSTOP) 
     {
      return("OP_BUYSTOP");
     }
   if(cmd==OP_SELLSTOP) 
     {
      return("OP_SELLSTOP");
     }
   if(cmd==OP_BUYLIMIT) 
     {
      return("OP_BUYLIMIT");
     }
   if(cmd==OP_SELLLIMIT) 
     {
      return("OP_SELLLIMIT");
     }
   return("(CMD=="+cmd+")");

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OrderReliable_SleepRandomTime(double mean_time,double max_time) 
  {
// This sleeps a random amount of time defined by 
// an exponential probability distribution. The mean time, in Seconds
// is given in 'mean_time'
// This is the back-off strategy used by Ethernet.  This will 
// quantize in tenths of seconds, so don't call this with a too 
// small a number.  This returns immediately if we are backtesting
// and does not sleep.
//
// Matt Kennel mbkennel@gmail.com.
//
   if(IsTesting()) return; // return immediately if backtesting.

   double tenths=MathCeil(mean_time/0.1);
   if(tenths <= 0) return;

   int maxtenths=MathRound(max_time/0.1);
   double p=1.0-1.0/tenths;

   Sleep(1000); // one tenth of a second
   for(int i=0; i<maxtenths; i++) 
     {
      if(MathRand()>p*32768) break;
      // MathRand() returns in 0..32767
      Sleep(1000);
     }
  }
//=============================================================================
//							 OrderCloseReliable()
//
//	This is intended to be a drop-in replacement for OrderClose() which, 
//	one hopes, is more resistant to various forms of errors prevalent 
//	with MetaTrader.
//			  
//	RETURN VALUE: 
//
//		TRUE if successful, FALSE otherwise
//
//
//	FEATURES:
//
//		 * Re-trying under some error conditions, sleeping a random 
//		   time defined by an exponential probability distribution.
//
//		 * Displays various error messages on the log for debugging.
//
//
//	Derk Wehler, ashwoods155@yahoo.com  	2006-07-19
//
//=============================================================================
bool OrderCloseReliable(int ticket,double lots,double price,
                        int slippage,color arrow_color=CLR_NONE)
  {
   OrderReliable_Fname="OrderCloseReliable";

   OrderReliablePrint(" attempted close of #"+ticket+" price:"+price+
                      " lots:"+lots+" slippage:"+slippage);

   if(!IsConnected())
     {
      OrderReliablePrint("error: IsConnected() == false");
      _OR_err=ERR_NO_CONNECTION;
      return(false);
     }

   if(IsStopped())
     {
      OrderReliablePrint("error: IsStopped() == true");
      return(false);
     }

   int cnt=0;
   while(!IsTradeAllowed() && cnt<retry_attempts)
     {
      OrderReliable_SleepRandomTime(sleep_time,sleep_maximum);
      cnt++;
     }
   if(!IsTradeAllowed())
     {
      OrderReliablePrint("error: no operation possible because IsTradeAllowed()==false, even after retries.");
      _OR_err=ERR_TRADE_CONTEXT_BUSY;
      return(false);
     }

   int err=GetLastError(); // so we clear the global variable.  
   err=0;
   _OR_err=0;
   bool exit_loop=false;
   cnt=0;
   bool result=false;

   while(!exit_loop)
     {
      if(IsTradeAllowed())
        {
         result=OrderClose(ticket,lots,price,slippage,arrow_color);
         err=GetLastError();
         _OR_err=err;
        }
      else
         cnt++;

      if(result==true)
         exit_loop=true;

      switch(err)
        {
         case ERR_NO_ERROR:
            exit_loop=true;
            break;

         case ERR_SERVER_BUSY:
         case ERR_NO_CONNECTION:
         case ERR_INVALID_PRICE:
         case ERR_OFF_QUOTES:
         case ERR_BROKER_BUSY:
         case ERR_TRADE_CONTEXT_BUSY:
         case ERR_TRADE_TIMEOUT:      // for modify this is a retryable error, I hope. 
            cnt++;    // a retryable error
            break;

         case ERR_PRICE_CHANGED:
         case ERR_REQUOTE:
            RefreshRates();
            continue;    // we can apparently retry immediately according to MT docs.

         default:
            // an apparently serious, unretryable error.
            exit_loop=true;
            break;

        }  // end switch 

      if(cnt>retry_attempts)
         exit_loop=true;

      if(!exit_loop)
        {
         OrderReliablePrint("retryable error ("+cnt+"/"+retry_attempts+
                            "): "+OrderReliableErrTxt(err));
         OrderReliable_SleepRandomTime(sleep_time,sleep_maximum);
         RefreshRates();
        }

      if(exit_loop)
        {
         if((err!=ERR_NO_ERROR) && (err!=ERR_NO_RESULT))
            OrderReliablePrint("non-retryable error: "+OrderReliableErrTxt(err));

         if(cnt>retry_attempts)
            OrderReliablePrint("retry attempts maxed at "+retry_attempts);
        }
     }

// we have now exited from loop. 
   bool bRes;
   if((result==true) || (err==ERR_NO_ERROR))
     {
      OrderReliablePrint("apparently successful modification order, updated trade details follow.");
      bRes=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
      OrderPrint();
      return(true); // SUCCESS! 
     }

   OrderReliablePrint("failed to execute close after "+cnt+" retries");
   OrderReliablePrint("failed close: Ticket #"+ticket+", Price: "+
                      price+", Slippage: "+slippage);
   OrderReliablePrint("last error: "+OrderReliableErrTxt(err));

   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool O_R_CheckForHistory(int ticket)
  {
//My thanks to Matt for this code. He also has the undying gratitude of all users of my trading robots

   int lastTicket=OrderTicket();

   int cnt =0;
   int err=GetLastError(); // so we clear the global variable.
   err=0;
   bool exit_loop=false;
   bool success=false;

   while(!exit_loop) 
     {
/* loop through open trades */
      int total=OrdersTotal();
      for(int c=0; c<total; c++) 
        {
         if(OrderSelect(c,SELECT_BY_POS,MODE_TRADES)==true) 
           {
            if(OrderTicket()==ticket) 
              {
               success=true;
               exit_loop=true;
              }
           }
        }
      if(cnt>3) 
        {
/* look through history too, as order may have opened and closed immediately */
         total=OrdersHistoryTotal();
         for(c=0; c<total; c++) 
           {
            if(OrderSelect(c,SELECT_BY_POS,MODE_HISTORY)==true) 
              {
               if(OrderTicket()==ticket) 
                 {
                  success=true;
                  exit_loop=true;
                 }
              }
           }
        }

      cnt=cnt+1;
      if(cnt>O_R_Setting_max_retries) 
        {
         exit_loop=true;
        }
      if(!(success || exit_loop)) 
        {
         Print("Did not find #"+ticket+" in history, sleeping, then doing retry #"+cnt);
         O_R_Sleep(O_R_Setting_sleep_time,O_R_Setting_sleep_max);
        }
     }
// Select back the prior ticket num in case caller was using it.
   bool bRes;
   if(lastTicket>=0) 
     {
      bRes=OrderSelect(lastTicket,SELECT_BY_TICKET,MODE_TRADES);
     }
   if(!success) 
     {
      Print("Never found #"+ticket+" in history! crap!");
     }
   return(success);
  }//End bool O_R_CheckForHistory(int ticket)
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
void O_R_Sleep(double mean_time,double max_time)
  {
   if(IsTesting()) 
     {
      return;   // return immediately if backtesting.
     }

   double p = (MathRand()+1) / 32768.0;
   double t = -MathLog(p)*mean_time;
   t=MathMin(t,max_time);
   int ms=t*1000;
   if(ms<10) 
     {
      ms=10;
     }
   Sleep(ms);
  }//End void O_R_Sleep(double mean_time, double max_time)
