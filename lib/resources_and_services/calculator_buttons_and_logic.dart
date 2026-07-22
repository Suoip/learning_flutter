import 'package:flutter/material.dart';

Widget calculatorNormalButton(
  String text, {
  required VoidCallback onPressed,
  Color fillColor = Colors.white,
  Color textColor = Colors.black,
}) {
  return SizedBox(
    width: 78,
    height: 78,
    child: RawMaterialButton(
      onPressed: onPressed,
      fillColor: fillColor,
      shape: const CircleBorder(),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 34,
          color: textColor,
        ),
      ),
    ),
  );
}

Widget calculatorWideButton(
  String text, {
  required VoidCallback onPressed,
  Color fillColor = Colors.white,
  Color textColor = Colors.black,
}) {
  return SizedBox(
    width: 168,
    height: 78,
    child: RawMaterialButton(
      onPressed: onPressed,
      fillColor: fillColor,
      shape: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.only(left: 18),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 34,
              color: textColor,
            ),
          ),
        ),
      ),
    ),
  );
}

class CalculatorLogic {
  String _display;
  double? _storedValue;
  String? _pendingOperator;
  bool _isTypingNewNumber;

  CalculatorLogic({
    String initialDisplay = '0',
  })  : _display = initialDisplay,
        _isTypingNewNumber = true;

  String get display => _display;

  void onDigitPressed(String digit) {
    if (_isTypingNewNumber || _display == '0') {
      _display = digit;
    } else {
      _display += digit;
    }
    _isTypingNewNumber = false;
  }

  void onDecimalPressed() {
    if (_isTypingNewNumber) {
      _display = '0.';
      _isTypingNewNumber = false;
      return;
    }

    if (!_display.contains('.')) {
      _display += '.';
    }
  }

  void onClearPressed() {
    _display = '0';
    _storedValue = null;
    _pendingOperator = null;
    _isTypingNewNumber = true;
  }

  void onToggleSignPressed() {
    if (_display == '0') {
      return;
    }

    if (_display.startsWith('-')) {
      _display = _display.substring(1);
    } else {
      _display = '-$_display';
    }
  }

  void onPercentPressed() {
    final value = double.tryParse(_display) ?? 0;
    final result = value / 100;
    _display = _formatNumber(result);
    _isTypingNewNumber = true;
  }

  void onOperatorPressed(String operator) {
    final current = double.tryParse(_display) ?? 0;

    if (_pendingOperator != null && !_isTypingNewNumber) {
      _storedValue = _calculate(_storedValue ?? 0, current, _pendingOperator!);
      _display = _formatNumber(_storedValue!);
    } else {
      _storedValue = current;
    }

    _pendingOperator = operator;
    _isTypingNewNumber = true;
  }

  void onEqualsPressed() {
    final current = double.tryParse(_display) ?? 0;
    if (_pendingOperator == null || _storedValue == null) {
      return;
    }

    final result = _calculate(_storedValue!, current, _pendingOperator!);
    _display = _formatNumber(result);
    _storedValue = result;
    _pendingOperator = null;
    _isTypingNewNumber = true;
  }

  double _calculate(double left, double right, String operator) {
    switch (operator) {
      case '+':
        return left + right;
      case '-':
        return left - right;
      case '×':
        return left * right;
      case '÷':
        if (right == 0) {
          return double.infinity;
        }
        return left / right;
      default:
        return right;
    }
  }

  String _formatNumber(double value) {
    if (value.isNaN || value.isInfinite) {
      return 'Error';
    }

    final fixed = value.toStringAsFixed(10);
    final cleaned =
        fixed.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');

    if (cleaned == '-0') {
      return '0';
    }

    return cleaned;
  }
}
