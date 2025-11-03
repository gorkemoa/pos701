import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // NumericFormatter için
import 'package:flutter/foundation.dart'; // debugPrint için
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
  final List<Map<String, dynamic>>? initialMenuProducts;

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
    this.initialMenuProducts,
  }) : super(key: key);

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  final ProductService _productService = ProductService();
  final AppLogger _logger = AppLogger();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Menü grupları için GlobalKey'ler
  final Map<int, GlobalKey> _menuGroupKeys = {};
  
  ProductDetail? _productDetail;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedPorsiyonIndex = 0;
  bool _isGift = false;
  bool _isCustomPrice = false; // Özel fiyat kullanılıyor mu
  
  // Seçili özellikler için state - Key: FeatureGroup ID, Value: Seçili Feature ID'leri
  Map<int, List<int>> _selectedFeatures = {};
  
  // Menü seçimleri için state - Key: MenuGroup ID, Value: Map<MenuProduct ID, Miktar>
  Map<int, Map<int, int>> _selectedMenuItems = {};

  @override
  void initState() {
    super.initState();
    _noteController.text = widget.initialNote ?? '';
    _isGift = widget.initialIsGift ?? false;
    
    // Debug: Constructor parametrelerini logla
    debugPrint('🚀 [PRODUCT_DETAIL] initState çağrıldı');
    debugPrint('   selectedProID: ${widget.selectedProID}');
    debugPrint('   selectedLineId: ${widget.selectedLineId}');
    debugPrint('   initialNote: ${widget.initialNote}');
    debugPrint('   initialIsGift: ${widget.initialIsGift}');
    debugPrint('   initialFeatures: ${widget.initialFeatures}');
    debugPrint('   initialMenuProducts: ${widget.initialMenuProducts}');
    
    _loadProductDetail();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _priceController.dispose();
    _scrollController.dispose();
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
          
          // DEBUG: Ürün detayını logla
          debugPrint('📦 [PRODUCT_DETAIL] Ürün detayı yüklendi: ${_productDetail!.postTitle}');
          debugPrint('   isMenu: ${_productDetail!.isMenu}');
          if (_productDetail!.isMenu && _productDetail!.menus.isNotEmpty) {
            debugPrint('   Menü grupları: ${_productDetail!.menus.length}');
            for (var menuGroup in _productDetail!.menus) {
              debugPrint('   - ${menuGroup.menuName} (ID: ${menuGroup.menuID}): ${menuGroup.menuProducts.length} ürün');
              for (var mp in menuGroup.menuProducts) {
                debugPrint('     * mpID=${mp.mpID}, productID=${mp.productID} (${mp.productTitle}), variantID=${mp.variantID} (${mp.variantUnit})');
              }
            }
          }
          
          // Menü grupları için key'leri oluştur
          if (_productDetail!.isMenu && _productDetail!.menus.isNotEmpty) {
            for (final menuGroup in _productDetail!.menus) {
              _menuGroupKeys[menuGroup.menuID] = GlobalKey();
            }
          }
          
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
            
            // Özellik grupları için kontrol
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
          
          // Sepetten gelen menü seçimleri varsa otomatik yükle
          if (widget.initialMenuProducts != null && widget.initialMenuProducts!.isNotEmpty && _productDetail!.isMenu) {
            debugPrint('📋 [PRODUCT_DETAIL] İnitial menü seçimleri yükleniyor: ${widget.initialMenuProducts!.length} adet');
            debugPrint('📋 [PRODUCT_DETAIL] Mevcut menü grupları: ${_productDetail!.menus.map((m) => m.menuID).toList()}');
            
            // initialMenuProducts formatı: [{productID, variantID, qty, menuID}, ...]
            for (final menuProductData in widget.initialMenuProducts!) {
              final int menuID = menuProductData['menuID'] ?? 0;
              final int productID = menuProductData['productID'] ?? 0;
              final int variantID = menuProductData['variantID'] ?? 0;
              
              debugPrint('🔍 [PRODUCT_DETAIL] Aranan: MenuID=$menuID, ProductID=$productID, VariantID=$variantID');
              
              // Bu menü grubunu bul
              try {
                final menuGroup = _productDetail!.menus.firstWhere(
                  (mg) => mg.menuID == menuID,
                );
                
                debugPrint('✓ [PRODUCT_DETAIL] Menü grubu bulundu: ${menuGroup.menuName} (${menuGroup.menuProducts.length} ürün)');
                
                // MenuProduct'ı productID ve variantID'ye göre bul
                try {
                  final menuProduct = menuGroup.menuProducts.firstWhere(
                    (mp) {
                      final matches = mp.productID == productID && mp.variantID == variantID;
                      debugPrint('  Kontrol: mpID=${mp.mpID}, productID=${mp.productID}, variantID=${mp.variantID}, eşleşme=$matches');
                      return matches;
                    },
                  );
                  
                  // Seçimi kaydet
                  if (!_selectedMenuItems.containsKey(menuID)) {
                    _selectedMenuItems[menuID] = <int, int>{};
                  }
                  
                  final currentCount = _selectedMenuItems[menuID]![menuProduct.mpID] ?? 0;
                  _selectedMenuItems[menuID]![menuProduct.mpID] = currentCount + 1;
                  
                  debugPrint('✅ [PRODUCT_DETAIL] Menü seçimi eklendi: MenuID=$menuID, ProductID=$productID, VariantID=$variantID, mpID=${menuProduct.mpID}');
                } catch (e) {
                  debugPrint('❌ [PRODUCT_DETAIL] MenuProduct bulunamadı: $e');
                  debugPrint('   Mevcut ürünler: ${menuGroup.menuProducts.map((mp) => 'mpID=${mp.mpID}(pID=${mp.productID},vID=${mp.variantID})').join(", ")}');
                }
              } catch (e) {
                debugPrint('❌ [PRODUCT_DETAIL] Menü grubu bulunamadı: MenuID=$menuID, Hata: $e');
              }
            }
            
            // Menü seçimlerine göre fiyatı güncelle
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
      // Seçili menü ID listesi (eski format - geriye dönük uyumluluk)
      final List<int> selectedMenuIds = _collectSelectedMenuIds();
      
      // Menü verileri
      final bool isMenu = _productDetail!.isMenu;
      final List<int> menuGroupIds = _collectMenuGroupIds();
      final List<Map<String, dynamic>> menuProductsData = _collectMenuProductsData();
      
      // Hem özellik hem menü ID'lerini birleştir (eski yöntem için)
      final List<int> allSelectedIds = [...selectedFeatureIds, ...selectedMenuIds];
      
      // Fiyat değeri olarak sadece HAM PORSIYON FİYATINI kullan
      // Özellik ve menü ekstra ücretlerini GÖNDERME - Backend hesaplasın
      final String priceValue = _isCustomPrice 
          ? _priceController.text 
          : selectedPorsiyon.proPrice.toString();
      
      final product = Product(
        postID: _productDetail!.postID,
        proID: selectedPorsiyon.proID,
        proName: _productDetail!.postTitle,
        proUnit: selectedPorsiyon.proUnit,
        proStock: selectedPorsiyon.proStock.toString(),
        proPrice: priceValue, // Sadece ham porsiyon fiyatı - ekstra ücretler backend'de hesaplanacak
        proNote: fullNote,
      );
      
      final basketViewModel = Provider.of<BasketViewModel>(context, listen: false);
      
      // Sepetten gelen bir ürün mü? (lineId veya proID ile belirlenebilir)
      if (widget.selectedLineId != null) {
        // Satır ID'si varsa, belirli bir satırı güncelleme
        _updateBasketLine(basketViewModel, product, fullNote, allSelectedIds, selectedMenuIds, isMenu, menuGroupIds, menuProductsData);
      } else if (widget.selectedProID != null) {
        // Sadece ürün ID'si varsa, geriye dönük uyumluluk için
        _updateBasketItemByProductId(basketViewModel, product, fullNote, allSelectedIds, selectedMenuIds, isMenu, menuGroupIds, menuProductsData);
      } else {
        // Yeni ürün ekleme - API ile sunucuya gönder, sonra sepete ekle
        _addProductAsNewItem(basketViewModel, product, fullNote, allSelectedIds, selectedMenuIds, isMenu, menuGroupIds, menuProductsData);
      }
    }
  }
  
  // Belirli bir satırı günceller (lineId ile)
  void _updateBasketLine(
    BasketViewModel basketViewModel, 
    Product product, 
    String fullNote, 
    List<int> allSelectedIds, 
    List<int> selectedMenuIds,
    bool isMenu,
    List<int> menuGroupIds,
    List<Map<String, dynamic>> menuProductsData,
  ) {
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
        proFeature: allSelectedIds,
        isMenu: isMenu,
        menuIDs: menuGroupIds,
        menuProducts: menuProductsData,
      );
      // Ardından 1 adet yeni satır olarak ikram ekle
      basketViewModel.addProduct(
        product,
        proNote: fullNote,
        isGift: true,
        proFeature: allSelectedIds,
        isMenu: isMenu,
        menuIDs: menuGroupIds,
        menuProducts: menuProductsData,
      );
    } else {
      // Satırı güncelle - yeni product bilgileriyle
      basketViewModel.updateSpecificLine(
        lineId, 
        product, 
        existingQuantity,
        proNote: fullNote,
        isGift: _isGift,
        proFeature: allSelectedIds,
        isMenu: isMenu,
        menuIDs: menuGroupIds,
        menuProducts: menuProductsData,
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
  void _updateBasketItemByProductId(
    BasketViewModel basketViewModel, 
    Product product, 
    String fullNote, 
    List<int> allSelectedIds, 
    List<int> selectedMenuIds,
    bool isMenu,
    List<int> menuGroupIds,
    List<Map<String, dynamic>> menuProductsData,
  ) {
    // Eski ürünün ID'si
        int oldProID = widget.selectedProID!;
        
        // Eğer aynı porsiyon seçildiyse sadece bilgileri güncelle
    if (oldProID == product.proID) {
      // İlk bulunan ürünü güncelle
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
            proFeature: allSelectedIds,
            isMenu: isMenu,
            menuIDs: menuGroupIds,
            menuProducts: menuProductsData,
          );
          basketViewModel.addProduct(
            product,
            proNote: fullNote,
            isGift: true,
            proFeature: allSelectedIds,
            isMenu: isMenu,
            menuIDs: menuGroupIds,
            menuProducts: menuProductsData,
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
        
        // Tüm bilgileri güncelle - updateSpecificLine kullan
        basketViewModel.updateSpecificLine(
          existingItem.lineId,
          product,
          existingItem.proQty,
          proNote: fullNote,
          isGift: _isGift,
          proFeature: allSelectedIds,
          isMenu: isMenu,
          menuIDs: menuGroupIds,
          menuProducts: menuProductsData,
        );
          
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
        _addProductAsNewItem(basketViewModel, product, fullNote, allSelectedIds, selectedMenuIds, isMenu, menuGroupIds, menuProductsData);
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
            proFeature: allSelectedIds,
          );
          // Yeni porsiyonu 1 adet ikram olarak ekle
          basketViewModel.addProduct(
            product,
            proNote: fullNote,
            isGift: true,
            proFeature: allSelectedIds,
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
            proFeature: allSelectedIds,
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
        _addProductAsNewItem(basketViewModel, product, fullNote, allSelectedIds, selectedMenuIds, isMenu, menuGroupIds, menuProductsData);
      }
    }
  }

  // Ürünü sepete eklerken API'ye gönder
  void _addProductAsNewItem(
    BasketViewModel basketViewModel, 
    Product product, 
    String fullNote, 
    List<int> allSelectedIds, 
    List<int> selectedMenuIds,
    bool isMenu,
    List<int> menuGroupIds,
    List<Map<String, dynamic>> menuProductsData,
  ) {
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
        proFeature: allSelectedIds,
        isMenu: isMenu,
        menuIDs: menuGroupIds,
        menuProducts: menuProductsData,
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
        proFeature: allSelectedIds,
        isMenu: isMenu,
        menuIDs: menuGroupIds,
        menuProducts: menuProductsData,
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
        final selectedMenuItems = _selectedMenuItems[menuGroup.menuID] ?? <int, int>{};
        for (var entry in selectedMenuItems.entries) {
          final menuProductId = entry.key;
          final quantity = entry.value;
          final menuProduct = menuGroup.menuProducts.firstWhere(
            (mp) => mp.mpID == menuProductId,
            orElse: () => menuGroup.menuProducts.first,
          );
          displayPrice += menuProduct.menuPrice * quantity;
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
        _selectedMenuItems[menuGroupId] = <int, int>{};
      }
      
      final selectedMenuItems = _selectedMenuItems[menuGroupId]!;
      final currentCount = selectedMenuItems[menuProductId] ?? 0;
      final totalSelected = selectedMenuItems.values.fold(0, (sum, count) => sum + count);
      
      if (isSelected) {
        // Maksimum seçim sayısını kontrol et
        if (totalSelected < maxSelection) {
          selectedMenuItems[menuProductId] = currentCount + 1;
          
          // Menü grubunun seçimi tamamlandıysa bir sonraki zorunlu gruba kaydır
          final newTotalSelected = selectedMenuItems.values.fold(0, (sum, count) => sum + count);
          if (newTotalSelected == maxSelection) {
            _scrollToNextIncompleteMenuGroup(menuGroupId);
          }
        }
      } else {
        if (currentCount > 0) {
          if (currentCount == 1) {
            selectedMenuItems.remove(menuProductId);
          } else {
            selectedMenuItems[menuProductId] = currentCount - 1;
          }
        }
      }
      
      // Fiyatı güncelle (sadece görsel gösterim)
      if (!_isCustomPrice) {
        _updatePriceController();
      }
    });
  }
  
  // Bir sonraki tamamlanmamış menü grubuna otomatik kaydır
  void _scrollToNextIncompleteMenuGroup(int currentMenuGroupId) {
    if (_productDetail == null || !_productDetail!.isMenu) return;
    
    // Mevcut grup indexini bul
    int currentIndex = _productDetail!.menus.indexWhere((group) => group.menuID == currentMenuGroupId);
    if (currentIndex == -1) return;
    
    // Bir sonraki tamamlanmamış grubu bul
    for (int i = currentIndex + 1; i < _productDetail!.menus.length; i++) {
      final menuGroup = _productDetail!.menus[i];
      final selectedItems = _selectedMenuItems[menuGroup.menuID] ?? <int, int>{};
      final totalSelected = selectedItems.values.fold(0, (sum, count) => sum + count);
      
      // Bu grup tamamlanmamışsa buraya kaydır
      if (totalSelected < menuGroup.menuSelectQty) {
        final targetKey = _menuGroupKeys[menuGroup.menuID];
        if (targetKey != null && targetKey.currentContext != null) {
          Future.delayed(Duration(milliseconds: 300), () {
            Scrollable.ensureVisible(
              targetKey.currentContext!,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              alignment: 0.1, // Ekranın üst kısmında görünsün
            );
          });
        }
        break;
      }
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
        controller: _scrollController,
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
                final groupKey = _menuGroupKeys[menuGroup.menuID];
                return Container(
                  key: groupKey,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              menuGroup.menuName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          // Minimal ilerleme göstergesi
                          Builder(
                            builder: (context) {
                              final selectedItems = _selectedMenuItems[menuGroup.menuID] ?? <int, int>{};
                              final totalSelected = selectedItems.values.fold(0, (sum, count) => sum + count);
                              final isComplete = totalSelected == menuGroup.menuSelectQty;
                              
                              return Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isComplete 
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  border: Border.all(
                                    color: isComplete ? Colors.green : Colors.grey.shade400,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: isComplete 
                                      ? Icon(Icons.check, size: 14, color: Colors.green)
                                      : Text(
                                          '$totalSelected',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...menuGroup.menuProducts.map((menuProduct) {
                        final selectedItems = _selectedMenuItems[menuGroup.menuID] ?? <int, int>{};
                        final currentQuantity = selectedItems[menuProduct.mpID] ?? 0;
                        final totalSelected = selectedItems.values.fold(0, (sum, count) => sum + count);
                        final canIncrease = totalSelected < menuGroup.menuSelectQty;
                        final canDecrease = currentQuantity > 0;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: currentQuantity > 0 
                                  ? Color(AppConstants.primaryColorValue).withOpacity(0.3)
                                  : Colors.grey.shade200,
                              width: 1,
                            ),
                            color: currentQuantity > 0 
                                ? Color(AppConstants.primaryColorValue).withOpacity(0.02)
                                : Colors.white,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        menuProduct.productTitle,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      if (menuProduct.variantUnit.isNotEmpty) ...[
                                        SizedBox(height: 2),
                                        Text(
                                          menuProduct.variantUnit,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                      if (menuProduct.menuPrice > 0) ...[
                                        SizedBox(height: 4),
                                        Text(
                                          '+₺${menuProduct.menuPrice.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(AppConstants.primaryColorValue),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // Minimal miktar kontrolü
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: canDecrease ? () {
                                            _updateMenuSelection(
                                              menuGroup.menuID, 
                                              menuProduct.mpID, 
                                              false,
                                              menuGroup.menuSelectQty
                                            );
                                          } : null,
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            child: Icon(
                                              Icons.remove,
                                              size: 16,
                                              color: canDecrease ? Colors.grey.shade600 : Colors.grey.shade300,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 36,
                                        child: Center(
                                          child: Text(
                                            '$currentQuantity',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: canIncrease ? () {
                                            _updateMenuSelection(
                                              menuGroup.menuID, 
                                              menuProduct.mpID, 
                                              true,
                                              menuGroup.menuSelectQty
                                            );
                                          } : null,
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            child: Icon(
                                              Icons.add,
                                              size: 16,
                                              color: canIncrease ? Color(AppConstants.primaryColorValue) : Colors.grey.shade300,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
            onPressed: () {
              // Menü seçimleri zorunlu değil - direkt sepete ekle
              _addProductToBasket();
            },
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

  // Seçili menü öğelerinin ID listesini döndürür (eski yöntem - geriye dönük uyumluluk için)
  List<int> _collectSelectedMenuIds() {
    final List<int> ids = [];
    if (_productDetail == null || !_productDetail!.isMenu) {
      return ids;
    }
    
    for (var menuGroup in _productDetail!.menus) {
      final Map<int, int> selectedItems = _selectedMenuItems[menuGroup.menuID] ?? <int, int>{};
      
      // Her menü öğesini miktar kadar ID listesine ekle
      for (var entry in selectedItems.entries) {
        final menuProductId = entry.key;
        final quantity = entry.value;
        for (int i = 0; i < quantity; i++) {
          ids.add(menuProductId);
        }
      }
    }
    
    return ids;
  }

  // Menü grup ID'lerini toplar
  List<int> _collectMenuGroupIds() {
    final List<int> ids = [];
    if (_productDetail == null || !_productDetail!.isMenu) {
      return ids;
    }
    
    for (var menuGroup in _productDetail!.menus) {
      final Map<int, int> selectedItems = _selectedMenuItems[menuGroup.menuID] ?? <int, int>{};
      if (selectedItems.isNotEmpty) {
        ids.add(menuGroup.menuID);
      }
    }
    
    return ids;
  }

  // Seçili menü ürünlerini API formatında döndürür
  List<Map<String, dynamic>> _collectMenuProductsData() {
    final List<Map<String, dynamic>> menuProductsData = [];
    if (_productDetail == null || !_productDetail!.isMenu) {
      return menuProductsData;
    }
    
    for (var menuGroup in _productDetail!.menus) {
      final Map<int, int> selectedItems = _selectedMenuItems[menuGroup.menuID] ?? <int, int>{};
      
      for (var entry in selectedItems.entries) {
        final mpID = entry.key; // MenuProduct ID (mpID)
        final quantity = entry.value;
        
        // Menü ürününü bul
        final menuProduct = menuGroup.menuProducts.firstWhere(
          (mp) => mp.mpID == mpID,
          orElse: () => menuGroup.menuProducts.first,
        );
        
        // Her birim için ayrı kayıt ekle
        for (int i = 0; i < quantity; i++) {
          menuProductsData.add({
            'productID': menuProduct.productID,
            'variantID': menuProduct.variantID,
            'qty': 1,
            'menuID': menuGroup.menuID,
          });
        }
      }
    }
    
    return menuProductsData;
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