import 'dart:async';

import 'package:flutter/material.dart';

import 'filter_sheet.dart';
import '../widgets/brand.dart';

import '../models/property.dart';
import '../services/app_store.dart';
import '../widgets/location_map.dart';
import '../widgets/property_card.dart';

class PropertyMapPage extends StatefulWidget {
  final Map<String, String> query;
  final bool recommendations;
  final Widget Function(String url)? tileBuilder;
  const PropertyMapPage({
    super.key,
    required this.query,
    this.recommendations = false,
    this.tileBuilder,
  });
  @override
  State<PropertyMapPage> createState() => _PropertyMapPageState();
}

class _PropertyMapPageState extends State<PropertyMapPage> {
  String? bounds, error;
  late Map<String, String> query = Map.of(widget.query);
  final searchController = TextEditingController();
  Timer? debounce;
  bool autoSearch = true, showResults = false;
  Property? selected;

  @override
  void initState() {
    super.initState();
    searchController.text = query['search'] ?? '';
  }

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void boundsChanged(String value) {
    final first = bounds == null;
    if (bounds == value) return;
    bounds = value;
    debounce?.cancel();
    if (first) {
      search();
    } else if (autoSearch) {
      debounce = Timer(const Duration(milliseconds: 550), search);
    }
  }

  Future<void> filters() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          FilterSheet(query: query, recommendations: widget.recommendations),
    );
    if (result == null || !mounted) return;
    setState(() {
      query = result;
      searchController.text = query['search'] ?? '';
    });
    search();
  }

  List<Property> items = [];
  bool loading = false;
  int count = 0, requestId = 0;
  Future<void> search() async {
    if (bounds == null) return;
    final id = ++requestId;
    final bbox = bounds!;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await AppScope.read(context).api.properties({
        ...query,
        'located': 'true',
        'bbox': bbox,
        'page_size': '100',
        'page': '1',
      }, recommendations: widget.recommendations);
      if (!mounted || id != requestId) return;
      setState(() {
        items = result.items;
        count = result.count;
      });
    } catch (e) {
      if (mounted && id == requestId) setState(() => error = '$e');
    } finally {
      if (mounted && id == requestId) setState(() => loading = false);
    }
  }

  void select(Property p) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: PropertyCard(property: p),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Газрын зураг дээр хайх')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    query['search'] = value.trim();
                    search();
                  },
                  decoration: InputDecoration(
                    hintText: 'Дүүрэг, хотхон, байршил...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      tooltip: 'Хайх',
                      onPressed: () {
                        query['search'] = searchController.text.trim();
                        search();
                      },
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: filters,
                tooltip: 'Шүүлтүүр',
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final map = Stack(
                children: [
                  Positioned.fill(
                    child: LocationMap(
                      initialCenter: selected == null
                          ? const MapPoint(47.9185, 106.9177)
                          : MapPoint(selected!.latitude!, selected!.longitude!),
                      tileBuilder: widget.tileBuilder,
                      onBoundsChanged: boundsChanged,
                      pins: items
                          .where(
                            (p) => p.latitude != null && p.longitude != null,
                          )
                          .map(
                            (p) => MapPin(
                              MapPoint(p.latitude!, p.longitude!),
                              p.priceLabel,
                              selected: selected?.id == p.id,
                              onTap: () {
                                if (wide) {
                                  setState(() => selected = p);
                                } else {
                                  select(p);
                                }
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 70,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        color: Colors.white,
                        elevation: 2,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 32,
                                child: Checkbox(
                                  value: autoSearch,
                                  onChanged: (value) {
                                    setState(() => autoSearch = value!);
                                    if (autoSearch) search();
                                  },
                                ),
                              ),
                              const Flexible(
                                child: Text(
                                  'Зөөхөд автоматаар хайх',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 34,
                    left: 12,
                    right: 12,
                    child: Center(
                      child: FilledButton.icon(
                        onPressed: loading ? null : search,
                        icon: const Icon(Icons.search, size: 18),
                        label: const Text('Энэ орчимд хайх'),
                      ),
                    ),
                  ),
                  if (loading)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(),
                    ),
                ],
              );
              return Row(
                children: [
                  if (wide) SizedBox(width: 360, child: _results()),
                  Expanded(child: !wide && showResults ? _results() : map),
                ],
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error != null)
                  Text(
                    error!,
                    style: const TextStyle(color: Colors.deepOrange),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        loading
                            ? 'Зар хайж байна…'
                            : count == 0
                            ? 'Энэ хүрээнд тохирох зар алга.'
                            : '$count зар • ${items.length} тэмдэглэгээ',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (MediaQuery.sizeOf(context).width < 900)
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => showResults = !showResults),
                        icon: Icon(
                          showResults
                              ? Icons.map_outlined
                              : Icons.view_list_outlined,
                          size: 18,
                        ),
                        label: Text(showResults ? 'Газрын зураг' : 'Зарууд'),
                      ),
                  ],
                ),
                if (count > items.length)
                  const Text(
                    'Эхний 100 зар харагдаж байна. Зургийг томруулж хүрээгээ багасгаарай.',
                    style: TextStyle(fontSize: 11),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _results() {
    final ordered = [...items];
    if (selected != null) {
      ordered.sort(
        (a, b) => a.id == selected!.id
            ? -1
            : b.id == selected!.id
            ? 1
            : 0,
      );
    }
    return ColoredBox(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Байршлаар нь харьцуулаарай',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Газрын зураг дээр үнэ дээр дарж байраа сонгоорой.',
            style: TextStyle(color: AppColors.secondaryText, height: 1.5),
          ),
          const SizedBox(height: 18),
          if (!loading && items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Газрын зургийг зөөх эсвэл шүүлтүүрээ өөрчилж хайгаарай.',
              ),
            ),
          for (final p in ordered)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (selected?.id == p.id)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'СОНГОСОН БАЙР',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  PropertyCard(property: p),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      selected = p;
                      showResults = false;
                    }),
                    icon: const Icon(Icons.place_outlined, size: 17),
                    label: const Text('Газрын зурагт харах'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
