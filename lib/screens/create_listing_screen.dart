import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_theme.dart';

/// The form behind the "+" button: post something for sale.
///
/// TODO(team): actually save the listing (right now it just pops with a
/// snackbar), add photo upload, and validate price formatting properly.
class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  // 'All' is a browse filter, not a real category, so skip it here.
  late String _category = kCategories[1];

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // TODO(team): build a Listing and hand it to the repository / backend.
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listing saved (not really — yet!)')),
    );
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
                  border: Border.all(color: LsuColors.purple.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        size: 36, color: LsuColors.purple),
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
                  (value == null || value.trim().isEmpty) ? 'Add a title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Add a price';
                if (double.tryParse(value.trim()) == null) {
                  return 'Numbers only';
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
                for (final category in kCategories.skip(1))
                  DropdownMenuItem(value: category, child: Text(category)),
              ],
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Post listing'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
