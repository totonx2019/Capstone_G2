//+------------------------------------------------------------------+
//|                                                       A0Enum.mqh |
//https://notify-api.line.me/api/notify
//>>This must be set, can't avoid
//+------------------------------------------------------------------+
#property strict
#ifndef A0ENUM_MQH  // Check if A_MQH is not defined
#define A0ENUM_MQH  // Define A_MQH
//+------------------------------------------------------------------+
/*
24 Sep 2018 -Reorder enum_time as reversal to manage BarID
04 Apr 2021 -Add SHLpct for KZM long time frame
            -Potential to remove Pivot line as using HLpct instead (120% can present forecast line)
26 May 2021 -Add Line Room in ENUM
*/
#define xSNTDEBUG
//+------------------------------------------------------------------+
//Data ENUM
//+------------------------------------------------------------------+
enum ENUM_HEDGE {
    OFF_HEDGE = 0,
    ON_HEDGE = 1,
    ON_RECOVER = 2    
};

enum ENUM_MERGE_ORDER {//Robot[0]
    OFF_MERGE = 0,
    ON_BOTH   = 1,
    ON_BUY    = 2,
    ON_SELL   = 3
};

enum ENUM_MKT_GRID {//Robot[1]
    OFF_GRID = 0,
    G_Price = 1,
    G_Trend = 2,
    G_Zone  = 3,
    G_BB    = 4
};

enum ENUM_MKT_VOLA {//Robot[x]
    OFF_VOLA = 0,
    HS = 1, //Harmonic Swing
    RS = 2, //Retracement Seeker
    TM = 4, //Triple Momentum
    VB = 8, //Vault Breaker
    HSRS = 3,//HS+RS
    HSTM = 5,//HS+TM
    HSVB = 9,//HS+VB
    RSTM = 6,//RS+TM
    RSVB = 10,//RS+VB
    TMVB = 12,//TM+VB
    HSRSTM = 7,//HS+RS+TM
    HSRSVB = 11,//HS+RS+VB
    HSTMVB = 13,//HS+TM+VB
    RSTMVB = 14,//RS+TM+VB
    HSRSTMVB = 15//HS+RS+TM+VB
};

enum ENUM_POINT {
    GOLD_x00  = 1,
    GOLD_x000 = 10,
    GOLD_x0000 = 100
};

enum ENUM_NOTI {
    Noti_OFF      =0,
    Line_Custom   =11,
    Line_Private  =12,
    Line_DEV      =13,
    Line_STX      =14,
    Line_ETO      =15,
    Line_Gold     =16,
    Line_Oil      =17, 
    Line_Home     =18,
    
    Tlgrm_Private =21,
    Tlgrm_STX     =22,
    Tlgrm_Home    =23,
    Tlgrm_PUB     =24,
    
    Dscrd_Private =31,
    
    MetaQ_ID      =99
};

enum ENUM_TIME {
    TFOFF  =-2,
    TFAUTO =-1,
    TFM1  =8,
    TFW1  =7,
    TFD1  =6,
    TFH4  =5,
    TF60  =4,
    TF30  =3,
    TF15  =2,
    TF05  =1,
    TF01  =0
};

enum ENUM_MATH { 
   A_POW =1,
   B_FIB =2,
   C_ADD =3
}; 


//+------------------------------------------------------------------+
//Struct clsControl
//Last validate 20190316
//+------------------------------------------------------------------+
struct sys_Input {
  string   str_EA_version;   // Optional: EA version
  uchar    chr_BotCount;     // EA bot count

  //1----------1
  bool     b_AvoidSamePrice;
  ENUM_MERGE_ORDER RunBot00;
  ENUM_MKT_GRID RunBot01;
  ENUM_MKT_VOLA RunBot02;
  ENUM_MKT_VOLA RunBot03;
  ENUM_MKT_VOLA RunBot04;
  ENUM_MKT_VOLA RunBot05;
  bool Exit01;
  bool Exit02;
  bool Exit03;
  bool Exit04;
  bool Exit05;
  bool Exit06;
  bool Exit07;
  
