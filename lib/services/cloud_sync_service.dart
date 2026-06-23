import 'package:flutter/material.dart';
import '../data/local_repository.dart';

/// ----------------------------------------------------
/// 1. क्लाउड सिंक सर्विस लॉजिक (Cloud Sync Service)
/// ----------------------------------------------------
class CloudSyncService {
  final LocalRepository localRepository;

  CloudSyncService({required this.localRepository});

  /// लोकल नोट्स को रिमोट सर्वर पर बैकअप और सिंक करने का कोर मेथड
  Future<SyncResult> performSync() async {
    try {
      // रियल सर्वर नेटवर्क डिले को सिमुलेट करना (2 सेकंड)
      await Future.delayed(const Duration(seconds: 2));

      // 1. लोकल डेटाबेस से सभी नोट्स निकालना
      final allNotes = await localRepository.getAllNotes();
      
      // 2. उन नोट्स को फिल्टर करना जो अभी सिंक नहीं हुए हैं (isSynced == false)
      final unsyncedNotes = allNotes.where((note) => !note.isSynced).toList();

      if (unsyncedNotes.isEmpty) {
        return SyncResult(
          success: true, 
          message: 'सभी नोट्स पहले से ही क्लाउड पर सुरक्षित हैं।', 
          syncedCount: 0
        );
      }

      // 3. क्लाउड बैकअप सिमुलेशन (सभी अनसिंक नोट्स को सर्वर पर भेजना)
      for (var note in unsyncedNotes) {
        // नोट को सिंक मार्क्ड (isSynced = true) करके लोकल में दोबारा सेव करना
        final updatedNote = note.copyWith(isSynced: true, updatedAt: DateTime.now());
        await localRepository.insertNote(updatedNote);
      }

      return SyncResult(
        success: true, 
        message: 'क्लाउड बैकअप सफलतापूर्वक पूरा हुआ।', 
        syncedCount: unsyncedNotes.length
      );
    } catch (e) {
      return SyncResult(
        success: false, 
        message: 'सिंक विफल रहा: कृपया नेटवर्क कनेक्शन जांचें।', 
        syncedCount: 0
      );
    }
  }
}

/// सिंक के परिणाम को ट्रैक करने के लिए मॉडल क्लास
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;

  SyncResult({required this.success, required this.message, required this.syncedCount});
}

/// ----------------------------------------------------
/// 2. क्लाउड सिंक स्क्रीन यूआई (Sync Screen UI)
/// ----------------------------------------------------
class SyncScreen extends StatefulWidget {
  final CloudSyncService syncService;

  const SyncScreen({super.key, required this.syncService});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _isSyncing = false;
  String _syncStatusMessage = 'आपका डेटा अंतिम बार सिंक नहीं किया गया है';
  DateTime? _lastSyncedTime;

  void _startCloudSync() async {
    setState(() {
      _isSyncing = true;
      _syncStatusMessage = 'क्लाउड सर्वर से कनेक्ट हो रहा है...';
    });

    final result = await widget.syncService.performSync();

    setState(() {
      _isSyncing = false;
      _syncStatusMessage = result.message;
      if (result.success) {
        _lastSyncedTime = DateTime.now();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'क्लाउड सिंक और बैकअप',
          style: TextStyle(color: Color(0xFF1E1E1E), fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // क्लाउड सिंक स्टेटस का मुख्य लोगो आइकन
            Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isSyncing ? Icons.sync : Icons.cloud_done_outlined,
                  size: 80,
                  color: const Color(0xFF1E1E1E),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // सिंक स्टेटस टेक्स्ट संदेश
            Text(
              _syncStatusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 8),
            
            // अंतिम सिंक का समय (यदि उपलब्ध हो)
            if (_lastSyncedTime != null)
              Text(
                'अंतिम सिंक: ${_lastSyncedTime!.hour}:${_lastSyncedTime!.minute.toString().padLeft(2, '0')}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            
            const SizedBox(height: 48),
            
            // प्रीमियम हाई-कॉन्ट्रास्ट सिंक बटन
            ElevatedButton.icon(
              onPressed: _isSyncing ? null : _startCloudSync,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.sync, color: Colors.white),
              label: Text(
                _isSyncing ? 'सिंक हो रहा है...' : 'अभी सिंक करें',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                disabledBackgroundColor: Colors.grey.shade400,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
                shadowColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory, // नो-ब्लू क्लिक इफेक्ट
              ),
            ),
            const SizedBox(height: 16),
            
            // डिवाइस सिंक आर्किटेक्चर जानकारी नोट
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF1E1E1E), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'सिंक पूरा होने के बाद आप अपने नोट्स को फोन, लैपटॉप या टैबलेट पर समान अकाउंट से एक्सेस कर सकते हैं।',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12, height: 1.4),
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
