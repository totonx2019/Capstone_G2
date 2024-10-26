//+------------------------------------------------------------------+
//| Class: sntData - To store tick data and custom indicators        |
//+------------------------------------------------------------------+
#ifndef B1Data_MQH  // Check if MQH is not defined
#define B1Data_MQH  // Define MQH
//+------------------------------------------------------------------+
#include "..\2Lib\A0Enum.mqh"
#include "..\2Lib\A1External.mqh"

//+------------------------------------------------------------------+
class CsntData {
private:
    uchar  chr_MA_S08;
    uchar  chr_MA_L14;
    uchar  chr_MA_S20;
    uchar  chr_MA_L55;

    uchar  chr_MaxBar;
    uchar  chr_MaxBuff;
    double dbl_TMABand;
    string DeCrypt(string text);    

    //OnInit
    void CheckHistoricalBarOnInit();
    void SetVariableOnInit();
    void SetBufArrayOnInit(char iTF);
    void SetBarArrayOnInit(char iTF);
    void SetPnTArrayOnInit(char iTF);
    void UpdateLicense();
    void DrawCurveOnInit(double &array[]);
    
    //OnDeinit
    void FreeVariableOnDeinit();
    
    //OnTimer
    char CheckLicense(char chrCase);

    //OnTick
    char CheckTimeBarOnTick(char iTF);
    void UpdateDataOnTick(char iTF);
    
    //OnNewBar
    void UpdateDataOnNewBar(char iTF);
    void MoveArrayOnNewBar(char iTF);
    void UpdateSymbolTickFactor();
    void UpdateSystemBalance();    
    void DrawPointOnNewBar(double &array[]);

protected://service class, doesn't need to inherit
public:
    CsntData();
    ~CsntData();
    void OnInit();
    void OnDeinit();
    void OnTimer();
    void OnTick();
    void OnNewBar();

    //++++++++++++++
    //mutable sys_Status SStatus;
    sys_Status SStatus;
    sys_Input  SInput;
    sys_Config SConfig;
    nav_Value NValue[8]; //Max = 8TF per ENUM_TIME
};

//+------------------------------------------------------------------+
//Start Class Body
//+------------------------------------------------------------------+

// Constructor
CsntData::CsntData() {
    // Initialize bot-specific data here
    SStatus.LicenseStatus = -1;
    SStatus.str_ExpireDate = "1111.11.11 11:11";

    this.chr_MA_S08   = 08;
    this.chr_MA_L14   = 13;
    this.chr_MA_S20   = 20;
    this.chr_MA_L55   = 55;
    this.chr_MaxBar   = 10;  //usable = 10, arraySize = 11
    this.chr_MaxBuff  = this.chr_MA_L55*2;
    this.dbl_TMABand  = 2.8;
    
    switch (_Period) {
      case PERIOD_M1:   SStatus.TFCUR = TF01;   break;
      case PERIOD_M5:   SStatus.TFCUR = TF05;   break;
      case PERIOD_M15:  SStatus.TFCUR = TF15;   break;
      case PERIOD_M30:  SStatus.TFCUR = TF30;   break;
      case PERIOD_H1:   SStatus.TFCUR = TF60;   break;
      case PERIOD_H4:   SStatus.TFCUR = TFH4;   break;
      case PERIOD_D1:   SStatus.TFCUR = TFD1;   break;
      default:          SStatus.TFCUR = TFW1;   break;
    }//switch
}

// Destructor
CsntData::~CsntData() {
    // Cleanup resources if necessary
}

string CsntData::DeCrypt(string text) {
    uchar src[],dst[],key[];
    StringToCharArray("",key,0,StringLen(""));
    StringToCharArray(text,dst,0,StringLen(text));

    int res=CryptDecode(CRYPT_BASE64,dst,key,src);
    if(res>0) return(CharArrayToString(src)); else return("");
}

//+------------------------------------------------------------------+

void CsntData::OnInit() {
    CheckHistoricalBarOnInit();
    SetVariableOnInit();
    #ifdef SNTDEBUG
      DrawCurveOnInit(NValue[SStatus.TFCUR].bar_TMAH);
    #endif   
    
    UpdateLicense();
    UpdateSymbolTickFactor();
    UpdateSystemBalance();
}

#ifdef __MQL5__
void CsntData::CheckHistoricalBarOnInit() {
    int requiredBars = 100;  // Number of bars needed for the indicator calculations

    // Loop through all available timeframes stored in NValue
    for (int iTF = 0; iTF < ArraySize(NValue); iTF++) {
        string strSymbol = SConfig.str_Symbol;
        ENUM_TIMEFRAMES timeframe = NValue[iTF].int_TimeFrame;  // Get the timeframe for this iteration

        int availableBars = Bars(strSymbol,timeframe);    
        if (availableBars < requiredBars) {
            Print("Not enough bars available for timeframe ", timeframe, ". Requesting more data...");
            
            MqlRates rates[];  // Create an array to store OHLC data
            CopyRates(strSymbol, timeframe, 0, requiredBars, rates);
            availableBars = Bars(strSymbol,timeframe);
        }//if
    }//for    
}
#else
void CsntData::CheckHistoricalBarOnInit() {
    int requiredBars = 100;  // Number of bars needed for the indicator calculations

    // Loop through all available timeframes stored in NValue
    for (int iTF = 0; iTF < ArraySize(NValue); iTF++) {
        string strSymbol = SConfig.str_Symbol;
        int timeframe = NValue[iTF].int_TimeFrame;  // Get the timeframe for this iteration

        int availableBars = iBars(strSymbol, timeframe);  // Get the available bars for the current timeframe
        if (availableBars < requiredBars) {
            Print("Not enough bars available for timeframe ", timeframe, ". Requesting more data...");

            // Trigger data loading by accessing past bars using iTime (forces loading historical bars)
            for (int i = availableBars; i < requiredBars; i++) {
                iTime(strSymbol, timeframe, i);  // Access older bars to force data loading
            }

            // Optional: Add RefreshRates() to ensure the latest data is loaded
            RefreshRates();
        }//if
    }//for
}
#endif 

