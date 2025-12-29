import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_providers.dart';
import '../widgets/financial_tab.dart';
import '../widgets/costs_tab.dart';
import '../widgets/evidence_tab.dart';
import '../widgets/chat_tab.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectDetailProvider(projectId));

    if (project == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(project.address ?? 'Detalle de Obra'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Finanzas'),
              Tab(text: 'Costos'),
              Tab(text: 'Evidencias'),
              Tab(text: 'Chat'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FinancialTab(project: project),
            CostsTab(projectId: project.id),
            EvidenceTab(projectId: project.id),
            ChatTab(projectId: project.id),
          ],
        ),
      ),
    );
  }
}
