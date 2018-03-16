//+------------------------------------------------------------------+
//|                                         BreakermindMT4Copier.mq4 |
//|                             Copyright 2011-2014, Breakermind.com |
//|                                          https://breakermind.com |
//+------------------------------------------------------------------+
#property copyright   "© 2011-2014, Breakermind.com"
#property link        "https://breakermind.com"

input bool   Start = true;
input int    MoneyUSD = 100;
input string ProviderId = "83320406";
input string Username = "woow";
input string Password = "pass";



int Timer = 1000;
bool   ssl = false;
//input string url="fx-breakermind.rhcloud.com";
string url="localhost";

int Refresh = Timer;  
string apiurl;

void OnInit()
{
 if(Refresh < 1000){ Refresh = 1000; }
 EventSetMillisecondTimer(Refresh);       
 
   // api url http or https(ssl)
   if(ssl){
      apiurl = "https://" + url + "/copy.php"; 
   }
   if(!ssl){
      apiurl = "http://" + url + "/copy.php"; 
   }  
    
}//end

void OnTimer(void)
  {
   if(!Start){ Print("On EA first! / Minimal deposit 100USD , 200USD ..."); return;  }   
   char post[];
   char result[];
   string headers;
   int res;   
   string send = "";
   string history[];
   bool setPosition = true;
        
   send =       
   "&user=" + Username + 
   "&pass=" + Password +
   "&id=" + ProviderId +
   "&money=" + MoneyUSD +
   "&end=0";

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
      //Print("Server response:",CharArrayToString(result,0));
      //Alert("Server response:",CharArrayToString(result,0));
      // set position if not exist in history
      
      string txt = CharArrayToString(result,0); // A string to split into substrings
      string sep = ";";                // A separator as a character
      ushort c_sep;                  // The code of the separator character
      string pos[];               // An array to get strings
      //--- Get the separator code
      c_sep=StringGetCharacter(sep,0);
      //--- Split the string to substrings
      int k=StringSplit(txt,c_sep,pos);
      if(k>0)
      {
         Print(pos[0]);
      }
         
      }      

   int orders=OrdersTotal();

   int ii, hTotal;
   hTotal= OrdersHistoryTotal();
   //Alert(hTotal);
   for(ii=0;ii<hTotal;ii++)
     {
      if(OrderSelect(ii,SELECT_BY_POS,MODE_HISTORY)==false)
        {
         Print("History Error ",GetLastError());
         break;
        }
      if(OrderType()<=OP_SELL){
         if(OrderComment() == pos[0]){
         setPosition == false;
         }
        }// if end
    }
   
    if(orders < 2 && setPosition == true)
    {
      Alert("Nie ma pozycji w historii !!!! Set position kuku ");   
    }
           

}//end
//+------------------------------------------------------------------+
