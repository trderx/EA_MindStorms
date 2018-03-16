// MoGri_Channel.mq4

// 10.08.2013 8:30

#property copyright ""



extern int		Отступ_первого_ордера = 5;	// Расстояние от цены до пары начальных ордеров. В пипсах
extern int		Шаг_сетки = 5;							// Расстояние между ордерами одного направления. В пипсах
extern int		Ордеров_одной_стороны = 3;	// Кол-во ордеров в одну сторону
extern int		Всего_сеток = 10;						// Макс кол-во одновременно раскрытых сетей
							
extern int		Дистанция_трала = 15;	// Сумма пипс прибыли/убытка всех ордеров сети
extern int		Шаг_трала = 5;				// Откат от максимальной суммы пипс прибыли, достаточный для сворачивания сети
							
extern double	Лот_фиксированный = 0.01;		// Если = 0, лот будет динамическим (Лот_в_процентах_депо)
extern double	Лот_в_процентах_депо = 0.01;		// Используется только если Лот_фиксированный = 0
							
extern bool		Рыночное_исполнение = false;	// ECN, NDD итд
extern bool		Журнал = true;								// Выводить сообщения в журнал?
extern bool		Инфо = true;									// Выводить информацию н чарт?
extern int		Проскальзывание = 2;					// Допуск




string
	gs_Symbol,
	gs_Prefix = "mgc_" // префикс имён
;
double
	gd_First_Level, gd_Level_Step,
	gd_Lot_Min, gd_Lot_Max, gd_Lot_Step, gd_Lot_Margin,
	gd_Stop_Level, gd_Freeze_Level,
	gd_Trail_Distance, gd_Trail_Step,
	gd_One_Pip_Rate
;
int
	gi_Trail_Distance, gi_Trail_Step,
	gi_Slippage, // проскальзывание
	gi_Orders_Limit = 0, // лимит открытых ордеров
	gi_Connect_Wait = 2, // пауза перед повтором отправки ордера. В секундах
	gi_Try_To_Trade = 4 // кол-во попыток отправки ордера
;
bool
	gb_Orders_Limit = false, // флаг лимита ордеров
	gb_Can_Trade = true // торговля разрешена
;


void init() {
	gs_Symbol = Symbol();
	if(MathAbs(Отступ_первого_ордера) <= MarketInfo(gs_Symbol, MODE_STOPLEVEL)) {
		Alert(gs_Symbol, ": Отступ_первого_ордера должен быть больше ", MarketInfo(gs_Symbol, MODE_STOPLEVEL), " пп!");
		return;
	}
	
	gd_One_Pip_Rate = MathPow(10, Digits);
	int i_Five_Digits_Ratio = 1;
	if(gd_One_Pip_Rate == 1000 || gd_One_Pip_Rate == 100000) i_Five_Digits_Ratio = 10;
	gd_First_Level = i_Five_Digits_Ratio * Отступ_первого_ордера / gd_One_Pip_Rate;
	gd_Level_Step = i_Five_Digits_Ratio * Шаг_сетки / gd_One_Pip_Rate;
	gi_Trail_Distance = i_Five_Digits_Ratio * Дистанция_трала;
	gi_Trail_Step = i_Five_Digits_Ratio * Шаг_трала;
//	gd_Trail_Distance = i_Five_Digits_Ratio * Дистанция_трала / gd_One_Pip_Rate;
//	gd_Trail_Step = i_Five_Digits_Ratio * Шаг_трала / gd_One_Pip_Rate;
	gi_Slippage = i_Five_Digits_Ratio * Проскальзывание;
	gd_Freeze_Level = MarketInfo(gs_Symbol, MODE_FREEZELEVEL) / gd_One_Pip_Rate;
	gd_Stop_Level = MarketInfo(gs_Symbol, MODE_STOPLEVEL) / gd_One_Pip_Rate;
	
	gd_Lot_Min = MarketInfo(gs_Symbol, MODE_MINLOT);
	gd_Lot_Max = MarketInfo(gs_Symbol, MODE_MAXLOT);
	gd_Lot_Step = MarketInfo(gs_Symbol, MODE_LOTSTEP);
	gd_Lot_Margin = MarketInfo(gs_Symbol, MODE_MARGINREQUIRED);
	
	gi_Connect_Wait *= 1000;
}


int deinit() {return (0);}


