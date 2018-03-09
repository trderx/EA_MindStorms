extern string EquitySTOP__ = "------------------------Filter  Equity STOP --------------------";
extern bool InpUseEquityStop = false;       // Usar EquityStop?
extern double InpTotalEquityRisk = 20.0;    // Total % Risk to EquityStop
extern bool InpAlertPushEquityLoss = false; //Send Alert to Celular
extern bool InpCloseAllEquityLoss = false;  // Close all orders in InpTotalEquityRisk

//+------------------------------------------------------------------+
//|           StopOut                                                |
//+------------------------------------------------------------------+
bool FilterStopOut(double profit_all, int MagicNumber)
{

    // SE EquityStop  ENABLE
    if (InpUseEquityStop)
    {

        if (profit_all < 0.0 && MathAbs(profit_all) > InpTotalEquityRisk / 100.0 * AccountEquity())
        {
            if (InpCloseAllEquityLoss)
            {
                CloseThisSymbolAll(MagicNumber, 6);
                Print("Closed All to Stop Out");
            }
            if (InpAlertPushEquityLoss)
                SendNotification("EquityLoss Alert " + (string)profit_all);

            return true;
        }
    }

    return false;
}