void CsntData::SetVariableOnInit() {
    //assum data from iData: old 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 new
    //iMAonArray will work from right to left as always

    //1) series array normal order 
    //index: [0]   [1]   [2]   [3]   [4]   [5]   [6]   [7]   [8]   [9]
    //Data:   1     2     3     4     5     6     7     8     9    10
    //sort:  [9]   [8]   [7]   [6]   [5]   [4]   [3]   [2]   [1]   [0]
    //value:  10     9     8     7     6     5     4     3     2     1
    //iMAonArray = 2.00

    //2) non series array normal order
    //index: [0]   [1]   [2]   [3]   [4]   [5]   [6]   [7]   [8]   [9]
    //Data:   1     2     3     4     5     6     7     8     9    10
    //sort:  [0]   [1]   [2]   [3]   [4]   [5]   [6]   [7]   [8]   [9]
    //value:   1     2     3     4     5     6     7     8     9    10
    //iMAonArray = 9.00
    
    //3) series array reverse order
    //index: [0]   [1]   [2]   [3]   [4]   [5]   [6]   [7]   [8]   [9]
    //Data:  10     9     8     7     6     5     4     3     2     1
    //sort:  [9]   [8]   [7]   [6]   [5]   [4]   [3]   [2]   [1]   [0]
    //value:   1     2     3     4     5     6     7     8     9    10
    //iMAonArray = 9.00
    
    //4) non series array reverse order
    //index: [0]   [1]   [2]   [3]   [4]   [5]   [6]   [7]   [8]   [9]
    //Data:  10     9     8     7     6     5     4     3     2     1
    //sort:  [0]   [1]   [2]   [3]   [4]   [5]   [6]   [7]   [8]   [9]
    //value:  10     9     8     7     6     5     4     3     2     1
    //iMAonArray = 2.00

    SConfig.str_Symbol = Symbol();
    string Cstr_Symbol= SConfig.str_Symbol;    
    
    //++++++++++++++
    //20210718: Disable, move to use P2D conversion
    //if (Digits % 2 == 1) SConfig.dbl_PIPxPoint = 10; //for human-PIP convert to point
    //else SConfig.dbl_PIPxPoint = 1;
    #ifdef __MQL4__
      SConfig.dbl_MaxLot  = MarketInfo(Cstr_Symbol, MODE_MAXLOT);
      SConfig.dbl_MinLot  = MarketInfo(Cstr_Symbol, MODE_MINLOT);
      SConfig.dbl_LotStep = MarketInfo(Cstr_Symbol, MODE_LOTSTEP);//20210723 : fix RoboForex min lot 0.1 mislead lot step
    #else
      SConfig.dbl_MaxLot  = SymbolInfoDouble(Cstr_Symbol, SYMBOL_VOLUME_MAX);
      SConfig.dbl_MinLot  = SymbolInfoDouble(Cstr_Symbol, SYMBOL_VOLUME_MIN);
      SConfig.dbl_LotStep = SymbolInfoDouble(Cstr_Symbol, SYMBOL_VOLUME_STEP); // Fix RoboForex min lot 0.1 mislead lot step
    #endif 

    SConfig.int_DigitLot = (int)(-MathLog10(SConfig.dbl_LotStep));
    /*keep old version for bug monitor
    //SConfig.int_DigitLot = (int)(-MathLog10(SConfig.dbl_LotStep) + 0.5);    
    //if (SConfig.dbl_LotStep == 0.001) SConfig.int_DigitLot = 3;
    //if (SConfig.dbl_LotStep ==  0.01) SConfig.int_DigitLot = 2;
    //if (SConfig.dbl_LotStep ==   0.1) SConfig.int_DigitLot = 1;
    //if (SConfig.dbl_LotStep ==   1.0) SConfig.int_DigitLot = 0;
    */

    SConfig.chr_MaxRetries = 5;
    SConfig.int_Slippage = 500;    

    //TAXES
    //??if (StringFind(AccountCompany(),"TopTrader",0) > 0) SConfig.dbl_Taxes = 0.07;
    //??else SConfig.dbl_Taxes = 0.00;
    if (AccountInfoString(ACCOUNT_CURRENCY)=="THB") SConfig.dbl_Taxes = 0.07;
    else SConfig.dbl_Taxes = 0.00;    

    //++++++++++++++
    //SConfig.str_Symbol    
    //SConfig.SInput.AdjPoint    
    NValue[TF01].int_TimeFrame = PERIOD_M1;
    NValue[TF05].int_TimeFrame = PERIOD_M5;
    NValue[TF15].int_TimeFrame = PERIOD_M15;
    NValue[TF30].int_TimeFrame = PERIOD_M30;
    NValue[TF60].int_TimeFrame = PERIOD_H1;
    NValue[TFH4].int_TimeFrame = PERIOD_H4;
    NValue[TFD1].int_TimeFrame = PERIOD_D1;
    NValue[TFW1].int_TimeFrame = PERIOD_W1;
    
    //==========================================    
    //Loop for TimeFrame Array
    for (char iTF = 0; iTF < ArraySize(NValue); iTF++) {//8TF, 0..7
        //20210625: re-order array index
        //NValue[iTF].MaxAr = this.chr_MaxBar;
        
        //MaxAr+1 to get 11AR, 0..10, assing [10] = current value
        //20210625: MaxAr+1 to get 11AR, 0..10, assign [00] = current value 
        // Resize and set arrays as series for tick data
        if (!ArrayResize(NValue[iTF].tck_ATRX, this.chr_MaxBuff, 2) ||
            !ArrayResize(NValue[iTF].tck_ATRV, this.chr_MaxBuff, 2) ||
            !ArrayResize(NValue[iTF].tck_ATRP, this.chr_MaxBuff, 2) ||
            !ArrayResize(NValue[iTF].tck_MACDV, this.chr_MaxBuff, 2)) {
            Print("Error resizing tick data arrays for TF: ", NValue[iTF].int_TimeFrame);
            continue;
        }
        ArraySetAsSeries(NValue[iTF].tck_ATRX, true);
        ArraySetAsSeries(NValue[iTF].tck_ATRV, true);
        ArraySetAsSeries(NValue[iTF].tck_ATRP, true);
        ArraySetAsSeries(NValue[iTF].tck_MACDV, true);
        
        //++++++++++++++
        // Resize and set arrays as series for buffer data
        if (!ArrayResize(NValue[iTF].buf_HLpct, this.chr_MaxBuff, 2) ||
            !ArrayResize(NValue[iTF].buf_SDL, this.chr_MaxBuff, 2) ||
            !ArrayResize(NValue[iTF].buf_ATR, this.chr_MaxBuff, 2) ||
            !ArrayResize(NValue[iTF].buf_HMAL, this.chr_MaxBuff, 2) ||
            !ArrayResize(NValue[iTF].buf_HMAS, this.chr_MaxBuff, 2) ||
            !ArrayResize(NValue[iTF].buf_DCW, this.chr_MaxBuff, 2)) {
            Print("Error resizing buffer data arrays for TF: ", NValue[iTF].int_TimeFrame);
            continue;
        }
        ArraySetAsSeries(NValue[iTF].buf_HLpct, true);
        ArraySetAsSeries(NValue[iTF].buf_SDL, true);
        ArraySetAsSeries(NValue[iTF].buf_ATR, true);
        ArraySetAsSeries(NValue[iTF].buf_HMAL, true);
        ArraySetAsSeries(NValue[iTF].buf_HMAS, true);
        ArraySetAsSeries(NValue[iTF].buf_DCW, true);
  
        //++++++++++++++
        // Resize and set arrays as series for bar data
        if (!ArrayResize(NValue[iTF].bar_TMAH, this.chr_MaxBar + 1, 2) ||
            !ArrayResize(NValue[iTF].bar_TMAL, this.chr_MaxBar + 1, 2) ||
            !ArrayResize(NValue[iTF].bar_HLpct, this.chr_MaxBar + 1, 2) ||
            !ArrayResize(NValue[iTF].bar_ATRL, this.chr_MaxBar + 1, 2) ||
            !ArrayResize(NValue[iTF].bar_HMAL, this.chr_MaxBar + 1, 2) ||
            !ArrayResize(NValue[iTF].bar_HMAS, this.chr_MaxBar + 1, 2) ||
            !ArrayResize(NValue[iTF].bar_MACDVSig, this.chr_MaxBar + 1, 2) ||
            !ArrayResize(NValue[iTF].bar_DCWL, this.chr_MaxBar + 1, 2) ||
            !ArrayResize(NValue[iTF].bar_Peak, this.chr_MaxBar + 1, 2) ||
            !ArrayResize(NValue[iTF].bar_Trough, this.chr_MaxBar + 1, 2)) {
            Print("Error resizing bar data arrays for TF: ", NValue[iTF].int_TimeFrame);
            continue;
        }
        ArraySetAsSeries(NValue[iTF].bar_TMAH, true);
        ArraySetAsSeries(NValue[iTF].bar_TMAL, true);
        ArraySetAsSeries(NValue[iTF].bar_HLpct, true);
        ArraySetAsSeries(NValue[iTF].bar_ATRL, true);
        ArraySetAsSeries(NValue[iTF].bar_HMAL, true);
        ArraySetAsSeries(NValue[iTF].bar_HMAS, true);
        ArraySetAsSeries(NValue[iTF].bar_MACDVSig, true);
        ArraySetAsSeries(NValue[iTF].bar_DCWL, true);
        ArraySetAsSeries(NValue[iTF].bar_Peak, true);
        ArraySetAsSeries(NValue[iTF].bar_Trough, true);
  
        //++++++++++++++
        //Reset data with loop for iTF
        SetBufArrayOnInit(iTF);
        SetBarArrayOnInit(iTF);
        SetPnTArrayOnInit(iTF);
  
        //++++++++++++++
        //use iTF loop to initial NewBar
        NValue[iTF].dt_Bar0 = 0;
        CheckTimeBarOnTick(iTF);
    }//for iTF    
}

