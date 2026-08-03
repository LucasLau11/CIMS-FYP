import 'dart:io';
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Lets the user pinch-zoom and drag-reposition a freshly picked photo inside
/// a fixed circular frame (matching how the avatar is actually displayed
/// everywhere in the app) before it gets uploaded. Pops the cropped image as
/// a new [File] on confirm, or `null` if the user backs out.
class PhotoCropScreen extends StatefulWidget {
  final File imageFile;

  const PhotoCropScreen({super.key, required this.imageFile});

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  final _controller = CropController();
  Uint8List? _imageBytes;
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await widget.imageFile.readAsBytes();
    if (!mounted) return;
    setState(() => _imageBytes = bytes);
  }

  Future<void> _onCropped(CropResult result) async {
    switch (result) {
      case CropSuccess(:final croppedImage):
        final dir = await getTemporaryDirectory();
        final outPath = '${dir.path}/avatar_crop_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final outFile = await File(outPath).writeAsBytes(croppedImage);
        if (!mounted) return;
        Navigator.pop(context, outFile);
      case CropFailure():
        if (!mounted) return;
        setState(() => _isCropping = false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorCropFailed), backgroundColor: AppColors.error),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(l10n.cropPhotoTitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _isCropping || _imageBytes == null
                ? null
                : () {
                    setState(() => _isCropping = true);
                    _controller.cropCircle();
                  },
            child: _isCropping
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(l10n.cropPhotoConfirm, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
      body: _imageBytes == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Crop(
              image: _imageBytes!,
              controller: _controller,
              onCropped: _onCropped,
              withCircleUi: true,
              interactive: true,
              fixCropRect: true,
              baseColor: Colors.black,
              maskColor: Colors.black.withValues(alpha: 0.65),
              progressIndicator: const CircularProgressIndicator(color: Colors.white),
            ),
    );
  }
}