int start() {
	if (!IsTesting() && IsStopped()) return (0);
	int
		i_Signal = 0, // сигнал пересечения
		ia_Magics[], // массив мэджиков сетей
		i_Magics, // кол-во раскрытых сетей
		i_Magic, // мэджик конкретной сети
		i_Level, // узел сети
		i_Orders = OrdersTotal(), // общее кол-во рыночных и отложенных ордеров
		i_Value, // вспомогательная переменная
		i_Order // тикет
	;
	double
		d_Sell_Max, d_Buy_Min,
		d_Sell_TP, d_Buy_TP,
		d_SL, d_TP, d_Level,
		d_Channel_Mid = 0, // цена середины канала
		d_Lot, // размер лота
		da_Orders_Data[50] // справочник по существующим ордерам
	;
	string
		s_Value // вспомогательная переменная
	;
	static int
		sia_Grid_Trail[20][5], // массив макс профита каждой сети
								// [][0] мэджик
								// [][1] профит в пп открытых ордеров
								// [][2] фаза алгоритма для этой сети
								// [][3] профит в пп закрытых ордеров
								// [][4] кол-во закрытых ордеров
		si_Last_Signal_Time = 0
	;
	bool
		b_OK
	;
	
	i_Magics = Get_Magics_List(ia_Magics, gs_Symbol); // получение списка мэджиков сетей
	
	// Развёртывание новой сети:
	if(i_Magics < Всего_сеток && si_Last_Signal_Time < Time[0]) i_Signal = Get_Signal(d_Channel_Mid); // получение сигнала
	if(i_Signal != 0) {
		s_Value = " пп над линией"; if(i_Signal < 0) s_Value = " пп под линией";
		s_Value = DoubleToStr(MathAbs((d_Channel_Mid - Bid) * gd_One_Pip_Rate), 0) + s_Value;
		i_Magic = Get_Magic(); // вычисление мэджика для этой сети
		if(Журнал) Print("Развёртывание сети " + i_Magic + " в " + s_Value);
		if(gi_Orders_Limit > 0 && gi_Orders_Limit - 2 * Ордеров_одной_стороны < i_Orders) {
			// развернуть новую сеть нельзя из-за лимита ордеров
			if(Журнал) Print("Развёртывание невозможно из-за лимита. Есть ", i_Orders, ", нужно ", (2 * Ордеров_одной_стороны), ", лимит ", gi_Orders_Limit);
		} else {
			d_Lot = Get_Lot(0, 0, Лот_в_процентах_депо, Лот_фиксированный); // расчёт лота
			if(d_Lot > 0.0) { // средств достаточно
				i_Level = 0;
				// нужна сеть SellLimit + BuyLimit
				while(i_Level < Ордеров_одной_стороны) {
					i_Order = Send_Order(gs_Symbol,
						i_Magic,
						Рыночное_исполнение, gi_Try_To_Trade, gi_Connect_Wait,
						OP_SELLLIMIT,
						d_Lot,
						Bid + gd_First_Level + i_Level * gd_Level_Step,
						gi_Slippage,
						DoubleToStr(Bid, Digits),
						0,
//						Bid + gd_First_Level + (i_Level - 1) * gd_Level_Step
						Bid
					);
					if(i_Order > 0) {
						gb_Orders_Limit = false; // снять флаг лимита
					} else if(i_Order == -148) {
						if(Журнал) Print("Развёртывание прервано - достигнут предел кол-ва ордеров");
						gi_Orders_Limit = i_Orders + 2 * i_Level + 1; // цифра лимита
						gb_Orders_Limit = true; // флаг лимита
						break; // прервать развёртывание
					}
					i_Order = Send_Order(gs_Symbol,
						i_Magic,
						Рыночное_исполнение, gi_Try_To_Trade, gi_Connect_Wait,
						OP_BUYLIMIT,
						d_Lot,
						Bid - gd_First_Level - i_Level * gd_Level_Step,
						gi_Slippage,
						DoubleToStr(Bid, Digits),
						0,
//						Bid - gd_First_Level - (i_Level - 1) * gd_Level_Step
						Bid
					);
					if(i_Order > 0) {
						gb_Orders_Limit = false; // снять флаг лимита
					} else if(i_Order == -148) {
						if(Журнал) Print("Развёртывание прервано - достигнут предел кол-ва ордеров");
						gi_Orders_Limit = i_Orders + 2 * i_Level + 2; // цифра лимита
						gb_Orders_Limit = true; // флаг лимита
						break; // прервать развёртывание
					}
					i_Level++;
				}
				si_Last_Signal_Time = Time[0]; // запомнить время бара последнего сигнала
			} else if(Журнал) Print("Отмена развёртывания - нет денег для открытия ордера заданным лотом");
		}
	}
	
	// Сопровождение сетей:
	// Актуализация памяти трала:
	if(i_Magics > 0) {
		int i_Tmp_Array[20][3];
		i_Magic = i_Magics;
		while(i_Magic > 0) {
			i_Magic--;
			
			i_Tmp_Array[i_Magic][0] = ia_Magics[i_Magic]; // мэджик
			i_Tmp_Array[i_Magic][1] = -1000000; // макс прибыль
			
			i_Level = 20;
			while(i_Level > 0) {
				i_Level--;
				
				if(i_Tmp_Array[i_Magic][0] == sia_Grid_Trail[i_Level][0]) {
					i_Tmp_Array[i_Magic][1] = sia_Grid_Trail[i_Level][1];
					i_Tmp_Array[i_Magic][2] = sia_Grid_Trail[i_Level][2];
					break; //i_Level = -100;
				}
			}
		}
		i_Magic = i_Magics;
		ArrayInitialize(sia_Grid_Trail, 0);
		while(i_Magic > 0) {
			i_Magic--;
			sia_Grid_Trail[i_Magic][0] = i_Tmp_Array[i_Magic][0];
			sia_Grid_Trail[i_Magic][1] = i_Tmp_Array[i_Magic][1];
			sia_Grid_Trail[i_Magic][2] = i_Tmp_Array[i_Magic][2];
			sia_Grid_Trail[i_Magic][3] = Get_Fixed_Pips(sia_Grid_Trail[i_Magic][0], gs_Symbol, i_Order);
			sia_Grid_Trail[i_Magic][4] = i_Order;
		}
	} else ArrayInitialize(sia_Grid_Trail, 0);
	
	i_Magic = i_Magics;
	while(i_Magic > 0) {
		i_Magic--;
		Get_Orders_Data(ia_Magics[i_Magic], da_Orders_Data, gs_Symbol); // сбор информации об ордерах сети
		i_Value = sia_Grid_Trail[i_Magic][3] + da_Orders_Data[24] + da_Orders_Data[25]; // прибыль в пипсах
		if(Инфо) Show_Info(da_Orders_Data, i_Magic, sia_Grid_Trail); // вывод инфо на чарт
		
		// Трал профита:
		if(i_Value > 0) { // прибыль есть
			if(sia_Grid_Trail[i_Magic][1] < i_Value) // прибыль выросла
				sia_Grid_Trail[i_Magic][1] = i_Value; // запомнить новый макс
			else { // прибыль не выросла
				if(sia_Grid_Trail[i_Magic][1] > gi_Trail_Distance) { // трал включён
					if(sia_Grid_Trail[i_Magic][1] - i_Value > gi_Trail_Step) { // откат, надо закрывать
						if(Журнал) Print("Сворачивание сети ", ia_Magics[i_Magic], " с прибылью " + i_Value + " пп");
						sia_Grid_Trail[i_Magic][2] = 3; // новая фаза: ликвидация сети
						b_OK = true; // флаг успешного закрытия сети
						if(!KillEm(sia_Grid_Trail[i_Magic][0], -20)) // попытка удалить отложенные
							b_OK = false; // не всё удалилось
						if(!KillEm(sia_Grid_Trail[i_Magic][0], -10)) // попытка закрыть рыночные перекрытием
							b_OK = false; // не всё закрылось
						
						if(b_OK) {
							sia_Grid_Trail[i_Magic][2] = 0; // новая фаза: ожидание сигнала
							RemoveObjects(gs_Prefix);
						}
						
						continue; // к следующей сети
					}
				}
			}
		}
		// Достройка сети:
		i_Orders = OrdersTotal(); // обновить общее кол-во рыночных и отложенных ордеров
		if(sia_Grid_Trail[i_Magic][2] != 3) { // фаза сопровождения сети
			if(da_Orders_Data[35] + da_Orders_Data[45] < 2 * Ордеров_одной_стороны) { // нужна достройка сети
				if(Get_Outer_Prices(sia_Grid_Trail[i_Magic][0], gs_Symbol, d_Sell_Max, d_Sell_TP, d_Buy_Min, d_Buy_TP, d_Lot)) {
					if(da_Orders_Data[35] < Ордеров_одной_стороны) { // некомплект ордеров BuyLimit
						if(gi_Orders_Limit > 0 && gi_Orders_Limit <= i_Orders) {
							if(Журнал) Print("Достройка невозможна из-за лимита (" + gi_Orders_Limit + ") ордеров");
						} else {
							d_Buy_Min -= gd_Level_Step;
							if(d_Buy_Min == -gd_Level_Step) d_Buy_Min = Bid - gd_Level_Step;
							while(d_Buy_Min > Ask - gd_Stop_Level) d_Buy_Min -= gd_Level_Step;
							if(d_Buy_TP < d_Buy_Min) {
								d_Buy_TP = d_Sell_TP;
								if(d_Buy_TP < d_Buy_Min) d_Buy_TP = d_Buy_Min + Ордеров_одной_стороны * gd_Level_Step;
							}
							if(Журнал) Print("Достройка сети " + sia_Grid_Trail[i_Magic][0]);
							i_Order = Send_Order(gs_Symbol,
								sia_Grid_Trail[i_Magic][0],
								Рыночное_исполнение, gi_Try_To_Trade, gi_Connect_Wait,
								OP_BUYLIMIT,
								d_Lot,
								d_Buy_Min,
								gi_Slippage,
								"", 0,
								d_Buy_TP
//								da_Orders_Data[22]
		//						da_Orders_Data[8] + gd_First_Level
		//						da_Orders_Data[36]
							);
							if(i_Order > 0) {
								i_Orders++;
								if(i_Orders < gi_Orders_Limit || gi_Orders_Limit < 1)
									gb_Orders_Limit = false; // снять флаг лимита
							} else if(i_Order == -148) {
								gi_Orders_Limit = i_Orders; // запомнить лимит
								if(!gb_Orders_Limit) if(Журнал) Print("Достигнут предел (" + gi_Orders_Limit + ") кол-ва ордеров");
								gb_Orders_Limit = true; // флаг лимита
							} else if(i_Order < 0) if(Журнал) Print("Ошибка выставления BuyLimit лотом ", da_Orders_Data[39], " на уровень", da_Orders_Data[36] - gd_Level_Step, " SL=", da_Orders_Data[36], " Ask=", Ask);
						}
					}
					if(da_Orders_Data[45] < Ордеров_одной_стороны) { // отложек SellLimit меньше заданного
						if(gi_Orders_Limit > 0 && gi_Orders_Limit <= i_Orders) {
							if(Журнал) Print("Достройка невозможна из-за лимита (" + gi_Orders_Limit + ") ордеров");
						} else {
							d_Sell_Max += gd_Level_Step;
							if(d_Sell_Max == gd_Stop_Level) d_Sell_Max = Bid + gd_Level_Step;
							while(d_Sell_Max < Ask + gd_Stop_Level) d_Sell_Max += gd_Level_Step;
							if(d_Sell_TP == 0.0 || d_Sell_TP > d_Sell_Max) {
								d_Sell_TP = d_Buy_TP;
								if(d_Sell_TP == 0.0 || d_Sell_TP > d_Sell_Max) d_Sell_TP = d_Sell_Max - Ордеров_одной_стороны * gd_Level_Step;
							}
							if(Журнал) Print("Достройка сети " + sia_Grid_Trail[i_Magic][0]);
							i_Order = Send_Order(gs_Symbol,
								sia_Grid_Trail[i_Magic][0],
								Рыночное_исполнение, gi_Try_To_Trade, gi_Connect_Wait,
								OP_SELLLIMIT,
								d_Lot,
								d_Sell_Max,
								gi_Slippage,
								"", 0,
								d_Sell_TP
//								da_Orders_Data[23]
		//						da_Orders_Data[11] - gd_First_Level
		//						da_Orders_Data[47]
							);
							if(i_Order > 0) {
								i_Orders++;
								if(i_Orders < gi_Orders_Limit || gi_Orders_Limit < 1)
									gb_Orders_Limit = false; // снять флаг лимита
							} else if(i_Order == -148) {
								if(Журнал) Print("Достигнут предел кол-ва ордеров");
								gb_Orders_Limit = true; // флаг лимита
								gi_Orders_Limit = da_Orders_Data[4] + da_Orders_Data[5] + da_Orders_Data[30] + da_Orders_Data[35] + da_Orders_Data[40] + da_Orders_Data[45]; // запомнить лимит
							} else if(i_Order < 0) if(Журнал) Print("Ошибка выставления SellLimit лотом ", da_Orders_Data[48], " на уровень ", da_Orders_Data[47] + gd_Level_Step, " SL=", da_Orders_Data[47], " Bid=", Bid);
						}
					}
				}
			}
		}
		// Ликвидация сети:
		i_Orders = OrdersTotal(); // обновить общее кол-во рыночных и отложенных ордеров
		if(sia_Grid_Trail[i_Magic][2] == 3) { // фаза ликвидации сети
			if(Журнал) Print("Режим ликвидации сети " + sia_Grid_Trail[i_Magic][0] + ". Ордеров Buy=", DoubleToStr(da_Orders_Data[4], 0), " Sell=", DoubleToStr(da_Orders_Data[5], 0), " BuyLimit=", DoubleToStr(da_Orders_Data[35], 0), " SellLimit=", DoubleToStr(da_Orders_Data[45], 0));
			b_OK = true;
			if(da_Orders_Data[35] + da_Orders_Data[45] > 0) { // есть отложенные
				if(!KillEm(sia_Grid_Trail[i_Magic][0], -20)) // попытка удалить отложенные
					b_OK = false; // не всё удалилось
			}
			if(da_Orders_Data[4] + da_Orders_Data[5] > 0) { // есть рыночные
				if(!KillEm(sia_Grid_Trail[i_Magic][0], -10)) // попытка закрыть рыночные перекрытием
					b_OK = false; // не всё закрылось
			}
			
			if(b_OK) sia_Grid_Trail[i_Magic][2] = 0; // новая фаза: ожидание сигнала
		}
	}
	
	return(0);
}



