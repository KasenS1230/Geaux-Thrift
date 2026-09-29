import 'package:flutter/material.dart';

import '../data/listing_repository.dart';
import '../models/cart.dart';
import '../theme/app_theme.dart';
import '../widgets/filter_drawer.dart';

import 'browse_tab.dart';
import 'cart_screen.dart';
import 'create_listing_screen.dart';
import 'messages_tab.dart';

/// The main page: the Geaux Thrift name, filter button and search bar on top, the current section in the middle, and
/// an Instagram-style icon bar at the bottom (Browse, Sell, Messages).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.repository});
  final ListingRepository? repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  /// What the user has typed. Both sections filter off this.
  String _query = '';
  late final ListingRepository _repository =
      widget.repository ?? ListingRepository();
  final Cart _cart = Cart();
  int _revision = 0;

  /// Which section is showing: 0 = Browse, 1 = Messages.
  int _index = 0;

  /// Price bounds from the filter sidebar, in cents (null = no bound).
  int? _minPriceCents, _maxPriceCents;
  bool get _hasPriceFilter =>
      _minPriceCents != null || _maxPriceCents != null;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _setPriceFilter(int? minCents, int? maxCents) {
    setState(() {
      _minPriceCents = minCents;
      _maxPriceCents = maxCents;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (widget.repository == null) _repository.close();
    _cart.dispose();
    super.dispose();
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => CartScreen(cart: _cart)),
    );
  }

  void _selectSection(int index) {
    if (index != _index) setState(() => _index = index);
  }

  Future<void> _openCreateListing() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateListingScreen(repository: _repository),
      ),
    );
    if (saved == true && mounted) {
      setState(() {
        _revision++;
        // Jump to Browse so the seller sees their new listing.
        _index = 0;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Listing saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final onBrowse = _index == 0;

    return Scaffold(
      key: _scaffoldKey,
      // The filter sidebar only applies to Browse.
      drawer: onBrowse
          ? FilterDrawer(
        minPriceCents: _minPriceCents,
        maxPriceCents: _maxPriceCents,
        onApply: _setPriceFilter,
      )
          : null,
      appBar: AppBar(
        leading: onBrowse
            ? IconButton(
          tooltip: 'Filters',
          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
          // Gold dot = a price filter is active.
          icon: Badge(
            isLabelVisible: _hasPriceFilter,
            backgroundColor: LsuColors.gold,
            smallSize: 8,
            child: const Icon(Icons.tune_rounded),
          ),
        )
            : null,
        centerTitle: true,
        toolbarHeight: 52,
        title: const _Wordmark(),
        actions: [
          ListenableBuilder(
            listenable: _cart,
            builder: (context, _) => IconButton(
              tooltip: 'Cart',
              onPressed: _openCart,
              icon: Badge(
                isLabelVisible: _cart.itemCount > 0,
                label: Text('${_cart.itemCount}'),
                backgroundColor: LsuColors.gold,
                textColor: LsuColors.purple,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
          ),
        ],
        // Search sits on its own row under the name, full width.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _SearchField(
              controller: _searchController,
              hintText: onBrowse ? 'Search LSU merch' : 'Search messages',
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
        ),
      ),
      // IndexedStack keeps each section alive, so switching back to Browse
      // doesn't reload listings or lose your scroll position.
      body: IndexedStack(
        index: _index,
        children: [
          BrowseTab(
            query: _query,
            repository: _repository,
            cart: _cart,
            revision: _revision,
            minPriceCents: _minPriceCents,
            maxPriceCents: _maxPriceCents,
            onClearPrice: () => _setPriceFilter(null, null),
          ),
          MessagesTab(query: _query),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        currentIndex: _index,
        onSelect: _selectSection,
        onSell: _openCreateListing,
      ),
    );
  }
}

/// Icon-only bottom bar: filled purple icon for the current section, outlined
/// grey icons for the rest, and a gold "sell" button in the middle.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentIndex,
    required this.onSelect,
    required this.onSell,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          child: Row(
            children: [
              _NavIcon(
                label: 'Browse',
                icon: Icons.grid_view_outlined,
                selectedIcon: Icons.grid_view_rounded,
                selected: currentIndex == 0,
                onTap: () => onSelect(0),
              ),
              Expanded(
                child: Center(
                  child: IconButton(
                    tooltip: 'Post an item',
                    onPressed: onSell,
                    icon: Container(
                      width: 42,
                      height: 30,
                      decoration: BoxDecoration(
                        color: LsuColors.gold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: LsuColors.purple,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              _NavIcon(
                label: 'Messages',
                icon: Icons.chat_bubble_outline_rounded,
                selectedIcon: Icons.chat_bubble_rounded,
                selected: currentIndex == 1,
                onTap: () => onSelect(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: selected,
        child: Center(
          child: IconButton(
            tooltip: label,
            onPressed: onTap,
            iconSize: 27,
            icon: Icon(
              selected ? selectedIcon : icon,
              color: selected ? LsuColors.purple : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

/// The "Geaux Thrift" name in the top bar: heavy italic, white + LSU gold.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      letterSpacing: -0.4,
      height: 1,
    );
    return Semantics(
      header: true,
      label: 'Geaux Thrift',
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Geaux',
                style: base.copyWith(color: Colors.white),
              ),
              TextSpan(
                text: ' Thrift',
                style: base.copyWith(color: LsuColors.gold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact frosted search pill that sits on the purple bar.
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
    OutlineInputBorder pill(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: color),
    );

    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        cursorColor: LsuColors.gold,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: Colors.white.withValues(alpha: 0.75),
          ),
          // Clear (x) button, only once something is typed.
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
              tooltip: 'Clear search',
              iconSize: 18,
              color: Colors.white.withValues(alpha: 0.75),
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                controller.clear();
                onChanged('');
              },
            ),
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.14),
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: pill(Colors.transparent),
          enabledBorder: pill(Colors.transparent),
          focusedBorder: pill(Colors.white.withValues(alpha: 0.45)),
        ),
      ),
    );
  }
}