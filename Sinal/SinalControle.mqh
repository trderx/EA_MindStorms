
extern string _Controle_ = "-----------------------------Sinal Manual--------------------";
input bool EnableSinalControle = false; //Enable Sinal Manual

int MagicNumberControle = 0;
int SinalControle = 0;
bool InitControle = false;

//-----------------------------------------------
int DivSinalControle()
{
    if (!EnableSinalControle)
        return (0);
    else
        return (1);
}

void InitControle(int MagicNumber)
{

    if (EnableSinalControle)
    {
        MagicNumberControle = MagicNumber;

        DrawRects(250, 15, Gray, 80, 50, "SELL");
        DrawRects(420, 15, Gray, 80, 50, "BUY");
        DrawRects(600, 15, Gray, 80, 50, "CLOSE ALL");
    }
}

//Deve ser chamado no start()
void ControleHandling(int MagicNumber)
{
    
    if (EnableSinalControle)
    {
        if(!InitControle){
                    InitControle( MagicNumber);
        } 

        int countTrades = CountTradesControle(MagicNumberControle);

        SinalControle = 0;

        if (countTrades > 0)
        {

            ObjectSetInteger(0, "_lSELL", OBJPROP_BGCOLOR, Gray);
            ObjectSetInteger(0, "_lBUY", OBJPROP_BGCOLOR, Gray);
            ObjectSetInteger(0, "_lCLOSE ALL", OBJPROP_BGCOLOR, Green);
        }else{
            
            ObjectSetInteger(0, "_lSELL", OBJPROP_BGCOLOR, Red);
            ObjectSetInteger(0, "_lBUY", OBJPROP_BGCOLOR, Blue);
            ObjectSetInteger(0, "_lCLOSE ALL", OBJPROP_BGCOLOR, Gray);

        }

        if (ObjectGetInteger(0, "_lSELL", OBJPROP_STATE) && countTrades == 0)
        {
            
            ObjectSetInteger(0, "_lSELL", OBJPROP_BGCOLOR, Gray);
             ObjectSetInteger(0, "_lSELL", OBJPROP_STATE, false);
            ObjectSetInteger(0, "_lBUY", OBJPROP_BGCOLOR, Blue);
            SinalControle = -1;
            
            ObjectSetInteger(0, "_lCLOSE ALL", OBJPROP_BGCOLOR, Green);
           
        }

        if (ObjectGetInteger(0, "_lBUY", OBJPROP_STATE) && countTrades == 0)
        {
            ObjectSetInteger(0, "_lBUY", OBJPROP_BGCOLOR, Gray);
            ObjectSetInteger(0, "_lBUY", OBJPROP_STATE, false);
            ObjectSetInteger(0, "_lSELL", OBJPROP_BGCOLOR, Red);
            SinalControle = 1;
            ObjectSetInteger(0, "_lCLOSE ALL", OBJPROP_BGCOLOR, Green);
        }

        if (ObjectGetInteger(0, "_lCLOSE ALL", OBJPROP_STATE) && countTrades > 0)
        {
            CloseThisSymbolAllControle(MagicNumberControle);
            ObjectSetInteger(0, "_lCLOSE ALL", OBJPROP_BGCOLOR, Gray);
            ObjectSetInteger(0, "_lCLOSE ALL", OBJPROP_STATE, false);
              SinalControle = 0;
        }else{
            ObjectSetInteger(0, "_lCLOSE ALL", OBJPROP_STATE, false);
        }
    }
}

int GetSinalControle()
{
    return (SinalControle);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseThisSymbolAllControle(int vInpMagic)
{
    bool foo = false;
    for (int l_pos_0 = OrdersTotal() - 1; l_pos_0 >= 0; l_pos_0--)
    {
        if (!OrderSelect(l_pos_0, SELECT_BY_POS, MODE_TRADES))
        {
            continue;
        }
        if (OrderSymbol() == Symbol())
        {
            if (OrderSymbol() == Symbol() && (OrderMagicNumber() == vInpMagic))
            {
                if (OrderType() == OP_BUY)
                    foo = OrderClose(OrderTicket(), OrderLots(), Bid, 6, Blue);

                if (OrderType() == OP_SELL)
                    foo = OrderClose(OrderTicket(), OrderLots(), Ask, 6, Red);
            }
            Sleep(1000);
        }
    }
}

int CountTradesControle(int vInpMagic)
{
    int l_count_0 = 0;
    for (int l_pos_4 = OrdersTotal() - 1; l_pos_4 >= 0; l_pos_4--)
    {
        if (!OrderSelect(l_pos_4, SELECT_BY_POS, MODE_TRADES))
        {
            continue;
        }
        if (OrderSymbol() != Symbol() || (OrderMagicNumber() != vInpMagic))
            continue;
        if (OrderSymbol() == Symbol() && (OrderMagicNumber() == vInpMagic))
            if (OrderType() == OP_SELL || OrderType() == OP_BUY)
                l_count_0++;
    }
    return (l_count_0);
}
