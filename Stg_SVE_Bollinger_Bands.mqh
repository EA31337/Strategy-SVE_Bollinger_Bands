/**
 * @file
 * Implements strategy based on the SVE Bollinger Bands indicator.
 */

// User input params.
INPUT string __SVE_Bollinger_Bands_Strategy_Params__ =
    "-- SVE Bollinger Bands strategy params --";           // >>> SVE Bollinger Bands strategy <<<
INPUT float SVE_Bollinger_Bands_LotSize = 0;               // Lot size
INPUT int SVE_Bollinger_Bands_SignalOpenMethod = 0;        // Signal open method
INPUT int SVE_Bollinger_Bands_SignalOpenFilterMethod = 1;  // Signal open filter method
INPUT float SVE_Bollinger_Bands_SignalOpenLevel = 0.0f;    // Signal open level
INPUT int SVE_Bollinger_Bands_SignalOpenBoostMethod = 0;   // Signal open boost method
INPUT int SVE_Bollinger_Bands_SignalCloseMethod = 0;       // Signal close method
INPUT float SVE_Bollinger_Bands_SignalCloseLevel = 0.0f;   // Signal close level
INPUT int SVE_Bollinger_Bands_PriceStopMethod = 0;         // Price stop method
INPUT float SVE_Bollinger_Bands_PriceStopLevel = 2;        // Price stop level
INPUT int SVE_Bollinger_Bands_TickFilterMethod = 1;        // Tick filter method
INPUT float SVE_Bollinger_Bands_MaxSpread = 4.0;           // Max spread to trade (in pips)
INPUT short SVE_Bollinger_Bands_Shift = 0;                 // Strategy Shift (relative to the current bar, 0 - default)
INPUT int SVE_Bollinger_Bands_OrderCloseTime = -20;        // Order close time in mins (>0) or bars (<0)

// Structs.

// Defines struct with default user strategy values.
struct Stg_SVE_Bollinger_Bands_Params_Defaults : StgParams {
  Stg_SVE_Bollinger_Bands_Params_Defaults()
      : StgParams(::SVE_Bollinger_Bands_SignalOpenMethod, ::SVE_Bollinger_Bands_SignalOpenFilterMethod,
                  ::SVE_Bollinger_Bands_SignalOpenLevel, ::SVE_Bollinger_Bands_SignalOpenBoostMethod,
                  ::SVE_Bollinger_Bands_SignalCloseMethod, ::SVE_Bollinger_Bands_SignalCloseLevel,
                  ::SVE_Bollinger_Bands_PriceStopMethod, ::SVE_Bollinger_Bands_PriceStopLevel,
                  ::SVE_Bollinger_Bands_TickFilterMethod, ::SVE_Bollinger_Bands_MaxSpread, ::SVE_Bollinger_Bands_Shift,
                  ::SVE_Bollinger_Bands_OrderCloseTime) {}
} stg_svebbands_defaults;

