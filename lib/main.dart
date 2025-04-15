import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(GameApp());

class GameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<Color> ballColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
  ];
  List<Color> balls = [];
  late Color shooterColor;
  late Color selectedBallColor;

  final int maxBallsOnBoard = 30;
  final int rows = 6;
  final int columns = 5;
  int score = 0;
  final int targetScore = 500;

  @override
  void initState() {
    super.initState();
    initializeGame();
  }

  void initializeGame() {
    setState(() {
      balls.clear();
      for (int i = 0; i < maxBallsOnBoard; i++) {
        balls.add(_getRandomBallColor());
      }
      shooterColor = _getRandomBallColor();
      score = 0;
    });
  }

  Color _getRandomBallColor() {
    final random = Random();
    return ballColors[random.nextInt(ballColors.length)];
  }

  void shootBall() {
    setState(() {
      balls.add(selectedBallColor);
      shooterColor = _getRandomBallColor();
    });
    checkCollisions();
  }

  void calculateScore(int matchedBalls) {
    int pointsEarned = matchedBalls * 10;
    setState(() {
      score += pointsEarned;
    });
  }

  void checkCollisions() {
    List<int> removeIndices = [];

    for (int i = 0; i < balls.length; i++) {
      if (balls[i] == shooterColor) {
        continue;
      }

      int currentRow = i ~/ columns;
      int currentCol = i % columns;
      int count = 1;

      for (int j = 1; j < columns; j++) {
        int index = i + j;
        if (index >= balls.length || balls[index] != balls[i]) {
          break;
        }
        if (index % columns != currentCol + j) {
          break;
        }
        count++;
      }

      for (int j = 1; j < rows; j++) {
        int index = i + (j * columns);
        if (index >= balls.length || balls[index] != balls[i]) {
          break;
        }
        count++;
      }

      if (count >= 3) {
        for (int j = 0; j < count; j++) {
          int indexToRemove = i + j * (j < columns ? 1 : columns);
          removeIndices.add(indexToRemove);
        }
      }
    }

    if (removeIndices.isNotEmpty) {
      // Calculate and update the score
      calculateScore(removeIndices.length);

      // Remove the matched balls from the list (remove in ascending order)
      setState(() {
        removeIndices.sort(); // Sort in ascending order
        for (int i = removeIndices.length - 1; i >= 0; i--) {
          balls.removeAt(removeIndices[i]);
        }
      });
    }

    // Check for game over condition
    if (balls.length >= 50) {
      showGameOverDialog();
    }

    // Check for win condition
    if (score >= targetScore) {
      showWinDialog();
    }
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Game Over'),
          content: Text('You have too many balls on the board. Try again!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                initializeGame();
              },
              child: Text('Restart'),
            ),
          ],
        );
      },
    );
  }

  void showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Congratulations!'),
          content: Text('You won the game with a score of $score!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                initializeGame();
              },
              child: Text('Play Again'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ball Color Blast'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => initializeGame(),
          ),
        ],
      ),
      body: Stack(
        children: [
          GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
            ),
            itemCount: balls.length,
            itemBuilder: (context, index) {
              return Ball(balls[index]);
            },
          ),
          Positioned(
            bottom: 10,
            left: (MediaQuery.of(context).size.width / 2) - 20,
            child: Shooter(
              shooterColor,
              () => shootBall(),
            ),
          ),
          ColorSelector(
            ballColors: ballColors,
            onColorSelected: (color) {
              setState(() {
                selectedBallColor = color;
              });
            },
          ),
          Positioned(
            top: 10,
            right: 10,
            child: ScoreOverlay(score: score),
          ),
        ],
      ),
    );
  }
}

class Ball extends StatelessWidget {
  final Color color;

  Ball(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class Shooter extends StatelessWidget {
  final Color color;
  final VoidCallback onPressed;

  Shooter(this.color, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class ColorSelector extends StatelessWidget {
  final List<Color> ballColors;
  final Function(Color) onColorSelected;

  ColorSelector({required this.ballColors, required this.onColorSelected});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 70,
      left: (MediaQuery.of(context).size.width / 2) - 40,
      child: Row(
        children: ballColors.map((color) {
          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              margin: EdgeInsets.all(4),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
class ScoreOverlay extends StatelessWidget {
  final int score;

  ScoreOverlay({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Score: $score',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
