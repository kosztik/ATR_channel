//+------------------------------------------------------------------+
//|                                                  ATR_Channel.mq4 |
//|                        Copyright 2025, MetaQuotes Software Corp. |
//|                                              https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1  DodgerBlue // Middle Line
#property indicator_color2  Red        // Upper Band
#property indicator_color3  Red        // Lower Band
#property indicator_style1  STYLE_SOLID
#property indicator_style2  STYLE_DASH
#property indicator_style3  STYLE_DASH
#property indicator_width1  2
#property indicator_width2  1
#property indicator_width3  1

//---- input parameters
input int MAPeriod = 20;                // Moving Average Period
input ENUM_MA_METHOD MAMethod = MODE_EMA; // Moving Average Method
input ENUM_APPLIED_PRICE MAPrice = PRICE_CLOSE; // Applied Price for MA
input int ATRPeriod = 14;               // ATR Period
input double ATRMultiplier = 2.0;      // ATR Multiplier

//---- indicator buffers
double MiddleBuffer[];
double UpperBuffer[];
double LowerBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
  //--- indicator buffers mapping
  SetIndexBuffer(0, MiddleBuffer);
  SetIndexBuffer(1, UpperBuffer);
  SetIndexBuffer(2, LowerBuffer);

  //--- setting labels for indicator lines
  SetIndexLabel(0, "MA(" + IntegerToString(MAPeriod) + ")");
  SetIndexLabel(1, "Upper Band");
  SetIndexLabel(2, "Lower Band");

  //--- setting styles
  SetIndexStyle(0, DRAW_LINE);
  SetIndexStyle(1, DRAW_LINE);
  SetIndexStyle(2, DRAW_LINE);

  //--- set drawing begin
  int draw_begin = MathMax(MAPeriod, ATRPeriod);
  SetIndexDrawBegin(0, draw_begin);
  SetIndexDrawBegin(1, draw_begin);
  SetIndexDrawBegin(2, draw_begin);

  //--- indicator digits
  IndicatorDigits(Digits); // Use Digits of the current symbol

  //--- name for DataWindow and indicator subwindow label
  IndicatorShortName(
    "ATR Ch(" + IntegerToString(MAPeriod) + "," +
    IntegerToString(ATRPeriod) + "," + DoubleToString(ATRMultiplier, 1) + ")"
  );

  return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(
  const int rates_total,      // size of the price[] array
  const int prev_calculated,  // bars calculated at previous call
  const datetime &time[],     // time array
  const double &open[],       // open price array
  const double &high[],       // high price array
  const double &low[],        // low price array
  const double &close[],      // close price array
  const long &tick_volume[],  // tick volume array
  const long &real_volume[],  // real volume array
  const int &spread[]         // spread array
) {
  //--- check for rates
  if (rates_total < MathMax(MAPeriod, ATRPeriod)) {
    return (0); // not enough bars for calculation
  }

  //--- define bars to calculate
  int start_bar_idx;
  if (prev_calculated == 0) { // first calculation
    start_bar_idx = rates_total - 1;
  } else {
    start_bar_idx = rates_total - prev_calculated;
  }
  // Ensure we don't try to access negative indices if prev_calculated is too large
  if (start_bar_idx >= rates_total) {
      start_bar_idx = rates_total - 1;
  }
  if (start_bar_idx < 0) { // Should not happen with correct prev_calculated
      start_bar_idx = 0;
  }


  //--- main calculation loop
  for (int i = start_bar_idx; i >= 0; i--) {
    // Calculate Middle Line (Moving Average)
    MiddleBuffer[i] = iMA(NULL, 0, MAPeriod, 0, MAMethod, MAPrice, i);

    // Calculate ATR
    double atr_value = iATR(NULL, 0, ATRPeriod, i);

    if (
      MiddleBuffer[i] != EMPTY_VALUE && atr_value != EMPTY_VALUE &&
      atr_value > 0.000000001 // Check ATR is not zero or negative
    ) {
      UpperBuffer[i] = MiddleBuffer[i] + ATRMultiplier * atr_value;
      LowerBuffer[i] = MiddleBuffer[i] - ATRMultiplier * atr_value;
    } else {
      // If MA or ATR is not calculable, set bands to empty as well
      // MiddleBuffer[i] might already be EMPTY_VALUE from iMA
      if (MiddleBuffer[i] == EMPTY_VALUE) {
          UpperBuffer[i] = EMPTY_VALUE;
          LowerBuffer[i] = EMPTY_VALUE;
      } else { // ATR is problematic, but MA is fine. Still, can't draw bands.
          UpperBuffer[i] = EMPTY_VALUE; // Or could set to MiddleBuffer[i] if preferred
          LowerBuffer[i] = EMPTY_VALUE; // Or could set to MiddleBuffer[i]
      }
    }
  }
  //--- return value of prev_calculated for next call
  return (rates_total);
}
//+------------------------------------------------------------------+
