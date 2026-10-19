import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  OcrService() : _recognizer = TextRecognizer();

  final TextRecognizer _recognizer;

  Future<String> recognize(String imagePath) async {
    final image = InputImage.fromFilePath(imagePath);
    final result = await _recognizer.processImage(image);
    return result.text;
  }

  Future<void> close() => _recognizer.close();
}
