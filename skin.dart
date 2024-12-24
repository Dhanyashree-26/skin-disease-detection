import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class DiseaseInfoScreen extends StatefulWidget {
  @override
  _DiseaseInfoScreenState createState() => _DiseaseInfoScreenState();
}

class _DiseaseInfoScreenState extends State<DiseaseInfoScreen> {
  File? selectedImage;
  String diseaseName = "Unknown";
  String firstAidInstructions = "No instructions available.";
  bool isUploading = false;

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
        diseaseName = "Loading...";
        firstAidInstructions = "Loading...";
        isUploading = true;
      });
      await uploadImage(File(pickedFile.path));
    }
  }

  Future<void> uploadImage(File imageFile) async {
    const String url = 'http://127.0.0.1:5000/predict'; // Use `10.0.2.2` for emulator; replace with local IP for physical device
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      print('Sending request to: $url');
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);

        setState(() {
          diseaseName = data['disease'] ?? "Unknown Disease";
          firstAidInstructions = (data['instructions'] is List
              ? (data['instructions'] as List).join("\n")
              : "No instructions available.");
          isUploading = false;
        });
      } else {
        setState(() {
          diseaseName = "Error";
          firstAidInstructions = "Could not connect to server. Status code: ${response.statusCode}";
          isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        diseaseName = "Error";
        firstAidInstructions = "Could not connect to server. Error: $e";
        isUploading = false;
      });
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Skin Disease Detector'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Pops the current screen off the stack
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            selectedImage != null
                ? Image.file(
                    selectedImage!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Center(child: Text('No Image Selected')),
                  ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isUploading ? null : pickImage,
              child: isUploading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text("Upload Image"),
            ),
            SizedBox(height: 20),
            Text(
              "Disease: $diseaseName",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: Text(
                "First Aid Instructions:\n$firstAidInstructions",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
