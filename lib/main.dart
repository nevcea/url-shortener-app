import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: Colors.teal),
      home: MyHome(),
    );
  }
}

class MyHome extends StatelessWidget {
  const MyHome({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    Future<Map<String, dynamic>> getData(String url) async {
      final response = await http.post(
        Uri.parse('https://api.lrl.kr/v6/short'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': dotenv.env['API_KEY'].toString(),
        },
        body: jsonEncode({'url': url}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create url: ${response.body}');
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text("URL Shortener"), centerTitle: true),

      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: controller,
                validator: (value) {
                  final urlPattern = r'^(http|https):\/\/[^\s$.?#].[^\s]*$';
                  final result = RegExp(
                    urlPattern,
                    caseSensitive: false,
                  ).hasMatch(value ?? '');
                  if (!result) {
                    return 'Please enter a valid URL';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  label: const Text("URL"),
                  hintText: "Enter URL",
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal),
                    borderRadius: BorderRadius.circular(10),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      final data = await getData(controller.text.trim());
                      final result = data['result'];

                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: Text("Shortened URL"),
                              content: Text(result ?? "No URL returned."),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: result),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Copied to clipboard!"),
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                  },
                                  child: Text("Copy"),
                                ),
                              ],
                            ),
                      );
                    } catch (e) {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: Text("Error"),
                              content: Text("Failed to shorten URL:\n$e"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text("OK"),
                                ),
                              ],
                            ),
                      );
                    }
                  }
                },
                child: Text("Convert"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
