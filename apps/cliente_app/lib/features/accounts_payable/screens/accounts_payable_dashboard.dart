import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accounts_payable_provider.dart';
import '../widgets/accounts_payable_list_sidebar.dart';
import '../widgets/account_payable_detail_view.dart';

class AccountsPayableDashboard extends ConsumerStatefulWidget {
  const AccountsPayableDashboard({super.key});

  @override
  ConsumerState<AccountsPayableDashboard> createState() =>
      _AccountsPayableDashboardState();
}

class _AccountsPayableDashboardState
    extends ConsumerState<AccountsPayableDashboard> {
  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFFDFBF7);

    return Scaffold(
      backgroundColor: bgLight,
      body: Row(
        children: [
          // Left Sidebar (Accounts List)
          const SizedBox(
            width: 380,
            child: AccountsPayableListSidebar(),
          ),

          // Vertical Divider
          VerticalDivider(width: 1, thickness: 1, color: Colors.grey[300]),

          // Right Content (Account Details)
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final selectedId = ref.watch(selectedAccountPayableIdProvider);
                if (selectedId == null) {
                  return const Center(
                    child: Text(
                      'Selecciona una cuenta por pagar para ver los detalles',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }
                return AccountPayableDetailView(accountId: selectedId);
              },
            ),
          ),
        ],
      ),
    );
  }
}
