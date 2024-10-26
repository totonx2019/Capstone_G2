//+------------------------------------------------------------------+
//| Class: sntSignal - Monitors price and generates trade signals    |
//1.HS : Harmonic Swing
//2.RS : Retracement Seeker
//3.TM : Triple Momentum
//4.VB : Vault Breaker
//+------------------------------------------------------------------+
#ifndef C1Signal_MQH  // Check if MQH is not defined
#define C1Signal_MQH  // Define MQH
//+------------------------------------------------------------------+
#include "..\2Lib\A0Enum.mqh"
#include "..\2Lib\B1Data.mqh"

//+------------------------------------------------------------------+
    //20241018: add BBZone with stoSig
//+------------------------------------------------------------------+
class CsntSignal {
private:
    const CsntData    *sntData;   //reference not allow, use clone pointer
    ENUM_TIME msTF;  //Master TF
    ENUM_TIME acTF;  //Action TF
    ENUM_TIME chTF;  //Action TF
    trade_FootPrint TFootPrint;//will need to move to private
  
    void UpdateFootPrintOnNewBar(double &AdjFactor[]);
    char Signal_Price_Buy(trade_Ticket &TTicket);
    char Signal_Price_Sell(trade_Ticket &TTicket);

    //1.HS : Harmonic Swing
    char Signal_HS11_MACD(bool isBuy);   //price in MACD zone
    char Signal_HS12_STOCH(bool isBuy);  //price in STOCH zone
    char Signal_HS13_BB7020(bool isBuy); //BB20 beyond BB70 and price cross in
    char Signal_HS14_BB70Z(bool isBuy);  //price beyond BB70 and sto reverse
    char Signal_HS15_ATR6x(bool isBuy);  //price at extreme ATR in rare case
  
    //2.RS : Retracement Seeker, under trend    
    char Signal_RS21_MACD(bool isBuy);   //MACD touch under psar
    char Signal_RS22_STOCH(bool isBuy);  //STOCH touch under psar
    char Signal_RS23_BB20(bool isBuy);   //price touch BB20 under psar
    char Signal_RS24_FIBOnOI(bool isBuy);//price touch fibo and open interest under psar
    char Signal_RS25_ATRLV(bool isBuy);  //price touch atr level under psar
    
    //3.TM : Triple Momentum
    char Signal_TM31_MACD(bool isBuy);   //MACD multi TF
    char Signal_TM32_STOCH(bool isBuy);  //STO multi TF
    char Signal_TM33_RSI(bool isBuy);    //RSI multi TF
    char Signal_TM34_PSAR(bool isBuy);   //cross multi TF
    
    //4.VB : Vault Breakout
    //use T3MA ribbon
    char Signal_VB41_DC20(bool isBuy);   //DC channel
    char Signal_VB42_ATR(bool isBuy);    //ATR channel
    char Signal_VB43_TMA(bool isBuy);    //TMA channel
    char Signal_VB44_T3MA(bool isBuy);   //T3MA with HMA

protected://service class, doesn't need to inherit
public:
     CsntSignal(const CsntData &_sntData);
     CsntSignal(){};
    ~CsntSignal();
    void OnInit(ENUM_TIME _msTF, ENUM_TIME _acTF, ENUM_TIME _chTF);
    void OnDeinit();
    void OnTimer();
    void OnTick();
    void OnNewBar();

    //++++++++++++++
    double GetPriceStep(trade_Ticket &TTicket);

    //++++++++++++++
    bool Check_Buy_HS10(trade_Ticket &TTicket);
    bool Check_Sell_HS10(trade_Ticket &TTicket);
    bool Check_Buy_RS20(trade_Ticket &TTicket);
    bool Check_Sell_RS20(trade_Ticket &TTicket);
    bool Check_Buy_TM30(trade_Ticket &TTicket);
    bool Check_Sell_TM30(trade_Ticket &TTicket);
    bool Check_Buy_VB40(trade_Ticket &TTicket);
    bool Check_Sell_VB40(trade_Ticket &TTicket);
  
    //++++++++++++++   
    bool Check_Buy_GP10(trade_Ticket &TTicket);
    bool Check_Sell_GP10(trade_Ticket &TTicket);
    bool Check_Buy_GT20(trade_Ticket &TTicket);
    bool Check_Sell_GT20(trade_Ticket &TTicket);
    bool Check_Buy_GZ30(trade_Ticket &TTicket);
    bool Check_Sell_GZ30(trade_Ticket &TTicket);
    bool Check_Buy_GB40(trade_Ticket &TTicket);
    bool Check_Sell_GB40(trade_Ticket &TTicket);
};

//+------------------------------------------------------------------+
//Start Class Body
//+------------------------------------------------------------------+

// Constructor
CsntSignal::CsntSignal(const CsntData &_sntData)
          : sntData(&_sntData)
{
    //sntData.sntData.SConfig.chr_MaxRetries = 5; //test read only mode
    //_sntData.sntData.SConfig.chr_MaxRetries = 5; //test read only mode
}

// Destructor
CsntSignal::~CsntSignal() {
    // Cleanup resources if necessary
}

//+------------------------------------------------------------------+

// Initialization logic for the bot
void CsntSignal::OnInit(ENUM_TIME _msTF, ENUM_TIME _acTF, ENUM_TIME _chTF) {
    this.msTF = _msTF;
    this.acTF = _acTF;
    this.chTF = _chTF;
}

//+------------------------------------------------------------------+

// Cleanup logic for the bot
void CsntSignal::OnDeinit() {
    // Bot-specific cleanup code here
}

//+------------------------------------------------------------------+

// Timer-based logic for this bot
void CsntSignal::OnTimer() {
    // Logic that executes on timer events
}

//+------------------------------------------------------------------+

// Handle strategy-specific logic per tick
void CsntSignal::OnTick() {
    // Logic that executes on each tick
}

//+------------------------------------------------------------------+

// Handle new bar event for this strategy
void CsntSignal::OnNewBar() {
    // Logic that executes when a new bar is detected
    double AdjFactor[4];
    double dbl_msATRX = MathAbs(sntData.NValue[msTF].tck_ATRX[0]);
    double dbl_acATRX = MathAbs(sntData.NValue[acTF].tck_ATRX[0]);
    
    //**Adjustable per TF
    AdjFactor[0] = (7-msTF)*dbl_msATRX;
    AdjFactor[1] = (7-acTF)*dbl_acATRX;
    AdjFactor[2] = (45-msTF*5)*dbl_msATRX;
    AdjFactor[3] = (45-acTF*5)*dbl_acATRX;
    
    UpdateFootPrintOnNewBar(AdjFactor);
}

