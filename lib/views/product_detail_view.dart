import 'package:flutter/material.dart';
import 'package:pos701/models/product_detail_model.dart';
import 'package:pos701/models/basket_model.dart';
import 'package:pos701/models/product_model.dart';
import 'package:pos701/services/product_service.dart';
import 'package:pos701/viewmodels/basket_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/utils/app_logger.dart';

class ProductDetailView extends StatefulWidget {
  final String userToken;
  final int compID;
  final int postID;
  final String tableName;

  const ProductDetailView({
    Key? key,
    required this.userToken,
    required this.compID,
    required this.postID,
    required this.tableName,
  }) : super(key: key);

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  final ProductService _productService = ProductService();
  final AppLogger _logger = AppLogger();
  
  ProductDetail? _productDetail;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedVariantIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProductDetail();
  }

  Future<void> _loadProductDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _productService.getProductDetail(
        userToken: widget.userToken,
        compID: widget.compID,
        postID: widget.postID,
      );

      if (response.success && response.data != null) {
        setState(() {
          _productDetail = response.data;
          _isLoading = false;
          
          // Varsayılan varyantı seçme
          _selectedVariantIndex = _productDetail!.variants
              .indexWhere((variant) => variant.isDefault);
          
          // Varsayılan varyant bulunamadıysa ilk varyantı seç
          if (_selectedVariantIndex < 0 && _productDetail!.variants.isNotEmpty) {
            _selectedVariantIndex = 0;
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Ürün detayları alınamadı';
        });
      }
    } catch (e) {
      _logger.e('Ürün detayları yüklenirken hata oluştu', e);
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().contains('Kullanıcı bilgileri yüklenemedi') 
            ? 'Kullanıcı bilgileri yüklenemedi. Lütfen tekrar giriş yapın.' 
            : 'Ürün detayları yüklenirken bir sorun oluştu. Lütfen daha sonra tekrar deneyin.';
      });
    }
  }

  void _addProductToBasket() {
    if (_productDetail != null && _productDetail!.variants.isNotEmpty) {
      final selectedVariant = _productDetail!.variants[_selectedVariantIndex];
      
      final product = Product(
        postID: _productDetail!.postID,
        proID: selectedVariant.proID,
        proName: '${_productDetail!.postTitle} ${selectedVariant.proUnit}',
        proUnit: selectedVariant.proUnit,
        proStock: selectedVariant.proStock.toString(),
        proPrice: selectedVariant.proPrice.toString(),
      );
      
      final basketViewModel = Provider.of<BasketViewModel>(context, listen: false);
      basketViewModel.addProduct(product);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ürün sepete eklendi'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(AppConstants.primaryColorValue),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.tableName.toUpperCase(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "Ürün Detayı",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _buildProductDetailContent(),
      bottomNavigationBar: _isLoading || _errorMessage != null
          ? null
          : _buildBottomBar(),
    );
  }

  Widget _buildProductDetailContent() {
    if (_productDetail == null) {
      return const Center(child: Text('Ürün detayları bulunamadı'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ürün Başlığı
          Text(
            _productDetail!.postTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Varyantlar
          const Text(
            'Varyantlar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Varyant Listesi
          _buildVariantsList(),
        ],
      ),
    );
  }

  Widget _buildVariantsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _productDetail!.variants.length,
      itemBuilder: (context, index) {
        final variant = _productDetail!.variants[index];
        final isSelected = index == _selectedVariantIndex;
        
        return Card(
          elevation: isSelected ? 4 : 1,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? Color(AppConstants.primaryColorValue) : Colors.transparent,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedVariantIndex = index;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        variant.proUnit,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (variant.isDefault)
                        const Text(
                          'Varsayılan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    '₺${variant.proPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Color(AppConstants.primaryColorValue),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    if (_productDetail == null || _productDetail!.variants.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final selectedVariant = _productDetail!.variants[_selectedVariantIndex];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fiyat',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '₺${selectedVariant.proPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _addProductToBasket,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(AppConstants.primaryColorValue),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Sepete Ekle',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}