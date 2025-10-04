import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/globe_provider.dart';
import '../providers/crypto_provider.dart';
import '../providers/gemini_provider.dart';
import '../widgets/globe_widget.dart';
import '../widgets/crypto_panel.dart';
import '../widgets/ai_insights_panel.dart';
import '../widgets/market_stats_widget.dart';
import '../widgets/search_bar_widget.dart';

class GlobeScreen extends StatefulWidget {
  const GlobeScreen({Key? key}) : super(key: key);

  @override
  State<GlobeScreen> createState() => _GlobeScreenState();
}

class _GlobeScreenState extends State<GlobeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  int _selectedTab = 0;
  bool _showPanel = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Auto-rotate globe
    Future.delayed(Duration.zero, () {
      _startAutoRotation();
    });
  }

  void _startAutoRotation() {
    final globeProvider = context.read<GlobeProvider>();
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 16));
      if (mounted) {
        globeProvider.autoRotate();
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(),
          
          // Main content
          SafeArea(
            child: isLandscape
                ? _buildLandscapeLayout()
                : _buildPortraitLayout(),
          ),
          
          // Top app bar
          _buildTopBar(),
          
          // Floating action buttons
          _buildFloatingActions(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A0E27),
            const Color(0xFF1A1F3A),
            const Color(0xFF0A0E27),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: StarFieldPainter(),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        const SizedBox(height: 60),
        
        // Market stats
        const MarketStatsWidget(),
        
        // 3D Globe
        Expanded(
          flex: 3,
          child: FadeTransition(
            opacity: _fadeController,
            child: const GlobeWidget(),
          ),
        ),
        
        // Bottom tabs
        _buildTabBar(),
        
        // Content panel
        Expanded(
          flex: 2,
          child: _buildContentPanel(),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Left side - Globe
        Expanded(
          flex: 3,
          child: Column(
            children: [
              const SizedBox(height: 60),
              const MarketStatsWidget(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeController,
                  child: const GlobeWidget(),
                ),
              ),
            ],
          ),
        ),
        
        // Right side - Panels
        Expanded(
          flex: 2,
          child: Column(
            children: [
              const SizedBox(height: 60),
              _buildTabBar(),
              Expanded(child: _buildContentPanel()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Logo and title
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6C5CE7).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.language,
                  color: Color(0xFF6C5CE7),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'CryptoGlobe',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              
              // Live indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6C5CE7).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildTab('Crypto', Icons.currency_bitcoin, 0),
          _buildTab('AI Insights', Icons.psychology, 1),
          _buildTab('Markets', Icons.show_chart, 2),
        ],
      ),
    );
  }

  Widget _buildTab(String label, IconData icon, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF9B8CEE)],
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : Colors.white54,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentPanel() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _selectedTab == 0
          ? const CryptoPanel()
          : _selectedTab == 1
              ? const AIInsightsPanel()
              : const MarketStatsWidget(),
    );
  }

  Widget _buildFloatingActions() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFloatingButton(
            icon: Icons.refresh,
            onTap: () {
              context.read<CryptoProvider>().refreshData();
            },
            tooltip: 'Refresh Data',
          ),
          const SizedBox(height: 12),
          _buildFloatingButton(
            icon: Icons.pause_circle_outline,
            onTap: () {
              context.read<GlobeProvider>().toggleRotation();
            },
            tooltip: 'Toggle Rotation',
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF9B8CEE)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C5CE7).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.3);
    
    for (int i = 0; i < 100; i++) {
      final x = (i * 37) % size.width;
      final y = (i * 73) % size.height;
      canvas.drawCircle(
        Offset(x, y),
        (i % 3) * 0.5 + 0.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}