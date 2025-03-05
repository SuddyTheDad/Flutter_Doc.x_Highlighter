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
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  String extractedText = "";
  bool isLoading = false;
  final String sentenceToHighlight = "How would you implement disaster recovery in Azure?";
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.95,
      upperBound: 1.0,
    )..repeat(reverse: true);

    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

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
    setState(() => isLoading = true);

    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      final text = docxToText(bytes, handleNumbering: true);

      await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading effect

      setState(() {
        extractedText = text ?? "Failed to extract text";
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error extracting text: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Document Viewer"),
          centerTitle: true,
          elevation: 4,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: ElevatedButton.icon(
                  onPressed: pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Select a DOCX File"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (extractedText.isNotEmpty)
                Expanded(
                  child: AnimatedOpacity(
                    opacity: extractedText.isNotEmpty ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 600),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          child: RichText(
                            text: highlightText(extractedText),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                const Text(
                  "No file selected",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
            ],
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

    return TextSpan(
      style: const TextStyle(color: Colors.black, fontSize: 16, height: 1.5),
      children: spans,
    );
  }
}
