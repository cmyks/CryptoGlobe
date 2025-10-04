import 'package:flutter/material.dart';
import 'dart:async';
import '../models/crypto_model.dart';
import '../services/crypto_service.dart';

class CryptoProvider extends ChangeNotifier {
  final CryptoService _cryptoService = CryptoService();
  
  List<CryptoData> _cryptos = [];
  MarketStats? _marketStats;
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  CryptoData? _selectedCrypto;
  List<String> _favorites = [];
  String _sortBy = 'market_cap';
  bool _sortAscending = false;

  List<CryptoData> get cryptos => _cryptos;
  MarketStats? get marketStats => _marketStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  CryptoData? get selectedCrypto => _selectedCrypto;
  List<String> get favorites => _favorites;

  List<CryptoData> get sortedCryptos {
    final sorted = List<CryptoData>.from(_cryptos);
    switch (_sortBy) {
      case 'price':
        sorted.sort((a, b) => _sortAscending 
            ? a.price.compareTo(b.price) 
            : b.price.compareTo(a.price));
        break;
      case 'change':
        sorted.sort((a, b) => _sortAscending 
            ? a.change24h.compareTo(b.change24h) 
            : b.change24h.compareTo(a.change24h));
        break;
      case 'volume':
        sorted.sort((a, b) => _sortAscending 
            ? a.volume24h.compareTo(b.volume24h) 
            : b.volume24h.compareTo(a.volume24h));
        break;
      default:
        sorted.sort((a, b) => _sortAscending 
            ? a.marketCap.compareTo(b.marketCap) 
            : b.marketCap.compareTo(a.marketCap));
    }
    return sorted;
  }

  List<CryptoData> get topGainers {
    final gainers = _cryptos.where((c) => c.change24h > 0).toList();
    gainers.sort((a, b) => b.change24h.compareTo(a.change24h));
    return gainers.take(5).toList();
  }

  List<CryptoData> get topLosers {
    final losers = _cryptos.where((c) => c.change24h < 0).toList();
    losers.sort((a, b) => a.change24h.compareTo(b.change24h));
    return losers.take(5).toList();
  }

  CryptoProvider() {
    initialize();
  }

  Future<void> initialize() async {
    await loadCryptos();
    await loadMarketStats();
    startAutoRefresh();
  }

  Future<void> loadCryptos({int limit = 50}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _cryptos = await _cryptoService.fetchTopCryptos(limit: limit);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load cryptocurrencies: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMarketStats() async {
    try {
      _marketStats = await _cryptoService.fetchMarketStats();
      notifyListeners();
    } catch (e) {
      print('Error loading market stats: $e');
    }
  }

  Future<void> refreshData() async {
    await loadCryptos();
    await loadMarketStats();
  }

  void startAutoRefresh({Duration interval = const Duration(seconds: 30)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) {
      refreshData();
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
  }

  void selectCrypto(CryptoData? crypto) {
    _selectedCrypto = crypto;
    notifyListeners();
  }

  void toggleFavorite(String cryptoId) {
    if (_favorites.contains(cryptoId)) {
      _favorites.remove(cryptoId);
    } else {
      _favorites.add(cryptoId);
    }
    notifyListeners();
  }

  bool isFavorite(String cryptoId) {
    return _favorites.contains(cryptoId);
  }

  void setSorting(String sortBy, {bool? ascending}) {
    _sortBy = sortBy;
    if (ascending != null) {
      _sortAscending = ascending;
    } else {
      _sortAscending = !_sortAscending;
    }
    notifyListeners();
  }

  Future<List<CryptoData>> searchCryptos(String query) async {
    if (query.isEmpty) return _cryptos;
    
    final lowercaseQuery = query.toLowerCase();
    return _cryptos.where((crypto) {
      return crypto.name.toLowerCase().contains(lowercaseQuery) ||
             crypto.symbol.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _cryptoService.dispose();
    super.dispose();
  }
}