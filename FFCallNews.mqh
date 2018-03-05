
bool vg_news_time = false;

extern string FFCall__=                                     "----------------------------Filter News FFCall-------------------";
extern bool                 InpUseFFCall= FALSE;                                 // Use Filter News FFCall
extern int                  InpMinsBeforeNews = 60;                             // mins before an event to stay out of trading
extern int                  InpMinsAfterNews  = 20;                             // mins after  an event to stay out of trading
extern bool                 InpIncludeHigh= true;                               // Include New High Impact



//+------------------------------------------------------------------+
//|            Function to check if it is news time                                     |
//+------------------------------------------------------------------+
void NewsHandling( )
{
   static int PrevMinute= -1;

    if (Minute() != PrevMinute) {
        PrevMinute = Minute();

        // Use this call to get ONLY impact of previous event
        int impactOfPrevEvent=
            (int)iCustom(NULL, 0, "FFCal", true, true, false, true, true, 2, 0);

        // Use this call to get ONLY impact of nexy event
        int impactOfNextEvent=
            (int)iCustom(NULL, 0, "FFCal", true, true, false, true, true, 2, 1);

        int minutesSincePrevEvent=
            (int)iCustom(NULL, 0, "FFCal", true, true, false, true, false, 1, 0);

        int minutesUntilNextEvent=
            (int)iCustom(NULL, 0, "FFCal", true, true, false, true, false, 1, 1);

        vg_news_time = false;
        if ((minutesUntilNextEvent <= InpMinsBeforeNews) ||
            (minutesSincePrevEvent <= InpMinsAfterNews)) {
            vg_news_time = true;
        }
    }
}