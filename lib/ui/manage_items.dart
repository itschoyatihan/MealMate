import 'package:flutter/material.dart';

const expenseGreen = Color(0xFF16840C);
const expenseDarkGreen = Color(0xFF075323);

class ExpenseItem {
  const ExpenseItem({required this.name, required this.quantity, required this.unitPrice, required this.mealType});
  final String name;
  final int quantity;
  final int unitPrice;
  final String mealType;
  int get total => quantity * unitPrice;
  ExpenseItem copy() => ExpenseItem(name: name, quantity: quantity, unitPrice: unitPrice, mealType: mealType);
  factory ExpenseItem.fromJson(Map<String, dynamic> json) => ExpenseItem(
    name: json['name'].toString(),
    quantity: int.parse(json['quantity'].toString()),
    unitPrice: int.parse(json['unitPrice'].toString()),
    mealType: json['mealType'].toString(),
  );
  Map<String, dynamic> toJson() => {'name': name, 'quantity': quantity, 'unitPrice': unitPrice, 'mealType': mealType};
}

String expenseMoney(int amount) {
  final text = amount.toString();
  return '${text.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')} MMK';
}

class ManageMealItemsPage extends StatefulWidget {
  const ManageMealItemsPage({super.key, required this.mealType, required this.initialItems});
  final String mealType;
  final List<ExpenseItem> initialItems;

  @override
  State<ManageMealItemsPage> createState() => _ManageMealItemsPageState();
}

class _ManageMealItemsPageState extends State<ManageMealItemsPage> {
  late final List<ExpenseItem> _items;
  final _name = TextEditingController();
  final _price = TextEditingController();
  int _quantity = 1;
  int? _editingIndex;
  String? _error;
  bool _changed = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _items = widget.initialItems.map((e) => e.copy()).toList();
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  String get _mealLabel => '${widget.mealType[0].toUpperCase()}${widget.mealType.substring(1)}';
  int get _total => _items.fold(0, (sum, item) => sum + item.total);

  void _clearForm() {
    _name.clear();
    _price.clear();
    setState(() { _quantity = 1; _editingIndex = null; _error = null; });
  }

  void _addOrUpdate() {
    final name = _name.text.trim();
    final price = int.tryParse(_price.text.trim());
    if (name.isEmpty || name.length > 100 || price == null || price < 0 || _quantity < 1) {
      setState(() => _error = 'Enter a food name (up to 100 characters), quantity and valid unit price.');
      return;
    }
    final item = ExpenseItem(name: name, quantity: _quantity, unitPrice: price, mealType: widget.mealType);
    setState(() {
      if (_editingIndex == null) { _items.add(item); } else { _items[_editingIndex!] = item; }
      _changed = true;
    });
    _clearForm();
  }

  void _edit(int index) {
    final item = _items[index];
    _name.text = item.name;
    _price.text = item.unitPrice.toString();
    setState(() { _editingIndex = index; _quantity = item.quantity; _error = null; });
  }

  Future<bool> _confirmLeave() async {
    if (!_changed) return true;
    return await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Discard changes?'),
      content: const Text('Items changed on this page have not been saved to Expenses.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep Editing')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard'))],
    )) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 650;
    return PopScope(canPop: _allowPop, onPopInvokedWithResult: (didPop, _) async {
      if (didPop) return;
      if (await _confirmLeave() && context.mounted) { setState(() => _allowPop = true); Navigator.pop(context); }
    }, child: Scaffold(
      backgroundColor: const Color(0xFFFFFCF7),
      appBar: AppBar(backgroundColor: const Color(0xFFFFFCF7), surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: expenseGreen), onPressed: () async {
          if (await _confirmLeave() && context.mounted) { setState(() => _allowPop = true); Navigator.pop(context); }
        }), title: const Text('Manage Meal Items', style: TextStyle(fontWeight: FontWeight.w800))),
      body: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: wide ? 680 : 550), child: ListView(
        padding: EdgeInsets.symmetric(horizontal: wide ? 28 : 20, vertical: 16), children: [
          Text(_mealLabel, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 22),
          Text('Existing Items (${_items.length})', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: expenseDarkGreen)),
          const SizedBox(height: 10),
          if (_items.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No item added', style: TextStyle(color: Colors.black54))),
          for (var i = 0; i < _items.length; i++) Card(color: Colors.white, surfaceTintColor: Colors.white, margin: const EdgeInsets.only(bottom: 10), child: Padding(
            padding: const EdgeInsets.all(12), child: Row(children: [
              const Icon(Icons.restaurant, color: expenseGreen), const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_items[i].name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                Text('${_items[i].quantity} × ${expenseMoney(_items[i].unitPrice)}', style: const TextStyle(fontSize: 14)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(expenseMoney(_items[i].total), style: const TextStyle(color: expenseDarkGreen, fontWeight: FontWeight.bold)),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(tooltip: 'Edit', onPressed: () => _edit(i), icon: const Icon(Icons.edit_outlined, color: expenseGreen)),
                  IconButton(tooltip: 'Delete', onPressed: () => setState(() {
                    _items.removeAt(i); _changed = true;
                    if (_editingIndex != null) { _editingIndex = null; _name.clear(); _price.clear(); _quantity = 1; }
                  }), icon: const Icon(Icons.delete_outline, color: Colors.red)),
                ]),
              ]),
            ]),
          )),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFE8F9D9), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [Expanded(child: Text('$_mealLabel Total', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
              Text(expenseMoney(_total), style: const TextStyle(color: expenseDarkGreen, fontWeight: FontWeight.w800, fontSize: 17))])),
          const SizedBox(height: 24),
          Text(_editingIndex == null ? 'Add New Item' : 'Edit Item', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: expenseDarkGreen)),
          const SizedBox(height: 14),
          const Text('Food Name *', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(controller: _name, maxLength: 100, decoration: const InputDecoration(hintText: 'Enter food or drink name', border: OutlineInputBorder(), counterText: '')),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Quantity *', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 7),
              Container(height: 54, decoration: BoxDecoration(border: Border.all(color: Colors.black26), borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  IconButton(onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null, icon: const Icon(Icons.remove, color: expenseGreen)),
                  Text('$_quantity', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => setState(() => _quantity++), icon: const Icon(Icons.add, color: expenseGreen)),
                ])),
            ])),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Unit Price (MMK) *', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 7),
              TextField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Enter price', border: OutlineInputBorder())),
            ])),
          ]),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 20),
          OutlinedButton.icon(onPressed: _addOrUpdate, icon: Icon(_editingIndex == null ? Icons.add : Icons.check),
            label: Text(_editingIndex == null ? 'Add Item' : 'Update Item'), style: OutlinedButton.styleFrom(
              foregroundColor: expenseDarkGreen, backgroundColor: const Color(0xFFE8F9D9), minimumSize: const Size.fromHeight(52))),
          if (_editingIndex != null) TextButton(onPressed: _clearForm, child: const Text('Cancel Editing')),
          const SizedBox(height: 28),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () async {
              if (await _confirmLeave() && context.mounted) { setState(() => _allowPop = true); Navigator.pop(context); }
            }, child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton.icon(onPressed: () { setState(() => _allowPop = true); Navigator.pop(context, List<ExpenseItem>.from(_items)); },
              icon: const Icon(Icons.check), label: const Text('Done'), style: FilledButton.styleFrom(backgroundColor: expenseGreen))),
          ]),
          const SizedBox(height: 24),
        ],
      ))),
    ));
  }
}
