import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // NumericFormatter için
import 'package:pos701/models/product_detail_model.dart';
import 'package:pos701/models/basket_model.dart';
import 'package:pos701/models/product_model.dart';
import 'package:pos701/services/product_service.dart';
import 'package:pos701/viewmodels/basket_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/utils/app_logger.dart';

// Sayısal değerleri formatlayan helper sınıfı
class NumericTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    // Sadece sayı ve nokta/virgül kabul et
    if (newValue.text.contains(RegExp(r'[^\d.,]'))) {
      return oldValue;
    }
    
    // Virgülü noktaya çevir (Türkçe klavye uyumluluğu için)
    String text = newValue.text.replaceAll(',', '.');
    
    // Birden fazla nokta varsa, sadece ilkini kabul et
    if (text.split('.').length > 2) {
      return oldValue;
    }
    
    // Sayısal değeri double olarak kontrol et
    try {
      double.parse(text);
      return TextEditingValue(
        text: text,
        selection: newValue.selection,
      );
    } catch (e) {
      return oldValue;
    }
  }
}

class ProductDetailView extends StatefulWidget {
  final String userToken;
  final int compID;
  final int postID;
  final String tableName;
  final int? selectedProID;
  final String? initialNote;
  final bool? initialIsGift;

  const ProductDetailView({
    Key? key,
    required this.userToken,
    required this.compID,
    required this.postID,
    required this.tableName,
    this.selectedProID,
    this.initialNote,
    this.initialIsGift,
  }) : super(key: key);

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  final ProductService _productService = ProductService();
  final AppLogger _logger = AppLogger();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  ProductDetail? _productDetail;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedPorsiyonIndex = 0;
  bool _isGift = false;
  bool _isCustomPrice = false; // Özel fiyat kullanılıyor mu

