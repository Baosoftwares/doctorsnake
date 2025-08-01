import 'dart:async';
import 'package:doctorsnake/ranking_screen.dart';
import 'package:doctorsnake/telainicial.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

class DoctorSnakeSplashScreen extends StatefulWidget {
  const DoctorSnakeSplashScreen({super.key});

  @override
  State<DoctorSnakeSplashScreen> createState() => _DoctorSnakeSplashScreenState();
}

class _DoctorSnakeSplashScreenState extends State<DoctorSnakeSplashScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playStartSound();
    Timer(const Duration(seconds: 6), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RankingScreen()),
      );
    });
  }

  Future<void> _playStartSound() async {
    try {
      await _audioPlayer.setAsset('assets/start_sound.wav');
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Erro ao tocar som de início: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F380F), // Verde escuro estilo Game Boy
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/splash_gameboy.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: 30),
              child: Text(
                'Baoh Softwares Games 2025',
                style: GoogleFonts.pressStart2p(
                  fontSize: 10,
                  color: const Color(0xFF9BBC0F),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