int Error_Handle(int iError) {
	// На базе функции by Nikolay Khrushchev N.A.Khrushchev@gmail.com
	switch(iError) {
		// группа 1: не прекращать попытки
		case 2: if(Журнал) Print("Общая ошибка (", iError, ")"); return(0);
		case 4: if(Журнал) Print("Торговый сервер занят (", iError, ")"); return(0);
		case 8: if(Журнал) Print("Слишком частые запросы (", iError, ")"); return(0);
		case 129: if(Журнал) Print("Неправильная цена (", iError, ")"); return(0);
		case 135: if(Журнал) Print("Цена изменилась (", iError, ")"); return(0);
		case 136: if(Журнал) Print("Нет цен (", iError, ")"); return(0);
		case 137: if(Журнал) Print("Брокер занят (", iError, ")"); return(0);
		case 138: if(Журнал) Print("Новые цены (", iError, ")"); return(0);
		case 141: if(Журнал) Print("Слишком много запросов (", iError, ")"); return(0);
		case 146: if(Журнал) Print("Подсистема торговли занята (", iError, ")"); return(0);
		// группа 2: прекращаем попытки
		case 0: if(Журнал) Print("Ошибка отсутствует (", iError, ")"); return(1);
		case 1: if(Журнал) Print("Нет ошибки, но результат не известен (", iError, ")"); return(1);
		case 3: if(Журнал) Print("Неправильные параметры (", iError, ")"); return(1);
		case 6: if(Журнал) Print("Нет связи с торговым сервером (", iError, ")"); return(1);
		case 128: if(Журнал) Print("Истек срок ожидания совершения сделки (", iError, ")"); return(1);
		case 130: if(Журнал) Print("Неправильные стопы (", iError, ")"); return(1);
		case 131: if(Журнал) Print("Неправильный объем (", iError, ")"); return(1);
		case 132: if(Журнал) Print("Рынок закрыт (", iError, ")"); return(1);
		case 133: if(Журнал) Print("Торговля запрещена (", iError, ")"); return(1);
		case 134: if(Журнал) Print("Недостаточно денег для совершения операции (", iError, ")"); return(1);
		case 139: if(Журнал) Print("Ордер заблокирован и уже обрабатывается (", iError, ")"); return(1);
		case 145: if(Журнал) Print("Модификация запрещена, так как ордер слишком близок к рынку (", iError, ")"); return(1);
		case 148: if(Журнал) Print("Количество открытых и отложенных ордеров достигло предела, установленного брокером (", iError, ")"); return(3);
		// группа 3: завершаем работу
		case 5: if(Журнал) Print("Старая версия клиентского терминала (", iError, ")"); return(2);
		case 7: if(Журнал) Print("Недостаточно прав (", iError, ")"); return(2);
		case 9: if(Журнал) Print("Недопустимая операция нарушающая функционирование сервера (", iError, ")"); return(2);
		case 64: if(Журнал) Print("Счет заблокирован (", iError, ")"); return(2);
		case 65: if(Журнал) Print("Неправильный номер счета (", iError, ")"); return(2);
		case 140: if(Журнал) Print("Разрешена только покупка (", iError, ")"); return(2);
		case 147: if(Журнал) Print("Использование даты истечения ордера запрещено брокером (", iError, ")"); return(2);
		case 149: if(Журнал) Print("Попытка открыть противоположную позицию к уже существующей в случае, если хеджирование запрещено (", iError, ")"); return(2);
		case 150: if(Журнал) Print("Попытка закрыть позицию по инструменту в противоречии с правилом FIFO (", iError, ")"); return(2);
	}
}                     