  @override
  void initState() {
    super.initState();
    _noteController.text = widget.initialNote ?? '';
    _isGift = widget.initialIsGift ?? false;
    _loadProductDetail();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _priceController.dispose();
    super.dispose();
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
          
          if (widget.selectedProID != null) {
            // Sepetten seçilen ürünün porsiyonunu bul
            _selectedPorsiyonIndex = _productDetail!.variants
                .indexWhere((porsiyon) => porsiyon.proID == widget.selectedProID);
          }
          
          // Seçili porsiyon bulunamadıysa varsayılan porsiyonu seç
          if (_selectedPorsiyonIndex < 0) {
            _selectedPorsiyonIndex = _productDetail!.variants
                .indexWhere((porsiyon) => porsiyon.isDefault);
          }
          
          // Varsayılan porsiyon bulunamadıysa ilk porsiyonu seç
          if (_selectedPorsiyonIndex < 0 && _productDetail!.variants.isNotEmpty) {
            _selectedPorsiyonIndex = 0;
          }
          
          // Fiyat kontrolcüsüne başlangıç değeri ata
          if (_productDetail!.variants.isNotEmpty) {
            _priceController.text = _productDetail!.variants[_selectedPorsiyonIndex].proPrice.toString();
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
      final selectedPorsiyon = _productDetail!.variants[_selectedPorsiyonIndex];
      
      // Fiyat değeri olarak özel fiyat veya mevcut fiyatı kullan
      final String priceValue = _isCustomPrice 
          ? _priceController.text 
          : selectedPorsiyon.proPrice.toString();
      
      final product = Product(
        postID: _productDetail!.postID,
        proID: selectedPorsiyon.proID,
        proName: '${_productDetail!.postTitle} ${selectedPorsiyon.proUnit}',
        proUnit: selectedPorsiyon.proUnit,
        proStock: selectedPorsiyon.proStock.toString(),
        proPrice: priceValue, // Özel fiyat veya orijinal fiyat
        proNote: _noteController.text,
      );
      
      final basketViewModel = Provider.of<BasketViewModel>(context, listen: false);
      
      // Sepetten gelen bir ürün mü?
      if (widget.selectedProID != null) {
        // Sepetten gelen ürünün eski proID'si
        int oldProID = widget.selectedProID!;
        
        // Eğer aynı porsiyon seçildiyse sadece notu, ikram durumunu ve fiyatı güncelle
        if (oldProID == selectedPorsiyon.proID) {
          basketViewModel.updateProductNote(oldProID, _noteController.text);
          basketViewModel.toggleGiftStatus(oldProID, isGift: _isGift);
          
          // Eğer özel fiyat seçilmişse fiyatı güncelle
          if (_isCustomPrice) {
            basketViewModel.updateProductPrice(oldProID, _priceController.text);
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ürün bilgileri güncellendi'),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop();
          return;
        }
        
        // Eski ürünü sepetten bul
        final existingItem = basketViewModel.items.firstWhere(
          (item) => item.product.proID == oldProID,
          orElse: () => BasketItem(product: product, proQty: 0),
        );
        
        if (existingItem.proQty > 0) {
          // Sadece seçili öğeyi güncelle, miktar korunacak ve not eklenecek
          basketViewModel.updateSpecificItem(
            oldProID, 
            product, 
            existingItem.proQty,
            proNote: _noteController.text,
            isGift: _isGift,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ürün bilgileri güncellendi'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // Ürün bulunamadı, normal ekleme yap
          basketViewModel.addProduct(
            product, 
            proNote: _noteController.text,
            isGift: _isGift,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ürün sepete eklendi'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Normal ürün ekleme
        basketViewModel.addProduct(
          product, 
          proNote: _noteController.text,
          isGift: _isGift,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ürün sepete eklendi'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Geri dön
      Navigator.of(context).pop();
    }
  }

  // Porsiyon seçildiğinde fiyat kontrolcüsünü günceller
  void _updatePriceController() {
    if (_productDetail != null && _productDetail!.variants.isNotEmpty) {
      _priceController.text = _productDetail!.variants[_selectedPorsiyonIndex].proPrice.toString();
      _isCustomPrice = false; // Porsiyon değiştiğinde özel fiyat sıfırlansın
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
          
          // Porsiyonlar
          const Text(
            'Porsiyonlar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Porsiyon Listesi
          _buildPorsiyonList(),
          
          // Özel Fiyat Alanı
          const SizedBox(height: 24),
          const Text(
            'Ürün Fiyatı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [NumericTextFormatter()],
                  decoration: InputDecoration(
                    labelText: 'Fiyat (₺)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.monetization_on),
                    suffixText: '₺',
                    enabled: _isCustomPrice,
                    filled: _isCustomPrice,
                    fillColor: _isCustomPrice ? Colors.yellow.shade50 : null,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isCustomPrice = !_isCustomPrice;
                    if (!_isCustomPrice) {
                      // Özel fiyat kaldırılırsa orijinal fiyata geri dön
                      _updatePriceController();
                    }
                  });
                },
                icon: Icon(_isCustomPrice ? Icons.lock_open : Icons.lock),
                label: Text(_isCustomPrice ? 'Kilidi Kaldır' : 'Fiyat Değiştir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCustomPrice ? Colors.orange : Color(AppConstants.primaryColorValue),
                ),
              ),
            ],
          ),
          if (_isCustomPrice)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Özel fiyat girişi aktif. Farklı bir fiyat girebilirsiniz.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade800,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          
          // Ürün Notu Alanı
          const SizedBox(height: 24),
          const Text(
            'Ürün Notu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              hintText: 'Ürün ile ilgili eklemek istediğiniz notları yazın',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            maxLines: 3,
          ),
          
          // İkram Seçeneği
          const SizedBox(height: 24),
          Row(
            children: [
              Checkbox(
                value: _isGift,
                activeColor: Color(AppConstants.primaryColorValue),
                onChanged: (value) {
                  setState(() {
                    _isGift = value ?? false;
                  });
                },
              ),
              const Text(
                'İkram olarak işaretle',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isGift)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.card_giftcard, color: Colors.red.shade400, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'İkram',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_isGift)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 8),
              child: Text(
                'Bu ürün ikram olarak işaretlenecek ve ücretlendirilmeyecek.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPorsiyonList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _productDetail!.variants.length,
      itemBuilder: (context, index) {
        final porsiyon = _productDetail!.variants[index];
        final isSelected = index == _selectedPorsiyonIndex;
        
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
                _selectedPorsiyonIndex = index;
                _updatePriceController(); // Fiyatı güncelle
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
                        porsiyon.proUnit,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (porsiyon.isDefault)
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
                    '₺${porsiyon.proPrice.toStringAsFixed(2)}',
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
    
    final selectedPorsiyon = _productDetail!.variants[_selectedPorsiyonIndex];
    // Gösterilecek fiyat: Özel fiyat veya porsiyon fiyatı
    final displayPrice = _isCustomPrice
        ? double.tryParse(_priceController.text) ?? selectedPorsiyon.proPrice
        : selectedPorsiyon.proPrice;
    
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
                Row(
                  children: [
                    const Text(
                      'Fiyat',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    if (_isCustomPrice)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Text(
                          'Özel',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  '₺${displayPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _isCustomPrice ? Colors.orange.shade800 : Colors.black,
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
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}