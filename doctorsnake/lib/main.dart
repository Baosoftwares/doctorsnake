import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:doctorsnake/DoctorSnakeSplashScreen.dart';
import 'package:doctorsnake/ranking_screen.dart';
import 'package:doctorsnake/telainicial.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lottie/lottie.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DoctorSnakeSplashScreen(), // aqui chamamos sua tela principal
    );
  }
}

class MiniGame extends StatefulWidget {
  final int score;
  final VoidCallback onRestart;

  const MiniGame({
    Key? key,
    required this.score,
    required this.onRestart,
  }) : super(key: key); // passa o key para o super

  @override
  _MiniGamePageState createState() => _MiniGamePageState();
}


class _MiniGamePageState extends State<MiniGame> {
  static const int squareSize = 18;
  late int rows;
  late int columns;
  List<int> snake = [45, 65, 85];
  int food = Random().nextInt(400);
  Color foodColor = Colors.red;
  Color snakeColor = Colors.green;
  String direction = 'up';
  bool isGameOver = false;
  int score = 0;
  bool showLottie = false;

  Timer? timer;

  int speedDelay = 200;

  late AudioPlayer _backgroundMusicPlayer;
  late AudioPlayer _foodSoundPlayer;

  List<int> obstacles = [];
  bool showFrascore = false;
  late int frascoremdioPosition;
  bool showFrascoremdio = false; // para saber se ele está visível
  late Timer _timer;
  int _timeRemaining = 250; // Tempo total em segundos

  static const Set<String> _kIds = {'premium_mensal'}; // Seu product ID
  List<ProductDetails> _products = []; // Lista para armazenar produtos
  String subscriptionPrice = '';
  final TextEditingController _nameController = TextEditingController();

  int multiple20Counter = 0; // To count multiples of 20 points
  int level = 1; // Add the level variable
  List<String> pilulas = [
    'assets/pilula1.png',
    'assets/pilula2.png',
    'assets/pilula3.png',
    'assets/pilula4.png',
    'assets/pilula5.png',
  ];

// Lista de posições onde as pílulas estão localizadas
  List<int> pilulaPositions = [235, 125, 290, 175, 114]; // Exemplos de posições

  String pilulaAtual = 'assets/pilula1.png'; // Pílula inicial


  @override
  void initState() {
    super.initState();
    _backgroundMusicPlayer = AudioPlayer();
    _foodSoundPlayer = AudioPlayer();
    // Buscar detalhes da assinatura assim que o app iniciar
    fetchProductDetails();
    // Initialize everything but do not start the game yet
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        _timer.cancel(); // Cancels the timer when the time runs out
        gameOver(); // Calls the game over method when time runs out
      }
    });

    // Show instructions modal on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructionsModal();
    });
  }


  @override
  void dispose() {
    _backgroundMusicPlayer.dispose();
    _foodSoundPlayer.dispose();
    timer?.cancel();

    super.dispose();
  }





  void updateSubscriptionPrice(ProductDetails product) {
    setState(() {
      subscriptionPrice = product.price; // ou formate como quiser
    });
  }


