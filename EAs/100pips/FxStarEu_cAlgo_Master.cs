using System;
using System.Linq;
using cAlgo.API;
using cAlgo.API.Indicators;
using cAlgo.API.Internals;
using cAlgo.Indicators;
using System.Collections.Generic;
// run browser
using System.Diagnostics;

//Add MySql Library
using MySql.Data.MySqlClient;

namespace cAlgo
{
    [Robot(TimeZone = TimeZones.UTC, AccessRights = AccessRights.Internet | AccessRights.FileSystem | AccessRights.FullAccess)]
    public class FxStarEu : Robot
    {
        [Parameter(DefaultValue = 1)]
        public int TimerSeconds { get; set; }

        // Mysql COnnection variables
        private MySqlConnection connection;
        private string server;
        private string database;
        private string uid;
        private string password;



        protected override void OnStart()
        {
            Timer.Start(TimerSeconds);
            //start timer with 1 second interval

            // MYSQL TABLES            
            //create table account(id INT NOT NULL AUTO_INCREMENT,time int, accountid int, balance float(10,2),equity float(10,2),margin float(10,2),freemargin float(10,2), currency varchar(20), leverage int, PRIMARY KEY(id));
            server = "localhost";
            database = "fxstar";
            uid = "user";
            password = "pass";
            string connectionString;
            connectionString = "SERVER=" + server + ";" + "DATABASE=" + database + ";" + "UID=" + uid + ";" + "PASSWORD=" + password + ";";
            connection = new MySqlConnection(connectionString);

        }
        protected override void OnTimer()
        {
            try
            {
                connection.Open();
            } catch (MySqlException ex)
            {

                //0: Cannot connect to server.
                //1045: Invalid user name and/or password.

                switch (ex.Number)
                {
                    case 0:
                        Print("Cannot connect to server.  Contact administrator");
                        break;

                    case 1045:
                        Print("Invalid username/password, please try again");
                        break;
                    default:
                        Print("Connected");
                        break;
                }

            }

            try
            {
                PositionsAdd();
            } catch (Exception ee)
            {
                Print(ee);
            }

            connection.Close();
        }

        protected override void OnBar()
        {

            try
            {
                connection.Open();
            } catch (MySqlException ex)
            {

                //0: Cannot connect to server.
                //1045: Invalid user name and/or password.

                switch (ex.Number)
                {
                    case 0:
                        Print("Cannot connect to server.  Contact administrator");
                        break;

                    case 1045:
                        Print("Invalid username/password, please try again");
                        break;
                    default:
                        Print("Connected");
                        break;
                }

            }

            // GBPJPY OHLC
            try
            {
                Insert("GBPJPY");
            } catch (Exception ee)
            {
                Print(ee);
            }

            try
            {
                Balance();
            } catch (Exception ee)
            {
                Print(ee);
            }
            connection.Close();
        }

        //====================================================================================================================
        // Insert()
        //====================================================================================================================
        public void Insert(string Currency = "GBPJPY")
        {
            /*
            private Regression cog;
            cog = Indicators.GetIndicator<Regression>(3, 2000, 2);
            double up = cog.sqh.LastValue;
            double zero = cog.prc.LastValue;
            double dn = cog.sql.LastValue;
            Print("Regression: " + up + " low " + dn);
            */

            // Current UNIX timestamp
            //Int32 Stamp = (Int32)(DateTime.UtcNow.Subtract(new DateTime(1970, 1, 1))).TotalSeconds;

            MarketSeries data = MarketData.GetSeries(Currency, TimeFrame.Weekly);
            DataSeries series = data.Close;
            int index = series.Count - 1;

            double close = data.Close[index];
            double high = data.High[index];
            double low = data.Low[index];
            double open = data.Open[index];
            Int32 opentime = (Int32)(data.OpenTime[index].Subtract(new DateTime(1970, 1, 1))).TotalSeconds;

            Print(open);

            //string query = "INSERT INTO account (time, accountid, balance, equity) VALUES('" + Stamp + "','" + Account.Number + "', '" + Account.Balance + "', '" + Account.Equity + "')";
            string query = "INSERT INTO " + Currency + " (time, open, close, low, high) VALUES('" + opentime + "','" + open + "', '" + close + "', '" + low + "', '" + high + "')";

            //create command and assign the query and connection from the constructor
            MySqlCommand cmd = new MySqlCommand(query, connection);

            //Execute command
            cmd.ExecuteNonQuery();
        }

