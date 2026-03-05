import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../api/transactions_api.dart';
import 'add_transaction_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _hasMore = false;
  int _page = 1;
  String? _typeFilter;
  String? _categoryFilter;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData({bool reset = true}) async {
    if (reset) {
      _page = 1;
      setState(() => _loading = true);
    }
    final result = await TransactionsApi.list(
      type: _typeFilter,
      category: _categoryFilter,
      startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
      endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
      page: _page,
    );
    if (!mounted) return;
    setState(() {
      if (reset) {
        _items = result.items;
      } else {
        _items.addAll(result.items);
      }
      _hasMore = result.hasMore;
      _loading = false;
    });
  }

  void _loadMore() {
    _page++;
    loadData(reset: false);
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FilterSheet(
        type: _typeFilter,
        category: _categoryFilter,
        startDate: _startDate,
        endDate: _endDate,
        onApply: (type, category, start, end) {
          setState(() {
            _typeFilter = type;
            _categoryFilter = category;
            _startDate = start;
            _endDate = end;
          });
          loadData();
        },
      ),
    );
  }

  void _showItemActions(Map<String, dynamic> item) {
    final isIncome = item['type'] == 'income';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (isIncome ? kIncomeGreen : kExpenseRed).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(categoryIcon(item['category'] ?? ''), color: isIncome ? kIncomeGreen : kExpenseRed),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['category'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        if (item['note'] != null && (item['note'] as String).isNotEmpty)
                          Text(item['note'], style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  Text(
                    '${isIncome ? '+' : '-'} ${formatCurrency(_toDouble(item['amount']))}',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: isIncome ? kIncomeGreen : kExpenseRed),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.edit, color: kPrimary),
                title: const Text('Editar'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _editItem(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: kDanger),
                title: const Text('Excluir', style: TextStyle(color: kDanger)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(item);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editItem(Map<String, dynamic> item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _EditDialog(item: item),
    );
    if (result == true) await loadData();
  }

  void _confirmDelete(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir lançamento'),
        content: const Text('Tem certeza que deseja excluir este lançamento?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: kDanger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final result = await TransactionsApi.delete(item['id']);
      if (!mounted) return;
      if (result.ok) {
        showSnack(context, result.message);
        await loadData();
      } else {
        showSnack(context, result.message, error: true);
      }
    }
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _typeFilter != null || _categoryFilter != null || _startDate != null,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('Nenhum lançamento', style: TextStyle(color: kTextSecondary, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length + (_hasMore ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == _items.length) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: TextButton(
                            onPressed: _loadMore,
                            child: const Text('Carregar mais'),
                          ),
                        ),
                      );
                    }
                    final item = _items[i];
                    final isIncome = item['type'] == 'income';
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (isIncome ? kIncomeGreen : kExpenseRed).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            categoryIcon(item['category'] ?? ''),
                            color: isIncome ? kIncomeGreen : kExpenseRed,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          item['category'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          formatDate(item['created_at'] ?? ''),
                          style: const TextStyle(fontSize: 12, color: kTextSecondary),
                        ),
                        trailing: Text(
                          '${isIncome ? '+' : '-'} ${formatCurrency(_toDouble(item['amount']))}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isIncome ? kIncomeGreen : kExpenseRed,
                            fontSize: 15,
                          ),
                        ),
                        onTap: () => _showItemActions(item),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final String? type;
  final String? category;
  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(String?, String?, DateTime?, DateTime?) onApply;

  const _FilterSheet({
    this.type,
    this.category,
    this.startDate,
    this.endDate,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _type;
  late String? _category;
  late DateTime? _start;
  late DateTime? _end;

  @override
  void initState() {
    super.initState();
    _type = widget.type;
    _category = widget.category;
    _start = widget.startDate;
    _end = widget.endDate;
  }

  List<String> get _cats => _type == 'income' ? kIncomeCategories : _type == 'expense' ? kExpenseCategories : [...kIncomeCategories, ...kExpenseCategories];

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _start : _end) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _start = picked; else _end = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            const Text('Filtros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            const Text('Tipo', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text('Todos'), selected: _type == null, onSelected: (_) => setState(() { _type = null; _category = null; })),
                ChoiceChip(label: const Text('Ganhos'), selected: _type == 'income', onSelected: (_) => setState(() { _type = 'income'; _category = null; }), selectedColor: kIncomeGreen.withOpacity(0.2)),
                ChoiceChip(label: const Text('Gastos'), selected: _type == 'expense', onSelected: (_) => setState(() { _type = 'expense'; _category = null; }), selectedColor: kExpenseRed.withOpacity(0.2)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Categoria', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ChoiceChip(label: const Text('Todas'), selected: _category == null, onSelected: (_) => setState(() => _category = null)),
                ..._cats.map((c) => ChoiceChip(label: Text(c), selected: _category == c, onSelected: (_) => setState(() => _category = c))),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Período', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_start != null ? DateFormat('dd/MM/yy').format(_start!) : 'Início'),
                    onPressed: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_end != null ? DateFormat('dd/MM/yy').format(_end!) : 'Fim'),
                    onPressed: () => _pickDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onApply(null, null, null, null);
                      Navigator.pop(context);
                    },
                    child: const Text('Limpar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_type, _category, _start, _end);
                      Navigator.pop(context);
                    },
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditDialog extends StatefulWidget {
  final Map<String, dynamic> item;
  const _EditDialog({required this.item});

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late String _category;
  bool _loading = false;

  bool get _isIncome => widget.item['type'] == 'income';
  List<String> get _cats => _isIncome ? kIncomeCategories : kExpenseCategories;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.item['amount']?.toString() ?? '');
    _noteCtrl = TextEditingController(text: widget.item['note'] ?? '');
    _category = widget.item['category'] ?? _cats.first;
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;
    setState(() => _loading = true);
    final result = await TransactionsApi.update(
      widget.item['id'],
      category: _category,
      amount: amount,
      note: _noteCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.ok) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Editar lançamento'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'Valor', prefixText: 'R\$ '),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _cats.contains(_category) ? _category : _cats.first,
              items: _cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
              decoration: const InputDecoration(labelText: 'Categoria'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(hintText: 'Observação'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