  bool EntryHS11;
  bool EntryHS12;
  bool EntryHS13;
  bool EntryHS14;
  bool EntryHS15;  
  bool EntryRS21;
  bool EntryRS22;
  bool EntryRS23;
  bool EntryRS24;
  bool EntryRS25;
  bool EntryTM31;
  bool EntryTM32;
  bool EntryTM33;
  bool EntryTM34;
  bool EntryVB41;
  bool EntryVB42;
  bool EntryVB43;
  bool EntryVB44;

  //2----------2
  double   dbl_StartLot;     // Matches StartLot
  double   dbl_LotMulti;     // Matches LotMulti
  int      int_ZoneSize;     // Matches ZoneSize
  int      int_ZonePlay;     // Matches ZonePlay
  int      int_MaxOrder;     // Matches MaxOrder
  double   dbl_NextStep;     // Matches NextStep
  double   dbl_StepMulti;    // Matches StepMulti
  ushort   int_RepeatLot;    // Matches RepeatLot
  double   dbl_MaxLastLot;   // Matches MaxLastLot
  uint     int_MaxSpread;    // Matches MaxSpread
  double   dbl_BiasSell;     // Matches BiasSell
  bool     b_AutoTF;         // Matches AutoTF

  //3----------3
  int      int_TargetTP;     // Matches TargetTP
  int      int_TargetSL;     // Matches TargetSL
  int      int_SetFixTP;     // Matches SetFixTP
  int      int_SetFixSL;     // Matches SetFixSL
  int      int_StartTSL;     // Matches StartTSL
  int      int_StepsTSL;     // Matches StepsTSL
  double   dbl_QuickTP;      // Matches QuickTP
  double   dbl_TPMax;        // Matches TPMax
  ENUM_HEDGE HedgeMode;      // Matches _HedgeMode
  ushort   int_HedgeBuffer;  // Matches HedgeBuffer

  //4----------4
  ENUM_POINT AdjPoint;       // Matches _AdjPoint
  string    str_KeyLicense;  // KeyLicense moved from extern to input
  uchar     chr_MagicGroup;  // Matches MagicGroup
  string    str_exNotiToken; // Matches exLineToken
  ENUM_NOTI exNotiSignal;    // Matches exLineSignal
  ENUM_NOTI exNotiStatus;    // Matches exLineStatus
  
  //5----------5
  string  str_ShortComment; // Matches ShortComment
  int     int_OrderExpired; // Matches OrderExpired
  double  dbl_OrderDD;      // Matches OrderDD
  bool    b_PauseBuy;       // Matches PauseBuy
  bool    b_PauseSell;      // Matches PauseSell
  bool    b_StopBuy;        // Matches StopBuy
  bool    b_StopSell;       // Matches StopSell
  bool    b_StopExit;       // Matches StopExit
  bool    b_DBEnable;       // Matches DBEnable
  uchar   StartHour1;       // Matches StartHour1
  uchar   StopHour1;        // Matches StopHour1
  uchar   StartHour2;       // Matches StartHour2
  uchar   StopHour2;        // Matches StopHour2
};

//+------------------------------------------------------------------+
struct sys_Status {
  //20241009: try to keep EA condition here
  char     LicenseStatus;
  string   str_ExpireDate;  //"2022.12.01 00:00"  

  double   dbl_EA_MaxDD;
  double   dbl_EA_Balance;     //refresh weekly
  double   dbl_EA_Lot;         //Added 20181009, TotalLot from Margin in one EA

  int      int_OrdersTotal;    //Account opened order included manual order
  char     chr_NewBar;
  ENUM_TIME TFCUR; //default  TF60
  
  double   dbl_LastBuy;  //ShareLastBuy;  manage by TradeBot[0]
  double   dbl_LastSell; //ShareLastSell; manage by TradeBot[0]

  bool     b_Recovery;
  bool     b_RemoteStopBuy;
  bool     b_RemoteStopSell;

  //++++++++++++++
  //loop back communication
  double   dbl_Display[5];
};

