//+------------------------------------------------------------------+
//|                                              FxStarEu_Master.mq4 |
//|                                          https://forex.fxstar.eu |
//+------------------------------------------------------------------+
#property copyright "Marcin Łukaszewski"
#property link      "https://forex.fxstar.eu"
#property version   "1.00"
#property strict

//--- include library https://www.mql5.com/en/articles/932
#include <MQLMySQL.mqh>

//--- position refresh timer
extern int timer = 3; 
extern string Host = "localhost";
extern string User = "fx";
extern string Password = "pass";
extern string Database = "fxstareu";
extern int Port     = 3306;
  
string INI;
int newbar = 0;
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
   if(newbar != Time[0]){          
   newbar = (int)Time[0];
   Print(TimeToStr(Time[0], TIME_DATE|TIME_SECONDS) + " Account equity " + DoubleToString(NormalizeDouble(AccountEquity(),2),2));
   Balance(); 
   }   
}
//+------------------------------------------------------------------+
//| CreateDatabase function                                                   |
//+------------------------------------------------------------------+
void CreateTable()
{
 Print ("Host: ",Host, ", User: ", User, ", Database: ",Database, " Connecting...");  
 DB = MySqlConnect(Host, User, Password, Database, Port, Socket, ClientFlag); 
 if (DB == -1) { Print ("Connection failed! Error: "+MySqlErrorDescription); } else { Print ("Connected! DBID#",DB);}
 Query = "create table IF NOT EXISTS `account_"+AccountNumber()+"`(time datetime, accountid int, balance float(10,2),equity float(10,2),margin float(10,2),freemargin float(10,2), currency varchar(20), leverage int, UNIQUE KEY `time` (`time`));";
 Query = Query + "CREATE TABLE IF NOT EXISTS `OpenSignal_"+AccountNumber()+"` (  `id` varchar(250) DEFAULT NULL,  `symbol` varchar(250) DEFAULT '0',  `volume` float DEFAULT '0',  `type` varchar(250) DEFAULT '0',  `opent` datetime,  `openp` float(25,6) DEFAULT '0',  `sl` float(25,6) DEFAULT '0',  `tp` float(25,6) DEFAULT '0',  `profit` float(55,2) DEFAULT '0',    `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,  `account` varchar(250) DEFAULT '0',  `comment` text,  UNIQUE KEY `id` (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8;";
 Query = Query + "CREATE TABLE IF NOT EXISTS `CloseSignal_"+AccountNumber()+"` (  `id` varchar(250) DEFAULT NULL,  `closet` datetime,  `closep` float(25,6) DEFAULT '0',  `profit` float(55,2) DEFAULT '0',  `pips` float(25,2) DEFAULT '0',  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,  `account` varchar(250) DEFAULT '0',  UNIQUE KEY `id` (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8;";
 
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
 Print ("Mysql Disconnected. Done!");
}
//+------------------------------------------------------------------+
//| Balance function                                                   |
//+------------------------------------------------------------------+
void Balance()
{
 Print ("Host: ",Host, ", User: ", User, ", Database: ",Database, " Connecting...");  
 DB = MySqlConnect(Host, User, Password, Database, Port, Socket, ClientFlag); 
 if (DB == -1) { Print ("Connection failed! Error: "+MySqlErrorDescription); } else { Print ("Connected! DBID#",DB);}
 Query = "INSERT INTO account_"+AccountNumber()+" (time, accountid, balance, equity, margin, freemargin, currency, leverage) VALUES('" + TimeToStr(Time[0], TIME_DATE|TIME_SECONDS) + "','" + AccountNumber() + "', '" + AccountBalance() + "', '" + AccountEquity() + "', '" + AccountMargin() + "', '" + AccountFreeMargin() + "', '" + AccountCurrency() + "', '" + AccountLeverage() + "')";
 if (MySqlExecute(DB, Query))
     {
      Print ("Succeeded: ", Query);
     }
 else
     {
      Print ("Error: ", MySqlErrorDescription);
      Print ("Query: ", Query);
     }
     
 MySqlDisconnect(DB);
 Print ("Mysql Disconnected. Done!");
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
 
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
         
         Print(OrderOpenPrice());
          Query = "INSERT INTO OpenSignal_"+AccountNumber()+" (id, symbol, volume, type, opent, openp, account, sl, tp, profit) VALUES('" + OrderTicket() + "','" + OrderSymbol() + "', '" + OrderLots() + "','SELL','" + OrderOpenTime() + "','" + OrderOpenPrice() + "','" + AccountNumber() + "','" + OrderStopLoss() + "','" + OrderTakeProfit() + "','" + OrderProfit() + "') ON DUPLICATE KEY UPDATE sl='" + OrderStopLoss() + "', tp='" + OrderTakeProfit() + "', profit='" + OrderProfit() + "'";
          if (MySqlExecute(DB, Query))
              {
               Print ("Succeeded: ", Query);
              }
          else
              {
               Print ("Error: ", MySqlErrorDescription);
               Print ("Query: ", Query);
              }
         }
      // BUY ORDERS
         if(OrderType() == OP_BUY){   
          
          Print(OrderOpenPrice());
          Query = "INSERT INTO OpenSignal_"+AccountNumber()+" (id, symbol, volume, type, opent, openp, account, sl, tp, profit) VALUES('" + OrderTicket() + "','" + OrderSymbol() + "', '" + OrderLots() + "','BUY','" + OrderOpenTime() + "','" + OrderOpenPrice() + "','" + AccountNumber() + "','" + OrderStopLoss() + "','" + OrderTakeProfit() + "','" + OrderProfit() + "') ON DUPLICATE KEY UPDATE sl='" + OrderStopLoss() + "', tp='" + OrderTakeProfit() + "', profit='" + OrderProfit() + "'";
          if (MySqlExecute(DB, Query))
              {
               Print ("Succeeded: ", Query);
              }
          else
              {
               Print ("Error: ", MySqlErrorDescription);
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
        
        int Pips = 0;
     // SELL ORDERS
         if(OrderType() == OP_SELL){   
          
          Print(OrderOpenPrice());
          Query = "INSERT INTO CloseSignal_"+AccountNumber()+" (id, closet, closep, profit, pips, account) VALUES('" + OrderTicket() + "','" + OrderOpenTime() + "','" + OrderOpenPrice() + "','" + OrderProfit() + "','" + Pips + "','" + AccountNumber() + "')";
          if (MySqlExecute(DB, Query))
              {
               Print ("Succeeded: ", Query);
              }
          else
              {
               Print ("Error: ", MySqlErrorDescription);
               Print ("Query: ", Query);
              }
         }
      // BUY ORDERS
         if(OrderType() == OP_BUY){           

          Print(OrderOpenPrice());
          Query = "INSERT INTO CloseSignal_"+AccountNumber()+" (id, closet, closep, profit, pips, account) VALUES('" + OrderTicket() + "','" + OrderOpenTime() + "','" + OrderOpenPrice() + "','" + OrderProfit() + "','" + Pips + "','" + AccountNumber() + "')";
          if (MySqlExecute(DB, Query))
              {
               Print ("Succeeded: ", Query);
              }
          else
              {
               Print ("Error: ", MySqlErrorDescription);
               Print ("Query: ", Query);
              }
         }  
         
    }
   MySqlDisconnect(DB);
   Print ("Mysql Disconnected. Done!");
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
 
