import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/image_upload_service.dart';

/// Reusable widget for picking and uploading images with preview.
/// Shows current image or placeholder, allows pick from gallery/camera.
class ImageUploadWidget extends StatefulWidget {
  final String? currentImageUrl;
  final String folder;
  final ImageUploadService uploadService;
  final ValueChanged<ImageUploadResult?> onImageUploaded;
  final double size;
  final bool circular;
  final String placeholder;

  const ImageUploadWidget({
    super.key,
    this.currentImageUrl,
    this.folder = '',
    required this.uploadService,
    required this.onImageUploaded,
    this.size = 120,
    this.circular = true,
    this.placeholder = 'Adicionar foto',
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  bool _uploading = false;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.currentImageUrl;
  }

  @override
  void didUpdateWidget(covariant ImageUploadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentImageUrl != widget.currentImageUrl) {
      _imageUrl = widget.currentImageUrl;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _uploading = true);

    try {
      final result = await widget.uploadService.pickAndUpload(
        source: source,
        folder: widget.folder,
      );

      if (result != null) {
        setState(() => _imageUrl = result.url);
        widget.onImageUploaded(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_imageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remover foto',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _imageUrl = null);
                  widget.onImageUploaded(null);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget imageContent;

    if (_uploading) {
      imageContent = SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      imageContent = CachedNetworkImage(
        imageUrl: _imageUrl!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        placeholder: (_, __) => SizedBox(
          width: widget.size,
          height: widget.size,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) => _buildPlaceholder(theme),
      );
    } else {
      imageContent = _buildPlaceholder(theme);
    }

    final child = widget.circular
        ? ClipOval(child: imageContent)
        : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageContent,
          );

    return GestureDetector(
      onTap: _uploading ? null : _showSourcePicker,
      child: Stack(
        children: [
          child,
          if (!_uploading)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _imageUrl != null ? Icons.edit : Icons.add_a_photo,
                  size: 16,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: widget.circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.circular ? null : BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: widget.size * 0.4,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 4),
          Text(
            widget.placeholder,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
