import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Placeholder for future on-device ML (TFLite / ML Kit) product recognition.
class AIProductRecognitionScreen extends StatefulWidget {
  const AIProductRecognitionScreen({super.key});

  @override
  State<AIProductRecognitionScreen> createState() =>
      _AIProductRecognitionScreenState();
}

class _AIProductRecognitionScreenState extends State<AIProductRecognitionScreen> {
  File? _image;
  String _status = 'Take a photo to analyze (placeholder).';

  Future<void> _capture() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
    );
    if (x == null) return;
    setState(() {
      _image = File(x.path);
      _status =
          'Photo captured. Later: run TensorFlow Lite or Google ML Kit here '
          'to suggest product name/category from the image.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI product recognition')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _status,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: _image == null
                    ? const Center(child: Text('No image yet'))
                    : Image.file(_image!, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _capture,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Take product photo'),
            ),
          ],
        ),
      ),
    );
  }
}
