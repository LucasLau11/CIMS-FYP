import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'file_picker_utils.dart';
import 'lang.dart';

/// One legal document chosen from the phone, before it is uploaded.
typedef PickedCompanyDocument = ({File file, String name, int size});

const int kMaxCompanyDocumentBytes = 10 * 1024 * 1024;

/// Lets the person choose company documents (PDF, JPG or PNG, up to 10 MB each). Files that are too big
/// or cannot be read are left out and named in [rejected], so the screen can say why.
Future<({List<PickedCompanyDocument> accepted, List<String> rejected})> pickCompanyDocuments() async {
  final picked = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    allowMultiple: true,
    withData: true,
  );
  final accepted = <PickedCompanyDocument>[];
  final rejected = <String>[];
  if (picked == null) return (accepted: accepted, rejected: rejected);
  for (final f in picked.files) {
    if (f.size > kMaxCompanyDocumentBytes) {
      rejected.add('${f.name} (${tr('over 10 MB', ms: 'melebihi 10 MB', zh: '超过 10 MB')})');
      continue;
    }
    try {
      accepted.add((file: await resolvePickedFile(f), name: f.name, size: f.size));
    } catch (_) {
      rejected.add(f.name);
    }
  }
  return (accepted: accepted, rejected: rejected);
}
