import 'package:flutter/material.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/models/user_model.dart';
import 'package:pos701/models/basket_model.dart';
import 'package:pos701/viewmodels/tables_viewmodel.dart';
import 'package:pos701/viewmodels/basket_viewmodel.dart';
import 'package:pos701/viewmodels/user_viewmodel.dart';
import 'package:pos701/viewmodels/order_viewmodel.dart'; // Added import for OrderViewModel
import 'package:provider/provider.dart';
import 'package:pos701/views/tables_view.dart'; // Added import for TablesView

// Enum ekle
enum AmountInputTarget { total, discount }

class PaymentView extends StatefulWidget {
  final String userToken;
  final int compID;
  final int orderID;
  final double totalAmount;
  final List<BasketItem> basketItems;
  final VoidCallback onPaymentSuccess;

  const PaymentView({
    super.key,
    required this.userToken,
    required this.compID,
    required this.orderID,
    required this.totalAmount,
    required this.basketItems,
    required this.onPaymentSuccess,
  });

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  bool _isLoading = false;
  bool _isPartialPayment = false;
  PaymentType? _selectedPaymentType;
  Map<String, bool> _selectedItems = {};
  Map<String, bool> _paidItems = {};
  String _amountStr = "0";
  int _selectedAction = 0;
  int _selectedDiscountType = 0;
  double _discountAmount = 0;
  bool _applyDiscount = false;
  bool _showPaymentTypeSelection = false;
  
  List<ExpandedBasketItem> _expandedItems = [];
  
  late final TextEditingController _discountAmountController;
  
  final List<String> _payActions = [
    "pay", // Öde
    "payClose", // Öde & Kapat
    "payPrint", // Öde & Yazdır
    "payPrintClose", // Öde & Yazdır & Kapat
  ];
  
  final List<String> _payActionLabels = [
    "Öde",
    "Öde & Kapat",
    "Öde & Yazdır",
    "Öde & Yazdır & Kapat",
  ];

  AmountInputTarget _inputTarget = AmountInputTarget.total;