int Send_Order(string sSymbol, int iMagic, bool b_Market_Exec, int iAttempts, int iConnect_Wait, int iOrder_Type, double dLots, double dPrice, int iSlippage, string sComment="", double dSL=0, double dTP=0) {
	// Отправка запроса на выставление ордера
	// Возвращает номер тикета или -1
	// Использует функции: Error_Handle()
	int
		iTry = iAttempts,
		i_Ticket = -1
	;
	
	while(iTry > 0) { // попытки выставить
		iTry--;
		if(IsTradeAllowed()) {
			if(b_Market_Exec) i_Ticket = OrderSend(sSymbol, iOrder_Type, dLots, NormalizeDouble(dPrice, Digits), iSlippage, 0, 0, sComment, iMagic);
			else i_Ticket = OrderSend(sSymbol, iOrder_Type, dLots, NormalizeDouble(dPrice, Digits), iSlippage, dSL, dTP, sComment, iMagic);
			
			if(b_Market_Exec && i_Ticket > 0 && (dSL > 0.0 || dTP > 0.0)) {
				if(OrderSelect(i_Ticket, SELECT_BY_TICKET))
					OrderModify(OrderTicket(), OrderOpenPrice(), dSL, dTP, 0);
			}
		} else {Sleep(1000 * iConnect_Wait); continue;}
		
		if(i_Ticket >= 0) break;
		switch(Error_Handle(GetLastError())) {
			case 0: RefreshRates(); Sleep(1000 * iConnect_Wait); break;
			case 1: return(i_Ticket);
//			case 2: gb_Can_Trade = false; return(i_Ticket);
			case 2: return(i_Ticket);
			case 3: return(-148);
		}
	}
	return(i_Ticket);
}


