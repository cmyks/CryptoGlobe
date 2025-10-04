import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/crypto_model.dart';

class CryptoService {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';
  static const String _coinMarketCapUrl = 'https://pro-api.coinmarketcap.com/v1';
  
  // Free tier - no API key required for CoinGecko
  final http.Client _client = http.Client();
  Timer? _refreshTimer;
  
  // Fetch top cryptocurrencies
  Future<List<CryptoData>> fetchTopCryptos({int limit = 50}) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '$_baseUrl/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=$limit&page=1&sparkline=false&price_change_percentage=24h',
        ),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CryptoData.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load crypto data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching crypto data: $e');
      return _getMockCryptoData();
    }
  }

  // Fetch specific cryptocurrency
  Future<CryptoData?> fetchCryptoById(String id) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/coins/markets?vs_currency=usd&ids=$id'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return CryptoData.fromJson(data[0]);
        }
      }
    } catch (e) {
      print('Error fetching crypto by id: $e');
    }
    return null;
  }

  // Fetch global market statistics
  Future<MarketStats> fetchMarketStats() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/global'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MarketStats.fromJson(data);
      }
    } catch (e) {
      print('Error fetching market stats: $e');
    }
    return _getMockMarketStats();
  }

  // Fetch historical price data for charts
  Future<List<Map<String, dynamic>>> fetchPriceHistory(
    String coinId, {
    int days = 7,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/coins/$coinId/market_chart?vs_currency=usd&days=$days'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prices = data['prices'] as List;
        return prices.map((p) => {
          'timestamp': p[0],
          'price': p[1],
        }).toList();
      }
    } catch (e) {
      print('Error fetching price history: $e');
    }
    return [];
  }

  // Stream real-time price updates (simulated with polling)
  Stream<List<CryptoData>> streamCryptoPrices({
    int limit = 20,
    Duration interval = const Duration(seconds: 30),
  }) async* {
    while (true) {
      try {
        final data = await fetchTopCryptos(limit: limit);
        yield data;
        await Future.delayed(interval);
      } catch (e) {
        print('Error in price stream: $e');
        await Future.delayed(interval);
      }
    }
  }

  // Search cryptocurrencies
  Future<List<CryptoData>> searchCryptos(String query) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/search?query=$query'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coins = data['coins'] as List;
        
        // Fetch detailed data for search results
        final ids = coins.take(10).map((c) => c['id']).join(',');
        return fetchTopCryptos(limit: 10);
      }
    } catch (e) {
      print('Error searching cryptos: $e');
    }
    return [];
  }

  // Mock data for offline/error scenarios
  List<CryptoData> _getMockCryptoData() {
    return [
      CryptoData(
        id: 'bitcoin',
        symbol: 'BTC',
        name: 'Bitcoin',
        price: 65420.50,
        change24h: 2.34,
        marketCap: 1280000000000,
        volume24h: 35000000000,
        image: '',
        high24h: 66000,
        low24h: 64000,
        lastUpdated: DateTime.now(),
      ),
      CryptoData(
        id: 'ethereum',
        symbol: 'ETH',
        name: 'Ethereum',
        price: 3245.80,
        change24h: -1.23,
        marketCap: 390000000000,
        volume24h: 18000000000,
        image: '',
        high24h: 3300,
        low24h: 3200,
        lastUpdated: DateTime.now(),
      ),
      CryptoData(
        id: 'binancecoin',
        symbol: 'BNB',
        name: 'BNB',
        price: 578.45,
        change24h: 3.45,
        marketCap: 89000000000,
        volume24h: 2100000000,
        image: '',
        high24h: 585,
        low24h: 560,
        lastUpdated: DateTime.now(),
      ),
    ];
  }

  MarketStats _getMockMarketStats() {
    return MarketStats(
      totalMarketCap: 2450000000000,
      totalVolume24h: 95000000000,
      btcDominance: 52.3,
      ethDominance: 15.9,
      activeCryptocurrencies: 13500,
      lastUpdated: DateTime.now(),
    );
  }

  void dispose() {
    _refreshTimer?.cancel();
    _client.close();
  }
}