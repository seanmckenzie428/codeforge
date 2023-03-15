import 'dart:math';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CodeForge',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: RandomCodeGenerator(),
    );
  }
}

class RandomCodeGenerator extends StatefulWidget {
  @override
  _RandomCodeGeneratorState createState() => _RandomCodeGeneratorState();
}

class _RandomCodeGeneratorState extends State<RandomCodeGenerator> {
  final _formKey = GlobalKey<FormState>();

  int _numCodes = 0;
  int _codeLength = 0;
  int _numCharsBetweenDashes = 0;
  int _codesPerFile = 0;
  String _outputFile = "";

  String _outputText = "";

  @override
  Widget build(BuildContext context) {
    String? outputLocation;
    TextEditingController outputTextController = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: Text("Random Code Generator"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Number of Codes"),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return "Please enter a number";
                  }
                  return null;
                },
                onSaved: (value) {
                  _numCodes = int.parse(value ?? "0");
                },
              ),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Code Length"),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return "Please enter a number";
                  }
                  return null;
                },
                onSaved: (value) {
                  _codeLength = int.parse(value ?? "0");
                },
              ),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: "Number of Characters Between Dashes"),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return "Please enter a number";
                  }
                  return null;
                },
                onSaved: (value) {
                  _numCharsBetweenDashes = int.parse(value ?? "0");
                },
              ),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Codes Per File"),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return "Please enter a number";
                  }
                  return null;
                },
                onSaved: (value) {
                  _codesPerFile = int.parse(value ?? "0");
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Output File"),
                onSaved: (value) {
                  _outputFile = value ?? "";
                },
                controller: outputTextController,
                initialValue: outputLocation,
              ),
              SizedBox(
                height: 4.0,
              ),
              TextButton(
                  onPressed: () {
                    _getOutputLocation().then((value) {
                      if (value != null) {
                        _outputFile = value;
                        outputTextController.text = _outputFile;
                      }
                    });
                  },
                  child: Text("Browse")),
              SizedBox(height: 16.0),
              ElevatedButton(
                child: Text("Generate Codes"),
                onPressed: () async {
                  if (_formKey.currentState?.validate() != null) {
                    _formKey.currentState?.save();
                    // setState(() {
                    //   _outputText = "";
                    // });

                    final codes = _generateCodes(
                        _numCodes, _codeLength, _numCharsBetweenDashes);

                    if (_codesPerFile > 0 && _codesPerFile < _numCodes) {
                      final files = _splitIntoFiles(codes, _codesPerFile);
                      for (int i = 0; i < files.length; i++) {
                        var stripExtension =
                            _outputFile.substring(0, _outputFile.length - 5);
                        final filename = "${stripExtension}_$i.csv";
                        await _writeFile(filename, files[i]);
                      }
                    } else {
                      final filename = _outputFile;
                      await _writeFile(filename, codes);
                    }

                    // setState(() {});
                  }
                },
              ),
              SizedBox(height: 16.0),
              Text(_outputText),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _generateCodes(
      int numCodes, int codeLength, int numCharsBetweenDashes,
      {String characterSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"}) {

    if (numCodes > pow(characterSet.length, codeLength)) {
      throw ErrorDescription("This combination of code length and count will create duplicates.");
    }

    Set<String> newCodes = {};
    final random = Random.secure();

    while (newCodes.length < numCodes) {
      String code = "";
      int dashIncrementer = 0;

      for (var i = 0; i < codeLength; i++) {
        if (dashIncrementer >= numCharsBetweenDashes) {
          code += "-";
          dashIncrementer = 0;
        }
        dashIncrementer++;

        code += characterSet[random.nextInt(characterSet.length)];
      }

      newCodes.add(code);
    }

    return newCodes.toList();
  }

  List<List<String>> _splitIntoFiles(List<String> codes, int codesPerFile) {
    final files = <List<String>>[];
    for (int i = 0; i < codes.length; i += codesPerFile) {
      final file = codes.sublist(i, i + codesPerFile);
      files.add(file);
    }
    return files;
  }

  Future<void> _writeFile(String filename, List<String> codes) async {
    final file = File(filename);
    final rows = codes.map((code) => [code]).toList();
    String csv = const ListToCsvConverter().convert(rows);
    await file.writeAsString(csv);

    // await Process.run('explorer', [directory.path]);
  }

  Future<String?> _getOutputLocation() async {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: 'codes.csv',
    );

    // print(outputFile);

    if (outputFile == null) {
      // User canceled the picker
      return null;
    } else {
      return outputFile;
    }
  }
}