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
  bool _isListVisible = true;

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFFDFBF7);

    final isMobile = MediaQuery.of(context).size.width < 800;
    final selectedId = ref.watch(selectedAccountPayableIdProvider);

    if (isMobile) {
      if (selectedId != null) {
        return Scaffold(
          backgroundColor: bgLight,
          appBar: AppBar(
            leading: BackButton(
              onPressed: () {
                ref.read(selectedAccountPayableIdProvider.notifier).state =
                    null;
              },
            ),
            title: const Text('Detalle de Cuenta'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 1,
          ),
          body: AccountPayableDetailView(accountId: selectedId),
        );
      } else {
        return Scaffold(
          backgroundColor: bgLight,
          body: const AccountsPayableListSidebar(),
        );
      }
    }

    return Scaffold(
      backgroundColor: bgLight,
      body: Row(
        children: [
          // Left Sidebar (Accounts List)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isListVisible ? 380 : 0,
            child: ClipRect(
              child: OverflowBox(
                minWidth: 380,
                maxWidth: 380,
                child: const AccountsPayableListSidebar(),
              ),
            ),
          ),

          // Collapsible Trigger / Divider
          Material(
            color: Colors.white,
            child: InkWell(
              onTap: () => setState(() => _isListVisible = !_isListVisible),
              child: Container(
                width: 24,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.grey[300]!, width: 1),
                    left: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                child: Center(
                  child: Icon(
                    _isListVisible ? Icons.chevron_left : Icons.chevron_right,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),

          // Right Content (Account Details)
          Expanded(
            child: selectedId == null
                ? const Center(
                    child: Text(
                      'Selecciona una cuenta por pagar para ver los detalles',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : AccountPayableDetailView(accountId: selectedId),
          ),
        ],
      ),
    );
  }
}
