import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../api/transactions_api.dart';

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

  List<String> get _cats =>
      _type == 'income'
          ? kIncomeCategories
          : _type == 'expense'
              ? kExpenseCategories
              : [...kIncomeCategories, ...kExpenseCategories];

  bool get _hasFilters =>
      _type != null || _category != null || _start != null || _end != null;

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _start : _end) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: kTextSecondary, fontSize: 13),
      filled: true,
      fillColor: kBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If category no longer valid after type change, reset it
    if (_category != null && !_cats.contains(_category)) {
      _category = null;
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header row
            Row(
              children: [
                const Text(
                  'Filtrar lançamentos',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
                const Spacer(),
                if (_hasFilters)
                  TextButton(
                    onPressed: () => setState(() {
                      _type = null;
                      _category = null;
                      _start = null;
                      _end = null;
                    }),
                    style: TextButton.styleFrom(
                      foregroundColor: kDanger,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Limpar tudo'),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Tipo + Categoria in a row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _type,
                    decoration: _dropdownDecoration('Tipo'),
                    style: const TextStyle(color: kTextPrimary, fontSize: 14),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Todos')),
                      DropdownMenuItem(value: 'income', child: Text('Ganhos')),
                      DropdownMenuItem(value: 'expense', child: Text('Gastos')),
                    ],
                    onChanged: (v) => setState(() {
                      _type = v;
                      _category = null;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _cats.contains(_category) ? _category : null,
                    decoration: _dropdownDecoration('Categoria'),
                    style: const TextStyle(color: kTextPrimary, fontSize: 14),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas')),
                      ..._cats.map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _category = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Período label
            const Text(
              'Período',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextSecondary,
              ),
            ),
            const SizedBox(height: 8),

            // Date pickers row
            Row(
              children: [
                Expanded(child: _DatePickerTile(
                  label: 'De',
                  date: _start,
                  onTap: () => _pickDate(true),
                  onClear: _start != null ? () => setState(() => _start = null) : null,
                )),
                const SizedBox(width: 12),
                Expanded(child: _DatePickerTile(
                  label: 'Até',
                  date: _end,
                  onTap: () => _pickDate(false),
                  onClear: _end != null ? () => setState(() => _end = null) : null,
                )),
              ],
            ),
            const SizedBox(height: 24),

            // Apply button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_type, _category, _start, _end);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Aplicar filtros',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: hasDate ? kPrimary.withOpacity(0.07) : kBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasDate ? kPrimary.withOpacity(0.4) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: hasDate ? kPrimary : kTextSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasDate ? DateFormat('dd/MM/yy').format(date!) : label,
                style: TextStyle(
                  fontSize: 13,
                  color: hasDate ? kPrimary : kTextSecondary,
                  fontWeight: hasDate ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 15, color: kTextSecondary),
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
