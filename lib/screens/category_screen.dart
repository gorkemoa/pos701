import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos701/models/user_model.dart';
import 'package:pos701/viewmodels/user_viewmodel.dart';
import 'package:pos701/viewmodels/category_viewmodel.dart';
import 'package:pos701/models/product_category_model.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/services/product_service.dart';

class CategoryScreen extends StatefulWidget {
  final int compID;
  final String userToken;
  final int? tableID;
  final int? orderID;

  const CategoryScreen({
    Key? key,
    required this.compID,
    required this.userToken,
    this.tableID,
    this.orderID,
  }) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late CategoryViewModel _categoryViewModel;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _categoryViewModel = CategoryViewModel(ProductService());
    _loadCategories();
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _categoryViewModel,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kategoriler'),
          backgroundColor: Color(AppConstants.primaryColorValue),
        ),
        body: Consumer<CategoryViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (viewModel.errorMessage != null) {
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
                      viewModel.errorMessage!,
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

            if (!viewModel.hasCategories) {
              return const Center(
                child: Text('Kategori bulunamadı'),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: viewModel.categories.length,
              itemBuilder: (context, index) {
                final category = viewModel.categories[index];
                Color categoryColor;
                try {
                  categoryColor = Color(
                    int.parse(category.catColor.replaceFirst('#', '0xFF')),
                  );
                } catch (e) {
                  categoryColor = Colors.grey;
                }
                
                return _buildCategoryCard(category, categoryColor);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Category category, Color categoryColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Ürün listesi ekranına yönlendirme yapılacak
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                categoryColor.withOpacity(0.7),
                categoryColor,
              ],
            ),
          ),
          child: Center(
            child: Text(
              category.catName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
} 