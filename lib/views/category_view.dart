import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:pos701/models/user_model.dart';
import 'package:pos701/viewmodels/user_viewmodel.dart';
import 'package:pos701/viewmodels/category_viewmodel.dart';
import 'package:pos701/viewmodels/product_viewmodel.dart';
import 'package:pos701/models/product_category_model.dart';
import 'package:pos701/models/product_model.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/services/product_service.dart';
import 'package:pos701/views/basket_view.dart';
import 'package:pos701/viewmodels/basket_viewmodel.dart';
import 'package:pos701/viewmodels/tables_viewmodel.dart';
import 'package:pos701/viewmodels/customer_viewmodel.dart';
import 'package:pos701/models/customer_model.dart';
import 'package:pos701/services/customer_service.dart';
import 'package:pos701/models/order_model.dart' as order_model;  // Sipariş için CustomerAddress sınıfı

class CategoryView extends StatefulWidget {
  final int compID;
  final String userToken;
  final int? tableID;
  final int? orderID;
  final String tableName;
  final int orderType; // Sipariş türü: 1-Masa, 2-Paket, 3-Gel-Al

  const CategoryView({
    Key? key,
    required this.compID,
    required this.userToken,
    this.tableID,
    this.orderID,
    required this.tableName,
    this.orderType = 1, // Varsayılan değer: Masa siparişi
  }) : super(key: key);

  @override
  State<CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  late CategoryViewModel _categoryViewModel;
  late ProductViewModel _productViewModel;
  bool _isInitialized = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _orderDescController = TextEditingController();
  final TextEditingController _customerSearchController = TextEditingController();
  Category? _selectedCategory;
  int _cartCount = 0;
  String _orderDesc = '';
  int _orderGuest = 1; // Misafir sayısı için değişken
  Customer? _selectedCustomer; // Seçili müşteri
  List<order_model.CustomerAddress> _selectedCustomerAddresses = [];
  int _isKuver = 0; // Kuver ücretinin aktif/pasif durumu (0: pasif, 1: aktif)
  int _isWaiter = 0; // Garsoniye ücretinin aktif/pasif durumu (0: pasif, 1: aktif)

