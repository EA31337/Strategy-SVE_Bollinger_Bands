/*
 * @file
 * Defines strategy's and indicator's default parameter values
 * for the given pair symbol and timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_SVE_Bollinger_Bands_Params_M30 : Indi_SVE_Bollinger_Bands_Params {
  Indi_SVE_Bollinger_Bands_Params_M30() : Indi_SVE_Bollinger_Bands_Params(stg_svebb_indi_svebb_defaults, PERIOD_M30) {
    shift = 0;
  }
} indi_svebbands_m30;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_SVE_Bollinger_Bands_Params_M30 : StgParams {
  // Struct constructor.
  Stg_SVE_Bollinger_Bands_Params_M30() : StgParams(stg_svebbands_defaults) {
    lot_size = 0;
    signal_open_method = 2;
    signal_open_level = (float)0;
    signal_open_boost = 0;
    signal_close_method = 2;
    signal_close_level = (float)0;
    price_profit_method = 60;
    price_profit_level = (float)6;
    price_stop_method = 60;
    price_stop_level = (float)6;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_svebbands_m30;
