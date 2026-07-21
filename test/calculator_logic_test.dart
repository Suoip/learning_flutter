import 'package:flutter_test/flutter_test.dart';
import 'package:new_project/resources_and_services/calculator_buttons_and_logic.dart';

void main() {
  group('CalculatorLogic', () {
    late CalculatorLogic calc;

    setUp(() {
      calc = CalculatorLogic();
    });

    test('starts with a display of 0', () {
      expect(calc.display, '0');
    });

    group('digit entry', () {
      test('replaces the leading zero with the first digit', () {
        calc.onDigitPressed('7');
        expect(calc.display, '7');
      });

      test('appends subsequent digits', () {
        calc.onDigitPressed('1');
        calc.onDigitPressed('2');
        calc.onDigitPressed('3');
        expect(calc.display, '123');
      });

      test('does not keep a leading zero when a digit follows', () {
        calc.onDigitPressed('0');
        calc.onDigitPressed('5');
        expect(calc.display, '5');
      });
    });

    group('decimal point', () {
      test('creates "0." when typing a fresh number', () {
        calc.onDecimalPressed();
        expect(calc.display, '0.');
      });

      test('appends a decimal point to the current number', () {
        calc.onDigitPressed('1');
        calc.onDecimalPressed();
        calc.onDigitPressed('5');
        expect(calc.display, '1.5');
      });

      test('ignores a second decimal point', () {
        calc.onDigitPressed('1');
        calc.onDecimalPressed();
        calc.onDecimalPressed();
        calc.onDigitPressed('5');
        expect(calc.display, '1.5');
      });
    });

    group('clear', () {
      test('resets the display to 0', () {
        calc.onDigitPressed('4');
        calc.onDigitPressed('2');
        calc.onClearPressed();
        expect(calc.display, '0');
      });

      test('clears any pending operation', () {
        calc.onDigitPressed('5');
        calc.onOperatorPressed('+');
        calc.onClearPressed();
        calc.onDigitPressed('3');
        calc.onEqualsPressed();
        // With the pending "+" cleared, equals is a no-op and 3 remains.
        expect(calc.display, '3');
      });
    });

    group('toggle sign', () {
      test('leaves zero unchanged', () {
        calc.onToggleSignPressed();
        expect(calc.display, '0');
      });

      test('negates a positive number and back again', () {
        calc.onDigitPressed('5');
        calc.onToggleSignPressed();
        expect(calc.display, '-5');
        calc.onToggleSignPressed();
        expect(calc.display, '5');
      });
    });

    group('arithmetic', () {
      test('adds two numbers', () {
        calc.onDigitPressed('2');
        calc.onOperatorPressed('+');
        calc.onDigitPressed('3');
        calc.onEqualsPressed();
        expect(calc.display, '5');
      });

      test('subtracts two numbers', () {
        calc.onDigitPressed('7');
        calc.onOperatorPressed('-');
        calc.onDigitPressed('2');
        calc.onEqualsPressed();
        expect(calc.display, '5');
      });

      test('multiplies two numbers', () {
        calc.onDigitPressed('4');
        calc.onOperatorPressed('×');
        calc.onDigitPressed('5');
        calc.onEqualsPressed();
        expect(calc.display, '20');
      });

      test('divides two numbers', () {
        calc.onDigitPressed('2');
        calc.onDigitPressed('0');
        calc.onOperatorPressed('÷');
        calc.onDigitPressed('4');
        calc.onEqualsPressed();
        expect(calc.display, '5');
      });

      test('reports an error when dividing by zero', () {
        calc.onDigitPressed('5');
        calc.onOperatorPressed('÷');
        calc.onDigitPressed('0');
        calc.onEqualsPressed();
        expect(calc.display, 'Error');
      });

      test('chains operators, evaluating the previous one', () {
        // 2 + 3 shows the running total (5) as soon as the next "+" arrives,
        // then + 4 = 9.
        calc.onDigitPressed('2');
        calc.onOperatorPressed('+');
        calc.onDigitPressed('3');
        calc.onOperatorPressed('+');
        expect(calc.display, '5');
        calc.onDigitPressed('4');
        calc.onEqualsPressed();
        expect(calc.display, '9');
      });

      test('equals with no pending operator does nothing', () {
        calc.onDigitPressed('5');
        calc.onEqualsPressed();
        expect(calc.display, '5');
      });
    });

    group('percent', () {
      test('divides the current value by 100', () {
        calc.onDigitPressed('5');
        calc.onDigitPressed('0');
        calc.onPercentPressed();
        expect(calc.display, '0.5');
      });
    });

    group('number formatting', () {
      test('trims floating-point noise from results', () {
        // 0.1 + 0.2 is 0.30000000000000004 in IEEE-754; the display should
        // clean that up to "0.3".
        calc.onDigitPressed('0');
        calc.onDecimalPressed();
        calc.onDigitPressed('1');
        calc.onOperatorPressed('+');
        calc.onDigitPressed('0');
        calc.onDecimalPressed();
        calc.onDigitPressed('2');
        calc.onEqualsPressed();
        expect(calc.display, '0.3');
      });

      test('drops a trailing ".0" from whole-number results', () {
        calc.onDigitPressed('6');
        calc.onOperatorPressed('÷');
        calc.onDigitPressed('2');
        calc.onEqualsPressed();
        expect(calc.display, '3');
      });
    });
  });
}
