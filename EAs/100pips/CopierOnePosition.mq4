//+------------------------------------------------------------------+
//|                              BreakermindMT4MasterOnePosition.mq4 |
//|                             Copyright 2000-2015, Breakermind.com |
//|                                          https://breakermind.com |
//+------------------------------------------------------------------+
#property copyright   "© 2000-2015, Breakermind.com"
#property link        "https://breakermind.com"

input bool Start = true;
input int Timer = 5000;
input bool   ssl = false;
input string url="localhost";

int Refresh = Timer;  
string apiurl;

void OnInit()
{
 if(Refresh < 5000){ Refresh = 5000; }
 EventSetMillisecondTimer(Refresh);       
 
   // api url http or https(ssl)
   if(ssl){
      apiurl = "https://" + url + "/api.php"; 
   }
   if(!ssl){
      apiurl = "http://" + url + "/api.php"; 
   }  
    
}//end

void OnTimer(void)
  {
   if(!Start){ Print("On EA first!"); return;  }   
   char post[];
   char result[];
   string headers;
   int res;   
   string send = "";
   string positions = "";   
   string historyall = "";
        
   int orders=OrdersTotal();
   for(int i=0;i<orders;i++)
     {
     if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
     Print("Orders error ",GetLastError());
     break;
     }
         if(OrderType() <= OP_SELL){   
            positions = OrderOpenTime() + ";" + OrderTicket() + ";" + OrderOpenPrice() + ";" + OrderSymbol() + ";" + OrderLots() + ";" + OrderType() + ";" + OrderStopLoss() + ";" + OrderTakeProfit() + ";" + OrderProfit() + ";" + AccountNumber() +"|";
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
      if(OrderType()<=OP_SELL)
        {
         historyall = historyall + OrderOpenTime() + ";" + OrderTicket() + ";" + OrderOpenPrice() + ";" + OrderSymbol() + ";" + OrderLots() + ";" + OrderType() + ";" + OrderStopLoss() + ";" + OrderTakeProfit() + ";" + OrderCloseTime() + ";" + OrderClosePrice() + ";" + OrderProfit() + ";" + AccountNumber() +"|";
        }// if end
    }

      send = 
      "&accountid=" +AccountNumber() + 
      "&time=" + TimeCurrent() + 
      "&positions=" + positions +
      "&historyall=" + historyall +
      "&balance=" + AccountBalance() +
      "&equity=" + AccountEquity()+"&end=0";

      Print("Master send: ",send);
      StringToCharArray(send,post);
      ResetLastError();
      res=WebRequest("POST",apiurl,NULL,NULL,50,post,ArraySize(post),result,headers);
      

      if(res==-1)
        {
         Print("Error code =",GetLastError());
         Print("Add address '"+apiurl+"' in Expert Advisors tab of the Options window","Error",MB_ICONINFORMATION);
        }
      else
        {
         Print("Server response:",CharArrayToString(result,0));
        }      
}//end
//+------------------------------------------------------------------+
