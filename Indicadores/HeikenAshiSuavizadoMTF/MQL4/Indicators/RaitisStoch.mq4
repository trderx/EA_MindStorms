//+------------------------------------------------------------------+
//|                                                                  |
//|                                                  RaitisStoch.mq4 |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright "Raitis"
#property link      "esterkin2313@inbox.lv"

#property indicator_separate_window
#property indicator_minimum -100.0
#property indicator_maximum 100.0
#property indicator_levelcolor DarkSlateGray
#property indicator_buffers 4
#property indicator_color1 LimeGreen
#property indicator_color2 DarkOrange
#property indicator_color3 LimeGreen
#property indicator_color4 DarkOrange
#property indicator_level2 50.0
#property indicator_level3 -50.0

extern int Length = 13;
extern int Smooth1 = 25;
extern int Smooth2 = 2;
extern int Signal = 5;
extern int Price = 0;
double g_ibuf_96[];
double g_ibuf_100[];
double g_ibuf_104[];
double g_ibuf_108[];
double g_ibuf_112[];
double gda_116[][6];

int init() {
   string ls_0;
   IndicatorBuffers(5);
   SetIndexBuffer(0, g_ibuf_96);
   SetIndexLabel(0, "Stochastic momentum");
   SetIndexBuffer(1, g_ibuf_100);
   SetIndexLabel(1, "Stochastic momentum signal");
   SetIndexBuffer(2, g_ibuf_104);
   SetIndexStyle(2, DRAW_ARROW);
   SetIndexArrow(2, 108);
   SetIndexBuffer(3, g_ibuf_108);
   SetIndexStyle(3, DRAW_ARROW);
   SetIndexArrow(3, 108);
   SetIndexBuffer(4, g_ibuf_112);
   switch (Price) {
   case 0:
      ls_0 = "Close";
      break;
   case 1:
      ls_0 = "Open";
      break;
   case 2:
      ls_0 = "High";
      break;
   case 3:
      ls_0 = "Low";
      break;
   case 4:
      ls_0 = "Median";
      break;
   case 5:
      ls_0 = "Typical";
      break;
   case 6:
      ls_0 = "Weighted";
   }
   Length = MathMax(Length, 1);
   Smooth1 = MathMax(Smooth1, 1);
   Smooth2 = MathMax(Smooth2, 1);
   IndicatorShortName(" RaitisStoch (" + Length + "," + Smooth1 + "," + Smooth2 + "," + ls_0 + ")");
   return (0);
}

int deinit() {
   return (0);
}

int start() {
   double ld_40;
   double ld_48;
   double l_ima_56;
   int li_0 = IndicatorCounted();
   if (li_0 < 0) return (-1);
   if (li_0 > 0) li_0--;
   int li_12 = MathMin(Bars - li_0, Bars - 1);
   if (ArrayRange(gda_116, 0) != Bars) ArrayResize(gda_116, Bars);
   double ld_16 = 2.0 / (Smooth1 + 1.0);
   double ld_24 = 2.0 / (Smooth2 + 1.0);
   double ld_32 = 2.0 / (Signal + 1.0);
   int li_4 = li_12;
   for (int li_8 = Bars - li_4 - 1; li_4 >= 0; li_8++) {
      ld_40 = High[iHighest(NULL, 0, MODE_HIGH, Length, li_4)];
      ld_48 = Low[iLowest(NULL, 0, MODE_LOW, Length, li_4)];
      l_ima_56 = iMA(NULL, 0, 1, 0, MODE_SMA, Price, li_4);
      gda_116[li_8][0] = l_ima_56 - (ld_40 + ld_48) / 2.0;
      gda_116[li_8][3] = ld_40 - ld_48;
      if (li_4 >= Bars - 3) {
         gda_116[li_8][1] = gda_116[li_8][0];
         gda_116[li_8][2] = gda_116[li_8][0];
         gda_116[li_8][4] = gda_116[li_8][3];
         gda_116[li_8][5] = gda_116[li_8][3];
      } else {
         gda_116[li_8][1] = gda_116[li_8 - 1][1] + ld_16 * (gda_116[li_8][0] - gda_116[li_8 - 1][1]);
         gda_116[li_8][2] = gda_116[li_8 - 1][2] + ld_24 * (gda_116[li_8][1] - gda_116[li_8 - 1][2]);
         gda_116[li_8][4] = gda_116[li_8 - 1][4] + ld_16 * (gda_116[li_8][3] - gda_116[li_8 - 1][4]);
         gda_116[li_8][5] = gda_116[li_8 - 1][5] + ld_24 * (gda_116[li_8][4] - gda_116[li_8 - 1][5]);
         g_ibuf_96[li_4] = 100.0 * gda_116[li_8][2] / (gda_116[li_8][5] / 2.0);
         if (Signal > 1) {
            g_ibuf_104[li_4] = EMPTY_VALUE;
            g_ibuf_108[li_4] = EMPTY_VALUE;
            g_ibuf_100[li_4] = g_ibuf_100[li_4 + 1] + ld_32 * (g_ibuf_96[li_4] - (g_ibuf_100[li_4 + 1]));
            g_ibuf_112[li_4] = g_ibuf_112[li_4 + 1];
            if (g_ibuf_96[li_4] > g_ibuf_100[li_4]) g_ibuf_112[li_4] = 1;
            if (g_ibuf_96[li_4] < g_ibuf_100[li_4]) g_ibuf_112[li_4] = -1;
            if (g_ibuf_112[li_4] != g_ibuf_112[li_4 + 1]) {
               if (g_ibuf_112[li_4] == 1.0) g_ibuf_104[li_4] = g_ibuf_100[li_4];
               if (g_ibuf_112[li_4] == -1.0) g_ibuf_108[li_4] = g_ibuf_100[li_4];
            }
         }
      }
      li_4--;
   }
   return (0);
}