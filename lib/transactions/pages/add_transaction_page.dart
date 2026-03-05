import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../api/transactions_api.dart';

class AddTransactionPage extends StatefulWidget {
  final String type;

  const AddTransactionPage({super.key, required this.type});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _selectedCategory;
  bool _loading = false;

  bool get _isIncome => widget.type == 'income';
  List<String> get _categories => _isIncome ? kIncomeCategories : kExpenseCategories;

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.').replaceAll(' ', ''));
    if (amount == null || amount <= 0) {
      showSnack(context, 'Informe um valor válido', error: true);
      return;
    }
    if (_selectedCategory == null) {
      showSnack(context, 'Selecione uma categoria', error: true);
      return;
    }
    setState(() => _loading = true);
    final result = await TransactionsApi.create(
      type: widget.type,
      category: _selectedCategory!,
      amount: amount,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.ok) {
      showSnack(context, result.message);
      Navigator.of(context).pop(true);
    } else {
      showSnack(context, result.message, error: true);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _isIncome ? kIncomeGreen : kExpenseRed;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isIncome ? 'Registrar Ganho' : 'Registrar Gasto'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    _isIncome ? Icons.trending_up : Icons.trending_down,
                    size: 32,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Valor', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0,00',
                  prefixText: 'R\$ ',
                  prefixIcon: Icon(Icons.attach_money, color: accentColor),
                ),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                autofocus: true,
              ),
              const SizedBox(height: 24),
              Text('Categoria', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final selected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(categoryIcon(cat), size: 18, color: selected ? Colors.white : kTextSecondary),
                        const SizedBox(width: 6),
                        Text(cat),
                      ],
                    ),
                    selected: selected,
                    selectedColor: accentColor,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : kTextPrimary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: selected ? accentColor : Colors.grey.shade200),
                    ),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text('Observação (opcional)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Ex: corridas pela manhã',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
