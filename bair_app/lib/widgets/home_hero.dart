import 'package:flutter/material.dart';

import 'brand.dart';

class HomeHero extends StatelessWidget {
  final TextEditingController search;
  final VoidCallback onSearch;
  final String listingType;
  final ValueChanged<String> onTypeChanged;
  const HomeHero({
    super.key,
    required this.search,
    required this.onSearch,
    required this.listingType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final wide = box.maxWidth >= 740;
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.turquoise, AppColors.blue, AppColors.lavender],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2483C5E6),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
          borderRadius: BorderRadius.circular(28),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _Architecture(wide: wide)),
            ),
            Padding(
              padding: EdgeInsets.all(wide ? 42 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .16),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.home_outlined,
                          size: 15,
                          color: Color(0xFFFFFFFF),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Таны дараагийн гэр',
                          style: TextStyle(color: Colors.black, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Байр хайх',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Худалдах, түрээслэх үл хөдлөх хөрөнгийн зарууд.',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 8,
                    children: [
                      _tab('sale', 'Худалдах'),
                      _tab('rent', 'Түрээслэх'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: TextField(
                      controller: search,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => onSearch(),
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        hintText: 'Дүүрэг, хотхон, байршлаар хайх...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Colors.black,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.primary,
                        ),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(6),
                          child: IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.turquoise,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: onSearch,
                            tooltip: 'Хайх',
                            icon: const Icon(Icons.arrow_forward),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _tab(String value, String label) => TextButton(
    onPressed: () => onTypeChanged(value),
    style: TextButton.styleFrom(
      backgroundColor: listingType == value
          ? const Color(0xFF83E6D6)
          : Colors.white.withValues(alpha: .35),
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    child: Text(label),
  );
}

class _Architecture extends CustomPainter {
  final bool wide;
  const _Architecture({required this.wide});
  @override
  void paint(Canvas canvas, Size size) {
    if (!wide) return;
    final x = size.width * .72;
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: .25);
    canvas.drawCircle(Offset(size.width * .92, size.height * .25), 125, paint);
    final line = Paint()
      ..color = const Color(0xFF34465E).withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final building = Path()
      ..moveTo(x, size.height)
      ..lineTo(x, 142)
      ..lineTo(x + 92, 80)
      ..lineTo(x + 205, 143)
      ..lineTo(x + 205, size.height);
    canvas.drawPath(building, line);
    canvas.drawLine(Offset(x + 92, 80), Offset(x + 92, size.height), line);
    for (var row = 0; row < 5; row++) {
      for (var col = 0; col < 3; col++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 110 + col * 27, 170 + row * 44, 15, 23),
            const Radius.circular(2),
          ),
          line,
        );
      }
    }
    canvas.drawLine(
      Offset(x - 50, size.height - 32),
      Offset(size.width, size.height - 32),
      line,
    );
  }

  @override
  bool shouldRepaint(_Architecture oldDelegate) => oldDelegate.wide != wide;
}
