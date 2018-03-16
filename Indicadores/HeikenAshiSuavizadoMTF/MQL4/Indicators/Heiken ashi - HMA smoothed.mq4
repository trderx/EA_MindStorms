//+----------------------------------------------------------------------------------+
//|                                                   Heiken ashi - HMA smoothed.mq4 |
//|                                                                           mladen |
//+----------------------------------------------------------------------------------+
#property copyright "mladen"
#property link      "mladenfx@gmail.com"

#property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1  LimeGreen
#property indicator_color2  DarkOrange
#property indicator_color3  LimeGreen
#property indicator_color4  DarkOrange
#property indicator_width3  2
#property indicator_width4  2

//
//
//
//
//

extern int HmaPeriod = 30;

//
//
//
//
//

double bufferHc[];
double bufferHo[];
double bufferHh[];
double bufferHl[];
double working[][8];
int    HalfPeriod;
int    HullPeriod;

//+----------------------------------------------------------------------------------+
//|                                                                                  |
//+----------------------------------------------------------------------------------+
//
//
//
//
//

int init()
{
   SetIndexBuffer(0,bufferHh); SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexBuffer(1,bufferHl); SetIndexStyle(1,DRAW_HISTOGRAM);
   SetIndexBuffer(2,bufferHc); SetIndexStyle(2,DRAW_HISTOGRAM);
   SetIndexBuffer(3,bufferHo); SetIndexStyle(3,DRAW_HISTOGRAM);
   
   //
   //
   //
   //
   //
      
   HmaPeriod  = MathMax(2,HmaPeriod);
   HalfPeriod = MathFloor(HmaPeriod/2.0);
   HullPeriod = MathFloor(MathSqrt(HmaPeriod));
   return(0);
}
int deinit()
{
   return(0);
}

//+----------------------------------------------------------------------------------+
//|                                                                                  |
//+----------------------------------------------------------------------------------+
//
//
//
//
//

#define _hrOpen  0
#define _haOpen  1
#define _hrClose 2
#define _haClose 3
#define _hrHigh  4
#define _haHigh  5
#define _hrLow   6
#define _haLow   7

//
//
//
//
//

int start()
{
   int counted_bars=IndicatorCounted();
   int i,r,limit;

   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
         limit = Bars-counted_bars;
         if (ArrayRange(working,0) != Bars) ArrayResize(working,Bars);

   //
   //
   //
   //
   //
        
   for(i=limit, r=Bars-i-1; i >= 0; i--,r++)
   {
      working[r][_hrOpen]  = iMA(NULL,0,HalfPeriod,0,MODE_LWMA,PRICE_OPEN,i)*2-iMA(NULL,0,HmaPeriod,0,MODE_LWMA,PRICE_OPEN,i);
      working[r][_haOpen]  = iLwma(_hrOpen,HullPeriod,r);
      working[r][_hrClose] = iMA(NULL,0,HalfPeriod,0,MODE_LWMA,PRICE_CLOSE,i)*2-iMA(NULL,0,HmaPeriod,0,MODE_LWMA,PRICE_CLOSE,i);
      working[r][_haClose] = iLwma(_hrClose,HullPeriod,r);
      working[r][_hrHigh]  = iMA(NULL,0,HalfPeriod,0,MODE_LWMA,PRICE_HIGH,i)*2-iMA(NULL,0,HmaPeriod,0,MODE_LWMA,PRICE_HIGH,i);
      working[r][_haHigh]  = iLwma(_hrHigh,HullPeriod,r);
      working[r][_hrLow]   = iMA(NULL,0,HalfPeriod,0,MODE_LWMA,PRICE_LOW,i)*2-iMA(NULL,0,HmaPeriod,0,MODE_LWMA,PRICE_LOW,i);
      working[r][_haLow]   = iLwma(_hrLow,HullPeriod,r);
      
      //
      //
      //
      //
      //
      
      double haOpen  = (bufferHo[i+1]+bufferHc[i+1])/2.0; 
      double haClose = (working[r][_haOpen]+working[r][_haClose]+working[r][_haHigh]+working[r][_haLow])/4.0;
      double haHigh  = MathMax(working[r][_haHigh],MathMax(haOpen,haClose));
      double haLow   = MathMin(working[r][_haLow] ,MathMin(haOpen,haClose));

      if (haOpen<haClose) 
         {
            bufferHl[i]=haLow;
            bufferHh[i]=haHigh;
         } 
      else
         {
            bufferHh[i]=haLow;
            bufferHl[i]=haHigh;
         }
      bufferHo[i]=haOpen;
      bufferHc[i]=haClose;
   }
   
   //
   //
   //
   //
   //
   
   return(0);
}

//+----------------------------------------------------------------------------------+
//|                                                                                  |
//+----------------------------------------------------------------------------------+
//
//
//
//
//

double iLwma(int forBuffer, int period, int shift)
{
   double weight=0;
   double sum   =0;
   int    i,k;
   
   if (shift>=period)
   {
      for (i=0,k=period; i<period; i++,k--)
      {
            weight += k;
            sum    += working[shift-i][forBuffer]*k;
        }
        if (weight !=0)
                return(sum/weight);
        else    return(0.0);
    }
    else return(working[shift][forBuffer]);
}