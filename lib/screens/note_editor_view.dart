import 'package:flutter/material.dart';
import '../data/local_repository.dart';

class NoteEditorScreen extends StatefulWidget {
  final LocalRepository repository;
  final NoteModel? noteToEdit; // अगर नया नोट है तो null होगा, एडिट के लिए पुराना नोट आएगा

  const NoteEditorScreen({
    super.key,
    required this.repository,
    this.noteToEdit,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  List<FolderModel> _folders = [];
  String? _selectedFolderId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initEditor();
  }

  Future<void> _initEditor() async {
    // डेटाबेस से सभी उपलब्ध फोल्डर्स (काम, निजी, विचार) लोड करें
    _folders = await widget.repository.getAllFolders();
    
    // अगर एडिट मोड है, तो पुराने डेटा को फील्ड्स में भरें
    if (widget.noteToEdit != null) {
      _titleController.text = widget.noteToEdit!.title;
      _contentController.text = widget.noteToEdit!.content;
      _selectedFolderId = widget.noteToEdit!.folderId;
    } else if (_folders.isNotEmpty) {
      // नए नोट के लिए पहला फोल्डर डिफॉल्ट चुनें
      _selectedFolderId = _folders.first.id;
    }
    
    setState(() => _isLoading = false);
  }

  void _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया नोट का शीर्षक (Title) लिखें'),
          backgroundColor: Color(0xFF1E1E1E),
        ),
      );
      return;
    }

    // नया या अपडेटेड नोट ऑब्जेक्ट तैयार करना
    final now = DateTime.now();
    final note = NoteModel(
      id: widget.noteToEdit?.id ?? now.millisecondsSinceEpoch.toString(),
      folderId: _selectedFolderId ?? 'f1',
      title: title,
      content: content,
      createdAt: widget.noteToEdit?.createdAt ?? now,
      updatedAt: now,
      isSynced: false, // नया/अपडेटेड नोट अभी सिंक नहीं हुआ है
    );

    // लोकल रिपॉजिटरी में सेव करना
    await widget.repository.insertNote(note);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('नोट सफलतापूर्वक सुरक्षित किया गया'),
          backgroundColor: Color(0xFF1E1E1E),
        ),
      );
      Navigator.pop(context, true); // पिछली स्क्रीन पर वापस जाएं और ट्रिगर दें
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1E1E)),
          onPressed: () => Navigator.pop(context),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        title: Text(
          widget.noteToEdit == null ? 'नया नोट' : 'नोट एडिट करें',
          style: const TextStyle(color: Color(0xFF1E1E1E), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF1E1E1E), size: 28),
            onPressed: _saveNote,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E1E1E)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // फोल्डर/कैटेगरी सिलेक्शन ड्रॉपडाउन
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFolderId,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        icon: const Icon(Icons.folder, color: Color(0xFF1E1E1E)),
                        style: const TextStyle(color: Color(0xFF1E1E1E), fontSize: 15),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedFolderId = newValue;
                          });
                        },
                        items: _folders.map<DropdownMenuItem<String>>((FolderModel folder) {
                          return DropdownMenuItem<String>(
                            value: folder.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(folder.colorHex),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(folder.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // शीर्षक (Title) इनपुट फ़ील्ड
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
                    maxLines: 1,
                    decoration: InputDecoration(
                      hintText: 'शीर्षक (Title)',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 20),
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(color: Color(0xFFE0E0E0), thickness: 0.5),
                  
                  // मुख्य नोट कंटेंट (Content) इनपुट फ़ील्ड
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      style: const TextStyle(fontSize: 16, color: Color(0xFF1E1E1E), height: 1.5),
                      maxLines: null, // मल्टीलाइन सपोर्ट के लिए
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: 'यहाँ लिखना शुरू करें...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