void CsntSignal::UpdateFootPrintOnNewBar(double &AdjFactor[]) {
    //Reset Value
    TFootPrint.chr_msVola = 0;     //SDATR
    TFootPrint.chr_acVola = 0;     //SDATR
    TFootPrint.chr_msStoZone = 0;  //HS
    TFootPrint.chr_acStoZone = 0;  //HS
    TFootPrint.chr_msMavZone = 0;  //HS
    TFootPrint.chr_acMavZone = 0;  //HS
    TFootPrint.chr_acStoSig = 0;   //HS
    TFootPrint.chr_acMacdSig = 0;  //HS
    TFootPrint.chr_acBB70Sig = 0;  //HS
    TFootPrint.chr_acBB20Sig = 0;  //HS

    TFootPrint.chr_msPSAR = 0;     //RS

    TFootPrint.chr_acMACD0 = 0;    //TM
    TFootPrint.chr_acMACD1 = 0;    //TM
    TFootPrint.chr_acMACD2 = 0;    //TM

    TFootPrint.chr_acDC20Sig = 0;  //VB
    TFootPrint.chr_acATRSig = 0;   //VB
    TFootPrint.chr_acPSARSig = 0;  //VB
    
    TFootPrint.chr_acMAline = 0;   //GT&GZ
    TFootPrint.chr_chMAline = 0;   //GT&GZ
    TFootPrint.chr_acBB70out = 0;  //GB
    
    //==========================================
    //Vola SDATR
    double dbl_msATR = iATR(sntData.SConfig.str_Symbol,sntData.NValue[msTF].int_TimeFrame,14,0);
    double dbl_msSD  = iStdDev(sntData.SConfig.str_Symbol,sntData.NValue[msTF].int_TimeFrame,20,0,MODE_SMA,PRICE_CLOSE,0);
    if ( dbl_msSD >  sntData.NValue[msTF].bar_ATRL[0]
      && dbl_msATR > sntData.NValue[msTF].bar_ATRL[0]
      && dbl_msSD >  dbl_msATR
    ) TFootPrint.chr_msVola += 1;

    if ( dbl_msSD <  sntData.NValue[msTF].bar_ATRL[0]
      && dbl_msATR < sntData.NValue[msTF].bar_ATRL[0]
      && dbl_msSD <  dbl_msATR
    ) TFootPrint.chr_msVola -= 1;

    //++++++++++++++
    double dbl_acATR = iATR(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,14,0);
    double dbl_acSD  = iStdDev(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,20,0,MODE_SMA,PRICE_CLOSE,0);
    if ( dbl_acSD >  sntData.NValue[acTF].bar_ATRL[0]
      && dbl_acATR > sntData.NValue[acTF].bar_ATRL[0]
      && dbl_acSD >  dbl_acATR
    ) TFootPrint.chr_acVola += 1;

    if ( dbl_acSD <  sntData.NValue[acTF].bar_ATRL[0]
      && dbl_acATR < sntData.NValue[acTF].bar_ATRL[0]
      && dbl_acSD <  dbl_acATR
    ) TFootPrint.chr_acVola -= 1;

    //==========================================
    //Sto Zone
    int int_StoPeriod;
    if (TFootPrint.chr_msVola == -1) int_StoPeriod = 25; else int_StoPeriod = 50;
    double dbl_msSTO = iStochastic(sntData.SConfig.str_Symbol,sntData.NValue[msTF].int_TimeFrame,int_StoPeriod,1,5,MODE_SMA,0,MODE_MAIN,0);
    if (dbl_msSTO >= MathMax(70+AdjFactor[0],80)) TFootPrint.chr_msStoZone += 1;
    if (dbl_msSTO <= MathMin(30-AdjFactor[0],20)) TFootPrint.chr_msStoZone -= 1;

    //++++++++++++++
    if (TFootPrint.chr_acVola == -1) int_StoPeriod = 25; else int_StoPeriod = 50;
    double dbl_acSTO = iStochastic(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,int_StoPeriod,1,5,MODE_SMA,0,MODE_MAIN,0);
    if (dbl_acSTO >= MathMax(70+AdjFactor[1],80)) TFootPrint.chr_acStoZone += 1;
    if (dbl_acSTO <= MathMin(30-AdjFactor[1],20)) TFootPrint.chr_acStoZone -= 1;
    
    //==========================================
    //MACD Zone
    if (sntData.NValue[msTF].tck_MACDV[0] >= MathMax( 1*AdjFactor[2], 50)) TFootPrint.chr_msMavZone += 1;
    if (sntData.NValue[msTF].tck_MACDV[0] <= MathMin(-1*AdjFactor[2],-50)) TFootPrint.chr_msMavZone -= 1;

    //++++++++++++++
    if (sntData.NValue[acTF].tck_MACDV[0] >= MathMax( 1*AdjFactor[3], 50)) TFootPrint.chr_acMavZone += 1;
    if (sntData.NValue[acTF].tck_MACDV[0] <= MathMin(-1*AdjFactor[3],-50)) TFootPrint.chr_acMavZone -= 1;

    //==========================================
    double dbl_Close0 = iClose(NULL,0,0); //close 0 is same for all time frame
    double dbl_Close1 = iClose(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,1);
    double dbl_acHigh0 = iHigh(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,0);//assume High0=Close0
    double dbl_acHigh1 = iHigh(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,1);
    double dbl_acHigh2 = iHigh(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,2);
    double dbl_acLow0 = iLow(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,0);//assume Low0=Close0
    double dbl_acLow1 = iLow(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,1);
    double dbl_acLow2 = iLow(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,2);
    double dbl_chHigh1 = iHigh(sntData.SConfig.str_Symbol,sntData.NValue[chTF].int_TimeFrame,1);
    double dbl_chLow1 = iLow(sntData.SConfig.str_Symbol,sntData.NValue[chTF].int_TimeFrame,1);

    //++++++++++++++
    //PSAR Trend Master
    double dbl_msPSAR = iSAR(sntData.SConfig.str_Symbol,sntData.NValue[msTF].int_TimeFrame,0.005,0.2,0);
    if (dbl_Close0 > dbl_msPSAR) TFootPrint.chr_msPSAR += 1;
    if (dbl_Close0 < dbl_msPSAR) TFootPrint.chr_msPSAR -= 1;

    //==========================================
    //MACD Trend Cross
    double dbl_acMACDM0 = iMACD(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,10,20,5,PRICE_CLOSE,MODE_MAIN,0);
    double dbl_acMACDS0 = iMACD(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,10,20,5,PRICE_CLOSE,MODE_SIGNAL,0);
    double dbl_acMACDM1 = iMACD(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,10,20,5,PRICE_CLOSE,MODE_MAIN,1);
    double dbl_acMACDS1 = iMACD(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,10,20,5,PRICE_CLOSE,MODE_SIGNAL,1);
    if ( dbl_acMACDM0 > dbl_acMACDS0 && dbl_acMACDM1 < dbl_acMACDS1 ) TFootPrint.chr_acMACD0 += 1;
    if ( dbl_acMACDM0 > dbl_acMACDS0 ) TFootPrint.chr_acMACD0 += 1;
    if ( dbl_acMACDM0 < dbl_acMACDS0 && dbl_acMACDM1 > dbl_acMACDS1 ) TFootPrint.chr_acMACD0 -= 1;
    if ( dbl_acMACDM0 < dbl_acMACDS0 ) TFootPrint.chr_acMACD0 -= 1;

    //++++++++++++++
    double dbl_acMACDM0p  = iMACD(sntData.SConfig.str_Symbol,sntData.NValue[acTF+1].int_TimeFrame,12,26,9,PRICE_CLOSE,MODE_MAIN,0);
    double dbl_acMACDS0p  = iMACD(sntData.SConfig.str_Symbol,sntData.NValue[acTF+1].int_TimeFrame,12,26,9,PRICE_CLOSE,MODE_SIGNAL,0);
    double dbl_acMACDM1p  = iMACD(sntData.SConfig.str_Symbol,sntData.NValue[acTF+1].int_TimeFrame,12,26,9,PRICE_CLOSE,MODE_MAIN,1);
    double dbl_acMACDS1p  = iMACD(sntData.SConfig.str_Symbol,sntData.NValue[acTF+1].int_TimeFrame,12,26,9,PRICE_CLOSE,MODE_SIGNAL,1);
    if ( dbl_acMACDM0p > dbl_acMACDS0p && dbl_acMACDM1p < dbl_acMACDS1p ) TFootPrint.chr_acMACD1 += 1;
    if ( dbl_acMACDM0p > dbl_acMACDS0p ) TFootPrint.chr_acMACD1 += 1;
    if ( dbl_acMACDM0p < dbl_acMACDS0p && dbl_acMACDM1p > dbl_acMACDS1p ) TFootPrint.chr_acMACD1 -= 1;
    if ( dbl_acMACDM0p < dbl_acMACDS0p ) TFootPrint.chr_acMACD1 -= 1;

    //++++++++++++++
    double dbl_acMACDM0pp = iMACD(sntData.SConfig.str_Symbol,sntData.NValue[acTF+2].int_TimeFrame,12,26,9,PRICE_CLOSE,MODE_MAIN,0);
    double dbl_acMACDS0pp = iMACD(sntData.SConfig.str_Symbol,sntData.NValue[acTF+2].int_TimeFrame,12,26,9,PRICE_CLOSE,MODE_SIGNAL,0);
    double dbl_acMACDM1pp = iMACD(sntData.SConfig.str_Symbol,sntData.NValue[acTF+2].int_TimeFrame,12,26,9,PRICE_CLOSE,MODE_MAIN,1);
    double dbl_acMACDS1pp = iMACD(sntData.SConfig.str_Symbol,sntData.NValue[acTF+2].int_TimeFrame,12,26,9,PRICE_CLOSE,MODE_SIGNAL,1);
    if ( dbl_acMACDM0pp > dbl_acMACDS0pp && dbl_acMACDM1pp < dbl_acMACDS1pp ) TFootPrint.chr_acMACD2 += 1;
    if ( dbl_acMACDM0pp > dbl_acMACDS0pp ) TFootPrint.chr_acMACD2 += 1;
    if ( dbl_acMACDM0pp < dbl_acMACDS0pp && dbl_acMACDM1pp > dbl_acMACDS1pp ) TFootPrint.chr_acMACD2 -= 1;
    if ( dbl_acMACDM0pp < dbl_acMACDS0pp ) TFootPrint.chr_acMACD2 -= 1;

    //==========================================
    //Sto Cross Signal
    int int_Period = 9 + MathMax(0,(4-acTF)*2);//20240101: defer sto to logner period on lower TF
    
    double dbl_acSTOM0 = iStochastic(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,int_Period,3,5,MODE_SMA,0,MODE_MAIN,0);
    double dbl_acSTOS0 = iStochastic(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,int_Period,3,5,MODE_SMA,0,MODE_SIGNAL,0);
    double dbl_acSTOM1 = iStochastic(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,int_Period,3,5,MODE_SMA,0,MODE_MAIN,1);
    double dbl_acSTOS1 = iStochastic(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,int_Period,3,5,MODE_SMA,0,MODE_SIGNAL,1);
    double dbl_acSTOM2 = iStochastic(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,int_Period,3,5,MODE_SMA,0,MODE_MAIN,2);
    double dbl_acSTOS2 = iStochastic(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,int_Period,3,5,MODE_SMA,0,MODE_SIGNAL,2);
    if ( dbl_acSTOM0 <= 20
      && dbl_acSTOM0 > dbl_acSTOS0 
      && dbl_acSTOM1 < dbl_acSTOS1
    ) TFootPrint.chr_acStoSig += 1;

    if ( dbl_acSTOM0 <= 20
      && dbl_acSTOM0 > dbl_acSTOS0 
      && dbl_acSTOM1 > dbl_acSTOS1 
      && dbl_acSTOM2 < dbl_acSTOS2
    ) TFootPrint.chr_acStoSig += 1;

    if ( dbl_acSTOM0 >= 80
      && dbl_acSTOM0 < dbl_acSTOS0 
      && dbl_acSTOM1 > dbl_acSTOS1
    ) TFootPrint.chr_acStoSig -= 1;

    if ( dbl_acSTOM0 >= 80
      && dbl_acSTOM0 < dbl_acSTOS0
      && dbl_acSTOM1 < dbl_acSTOS1 
      && dbl_acSTOM2 > dbl_acSTOS2
    ) TFootPrint.chr_acStoSig -= 1;

    //==========================================    
    //MACD Cross Signal
    if ( dbl_acSTOM0 > dbl_acSTOS0 
      && dbl_acMACDM0 > dbl_acMACDS0 
      && dbl_acMACDM1 < dbl_acMACDS1
    ) TFootPrint.chr_acMacdSig += 1;

    if ( dbl_acSTOM0 < dbl_acSTOS0 
      && dbl_acMACDM0 < dbl_acMACDS0 
      && dbl_acMACDM1 > dbl_acMACDS1
    ) TFootPrint.chr_acMacdSig -= 1;

    //==========================================
    //BB70 Cross Signal
    //Assume Bar0 is just a begining no low, no high
    double dbl_acBB70L0 = iBands(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,70,2.0,0,PRICE_MEDIAN,MODE_LOWER,0);
    double dbl_acBB70L1 = iBands(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,70,2.0,0,PRICE_MEDIAN,MODE_LOWER,1);
    double dbl_acBB70L2 = iBands(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,70,2.0,0,PRICE_MEDIAN,MODE_LOWER,2);
    if ( dbl_acLow2 < dbl_acBB70L2
      && dbl_acLow1 > dbl_acBB70L1
      && dbl_acLow0 > dbl_acBB70L0
	  ) TFootPrint.chr_acBB70Sig += 1;

    double dbl_acBB70H0 = iBands(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,70,2.0,0,PRICE_MEDIAN,MODE_UPPER,0);
    double dbl_acBB70H1 = iBands(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,70,2.0,0,PRICE_MEDIAN,MODE_UPPER,1);
    double dbl_acBB70H2 = iBands(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,70,2.0,0,PRICE_MEDIAN,MODE_UPPER,2);
    if ( dbl_acHigh2 > dbl_acBB70H2
      && dbl_acHigh1 < dbl_acBB70H1
      && dbl_acHigh0 < dbl_acBB70H0
	  ) TFootPrint.chr_acBB70Sig -= 1;

    //==========================================
    //BB20 Cross Signal
    double dbl_acBB20L0 = iBands(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,20,2.0,0,PRICE_MEDIAN,MODE_LOWER,0);
    double dbl_acBB20L1 = iBands(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,20,2.0,0,PRICE_MEDIAN,MODE_LOWER,1);
    double dbl_acBB20L2 = iBands(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,20,2.0,0,PRICE_MEDIAN,MODE_LOWER,2);
    if ( dbl_acLow2 < dbl_acBB20L2
      && dbl_acLow1 > dbl_acBB20L1
      && dbl_acLow0 > dbl_acBB20L0
      //&& dbl_acBB20L0 < dbl_acBB70L0
	  ) TFootPrint.chr_acBB20Sig += 1;

    double dbl_acBB20H0 = iBands(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,20,2.0,0,PRICE_MEDIAN,MODE_UPPER,0);
    double dbl_acBB20H1 = iBands(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,20,2.0,0,PRICE_MEDIAN,MODE_UPPER,1);
    double dbl_acBB20H2 = iBands(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,20,2.0,0,PRICE_MEDIAN,MODE_UPPER,2);
    if ( dbl_acHigh2 > dbl_acBB20H2
      && dbl_acHigh1 < dbl_acBB20H1
      && dbl_acHigh0 < dbl_acBB20H0
      //&& dbl_acBB20H0 > dbl_acBB70H0
	  ) TFootPrint.chr_acBB20Sig -= 1;

    //==========================================
    //DC20 Cross Signal
    //apply with high volatile
    double dbl_acDC20H = iHigh(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,
                         iHighest(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,MODE_HIGH,20,1));
    if ( dbl_Close0 > dbl_acDC20H
      && dbl_Close1 < dbl_acDC20H
	  ) TFootPrint.chr_acDC20Sig += 1;//price break DCH

    double dbl_acDC20L = iLow(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,
                         iLowest(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,MODE_LOW,20,1));
    if ( dbl_Close0 < dbl_acDC20L
      && dbl_Close1 > dbl_acDC20L
	  ) TFootPrint.chr_acDC20Sig -= 1; //price break DCL

    //==========================================
    //ATR Cross Signal 
    //apply with high volatile
    double dbl_acMA = iMA(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,20,0,MODE_SMA,PRICE_MEDIAN,0);
    dbl_acATR = iATR(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,100,0);
    double dbl_acATRH0 = dbl_acMA+dbl_acATR;
    double dbl_acATRL0 = dbl_acMA-dbl_acATR;

    dbl_acMA = iMA(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,20,0,MODE_SMA,PRICE_MEDIAN,1);
    dbl_acATR = iATR(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,100,1);
    double dbl_acATRH1 = dbl_acMA+dbl_acATR;
    double dbl_acATRL1 = dbl_acMA-dbl_acATR;

    dbl_acMA = iMA(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,20,0,MODE_SMA,PRICE_MEDIAN,2);
    dbl_acATR = iATR(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,100,2);
    double dbl_acATRH2 = dbl_acMA+dbl_acATR;
    double dbl_acATRL2 = dbl_acMA-dbl_acATR;    

    if ( dbl_acHigh2 < dbl_acATRH2
      && dbl_acHigh1 > dbl_acATRH1
      && dbl_acHigh0 > dbl_acATRH1
      && TFootPrint.chr_acVola >= 0
	  ) TFootPrint.chr_acATRSig += 1;

    if ( dbl_acLow2 > dbl_acATRL2
      && dbl_acLow1 < dbl_acATRL1
      && dbl_acLow0 < dbl_acATRL0
      && TFootPrint.chr_acVola >= 0
	  ) TFootPrint.chr_acATRSig -= 1;

    //==========================================    
    //PSAR Cross Signal
    double dbl_acPSAR0 = iSAR(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,0.005,0.2,0);
    double dbl_acPSAR1 = iSAR(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,0.005,0.2,1);
    if ( dbl_Close0 > dbl_acPSAR0
      && dbl_Close1 < dbl_acPSAR1
    ) TFootPrint.chr_acPSARSig += 1;

    if ( dbl_Close0 < dbl_acPSAR0
      && dbl_Close1 > dbl_acPSAR1
    ) TFootPrint.chr_acPSARSig -= 1;

    //==========================================
    //MA for GT & GZ
    double dbl_acMA0 = iMA(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,27,0,MODE_SMA,PRICE_MEDIAN,0);
    double dbl_chMA1 = iMA(sntData.SConfig.str_Symbol,sntData.NValue[chTF].int_TimeFrame,27,0,MODE_SMA,PRICE_MEDIAN,1);
    
    if ( dbl_chLow1 > dbl_chMA1  //full bar
      && dbl_acHigh0 > dbl_acMA0 //assume high = close
    ) TFootPrint.chr_acMAline += 1;

    if ( dbl_chHigh1 < dbl_chMA1 //full bar
      && dbl_acLow0 < dbl_acMA0  //assume high = close
    ) TFootPrint.chr_acMAline -= 1;

    //==========================================
    //BB for GB
    if ( dbl_acLow0 < dbl_acBB70L0
      || dbl_acLow1 < dbl_acBB70L1
    ) TFootPrint.chr_acBB70out += 1;

    if ( dbl_acHigh0 > dbl_acBB70H0
      || dbl_acHigh1 > dbl_acBB70H1    
    ) TFootPrint.chr_acBB70out -= 1;
}

