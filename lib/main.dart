import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guessnumber/utils/color_util.dart';
void main() {
  runApp(NumberGuessingGame());
}

class NumberGuessingGame extends StatefulWidget {
  @override
  _NumberGuessingGameState createState() => _NumberGuessingGameState();
}

class _NumberGuessingGameState extends State<NumberGuessingGame> {
  Random random = Random();
  late int targetNumber;
  late int attempts;
  late String feedback;

  @override
  void initState() {
    super.initState();
    startNewGame();
  }

  void startNewGame() {
    targetNumber = random.nextInt(100) + 1;
    attempts = 0;
    feedback = "";
  }

  void checkGuess(int guess) {
    setState(() {
      attempts++;

      if (guess == targetNumber) {
        feedback = 'Congratulations! You guessed the correct number in $attempts attempts.';
      } else if (guess < targetNumber) {
        feedback = 'Too low! Try again.';
      } else {
        feedback = 'Too high! Try again.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Number Guessing Game'),
        ),
        body: Center(
          child: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  hexStringToColor("CB2B93"),
                  hexStringToColor("9546C4"),
                  hexStringToColor("5E61F4")
                ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Guess the number between 1 and 100',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white,fontSize: 20.0),
                ),
                SizedBox(height: 20.0),
                Text(
                  feedback,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white,fontSize: 20.0),
                ),
                SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () => startNewGame(),
                  child: Text('Start New Game'),
                ),
                SizedBox(height: 20.0),
                GuessInputForm(checkGuess),
                SizedBox(height: 20.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GuessInputForm extends StatefulWidget {
  final Function(int) checkGuess;

  GuessInputForm(this.checkGuess);

  @override
  _GuessInputFormState createState() => _GuessInputFormState();
}

class _GuessInputFormState extends State<GuessInputForm> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _guessController = TextEditingController();

  @override
  void dispose() {
    _guessController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextFormField(
              controller: _guessController,
              keyboardType: TextInputType.number,
              cursorColor: Colors.white,
              style: TextStyle(color: Colors.white.withOpacity(0.9)),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.question_mark,
                  color: Colors.white70,
                ),
                labelText: "Enter you guess",
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
                filled: true,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                fillColor: Colors.white.withOpacity(0.3),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: const BorderSide(width: 0, style: BorderStyle.none)),
              ),


              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter a number: ';
                }
                return null;
              },
            ),
          ),
          SizedBox(height: 10.0),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                int guess = int.parse(_guessController.text);
                _guessController.clear();
                widget.checkGuess(guess);
              }
            },
            child: Text('Check'),
          ),
        ],
      ),
    );
  }
}
