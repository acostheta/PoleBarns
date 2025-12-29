import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/project_models.dart';
import '../providers/project_providers.dart';

class ProjectCreateDialog extends ConsumerStatefulWidget {
  const ProjectCreateDialog({super.key});

  @override
  ConsumerState<ProjectCreateDialog> createState() =>
      _ProjectCreateDialogState();
}

class _ProjectCreateDialogState extends ConsumerState<ProjectCreateDialog> {
  final _formKey = GlobalKey<FormState>();

  // Form State
  final _addressController = TextEditingController();
  final _responsableController = TextEditingController();
  final _groupController = TextEditingController();

  String? _selectedClientId;
  String _selectedStatus = 'En Proceso';

  final List<String> _statusOptions = ['Pendiente', 'En Proceso', 'Terminado'];

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a client')));
      return;
    }

    // Create Model
    final newProject = ProjectModel(
      id: '',
      refCliente: _selectedClientId!,
      responsable: _responsableController.text.isEmpty
          ? 'N/A'
          : _responsableController.text,
      estatus: _selectedStatus,
      grupoAsignado: _groupController.text,
      address: _addressController.text,
      fechaInicio: _startDate,
      fechaFinalizacion: _endDate,
      ventaTotal: 0,
      costosTotales: 0,
      profit: 0,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(projectRepositoryProvider).createProject(newProject);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating project: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientListProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('New Project',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 24),

                // Form Fields
                _buildTextField('Project Name / Address', _addressController,
                    required: true),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: 216,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Client',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  color: Color(0xFF374151))),
                          const SizedBox(height: 4),
                          clientsAsync.when(
                            data: (clients) => DropdownButtonFormField<String>(
                              value: _selectedClientId,
                              items: clients
                                  .map((c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.fullName,
                                          overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedClientId = val),
                              decoration: _inputDecoration(),
                              validator: (v) => v == null ? 'Required' : null,
                              isExpanded: true,
                            ),
                            loading: () => const LinearProgressIndicator(),
                            error: (e, _) => Text('Error loading clients: $e',
                                style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                        width: 216,
                        child: _buildTextField(
                            'Responsable', _responsableController)),
                  ],
                ),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: 216,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Status',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  color: Color(0xFF374151))),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            items: _statusOptions
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedStatus = val);
                              }
                            },
                            decoration: _inputDecoration(),
                          )
                        ],
                      ),
                    ),
                    SizedBox(
                        width: 216,
                        child: _buildTextField('Group', _groupController)),
                  ],
                ),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                        width: 216,
                        child: _buildDateField('Start Date', _startDate,
                            (d) => setState(() => _startDate = d))),
                    SizedBox(
                        width: 216,
                        child: _buildDateField('End Date', _endDate,
                            (d) => setState(() => _endDate = d))),
                  ],
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Create Project'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300)),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Color(0xFF374151))),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          validator: required
              ? (v) => v == null || v.isEmpty ? 'Required' : null
              : null,
          decoration: _inputDecoration(),
        )
      ],
    );
  }

  Widget _buildDateField(
      String label, DateTime date, Function(DateTime) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Color(0xFF374151))),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030));
            if (picked != null) onChanged(picked);
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('dd/MM/yyyy').format(date)),
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              ],
            ),
          ),
        )
      ],
    );
  }
}