void CsntData::SetBufArrayOnInit(char iTF) {
    //indy array store [0] as newest value
    //buffer array store [max] as newest value > easier to use iMAonArray
    //++++++++++++++    
    //store array from left to right, easy to use iMAonArray the newest data must be at MaxArray and oldest must be [0]
	  //      Bar9  Bar8  Bar7  Bar6  Bar5  Bar4  Bar3  Bar2  Bar1  Bar0 << command use this bar for iMAonArray
    //Array [0]   [1]	  [2]   [3]   [4]   [5]   [6]   [7]   [8]   [9]
    //	    new									                                  old  << indy array sorting direction
    //	    old									                                  new  << buffer array sorting direction
    //data 	 1     2     3     4     5     6     7     8     9     10  << iMAOnArray(ar,0,2,0,MODE_SMA,0) = 9.5
    //ArrayCopy.Buffer order to 0,1,0 (dst,src,whole) back to front    << can use whole size for (0,1,0)
    //copy1	 2     3     4     5     6     7     8     9     10     0  << iMAOnArray(ar,0,2,0,MODE_SMA,0) = 5.0
    //ArrayCopy.Indy order to 1,0,0 (dst,src,srcSize-1) front to back  << Use srcSize to get correct MA in series
    //copy2	 0     1     2     3     4     5     6     7     8      9  << iMAOnArray(ar,0,2,0,MODE_SMA,0) = 8.5
    //In this code iMAonArray can use with Buff only, except MACDV copy 0,9 to arTemp
    //iStdDevOnArray also calculate in same of Buffer array

    string Cstr_Symbol= SConfig.str_Symbol;
    double dbl_Value;
    //++++++++++++++    
    //Fill default bar Array
    dbl_Value = iStdDev(Cstr_Symbol,NValue[iTF].int_TimeFrame,20,0,MODE_SMA,PRICE_CLOSE,0);
    ArrayInitialize(NValue[iTF].buf_SDL,dbl_Value);
    
    dbl_Value = iATR(Cstr_Symbol,NValue[iTF].int_TimeFrame,14,0);
    //20240805: change back from 5 to 14,switch to use SDATR
    //20240323: change from 14 to 5, would like to get more swing, not smoothen
    ArrayInitialize(NValue[iTF].buf_ATR,dbl_Value);
    
    dbl_Value = 2*iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,(int)MathFloor(this.chr_MA_L55/2),0,MODE_SMMA,PRICE_OPEN,0)//20210712:change to price_open
                 -iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,this.chr_MA_L55,0,MODE_SMMA,PRICE_OPEN,0);
    ArrayInitialize(NValue[iTF].buf_HMAL,dbl_Value);
    
    dbl_Value = 2*iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,(int)MathFloor(this.chr_MA_S20/2),0,MODE_SMMA,PRICE_OPEN,0)//20210712:change to price_open
                 -iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,this.chr_MA_S20,0,MODE_SMMA,PRICE_OPEN,0);
    ArrayInitialize(NValue[iTF].buf_HMAS,dbl_Value);
    
    dbl_Value = iHigh(Cstr_Symbol,NValue[iTF].int_TimeFrame,iHighest(Cstr_Symbol,NValue[iTF].int_TimeFrame,MODE_HIGH,70,0))
               -iLow(Cstr_Symbol,NValue[iTF].int_TimeFrame,iLowest(Cstr_Symbol,NValue[iTF].int_TimeFrame,MODE_LOW,70,0));
    ArrayInitialize(NValue[iTF].buf_DCW,dbl_Value);

    //++++++++++++++
    //Fill default tick Array
    dbl_Value = (iClose(Cstr_Symbol,NValue[iTF].int_TimeFrame,0)-iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,27,0,MODE_EMA,PRICE_CLOSE,0))
                /iATR(Cstr_Symbol,NValue[iTF].int_TimeFrame,14,0);//20230718: remove *100, use as ratio rather percent
    ArrayInitialize(NValue[iTF].tck_ATRX,dbl_Value);
                                                                                                            //5 bars shift right
    dbl_Value = (iClose(Cstr_Symbol,NValue[iTF].int_TimeFrame,0)-iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,27,5,MODE_SMA,PRICE_CLOSE,0))
                /iATR(Cstr_Symbol,NValue[iTF].int_TimeFrame,14,0);//20230718: remove *100, use as ratio rather percent
    ArrayInitialize(NValue[iTF].tck_ATRV,dbl_Value);

    dbl_Value = MathMax(MathAbs(iClose(Cstr_Symbol,NValue[iTF].int_TimeFrame,0)-iLow(Cstr_Symbol,NValue[iTF].int_TimeFrame,0)),
                        MathAbs(iClose(Cstr_Symbol,NValue[iTF].int_TimeFrame,0)-iHigh(Cstr_Symbol,NValue[iTF].int_TimeFrame,0)))
                /iATR(Cstr_Symbol,NValue[iTF].int_TimeFrame,99,0);//20230718: remove *100, use as ratio rather percent
    ArrayInitialize(NValue[iTF].tck_ATRP,dbl_Value);

    dbl_Value = (iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,12,0,MODE_EMA,PRICE_CLOSE,0)-iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,26,0,MODE_EMA,PRICE_CLOSE,0))
                /iATR(Cstr_Symbol,NValue[iTF].int_TimeFrame,26,0)*100;
    ArrayInitialize(NValue[iTF].tck_MACDV,dbl_Value);

    //Fill default buf Array
    dbl_Value = (iHigh(Cstr_Symbol,NValue[iTF].int_TimeFrame,1)-iLow(Cstr_Symbol,NValue[iTF].int_TimeFrame,1))
                /iOpen(Cstr_Symbol,NValue[iTF].int_TimeFrame,1);
    ArrayInitialize(NValue[iTF].buf_HLpct,dbl_Value);
    
    //==========================================
    //update real value for tck_Array, replace init value
    //Loop to updte value, skip if data has zero div error
    for (int i=this.chr_MaxBuff-1; i>=0; i--) //loop from [199] to [0] //200-1=199
    {                                         //55-54-1=0, 55-0-1=54 >> //54-to-0
      dbl_Value = iATR(Cstr_Symbol,NValue[iTF].int_TimeFrame,14,i);
      if (dbl_Value != 0) {
        NValue[iTF].tck_ATRX[i] = (iClose(Cstr_Symbol,NValue[iTF].int_TimeFrame,i)-iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,27,0,MODE_EMA,PRICE_CLOSE,i))
                                  /dbl_Value;
                                              
        NValue[iTF].tck_ATRV[i] = (iClose(Cstr_Symbol,NValue[iTF].int_TimeFrame,i)-iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,27,5,MODE_SMA,PRICE_CLOSE,i))
                                  /dbl_Value;
      }
      
      dbl_Value = iATR(Cstr_Symbol,NValue[iTF].int_TimeFrame,99,i);
      if (dbl_Value != 0) {
        NValue[iTF].tck_ATRP[i] = MathMax(MathAbs(iClose(Cstr_Symbol,NValue[iTF].int_TimeFrame,i)-iLow(Cstr_Symbol,NValue[iTF].int_TimeFrame,i)),
                                          MathAbs(iClose(Cstr_Symbol,NValue[iTF].int_TimeFrame,i)-iHigh(Cstr_Symbol,NValue[iTF].int_TimeFrame,i)))
                                  /dbl_Value;
      }
      
      dbl_Value = iATR(Cstr_Symbol,NValue[iTF].int_TimeFrame,26,i);
      if (dbl_Value != 0) {
        NValue[iTF].tck_MACDV[i] = (iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,12,0,MODE_EMA,PRICE_CLOSE,i)-iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,26,0,MODE_EMA,PRICE_CLOSE,i))
                                   /dbl_Value*100;;
      }
      
      dbl_Value = iOpen(Cstr_Symbol,NValue[iTF].int_TimeFrame,i);
      if (dbl_Value !=0) {
        NValue[iTF].buf_HLpct[i] = (iHigh(Cstr_Symbol,NValue[iTF].int_TimeFrame,i)-iLow(Cstr_Symbol,NValue[iTF].int_TimeFrame,i))
                                   /dbl_Value;
      }
    }//for
}

