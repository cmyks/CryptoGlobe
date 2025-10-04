import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/crypto_provider.dart';
import '../models/crypto_model.dart';

class CryptoPanel extends StatelessWidget {
  const CryptoPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CryptoProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF6C5CE7),
            ),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(provider.error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.refreshData(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Top gainers/losers
            _buildTopMoversSection(provider),
            
            // Crypto list
            Expanded(
              child: _buildCryptoList(provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopMoversSection(CryptoProvider provider) {
    return Container(
      height: 140,
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildMoverCard(
              'Top Gainers',
              provider.topGainers,
              Colors.green,
              Icons.trending_up,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMoverCard(
              'Top Losers',
              provider.topLosers,
              Colors.red,
              Icons.trending_down,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoverCard(
    String title,
    List<CryptoData> cryptos,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: cryptos.length.clamp(0, 3),
              itemBuilder: (context, index) {
                final crypto = cryptos[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        crypto.symbol,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${crypto.change24h >= 0 ? '+' : ''}${crypto.change24h.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCryptoList(CryptoProvider provider) {
    final cryptos = provider.sortedCryptos;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withOpacity(0.6),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'All Cryptocurrencies',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildSortButton(provider),
              ],
            ),
          ),
          
          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: cryptos.length,
              itemBuilder: (context, index) {
                return _buildCryptoListItem(cryptos[index], provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton(CryptoProvider provider) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort, color: Colors.white),
      color: const Color(0xFF1A1F3A),
      onSelected: (value) => provider.setSorting(value),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'market_cap', child: Text('Market Cap')),
        const PopupMenuItem(value: 'price', child: Text('Price')),
        const PopupMenuItem(value: 'change', child: Text('24h Change')),
        const PopupMenuItem(value: 'volume', child: Text('Volume')),
      ],
    );
  }

  Widget _buildCryptoListItem(CryptoData crypto, CryptoProvider provider) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final compactFormatter = NumberFormat.compact();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3561).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6C5CE7).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: crypto.isPositive 
                ? const Color(0xFF00B894).withOpacity(0.2)
                : const Color(0xFFFF6B6B).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              crypto.symbol.substring(0, crypto.symbol.length.clamp(0, 3)),
              style: TextStyle(
                color: crypto.isPositive ? const Color(0xFF00B894) : const Color(0xFFFF6B6B),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        title: Text(
          crypto.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          'Vol: ${compactFormatter.format(crypto.volume24h)}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatter.format(crypto.price),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: crypto.isPositive
                    ? const Color(0xFF00B894).withOpacity(0.2)
                    : const Color(0xFFFF6B6B).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${crypto.change24h >= 0 ? '+' : ''}${crypto.change24h.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: crypto.isPositive ? const Color(0xFF00B894) : const Color(0xFFFF6B6B),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        onTap: () => provider.selectCrypto(crypto),
      ),
    );
  }
}