// Função que gera novas posições para as pílulas
  void generatePilulaPositions() {
    pilulaPositions.clear(); // Limpa as posições atuais das pílulas
    for (int i = 0; i < 5; i++) { // Cria 5 pílulas
      int position;
      do {
        position =
            Random().nextInt(rows * columns); // Gera uma posição aleatória
      } while (snake.contains(position) || obstacles.contains(position) ||
          pilulaPositions.contains(
              position)); // Garante que a pílula não aparece em posições indesejadas
      pilulaPositions.add(position);
    }
    setState(() {}); // Força a re-renderização
  }

  void startGame() {
    // Cancela timers antigos
    timer?.cancel();
    _timer?.cancel();

    setState(() {
      snake = [45, 65, 85];
      food = Random().nextInt(rows * columns);
      foodColor = Colors.red;
      snakeColor = Colors.green;
      direction = 'up';
      isGameOver = false;
      score = 0;
      obstacles = [];
      showLottie = false;
      multiple20Counter = 0;
      level = 1;
      _timeRemaining = 250;
    });

    _backgroundMusicPlayer.setAsset('assets/sound8bit.wav');
    _backgroundMusicPlayer.setLoopMode(LoopMode.all);
    _backgroundMusicPlayer.play();

    // Timer para movimentar a cobra
    timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      setState(() {
        moveSnake();
        checkCollision();
        updateObstacles();
      });
    });

    // Timer do contador regressivo
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        _timer?.cancel();
        gameOver();
      }
    });
  }


  void _showInstructionsModal() {
    showDialog(
      context: context,
      barrierDismissible: false, // Não fecha ao tocar fora
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Bloqueia botão "Voltar"
          child: AlertDialog(
            backgroundColor: const Color(0xFF9BBC0F), // Verde Game Boy
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFF0F380F), width: 4),
            ),
            title: Center(
              child: Text(
                '📜 Game Rules',
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F380F),
                ),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '1. Eat the correct pills shown above.\n'
                      '2. Don’t crash into walls or yourself.\n'
                      '3. Score 200 points before time ends.\n'
                      '4. Use the on-screen arrows!',
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 12,
                    height: 1.5,
                    color: const Color(0xFF0F380F),
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    startGame();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF306230),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    '▶ START',
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }




  Future<void> salvarPontuacao(String nome, int score) async {
    final prefs = await SharedPreferences.getInstance();

    List<Player> ranking = [];

    final jsonString = prefs.getString('ranking_data');
    if (jsonString != null) {
      List<dynamic> jsonList = jsonDecode(jsonString);
      ranking = jsonList.map((e) => Player.fromJson(e)).toList();
    }

    ranking.add(Player(name: nome.substring(0, nome.length.clamp(0, 3)), score: score));

    // Ordena e mantém os 15 maiores
    ranking.sort((a, b) => b.score.compareTo(a.score));
    ranking = ranking.take(15).toList();

    final updatedJson = jsonEncode(ranking.map((e) => e.toJson()).toList());
    await prefs.setString('ranking_data', updatedJson);
  }

  // Função para buscar detalhes dos produtos in-app (assinaturas)
  Future<void> fetchProductDetails() async {
    final bool available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      print('In-app purchases não disponíveis neste dispositivo.');
      _voltarParaInicio();
      return;
    }

    final ProductDetailsResponse response = await InAppPurchase.instance.queryProductDetails(_kIds);

    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
      print('Produtos não encontrados: ${response.notFoundIDs}');
      _voltarParaInicio();
      return;
    }

    final productDetails = response.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: productDetails);

    late StreamSubscription<List<PurchaseDetails>> subscription;

    subscription = InAppPurchase.instance.purchaseStream.listen((purchases) {
      bool compraFinalizada = false;

      for (var purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased) {
          compraFinalizada = true;
          print('Assinatura concluída com sucesso!');
          // Aqui você pode fazer lógica de desbloqueio, salvar no banco etc.
          break;
        } else if (purchase.status == PurchaseStatus.error || purchase.status == PurchaseStatus.canceled) {
          print('Compra cancelada ou falhou.');
          _voltarParaInicio();
          break;
        }
      }

      if (!compraFinalizada) {
        _voltarParaInicio();
      }

      subscription.cancel();
    });

    // Iniciar compra
    InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _voltarParaInicio() {
    _backgroundMusicPlayer.stop();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TelaInicial()),
    );
  }



  void _buySubscription() {
    final ProductDetails? product = _products.firstWhereOrNull(
          (p) => p.id == 'premium_mensal',
    );

    if (product != null) {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      print('Produto não encontrado');
    }
  }





  void moveSnake() {
    switch (direction) {
      case 'up':
        snake.insert(0, snake.first - columns);
        break;
      case 'down':
        snake.insert(0, snake.first + columns);
        break;
      case 'left':
        snake.insert(0, snake.first - 1);
        break;
      case 'right':
        snake.insert(0, snake.first + 1);
        break;
    }

    if (snake.first < 0) {
      snake[0] = (rows * columns) - columns + (snake.first % columns);
    } else if (snake.first >= rows * columns) {
      snake[0] = snake.first % columns;
    } else if (snake.first % columns == columns - 1) {
      snake[0] = snake.first - (columns - 1);
    } else if (snake.first % columns == 0) {
      snake[0] = snake.first + (columns - 1);
    }

    bool atePill = false;

    // Verifica se a cobra comeu uma pílula
    if (pilulaPositions.contains(snake.first)) {
      int index = pilulaPositions.indexOf(snake.first);

      setState(() {
        if (pilulas[index] == pilulaAtual) {
          pilulaPositions.remove(snake.first);
          pilulaPositions.add(Random().nextInt(rows * columns));
          pilulaAtual = pilulas[Random().nextInt(pilulas.length)];
          score += 10;
          atePill = true;

          if (score % 200 == 0 && score != 0) {
            showFrascore = true;
            Future.delayed(const Duration(seconds: 10), () {
              setState(() {
                showFrascore = false;
              });
            });

            showFrascoremdio = true;
            frascoremdioPosition = Random().nextInt(rows * columns);
            Future.delayed(const Duration(seconds: 10), () {
              setState(() {
                showFrascoremdio = false;
              });
            });
          }

          _foodSoundPlayer.setAsset('assets/gamecolect.wav');
          _foodSoundPlayer.play();
        }
      });

      if (score % 200 == 0) {
        levelUp();
      }

      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          showLottie = false;
        });
      });
    }

    // Verifica colisão com frascoremdio.png
    if (showFrascoremdio && snake.first == frascoremdioPosition) {
      setState(() {
        snake = [45, 65, 85]; // Reinicia o tamanho da cobra

        showFrascoremdio = false;
        frascoremdioPosition = Random().nextInt(rows * columns);


        _foodSoundPlayer.play();
      });
    } else if (!atePill) {
      snake.removeLast(); // Só remove se não comeu
    }
  }


  void levelUp() {
    // If score reaches 20, increase level and adjust speed
    if (score >= 200 * level) {
      setState(() {
        level++;
        speedDelay = (speedDelay > 100)
            ? speedDelay - 30
            : 100; // Increase speed slightly with each level
        multiple20Counter = 0; // Reset the multiple 20 counter
      });
      // Reset the timer when level increases
      _resetTimer();

      // You can add a visual cue for level-up here, such as showing a Lottie animation or message
      showLottie = true;
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          showLottie = false;
        });
      });
    }
  }

  void _resetTimer() {
    setState(() {
      _timeRemaining =
      250; // Reset the time to the initial value when the level increases
    });

    if (_timer.isActive) {
      _timer.cancel(); // Cancel the current timer
    }

    // Start a new timer with the updated time
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        _timer.cancel(); // Cancels the timer when the time runs out
        gameOver(); // Calls the game over method when time runs out
      }
    });
  }

  int getValidFoodPosition() {
    int newFood;
    int minBoundary = columns; // Evita a primeira linha
    int maxBoundary = (rows - 1) * columns; // Evita a última linha

    // Evita as bordas (primeira linha, última linha, primeira coluna, última coluna)
    do {
      newFood = Random().nextInt(rows * columns);
    } while (
    snake.contains(newFood) || // Evita colisão com a cobra
        newFood < minBoundary || // Evita a primeira linha
        newFood >= maxBoundary || // Evita a última linha
        newFood % columns == 0 || // Evita a primeira coluna
        newFood % columns == columns - 1 || // Evita a última coluna
        newFood < columns || // Evita a primeira linha
        newFood >= (rows - 1) * columns // Evita a última linha
    );

    return newFood;
  }


  void checkCollision() {
    for (int i = 1; i < snake.length; i++) {
      if (snake[i] == snake.first) {
        gameOver();
      }
    }

    if (obstacles.contains(snake.first)) {
      gameOver();
    }

    // Check if the game should be over due to not reaching 20 multiples of 20 points
    if (_timeRemaining == 0 && multiple20Counter < 20) {
      gameOver();
    }
  }

  void gameOver() {
    timer?.cancel();

    setState(() {
      isGameOver = true;
    });
  }

  void updateObstacles() {
    if (score % 20 == 0 && obstacles.length < 10) {
      setState(() {
        obstacles.add(Random().nextInt(rows * columns));
      });
    }
  }

  void changeDirection(Offset position) {
    List<String> directions = ['up', 'left', 'down', 'right'];
    int currentIndex = directions.indexOf(direction);
    int nextIndex = (currentIndex + 1) % directions.length;

    setState(() {
      direction = directions[nextIndex];
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(minutes)}:${twoDigits(remainingSeconds)}';
  }


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    double screenHeight = MediaQuery
        .of(context)
        .size
        .height - 100;
    columns = (screenWidth / squareSize).floor();
    rows = (screenHeight / squareSize).floor();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 106, 9, 216),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'assets/doctorjeff.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(width: 5),
            Lottie.asset(
              'assets/monitorcardiaco.json',
              width: 80,
              height: 80,
              repeat: true,
            ),
            const SizedBox(width: 10),
            Image.asset(
              pilulaAtual,
              width: 30,
              height: 30,
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Score: $score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Level: $level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (subscriptionPrice.isNotEmpty)
                  Text(
                    'Assinatura: $subscriptionPrice',
                    style: const TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  'Time: ${_formatTime(_timeRemaining)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/fundotela.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTapDown: (details) {
                    changeDirection(details.localPosition);
                  },
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 0,
                      mainAxisSpacing: 0,
                    ),
                    itemCount: rows * columns,
                    itemBuilder: (BuildContext context, int index) {
                      if (snake.contains(index)) {
                        if (index == snake.first) {
                          String headAsset;
                          switch (direction) {
                            case 'up':
                              headAsset = 'assets/cabeca2.png';
                              break;
                            case 'down':
                              headAsset = 'assets/cabeca1.png';
                              break;
                            case 'left':
                              headAsset = 'assets/cabeca4.png';
                              break;
                            case 'right':
                            default:
                              headAsset = 'assets/cabeca3.png';
                              break;
                          }
                          return Image.asset(headAsset);
                        } else if (index == snake.last) {
                          String tailAsset;
                          int tailSegment = snake[snake.length - 2];
                          if (tailSegment == index - columns) {
                            tailAsset = 'assets/calda1.png';
                          } else if (tailSegment == index + columns) {
                            tailAsset = 'assets/calda2.png';
                          } else if (tailSegment == index - 1) {
                            tailAsset = 'assets/calda3.png';
                          } else {
                            tailAsset = 'assets/calda4.png';
                          }
                          return Image.asset(tailAsset);
                        } else {
                          String bodyAsset;
                          int currentIndex = snake.indexOf(index);
                          int previous = snake[currentIndex - 1];
                          int next = snake[currentIndex + 1];

                          if ((previous == index - columns &&
                              next == index + columns) ||
                              (previous == index + columns &&
                                  next == index - columns)) {
                            bodyAsset = 'assets/corpo1.png';
                          } else if ((previous == index - 1 &&
                              next == index + 1) ||
                              (previous == index + 1 && next == index - 1)) {
                            bodyAsset = 'assets/corpo3.png';
                          } else if ((previous == index - columns &&
                              next == index + 1) ||
                              (previous == index + 1 &&
                                  next == index - columns)) {
                            bodyAsset = 'assets/curva1.png';
                          } else if ((previous == index + columns &&
                              next == index + 1) ||
                              (previous == index + 1 &&
                                  next == index + columns)) {
                            bodyAsset = 'assets/curva4.png';
                          } else if ((previous == index + columns &&
                              next == index - 1) ||
                              (previous == index - 1 &&
                                  next == index + columns)) {
                            bodyAsset = 'assets/curva3.png';
                          } else if ((previous == index - columns &&
                              next == index - 1) ||
                              (previous == index - 1 &&
                                  next == index - columns)) {
                            bodyAsset = 'assets/curva2.png';
                          } else {
                            bodyAsset = 'assets/corpo2.png';
                          }
                          return Image.asset(bodyAsset);
                        }
                      } else if (pilulaPositions.contains(index)) {
                        int pilulaIndex = pilulaPositions.indexOf(index);
                        return Image.asset(
                          pilulas[pilulaIndex],
                          width: squareSize.toDouble(),
                          height: squareSize.toDouble(),
                        );
                      } else if (obstacles.contains(index)) {
                        return Lottie.asset(
                          'assets/bacterias.json',
                          width: squareSize.toDouble() * 8.5,
                          height: squareSize.toDouble() * 8.5,
                          fit: BoxFit.contain,
                        );
                      } else
                      if (showFrascoremdio && index == frascoremdioPosition) {
                        return Image.asset(
                          'assets/frascoremedio.png',
                          width: squareSize.toDouble() * 5.0,
                          height: squareSize.toDouble() * 5.0,
                        );
                      } else {
                        return Container(
                          width: squareSize.toDouble(),
                          height: squareSize.toDouble(),
                          margin: const EdgeInsets.all(1),
                          color: Colors.black,
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          if (showLottie)
            Center(
              child: Lottie.asset(
                'assets/star.json',
                width: 200,
                height: 200,
              ),
            ),
          if (isGameOver)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/bacterias.json',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'GAME OVER',
                      style: TextStyle(
                        fontSize: 40,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.white,
                            offset: Offset(2, 2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    // Campo de nome com estilo Game Boy Color
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.green[200],
                        border: Border.all(color: Colors.green[900]!, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _nameController,
                        maxLength: 3,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'PressStart2P', // Use uma fonte estilo Game Boy (adicione ao pubspec.yaml)
                          color: Colors.black,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                          hintText: 'Insira seu nome',
                          hintStyle: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        String nome = _nameController.text.trim();
                        if (nome.isEmpty) nome = '???';

                        await salvarPontuacao(nome, score);
                        widget.onRestart(); // Reinicia o jogo
                        startGame(); // Inicia o jogo novamente
                      },
                      icon: const Icon(
                        Icons.restart_alt,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Reiniciar',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
