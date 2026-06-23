import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/local_repository.dart';
import 'screens/home_search_view.dart';
import 'screens/note_editor_view.dart';
import 'services/cloud_sync_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // सिस्टम स्टेटस बार और नेविगेशन बार को प्योर व्हाइट और आइकन्स को डार्क कॉन्फिगर करना
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  // ग्लोबल डिपेंडेंसीज को इनिशियलाइज करना (मेमोरी लीक और ओवरहेड से बचने के लिए सिंगलटन एप्रोच)
  final localRepository = LocalRepository();
  final cloudSyncService = CloudSyncService(localRepository: localRepository);

  runApp(NoteApp(
    localRepository: localRepository,
    cloudSyncService: cloudSyncService,
  ));
}

class NoteApp extends StatelessWidget {
  final LocalRepository localRepository;
  final CloudSyncService cloudSyncService;

  const NoteApp({
    super.key,
    required this.localRepository,
    required this.cloudSyncService,
  });

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
          seedColor: const Color(0xFF1E1E1E),
          background: Colors.white,
        ),
        // पूरे ऐप से डिफ़ॉल्ट ब्लू स्प्लैश और हाइलाइट इफेक्ट को रिमूव करना
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF1E1E1E)),
        ),
      ),
      home: MainNavigationHub(
        repository: localRepository,
        syncService: cloudSyncService,
      ),
    );
  }
}

class MainNavigationHub extends StatefulWidget {
  final LocalRepository repository;
  final CloudSyncService syncService;

  const MainNavigationHub({
    super.key,
    required this.repository,
    required this.syncService,
  });

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _currentTabIndex = 0;
  
  // एडवांस्ड बैक बटन नेविगेशन के लिए हिस्ट्री ट्रैकिंग स्टैक
  final List<int> _navigationHistory = [0];

  // स्टेट रिफ्रेश करने के लिए यूनिक की (Key) आर्किटेक्चर
  final GlobalKey<State> _homeKey = GlobalKey();

  void _onTabSelected(int index) {
    if (_currentTabIndex == index) return;
    setState(() {
      _currentTabIndex = index;
      _navigationHistory.remove(index);
      _navigationHistory.add(index);
    });
  }

  // नोट एडिटर स्क्रीन पर नेविगेट करने का मेथड
  void _navigateToEditor() async {
    final bool? shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(repository: widget.repository),
      ),
    );

    // अगर नया नोट सेव हुआ है, तो होम स्क्रीन का स्टेट रिफ्रेश करें
    if (shouldRefresh == true) {
      setState(() {
        // होम स्क्रीन विजेट को री-क्रिएट करने के लिए की (Key) को अपडेट या री-ट्रिगर करना
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // सभी स्क्रीन्स की लिस्ट जो नेविगेशन बार से जुड़ी हैं
    final List<Widget> screens = [
      RootHomeScreen(
        key: _homeKey,
        repository: widget.repository,
        onAddNotePressed: _navigateToEditor,
      ),
      // फोल्डर स्क्रीन (लेवल 2 के मॉडल्स डेटा को प्रदर्शित करने के लिए)
      FolderDirectoryView(repository: widget.repository),
      SearchScreen(repository: widget.repository),
      SyncScreen(syncService: widget.syncService),
    ];

    // एडवांस्ड बैक बटन हैंडलिंग: PopScope का उपयोग
    return PopScope(
      canPop: false, // सिस्टम बैक बटन से ऐप को सीधे बंद होने से रोकेगा
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // यदि हिस्ट्री स्टैक में पिछली स्क्रीन्स मौजूद हैं
        if (_navigationHistory.length > 1) {
          setState(() {
            _navigationHistory.removeLast(); // वर्तमान स्क्रीन को स्टैक से हटाएं
            _currentTabIndex = _navigationHistory.last; // पिछली स्क्रीन पर स्विच करें
          });
        } else {
          // यदि यूजर एब्सोल्यूट रूट (होम स्क्रीन) पर है, तो ऐप से एग्जिट करें
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(
          index: _currentTabIndex,
          children: screens, // परफॉर्मेंस ऑप्टिमाइजेशन: स्क्रीन्स का स्टेट प्रिजर्व रखने के लिए IndexedStack का उपयोग
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentTabIndex,
            onTap: _onTabSelected,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF1E1E1E),
            unselectedItemColor: Colors.grey.shade400,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.description_outlined),
                activeIcon: Icon(Icons.description),
                label: 'नोट्स',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.folder_open_outlined),
                activeIcon: Icon(Icons.folder),
                label: 'फोल्डर्स',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                activeIcon: Icon(Icons.search),
                label: 'सर्च',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.sync_outlined),
                activeIcon: Icon(Icons.sync),
                label: 'सिंक',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// फोल्डर्स/कैटेगरी को क्लीन लिस्ट में दिखाने के लिए विजेट (Performance Optimized)
class FolderDirectoryView extends StatelessWidget {
  final LocalRepository repository;
  const FolderDirectoryView({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'फोल्डर्स और कैटेगरीज',
          style: TextStyle(color: Color(0xFF1E1E1E), fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<FolderModel>>(
        future: repository.getAllFolders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1E1E1E)));
          }
          final folders = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return Container(
                margin: const EdgeInsets.bottom(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
                ),
                child: ListTile(
                  leading: Icon(Icons.folder, color: Color(folder.colorHex)),
                  title: Text(
                    folder.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF1E1E1E)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
