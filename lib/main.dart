import 'package:flutter/material.dart';
import 'db_helper.dart';

void main() {
  runApp(CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blueGrey[900],
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w300,
            color: Colors.white,
            fontFamily: 'RobotoMono',
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: Colors.blueGrey[800],
            fontFamily: 'Roboto',
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.blueGrey[800],
            elevation: 8,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: EdgeInsets.all(20),
            textStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto',
            ),
          ),
        ),
      ),
      home: CalculatorHome(),
    );
  }
}

class CalculatorHome extends StatefulWidget {
  @override
  _CalculatorHomeState createState() => _CalculatorHomeState();
}

class _CalculatorHomeState extends State<CalculatorHome> {
  String _display = '0';
  String _operation = '';
  double _num1 = 0;
  String _num2Input = '';
  String? _errorMessage;
  List<Calculation> _history = [];
  final DBHelper _dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final maps = await _dbHelper.getCalculations();
    setState(() {
      _history = List.generate(maps.length, (i) {
        return Calculation(
          id: maps[i]['id'],
          expression: maps[i]['expression'],
          result: maps[i]['result'],
        );
      });
    });
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (_errorMessage != null) {
        _display = number;
        _num2Input = number;
        _errorMessage = null;
      } else if (_operation.isEmpty) {
        // Entering first number
        if (_display == '0') {
          _display = number;
        } else {
          _display += number;
        }
      } else {
        // Entering second number
        _num2Input += number;
        _display = '${_formatNumber(_num1)} $_operation $_num2Input';
      }
    });
  }

  void _onOperatorPressed(String operator) {
    setState(() {
      try {
        if (_display.isEmpty || _display == '0') return;
        _num1 = double.parse(_operation.isEmpty ? _display : _num2Input);
        _operation = operator;
        _num2Input = '';
        _display = '${_formatNumber(_num1)} $_operation ';
        _errorMessage = null;
      } catch (e) {
        _errorMessage = 'Invalid Input';
      }
    });
  }

  String _formatNumber(double number) {
    if (number == number.toInt()) {
      return number.toInt().toString();
    } else {
      return number.toStringAsFixed(2);
    }
  }

  String _removeLeadingZeros(String number) {
    return double.parse(number).toStringAsFixed(0);
  }

  void _onEqualPressed() {
    try {
      if (_num2Input.isEmpty || _operation.isEmpty) return;
      double num2 = double.parse(_num2Input);
      double result = 0;
      String expression = '${_removeLeadingZeros(_num1.toString())} $_operation ${_removeLeadingZeros(_num2Input)}';

      switch (_operation) {
        case '+':
          result = _num1 + num2;
          break;
        case '-':
          result = _num1 - num2;
          break;
        case '*':
          result = _num1 * num2;
          break;
        case '/':
          if (num2 != 0) {
            result = _num1 / num2;
          } else {
            result = double.infinity;
            _errorMessage = 'Division by Zero';
          }
          break;
        default:
          return;
      }

      setState(() {
        _display = _errorMessage ?? _formatNumber(result);
        if (_operation.isNotEmpty && _errorMessage == null) {
          _dbHelper.insertCalculation(expression, _formatNumber(result));
          _loadHistory();
        }
        _operation = '';
        _num1 = 0;
        _num2Input = '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid Input';
        _display = '0';
      });
    }
  }

  void _onClearPressed() {
    setState(() {
      _display = '0';
      _operation = '';
      _num1 = 0;
      _num2Input = '';
      _errorMessage = null;
    });
  }

  void _onDeleteHistory() async {
    await _dbHelper.clearHistory();
    _loadHistory();
  }

  @override
  void dispose() {
    _dbHelper.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Calculator',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueGrey[900],
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueGrey[800]!, Colors.blueGrey[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Text(
              _errorMessage ?? (_display.isEmpty ? '0' : _display),
              style: Theme.of(context).textTheme.displayLarge!.copyWith(
                color: _errorMessage != null ? Colors.red[300] : Colors.white,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Text(
                      '${_history[index].expression} = ${_history[index].result}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildButton('7'),
                    SizedBox(width: 8),
                    _buildButton('8'),
                    SizedBox(width: 8),
                    _buildButton('9'),
                    SizedBox(width: 8),
                    _buildButton('/', color: Colors.orange[400]),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    _buildButton('4'),
                    SizedBox(width: 8),
                    _buildButton('5'),
                    SizedBox(width: 8),
                    _buildButton('6'),
                    SizedBox(width: 8),
                    _buildButton('*', color: Colors.orange[400]),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    _buildButton('1'),
                    SizedBox(width: 8),
                    _buildButton('2'),
                    SizedBox(width: 8),
                    _buildButton('3'),
                    SizedBox(width: 8),
                    _buildButton('-', color: Colors.orange[400]),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    _buildButton('0'),
                    SizedBox(width: 8),
                    _buildButton('C', color: Colors.red[400], onPressed: _onClearPressed),
                    SizedBox(width: 8),
                    _buildButton('=', color: Colors.green[400], onPressed: _onEqualPressed),
                    SizedBox(width: 8),
                    _buildButton('+', color: Colors.orange[400]),
                  ],
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _onDeleteHistory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[800],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text('Clear History', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, {VoidCallback? onPressed, Color? color}) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed ??
                () {
              if (text == '+' || text == '-' || text == '*' || text == '/') {
                _onOperatorPressed(text);
              } else {
                _onNumberPressed(text);
              }
            },
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.white,
          foregroundColor: color != null ? Colors.white : Colors.blueGrey[800],
          elevation: 6,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: EdgeInsets.all(20),
        ),
        child: Text(text, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class Calculation {
  final int id;
  final String expression;
  final String result;

  Calculation({required this.id, required this.expression, required this.result});
}