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

class CategoryScreen extends StatefulWidget {
  final int compID;
  final String userToken;
  final int? tableID;
  final int? orderID;
  final String tableName;

  const CategoryScreen({
    Key? key,
    required this.compID,
    required this.userToken,
    this.tableID,
    this.orderID,
    this.tableName = "Yeni sipariş",
  }) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
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
              Text("Yeni sipariş", 
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
              onPressed: () {},
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
            
            // Alt Navigasyon Çubuğu
            Container(
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
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chevron_left, color: Colors.white),
                                  Text(
                                    'Geri',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
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
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ödeme Al',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
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
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.print, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Yazdır',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: _cartCount > 0 
                        ? Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _cartCount.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : SizedBox(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(Category category, Color categoryColor) {
    final isSelected = _selectedCategory?.catID == category.catID;
    
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
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Ürün sepete eklenecek
          setState(() {
            _cartCount++;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    product.proName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '₺${product.proPrice.replaceAll(" TL", "")}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 