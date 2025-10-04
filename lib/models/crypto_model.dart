// Cryptocurrency Model
class CryptoData {
  final String id;
  final String symbol;
  final String name;
  final double price;
  final double change24h;
  final double marketCap;
  final double volume24h;
  final String image;
  final double high24h;
  final double low24h;
  final DateTime lastUpdated;

  CryptoData({
    required this.id,
    required this.symbol,
    required this.name,
    required this.price,
    required this.change24h,
    required this.marketCap,
    required this.volume24h,
    required this.image,
    required this.high24h,
    required this.low24h,
    required this.lastUpdated,
  });

  factory CryptoData.fromJson(Map<String, dynamic> json) {
    return CryptoData(
      id: json['id'] ?? '',
      symbol: (json['symbol'] ?? '').toUpperCase(),
      name: json['name'] ?? '',
      price: (json['current_price'] ?? 0).toDouble(),
      change24h: (json['price_change_percentage_24h'] ?? 0).toDouble(),
      marketCap: (json['market_cap'] ?? 0).toDouble(),
      volume24h: (json['total_volume'] ?? 0).toDouble(),
      image: json['image'] ?? '',
      high24h: (json['high_24h'] ?? 0).toDouble(),
      low24h: (json['low_24h'] ?? 0).toDouble(),
      lastUpdated: DateTime.parse(json['last_updated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'current_price': price,
      'price_change_percentage_24h': change24h,
      'market_cap': marketCap,
      'total_volume': volume24h,
      'image': image,
      'high_24h': high24h,
      'low_24h': low24h,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  bool get isPositive => change24h >= 0;
}

// Global Information Model
class GlobalInfo {
  final String country;
  final String capital;
  final double latitude;
  final double longitude;
  final String timezone;
  final int population;
  final String currency;
  final String flag;
  final List<String> languages;

  GlobalInfo({
    required this.country,
    required this.capital,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.population,
    required this.currency,
    required this.flag,
    required this.languages,
  });

  factory GlobalInfo.fromJson(Map<String, dynamic> json) {
    return GlobalInfo(
      country: json['country'] ?? '',
      capital: json['capital'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      timezone: json['timezone'] ?? '',
      population: json['population'] ?? 0,
      currency: json['currency'] ?? '',
      flag: json['flag'] ?? '',
      languages: List<String>.from(json['languages'] ?? []),
    );
  }
}

// Market Statistics Model
class MarketStats {
  final double totalMarketCap;
  final double totalVolume24h;
  final double btcDominance;
  final double ethDominance;
  final int activeCryptocurrencies;
  final DateTime lastUpdated;

  MarketStats({
    required this.totalMarketCap,
    required this.totalVolume24h,
    required this.btcDominance,
    required this.ethDominance,
    required this.activeCryptocurrencies,
    required this.lastUpdated,
  });

  factory MarketStats.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return MarketStats(
      totalMarketCap: (data['total_market_cap']?['usd'] ?? 0).toDouble(),
      totalVolume24h: (data['total_volume']?['usd'] ?? 0).toDouble(),
      btcDominance: (data['market_cap_percentage']?['btc'] ?? 0).toDouble(),
      ethDominance: (data['market_cap_percentage']?['eth'] ?? 0).toDouble(),
      activeCryptocurrencies: data['active_cryptocurrencies'] ?? 0,
      lastUpdated: DateTime.now(),
    );
  }
}

// AI Insight Model
class AIInsight {
  final String title;
  final String content;
  final String category;
  final DateTime timestamp;
  final double confidence;

  AIInsight({
    required this.title,
    required this.content,
    required this.category,
    required this.timestamp,
    required this.confidence,
  });

  factory AIInsight.fromGeminiResponse(String response) {
    return AIInsight(
      title: 'Market Analysis',
      content: response,
      category: 'crypto',
      timestamp: DateTime.now(),
      confidence: 0.85,
    );
  }
}