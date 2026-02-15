import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';

/// Screen for adding or editing a pantry item.
class AddItemScreen extends ConsumerStatefulWidget {
  final PantryItem? editItem;

  const AddItemScreen({super.key, this.editItem});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  StorageLocation _storageLocation = StorageLocation.fridge;
  String? _category;
  String? _barcode;

  // USDA data for auto-suggestions
  List<Map<String, dynamic>> _usdaSuggestions = [];
  bool _showSuggestions = false;

  // Category options
  static const List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Dairy',
    'Meat',
    'Seafood',
    'Bread & Bakery',
    'Condiments & Sauces',
    'Grains & Pasta',
    'Canned Goods',
    'Beverages',
    'Snacks',
    'Frozen',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editItem != null) {
      _nameController.text = widget.editItem!.name;
      _expiryDate = widget.editItem!.expiryDate;
      _storageLocation = widget.editItem!.storageLocation;
      _category = widget.editItem!.category;
      _barcode = widget.editItem!.barcode;
    }

    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (_nameController.text.length >= 2) {
      _searchUSDA(_nameController.text);
    } else {
      setState(() {
        _usdaSuggestions = [];
        _showSuggestions = false;
      });
    }
  }

  Future<void> _searchUSDA(String query) async {
    try {
      final data =
          await rootBundle.loadString('assets/usda_foodkeeper.json');
      final json = jsonDecode(data);
      final categories = json['categories'] as List;

      final results = <Map<String, dynamic>>[];
      for (var cat in categories) {
        final items = cat['items'] as List;
        for (var item in items) {
          if ((item['name'] as String)
              .toLowerCase()
              .contains(query.toLowerCase())) {
            results.add({
              ...item,
              'category_name': cat['name'],
            });
          }
        }
      }

      setState(() {
        _usdaSuggestions = results;
        _showSuggestions = results.isNotEmpty;
      });
    } catch (_) {
      // USDA data not available
    }
  }

  void _selectUSDAItem(Map<String, dynamic> item) {
    _nameController.text = item['name'] as String;
    _category = item['category_name'] as String;

    // Calculate expiry based on storage location
    int days;
    switch (_storageLocation) {
      case StorageLocation.pantry:
        days = item['pantry_days'] as int;
        break;
      case StorageLocation.fridge:
        days = item['refrigerator_days'] as int;
        break;
      case StorageLocation.freezer:
        days = (item['freezer_months'] as int) * 30;
        break;
    }

    setState(() {
      _expiryDate = DateTime.now().add(Duration(days: days));
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editItem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Item' : 'Add Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  prefixIcon: Icon(Icons.fastfood),
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Milk, Chicken Breast',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an item name';
                  }
                  return null;
                },
              ),

              // USDA Suggestions
              if (_showSuggestions)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _usdaSuggestions.length,
                    itemBuilder: (ctx, i) {
                      final item = _usdaSuggestions[i];
                      return ListTile(
                        dense: true,
                        title: Text(item['name'] as String),
                        subtitle:
                            Text(item['category_name'] as String),
                        trailing: Text(
                            '${item['refrigerator_days']}d fridge'),
                        onTap: () => _selectUSDAItem(item),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 16),

              // Storage Location
              SegmentedButton<StorageLocation>(
                segments: const [
                  ButtonSegment(
                    value: StorageLocation.pantry,
                    label: Text('Pantry'),
                    icon: Icon(Icons.kitchen),
                  ),
                  ButtonSegment(
                    value: StorageLocation.fridge,
                    label: Text('Fridge'),
                    icon: Icon(Icons.ac_unit),
                  ),
                  ButtonSegment(
                    value: StorageLocation.freezer,
                    label: Text('Freezer'),
                    icon: Icon(Icons.severe_cold),
                  ),
                ],
                selected: {_storageLocation},
                onSelectionChanged: (selection) {
                  setState(() {
                    _storageLocation = selection.first;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Expiry Date
              ListTile(
                tileColor: Colors.grey[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                leading: const Icon(Icons.calendar_today),
                title: const Text('Expiry Date'),
                subtitle: Text(
                  '${_expiryDate.day}/${_expiryDate.month}/${_expiryDate.year}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
                trailing: Text(
                  '${_expiryDate.difference(DateTime.now()).inDays} days',
                  style: TextStyle(
                    color: _expiryDate.difference(DateTime.now()).inDays <= 3
                        ? Colors.red
                        : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: _pickExpiryDate,
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                initialValue: _category,
                items: _categories
                    .map((cat) =>
                        DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _category = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Barcode (if scanned)
              if (_barcode != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Chip(
                    avatar: const Icon(Icons.qr_code, size: 18),
                    label: Text('Barcode: $_barcode'),
                    onDeleted: () {
                      setState(() => _barcode = null);
                    },
                  ),
                ),

              // Submit button
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: Icon(isEditing ? Icons.save : Icons.add),
                  label: Text(isEditing ? 'Save Changes' : 'Add to Pantry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (widget.editItem != null) {
        // Update existing item
        final item = widget.editItem!;
        item.name = _nameController.text.trim();
        item.expiryDate = _expiryDate;
        item.storageLocation = _storageLocation;
        item.category = _category;
        item.barcode = _barcode;
        ref.read(pantryProvider.notifier).updateItem(item);
      } else {
        // Create new item
        final item = PantryItem(
          name: _nameController.text.trim(),
          expiryDate: _expiryDate,
          storageLocation: _storageLocation,
          category: _category,
          barcode: _barcode,
        );
        ref.read(pantryProvider.notifier).addItem(item);
      }

      Navigator.pop(context);
    }
  }
}
