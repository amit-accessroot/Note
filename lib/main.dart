import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/local_repository.dart';
import 'screens/home_search_view.dart';
import 'screens/note_editor_view.dart';
import 'services/cloud_sync_service.dart';

void main() async {
  // इनिशियलाइजेशन को पक्का करना ताकि डेटाबेस सही से काम करे
  WidgetsFlutterBinding.ensureInitialized();
  
  // सिस्टम स्टेटस बार और नेविगेशन बार (बॉटम बैक बटन पट्टी) को प्योर व्हाइट और आइकन्स को डार्क करना
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white, // बॉटम पट्टी का रंग प्योर व्हाइट
    systemNavigationBarIconBrightness: Brightness.dark, // बैक बटन का रंग डार्क
    systemNavigationBarDividerColor: Colors.transparent,
  ));

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
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E1E1E),
          background: Colors.white,
        ),
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
  final List<int> _navigationHistory = [0];
  final GlobalKey<State> _homeKey = GlobalKey();

  void _onTabSelected(int index) {
    if (_currentTabIndex == index) return;
    setState(() {
      _currentTabIndex = index;
      _navigationHistory.remove(index);
      _navigationHistory.add(index);
    });
  }

  void _navigateToEditor() async {
    final bool? shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(repository: widget.repository),
      ),
    );

    if (shouldRefresh == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      RootHomeScreen(
        key: _homeKey,
        repository: widget.repository,
        onAddNotePressed: _navigateToEditor,
      ),
      FolderDirectoryView(repository: widget.repository),
      SearchScreen(repository: widget.repository),
      SyncScreen(syncService: widget.syncService),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_navigationHistory.length > 1) {
          setState(() {
            _navigationHistory.removeLast();
            _currentTabIndex = _navigationHistory.last;
          });
        } else {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(
          index: _currentTabIndex,
          children: screens,
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
                margin: const EdgeInsets.only(bottom: 12),
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
