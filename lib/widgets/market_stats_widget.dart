import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/crypto_provider.dart';

class MarketStatsWidget extends StatelessWidget {
  const MarketStatsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CryptoProvider>(
      builder: (context, provider, child) {
        final stats = provider.marketStats;
        
        if (stats == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C5CE7).withOpacity(0.2),
                const Color(0xFF9B8CEE).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF6C5CE7).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildStatRow(
                'Total Market Cap',
                _formatCurrency(stats.totalMarketCap),
                Icons.account_balance,
                const Color(0xFF6C5CE7),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'BTC Dominance',
                      '${stats.btcDominance.toStringAsFixed(1)}%',
                      Icons.currency_bitcoin,
                      const Color(0xFFF7931A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'ETH Dominance',
                      '${stats.ethDominance.toStringAsFixed(1)}%',
                      Icons.currency_exchange,
                      const Color(0xFF627EEA),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatRow(
                '24h Volume',
                _formatCurrency(stats.totalVolume24h),
                Icons.trending_up,
                const Color(0xFF00B894),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3561).withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1e12) {
      return '\$${(value / 1e12).toStringAsFixed(2)}T';
    } else if (value >= 1e9) {
      return '\$${(value / 1e9).toStringAsFixed(2)}B';
    } else if (value >= 1e6) {
      return '\$${(value / 1e6).toStringAsFixed(2)}M';
    } else {
      return NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(value);
    }
  }
}