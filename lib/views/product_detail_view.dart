import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // NumericFormatter için
import 'package:pos701/models/product_detail_model.dart';
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
  final int? selectedLineId;
  final String? initialNote;
  final bool? initialIsGift;
  final List<int>? initialFeatures;

  const ProductDetailView({
    Key? key,
    required this.userToken,
    required this.compID,
    required this.postID,
    required this.tableName,
    this.selectedProID,
    this.selectedLineId,
    this.initialNote,
    this.initialIsGift,
    this.initialFeatures,
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
  
  // Seçili özellikler için state - Key: FeatureGroup ID, Value: Seçili Feature ID'leri
  Map<int, List<int>> _selectedFeatures = {};
  
  // Menü seçimleri için state - Key: MenuGroup ID, Value: Seçili MenuProduct ID'leri
  Map<int, List<int>> _selectedMenuItems = {};

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

          // Eğer initialFeatures gelmediyse, varianttaki isDefault özellikleri seç
          if ((widget.initialFeatures == null || widget.initialFeatures!.isEmpty) &&
              _productDetail!.variants.isNotEmpty) {
            _applyDefaultFeaturesForCurrentVariant();
            _updatePriceController();
          }

          // Sepetten gelen özellikler varsa otomatik seç
          if (widget.initialFeatures != null && widget.initialFeatures!.isNotEmpty) {
            final selectedVariant = _productDetail!.variants[_selectedPorsiyonIndex];
            final List<int> ids = widget.initialFeatures!;
            for (final fg in selectedVariant.featureGroups) {
              final selectedInGroup = <int>[];
              for (final f in fg.features) {
                if (ids.contains(f.featureID)) {
                  selectedInGroup.add(f.featureID);
                }
              }
              if (selectedInGroup.isNotEmpty) {
                _selectedFeatures[fg.fgID] = selectedInGroup;
              }
            }
            // Seçili özelliklere göre fiyatı güncelle
            _updatePriceController();
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
      
      // Seçili özellikleri not olarak hazırla
      String fullNote = _buildProductNote();
      // Seçili özellik ID listesi
      final List<int> selectedFeatureIds = _collectSelectedFeatureIds();
      // Seçili menü ID listesi
      final List<int> selectedMenuIds = _collectSelectedMenuIds();
      
      // Fiyat değeri olarak sadece temel porsiyon fiyatını kullan (özellik fiyatları backend'de hesaplanıyor)
      final String priceValue = _isCustomPrice 
          ? _priceController.text 
          : selectedPorsiyon.proPrice.toString();
      
      final product = Product(
        postID: _productDetail!.postID,
        proID: selectedPorsiyon.proID,
        proName: _productDetail!.postTitle,
        proUnit: selectedPorsiyon.proUnit,
        proStock: selectedPorsiyon.proStock.toString(),
        proPrice: priceValue, // Özel fiyat veya özellikleri dahil hesaplanmış fiyat
        proNote: fullNote,
      );
      
      final basketViewModel = Provider.of<BasketViewModel>(context, listen: false);
      
      // Sepetten gelen bir ürün mü? (lineId veya proID ile belirlenebilir)
      if (widget.selectedLineId != null) {
        // Satır ID'si varsa, belirli bir satırı güncelleme
        _updateBasketLine(basketViewModel, product, fullNote, selectedFeatureIds, selectedMenuIds);
      } else if (widget.selectedProID != null) {
        // Sadece ürün ID'si varsa, geriye dönük uyumluluk için
        _updateBasketItemByProductId(basketViewModel, product, fullNote, selectedFeatureIds, selectedMenuIds);
      } else {
        // Yeni ürün ekleme - API ile sunucuya gönder, sonra sepete ekle
        _addProductAsNewItem(basketViewModel, product, fullNote, selectedFeatureIds, selectedMenuIds);
      }
    }
  }
  
  // Belirli bir satırı günceller (lineId ile)
  void _updateBasketLine(BasketViewModel basketViewModel, Product product, String fullNote, List<int> selectedFeatureIds, List<int> selectedMenuIds) {
    // Sepette var olan lineId'li satırı güncelle
    int lineId = widget.selectedLineId!;
    
    // Geçerli satırın miktarını bul
    var existingQuantity = 1;
    var existingItem = basketViewModel.items.firstWhere(
      (item) => item.lineId == lineId,
      orElse: () => basketViewModel.items.first,
    );
    try {
      existingQuantity = existingItem.proQty;
    } catch (e) {
      // Satır bulunamadıysa 1 adet olarak devam et
    }
    
    // Eğer miktar 2+ ve ikram seçili ise yalnızca 1 adedi ikram yap (satırı böl)
    if (_isGift && existingQuantity > 1) {
      // Önce mevcut satırı ikram olmayan ve miktarı 1 azaltılmış hale getir
      basketViewModel.updateSpecificLine(
        lineId,
        product,
        existingQuantity - 1,
        proNote: fullNote,
        isGift: false,
        proFeature: selectedFeatureIds,
      );
      // Ardından 1 adet yeni satır olarak ikram ekle
      basketViewModel.addProduct(
        product,
        proNote: fullNote,
        isGift: true,
        proFeature: selectedFeatureIds,
      );
    } else {
      // Satırı güncelle - yeni product bilgileriyle
      basketViewModel.updateSpecificLine(
        lineId, 
        product, 
        existingQuantity,
        proNote: fullNote,
        isGift: _isGift,
        proFeature: selectedFeatureIds,
      );
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ürün bilgileri güncellendi'),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }
  
  // Ürün ID'ye göre sepet öğesini günceller (geriye dönük uyumluluk için)
  void _updateBasketItemByProductId(BasketViewModel basketViewModel, Product product, String fullNote, List<int> selectedFeatureIds, List<int> selectedMenuIds) {
    // Eski ürünün ID'si
        int oldProID = widget.selectedProID!;
        
        // Eğer aynı porsiyon seçildiyse sadece seçilen ürünün notunu, ikram durumunu ve fiyatını güncelle
    if (oldProID == product.proID) {
      // İlk bulunan ürünü güncelle (artık tek bir satır olacak)
      try {
        final existingItem = basketViewModel.items.firstWhere(
          (item) => item.product.proID == oldProID,
        );
        // Eğer miktar 2+ ve ikram seçili ise yalnızca 1 adedi ikram yap (satırı böl)
        if (_isGift && existingItem.proQty > 1) {
          basketViewModel.updateSpecificLine(
            existingItem.lineId,
            product,
            existingItem.proQty - 1,
            proNote: fullNote,
            isGift: false,
            proFeature: selectedFeatureIds,
          );
          basketViewModel.addProduct(
            product,
            proNote: fullNote,
            isGift: true,
            proFeature: selectedFeatureIds,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ürün bilgileri güncellendi'),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop();
          return;
        }
        
        // Not güncelle
        basketViewModel.updateProductNote(existingItem.lineId, fullNote);
        
        // İkram durumunu güncelle
        basketViewModel.toggleGiftStatus(existingItem.lineId, isGift: _isGift);
          
          // Eğer özel fiyat seçilmişse fiyatı güncelle
          if (_isCustomPrice) {
          basketViewModel.updateProductPrice(existingItem.lineId, _priceController.text);
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ürün bilgileri güncellendi'),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop();
          return;
      } catch (e) {
        // Ürün bulunamadıysa, yeni ürün olarak ekle
        _addProductAsNewItem(basketViewModel, product, fullNote, selectedFeatureIds, selectedMenuIds);
        }
    } else {
      // Farklı porsiyon seçildi, ilk bulunan ürünü güncelle
      try {
        final existingItem = basketViewModel.items.firstWhere(
          (item) => item.product.proID == oldProID,
        );
        // Eğer miktar 2+ ve ikram seçili ise yalnızca 1 adedi ikram yap (satırı böl)
        if (_isGift && existingItem.proQty > 1) {
          // Mevcut satırı (eski porsiyon) miktarını 1 azalt, ikram değil
          basketViewModel.updateSpecificLine(
            existingItem.lineId,
            existingItem.product,
            existingItem.proQty - 1,
            proNote: existingItem.proNote,
            isGift: false,
            proFeature: selectedFeatureIds,
          );
          // Yeni porsiyonu 1 adet ikram olarak ekle
          basketViewModel.addProduct(
            product,
            proNote: fullNote,
            isGift: true,
            proFeature: selectedFeatureIds,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ürün bilgileri güncellendi'),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop();
          return;
        }
        
        // Satırı güncelle - yeni porsiyon, not ve ikram bilgileriyle
        basketViewModel.updateSpecificLine(
          existingItem.lineId, 
            product, 
            existingItem.proQty,
            proNote: fullNote,
            isGift: _isGift,
            proFeature: selectedFeatureIds,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ürün bilgileri güncellendi'),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop();
      } catch (e) {
        // Ürün bulunamadıysa, yeni ürün olarak ekle
        _addProductAsNewItem(basketViewModel, product, fullNote, selectedFeatureIds, selectedMenuIds);
      }
    }
  }

  // Ürünü sepete eklerken API'ye gönder
  void _addProductAsNewItem(BasketViewModel basketViewModel, Product product, String fullNote, List<int> selectedFeatureIds, List<int> selectedMenuIds) {
    // Eğer orderID yoksa, sadece sepete ekle (yeni sipariş oluşturma durumunda)
    Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    int? orderID = args?['orderID'];
    
    if (orderID != null) {
      // Sipariş varsa, önce API'ye gönder, sonra sepete ekle
      setState(() => _isLoading = true);
      
      basketViewModel.addProductToOrder(
        userToken: widget.userToken,
        compID: widget.compID,
        orderID: orderID,
        product: product,
        quantity: 1,
        proNote: fullNote,
        isGift: _isGift,
        proFeature: selectedFeatureIds,
      ).then((success) {
        setState(() => _isLoading = false);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ürün sepete eklendi'),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(basketViewModel.errorMessage ?? 'Ürün eklenirken bir hata oluştu'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    } else {
      // Sipariş yoksa, sadece yerel sepete ekle
      basketViewModel.addProduct(
        product,
        proNote: fullNote,
        isGift: _isGift,
        proFeature: selectedFeatureIds,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ürün sepete eklendi'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  // Porsiyon seçildiğinde fiyat kontrolcüsünü günceller (sadece görsel - hesaplama backend'de)
  void _updatePriceController() {
    if (_productDetail != null && _productDetail!.variants.isNotEmpty) {
      final basePrice = _productDetail!.variants[_selectedPorsiyonIndex].proPrice;
      _priceController.text = basePrice.toString();
      _isCustomPrice = false; // Porsiyon değiştiğinde özel fiyat sıfırlansın
    }
  }

  // Toplam fiyatı hesaplar (sadece görsel gösterim için - gerçek hesaplama backend'de yapılıyor)
  double _calculateTotalPrice() {
    if (_productDetail == null || _productDetail!.variants.isEmpty) return 0.0;
    
    final selectedVariant = _productDetail!.variants[_selectedPorsiyonIndex];
    double displayPrice = selectedVariant.proPrice;
    
    // Seçili özelliklerin fiyatlarını görsel olarak ekle (sadece gösterim için)
    for (var featureGroup in selectedVariant.featureGroups) {
      final selectedFeatureIds = _selectedFeatures[featureGroup.fgID] ?? [];
      for (var featureId in selectedFeatureIds) {
        final feature = featureGroup.features.firstWhere(
          (f) => f.featureID == featureId,
          orElse: () => featureGroup.features.first,
        );
        displayPrice += feature.featurePrice;
      }
    }
    
    // Seçili menü öğelerinin fiyatlarını görsel olarak ekle (sadece gösterim için)
    if (_productDetail!.isMenu) {
      for (var menuGroup in _productDetail!.menus) {
        final selectedMenuIds = _selectedMenuItems[menuGroup.menuID] ?? [];
        for (var menuProductId in selectedMenuIds) {
          final menuProduct = menuGroup.menuProducts.firstWhere(
            (mp) => mp.mpID == menuProductId,
            orElse: () => menuGroup.menuProducts.first,
          );
          displayPrice += menuProduct.menuPrice;
        }
      }
    }
    
    return displayPrice;
  }

  // Ürün notunu hazırlar (sadece kullanıcının elle girdiği not)
  String _buildProductNote() {
    // Sadece kullanıcının girdiği notu döndür
    return _noteController.text.trim();
  }

  // Özellik seçildiğinde fiyatı günceller
  void _updateFeatureSelection(int featureGroupId, int featureId, bool isSelected) {
    setState(() {
      if (!_selectedFeatures.containsKey(featureGroupId)) {
        _selectedFeatures[featureGroupId] = [];
      }
      
      final selectedFeatureIds = _selectedFeatures[featureGroupId]!;
      
      if (isSelected) {
        // Tek seçim yapılabiliyorsa önceki seçimi kaldır
        final featureGroup = _productDetail!.variants[_selectedPorsiyonIndex].featureGroups
            .firstWhere((fg) => fg.fgID == featureGroupId);
        
        if (featureGroup.fgType == "1") { // Tek seçim
          selectedFeatureIds.clear();
        }
        
        if (!selectedFeatureIds.contains(featureId)) {
          selectedFeatureIds.add(featureId);
        }
      } else {
        selectedFeatureIds.remove(featureId);
      }
      
      // Fiyatı güncelle (sadece görsel gösterim)
      if (!_isCustomPrice) {
        _updatePriceController();
      }
    });
  }

  // Menü öğesi seçildiğinde güncelleme
  void _updateMenuSelection(int menuGroupId, int menuProductId, bool isSelected, int maxSelection) {
    setState(() {
      if (!_selectedMenuItems.containsKey(menuGroupId)) {
        _selectedMenuItems[menuGroupId] = [];
      }
      
      final selectedMenuIds = _selectedMenuItems[menuGroupId]!;
      
      if (isSelected) {
        // Maksimum seçim sayısını kontrol et
        if (selectedMenuIds.length < maxSelection) {
          selectedMenuIds.add(menuProductId);
        }
      } else {
        selectedMenuIds.remove(menuProductId);
      }
      
      // Fiyatı güncelle (sadece görsel gösterim)
      if (!_isCustomPrice) {
        _updatePriceController();
      }
    });
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
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "Ürün Detayı",
              style: TextStyle(fontSize: 12),
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ürün Başlığı ve Seçili Porsiyon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _productDetail!.postTitle,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_productDetail!.variants.isNotEmpty) 
                    Row(
                      children: [
                        Text(
                          'Seçili Porsiyon: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          _productDetail!.variants[_selectedPorsiyonIndex].proUnit,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(AppConstants.primaryColorValue),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Porsiyonlar
            if (_productDetail!.variants.length > 1) // Sadece birden fazla porsiyon varsa göster
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Porsiyon Seçimi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _selectedPorsiyonIndex,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down),
                      style: const TextStyle(color: Colors.black87, fontSize: 15),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedPorsiyonIndex = newValue;
                            _selectedFeatures.clear();
                            _applyDefaultFeaturesForCurrentVariant();
                            _updatePriceController();
                          });
                        }
                      },
                      items: _productDetail!.variants.asMap().entries.map<DropdownMenuItem<int>>((entry) {
                        int index = entry.key;
                        var porsiyon = entry.value;
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(porsiyon.proUnit, style: const TextStyle(fontSize: 15)),
                              Text(
                                '₺${porsiyon.proPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(AppConstants.primaryColorValue),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            
            // Menü Seçimi (sadece menülü ürünler için)
            if (_productDetail!.isMenu && _productDetail!.menus.isNotEmpty)
              ..._productDetail!.menus.map((menuGroup) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            menuGroup.menuName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Color(AppConstants.primaryColorValue).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              '${menuGroup.menuSelectQty} adet seçin',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(AppConstants.primaryColorValue),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...menuGroup.menuProducts.map((menuProduct) {
                        final isSelected = _selectedMenuItems[menuGroup.menuID]?.contains(menuProduct.mpID) ?? false;
                        final selectedCount = _selectedMenuItems[menuGroup.menuID]?.length ?? 0;
                        final canSelect = selectedCount < menuGroup.menuSelectQty;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: isSelected 
                                  ? Color(AppConstants.primaryColorValue)
                                  : Colors.grey.shade300,
                              width: 0.5,
                            ),
                            color: isSelected 
                                ? Color(AppConstants.primaryColorValue).withOpacity(0.04)
                                : Colors.transparent,
                          ),
                          child: InkWell(
                            onTap: () => _updateMenuSelection(
                              menuGroup.menuID, 
                              menuProduct.mpID, 
                              !isSelected,
                              menuGroup.menuSelectQty
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Radio<int>(
                                    value: menuProduct.mpID,
                                    groupValue: isSelected ? menuProduct.mpID : null,
                                    onChanged: canSelect || isSelected ? (value) {
                                      if (value != null) {
                                        _updateMenuSelection(
                                          menuGroup.menuID, 
                                          value, 
                                          !isSelected,
                                          menuGroup.menuSelectQty
                                        );
                                      }
                                    } : null,
                                    activeColor: Color(AppConstants.primaryColorValue),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          menuProduct.productTitle,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                          ),
                                        ),
                                        Text(
                                          menuProduct.variantUnit,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (menuProduct.menuPrice > 0)
                                        Text(
                                          '+₺${menuProduct.menuPrice.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(AppConstants.primaryColorValue),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      Text(
                                        '₺${menuProduct.variantPrice.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                          decoration: menuProduct.menuPrice > 0 
                                              ? TextDecoration.lineThrough 
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            
            // Özellik Seçimi
            if (_productDetail!.variants.isNotEmpty && 
                _productDetail!.variants[_selectedPorsiyonIndex].featureGroups.isNotEmpty)
              ..._productDetail!.variants[_selectedPorsiyonIndex].featureGroups.map((featureGroup) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            featureGroup.fgName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          if (featureGroup.isFeatureRequired)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Text(
                                'Zorunlu*',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...featureGroup.features.map((feature) {
                        final isSelected = _selectedFeatures[featureGroup.fgID]?.contains(feature.featureID) ?? false;
                        final isSingleSelection = featureGroup.fgType == "1";
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: isSelected 
                                  ? Color(AppConstants.primaryColorValue)
                                  : Colors.grey.shade300,
                              width: 0.5,
                            ),
                            color: isSelected 
                                ? Color(AppConstants.primaryColorValue).withOpacity(0.04)
                                : Colors.transparent,
                          ),
                          child: InkWell(
                            onTap: () => _updateFeatureSelection(
                              featureGroup.fgID, 
                              feature.featureID, 
                              !isSelected
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  if (isSingleSelection)
                                    Radio<int>(
                                      value: feature.featureID,
                                      groupValue: _selectedFeatures[featureGroup.fgID]?.isNotEmpty == true
                                          ? _selectedFeatures[featureGroup.fgID]!.first
                                          : null,
                                      onChanged: (value) {
                                        if (value != null) {
                                          _updateFeatureSelection(featureGroup.fgID, value, true);
                                        }
                                      },
                                      activeColor: Color(AppConstants.primaryColorValue),
                                      visualDensity: VisualDensity.compact,
                                    )
                                  else
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (value) => _updateFeatureSelection(
                                        featureGroup.fgID, 
                                        feature.featureID, 
                                        value ?? false
                                      ),
                                      activeColor: Color(AppConstants.primaryColorValue),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      feature.featureName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (feature.featurePrice > 0)
                                    Text(
                                      '+₺${feature.featurePrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(AppConstants.primaryColorValue),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            
            // Özel Fiyat Alanı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ürün Fiyatı',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [NumericTextFormatter()],
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            labelText: 'Fiyat (₺)',
                            labelStyle: const TextStyle(fontSize: 14),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                            suffixText: '₺',
                            enabled: _isCustomPrice,
                            filled: _isCustomPrice,
                            fillColor: _isCustomPrice ? Colors.yellow.shade50 : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Özel fiyat',
                                style: TextStyle(fontSize: 13),
                              ),
                              const SizedBox(width: 6),
                              Switch.adaptive(
                                value: _isCustomPrice,
                                activeColor: Color(AppConstants.primaryColorValue),
                                onChanged: (value) {
                                  setState(() {
                                    _isCustomPrice = value;
                                    if (!value) {
                                      _updatePriceController();
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                          if (_isCustomPrice)
                            Text(
                              'Manuel giriş aktif',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade800,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Ürün Notu Alanı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ürün Notu',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Ürün ile ilgili eklemek istediğiniz notları yazın',
                      hintStyle: const TextStyle(fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // İkram Seçeneği
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  'İkram olarak işaretle',
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                subtitle: _isGift
                    ? Text(
                        'Bu ürün ikram olarak işaretlenecek.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      )
                    : null,
                value: _isGift,
                activeColor: Color(AppConstants.primaryColorValue),
                onChanged: (val) {
                  setState(() => _isGift = val);
                },
                secondary: Icon(Icons.card_giftcard, color: Color(AppConstants.primaryColorValue), size: 20),
              ),
            ),
          ],
          ),
        ),
      );
    
        
        
  
  }

  Widget _buildBottomBar() {
    if (_productDetail == null || _productDetail!.variants.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Gösterilecek fiyat: Özel fiyat veya görsel toplam fiyat (gerçek hesaplama backend'de)
    final displayPrice = _isCustomPrice
        ? double.tryParse(_priceController.text) ?? _calculateTotalPrice()
        : _calculateTotalPrice();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
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
                    Text(
                      'Fiyat',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (_isCustomPrice)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.orange.shade300, width: 0.5),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isCustomPrice ? Colors.orange.shade800 : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ElevatedButton(
            onPressed: _addProductToBasket,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(AppConstants.primaryColorValue),
                foregroundColor: Colors.white,
                shape:  RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart, size: 18),
                  const SizedBox(width: 8),
                  
                  const Text(
              'Sepete Ekle',
              style: TextStyle(
                      fontSize: 14,
                fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Seçili özelliklerin ID listesini döndürür
  List<int> _collectSelectedFeatureIds() {
    final List<int> ids = [];
    if (_productDetail == null || _productDetail!.variants.isEmpty) return ids;
    final selectedVariant = _productDetail!.variants[_selectedPorsiyonIndex];
    for (var featureGroup in selectedVariant.featureGroups) {
      final List<int> selectedIds = _selectedFeatures[featureGroup.fgID] ?? [];
      ids.addAll(selectedIds);
    }
    return ids;
  }

  // Seçili menü öğelerinin ID listesini döndürür
  List<int> _collectSelectedMenuIds() {
    final List<int> ids = [];
    if (_productDetail == null || !_productDetail!.isMenu) return ids;
    for (var menuGroup in _productDetail!.menus) {
      final List<int> selectedIds = _selectedMenuItems[menuGroup.menuID] ?? [];
      ids.addAll(selectedIds);
    }
    return ids;
  }

  // Mevcut seçili porsiyon için featureGroups içindeki isDefault==true olanları uygular
  void _applyDefaultFeaturesForCurrentVariant() {
    if (_productDetail == null || _productDetail!.variants.isEmpty) return;
    final selectedVariant = _productDetail!.variants[_selectedPorsiyonIndex];
    for (final fg in selectedVariant.featureGroups) {
      final defaults = fg.features.where((f) => f.isDefault).map((f) => f.featureID).toList();
      if (defaults.isNotEmpty) {
        // Tek seçim grubunda birden fazla default gelse bile ilkini alır
        _selectedFeatures[fg.fgID] = List<int>.from(defaults);
      }
    }
  }
}