        //====================================================================================================================
        // Balance()
        //====================================================================================================================
        public void Balance()
        {
            Int32 Stamp = (Int32)(DateTime.UtcNow.Subtract(new DateTime(1970, 1, 1))).TotalSeconds;
            string query = "INSERT INTO account (time, accountid, balance, equity, margin, freemargin, currency, leverage) VALUES('" + Stamp + "','" + Account.Number + "', '" + Account.Balance + "', '" + Account.Equity + "', '" + Account.Margin + "', '" + Account.FreeMargin + "', '" + Account.Currency + "', '" + Account.Leverage + "')";
            MySqlCommand cmd = new MySqlCommand(query, connection);
            cmd.ExecuteNonQuery();
            Print("Account balance added.");
        }

        //====================================================================================================================
        // PositionAdd()                                                                                         
        //====================================================================================================================
        public void PositionsAdd()
        {
            foreach (var position in Positions)
            {

                // BUY positions
                if (position.TradeType == TradeType.Buy)
                {
                    Int32 EntryTime = (Int32)(position.EntryTime.Subtract(new DateTime(1970, 1, 1))).TotalSeconds;

                    double? sl = position.StopLoss;
                    if (sl == null)
                    {
                        sl = 0;
                    }
                    double? tp = position.TakeProfit;
                    if (tp == null)
                    {
                        tp = 0;
                    }

                    string query = "INSERT INTO OpenSignal (id, symbol, volume, type, opent, openp, account, sl, tp) VALUES('" + position.Id + "','" + position.SymbolCode + "', '" + position.Volume + "','BUY','" + EntryTime + "','" + position.EntryPrice + "','" + Account.Number + "','" + sl + "','" + tp + "') ON DUPLICATE KEY UPDATE sl='" + sl + "', tp='" + tp + "'";

                    try
                    {
                        MySqlCommand cmd = new MySqlCommand(query, connection);
                        cmd.ExecuteNonQuery();
                        Print("Add Position " + position.Id);
                    } catch
                    {
                        Print("Error BUY " + position.Id);
                    }


                }

                // SELL positions
                if (position.TradeType == TradeType.Sell)
                {
                    Int32 EntryTime = (Int32)(position.EntryTime.Subtract(new DateTime(1970, 1, 1))).TotalSeconds;

                    //string query = "INSERT INTO OpenSignal (id, symbol, volume, type, opent, openp, account) VALUES('" + position.Id + "','" + position.SymbolCode + "', '" + position.Volume + "','SELL','" + EntryTime + "','" + position.EntryPrice + "','" + Account.Number + "')";

                    double? sl = position.StopLoss;
                    if (sl == null)
                    {
                        sl = 0;
                    }
                    double? tp = position.TakeProfit;
                    if (tp == null)
                    {
                        tp = 0;
                    }

                    string query = "INSERT INTO OpenSignal (id, symbol, volume, type, opent, openp, account, sl, tp) VALUES('" + position.Id + "','" + position.SymbolCode + "', '" + position.Volume + "','SELL','" + EntryTime + "','" + position.EntryPrice + "','" + Account.Number + "','" + sl + "','" + tp + "') ON DUPLICATE KEY UPDATE sl='" + sl + "', tp='" + tp + "'";
                    try
                    {
                        MySqlCommand cmd = new MySqlCommand(query, connection);
                        cmd.ExecuteNonQuery();
                        Print("Add Position " + position.Id);
                    } catch
                    {
                        Print("Error SELL " + position.Id);
                    }
                }

            }


            foreach (HistoricalTrade tr in History)
            {
                // this month closed positions
                if (DateTime.Now.Month == tr.EntryTime.Month)
                {
                    if (tr.TradeType == TradeType.Sell || tr.TradeType == TradeType.Buy)
                    {
                        Int32 EntryTime = (Int32)(tr.EntryTime.Subtract(new DateTime(1970, 1, 1))).TotalSeconds;

                        string query = "INSERT INTO CloseSignal (id, closet, closep, profit, pips, account) VALUES('" + tr.PositionId + "','" + EntryTime + "','" + tr.EntryPrice + "','" + tr.NetProfit + "','" + tr.Pips + "','" + Account.Number + "')";

                        try
                        {
                            MySqlCommand cmd = new MySqlCommand(query, connection);
                            cmd.ExecuteNonQuery();
                            Print("Close Position " + tr.PositionId);
                        } catch
                        {
                            Print("Duplicate close position" + tr.PositionId);
                        }
                    }
                }
            }
        }
    }
}

/*
    // RUN WEB BROWSER with my web page
    ProcessStartInfo psi = new ProcessStartInfo();
    psi.FileName = "IExplore.exe";
    psi.Arguments = "forex.fxstar.eu";            
    Process.Start(psi);
*/