  @override
  void initState() {
    super.initState();
    _categoryViewModel = CategoryViewModel(ProductService());
    _productViewModel = ProductViewModel(ProductService());
    
    // Widget ağacı oluşturulduktan sonra sepeti temizle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final basketViewModel = Provider.of<BasketViewModel>(context, listen: false);
      basketViewModel.clearBasket();
    });
    
    // Arama alanını dinlemeye başla
    _searchController.addListener(_filterProducts);
    
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterProducts);
    _searchController.dispose();
    _orderDescController.dispose();
    _customerSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final success = await _categoryViewModel.loadCategories(
      widget.userToken,
      widget.compID,
    );
    
    setState(() {
      _isInitialized = true;
    });

    // Kategoriler başarıyla yüklendiyse ve en az bir kategori varsa, ilk kategoriyi seç
    if (success && _categoryViewModel.hasCategories) {
      setState(() {
        _selectedCategory = _categoryViewModel.categories[0];
      });
      // İlk kategorinin ürünlerini yükle
      _loadProducts(_selectedCategory!.catID, _selectedCategory!.catName);
    }
  }
  
  Future<void> _loadProducts(int catID, String categoryName) async {
    _productViewModel.setCategoryInfo(catID, categoryName);
    final success = await _productViewModel.loadProductsOfCategory(
      widget.userToken,
      widget.compID,
      catID,
    );
  }

  // Ürünleri arama metni ile filtrele
  void _filterProducts() {
    final String searchText = _searchController.text.trim().toLowerCase();
    _productViewModel.filterProductsByName(searchText);
  }

  @override
  Widget build(BuildContext context) {
    final basketViewModel = Provider.of<BasketViewModel>(context);
    final customerViewModel = Provider.of<CustomerViewModel>(context, listen: false);
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _categoryViewModel),
        ChangeNotifierProvider.value(value: _productViewModel),
      ],
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(AppConstants.primaryColorValue),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.tableName.toUpperCase(), 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(widget.orderID != null ? "Sipariş Düzenle" : "Yeni sipariş", 
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, size: 30),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: _showMenuDialog,
            ),
          ],
        ),
        body: Consumer<CategoryViewModel>(
          builder: (context, categoryViewModel, child) {
            if (categoryViewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (categoryViewModel.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text(categoryViewModel.errorMessage!, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadCategories,
                      style: ElevatedButton.styleFrom(backgroundColor: Color(AppConstants.primaryColorValue)),
                      child: const Text('Yeniden Dene'),
                    ),
                  ],
                ),
              );
            }

            if (!categoryViewModel.hasCategories) {
              return const Center(child: Text('Kategori bulunamadı'));
            }

            return Column(
              children: [
                // Arama Çubuğu
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Ürün arayın...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    // Arama temizlendiğinde tüm ürünleri görüntüle
                                    _filterProducts();
                                  },
                                )
                              : null,
                          hintStyle: const TextStyle(fontSize: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) {
                          // Her değişiklikte değil, setState çağırarak UI'yı güncelle
                          setState(() {});
                          // Listener zaten _filterProducts'ı çağıracak
                        },
                      ),
                      
                      // Arama sonucu bilgisi
                      if (_searchController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                          child: Consumer<ProductViewModel>(
                            builder: (context, productViewModel, child) {
                              final int productCount = productViewModel.products.length;
                              return Text(
                                'Bulunan ürün: $productCount',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Kategoriler ve Ürünler tek bir ScrollView içinde
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Kategoriler Bölümü
                        _buildCategoriesSection(categoryViewModel),
                        
                        // Ürünler Bölümü
                        _buildProductsSection(context),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _goToBasket,
          backgroundColor: Color(AppConstants.primaryColorValue),
          child: Stack(
            children: [
              const Icon(Icons.shopping_cart),
              if (basketViewModel.totalQuantity > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      '${basketViewModel.totalQuantity}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Alt Navigasyon Çubuğu
        bottomNavigationBar: Container(
          height: 60,
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    color: Color(AppConstants.primaryColorValue),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chevron_left, color: Colors.white),
                          Text(
                            'Geri',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: widget.orderID != null ? _showPaymentDialog : null,
                  child: Container(
                    color: Color(AppConstants.primaryColorValue),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.payment, 
                            color: widget.orderID != null ? Colors.white : Colors.white.withOpacity(0.5), 
                            size: 18
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ödeme Al',
                            style: TextStyle(
                              color: widget.orderID != null ? Colors.white : Colors.white.withOpacity(0.5), 
                              fontSize: 14
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {},
                  child: Container(
                    color: Color(AppConstants.primaryColorValue),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.print, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Yazdır',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Kategoriler bölümünü oluştur
  Widget _buildCategoriesSection(CategoryViewModel categoryViewModel) {
    List<Category> categories = categoryViewModel.categories;
    if (categories.isEmpty) return const SizedBox.shrink();
    
    // Sabit yükseklik hesapla (görseldeki 6 satırlık kategori alanı)
    final double categoryBlockHeight = MediaQuery.of(context).size.height * 0.28;
    final double rowHeight = categoryBlockHeight / 6.0;
    
    List<Widget> categoryRows = [];
    int itemsProcessed = 0;

    // İlk 5 satır, her satırda 3 kategori
    for (int i = 0; i < 5 && itemsProcessed < categories.length; i++) {
      List<Widget> rowButtons = [];
      for (int j = 0; j < 3; j++) {
        if (itemsProcessed < categories.length) {
          Category category = categories[itemsProcessed];
          Color categoryColor = _getCategoryColor(category);
          rowButtons.add(Expanded(child: _buildConfigurableCategoryButton(category, categoryColor, rowHeight)));
          itemsProcessed++;
        } else {
          rowButtons.add(const Expanded(child: SizedBox.shrink()));
        }
      }
      categoryRows.add(SizedBox(
        height: rowHeight, 
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: rowButtons)
      ));
    }

    // Son satırda kalan kategoriler (en fazla 2 kategori)
    if (itemsProcessed < categories.length) {
      List<Widget> lastRowButtons = [];
      int remainingItems = categories.length - itemsProcessed;
      for (int k = 0; k < remainingItems && k < 2; k++) {
        Category category = categories[itemsProcessed];
        Color categoryColor = _getCategoryColor(category);
        lastRowButtons.add(Expanded(child: _buildConfigurableCategoryButton(category, categoryColor, rowHeight)));
        itemsProcessed++;
      }
      
      // Son satırda en az bir kategori varsa ekle
      if (lastRowButtons.isNotEmpty) {
        categoryRows.add(SizedBox(
          height: rowHeight, 
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: lastRowButtons)
        ));
      }
    }

    return Column(children: categoryRows);
  }

  // Ürünler bölümünü oluştur
  Widget _buildProductsSection(BuildContext context) {
    return Consumer<ProductViewModel>(
      builder: (context, productViewModel, child) {
        if (productViewModel.isLoading) {
          return Container(
            height: 300,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        }

        if (productViewModel.errorMessage != null) {
          return Container(
            height: 300,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(productViewModel.errorMessage!, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _selectedCategory != null ? 
                    _loadProducts(_selectedCategory!.catID, _selectedCategory!.catName) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedCategory != null ? 
                      _getCategoryColor(_selectedCategory!) : Colors.grey,
                  ),
                  child: const Text('Yeniden Dene'),
                ),
              ],
            ),
          );
        }

        if (!productViewModel.hasProducts) {
          return Container(
            height: 300,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'Bu kategoride henüz ürün bulunmuyor',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Ürün sayısına göre dinamik yükseklik hesapla (her satırda 3 ürün)
        final int productCount = productViewModel.products.length;
        final int rowCount = (productCount / 3).ceil();
        final double estimatedGridHeight = rowCount * 180.0; // 180 piksel ortalama kart yüksekliği
        
        return Container(
          height: estimatedGridHeight,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(), // Ana kaydırma içinde olduğu için bu grid kaydırılmayacak
            shrinkWrap: true,
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 6,
              childAspectRatio: 0.9,
            ),
            itemCount: productViewModel.products.length,
            itemBuilder: (context, index) {
              final product = productViewModel.products[index];
              return _buildProductCard(product);
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryButton(Category category, Color categoryColor) {
    
    return Card(
      margin: const EdgeInsets.all(1.0), // Adjusted margin for tighter fit
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      color: categoryColor,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = category;
          });
          _loadProducts(category.catID, category.catName);
        },
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              category.catName.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigurableCategoryButton(Category category, Color categoryColor, double buttonHeight) {
    return SizedBox(
      height: buttonHeight,
      child: Card(
        margin: const EdgeInsets.all(1.0), // Görseldeki sıkı yerleşim için kenar boşluğunu azalttım
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0), // Köşeleri olmayan düz butonlar
        ),
        color: categoryColor,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedCategory = category;
            });
            _loadProducts(category.catID, category.catName);
          },
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0), // Metin için iç dolgu
              child: Text(
                category.catName.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14, 
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis, // Uzun metinler için
                maxLines: 2, // En fazla iki satır
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(Category category) {
    try {
      return Color(int.parse(category.catColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey; // Renk kodu geçersizse varsayılan renk
    }
  }

  Widget _buildProductCard(Product product) {
    final basketViewModel = Provider.of<BasketViewModel>(context, listen: false);
    final isInBasket = basketViewModel.getProductQuantity(product) > 0;
    final quantity = basketViewModel.getProductQuantity(product);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Sepete eklenmemişse tıklandığında ekle
          // Sepetteyse ve kontrol butonları görünüyorsa, ana tıklama bir şey yapmayabilir
          // veya ürün detayına gidebilir (şu anki davranış ekleme)
          if (!isInBasket) {
            // Ürünü opID=0 ile ekle (yeni ürün)
            basketViewModel.addProduct(product, opID: 0);
            debugPrint('🛍️ [CATEGORY_VIEW] Yeni ürün sepete eklendi: ${product.proName}');
          } else {
            // İsteğe bağlı: Sepetteyken karta tıklamak bir şey yapmasın
            // Veya miktar artırma gibi birincil eylem olabilir.
            // Mevcut +/- butonları zaten bu işlevi görüyor.
            debugPrint('🛍️ [CATEGORY_VIEW] Ürün zaten sepette: ${product.proName}, miktar: $quantity');
          }
        },
        child: Column(
          children: [
            // Ürün Adı ve Fiyat Bölümü
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          product.proName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₺${product.proPrice.replaceAll(" TL", "")}',
                      style: const TextStyle(
                        fontSize: 14, // Görselle uyum için punto biraz büyütüldü
                        fontWeight: FontWeight.bold,
                        color: Colors.black87, // Görseldeki gibi siyah tonu
                      ),
                    ),
                    // Stok bilgisini küçük yazı olarak ekle
                    if (product.proStock != null && product.proStock.isNotEmpty && int.tryParse(product.proStock) != null && int.parse(product.proStock) > 0)
                      Text(
                        'Stok: ${product.proStock}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Alt Kontrol Bölümü (Sadece sepetteyse gösterilir)
            if (isInBasket)
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Eksi Butonu
                    Container(
                      width: 26,
                      height: 26,
                      margin: const EdgeInsets.only(right: 4),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            basketViewModel.decreaseProduct(product);
                            debugPrint('➖ [CATEGORY_VIEW] Ürün miktarı azaltıldı: ${product.proName}, miktar: ${basketViewModel.getProductQuantity(product)}');
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(AppConstants.primaryColorValue).withOpacity(0.1),
                            ),
                            child: Icon(
                              Icons.remove,
                              size: 14,
                              color: Color(AppConstants.primaryColorValue),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Miktar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '$quantity',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(AppConstants.primaryColorValue),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                    // Artı Butonu
                    Container(
                      width: 26,
                      height: 26,
                      margin: const EdgeInsets.only(left: 4),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            basketViewModel.addProduct(product, opID: 0);
                            debugPrint('➕ [CATEGORY_VIEW] Ürün miktarı artırıldı: ${product.proName}, miktar: ${basketViewModel.getProductQuantity(product)}');
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(AppConstants.primaryColorValue).withOpacity(0.1),
                            ),
                            child: Icon(
                              Icons.add,
                              size: 14,
                              color: Color(AppConstants.primaryColorValue),
                            ),
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
  }

  Future<void> _goToBasket() async {
    debugPrint('🛒 Sepete yönlendiriliyor. TableID: ${widget.tableID}, OrderID: ${widget.orderID}, TableName: ${widget.tableName}, OrderType: ${widget.orderType}');
    
    final Map<String, dynamic> arguments = {
      'tableID': widget.tableID,
      'tableName': widget.tableName,
      'orderDesc': _orderDesc,
      'orderGuest': _orderGuest,
      'orderType': widget.orderType, // Sipariş türünü ekle
      'isKuver': _isKuver, // Kuver aktif/pasif durumu
      'isWaiter': _isWaiter, // Garsoniye aktif/pasif durumu
    };
    
    // Eğer müşteri seçilmişse müşteri bilgilerini ekleyelim
    if (_selectedCustomer != null) {
      arguments['custID'] = _selectedCustomer!.custID;
      arguments['custName'] = _selectedCustomer!.custName;
      arguments['custPhone'] = _selectedCustomer!.custPhone;
      
      // Müşteri adres bilgilerini de ekleyelim
      arguments['custAdrs'] = _selectedCustomerAddresses;
      
      debugPrint('🛒 Müşteri seçildi: ${_selectedCustomer!.custName}');
      if (_selectedCustomerAddresses.isNotEmpty) {
        debugPrint('🛒 Müşteri için adres eklendi: ${_selectedCustomerAddresses.length} adet');
      }
    }
    
    // Eğer sipariş varsa orderID ekleyelim
    if (widget.orderID != null) {
      arguments['orderID'] = widget.orderID;
      debugPrint('🛒 Mevcut sipariş düzenleniyor. OrderID: ${widget.orderID}');
    } else {
      debugPrint('🛒 Yeni sipariş oluşturuluyor.');
    }
    
    debugPrint('🛒 Sipariş notu: $_orderDesc');
    debugPrint('🛒 Misafir sayısı: $_orderGuest');
    debugPrint('🛒 Kuver durumu: $_isKuver');
    debugPrint('🛒 Garsoniye durumu: $_isWaiter');
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BasketView(
          tableName: widget.tableName,
          orderID: widget.orderID,
          orderDesc: _orderDesc,
          orderGuest: _orderGuest,
          selectedCustomer: _selectedCustomer,
          customerAddresses: _selectedCustomerAddresses,  // Müşteri adres bilgilerini ekle
          tableID: widget.tableID, // Masa ID'sini ekle
          orderType: widget.orderType, // Sipariş türünü ekle
          isKuver: _isKuver, // Kuver durumunu ekle
          isWaiter: _isWaiter, // Garsoniye durumunu ekle
        ),
        settings: RouteSettings(
          arguments: arguments,
        ),
      ),
    );
  }
  
  /// Ödeme tipi seçme diyaloğunu göster
  Future<void> _showPaymentDialog() async {
    if (widget.orderID == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ödeme almak için aktif bir sipariş gereklidir.'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final basketViewModel = Provider.of<BasketViewModel>(context, listen: false);
    
    if (basketViewModel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ödeme almak için sepette ürün olmalıdır.'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Kullanıcı bilgilerini kontrol et, company ve ödeme tipleri var mı?
    if (userViewModel.userInfo == null || userViewModel.userInfo!.company == null || 
        userViewModel.userInfo!.company!.compPayTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ödeme tipleri bulunamadı.'), backgroundColor: Colors.red),
      );
      return;
    }
    
    // Ödeme diyaloğunu göster
    final List<PaymentType> paymentTypes = userViewModel.userInfo!.company!.compPayTypes;
    
    PaymentType? selectedPaymentType;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödeme Tipi Seçin', style: TextStyle(fontSize: 18)),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.4,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: paymentTypes.length,
            itemBuilder: (context, index) {
              final paymentType = paymentTypes[index];
              Color typeColor;
              try {
                typeColor = Color(int.parse(paymentType.typeColor.replaceFirst('#', '0xFF')));
              } catch (e) {
                typeColor = Colors.grey;
              }
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: typeColor.withOpacity(0.2),
                  child: paymentType.typeImg.isNotEmpty 
                      ? Image.network(
                          paymentType.typeImg,
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) => 
                              Icon(Icons.payment, color: typeColor),
                        )
                      : Icon(Icons.payment, color: typeColor),
                ),
                title: Text(paymentType.typeName),
                onTap: () {
                  selectedPaymentType = paymentType;
                  Navigator.of(context).pop();
                },
                trailing: Icon(Icons.chevron_right, color: typeColor),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
    
    // Ödeme tipi seçildiyse ödeme işlemini gerçekleştir
    if (selectedPaymentType != null) {
      _processPayment(selectedPaymentType!);
    }
  }
  
  /// Seçilen ödeme tipi ile ödeme işlemini gerçekleştir
  Future<void> _processPayment(PaymentType paymentType) async {
    setState(() => _isInitialized = false); // Yükleniyor durumunu göster
    
    try {
      final tablesViewModel = Provider.of<TablesViewModel>(context, listen: false);
      
      // Hızlı ödeme işlemini gerçekleştir
      final bool success = await tablesViewModel.fastPay(
        userToken: widget.userToken,
        compID: widget.compID,
        orderID: widget.orderID!,
        isDiscount: 0, // İndirim yok
        discountType: 0, // İndirim tipi yok
        discount: 0, // İndirim miktarı 0
        payType: paymentType.typeID,
        payAction: 'PAYMENT', // Ödeme işlemi
      );
      
      setState(() => _isInitialized = true);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${paymentType.typeName} ile ödeme başarıyla alındı.'),
            backgroundColor: Colors.green,
          ),
        );
        // Ana sayfaya geri dön
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ödeme işlemi başarısız: ${tablesViewModel.errorMessage ?? "Bilinmeyen hata"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isInitialized = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ödeme işlemi sırasında hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMenuDialog() {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final bool showKuverGarsoniye = userViewModel.userInfo?.company?.compKuverWaiter ?? false;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
        insetPadding: EdgeInsets.zero,
        alignment: Alignment.topRight,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.height,
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: Color(AppConstants.primaryColorValue),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      'Menü',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: ListView(
                  children: [
                    _buildMenuItem(
                      icon: Icons.description,
                      title: 'NOT',
                      onTap: () {
                        Navigator.of(context).pop();
                        _showOrderDescDialog();
                      },
                    ),
                    
                    const Divider(height: 1),
                    
                    _buildMenuItem(
                      icon: Icons.people,
                      title: 'Misafir Sayısı',
                      onTap: () {
                        Navigator.of(context).pop();
                        _showGuestCountDialog();
                      },
                    ),
                    
                    const Divider(height: 1),
                    
                    _buildMenuItem(
                      icon: Icons.person,
                      title: 'Müşteri',
                      onTap: () {
                        Navigator.of(context).pop();
                        _showCustomerDialog();
                      },
                    ),
                    
                    if (showKuverGarsoniye) const Divider(height: 1),
                    
                    if (showKuverGarsoniye)
                      _buildMenuItem(
                        icon: Icons.attach_money,
                        title: 'Kuver Ücreti Ekle',
                        onTap: () {
                          Navigator.of(context).pop();
                          _toggleKuverDurumu();
                        },
                      ),
                    
                    if (showKuverGarsoniye) const Divider(height: 1),
                    
                    if (showKuverGarsoniye)
                      _buildMenuItem(
                        icon: Icons.monetization_on,
                        title: 'Garsoniye Ücreti Ekle',
                        onTap: () {
                          Navigator.of(context).pop();
                          _toggleGarsoniyeDurumu();
                        },
                      ),
                    
                    const Divider(height: 1),
                    
                    _buildMenuItem(
                      icon: Icons.print,
                      title: 'Yazdır',
                      onTap: () {
                        Navigator.of(context).pop();
                        // Yazdır işlemi
                      },
                    ),
                    
                    const Divider(height: 1),
                    
                    _buildMenuItem(
                      icon: Icons.qr_code,
                      title: 'Barkod',
                      onTap: () {
                        Navigator.of(context).pop();
                        // Barkod işlemi
                      },
                    ),
                    
                    const Divider(height: 1),
                    
                    _buildMenuItem(
                      icon: Icons.close,
                      title: 'Masayı Kapat',
                      onTap: () {
                        Navigator.of(context).pop();
                        _showCancelOrderDialog();
                      },
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
  
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  // Sipariş açıklaması ekleme diyaloğu
  void _showOrderDescDialog() {
    _orderDescController.text = _orderDesc;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sipariş Notu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _orderDescController,
              decoration: const InputDecoration(
                hintText: 'Sipariş için not ekleyin',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            const Text(
              'Bu not sipariş ile ilişkilendirilecek ve mutfağa iletilecektir.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _orderDesc = _orderDescController.text.trim();
              });
              Navigator.of(context).pop();
              
              if (_orderDesc.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sipariş notu kaydedildi'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(AppConstants.primaryColorValue),
            ),
            child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Misafir sayısı seçme diyaloğu
  void _showGuestCountDialog() {
    int tempGuestCount = _orderGuest;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Misafir Sayısı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_circle, color: Color(AppConstants.primaryColorValue)),
                    onPressed: () {
                      if (tempGuestCount > 1) {
                        setState(() {
                          tempGuestCount--;
                        });
                      }
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$tempGuestCount',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: Color(AppConstants.primaryColorValue)),
                    onPressed: () {
                      setState(() {
                        tempGuestCount++;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Masadaki misafir sayısını belirleyin',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _orderGuest = tempGuestCount;
                });
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Misafir sayısı: $_orderGuest'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(AppConstants.primaryColorValue),
              ),
              child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Müşteri seçme diyaloğu
  void _showCustomerDialog() async {
    final customerViewModel = Provider.of<CustomerViewModel>(context, listen: false);
    
    // Müşteri listesini getir
    await customerViewModel.getCustomers(
      userToken: widget.userToken,
      compID: widget.compID,
    );

    if (!mounted) return;
    
    // Yeni müşteri ekleme için değişkenler
    String newCustomerName = '';
    String newCustomerPhone = '';
    String newCustomerEmail = '';
    bool isPhoneValid = true;
    final formKey = GlobalKey<FormState>();
    
    // Adres bilgileri için değişkenler
    bool showAddressForm = false;
    String addrTitle = '';
    String addrAddress = '';
    String addrNote = '';
    bool isDefaultAddress = true;
    
    // _CategoryViewState'in setState'ini çağırmak için referans
    final outerSetState = setState;
    
    // Sipariş oluşturmak için kullanılacak adres listesi
    List<order_model.CustomerAddress> orderAddresses = [];

    // Aktif tab değişkenini diyalog dışında tanımlayalım
    int activeTabIndex = 0;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: DefaultTabController(
              length: 2,
              initialIndex: 0,
              child: Builder(
                builder: (builderContext) {
                  // DefaultTabController değişikliklerini dinle
                  final tabController = DefaultTabController.of(builderContext);
                  tabController.addListener(() {
                    if (!tabController.indexIsChanging) {
                      setState(() {
                        // Tab değişikliğini burada izleyip StatefulBuilder içindeki değişkeni güncelliyoruz
                        activeTabIndex = tabController.index;
                        debugPrint('🔄 Tab değişti: $activeTabIndex');
                      });
                    }
                  });
                  
                  return Container(
                    width: MediaQuery.of(context).size.width * 0.95,
                    height: MediaQuery.of(context).size.height * 0.85,
                    child: Column(
                      children: [
                        // Başlık ve kapama butonu
                        Container(
                          decoration: BoxDecoration(
                            color: Color(AppConstants.primaryColorValue),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Müşteri İşlemleri',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ),
                        
                        // Tab bar
                        Material(
                          color: Colors.white,
                          child: TabBar(
                            indicatorColor: Color(AppConstants.primaryColorValue),
                            labelColor: Color(AppConstants.primaryColorValue),
                            unselectedLabelColor: Colors.grey.shade600,
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                            tabs: const [
                              Tab(
                                icon: Icon(Icons.person_search),
                                text: 'Müşteri Ara',
                              ),
                              Tab(
                                icon: Icon(Icons.person_add),
                                text: 'Yeni Müşteri',
                              ),
                            ],
                          ),
                        ),
                        
                        // Tab içerikleri
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: TabBarView(
                              children: [
                                // Müşteri arama tab içeriği
                                Column(
                                  children: [
                                    // Arama kutusu
                                    TextField(
                                      controller: _customerSearchController,
                                      decoration: InputDecoration(
                                        hintText: 'Müşteri adı, telefon veya e-posta ara...',
                                        prefixIcon: const Icon(Icons.search),
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _customerSearchController.clear();
                                            // Arama temizlendiğinde tüm müşterileri getir
                                            customerViewModel.getCustomers(
                                              userToken: widget.userToken,
                                              compID: widget.compID,
                                            );
                                          },
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                      ),
                                      onSubmitted: (value) {
                                        // Arama yapılınca filtrelenmiş müşterileri getir
                                        customerViewModel.getCustomers(
                                          userToken: widget.userToken,
                                          compID: widget.compID,
                                          searchText: value,
                                        );
                                      },
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Seçili müşteri bilgisi
                                    if (_selectedCustomer != null)
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Color(AppConstants.primaryColorValue).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Color(AppConstants.primaryColorValue),
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Seçili Müşteri:',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Color(AppConstants.primaryColorValue),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.clear),
                                                  color: Color(AppConstants.primaryColorValue),
                                                  onPressed: () {
                                                    setState(() {
                                                      _selectedCustomer = null;
                                                    });
                                                    outerSetState(() {
                                                      _selectedCustomer = null;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor: Color(AppConstants.primaryColorValue).withOpacity(0.2),
                                                  radius: 28,
                                                  child: Icon(
                                                    Icons.person,
                                                    size: 32,
                                                    color: Color(AppConstants.primaryColorValue),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        _selectedCustomer!.custName,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            _selectedCustomer!.custPhone,
                                                            style: const TextStyle(fontSize: 14),
                                                          ),
                                                        ],
                                                      ),
                                                      if (_selectedCustomer!.custEmail.isNotEmpty) ...[
                                                        const SizedBox(height: 4),
                                                        Row(
                                                          children: [
                                                            const Icon(Icons.email, size: 16, color: Colors.grey),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              _selectedCustomer!.custEmail,
                                                              style: const TextStyle(fontSize: 14),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Müşteri listesi
                                    Expanded(
                                      child: Consumer<CustomerViewModel>(
                                        builder: (context, customerViewModel, child) {
                                          if (customerViewModel.isLoading) {
                                            return const Center(
                                              child: CircularProgressIndicator(),
                                            );
                                          }
                                          
                                          if (customerViewModel.errorMessage != null) {
                                            return Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.error_outline,
                                                    size: 48,
                                                    color: Colors.red.shade300,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    customerViewModel.errorMessage!,
                                                    style: const TextStyle(fontSize: 16),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  ElevatedButton(
                                                    onPressed: () => customerViewModel.getCustomers(
                                                      userToken: widget.userToken,
                                                      compID: widget.compID,
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Color(AppConstants.primaryColorValue),
                                                    ),
                                                    child: const Text('Yeniden Dene'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                          
                                          if (!customerViewModel.hasCustomers) {
                                            return Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.person_search,
                                                    size: 64,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                  const SizedBox(height: 24),
                                                  const Text(
                                                    'Müşteri bulunamadı',
                                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  const Text(
                                                    'Aradığınız kriterlere uygun müşteri bulunmuyor. Yeni müşteri eklemek için "Yeni Müşteri" sekmesine geçebilirsiniz.',
                                                    style: TextStyle(fontSize: 14, color: Colors.grey),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 24),
                                                  ElevatedButton.icon(
                                                    icon: const Icon(Icons.person_add, color: Colors.white),
                                                    label: const Text('Yeni Müşteri Ekle', style: TextStyle(color: Colors.white)),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Color(AppConstants.primaryColorValue),
                                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                                    ),
                                                    onPressed: () {
                                                      final tabController = DefaultTabController.of(builderContext);
                                                      tabController.animateTo(1);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                          
                                          return Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: ListView.separated(
                                              itemCount: customerViewModel.customers.length,
                                              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade300),
                                              itemBuilder: (context, index) {
                                                final customer = customerViewModel.customers[index];
                                                final bool isSelected = _selectedCustomer != null && _selectedCustomer!.custID == customer.custID;
                                                
                                                return Material(
                                                  color: isSelected ? Color(AppConstants.primaryColorValue).withOpacity(0.1) : Colors.white,
                                                  child: InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        _selectedCustomer = customer;
                                                      });
                                                      outerSetState(() {
                                                        _selectedCustomer = customer;
                                                      });
                                                    },
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(12),
                                                      child: Row(
                                                        children: [
                                                          CircleAvatar(
                                                            backgroundColor: isSelected 
                                                                ? Color(AppConstants.primaryColorValue) 
                                                                : Color(AppConstants.customerCardColor).withOpacity(0.2),
                                                            child: Icon(
                                                              Icons.person,
                                                              color: isSelected 
                                                                  ? Colors.white 
                                                                  : Color(AppConstants.customerCardColor),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 16),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  customer.custName,
                                                                  style: TextStyle(
                                                                    fontWeight: FontWeight.bold, 
                                                                    fontSize: 16,
                                                                    color: isSelected ? Color(AppConstants.primaryColorValue) : Colors.black,
                                                                  ),
                                                                ),
                                                                const SizedBox(height: 4),
                                                                Row(
                                                                  children: [
                                                                    Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                                                                    const SizedBox(width: 4),
                                                                    Text(
                                                                      customer.custPhone,
                                                                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                                                                    ),
                                                                  ],
                                                                ),
                                                                if (customer.custEmail.isNotEmpty) ...[
                                                                  const SizedBox(height: 4),
                                                                  Row(
                                                                    children: [
                                                                      Icon(Icons.email, size: 14, color: Colors.grey.shade600),
                                                                      const SizedBox(width: 4),
                                                                      Text(
                                                                        customer.custEmail,
                                                                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ],
                                                            ),
                                                          ),
                                                          Icon(
                                                            isSelected ? Icons.check_circle : Icons.arrow_forward_ios,
                                                            color: isSelected ? Color(AppConstants.primaryColorValue) : Colors.grey,
                                                            size: isSelected ? 24 : 16,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // Yeni müşteri ekleme tab içeriği
                                Form(
                                  key: formKey,
                                  child: SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Müşteri adı
                                          TextFormField(
                                            decoration: const InputDecoration(
                                              labelText: 'Müşteri Adı *',
                                              hintText: 'Müşteri adını giriniz',
                                              border: OutlineInputBorder(),
                                              prefixIcon: Icon(Icons.person),
                                            ),
                                            validator: (value) {
                                              if (value == null || value.trim().isEmpty) {
                                                return 'Müşteri adı boş olamaz';
                                              }
                                              return null;
                                            },
                                            onChanged: (value) {
                                              newCustomerName = value.trim();
                                            },
                                          ),
                                          
                                          const SizedBox(height: 16),
                                          
                                          // Telefon numarası
                                          TextFormField(
                                            decoration: InputDecoration(
                                              labelText: 'Telefon Numarası *',
                                              hintText: '05XXXXXXXXX',
                                              border: const OutlineInputBorder(),
                                              prefixIcon: const Icon(Icons.phone),
                                              errorText: isPhoneValid ? null : 'Geçerli bir telefon numarası giriniz (05XXXXXXXXX)',
                                            ),
                                            keyboardType: TextInputType.phone,
                                            validator: (value) {
                                              if (value == null || value.trim().isEmpty) {
                                                return 'Telefon numarası boş olamaz';
                                              }
                                              
                                              // Telefon numarası kontrolü (05XXXXXXXXX formatında)
                                              final RegExp phoneRegex = RegExp(r'^0[5][0-9]{9}$');
                                              if (!phoneRegex.hasMatch(value.trim())) {
                                                return 'Geçerli bir telefon numarası giriniz (05XXXXXXXXX)';
                                              }
                                              
                                              return null;
                                            },
                                            onChanged: (value) {
                                              final String phone = value.trim();
                                              newCustomerPhone = phone;
                                              
                                              // Telefon formatını anlık kontrol et
                                              final RegExp phoneRegex = RegExp(r'^0[5][0-9]{9}$');
                                              setState(() {
                                                isPhoneValid = phone.isEmpty || phoneRegex.hasMatch(phone);
                                              });
                                            },
                                          ),
                                          
                                          const SizedBox(height: 16),
                                          
                                          // E-posta adresi (opsiyonel)
                                          TextFormField(
                                            decoration: const InputDecoration(
                                              labelText: 'E-posta Adresi (Opsiyonel)',
                                              hintText: 'ornek@email.com',
                                              border: OutlineInputBorder(),
                                              prefixIcon: Icon(Icons.email),
                                            ),
                                            keyboardType: TextInputType.emailAddress,
                                            validator: (value) {
                                              if (value != null && value.trim().isNotEmpty) {
                                                // E-posta formatı kontrolü
                                                final RegExp emailRegex = RegExp(
                                                  r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
                                                );
                                                if (!emailRegex.hasMatch(value.trim())) {
                                                  return 'Geçerli bir e-posta adresi giriniz';
                                                }
                                              }
                                              return null;
                                            },
                                            onChanged: (value) {
                                              newCustomerEmail = value.trim();
                                            },
                                          ),
                                          
                                          // Adres ekle butonu
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            child: Row(
                                              children: [
                                                const Text(
                                                  'Adres Bilgileri',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                TextButton.icon(
                                                  icon: Icon(
                                                    showAddressForm ? Icons.remove_circle : Icons.add_circle,
                                                    color: Color(AppConstants.primaryColorValue),
                                                  ),
                                                  label: Text(
                                                    showAddressForm ? 'Adres İptal' : 'Adres Ekle',
                                                    style: TextStyle(color: Color(AppConstants.primaryColorValue)),
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      showAddressForm = !showAddressForm;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          // Adres formu (göster/gizle)
                                          if (showAddressForm) ...[
                                            const Divider(),
                                            
                                            // Adres başlığı
                                            TextFormField(
                                              decoration: const InputDecoration(
                                                labelText: 'Adres Başlığı *',
                                                hintText: 'Ev, İş vb.',
                                                border: OutlineInputBorder(),
                                                prefixIcon: Icon(Icons.label),
                                              ),
                                              validator: (value) {
                                                if (showAddressForm && (value == null || value.trim().isEmpty)) {
                                                  return 'Adres başlığı boş olamaz';
                                                }
                                                return null;
                                              },
                                              onChanged: (value) {
                                                addrTitle = value.trim();
                                              },
                                            ),
                                            
                                            const SizedBox(height: 16),
                                            
                                            // Adres
                                            TextFormField(
                                              decoration: const InputDecoration(
                                                labelText: 'Adres *',
                                                hintText: 'Adres bilgilerini giriniz',
                                                border: OutlineInputBorder(),
                                                prefixIcon: Icon(Icons.location_on),
                                              ),
                                              maxLines: 3,
                                              validator: (value) {
                                                if (showAddressForm && (value == null || value.trim().isEmpty)) {
                                                  return 'Adres boş olamaz';
                                                }
                                                return null;
                                              },
                                              onChanged: (value) {
                                                addrAddress = value.trim();
                                              },
                                            ),
                                            
                                            const SizedBox(height: 16),
                                            
                                            // Adres notu
                                            TextFormField(
                                              decoration: const InputDecoration(
                                                labelText: 'Adres Notu (Opsiyonel)',
                                                hintText: 'Kapı no, kat, daire vb.',
                                                border: OutlineInputBorder(),
                                                prefixIcon: Icon(Icons.note),
                                              ),
                                              maxLines: 2,
                                              onChanged: (value) {
                                                addrNote = value.trim();
                                              },
                                            ),
                                            
                                            const SizedBox(height: 16),
                                            
                                            // Varsayılan adres
                                            CheckboxListTile(
                                              title: const Text('Varsayılan adres olarak kaydet'),
                                              value: isDefaultAddress,
                                              contentPadding: EdgeInsets.zero,
                                              controlAffinity: ListTileControlAffinity.leading,
                                              activeColor: Color(AppConstants.primaryColorValue),
                                              onChanged: (value) {
                                                setState(() {
                                                  isDefaultAddress = value ?? true;
                                                });
                                              },
                                            ),
                                          ],
                                          
                                          // Kaydet butonu için boşluk
                                          const SizedBox(height: 16),
                                          
                                          // API'den gelen cevabı göster
                                          if (customerViewModel.isLoading)
                                            const Center(
                                              child: Padding(
                                                padding: EdgeInsets.all(16.0),
                                                child: CircularProgressIndicator(),
                                              ),
                                            ),
                                          
                                          if (customerViewModel.errorMessage != null)
                                            Container(
                                              margin: const EdgeInsets.only(bottom: 16),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.red.shade300),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.error_outline, color: Colors.red.shade700),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      customerViewModel.errorMessage!,
                                                      style: TextStyle(color: Colors.red.shade700),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Alt butonlar
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('İptal'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {
                                  // Aktif tab'ı kontrol et
                                  debugPrint('🔄 Kaydet butonuna basıldı. Aktif tab: $activeTabIndex');
                                  
                                  if (activeTabIndex == 0) {
                                    // Müşteri seçme tab'ı
                                    Navigator.of(context).pop();
                                    if (_selectedCustomer != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${_selectedCustomer!.custName} müşterisi seçildi'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } else if (activeTabIndex == 1) {
                                    // Yeni müşteri ekleme tab'ı
                                    debugPrint('🔄 Yeni müşteri ekleme tab\'ı. Form doğrulanacak.');
                                    
                                    if (formKey.currentState != null && formKey.currentState!.validate()) {
                                      debugPrint('🔄 Form doğrulandı. Adres bilgileri oluşturuluyor.');
                                      
                                      // Adres bilgilerini oluştur (eğer eklenecekse)
                                      if (showAddressForm && addrTitle.isNotEmpty && addrAddress.isNotEmpty) {
                                        orderAddresses = [
                                          order_model.CustomerAddress(
                                            adrTitle: addrTitle,
                                            adrAdress: addrAddress,
                                            adrNote: addrNote,
                                            isDefault: isDefaultAddress,
                                          )
                                        ];
                                      } else {
                                        orderAddresses = [];
                                      }
                                      
                                      debugPrint('🔄 Adres bilgileri oluşturuldu. Müşteri ekleme işlemi başlatılıyor.');
                                      debugPrint('🔄 Müşteri Adı: $newCustomerName, Telefon: $newCustomerPhone');
                                      
                                      // Yeni müşteri oluştur ve API'ye gönder
                                      setState(() {
                                        // Yükleniyor göster
                                      });
                                      
                                      // API'ye müşteri ekleme isteği gönder
                                      customerViewModel.addCustomer(
                                        userToken: widget.userToken,
                                        compID: widget.compID,
                                        custName: newCustomerName,
                                        custPhone: newCustomerPhone,
                                        addresses: orderAddresses,
                                      ).then((success) {
                                        debugPrint('🔄 Müşteri ekleme sonucu: $success');
                                        
                                        if (success) {
                                          // Müşteri başarıyla eklenirse
                                          final newCustomer = customerViewModel.selectedCustomer;
                                          debugPrint('🔄 Müşteri başarıyla eklendi: ${newCustomer?.custName}');
                                          
                                          // Müşteri seçili olarak ayarla
                                          setState(() {
                                            _selectedCustomer = newCustomer;
                                          });
                                          outerSetState(() {
                                            _selectedCustomer = newCustomer;
                                            
                                            // Ayrıca adres bilgilerini de kaydet (sipariş oluşturma sırasında kullanılacak)
                                            _selectedCustomerAddresses = orderAddresses;
                                          });
                                          
                                          Navigator.of(context).pop();
                                          
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('${newCustomerName} müşterisi başarıyla eklendi'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } else {
                                          // Form içinde hata gösteriliyor, pencereyi kapatma
                                          debugPrint('🔴 Müşteri eklenirken hata oluştu: ${customerViewModel.errorMessage}');
                                          setState(() {}); // UI'ı yenile
                                        }
                                      }).catchError((error) {
                                        debugPrint('🔴 Müşteri ekleme hatası: $error');
                                        setState(() {}); // UI'ı yenile
                                      });
                                    } else {
                                      debugPrint('🔴 Form doğrulanamadı!');
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(AppConstants.primaryColorValue),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: const Text(
                                  'Kaydet',
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
              ),
            ),
          );
        }
      ),
    );
  }

  // Sipariş iptali için onay diyaloğu
  void _showCancelOrderDialog() {
    final TextEditingController cancelDescController = TextEditingController();
    
    // Sipariş ID kontrolü
    if (widget.orderID == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İptal edilecek aktif bir sipariş bulunmuyor.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Masayı Kapat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bu işlem mevcut siparişi iptal edecek ve masayı kapatacaktır. Devam etmek istiyor musunuz?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cancelDescController,
              decoration: const InputDecoration(
                hintText: 'İptal nedeni (opsiyonel)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelOrder(cancelDescController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Masayı Kapat', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _cancelOrder(String cancelDesc) async {
    if (widget.orderID == null) {
      return;
    }
    
    if (mounted) {
      setState(() => _isInitialized = false); // Yükleniyor durumunu göster
    }
    
    try {
      final tablesViewModel = Provider.of<TablesViewModel>(context, listen: false);
      
      // Sipariş iptal işlemini gerçekleştir
      final bool success = await tablesViewModel.cancelOrder(
        userToken: widget.userToken,
        compID: widget.compID,
        orderID: widget.orderID!,
        cancelDesc: cancelDesc,
      );
      
      if (mounted) {
        setState(() => _isInitialized = true);
      
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sipariş başarıyla iptal edildi ve masa kapatıldı.'),
              backgroundColor: Colors.green,
            ),
          );
          // Ana sayfaya geri dön
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sipariş iptal edilemedi: ${tablesViewModel.errorMessage ?? "Bilinmeyen hata"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitialized = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sipariş iptal edilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Kuver durumunu değiştirme fonksiyonu
  void _toggleKuverDurumu() {
    setState(() {
      _isKuver = _isKuver == 0 ? 1 : 0;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isKuver == 1 ? 'Kuver ücreti eklendi' : 'Kuver ücreti kaldırıldı'),
        backgroundColor: _isKuver == 1 ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  // Garsoniye durumunu değiştirme fonksiyonu
  void _toggleGarsoniyeDurumu() {
    setState(() {
      _isWaiter = _isWaiter == 0 ? 1 : 0;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isWaiter == 1 ? 'Garsoniye ücreti eklendi' : 'Garsoniye ücreti kaldırıldı'),
        backgroundColor: _isWaiter == 1 ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}