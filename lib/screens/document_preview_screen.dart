import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

/// Shared in-app viewer for any uploaded document (resume, report,
/// document, chat attachment) across every role — replaces the previous
/// pattern of launching the signed URL in an external browser/app.
///
/// [url] must already be a resolved (signed) URL; [fileName] is used only
/// to infer the file type via its extension and for the app bar title.
class DocumentPreviewScreen extends StatefulWidget {
  final String url;
  final String fileName;

  const DocumentPreviewScreen({super.key, required this.url, required this.fileName});

  @override
  State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  String get _extension {
    final parts = widget.fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  Future<void> _openExternally() async {
    try {
      await launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open file: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(
          widget.fileName,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            tooltip: 'Open externally',
            onPressed: _openExternally,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_extension) {
      case 'pdf':
        return _PdfPreview(url: widget.url, onOpenExternally: _openExternally);
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return _ImagePreview(url: widget.url, onOpenExternally: _openExternally);
      case 'docx':
        return _DocxPreview(url: widget.url, onOpenExternally: _openExternally);
      default:
        return _UnsupportedPreview(onOpenExternally: _openExternally);
    }
  }
}

class _PdfPreview extends StatefulWidget {
  final String url;
  final VoidCallback onOpenExternally;

  const _PdfPreview({required this.url, required this.onOpenExternally});

  @override
  State<_PdfPreview> createState() => _PdfPreviewState();
}

class _PdfPreviewState extends State<_PdfPreview> {
  late final PdfController _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = PdfController(document: PdfDocument.openData(http.readBytes(Uri.parse(widget.url))));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return _UnsupportedPreview(onOpenExternally: widget.onOpenExternally, message: 'Could not load this PDF for preview.');
    }
    return PdfView(
      controller: _controller,
      scrollDirection: Axis.vertical,
      onDocumentError: (_) {
        if (mounted) setState(() => _failed = true);
      },
      builders: PdfViewBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        pageLoaderBuilder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String url;
  final VoidCallback onOpenExternally;

  const _ImagePreview({required this.url, required this.onOpenExternally});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4,
      child: Center(
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          },
          errorBuilder: (context, error, stackTrace) =>
              _UnsupportedPreview(onOpenExternally: onOpenExternally, message: 'Could not load this image for preview.'),
        ),
      ),
    );
  }
}

class _DocxPreview extends StatefulWidget {
  final String url;
  final VoidCallback onOpenExternally;

  const _DocxPreview({required this.url, required this.onOpenExternally});

  @override
  State<_DocxPreview> createState() => _DocxPreviewState();
}

class _DocxPreviewState extends State<_DocxPreview> {
  late final Future<String> _textFuture;

  @override
  void initState() {
    super.initState();
    _textFuture = _load();
  }

  Future<String> _load() async {
    final bytes = await http.readBytes(Uri.parse(widget.url));
    return docxToText(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _textFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.trim().isEmpty) {
          return _UnsupportedPreview(onOpenExternally: widget.onOpenExternally, message: 'Could not load this document for preview.');
        }
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppColors.infoBg,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Showing extracted text only — formatting isn't preserved. Open externally for the original layout.",
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Text(snapshot.data!, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, height: 1.5)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UnsupportedPreview extends StatelessWidget {
  final VoidCallback onOpenExternally;
  final String? message;

  const _UnsupportedPreview({required this.onOpenExternally, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file_outlined, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              message ?? 'Preview not available for this file type.',
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onOpenExternally,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open externally'),
            ),
          ],
        ),
      ),
    );
  }
}