  @override
  void initState() {
    super.initState();
    _discountAmountController = TextEditingController();
    _amountStr = widget.totalAmount.toStringAsFixed(2);
    
    _expandBasketItems();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadUserInfo();
    });
  }

  @override
  void dispose() {
    _discountAmountController.dispose();
    super.dispose();
  }
  
  void _expandBasketItems() {
    _expandedItems = [];
    
    for (var item in widget.basketItems) {
      for (int i = 0; i < item.proQty; i++) {
        final String key = "${item.product.proID}-${item.opID}-$i";
        
        _expandedItems.add(ExpandedBasketItem(
          basketItem: item,
          unitIndex: i,
          key: key,
        ));
        
        _selectedItems[key] = false;
        _paidItems[key] = false;
      }
    }
    
    debugPrint('📦 Sepet öğeleri genişletildi. Toplam: ${_expandedItems.length} birim');
  }
  
  Future<void> _checkAndLoadUserInfo() async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    
    if (userViewModel.userInfo == null || 
        userViewModel.userInfo!.company == null || 
        userViewModel.userInfo!.company!.compPayTypes.isEmpty) {
      await userViewModel.loadUserInfo();
    }
  }

  double get amount => double.tryParse(_amountStr) ?? 0.0;
  
  double get selectedItemsTotal {
    double total = 0;
    
    if (!_isPartialPayment) {
      return widget.totalAmount;
    }
    
    for (var item in widget.basketItems) {
      if (_selectedItems[item.opID] == true) {
        total += item.totalPrice;
      }
    }
    
    return total;
  }

  void _addNumber(String num) {
    setState(() {
      // Sadece indirim kutusu odaktayken numpad çalışsın
      if (_inputTarget == AmountInputTarget.discount) {
        String current = _discountAmountController.text;
        if (current == "0") {
          _discountAmountController.text = num;
        } else {
          _discountAmountController.text = current + num;
        }
        _discountAmount = double.tryParse(_discountAmountController.text) ?? 0;
      }
    });
  }

  void _removeLastNumber() {
    setState(() {
      // Sadece indirim kutusu odaktayken numpad çalışsın
      if (_inputTarget == AmountInputTarget.discount) {
        String current = _discountAmountController.text;
        if (current.length > 1) {
          _discountAmountController.text = current.substring(0, current.length - 1);
        } else {
          _discountAmountController.text = "0";
        }
        _discountAmount = double.tryParse(_discountAmountController.text) ?? 0;
      }
    });
  }
  
  void _showPaymentTypesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final userViewModel = Provider.of<UserViewModel>(context, listen: false);
        
        if (userViewModel.userInfo == null) {
          return AlertDialog(
            title: const Text('Hata'),
            content: const Text('Kullanıcı bilgileri yüklenemedi. Lütfen tekrar giriş yapın.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tamam'),
              ),
            ],
          );
        }
        
        if (userViewModel.userInfo!.company == null) {
          return AlertDialog(
            title: const Text('Hata'),
            content: const Text('Şirket bilgileri bulunamadı. Lütfen yöneticinizle iletişime geçin.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tamam'),
              ),
            ],
          );
        }
        
        if (userViewModel.userInfo!.company!.compPayTypes.isEmpty) {
          return AlertDialog(
            title: const Text('Hata'),
            content: const Text('Ödeme tipleri bulunamadı. Lütfen yönetici panelinizden ödeme tiplerini tanımlayın.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tamam'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kullanıcı bilgileri yenileniyor...'))
                  );
                  await userViewModel.loadUserInfo();
                  _showPaymentTypesDialog();
                },
                child: const Text('Yenile'),
              ),
            ],
          );
        }
        
        final List<PaymentType> paymentTypes = userViewModel.userInfo!.company!.compPayTypes;
        
        return AlertDialog(
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
                    setState(() {
                      _selectedPaymentType = paymentType;
                    });
                    Navigator.of(context).pop();
                    
                    if (_isPartialPayment) {
                      _processPartialPayment();
                    } else {
                      _processFullPayment();
                    }
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
        );
      },
    );
  }

  void _processFullPayment() async {
    if (_isLoading || _selectedPaymentType == null) return;
    if (_applyDiscount && _selectedDiscountType == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir indirim tipi seçin.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final tablesViewModel = Provider.of<TablesViewModel>(context, listen: false);
      
      final bool success = await tablesViewModel.fastPay(
        userToken: widget.userToken,
        compID: widget.compID,
        orderID: widget.orderID,
        isDiscount: _applyDiscount ? 1 : 0,
        discountType: _selectedDiscountType,
        discount: _discountAmount.toInt(),
        payType: _selectedPaymentType!.typeID,
        payAction: _payActions[_selectedAction],
      );
      
      setState(() => _isLoading = false);
      
      if (success) {
        widget.onPaymentSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedPaymentType!.typeName} ile ödeme başarıyla alındı.'),
            backgroundColor: Colors.green,
          ),
        );
        // Tam ödeme başarılıysa TablesView'a yönlendir
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => TablesView(
              userToken: widget.userToken,
              compID: widget.compID,
              title: 'Masalar',
            ),
          ),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ödeme işlemi başarısız: ${tablesViewModel.errorMessage ?? "Bilinmeyen hata"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ödeme işlemi sırasında hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _processPartialPayment() async {
    if (_isLoading || _selectedPaymentType == null) return;
    if (_applyDiscount && _selectedDiscountType == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir indirim tipi seçin.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    bool anySelected = _selectedItems.values.any((selected) => selected);
    if (!anySelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen ödeme yapılacak en az bir ürün seçin.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final tablesViewModel = Provider.of<TablesViewModel>(context, listen: false);
      bool allSuccess = true;
      int successCount = 0;
      List<String> successKeys = [];
      
      for (var expandedItem in _expandedItems) {
        if (_selectedItems[expandedItem.key] == true) {
          final item = expandedItem.basketItem;
          
          if (item.opID <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.product.proName} için geçerli bir adisyon kalemi ID bulunamadı.'),
                backgroundColor: Colors.orange,
              ),
            );
            continue;
          }
          
          debugPrint('🔄 Parçalı ödeme işleniyor: Ürün=${item.product.proName}, opID=${item.opID}, Birim=${expandedItem.unitIndex + 1}');
          
          final bool success = await tablesViewModel.partPay(
            userToken: widget.userToken,
            compID: widget.compID,
            orderID: widget.orderID,
            opID: item.opID,
            opQty: 1,
            payType: _selectedPaymentType!.typeID,
          );
          
          if (success) {
            successCount++;
            successKeys.add(expandedItem.key);
            _paidItems[expandedItem.key] = true;
            _selectedItems[expandedItem.key] = false;
            debugPrint('✅ Parçalı ödeme başarılı: Ürün= {item.product.proName}, opID=${item.opID}, Birim=${expandedItem.unitIndex + 1}');
          } else {
            allSuccess = false;
            debugPrint('❌ Parçalı ödeme başarısız: Ürün=${item.product.proName}, opID=${item.opID}, Birim=${expandedItem.unitIndex + 1}, Hata=${tablesViewModel.errorMessage}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.product.proName} (Birim ${expandedItem.unitIndex + 1}) için ödeme alınamadı: ${tablesViewModel.errorMessage}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
      
      setState(() => _isLoading = false);
      
      if (successCount > 0) {
        widget.onPaymentSuccess();
        
        // Parçalı ödeme sonrası sipariş detayını güncelle
        final orderViewModel = Provider.of<OrderViewModel>(context, listen: false);
        final bool detailSuccess = await orderViewModel.getSiparisDetayi(
          userToken: widget.userToken,
          compID: widget.compID,
          orderID: widget.orderID,
        );
        if (detailSuccess && orderViewModel.orderDetail != null) {
          // Sepeti güncelle
          setState(() {
            widget.basketItems.clear();
            widget.basketItems.addAll(orderViewModel.siparisUrunleriniSepeteAktar());
            _expandBasketItems();
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedPaymentType!.typeName} ile $successCount ürün birimi için ödeme başarıyla alındı.'),
            backgroundColor: Colors.green,
          ),
        );
        
        bool allItemsPaid = _expandedItems.every((item) => _paidItems[item.key] == true);
        
        if (allItemsPaid) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => TablesView(
                userToken: widget.userToken,
                compID: widget.compID,
                title: 'Masalar',
              ),
            ),
            (route) => false,
          );
        }
      } else if (allSuccess == false) {
        // Hiçbir başarılı işlem yoksa ve en az bir hata varsa
        // Not: Mesajlar zaten yukarıda gösterildi
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hiçbir ürün için ödeme yapılamadı.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('🔴 Parçalı ödeme genel hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ödeme işlemi sırasında hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isPartialPayment ? "Parçalı Öde" : "Ödeme Al"),
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isPartialPayment = !_isPartialPayment;
              });
            },
            child: Text(
              _isPartialPayment ? "Tam Öde" : "Parçalı Öde",
              style: const TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isPartialPayment
              ? _buildPartialPaymentView()
              : _buildFullPaymentView(),
    );
  }
  
  Widget _buildPartialPaymentView() {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: _expandedItems.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final expandedItem = _expandedItems[index];
              final item = expandedItem.basketItem;
              final isSelected = _selectedItems[expandedItem.key] ?? false;
              final isPaid = _paidItems[expandedItem.key] ?? false;
              
              final bool hasValidOpId = item.opID > 0;
              final bool canSelect = hasValidOpId && !isPaid;
              
              final double unitPrice = item.totalPrice / item.proQty;
              
              return ListTile(
                leading: Checkbox(
                  value: isSelected,
                  onChanged: canSelect ? (value) {
                    setState(() {
                      _selectedItems[expandedItem.key] = value ?? false;
                    });
                  } : null,
                  activeColor: const Color(AppConstants.primaryColorValue),
                ),
                title: Text(
                  "1 Tam | ${item.product.proName}",
                  style: TextStyle(
                    fontWeight: isPaid ? FontWeight.normal : FontWeight.bold,
                    color: isPaid ? Colors.grey : Colors.black,
                    decoration: isPaid ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
                subtitle: isPaid
                    ? Text("Ödendi", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold))
                    : hasValidOpId 
                      ? Text("Adisyon Kalemi ID: ${item.opID}", style: TextStyle(fontSize: 12, color: Colors.green[700]))
                      : Text("Ödeme yapılamaz: Adisyon Kalemi ID bulunamadı", style: TextStyle(fontSize: 12, color: Colors.red[700])),
                trailing: Text(
                  "₺${unitPrice.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isPaid ? Colors.grey : Colors.black,
                    decoration: isPaid ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
                onTap: canSelect ? () {
                  setState(() {
                    _selectedItems[expandedItem.key] = !isSelected;
                  });
                } : isPaid ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bu ürün için ödeme zaten alındı.'),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 1),
                    ),
                  );
                } : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bu ürün parçalı ödeme için uygun değil. Adisyon kalemi ID bulunamadı.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                enabled: true,
                tileColor: isPaid ? Colors.grey[100] : null,
              );
            },
          ),
        ),
        
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "İptal",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showPaymentTypesDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE52C2C),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Ödeme Yap",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFullPaymentView() {
    return Column(
      children: [
        Container(
          color: Colors.grey[200],
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Toplam :",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "₺$_amountStr",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Switch(
                value: _applyDiscount,
                onChanged: (value) {
                  setState(() {
                    _applyDiscount = value;
                    if (!value) {
                      _discountAmountController.clear();
                      _discountAmount = 0;
                      _selectedDiscountType = 0;
                      _inputTarget = AmountInputTarget.total;
                    }
                  });
                },
                activeColor: Color(AppConstants.primaryColorValue),
              ),
              const Text("İndirim Uygula"),
              const SizedBox(width: 16),
              if (_applyDiscount) ...[
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedDiscountType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text("İndirim Tipi Seçin")),
                      DropdownMenuItem(value: 1, child: Text("Tutar")),
                      DropdownMenuItem(value: 2, child: Text("Yüzde")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDiscountType = value ?? 0;
                        _discountAmountController.clear();
                        _discountAmount = 0;
                        _inputTarget = AmountInputTarget.discount;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    readOnly: true,
                    controller: _discountAmountController,
                    onTap: () {
                      setState(() {
                        _inputTarget = AmountInputTarget.discount;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: "Miktar",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              labelText: "Ödeme Aksiyonu",
              border: OutlineInputBorder(),
            ),
            value: _selectedAction,
            items: List.generate(
              _payActionLabels.length,
              (index) => DropdownMenuItem(
                value: index,
                child: Text(_payActionLabels[index]),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _selectedAction = value ?? 0;
              });
            },
          ),
        ),
        
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildNumberButton("7"),
                      _buildNumberButton("8"),
                      _buildNumberButton("9"),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      _buildNumberButton("4"),
                      _buildNumberButton("5"),
                      _buildNumberButton("6"),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      _buildNumberButton("1"),
                      _buildNumberButton("2"),
                      _buildNumberButton("3"),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      _buildNumberButton("0"),
                      _buildNumberButton("."),
                      _buildNumberButton("⌫", onTap: _removeLastNumber),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "İptal",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showPaymentTypesDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE52C2C),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Ödeme Yap",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumberButton(String number, {VoidCallback? onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          onPressed: onTap ?? () => _addNumber(number),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Text(
            number,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}

class ExpandedBasketItem {
  final BasketItem basketItem;
  final int unitIndex;
  final String key;
  
  ExpandedBasketItem({
    required this.basketItem,
    required this.unitIndex,
    required this.key,
  });
} 