//+------------------------------------------------------------------+
struct sys_Config {
  //sys_Input  SInput; //SInput.
  //sys_Status SStatus;

  string   str_Symbol; 
  //20240321: move for Market Infor Data  
  int      int_DigitLot;
  double   dbl_MinLot; //system min lot
  double   dbl_MaxLot; //system max lot
  double   dbl_LotStep; //use to calculate TP with P2D

  double   dbl_Point;           //TickSize only used for P2D, to GetTp and GetSL, we need to use Point in conversion
  double   dbl_P2D;             //P2D: convert price delta to profit (default Lot = 1.0)
  //profit = price*P2D*lot
  char     chr_MaxRetries;
  int      int_Slippage;
  double   dbl_Taxes;
};

//+------------------------------------------------------------------+
//Struct clsNavigator
//Last validate 20190316
//+------------------------------------------------------------------+
struct trade_FootPrint {
  //ATR compare to SD or ATRL (change from ATRS to SDS
  char chr_msVola; 
  char chr_acVola; 

  //for HS
  char chr_msStoZone; 
  char chr_acStoZone;
  char chr_msMavZone;
  char chr_acMavZone;
  char chr_acStoSig;
  char chr_acMacdSig;
  char chr_acBB70Sig;
  char chr_acBB20Sig;
  
  //for LS
  char chr_msPSAR;

  //for HT
  char chr_acMACD0;
  char chr_acMACD1;
  char chr_acMACD2;

  //for LT
  char chr_acDC20Sig;
  char chr_acATRSig;
  char chr_acPSARSig;

  //for GT & GZ
  char chr_acMAline;
  char chr_chMAline;
  
  //for GB
  char chr_acBB70out;
};

//+------------------------------------------------------------------+
struct nav_Value {
  bool     b_NewBar;
  datetime dt_Bar0;       
  //int      int_TimeFrame; //ENUM_TIMEFRAMES
  ENUM_TIMEFRAMES int_TimeFrame;
  
  double   dbl_Elapsed;
  int      int_Mountain; //iHighest bar num
  int      int_Valley;   //iLowest bar num
  double   bar_ATRV_Mean;//One value By TF by bar
  double   bar_ATRV_SD;  //One value By TF by bar
  double   tck_ATRVZV;   //Live ATRX Z-score by TF by tick
  
  //++++++++++++++
  //Primary data
  //Indy Array on tick Max =200, newest at [0]
  double   tck_ATRX[];     //For iSTDonArray ATRX=Close-EMA/ATR
  double   tck_ATRV[];     //ATRV=Close-SMA/ATR shift back 5 bar, use for ZV is better
  double   tck_ATRP[];     //ATRP=Price pwer max(abs(Close-Low_or_High))/ATR100, norm 0-3
  double   tck_MACDV[];    //For iSTDonArray MACDV=MACD/ATR 
  double   bar_MACDVSig[]; //Alex MACD Volatile Signal //name as "bar" bcoz,it has MaxArray, not MaxBuff
  
  //++++++++++++++
  //Buffer Array on new bar Max =200, newest at [max]
  //buff value will be used for iMAonArray by bar_Indy, newest at [max]
  //buff has differ array order, can't direct use
  double   buf_HLpct[];   //HLpct=High-Low/Open = percent move in current price bar
  double   buf_SDL[];      //SDL=SD Long smooth for TMA
  double   buf_ATR[];      //normal ATR in buff array for ATRL and ATRS
  double   buf_HMAL[];     //raw value of DiffMA long period use in bar_HMAL
  double   buf_HMAS[];     //raw value of DiffMA short period use in bar_HMAS
  double   buf_DCW[];      //raw value of DC width look back long period 
  /*
  double   buf_T3MAL_e1[];
  double   buf_T3MAL_e2[];
  double   buf_T3MAL_e3[];
  double   buf_T3MAL_e4[];
  double   buf_T3MAL_e5[];
  double   buf_T3MAL_e6[];
  double   buf_T3MAS_e1[];
  double   buf_T3MAS_e2[];
  double   buf_T3MAS_e3[];
  double   buf_T3MAS_e4[];
  double   buf_T3MAS_e5[];
  double   buf_T3MAS_e6[];
*/
  //Secondary data from buffer data
  //Indy Array on new bar Max=10, newest at [0]
  //Make recent indicator data to use in EA
  double   bar_TMAH[];     //TMA upper channel
  double   bar_TMAL[];     //TMA lower channel
  
