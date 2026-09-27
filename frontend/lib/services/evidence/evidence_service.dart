import '../../models/models.dart';

class EvidenceService {
  final List<EvidenceRecord> _records = [];

  List<EvidenceRecord> get records => List.unmodifiable(_records);

  void add(EvidenceRecord record) {
    _records.insert(0, record);
  }

  List<EvidenceRecord> getByAwb(String awb) {
    return _records.where((e) => e.awb == awb).toList();
  }
}