void CsntData::SetBarArrayOnInit(char iTF) {
    string Cstr_Symbol= SConfig.str_Symbol;
    double dbl_Value;

    //Reset secondary data bar Array
    dbl_Value = iBands(Cstr_Symbol,NValue[iTF].int_TimeFrame,18,2.5,0,PRICE_HIGH,MODE_UPPER,0);
    ArrayInitialize(NValue[iTF].bar_TMAH,dbl_Value);
    
    dbl_Value = iBands(Cstr_Symbol,NValue[iTF].int_TimeFrame,18,2.5,0,PRICE_LOW,MODE_LOWER,0);
    ArrayInitialize(NValue[iTF].bar_TMAL,dbl_Value);
    
    //++++++++++++++
    //Generate Bar data from Buf Data    
    
    dbl_Value = iMAOnArray(NValue[iTF].buf_HLpct,0,this.chr_MA_L55,0,MODE_SMMA,0);
    ArrayInitialize(NValue[iTF].bar_HLpct,dbl_Value);

    dbl_Value = iMAOnArray(NValue[iTF].buf_ATR,0,this.chr_MA_L55,0,MODE_SMMA,0);
    ArrayInitialize(NValue[iTF].bar_ATRL,dbl_Value);

    dbl_Value = iMAOnArray(NValue[iTF].buf_HMAL,0,(int)MathFloor(MathSqrt(this.chr_MA_L55)),0,MODE_SMMA,0);
    ArrayInitialize(NValue[iTF].bar_HMAL,dbl_Value);
    
    dbl_Value = iMAOnArray(NValue[iTF].buf_HMAS,0,(int)MathFloor(MathSqrt(this.chr_MA_S20)),0,MODE_SMMA,0);
    ArrayInitialize(NValue[iTF].bar_HMAS,dbl_Value);
    
    dbl_Value = iMAOnArray(NValue[iTF].tck_MACDV,0,9,0,MODE_EMA,0); //can use iMA on non Buff only at this init
    ArrayInitialize(NValue[iTF].bar_MACDVSig,dbl_Value);
    
    dbl_Value = iMAOnArray(NValue[iTF].buf_DCW,0,this.chr_MA_L55,0,MODE_SMA,0);
    ArrayInitialize(NValue[iTF].bar_DCWL,dbl_Value);
    
    NValue[iTF].bar_ATRV_Mean = iMAOnArray(NValue[iTF].tck_ATRV,0,this.chr_MaxBuff,0,MODE_SMA,0);
    NValue[iTF].bar_ATRV_SD = iStdDevOnArray(NValue[iTF].tck_ATRV,0,this.chr_MaxBuff,0,MODE_SMA,0);      
    if (NValue[iTF].bar_ATRV_SD==0) NValue[iTF].tck_ATRVZV=0; else
    NValue[iTF].tck_ATRVZV = (NValue[iTF].tck_ATRV[0]-NValue[iTF].bar_ATRV_Mean)/NValue[iTF].bar_ATRV_SD;
}

void CsntData::SetPnTArrayOnInit(char iTF) {
    ArrayInitialize(NValue[iTF].bar_Peak,0);
    ArrayInitialize(NValue[iTF].bar_Trough,0);
    string Cstr_Symbol= SConfig.str_Symbol;    

    //==========================================
    //Find Peak n Trough, move Array when needed
    //==========================================
    double dbl_M1;
    double dbl_S1;
    double dbl_M2;
    double dbl_S2;
    
    for (int iBar = 99; iBar > 0; iBar--) {//99..1
      dbl_M1 = iStochastic(Cstr_Symbol,NValue[iTF].int_TimeFrame,30,3,5,MODE_SMA,1,MODE_MAIN,iBar);   //dbl_Main_1
      dbl_S1 = iStochastic(Cstr_Symbol,NValue[iTF].int_TimeFrame,30,3,5,MODE_SMA,1,MODE_SIGNAL,iBar); //dbl_Sign_1
      dbl_M2 = iStochastic(Cstr_Symbol,NValue[iTF].int_TimeFrame,30,3,5,MODE_SMA,1,MODE_MAIN,iBar+1);   //dbl_Main_2
      dbl_S2 = iStochastic(Cstr_Symbol,NValue[iTF].int_TimeFrame,30,3,5,MODE_SMA,1,MODE_SIGNAL,iBar+1); //dbl_Sign_2
  
      //ArrayCopy.Buffer 0,1,0 (dst,src,whole)
      //ArrayCopy.Indy   1,0,0 (dst,src,srcSize-1)

      //Peak
      if (dbl_M2 > dbl_S2 && dbl_M1 < dbl_S1) {//cross down
        //20210625: re-order array index
        NValue[iTF].bar_Peak[0] = iHigh(Cstr_Symbol,NValue[iTF].int_TimeFrame,iHighest(Cstr_Symbol,NValue[iTF].int_TimeFrame,MODE_HIGH,10,iBar));
        //20210625: change from 0,1,0 to 1,0,0
        //20240313: change from whole to MaxArray-1=this.chr_MaxBar
        ArrayCopy(NValue[iTF].bar_Peak,NValue[iTF].bar_Peak, 1, 0, this.chr_MaxBar); 
      }//if
  
      //Trough
      if (dbl_M2 < dbl_S2 && dbl_M1 > dbl_S1) {//cross up
        //20210625: re-order array index
        NValue[iTF].bar_Trough[0] = iLow(Cstr_Symbol,NValue[iTF].int_TimeFrame,iLowest(Cstr_Symbol,NValue[iTF].int_TimeFrame,MODE_LOW,10,iBar));
        //20210625: change from 0,1,0 to 1,0,0
        //20240313: change from whole to MaxArray-1=this.chr_MaxBar
        ArrayCopy(NValue[iTF].bar_Trough,NValue[iTF].bar_Trough, 1, 0, this.chr_MaxBar); 
      }//if
    }//for  
}

//+------------------------------------------------------------------+

// Cleanup logic for the bot
void CsntData::OnDeinit() {
    // Bot-specific cleanup code here
    FreeVariableOnDeinit();
}

void CsntData::FreeVariableOnDeinit() {
    // Loop through all NValue timeframes and free memory for dynamically resized arrays
    for (int iTF = 0; iTF < ArraySize(NValue); iTF++) {
        // Free arrays resized with this.chr_MaxBuff
        ArrayFree(NValue[iTF].tck_ATRX);     // Support iStdDev
        ArrayFree(NValue[iTF].tck_ATRV);     // Support iStdDev
        ArrayFree(NValue[iTF].tck_ATRP);     // Support iStdDev
        ArrayFree(NValue[iTF].tck_MACDV);    // Support iStdDev

        ArrayFree(NValue[iTF].buf_HLpct);
        ArrayFree(NValue[iTF].buf_SDL);      // No need to add +1
        ArrayFree(NValue[iTF].buf_ATR);      // No need to add +1
        ArrayFree(NValue[iTF].buf_HMAL);     // No need to add +1
        ArrayFree(NValue[iTF].buf_HMAS);     // Long buffer for same loop
        ArrayFree(NValue[iTF].buf_DCW);      // Long buffer for same loop

        // Free arrays resized with this.chr_MaxBar+1
        ArrayFree(NValue[iTF].bar_TMAH);     // Time series buffer
        ArrayFree(NValue[iTF].bar_TMAL);     // Time series buffer
        ArrayFree(NValue[iTF].bar_HLpct);    // Time series buffer
        ArrayFree(NValue[iTF].bar_ATRL);     // Time series buffer
        ArrayFree(NValue[iTF].bar_HMAL);     // Time series buffer
        ArrayFree(NValue[iTF].bar_HMAS);     // Time series buffer
        ArrayFree(NValue[iTF].bar_MACDVSig); // Time series buffer
        ArrayFree(NValue[iTF].bar_DCWL);     // Time series buffer

        ArrayFree(NValue[iTF].bar_Peak);     // Time series buffer
        ArrayFree(NValue[iTF].bar_Trough);   // Time series buffer
    }
}

//+------------------------------------------------------------------+

// Timer-based logic for this bot
void CsntData::OnTimer() {
    UpdateLicense();//>>Check expired daily    
}

void CsntData::UpdateLicense() {
    //Default value is 0, check for all case from begining
    SStatus.LicenseStatus = CheckLicense(0);
}

