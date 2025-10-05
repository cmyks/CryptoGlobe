import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/crypto_model.dart';
import '../services/crypto_service.dart';

/// Robust, null-safe CryptoProvider with safe initialization, error handling,
/// and unmodifiable public collections to avoid accidental mutation from UI.
class CryptoProvider extends ChangeNotifier {
  final CryptoService _cryptoService = CryptoService();

  final List<CryptoData> _cryptos = [];
  MarketStats? _marketStats;
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  CryptoData? _selectedCrypto;
  final List<String> _favorites = [];
  String _sortBy = 'market_cap';
  bool _sortAscending = false;
  bool _initialized = false;

  // Public, read-only views
  UnmodifiableListView<CryptoData> get cryptos => UnmodifiableListView(_cryptos);
  MarketStats? get marketStats => _marketStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  CryptoData? get selectedCrypto => _selectedCrypto;
  UnmodifiableListView<String> get favorites => UnmodifiableListView(_favorites);

  CryptoProvider() {
    // Kick off initialization without blocking the constructor.
    _initialize();
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    _initialized = true;
    await initialize();
  }

  Future<void> initialize() async {
    _setLoading(true);
    try {
      await loadCryptos();
      await loadMarketStats();
      startAutoRefresh();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCryptos({int limit = 50}) async {
    _setLoading(true);
    _setError(null);
    try {
      final fetched = await _cryptoService.fetchTopCryptos(limit: limit);
      _cryptos
        ..clear()
        ..addAll(fetched);
      // Keep existing sorting behavior intact (UI should call setSorting if needed)
      notifyListeners();
    } catch (e, st) {
      _setError('Failed to load cryptocurrencies: $e');
      if (kDebugMode) {
        // ignore: avoid_print
        print('CryptoProvider.loadCryptos error: $e\n$st');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMarketStats() async {
    try {
      final stats = await _cryptoService.fetchMarketStats();
      _marketStats = stats;
      notifyListeners();
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('CryptoProvider.loadMarketStats error: $e\n$st');
      }
    }
  }

  Future<void> refreshData() async {
    // Fire both in parallel to be faster; errors are handled inside methods.
    await Future.wait([
      loadCryptos(),
      loadMarketStats(),
    ]);
  }

  void startAutoRefresh({Duration interval = const Duration(seconds: 30)}) {
    _refreshTimer?.cancel();
    // Use a non-blocking periodic timer and handle async refresh inside.
    _refreshTimer = Timer.periodic(interval, (_) {
      // Fire-and-forget but catch errors in refreshData
      refreshData().catchError((e, st) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('Auto-refresh error: $e\n$st');
        }
      });
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
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

  bool isFavorite(String cryptoId) => _favorites.contains(cryptoId);

  void setSorting(String sortBy, {bool? ascending}) {
    _sortBy = sortBy;
    if (ascending != null) {
      _sortAscending = ascending;
    } else {
      _sortAscending = !_sortAscending;
    }
    notifyListeners();
  }

  List<CryptoData> get sortedCryptos {
    final sorted = List<CryptoData>.from(_cryptos);
    switch (_sortBy) {
      case 'price':
        sorted.sort((a, b) =>
            _sortAscending ? a.price.compareTo(b.price) : b.price.compareTo(a.price));
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

  Future<List<CryptoData>> searchCryptos(String query) async {
    if (query.trim().isEmpty) return List<CryptoData>.from(_cryptos);
    final lowercaseQuery = query.toLowerCase();
    return _cryptos.where((crypto) {
      return crypto.name.toLowerCase().contains(lowercaseQuery) ||
          crypto.symbol.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? e) {
    _error = e;
    notifyListeners();
  }

  @override
  void dispose() {
    stopAutoRefresh();
    // If CryptoService exposes a dispose method, call it safely.
    try {
      // ignore: unnecessary_null_comparison
      if (_cryptoService != null) {
        _cryptoService.dispose.call();
      }
    } catch (_) {
      // ignore errors if service doesn't have dispose
    }
    super.dispose();
  }
}