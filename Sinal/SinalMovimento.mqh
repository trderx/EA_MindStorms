extern string SensorMovimentoConfig__ = "-----------------------------Sensor Movimento--------------------";
input bool EnableSensorMovimento = true;        //Enable SensorMovimento
input ENUM_TIMEFRAMES InpSensorMovimento = PERIOD_H4;      // Sensor Movimento TimeFrame

bool SinalMovimento()
{
    int vRet = 0;

    if (!EnableSensorMovimento)
       vRet;


    double vDiffAtualL = iClose(NULL, InpSensorMovimento, 0)  - iLow(NULL, InpSensorMovimento, 0);
    double vDiffAtualH = iHigh(NULL, InpSensorMovimento, 1) - iClose(NULL, InpSensorMovimento, 0);
   
    double vDiffAnt = iHigh(NULL, InpSensorMovimento, 1) - iLow(NULL, InpSensorMovimento, 1);
    
    double vPercentH = vDiffAtualL*100/vDiffAnt;
    double vPercentL = vDiffAtualH*100/vDiffAnt;

    if(vPercentL > 100 ) 
        vRet= -1;

     if(vPercentH > 100 ) 
        vRet= 1;

   Comment(vRet);
    return vRet;

}
