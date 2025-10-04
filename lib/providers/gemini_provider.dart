import 'package:flutter/material.dart';
import '../models/crypto_model.dart';
import '../services/firebase_service.dart';

class GeminiProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;
  
  String? _marketAnalysis;
  String? _cryptoInsight;
  String? _marketPrediction;
  bool _isLoadingAnalysis = false;
  bool _isLoadingInsight = false;
  bool _isLoadingPrediction = false;
  List<ChatMessage> _chatHistory = [];

  String? get marketAnalysis => _marketAnalysis;
  String? get cryptoInsight => _cryptoInsight;
  String? get marketPrediction => _marketPrediction;
  bool get isLoadingAnalysis => _isLoadingAnalysis;
  bool get isLoadingInsight => _isLoadingInsight;
  bool get isLoadingPrediction => _isLoadingPrediction;
  List<ChatMessage> get chatHistory => _chatHistory;

  GeminiProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _firebaseService.initialize();
  }

  Future<void> generateMarketAnalysis(List<CryptoData> cryptos) async {
    if (cryptos.isEmpty) return;
    
    _isLoadingAnalysis = true;
    notifyListeners();

    try {
      _marketAnalysis = await _firebaseService.generateMarketAnalysis(cryptos);
    } catch (e) {
      _marketAnalysis = 'Unable to generate market analysis at this time.';
      print('Error generating market analysis: $e');
    } finally {
      _isLoadingAnalysis = false;
      notifyListeners();
    }
  }

  Future<void> generateCryptoInsight(CryptoData crypto) async {
    _isLoadingInsight = true;
    notifyListeners();

    try {
      _cryptoInsight = await _firebaseService.generateCryptoInsight(crypto);
    } catch (e) {
      _cryptoInsight = 'Unable to generate insight at this time.';
      print('Error generating crypto insight: $e');
    } finally {
      _isLoadingInsight = false;
      notifyListeners();
    }
  }

  Future<void> generateMarketPrediction(MarketStats stats) async {
    _isLoadingPrediction = true;
    notifyListeners();

    try {
      _marketPrediction = await _firebaseService.generateMarketPrediction(stats);
    } catch (e) {
      _marketPrediction = 'Unable to generate prediction at this time.';
      print('Error generating prediction: $e');
    } finally {
      _isLoadingPrediction = false;
      notifyListeners();
    }
  }

  Future<void> sendChatMessage(String message, {String? context}) async {
    // Add user message
    _chatHistory.add(ChatMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    notifyListeners();

    // Add loading indicator
    _chatHistory.add(ChatMessage(
      text: '...',
      isUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    ));
    notifyListeners();

    try {
      final response = await _firebaseService.chatWithAI(message, context: context);
      
      // Remove loading indicator
      _chatHistory.removeLast();
      
      // Add AI response
      _chatHistory.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _chatHistory.removeLast();
      _chatHistory.add(ChatMessage(
        text: 'Sorry, I encountered an error. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      ));
      print('Error in chat: $e');
    }
    notifyListeners();
  }

  void clearChat() {
    _chatHistory.clear();
    notifyListeners();
  }

  void clearAnalysis() {
    _marketAnalysis = null;
    _cryptoInsight = null;
    _marketPrediction = null;
    notifyListeners();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
    this.isError = false,
  });
}