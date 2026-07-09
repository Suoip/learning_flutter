import 'package:flutter/material.dart';
import '../resources_and_services/calculator_buttons_and_logic.dart';

void main() => runApp(const CalculatorApp());

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(debugShowCheckedModeBanner: false, home: Home());
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Calculator'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: const SafeArea(child: Body()),
    );
  }
}

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final CalculatorLogic _logic = CalculatorLogic();

  static const Color _numberFill = Color(0xFF333333);
  static const Color _numberText = Color(0xFFF1F1F1);
  static const Color _operatorFill = Color(0xFFFF9F0A);
  static const Color _topRowFill = Color(0xFFA5A5A5);
  static const Color _topRowText = Color(0xFF1C1C1C);

  void _onDigitPressed(String digit) {
    setState(() {
      _logic.onDigitPressed(digit);
    });
  }

  void _onDecimalPressed() {
    setState(() {
      _logic.onDecimalPressed();
    });
  }

  void _onClearPressed() {
    setState(() {
      _logic.onClearPressed();
    });
  }

  void _onToggleSignPressed() {
    setState(() {
      _logic.onToggleSignPressed();
    });
  }

  void _onPercentPressed() {
    setState(() {
      _logic.onPercentPressed();
    });
  }

  void _onOperatorPressed(String operator) {
    setState(() {
      _logic.onOperatorPressed(operator);
    });
  }

  void _onEqualsPressed() {
    setState(() {
      _logic.onEqualsPressed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      child: Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 10, bottom: 14),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _logic.display,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 92,
                      fontWeight: FontWeight.w300,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buttonRow([
            calculatorNormalButton(
              'AC',
              onPressed: _onClearPressed,
              fillColor: _topRowFill,
              textColor: _topRowText,
            ),
            calculatorNormalButton(
              '+/-',
              onPressed: _onToggleSignPressed,
              fillColor: _topRowFill,
              textColor: _topRowText,
            ),
            calculatorNormalButton(
              '%',
              onPressed: _onPercentPressed,
              fillColor: _topRowFill,
              textColor: _topRowText,
            ),
            calculatorNormalButton(
              '÷',
              onPressed: () => _onOperatorPressed('÷'),
              fillColor: _operatorFill,
              textColor: Colors.white,
            ),
          ]),
          _buttonRow([
            calculatorNormalButton(
              '7',
              onPressed: () => _onDigitPressed('7'),
              fillColor: _numberFill,
              textColor: _numberText,
            ),
            calculatorNormalButton(
              '8',
              onPressed: () => _onDigitPressed('8'),
              fillColor: _numberFill,
              textColor: _numberText,
            ),
            calculatorNormalButton(
              '9',
              onPressed: () => _onDigitPressed('9'),
              fillColor: _numberFill,
              textColor: _numberText,
            ),
            calculatorNormalButton(
              '×',
              onPressed: () => _onOperatorPressed('×'),
              fillColor: _operatorFill,
              textColor: Colors.white,
            ),
          ]),
          _buttonRow([
            calculatorNormalButton(
              '4',
              onPressed: () => _onDigitPressed('4'),
              fillColor: _numberFill,
              textColor: _numberText,
            ),
            calculatorNormalButton(
              '5',
              onPressed: () => _onDigitPressed('5'),
              fillColor: _numberFill,
              textColor: _numberText,
            ),
            calculatorNormalButton(
              '6',
              onPressed: () => _onDigitPressed('6'),
              fillColor: _numberFill,
              textColor: _numberText,
            ),
            calculatorNormalButton(
              '-',
              onPressed: () => _onOperatorPressed('-'),
              fillColor: _operatorFill,
              textColor: Colors.white,
            ),
          ]),
          _buttonRow([
            calculatorNormalButton(
              '1',
              onPressed: () => _onDigitPressed('1'),
              fillColor: _numberFill,
              textColor: _numberText,
            ),
            calculatorNormalButton(
              '2',
              onPressed: () => _onDigitPressed('2'),
              fillColor: _numberFill,
              textColor: _numberText,
            ),
            calculatorNormalButton(
              '3',
              onPressed: () => _onDigitPressed('3'),
              fillColor: _numberFill,
              textColor: _numberText,
            ),
            calculatorNormalButton(
              '+',
              onPressed: () => _onOperatorPressed('+'),
              fillColor: _operatorFill,
              textColor: Colors.white,
            ),
          ]),
          _buttonRow([
            calculatorWideButton(
              '0',
              onPressed: () => _onDigitPressed('0'),
              fillColor: _numberFill,
              textColor: _numberText,
            ),
            calculatorNormalButton(
              '.',
              onPressed: _onDecimalPressed,
              fillColor: _numberFill,
              textColor: Colors.white,
            ),
            calculatorNormalButton(
              '=',
              onPressed: _onEqualsPressed,
              fillColor: _operatorFill,
              textColor: Colors.white,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buttonRow(List<Widget> buttons) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: buttons,
      ),
    );
  }
}
