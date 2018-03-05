
extern string TimeFilter__=                                 "-------------------------Filter DateTime--------------------------";
extern bool InpUtilizeTimeFilter= true;
extern bool InpTrade_in_Monday  = true;
extern bool InpTrade_in_Tuesday = true;
extern bool InpTrade_in_Wednesday= true;
extern bool InpTrade_in_Thursday= true;
extern bool InpTrade_in_Friday  = true;

extern string InpStartHour = "00:00";
extern string InpEndHour   = "23:59";

//+------------------------------------------------------------------+
//|           TimeFilter                                     |
//+------------------------------------------------------------------+
bool TimeFilter()
{

    bool _res= false;
    datetime _time_curent= TimeCurrent();
    datetime _time_start = StrToTime(DoubleToStr(Year(), 0) + "." + DoubleToStr(Month(), 0) + "." + DoubleToStr(Day(), 0) + " " + InpStartHour);
    datetime _time_stop= StrToTime(DoubleToStr(Year(), 0) + "." + DoubleToStr(Month(), 0) + "." + DoubleToStr(Day(), 0) + " " + InpEndHour);
    if (((InpTrade_in_Monday == true) && (TimeDayOfWeek(Time[0]) == 1)) ||
        ((InpTrade_in_Tuesday == true) && (TimeDayOfWeek(Time[0]) == 2)) ||
        ((InpTrade_in_Wednesday == true) && (TimeDayOfWeek(Time[0]) == 3)) ||
        ((InpTrade_in_Thursday == true) && (TimeDayOfWeek(Time[0]) == 4)) ||
        ((InpTrade_in_Friday == true) && (TimeDayOfWeek(Time[0]) == 5)))

        if (_time_start > _time_stop) {
            if (_time_curent >= _time_start || _time_curent <= _time_stop) _res = true;
        }
        else
            if (_time_curent >= _time_start && _time_curent <= _time_stop) _res = true;

    return (_res);

}