char CsntData::CheckLicense(char chrCase) {
    string strKeyLicense = SInput.str_KeyLicense;

    if (IsTesting()) return(1);
    if (IsOptimization()) return(1);

    string str_AccountNo = DoubleToStr(AccountNumber(),0);
    string str_GsheetURL = "https://script.google.com/macros/s/AKfycbyI1_MHrSHlZ1Dn2U4yD4c9hz459aOfSKbLmZ_xbLwwuvzaqRde5O0_gQ6kPyehWXuk/exec";

    switch (chrCase) { //use with no break command
      case 0:
        //Developer team
        //Print("Name0=",AccountName());
        //Print("check0=",AccountName()== "Narin Dispat");
        if (AccountName() == "Narin Dispat") return(1);
        if (AccountName() == "Dispat Narin") return(1);
        
        if (AccountName() == "Paweena Phansiri") return(1);
        if (AccountName() == "Phansiri Paweena") return(1);
        
        if (AccountName() == "Patpon Vatanatham") return(1);    
        if (AccountName() == "Son Sornpan") return(1);
    
        if (AccountName() == "Ekachai Kantasri") return(1);
        if (AccountName() == "Tanit Sittiyakorn") return(1);        
      
      case 1:
        //SNT IB Partner team
        //Print("check1=",AccountNumber());
        switch (AccountNumber()) {
          case 484489:   //Suntorn 4pip
          case 8141329:  //Exness-Demo
          case 9321283:  //Jejira-1
          case 846099:   //Jejira-2
          case 3195719:  //Supa-1
          case 1249276:  //Supa-2
          case 1249848:  //Supa-3
          case 1250050:  //Supa-4
          case 1250054:  //Supa-5
          case 10547260: //GMI jidapah.19@gmail.com      
    
          case 10545272: //GMI jajira@gmail.com
          case 10547343: //GMI jajira@gmail.com
          
          case 10544952: //GMI kkung31@gmail.com
          case 13003401: //GMI kkung31@gmail.com
          case 4528784:  //GMI kkung31@gmail.com      
          case 30087991: //RBFX kkung31@gmail.com
          case 30104086: //RBFX kkung31@gmail.com

            Print("License1 VIP is correct : ", SStatus.str_ExpireDate);
            return(1);
        }//end of accout switch
      
      case 2:
        //Read from google sheet here
        //Print("check2=",SConfig.SStatus.str_ExpireDate);        
        {
          string send = str_GsheetURL+"?path=/product/"+str_AccountNo;
          string reply = "error";
          #ifdef NODLL
              GrabWeb();
          #else
              if (IsDllsAllowed()) GrabWeb(send,reply); else Alert("DLL is not allowed");
          #endif //NODLL
          
          if(StringFind(reply,"error") >= 0) Print("License2 WEB not found : ",str_AccountNo);
          else {
            /*reply example and check string find position
            {"row_":16,"#":"31012612","expire":"2222.02.02 00:00","ver":"2.514","team":"SNT"}*/
            int int_Position = StringFind(reply,"expire");
            SStatus.str_ExpireDate = StringSubstr(reply,int_Position+9,16);

            int_Position = StringFind(reply,"ver");
            string str_MaxVer = StringSubstr(reply,int_Position+6,5);
      
            if (TimeCurrent() < StringToTime(SStatus.str_ExpireDate)) {
              if (SInput.str_EA_version <= str_MaxVer) { //20230725 : add to control max version, lib v1.011
                Print("License2 WEB is correct : ", SStatus.str_ExpireDate);
                return(1);
              }//Check version

              if (SInput.str_EA_version > str_MaxVer) { //20230725 : add to control max version, lib v1.011
                Print("License2 WEB is Guest : ", SStatus.str_ExpireDate);
                return(0);
              }//Check version
            } else Print("License2 WEB expired : ", SStatus.str_ExpireDate);
          }//end of check Google Sheet
        }
      case 3:
        //Rental by account >> use key
        //Print("check3=",strKeyLicense);
        if (strKeyLicense == "") Print("License3 KEY not found : ",str_AccountNo);
        else {
          string str_DeCrypt = DeCrypt(strKeyLicense);
//          string str_Account = StringSubstr(str_DeCrypt,0,StringFind(str_DeCrypt,",",0));
//          SConfig.SStatus.str_ExpireDate = StringSubstr(str_DeCrypt,StringFind(str_DeCrypt,"#",0)+1,16);
          //Print("Decrypt",str_DeCrypt); Print("Account",str_Account); /Print("Expired",str_Expire);
          //20230728: Support shuffle position in text
          int int_StrFind = StringFind(str_DeCrypt,"*",0);//StartAccount
          string str_Account = StringSubstr(str_DeCrypt,int_StrFind+1,StringFind(str_DeCrypt,",",0)-int_StrFind-1);
          SStatus.str_ExpireDate = StringSubstr(str_DeCrypt,StringFind(str_DeCrypt,"#",0)+1,16);
          
          if (TimeCurrent() < StringToTime(SStatus.str_ExpireDate)) {
            if (str_Account == str_AccountNo) {
              Print("License3 KEY is correct : ", SStatus.str_ExpireDate);
              return(1);
            }//Rent member
            
            if (str_Account == "9999999") {
              Print("License3 KEY is Guest : ", SStatus.str_ExpireDate);
              return(0);
            }//Guest
          } else Print("License3 KEY expired : ", SStatus.str_ExpireDate);
        }//end of check license key
    }//switch for test validate case
   
   
    //++++++++++++++    
    //not match any License case
    Alert("Expired!! == sntEA STOP =="); //Can't find License in any step
    return(-1);
    //return 1 licence
    //return 0 temporary
    //return -1 expire
}

//+------------------------------------------------------------------+

// Handle strategy-specific logic per tick
void CsntData::OnTick() {
    // Define the timeframe constants array globally or within the class
    char timeframes[] = {TF01, TF05, TF15, TF30, TF60, TFH4, TFD1, TFW1};

    // Reset chr_NewBar at the beginning of each tick
    SStatus.chr_NewBar = 0;
    
    // Loop through timeframes and handle both logic: check new bars and update data
    for(int i = 0; i < ArraySize(timeframes); i++) {
        SStatus.chr_NewBar += CheckTimeBarOnTick(timeframes[i]);
        UpdateDataOnTick(timeframes[i]);
    }//for
}

char CsntData::CheckTimeBarOnTick(char iTF) {
    // Block value based on License status
    // Return -1 if the license is invalid, no data processing
    if (SStatus.LicenseStatus < 0) return 0;  
    
    // Get the current bar time for the timeframe
    datetime dt_NewBar = iTime(SConfig.str_Symbol, NValue[iTF].int_TimeFrame, 0);

    // Compare with the stored bar time
    NValue[iTF].b_NewBar = false; //reset next tick after new bar
    if (NValue[iTF].dt_Bar0 != dt_NewBar) {
        // Found a new bar
        NValue[iTF].dt_Bar0 = dt_NewBar;
        NValue[iTF].b_NewBar = true; //this is important to capture newly bar move
        return 1;  // Return 1 if a new bar is found
    }  

    // No new bar found
    return 0;  // Return 0 if no new bar is found
}

void CsntData::UpdateDataOnTick(char iTF) {
    //>>Update only last value at Ar[this.chr_MaxBar] for current live value
    //Array is in revert position 0..10,where 0 is oldest, 10 is floating
    //20210625: Array is now in forward position 0..10,where 10 is oldest, 0 is floating same as time Series
    string Cstr_Symbol= SConfig.str_Symbol;
    
    double dbl_H  = 0;
    double dbl_L  = 0;
    double dbl_R  = 0;
    double dbl_C0 = iClose(Cstr_Symbol,NValue[iTF].int_TimeFrame,0);
    double dbl_C1 = iClose(Cstr_Symbol,NValue[iTF].int_TimeFrame,1);
    double dbl_P0 = iOpen(Cstr_Symbol,NValue[iTF].int_TimeFrame,0);
    double dbl_P1 = iOpen(Cstr_Symbol,NValue[iTF].int_TimeFrame,1);

    //==========================================
    //1.Bar Value
    //------------------------------------------
    NValue[iTF].dbl_Elapsed = 1.0*(TimeCurrent()-iTime(Cstr_Symbol,NValue[iTF].int_TimeFrame,0))/NValue[iTF].int_TimeFrame/60;
    //NValue[iTF].int_Mountain = iHighest(Cstr_Symbol,NValue[iTF].int_TimeFrame,MODE_HIGH,50,1);
    //NValue[iTF].int_Valley = iLowest(Cstr_Symbol,NValue[iTF].int_TimeFrame,MODE_LOW,50,1);

    //==========================================
    //3.Calculate 
    //ATRX = (Close - EMA27 ) ÷ ATR(14) 
    //ATRV = (Close - SMA27/shift5 ) ÷ ATR(14) 
    //ATRP = (Close - low/high ) ÷ ATR(99)
    //------------------------------------------
    //20240118: fix div zero value
    double TatrT = iATR(Cstr_Symbol,NValue[iTF].int_TimeFrame,14,0);
    if (TatrT==0) NValue[iTF].tck_ATRX[0] = NValue[iTF].tck_ATRX[1]; else
    NValue[iTF].tck_ATRX[0] = (iClose(Cstr_Symbol,NValue[iTF].int_TimeFrame,0)-iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,27,0,MODE_EMA,PRICE_CLOSE,0))
                              /TatrT;//20230718: remove *100, use as ratio rather percent

    //20240805: add ATRV/ATRP inidicator
    if (TatrT==0) NValue[iTF].tck_ATRV[0] = NValue[iTF].tck_ATRV[1]; else
    NValue[iTF].tck_ATRV[0] = (iClose(Cstr_Symbol,NValue[iTF].int_TimeFrame,0)-iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,27,5,MODE_SMA,PRICE_CLOSE,0))
                              /TatrT;//20230718: remove *100, use as ratio rather percent

    TatrT = iATR(Cstr_Symbol,NValue[iTF].int_TimeFrame,99,0);    
    if (TatrT==0) NValue[iTF].tck_ATRP[0] = NValue[iTF].tck_ATRP[1]; else
    NValue[iTF].tck_ATRP[0] = MathMax(MathAbs(iClose(Cstr_Symbol,NValue[iTF].int_TimeFrame,0)-iLow(Cstr_Symbol,NValue[iTF].int_TimeFrame,0)),
                                      MathAbs(iClose(Cstr_Symbol,NValue[iTF].int_TimeFrame,0)-iHigh(Cstr_Symbol,NValue[iTF].int_TimeFrame,0)))
                              /TatrT;//20230718: remove *100, use as ratio rather percent

    //==========================================
    //4.Calculate MACDV
    //------------------------------------------
    //20240118: fix div zero value
    TatrT = iATR(Cstr_Symbol,NValue[iTF].int_TimeFrame,26,0);
    if (TatrT==0) NValue[iTF].tck_MACDV[0] = NValue[iTF].tck_MACDV[1]; else
    NValue[iTF].tck_MACDV[0] = (iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,12,0,MODE_EMA,PRICE_CLOSE,0)-iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,26,0,MODE_EMA,PRICE_CLOSE,0)) 
                               /TatrT*100;
    NValue[iTF].bar_MACDVSig[0] = iMAOnArray(NValue[iTF].tck_MACDV,0,9,0,MODE_EMA,0); //already set as Serie, use iMA[0]

    //------------------------------------------
    if (NValue[iTF].bar_ATRV_SD==0) NValue[iTF].tck_ATRVZV=0; else
    NValue[iTF].tck_ATRVZV = (NValue[iTF].tck_ATRV[0]-NValue[iTF].bar_ATRV_Mean)/NValue[iTF].bar_ATRV_SD;
}

