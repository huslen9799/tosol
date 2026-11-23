import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/property.dart';
import '../models/nearby_place.dart';
import '../services/app_store.dart';
import '../widgets/property_card.dart';
import '../widgets/property_location.dart';
import 'property_form_page.dart';
import 'property_map_page.dart';
import 'compare_page.dart';

class PropertyDetailPage extends StatefulWidget {
  final int id;
  const PropertyDetailPage({super.key, required this.id});
  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> {
  Property? property;
  String? error;
  bool loading = true, deleting = false;
  int photoIndex = 0;
  final photoController = PageController();
  NearbyResult? nearby;
  bool nearbyLoading = false;
  String? nearbyError;
  @override
  void dispose() {
    photoController.dispose();
    super.dispose();
  }

  bool started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!started) {
      started = true;
      load();
    }
  }

  Future<void> load() async {
    final store = AppScope.read(context);
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final p = await store.api.property(widget.id);
      store.rememberFavorites([p]);
      if (mounted) {
        setState(() {
          property = p;
          photoIndex = 0;
        });
      }
      if (p.latitude != null && p.longitude != null) {
        loadNearby(); // background — байрны мэдээллийг даруй харуулах
      } else if (mounted) {
        setState(() => nearby = null);
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> loadNearby() async {
    final store = AppScope.read(context);
    setState(() {
      nearbyLoading = true;
      nearbyError = null;
    });
    try {
      final result = await store.api.nearby(widget.id);
      if (mounted) setState(() => nearby = result);
    } catch (e) {
      if (mounted) setState(() => nearbyError = '$e');
    } finally {
      if (mounted) setState(() => nearbyLoading = false);
    }
  }

  Future<void> remove() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Зарыг устгах уу?'),
        content: Text('Энэ зар болон хадгалсан холбоосууд устна.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text('Болих'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text('Устгах'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final store = AppScope.read(context);
    setState(() => deleting = true);
    try {
      await store.api.request('DELETE', 'properties/${widget.id}/');
      store.favorites.remove(widget.id);
      store.changed();
      if (mounted) {
        showMessage(context, 'Зар устгагдлаа.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showMessage(context, e);
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final p = property;
    return Scaffold(
      appBar: AppBar(
        title: Text('Байрны дэлгэрэнгүй'),
        actions: [
          if (p != null) SaveButton(property: p),
          IconButton(
            tooltip: 'Байр харьцуулах',
            icon: Icon(Icons.compare_arrows),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ComparePage()),
            ),
          ),
        ],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : error != null
          ? EmptyState(
              title: 'Зар ачаалж чадсангүй',
              message: error!,
              onRetry: load,
            )
          : p == null
          ? SizedBox.shrink()
          : RefreshIndicator(
              onRefresh: load,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 1040),
                  child: ListView(
                    padding: EdgeInsets.only(bottom: 24),
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.zero,
                        child: SizedBox(
                          height: MediaQuery.sizeOf(context).width >= 900
                              ? 440
                              : 280,
                          child: Stack(
                            children: [
                              if (p.imageUrls.isEmpty)
                                PropertyImageView()
                              else
                                PageView.builder(
                                  controller: photoController,
                                  key: ValueKey(p.updatedKey),
                                  itemCount: p.imageUrls.length,
                                  onPageChanged: (i) =>
                                      setState(() => photoIndex = i),
                                  itemBuilder: (_, i) => GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PhotoGallery(
                                          urls: p.imageUrls,
                                          initialIndex: i,
                                        ),
                                      ),
                                    ),
                                    child: PropertyImageView(
                                      url: p.imageUrls[i],
                                    ),
                                  ),
                                ),
                              if (p.imageUrls.isNotEmpty)
                                Positioned(
                                  bottom: 16,
                                  right: 20,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${photoIndex + 1} / ${p.imageUrls.length}',
                                      style: TextStyle(),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (p.imageUrls.length > 1)
                        Padding(
                          padding: EdgeInsets.fromLTRB(24, 10, 24, 0),
                          child: SizedBox(
                            height: 64,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: p.imageUrls.length,
                              separatorBuilder: (_, index) =>
                                  SizedBox(width: 8),
                              itemBuilder: (_, i) => GestureDetector(
                                onTap: () => photoController.animateToPage(
                                  i,
                                  duration: Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                ),
                                child: Container(
                                  width: 108,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: photoIndex == i
                                          ? Color(0xFF8394E6)
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: PropertyImageView(url: p.imageUrls[i]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Chip(
                              label: Text(
                                '${p.typeLabel} • ${propertyTypes[p.propertyType]}',
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              p.priceLabel,
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.8,
                              ),
                            ),
                            if (p.area > 0 && p.listingType == 'sale')
                              Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Text(
                                  '${money(p.price / p.area)} / м²',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            SizedBox(height: 14),
                            Text(
                              p.title,
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                            SizedBox(height: 10),
                            PropertyLocation(property: p),
                            SizedBox(height: 16),
                            Card(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _Fact(
                                      icon: Icons.bed_outlined,
                                      value: '${p.rooms} өрөө',
                                      label: 'Өрөөний тоо',
                                    ),
                                    _Fact(
                                      icon: Icons.square_foot,
                                      value:
                                          '${p.area.toStringAsFixed(p.area % 1 == 0 ? 0 : 1)} м²',
                                      label: 'Нийт талбай',
                                    ),
                                    _Fact(
                                      icon: Icons.layers_outlined,
                                      value: '${p.floor}/${p.totalFloors}',
                                      label: 'давхар',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              'Байрны тухай',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 12),
                            SelectableText(
                              p.description.isEmpty
                                  ? 'Нэмэлт тайлбар оруулаагүй.'
                                  : p.description,
                              style: TextStyle(height: 1.65),
                            ),
                            SizedBox(height: 24),
                            CompareButton(property: p),
                            OutlinedButton.icon(
                              icon: Icon(Icons.map_outlined),
                              label: Text(
                                p.latitude == null || p.longitude == null
                                    ? 'Байршлын цэг оруулаагүй'
                                    : 'Газрын зурагт харах',
                              ),
                              onPressed:
                                  p.latitude == null || p.longitude == null
                                  ? null
                                  : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PropertyMapPage(
                                          initialProperty: p,
                                          query: {
                                            'listing_type': p.listingType,
                                            if (p.district.isNotEmpty)
                                              'district': p.district,
                                          },
                                        ),
                                      ),
                                    ),
                            ),
                            if (nearby != null ||
                                nearbyLoading ||
                                nearbyError != null) ...[
                              SizedBox(height: 20),
                              _NearbySection(
                                result: nearby,
                                loading: nearbyLoading,
                                error: nearbyError,
                              ),
                            ],
                            SizedBox(height: 12),
                            Text(
                              'Зар нийтэлсэн',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 12),
                            Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Icon(Icons.person_outline),
                                ),
                                title: Text(
                                  p.owner == null
                                      ? 'Зар нийтлэгч'
                                      : '${p.owner!['last_name']} ${p.owner!['first_name']}'
                                            .trim(),
                                ),
                                subtitle: Text(
                                  p.phone.isEmpty ? 'Утас оруулаагүй' : p.phone,
                                ),
                                trailing: IconButton(
                                  tooltip: 'Утас хуулах',
                                  onPressed: p.phone.isEmpty
                                      ? null
                                      : () async {
                                          await Clipboard.setData(
                                            ClipboardData(text: p.phone),
                                          );
                                          if (context.mounted) {
                                            showMessage(
                                              context,
                                              'Утасны дугаар хуулагдлаа.',
                                            );
                                          }
                                        },
                                  icon: Icon(Icons.copy_outlined),
                                ),
                              ),
                            ),
                            if (p.isOwner || store.isAdmin) ...[
                              SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: deleting
                                          ? null
                                          : () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      PropertyFormPage(
                                                        property: p,
                                                      ),
                                                ),
                                              );
                                              if (mounted) await load();
                                            },
                                      icon: Icon(Icons.edit_outlined),
                                      label: Text('Засах'),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: deleting ? null : remove,
                                      icon: Icon(Icons.delete_outline),
                                      label: Text(
                                        deleting ? 'Устгаж байна' : 'Устгах',
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: p == null || loading || error != null
          ? null
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: FilledButton.icon(
                  icon: Icon(Icons.call_outlined),
                  label: Text(
                    p.phone.isEmpty
                        ? 'Утасны мэдээлэл алга'
                        : '${p.phone} • Холбогдох',
                  ),
                  onPressed: p.phone.isEmpty
                      ? null
                      : () async {
                          try {
                            final launched = await launchUrl(
                              Uri(scheme: 'tel', path: p.phone),
                            );
                            if (!launched && context.mounted) {
                              showMessage(
                                context,
                                'Дуудлага нээж чадсангүй. Дугаарыг хуулж авна уу.',
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              showMessage(
                                context,
                                'Дуудлага нээж чадсангүй. Дугаарыг хуулж авна уу.',
                              );
                            }
                          }
                        },
                ),
              ),
            ),
    );
  }
}

extension on Property {
  String get updatedKey => '$id:${imageUrls.join(',')}';
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _Fact({required this.icon, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: Color(0xFF8394E6), size: 21),
        SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
          ),
        ),
        SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10),
        ),
      ],
    ),
  );
}

