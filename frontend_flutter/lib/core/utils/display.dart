import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

String formatDateTime(DateTime dateTime) =>
    DateFormat('dd/MM/yyyy HH:mm').format(dateTime.toLocal());

String formatTime(DateTime dateTime) =>
    DateFormat('HH:mm').format(dateTime.toLocal());

String tabletStatusLabel(String status) => switch (status) {
  'AVAILABLE' => 'Disponível',
  'CHECKED_OUT' => 'Emprestado',
  'MAINTENANCE' => 'Manutenção',
  _ => status,
};

String sessionStatusLabel(String status) => switch (status) {
  'PENDING' => 'Pendente',
  'UNLOCKED' => 'Destravado',
  'OPEN' => 'Em andamento',
  'DIVERGENT' => 'Divergente',
  'COMPLETED' => 'Concluído',
  'CANCELLED' => 'Cancelado',
  'FAILED' => 'Falhou',
  _ => status,
};

Color sessionStatusColor(String status) => switch (status) {
  'COMPLETED' => AppTheme.success,
  'DIVERGENT' || 'PENDING' => AppTheme.warning,
  'CANCELLED' || 'FAILED' => AppTheme.danger,
  _ => AppTheme.blue,
};

Color tabletStatusColor(String status) => switch (status) {
  'AVAILABLE' => AppTheme.success,
  'CHECKED_OUT' => AppTheme.blue,
  'MAINTENANCE' => AppTheme.warning,
  _ => AppTheme.muted,
};