//+------------------------------------------------------------------+

// Handle new bar event for this strategy
void CsntData::OnNewBar() {
    // Loop from 1 to chr_NewBar (1-based index for new bars)
    for (char iBar = 1; iBar <= SStatus.chr_NewBar; iBar++) {        
        char iTF = iBar-1;
        UpdateDataOnNewBar(iTF);  // Call this for each new bar
        MoveArrayOnNewBar(iTF);   // Call this for each new bar
    }
    
    // Logic that executes when a new bar is detected
    if (SStatus.chr_NewBar >= 7) UpdateSymbolTickFactor();//>>update refresh daily
    if (SStatus.chr_NewBar >= 8) UpdateSystemBalance();   //>>update refresh weekly
    
    #ifdef SNTDEBUG
      DrawPointOnNewBar(NValue[SStatus.TFCUR].bar_TMAH);
    #endif      
}

void CsntData::UpdateDataOnNewBar(char iTF) {
    string Cstr_Symbol= SConfig.str_Symbol;
    double dbl_P = 0;
    double dbl_WG = 0;
    double dbl_Point  = MarketInfo(Cstr_Symbol, MODE_POINT); //20210726: change tickSize to Point as RBFX has tickSize issue
    if (dbl_Point <= 0) dbl_Point = Point;

    NValue[iTF].int_Mountain = iHighest(Cstr_Symbol,NValue[iTF].int_TimeFrame,MODE_HIGH,50,1);
    NValue[iTF].int_Valley = iLowest(Cstr_Symbol,NValue[iTF].int_TimeFrame,MODE_LOW,50,1);
    
    //++++++++++++++    
    //Start Calucate Buffer Array
    //ArrayCopy.Buffer 0,1,0 (dst,src,whole) = push left
    //ArrayCopy.Indy   1,0,0 (dst,src,srcSize-1) = push right
    //This is array Buffer which is  for iMAonArray or iSTDonArray 
    //It will need to update [1] then copy then update [0] to correct value at new bar
    //++++++++++++++    
 
    //==========================================
    //Start from here since 20241024 : change from self reserve data to setasSerie sorting
    //Change active position from [last] to [0]
    //change copy from 0,1,0 to 1,0,0
    //==========================================
    //1.Calculate TMA Buffer
    //------------------------------------------    
    double sum  = (this.chr_MA_L55+1)*iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,1,0,MODE_SMA,PRICE_WEIGHTED,0);
    double sumw = (this.chr_MA_L55+1);

    for(int j=1, k=this.chr_MA_L55; j<=this.chr_MA_L55; j++, k--)
    {
       sum  += k*iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,1,0,MODE_SMA,PRICE_WEIGHTED,j);
       sumw += k;
    }//for
    dbl_P = sum/sumw; //dbl-p = MA mid line

    //Calculate TMA Range 
    //20241023: As a new bar, set [0] with [1] first before push array
    NValue[iTF].buf_SDL[0] = iStdDev(Cstr_Symbol,NValue[iTF].int_TimeFrame,20,0,MODE_SMA,PRICE_CLOSE,1);
    ArrayCopy(NValue[iTF].buf_SDL, NValue[iTF].buf_SDL, 1, 0, ArraySize(NValue[iTF].buf_SDL) - 1);
    NValue[iTF].buf_SDL[0] = iStdDev(Cstr_Symbol,NValue[iTF].int_TimeFrame,20,0,MODE_SMA,PRICE_CLOSE,0);
    

    sumw = this.dbl_TMABand*iMAOnArray(NValue[iTF].buf_SDL,0,this.chr_MA_L55,0,MODE_SMMA,0);
    NValue[iTF].bar_TMAH[0] = dbl_P + sumw;
    NValue[iTF].bar_TMAL[0] = dbl_P - sumw;

    //==========================================
    //2.Calculate ATR Buffer
    //------------------------------------------
    //20210712: update buff[54] with ATR[1] as there is a new bar [0] to be sure last bar is static value
    NValue[iTF].buf_ATR[0] = iATR(Cstr_Symbol,NValue[iTF].int_TimeFrame,14,1); //most rerent closed bar
    ArrayCopy(NValue[iTF].buf_ATR, NValue[iTF].buf_ATR, 1, 0, ArraySize(NValue[iTF].buf_ATR) - 1);
    NValue[iTF].buf_ATR[0] = iATR(Cstr_Symbol,NValue[iTF].int_TimeFrame,14,0); //current bar
    NValue[iTF].bar_ATRL[0] = iMAOnArray(NValue[iTF].buf_ATR,0,this.chr_MA_L55,0,MODE_SMMA,0);

    //==========================================
    //3.Calculate HMA Buffer Long
    //------------------------------------------
    NValue[iTF].buf_HMAL[0] = 2*iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,(int)MathFloor(this.chr_MA_L55/2),0,MODE_SMMA,PRICE_OPEN,0)//20210712:change to price_open
                               -iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,this.chr_MA_L55,0,MODE_SMMA,PRICE_OPEN,1);
    ArrayCopy(NValue[iTF].buf_HMAL, NValue[iTF].buf_HMAL, 1, 0, ArraySize(NValue[iTF].buf_HMAL) - 1);    
    NValue[iTF].buf_HMAL[0] = 2*iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,(int)MathFloor(this.chr_MA_L55/2),0,MODE_SMMA,PRICE_OPEN,1)//20210712:change to price_open
                               -iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,this.chr_MA_L55,0,MODE_SMMA,PRICE_OPEN,0);
    NValue[iTF].bar_HMAL[0] = iMAOnArray(NValue[iTF].buf_HMAL,0,(int)MathFloor(MathSqrt(this.chr_MA_L55)),0,MODE_SMMA,0);

    //==========================================
    //4.Calculate HMA Buffer Short
    //------------------------------------------
    NValue[iTF].buf_HMAS[0] = 2*iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,(int)MathFloor(this.chr_MA_S20/2),0,MODE_SMMA,PRICE_OPEN,1)//20210712:change to price_open
                               -iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,this.chr_MA_S20,0,MODE_SMMA,PRICE_OPEN,1);
    ArrayCopy(NValue[iTF].buf_HMAS, NValue[iTF].buf_HMAS, 1, 0, ArraySize(NValue[iTF].buf_HMAS) - 1);
    NValue[iTF].buf_HMAS[0] = 2*iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,(int)MathFloor(this.chr_MA_S20/2),0,MODE_SMMA,PRICE_OPEN,0)//20210712:change to price_open
                               -iMA(Cstr_Symbol,NValue[iTF].int_TimeFrame,this.chr_MA_S20,0,MODE_SMMA,PRICE_OPEN,0);
    //20210705: iMaOnArray can use Bar[0] as the Buffer has the reverse position at initial function
    NValue[iTF].bar_HMAS[0] = iMAOnArray(NValue[iTF].buf_HMAS,0,(int)MathFloor(MathSqrt(this.chr_MA_S20)),0,MODE_SMMA,0);

    //==========================================
    //5.Calculate DCW Buffer
    //------------------------------------------
    NValue[iTF].buf_DCW[0] = iHigh(Cstr_Symbol,NValue[iTF].int_TimeFrame,iHighest(Cstr_Symbol,NValue[iTF].int_TimeFrame,MODE_HIGH,70,1))
                             -iLow(Cstr_Symbol,NValue[iTF].int_TimeFrame,iLowest(Cstr_Symbol,NValue[iTF].int_TimeFrame,MODE_LOW,70,1));
    ArrayCopy(NValue[iTF].buf_DCW, NValue[iTF].buf_DCW, 1, 0, ArraySize(NValue[iTF].buf_DCW) - 1);
    NValue[iTF].buf_DCW[0] = iHigh(Cstr_Symbol,NValue[iTF].int_TimeFrame,iHighest(Cstr_Symbol,NValue[iTF].int_TimeFrame,MODE_HIGH,70,0))
                             -iLow(Cstr_Symbol,NValue[iTF].int_TimeFrame,iLowest(Cstr_Symbol,NValue[iTF].int_TimeFrame,MODE_LOW,70,0));
    NValue[iTF].bar_DCWL[0] = iMAOnArray(NValue[iTF].buf_DCW,0,this.chr_MA_L55,0,MODE_SMA,0);

    //==========================================
    //6.Calculate BBW Buffer
    //------------------------------------------
    //20240805: remove BBW

    //==========================================
    //7.Calculate VOLA Buffer
    //------------------------------------------
    double hlPct = (iHigh(Cstr_Symbol,NValue[iTF].int_TimeFrame,1)-iLow(Cstr_Symbol,NValue[iTF].int_TimeFrame,1))
                   /iOpen(Cstr_Symbol,NValue[iTF].int_TimeFrame,1);
    NValue[iTF].buf_HLpct[0] = hlPct;
    ArrayCopy(NValue[iTF].buf_HLpct, NValue[iTF].buf_HLpct, 1, 0, ArraySize(NValue[iTF].buf_HLpct) - 1);
    NValue[iTF].buf_HLpct[0] = hlPct;
    NValue[iTF].bar_HLpct[0] = iMAOnArray(NValue[iTF].buf_HLpct,0,this.chr_MA_L55,0,MODE_SMMA,0);

    //==========================================
    //this.chr_MaxBuff = 200, ATR200 = whole array
    NValue[iTF].bar_ATRV_Mean = iMAOnArray(NValue[iTF].tck_ATRV,0,this.chr_MA_L55,0,MODE_SMA,0);
    NValue[iTF].bar_ATRV_SD = iStdDevOnArray(NValue[iTF].tck_ATRV,0,this.chr_MA_L55,0,MODE_SMA,0);
}


