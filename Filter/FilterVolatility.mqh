extern string FilterVolatility__ = "------------------------ Filter Volatility --------------------";
extern bool InpUseFilterVolatility = false;                 // Use Filter Volatility?
extern bool InpUseFilterVolatilityInvert = false;              // If True Invert Filter
input ENUM_TIMEFRAMES InpFilterVolatilityFrame = PERIOD_CURRENT; //  Filter Volatility TimeFrame
extern bool InpUseDynamicInpVolatilityLimit = TRUE;               // Calculate Volatility Limit based on INT (spread * InpVolatilityMultiplier)
extern double InpVolatilityMultiplier = 125;                   // Dynamic value, only used if InpUseDynamicVolatilityLimit is set to TRUE
extern double InpVolatilityLimit = 180;                        // Fix value, only used if InpUseDynamic VolatilityLimit is set to FALSE

double volatility;
double volatilitypercentage;
double avgspread;
double realavgspread;
double sumofspreads;
int UpTo30Counter = 0;
double Array_spread[30]; // Store spreads for the last 30 tics
double VolatilityLimit;

string DebugFilterVolatility()
{

    string vDebug = "";
    vDebug = vDebug + "=========== FilterVolatility ============\n";
    vDebug = vDebug + "[volatility] = [" + volatility + "]\n";
    vDebug = vDebug + "[volatilitypercentage] = [" + volatilitypercentage + "]\n";
    vDebug = vDebug + "[avgspread] = [" + avgspread + "]\n";
    vDebug = vDebug + "[realavgspread] = [" + realavgspread + "]\n";
    vDebug = vDebug + "[sumofspreads] = [" + sumofspreads + "]\n";
     vDebug = vDebug + "[VolatilityLimit] = [" + VolatilityLimit + "]\n";
    return vDebug;
}

//-----------------------------------------------
bool FilterVolatility()
{
    bool vRet = false;

    double ihigh;
    double ilow;
    int loopcount2, loopcount1;
    VolatilityLimit = InpVolatilityLimit * Point;
    // SE EquityStop  ENABLE
    if (InpUseFilterVolatility)
    {

        if (InpUseDynamicInpVolatilityLimit)
        {
            // Calculate average true spread, which is the average of the spread for the last 30 tics
            ArrayCopy(Array_spread, Array_spread, 0, 1, 29);
            Array_spread[29] = MarketInfo(Symbol(), MODE_SPREAD) * Point;
            if (UpTo30Counter < 30)
                UpTo30Counter++;
            sumofspreads = 0;
            loopcount2 = 29;
            for (loopcount1 = 0; loopcount1 < UpTo30Counter; loopcount1++)
            {
                sumofspreads += Array_spread[loopcount2];
                loopcount2--;
            }
            // Calculate an average of spreads based on the spread from the last 30 tics
            avgspread = sumofspreads / UpTo30Counter;
            realavgspread = avgspread;
            //realavgspread = avgspread + Commission;
            VolatilityLimit = realavgspread * InpVolatilityMultiplier;
        }

        ihigh = iHigh(Symbol(), InpFilterVolatilityFrame, 0);
        ilow = iLow(Symbol(), InpFilterVolatilityFrame, 0);
        volatility = ihigh - ilow;
        volatilitypercentage = volatility / InpVolatilityLimit;

        if (volatility > VolatilityLimit)
            vRet =  true;

        if(InpUseFilterVolatilityInvert) vRet = !vRet;

        return vRet;
    }

    return vRet;
}