double CsntSignal::GetPriceStep(trade_Ticket &TTicket) {
    double dbl_CalStep = 0; //Reset value
    //20240321: NextStep -x:xATR, 0:snt, 0.x:%, X:Point
    //20240818: NextStep -x:SDATR+min, 0:ATR/TF, 0.x:%, x:Point
    
    //1111111111
    //>>X = Point change to price
    if (sntData.SInput.dbl_NextStep >= 1) {
      dbl_CalStep = sntData.SInput.dbl_NextStep*sntData.SInput.AdjPoint*sntData.SConfig.dbl_Point;//change pip to price
    }//NextStep > 0
    
    //2222222222
    //>>0.x = %x of price
    if ( sntData.SInput.dbl_NextStep > 0
      && sntData.SInput.dbl_NextStep < 1 
    ){
      dbl_CalStep = iClose(NULL,0,0)* sntData.SInput.dbl_NextStep;//it is price
    }//NextStep = 0.x
    
    //3333333333
    //>>0 = ATR/TF with out min point
    //>>should use with other filter, eg BB20 > BB70
    if (sntData.SInput.dbl_NextStep == 0) {
      double dbl_ATR  = iATR(NULL,0,14,0);
      double dbl_SD   = iStdDev(NULL,0,20,0,MODE_SMA,PRICE_CLOSE,0);
      double dbl_ATRL = iATR(NULL,0,100,0);
      dbl_CalStep = MathMax(dbl_ATR,dbl_SD);
      dbl_CalStep = MathMax(dbl_CalStep,dbl_ATRL);      
    }//NextStep = 0
/*
    //>>0 = snt SmartStep
    if (sntData.SInput.dbl_NextStep == 0) {//Need to check at bot level
      double dbl_ATR  = iATR(sntData.SConfig.str_Symbol,PERIOD_M5,14,1);                                   //ATR 3.955833333333354
      double dbl_MACD = iMACD(sntData.SConfig.str_Symbol,PERIOD_M5,12,26,9,PRICE_CLOSE,MODE_SIGNAL,1);     //MACD 0.5094983365152075
      double dbl_BBup = (iBands(sntData.SConfig.str_Symbol,PERIOD_M5,20,1,0,PRICE_CLOSE,MODE_UPPER,0)-iClose(sntData.SConfig.str_Symbol,PERIOD_M5,0)); //BB 1843.236454304918
      double dbl_BBdn = (iClose(sntData.SConfig.str_Symbol,PERIOD_M5,0)-iBands(sntData.SConfig.str_Symbol,PERIOD_M5,20,1,0,PRICE_CLOSE,MODE_LOWER,0)); //Delta to iClose

      dbl_CalStep = MathMax(dbl_ATR,dbl_MACD);
      switch (TTicket[0].int_OrderType) {
        case OP_BUY : dbl_CalStep = MathMax(dbl_CalStep,dbl_BBup); break;
        case OP_SELL: dbl_CalStep = MathMax(dbl_CalStep,dbl_BBdn); break;
      }//switch
    }//if int_NextStep=0
*/

    //4444444444
    //>>-0.x = ATR multiplier
    if ( sntData.SInput.dbl_NextStep < 0
      && sntData.SInput.dbl_NextStep > -1
    ){
      double dbl_ATRL = iATR(NULL,PERIOD_H1,100,0);
      dbl_CalStep = dbl_ATRL/MathAbs(sntData.SInput.dbl_NextStep); //example 30/0.90 = 1.1x, 30/0.5 = 2x
    }//NextStep = 0.x

    //5555555555
    //>>-x = SDATRM off H1 with min point
    if (sntData.SInput.dbl_NextStep <= -1) {
      double dbl_ATR  = iATR(NULL,PERIOD_H1,14,0);
      double dbl_SD   = iStdDev(NULL,PERIOD_H1,20,0,MODE_SMA,PRICE_CLOSE,0);
      double dbl_ATRL = iATR(NULL,PERIOD_H1,100,0);

      dbl_CalStep = MathAbs(sntData.SInput.dbl_NextStep)*sntData.SInput.AdjPoint*sntData.SConfig.dbl_Point;//change pip to price
      dbl_CalStep = MathMax(dbl_CalStep,dbl_ATR);
      dbl_CalStep = MathMax(dbl_CalStep,dbl_SD);
      dbl_CalStep = MathMax(dbl_CalStep,dbl_ATRL);      
    }    

    //==========================================
    //20211129:add StepMulti for both Buy and Sell
    dbl_CalStep = dbl_CalStep * MathPower(A_POW ,sntData.SInput.dbl_StepMulti ,TTicket.Cnt_Ticket);
    
    //20240523:add BiasSell for only Sell
    switch (TTicket.int_OrderType) {
      case OP_SELL: 
        dbl_CalStep = dbl_CalStep / sntData.SInput.dbl_BiasSell;
      break;
    }//switch

    double dbl_MinStep  = MarketInfo(sntData.SConfig.str_Symbol,MODE_STOPLEVEL)* sntData.SConfig.dbl_Point; //Prevent 0 value, set default as STLV
    dbl_CalStep = MathMax(dbl_CalStep,dbl_MinStep); //Max to stop level

    return (NormalizeDouble(dbl_CalStep,Digits));
    //Use case: set step multi to 2.0 for oil and use automin    
}

