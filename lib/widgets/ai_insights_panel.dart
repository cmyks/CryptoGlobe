import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gemini_provider.dart';
import '../providers/crypto_provider.dart';

class AIInsightsPanel extends StatefulWidget {
  const AIInsightsPanel({Key? key}) : super(key: key);

  @override
  State<AIInsightsPanel> createState() => _AIInsightsPanelState();
}

class _AIInsightsPanelState extends State<AIInsightsPanel> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialInsights();
    });
  }

  void _loadInitialInsights() {
    final geminiProvider = context.read<GeminiProvider>();
    final cryptoProvider = context.read<CryptoProvider>();

    if (geminiProvider.marketAnalysis == null && cryptoProvider.cryptos.isNotEmpty) {
      geminiProvider.generateMarketAnalysis(cryptoProvider.cryptos);
    }

    if (geminiProvider.marketPrediction == null && cryptoProvider.marketStats != null) {
      geminiProvider.generateMarketPrediction(cryptoProvider.marketStats!);
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GeminiProvider, CryptoProvider>(
      builder: (context, geminiProvider, cryptoProvider, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F3A).withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF6C5CE7).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildHeader(geminiProvider, cryptoProvider),
              Expanded(
                child: geminiProvider.chatHistory.isEmpty
                    ? _buildInsightsView(geminiProvider)
                    : _buildChatView(geminiProvider),
              ),
              _buildChatInput(geminiProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(GeminiProvider geminiProvider, CryptoProvider cryptoProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF6C5CE7).withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF9B8CEE)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.psychology,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Insights',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Powered by Gemini',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              if (cryptoProvider.cryptos.isNotEmpty) {
                geminiProvider.generateMarketAnalysis(cryptoProvider.cryptos);
              }
              if (cryptoProvider.marketStats != null) {
                geminiProvider.generateMarketPrediction(cryptoProvider.marketStats!);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsView(GeminiProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInsightCard(
          'Market Analysis',
          provider.marketAnalysis,
          provider.isLoadingAnalysis,
          Icons.analytics,
          const Color(0xFF6C5CE7),
        ),
        const SizedBox(height: 16),
        _buildInsightCard(
          'Market Prediction',
          provider.marketPrediction,
          provider.isLoadingPrediction,
          Icons.trending_up,
          const Color(0xFF00B894),
        ),
        const SizedBox(height: 16),
        _buildQuickActions(provider),
      ],
    );
  }

  Widget _buildInsightCard(
    String title,
    String? content,
    bool isLoading,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3561).withOpacity(0.4),
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            _buildLoadingShimmer()
          else if (content != null)
            Text(
              content,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            )
          else
            const Text(
              'No insights available yet.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }

  Widget _buildQuickActions(GeminiProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3561).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Questions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickActionChip('Explain Bitcoin', provider),
              _buildQuickActionChip('Best crypto to buy?', provider),
              _buildQuickActionChip('Market trends today', provider),
              _buildQuickActionChip('What is DeFi?', provider),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(String text, GeminiProvider provider) {
    return InkWell(
      onTap: () {
        provider.sendChatMessage(text);
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF6C5CE7).withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6C5CE7).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildChatView(GeminiProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: provider.chatHistory.length,
      itemBuilder: (context, index) {
        final message = provider.chatHistory[index];
        return _buildChatMessage(message);
      },
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: message.isUser
              ? const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF9B8CEE)],
                )
              : null,
          color: message.isUser ? null : const Color(0xFF2D3561).withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: message.isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Thinking...', style: TextStyle(color: Colors.white70)),
                ],
              )
            : Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
      ),
    );
  }

  Widget _buildChatInput(GeminiProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: const Color(0xFF6C5CE7).withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ask about crypto...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: const Color(0xFF2D3561).withOpacity(0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  provider.sendChatMessage(value.trim());
                  _chatController.clear();
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF9B8CEE)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () {
                final text = _chatController.text.trim();
                if (text.isNotEmpty) {
                  provider.sendChatMessage(text);
                  _chatController.clear();
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}