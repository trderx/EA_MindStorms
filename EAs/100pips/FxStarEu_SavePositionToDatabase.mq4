//+------------------------------------------------------------------+
//|                                              FxStarEu_Master.mq4 |
//|                                                https://fxstar.eu |
//+------------------------------------------------------------------+
#property copyright "2016 Copyright Fxstar.eu"
#property link      "https://fxstar.eu"
#property version   "1.00"
#property strict

//--- include library https://www.mql5.com/en/articles/932
#include <MQLMySQL.mqh>

//--- position refresh timer
extern int timer = 5; 
extern string Host = "localhost";
extern string User = "root";
extern string Password = "toor";
extern string Database = "fxstareu";
extern int Port     = 3306;
  
string INI;
datetime newbar = 0;
string Socket, Query;
int ClientFlag;
int DB; // database identifier

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   //create timer
   EventSetTimer(timer);
   //Print (MySqlVersion());

   Socket   = "0";
   ClientFlag = CLIENT_MULTI_STATEMENTS;

   // create tables
   CreateTable();    
   Prices();   
  return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();      
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
{
   // stop on weekends
   if(DayOfWeek() >= 1 && DayOfWeek() <= 5){
      if(newbar != Time[0]){          
      newbar = Time[0];
      Print(TimeToStr(Time[0], TIME_DATE|TIME_SECONDS) + " Account equity " + DoubleToString(NormalizeDouble(AccountEquity(),2),2));
      Balance();    
      }   
   }
}

