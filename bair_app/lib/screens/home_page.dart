import 'package:flutter/material.dart';

import '../models/property.dart';
import '../services/app_store.dart';
import '../widgets/property_card.dart';
import '../widgets/brand.dart';
import '../widgets/home_hero.dart';
import 'property_page.dart';
import 'property_map_page.dart';
import 'property_form_page.dart';
import 'discovery_page.dart';
import 'filter_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final search = TextEditingController();
  String listingType = 'sale';
  List<Property> items = [], featured = [];
  String? error;
  bool loading = true;
  int revision = -1, requestId = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = AppScope.of(context).revision;
    if (revision != r) {
      revision = r;
      load();
    }
  }

  Future<void> load() async {
    final store = AppScope.read(context);
    final id = ++requestId;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final results = await Future.wait([
        store.api.properties({'page_size': '6', 'listing_type': listingType}),
        store.api.properties({
          'page_size': '6',
          'featured': 'true',
          'listing_type': listingType,
        }),
      ]);
      final result = results.first;
      if (mounted && id == requestId) {
        store.rememberFavorites(result.items);
        setState(() {
          items = result.items;
          featured = results.last.items;
        });
      }
    } catch (e) {
      if (mounted && id == requestId) setState(() => error = '$e');
    } finally {
      if (mounted && id == requestId) setState(() => loading = false);
    }
  }

  void browse({String? district, String? type}) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PropertyPage(
        standalone: true,
        initialQuery: {
          'listing_type': listingType,
          if (search.text.trim().isNotEmpty) 'search': search.text.trim(),
          'district': ?district,
          'property_type': ?type,
        },
      ),
    ),
  );
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: load,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              return ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 32 : 18,
                  vertical: 20,
                ),
                children: [
                  Row(
                    children: [
                      const BrandMark(size: 32),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Өргөө',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      if (wide)
                        const Text(
                          'Таны дараагийн түүх эндээс эхэлнэ',
                          style: TextStyle(color: AppColors.secondaryText),
                        ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: addListing,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Зар нэмэх'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  HomeHero(
                    search: search,
                    onSearch: browse,
                    listingType: listingType,
                    onTypeChanged: (value) {
                      setState(() => listingType = value);
                      load();
                    },
                  ),
                  const SizedBox(height: 28),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PropertyMapPage(
                          query: {
                            'listing_type': listingType,
                            if (search.text.trim().isNotEmpty)
                              'search': search.text.trim(),
                          },
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.map_outlined),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Газрын зураг дээр байр хайх'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: propertyTypes.entries
                        .map(
                          (e) => ActionChip(
                            padding: EdgeInsets.symmetric(
                              horizontal: wide ? 18 : 8,
                              vertical: 10,
                            ),
                            avatar: Icon(
                              {
                                'apartment': Icons.apartment_rounded,
                                'house': Icons.cottage_outlined,
                                'office': Icons.business_outlined,
                                'land': Icons.landscape_outlined,
                              }[e.key],
                              size: 21,
                            ),
                            label: Text(e.value),
                            onPressed: () => browse(type: e.key),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 32),
                  _heading(
                    'Өөрийн хэмнэлд тохирох байршил',
                    'Хаана амьдрахыг хүсэж байна вэ?',
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: districts
                          .map(
                            (d) => Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ActionChip(
                                avatar: const Icon(
                                  Icons.place_outlined,
                                  size: 17,
                                ),
                                label: Text(d),
                                onPressed: () => browse(district: d),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DiscoveryPage(
                              kind: 'districts',
                              title: 'Дүүрэг судлах',
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.explore_outlined, size: 18),
                        label: const Text('Дүүрэг судлах'),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DiscoveryPage(
                              kind: 'complexes',
                              title: 'Хотхонууд',
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.location_city, size: 18),
                        label: const Text('Хотхонууд'),
                      ),
                      TextButton.icon(
                        onPressed: recommendations,
                        icon: const Icon(Icons.tune, size: 18),
                        label: const Text('Танд тохирох байр'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (error != null)
                    EmptyState(
                      title: 'Зар ачаалж чадсангүй',
                      message: error!,
                      onRetry: load,
                    )
                  else ...[
                    if (featured.isNotEmpty) ...[
                      _sectionTitle('Онцлох байр', 'Анхаарал татах сонголтууд'),
                      const SizedBox(height: 16),
                      _listings(featured, constraints.maxWidth),
                      const SizedBox(height: 32),
                    ],
                    _sectionTitle(
                      'Шинээр нэмэгдсэн',
                      'Шинэ эхлэлд нэг алхам ойр',
                    ),
                    const SizedBox(height: 16),
                    if (items.isEmpty)
                      EmptyState(
                        title: 'Эхний зарыг нэмээрэй',
                        message: 'Шинэ зарууд энд харагдана.',
                        buttonLabel: 'Зар нэмэх',
                        onRetry: addListing,
                      )
                    else
                      _listings(items, constraints.maxWidth),
                  ],
                  const SizedBox(height: 36),
                  Container(
                    padding: EdgeInsets.all(wide ? 32 : 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EFD9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.key_outlined,
                          color: AppColors.primary,
                          size: 30,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Таны байр хэн нэгний\nшинэ эхлэл.',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            letterSpacing: -.7,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Худалдах эсвэл түрээслэх байраа танилцуулаарай.',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: addListing,
                          icon: const Icon(Icons.add),
                          label: const Text('Зар нэмэх'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Center(
                    child: Text(
                      'ӨРГӨӨ  /  Амьдрах орон зайгаа ол.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _heading(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        subtitle,
        style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
      ),
      const SizedBox(height: 6),
      Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -.5,
        ),
      ),
    ],
  );

  Widget _sectionTitle(String title, String subtitle) => Row(
    children: [
      Expanded(child: _heading(title, subtitle)),
      TextButton(onPressed: browse, child: const Text('Бүгдийг үзэх →')),
    ],
  );

  Widget _listings(List<Property> properties, double width) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = width >= 1050
          ? 3
          : width >= 700
          ? 2
          : 1;
      final cardWidth = (constraints.maxWidth - (columns - 1) * 18) / columns;
      return Wrap(
        spacing: 18,
        runSpacing: 18,
        children: properties
            .map(
              (p) => SizedBox(
                width: cardWidth,
                child: PropertyCard(property: p),
              ),
            )
            .toList(),
      );
    },
  );

  Future<void> addListing() async {
    if (!await requireLogin(context) || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PropertyFormPage()),
    );
  }

  Future<void> recommendations() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FilterSheet(
        query: {'listing_type': listingType},
        recommendations: true,
      ),
    );
    if (result == null || result['max_price'] == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyPage(
          standalone: true,
          recommendations: true,
          initialQuery: result,
        ),
      ),
    );
  }
}