// Defines struct to store indicator and strategy params.
struct Stg_SVE_Bollinger_Bands_Params {
  Indi_SVE_Bollinger_Bands_Params iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_SVE_Bollinger_Bands_Params(Indi_SVE_Bollinger_Bands_Params &_iparams, StgParams &_sparams)
      : iparams(indi_svebbands_defaults, _iparams.tf), sparams(stg_svebbands_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_SVE_Bollinger_Bands : public Strategy {
 public:
  Stg_SVE_Bollinger_Bands(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_SVE_Bollinger_Bands *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL,
                                       ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Indi_SVE_Bollinger_Bands_Params _indi_params(indi_svebbands_defaults, _tf);
    StgParams _stg_params(stg_svebbands_defaults);
#ifdef __config__
    SetParamsByTf<Indi_SVE_Bollinger_Bands_Params>(_indi_params, _tf, indi_svebbands_m1, indi_svebbands_m5,
                                                   indi_svebbands_m15, indi_svebbands_m30, indi_svebbands_h1,
                                                   indi_svebbands_h4, indi_svebbands_h4);
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_svebbands_m1, stg_svebbands_m5, stg_svebbands_m15, stg_svebbands_m30,
                             stg_svebbands_h1, stg_svebbands_h4, stg_svebbands_h4);
#endif
    // Initialize indicator.
    _stg_params.SetIndicator(new Indi_SVE_Bollinger_Bands(_indi_params));
    // Initialize strategy parameters.
    _stg_params.GetLog().SetLevel(_log_level);
    _stg_params.SetMagicNo(_magic_no);
    _stg_params.SetTf(_tf, _Symbol);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_SVE_Bollinger_Bands(_stg_params, "SVE BB");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indicator *_indi = GetIndicator();
    bool _is_valid = _indi[CURR].IsValid();
    bool _result = _is_valid;
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    double level = _level * Chart().GetPipSize();
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result = _indi[CURR][(int)SVE_BAND_MAIN] < _indi[CURR][(int)SVE_BAND_LOWER];
        if (_method != 0) {
          if (METHOD(_method, 0)) _result &= fmin(Close[PREV], Close[PPREV]) < _indi[CURR][(int)SVE_BAND_LOWER];
          if (METHOD(_method, 1)) _result &= (_indi[CURR][(int)SVE_BAND_LOWER] > _indi[PPREV][(int)SVE_BAND_LOWER]);
          if (METHOD(_method, 2)) _result &= (_indi[CURR][(int)SVE_BAND_MAIN] > _indi[PPREV][(int)SVE_BAND_MAIN]);
          if (METHOD(_method, 3)) _result &= (_indi[CURR][(int)SVE_BAND_UPPER] > _indi[PPREV][(int)SVE_BAND_UPPER]);
          if (METHOD(_method, 4)) _result &= Open[CURR] < _indi[CURR][(int)SVE_BAND_MAIN];
          if (METHOD(_method, 5)) _result &= fmin(Close[PREV], Close[PPREV]) > _indi[CURR][(int)SVE_BAND_MAIN];
        }
        break;
      case ORDER_TYPE_SELL:
        _result = _indi[CURR][(int)SVE_BAND_MAIN] > _indi[CURR][(int)SVE_BAND_UPPER];
        if (_method != 0) {
          if (METHOD(_method, 0)) _result &= fmin(Close[PREV], Close[PPREV]) > _indi[CURR][(int)SVE_BAND_UPPER];
          if (METHOD(_method, 1)) _result &= (_indi[CURR][(int)SVE_BAND_LOWER] < _indi[PPREV][(int)SVE_BAND_LOWER]);
          if (METHOD(_method, 2)) _result &= (_indi[CURR][(int)SVE_BAND_MAIN] < _indi[PPREV][(int)SVE_BAND_MAIN]);
          if (METHOD(_method, 3)) _result &= (_indi[CURR][(int)SVE_BAND_UPPER] < _indi[PPREV][(int)SVE_BAND_UPPER]);
          if (METHOD(_method, 4)) _result &= Open[CURR] > _indi[CURR][(int)SVE_BAND_MAIN];
          if (METHOD(_method, 5)) _result &= fmin(Close[PREV], Close[PPREV]) < _indi[CURR][(int)SVE_BAND_MAIN];
        }
        break;
    }
    return _result;
  }

  /**
   * Gets price stop value for profit take or stop loss.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0f) {
    Indi_SVE_Bollinger_Bands *_indi = GetIndicator();
    double _trail = _level * Market().GetPipSize();
    // int _bar_count = (int)_level * 10;
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    switch (_method) {
      case 1:
        _result = (_direction > 0 ? _indi[CURR][(int)SVE_BAND_UPPER] : _indi[CURR][(int)SVE_BAND_LOWER]) +
                  _trail * _direction;
        break;
      case 2:
        _result = (_direction > 0 ? _indi[PREV][(int)SVE_BAND_UPPER] : _indi[PREV][(int)SVE_BAND_LOWER]) +
                  _trail * _direction;
        break;
      case 3:
        _result = (_direction > 0 ? _indi[PPREV][(int)SVE_BAND_UPPER] : _indi[PPREV][(int)SVE_BAND_LOWER]) +
                  _trail * _direction;
        break;
      case 4:
        _result = (_direction > 0 ? fmax(_indi[PREV][(int)SVE_BAND_UPPER], _indi[PPREV][(int)SVE_BAND_UPPER])
                                  : fmin(_indi[PREV][(int)SVE_BAND_LOWER], _indi[PPREV][(int)SVE_BAND_LOWER])) +
                  _trail * _direction;
        break;
      case 5:
        _result = _indi[CURR][(int)SVE_BAND_MAIN] + _trail * _direction;
        break;
      case 6:
        _result = _indi[PREV][(int)SVE_BAND_MAIN] + _trail * _direction;
        break;
      case 7:
        _result = _indi[PPREV][(int)SVE_BAND_MAIN] + _trail * _direction;
        break;
      case 8: {
        int _bar_count8 = (int)round(_level * _indi.params.GetSvePeriod());
        _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest<double>(_bar_count8))
                                 : _indi.GetPrice(PRICE_LOW, _indi.GetLowest<double>(_bar_count8));
        break;
      }
      case 9: {
        int _bar_count9 = (int)round(_level * _indi.params.GetTEMAPeriod());
        _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest<double>(_bar_count9))
                                 : _indi.GetPrice(PRICE_LOW, _indi.GetLowest<double>(_bar_count9));
        break;
      }
    }
    return (float)_result;
  }
};
