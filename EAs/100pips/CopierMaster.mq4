//+------------------------------------------------------------------+
//|                                         BreakermindMT4Master.mq4 |
//|                                  Copyright 2011, Breakermind.com |
//|                                          https://breakermind.com |
//+------------------------------------------------------------------+
#property copyright   "© 2011, Breakermind.com"
#property link        "https://breakermind.com"

input bool Start = true;
input int Timer = 5000;
input int Second = 6000000;
input bool   ssl = false;
input string url="localhost";

int Refresh = Timer;  
string apiurl;

void OnInit()
{
 if(Refresh < 3000){ Refresh = 3000; }
 EventSetMillisecondTimer(Refresh);       
 
   // api url http or https(ssl)
   if(ssl){
      apiurl = "https://" + url + "/fx/index.php"; 
   }
   if(!ssl){
      apiurl = "http://" + url + "/fx/index.php"; 
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
     if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){     
         if(OrderType() == OP_SELL && OrderOpenTime() > (TimeCurrent()- Second) ){ 
            Print("SELL");  
            positions = positions + OrderOpenTime() + ";" + OrderTicket() + ";" + OrderOpenPrice() + ";" + OrderSymbol() + ";" + OrderLots() + ";" + "0" + ";" + OrderStopLoss() + ";" + OrderTakeProfit() + ";" + OrderProfit() + ";" + AccountNumber() +"|";
         }
         if(OrderType() == OP_BUY && OrderOpenTime() > (TimeCurrent()- Second) ){  
            Print("BUY");  
            positions = positions + OrderOpenTime() + ";" + OrderTicket() + ";" + OrderOpenPrice() + ";" + OrderSymbol() + ";" + OrderLots() + ";" + "1" + ";" + OrderStopLoss() + ";" + OrderTakeProfit() + ";" + OrderProfit() + ";" + AccountNumber() +"|";
         }
      }else{
      Print("Orders error ",GetLastError());
      break;}
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
      if(OrderType()==OP_SELL || OrderType()==OP_BUY)
        {         
         historyall = historyall + OrderOpenTime() + ";" + OrderTicket() + ";" + OrderOpenPrice() + ";" + OrderSymbol() + ";" + OrderLots() + ";" + OrderType() + ";" + OrderStopLoss() + ";" + OrderTakeProfit() + ";" + OrderCloseTime() + ";" + OrderClosePrice() + ";" + OrderProfit() + ";" + AccountNumber() +"|";
        }
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
         Print("Server response:" + CharArrayToString(result,0));
      }      
}//end
//+------------------------------------------------------------------+

/*

<?php
// save to file all data
if($_SERVER['REMOTE_ADDR'] != "::1")echo "Error001";
echo file_put_contents('pos/'.date('Y-m-d-H-m',time()).'.txt', serialize($_POST));
?>

*/
