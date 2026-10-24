import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../models/property.dart';
import 'brand.dart';
import 'property_card.dart';

class DesktopBrowser extends StatefulWidget {
  final Map<String, String> query;
  final TextEditingController search;
  final List<Property> items;
  final int count;
  final bool loading, loadingMore, hasNext;
  final String? error;
  final VoidCallback onMap, onFilters, onMore, onRetry;
  final ValueChanged<Map<String, String>> onApply;
  const DesktopBrowser({
    super.key,
    required this.query,
    required this.search,
    required this.items,
    required this.count,
    required this.loading,
    required this.loadingMore,
    required this.hasNext,
    this.error,
    required this.onMap,
    required this.onFilters,
    required this.onMore,
    required this.onRetry,
    required this.onApply,
  });
  @override
  State<DesktopBrowser> createState() => _DesktopBrowserState();
}

class _DesktopBrowserState extends State<DesktopBrowser> {
  final minPrice = TextEditingController(), maxPrice = TextEditingController();
  final minArea = TextEditingController(), maxArea = TextEditingController();
  late Map<String, String> draft;
  @override
  void initState() {
    super.initState();
    sync();
  }

  void sync() {
    draft = Map.of(widget.query);
    for (final pair in [
      (minPrice, 'min_price'),
      (maxPrice, 'max_price'),
      (minArea, 'min_area'),
      (maxArea, 'max_area'),
    ]) {
      pair.$1.text = draft[pair.$2] ?? '';
    }
  }

  @override
  void didUpdateWidget(DesktopBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.query, widget.query)) sync();
  }

  @override
  void dispose() {
    for (final c in [minPrice, maxPrice, minArea, maxArea]) {
      c.dispose();
    }
    super.dispose();
  }

  void apply() {
    final next = {...draft, 'search': widget.search.text.trim()};
    for (final pair in [
      (minPrice, 'min_price'),
      (maxPrice, 'max_price'),
      (minArea, 'min_area'),
      (maxArea, 'max_area'),
    ]) {
      if (pair.$1.text.trim().isEmpty) {
        next.remove(pair.$2);
      } else {
        next[pair.$2] = pair.$1.text.trim();
      }
    }
    widget.onApply(next);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        color: const Color(0xFFF0EEE7),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'НҮҮР  ›  БАЙР ХАЙХ',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.secondaryText,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Дараагийн гэрээ эндээс.',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: widget.search,
                    onSubmitted: (_) => apply(),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.place_outlined, size: 20),
                      hintText: 'Улаанбаатар, дүүрэг, хотхон...',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: draft['property_type'] ?? '',
                    key: ValueKey(draft['property_type']),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.apartment, size: 20),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Бүх төрөл'),
                      ),
                      ...propertyTypes.entries.map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => draft['property_type'] = value!),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: apply,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Хайх'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: widget.onMap,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Газрын зураг'),
                ),
              ],
            ),
          ],
        ),
      ),
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 220,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 12, 30),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Шүүлтүүр',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                draft = {};
                                for (final c in [
                                  minPrice,
                                  maxPrice,
                                  minArea,
                                  maxArea,
                                ]) {
                                  c.clear();
                                }
                              });
                              widget.search.clear();
                              widget.onApply({});
                            },
                            child: const Text(
                              'Цэвэрлэх',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Дүүрэг',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final d in ['', ...districts])
                        InkWell(
                          onTap: () => setState(() {
                            toggleDistrict(draft, d);
                          }),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  (d.isEmpty
                                          ? selectedDistricts(draft).isEmpty
                                          : selectedDistricts(draft)
                                                .contains(d))
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  size: 15,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    d.isEmpty ? 'Бүх дүүрэг' : d,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Text('Үнэ · ₮', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      _range(minPrice, maxPrice),
                      const SizedBox(height: 20),
                      const Text('Өрөөний тоо', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          for (final r in ['1', '2', '3', '4'])
                            ChoiceChip(
                              label: Text(r),
                              selected: draft['rooms'] == r,
                              onSelected: (selected) => setState(() {
                                if (selected) {
                                  draft['rooms'] = r;
                                } else {
                                  draft.remove('rooms');
                                }
                              }),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('Талбай · м²', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      _range(minArea, maxArea),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: apply,
                          child: const Text(
                            'Үр дүн харах',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: widget.onFilters,
                        icon: const Icon(Icons.tune, size: 16),
                        label: const Text(
                          'Бүх шүүлтүүр',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 20, 24, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${widget.count} байр',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        for (final option in [
                          ('sale', 'Худалдах'),
                          ('rent', 'Түрээслэх'),
                        ])
                          TextButton(
                            onPressed: () => widget.onApply({
                              ...widget.query,
                              'listing_type': option.$1,
                            }),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  widget.query['listing_type'] == option.$1
                                  ? AppColors.primary
                                  : AppColors.secondaryText,
                            ),
                            child: Text(option.$2),
                          ),
                        const SizedBox(width: 16),
                        DropdownButton<String>(
                          value: widget.query['ordering'] ?? '-created_at',
                          underline: const SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(
                              value: '-created_at',
                              child: Text('Шинэ эхэнд'),
                            ),
                            DropdownMenuItem(
                              value: 'price',
                              child: Text('Үнэ өсөхөөр'),
                            ),
                            DropdownMenuItem(
                              value: '-price',
                              child: Text('Үнэ буурахаар'),
                            ),
                            DropdownMenuItem(
                              value: '-area',
                              child: Text('Талбай ихээс'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              widget.onApply({
                                ...widget.query,
                                'ordering': value,
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: widget.loading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(12, 0, 24, 32),
                            children: [
                              if (widget.error != null)
                                EmptyState(
                                  title: 'Зар ачаалж чадсангүй',
                                  message: widget.error!,
                                  onRetry: widget.onRetry,
                                ),
                              if (widget.items.isEmpty && widget.error == null)
                                const EmptyState(
                                  title: 'Тохирох зар олдсонгүй',
                                  message:
                                      'Шүүлтүүрээ өөрчилж дахин хайгаарай.',
                                ),
                              LayoutBuilder(
                                builder: (context, box) {
                                  final cols = box.maxWidth >= 820 ? 3 : 2;
                                  final width =
                                      (box.maxWidth - 14 * (cols - 1)) / cols;
                                  return Wrap(
                                    spacing: 14,
                                    runSpacing: 14,
                                    children: widget.items
                                        .map(
                                          (p) => SizedBox(
                                            width: width,
                                            child: PropertyCard(property: p),
                                          ),
                                        )
                                        .toList(),
                                  );
                                },
                              ),
                              if (widget.hasNext)
                                Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: OutlinedButton(
                                    onPressed: widget.loadingMore
                                        ? null
                                        : widget.onMore,
                                    child: Text(
                                      widget.loadingMore
                                          ? 'Ачаалж байна…'
                                          : 'Дараагийн зарууд',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
  Widget _range(TextEditingController min, TextEditingController max) => Row(
    children: [
      Expanded(
        child: TextField(
          controller: min,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 11),
          decoration: const InputDecoration(
            hintText: 'Доод',
            contentPadding: EdgeInsets.all(10),
          ),
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: TextField(
          controller: max,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 11),
          decoration: const InputDecoration(
            hintText: 'Дээд',
            contentPadding: EdgeInsets.all(10),
          ),
        ),
      ),
    ],
  );
}
