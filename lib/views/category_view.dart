import 'package:flutter/material.dart';
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

class CategoryView extends StatefulWidget {
  final int compID;
  final String userToken;
  final int? tableID;
  final int? orderID;
  final String tableName;

  const CategoryView({
    Key? key,
    required this.compID,
    required this.userToken,
    this.tableID,
    this.orderID,
    required this.tableName,
  }) : super(key: key);

  @override
  State<CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  late CategoryViewModel _categoryViewModel;
  late ProductViewModel _productViewModel;
  bool _isInitialized = false;
  final TextEditingController _searchController = TextEditingController();
  Category? _selectedCategory;
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _categoryViewModel = CategoryViewModel(ProductService());
    _productViewModel = ProductViewModel(ProductService());
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
  }
  
  Future<void> _loadProducts(int catID, String categoryName) async {
    _productViewModel.setCategoryInfo(catID, categoryName);
    final success = await _productViewModel.loadProductsOfCategory(
      widget.userToken,
      widget.compID,
      catID,
    );
  }

  @override
  Widget build(BuildContext context) {
    final basketViewModel = Provider.of<BasketViewModel>(context);
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _categoryViewModel),
        ChangeNotifierProvider.value(value: _productViewModel),
      ],
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(AppConstants.primaryColorValue),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.tableName.toUpperCase(), 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(widget.orderID != null ? "Sipariş Düzenle" : "Yeni sipariş", 
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          leading: IconButton(
            icon: Icon(Icons.chevron_left, size: 30),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                _showMenuDialog();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Arama Çubuğu
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Ürün arayın...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 0),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            
            // İçerik
            Expanded(
              child: Consumer<CategoryViewModel>(
                builder: (context, categoryViewModel, child) {
                  if (categoryViewModel.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (categoryViewModel.errorMessage != null) {
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
                            categoryViewModel.errorMessage!,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadCategories,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(AppConstants.primaryColorValue),
                            ),
                            child: const Text('Yeniden Dene'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!categoryViewModel.hasCategories) {
                    return const Center(
                      child: Text('Kategori bulunamadı'),
                    );
                  }

                  return Column(
                    children: [
                      // Kategoriler Bölümü
                      Container(
                        height: MediaQuery.of(context).size.height * 0.28,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(2),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 3,
                            childAspectRatio: 2,
                          ),
                          itemCount: categoryViewModel.categories.length,
                          itemBuilder: (context, index) {
                            final category = categoryViewModel.categories[index];
                            Color categoryColor;
                            try {
                              categoryColor = Color(
                                int.parse(category.catColor.replaceFirst('#', '0xFF')),
                              );
                            } catch (e) {
                              categoryColor = Colors.grey;
                            }
                            
                            return _buildCategoryButton(category, categoryColor);
                          },
                        ),
                      ),
                      
                      // Ürünler Bölümü
                      Expanded(
                        child: Consumer<ProductViewModel>(
                          builder: (context, productViewModel, child) {
                            if (_selectedCategory == null) {
                              return Center(
                                child: Text(
                                  'Lütfen bir kategori seçin',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              );
                            }
                            
                            if (productViewModel.isLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (productViewModel.errorMessage != null) {
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
                                      productViewModel.errorMessage!,
                                      style: const TextStyle(fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () => _loadProducts(_selectedCategory!.catID, _selectedCategory!.catName),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(
                                          int.parse(_selectedCategory!.catColor.replaceFirst('#', '0xFF')),
                                        ),
                                      ),
                                      child: const Text('Yeniden Dene'),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (!productViewModel.hasProducts) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
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

                            return GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 0.8,
                              ),
                              itemCount: productViewModel.products.length,
                              itemBuilder: (context, index) {
                                final product = productViewModel.products[index];
                                return _buildProductCard(product);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _goToBasket();
          },
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
          child: Stack(
            children: [
              Row(
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
                              SizedBox(width: 4),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton(Category category, Color categoryColor) {
    
    return Card(
      margin: const EdgeInsets.all(2),
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
          child: Text(
            category.catName.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
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
      child: Column(
        children: [
          // Ürün Adı ve Fiyat Bölümü
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        product.proName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(AppConstants.primaryColorValue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '₺${product.proPrice.replaceAll(" TL", "")}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(AppConstants.primaryColorValue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Alt Kontrol Bölümü
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Eksi Butonu
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isInBasket ? () => basketViewModel.decreaseProduct(product) : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isInBasket 
                            ? Color(AppConstants.primaryColorValue).withOpacity(0.1)
                            : Colors.grey.shade200,
                      ),
                      child: Icon(
                        Icons.remove,
                        size: 16,
                        color: isInBasket 
                            ? Color(AppConstants.primaryColorValue)
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
                // Miktar
                Container(
                  constraints: BoxConstraints(minWidth: 32),
                  child: Text(
                    '$quantity',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isInBasket 
                          ? Color(AppConstants.primaryColorValue)
                          : Colors.grey.shade400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Artı Butonu
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => basketViewModel.addProduct(product, opID: 0),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(AppConstants.primaryColorValue).withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.add,
                        size: 16,
                        color: Color(AppConstants.primaryColorValue),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToBasket() async {
    debugPrint('🛒 Sepete yönlendiriliyor. TableID: ${widget.tableID}, OrderID: ${widget.orderID}, TableName: ${widget.tableName}');
    
    final Map<String, dynamic> arguments = {
      'tableID': widget.tableID,
      'tableName': widget.tableName,
    };
    
    // Eğer sipariş varsa orderID ekleyelim
    if (widget.orderID != null) {
      arguments['orderID'] = widget.orderID;
      debugPrint('🛒 Mevcut sipariş düzenleniyor. OrderID: ${widget.orderID}');
    } else {
      debugPrint('🛒 Yeni sipariş oluşturuluyor.');
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BasketView(
          tableName: widget.tableName,
          orderID: widget.orderID,
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
                        // NOT işlemi
                      },
                    ),
                    
                    const Divider(height: 1),
                    
                    _buildMenuItem(
                      icon: Icons.people,
                      title: 'Misafir Sayısı',
                      onTap: () {
                        Navigator.of(context).pop();
                        // Misafir sayısı işlemi
                      },
                    ),
                    
                    const Divider(height: 1),
                    
                    _buildMenuItem(
                      icon: Icons.person,
                      title: 'Müşteri',
                      onTap: () {
                        Navigator.of(context).pop();
                        // Müşteri işlemi
                      },
                    ),
                    
                    const Divider(height: 1),
                    
                    _buildMenuItem(
                      icon: Icons.attach_money,
                      title: 'Kuver Ücreti Ekle',
                      onTap: () {
                        Navigator.of(context).pop();
                        // Kuver ücreti işlemi
                      },
                    ),
                    
                    const Divider(height: 1),
                    
                    _buildMenuItem(
                      icon: Icons.monetization_on,
                      title: 'Garsoniye Ücreti Ekle',
                      onTap: () {
                        Navigator.of(context).pop();
                        // Garsoniye ücreti işlemi
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
                        // Masayı kapat işlemi
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
} 