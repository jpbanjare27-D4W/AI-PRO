import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AiProApp());
}

class AiProApp extends StatelessWidget {
  const AiProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI-PRO OS',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const AiProScreen(),
    );
  }
}

class AiProScreen extends StatefulWidget {
  const AiProScreen({super.key});

  @override
  State<AiProScreen> createState() => _AiProScreenState();
}

class _AiProScreenState extends State<AiProScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final Battery _battery = Battery();

  bool _isListening = false;
  String _userSpeech = "Boliye ya type kijiye...";
  String _aiReply = "AI-PRO Online & Ready.";
  final TextEditingController _textController = TextEditingController();

  // Yahan apni Gemini API Key daal sakte hain
  final String _geminiApiKey = "YOUR_GEMINI_API_KEY";

  @override
  void initState() {
    super.initState();
    _initSpeechAndBattery();
  }

  void _initSpeechAndBattery() async {
    await _speech.initialize();
    await _tts.setLanguage("hi-IN"); // Hindi + English voice

    // Battery Monitor: Low battery par alert
    _battery.onBatteryStateChanged.listen((BatteryState state) async {
      int batteryLevel = await _battery.batteryLevel;
      if (batteryLevel <= 15 && state != BatteryState.charging) {
        _speak("Phone charging karo, I am hungry! Battery 15 percent se kam hai.");
      }
    });
  }

  Future<void> _speak(String text) async {
    setState(() => _aiReply = text);
    await _tts.speak(text);
  }

  // Voice Command Processing System
  Future<void> _processCommand(String text) async {
    String cmd = text.toLowerCase().trim();

    // 1. WhatsApp Open
    if (cmd.contains("whatsapp") && (cmd.contains("open") || cmd.contains("kholo"))) {
      await _speak("WhatsApp khol raha hoon");
      await LaunchApp.openApp(androidPackageName: 'com.whatsapp');
      return;
    }

    // 2. YouTube Open
    if (cmd.contains("youtube") && (cmd.contains("open") || cmd.contains("kholo"))) {
      await _speak("YouTube open kar raha hoon");
      final Uri url = Uri.parse("https://www.youtube.com");
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return;
    }

    // 3. Call lagana
    if (cmd.contains("call") || cmd.contains("phone lagao")) {
      await _speak("Dialer open kar raha hoon");
      final Uri telUri = Uri.parse('tel:');
      await launchUrl(telUri);
      return;
    }

    // 4. Baki General Knowledge ya Chat -> AI Brain (Gemini)
    await _askAi(text);
  }

  // AI Brain Function
  Future<void> _askAi(String prompt) async {
    setState(() => _aiReply = "Soch raha hoon...");
    if (_geminiApiKey == "YOUR_GEMINI_API_KEY") {
      await _speak("AI connected. Aapne pucha: $prompt. Kripya apni API key set karein.");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_geminiApiKey"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{"parts": [{"text": prompt}]}]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String reply = data['candidates'][0]['content']['parts'][0]['text'];
        await _speak(reply);
      } else {
        await _speak("Server se jawab nahi mil paya.");
      }
    } catch (e) {
      await _speak("Internet connection check kijiye.");
    }
  }

  void _listenVoice() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          setState(() => _userSpeech = val.recognizedWords);
          if (val.hasConfidenceRating && val.confidence > 0) {
            _speech.stop();
            setState(() => _isListening = false);
            _processCommand(val.recognizedWords);
          }
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI-PRO Voice OS"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.star, color: Colors.amber),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Trial: 7 Din Baaki. Membership: ₹29/month")),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text("Aapne kaha:", style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(height: 8),
                  Text(_userSpeech, style: const TextStyle(fontSize: 18, color: Colors.cyanAccent)),
                  const Divider(height: 40, color: Colors.white24),
                  Text("AI-PRO Jawab:", style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(height: 8),
                  Text(_aiReply, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          
          // Voice Glowing Mic Button
          GestureDetector(
            onTap: _listenVoice,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? Colors.redAccent : Colors.cyan,
                boxShadow: [
                  BoxShadow(
                    color: _isListening ? Colors.red.withOpacity(0.5) : Colors.cyan.withOpacity(0.5),
                    blurRadius: 25,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Icon(_isListening ? Icons.stop : Icons.mic, size: 40, color: Colors.black),
            ),
          ),
          const SizedBox(height: 10),
          Text(_isListening ? "Listening... Boliye" : "Tap Mic to Talk", style: const TextStyle(color: Colors.white54)),

          // Search Bar (Kuch likh kar puchne ke liye)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: "Kuch bhi puchiye ya command dein...",
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.cyan),
                  onPressed: () {
                    if (_textController.text.isNotEmpty) {
                      _processCommand(_textController.text);
                      _textController.clear();
                    }
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}