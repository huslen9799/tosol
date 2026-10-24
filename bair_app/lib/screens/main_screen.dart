import 'package:flutter/material.dart';

import '../services/app_store.dart';
import '../widgets/property_card.dart';
import '../widgets/brand.dart';
import 'home_page.dart';
import 'property_page.dart';
import 'property_form_page.dart';
import 'profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    return Scaffold(
      body: Column(
        children: [
          if (wide)
            Container(
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              color: Colors.white,
              child: Row(
                children: [
                  const BrandMark(size: 26),
                  const SizedBox(width: 10),
                  const Text(
                    'ӨРГӨӨ',
                    style: TextStyle(
                      fontSize: 18,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  for (final tab in [
                    (0, 'Нүүр'),
                    (1, 'Байр хайх'),
                    (2, 'Хадгалсан'),
                    (3, 'Профайл'),
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: TextButton(
                        onPressed: () => setState(() => currentIndex = tab.$1),
                        style: TextButton.styleFrom(
                          foregroundColor: currentIndex == tab.$1
                              ? AppColors.primary
                              : AppColors.secondaryText,
                          backgroundColor: currentIndex == tab.$1
                              ? AppColors.light
                              : null,
                        ),
                        child: Text(tab.$2),
                      ),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () async {
                      if (!await requireLogin(context) || !context.mounted) {
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PropertyFormPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Зар нэмэх'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: IndexedStack(
                  index: currentIndex,
                  children: [
                    const HomePage(),
                    const PropertyPage(),
                    store.loggedIn
                        ? const PropertyPage(saved: true)
                        : EmptyState(
                            title: 'Таалагдсан байраа хадгалаарай',
                            message: 'Нэвтэрч ороод хадгалсан заруудаа бүх төхөөрөмжөөсөө хараарай.',
                            buttonLabel: 'Нэвтрэх',
                            onRetry: () async {
                              await requireLogin(context);
                            },
                          ),
                    const ProfilePage(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: !wide && currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                if (!await requireLogin(context) || !context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PropertyFormPage()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Зар нэмэх'),
            )
          : null,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: currentIndex,
              height: 72,
              onDestinationSelected: (i) => setState(() => currentIndex = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Нүүр',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search),
                  selectedIcon: Icon(Icons.manage_search),
                  label: 'Хайх',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_border),
                  selectedIcon: Icon(Icons.favorite),
                  label: 'Хадгалсан',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Профайл',
                ),
              ],
            ),
    );
  }
}
