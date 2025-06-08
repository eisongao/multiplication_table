import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_configs.dart';
import 'quests_page.dart';
import 'home_page.dart';
import 'test_page.dart';
import 'settings_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 允许所有四个方向
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppConfigs(),
      child: const MultiplicationTableApp(),
    ),
  );
}

class MultiplicationTableApp extends StatelessWidget {
  const MultiplicationTableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '九九乘法表',
      theme: ThemeData(
        primaryColor: Colors.blue[800],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue[800]!,
          brightness: Brightness.light,
          surface: Colors.grey[100],
        ),
        fontFamily: GoogleFonts.notoSans().fontFamily,
        textTheme: GoogleFonts.notoSansTextTheme().apply(
          bodyColor: Colors.grey[900],
          displayColor: Colors.grey[900],
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 4,
          shadowColor: Colors.black12,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.blue[800],
          unselectedItemColor: Colors.grey[600],
          showUnselectedLabels: true,
        ),
      ),
      darkTheme: ThemeData(
        primaryColor: Colors.blue[900],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue[900]!,
          brightness: Brightness.dark,
        ),
        fontFamily: GoogleFonts.notoSans().fontFamily,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late final AnimationController _controller;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _controller.value = 1;
    _pages = [
      const HomePage(),
      const TestPage(),
      const QuestsPage(),
      const SettingsPage(),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
        _controller.forward(from: 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppConfigs>(context);
    final isChinese = settings.language == 'Chinese';

    return Scaffold(
      appBar: AppBar(
        title: FadeTransition(
          opacity: _controller,
          child: Text(
            isChinese ? '九九乘法表' : 'Multiplication Table',
            style: GoogleFonts.notoSans(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.table_chart),
            activeIcon: Icon(Icons.table_chart, color: Theme.of(context).colorScheme.primary),
            label: isChinese ? '首页' : 'Home',
            tooltip: isChinese ? '首页' : 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.quiz),
            activeIcon: Icon(Icons.quiz, color: Theme.of(context).colorScheme.primary),
            label: isChinese ? '测试' : 'Test',
            tooltip: isChinese ? '测试' : 'Test',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.games),
            activeIcon: Icon(Icons.games, color: Theme.of(context).colorScheme.primary),
            label: isChinese ? '闯关' : 'Quests',
            tooltip: isChinese ? '闯关' : 'Quests',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            activeIcon: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
            label: isChinese ? '设置' : 'Settings',
            tooltip: isChinese ? '设置' : 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.notoSans(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.notoSans(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
      ),
    );
  }
}