void CsntData::MoveArrayOnNewBar(char iTF) {
    string Cstr_Symbol= SConfig.str_Symbol;
    //>>Update when new Bar , this is for Array Indy
    //ArrayCopy.Buffer 0,1,0 (dst,src,whole)
    //ArrayCopy.Indy   1,0,0 (dst,src,srcSize-1)
   
    //==========================================
    //Push Array by one position, use Bar[1], array[0..10], 10 = current value
    //==========================================
    //20210625: change from 0,1,0 to 1,0,0
    //20240313: change from whole to MaxArray-1=this.chr_MaxBar+1-1
    ArrayCopy(NValue[iTF].bar_TMAH, NValue[iTF].bar_TMAH, 1, 0, ArraySize(NValue[iTF].bar_TMAH) - 1);
    ArrayCopy(NValue[iTF].bar_TMAL, NValue[iTF].bar_TMAL, 1, 0, ArraySize(NValue[iTF].bar_TMAL) - 1);
    ArrayCopy(NValue[iTF].bar_HLpct, NValue[iTF].bar_HLpct, 1, 0, ArraySize(NValue[iTF].bar_HLpct) - 1);
    ArrayCopy(NValue[iTF].bar_ATRL, NValue[iTF].bar_ATRL, 1, 0, ArraySize(NValue[iTF].bar_ATRL) - 1);
    ArrayCopy(NValue[iTF].bar_HMAL, NValue[iTF].bar_HMAL, 1, 0, ArraySize(NValue[iTF].bar_HMAL) - 1);
    ArrayCopy(NValue[iTF].bar_HMAS, NValue[iTF].bar_HMAS, 1, 0, ArraySize(NValue[iTF].bar_HMAS) - 1);
    ArrayCopy(NValue[iTF].bar_MACDVSig, NValue[iTF].bar_MACDVSig, 1, 0, ArraySize(NValue[iTF].bar_MACDVSig) - 1);
    ArrayCopy(NValue[iTF].bar_DCWL, NValue[iTF].bar_DCWL, 1, 0, ArraySize(NValue[iTF].bar_DCWL) - 1);

    //++++++++++++++
    ArrayCopy(NValue[iTF].tck_ATRX, NValue[iTF].tck_ATRX, 1, 0, ArraySize(NValue[iTF].tck_ATRX) - 1);
    ArrayCopy(NValue[iTF].tck_ATRV, NValue[iTF].tck_ATRV, 1, 0, ArraySize(NValue[iTF].tck_ATRV) - 1);
    ArrayCopy(NValue[iTF].tck_ATRP, NValue[iTF].tck_ATRP, 1, 0, ArraySize(NValue[iTF].tck_ATRP) - 1);
    ArrayCopy(NValue[iTF].tck_MACDV, NValue[iTF].tck_MACDV, 1, 0, ArraySize(NValue[iTF].tck_MACDV) - 1);

    //==========================================
    //Find Peak n Trough, move Array when needed
    //==========================================
    double dbl_H = 0;
    double dbl_L = 0;
    double dbl_M = 0;
    double dbl_P = 0;
    dbl_H = iStochastic(Cstr_Symbol,NValue[iTF].int_TimeFrame,30,3,5,MODE_SMA,1,MODE_MAIN,1);   //dbl_Main_1
    dbl_L = iStochastic(Cstr_Symbol,NValue[iTF].int_TimeFrame,30,3,5,MODE_SMA,1,MODE_SIGNAL,1); //dbl_Sign_1
    dbl_M = iStochastic(Cstr_Symbol,NValue[iTF].int_TimeFrame,30,3,5,MODE_SMA,1,MODE_MAIN,2);   //dbl_Main_2
    dbl_P = iStochastic(Cstr_Symbol,NValue[iTF].int_TimeFrame,30,3,5,MODE_SMA,1,MODE_SIGNAL,2); //dbl_Sign_2

    //Peak
    //20210625: re-index
    if (dbl_M > dbl_P && dbl_H < dbl_L) {
      NValue[iTF].bar_Peak[0] = iHigh(Cstr_Symbol,NValue[iTF].int_TimeFrame,iHighest(Cstr_Symbol,NValue[iTF].int_TimeFrame,MODE_HIGH,10,1));
      ArrayCopy(NValue[iTF].bar_Peak, NValue[iTF].bar_Peak, 1, 0, ArraySize(NValue[iTF].bar_Peak) - 1);      
    }

    //Trough
    //20210625: re-index
    if (dbl_M < dbl_P && dbl_H > dbl_L) {
      NValue[iTF].bar_Trough[0] = iLow(Cstr_Symbol,NValue[iTF].int_TimeFrame,iLowest(Cstr_Symbol,NValue[iTF].int_TimeFrame,MODE_LOW,10,1));
      ArrayCopy(NValue[iTF].bar_Trough, NValue[iTF].bar_Trough, 1, 0, ArraySize(NValue[iTF].bar_Trough) - 1);
    }
}

//+------------------------------------------------------------------+

void CsntData::UpdateSystemBalance() {
    SStatus.dbl_EA_Balance = NormalizeDouble(AccountBalance(),0); //snapshort if Balance
    
    double dbl_ContractSize = MarketInfo(NULL, MODE_LOTSIZE);
    double dbl_Cost = iClose(NULL,0,0);
    SStatus.dbl_EA_Lot = SStatus.dbl_EA_Balance/dbl_Cost/dbl_ContractSize;
    
    if (SConfig.dbl_MinLot != 0) SStatus.dbl_EA_Lot = MathFloor(SStatus.dbl_EA_Lot / SConfig.dbl_MinLot)*SConfig.dbl_MinLot;
    SStatus.dbl_EA_Lot = NormalizeDouble(SStatus.dbl_EA_Lot, SConfig.int_DigitLot);
}

