import 'package:flutter/material.dart';

import '../data/listing_repository.dart';
import '../theme/app_theme.dart';

/// The form behind the "+" button: post something for sale.
///
/// TODO(team): add photo upload.

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

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.create(
        title: _titleController.text,
        priceCents: parsePriceCents(_priceController.text)!,
        category: _category,
        description: _descriptionController.text,
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
            // TODO(team): image picker goes here.
            InkWell(
              onTap: () {},
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: LsuColors.purple.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: LsuColors.purple.withValues(alpha: 0.3),
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 36,
                      color: LsuColors.purple,
                    ),
                    SizedBox(height: 8),
                    Text('Add photos'),
                  ],
                ),
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
