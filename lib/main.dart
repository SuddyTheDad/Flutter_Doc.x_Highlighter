import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:docx_to_text/docx_to_text.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String extractedText = "";
  final String sentenceToHighlight = "How would you implement disaster recovery in Azure? ";

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
    );

    if (result != null && result.files.single.path != null) {
      String filePath = result.files.single.path!;
      extractText(filePath);
    } else {
      debugPrint("No file selected");
    }
  }

  Future<void> extractText(String path) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      final text = docxToText(bytes, handleNumbering: true);

      setState(() {
        extractedText = text ?? "Failed to extract text";
      });
    } catch (e) {
      debugPrint("Error extracting text: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Document Viewer')),
        body: Center(
          child: extractedText.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("No file selected"),
                    ElevatedButton(
                      onPressed: pickFile,
                      child: const Text("Pick a DOCX file"),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: RichText(
                      text: highlightText(extractedText),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  TextSpan highlightText(String text) {
    List<TextSpan> spans = [];
    int startIndex = text.indexOf(sentenceToHighlight);

    if (startIndex == -1) {
      spans.add(TextSpan(text: text));
    } else {
      spans.add(TextSpan(text: text.substring(0, startIndex)));
      spans.add(
        TextSpan(
          text: sentenceToHighlight,
          style: const TextStyle(backgroundColor: Colors.yellow, fontWeight: FontWeight.bold),
        ),
      );
      spans.add(TextSpan(text: text.substring(startIndex + sentenceToHighlight.length)));
    }

    return TextSpan(style: const TextStyle(color: Colors.black, fontSize: 16), children: spans);
  }
}
