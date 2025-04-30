import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final file = File("test.pdf");

  // Define the base URL^ for the server
  final baseUrl = 'http://127.0.0.1:8000/';

  try {
    print('Starte Upload...');
    print('Verwende Datei: ${file.path}');

    // Create the upload URI
    final uri = Uri.parse('${baseUrl}upload');

    // Create a multipart request with bytes (web-style)
    final request =
        http.MultipartRequest('POST', uri)
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              await file.readAsBytes(),
              filename: file.path.split('/').last,
            ),
          )
          ..fields['namespace'] = 'test456';

    print('Sende Request...');
    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    // Check response status
    if (response.statusCode == 200) {
      print('Upload erfolgreich!');
      print('Response: $responseData');
    } else {
  
    }
  } catch (e) {

  }
}
