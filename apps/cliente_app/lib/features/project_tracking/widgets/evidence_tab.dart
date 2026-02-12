import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import '../providers/project_providers.dart';
import '../models/project_models.dart';

class EvidenceTab extends ConsumerWidget {
  final String projectId;

  const EvidenceTab({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(projectMediaProvider(projectId));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: mediaAsync.when(
        data: (mediaList) {
          if (mediaList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay evidencias visuales',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sube fotos para documentar el progreso',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // Group by date
          final Map<String, List<ProjectMediaModel>> groupedByDate = {};
          for (var media in mediaList) {
            final dateKey = DateFormat('yyyy-MM-dd').format(media.fecha);
            groupedByDate.putIfAbsent(dateKey, () => []);
            groupedByDate[dateKey]!.add(media);
          }

          // Sort dates descending (newest first)
          final sortedDates = groupedByDate.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final dateKey = sortedDates[index];
              final mediaForDate = groupedByDate[dateKey]!;
              final firstMedia = mediaForDate.first;

              return _DateCarouselCard(
                date: firstMedia.fecha,
                descripcion: firstMedia.descripcion,
                uploadedBy: firstMedia.usuarioNombre ?? 'Usuario',
                mediaList: mediaForDate,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $e',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadDialog(context, ref),
        backgroundColor: AppStyles.primaryOrange,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Subir Evidencias'),
      ),
    );
  }

  void _showUploadDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _UploadMediaDialog(projectId: projectId),
    );
  }
}

class _DateCarouselCard extends ConsumerWidget {
  final DateTime date;
  final String? descripcion;
  final String uploadedBy;
  final List<ProjectMediaModel> mediaList;