//+------------------------------------------------------------------+
//Price : 
//+------------------------------------------------------------------+
char CsntSignal::Signal_Price_Buy(trade_Ticket &TTicket) {
    if (TTicket.Cnt_Ticket <= 0) {
      return 1;
    } else {
      //next order
      double dbl_NextStep = NormalizeDouble(GetPriceStep(TTicket),Digits);
    
      //Add b_AvoidSamePrice to skip TTicket and take global
      // dbl_LastBuy; 
      // dbl_LastSell; 
      
      if ( dbl_NextStep > 0
        && TTicket.dbl_Price - Ask >= dbl_NextStep
      ){
        return 1;
      }//nextStep      
    }//else
    
    return 0; 
}

char CsntSignal::Signal_Price_Sell(trade_Ticket &TTicket) {
    if (TTicket.Cnt_Ticket <= 0) {
      return 1;
    } else {
      //next order
      double dbl_NextStep = NormalizeDouble(GetPriceStep(TTicket),Digits);

      //Add b_AvoidSamePrice to skip TTicket and take global
      // dbl_LastBuy; 
      // dbl_LastSell; 
    
      if ( dbl_NextStep > 0
        && Bid - TTicket.dbl_Price >= dbl_NextStep
      ){
        return 1;
      }//nextStep      
    }//else
    
    return 0;
}

