import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/listing_repository.dart';
import '../theme/app_theme.dart';

/// The form behind the "+" button: post something for sale.
///
/// The photo is uploaded on submit, not on pick, so abandoning the form leaves
/// nothing behind on the server.

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key, required this.repository});
  final ListingRepository repository;

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  // 'All' is a browse filter, not a real category, so skip it here.
  late String _category = listingCategories[1];

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _saving = false;
  String? _error;

  /// Bytes of the chosen photo, held in memory until the listing is posted.
  Uint8List? _photo;
  String? _photoContentType;

  bool get _cameraAvailable =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      // Resizing keeps phone photos comfortably under the server's 5 MB cap.
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file == null) return;
      final contentType = imageContentType(
        filename: file.name,
        mimeType: file.mimeType,
      );
      if (contentType == null) {
        throw const ListingApiException('Choose a JPEG, PNG or WebP photo.');
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > maxImageBytes) {
        throw const ListingApiException('That photo is larger than 5 MB.');
      }
      if (!mounted) return;
      setState(() {
        _photo = bytes;
        _photoContentType = contentType;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ListingApiException
            ? error.message
            : 'Could not open that photo. Please try another.';
      });
    }
  }

  Future<void> _choosePhotoSource() async {
    if (!_cameraAvailable) return _pickPhoto(ImageSource.gallery);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from library'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pickPhoto(source);
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final photo = _photo;
      final imageUrl = photo == null
          ? null
          : await widget.repository.uploadImage(
              photo,
              contentType: _photoContentType!,
            );
      await widget.repository.create(
        title: _titleController.text,
        priceCents: parsePriceCents(_priceController.text)!,
        category: _category,
        description: _descriptionController.text,
        imageUrl: imageUrl,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error is ListingApiException
              ? error.message
              : 'Could not save listing. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sell an item')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InkWell(
              onTap: _saving ? null : _choosePhotoSource,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 200,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: LsuColors.purple.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: LsuColors.purple.withValues(alpha: 0.3),
                  ),
                ),
                child: _photo == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 36,
                            color: LsuColors.purple,
                          ),
                          SizedBox(height: 8),
                          Text('Add a photo'),
                        ],
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_photo!, fit: BoxFit.cover),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Material(
                              color: Colors.black54,
                              shape: const CircleBorder(),
                              child: IconButton(
                                tooltip: 'Remove photo',
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: _saving
                                    ? null
                                    : () => setState(() {
                                        _photo = null;
                                        _photoContentType = null;
                                      }),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (_photo != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: _saving ? null : _choosePhotoSource,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Change photo'),
                ),
              ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'What are you selling?',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null ||
                      value.trim().isEmpty ||
                      value.trim().length > 120)
                  ? 'Enter a title of 1–120 characters'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Add a price';
                if (parsePriceCents(value) == null) {
                  return 'Use a price from 0 to 1,000,000 with at most 2 decimals';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final category in listingCategories.skip(1))
                  DropdownMenuItem(value: category, child: Text(category)),
              ],
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 5000,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(_saving ? 'Saving…' : 'Post listing'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