  double   bar_HLpct[];
  double   bar_ATRL[];     //MA of ATR smoothed 55 long  
  double   bar_HMAL[];     //Long bar length on open price
  double   bar_HMAS[];     //Short bar length on open price
  double   bar_DCWL[];     //Avg DCW at long period
  //double   bar_T3MAL_e7[];
  //double   bar_T3MAS_e7[];

  double   bar_Peak[];     //top per Stoch cross
  double   bar_Trough[];   //btm per Stoch cross
  //double   bar_InfoGain[10]; //Main Indicators = total+1 
};

//+------------------------------------------------------------------+
//Struct clsTrade
//Last validate 20190316
//+------------------------------------------------------------------+
struct trade_Attribute {//to track order history with indicator
  //trade_Ticket
  
  //indicator
  
  
  //footprint

};

struct trade_Summary {//input at addRecord function, read only in class
//Last validate 20190316
  int      int_FirstTicket;
  int      int_LastTicket;
  //datetime dt_LastTicket_Time;

  //>>LastOrder_Price depend on OrderType, use Max/Min Price
  //20191014: convert to use TTicket[0].dbl_Price;
  //double   dbl_LastMax_Price;
  //double   dbl_LastMin_Price;  
  
  //>>Fact number from Orders
  double   dbl_TTLOpenCost;
  double   dbl_TTLOpenLot;
  double   dbl_WgOpenCost;

  //>>Profit & TP depend on Bid/Ask
  double   dbl_CurrProfit;  //to make quick cut decision >> use ticket.profit
  int      int_CurrOrder;
};

//+------------------------------------------------------------------+
struct trade_Ticket {       //Ticket Array
//Last validate 20190316
  //Order Attributes
  int      int_Magic;       //add 20180919
  int      int_OrderType;   //add 20181115
  int      Cnt_Ticket;      //[i] = ticket ID   , [0] = array Count
  int      int_SLTicket;    //[i] = ticket of original SL
  datetime dt_Time;         //[i] = ticket Time , [0] = Latest Time
  
  double   dbl_OrderLot;    //[i] = lot on ticket,[0] = initial lot to open
  double   dbl_Price;       //[i] = ticket Price, [0] = Buy(MinPrice), Sell(MaxPrice)
  double   dbl_SetSL;       //[i] = ticket SL   , [0] = Latest SL by ticket ID
  double   dbl_SetTP;       //[i] = ticket TP   , [0] = Latest TP by ticket ID  
  double   dbl_Profit;      //[i] = ticket Profit,
  double   dbl_Fee;         //[i] = OrderCommission + OrderSwap
  double   dbl_FirstPrice;  //[0] = Buy(MaxPrice), Sell(MinPrice)

  //Order Actions
  char     chr_PlanID;     //0-99, use to control Exit strategies in magic
  char     chr_ActionPlan; //0>max,  -2= Close, -1= Mod, 0= do nothing, 1= open 1 order, 2= open 2 orders, 3= ...
  string   str_Comment;
  
  //Order Feedback
  bool     b_Alive;
};

//+------------------------------------------------------------------+
struct trade_Order {       //Robot Array
    trade_Ticket TBuyMatch[];   //Dynamic Array per max order
    trade_Ticket TBuyStop[];
    trade_Ticket TBuyLimit[];
    
    trade_Ticket TSellMatch[];
    trade_Ticket TSellStop[];
    trade_Ticket TSellLimit[];
    
    trade_Summary TBuySum;
    trade_Summary TSellSum;

