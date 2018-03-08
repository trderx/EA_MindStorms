extern string _BB1_ =                                     "-----------------------------Bollinger Bands--------------------";
input bool EnableSinalBB    = false;                                         //Enable Sinal  Bollinger Bands
input ENUM_TIMEFRAMES        InpBBFrame= PERIOD_M5;                                   // Bollinger Bands TimeFrame
input int          InpperiodBB = 10;                                                    //averaging period
input int          InpdeviationBB = 2;                                                  // standard deviations
input int          Inpbands_shiftBB = 0;                                                // bands shift
extern int         InppriceBBUP  = PRICE_CLOSE;                                         //price BB UP
extern int         InppriceBBDN  = PRICE_CLOSE;                                         //price BB DOWN
input int          InpCheckBarsBB = 10;                                                 //Check Bars BB

//-----------------------------------------------
int DivSinalBB()
{
    if(!EnableSinalBB) return (0);
    else return (1);
}


int GetSinalBB()
{
   if(!EnableSinalBB) return (0);


 double  bh, bl; int dn=0,up=0;
 int j;
 int ii=1;
 for(j = ii; j<=ii+InpCheckBarsBB; j++)
 {
   bh = iBands(NULL,InpBBFrame,InpperiodBB,InpdeviationBB,Inpbands_shiftBB,InppriceBBUP,MODE_UPPER,j);
   bl = iBands(NULL,InpBBFrame,InpperiodBB,InpdeviationBB,Inpbands_shiftBB,InppriceBBDN,MODE_LOWER,j);
   if(Close[j]>=bh) {dn++;break;} 
   if(Close[j]<=bl) {up++;break;} 
  }
 if(dn>0)return(-1);
 if(up>0)return( 1);
 return(0);
}