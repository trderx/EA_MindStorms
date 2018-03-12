
extern string TimeFilter__ = "-------------------------Filter DateTime--------------------------";
extern bool InpUtilizeTimeFilterr = true;
extern bool InpTrade_in_Monday = true;
extern bool InpTrade_in_Tuesday = true;
extern bool InpTrade_in_Wednesday = true;
extern bool InpTrade_in_Thursday = true;
extern bool InpTrade_in_Friday = true;

extern string InpStartHour = "00:00";
extern string InpEndHour = "23:59";

int vg_TimeDayOfWeek;

//+------------------------------------------------------------------+
//|           TimeFilter                                     |
//+------------------------------------------------------------------+
bool TimeFilter()
{
    bool _res = false;
    vg_TimeDayOfWeek = TimeDayOfWeek(Time[0]);
    datetime _time_curent = TimeCurrent();
    datetime _time_start = StrToTime(DoubleToStr(Year(), 0) + "." + DoubleToStr(Month(), 0) + "." + DoubleToStr(Day(), 0) + " " + InpStartHour);
    datetime _time_stop = StrToTime(DoubleToStr(Year(), 0) + "." + DoubleToStr(Month(), 0) + "." + DoubleToStr(Day(), 0) + " " + InpEndHour);

    if (InpUtilizeTimeFilterr)
    {

        if (((InpTrade_in_Monday == true) && (vg_TimeDayOfWeek == 1)) ||
            ((InpTrade_in_Tuesday == true) && (vg_TimeDayOfWeek == 2)) ||
            ((InpTrade_in_Wednesday == true) && (vg_TimeDayOfWeek == 3)) ||
            ((InpTrade_in_Thursday == true) && (vg_TimeDayOfWeek == 4)) ||
            ((InpTrade_in_Friday == true) && (vg_TimeDayOfWeek == 5)))
        {

            if (_time_start > _time_stop)
            {
                if (_time_curent >= _time_start || _time_curent <= _time_stop)
                    _res = true;
            }
            else if (_time_curent >= _time_start && _time_curent <= _time_stop)
                _res = true;
        }

        return (!_res);
    }

    return (false);
}
