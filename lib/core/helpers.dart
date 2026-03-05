import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

String formatCurrency(double value) {
  final f = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  return f.format(value);
}

String formatDate(String iso) {
  try {
    final dt = DateTime.parse(iso);
    return DateFormat('dd/MM/yyyy · HH:mm', 'pt_BR').format(dt.toLocal());
  } catch (_) {
    return iso;
  }
}

String formatShortDate(String iso) {
  try {
    final dt = DateTime.parse(iso);
    return DateFormat('dd/MM', 'pt_BR').format(dt.toLocal());
  } catch (_) {
    return iso;
  }
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? kDanger : kAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ),
  );
}

IconData categoryIcon(String category) {
  return kCategoryIcons[category] ?? Icons.category;
}

Color progressColor(double percent) {
  if (percent >= 0.85) return kSuccess;
  if (percent >= 0.50) return kWarning;
  return kDanger;
}
