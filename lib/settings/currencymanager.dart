import 'package:flutter/material.dart';
import '../DataBase/sharedpreferences.dart';

class CurrencyManager extends ChangeNotifier {
  static final CurrencyManager _instance = CurrencyManager._internal();

  factory CurrencyManager() {
    return _instance;
  }

  CurrencyManager._internal();

  String _currencySymbol = "\$";
  static String cr = "\$";

  String get currentCurrency => _currencySymbol;

  Future<void> updateCurrency(String symbol) async {
    _currencySymbol = symbol;
    cr = symbol;
    await SharedPreferenceHelper.save(value: symbol, prefKey: PrefKey.currencySymbol);
    notifyListeners();
  }

  Future<void> loadCurrency() async {
    _currencySymbol = await SharedPreferenceHelper.get(prefKey: PrefKey.currencySymbol) ?? "\$";
    cr = _currencySymbol;
    notifyListeners();
  }
}