const _nearbyIcons = {
  'school': Icons.school_outlined,
  'kindergarten': Icons.child_care,
  'pharmacy': Icons.local_pharmacy_outlined,
  'bus_stop': Icons.directions_bus_outlined,
  'shop': Icons.storefront_outlined,
};
const _nearbyColors = {
  'school': Color(0xFF6366F1),
  'kindergarten': Color(0xFFF59E0B),
  'pharmacy': Color(0xFFEF4444),
  'bus_stop': Color(0xFF14B8A6),
  'shop': Color(0xFFA855F7),
};

class _NearbySection extends StatelessWidget {
  final NearbyResult? result;
  final bool loading;
  final String? error;
  const _NearbySection({
    required this.result,
    required this.loading,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && result == null) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 14),
              Text(
                'Ойр байрлах газрыг хайж байна…',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final r = result;
    if (r == null) {
      if (error != null) {
        return Card(
          child: ListTile(
            leading: Icon(Icons.near_me_outlined, color: Color(0xFF8394E6)),
            title: Text('Ойр байрлах газрыг ачаалж чадсангүй.'),
            subtitle: Text('Интернэтээ шалгаад дахин оролдоно уу.'),
          ),
        );
      }
      return SizedBox.shrink();
    }

    final categories = r.categories;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.near_me_outlined, color: Color(0xFF8394E6)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ойр байрлах газрууд',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'Байрнаас хамгийн ойр байгууллагууд (эх сурвалж: OpenStreetMap).',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
            SizedBox(height: 14),
            if (categories.isEmpty)
              Text(
                r.available
                    ? 'Энэ орчимд ойр байрлах газар олдсонгүй.'
                    : 'Ойр байрлах газрын мэдээлэл түр ачаалагдаагүй байна.',
                style: TextStyle(fontSize: 13),
              )
            else
              for (final category in categories)
                Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _nearbyIcons[category.key] ?? Icons.place_outlined,
                            size: 19,
                            color:
                                _nearbyColors[category.key] ??
                                Color(0xFF8394E6),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              category.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (category.nearest != null)
                            Text(
                              category.nearest!.distanceLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8394E6),
                              ),
                            ),
                        ],
                      ),
                      for (final place in category.places)
                        Padding(
                          padding: EdgeInsets.only(left: 27, top: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  place.name.isEmpty
                                      ? category.label
                                      : place.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              Text(
                                place.distanceLabel,
                                style: TextStyle(fontSize: 12),
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
    );
  }
}

class PhotoGallery extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const PhotoGallery({
    super.key,
    required this.urls,
    required this.initialIndex,
  });
  @override
  State<PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  late final PageController controller;
  late int index;
  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
    controller = PageController(initialPage: index);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Theme.of(context).colorScheme.surface,
      title: Text('${index + 1} / ${widget.urls.length}'),
    ),
    body: PageView.builder(
      controller: controller,
      itemCount: widget.urls.length,
      onPageChanged: (i) => setState(() => index = i),
      itemBuilder: (_, i) => InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        child: Center(
          child: Image.network(
            widget.urls[i],
            fit: BoxFit.contain,
            errorBuilder: (_, error, stack) => Icon(
              Icons.broken_image_outlined,
              color: Theme.of(context).colorScheme.surface,
              size: 60,
            ),
          ),
        ),
      ),
    ),
  );
}