//+------------------------------------------------------------------+
//HS : High Valo Swing Trade
//+------------------------------------------------------------------+
char CsntSignal::Signal_HS11_MACD(bool isBuy) {
    if (!sntData.SInput.EntryHS11) return 0;
    
    //==========================================
    //MACD signal under zone condition
    //==========================================
    char chr_Signal = 0;
    if (isBuy) {
        //MACD Cross
        if ( TFootPrint.chr_msStoZone <= 0 //MS Mid+Low Zone
          && TFootPrint.chr_acStoZone < 0  //AC Low Zone
          && TFootPrint.chr_acMacdSig > 0  //Momentum UP
        ){ chr_Signal += 1;}
    
        if ( TFootPrint.chr_msStoZone <= 0 //MS Mid+Low Zone
          && TFootPrint.chr_acMavZone < 0  //AC Low Zone
          && TFootPrint.chr_acMacdSig > 0  //Momentum UP
        ){ chr_Signal += 1;}
    } else {
        if ( TFootPrint.chr_msStoZone >= 0 //MS High+Mid Zone
          && TFootPrint.chr_acStoZone > 0  //AC High Zone
          && TFootPrint.chr_acMacdSig < 0  //Momentum DN
        ){ chr_Signal += 1;}
    
        if ( TFootPrint.chr_msStoZone >= 0 //MS High+Mid Zone
          && TFootPrint.chr_acMavZone > 0  //AC High Zone
          && TFootPrint.chr_acMacdSig < 0  //Momentum DN
        ){ chr_Signal += 1;}
    }

    return chr_Signal; 
}

char CsntSignal::Signal_HS12_STOCH(bool isBuy) {
    if (!sntData.SInput.EntryHS12) return 0;
    
    //==========================================
    //STOCH signal under zone condition
    //==========================================
    char chr_Signal = 0;
    if (isBuy) {
        //Stoch Cross
        if ( TFootPrint.chr_msStoZone <= 0 //MS Mid+Low Zone
          && TFootPrint.chr_acStoZone < 0  //AC Low Zone
          && TFootPrint.chr_acStoSig > 0   //Momentum UP
        ){ chr_Signal += 1;}
    
        if ( TFootPrint.chr_msStoZone <= 0 //MS Mid+Low Zone
          && TFootPrint.chr_acMavZone < 0  //AC Low Zone
          && TFootPrint.chr_acStoSig > 0   //Momentum UP
        ){ chr_Signal += 1;}
    } else {
        //Stoch Cross
        if ( TFootPrint.chr_msStoZone >= 0 //MS High+Mid Zone
          && TFootPrint.chr_acStoZone > 0  //AC High Zone
          && TFootPrint.chr_acStoSig < 0   //Momentum DN
        ){ chr_Signal += 1;}
    
        if ( TFootPrint.chr_msStoZone >= 0 //MS High+Mid Zone
          && TFootPrint.chr_acMavZone > 0  //AC High Zone
          && TFootPrint.chr_acStoSig < 0   //Momentum DN
        ){ chr_Signal += 1;}
    }

    return chr_Signal;
}


char CsntSignal::Signal_HS13_BB7020(bool isBuy) {
    if (!sntData.SInput.EntryHS13) return 0;

    //==========================================
    //BB70 cross signal under BB7020 zone condition
    //==========================================
    //20241018: add BBZone with stoSig
    //should use BB7020 as zone to replace MACD zone
    //and use BB70Sig

    char chr_Signal = 0;
    if (isBuy) {
        //BB pullback
        if ( TFootPrint.chr_msStoZone <= 0 //MS Mid+Low Zone
          && TFootPrint.chr_acStoZone < 0  //AC Low Zone
          && TFootPrint.chr_acBB70Sig > 0  //Momentum UP
        ){ chr_Signal += 1;}
    
        if ( TFootPrint.chr_msStoZone <= 0 //MS Mid+Low Zone
          && TFootPrint.chr_acMavZone < 0  //AC Low Zone
          && TFootPrint.chr_acBB70Sig > 0  //Momentum UP
        ){ chr_Signal += 1;}
    } else {
        //BB pullback
        if ( TFootPrint.chr_msStoZone >= 0 //MS High+Mid Zone
          && TFootPrint.chr_acStoZone > 0  //AC High Zone
          && TFootPrint.chr_acBB70Sig < 0  //Momentum DN
        ){ chr_Signal += 1;}
    
        if ( TFootPrint.chr_msStoZone >= 0 //MS High+Mid Zone
          && TFootPrint.chr_acMavZone > 0  //AC High Zone
          && TFootPrint.chr_acBB70Sig < 0  //Momentum DN
        ){ chr_Signal += 1;}
    }

    return chr_Signal;    
}

char CsntSignal::Signal_HS14_BB70Z(bool isBuy) {
    if (!sntData.SInput.EntryHS14) return 0;

    //==========================================
    //Stoch or MACD signal under BB70 zone condition
    //==========================================
    char chr_Signal = 0;
    if (isBuy) {
    } else {
    }

    return chr_Signal;
}

