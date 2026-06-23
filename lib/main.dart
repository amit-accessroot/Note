import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // सिस्टम बार (Status Bar & Navigation Bar) को प्योर व्हाइट और आइकन्स को डार्क सेट करना
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  runApp(const NoteApp());
}

class NoteApp extends StatelessWidget {
  const NoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Note',
      debugShowCheckedModeBanner: false,
      // ग्लोबल थीम कॉन्फिगरेशन: प्योर व्हाइट बैकग्राउंड और नो-ब्लू क्लिक इफेक्ट
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E1E1E), // प्रोफेशनल डार्क ग्रे/ब्लैक टोन
          background: Colors.white,
        ),
        // पूरे ऐप से ब्लू हाइलाइट और स्पलैश इफेक्ट को हटाना
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        // ऐप बार की डिफ़ॉल्ट सेटिंग्स
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF1E1E1E)),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentTabIndex = 0;
  
  // नेविगेशन हिस्ट्री को ट्रैक करने के लिए स्टैक (एडवांस्ड बैक बटन के लिए)
  final List<int> _navigationHistory = [0];

  // हमारी डमी स्क्रीन्स (जिन्हें हम अगले लेवल्स में अपग्रेड करेंगे)
  final List<Widget> _screens = [
    const RootHomeScreen(),
    const FolderScreen(),
    const SearchScreen(),
    const SyncScreen(),
  ];

  void _onTabSelected(int index) {
    if (_currentTabIndex == index) return;
    
    setState(() {
      _currentTabIndex = index;
      // हिस्ट्री में डुप्लिकेट्स को रोकने के लिए पुराना इंडेक्स हटाकर नया जोड़ना
      _navigationHistory.remove(index);
      _navigationHistory.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // एडवांस्ड बैक बटन हैंडलिंग: PopScope का उपयोग
    return PopScope(
      canPop: false, // सीधे ऐप बंद होने से रोकेगा
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // अगर यूजर हिस्ट्री में पीछे जा सकता है
        if (_navigationHistory.length > 1) {
          setState(() {
            _navigationHistory.removeLast(); // करंट स्क्रीन को हटाएं
            _currentTabIndex = _navigationHistory.last; // पिछली स्क्रीन पर जाएं
          });
        } else {
          // अगर यूजर एब्सोल्यूट रूट (होम स्क्रीन) पर है, तो ऐप बंद करने की अनुमति दें
          SystemNavigator.pop();
        }
      },
