import 'package:flutter/material.dart';
// NOTE: Assuming these files exist, but we need placeholder classes for them
// import '../models/crypto_model.dart';
// import '../services/firebase_service.dart';

// -----------------------------------------------------------------------------
// PLACEHOLDER CLASS DEFINITIONS for types missing from the provided code
// In a real project, these would be in '../models/crypto_model.dart'
// and '../services/firebase_service.dart'.
// -----------------------------------------------------------------------------

/// Placeholder for a single cryptocurrency's data.
class CryptoData {
  final String name;
  final double price;
  final double change24h;

  CryptoData({required this.name, required this.price, required this.change24h});

  @override
  String toString() => '$name (Price: $price, 24h Change: $change24h%)';
}

/// Placeholder for general market statistics.
class MarketStats {
  final double totalMarketCap;
  final double dominance;

  MarketStats({required this.totalMarketCap, required this.dominance});

  @override
  String toString() => 'Market Cap: $totalMarketCap, Dominance: $dominance%';
}

/// Placeholder for the Firebase Service which handles AI interactions.
class FirebaseService {
  // Singleton pattern for the placeholder
  static final FirebaseService instance = FirebaseService._internal();
  factory FirebaseService() => instance;
  FirebaseService._internal();

  Future<void> initialize() async {
    // Simulate initialization
    await Future.delayed(const Duration(milliseconds: 10));
    print('FirebaseService initialized (Placeholder)');
  }

  Future<String> generateMarketAnalysis(List<CryptoData> cryptos) async {
    // Simulate an AI call
    await Future.delayed(const Duration(seconds: 2));
    return 'The market shows a mild upward trend, led by ${cryptos.first.name}.';
  }

  Future<String> generateCryptoInsight(CryptoData crypto) async {
    // Simulate an AI call
    await Future.delayed(const Duration(seconds: 2));
    return '${crypto.name} is performing well, with a ${crypto.change24h > 0 ? 'strong' : 'weak'} $crypto.change24h% movement.';
  }

  Future<String> generateMarketPrediction(MarketStats stats) async {
    // Simulate an AI call
    await Future.delayed(const Duration(seconds: 2));
    return 'Based on a market cap of ${stats.totalMarketCap}, a bullish movement is predicted.';
  }

  Future<String> chatWithAI(String message, {String? context}) async {
    // Simulate a chat AI call
    await Future.delayed(const Duration(seconds: 2));
    return 'Neko says: Meow! You asked about: "$message".';
  }
}
// -----------------------------------------------------------------------------
// END OF PLACEHOLDER CLASS DEFINITIONS
// -----------------------------------------------------------------------------


class GeminiProvider extends ChangeNotifier {
  // Use the placeholder's instance getter
  final FirebaseService _firebaseService = FirebaseService.instance;
  
  String? _marketAnalysis;
  String? _cryptoInsight;
  String? _marketPrediction;
  bool _isLoadingAnalysis = false;
  bool _isLoadingInsight = false;
  bool _isLoadingPrediction = false;
  final List<ChatMessage> _chatHistory = [];

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
      // Use print to show the error, as it was in the original code
      // ignore: avoid_print
      print('Error generating market analysis: $e');
      _marketAnalysis = 'Unable to generate market analysis at this time.';
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
      // ignore: avoid_print
      print('Error generating crypto insight: $e');
      _cryptoInsight = 'Unable to generate insight at this time.';
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
      // ignore: avoid_print
      print('Error generating prediction: $e');
      _marketPrediction = 'Unable to generate prediction at this time.';
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
      // ignore: avoid_print
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