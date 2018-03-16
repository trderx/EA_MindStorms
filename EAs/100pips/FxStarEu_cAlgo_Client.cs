using System;
using System.Linq;
using cAlgo.API;
using cAlgo.API.Indicators;
using cAlgo.API.Internals;
using cAlgo.Indicators;
using System.Collections.Generic;
// run browser
using System.Diagnostics;
using System.IO;

//Add MySql Library
using MySql.Data.MySqlClient;

namespace cAlgo
{
    [Robot(TimeZone = TimeZones.UTC, AccessRights = AccessRights.Internet | AccessRights.FileSystem | AccessRights.FullAccess)]
    public class FxStarEu_Client : Robot
    {
        [Parameter(DefaultValue = 1)]
        public int TimerSeconds { get; set; }

        [Parameter(DefaultValue = 1)]
        public int SignalId { get; set; }

        [Parameter(DefaultValue = 0.1)]
        public double Percent { get; set; }

        [Parameter(DefaultValue = "user")]
        public string User { get; set; }

        [Parameter(DefaultValue = "pass")]
        public string Password { get; set; }

        public string path;

        // Mysql Connection variables
        private MySqlConnection connection;
        private string server;
        private string database;

        protected override void OnStart()
        {
            Timer.Start(TimerSeconds);

            // Create robot folder
            path = "c:\\cBot" + Account.Number;
            System.IO.Directory.CreateDirectory(path);

            //mysql            
            server = "localhost";
            database = "fxstar";

            string connectionString;
            connectionString = "SERVER=" + server + ";" + "DATABASE=" + database + ";" + "UID=" + User + ";" + "PASSWORD=" + Password + ";";
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

            Select();
            connection.Close();
        }



        public bool CreateFile(string fileName = "1234567890")
        {
            string path1 = "";
            path1 = path + "\\" + fileName + ".POS";
            if (!System.IO.File.Exists(path1))
            {
                try
                {
                    System.IO.FileStream fs = System.IO.File.Create(path1);
                } catch (DirectoryNotFoundException e)
                {
                    Print(e);
                }
                return false;
            }
            else
            {
                Print("File \"{0}\" already exists.", fileName);
                return true;
            }
        }


//Select statement
        public List<string>[] Select()
        {
            string query = "SELECT * FROM opensignal";

            //Create a list to store the result
            List<string>[] list = new List<string>[9];
            string[][] arr = new string[20][];
            for (int x = 0; x < arr.Length; x++)
            {
                arr[x] = new string[8];
            }

            list[0] = new List<string>();
            list[1] = new List<string>();
            list[2] = new List<string>();
            list[3] = new List<string>();
            list[4] = new List<string>();
            list[5] = new List<string>();
            list[6] = new List<string>();
            list[7] = new List<string>();
            list[8] = new List<string>();

            MySqlCommand cmd = new MySqlCommand(query, connection);
            MySqlDataReader dataReader = cmd.ExecuteReader();

            int nr = 0;
            while (dataReader.Read())
            {
                // Console.WriteLine("\t{0}\t{1}", reader.GetInt32(0), reader.GetString(1));
                /// SET POSITION HERE DONT INSERT IN ARRAY
                /// create file with position or check is exist position with label in history or open positions

                arr[nr][0] = "" + dataReader["id"];
                arr[nr][1] = "" + dataReader["symbol"];
                arr[nr][2] = "" + dataReader["volume"];
                arr[nr][3] = "" + dataReader["type"];
                arr[nr][4] = "" + dataReader["opent"];
                arr[nr][5] = "" + dataReader["openp"];
                arr[nr][6] = "" + dataReader["sl"];
                arr[nr][7] = "" + dataReader["tp"];

                if (!CreateFile("" + dataReader["id"]))
                {
                    Symbol sym = MarketData.GetSymbol("" + dataReader["symbol"]);
                    //ExecuteMarketOrder(TradeType.Buy, sym, (Int32)dataReader["volume"], (string)dataReader["id"]);
                    Print("Utwórz pozycję" + dataReader["id"]);

                }
                //Print(arr[nr][1]);

                nr++;

                //Print(dataReader["id"]);
                list[0].Add(dataReader["id"] + "");
                list[1].Add(dataReader["symbol"] + "");
                list[2].Add(dataReader["volume"] + "");
                list[3].Add(dataReader["type"] + "");
                list[4].Add(dataReader["opent"] + "");
                list[5].Add(dataReader["sl"] + "");
                list[6].Add(dataReader["tp"] + "");
                list[7].Add(dataReader["time"] + "");
                list[8].Add(dataReader["account"] + "");
            }
            dataReader.Close();

            foreach (string[] dd in arr)
            {
                if (dd[0] != null)
                    Print("POS " + dd[0]);

            }
            // Loop over list elements using foreach-loop.
            foreach (List<string> element in list)
            {
                //Print("ELEMENT " + element);
                string line = string.Join(",", element.ToArray());
                //Print("POZYCJA ============================= " + line);
                //Print(element.ElementAt(0));
                foreach (string pos in element)
                {
                    //Print(pos);
                }
            }

            return list;
        }



    }
}

/*
    // RUN WEB BROWSER with my web page
    ProcessStartInfo psi = new ProcessStartInfo();
    psi.FileName = "IExplore.exe";
    psi.Arguments = "forex.fxstar.eu";            
    Process.Start(psi);


Arrays :
https://msdn.microsoft.com/en-us/library/aa288453%28v=vs.71%29.aspx
*/
