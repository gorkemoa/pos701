import 'package:flutter/material.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/models/user_model.dart';
import 'package:pos701/models/basket_model.dart';
import 'package:pos701/viewmodels/tables_viewmodel.dart';
import 'package:pos701/viewmodels/basket_viewmodel.dart';
import 'package:pos701/viewmodels/user_viewmodel.dart';
import 'package:provider/provider.dart';

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
  Map<int, bool> _selectedItems = {};
  Map<int, bool> _paidItems = {};
  String _amountStr = "0";
  int _selectedAction = 0;
  int _selectedDiscountType = 0;
  double _discountAmount = 0;
  bool _applyDiscount = false;
  bool _showPaymentTypeSelection = false;
  
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

  @override
  void initState() {
    super.initState();
    _amountStr = widget.totalAmount.toStringAsFixed(2);
    
    // Varsayılan olarak tüm ürünleri seçili yap
    for (var item in widget.basketItems) {
      _selectedItems[item.product.proID] = false;
    }
    
    // Kullanıcı bilgilerini yükle (ödeme tipleri için)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadUserInfo();
    });
  }
  
  // Kullanıcı bilgilerini kontrol et ve gerekirse yükle
  Future<void> _checkAndLoadUserInfo() async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    
    // Kullanıcı bilgileri veya ödeme tipleri yoksa yeniden yükle
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
      if (_selectedItems[item.product.proID] == true) {
        total += item.totalPrice;
      }
    }
    
    return total;
  }

  void _addNumber(String num) {
    if (_amountStr == "0") {
      setState(() {
        _amountStr = num;
      });
    } else {
      setState(() {
        _amountStr = _amountStr + num;
      });
    }
  }

  void _removeLastNumber() {
    if (_amountStr.length > 1) {
      setState(() {
        _amountStr = _amountStr.substring(0, _amountStr.length - 1);
      });
    } else {
      setState(() {
        _amountStr = "0";
      });
    }
  }
  
  void _showPaymentTypesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final userViewModel = Provider.of<UserViewModel>(context, listen: false);
        
        // Kullanıcı bilgisi durumunu kontrol et ve hata mesajlarını iyileştir
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
                  // Kullanıcı bilgilerini yeniden yükle
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kullanıcı bilgileri yenileniyor...'))
                  );
                  await userViewModel.loadUserInfo();
                  _showPaymentTypesDialog(); // Diyalogu tekrar göster
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
        Navigator.of(context).pop(); // Ödeme ekranını kapat
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
    
    // Seçili ürün kontrolü
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
      List<BasketItem> paidItems = []; // Ödenen ürünleri toplayacağız
      
      // Her seçili ürün için ödeme işlemi yap
      for (var item in widget.basketItems) {
        if (_selectedItems[item.product.proID] == true) {
          // opID geçerliliğini kontrol et
          if (item.opID <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.product.proName} için geçerli bir adisyon kalemi ID bulunamadı.'),
                backgroundColor: Colors.orange,
              ),
            );
            continue; // Bu ürünü atla, diğerlerine devam et
          }
          
          debugPrint('🔄 Parçalı ödeme işleniyor: Ürün=${item.product.proName}, opID=${item.opID}, Miktar=${item.quantity}');
          
          final bool success = await tablesViewModel.partPay(
            userToken: widget.userToken,
            compID: widget.compID,
            orderID: widget.orderID,
            opID: item.opID,
            opQty: item.quantity,
            payType: _selectedPaymentType!.typeID,
          );
          
          if (success) {
            successCount++;
            paidItems.add(item); // Başarıyla ödenen ürünü kaydet
            _paidItems[item.product.proID] = true; // Ödendi olarak işaretle
            debugPrint('✅ Parçalı ödeme başarılı: Ürün=${item.product.proName}, opID=${item.opID}');
          } else {
            allSuccess = false;
            debugPrint('❌ Parçalı ödeme başarısız: Ürün=${item.product.proName}, opID=${item.opID}, Hata=${tablesViewModel.errorMessage}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.product.proName} için ödeme alınamadı: ${tablesViewModel.errorMessage}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
      
      setState(() => _isLoading = false);
      
      if (successCount > 0) {
        // Ödenen ürünleri callback üzerinden ana sayfaya bildir
        // Bu ürünler burada listeden çıkarılmaz, basket_view'da çıkarılır
        widget.onPaymentSuccess();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedPaymentType!.typeName} ile $successCount ürün için ödeme başarıyla alındı.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Tüm ürünler ödendiyse sayfayı kapat
        bool allItemsPaid = true;
        for (var item in widget.basketItems) {
          if (_paidItems[item.product.proID] != true) {
            allItemsPaid = false;
            break;
          }
        }
        
        if (allItemsPaid) {
          Navigator.of(context).pop();
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
        // Ürün listesi
        Expanded(
          child: ListView.separated(
            itemCount: widget.basketItems.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = widget.basketItems[index];
              final isSelected = _selectedItems[item.product.proID] ?? false;
              final isPaid = _paidItems[item.product.proID] ?? false;
              
              // opID kontrolü - 0 ise ödeme için uygun değil
              final bool hasValidOpId = item.opID > 0;
              final bool canSelect = hasValidOpId && !isPaid; // Ödenmediyse ve geçerli opID varsa seçilebilir
              
              return ListTile(
                leading: Checkbox(
                  value: isSelected,
                  onChanged: canSelect ? (value) {
                    setState(() {
                      _selectedItems[item.product.proID] = value ?? false;
                    });
                  } : null, // Ödendiyse veya geçersiz opID varsa seçilemez
                  activeColor: const Color(AppConstants.primaryColorValue),
                ),
                title: Text(
                  "${item.quantity} Tam | ${item.product.proName}",
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
                  "₺${item.totalPrice.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isPaid ? Colors.grey : Colors.black,
                    decoration: isPaid ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
                onTap: canSelect ? () {
                  setState(() {
                    _selectedItems[item.product.proID] = !isSelected;
                  });
                } : isPaid ? () {
                  // Ödenen ürün için bilgi mesajı
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bu ürün için ödeme zaten alındı.'),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 1),
                    ),
                  );
                } : () {
                  // Uyarı mesajı göster
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bu ürün parçalı ödeme için uygun değil. Adisyon kalemi ID bulunamadı.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                enabled: true, // Her zaman etkin, ancak sadece seçilebilirlik durumu değişir
                tileColor: isPaid ? Colors.grey[100] : null, // Ödenen ürünler için hafif gri arkaplan
              );
            },
          ),
        ),
        
        // Alt butonlar
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
        // Toplam bilgisi
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
        
        // İndirim seçenekleri
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Switch(
                value: _applyDiscount,
                onChanged: (value) {
                  setState(() {
                    _applyDiscount = value;
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
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: "Miktar",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _discountAmount = double.tryParse(value) ?? 0;
                      });
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Ödeme aksiyon seçimi
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
        
        // Tuş takımı
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
        
        // Alt butonlar
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