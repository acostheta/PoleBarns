import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:path/path.dart' as p; // Uncomment if needed for path manip
import '../providers/project_providers.dart';

class EvidenceTab extends ConsumerStatefulWidget {
  final String projectId;

  const EvidenceTab({super.key, required this.projectId});

  @override
  ConsumerState<EvidenceTab> createState() => _EvidenceTabState();
}

class _EvidenceTabState extends ConsumerState<EvidenceTab> {
  String _selectedTag = 'Todos'; // Todos, Antes, Durante, Después

  @override
  Widget build(BuildContext context) {
    final mediaAsync = ref.watch(projectMediaProvider(widget.projectId));

    return Scaffold(
      body: Column(
        children: [
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['Todos', 'Antes', 'Durante', 'Después'].map((tag) {
                final isSelected = _selectedTag == tag;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() => _selectedTag = tag);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: Colors.blue.shade100,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.blue.shade900 : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: mediaAsync.when(
              data: (mediaList) {
                // Filter locally
                final filtered = _selectedTag == 'Todos'
                    ? mediaList
                    : mediaList
                        .where((m) => m.etiqueta == _selectedTag)
                        .toList();

                if (filtered.isEmpty) {
                  return const Center(
                      child: Text('No hay evidencias visuales.'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return GestureDetector(
                      onTap: () {
                        // TODO: Open full screen image
                        showDialog(
                          context: context,
                          builder: (_) =>
                              Dialog(child: Image.network(item.urlMedia)),
                        );
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            item.urlMedia,
                            fit: BoxFit.cover,
                            loadingBuilder: (c, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            },
                            errorBuilder: (c, e, s) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image,
                                  color: Colors.grey),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.black54,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 4),
                              child: Text(
                                item.etiqueta,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUploadDialog(context),
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _UploadMediaDialog(projectId: widget.projectId),
    );
  }
}

class _UploadMediaDialog extends ConsumerStatefulWidget {
  final String projectId;
  const _UploadMediaDialog({required this.projectId});

  @override
  ConsumerState<_UploadMediaDialog> createState() => _UploadMediaDialogState();
}

class _UploadMediaDialogState extends ConsumerState<_UploadMediaDialog> {
  final _picker = ImagePicker();
  File? _imageFile;
  String _selectedTag = 'Durante';
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _upload() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);

    try {
      // 1. Compress
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        _imageFile!.absolute.path,
        minWidth: 800,
        minHeight: 800,
        quality: 70, // Adjustable quality
      );

      if (compressedBytes == null) throw Exception('Falló la compresión');

      // 2. Upload to Storage
      // Create bucket 'project_media' if not exists? Ideally pre-created.
      // We'll assume bucket 'project-media' exists or use a common one.
      // Let's use 'project-media' bucket.
      final fileName =
          '${widget.projectId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = await Supabase.instance.client.storage
          .from('project-media')
          .uploadBinary(fileName, compressedBytes);

      // 3. Get Public URL
      final publicUrl = Supabase.instance.client.storage
          .from('project-media')
          .getPublicUrl(fileName);

      // 4. Save to DB
      await ref.read(projectRepositoryProvider).addMedia(
            projectId: widget.projectId,
            url: publicUrl,
            tipo: 'foto',
            etiqueta: _selectedTag,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen subida exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Subir Evidencia'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_imageFile != null)
            SizedBox(
              height: 150,
              width: 150,
              child: Image.file(_imageFile!, fit: BoxFit.cover),
            )
          else
            Container(
              height: 150,
              width: 150,
              color: Colors.grey[200],
              child: const Icon(Icons.image, size: 50, color: Colors.grey),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                tooltip: 'Cámara',
              ),
              IconButton(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                tooltip: 'Galería',
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedTag,
            decoration: const InputDecoration(labelText: 'Etiqueta'),
            items: ['Antes', 'Durante', 'Después']
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedTag = val);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: (_imageFile != null && !_isUploading) ? _upload : null,
          child: _isUploading
              ? const SizedBox(
                  height: 16, width: 16, child: CircularProgressIndicator())
              : const Text('Subir'),
        ),
      ],
    );
  }
}