void Get_Orders_Data(int i_Magic, double& da_Orders_Data[], string s_Symbol) {
	// Записывает в массив da_Orders_Data суммарную информацию о рыночных ордерах
		// [0] прибыль
		// [1] убыток
		// [2] кол-во прибыльных ордеров
		// [3] кол-во убыточных ордеров
		// [4] кол-во ордеров Buy
		// [5] кол-во ордеров Sell
		// [6] сумма лотов Buy
		// [7] сумма лотов Sell
		// [8] цена верхнего входа Buy
		// [9] цена нижнего входа Buy
		// [10] цена верхнего входа Sell
		// [11] цена нижнего входа Sell
		// [12] тип последнего входа: 0=Buy, 1=Sell, -1=нет
		// [13] лот последнего входа
		// [14] цена последнего входа
		// [15] тикет последнего входа
		// [17] ??
		// [18] тикет верхнего входа Buy
		// [19] тикет нижнего входа Buy
		// [20] тикет верхнего входа Sell
		// [21] тикет нижнего входа Sell
		// [22] число из коммента верхнего входа Buy
		// [23] число из коммента нижнего входа Sell
		// [24] сумма пунктов Buy
		// [25] сумма пунктов Sell
		// [26] прибыль Buy
		// [27] прибыль Sell
		// [28] сумма пунктов StopLos Buy
		// [29] сумма пунктов StopLos Sell
		
		// [30] кол-во отложенных ордеров BuyStop
		// [31] цена нижнего ордера BuyStop
		// [32] цена верхнего ордера BuyStop
		// [33] лот верхнего ордера BuyStop
		// [34] лот нижнего ордера BuyStop
		
		// [35] кол-во отложенных ордеров BuyLimit
		// [36] цена нижнего ордера BuyLimit
		// [37] цена верхнего ордера BuyLimit
		// [38] лот верхнего ордера BuyLimit
		// [39] лот нижнего ордера BuyLimit
		
		// [40] кол-во отложенных ордеров SellStop
		// [41] цена нижнего ордера SellStop
		// [42] цена верхнего ордера SellStop
		// [43] лот верхнего ордера SellStop
		// [44] лот нижнего ордера SellStop
		
		// [45] кол-во отложенных ордеров SellLimit
		// [46] цена нижнего ордера SellLimit
		// [47] цена верхнего ордера SellLimit
		// [48] лот верхнего ордера SellLimit
		// [49] лот нижнего ордера SellLimit
		
	// Глобальные переменные: gd_One_Pip_Rate
	
	ArrayInitialize(da_Orders_Data, 0);
	da_Orders_Data[12] = -1;
	int
		iOrder = OrdersTotal(),
		i_Last_Entry_Time = 0
	;
	double
		d_Value
	;
	if(iOrder < 1) return;
	
	while(iOrder > 0) { // перебор ордеров
		iOrder--;
		if(OrderSelect(iOrder, SELECT_BY_POS, MODE_TRADES))
			if(OrderSymbol() == s_Symbol)
				if(OrderMagicNumber() == i_Magic || i_Magic == 0) { // наш клиент
					// прибыль/убыток
					d_Value = OrderProfit() + OrderSwap();
					if(d_Value > 0) {
						da_Orders_Data[0] += d_Value; // прибыль
						da_Orders_Data[2] += 1; // кол-во прибыльных
					}
					else {
						da_Orders_Data[1] += d_Value; // убыток
						da_Orders_Data[3] += 1; // кол-во убыточных
					}
					if(i_Last_Entry_Time < OrderOpenTime() && OrderType() < 2) {
						i_Last_Entry_Time = OrderOpenTime();
						da_Orders_Data[12] = OrderType(); // направление последнего входа
						da_Orders_Data[13] = OrderLots(); // лот последнего входа
						da_Orders_Data[14] = OrderOpenPrice(); // направление последнего входа
						da_Orders_Data[15] = OrderTicket(); // тикет последнего входа
					}
					switch(OrderType()) {
						case OP_BUY:
								da_Orders_Data[4] += 1; // счётчик рыночных ордеров на покупку
								da_Orders_Data[6] += OrderLots(); // сумма лотов ордеров на покупку
								da_Orders_Data[24] += Bid - OrderOpenPrice(); // прибыль в пунктах ордеров на покупку
								da_Orders_Data[26] += d_Value; // прибыль ордеров на покупку
								da_Orders_Data[28] += OrderOpenPrice() - OrderStopLoss(); // SL ордеров на покупку
								if(OrderOpenPrice() > da_Orders_Data[8]) {
									da_Orders_Data[8] = OrderOpenPrice(); // цена верхнего входа Buy
									da_Orders_Data[18] = OrderTicket(); // тикет верхнего входа Buy
									da_Orders_Data[22] = StrToDouble(OrderComment()); // число из коммента верхнего входа Buy
								}
								if(OrderOpenPrice() < da_Orders_Data[9] || da_Orders_Data[9] == 0.0) {
									da_Orders_Data[9] = OrderOpenPrice(); // цена нижнего входа Buy
									da_Orders_Data[19] = OrderTicket(); // тикет нижнего входа Buy
								}
								break;
						case OP_SELL:
								da_Orders_Data[5] += 1; // счётчик рыночных ордеров на продажу
								da_Orders_Data[7] += OrderLots(); // сумма лотов ордеров на продажу
								da_Orders_Data[25] += OrderOpenPrice() - Ask; // прибыль в пунктах ордеров на продажу
								da_Orders_Data[27] += d_Value; // прибыль ордеров на продажу
								da_Orders_Data[29] += OrderStopLoss() - OrderOpenPrice(); // SL ордеров на продажу
								if(OrderOpenPrice() > da_Orders_Data[10]) {
									da_Orders_Data[10] = OrderOpenPrice(); // цена верхнего входа Sell
									da_Orders_Data[20] = OrderTicket(); // тикет верхнего входа Sell
								}
								if(OrderOpenPrice() < da_Orders_Data[11] || da_Orders_Data[11] == 0.0) {
									da_Orders_Data[11] = OrderOpenPrice(); // цена нижнего входа Sell
									da_Orders_Data[21] = OrderTicket(); // тикет нижнего входа Sell
									da_Orders_Data[23] = StrToDouble(OrderComment()); // число из коммента нижнего входа Sell
								}
								break;
						case OP_BUYLIMIT:
								da_Orders_Data[35] += 1; // счётчик отложенных ордеров BuyLimit
								if(OrderOpenPrice() > da_Orders_Data[37]) {
									da_Orders_Data[37] = OrderOpenPrice(); // цена верхнего ордера BuyLimit
									da_Orders_Data[38] = OrderLots(); // лот верхнего ордера BuyLimit
								}
								if(OrderOpenPrice() < da_Orders_Data[36] || da_Orders_Data[36] == 0.0) {
									da_Orders_Data[36] = OrderOpenPrice(); // цена нижнего ордера BuyLimit
									da_Orders_Data[39] = OrderLots(); // лот нижнего ордера BuyLimit
								}
								break;
						case OP_SELLLIMIT:
								da_Orders_Data[45] += 1; // счётчик отложенных ордеров SellLimit
								if(OrderOpenPrice() > da_Orders_Data[47]) {
									da_Orders_Data[47] = OrderOpenPrice(); // цена верхнего ордера SellLimit
									da_Orders_Data[48] = OrderLots(); // лот верхнего ордера SellLimit
								}
								if(OrderOpenPrice() < da_Orders_Data[46] || da_Orders_Data[46] == 0.0) {
									da_Orders_Data[46] = OrderOpenPrice(); // цена нижнего ордера SellLimit
									da_Orders_Data[49] = OrderLots(); // лот нижнего ордера SellLimit
								}
								break;
						case OP_BUYSTOP:
								da_Orders_Data[30] += 1; // счётчик отложенных ордеров BuyStop
								if(OrderOpenPrice() > da_Orders_Data[32]) {
									da_Orders_Data[32] = OrderOpenPrice(); // цена верхнего ордера BuyStop
									da_Orders_Data[33] = OrderLots(); // лот верхнего ордера BuyStop
								}
								if(OrderOpenPrice() < da_Orders_Data[31] || da_Orders_Data[31] == 0.0) {
									da_Orders_Data[31] = OrderOpenPrice(); // цена нижнего ордера BuyStop
									da_Orders_Data[34] = OrderLots(); // лот нижнего ордера BuyStop
								}
								break;
						case OP_SELLSTOP:
								da_Orders_Data[40] += 1; // счётчик отложенных ордеров SellStop
								if(OrderOpenPrice() > da_Orders_Data[42]) {
									da_Orders_Data[42] = OrderOpenPrice(); // цена верхнего ордера SellStop
									da_Orders_Data[43] = OrderLots(); // лот верхнего ордера SellStop
								}
								if(OrderOpenPrice() < da_Orders_Data[41] || da_Orders_Data[41] == 0.0) {
									da_Orders_Data[41] = OrderOpenPrice(); // цена нижнего ордера SellStop
									da_Orders_Data[44] = OrderLots(); // лот нижнего ордера SellStop
								}
								break;
					}
				}
	}
	
	da_Orders_Data[24] *= gd_One_Pip_Rate;
	da_Orders_Data[25] *= gd_One_Pip_Rate;
	da_Orders_Data[28] *= gd_One_Pip_Rate;
	da_Orders_Data[29] *= gd_One_Pip_Rate;
	return;
}



double Get_Lot(double dRisk_Percent, double dSL, double dLot_Rate=0, double dLot_Value=0) {
	// Расчёт лота
	// Глобальные переменные: gd_Lot_Step, gd_Lot_Margin, gd_Lot_Min, gd_Lot_Max
	double dLot;
	
	if(dRisk_Percent > 0.0) // лот надо рассчитывать из заданных риска и SL
		dLot = gd_Lot_Step * MathFloor(dRisk_Percent * AccountFreeMargin() / 100 / dSL / MarketInfo(Symbol(), MODE_TICKVALUE) / gd_Lot_Step);
	else dLot = dLot_Value;
	if(dLot == 0)	dLot = gd_Lot_Step * MathFloor(dLot_Rate * AccountFreeMargin() / 100 / MarketInfo(Symbol(), MODE_TICKVALUE) / gd_Lot_Step);
	
	if(dLot < gd_Lot_Min) {
//		if(Журнал) Print("Обломайся: расчётный лот (", dLot, ") меньше допустимого (", gd_Lot_Min, ")");
//		return(0);
		if(Журнал) Print("Расчётный лот (", dLot, ") увеличен до допустимого (", gd_Lot_Min, ")");
		dLot = gd_Lot_Min;
	}
	if(dLot > gd_Lot_Max) {
		if(Журнал) Print("Расчётный лот (", dLot, ") уменьшен до допустимого (", gd_Lot_Max, ")");
		dLot = gd_Lot_Max;
	}
	
	return (dLot);
}