char CsntSignal::Signal_HS15_ATR6x(bool isBuy) {
    if (!sntData.SInput.EntryHS15) return 0;

    //==========================================
    //Stoch or MACD signal under ATR6x zone condition
    //==========================================
    char chr_Signal = 0;
    if (isBuy) {
    } else {
    }

    return chr_Signal;
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

bool CsntSignal::Check_Buy_HS10( trade_Ticket &TTicket) {
    //20240803: split pure signal and filter check
    string str_MSG = ">";
    char chr_Sig11 = 0;//MACD
    char chr_Sig12 = 0;//STOCH
    char chr_Sig13 = 0;//BB
    
    //20240803: remove DC and change to BB
    double dbl_BB20 = iBands(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,20,2,0,PRICE_WEIGHTED,MODE_LOWER,0);
    double dbl_BB70 = iBands(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,70,2,0,PRICE_WEIGHTED,MODE_LOWER,0);

    //++++++++++++++
    if (dbl_BB20 <= dbl_BB70) {
      //High vola, use only MACD or BB
      chr_Sig11 = Signal_HS11_MACD(true);
      chr_Sig12 = 0;
      chr_Sig13 = Signal_HS13_BB7020(true);
    } else {
      //Low vola, use any sto / MACD / BB
      chr_Sig11 = Signal_HS11_MACD(true);
      chr_Sig12 = Signal_HS12_STOCH(true);
      chr_Sig13 = Signal_HS14_BB70Z(true);
    }

    if (chr_Sig11 > 0) str_MSG = str_MSG+"MACD/";
    if (chr_Sig12 > 0) str_MSG = str_MSG+"STO/";
    if (chr_Sig13 > 0) str_MSG = str_MSG+"BB1/";

    //++++++++++++++
    //Pure signal
    char chr_Order = 0;
    if (chr_Sig11 > 0 || chr_Sig12 > 0 || chr_Sig13 > 0) {
      chr_Order += 1;
      
      //if (sntData.SInput.b_DBEnable) DBcon.Sgnl_WriteTable("SGNL_BHS",TFootPrint,TTicket[0].int_Magic);
      SendNotificationEA(sntData.SInput.exNotiSignal,sntData.SInput.str_exNotiToken, sntData.SConfig.str_Symbol 
               + " ,Buy.HS."+DoubleToStr(sntData.NValue[acTF].int_TimeFrame,0)
      + "\n"      
      + (" ,Price=") + DoubleToStr(Ask,Digits)
      + " ,#" + DoubleToStr(TTicket.Cnt_Ticket+1,0)
      + "\n"
      + " ,v" + sntData.SInput.str_EA_version
      + " ,MSG=" + str_MSG
      );//Line
    }//chr_Order

    //==========================================
    char chr_Price = Signal_Price_Buy(TTicket);
    if (chr_Order > 0 && chr_Price > 0) return true;
    return false;
}

bool CsntSignal::Check_Sell_HS10(trade_Ticket &TTicket) {
    //20240803: split pure signal and filter check
    string str_MSG = ">";
    char chr_Sig11 = 0;//MACD
    char chr_Sig12 = 0;//STOCH
    char chr_Sig13 = 0;//BB

    //20240803: remove DC and change to BB
    double dbl_BB20 = iBands(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,20,2,0,PRICE_WEIGHTED,MODE_UPPER,0);
    double dbl_BB70 = iBands(sntData.SConfig.str_Symbol,sntData.NValue[acTF].int_TimeFrame,70,2,0,PRICE_WEIGHTED,MODE_UPPER,0);

    //++++++++++++++
    if (dbl_BB20 >= dbl_BB70) {
      //High vola, use only MACD or BB
      chr_Sig11 = Signal_HS11_MACD(false);
      chr_Sig12 = 0;
      chr_Sig13 = Signal_HS13_BB7020(false);
    } else {
      //Low vola, use any sto / MACD / BB
      chr_Sig11 = Signal_HS11_MACD(false);
      chr_Sig12 = Signal_HS12_STOCH(false);
      chr_Sig13 = Signal_HS14_BB70Z(false);
    }

    if (chr_Sig11 > 0) str_MSG = str_MSG+"MACD/";
    if (chr_Sig12 > 0) str_MSG = str_MSG+"STO/";
    if (chr_Sig13 > 0) str_MSG = str_MSG+"BB1/";

    //++++++++++++++
    //Pure signal
    char chr_Order = 0;
    if (chr_Sig11 > 0 || chr_Sig12 > 0 || chr_Sig13 > 0) {
      chr_Order += 1;

      //if (sntData.SInput.b_DBEnable) DBcon.Sgnl_WriteTable("SGNL_SHS",TFootPrint,TTicket[0].int_Magic);
      SendNotificationEA(sntData.SInput.exNotiSignal,sntData.SInput.str_exNotiToken, sntData.SConfig.str_Symbol 
               + " ,Sell.HS."+DoubleToStr(sntData.NValue[acTF].int_TimeFrame,0)
      + "\n"
      + (" ,Price=") + DoubleToStr(Bid,Digits)
      + " ,#" + DoubleToStr(TTicket.Cnt_Ticket+1,0)
      + "\n"
      + " ,v" + sntData.SInput.str_EA_version
      + " ,MSG=" + str_MSG
      );//Line
    }//chr_Order

    //==========================================
    char chr_Price = Signal_Price_Sell(TTicket);
    if (chr_Order > 0 && chr_Price > 0) return true;
    return false;
}

//+------------------------------------------------------------------+
//RS : Swing Signal at UnderTrend PSAR without msZone
//not breaking PSAR means still in previous low limit
//+------------------------------------------------------------------+
char CsntSignal::Signal_RS21_MACD(bool isBuy) {
    //RS doesn't use msZone
    char chr_Signal = 0;
    //MACD Cross
    if ( TFootPrint.chr_acStoZone < 0  //AC Low Zone
      && TFootPrint.chr_acMacdSig > 0  //Momentum UP
    ){ chr_Signal += 1;}

    if ( TFootPrint.chr_acMavZone < 0  //AC Low Zone
      && TFootPrint.chr_acMacdSig > 0  //Momentum UP
    ){ chr_Signal += 1;}

    //Stoch Cross
    if ( TFootPrint.chr_acStoZone < 0  //AC Low Zone
      && TFootPrint.chr_acStoSig > 0   //Momentum UP
    ){ chr_Signal += 1;}

    if ( TFootPrint.chr_acMavZone < 0  //AC Low Zone
      && TFootPrint.chr_acStoSig > 0   //Momentum UP
    ){ chr_Signal += 1;}

    //BB pullback
    if ( TFootPrint.chr_acStoZone < 0  //AC Low Zone
      && TFootPrint.chr_acBB20Sig > 0  //Momentum UP
    ){ chr_Signal += 1;}

    if ( TFootPrint.chr_acMavZone < 0  //AC Low Zone
      && TFootPrint.chr_acBB20Sig > 0  //Momentum UP
    ){ chr_Signal += 1;}

    //++++++++++++++
    return chr_Signal;    
}

//+------------------------------------------------------------------+

char CsntSignal::Signal_Sell_RS20_PSAR() {
    //RS doesn't use msZone
    char chr_Signal = 0;
    //MACD Cross
    if ( TFootPrint.chr_acStoZone > 0  //AC High Zone
      && TFootPrint.chr_acMacdSig < 0  //Momentum DN
    ){ chr_Signal += 1;}

    if ( TFootPrint.chr_acMavZone > 0  //AC High Zone
      && TFootPrint.chr_acMacdSig < 0  //Momentum DN
    ){ chr_Signal += 1;}

    //Stoch Cross
    if ( TFootPrint.chr_acStoZone > 0  //AC High Zone
      && TFootPrint.chr_acStoSig < 0   //Momentum DN
    ){ chr_Signal += 1;}

    if ( TFootPrint.chr_acMavZone > 0  //AC High Zone
      && TFootPrint.chr_acStoSig < 0   //Momentum DN
    ){ chr_Signal += 1;}

    //BB pullback
    if ( TFootPrint.chr_acStoZone > 0  //AC High Zone
      && TFootPrint.chr_acBB20Sig < 0  //Momentum DN
    ){ chr_Signal += 1;}

    if ( TFootPrint.chr_acMavZone > 0  //AC High Zone
      && TFootPrint.chr_acBB20Sig < 0  //Momentum DN
    ){ chr_Signal += 1;}

    //++++++++++++++
    return chr_Signal;    
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

bool CsntSignal::Check_Buy_RS20(trade_Ticket &TTicket) {
    string str_MSG = ">";
    char chr_Signal = 0;

    chr_Signal = Signal_Buy_RS20_PSAR();
    if (chr_Signal > 0) str_MSG = str_MSG+"PSAR/";

    //++++++++++++++
    //Pure signal
    char chr_Order = 0;
    if (chr_Signal > 0 && TFootPrint.chr_msPSAR > 0) {
      chr_Order += 1;
      
      //if (sntData.SInput.b_DBEnable) DBcon.Sgnl_WriteTable("SGNL_BRS",TFootPrint,TTicket[0].int_Magic);
      SendNotificationEA(sntData.SInput.exNotiSignal,sntData.SInput.str_exNotiToken, sntData.SConfig.str_Symbol 
               + " ,Buy.RS."+DoubleToStr(sntData.NValue[acTF].int_TimeFrame,0)
      + "\n"
      + (" ,Price=") + DoubleToStr(Ask,Digits)
      + " ,#" + DoubleToStr(TTicket.Cnt_Ticket+1,0)
      + "\n"
      + " ,v" + sntData.SInput.str_EA_version
      + " ,MSG=" + str_MSG
      );//Line
    }//chr_Signal

    //==========================================
    char chr_Price = Signal_Price_Buy(TTicket);
    if (chr_Order > 0 && chr_Price > 0) return true;
    return false;
}

bool CsntSignal::Check_Sell_RS20(trade_Ticket &TTicket) {
    string str_MSG = ">";
    char chr_Signal = 0;

    chr_Signal = Signal_Sell_RS20_PSAR();
    if (chr_Signal > 0) str_MSG = str_MSG+"PSAR/";

    //++++++++++++++
    //Pure signal
    char chr_Order = 0;
    if (chr_Signal > 0 && TFootPrint.chr_msPSAR < 0) {
      chr_Order += 1;    
      
      //if (sntData.SInput.b_DBEnable) DBcon.Sgnl_WriteTable("SGNL_SRS",TFootPrint,TTicket[0].int_Magic);
      SendNotificationEA(sntData.SInput.exNotiSignal,sntData.SInput.str_exNotiToken, sntData.SConfig.str_Symbol 
               + " ,Sell.RS."+DoubleToStr(sntData.NValue[acTF].int_TimeFrame,0)
      + "\n"
      + (" ,Price=") + DoubleToStr(Bid,Digits)
      + " ,#" + DoubleToStr(TTicket.Cnt_Ticket+1,0)
      + "\n"
      + " ,v" + sntData.SInput.str_EA_version
      + " ,MSG=" + str_MSG
      );//Line
    }//chr_Signal

    //==========================================
    char chr_Price = Signal_Price_Sell(TTicket);
    if (chr_Order > 0 && chr_Price > 0) return true;
    return false;
}

//+------------------------------------------------------------------+
//TM : Follow multi TF MACD Trend with msZone not OverBougth OverSold
//+------------------------------------------------------------------+
bool CsntSignal::Check_Buy_TM30(trade_Ticket &TTicket) {
    string str_MSG = ">";
    char chr_Signal = 0;
    if ( (TFootPrint.chr_acMACD0==2 || TFootPrint.chr_acMACD1==2 || TFootPrint.chr_acMACD2==2) //one TF MACD cross
      && (TFootPrint.chr_acMACD0>0 && TFootPrint.chr_acMACD1>0 && TFootPrint.chr_acMACD2>0)    //all TF MACD UP
    ){ 
      chr_Signal += 1;
      str_MSG = str_MSG+"MACDUP/";
    }

    //++++++++++++++
    //Pure signal
    char chr_Order = 0;
    if ( chr_Signal > 0 
      && TFootPrint.chr_msStoZone <= 0
      && TFootPrint.chr_acVola >= 0    //High+Mid Vola
    ){
      chr_Order += 1;
    
      //if (sntData.SInput.b_DBEnable) DBcon.Sgnl_WriteTable("SGNL_BTM",TFootPrint,TTicket[0].int_Magic);
      SendNotificationEA(sntData.SInput.exNotiSignal,sntData.SInput.str_exNotiToken, sntData.SConfig.str_Symbol 
               + " ,Buy.TM."+DoubleToStr(sntData.NValue[acTF].int_TimeFrame,0)
      + "\n"
      + (" ,Price=") + DoubleToStr(Ask,Digits)
      + " ,#" + DoubleToStr(TTicket.Cnt_Ticket,0)
      + "\n"
      + " ,v" + sntData.SInput.str_EA_version
      + " ,MSG=" + str_MSG
      );//Line    
    }//chr_Signal

    //==========================================
    char chr_Price = Signal_Price_Buy(TTicket);
    if (chr_Order > 0 && chr_Price > 0) return true;
    return false;
}

bool CsntSignal::Check_Sell_TM30(trade_Ticket &TTicket) {
    string str_MSG = ">";
    char chr_Signal = 0;
    if ( (TFootPrint.chr_acMACD0==-2 || TFootPrint.chr_acMACD1==-2 || TFootPrint.chr_acMACD2==-2) //one TF MACD cross
      && (TFootPrint.chr_acMACD0<0 && TFootPrint.chr_acMACD1<0 && TFootPrint.chr_acMACD2<0)       //all TF MACD DN
    ){ 
      chr_Signal += 1;
      str_MSG = str_MSG+"MACDDN/";
    }

    //++++++++++++++
    //Pure signal
    char chr_Order = 0;
    if ( chr_Signal > 0 
      && TFootPrint.chr_msStoZone >= 0
      && TFootPrint.chr_acVola >= 0    //High+Mid Vola
    ){
      chr_Order += 1;

      //if (sntData.SInput.b_DBEnable) DBcon.Sgnl_WriteTable("SGNL_STM",TFootPrint,TTicket[0].int_Magic);
      SendNotificationEA(sntData.SInput.exNotiSignal,sntData.SInput.str_exNotiToken, sntData.SConfig.str_Symbol 
               + " ,Sell.TM."+DoubleToStr(sntData.NValue[acTF].int_TimeFrame,0)
      + "\n"
      + (" ,Price=") + DoubleToStr(Bid,Digits)
      + " ,#" + DoubleToStr(TTicket.Cnt_Ticket,0)
      + "\n"
      + " ,v" + sntData.SInput.str_EA_version
      + " ,MSG=" + str_MSG
      );//Line
    }//chr_Signal

    //==========================================
    char chr_Price = Signal_Price_Sell(TTicket);
    if (chr_Order > 0 && chr_Price > 0) return true;
    return false;
}

//+------------------------------------------------------------------+
//VB : Breakout of a channel wih MA assist trend line
//+------------------------------------------------------------------+
bool CsntSignal::Check_Buy_VB40(trade_Ticket &TTicket) {
    string str_MSG = ">";
    char chr_Signal = 0;
    if (TFootPrint.chr_acDC20Sig > 0){ chr_Signal += 1; str_MSG = str_MSG+"DC/";}
    if (TFootPrint.chr_acATRSig > 0) { chr_Signal += 1; str_MSG = str_MSG+"ATR/";}
    if (TFootPrint.chr_acPSARSig > 0){ chr_Signal += 1; str_MSG = str_MSG+"PSAR/";}

    //++++++++++++++
    //Pure signal
    char chr_Order = 0;
    if ( chr_Signal > 0
      //&& BB20 < BB70
    ){
      chr_Order += 1;

      //if (sntData.SInput.b_DBEnable) DBcon.Sgnl_WriteTable("SGNL_BVB",TFootPrint,TTicket[0].int_Magic);
      SendNotificationEA(sntData.SInput.exNotiSignal,sntData.SInput.str_exNotiToken, sntData.SConfig.str_Symbol 
               + " ,Buy.VB."+DoubleToStr(sntData.NValue[acTF].int_TimeFrame,0)
      + "\n"
      + (" ,Price=") + DoubleToStr(Ask,Digits)
      + " ,#" + DoubleToStr(TTicket.Cnt_Ticket,0)
      + "\n"
      + " ,v" + sntData.SInput.str_EA_version
      + " ,MSG=" + str_MSG
      );//Line
    }//chr_Signal

    //==========================================
    char chr_Price = Signal_Price_Buy(TTicket);
    if (chr_Order > 0 && chr_Price > 0) return true;
    return false;
}

bool CsntSignal::Check_Sell_VB40(trade_Ticket &TTicket) {
    string str_MSG = ">";
    char chr_Signal = 0;
    if (TFootPrint.chr_acDC20Sig < 0){ chr_Signal += 1; str_MSG = str_MSG+"DC/";}
    if (TFootPrint.chr_acATRSig < 0) { chr_Signal += 1; str_MSG = str_MSG+"ATR/";}
    if (TFootPrint.chr_acPSARSig < 0){ chr_Signal += 1; str_MSG = str_MSG+"PSAR/";}

    //++++++++++++++
    //Pure signal
    char chr_Order = 0;
    if ( chr_Signal > 0
      //&& BB20 < BB70
    ){
      chr_Order += 1;

      //if (sntData.SInput.b_DBEnable) DBcon.Sgnl_WriteTable("SGNL_SVB",TFootPrint,TTicket[0].int_Magic);
      SendNotificationEA(sntData.SInput.exNotiSignal,sntData.SInput.str_exNotiToken, sntData.SConfig.str_Symbol 
               + " ,Sell.VB."+DoubleToStr(sntData.NValue[acTF].int_TimeFrame,0)
      + "\n"
      + (" ,Price=") + DoubleToStr(Bid,Digits)
      + " ,#" + DoubleToStr(TTicket.Cnt_Ticket,0)
      + "\n"
      + " ,v" + sntData.SInput.str_EA_version
      + " ,MSG=" + str_MSG
      );//Line
    }//chr_Signal

    //==========================================
    char chr_Price = Signal_Price_Sell(TTicket);
    if (chr_Order > 0 && chr_Price > 0) return true;
    return false;
}

//+------------------------------------------------------------------+
//Grid Signal
//+------------------------------------------------------------------+
bool CsntSignal::Check_Buy_GP10(trade_Ticket &TTicket) {
    char chr_Order = 0;
    if (TTicket.Cnt_Ticket <= 0) { //first order
      chr_Order = Signal_Buy_RS20_PSAR();
    } else {
      chr_Order = 1;
    }

    //==========================================
    char chr_Price = Signal_Price_Buy(TTicket);
    if (chr_Order > 0 && chr_Price > 0) return true;
    return false;
}

bool CsntSignal::Check_Sell_GP10(trade_Ticket &TTicket) {
    char chr_Order = 0;
    if (TTicket.Cnt_Ticket <= 0) { //first order
      chr_Order = Signal_Sell_RS20_PSAR();
    } else {
      chr_Order = 1;
    }
	
    //==========================================
    char chr_Price = Signal_Price_Sell(TTicket);
    if (chr_Order > 0 && chr_Price > 0) return true;
    return false;
}

//+------------------------------------------------------------------+

bool CsntSignal::Check_Buy_GT20(trade_Ticket &TTicket) {
    char chr_Signal = 0;
    if (TTicket.Cnt_Ticket <= 0) { //first order
      chr_Signal = Signal_Buy_RS20_PSAR();
    } else {
      chr_Signal = 1;
    }

    char chr_Order = 0;
    if (chr_Signal > 0 && TFootPrint.chr_acMAline > 0) {
      chr_Order += 1;
    }//chr_Signal
		
    //==========================================
    char chr_Price = Signal_Price_Buy(TTicket);
    if (chr_Order > 0 && chr_Price > 0) return true;
    return false;
}

bool CsntSignal::Check_Sell_GT20(trade_Ticket &TTicket) {
    char chr_Signal = 0;
    if (TTicket.Cnt_Ticket <= 0) { //first order
      chr_Signal = Signal_Sell_RS20_PSAR();
    } else {
      chr_Signal = 1;
    }

    char chr_Order = 0;
    if (chr_Signal > 0 && TFootPrint.chr_acMAline < 0) {
      chr_Order += 1;
    }//chr_Signal
	
    //==========================================
    char chr_Price = Signal_Price_Sell(TTicket);
    if (chr_Order > 0 && chr_Price > 0) return true;
    return false;
}

//+------------------------------------------------------------------+

bool CsntSignal::Check_Buy_GZ30(trade_Ticket &TTicket) {
    char chr_Signal = 0;
    if (TTicket.Cnt_Ticket <= 0) { //first order
      chr_Signal = Signal_Buy_RS20_PSAR();
    } else {
      chr_Signal = 1;
    }

    char chr_Order = 0;
    if (chr_Signal > 0 && TFootPrint.chr_acMAline > 0) {
      chr_Order += 1;
    }//chr_Signal
	
    //==========================================
    char chr_Price = Signal_Price_Buy(TTicket);
    if (chr_Order > 0 && chr_Price > 0) return true;
    return false;
}

bool CsntSignal::Check_Sell_GZ30(trade_Ticket &TTicket) {
    char chr_Signal = 0;
    if (TTicket.Cnt_Ticket <= 0) { //first order
      chr_Signal = Signal_Sell_RS20_PSAR();
    } else {
      chr_Signal = 1;
    }

    char chr_Order = 0;
    if (chr_Signal > 0 && TFootPrint.chr_acMAline < 0) {
      chr_Order += 1;
    }//chr_Signal
	
    //==========================================
    char chr_Price = Signal_Price_Sell(TTicket);
    if (chr_Order > 0 && chr_Price > 0) return true;
    return false;
}

//+------------------------------------------------------------------+

bool CsntSignal::Check_Buy_GB40(trade_Ticket &TTicket) {
    char chr_Signal = 0;
    if (TTicket.Cnt_Ticket <= 0) { // No existing orders      
      if (TFootPrint.chr_acStoSig > 0) chr_Signal = 1; 
    } else {
      chr_Signal = 1; 
    }

    char chr_Order = 0;
    if (chr_Signal > 0 && TFootPrint.chr_acBB70out < 0) {
      chr_Order = 1;    
    }

    //==========================================
    char chr_Price = Signal_Price_Buy(TTicket);
    if (chr_Order > 0 && chr_Price > 0) return true;
    return false;
}

bool CsntSignal::Check_Sell_GB40(trade_Ticket &TTicket) {
    char chr_Signal = 0;
    if (TTicket.Cnt_Ticket <= 0) { // No existing orders
      if (TFootPrint.chr_acStoSig < 0) chr_Signal = 1; // Downward stochastic momentum
    } else {
      chr_Signal = 1; // Set signal for subsequent orders
    }

    char chr_Order = 0;
    if (chr_Signal > 0 && TFootPrint.chr_acBB70out > 0) { // Modified
        chr_Order = 1; // Confirm the signal if the price is above BB(70) (new step)
    }

    //==========================================
    char chr_Price = Signal_Price_Sell(TTicket);
    if (chr_Order > 0 && chr_Price > 0) return true; // Changed to use chr_Order
    return false;
}



#endif  //End of include guard