void CsntData::UpdateSymbolTickFactor() { 
/*
  double  PointValuePerLot(string pair="") {
     * Value in account currency of a Point of Symbol.
     * In tester I had a sale: open=1.35883 close=1.35736 (0.00147)
     * gain$=97.32/6.62 lots/147 points=$0.10/point or $1.00/pip.
     * IBFX demo/mini       EURUSD TICKVALUE=0.1 MAXLOT=50 LOTSIZE=10,000
     * IBFX demo/standard   EURUSD TICKVALUE=1.0 MAXLOT=50 LOTSIZE=100,000
     *                                  $1.00/point or $10.00/pip.
     *
     * https://forum.mql4.com/33975 CB: MODE_TICKSIZE will usually return the
     * same value as MODE_POINT (or Point for the current symbol), however, an
     * example of where to use MODE_TICKSIZE would be as part of a ratio with
     * MODE_TICKVALUE when performing money management calculations which need
     * to take account of the pair and the account currency. The reason I use
     * this ratio is that although TV and TS may constantly be returned as
     * something like 7.00 and 0.00001 respectively, I've seen this
     * (intermittently) change to 14.00 and 0.00002 respectively (just example
     * tick values to illustrate). 
    if (pair == "") pair = Symbol();
    return(  MarketInfo(pair, MODE_TICKVALUE)
           / MarketInfo(pair, MODE_TICKSIZE) ); // Not Point.
  }

Contract Size = MarketInfo(NULL, MODE_LOTSIZE)
EURUSD,TickValue: 1.00000, TickSize: 0.00001
XAUUSD,TickValue: 1.00000, TickSize: 0.01000
XAGUSD,TickValue: 5.00000, TickSize: 0.00100
AUDCAD,TickValue: 0.74300, TickSize: 0.00001 = convert AUDCAD to USD base of $0.74300
AUDJPY,TickValue: 0.89562, TickSize: 0.00100
P4D = TickValue/TickSize
Whenever we have price delta (point)
Profit = P4D*PriceDelta*OpenLot

20210719 : update definition
TickSize is minimum price change.
When TickSize changed, TickValue also subject to change.
To get correct theory, we will use P2D=TicValue/TickSize.
As of now, under MT4, we need found TickSize is not same as Point.
 
TickSize = smaller price move in one step.
TickValue = value of the tick when consider ContractSize

Example : XAGUSD has cost $5 for 1.0 lot
  * it will cost 5/0.001 = $5000 when trade 1.0 lot and price change $1.0
  * it will cost 5 when trade 1.0 lot and price change every TickSize 0.001
  * it will cost 0.05 when trade 0.01 lot and price change every TickSize 0.001
  * TickSize	TickValue	Point	LotSize
  * 0.001	    5	        0.001	5000
  * 0.002	    10	      0.001	5000 >> use TickValue/TickSize to get a correct P2D

TickSize = Point at this moment in this EA assumption
*/
    SConfig.dbl_Point = MarketInfo(SConfig.str_Symbol, MODE_POINT);

    //20210724: fix bug roboforex ticksize = 0.001 while point = 0.01 and contract = 100
    //which ticksize should be 0.01 when compare to contract size
    double dbl_TickSize = MarketInfo(SConfig.str_Symbol, MODE_TICKSIZE);
    dbl_TickSize = MathMax(dbl_TickSize,SConfig.dbl_Point);

    SConfig.dbl_P2D = MarketInfo(SConfig.str_Symbol, MODE_TICKVALUE)/dbl_TickSize;

/*
    if (MarketInfo(SConfig.str_Symbol, MODE_TICKSIZE) > 0) {
      SConfig.dbl_ContractSize = NormalizeDouble(MarketInfo(SConfig.str_Symbol, MODE_TICKVALUE)/MarketInfo(SConfig.str_Symbol, MODE_TICKSIZE),2);
      SConfig.dbl_TickSize = MarketInfo(SConfig.str_Symbol, MODE_TICKSIZE);
    }
    else {
      SConfig.dbl_ContractSize = NormalizeDouble(MarketInfo(SConfig.str_Symbol, MODE_TICKVALUE)/Point,2);
      SConfig.dbl_TickSize = 1/MathPow(10,Digits);
    }  
    
    if (MarketInfo(SConfig.str_Symbol, MODE_TICKVALUE) > 0)
      SConfig.dbl_Price4Dollar = MarketInfo(SConfig.str_Symbol, MODE_TICKSIZE)/MarketInfo(SConfig.str_Symbol, MODE_TICKVALUE);
    else SConfig.dbl_Price4Dollar = MarketInfo(SConfig.str_Symbol, MODE_TICKSIZE);
    
    if (MarketInfo(SConfig.str_Symbol,MODE_MINLOT) > 0)
      SConfig.dbl_Price4Dollar = NormalizeDouble(SConfig.dbl_Price4Dollar/MarketInfo(SConfig.str_Symbol,MODE_MINLOT),Digits);
    else SConfig.dbl_Price4Dollar = NormalizeDouble(SConfig.dbl_Price4Dollar/0.01,Digits);

    if (SConfig.chr_AccountType == 2) SConfig.dbl_Price4Dollar = SConfig.dbl_Price4Dollar/10; //mini
    if (SConfig.chr_AccountType == 3) SConfig.dbl_Price4Dollar = SConfig.dbl_Price4Dollar/100; //micro
*/    
}

#ifdef SNTDEBUG
void CsntData::DrawCurveOnInit(double &array[]) {
    string objName;
    datetime timeStart, timeEnd;
    double priceStart, priceEnd;

    // Loop through the array and draw segments between points
    for (int i = 0; i < ArraySize(array)-1; i++) {
        // Unique name for each trendline object
        objName = "CurveLine";

        // Get start and end times for the trendline (based on bar times)
        timeStart = iTime(SConfig.str_Symbol, NValue[SStatus.TFCUR].int_TimeFrame, i);      // Time of the current bar
        timeEnd = iTime(SConfig.str_Symbol, NValue[SStatus.TFCUR].int_TimeFrame, i + 1);    // Time of the previous bar

        // Get the prices (array values) for start and end points
        priceStart = array[i];  // Value of the current point
        priceEnd = array[i+1];  // Value of the previous point

        // Create the trendline if it doesn't exist
        if (ObjectFind(0, objName) == -1) {
            ObjectCreate(0, objName, OBJ_TREND, 0, timeStart, priceStart, timeEnd, priceEnd);
        }

        // Update the trendline coordinates
        ObjectSetInteger(0, objName, OBJPROP_TIME1, timeStart);
        ObjectSetDouble(0, objName, OBJPROP_PRICE1, priceStart);
        ObjectSetInteger(0, objName, OBJPROP_TIME2, timeEnd);
        ObjectSetDouble(0, objName, OBJPROP_PRICE2, priceEnd);

        // Customize appearance
        ObjectSetInteger(0, objName, OBJPROP_COLOR, clrRed);  // Line color
        ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);  // Line width
    }
}

void CsntData::DrawPointOnNewBar(double &array[]) {
    string objName;
    datetime timeStart, timeEnd;
    double priceStart, priceEnd;

    int arraySize = ArraySize(array);
    if (arraySize < 2) return;

    // Unique name for the last trendline object
    objName = "CurveLine";

    // Get start and end times for the trendline (based on bar times)
    timeStart = iTime(SConfig.str_Symbol, NValue[SStatus.TFCUR].int_TimeFrame, 1);      // Time of the current bar
    timeEnd = iTime(SConfig.str_Symbol, NValue[SStatus.TFCUR].int_TimeFrame, 2);    // Time of the previous bar

    // Get the prices (array values) for start and end points
    // bar count from right to left
    priceStart = array[1];      // Most recent point
    priceEnd = array[2];    // Older point

    // Check if the last trendline object exists; if not, create it
    if (ObjectFind(0, objName) == -1) {
        ObjectCreate(0, objName, OBJ_TREND, 0, timeStart, priceStart, timeEnd, priceEnd);
    }

    // Update the trendline coordinates for the last point
    ObjectSetInteger(0, objName, OBJPROP_TIME1, timeStart);
    ObjectSetDouble(0, objName, OBJPROP_PRICE1, priceStart);
    ObjectSetInteger(0, objName, OBJPROP_TIME2, timeEnd);
    ObjectSetDouble(0, objName, OBJPROP_PRICE2, priceEnd);

    // Customize appearance
    ObjectSetInteger(0, objName, OBJPROP_COLOR, clrRed);  // Line color
    ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);       // Line width
}
#endif  //SNTDEBUG
#endif  //End of include guard