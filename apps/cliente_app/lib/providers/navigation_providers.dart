import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardIndexProvider = StateProvider<int>((ref) => 0);
final sidebarExpandedProvider = StateProvider<bool>((ref) => true);

/// Provider to hold global AppBar actions from child screens
final appBarActionsProvider = StateProvider<List<Widget>>((ref) => []);

/// Provider to hold a custom title for the global AppBar
final appBarTitleProvider = StateProvider<String?>((ref) => null);

class DashboardIndices {
  static const int home = 0;
  static const int profile = 1;
  static const int settings = 2;
  static const int accountsPayable = 3;
  static const int projectTracking = 4;
  static const int poleBarns = 5;
  static const int invoices = 6;
  static const int payroll = 7;
  static const int users = 8;
  static const int clients = 9;
  static const int rawMaterials = 10;
  static const int measures = 11;
}
