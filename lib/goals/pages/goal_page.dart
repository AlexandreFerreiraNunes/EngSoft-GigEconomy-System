import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../api/goals_api.dart';
import '../../shell/pages/shell_page.dart';

class GoalPage extends StatefulWidget {
  final bool isFirstTime;
  final double? currentAmount;
  final int? goalId;

  const GoalPage({
    super.key,
    this.isFirstTime = false,
    this.currentAmount,
    this.goalId,
  });

  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
  late final TextEditingController _ctrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.currentAmount != null ? widget.currentAmount!.toStringAsFixed(2).replaceAll('.', ',') : '',
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_ctrl.text.replaceAll(',', '.').replaceAll(' ', ''));
    if (amount == null || amount <= 0) {
      showSnack(context, 'Informe um valor válido', error: true);
      return;
    }
    setState(() => _loading = true);

    final result = widget.goalId != null
        ? await GoalsApi.update(widget.goalId!, amount)
        : await GoalsApi.create(amount);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.ok) {
      showSnack(context, result.message);
      if (widget.isFirstTime) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ShellPage()),
          (_) => false,
        );
      } else {
        Navigator.of(context).pop(true);
      }
    } else {
      showSnack(context, result.message, error: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isFirstTime ? null : AppBar(title: const Text('Meta mensal')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.flag_rounded, size: 44, color: kPrimary),
              ),
              const SizedBox(height: 24),
              Text(
                widget.isFirstTime ? 'Defina sua meta mensal' : 'Alterar meta mensal',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Quanto você quer ganhar por mês?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: '0,00',
                  prefixText: 'R\$ ',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Confirmar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
