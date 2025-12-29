import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/project_providers.dart';
import '../../models/project_models.dart';

class ProjectGallerySection extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectGallerySection({super.key, required this.projectId});

  @override
  ConsumerState<ProjectGallerySection> createState() =>
      _ProjectGallerySectionState();
}

class _ProjectGallerySectionState extends ConsumerState<ProjectGallerySection> {
  bool _isEditing = false;
  bool _isSaving = false;
  List<ProjectMediaModel> _localMediaList = [];
  List<String> _pendingDeletions = [];

  @override
  Widget build(BuildContext context) {
    final mediaAsync = ref.watch(projectMediaProvider(widget.projectId));
    const primaryColor = Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              const Text(
                'Fotos del Proyecto',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: _upload,
                    icon: const Icon(Icons.add_a_photo,
                        size: 16, color: primaryColor),
                    label: const Text('Subir foto',
                        style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
                  if (mediaAsync.valueOrNull?.isNotEmpty == true || _isEditing)
                    TextButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () {
                              if (_isEditing) {
                                _saveChanges();
                              } else {
                                setState(() {
                                  _isEditing = true;
                                  _pendingDeletions = [];
                                  _localMediaList =
                                      List.from(mediaAsync.value ?? []);
                                });
                              }
                            },
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(_isEditing ? Icons.save : Icons.edit,
                              size: 16, color: primaryColor),
                      label: Text(_isEditing ? 'Guardar' : 'Editar',
                          style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 24),
          mediaAsync.when(
            data: (serverList) {
              final displayList = _isEditing ? _localMediaList : serverList;
              if (displayList.isEmpty && !_isEditing) {
                return _buildEmptyState();
              }
              return SizedBox(
                height: 220,
                child: _isEditing
                    ? ReorderableListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: displayList.length,
                        proxyDecorator: (widget, index, animation) {
                          return Material(
                              color: Colors.transparent, child: widget);
                        },
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = _localMediaList.removeAt(oldIndex);
                            _localMediaList.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final item = displayList[index];
                          return Container(
                            key: ValueKey(item.id),
                            width: 160,
                            margin: const EdgeInsets.only(right: 16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(item.urlMedia,
                                      fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: InkWell(
                                    onTap: () => _deletePhoto(item.id),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.red.withOpacity(0.9),
                                        boxShadow: [
                                          BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              blurRadius: 4)
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(6),
                                      child: const Icon(Icons.close,
                                          size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(Icons.drag_indicator,
                                        size: 16, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: displayList.length + 1,
                        itemBuilder: (context, index) {
                          if (index == displayList.length) {
                            return _buildAddCard();
                          }
                          final item = displayList[index];
                          return _buildPhotoItem(context, item);
                        },
                      ),
              );
            },
            loading: () => const SizedBox(
                height: 180, child: Center(child: CircularProgressIndicator())),
            error: (e, s) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return InkWell(
      onTap: _upload,
      child: Container(
        height: 150,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined,
                size: 32, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No hay fotos aún. Haz click para subir una.',
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCard() {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: InkWell(
        onTap: _upload,
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CustomPaint(
            painter: _DashedBorderPainter(
                color: Colors.grey[300]!, strokeWidth: 1.5, gap: 4),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 28, color: Colors.grey),
                SizedBox(height: 4),
                Text('Añadir Foto',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoItem(BuildContext context, ProjectMediaModel item) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: () => _openFullScreen(context, item.urlMedia),
        child: Container(
          width: 200,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item.urlMedia,
              fit: BoxFit.cover,
              loadingBuilder: (c, child, progress) {
                if (progress == null) return child;
                return Container(color: Colors.grey[100]);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _upload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      final bytes = await picked.readAsBytes();

      // Compress
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1200,
        minHeight: 1200,
        quality: 80,
      );
      if (compressedBytes.isEmpty) return;

      final fileName =
          '${widget.projectId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage
          .from('project-media')
          .uploadBinary(fileName, compressedBytes);

      final publicUrl = Supabase.instance.client.storage
          .from('project-media')
          .getPublicUrl(fileName);

      final newMedia = ProjectMediaModel(
        id: '',
        projectRef: widget.projectId,
        urlMedia: publicUrl,
        tipo: 'foto',
        etiqueta: 'Gallery',
        usuarioCargaRef: Supabase.instance.client.auth.currentUser?.id ?? '',
        createdAt: DateTime.now(),
      );

      await ref.read(projectRepositoryProvider).addMedia(
            projectId: widget.projectId,
            url: publicUrl,
            tipo: 'foto',
            etiqueta: 'Gallery',
          );

      if (_isEditing) {
        setState(() {
          _localMediaList.add(newMedia);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto subida exitosamente')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al subir: $e')));
      }
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      // 1. Process Deletions
      for (final id in _pendingDeletions) {
        // Skip temporary IDs (empty strings) if any
        if (id.isNotEmpty) {
          await ref.read(projectRepositoryProvider).deleteMedia(id);
        }
      }

      // 2. Process Order
      await ref
          .read(projectRepositoryProvider)
          .updateMediaOrder(_localMediaList);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios guardados con éxito')),
        );
        setState(() {
          _isEditing = false;
          _isSaving = false;
          _pendingDeletions = [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  void _deletePhoto(String mediaId) {
    setState(() {
      _localMediaList.removeWhere((m) => m.id == mediaId);
      if (mediaId.isNotEmpty) {
        _pendingDeletions.add(mediaId);
      }
    });
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  _DashedBorderPainter(
      {this.color = Colors.grey, this.strokeWidth = 1.0, this.gap = 5.0});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final RRect rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12));
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
