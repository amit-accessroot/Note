import 'dart:async';

/// ----------------------------------------------------
/// 1. फोल्डर / कैटेगरी मॉडल (Folder Model)
/// ----------------------------------------------------
class FolderModel {
  final String id;
  final String name;
  final int colorHex; // फोल्डर का थीम कलर (जैसे: काम के लिए डार्क रेड, विचार के लिए डार्क ब्लू)

  const FolderModel({
    required this.id,
    required this.name,
    required this.colorHex,
  });

  // डार्ट ऑब्जेक्ट को मैप/JSON में बदलने के लिए
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorHex': colorHex,
    };
  }

  // JSON से वापस डार्ट ऑब्जेक्ट बनाने के लिए
  factory FolderModel.fromMap(Map<String, dynamic> map) {
    return FolderModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      colorHex: map['colorHex'] ?? 0xFF1E1E1E,
    );
  }
}

/// ----------------------------------------------------
/// 2. नोट मॉडल (Note Model)
/// ----------------------------------------------------
class NoteModel {
  final String id;
  final String folderId; // किस फोल्डर से जुड़ा है
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced; // क्लाउड सिंक ट्रैकिंग के लिए (Level 5 में काम आएगा)

  const NoteModel({
    required this.id,
    required this.folderId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folderId': folderId,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] ?? '',
      folderId: map['folderId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      isSynced: (map['isSynced'] == 1),
    );
  }

  // नोट अपडेट करते समय नया ऑब्जेक्ट बनाने के लिए सहायक मेथड
  NoteModel copyWith({
    String? title,
    String? content,
    String? folderId,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return NoteModel(
      id: this.id,
      folderId: folderId ?? this.folderId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

/// ----------------------------------------------------
/// 3. लोकल रिपॉजिटरी इम्प्लीमेंटेशन (Local Repository)
/// ----------------------------------------------------
/// यह क्लास बिना किसी बाहरी डिपेंडेंसी एरर के इन-मेमोरी सिम्युलेटर का उपयोग करती है,
/// जिससे डेटा क्रैश नहीं होगा और यह पूरी तरह सिंक्रोनस और एसिंक्रोनस ऑपरेशन्स को सपोर्ट करेगी।
class LocalRepository {
  // इन-मेमोरी डेटाबेस सिमुलेशन जो ऐप रीस्टार्ट होने तक डेटा सुरक्षित रखता है
  final List<FolderModel> _mockFolders = [];
  final List<NoteModel> _mockNotes = [];

  LocalRepository() {
    // ऐप के शुरुआती रन पर डिफॉल्ट फोल्डर्स (काम, निजी, विचार) लोड करना
    _insertDefaultFolders();
  }

  void _insertDefaultFolders() {
    _mockFolders.addAll([
      const FolderModel(id: 'f1', name: 'काम (Work)', colorHex: 0xFFD32F2F),
      const FolderModel(id: 'f2', name: 'निजी (Personal)', colorHex: 0xFF1976D2),
      const FolderModel(id: 'f3', name: 'विचार (Ideas)', colorHex: 0xFF388E3C),
    ]);
  }

  // --- फोल्डर ऑपरेशन्स ---
  
  Future<List<FolderModel>> getAllFolders() async {
    await Future.delayed(const Duration(milliseconds: 100)); // रियल DB की तरह डिले
    return List.from(_mockFolders);
  }

  Future<void> createFolder(FolderModel folder) async {
    _mockFolders.add(folder);
  }

  // --- नोट ऑपरेशन्स ---

  Future<List<NoteModel>> getAllNotes() async {
    return List.from(_mockNotes);
  }

  Future<List<NoteModel>> getNotesByFolder(String folderId) async {
    return _mockNotes.where((note) => note.folderId == folderId).toList();
  }

  Future<void> insertNote(NoteModel note) async {
    // अगर नोट पहले से मौजूद है तो उसे हटाकर नया वर्ज़न सेव करेंगे (Upsert)
    _mockNotes.removeWhere((element) => element.id == note.id);
    _mockNotes.add(note);
  }

  Future<void> deleteNote(String noteId) async {
    _mockNotes.removeWhere((note) => note.id == noteId);
  }

  Future<List<NoteModel>> searchNotes(String query) async {
    if (query.isEmpty) return [];
    return _mockNotes
        .where((note) =>
            note.title.toLowerCase().contains(query.toLowerCase()) ||
            note.content.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