bool KillEm(int iMagic, int iOrder_Type = -1, int iClose_Type = 0, int iExclude_Ticket = -1) {
	// Закрытие и удаление ордеров, исключая указанный в iExclude_Ticket тикет
	// Возвращает false, если не все ордера удалось закрыть или удалить
	// Отрицательные значения iOrder_Type означают:
	// -1  : закрыть всё
	// -10 : закрыть все рыночные
	// -20 : закрыть все отложенные
	// iClose_Type - последовательность закрытия ордеров:
	// 0 : от последних к первым
	// 1 : только прибыльные
	// 2 : только убыточные
	// 3 : сначала убыточные
	// 4 : сначала прибыльные
	// 5 : сначала Buy
	// 6 : сначала Sell
	// 7 : закрытие встречным
	// 8 : от первых к последним
	// Глобальные переменные: gs_Symbol, gi_Slippage, gi_Try_To_Trade, gi_Connect_Wait
	// Использует функции: Error_Handle()
	int
		iTry,
		iNet_Orders = 0, // кол-во закрытых ордеров
		i_Ticket = -1,
		ia_Tickets_A[40], ia_Tickets_B[40], // 2 массива ордеров (buy/sell или прибыльных/убыточных)
		i_Tickets_A = -1, i_Tickets_B = -1, // индексы массивов ордеров
		iOrder = OrdersTotal() // общее кол-во рыночных ордеров
	;
	bool
		b_OK = true // все ордера ликвидированы
	;
	if(iOrder < 1) return(b_OK); // нет ордеров
	double
		d_Price,
		dNet_Profit = 0 // профит
	;
	if(iClose_Type > 0) {ArrayInitialize(ia_Tickets_A, 0); ArrayInitialize(ia_Tickets_B, 0);}
	
	while(iOrder > 0) { // перебор ордеров
		iOrder--;
		if(OrderSelect(iOrder, SELECT_BY_POS, MODE_TRADES))
			if(OrderTicket() == iExclude_Ticket) continue;
			else if(OrderSymbol() == gs_Symbol)
				if(OrderMagicNumber() == iMagic) { // наш клиент
					i_Ticket = -1;
					iTry = gi_Try_To_Trade;
					if(OrderType() == OP_BUY && (iOrder_Type == OP_BUY || iOrder_Type == -1 || iOrder_Type == -10)) { // это была покупка
						if(iClose_Type > 4) { // разделение по buy/sell
							i_Tickets_A++;
							ia_Tickets_A[i_Tickets_A] = OrderTicket(); // запись ордера в список покупок
						} else if(iClose_Type > 0) { // разделение по прибыли/убыткам
							if(OrderProfit() > 0.0) { // запись ордера в список прибыльных
								i_Tickets_A++;
								ia_Tickets_A[i_Tickets_A] = OrderTicket();
							} else { // запись ордера в список убыточных
								i_Tickets_B++;
								ia_Tickets_B[i_Tickets_B] = OrderTicket();
							}
						} else // простое закрытие
							if(!Close_Order(OrderTicket(), gi_Try_To_Trade, gi_Slippage)) b_OK = false; // не всё закрылось
					} else if(OrderType() == OP_SELL && (iOrder_Type == OP_SELL || iOrder_Type == -1 || iOrder_Type == -10)) { // это была продажа
						if(iClose_Type > 4) { // разделение по buy/sell
							i_Tickets_B++;
							ia_Tickets_B[i_Tickets_B] = OrderTicket(); // запись ордера в список покупок
						} else if(iClose_Type > 0) { // разделение по прибыли/убыткам
							if(OrderProfit() > 0.0) { // запись ордера в список прибыльных
								i_Tickets_A++;
								ia_Tickets_A[i_Tickets_A] = OrderTicket();
							} else { // запись ордера в список убыточных
								i_Tickets_B++;
								ia_Tickets_B[i_Tickets_B] = OrderTicket();
							}
						} else // простое закрытие
							if(!Close_Order(OrderTicket(), gi_Try_To_Trade, gi_Slippage)) b_OK = false; // не всё закрылось
					} else // это была отложка
						if(OrderType() > 1 && iOrder_Type == OrderType() || iOrder_Type == -1 || iOrder_Type == -20) {
							while(iTry > 0) { // попытки закрыть
								iTry--;
								if(IsTradeAllowed()) if(OrderDelete(OrderTicket())) i_Ticket = 1;
								else{Sleep(gi_Connect_Wait); continue;}
								if(i_Ticket >= 0) break;
								switch(Error_Handle(GetLastError())) {
									case 0: RefreshRates(); Sleep(gi_Connect_Wait); break;
									case 1: break;
									case 2: gb_Can_Trade = false; break;
								}
							}
							if(i_Ticket > -1) {
								iNet_Orders++; // счётчик закрытых ордеров
							} else {
								b_OK = false; // не всё закрылось
								if(Журнал) Print("Ошибка удаления ордера #", OrderTicket(), " OpenPrice=", OrderOpenPrice(), " Bid=", Bid, " Ask=", Ask);
							}
						}
				}
	}
	
	switch(iClose_Type) {
		case 0: // от последних к первым
			return(b_OK);
		case 1:	// только прибыльные
			while(i_Tickets_A > -1) { // прибыльные
				if(!Close_Order(ia_Tickets_A[i_Tickets_A], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // не всё закрылось
				i_Tickets_A--;
			}
			return(b_OK);
		case 2:	// только убыточные
			while(i_Tickets_B > -1) { // убыточные
				if(!Close_Order(ia_Tickets_B[i_Tickets_B], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // не всё закрылось
				i_Tickets_B--;
			}
			return(b_OK);
		case 3:	// сначала убыточные
			while(i_Tickets_B > -1) { // убыточные
				if(!Close_Order(ia_Tickets_B[i_Tickets_B], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // не всё закрылось
				i_Tickets_B--;
			}
			while(i_Tickets_A > -1) { // прибыльные
				if(!Close_Order(ia_Tickets_A[i_Tickets_A], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // не всё закрылось
				i_Tickets_A--;
			}
			return(b_OK);
		case 4:	// сначала прибыльные
			while(i_Tickets_A > -1) { // прибыльные
				if(!Close_Order(ia_Tickets_A[i_Tickets_A], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // не всё закрылось
				i_Tickets_A--;
			}
			while(i_Tickets_B > -1) { // убыточные
				if(!Close_Order(ia_Tickets_B[i_Tickets_B], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // не всё закрылось
				i_Tickets_B--;
			}
			return(b_OK);
		case 5:	// сначала buy
			while(i_Tickets_A > -1) { // buy
				if(!Close_Order(ia_Tickets_A[i_Tickets_A], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // не всё закрылось
				i_Tickets_A--;
			}
			while(i_Tickets_B > -1) { // sell
				if(!Close_Order(ia_Tickets_B[i_Tickets_B], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // не всё закрылось
				i_Tickets_B--;
			}
			return(b_OK);
		case 6:	// сначала sell
			while(i_Tickets_B > -1) { // sell
				if(!Close_Order(ia_Tickets_B[i_Tickets_B], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // не всё закрылось
				i_Tickets_B--;
			}
			while(i_Tickets_A > -1) { // buy
				if(!Close_Order(ia_Tickets_A[i_Tickets_A], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // не всё закрылось
				i_Tickets_A--;
			}
			return(b_OK);
		case 7:	// закрытие встречным
			// цикл закрытия встречными:
			while((i_Tickets_A + 1) * (i_Tickets_B + 1) > 0) {
				i_Ticket = MathMin(i_Tickets_A, i_Tickets_B);
				while(i_Ticket > -1) {
					if(!OrderCloseBy(ia_Tickets_B[i_Ticket], ia_Tickets_A[i_Ticket])) b_OK = false; // не всё закрылось
					i_Ticket--;
				}
				// обновление списков ордеров:
				i_Tickets_A = -1;
				i_Tickets_B = -1;
				ArrayInitialize(ia_Tickets_A, 0);
				ArrayInitialize(ia_Tickets_B, 0);
				
				iOrder = OrdersTotal();
				while(iOrder > 0) { // перебор ордеров
					iOrder--;
					if(OrderSelect(iOrder, SELECT_BY_POS, MODE_TRADES))
						if(OrderTicket() == iExclude_Ticket) continue;
						else if(OrderSymbol() == gs_Symbol)
							if(OrderMagicNumber() == iMagic) { // наш клиент
								i_Ticket = -1;
								if(OrderType() == OP_BUY) { // это была покупка
									i_Tickets_A++;
									ia_Tickets_A[i_Tickets_A] = OrderTicket(); // запись ордера в список покупок
								} else if(OrderType() == OP_SELL) { // это была продажа
									i_Tickets_B++;
									ia_Tickets_B[i_Tickets_B] = OrderTicket(); // запись ордера в список покупок
								}
							}
				}
			}
			// закрытие остатков:
			while(i_Tickets_B > -1) { // sell
				if(!Close_Order(ia_Tickets_B[i_Tickets_B], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // не всё закрылось
				i_Tickets_B--;
			}
			while(i_Tickets_A > -1) { // buy
				if(!Close_Order(ia_Tickets_A[i_Tickets_A], gi_Try_To_Trade, gi_Slippage)) b_OK = false; // не всё закрылось
				i_Tickets_A--;
			}
			return(b_OK);
	}
	
	return(b_OK);
}



bool Close_Order(int i_Ticket, int i_Try_To_Trade, int i_Slippage, double d_Lot=0) {
	// Закрытие ордера или его части по заданному тикету
	
	if(!OrderSelect(i_Ticket, SELECT_BY_TICKET)) return(true); // этого ордера уже нет, занчит закрыт
	
	double dPrice;
	bool b_Done = false;
	while(i_Try_To_Trade > 0) { // попытки закрыть
		i_Try_To_Trade--;
		dPrice = Bid; if(OrderType() == OP_SELL) dPrice = Ask;
		if(d_Lot == 0.0) d_Lot = OrderLots();
		if(IsTradeAllowed()) b_Done = OrderClose(OrderTicket(), d_Lot, dPrice, i_Slippage);
		else{Sleep(gi_Connect_Wait); continue;}
		if(b_Done) return(true);
		
		Print("Ошибка закрытия ордера. Ticket=", OrderTicket(), " Lot=", d_Lot, " Price=", dPrice, " Slippage=", i_Slippage, " Ask=", Ask, " Bid=", Bid);
		switch(Error_Handle(GetLastError())) {
			case 0: RefreshRates(); Sleep(gi_Connect_Wait); break;
			case 1: break;
			case 2: gb_Can_Trade = false; break;
		}
	}
	
	return(false);
}


void Label_Handle(string sLabelName, string sLabelText = "", string sLabelFontName = "Arial", int iLabelFontSize = 10, color cLabelFontColor = Bisque, int iCorner = 0, int iXpos = 0, int iYpos = 0, int iAngle = 0, int iWindow = 0, bool bBackground=false) {
	// Инфо-надписи в углах графика
	if(ObjectFind(sLabelName) != -1) ObjectDelete(sLabelName);
	if(sLabelText != "") {
		ObjectCreate(sLabelName, OBJ_LABEL, iWindow, 0, 0);
		ObjectSet(sLabelName, OBJPROP_CORNER, iCorner);
		ObjectSet(sLabelName, OBJPROP_XDISTANCE, iXpos);
		ObjectSet(sLabelName, OBJPROP_YDISTANCE, iYpos);
		ObjectSet(sLabelName, OBJPROP_ANGLE, iAngle);
		ObjectSet(sLabelName, OBJPROP_BACK, bBackground);
		ObjectSetText(sLabelName, sLabelText, iLabelFontSize, sLabelFontName, cLabelFontColor);
	}
}


void Show_Info(double da_Orders_Data[], int i_Level, int ia_Grid_Trail[][]) {
	// Вывод информации на график
	// Глобальные переменные: gs_Prefix, gd_Loss_Rate, gb_Orders_Limit
	int
		i_Value = 0,
		iX_Pos = 10,
		iY_Pos = 5 + 25 * (i_Level + 1)
	;
	string s_String;
	color c_Color;
	
	s_String = ia_Grid_Trail[i_Level][3];
	if(ia_Grid_Trail[i_Level][3] > 0) s_String = "+" + s_String;
	s_String = " Закр=" + ia_Grid_Trail[i_Level][4] + " " + s_String;
	i_Value = da_Orders_Data[24] + da_Orders_Data[25];
	s_String = i_Value + " Buy=" + DoubleToStr(da_Orders_Data[4], 0) + " Sell=" + DoubleToStr(da_Orders_Data[5], 0) + s_String;
	if(i_Value > 0) s_String = "+" + s_String;
	i_Value += ia_Grid_Trail[i_Level][3];
	c_Color = Silver;
	if(i_Value < 0) c_Color = HotPink;
	else if(i_Value > 0) c_Color = LightGreen;
	Label_Handle(gs_Prefix + " сеть " + i_Level, s_String + " : " + ia_Grid_Trail[i_Level][0], "Arial", 10, c_Color, 3, iX_Pos, iY_Pos);
	// Всего ордеров:
	if(i_Level == 0) {
		iY_Pos = 5;
		if(gb_Orders_Limit) c_Color = OrangeRed;
		else c_Color = Silver;
		Label_Handle(gs_Prefix + " ордеров", "ордеров: " + OrdersTotal(), "Arial", 10, c_Color, 3, iX_Pos, iY_Pos);
	}
}


int Get_Signal(double& d_Channel_Mid) {
	// Получение средней линии из FX_SHIChannel и определение её пересечения
	// В переменную d_Channel_Mid возвращает уровень середины канала
	d_Channel_Mid = iCustom(NULL, 0, "FX_SHIChannel", 1, 0); // средняя линия на этом баре
	double d_Mid_Line_Prev = iCustom(NULL, 0, "FX_SHIChannel", 1, 1); // средняя линия на предыдущем
	
	if(d_Channel_Mid == Close[0]) return(0); // цена на линии, нет пересечения
	if(d_Mid_Line_Prev ==  Close[1]) { // предыдущий бар закрылся на линии
		d_Mid_Line_Prev = iCustom(NULL, 0, "FX_SHIChannel", 1, 2); // а перед ним?
		if(d_Mid_Line_Prev ==  Close[2]) { // тоже
			d_Mid_Line_Prev = iCustom(NULL, 0, "FX_SHIChannel", 1, 3); // а перед ним?
			if(d_Mid_Line_Prev ==  Close[3]) // цена предыдущего бара закрылась на линии
				return(0); // пас
		}
	}
	
	if(Close[0] > d_Channel_Mid) {
		if(Close[1] < d_Mid_Line_Prev) return(1); // пересечение вверх
	}
	else if(Close[1] > d_Mid_Line_Prev) return(-1); // пересечение вниз
	
	return(0);
}


int Get_Magics_List(int& ia_Magics[], string s_Symbol) {
	// Получение списка идентификаторов сетей
	ArrayResize(ia_Magics, 0);
	int
		i_Order = OrdersTotal(),
		i_Magics = 0
	;
	if(i_Order < 1) return(i_Magics);
	
	while(i_Order > 0) { // перебор ордеров
		i_Order--;
		if(OrderSelect(i_Order, SELECT_BY_POS, MODE_TRADES))
			if(OrderSymbol() == s_Symbol)
				i_Magics = Array_Int_Push(ia_Magics, OrderMagicNumber(), i_Magics);
	}
	return(i_Magics);
}


int Get_Fixed_Pips(int i_Magic, string s_Symbol, int& i_Count) {
	// Считает в истории закрытых сделок сумму прибыли по заданному мэджику. В пипсах
	// В переменную i_Count помещает кол-во закрытых ордеров
	// Глобальные переменные: gd_One_Pip_Rate
	
	i_Count = 0;
	int i_Order = OrdersHistoryTotal();
	if(i_Order < 1) return(0);
	
	double d_Pips = 0;
	
	while(i_Order > 0) { // перебор ордеров
		i_Order--;
		if(OrderSelect(i_Order, SELECT_BY_POS, MODE_HISTORY))
			if(OrderSymbol() == s_Symbol)
				if(OrderMagicNumber() == i_Magic) {
					if(OrderType() == OP_BUY) {i_Count++; d_Pips += OrderClosePrice() - OrderOpenPrice();}
					else if(OrderType() == OP_SELL) {i_Count++; d_Pips += OrderOpenPrice() - OrderClosePrice();}
				}
	}
	
	return(d_Pips * gd_One_Pip_Rate);
	
}


int Array_Int_Push(int& ia_Array[], int i_Value, int i_Count) {
	if(i_Count < 1) {
		ArrayResize(ia_Array, 1);
		ia_Array[0] = i_Value;
		i_Count = 1;
	} else {
		int i_Index = 0;
		while(i_Index < i_Count) {
			if(ia_Array[i_Index] == i_Value) break;
			i_Index++;
		}
		if(i_Index == i_Count) {
			ArrayResize(ia_Array, i_Count + 1);
			ia_Array[i_Index] = i_Value;
			i_Count++;
		}
	}
	
	return(i_Count);
}


int Get_Magic() {
	// Возвращает мэджик = 1 + день года (3 зн) + секунда дня (5 зн)
	int i_Value = DayOfYear();
	string s_Value = "1";
	
	if(i_Value < 10) s_Value = "100" + i_Value;
	else if(i_Value < 100) s_Value = "10" + i_Value;
	else s_Value = "1" + i_Value;
	
	i_Value = TimeCurrent() - iTime(Symbol(), PERIOD_D1, 0);
	if(i_Value < 10) s_Value = s_Value + "0000" + i_Value;
	else if(i_Value < 100) s_Value = s_Value + "000" + i_Value;
	else if(i_Value < 1000) s_Value = s_Value + "00" + i_Value;
	else if(i_Value < 10000) s_Value = s_Value + "0" + i_Value;
	else s_Value = s_Value + i_Value;
	
	return(StrToInteger(s_Value));
}


int RemoveObjects(string sName="", bool bExact=false) {
	int iObjectID = ObjectsTotal();
	while(iObjectID > 0) {
		iObjectID--;
		if(sName == "") ObjectDelete(ObjectName(iObjectID)); // если имя не указано - косим всех!
		else {
			if(bExact) { // если задано удалить только того, чьё имя указано
				if(ObjectName(iObjectID) == sName) ObjectDelete(ObjectName(iObjectID)); // kill'em
			}
			else {
				if(StringFind(ObjectName(iObjectID), sName) != 0) continue; // если имя граф.объекта не начинается с указанного - не наш клиент
				ObjectDelete(ObjectName(iObjectID)); // kill'em
			}
		}
	}
	
	return(0);
}


bool Get_Outer_Prices(int i_Magic, string s_Symbol, double& d_Sell_Max, double& d_Sell_TP, double& d_Buy_Min, double& d_Buy_TP, double& d_Lot) {
	// Поиск крайних ордеров (открытых и закрытых) по заданному мэджику
	// Уровень нижнего ордера Buy или BuyLimit помещает в переменную d_Buy_Min
	// а верхнего Buy Sell или SellLimit - в d_Sell_Max
	
	int
		i_Order = OrdersTotal()
	;
	d_Sell_Max = 0;
	d_Buy_Min = 1000000;
	d_Lot = 0;
	d_Sell_TP = 0; d_Buy_TP = 0;
	
	// перебор рыночных и отложенных ордеров:
	while(i_Order > 0) {
		i_Order--;
		if(OrderSelect(i_Order, SELECT_BY_POS, MODE_TRADES))
			if(OrderSymbol() == s_Symbol)
				if(OrderMagicNumber() == i_Magic) {
					if(OrderType() == OP_SELL || OrderType() == OP_SELLLIMIT) {
						d_Lot = OrderLots();
						if(OrderOpenPrice() > d_Sell_Max) {
							d_Sell_Max = OrderOpenPrice();
							d_Sell_TP = OrderTakeProfit();
						}
					} else if(OrderType() == OP_BUY || OrderType() == OP_BUYLIMIT) {
						d_Lot = OrderLots();
						if(OrderOpenPrice() < d_Buy_Min) {
							d_Buy_Min = OrderOpenPrice();
							d_Buy_TP = OrderTakeProfit();
						}
					}
				}
	}
	
	// перебор закрытых ордеров:
	i_Order = OrdersHistoryTotal();
	while(i_Order > 0) {
		i_Order--;
		if(OrderSelect(i_Order, SELECT_BY_POS, MODE_HISTORY))
			if(OrderSymbol() == s_Symbol)
				if(OrderMagicNumber() == i_Magic) {
					if(OrderType() == OP_BUY) {
						d_Lot = OrderLots();
						if(OrderOpenPrice() < d_Buy_Min) {
							d_Buy_Min = OrderOpenPrice();
							d_Buy_TP = OrderTakeProfit();
						}
					} else if(OrderType() == OP_SELL) {
						d_Lot = OrderLots();
						if(OrderOpenPrice() > d_Sell_Max) {
							d_Sell_Max = OrderOpenPrice();
							d_Sell_TP = OrderTakeProfit();
						}
					}
				}
	}
	
	if(d_Lot > 0.0) return(true);
	return(false); // ничего не найдено
}