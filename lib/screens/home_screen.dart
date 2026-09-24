import 'package:flutter/material.dart';

import 'browse_tab.dart';
import 'create_listing_screen.dart';
import 'messages_tab.dart';

/// The main page: a search bar on top, two tabs (Browse / Messages), and the
/// "+" button in the bottom right for posting something to sell.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this)..addListener(_onTabChanged);
  final TextEditingController _searchController = TextEditingController();

  /// What the user has typed. Both tabs filter off this.
  String _query = '';

  void _onTabChanged() {
    // Rebuild so the FAB shows only on the browse tab.
    if (!_tabController.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreateListing() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CreateListingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onBrowseTab = _tabController.index == 0;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: _SearchField(
          controller: _searchController,
          hintText: onBrowseTab ? 'Search LSU merch' : 'Search messages',
          onChanged: (value) => setState(() => _query = value),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.secondary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.grid_view), text: 'Browse'),
            Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Messages'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          BrowseTab(query: _query),
          MessagesTab(query: _query),
        ],
      ),
      // Only offer "sell something" while browsing.
      floatingActionButton: onBrowseTab
          ? FloatingActionButton(
              onPressed: _openCreateListing,
              tooltip: 'Post an item',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

/// The rounded search box that lives in the app bar.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
