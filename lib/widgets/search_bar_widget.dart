import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crypto_provider.dart';
import '../models/crypto_model.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({Key? key}) : super(key: key);

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<CryptoData> _searchResults = [];
  bool _isSearching = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    
    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      _animController.reverse();
    } else {
      setState(() => _isSearching = true);
      _performSearch(query);
      _animController.forward();
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _searchController.text.isEmpty) {
      _animController.reverse();
    }
  }

  Future<void> _performSearch(String query) async {
    final provider = context.read<CryptoProvider>();
    final results = await provider.searchCryptos(query);
    
    if (mounted) {
      setState(() {
        _searchResults = results;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _focusNode.unfocus();
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
    _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        if (_isSearching) _buildSearchResults(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C5CE7).withOpacity(0.1),
            const Color(0xFF9B8CEE).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6C5CE7).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Search cryptocurrencies...',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: const Color(0xFF6C5CE7),
            size: 24,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
                  onPressed: _clearSearch,
                )
              : Icon(
                  Icons.mic,
                  color: Colors.white.withOpacity(0.3),
                  size: 24,
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6C5CE7).withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: _searchResults.isEmpty
            ? _buildNoResults()
            : _buildResultsList(),
      ),
    );
  }

  Widget _buildNoResults() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No cryptocurrencies found',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildSearchResultItem(_searchResults[index]);
      },
    );
  }

  Widget _buildSearchResultItem(CryptoData crypto) {
    return InkWell(
      onTap: () {
        context.read<CryptoProvider>().selectCrypto(crypto);
        _clearSearch();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2D3561).withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Crypto Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: crypto.isPositive
                      ? [
                          const Color(0xFF00B894).withOpacity(0.3),
                          const Color(0xFF00B894).withOpacity(0.1),
                        ]
                      : [
                          const Color(0xFFFF6B6B).withOpacity(0.3),
                          const Color(0xFFFF6B6B).withOpacity(0.1),
                        ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  crypto.symbol.substring(0, crypto.symbol.length.clamp(0, 3)),
                  style: TextStyle(
                    color: crypto.isPositive
                        ? const Color(0xFF00B894)
                        : const Color(0xFFFF6B6B),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Crypto Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crypto.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    crypto.symbol,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Price and Change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${crypto.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${crypto.change24h >= 0 ? '+' : ''}${crypto.change24h.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: crypto.isPositive
                        ? const Color(0xFF00B894)
                        : const Color(0xFFFF6B6B),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}