string Prices(){
   int total = 1;
   total = SymbolsTotal(1);
   string all = "Symbol,Time,Open,High,Low,Close,Volume,Ask,Bid|||";
   for(int i=1;i<total;i++)
   {
    string s = SymbolName(i,1);         
    all = all +s+","+iTime(s,0,0)+","+iOpen(s,0,0)+","+iHigh(s,0,0)+","+iLow(s,0,0)+","+iClose(s,0,0)+","+iVolume(s,0,0)+","+SymbolInfoDouble(s,SYMBOL_ASK)+","+SymbolInfoDouble(s,SYMBOL_BID)+"|||";
   }   
return all;
}   
//+------------------------------------------------------------------+
//| CreateDatabase function                                                   |
//+------------------------------------------------------------------+
void CreateTable()
{
 Print ("Host: ",Host, ", User: ", User, ", Database: ",Database, " Connecting...");  
 DB = MySqlConnect(Host, User, Password, Database, Port, Socket, ClientFlag); 
 if (DB == -1) { Print ("Connection failed! Error: "+MySqlErrorDescription); } else { Print ("Connected! DBID#",DB);}
 Query = "create table IF NOT EXISTS `account_"+AccountNumber()+"`(time datetime, accountid int, balance float(10,2),equity float(10,2),margin float(10,2),freemargin float(10,2), currency varchar(20), leverage int, prices text, UNIQUE KEY `time` (`time`));";
 Query = Query + "CREATE TABLE IF NOT EXISTS `OpenSignal_"+AccountNumber()+"` (  `id` varchar(250) DEFAULT NULL, `symbol` varchar(250) DEFAULT '0',  `volume` float DEFAULT '0',  `type` varchar(250) DEFAULT '0',  `opent` datetime,  `openp` float(25,6) DEFAULT '0',  `sl` float(25,6) DEFAULT '0',  `tp` float(25,6) DEFAULT '0',  `profit` float(55,2) DEFAULT '0',    `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,  `account` varchar(250) DEFAULT '0',  `comment` text,  UNIQUE KEY `id` (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8;";
 Query = Query + "CREATE TABLE IF NOT EXISTS `CloseSignal_"+AccountNumber()+"` ( `id` varchar(250) DEFAULT NULL, `symbol` varchar(250) DEFAULT '0',  `volume` float DEFAULT '0',  `type` varchar(250) DEFAULT '0',  `opent` datetime,  `openp` float(25,6) DEFAULT '0',  `sl` float(25,6) DEFAULT '0',  `tp` float(25,6) DEFAULT '0', `closet` datetime,  `closep` float(25,6) DEFAULT '0',  `profit` float(55,2) DEFAULT '0',  `pips` float(25,2) DEFAULT '0',  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,  `account` varchar(250) DEFAULT '0',  UNIQUE KEY `id` (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8;";
 Query = Query = "create table IF NOT EXISTS `accounts`(accountid int, name text, leverage int, deposit int, currency char(3), UNIQUE KEY `accountid` (`accountid`));";
 if (MySqlExecute(DB, Query))
     {
      Print("Create table Succeeded: ", Query);
     }
 else
     {
      Alert ("Error create databases: ", MySqlErrorDescription);
      Print ("Query: ", Query);
      return;
     }     
 MySqlDisconnect(DB);
 Print ("Create Tables Done!");
}
//+------------------------------------------------------------------+
//| Balance function                                                   |
//+------------------------------------------------------------------+
void Balance()
{
 Print ("Host: ",Host, ", User: ", User, ", Database: ",Database, " Connecting...");  
 DB = MySqlConnect(Host, User, Password, Database, Port, Socket, ClientFlag); 
 if (DB == -1) { Print ("Connection failed! Error: "+MySqlErrorDescription); } else { Print ("Connected! DBID#",DB);}
 //Query = "INSERT INTO account_"+AccountNumber()+" (time, accountid, balance, equity, margin, freemargin, currency, leverage) VALUES('" + TimeToStr(Time[0], TIME_DATE|TIME_SECONDS) + "','" + AccountNumber() + "', '" + AccountBalance() + "', '" + AccountEquity() + "', '" + AccountMargin() + "', '" + AccountFreeMargin() + "', '" + AccountCurrency() + "', '" + AccountLeverage() + "') ON DUPLICATE KEY UPDATE leverage='" + AccountLeverage() +  "'";
 Query = "INSERT INTO account_"+AccountNumber()+" (time, accountid, balance, equity, margin, freemargin, currency, leverage,prices) VALUES('" + TimeToStr(Time[0], TIME_DATE|TIME_SECONDS) + "','" + AccountNumber() + "', '" + AccountBalance() + "', '" + AccountEquity() + "', '" + AccountMargin() + "', '" + AccountFreeMargin() + "', '" + AccountCurrency() + "', '" + AccountLeverage() + "', '" + Prices() + "') ON DUPLICATE KEY UPDATE prices='" + Prices() + "'";
 if (MySqlExecute(DB, Query))
     {
      Print ("Succeeded: ", Query);
     }
 else
     {
      Print ("!!! ", MySqlErrorDescription);
      Print ("Query: ", Query);
     }

     int deposit = 10000;
 Query = "INSERT INTO accounts(accountid,name,leverage,deposit,currency) VALUES('" + AccountNumber() + "', '" + AccountName() + "', '" + AccountLeverage() + "', '" + deposit + "', '" + AccountCurrency() +"') ON DUPLICATE KEY UPDATE name='" + AccountName() + "'";
 if (MySqlExecute(DB, Query))
     {
      Print ("Succeeded: ", Query);
     }
 else
     {
      Print ("!!! ", MySqlErrorDescription);
      Print ("Query: ", Query);
     }
          
 MySqlDisconnect(DB);
 Print ("Equity. Done!");
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   // stop on weekends
   if(DayOfWeek() >= 1 && DayOfWeek() <= 5){
    
   Print ("Host: ",Host, ", User: ", User, ", Database: ",Database, " Connecting...");
   DB = MySqlConnect(Host, User, Password, Database, Port, Socket, ClientFlag);   
   if (DB == -1) { Alert ("Connection failed! Error: "+MySqlErrorDescription); } else { Print ("Connected! DBID#",DB);}
    
   int orders=OrdersTotal();
   for(int i=0;i<orders;i++)
     {
     if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
     Print("Orders error ",GetLastError());
     break;
     }
     
     // SELL ORDERS
         if(OrderType() == OP_SELL){   
        
          Query = "INSERT INTO OpenSignal_"+AccountNumber()+" (id, symbol, volume, type, opent, openp, account, sl, tp, profit) VALUES('" + OrderTicket() + "','" + OrderSymbol() + "', '" + OrderLots() + "','SELL','" + OrderOpenTime() + "','" + OrderOpenPrice() + "','" + AccountNumber() + "','" + OrderStopLoss() + "','" + OrderTakeProfit() + "','" + OrderProfit() + "') ON DUPLICATE KEY UPDATE sl='" + OrderStopLoss() + "', tp='" + OrderTakeProfit() + "', profit='" + OrderProfit() + "'";
          if (MySqlExecute(DB, Query))
              {
               Print ("Succeeded: ", Query);
              }
          else
              {
               Print ("!!! ", MySqlErrorDescription);
               Print ("Query: ", Query);
              }
         }
      // BUY ORDERS
         if(OrderType() == OP_BUY){   
          
          
          Query = "INSERT INTO OpenSignal_"+AccountNumber()+" (id, symbol, volume, type, opent, openp, account, sl, tp, profit) VALUES('" + OrderTicket() + "','" + OrderSymbol() + "', '" + OrderLots() + "','BUY','" + OrderOpenTime() + "','" + OrderOpenPrice() + "','" + AccountNumber() + "','" + OrderStopLoss() + "','" + OrderTakeProfit() + "','" + OrderProfit() + "') ON DUPLICATE KEY UPDATE sl='" + OrderStopLoss() + "', tp='" + OrderTakeProfit() + "', profit='" + OrderProfit() + "'";
          if (MySqlExecute(DB, Query))
              {
               Print ("Succeeded: ", Query);
              }
          else
              {
               Print ("!!! ", MySqlErrorDescription);
               Print ("Query: ", Query);
              }
         }            
         
     }

   int ii, hTotal;
   hTotal= OrdersHistoryTotal();
   for(ii=0;ii<hTotal;ii++)
     {
      if(OrderSelect(ii,SELECT_BY_POS,MODE_HISTORY)==false)
        {
         Print("History Error ",GetLastError());
         break;
        }
        
        double Pips = 0;
     // SELL ORDERS
         if(OrderType() == OP_SELL){   
          
          //Print(OrderOpenPrice());
          Pips = ((OrderOpenPrice()-OrderClosePrice())/MarketInfo(OrderSymbol(),MODE_POINT))/10;
          //Print("SELL Pips " + Pips);
          Query = "INSERT INTO CloseSignal_"+AccountNumber()+" (id, symbol, volume, type, opent, openp, account, sl, tp, closet, closep, profit, pips) VALUES('" + OrderTicket() + "','" + OrderSymbol() + "', '" + OrderLots() + "','SELL','" + OrderOpenTime() + "','" + OrderOpenPrice() + "','" + AccountNumber() + "','" + OrderStopLoss() + "','" + OrderTakeProfit() + "','" + OrderCloseTime() + "','" + OrderClosePrice() + "','" + OrderProfit() + "','" + Pips + "')";
          if (MySqlExecute(DB, Query))
              {
               Print ("Succeeded: ", Query);
              }
          else
              {
               Print ("!!! ", MySqlErrorDescription);
               Print ("Query: ", Query);
              }
         }
      // BUY ORDERS
         if(OrderType() == OP_BUY){           
          Pips = 0;
          //Print(OrderOpenPrice());
          Pips = ((OrderClosePrice()-OrderOpenPrice())/MarketInfo(OrderSymbol(),MODE_POINT))/10;
          //Print("BUY Pips " +Pips);
          Query = "INSERT INTO CloseSignal_"+AccountNumber()+" (id, symbol, volume, type, opent, openp, account, sl, tp, closet, closep, profit, pips) VALUES('" + OrderTicket() + "','" + OrderSymbol() + "', '" + OrderLots() + "','BUY','" + OrderOpenTime() + "','" + OrderOpenPrice() + "','" + AccountNumber() + "','" + OrderStopLoss() + "','" + OrderTakeProfit() + "','" + OrderCloseTime() + "','" + OrderClosePrice() + "','" + OrderProfit() + "','" + Pips + "')";
          if (MySqlExecute(DB, Query))
              {
               Print ("Succeeded: ", Query);
              }
          else
              {
               Print ("!!! ", MySqlErrorDescription);
               Print ("Query: ", Query);
              }
         }  
         
    }
   MySqlDisconnect(DB);
   Print ("Positions. Done!");
   }
 }
//+------------------------------------------------------------------+

 /*
  // multi-insert
  Query =         "INSERT INTO `test_table` (id, code, start_date) VALUES (1,\'EURUSD\',\'2014.01.01 00:00:01\');";
  Query = Query + "INSERT INTO `test_table` (id, code, start_date) VALUES (2,\'EURJPY\',\'2014.01.02 00:02:00\');";
  Query = Query + "INSERT INTO `test_table` (id, code, start_date) VALUES (3,\'USDJPY\',\'2014.01.03 03:00:00\');";
  if (MySqlExecute(DB, Query))
     {
      Print ("Succeeded! 3 rows has been inserted by one query.");
     }
  else
     {
      Print ("Error of multiple statements: ", MySqlErrorDescription);
     }
   */
 
