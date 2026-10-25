import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  const OcrResult({required this.text, required this.lines});

  final String text;
  final List<String> lines;
}

class OcrService {
  OcrService()
    : _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  Future<OcrResult> recognize(String imagePath) async {
    final image = InputImage.fromFilePath(imagePath);
    final result = await _recognizer.processImage(image);
    return OcrResult(
      text: result.text,
      lines: result.blocks
          .expand((block) => block.lines)
          .map((line) => line.text)
          .toList(growable: false),
    );
  }

  Future<void> close() => _recognizer.close();
}
