import 'package:flutter/material.dart';

import '../services/app_store.dart';
import '../widgets/property_card.dart';
import '../widgets/brand.dart';
import '../widgets/app_theme.dart';
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
      appBar: wide
          ? null
          : AppBar(
              toolbarHeight: 44,
              actions: [ThemeToggle(), SizedBox(width: 12)],
            ),
      body: Column(
        children: [
          if (wide)
            Container(
              height: 76,
              padding: EdgeInsets.symmetric(horizontal: 40),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  BrandMark(size: 26),
                  SizedBox(width: 10),
                  Text(
                    'ӨРГӨӨ',
                    style: TextStyle(
                      fontSize: 18,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  for (final tab in [
                    (0, 'Нүүр'),
                    (1, 'Байр хайх'),
                    (2, 'Хадгалсан'),
                    (3, 'Профайл'),
                  ])
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: TextButton(
                        onPressed: () => setState(() => currentIndex = tab.$1),
                        style: TextButton.styleFrom(
                          foregroundColor: currentIndex == tab.$1
                              ? AppColors.primary
                              : Theme.of(context).colorScheme.onSurface,
                          backgroundColor: currentIndex == tab.$1
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                        ),
                        child: Text(tab.$2),
                      ),
                    ),
                  Spacer(),
                  ThemeToggle(),
                  SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      if (!await requireLogin(context) || !context.mounted) {
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PropertyFormPage()),
                      );
                    },
                    icon: Icon(Icons.add, size: 18),
                    label: Text('Зар нэмэх'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1280),
                child: IndexedStack(
                  index: currentIndex,
                  children: [
                    HomePage(),
                    PropertyPage(),
                    store.loggedIn
                        ? PropertyPage(saved: true)
                        : EmptyState(
                            title: 'Таалагдсан байраа хадгалаарай',
                            message: 'Нэвтэрч ороод хадгалсан заруудаа бүх төхөөрөмжөөсөө хараарай.',
                            buttonLabel: 'Нэвтрэх',
                            onRetry: () async {
                              await requireLogin(context);
                            },
                          ),
                    ProfilePage(),
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
                  MaterialPageRoute(builder: (_) => PropertyFormPage()),
                );
              },
              icon: Icon(Icons.add),
              label: Text('Зар нэмэх'),
            )
          : null,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: currentIndex,
              height: 72,
              onDestinationSelected: (i) => setState(() => currentIndex = i),
              destinations: [
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
