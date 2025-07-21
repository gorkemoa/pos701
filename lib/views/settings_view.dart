import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos701/constants/app_constants.dart';
import 'dart:async';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> with TickerProviderStateMixin {
  bool _isVerticalLayout = false;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    
    // Animasyon controller'larını başlat
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Animasyonu başlat
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isVerticalLayout = prefs.getBool('isVerticalLayout') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _toggleLayoutPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isVerticalLayout = !_isVerticalLayout;
    });
    await prefs.setBool('isVerticalLayout', _isVerticalLayout);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isVerticalLayout ? 'Dikey tasarım aktif' : 'Klasik tasarım aktif'),
          backgroundColor: Color(AppConstants.primaryColorValue),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(AppConstants.primaryColorValue),
        title: const Text(
          'Ayarlar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tasarım Ayarları Bölümü
                      _buildSectionHeader('Tasarım Ayarları'),
                      const SizedBox(height: 16),
                      
                      // Layout Seçimi ve Önizleme
                      _buildLayoutSelectionCard(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(AppConstants.primaryColorValue),
      ),
    );
  }

  Widget _buildLayoutSelectionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Başlık ve Switch
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(AppConstants.primaryColorValue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.view_agenda,
                    color: Color(AppConstants.primaryColorValue),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sipariş Sayfası Tasarımı',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isVerticalLayout 
                            ? 'Dikey tasarım - Kategoriler solda, ürünler sağda'
                            : 'Klasik tasarım - Kategoriler üstte, ürünler altta',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isVerticalLayout,
                  onChanged: (value) => _toggleLayoutPreference(),
                  activeColor: Color(AppConstants.primaryColorValue),
                ),
              ],
            ),
          ),
          
          // Önizleme Bölümü
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      size: 16,
                      color: Color(AppConstants.primaryColorValue),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Önizleme',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(AppConstants.primaryColorValue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Tasarım Önizlemesi
                _buildLayoutPreview(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutPreview() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _isVerticalLayout ? _buildVerticalPreview() : _buildClassicPreview(),
    );
  }

  Widget _buildVerticalPreview() {
    return Row(
      children: [
        // Sol: Kategoriler
        Container(
          width: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(
              right: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Column(
            children: [
              _buildPreviewCategory('Yemekler', true),
              _buildPreviewCategory('İçecekler', false),
              _buildPreviewCategory('Tatlılar', false),
            ],
          ),
        ),
        
        // Sağ: Ürünler
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                _buildPreviewProduct('Hamburger', '₺45'),
                _buildPreviewProduct('Pizza', '₺35'),
                _buildPreviewProduct('Salata', '₺25'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassicPreview() {
    return Column(
      children: [
        // Üst: Kategoriler
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Row(
            children: [
              _buildPreviewCategory('Yemekler', true),
              const SizedBox(width: 8),
              _buildPreviewCategory('İçecekler', false),
              const SizedBox(width: 8),
              _buildPreviewCategory('Tatlılar', false),
            ],
          ),
        ),
        
        // Alt: Ürünler Grid
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPreviewProductCard('Hamburger', '₺45'),
                _buildPreviewProductCard('Pizza', '₺35'),
                _buildPreviewProductCard('Salata', '₺25'),
                _buildPreviewProductCard('Kola', '₺8'),
                _buildPreviewProductCard('Su', '₺3'),
                _buildPreviewProductCard('Tiramisu', '₺15'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCategory(String name, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Color(AppConstants.primaryColorValue).withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSelected ? Color(AppConstants.primaryColorValue) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Color(AppConstants.primaryColorValue) : Colors.black87,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPreviewProduct(String name, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            price,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(AppConstants.primaryColorValue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewProductCard(String name, String price) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            price,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Color(AppConstants.primaryColorValue),
            ),
          ),
        ],
      ),
    );
  }


} 