  const _DateCarouselCard({
    required this.date,
    required this.descripcion,
    required this.uploadedBy,
    required this.mediaList,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date and user
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppStyles.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_today,
                      color: AppStyles.primaryOrange, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, d MMMM yyyy').format(date),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.person,
                              size: 14, color: Color(0xFF6B7280)),
                          const SizedBox(width: 4),
                          Text(
                            'Subido por $uploadedBy',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${mediaList.length} ${mediaList.length == 1 ? 'foto' : 'fotos'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      _showEditDialog(context, ref);
                    } else if (value == 'delete') {
                      _showDeleteConfirm(context, ref);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Editar descripción'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar todo el día',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (descripcion != null && descripcion!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.description_outlined,
                        size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        descripcion!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Carousel
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: mediaList.length,
                itemBuilder: (context, index) {
                  final media = mediaList[index];
                  return GestureDetector(
                    onTap: () => _showFullImage(context, media.urlMedia),
                    child: Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          media.urlMedia,
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
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _UploadMediaDialog(
        projectId: mediaList.first.projectRef,
        existingMedia: mediaList,
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar registro?'),
        content: Text(
            'Se eliminarán las ${mediaList.length} fotos y la descripción de este día. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final repo = ref.read(projectRepositoryProvider);
                final ids = mediaList.map((m) => m.id).toList();
                await repo.deleteMediaBatch(ids);
                ref.invalidate(
                    projectMediaProvider(mediaList.first.projectRef));
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e')),
                  );
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            Positioned(
              top: 40,
              right: 40,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadMediaDialog extends ConsumerStatefulWidget {
  final String projectId;
  final List<ProjectMediaModel>? existingMedia;
  const _UploadMediaDialog({required this.projectId, this.existingMedia});

  @override
  ConsumerState<_UploadMediaDialog> createState() => _UploadMediaDialogState();
}

class _UploadMediaDialogState extends ConsumerState<_UploadMediaDialog> {
  final _picker = ImagePicker();
  final List<XFile> _newImageFiles = [];
  final List<ProjectMediaModel> _currentImages = [];
  final List<String> _pendingDeletions = [];
  final _descripcionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingMedia != null && widget.existingMedia!.isNotEmpty) {
      _currentImages.addAll(widget.existingMedia!);
      _selectedDate = widget.existingMedia!.first.fecha;
      _descripcionController.text =
          widget.existingMedia!.first.descripcion ?? '';
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => _newImageFiles.addAll(picked));
    }
  }

  Future<void> _pickImageFromCamera() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _newImageFiles.add(picked));
    }
  }

  void _removeNewImage(int index) {
    setState(() => _newImageFiles.removeAt(index));
  }

  void _removeExistingImage(int index) {
    setState(() {
      final item = _currentImages.removeAt(index);
      _pendingDeletions.add(item.id);
    });
  }

  Future<void> _uploadAll() async {
    if (_newImageFiles.isEmpty &&
        _currentImages.isEmpty &&
        _pendingDeletions.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final repo = ref.read(projectRepositoryProvider);
      final newDescription = _descripcionController.text.isEmpty
          ? null
          : _descripcionController.text;

      // 1. Handle Deletions
      if (_pendingDeletions.isNotEmpty) {
        await repo.deleteMediaBatch(_pendingDeletions);
      }

      // 2. Handle metadata updates for existing images
      for (var media in _currentImages) {
        // Only update if changed
        final dateString = _selectedDate.toIso8601String().split('T')[0];
        final oldDateString = media.fecha.toIso8601String().split('T')[0];

        if (dateString != oldDateString ||
            media.descripcion != newDescription) {
          await repo.updateMediaMetadata(
            mediaId: media.id,
            fecha: _selectedDate,
            descripcion: newDescription,
          );
        }
      }

      // 3. Handle New Image Uploads
      for (var imageFile in _newImageFiles) {
        Uint8List? compressedBytes;

        if (kIsWeb) {
          final bytes = await imageFile.readAsBytes();
          try {
            compressedBytes = await FlutterImageCompress.compressWithList(
              bytes,
              minHeight: 800,
              minWidth: 800,
              quality: 70,
            );
          } catch (e) {
            debugPrint('Web compression failed, using original bytes: $e');
            compressedBytes = bytes;
          }
        } else {
          final file = File(imageFile.path);
          compressedBytes = await FlutterImageCompress.compressWithFile(
            file.absolute.path,
            minWidth: 800,
            minHeight: 800,
            quality: 70,
          );
        }

        if (compressedBytes == null) {
          throw Exception('Falló el procesamiento de una imagen');
        }

        final fileName =
            '${widget.projectId}/${DateTime.now().millisecondsSinceEpoch}.jpg';

        await Supabase.instance.client.storage
            .from('project-media')
            .uploadBinary(
              fileName,
              compressedBytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );

        final publicUrl = Supabase.instance.client.storage
            .from('project-media')
            .getPublicUrl(fileName);

        await ref.read(projectRepositoryProvider).addMedia(
              projectId: widget.projectId,
              url: publicUrl,
              fecha: _selectedDate,
              descripcion: _descripcionController.text.isEmpty
                  ? null
                  : _descripcionController.text,
            );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.existingMedia == null
                  ? 'Evidencias subidas exitosamente'
                  : 'Registro actualizado exitosamente')),
        );
        ref.invalidate(projectMediaProvider(widget.projectId));
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

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingMedia == null
                      ? 'Subir Evidencias Diarias'
                      : 'Editar Registro Diario',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Date selector
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: AppStyles.primaryOrange),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Description
            TextField(
              controller: _descripcionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción del progreso (opcional)',
                hintText: 'Ej: Instalación de postes de la estructura',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Image picker buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImageFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cámara'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                  ),
                ),
              ],
            ),
            if (_currentImages.isNotEmpty || _newImageFiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Imágenes:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Existing Images
                    ..._currentImages.asMap().entries.map((entry) {
                      final index = entry.key;
                      final media = entry.value;
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(media.urlMedia,
                                  fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => _removeExistingImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    // New Images
                    ..._newImageFiles.asMap().entries.map((entry) {
                      final index = entry.key;
                      final imageFile = entry.value;
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppStyles.primaryOrange, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb
                                  ? Image.network(imageFile.path,
                                      fit: BoxFit.cover)
                                  : Image.file(File(imageFile.path),
                                      fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => _removeNewImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppStyles.primaryOrange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('NUEVA',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed:
                  ((_currentImages.isNotEmpty || _newImageFiles.isNotEmpty) &&
                          !_isUploading)
                      ? _uploadAll
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      widget.existingMedia == null
                          ? 'Subir Evidencias'
                          : 'Guardar Cambios',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
