import 'dart:convert';
import 'dart:async';
import 'package:doctorsnake/telainicial.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Player {
  final String name;
  final int score;

  Player({required this.name, required this.score});

  Map<String, dynamic> toJson() => {
    'name': name,
    'score': score,
  };

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'],
      score: json['score'],
    );
  }
}

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<Player> _players = [];
  List<Color> _animatedColors = [
    const Color(0xFF0F380F),
    const Color(0xFF306230),
    const Color(0xFF8BAC0F),
  ];
  int _colorIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadRanking();
    _startColorAnimation();

    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TelaInicial()),
        );
      }
    });
  }

  void _startColorAnimation() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _colorIndex = (_colorIndex + 1) % _animatedColors.length;
      });
      _startColorAnimation();
    });
  }

  Future<void> _loadRanking() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('ranking_data');
    if (jsonString != null) {
      List<dynamic> jsonList = jsonDecode(jsonString);
      List<Player> players = jsonList.map((e) => Player.fromJson(e)).toList();
      players.sort((a, b) => b.score.compareTo(a.score));

      setState(() {
        _players = players.take(15).toList();
      });
    }
  }

  String _getMedalEmoji(int index) {
    switch (index) {
      case 0:
        return '🥇';
      case 1:
        return '🥈';
      case 2:
        return '🥉';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F380F),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF8BAC0F), width: 5),
            color: const Color(0xFF0F380F),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _animatedColors[_colorIndex],
                  _animatedColors[(_colorIndex + 1) % _animatedColors.length],
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  '🏆 RANKING TOP 15 🕹️',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 18,
                    color: const Color(0xFF0F380F),
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _players.length,
                    itemBuilder: (context, index) {
                      final player = _players[index];
                      final medal = _getMedalEmoji(index);

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8BAC0F),
                          border: Border.all(color: const Color(0xFF0F380F), width: 3),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$medal ${index + 1}. ${player.name.substring(0, 3).toUpperCase()}',
                              style: GoogleFonts.pressStart2p(
                                fontSize: 14,
                                color: const Color(0xFF0F380F),
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${player.score} pts',
                              style: GoogleFonts.pressStart2p(
                                fontSize: 14,
                                color: const Color(0xFFFFF200),
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