    //sub ticket from Match Order
    trade_Ticket TBuyP10[]; //BuyMatch for strategies Magic#10
    trade_Ticket TBuyP20[]; //BuyMatch for strategies Magic#20
    trade_Ticket TBuyP30[]; //BuyMatch for strategies Magic#30
    trade_Ticket TBuyP40[]; //BuyMatch for strategies Magic#40
    trade_Ticket TSellP10[]; //SellMatch for strategies Magic#10
    trade_Ticket TSellP20[]; //SellMatch for strategies Magic#20
    trade_Ticket TSellP30[]; //SellMatch for strategies Magic#30
    trade_Ticket TSellP40[]; //SellMatch for strategies Magic#40
};

void PrintOnDebug(string strMsg) {
    #ifdef SNTDEBUG
      Print(strMsg);
    #endif 
}

void PrintOnPanel(char chrBotID, string strMsg ,char chrType=1) {
    strMsg = DoubleToString(chrBotID,0)+"/"+strMsg;
    if (chrType == 0) 
      ObjectSetString(0, "MESSAGE", OBJPROP_TEXT, TimeToString(TimeCurrent(), TIME_SECONDS)+": "+strMsg);
    else {
      ObjectSetString(0,"LINE08",OBJPROP_TEXT,ObjectGetString(0,"LINE07",OBJPROP_TEXT));
      ObjectSetString(0,"LINE07",OBJPROP_TEXT,ObjectGetString(0,"LINE06",OBJPROP_TEXT));
      ObjectSetString(0,"LINE06",OBJPROP_TEXT,ObjectGetString(0,"LINE05",OBJPROP_TEXT));
      ObjectSetString(0,"LINE05",OBJPROP_TEXT,ObjectGetString(0,"LINE04",OBJPROP_TEXT));
      ObjectSetString(0,"LINE04",OBJPROP_TEXT,ObjectGetString(0,"LINE03",OBJPROP_TEXT));
      ObjectSetString(0,"LINE03",OBJPROP_TEXT,ObjectGetString(0,"LINE02",OBJPROP_TEXT));
      ObjectSetString(0,"LINE02",OBJPROP_TEXT,ObjectGetString(0,"LINE01",OBJPROP_TEXT));
      ObjectSetString(0,"LINE01",OBJPROP_TEXT,TimeToString(TimeCurrent(), TIME_SECONDS)+": "+strMsg);
    }
}

double MathFibo(int iCount) {
    int first =0;
    int second =1;
    int sum =0;
    
    if (iCount == 0) return(first);
    else {
      if (iCount == 1) return(second);
      else {
        for (int iPos = 2 ; iPos <= iCount; iPos++) {
          sum = first + second;
          first = second;
          second = sum;
        }//for
        return(sum);
      }//else
    }//else     
}

double MathFiboSum(int iCount) {
    int first =0;
    int second =1;
    int sum =0;
    int total =0;
    
    iCount = iCount+1;
    if (iCount == 0) return(first);
    else {
      if (iCount == 1) return(second);
      else {
        for (int iPos = 2 ; iPos <= iCount; iPos++) {
          sum = first + second;
          first = second;
          second = sum;
          total +=sum;
        }//for
        return(total);
      }//else
    }//else     
}

double MathPower(int iMethod, double dLotMulti, int iCount) {
    switch (iMethod)
    {
      case A_POW:
        return(MathPow(dLotMulti, iCount));
        break;//A_POW
        
      case B_FIB:
        return(MathFibo(iCount+2)); //skip first 2 number
        break;//B_FIB

      case C_ADD:
        return(iCount+1);
        break;//C_ADD
    }//switch  
  
    return(0);
}

int MathRepeatLot(int iCount ,int iRepeatLot) {
    if (iRepeatLot <= 1) return(iCount);
    
    //convert from OrderCount to newOrderCount
    //user this new orderCount for iCount in MathPower(LotMulti)
    return((int)MathFloor(iCount/(1.0*iRepeatLot)+(1-2/(1.0*iRepeatLot)))+1);
}




#endif  //End of include guard