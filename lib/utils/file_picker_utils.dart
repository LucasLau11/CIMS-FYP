import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Resolves a picked file to a real [File] on disk.
///
/// [FilePicker]'s `path` can come back null for files picked from sources
/// without direct filesystem access (Android's Storage Access Framework,
/// cloud-backed "Files" providers, etc.) — this is common on real devices,
/// not just an edge case. When that happens, callers that only checked
/// `path != null` and silently returned left the user with no feedback and
/// nothing uploaded. Always pass `withData: true` to [FilePicker.pickFiles]
/// so [PlatformFile.bytes] is available as a fallback, and use this to get
/// a [File] regardless of which one the platform gave back.
Future<File> resolvePickedFile(PlatformFile picked) async {
  if (picked.path != null) {
    return File(picked.path!);
  }
  if (picked.bytes != null) {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/${picked.name}');
    await tempFile.writeAsBytes(picked.bytes!);
    return tempFile;
  }
  throw Exception('Could not read the selected file. Please try picking it again.');
}
