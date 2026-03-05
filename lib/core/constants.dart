import 'package:flutter/material.dart';

const String kBaseUrl = 'http://192.168.12.18:8000';

const Color kPrimary = Color(0xFF6C63FF);
const Color kPrimaryDark = Color(0xFF4A42D1);
const Color kAccent = Color(0xFF00D09E);
const Color kBackground = Color(0xFFF7F8FC);
const Color kSurface = Colors.white;
const Color kTextPrimary = Color(0xFF1E1E2D);
const Color kTextSecondary = Color(0xFF7B7B93);
const Color kDanger = Color(0xFFFF4D4F);
const Color kWarning = Color(0xFFFFC107);
const Color kSuccess = Color(0xFF00D09E);
const Color kIncomeGreen = Color(0xFF00D09E);
const Color kExpenseRed = Color(0xFFFF6B6B);

const List<String> kIncomeCategories = [
  'Uber',
  '99',
  'iFood',
  'Rappi',
  'Loggi',
  'Freelance',
  'Outros',
];

const List<String> kExpenseCategories = [
  'Combustível',
  'Alimentação',
  'Manutenção do veículo',
  'Aluguel / Moradia',
  'Saúde',
  'Outros',
];

const Map<String, IconData> kCategoryIcons = {
  'Uber': Icons.local_taxi,
  '99': Icons.local_taxi_outlined,
  'iFood': Icons.restaurant,
  'Rappi': Icons.delivery_dining,
  'Loggi': Icons.local_shipping,
  'Freelance': Icons.work_outline,
  'Outros': Icons.more_horiz,
  'Combustível': Icons.local_gas_station,
  'Alimentação': Icons.fastfood,
  'Manutenção do veículo': Icons.build,
  'Aluguel / Moradia': Icons.home,
  'Saúde': Icons.health_and_safety,
};
