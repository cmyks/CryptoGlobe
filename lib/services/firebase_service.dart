import 'package:firebase_ai/firebase_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/crypto_model.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }
  
  FirebaseService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final GenerativeModel _marketAnalystModel;
  late final GenerativeModel _cryptoExpertModel;
  late final GenerativeModel _chatModel;
  bool _initialized = false;

  // Initialize Firebase AI with Gemini models
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Model for market analysis with Google Search grounding
      _marketAnalystModel = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.0-flash-exp',
        systemInstruction: Content.system(
          '''You are an expert cryptocurrency market analyst with deep knowledge of blockchain technology, 
          trading patterns, and market dynamics. Your role is to provide professional, data-driven analysis 
          of cryptocurrency markets. Always base your insights on current market data and trends. Be concise, 
          informative, and objective. Focus on actionable insights for investors and traders. Use technical 
          analysis terminology when appropriate.'''
        ),
        tools: [
          Tool.googleSearch(), // Enable real-time web search for latest crypto news
        ],
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
          responseMimeType: 'text/plain',
        ),
      );

      // Model for individual crypto analysis
      _cryptoExpertModel = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.0-flash-exp',
        systemInstruction: Content.system(
          '''You are a cryptocurrency technical analysis expert specializing in individual coin analysis. 
          Provide detailed technical insights about specific cryptocurrencies including price action, 
          support/resistance levels, market sentiment, and potential trends. Always consider market cap, 
          volume, and recent price movements. Be professional and educational in your explanations. 
          Avoid giving direct financial advice - focus on technical analysis and educational information.'''
        ),
        tools: [
          Tool.googleSearch(), // Get latest crypto news and updates
        ],
        generationConfig: GenerationConfig(
          temperature: 0.6,
          topK: 40,
          topP: 0.9,
          maxOutputTokens: 800,
        ),
      );

      // Model for interactive chat with broader knowledge
      _chatModel = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash-lite',
        systemInstruction: Content.system(
          '''You are a helpful cryptocurrency and blockchain expert assistant. You help users understand 
          cryptocurrencies, blockchain technology, DeFi, NFTs, and related topics. Provide clear, accurate, 
          and educational responses. Use real-time information when discussing current market conditions. 
          Be friendly and approachable while maintaining professional expertise. Always encourage users to 
          do their own research (DYOR) and never provide direct investment advice.'''
        ),
        tools: [
          Tool.googleSearch(), // Access latest crypto information
        ],
        generationConfig: GenerationConfig(
          temperature: 0.8,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1200,
        ),
      );

      _initialized = true;
      print('✅ Firebase AI with Gemini initialized successfully');
      print('📡 Google Search grounding enabled for real-time data');
    } catch (e) {
      print('❌ Error initializing Firebase AI: $e');
      rethrow;
    }
  }

  // Generate comprehensive market analysis with Google Search grounding
  Future<String> generateMarketAnalysis(List<CryptoData> cryptos) async {
    if (!_initialized) await initialize();
    
    try {
      final topGainers = cryptos.where((c) => c.change24h > 0)
          .toList()..sort((a, b) => b.change24h.compareTo(a.change24h));
      final topLosers = cryptos.where((c) => c.change24h < 0)
          .toList()..sort((a, b) => a.change24h.compareTo(b.change24h));

      final avgChange = cryptos.map((c) => c.change24h).reduce((a, b) => a + b) / cryptos.length;

      final prompt = '''Analyze the current cryptocurrency market based on this real-time data:

TOP 3 GAINERS (24h):
${topGainers.take(3).map((c) => '• ${c.name} (${c.symbol}): ${c.change24h >= 0 ? '+' : ''}${c.change24h.toStringAsFixed(2)}% | Price: \$${c.price.toStringAsFixed(2)} | Market Cap: \$${(c.marketCap / 1e9).toStringAsFixed(2)}B').join('\n')}

TOP 3 LOSERS (24h):
${topLosers.take(3).map((c) => '• ${c.name} (${c.symbol}): ${c.change24h >= 0 ? '+' : ''}${c.change24h.toStringAsFixed(2)}% | Price: \$${c.price.toStringAsFixed(2)} | Market Cap: \$${(c.marketCap / 1e9).toStringAsFixed(2)}B').join('\n')}

MARKET OVERVIEW:
• Average 24h Change: ${avgChange >= 0 ? '+' : ''}${avgChange.toStringAsFixed(2)}%
• Total Cryptocurrencies Tracked: ${cryptos.length}
• Bitcoin Price: \$${cryptos.firstWhere((c) => c.id == 'bitcoin', orElse: () => cryptos.first).price.toStringAsFixed(2)}

Please provide a concise market analysis (3-4 sentences) covering:
1. Overall market sentiment (bullish, bearish, or mixed)
2. Key trends or notable patterns
3. Significant movements and potential catalysts
4. Brief outlook based on current data

Use Google Search to check for any breaking crypto news that might be affecting these prices.''';

      final response = await _marketAnalystModel.generateContent([Content.text(prompt)]);
      
      // Check if response contains grounding metadata
      if (response.candidates?.isNotEmpty ?? false) {
        final candidate = response.candidates!.first;
        if (candidate.groundingMetadata != null) {
          print('🔍 Response grounded with ${candidate.groundingMetadata!.searchEntryPoint?.renderedContent?.length ?? 0} search results');
        }
      }

      return response.text ?? 'Unable to generate market analysis at this time. Please try again.';
    } catch (e) {
      print('❌ Error generating market analysis: $e');
      return 'Market analysis temporarily unavailable. The crypto market shows mixed signals with varied performance across major assets. Bitcoin continues to lead market sentiment.';
    }
  }

  // Generate AI insights about specific cryptocurrency with real-time data
  Future<String> generateCryptoInsight(CryptoData crypto) async {
    if (!_initialized) await initialize();
    
    try {
      final priceChange = crypto.change24h >= 0 ? 'gained' : 'lost';
      final momentum = crypto.change24h.abs() > 5 ? 'strong' : 
                       crypto.change24h.abs() > 2 ? 'moderate' : 'weak';

      final prompt = '''Provide a technical analysis for ${crypto.name} (${crypto.symbol}):

CURRENT METRICS:
• Price: \$${crypto.price.toStringAsFixed(2)}
• 24h Change: ${crypto.change24h >= 0 ? '+' : ''}${crypto.change24h.toStringAsFixed(2)}%
• 24h High: \$${crypto.high24h.toStringAsFixed(2)}
• 24h Low: \$${crypto.low24h.toStringAsFixed(2)}
• Market Cap: \$${(crypto.marketCap / 1e9).toStringAsFixed(2)}B
• 24h Volume: \$${(crypto.volume24h / 1e9).toStringAsFixed(2)}B

OBSERVATION:
${crypto.name} has ${priceChange} ${crypto.change24h.abs().toStringAsFixed(2)}% in the last 24 hours, showing ${momentum} ${crypto.change24h >= 0 ? 'upward' : 'downward'} momentum.

Provide 2-3 sentences about:
1. Current price action and momentum analysis
2. Technical outlook and key levels to watch
3. Any recent news or developments (use Google Search)

Keep it concise, professional, and educational.''';

      final response = await _cryptoExpertModel.generateContent([Content.text(prompt)]);
      
      return response.text ?? 'Technical analysis for ${crypto.name} is temporarily unavailable. Please try again.';
    } catch (e) {
      print('❌ Error generating crypto insight: $e');
      return 'Analysis for ${crypto.name} is temporarily unavailable. Current price: \$${crypto.price.toStringAsFixed(2)}, 24h change: ${crypto.change24h >= 0 ? '+' : ''}${crypto.change24h.toStringAsFixed(2)}%.';
    }
  }

  // Generate global market predictions with Google Search for latest trends
  Future<String> generateMarketPrediction(MarketStats stats) async {
    if (!_initialized) await initialize();
    
    try {
      final prompt = '''Analyze the overall cryptocurrency market health and provide insights:

GLOBAL MARKET METRICS:
• Total Market Cap: \$${(stats.totalMarketCap / 1e12).toStringAsFixed(2)} Trillion
• 24h Trading Volume: \$${(stats.totalVolume24h / 1e9).toStringAsFixed(2)} Billion
• Bitcoin Dominance: ${stats.btcDominance.toStringAsFixed(2)}%
• Ethereum Dominance: ${stats.ethDominance.toStringAsFixed(2)}%
• Active Cryptocurrencies: ${stats.activeCryptocurrencies.toLocaleString()}

Using the latest market data and Google Search for recent developments, provide a 3-4 sentence market outlook focusing on:
1. Overall market health indicators
2. Dominance trends and what they suggest
3. Volume analysis and liquidity conditions
4. Short-term market outlook based on current conditions

Use real-time information to provide the most accurate assessment.''';

      final response = await _marketAnalystModel.generateContent([Content.text(prompt)]);
      
      return response.text ?? 'Market prediction temporarily unavailable. Monitor Bitcoin dominance and trading volumes for market direction.';
    } catch (e) {
      print('❌ Error generating prediction: $e');
      return 'Market outlook analysis is temporarily unavailable. Current market cap: \$${(stats.totalMarketCap / 1e12).toStringAsFixed(2)}T with ${stats.btcDominance.toStringAsFixed(1)}% BTC dominance.';
    }
  }

  // Interactive chat with AI using Google Search for up-to-date information
  Future<String> chatWithAI(String userMessage, {String? context}) async {
    if (!_initialized) await initialize();
    
    try {
      String prompt = userMessage;
      
      // Add context if provided
      if (context != null && context.isNotEmpty) {
        prompt = '''CONTEXT: $context

USER QUESTION: $userMessage

Please provide a helpful and accurate response. Use Google Search to find the latest information if the question requires current data or recent events.''';
      }

      final response = await _chatModel.generateContent([Content.text(prompt)]);
      
      // Log if grounding was used
      if (response.candidates?.isNotEmpty ?? false) {
        final candidate = response.candidates!.first;
        if (candidate.groundingMetadata != null) {
          print('🔍 Chat response grounded with Google Search');
        }
      }

      return response.text ?? 'I apologize, but I cannot respond at this time. Please try rephrasing your question.';
    } catch (e) {
      print('❌ Error in AI chat: $e');
      return 'I\'m having trouble processing your request. Please try again or rephrase your question.';
    }
  }

  // Advanced chat with conversation history (multi-turn)
  Future<String> chatWithHistory(
    String userMessage, 
    List<Map<String, String>> conversationHistory,
  ) async {
    if (!_initialized) await initialize();
    
    try {
      // Build conversation context
      final contents = <Content>[];
      
      // Add previous conversation turns
      for (var turn in conversationHistory) {
        if (turn['role'] == 'user') {
          contents.add(Content.text(turn['content'] ?? ''));
        } else if (turn['role'] == 'model') {
          contents.add(Content.model([TextPart(turn['content'] ?? '')]));
        }
      }
      
      // Add current user message
      contents.add(Content.text(userMessage));

      final response = await _chatModel.generateContent(contents);
      
      return response.text ?? 'I couldn\'t generate a response. Please try again.';
    } catch (e) {
      print('❌ Error in chat with history: $e');
      return 'Error processing conversation. Please start a new chat.';
    }
  }

  // Get real-time crypto news using Google Search
  Future<String> getCryptoNews(String topic) async {
    if (!_initialized) await initialize();
    
    try {
      final prompt = '''Search for the latest news and updates about: $topic

Provide a brief summary (3-4 sentences) of the most recent and relevant news articles. 
Include key developments, price movements, or important announcements. 
Focus on credible sources and factual information.''';

      final response = await _marketAnalystModel.generateContent([Content.text(prompt)]);
      
      return response.text ?? 'No recent news found for this topic.';
    } catch (e) {
      print('❌ Error fetching crypto news: $e');
      return 'Unable to fetch news at this time.';
    }
  }

  // Explain crypto concepts with educational focus
  Future<String> explainConcept(String concept) async {
    if (!_initialized) await initialize();
    
    try {
      final prompt = '''Explain the following cryptocurrency/blockchain concept in simple terms: $concept

Provide a clear, educational explanation suitable for beginners. Include:
1. What it is
2. Why it matters
3. A simple real-world analogy
4. Current relevance in the crypto space

Use Google Search to ensure you have the latest understanding and examples.''';

      final response = await _chatModel.generateContent([Content.text(prompt)]);
      
      return response.text ?? 'Unable to explain this concept right now.';
    } catch (e) {
      print('❌ Error explaining concept: $e');
      return 'Explanation unavailable. Please try searching for "$concept" online.';
    }
  }

  // Save user preferences to Firestore
  Future<void> saveUserPreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      await _firestore.collection('user_preferences').doc(userId).set(
        {
          ...preferences,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      print('❌ Error saving preferences: $e');
    }
  }

  // Load user preferences from Firestore
  Future<Map<String, dynamic>?> loadUserPreferences(String userId) async {
    try {
      final doc = await _firestore.collection('user_preferences').doc(userId).get();
      return doc.data();
    } catch (e) {
      print('❌ Error loading preferences: $e');
      return null;
    }
  }

  // Save favorite cryptocurrencies
  Future<void> saveFavorites(String userId, List<String> favorites) async {
    try {
      await _firestore.collection('favorites').doc(userId).set({
        'cryptos': favorites,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error saving favorites: $e');
    }
  }

  // Load favorite cryptocurrencies
  Future<List<String>> loadFavorites(String userId) async {
    try {
      final doc = await _firestore.collection('favorites').doc(userId).get();
      if (doc.exists) {
        return List<String>.from(doc.data()?['cryptos'] ?? []);
      }
    } catch (e) {
      print('❌ Error loading favorites: $e');
    }
    return [];
  }

  // Save AI-generated insights for offline viewing
  Future<void> saveInsight(String type, String content) async {
    try {
      await _firestore.collection('ai_insights').add({
        'type': type,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error saving insight: $e');
    }
  }

  // Stream market alerts
  Stream<List<Map<String, dynamic>>> streamMarketAlerts() {
    return _firestore
        .collection('market_alerts')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Check if initialized
  bool get isInitialized => _initialized;
}