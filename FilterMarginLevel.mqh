extern string FilterMargiLevel__ = "------------------------Filter  Margin Level --------------------";
extern bool InpUseFilterMargiLevel = false; // Usar Filter  Margin Level?
extern double InpMinMarginLevel = 100;      // Lowest allowed Margin level for new positions to be opened.
extern bool InpAlertMarginLevel = false;

double MarginFree; // Free margin in percentage
double marginlevel;
double am = 0.000000001; // Set variable to a very small number
//+------------------------------------------------------------------+
//|           StopOut                                                |
//+------------------------------------------------------------------+
bool FilterMargiLevel()
{

    // SE EquityStop  ENABLE
    if (InpUseFilterMargiLevel)
    {

        // Get the Free Margin
        MarginFree = AccountFreeMargin();
        // Calculate Margin level
        if (AccountMargin() != 0)
            am = AccountMargin();
        marginlevel = AccountEquity() / am * 100;

        // Free Margin is less than the value of MinMarginLevel, so no trading is allowed
        if (marginlevel < InpMinMarginLevel)
        {
            //Comment("Warning! Free Margin " + DoubleToStr(marginlevel, 2) + " is lower than MinMarginLevel!");
            if (InpAlertMarginLevel)
                Alert("Warning! Free Margin " + DoubleToStr(marginlevel, 2) + " is lower than MinMarginLevel!");
            
            
            return true;
        }
    }

    return false;
}
