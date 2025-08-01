import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart'; // <- Import do just_audio
import 'main.dart';

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late AudioPlayer _player;
  int score = 0; // <-- variável declarada aqui e inicializada
  @override
  void initState() {
    super.initState();

    // Inicia o player e toca o som assim que a tela carrega
    _player = AudioPlayer();
    _playStartSound(); // chama o método que reproduz o som

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )
      ..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  Future<void> _playStartSound() async {
    try {
      await _player.setAsset('assets/start_game.wav');
      _player.setLoopMode(LoopMode.one); // <- Isso ativa o loop infinito
      await _player.play();
    } catch (e) {
      print("Erro ao tocar som: $e");
    }
  }


  @override
  void dispose() {
    _controller.dispose();
    _player.dispose(); // Libera o player ao sair da tela
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fundo com imagem
          Positioned.fill(
            child: Image.asset(
              'assets/capainiciotela.png',
              fit: BoxFit.cover,
            ),
          ),
          // Container com título, botão e versão
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 40),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF9BBC0F),
                    width: 4,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  color: const Color(0xAA306230),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F380F),
                        border: Border.all(color: const Color(0xFF8BAC0F),
                            width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'DOCTOR SNAKE',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 18,
                          color: const Color(0xFF9BBC0F),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: ElevatedButton(
                        onPressed: () async {
                          await _player
                              .stop(); // Para o som antes de mudar de tela
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MiniGame(
                                    score: 0, // valor inicial de score
                                    onRestart: () {
                                      // lógica de reinício se necessário
                                    },
                                  ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24,
                              vertical: 14),
                          backgroundColor: const Color(0xFF8BAC0F),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                        ),
                        child: Text(
                          'START GAME',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'v1.0.43',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 8,
                        color: const Color(0xFF9BBC0F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
