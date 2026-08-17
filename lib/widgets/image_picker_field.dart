import 'package:flutter/material.dart';

import '../services/cloudinary_service.dart';
import '../widgets/luxury.dart';

class ImagePickerField extends StatefulWidget {
  const ImagePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  bool _uploading = false;
  String? _error;

  Future<void> _upload() async {
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final url = await CloudinaryService().uploadPickedImage();
      widget.onChanged(url);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SiteScope.of(context).colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label),
          const SizedBox(height: 8),
          if (widget.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Image.network(
                widget.value,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(height: 40),
              ),
            ),
          TextFormField(
            initialValue: widget.value,
            decoration: const InputDecoration(labelText: 'Image URL'),
            onChanged: widget.onChanged,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _uploading ? null : _upload,
                icon: _uploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(_uploading ? 'Uploading...' : 'Upload to Cloudinary'),
              ),
              if (widget.value.isNotEmpty)
                TextButton(
                  onPressed: () => widget.onChanged(''),
                  child: const Text('Remove'),
                ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: colors.brass, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
